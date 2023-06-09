//
//  BLEUpdateHandler.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/1/21.
//  
//
    

import CoreBluetooth
import CoreData

extension Date {
   func getFormattedDate(format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        return dateformat.string(from: self)
    }
}

struct BLEUpdatedCharacteristicHandler {
	
	let bleManager = BLEManager.shared
    let bleManagerVal = BLEManagerVal.shared
	
	// function to translate heart rate to decimal, copied straight up from this tut: https://www.raywenderlich.com/231-core-bluetooth-tutorial-for-ios-heart-rate-monitor#toc-anchor-014
	func heartRate(from characteristic: CBCharacteristic) -> Int {
		guard let characteristicData = characteristic.value else { return -1 }
		let byteArray = [UInt8](characteristicData)

		let firstBitValue = byteArray[0] & 0x01
		if firstBitValue == 0 {
			// Heart Rate Value Format is in the 2nd byte
			return Int(byteArray[1])
		} else {
			// Heart Rate Value Format is in the 2nd and 3rd bytes
			return (Int(byteArray[1]) << 8) + Int(byteArray[2])
		}
	}
    
    func callAPI(data: String) {
        guard let url = URL(string: "https://jxjsservice.jxfit.cn/management2/heart_rate/insert"+data) else{
            return
        }

        let task = URLSession.shared.dataTask(with: url){
            data, response, error in
            
            if let data = data, let string = String(data: data, encoding: .utf8){
                print(string)
            }
        }

        task.resume()
    }
    

	
	func handleUpdates(characteristic: CBCharacteristic, peripheral: CBPeripheral) {
		switch characteristic.uuid {
		case bleManagerVal.cbuuidList.musicControl:
			let musicControl = [UInt8](characteristic.value!)
			MusicController.shared.controlMusic(controlNumber: Int(musicControl[0]))
		case bleManagerVal.cbuuidList.hrm:
			let bpm = heartRate(from: characteristic)
            bleManagerVal.heartBPM = Double(bpm)
			if bpm != 0{
                ChartManager.shared.addItem(dataPoint: DataPoint(date: Date(), value: Double(bpm), chart: ChartsAsInts.heart.rawValue))
                
                // Complete the func was send a value of heart rate to server.
                // write by Xavi
                
                let date = Date()
                let format = date.getFormattedDate(format: "yyyy-MM-dd HH:mm:ss")
                let escapedString = format.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                let data = "?services_no=1&record_time=\(escapedString!)&rate=\(Int(bpm))"
                DebugLogManager.shared.debug(error: "heart rate value \(String(data))", log: .ble, date: Date())
                callAPI(data: data)
			}
		case bleManagerVal.cbuuidList.bat:
			guard let value = characteristic.value else {
				DebugLogManager.shared.debug(error: "Could not read battery level", log: .ble, date: Date())
				break
			}
			let batData = [UInt8](value)
			DebugLogManager.shared.debug(error: "battery level report: \(String(batData[0]))", log: .ble, date: Date())
            ChartManager.shared.addItem(dataPoint: DataPoint(date: Date(), value: Double(batData[0]), chart: ChartsAsInts.battery.rawValue))
            bleManager.batteryLevel = Double(batData[0])
		case bleManagerVal.cbuuidList.stepCount:
            guard let value = characteristic.value else {
				DebugLogManager.shared.debug(error: "Could not read step count", log: .ble, date: Date())
				break
			}
			let stepData = [UInt8](value)
            bleManagerVal.stepCount = Int(stepData[0]) + (Int(stepData[1]) * 256) + (Int(stepData[2]) * 65536) + (Int(stepData[3]) * 16777216)
            //bleManager.stepCount = Int(stepData[0]) + (Int(stepData[1]) * 256) + (Int(stepData[2]) * 65536) + (Int(stepData[3]) * 16777216)
			StepCountPersistenceManager().setStepCount(steps: bleManagerVal.stepCount, arbitrary: false, date: Date())
		default:
			break
		}
	}
}
