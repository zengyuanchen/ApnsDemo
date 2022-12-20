//
//  ApnsVoiceHelper.swift
//  ApnsDemo
//
//  Created by ak on 2020/4/14.
//  Copyright © 2020 ak. All rights reserved.
//

import UIKit
import AVKit

fileprivate let GroupName = "group.club.nineu.matrix.element.ios.test"
struct ApnsHelper {
    
    static func makeMp3(_ amount: String, complete:@escaping (String)->Void) {
        let path = NSHomeDirectory()+"/Library/Sounds/"
        
        mergeVoice(libPath: path, prefix: "", amount: amount, symbol: "") { fileName in
            complete(fileName)
        }
    }
    
    static func makeMp3FromExt(prefix: String,
                               amount: String,
                               symbol: String,
                               complete:@escaping (String)->Void) {
        let path = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: GroupName)!.absoluteString.replacingOccurrences(of: "file://", with: "") + "Library/Sounds/"
        mergeVoice(libPath: path, prefix: prefix, amount: amount, symbol: symbol) { fileName in
            complete(fileName)
        }
    }
    
    private static func mergeVoice(libPath: String,
                                   prefix: String,
                                   amount: String,
                                   symbol: String,
                                   complete:@escaping (String)->Void) {
        clearFiles(libPath)
        
        let nums: String = ApnsHelper.caculateNumber(amount)
        var numsList: [String] = nums.map { String($0) }
        // 添加前面的九乾到账
        numsList.insert(prefix, at: numsList.startIndex)
        // 添加后面的币种
        numsList.append(symbol)
        
        let urls: [URL] = numsList.compactMap { string in
            var fileName = ""
            var ext = ""
            let array = string.components(separatedBy: ".")
            if array.count > 1 {
                fileName = array.first ?? ""
                ext = (array.last == "" ? "mp3" : array.last)!
            } else {
                fileName = string
                ext = "mp3"
            }
            
            let fullName = "\(fileName).\(ext)"
            
            return Bundle.main.url(forResource: fullName, withExtension: "")
        }
        print("数组个数：\(numsList.count)，找到的mp3文件个数：\(urls.count)")
        
        guard !urls.isEmpty else {
            complete("")
            return
        }
        if !FileManager.default.fileExists(atPath: libPath) {
            do {
                try FileManager.default.createDirectory(atPath: libPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("创建Sounds文件失败 \(libPath)")
                complete("")
                return
            }
        }
        let fileName = "\(now()).m4a"
        
        guard let fileURL = URL(string: "file://\(libPath)\(fileName)") else {
            print("创建file失败， fileURL生成失败！")
            complete("")
            return
        }
        print("fileURL: \(String(describing: fileURL))")
        ApnsHelper.merge(urls, fileURL) { u in
            complete(fileName)
        }
    }
    
    // 将金额转成读音
    static func caculateNumber(_ amountString: String) -> String {
        let numberchar = ["0","1","2","3","4","5","6","7","8","9"]
        let inunitchar = ["","十","百","千"]
        let unitname = ["","万","亿"]
        
        let valstr = amountString
        var prefix = ""
        
        // 将金额分为整数部分和小数部分
        let splitArray = valstr.components(separatedBy: CharacterSet(charactersIn: "."))
        var head: String = ""
        var foot: String = ""
        if splitArray.count > 0 {
            head = splitArray[0]
        }
        if splitArray.count == 2 {
            foot = splitArray[1]
        }
        
        // 处理整数部分
        if head == "0" {
            prefix = "0"
        } else {
            
            var ch:[Character] = []
            for index in head.indices {
                let str = head[index]
                ch.append(str)
            }
            
            var zeronum = 0
            for i in 0..<ch.count {
                let index = (ch.count-1-i)%4
                let indexloc = (ch.count-1-i)/4
                
                let ii = ch.index(ch.startIndex, offsetBy: i)
                if ch[ii] == "0" {
                    zeronum += 1
                } else {
                    if zeronum != 0 {
                        if index != 3 {
                            prefix = prefix.appending("零")
                        }
                        zeronum = 0
                    }
                    if ch.count > i {
                        let numIndex = Int(String(ch[ii]))!
                        if numberchar.count > numIndex {
                            let numbercharIndexii = numberchar.index(numberchar.startIndex, offsetBy: numIndex)
                            prefix = prefix.appending(numberchar[numbercharIndexii])
                        }
                    }
                    
                    if inunitchar.count > index {
                        let inunitcharIndexii = inunitchar.index(inunitchar.startIndex, offsetBy: index)
                        prefix = prefix.appending(inunitchar[inunitcharIndexii])
                    }
                }
                if index == 0 && zeronum < 4 {
                    if unitname.count > indexloc {
                        let unitnameIndexii = unitname.index(unitname.startIndex, offsetBy: indexloc)
                        prefix = prefix.appending(unitname[unitnameIndexii])
                    }
                }
            }
        }
        
        //1十开头的改为十
        if prefix.hasPrefix("1十") {
            prefix = prefix.replacingOccurrences(of: "1十", with: "十")
        }
        
        //处理小数部分
        // 判断小数是否全部是0
        var isFootAllZero = true
        for char in foot {
            if char != "0" {
                isFootAllZero = false
                break
            }
        }
        if !isFootAllZero {
            prefix = prefix.appendingFormat("点%@", foot)
        }
        
        return prefix
    }
    
    // 合并音频
    static func merge(_ urls: [URL], _ outputUrl: URL, complete:@escaping (URL?)->Void) {
        // 创建音频轨道,并获取多个音频素材的轨道
        let composition = AVMutableComposition()
        // 音频插入的开始时间,用于记录每次添加音频文件的开始时间
        var beginTime = CMTime.zero
        urls.forEach { audioFileURL in
            // 获取音频素材
            let audioAsset1 = AVURLAsset.init(url: audioFileURL)
            
            // 音频轨道
            let audioTrack1 = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            // 获取音频素材轨道
            guard let audioAssetTrack1 = audioAsset1.tracks(withMediaType: .audio).first else {
                print("有合成失败的素材：url：\(audioFileURL)")
                return
            }
            // 音频合并- 插入音轨文件
            audioTrack1?.naturalTimeScale = 600
            let range = CMTimeRangeMake(start: .zero, duration: audioAsset1.duration)
            try? audioTrack1?.insertTimeRange(range, of: audioAssetTrack1, at: beginTime)
            
            beginTime = beginTime + audioAsset1.duration
            
        }
        let range = CMTimeRangeMake(start: CMTime(seconds: 2.0, preferredTimescale: Int32(600)), duration: composition.duration)
        let toDuration = CMTimeMakeWithSeconds(ApnsHelper.caculateDuration(count: urls.count), preferredTimescale: Int32(600))
        composition.scaleTimeRange(range, toDuration: toDuration)
        // 导出合并后的音频文件
        guard let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            print("导出失败：session创建失败")
            return
        }
        // 音频文件输出
        session.outputURL = outputUrl
        session.outputFileType = .m4a
        session.audioTimePitchAlgorithm = .spectral
        session.shouldOptimizeForNetworkUse = true
        session.exportAsynchronously {
            if session.status == .completed {
                print("合成成功-----\(outputUrl)")
                print("声音文件时间长度-----\(CMTimeShow(composition.duration))")
                complete(outputUrl)
            } else {
                print("合成失败-----session.status = \(session.status)")
                complete(nil)
            }
        }
    }
    
    static func caculateDuration(count: Int) -> Double {
        print("count = \(count)")
        var d = 0.0;
        if count < 1 {
            d = 3.5
        } else if count < 2 {
            d = 3.6
        } else if count < 3 {
            d = 3.7
        } else if count < 4 {
            d = 3.8
        } else if count < 5 {
            d = 3.9
        } else if count < 6 {
            d = 4.0
        } else if count < 7 {
            d = 4.1
        } else if count < 8 {
            d = 4.4
        } else if count < 9 {
            d = 4.9
        } else if count < 10 {
            d = 5.1
        } else if count < 11 {
            d = 5.2
        } else if count < 12 {
            d = 5.3
        } else if count < 13 {
            d = 5.3
        } else if count < 14 {
            d = 5.3
        } else if count < 15 {
            d = 5.3
        } else if count < 16 {
            d = 5.3
        } else if count < 17 {
            d = 5.3
        } else {
            d = 5.3
        }
        
        return d+0.40
    }
    
    
    
    private static func clearFiles(_ libPath: String) {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: libPath, isDirectory: &isDir), let list = try? FileManager.default.contentsOfDirectory(atPath: libPath) else { return }
        let before = now() - 12*60*60*1000 //1day ago
        list.forEach { file in
            if let time = Int(file.replacingOccurrences(of: ".m4a", with: "")), time < before {
                //delete file
                do {
                    let url = URL(string: "file://" + libPath + file)!
                    try FileManager.default.removeItem(at: url)
                    print("成功删除过期的文件：\(url)")
                } catch {
                    print("删除过期m4a失败, \(error)")
                }
            }
        }
    }
    
    private static func now() -> Int {
        return Int(Date().timeIntervalSince1970*1000)
    }
}
