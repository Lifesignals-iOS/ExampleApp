//
//  MainViewController.swift
//
//  Created by Gadgeon on 01/10/19.
//  Copyright © 2019 LifeSignals. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lblAppVersion: UILabel!
    @IBOutlet weak var lblLibVersion: UILabel!


    var patchIds: [String] = []
    var discoveryObj:[[String: Any]] = []

    

    override func viewDidLoad() {
        super.viewDidLoad()
        // update xib inside topView
       
        self.tableView.delegate = self
        self.tableView.dataSource = self

        LSPatchManager.shared.initializePatch()
        LSPatchManager.shared.delegate = self
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
        self.getVersions()
    }
    
    
    private func getVersions() {
        self.lblAppVersion.text = "App v" + DataManager.getAppVersion() + "   |"
        self.lblLibVersion.text = "Lib v" + DataManager.lsPatchLibVersion()
    }
    

}
extension HomeViewController: UITableViewDataSource, UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return patchIds.count 
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if patchIds.count > 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: "patchID") as! PatchTableViewCell
            cell.setData()
            cell.patchIdLabel.text = patchIds[indexPath.row]
            cell.patchIdLabel.textColor = .blue
            cell.patchIdLabel.textAlignment = .center
            cell.patchIdLabel.font = UIFont.systemFont(ofSize: 20.0)
            return cell
        }
        
        return UITableViewCell()
    }

        //MARK -- Tableview Delegate Methods
        
         func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            // In order to fadeaway the selection in grey clour after user select a particular row.
            tableView.deselectRow(at: indexPath, animated: true)
            let patchId: String? = patchIds[indexPath.row]
            let brdCast =  discoveryObj[indexPath.row]
                LSPatchManager.shared.select(patchId: patchId!, brdCast: brdCast)
                
            let viewController: UIViewController? = self.storyboard?.instantiateViewController(withIdentifier: "ConfigureViewController")
                
            self.navigationController?.pushViewController(viewController!, animated: true)
            }
        }

extension HomeViewController: LSPatchManagerDelegate {
    
    func onDiscovery(bcast: [String : Any]) {
        DispatchQueue.main.async {
            if let patchInfo = bcast["PatchInfo"] as? [String: Any], let patchId = patchInfo["PatchId"] as? String {
                if !self.patchIds.contains(patchId){
                    self.patchIds.append(patchId)
                    self.discoveryObj.append(bcast)
                }
                if let row = self.patchIds.firstIndex(where: {$0 == patchId}) {
                    self.discoveryObj[row] = bcast
                }
                self.tableView.reloadData()
            }
        }
    }
}
