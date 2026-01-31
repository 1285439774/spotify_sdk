//
//  ContentStreamHandler.swift
//  Pods
//
//  Created by 邝枫 on 2025/10/25.
//


class ContentStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
   
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    func send(_ data: [String: Any]) {
        eventSink?(data)
    }

    func sendError(_ message: String) {
        eventSink?(FlutterError(code: "SPOTIFY_CONTENT_ERROR", message: message, details: nil))
    }
}
