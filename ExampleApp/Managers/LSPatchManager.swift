//
//  LSPatchManager.swift
//  SPatch
//
//  Created by Lifesignals on 24/04/20.
//  Copyright © 2020 Lifesignals. All rights reserved.
//

import Foundation
import UIKit
import LSPatch

enum SensorStatus: UInt16 {
    
    case Initial = 1
    case Configured = 2
    case StartProc = 4
    case Streaming = 8
    case Complete = 16
    
    public static func isConfigured(status: UInt16) -> Bool {
        return (status & SensorStatus.Configured.rawValue) == SensorStatus.Configured.rawValue
    }
    
    public static func isStreaming(status: UInt16) -> Bool {
        return (status & SensorStatus.Streaming.rawValue) == SensorStatus.Streaming.rawValue
    }
    
    public static func isCommitted(status: UInt16) -> Bool {
        return (status & SensorStatus.StartProc.rawValue) == SensorStatus.StartProc.rawValue
    }
    public static func isProcComplete(status: UInt16) -> Bool {
        return (status & SensorStatus.Complete.rawValue) == SensorStatus.Complete.rawValue
    }
}
@objc protocol LSPatchManagerDelegate {
    @objc optional func onDiscovery(bcast: [String: Any])
    @objc optional func onData(data: [String: Any])
    @objc optional func onStatus(status: [String: Any])
    @objc optional func onConnectionStatusUpdate(isConnected: Bool)
}
final class LSPatchManager {
    
    static let shared = LSPatchManager()
    
    public var selectedPatchID: String = ""
    public var selectedBroadcastData: [String: Any]?
    public var isConnected = false
    
    public var delegate: LSPatchManagerDelegate? = nil
    
    private var totalAvailSeq = 0
    
    private var lsPatch: LSPatch?
    var lastDataRxTime = Date()
    
    private var lastBroadcastReceivedTime: Int = 0
    private var statusQueue = DispatchQueue(label: "statusQueue", qos: .userInitiated)
    
    private var connTimer: Timer? = nil // Until a START is given, if the broadcast is not received in 12 sec, the isConnected should be made false. Once started, the condition is checked when the connection "socket-timeout" is triggered.
    
    
    func initializePatch() {
        if (self.lsPatch != nil){
            return
        }
        self.lsPatch = LSPatch(options: [String: Any](), onDiscovery: { [weak self](discObj) in
            
            if let patchInfo = discObj["PatchInfo"] as? [String: Any?], let patchId = patchInfo["PatchId"] as? String {
                
                if(patchId == self?.selectedPatchID){
                    
                    if let capability = discObj["Capability"] as? [String: Any?], let patchStatus = capability["PatchStatus"] as? UInt16 {
                       
                        // check for duplicate broadcast
                        if (self!.lastBroadcastReceivedTime != 0 && Int(Date().timeIntervalSince1970) - self!.lastBroadcastReceivedTime < 2) {
                            return
                        }
                        
                        self?.selectedBroadcastData = discObj
                        if(!self!.isConnected) {
                            self?.isConnected = true
                            self?.delegate?.onConnectionStatusUpdate?(isConnected: true)
                        }
                        
                        self?.lastBroadcastReceivedTime = Int(Date().timeIntervalSince1970)
                      
                        // receving broadcast. But not streaming. So need to call redirect.
                        if self?.selectedPatchID == patchId && self?.selectedBroadcastData != nil &&  SensorStatus.isCommitted(status: patchStatus){
                            let capability = self!.selectedBroadcastData!["Capability"] as! Dictionary<String, Any>
                            let destIP = capability["DestIP"] as? String
                            let patchIP = self?.selectedBroadcastData!["PatchIP"] as! String
                            if let deviceIP = UIDevice.current.getIFAddresses(patchIP: patchIP){
                                print("Dest ip \(destIP!)  deviceip \(deviceIP)")
                                
                                if deviceIP != destIP {
                                    self?.lsPatch?.redirect(ip: deviceIP)
                                }
                            }
                        }
                    }
                }
            }
            self?.delegate?.onDiscovery?(bcast: discObj)
            
        }, onData: { [weak self] (streamObj) in
            let dataJSON = streamObj["SensorData"]  as? Dictionary<String, Any?>
            if let patch = dataJSON?["PatchId"] as? String {
                if(self?.selectedPatchID == patch){
                    self?.lastDataRxTime = Date()
                    self?.delegate?.onData?(data: streamObj)
                }else{
                    //Skipping stream
                    //logger.log(str:"\(logger.testLogCurrentTime) " +  "Skipped stream packet patch id mismatch patch :\(patch)")
                }
            }
            
        }, onStatus: { [weak self] (statusObj)  in
            
            if self != nil {
                let status = statusObj["status"] as! String
                let value = statusObj["value"] as! String
                if (status == "connection") {
                    
                    if(value == "socket-timeout") {
                        
                       // logger.testLog(time: logger.testLogCurrentTime, tag: APP_TCPCMDS, message: "${command = connection} ${value = \(value)}")
                        
                        // The time check is also needed, because the serial queue for the data receival is taking more time, during which the connection-timeout is being triggered too.
                        if(!self!.isBCReceivedRecently() && Date().timeIntervalSince(self!.lastDataRxTime) > 3) {
                            if(self!.isConnected){
                                self?.isConnected = false
                                self?.delegate?.onConnectionStatusUpdate?(isConnected: false)
                                
                            }
                        } else if Date().timeIntervalSince(self!.lastDataRxTime) < 3 {
                           // logger.log(str:"\(logger.testLogCurrentTime) " +  "Data is being received from lib!!!")
                        }
                    }
                    
                }
                self?.delegate?.onStatus?(status: statusObj)
            }
            
            
        })
    }
    func identifyPatch(){
        lsPatch?.identify()
    }
    
