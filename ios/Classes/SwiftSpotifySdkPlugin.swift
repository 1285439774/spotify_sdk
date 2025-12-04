import Flutter
import SpotifyiOS
import Foundation
import ObjectiveC.runtime

// 在文件顶部或其他合适的位置添加

struct ContentItem: Codable {
    let title: String?
    let subtitle: String?
    let contentDescription: String?
    let identifier: String
    let URI: String
    let availableOffline: Bool
    let playable: Bool
    let container: Bool
    let pinned: Bool
    let children: [ContentItem]?

    enum CodingKeys: String, CodingKey {
        case title
        case subtitle
        case contentDescription
        case identifier
        case URI
        case availableOffline = "isAvailableOffline"
        case playable = "isPlayable"
        case container = "isContainer"
        case pinned = "isPinned"
        case children
    }
}


public class SwiftSpotifySdkPlugin: NSObject, FlutterPlugin{
   
    
    public static var instance = SwiftSpotifySdkPlugin()
//    public var appRemote: SPTAppRemote?
    private var connectionStatusHandler: ConnectionStatusHandler?
    private var playerStateHandler: PlayerStateHandler?
    private var playerContextHandler: PlayerContextHandler?
    private static var playerStateChannel: FlutterEventChannel?
    private static var playerContextChannel: FlutterEventChannel?
    private var contentStreamHandler: ContentStreamHandler?
    private static var contentEventChannel : FlutterEventChannel?
    // 全局缓存（key: contentItem.identifier, value: contentItem）
    private var contentItems: [String: SPTAppRemoteContentItem] = [:]


    public static func register(with registrar: FlutterPluginRegistrar) {
        guard playerStateChannel == nil else {
            // Avoid multiple plugin registations
            return
        }
        let spotifySDKChannel = FlutterMethodChannel(name: "spotify_sdk", binaryMessenger: registrar.messenger())
        let connectionStatusChannel = FlutterEventChannel(name: "connection_status_subscription", binaryMessenger: registrar.messenger())
        playerStateChannel = FlutterEventChannel(name: "player_state_subscription", binaryMessenger: registrar.messenger())
        playerContextChannel = FlutterEventChannel(name: "player_context_subscription", binaryMessenger: registrar.messenger())
        registrar.addApplicationDelegate(instance)
        registrar.addMethodCallDelegate(instance, channel: spotifySDKChannel)
        instance.connectionStatusHandler = ConnectionStatusHandler()
        connectionStatusChannel.setStreamHandler(instance.connectionStatusHandler)
        
        contentEventChannel = FlutterEventChannel(name: "root_content_items_subscription", binaryMessenger: registrar.messenger())
        instance.contentStreamHandler = ContentStreamHandler()
        SwiftSpotifySdkPlugin.contentEventChannel?.setStreamHandler(instance.contentStreamHandler)
        
    }
    
