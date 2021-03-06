

# ExampleApp
Example App is for demonstrating the usage of LSPatch lib in an app. The code should be used only as a reference. If you want to build a project, copy the DataReceiverService.swift and UIDeviceExtension.swift to the new project and continue the development. 

# Xcode and Swift requirements
Requires Xcode 12.4 and Swift 5.3.2

# Installation
Download the source code, and just open the Xcode project and run on an iPhone or iPad.

# Description
The LSPatch lib version 1.1.0 is linked to the project. LSPatch lib is a biosensor - app communicator which will handle the UDP and TCP communications with the patch and parses the sensor data into a Dictionary with key value pairs. 

![Demo](Images/Screen.png)

The main classes in the Example App is given below:-

## DataReceiverService 
This acts as a wiring module which communicates with the LSPatch and app's layer. The class provides certain callbacks and helper methods for the easy communication with LSPatch lib. The user can either implement his own communication layer with the LSPatch by using this class as a reference OR he can directly edit this file to elaborate the usage. 

For details of LSPatch lib and the Biosensor, contact https://lifesignals.com/contact/

### onDiscovery
Whenever the biosensor broadcast information is received through LSPatch, this callback will get triggered. The broadcast information is available with the callback. The broadcast information is received every 3sec-3sec-12sec inteval.
### onData
Whenever the sensor data is received from the selected biosensor, this callback will get triggered. Any live data and history data is received through this callback. The user can differentiate a live data and history data with the help of sequence number of the sensor data and the "TotalAvailSequence" key present in the broadcast.
### onStatus
Whenever any tcp command is issued, the response is obtained and thiscallback will be triggered. The TCP commands are configure, start, commit, identify, requestData, stopAcq, turnOff. In addition to this, if the sensor data is not received for 10sec, then a socket timeout is received as status every 10sec.
### onConnectionStatusUpdate
The DataReceiverService identifies that a biosensor is out of range from the hotspot by checking whether the broadcast for the selected biosensor is not received in a 12 sec, and no sensor data is being received. Similarly it is assumed that the connection is regained when a broadcast is received or when data is started to receive. 

In addition to the above, the DataReceiverService also provides helper methods to initialize LSPatch, APIs to send various TCP commands to the biosensor. The DataReceiverService will also handle the redirecting of IP address in case the biosensor's streaming destination IP is a different one from the phone's IP. The phone's IP is obtained using a utility method present in UIdevice's extension class defined in the UIDeviceExtension.swift.

## SensorStatus
This is an enum which provides the methods to identify the sensor state - whether the biosensor is in Initial/ Streaming/ Configured/ Committed/ ProcedureCompleted.

## ViewControllers
### MainViewController
The usage of the LSpatch is demonstrated in this class. Each API call is demonstrated using button clicks. The user has to switch on the hotspot and get the patch connected before executing the commands.

To initialize the LSpatch and start scanning for biosensors:-

`DataReceiverService.shared.initializePatch()`

`DataReceiverService.shared.delegate = self`

User can select one biosensor ID from the discovered list.

`DataReceiverService.shared.select(patchId: patchId, brdCast: brdCast)`

The user can select a sensor life(how many minutes of procedure) and click Configure. 

`DataReceiverService.shared.configure(input: pLife)`

To start a biosensor streaming:-

`DataReceiverService.shared.start()`

To send a commit command to biosensor:-

`DataReceiverService.shared.commit()`
This will send the commit command with Short sync selected to the biosensor.

To stop acquisition:-

`DataReceiverService.shared.stopAcq()`

To turn off:-

`DataReceiverService.shared.turnOff(eraseFlash: Bool)`

If the parameter eraseFlash is "true", then the flash is erased in the biosensor.

To stop the all the patch communication from the app side:- 

`DataReceiverService.shared.finish()`

### Known Issues
The iOS has limitations in the background operation for UDP streaming. If the ExampleApp is put in background, the socket operations will get suspended.

### Contact Details
To get more details of the Biosensor and API documentation for the LSPatch lib, contact: https://lifesignals.com/


