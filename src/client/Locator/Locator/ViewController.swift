//
//  ViewController.swift
//  Locator
//
//  Created by Allen Casey on 10/9/21.
//

import UIKit
import CocoaMQTT


class ViewController: UIViewController {
    
    var mqtt: CocoaMQTT!
    
    var start: DispatchTime?
    var end: DispatchTime?
    
    var computationLocation = "edge"
    var computationType = "original"
    var benchmark1000 = false
    
    var messageRTTs = [Double]()
    
    @IBOutlet weak var valueOneText: UITextField!
    @IBOutlet weak var valueTwoText: UITextField!
    @IBOutlet weak var valueThreeText: UITextField!
    @IBOutlet weak var valueFourText: UITextField!
    
    @IBOutlet weak var segmentedLocation: UISegmentedControl!
    @IBOutlet weak var segmentedType: UISegmentedControl!
    @IBOutlet weak var segmentedMsgNumber: UISegmentedControl!
    
    @IBOutlet weak var resultTextField: UITextView!
    @IBOutlet weak var roundTripTextField: UITextView!
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didActivate), name: UIScene.didActivateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIScene.didEnterBackgroundNotification, object: nil)

        setUpMQTT()

        mqtt.delegate = self
    }
    
    @IBAction func selectComputationLocation(_ sender: Any) {
        switch segmentedLocation.selectedSegmentIndex
            {
            case 0:
            computationLocation = "edge"
            case 1:
            computationLocation = "cloud"
            default:
                break
            }
    }
    
    @IBAction func selectComputationType(_ sender: Any) {
        switch segmentedType.selectedSegmentIndex
            {
            case 0:
            computationType = "original"
            case 1:
            computationType = "ml"
            default:
                break
            }
    }
    
    @IBAction func selectNumberMsgsSent(_ sender: Any) {
        switch segmentedMsgNumber.selectedSegmentIndex
            {
            case 0:
            benchmark1000 = false
            case 1:
            benchmark1000 = true
            default:
                break
            }
    }
    
    @IBAction func sendButton(_ sender: UIButton) {
        
        var val1: Int? = Int(valueOneText.text!)
        var val2: Int? = Int(valueTwoText.text!)
        var val3: Int? = Int(valueThreeText.text!)
        var val4: Int? = Int(valueFourText.text!)
        
        if (benchmark1000 == true) {
            
            for _ in 0..<1000 {
                
                val1! += 1
                val2! += 1
                val3! += 1
                val4! += 1
                
                let data = buildJSONMessage(val1: val1!, val2: val2!, val3: val3!, val4: val4!)
                let dataString = String(data: data, encoding: String.Encoding.utf8)
                print(dataString!)

                // 'sleep' so we send messages once a second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.start = DispatchTime.now()
                    self.mqtt.publish("/values", withString: dataString!)
                }
            }
            
            let rttSum = messageRTTs.reduce(0, +)
            let rttAverage = Double(rttSum) / 1000.0
            resultTextField.text = "Benchmark done."
            roundTripTextField.text = String("Average RTT: \(rttAverage) ms")
        }
        else {
            let data = buildJSONMessage(val1: val1!, val2: val2!, val3: val3!, val4: val4!)
            let dataString = String(data: data, encoding: String.Encoding.utf8)
            print(dataString!)
            
            start = DispatchTime.now()
            mqtt.publish("/values", withString: dataString!)
        }
    }
    
    
    //Remove observer notification
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIScene.didActivateNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIScene.didEnterBackgroundNotification, object: nil)
    }
    
    //Notification, when the App is activated, I restore the connection with Mqtt broker
    @objc func didActivate(){
        let _: Bool = mqtt.connect()
    }
    
    //Notification, when the App enters in background, I disconnect the mqtt Object
    @objc func didEnterBackground(){
        mqtt.disconnect()
    }
    
    func buildJSONMessage(val1: Int, val2: Int, val3: Int, val4: Int) -> Data {
        
        let json: [String : Any] = ["val1" : val1, "val2": val2, "val3": val3, "val4": val4, "location": computationLocation, "type": computationType]
        let data = try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        
        return data
    }

    //Setup mqtt client
    func setUpMQTT() {
        var connected:Bool = false
        
        // Definition of the client Identificator
        let clientID = "CocoaMQTT-" + String(ProcessInfo().processIdentifier)

        // Definition of mqtt broker connection
        mqtt = CocoaMQTT(clientID: clientID, host: "172.23.55.240", port: 1883)

        // Definition of will message topic and connection
        mqtt.willMessage = CocoaMQTTWill(topic: "/result", message: "dieout")
        mqtt.keepAlive = 60
        connected = mqtt.connect()
        
        if connected{
            print("Connected to the broker")
        }
        else{
            print("Not connected to the broker")
        }
    }
}

extension ViewController: CocoaMQTTDelegate {
    
    //1. Connection with Broker, time to subscribe to a topic
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        mqtt.subscribe("/result")
        
    }		

    //2. Reception of mqtt message in the topic "/sensors/temperature"
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ){
        
        end = DispatchTime.now()
        let elapsed = end!.uptimeNanoseconds - start!.uptimeNanoseconds
        let timeInterval = Double(elapsed) / 1_000_000
        messageRTTs.append(timeInterval)
        
        print(message.string!)
        resultTextField.text = message.string!
        roundTripTextField.text = String("\(timeInterval) ms")
    }
    
    // Other required methods for CocoaMQTTDelegate
    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {}
    func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {}
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topics: [String]) {}
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {}
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {}
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {}
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {}
    func mqttDidPing(_ mqtt: CocoaMQTT) {}
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {}
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {}
    func _console(_ info: String) {}
}
