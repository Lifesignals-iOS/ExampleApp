# ExampleApp
Example App for demonstrating the usage of LSPatch lib in an app

# Xcode and Swift requirements
Requires Xcode 12.3 and Swift 5.3.2

# Installation
Download the source code, and just open the Xcode project and run.

# Description
The LSPatch lib version 1.0.5 is linked to the project. The main classes in the Example App is given below:-

## LSPatchManager 
This acts as a wiring module which communicates with the LSPatch and app's layer. The class provides callbacks:-

### onDiscovery
Whenever the patch broadcast information is received, this will be called.
### onData
Whenever the sensor data is received from the selected sensor, this will be called.
### onStatus
Whenever any tcp command is issued, the response is obtained and this will be called. The TCP commands are configure, start, commit, identify, requestData, stopAcq, turnOff. In addition to this, if the sensor data is not received for 10sec, then a "connection" "socket-timeout". 
### onConnectionStatusUpdate
The LSPatchManager identifies that a patch is lost or out of range by checking whether the broadcast for the selected patch is not received in a 12 sec, and no sensor data is being received. Similarly it is assumed that the connection is regained when a broadcast is received or when data is started to receive. 

In addition to the above, the LSPatchManager also provides helper methods to initialize LSPatch, and methods to send the TCP commands. The LSPatchManager will call redirect command to the patch in case the IP address to which the patch is streaming is changed. This is done by getting the IP address with an extension method defined in the UIDeviceExtension.swift

## SensorStatus
This is an enum which provides the methods to identify the sensor state - whether the patch is in Initial/Streaming/Configured/Committed/ProcedureCompleted.

## ViewControllers
### HomeViewController
Intiializes the LSPatch and displays the patchIds extracted from the broadcast datas received. 
`LSPatchManager.shared.initializePatch()`

`LSPatchManager.shared.delegate = self`

User can select one patch ID from the list.

`LSPatchManager.shared.select(patchId: patchId, brdCast: brdCast)`

### ConfigureViewController
The user can select a patch life(how many minutes of procedure) and click Configure. 

`LSPatchManager.shared.configure(input: pLife)`

### PlottingViewController
The user can select different commands from the Menu. The response of different commands will be available as status on the screen. 

To start a patch streaming:-

`LSPatchManager.shared.start()`

To commit a patch:-

`LSPatchManager.shared.commit()`

To stop acquisition:-

`LSPatchManager.shared.stopAcq()`

To turn off the patch:-

`LSPatchManager.shared.turnOff()`

To stop the all the patch communication:- 

`LSPatchManager.shared.finish()`