    func select(patchId: String,brdCast: [String: Any]) {
        connTimer?.invalidate()
        connTimer = nil
        
        selectedPatchID = patchId
        selectedBroadcastData = brdCast
        lsPatch?.select(patchId: patchId)
        
        startConnCheckTimer()
    }
    
    func reconfigure(ssid: String, password: String) {
       // logger.log(str:"\(logger.testLogCurrentTime) " +  "Reconfigure ssid: \(ssid) pass: \(password)")
        lsPatch?.configureSSID(SSID: ssid, passwd: password)
    }
    func request(seqnceList: [UInt32]){
       
        self.lsPatch?.requestData(sequenceList: seqnceList)
        
    }
    func redirect(deviceIP: String){
        lsPatch?.redirect(ip: deviceIP)
    }
    func start() {
        self.lsPatch?.start()
    }
    
    func commit() {
       
        lsPatch?.commit(longSync: false)
       
    }
    
    
    func configurePatch(input : UInt16) {
        
        if var bcData = self.selectedBroadcastData {
            
            var bc = bcData["ConfigurePatch"] as? Dictionary<String,Any>
            
         //   let duration = UserDefaults.standard.value(forKey: DURATION)
            
//            if duration is String{
//
//                bc?["PatchLife"] = UInt16(duration as! String)
//
//            }else{
//
//                bc?["PatchLife"] = duration as! UInt16
//
//            }
           // let duration: UInt16 = 10
            bc?["PatchLife"] = input

            //patchLife
            
            bcData["ConfigurePatch"] = bc
            
            lsPatch?.configure(sensorConfig: bcData)
            
        }
        
    }
    
    func stopAcq() {
        lsPatch?.stopAcquisition()
    }
    func turnOff(){
       // logger.testLog(time: logger.testLogCurrentTime, tag: APP_RET_LOGIC, message: "Turn off Called")
        
        lsPatch?.turnOff(eraseFlash: true)
    }
    func requestRange(start: UInt32, stop: UInt32) {
        //        print("requested for range start === \(start) and stop === \(stop)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            //logger.testLog(time: logger.testLogCurrentTime, tag: APP_RET_LOGIC, message: "${RRTCP = (\(start),\(stop))}")
            self.lsPatch?.requestData(seqStart: start, seqEnd: stop)
        }
    }
    
    func isPatchStreaming() -> Bool {
        if(!selectedPatchID.isEmpty && selectedBroadcastData != nil) {
            let cap = selectedBroadcastData!["Capability"] as! [String: Any]
            let patchStatus = cap["PatchStatus"] as? UInt16 ?? 0
           // logger.log(str: "PAth status !!!!!!!!!!!!!! \(patchStatus)   \(SensorStatus.isCommitted(status: patchStatus))")
            return SensorStatus.isCommitted(status: patchStatus)
        }
        //logger.log(str: "isPatchStreaming !!!!!!!!!!!!!! Else")
        return false
    }
    
    func getPatchStartTime() -> UInt32 {
        if(!selectedPatchID.isEmpty && selectedBroadcastData != nil) {
            let stTime = selectedBroadcastData!["Capability"] as! [String: Any]
            let stTimeRet = stTime["StartTime"] as? UInt32 ?? 0
            return stTimeRet
        }
        return 0
    }

    func finish(){
      //  logger.log(str:"\(logger.testLogCurrentTime) " +  "LSPatchManager : Close connection ")
        lsPatch?.finish()
        selectedPatchID = ""
        selectedBroadcastData = nil
        lsPatch = nil
        lastBroadcastReceivedTime = 0
        DispatchQueue.main.async {
            self.connTimer?.invalidate()
            self.connTimer = nil
        }
        
    }
    
    private func startConnCheckTimer() {
        connTimer?.invalidate()
        connTimer = nil
        
        DispatchQueue.main.async {
            self.connTimer = Timer.scheduledTimer(withTimeInterval: 12, repeats: true, block: { (timer) in
                
                self.statusQueue.async {
                    
                    // Stops the timer, if the patch started streaming. This is because, timer is not required, as the "Socket-timeout" for "connection" will be received, and the check can be done there.
                    if(self.isPatchStreaming()) {
                        self.connTimer?.invalidate()
                        self.connTimer = nil
                        return
                    }
                    
                    if(!self.isBCReceivedRecently()) {
                        if(self.isConnected){
                            self.isConnected = false
                            self.delegate?.onConnectionStatusUpdate?(isConnected: false)
                        }}}})
        }
    }
    
    private func isBCReceivedRecently() -> Bool {
        let currentTime = Int(Date().timeIntervalSince1970)
     //   logger.log(str: "Last broadcast: \(self.lastBroadcastReceivedTime ) Connected: \(self.isConnected) currentTime: \(currentTime)")
        if (self.lastBroadcastReceivedTime != 0){
            if((currentTime - (self.lastBroadcastReceivedTime)) > 12){
           //     logger.log(str: "isBCReceivedRecently return false")
                return false
            }else{
                return true
            }
        }
        return false
    }
}

