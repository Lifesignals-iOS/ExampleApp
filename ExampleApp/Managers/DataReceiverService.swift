//
//  DataReceiverService.swift
//  This is a helper class to wire the LSpatch library. Any developer can either discard this class and create his own. Or even edit the class to cop with the usage of the project. The class provides helper methods for the user to understand whether the patch is connected or not. Similarly the patchStatus from the Capability of the broadcast message can be better understood using the enum "SensorStatus".

//  The class determines that the patch is connected or not based on the data receival and the broadcast received. If the data is not received, and broadcast is also not rreceived in 12 sec, the onConnectionStatusUpdate delegate method will get called with "disconnected" status.

//  The class will also issue the redirect command  to the selected patch in case the IP address of the phone changes.

//  Instead of doing logics in different classes, this single class is enough for handling all the patch related communication logics. This is because, intantiating the LSPatch in each ViewController will not be feasible. The developer must take care that multiple LSPatch instances are not getting created, if he is developing on his own.

//  APIs are defined for calling all lib APIs.

//
//  Created by Lifesignals on 24/04/20.
//  Copyright © 2020 Lifesignals. All rights reserved.
//

import Foundation
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
@objc protocol DataReceiverServiceDelegate {
    @objc optional func onDiscovery(bcast: [String: Any])
    @objc optional func onData(data: [String: Any])
    @objc optional func onStatus(status: [String: Any])
    @objc optional func onConnectionStatusUpdate(isConnected: Bool)
}
final class DataReceiverService {
    
    static let shared = DataReceiverService()
    
    public var selectedPatchID: String = ""
    public var selectedBroadcastData: [String: Any]?
    public var isConnected = false
    
    public var delegate: DataReceiverServiceDelegate? = nil
    
    private var lsPatch: LSPatch?
    var lastDataRxTime = Date()
    
    private var lastBroadcastReceivedTime: Int = 0
    private var statusQueue = DispatchQueue(label: "statusQueue", qos: .userInitiated)
    
    private var connTimer: Timer? = nil // Until a START is given, if the broadcast is not received in 12 sec, the isConnected should be made false. Once started, the condition is checked when the connection "socket-timeout" is triggered.
    
    
    // LSPatch lib intialization
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
                }
            }
            
        }, onStatus: { [weak self] (statusObj)  in
            
            if self != nil {
                let status = statusObj["status"] as! String
                let value = statusObj["value"] as! String
                if (status == "connection") {
                    
                    if(value == "socket-timeout") {
                        // The time check is also needed, because the serial queue for the data receival is taking more time, during which the connection-timeout is being triggered too.
                        if(!self!.isBCReceivedRecently() && Date().timeIntervalSince(self!.lastDataRxTime) > 3) {
                            if(self!.isConnected){
                                self?.isConnected = false
                                self?.delegate?.onConnectionStatusUpdate?(isConnected: false)
                                
                            }
                        } else if Date().timeIntervalSince(self!.lastDataRxTime) < 3 {
                        
                        }
                    }
                    
                }
                self?.delegate?.onStatus?(status: statusObj)
            }
        })
    }
    
    func getLibVersion() -> String {
        let bundle = Bundle(identifier: "com.ls.lspatch")! // Get a reference to the bundle from your framework (not the bundle of the app itself!)
        let build = bundle.infoDictionary!["CFBundleShortVersionString"] as! String
        return build
    }
    
    func select(patchId: String,brdCast: [String: Any]) {
        connTimer?.invalidate()
        connTimer = nil
        
        selectedPatchID = patchId
        selectedBroadcastData = brdCast
        lsPatch?.select(patchId: patchId)
        
        startConnCheckTimer()
    }
    
    func identify(){
        lsPatch?.identify()
    }
    
    func reconfigure(ssid: String, password: String) {
        lsPatch?.configureSSID(SSID: ssid, passwd: password)
    }
    
    func redirect(deviceIP: String){
        lsPatch?.redirect(ip: deviceIP)
    }
    
    func configure(configObj : [String: Any]) {
        lsPatch?.configure(sensorConfig: configObj)
    }
    
    func start() {
        self.lsPatch?.start()
    }
    
    func commit() {
        
        // If LongSync = false, the patch will scan for hotspot in every 15 sec if connection is lost. If true, the scan will happen only after every 2 min.
        lsPatch?.commit(longSync: false)
    }
    
    func request(seqnceList: [UInt32]){
        
        // If some data is lost due to patch going out of range, the app can request the data as a list if the number of lost packets is less than 100.
        
        // The request has to be given as 3 requests with seqnceList count as 100 - 100 - 55 at a time. The next bunch of requests can be given either after all the requested data is received or after 3 sec. The same sequence request should happen only after 3 sec.
        
        self.lsPatch?.requestData(sequenceList: seqnceList)
    }
    
    func requestRange(start: UInt32, stop: UInt32) {
        
        // If the app has not obtained data for a long duration, then the request can be done as range request. At a time max of 32 requests can be given. If the patch's buffer count limit is reached, then the remaining requests are discarded.
        lsPatch?.requestData(seqStart: start, seqEnd: stop)
    }
   
    func stopAcq() {
        lsPatch?.stopAcquisition()
    }
    
    func turnOff(eraseFlash: Bool){
        lsPatch?.turnOff(eraseFlash: true)
    }
    
    func finish(){
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
    
    func isPatchStreaming() -> Bool {
        if(!selectedPatchID.isEmpty && selectedBroadcastData != nil) {
            let cap = selectedBroadcastData!["Capability"] as! [String: Any]
            let patchStatus = cap["PatchStatus"] as? UInt16 ?? 0
            return SensorStatus.isCommitted(status: patchStatus)
        }
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
        if (self.lastBroadcastReceivedTime != 0){
            if((currentTime - (self.lastBroadcastReceivedTime)) > 12){
                return false
            }else{
                return true
            }
        }
        return false
    }
    
}

