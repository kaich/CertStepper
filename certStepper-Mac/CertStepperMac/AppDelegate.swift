//
//  AppDelegate.swift
//  CertStepperMac
//
//  Created by mac on 15/5/29.
//  Copyright (c) 2015年 kaicheng. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
   
    var statusItem: NSStatusItem!
    var task: NSTask!
    var filePath: NSString?

    @IBAction func getHelp(sender: AnyObject) {
        
        
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        self.filePath = NSUserDefaults.standardUserDefaults().objectForKey("CertsFilePath") as? NSString
        self.activateStatusMenu();
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


    func activateStatusMenu()
    {
        let bar = NSStatusBar.systemStatusBar();
        self.statusItem = bar.statusItemWithLength(-1.0);
        self.statusItem.image = NSImage(named: "icon_wait");
        
        //create menu
        let menu = NSMenu();
        //create menu item
        let chooseFileItem = NSMenuItem(title: "Choose File", action:Selector("chooseFile"), keyEquivalent:"choose file");
        let startStepItem = NSMenuItem(title: "Start", action:Selector("startStep"), keyEquivalent:"start step");
        let nextStepItem = NSMenuItem(title: "Next Step", action:Selector("nextStep"), keyEquivalent: "next step");
        
        menu.addItem(nextStepItem)
        menu.addItem(startStepItem)
        menu.addItem(chooseFileItem)
        
        self.statusItem.menu = menu;
        
    }
    
    func startStep()
    {
        self.statusItem.image = NSImage(named: "icon_running")
        let taskQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_async(taskQueue, { () -> Void in
            let output = self.executeCommand("/usr/bin/certstepper",args: [self.filePath! as String]);
            self.statusItem.image = NSImage(named: "icon_wait");
        });
    }
    
    func nextStep()
    {
        var data = "\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        self.task.standardInput.fileHandleForWriting.writeData(data!)
    }
    
    func chooseFile()
    {
        let  openPannel = NSOpenPanel()
        openPannel.runModal();
        self.filePath = openPannel.URL?.path
        self.filePath = self.filePath == nil ?  "~/Desktop/CertDirectory/Certs" : self.filePath
        NSUserDefaults.standardUserDefaults() .setObject(self.filePath, forKey: "CertsFilePath")
    }
    
    func executeCommand(command: String, args: [String]) -> String {
        
        self.task = NSTask()
        
        self.task.launchPath = command
        self.task.arguments = args
        
        let pipe = NSPipe()
        let inPipe = NSPipe()
        self.task.standardOutput = pipe
        self.task.standardInput = inPipe;
        self.task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
        
        return output
        
    }
}

