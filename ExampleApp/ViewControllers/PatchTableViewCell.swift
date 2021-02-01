//
//  cellStructureHome.swift
//
//  Created by Gadgeon on 04/10/19.
//  Copyright © 2019 LifeSignals. All rights reserved.
//

import UIKit

class PatchTableViewCell: UITableViewCell {

    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var patchIdLabel: UILabel!
    
    func setData(){
        cellView.layer.cornerRadius = 15
        cellView.layer.borderWidth = 1
       // cellView.layer.borderColor = CGColor.
    }

}

