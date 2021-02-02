//
//  ConfigureViewController.swift
//
//  Created by Reshmi KV on 05/01/21.
//  Copyright © 2021 LifeSignals. All rights reserved.
//

import UIKit

class ConfigureViewController: UIViewController ,UITextFieldDelegate{

    @IBOutlet weak var patchLifeTextField: UITextField!
    @IBOutlet weak var patchConnStatusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
        LSPatchManager.shared.delegate = self
        
        self.onConnectionStatusUpdate(isConnected: LSPatchManager.shared.isConnected)
        
        let menu = UIBarButtonItem(title: "Menu", style: .plain, target: self, action: #selector(menuTapped))

        navigationItem.rightBarButtonItems = [menu]
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        patchLifeTextField.resignFirstResponder()
    }

    @IBAction func configureTapped(_ sender: Any) {
        let pLife = UInt16(patchLifeTextField.text!) ?? 15
        LSPatchManager.shared.configurePatch(input: pLife)
    }
    
    @objc func menuTapped() {
        let alert = UIAlertController(title: "Command", message: "", preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Identify", style: .default , handler:{ (UIAlertAction)in
               
                LSPatchManager.shared.identifyPatch()
            }))
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default , handler:{ (UIAlertAction)in
           
        }))

            self.present(alert, animated: true, completion: nil)
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
           self.view.endEditing(true)
           return false
       }
}
extension ConfigureViewController: LSPatchManagerDelegate {
   
    func onStatus(status: [String: Any]) {
        let cmd = status["command"] as! String
        let error = status["value"] as! String
        
        if cmd == "configure" {
            
            if error == "success" || error == "usage-err" {
                // navigate to plotting screen.
                DispatchQueue.main.async {
                    
                    if error == "usage-err" { // already configured.
                        let alert = UIAlertController(title: "Already configured", message: "", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .default , handler:{ (UIAlertAction)in
                            let viewController: UIViewController? = self.storyboard?.instantiateViewController(withIdentifier: "PlotViewController")
                            self.navigationController?.pushViewController(viewController!, animated: true)
                        }))
                        self.present(alert, animated: true, completion: nil)
                    } else { // first time configure
                        let viewController: UIViewController? = self.storyboard?.instantiateViewController(withIdentifier: "PlotViewController")
                        self.navigationController?.pushViewController(viewController!, animated: true)
                    }
                }
                
            } else {
                DispatchQueue.main.async {
                    self.patchConnStatusLabel.text = "Configure Failed. Try Again"
                }
            }
        }
        
    }
    func onConnectionStatusUpdate(isConnected: Bool) {
        if isConnected {
            DispatchQueue.main.async {
                self.patchConnStatusLabel.text = "\(LSPatchManager.shared.selectedPatchID) Connected"
            }
        } else {
            DispatchQueue.main.async {
                self.patchConnStatusLabel.text = "\(LSPatchManager.shared.selectedPatchID) Disconnected"
            }
        }
    }
}
