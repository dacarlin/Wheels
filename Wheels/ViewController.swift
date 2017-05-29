//
//  ViewController.swift
//  Wheels
//
//  Created by Alex Carlin on 5/23/17.
//  Copyright © 2017 Alex Carlin. All rights reserved.
//

import UIKit
import AVFoundation

class tape_recorder {
    func load(tape: String) {
        print("Loading", tape)
    }
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // create a tape recorder
    let tp = tape_recorder()

    // array of recordings
    var tapes = [String]()

    // this is used during recording
    var timer: Timer !

    // timestamp on recording (and meters)
    @IBOutlet var timestamp: UILabel !

    var audioRecorder: AVAudioRecorder !

    let recordSettings = [
        AVSampleRateKey: NSNumber(value: Float(44100.0)),
        AVFormatIDKey: NSNumber(value:Int32(kAudioFormatMPEG4AAC)),
        AVNumberOfChannelsKey: NSNumber(value: Int32(1)),
        AVEncoderAudioQualityKey: NSNumber(value: Int32(AVAudioQuality.medium.rawValue))
    ]

    func updateAudioMeter(_ timer: Timer) {
        if audioRecorder.isRecording {
            let hour = Int(audioRecorder.currentTime / 360)
            let min = Int(audioRecorder.currentTime / 60)
            let sec = Int(audioRecorder.currentTime.truncatingRemainder(dividingBy: 60))
            let s = String(format: "%02d:%02d:%02d", hour, min, sec)
            timestamp.text = s
            audioRecorder.updateMeters()
            let avg = audioRecorder.averagePower(forChannel:0)
            print(avg)
            let peak = audioRecorder.peakPower(forChannel:0)
            print(Int(peak))
            level0.text = String(format:"%f", avg)
            level1.text = String(format:"%f", peak)
            level_bar.setProgress(1-(peak * -(1/160)), animated:false)
            average_bar.setProgress(1-(avg * -(1/120)), animated:false)
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
                tapes.append(fn)
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


    // record button and action
    @IBOutlet weak var recordButton: UIButton!

    @IBAction func doRecordAction(_ sender: AnyObject) {
        print("Begin recording")
        if !audioRecorder.isRecording {
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setActive(true)
                audioRecorder.record()
                self.timer = Timer.scheduledTimer(timeInterval: 0.1,target:self,selector:#selector(updateAudioMeter(_:)),userInfo:nil,repeats:true)
            } catch {
              // what to do here?
            }
        }
    }

    // stop button
    @IBOutlet weak var stopButton: UIButton!

    @IBAction func doStopAction(_ sender:
        AnyObject) {
        print("Stop recording")
        if audioRecorder.isRecording {
          audioRecorder.stop()
          // save the tape!
          let audioSession = AVAudioSession.sharedInstance()
          do {
              try audioSession.setActive(false)
          } catch {}
          // no idea what the above 4 lines do
        }
    }

    // table view
    
    // cell reuse id (cells that scroll out of view can be reused)
    let cellReuseIdentifier = "cell"

    // don't forget to hook this up from the storyboard
    @IBOutlet var tableView: UITableView!

    // number of rows in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tapes.count
    }

    // create a cell for each table view row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // create a new cell if needed or reuse an old one
        let cell:UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as UITableViewCell!

        // set the text from the data model
        cell.textLabel?.text = self.tapes[indexPath.row]
        return cell
    }

    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You tapped cell number \(indexPath.row).")
        // get the tape in this cell
        // self.tapes[indexPath.row]
        print(indexPath.row)
        print(self.tapes)
        print(self.tapes[indexPath.row])
        let tapped_tape = self.tapes[indexPath.row]
        print( tapped_tape )
        // load this tape
        tp.load(tape:tapped_tape)
    }

    // this method handles row deletion
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // remove the item from the data model
            tapes.remove(at: indexPath.row)
            // delete the table view row
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Not used in our example, but if you were adding a new row, this is where you would do it.
        }
    }

    // meters
    @IBOutlet weak var level0: UILabel!
    @IBOutlet weak var level1: UILabel!
    @IBOutlet weak var level_bar: UIProgressView!
    @IBOutlet weak var average_bar: UIProgressView!

    // tape playback interface
    @IBOutlet weak var play: UIButton!
    @IBAction func doPlay(_ sender: UIButton) {
        print("Play was pressed")
    }


}
