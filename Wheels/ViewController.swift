//
//  ViewController.swift
//  Wheels
//
//  Created by Alex Carlin on 5/23/17.
//  Copyright © 2017 Alex Carlin. All rights reserved.
//

import UIKit
import AVFoundation



class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Register the table view cell class and its reuse id
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)

        self.update_tape_view()
        self.init_audio()

    }
    

    func init_audio() {
        // function for initializing audio
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioRecorder = AVAudioRecorder(url: directoryURL()!,
                                                settings: recordSettings)
            audioRecorder.isMeteringEnabled = true
            audioRecorder.prepareToRecord()
        } catch {}
    }
    
    
    
    // 2 utility functions for accessing the "tapes"
    // as URL from the disk
    
    func update_tape_view() {
        // get the "data" (the list of files) for the table
        // Get the document directory url
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: [])
            print(directoryContents)
            
            let my_files = directoryContents.flatMap({$0.lastPathComponent})
            for fn in my_files {
                animals.append(fn)
                
                // right now, it has a side effect! 
                // change to return this animals list
            }
            
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }


    func directoryURL() -> URL? {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as URL

        let format = DateFormatter()
        format.dateFormat="yyyy-MM-dd, HH:mm:ss"
        let currentFileName = "Tape \(format.string(from: Date())).m4a"
        print(currentFileName)

        let soundURL = documentDirectory.appendingPathComponent(currentFileName)
        return soundURL
    }
    
    
    
    
    
    
    
    
    
    // tape recorder interface
    
    var audioRecorder:AVAudioRecorder!
    
    let recordSettings = [
        AVSampleRateKey : NSNumber(value: Float(44100.0)),
        AVFormatIDKey : NSNumber(value:Int32(kAudioFormatMPEG4AAC)),
        AVNumberOfChannelsKey : NSNumber(value: Int32(1)),
        AVEncoderAudioQualityKey :
            NSNumber(value: Int32(AVAudioQuality.medium.rawValue))]
    
    // array of recordings
    var animals = [String]()
    var timer: Timer!
    
    @IBOutlet var levelBar: UIView!
    
    func updateAudioMeter(_ timer:Timer) {
        
        if audioRecorder.isRecording {
            let hour = Int(audioRecorder.currentTime / 360)
            let min = Int(audioRecorder.currentTime / 60)
            let sec = Int(audioRecorder.currentTime.truncatingRemainder(dividingBy: 60))
            let s = String(format: "%02d:%02d:%02d", hour, min, sec)
            timestamp.text = s
            audioRecorder.updateMeters()
            // if you want to draw some graphics...
            let apc0 = audioRecorder.averagePower(forChannel:0)
            print(apc0)
            let peak0 = audioRecorder.peakPower(forChannel:0)
            print(peak0)
        }
    }
    
    


    @IBOutlet var timestamp: UILabel!

    @IBOutlet weak var recordButton: UIButton!

    @IBAction func doRecordAction(_ sender: AnyObject) {
        print("Begin recording")
        if !audioRecorder.isRecording {
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setActive(true)
                audioRecorder.record()
                self.timer = Timer.scheduledTimer(timeInterval: 0.1,
                                                       target:self,
                                                       selector:#selector(updateAudioMeter(_:)),
                                                       userInfo:nil,
                                                       repeats:true)
            } catch {}
        }
    }

    
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var playButton: UIButton!

    @IBAction func doStopAction(_ sender: Any) {
        // function to run when "Stop" is pressed
        print("Stop was pressed")
        audioRecorder.stop()
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false)
        } catch {
            // there was an error relinquishing the audio session
        }
    }
    
    @IBAction func doPlayAction(_ sender: Any) {
        // function to run when "Play" is pressed
    }
    
    
    
    
    
    
    
    
    
    
    // tape deck / stack interface

    // cell reuse id (cells that scroll out of view can be reused)
    let cellReuseIdentifier = "cell"

    // don't forget to hook this up from the storyboard
    @IBOutlet var tableView: UITableView!

    // number of rows in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.animals.count
    }

    // create a cell for each table view row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // create a new cell if needed or reuse an old one
        let cell:UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as UITableViewCell!

        // set the text from the data model
        cell.textLabel?.text = self.animals[indexPath.row]
        return cell
    }

    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You tapped cell number \(indexPath.row).")
    }

    // this method handles row deletion
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {

            // remove the item from the data model
            animals.remove(at: indexPath.row)

            // delete the table view row
            tableView.deleteRows(at: [indexPath], with: .fade)

        } else if editingStyle == .insert {
            // Not used in our example, but if you were adding a new row, this is where you would do it.
        }
    }

}
