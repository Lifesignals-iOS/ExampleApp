//
//  UIDeviceExtension.swift
//  SPatch
//
//  Created by Lifesignals on 24/04/20.
//  Copyright © 2020 Lifesignals. All rights reserved.
//

import UIKit

extension UIDevice {

  
    func getIFAddresses(patchIP: String) -> String? {
        var address : String?
            
        let arr = patchIP.components(separatedBy: ".")

        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }

        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee

            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            //if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {  // **ipv6 committed
            if addrFamily == UInt8(AF_INET){
                // Convert interface address to a human readable string:
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST)
               address = String(cString: hostname)
                    if address!.contains(arr[0]) {
                        break
                    }
            }
        }
        freeifaddrs(ifaddr)

        return address
    }
}



extension UIColor {
    static let phoenixBlue: UIColor = UIColor(red: 41/225, green: 98/255, blue: 156/255, alpha: 1)
    static let phoenixLightGray: UIColor = UIColor(red: 219/255, green: 219/255, blue: 219/255, alpha: 1)
}

