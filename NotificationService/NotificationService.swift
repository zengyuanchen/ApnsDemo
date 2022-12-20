//
//  NotificationService.swift
//  NotificationService
//
//  Created by ak on 2020/4/14.
//  Copyright © 2020 ak. All rights reserved.
//

import UserNotifications
class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let info = bestAttemptContent?.userInfo,
           let aps = info["aps"] as? [String: Any],
           let isNeedSpeak = aps["isNeedSpeak"] as? Bool, isNeedSpeak == true,
           let speakInfo = aps["speak"] as? [String: Any],
           let prefix = speakInfo["prefix"] as? String,
           let amountString = speakInfo["amount"] as? String,
           let cnt = Double(amountString), cnt > 0,
           let symbol = speakInfo["tokenSymbol"] as? String {
            
            ApnsHelper.makeMp3FromExt(prefix: prefix , amount: amountString, symbol: symbol) { name in
                let sound = UNNotificationSound(named: UNNotificationSoundName(name))
                self.bestAttemptContent?.sound = sound
                
                if let bestAttemptContent = self.bestAttemptContent {
                    bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"
                    bestAttemptContent.body = "\(bestAttemptContent.body) amount=\(amountString), symbol=\(symbol), 转=\(name)"
                    if #available(iOSApplicationExtension 15.0, *) {
                        bestAttemptContent.interruptionLevel = .timeSensitive
                    }
                    contentHandler(bestAttemptContent)
                }
            }
        } else {
            contentHandler(request.content)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
