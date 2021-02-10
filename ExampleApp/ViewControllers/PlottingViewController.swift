//
//  PlottingViewController.swift
//
//  Created by Gadgeon on 08/11/19.
//  Copyright © 2019 LifeSignals. All rights reserved.
//

import UIKit

class PlottingViewController: UIViewController {
    @IBOutlet weak var bottomStackView: UIStackView!
    @IBOutlet weak var ecgPlot2: LineChart!
    @IBOutlet weak var plotScrollView: UIScrollView!
    @IBOutlet weak var lineChartHeightConstraint: NSLayoutConstraint!
   
    @IBOutlet weak var lblAppVersion: UILabel!
    @IBOutlet weak var lblLibVersion: UILabel!
    
    @IBOutlet weak var bottomStackHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    let PLOT_HEIGHT: Int32 = 500
    
    

    var lineColors = [UIColor.blue, UIColor.green, UIColor.yellow, UIColor.red, UIColor.orange, UIColor.magenta, UIColor.purple]

    override func viewDidLoad() {
        super.viewDidLoad()
        let menu = UIBarButtonItem(title: "Menu", style: .plain, target: self, action: #selector(menuTapped))

        navigationItem.rightBarButtonItems = [menu]
        
        DataReceiverService.shared.delegate = self
        
        initializePlots()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
        self.getVersions()
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidDisappear(true)
    }
    
    @objc func menuTapped() {
        let alert = UIAlertController(title: "Command", message: "", preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Identify", style: .default , handler:{ (UIAlertAction)in
               
                DataReceiverService.shared.identifyPatch()
            }))
        alert.addAction(UIAlertAction(title: "Start", style: .default , handler:{ (UIAlertAction)in
           
            DataReceiverService.shared.start()
        }))
        
        alert.addAction(UIAlertAction(title: "Commit", style: .default , handler:{ (UIAlertAction)in
           
            DataReceiverService.shared.commit()
        }))
        
        alert.addAction(UIAlertAction(title: "StopAcq", style: .default , handler:{ (UIAlertAction)in
           
            DataReceiverService.shared.stopAcq()
        }))
        alert.addAction(UIAlertAction(title: "Turn off", style: .default , handler:{ (UIAlertAction)in
           
            DataReceiverService.shared.turnOff(eraseFlash: true)
        }))
        alert.addAction(UIAlertAction(title: "Finish", style: .default , handler:{ (UIAlertAction)in
            DataReceiverService.shared.finish()
        }))
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default , handler:{ (UIAlertAction)in
        }))
       
        
        alert.popoverPresentationController?.sourceView = self.view // works for both iPhone & iPad

            present(alert, animated: true) {
                print("option menu presented")
            }
                
    }
    
    private func getVersions() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        self.lblAppVersion.text = "App v" + appVersion + "   |"
        self.lblLibVersion.text = "Lib v" + DataReceiverService.shared.getLibVersion()
    }

    
    @IBAction func Start(_ sender: Any) {
        DataReceiverService.shared.start()

    }
    @IBAction func Cancel(_ sender: Any) {
        DataReceiverService.shared.commit()
    }
    
    func initializePlots() {
            if self.ecgPlot2.chartTransform.count == 0 {
                self.ecgPlot2.chartTransform.append(CGAffineTransform())
                self.ecgPlot2.chartTransform.append(CGAffineTransform())
                self.ecgPlot2.chartTransform.append(CGAffineTransform())
                self.ecgPlot2.addPlot(yCenter: 250, height: self.PLOT_HEIGHT, yValuePerPixel: 0.3, spacing: 512, graphColor: UIColor.green.cgColor, plotView: self)
                self.ecgPlot2.addPlot(yCenter: 750, height: self.PLOT_HEIGHT, yValuePerPixel: 0.3, spacing: 512, graphColor: UIColor.blue.cgColor, plotView: self)
                self.ecgPlot2.addPlot(yCenter: 1250, height: self.PLOT_HEIGHT, yValuePerPixel: 0.05, spacing: 8192, graphColor: UIColor.cyan.cgColor, plotView: self)
                self.lineChartHeightConstraint.constant = CGFloat(1500)
            }
        
    }
}
extension PlottingViewController : LSPatchManagerDelegate {
    
    func onDiscovery(bcast: [String : Any]) {
        let capability = bcast["Capability"] as! [String: Any]
        let patchStatus = capability["PatchStatus"] as? UInt16 ?? 0
        if SensorStatus.isProcComplete(status: patchStatus) {
            DispatchQueue.main.async {
                self.statusLabel.text = "Procedure completed"
            }
        }
    }
    
    func onConnectionStatusUpdate(isConnected: Bool) {
        if(!isConnected){
            DispatchQueue.main.async {
                self.statusLabel.text = "\(DataReceiverService.shared.selectedPatchID) Disconnected"
            }
        }else{
        }
    }
    
    func onStatus(status: [String : Any]) {
        let cmd = status["command"] as? String
        let error = status["value"] as! String
        
        if error == "success" || error == "usage-err" {
            if(cmd == "commit"){
                DispatchQueue.main.async {
                    self.statusLabel.text = "Commit is \(error)"
                }
            }else if(cmd == "start"){
                DispatchQueue.main.async {
                    self.statusLabel.text = "Start is \(error)"
                }
            }else if(cmd == "turn-off"){
                DispatchQueue.main.async {
                    self.statusLabel.text = "Turn off is \(error)"
                }
            }else if(cmd == "stop"){
                DispatchQueue.main.async {
                    self.statusLabel.text = "Stop is \(error)"
                }
            }
        } else {
            if(cmd == "commit"){
                DispatchQueue.main.async {
                    self.statusLabel.text = "Commit Failed. Try Again."
                }
            }
            else if(cmd == "start"){
                DispatchQueue.main.async {
                    self.statusLabel.text = "Start failed. Try Again."
                }
            }
            else if(cmd == "turn-off"){
                DispatchQueue.main.async {
                    self.statusLabel.text = "Turn off failed. Try Again."
                }
            }else if(cmd == "stop"){
                DispatchQueue.main.async {
                    self.statusLabel.text = "Stop failed. Try Again."
                }
            }
        }
    }
    
    func onData(data: [String : Any]) {
        DispatchQueue.main.async {
            
            let sensorData = data["SensorData"] as! [String: Any]
            let ecg0 = sensorData["ECG0"] as! [Int]
            let ecg1 = sensorData["ECG1"] as! [Int]

            self.ecgPlot2.plot(ecg0, at: 0)
            self.ecgPlot2.plot(ecg1, at: 1)

            self.ecgPlot2.runTimer()
            
        }
    }
}
