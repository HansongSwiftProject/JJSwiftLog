//
//  JJLogOutput+Extension.swift
//  JJSwiftLog
//
//  Created by Jezz on 2019/12/27.
//  Copyright © 2019 JJSwiftLog. All rights reserved.
//

import Foundation

/// Extension for JJSwiftLog.Level
extension JJSwiftLog.Level {

    /// String level
    public var stringLevel: String {
        switch self {
        case .verbose:
            return "VERBOSE"
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .warning:
            return "WARN"
        case .error:
            return "ERROR"
        }
    }

    /// Emoji level
    public var emojiLevel: String {
        switch self {
        case .verbose:
            return "📗"
        case .debug:
            return "📘"
        case .info:
            return "📓"
        case .warning:
            return "📙"
        case .error:
            return "📕"
        }
    }
    
}

extension JJLogOutput {
    
    /// 根据日志级别，线程，文件，函数，行数组成的字符串
    /// - Parameter level: 日志级别
    /// - Parameter msg: 开发输入的信息
    /// - Parameter thread: 当前线程
    /// - Parameter file: 文件名
    /// - Parameter function: 函数名
    /// - Parameter line: 日志当前行
    func formatMessage(level: JJSwiftLog.Level, msg: String, thread: String,
                       file: String, function: String, line: Int) -> String {
        if !JJLogFormatter.shared.segments.isEmpty {
            return formatSegmentMessage(level: level, msg: msg, thread: thread, file: file, function: function, line: line)
        }
        var text = ""
        text += self.formatDate(JJLogOutputConfig.formatter) + JJLogOutputConfig.padding
        text += level.emojiLevel + JJLogOutputConfig.padding
        text += thread.isEmpty ? "" : (thread + JJLogOutputConfig.padding)
        text += JJLogOutputConfig.fileNameWithoutSuffix(file)  + JJLogOutputConfig.point
        text += function + JJLogOutputConfig.padding
        text += "\(line)" + JJLogOutputConfig.padding
        text += level.stringLevel + JJLogOutputConfig.padding
        text += msg
        text += JJLogOutputConfig.newline
        return text
    }

    /// Format segment message
    /// - Parameters:
    ///   - level: Log level
    ///   - msg: Text message
    ///   - thread: Thread name
    ///   - file: File name
    ///   - function: Function
    ///   - line: Function line number
    /// - Returns: All info string
    func formatSegmentMessage(level: JJSwiftLog.Level, msg: String, thread: String,
                              file: String, function: String, line: Int) -> String {
        var text = ""
        let segments = JJLogFormatter.shared.segments
        for segment in segments {
            switch segment {
            case .token(let option, let string):
                switch option {
                case .message:
                    text += (msg + string)
                case .level:
                    text += (level.stringLevel + string)
                case .line:
                    text += ("\(line)" + string)
                case .file:
                    text += (JJLogOutputConfig.fileNameWithoutSuffix(file) + string)
                case .function:
                    text += (function + string)
                case .date:
                    text += (self.formatDate(JJLogOutputConfig.formatter) + string)
                case .thread:
                    text += thread.isEmpty ? "" : thread
                case .origin:
                    text += string
                case .ignore:
                    text += string
                }
            }
        }
        text += JJLogOutputConfig.newline
        return text
    }
    
    /// Format date
    /// - Parameter dateFormat: Date format
    /// - Parameter timeZone: timeZone
    func formatDate(_ dateFormat: String, timeZone: String = "") -> String {
        
        if !timeZone.isEmpty {
            JJLogOutputConfig.formatDate.timeZone = TimeZone(abbreviation: timeZone)
        }
        JJLogOutputConfig.formatDate.dateFormat = dateFormat
        let dateStr = JJLogOutputConfig.formatDate.string(from: Date())
        return dateStr
    }
    
    /// Write string to filepointer
    /// - Parameter string: string
    /// - Parameter filePointer: UnsafeMutablePointer<FILE>
    func writeStringToFile(_ string: String, filePointer: UnsafeMutablePointer<FILE>) {
        string.withCString { ptr in
            
            #if os(Windows)
             _lock_file(filePointer)
             #else
             flockfile(filePointer)
             #endif
            defer {
                #if os(Windows)
                _unlock_file(filePointer)
                #else
                funlockfile(filePointer)
                #endif
            }
            
            _ = fputs(ptr, filePointer)
            _ = fflush(filePointer)
        }
    }
    
}
