//
//  NotificationService.swift
//  NotificationService
//
//  Created by zengsir on 2022/12/27.
//
/*
{
    "data": {
      "title": "到账成功",
      "content": "到账“41.2CUST”",
      "isNeedReport": 1,
      "params": {
        "showStyle": 0,
        "action": "nineu://order/transfer?id=Sk4xeTlKQTR2YStnT05iTkVEL0ZFQT09"
      },
      "sound": "jqdz_cn.mp3",
      "isNeedSpeak": 1,
      "speak": {
        "prefix": "jqdz_cn.mp3",
        "amount": "41.2",
        "tokenSymbol": "CUST.mp3"
      },
      "id": 684746565503425536
    },
    "aps": {
      "alert": {
        "title": "到账成功",
        "body": "到账“41.2CUST”"
      },
      "badge": 1,
      "sound": "jqdz_cn.mp3",
      "mutable-content": 1,
      "content-available": 1,
      "category": null
    }
  }
*/
import UserNotifications
import Dispatch

var timer: DispatchSourceTimer?
//var test1 = 0
//var test2 = 0
var countDownNum = 0
var queue: [[String: Any]] = [];

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        let block = {
            
//            test2 += 1
            print("语音播报：当前countDownNum = \(countDownNum)")
            countDownNum -= 1
            if countDownNum > 0 {
                return
            }

            if queue.isEmpty {
                return
            }
            let first = queue.removeFirst()
            let bestAttemptContent_ = first["bestAttemptContent"] as! UNNotificationContent
            let contentHandler_ = first["contentHandler"] as! ((UNNotificationContent) -> Void)
//            (bestAttemptContent_ as! UNMutableNotificationContent).body = "test2=\(test2), countDownNum = \(countDownNum)"
            countDownNum = 7
            contentHandler_(bestAttemptContent_)
            
            print("语音播报：已播报一条，重置countDownNum = \(countDownNum)")

        }
        
        if timer == nil {

            print("语音播报：timer初始化")
            timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())
            timer?.schedule(deadline: DispatchTime.now(), repeating: .seconds(1), leeway: .nanoseconds(1))
            timer?.setEventHandler {
                DispatchQueue.main.async {
                    block()
                }
            }
            timer?.resume()
        }
        
        if let info = bestAttemptContent?.userInfo,
           let params = info["data"] as? [String: Any],
           let isNeedSpeak = params["isNeedSpeak"] as? Bool, isNeedSpeak == true,
           let speakInfo = params["speak"] as? [String: Any],
           let prefix = speakInfo["prefix"] as? String,
           let amountString = speakInfo["amount"] as? String,
           let cnt = Double(amountString), cnt > 0,
           let symbol = speakInfo["tokenSymbol"] as? String {
//            test1 += 1
            ApnsHelper.makeMp3FromExt(prefix: prefix , amount: amountString, symbol: symbol) { name in
                let sound = UNNotificationSound(named: UNNotificationSoundName(name))
                self.bestAttemptContent?.sound = sound

                if let bestAttemptContent = self.bestAttemptContent {
                    if #available(iOSApplicationExtension 15.0, *) {
                        bestAttemptContent.interruptionLevel = .timeSensitive
                    }
//                    bestAttemptContent.title = "test1 = \(test1), test2 = \(test2)"
//                    bestAttemptContent.body = "timer is cancelled = \(String(describing: timer?.isCancelled))"
                    print("语音播报：添加一个播报push进队列， 金额=\(amountString) sound=\(String(describing: bestAttemptContent.sound))")
                    let item = ["bestAttemptContent": bestAttemptContent, "contentHandler": self.contentHandler!] as [String : Any]
                    queue.append(item)
//                    contentHandler(bestAttemptContent)
                }
            }
        } else {
            print("语音播报：接收到不满足语音播报条件的push")
//            bestAttemptContent?.title = "接收到不满足语音播报条件的push"
            let item = ["bestAttemptContent": bestAttemptContent!, "contentHandler": self.contentHandler!] as [String : Any]
            queue.append(item)
//            contentHandler(request.content)
        }
        
    }
       
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
//            bestAttemptContent.title = "超时"
            contentHandler(bestAttemptContent)
        }
    }

}





//
//  NotificationService.swift
//  NotificationService
//
//  Created by ak on 2020/4/14.
//  Copyright © 2020 ak. All rights reserved.
//

//import UserNotifications
//class NotificationService: UNNotificationServiceExtension {
//
//    var contentHandler: ((UNNotificationContent) -> Void)?
//    var bestAttemptContent: UNMutableNotificationContent?
//
//    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
//        self.contentHandler = contentHandler
//        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
//
//        if let info = bestAttemptContent?.userInfo,
//           let aps = info["aps"] as? [String: Any],
//           let isNeedSpeak = aps["isNeedSpeak"] as? Bool, isNeedSpeak == true,
//           let speakInfo = aps["speak"] as? [String: Any],
//           let prefix = speakInfo["prefix"] as? String,
//           let amountString = speakInfo["amount"] as? String,
//           let cnt = Double(amountString), cnt > 0,
//           let symbol = speakInfo["tokenSymbol"] as? String {
//
//            ApnsHelper.makeMp3FromExt(prefix: prefix , amount: amountString, symbol: symbol) { name in
//                let sound = UNNotificationSound(named: UNNotificationSoundName(name))
//                self.bestAttemptContent?.sound = sound
//
//                if let bestAttemptContent = self.bestAttemptContent {
//                    bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"
//                    bestAttemptContent.body = "\(bestAttemptContent.body) amount=\(amountString), symbol=\(symbol), 转=\(name)"
//                    if #available(iOSApplicationExtension 15.0, *) {
//                        bestAttemptContent.interruptionLevel = .timeSensitive
//                    }
//                    contentHandler(bestAttemptContent)
//                }
//            }
//        } else {
//            contentHandler(request.content)
//        }
//    }
//
//    override func serviceExtensionTimeWillExpire() {
//        // Called just before the extension will be terminated by the system.
//        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
//        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
//            contentHandler(bestAttemptContent)
//        }
//    }
//}
