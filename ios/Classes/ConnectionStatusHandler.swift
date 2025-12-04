import SpotifyiOS
import UIKit

class ConnectionStatusHandler: StatusHandler, SPTAppRemoteDelegate {

    var tokenResult: FlutterResult?
    var connectionResult: FlutterResult?
    var silentConnectionResult: FlutterResult?
    
    private let redirectUri = URL(string:"comspotifytestsdk://")!
    private let clientIdentifier = "951082a22bed4dfa9f1c3680a7f498fe"
    
    static private let kAccessTokenKey = "access-token-key"
    
    lazy var appRemote: SPTAppRemote = {
        let configuration = SPTConfiguration(clientID: self.clientIdentifier, redirectURL: self.redirectUri)
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.connectionParameters.accessToken = self.accessToken
        appRemote.delegate = self
        return appRemote
    }()
    
    var accessToken = UserDefaults.standard.string(forKey: kAccessTokenKey) {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(accessToken, forKey: ConnectionStatusHandler.kAccessTokenKey)
        }
    }
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        self.appRemote = appRemote
        connectionResult?(true)
        silentConnectionResult?(true)
        tokenResult?(appRemote.connectionParameters.accessToken)
        eventSink?("{\"connected\": true}")

        connectionResult = nil
        silentConnectionResult = nil
        tokenResult = nil
        print("**ConnectionStatusHandler_appRemoteDidEstablishConnection**")
//        let playerDelegate = PlayerDelegate()
//        let playerStateHandler = PlayerStateHandler(appRemote: appRemote, playerDelegate: playerDelegate)
//        SwiftSpotifySdkPlugin.instance.playerStateChannel?.setStreamHandler(playerStateHandler)
//
//        let playerContextHandler = PlayerContextHandler(appRemote: appRemote, playerDelegate: playerDelegate)
//        SwiftSpotifySdkPlugin.instance.playerContextChannel?.setStreamHandler(playerContextHandler)
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("**ConnectionStatusHandler_appRemote_didFailConnectionAttemptWithError**")
        defer {
            connectionResult = nil
            tokenResult = nil
            silentConnectionResult = nil
        }

        if error != nil {
            // report spotify remote error to plugin
            eventSink?("{\"connected\": false, \"errorCode\": \"\(error!._code)\", \"errorDetails\": \"\(error!.localizedDescription)\"}")
            connectionResult?(FlutterError(code: String(error!._code), message: error!.localizedDescription, details: nil))
            silentConnectionResult?(FlutterError(code: String(error!._code), message: error!.localizedDescription, details: nil))
            tokenResult?(FlutterError(code: String(error!._code), message: error!.localizedDescription, details: nil))
        } else {
            // report disconnection to plugin
            eventSink?("{\"connected\": false}")
            connectionResult?(FlutterError(code: "errorConnection", message: "Failed Connection Attempt", details: nil))
            tokenResult?(FlutterError(code: "errorConnection", message: "Failed Connection Attempt", details: nil))
            silentConnectionResult?(FlutterError(code: "errorConnection", message: "Failed Connection Attempt", details: nil))
        }
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("**ConnectionStatusHandler_appRemote_didDisconnectWithError**")
        if error != nil {
            // report spotify remote error to plugin
            eventSink?("{\"connected\": false, \"errorCode\": \"\(error!._code)\", \"errorDetails\": \"\(error!.localizedDescription)\"}")
        } else {
            // report disconnection to plugin
            eventSink?("{\"connected\": false}")
        }
    }
}
