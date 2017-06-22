//
//  ViewController.swift
//  Wheels
//
//  Created by Alex Carlin on 5/23/17.
//  Copyright © 2017 Alex Carlin. All rights reserved.
//

import UIKit
import AVFoundation

class Tape {
    // class to hold tape metadata 
    
    var url: URL!
    var name: String!
    var duration: String! // ("43 seconds")
    
    init(url: URL) {
        // create a tape from a URL
        self.url = url
        self.name = url.lastPathComponent
        self.duration = "43 seconds"
    }
}

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
    
    
    /////////////////////////////////////////////////////
    // 2 utility functions for accessing the "tapes"
    // as URL from the disk
    /////////////////////////////////////////////////////
    
    func directoryURL() -> URL? {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as URL
        
        let format = DateFormatter()
        format.dateFormat="yyyy-MM-dd HH:mm:ss"
        let currentFileName = "Tape \(format.string(from: Date())).m4a"
        
        let soundURL = documentDirectory.appendingPathComponent(currentFileName)
        return soundURL
    }
    
    func init_audio() {
        // function for initializing audio
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioRecorder = AVAudioRecorder(url: directoryURL()!, settings: recordSettings)
            audioRecorder.isMeteringEnabled = true
            audioRecorder.prepareToRecord()
        } catch {
            // Error initializing audio
        }
    }
    
    var tapes = [Tape]()
    func update_tape_view() {
        // get the "data" (the list of files) for the table
        // Get the document directory url
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: [])
            for url in directoryContents {
                tape_list.append(url)
            }
            for url in directoryContents {
                let my_tape = Tape(url: url)
                tapes.append(my_tape)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }

    
    
    //////////////////////////////////
    //// tape recorder interface
    //////////////////////////////////
    
    let recordSettings = [
        AVSampleRateKey: NSNumber(value: Float(44100.0)),
        AVFormatIDKey: NSNumber(value:Int32(kAudioFormatMPEG4AAC)),
        AVNumberOfChannelsKey: NSNumber(value: Int32(1)),
        AVEncoderAudioQualityKey: NSNumber(value: Int32(AVAudioQuality.medium.rawValue))
    ]
    
    var timer: Timer!
    var audioRecorder:AVAudioRecorder!
    @IBOutlet weak var levelBar: UIProgressView!
    @IBOutlet weak var loadedLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet var timestamp: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    
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
            levelBar.setProgress((apc0+60)/100, animated: true)
        }
    }

    @IBAction func doRecordAction(_ sender: AnyObject) {
        print("Begin recording")
        if !audioRecorder.isRecording {
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setActive(true)
                audioRecorder.record()
                self.timer = Timer.scheduledTimer(timeInterval: 0.1,target:self,selector:#selector(updateAudioMeter(_:)),userInfo:nil,repeats:true)
            } catch {
                print("Error in recordin")
            }
        }
    }

    @IBAction func doStopAction(_ sender: Any) {
        // function to run when "Stop" is pressed
        print("Stop was pressed")
        audioRecorder.stop()
        player.stop()
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false)
        } catch {
            // there was an error relinquishing the audio session
        }
        self.update_tape_view()
    }
    
    var player = AVAudioPlayer()
    @IBAction func doPlayAction(_ sender: Any) {
        // function to run when "Play" is pressed
        
        if let tape = self.loaded_tape {
            // if a tape has been loaded 
            // play that tape
            
            print(tape.url)
            
            
            do {
                try player = AVAudioPlayer(contentsOf: tape.url)
                print(player)
                player.play()
            } catch {
                print("ERROR")
            }
        }
    }
    
    
    ////////////////////////////////////
    //// tape stack interface
    ////////////////////////////////////
    
    var animals = [String]()
    var tape_list = [URL]() // empty list of URL which we will use to keep tapes
    
    let cellReuseIdentifier = "cell"
    @IBOutlet var tableView: UITableView!

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // length of table view
        return self.tape_list.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // create a new cell if needed or reuse an old one
        // set the text from the data model
        let cell:UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as UITableViewCell!
        cell.textLabel?.text = self.tapes[indexPath.row].name
        return cell
    }
    
    var tp: URL!
    var loaded_tape: Tape!
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // method to run when table view cell is tapped
        self.loaded_tape = tapes[indexPath.row]
        loadedLabel.text = self.loaded_tape.name
        durationLabel.text = self.loaded_tape.duration
        print("You tapped cell number \(indexPath.row).")
        print("Tape tapped:", self.loaded_tape.name)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {

            // remove the item from the data model
            //tape_list.remove(at: indexPath.row)

            // delete the table view row
            //tableView.deleteRows(at: [indexPath], with: .fade)

        } else if editingStyle == .insert {
            // Not used in our example, but if you were adding a new row, this is where you would do it.
        }
    }

}