    public var appRemote: SPTAppRemote? {
        get {
            return connectionStatusHandler?.appRemote
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        var defaultPlayAPICallback: SPTAppRemoteCallback {
            get {
                return {_, error in
                    if let error = error {
                        result(FlutterError(code: "PlayerAPI Error", message: error.localizedDescription, details: nil))
                    } else {
                        result(true)
                    }
                }
            }
        }

        switch call.method {
        case SpotifySdkConstants.methodSilentConnecToSpotify:
            guard let appRemote = appRemote else {
                result(FlutterError(code: "Connection Error", message: "AppRemote is null", details: nil))
                return
            }
           
            print("appRemote.connect")
            connectionStatusHandler?.silentConnectionResult = result
            
            do{
                appRemote.delegate = connectionStatusHandler
                appRemote.connect()
                
                let playerDelegate = PlayerDelegate()
                playerStateHandler = PlayerStateHandler(appRemote: self.appRemote!, playerDelegate: playerDelegate)
                SwiftSpotifySdkPlugin.playerStateChannel?.setStreamHandler(playerStateHandler)

                playerContextHandler = PlayerContextHandler(appRemote: self.appRemote!, playerDelegate: playerDelegate)
                SwiftSpotifySdkPlugin.playerContextChannel?.setStreamHandler(playerContextHandler)
            }catch SpotifyError.redirectURLInvalid {
                result(FlutterError(code: "errorConnecting", message: "Redirect URL is not set or has invalid format", details: nil))
            }catch {
                result(FlutterError(code: "CouldNotFindSpotifyApp", message: "The Spotify app is not installed on the device", details: nil))
                return
            }
        case SpotifySdkConstants.methodConnectToSpotify:
            guard let swiftArguments = call.arguments as? [String:Any],
                  let clientID = swiftArguments[SpotifySdkConstants.paramClientId] as? String,
                  !clientID.isEmpty else {
                result(FlutterError(code: "Argument Error", message: "Client ID is not set", details: nil))
                return
            }

            guard let url = swiftArguments[SpotifySdkConstants.paramRedirectUrl] as? String,
                  !url.isEmpty else {
                result(FlutterError(code: "Argument Error", message: "Redirect URL is not set", details: nil))
                return
            }

            connectionStatusHandler?.connectionResult = result


            let accessToken: String? = swiftArguments[SpotifySdkConstants.paramAccessToken] as? String
            let spotifyUri: String = swiftArguments[SpotifySdkConstants.paramSpotifyUri] as? String ?? ""

            do {
                try connectToSpotify(clientId: clientID, redirectURL: url, accessToken: accessToken, spotifyUri: spotifyUri, asRadio: swiftArguments[SpotifySdkConstants.paramAsRadio] as? Bool, additionalScopes: swiftArguments[SpotifySdkConstants.scope] as? String)
            }
            catch SpotifyError.redirectURLInvalid {
                result(FlutterError(code: "errorConnecting", message: "Redirect URL is not set or has invalid format", details: nil))
            }
            catch {
                result(FlutterError(code: "CouldNotFindSpotifyApp", message: "The Spotify app is not installed on the device", details: nil))
                return
            }

        case SpotifySdkConstants.methodGetAccessToken:
            guard let swiftArguments = call.arguments as? [String:Any],
                let clientID = swiftArguments[SpotifySdkConstants.paramClientId] as? String,
                let url = swiftArguments[SpotifySdkConstants.paramRedirectUrl] as? String else {
                    result(FlutterError(code: "Arguments Error", message: "One or more arguments are missing", details: nil))
                    return
            }
            connectionStatusHandler?.tokenResult = result
            let spotifyUri: String = swiftArguments[SpotifySdkConstants.paramSpotifyUri] as? String ?? ""
            
            do {
                try connectToSpotify(clientId: clientID, redirectURL: url, spotifyUri: spotifyUri, asRadio: swiftArguments[SpotifySdkConstants.paramAsRadio] as? Bool, additionalScopes: swiftArguments[SpotifySdkConstants.scope] as? String)
            }
            catch SpotifyError.redirectURLInvalid {
                result(FlutterError(code: "errorConnecting", message: "Redirect URL is not set or has invalid format", details: nil))
            }
            catch {
                result(FlutterError(code: "CouldNotFindSpotifyApp", message: "The Spotify app is not installed on the device", details: nil))
                return
            }
        case SpotifySdkConstants.methodGetImage:
            guard let appRemote = appRemote else {
                result(FlutterError(code: "Connection Error", message: "AppRemote is null", details: nil))
                return
            }
            guard let swiftArguments = call.arguments as? [String:Any],
                let paramImageUri = swiftArguments[SpotifySdkConstants.paramImageUri] as? String,
                let paramImageDimension = swiftArguments[SpotifySdkConstants.paramImageDimension] as? Int else {
                    result(FlutterError(code: "Arguments Error", message: "One or more arguments are missing", details: nil))
                    return
            }

            class ImageObject: NSObject, SPTAppRemoteImageRepresentable {
                var imageIdentifier: String = ""
            }

            let imageObject = ImageObject()
            imageObject.imageIdentifier = paramImageUri
            appRemote.imageAPI?.fetchImage(forItem: imageObject, with: CGSize(width: paramImageDimension, height: paramImageDimension), callback: { (image, error) in
                guard error == nil else {
                    result(FlutterError(code: "ImageAPI Error", message: error?.localizedDescription, details: nil))
                    return
                }
                guard let imageData = (image as? UIImage)?.pngData() else {
                    result(FlutterError(code: "ImageAPI Error", message: "Image is empty", details: nil))
                    return
                }
                result(imageData)
            })
        case SpotifySdkConstants.methodGetImageForContentItem:
            guard let appRemote = appRemote else {
                result(FlutterError(code: "Connection Error", message: "AppRemote is null", details: nil))
                return
            }
            guard let swiftArguments = call.arguments as? [String:Any],
                  let id = swiftArguments[SpotifySdkConstants.paramContentItemId] as? String,
                  let uri = swiftArguments[SpotifySdkConstants.paramSpotifyUri] as? String,
                  let paramImageDimension = swiftArguments[SpotifySdkConstants.paramImageDimension] as? Int else {
                      result(FlutterError(code: "Arguments Error", message: "One or more arguments are missing", details: nil))
                      return
                
            }
            let contentItem = getContentItem(id: id)
            if let item = contentItem {
                print("**fetchImage**")
                appRemote.imageAPI?.fetchImage(forItem: item, with: CGSize(width: paramImageDimension, height: paramImageDimension), callback: { (image, error) in
                    guard error == nil else {
                        result(FlutterError(code: "ImageAPI Error", message: error?.localizedDescription, details: nil))
                        return
                    }
                    guard let imageData = (image as? UIImage)?.pngData() else {
                        result(FlutterError(code: "ImageAPI Error", message: "Image is empty", details: nil))
                        return
                    }
                    result(imageData)
                })
            }else{
                print("**fetchContentItem**")
                appRemote.contentAPI?.fetchContentItem(forURI: uri, callback: { (contentItemResult, error) in
                    if let error = error {
                        result(FlutterError(code: "Content API Error", message: error.localizedDescription, details: nil))
                        return
                    }

                    guard let contentItem = contentItemResult as? SPTAppRemoteContentItem else {
                        result(FlutterError(code: "Content API Error", message: "Invalid content item", details: nil))
                        return
                    }
                    print("**fetchImage2**")
                    appRemote.imageAPI?.fetchImage(forItem: contentItem, with: CGSize(width: paramImageDimension, height: paramImageDimension), callback: { (image, error) in
                        guard error == nil else {
                            result(FlutterError(code: "ImageAPI Error", message: error?.localizedDescription, details: nil))
                            return
                        }
                        guard let imageData = (image as? UIImage)?.pngData() else {
                            result(FlutterError(code: "ImageAPI Error", message: "Image is empty", details: nil))
                            return
                        }
                        result(imageData)
                    })
                    
                })
            }
            

        case SpotifySdkConstants.methodGetPlayerState:
            guard let appRemote = appRemote else {
                result(FlutterError(code: "Connection Error", message: "AppRemote is null", details: nil))
                return
            }
            
            appRemote.playerAPI?.getPlayerState({ (playerState, error) in
                guard error == nil else {
                    result(FlutterError(code: "PlayerAPI Error", message: error?.localizedDescription, details: nil))
                    return
                }
                guard let playerState = playerState as? SPTAppRemotePlayerState else {
                    result(FlutterError(code: "PlayerAPI Error", message: "PlayerState is empty", details: nil))
                    return
                }
                result(State.playerStateDictionary(playerState).json)
            })
        case SpotifySdkConstants.methodDisconnectFromSpotify:
            appRemote?.disconnect()
//            appRemote?.connectionParameters.accessToken = nil
            result(true)
        case SpotifySdkConstants.methodPlay:
            guard let appRemote = appRemote else {
                result(FlutterError(code: "Connection Error", message: "AppRemote is null", details: nil))
                return
            }
            guard let swiftArguments = call.arguments as? [String:Any],
                let uri = swiftArguments[SpotifySdkConstants.paramSpotifyUri] as? String else {
                    result(FlutterError(code: "URI Error", message: "No URI was specified", details: nil))
                    return
            }
            let asRadio: Bool = (swiftArguments[SpotifySdkConstants.paramAsRadio] as? Bool) ?? false
            appRemote.playerAPI?.play(uri, asRadio: asRadio, callback: defaultPlayAPICallback)
        case SpotifySdkConstants.methodPause:
            guard let appRemote = appRemote else {
                result(FlutterError(code: "Connection Error", message: "AppRemote is null", details: nil))
                return
            }
            appRemote.playerAPI?.pause(defaultPlayAPICallback)
        case SpotifySdkConstants.methodResume:
            guard let appRemote = appRemote else {
                result(FlutterError(code: "Connection Error", message: "AppRemote is null", details: nil))
                return
            }
            appRemote.playerAPI?.resume(defaultPlayAPICallback)
        case SpotifySdkConstants.methodSkipNext:
            guard let appRemote = appRemote else {
                result(FlutterError(code: "Connection Error", message: "AppRemote is null", details: nil))
                return
            }
            appRemote.playerAPI?.skip(toNext: defaultPlayAPICallback)
        case SpotifySdkConstants.methodSkipPrevious:
            guard let appRemote = appRemote else {
                result(FlutterError(code: "Connection Error", message: "AppRemote is null", details: nil))
                return
            }
            appRemote.playerAPI?.skip(toPrevious: { (spotifyResult, error) in
                if let error = error {
                    result(FlutterError(code: "PlayerAPI Error", message: error.localizedDescription, details: nil))
                    return
                }
                result(true)
            })
        case SpotifySdkConstants.methodSkipToIndex:
            guard let appRemote = appRemote else {
                result(FlutterError(code: "Connection Error", message: "AppRemote is null", details: nil))
                return
            }
            guard let swiftArguments = call.arguments as? [String:Any],
                let uri = swiftArguments[SpotifySdkConstants.paramSpotifyUri] as? String else {
                    result(FlutterError(code: "URI Error", message: "No URI was specified", details: nil))
                    return
            }
            let index = (swiftArguments[SpotifySdkConstants.paramTrackIndex] as? Int) ?? 0

            appRemote.contentAPI?.fetchContentItem(forURI: uri, callback: { (contentItemResult, error) in
                guard error == nil else {
                    result(FlutterError(code: "PlayerAPI Error", message: error?.localizedDescription, details: nil))
                    return
                }
                guard let contentItem = contentItemResult as? SPTAppRemoteContentItem else {
                    result(FlutterError(code: "URI Error", message: "No URI was specified", details: nil))
                    return
                }
                appRemote.playerAPI?.play(contentItem, skipToTrackIndex: index, callback: defaultPlayAPICallback)
            })

        case SpotifySdkConstants.methodAddToLibrary:
            guard let appRemote = appRemote else {
                result(FlutterError(code: "Connection Error", message: "AppRemote is null", details: nil))
                return
            }
            guard let swiftArguments = call.arguments as? [String:Any],
                let uri = swiftArguments[SpotifySdkConstants.paramSpotifyUri] as? String else {
                    result(FlutterError(code: "URI Error", message: "No URI was specified", details: nil))
                    return
            }
            appRemote.userAPI?.addItemToLibrary(withURI: uri, callback: defaultPlayAPICallback)
        case SpotifySdkConstants.methodRemoveFromLibrary:
            guard let appRemote = appRemote else {
                result(FlutterError(code: "Connection Error", message: "AppRemote is null", details: nil))
                return
            }
            guard let swiftArguments = call.arguments as? [String:Any],
                let uri = swiftArguments[SpotifySdkConstants.paramSpotifyUri] as? String else {
                    result(FlutterError(code: "URI Error", message: "No URI was specified", details: nil))
                    return
            }
            appRemote.userAPI?.removeItemFromLibrary(withURI: uri, callback: defaultPlayAPICallback)
        case SpotifySdkConstants.methodGetCapabilities:
            guard let appRemote = appRemote else {
                result(FlutterError(code: "Connection Error", message: "AppRemote is null", details: nil))
                return
            }
            appRemote.userAPI?.fetchCapabilities(callback: { (capabilitiesResult, error) in
                guard error == nil else {
                    result(FlutterError(code: "getCapabilitiesError", message: error?.localizedDescription, details: nil))
                    return
                }
                guard let userCapabilities = capabilitiesResult as? SPTAppRemoteUserCapabilities else {
                    result(FlutterError(code: "getCapabilitiesError", message: error?.localizedDescription, details: nil))
                    return
                }

                result(State.userCapabilitiesDictionary(userCapabilities).json)
            })
        case SpotifySdkConstants.methodQueueTrack:
            guard let appRemote = appRemote else {
                result(FlutterError(code: "Connection Error", message: "AppRemote is null", details: nil))
                return
            }
            guard let swiftArguments = call.arguments as? [String:Any],
                let uri = swiftArguments[SpotifySdkConstants.paramSpotifyUri] as? String else {
                    result(FlutterError(code: "URI Error", message: "No URI was specified", details: nil))
                    return
            }
            appRemote.playerAPI?.enqueueTrackUri(uri, callback: defaultPlayAPICallback)
        case SpotifySdkConstants.methodSeekTo:
            guard let appRemote = appRemote else {
                result(FlutterError(code: "Connection Error", message: "AppRemote is null", details: nil))
                return
            }
            guard let swiftArguments = call.arguments as? [String:Any],
                let position = swiftArguments[SpotifySdkConstants.paramPositionedMilliseconds] as? Int else {
                    result(FlutterError(code: "Position error", message: "No position was specified", details: nil))
                    return
            }
            appRemote.playerAPI?.seek(toPosition: position, callback: defaultPlayAPICallback)
        case SpotifySdkConstants.methodGetCrossfadeState:
            guard let appRemote = appRemote else {
                result(FlutterError(code: "Connection Error", message: "AppRemote is null", details: nil))
                return
            }
            appRemote.playerAPI?.getCrossfadeState({ (crossfadeState, error) in
                guard error == nil else {
                    result(FlutterError(code: "PlayerAPI Error", message: error?.localizedDescription, details: nil))
                    return
                }
                guard let crossfadeState = crossfadeState as? SPTAppRemoteCrossfadeState else {
                    result(FlutterError(code: "PlayerAPI Error", message: "PlayerState is empty", details: nil))
                    return
                }
                result(State.crossfadeStateDictionary(crossfadeState).json)
            })
        case SpotifySdkConstants.methodSetShuffle:
            guard let appRemote = appRemote else {
                result(FlutterError(code: "Connection Error", message: "AppRemote is null", details: nil))
                return
            }
            guard let swiftArguments = call.arguments as? [String:Any],
                let shuffle = swiftArguments[SpotifySdkConstants.paramShuffle] as? Bool else {
                    result(FlutterError(code: "Shuffle mode error", message: "No ShuffleMode was specified", details: nil))
                    return
            }
            appRemote.playerAPI?.setShuffle(shuffle, callback: defaultPlayAPICallback)
        case SpotifySdkConstants.methodSetRepeatMode:
            guard let appRemote = appRemote else {
                result(FlutterError(code: "Connection Error", message: "AppRemote is null", details: nil))
                return
            }
            guard let swiftArguments = call.arguments as? [String:Any],
                let repeatModeIndex = swiftArguments[SpotifySdkConstants.paramRepeatMode] as? UInt,
                let repeatMode = SPTAppRemotePlaybackOptionsRepeatMode(rawValue: repeatModeIndex) else {
                    result(FlutterError(code: "Repeat mode error", message: "No RepeatMode was specified", details: nil))
                    return
            }
            appRemote.playerAPI?.setRepeatMode(repeatMode, callback: defaultPlayAPICallback)
        case SpotifySdkConstants.getLibraryState:
            guard let appRemote = appRemote else {
                result(FlutterError(code: "Connection Error", message: "AppRemote is null", details: nil))
                return
            }
            guard let swiftArguments = call.arguments as? [String:Any],
                let uri = swiftArguments[SpotifySdkConstants.paramSpotifyUri] as? String else {
                    result(FlutterError(code: "URI Error", message: "No URI was specified", details: nil))
                    return
            }
            appRemote.userAPI?.fetchLibraryState(forURI: uri, callback: {libraryStateResult, error in
                guard error == nil else {
                    result(FlutterError(code: "fetchLibraryStateError", message: error?.localizedDescription, details: nil))
                    return
                }
                guard let libraryState = libraryStateResult as? SPTAppRemoteLibraryState else {
                    result(FlutterError(code: "fetchLibraryStateError", message: error?.localizedDescription, details: nil))
                    return
                }

                result(State.libraryStateDictionary(libraryState).json)
            })
            
        case SpotifySdkConstants.methodGetRecommendedContentItem:
            guard let appRemote = appRemote else {
                    result(FlutterError(code: "Connection Error", message: "AppRemote is null", details: nil))
                    return
                }
                appRemote.contentAPI?.fetchRecommendedContentItems(forType: SPTAppRemoteContentTypeDefault, flattenContainers: false) { (items, error) in
                    if let error = error {
                        result(FlutterError(code: "Content API Error", message: error.localizedDescription, details: nil))
                        return
                    }
                    
                    if let contentItems = items as? [SPTAppRemoteContentItem] {
                        // 将获取到的 contentItems 转换为字典格式
                        let contentItemDictionaries = contentItems.map { item in
//                            print("title: \(item.title ?? "nil"), isContainer: \(item.isContainer)")
                            self.saveContentItem(item)
                            return [
                                "id": item.identifier,
                                "uri": item.uri,
//                               "image_id": "",
                                "title": item.title ?? "",
                                "subtitle": item.subtitle ?? "",
                                "playable":item.isPlayable,
                                "has_children":item.isContainer,
                                "is_pinned":item.isPinned,
//                                "description":item.contentDescription
                             
                            
                                ]
                            }
                        if(!contentItemDictionaries.isEmpty){
                            let contentItemsDictionaries :[String: Any] = [
                                "limit" : contentItemDictionaries.count,
                                "offset": 0,
                                "total" : contentItemDictionaries.count,
                                "items": contentItemDictionaries
                            ]
                            result(contentItemsDictionaries.json)
                        }
                        
                        // ---- 同时开始通过 event stream 推送逐个子项 ----
                        
                        let serializedItems = contentItems.map { self.serializeItem($0) }
                                let rootListPayload: [String: Any] = [
                                    "limit": serializedItems.count,
                                    "offset": 0,
                                    "total": serializedItems.count,
                                    "items": serializedItems
                                ]

                        print("📤 Sending root_list event to Flutter")
                                // --- 1️⃣ 通过 Stream 推送 Root 层完整数据 ---
                                self.contentStreamHandler?.send([
                                    "type": "root_list",
                                    "data": rootListPayload
                                ])
                        
                        
                        for item in contentItems where item.isContainer {
                                    self.fetchChildrenRecursive(of: item)
                                }
                    } else {
                        result(FlutterError(code: "Content API Error", message: "Failed to fetch content items", details: nil))
                    }
                }
        case SpotifySdkConstants.methodGetChildrenOfItem:
            guard let appRemote = appRemote else {
                result(FlutterError(code: "Connection Error", message: "AppRemote is null", details: nil))
                return
            }
            // 先把 arguments 取出来
            guard let swiftArguments = call.arguments as? [String: Any] else {
                print("⚠️ call.arguments is not a dictionary: \(String(describing: call.arguments))")
                result(FlutterError(code: "Argument Error", message: "Arguments should be a dictionary.", details: nil))
                return
            }

            // 打印全部参数
            print("📌 Received arguments: \(swiftArguments)")

            // 再做详细校验
            guard let uri = swiftArguments[SpotifySdkConstants.paramSpotifyUri] as? String,
                  let id = swiftArguments[SpotifySdkConstants.paramContentItemId] as? String else {

                print("⚠️ Missing parameters: uri=\(swiftArguments[SpotifySdkConstants.paramSpotifyUri] ?? "nil"), id=\(swiftArguments[SpotifySdkConstants.paramContentItemId] ?? "nil")")

                result(FlutterError(code: "Argument Error", message: "Arguments missing: id and uri are required.", details: nil))
                return
            }
            let contentItem = getContentItem(id: id)
            if let item = contentItem {
                // ① 缓存中有，直接播放
                print("**fetchChildren**")
                appRemote.contentAPI?.fetchChildren(of: item) { (items, error) in
                    if let error = error {
                        result(FlutterError(code: "Content API Error", message: error.localizedDescription, details: nil))
                        return
                    }

                    if let contentItems = items as? [SPTAppRemoteContentItem] {
            
                        let contentItemDictionaries = contentItems.map { item in
                            self.saveContentItem(item)
                            return [
                                "id": item.identifier,
                                "uri": item.uri,
                                "image_id": nil,
                                "title": item.title,
                                "subtitle": item.subtitle,
                                "playable": item.isPlayable,
                                "has_children":item.isContainer,
                                "is_pinned":item.isPinned,
                                "description":item.contentDescription
                            ]
                        }
                        
                        let contentItemsDictionaries: [String: Any] = [
                            "limit": contentItemDictionaries.count,
                            "offset": 0,
                            "total": contentItemDictionaries.count,
                            "items": contentItemDictionaries
                        ]
                        
                        result(contentItemsDictionaries.json)
                    } else {
                        result(FlutterError(code: "Content API Error", message: "Failed to fetch children items", details: nil))
                    }
                }
            } else {
                // ② 缓存中没有，从 Spotify 重新 fetch
                appRemote.contentAPI?.fetchContentItem(forURI: uri, callback: { (contentItemResult, error) in
                    if let error = error {
                        result(FlutterError(code: "Content API Error", message: error.localizedDescription, details: nil))
                        return
                    }
                    
                    guard let container = contentItemResult as? SPTAppRemoteContentItem else {
                        result(FlutterError(code: "Content API Error", message: "Invalid container item", details: nil))
                        return
                    }
                    
                    appRemote.contentAPI?.fetchChildren(of: container) { (items, error) in
                        if let error = error {
                            result(FlutterError(code: "Content API Error", message: error.localizedDescription, details: nil))
                            return
                        }

                        if let contentItems = items as? [SPTAppRemoteContentItem] {
                
                            let contentItemDictionaries = contentItems.map { item in
                                self.saveContentItem(item)
                                return [
                                    "id": item.identifier,
                                    "uri": item.uri,
                                    "image_id": nil,
                                    "title": item.title,
                                    "subtitle": item.subtitle,
                                    "playable": item.isPlayable,
                                    "has_children":item.isContainer,
                                    "is_pinned":item.isPinned,
                                    "description":item.contentDescription
                                ]
                            }
                            
                            let contentItemsDictionaries: [String: Any] = [
                                "limit": contentItemDictionaries.count,
                                "offset": 0,
                                "total": contentItemDictionaries.count,
                                "items": contentItemDictionaries
                            ]
                            
                            result(contentItemsDictionaries.json)
                        } else {
                            result(FlutterError(code: "Content API Error", message: "Failed to fetch children items", details: nil))
                        }
                    }
                })
            }
            
            
        case SpotifySdkConstants.methodPlayContentItem:
            guard let appRemote = appRemote else {
                    result(FlutterError(code: "Connection Error", message: "AppRemote is null", details: nil))
                    return
                }
                guard let swiftArguments = call.arguments as? [String: Any],
                      let uri = swiftArguments[SpotifySdkConstants.paramSpotifyUri] as? String,
                      let id = swiftArguments[SpotifySdkConstants.paramContentItemId] as? String else {
                    result(FlutterError(code: "Argument Error", message: "Arguments missing: id and uri are required.", details: nil))
                    return
                }
            let contentItem = getContentItem(id: id)
            if let item = contentItem {
                // ① 缓存中有，直接播放
                appRemote.playerAPI?.play(item, callback: { (_, error) in
                    if let error = error {
                        result(FlutterError(code: "PlayerAPI_Error", message: error.localizedDescription, details: nil))
                    } else {
                        result(true)
                    }
                })
            } else {
                // ② 缓存中没有，从 Spotify 重新 fetch
                appRemote.contentAPI?.fetchContentItem(forURI: uri, callback: { (fetched, error) in
                    if let error = error {
                        result(FlutterError(code: "ContentAPI_Error", message: error.localizedDescription, details: nil))
                        return
                    }

                    guard let fetchedItem = fetched as? SPTAppRemoteContentItem else {
                        result(FlutterError(code: "ContentAPI_Error", message: "Failed to fetch content item", details: nil))
                        return
                    }

                    // 可选：把重新获取的 item 存回缓存
                    self.saveContentItem(fetchedItem)

                    // 播放
                    appRemote.playerAPI?.play(fetchedItem, callback: { (_, error) in
                        if let error = error {
                            result(FlutterError(code: "PlayerAPI_Error", message: error.localizedDescription, details: nil))
                        } else {
                            result(true)
                        }
                    })
                })
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func fetchChildrenRecursive(of item: SPTAppRemoteContentItem) {
        appRemote?.contentAPI?.fetchChildren(of: item) {[weak self] (children, error) in
            guard let self = self else { return } // 先解包 self
                guard let children = children as? [SPTAppRemoteContentItem], error == nil else { return }
                
            // 1️⃣ 序列化所有子节点
                let serializedChildren = children.map {
                    self.saveContentItem($0)//保存在字典合集中
                    return self.serializeItem($0)
                }

                // 2️⃣ 封装为列表结构（和 root 一致）
                let childListPayload: [String: Any] = [
                    "limit": serializedChildren.count,
                    "offset": 0,
                    "total": serializedChildren.count,
                    "items": serializedChildren
                ]

                // 3️⃣ 发送一个完整的 "child_list" 事件
                self.contentStreamHandler?.send([
                    "type": "child_list",
                    "parent": item.identifier,
                    "data": childListPayload
                ])
            
                for child in children where child.isContainer {
                    self.fetchChildrenRecursive(of: child)
                }
        }
    }

    private func serializeItem(_ item: SPTAppRemoteContentItem) -> [String: Any] {
        return [
            "id": item.identifier,
            "uri": item.uri,
            "title": item.title ?? "",
            "subtitle": item.subtitle ?? "",
            "playable": item.isPlayable,
            "has_children": item.isContainer,
            "is_pinned": item.isPinned
        ]
    }
    func saveContentItem(_ item: SPTAppRemoteContentItem) {
        let id = item.identifier
        contentItems[id] = item
    }

    func getContentItem(id: String) -> SPTAppRemoteContentItem? {
        return contentItems[id]
    }


    
    private func connectToSpotify(clientId: String, redirectURL: String, accessToken: String? = nil, spotifyUri: String = "", asRadio: Bool?, additionalScopes: String? = nil) throws {
//        func configureAppRemote(clientID: String, redirectURL: String, accessToken: String? = nil) throws {
//            guard let redirectURL = URL(string: redirectURL) else {
//                throw SpotifyError.redirectURLInvalid
//            }
//            let configuration = SPTConfiguration(clientID: clientID, redirectURL: redirectURL)
//            let appRemote = SPTAppRemote(configuration: configuration, logLevel: .none)
//            appRemote.delegate = connectionStatusHandler
//            appRemote.connectionParameters.accessToken = accessToken
//            self.appRemote = appRemote
//            
//            let playerDelegate = PlayerDelegate()
//            playerStateHandler = PlayerStateHandler(appRemote: appRemote, playerDelegate: playerDelegate)
//            SwiftSpotifySdkPlugin.playerStateChannel?.setStreamHandler(playerStateHandler)
//
//            playerContextHandler = PlayerContextHandler(appRemote: appRemote, playerDelegate: playerDelegate)
//            SwiftSpotifySdkPlugin.playerContextChannel?.setStreamHandler(playerContextHandler)
//        }
//
//        try configureAppRemote(clientID: clientId, redirectURL: redirectURL, accessToken: accessToken)

        var scopes: [String]?
        if let additionalScopes = additionalScopes {
            scopes = additionalScopes.components(separatedBy: ",")
        }

        if accessToken != nil {
            self.appRemote?.connect()
        } else {
          // Note: A blank string will play the user's last song or pick a random one.
          self.appRemote?.authorizeAndPlayURI(spotifyUri, asRadio: asRadio ?? false, additionalScopes: scopes) { success in
            if (!success) {
              self.connectionStatusHandler?.connectionResult?(FlutterError(code: "spotifyNotInstalled", message: "Spotify app is not installed", details: nil))
            }
          }
            let playerDelegate = PlayerDelegate()
            playerStateHandler = PlayerStateHandler(appRemote: self.appRemote!, playerDelegate: playerDelegate)
            SwiftSpotifySdkPlugin.playerStateChannel?.setStreamHandler(playerStateHandler)

            playerContextHandler = PlayerContextHandler(appRemote: self.appRemote!, playerDelegate: playerDelegate)
            SwiftSpotifySdkPlugin.playerContextChannel?.setStreamHandler(playerContextHandler)
        }
    }
}

extension SwiftSpotifySdkPlugin {
    public func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("application1");
        setAccessTokenFromURL(url: url)
        return true
    }

    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = userActivity.webpageURL
            else {
                connectionStatusHandler?.connectionResult?(FlutterError(code: "errorConnecting", message: "client id or redirectUrl is invalid", details: nil))
                connectionStatusHandler?.tokenResult?(FlutterError(code: "errorConnecting", message: "client id or redirectUrl is invalid", details: nil))
                connectionStatusHandler?.connectionResult = nil
                connectionStatusHandler?.tokenResult = nil
                return false
        }
        print("application2");
        setAccessTokenFromURL(url: url)
        return false
    }

    private func setAccessTokenFromURL(url: URL) {
        guard let appRemote = appRemote else {
            connectionStatusHandler?.connectionResult?(FlutterError(code: "errorConnection", message: "AppRemote is null", details: nil))
            connectionStatusHandler?.tokenResult?(FlutterError(code: "errorConnection", message: "AppRemote is null", details: nil))
            connectionStatusHandler?.connectionResult = nil
            connectionStatusHandler?.tokenResult = nil
            return
        }

        guard let token = appRemote.authorizationParameters(from: url)?[SPTAppRemoteAccessTokenKey] else {
            connectionStatusHandler?.connectionResult?(FlutterError(code: "authenticationTokenError", message: appRemote.authorizationParameters(from: url)?[SPTAppRemoteErrorDescriptionKey], details: nil))
            connectionStatusHandler?.tokenResult?(FlutterError(code: "authenticationTokenError", message: appRemote.authorizationParameters(from: url)?[SPTAppRemoteErrorDescriptionKey], details: nil))
            connectionStatusHandler?.connectionResult = nil
            connectionStatusHandler?.tokenResult = nil
            return
        }

        print("setAccessTokenFromURL:"+token);
        
        connectionStatusHandler?.accessToken = token;
        appRemote.connectionParameters.accessToken = token
        appRemote.connect()
    }
    
    func debugPrintObjCProperties(_ object: AnyObject) {
        let mirrorClass: AnyClass = type(of: object)
        var count: UInt32 = 0
        if let properties = class_copyPropertyList(mirrorClass, &count) {
            print("----- \(mirrorClass) -----")
            for i in 0..<Int(count) {
                let property = properties[i]
                if let name = NSString(utf8String: property_getName(property)) {
                    if let value = object.value(forKey: name as String) {
                        print("\(name): \(value)")
                    } else {
                        print("\(name): nil")
                    }
                }
            }
            print("----------------------------")
            free(properties)
        } else {
            print("⚠️ No properties found for \(mirrorClass)")
        }
    }
}
