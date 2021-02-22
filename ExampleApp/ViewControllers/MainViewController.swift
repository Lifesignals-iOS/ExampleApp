//
//  MainViewController.swift
//  LSExampleApp
//
//  Created by Reshmi K V on 19/02/21.
//  Copyright © 2021 LifeSignals. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    @IBOutlet weak var patchLifeTextField: UITextField!
    @IBOutlet weak var patchIdLabel: UILabel!
    @IBOutlet weak var ecgPlot: LineChart!

    let drc = DataReceiverService.shared
    
    private var discoveredBroadcastObj: [String: Any]? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        drc.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        initializePlot()
    }
    
    @IBAction func didSelectScan(_ sender: Any) {
        print("Scanning started")
        drc.initializePatch()
    }
    
    @IBAction func didSelect(_ sender: Any) {
        if let patchId = self.patchIdLabel.text, let brdcst = discoveredBroadcastObj {
            // The select method has to be called to start communication with a particular patch. The patch to be connected to has to be discovered first so that user can call this command.
            print("Selected \(patchId)")
            drc.select(patchId: patchId, brdCast: brdcst)
        }
    }
    
    @IBAction func didSelectConfigure(_ sender: Any) {
        if let duration = UInt16(patchLifeTextField.text ?? "") {
            var configDict = [String: Any]()
            var subConfig = [String: Any]()
            subConfig["PatchLife"] = duration
            configDict["ConfigurePatch"] = subConfig

            print("Configure \(configDict)")
            drc.configure(configObj: configDict)
        }
        
        // The user can configure ECGChSps, Latency, Aggregation Interval, FeatureConfig etc. the "subConfig" keys and values need to be added for those which are required
        
        // The next broadcast received after the configuration will have configured values.
        
        // Always the user should do configure() -> start() -> commit()
        
        // User can call configure multiple times before start.
        
        // In case configure() is not done and start() is called, the patch will start in its default configuration.
    
        // After the commit() is called, the configuration will get permenantly written to patch flash. The next broadcast after Commit will have the patch status as Configured, Streaming, StartProc.
    
    }
    
    @IBAction func didSelectStart(_ sender: Any) {
        print("Start pressed")
        drc.start()
    }
    @IBAction func didSelectCommit(_ sender: Any) {
        print("Commit pressed")
        drc.commit()
        
        // The LSPatch Actually takes a variable with the commit - LongSync - true/false
        // The drc will set LongSync = false while commit(). This is preferred for a Real time monitoring scenarion, were the patch will try to connect back to Hotspot in 15 sec if connection is lost. If LongSync = 2, the reconnection will happen after 2 min.
    }

    @IBAction func didSelectStopAcq(_ sender: Any) {
        print("Stop pressed")
        drc.stopAcq()
    }
    
    @IBAction func didSelectTurnOff(_ sender: Any) {
        print("Turn Off pressed")
        drc.turnOff(eraseFlash: true)
    }
    
    @IBAction func didSelectFinish(_ sender: Any) {
        print("Finish pressed")
        drc.finish()
        
        discoveredBroadcastObj = nil
        self.patchIdLabel.text = "Patch Id"
    }
    
    private func initializePlot() {
            if self.ecgPlot.chartTransform.count == 0 {
                self.ecgPlot.chartTransform.append(CGAffineTransform())
                let bounds = ecgPlot.frame
                self.ecgPlot.addPlot(yCenter: Int32(bounds.minY), height: Int32(bounds.height/2), yValuePerPixel: 0.3, spacing: 512, graphColor: UIColor.green.cgColor)
            }
        
//        self.ecgPlot.runTimer()

    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MainViewController: DataReceiverServiceDelegate {
    func onDiscovery(bcast: [String: Any]) {
        if let patchInfo = bcast["PatchInfo"] as? [String: Any], let patchId = patchInfo["PatchId"] as? String {
            
            DispatchQueue.main.async {
                self.patchIdLabel.text = patchId
            }
            self.discoveredBroadcastObj = bcast
            
            print("Discovered: \(discoveredBroadcastObj)")
            
            // In usual cases there will be only patch connected to a hotspot. The above code is assuming that only one patch per hotspot will be present.
            // In case there are multiple patches, a list has to  be maintained for the broadcast objects for the user selection
            
            // Once the Start(), commit() or stopAcq() is done, the next broadcast will have the patch Status updated in the Capability.
            
            // Uncomment the following to know the current patch status in each broadcast:-
            /*if let capability = bcast["Capability"] as? [String: Any?], let patchStatus = capability["PatchStatus"] as? UInt16 {
                
                if SensorStatus.isStreaming(status: patchStatus) {
                    print("Patch is streaming")
                } else if SensorStatus.isProcComplete(status: patchStatus) {
                    print("Patch proc is complete")
                }
            }*/
        }
    }
    func onData(data: [String: Any]) {
        DispatchQueue.main.async {

            let sensorData = data["SensorData"] as! [String: Any]
//            if let ecg0 = sensorData["ECG0"] as? [Int] {
//                self.ecgPlot.plot(ecg0, at: 0)
//            }
            
            if let seq = sensorData["Seq"] as? UInt32 {
                print("Rx \(seq)")
            }
            
            // To identify if the data is Live or History, the order of sequence numbers is to be checked.
            // 1.When the app is started, set the prevSeq as TotalAvailSequence from the Broadcast only once.
            //2. When each data is received, check if current sequence is greater than prev sequence. If Yes, the data is live.
            //3. Give to plot only if the data is Live.
        
            let points = [30,100,500, 30,100,500, 30,100,500, 30,100,500, 30,100,500, 30,100,500, 30,100,500, 30,100,500, 30,100,500, 30,100,500, 30,100,500, 30,100,500, 30,100,500, 30,100,500, 30,100,500, 30,100,500, 30,100,500]
            self.ecgPlot.plot(points, at: 0)
        }
    }
    func onStatus(status: [String: Any]) {
        print("Status: \(status)")
        
        // All the TCP command status is obtained here. success, usage-err, socket-err are returned for th commands. If the streaming is started, and data is not received in 10 sec(which can be due to hotspot disconnection), then the status of command = "connection", "status" = "socket-timeout" is obtained every 10 sec.
        
    }
    
    func onConnectionStatusUpdate(isConnected: Bool) {
        if isConnected {
            print("Patch is Connected")
        } else {
            print("Patch lost connection")
        }
        
    }
}
