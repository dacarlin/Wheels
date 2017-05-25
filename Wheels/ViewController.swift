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

    // array of recordings
    var animals = [String]()
    var timer: Timer!


    func updateAudioMeter(_ timer:Timer) {

        if audioRecorder.isRecording {
            let hour = Int(audioRecorder.currentTime / 360)
            let min = Int(audioRecorder.currentTime / 60)
            let sec = Int(audioRecorder.currentTime.truncatingRemainder(dividingBy: 60))
            let s = String(format: "%02d:%02d:%02d", hour, min, sec)
            timestamp.text = s
            audioRecorder.updateMeters()
            // if you want to draw some graphics...
            var apc0 = audioRecorder.averagePower(forChannel:0)
            print(apc0)
            var peak0 = audioRecorder.peakPower(forChannel:0)
            print(peak0)
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Register the table view cell class and its reuse id
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)

        // This view controller itself will provide the delegate methods and row data for the table view.
        tableView.delegate = self
        tableView.dataSource = self

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
            }


        } catch let error as NSError {
            print(error.localizedDescription)
        }


        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioRecorder = AVAudioRecorder(url: directoryURL()!,
                                                settings: recordSettings)
            audioRecorder.isMeteringEnabled = true
            audioRecorder.prepareToRecord()
        } catch {}
    }

    var audioRecorder:AVAudioRecorder!

    let recordSettings = [
        AVSampleRateKey : NSNumber(value: Float(44100.0)),
        AVFormatIDKey : NSNumber(value:Int32(kAudioFormatMPEG4AAC)),
        AVNumberOfChannelsKey : NSNumber(value: Int32(1)),
        AVEncoderAudioQualityKey :
            NSNumber(value: Int32(AVAudioQuality.medium.rawValue))]


    func directoryURL() -> URL? {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as URL

        let format = DateFormatter()
        format.dateFormat="yyyy-MM-dd-HH-mm-ss"
        let currentFileName = "recording-\(format.string(from: Date())).m4a"
        print(currentFileName)

        let soundURL = documentDirectory.appendingPathComponent(currentFileName)
        return soundURL
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

    @IBAction func doStopAction(_ sender:
        AnyObject) {
        print("Stop recording")
        audioRecorder.stop()
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false)
        } catch {}
    }

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
