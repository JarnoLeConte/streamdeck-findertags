//
//  Plugin.swift
//  A plug-in for Stream Deck
//
//  Created by Jarno Le Conté on 19/10/2019.
//  Copyright © 2019 Jarno Le Conté. All rights reserved.
//

import Foundation


public class Plugin: NSObject, ESDEventsProtocol {
    var connectionManager: ESDConnectionManager?
    
    let tagger = Tagger()

    public func setConnectionManager(_ connectionManager: ESDConnectionManager) {
        self.connectionManager = connectionManager
    }
    
    func color(for name: String) -> Color {
        return colorTags.first(where: { $0.1 == name })?.0 ?? .Custom
    }
    
    func getSelectedFileUrls() -> [URL]? {
        return executeAppleScript(source: scriptForGettingSelectedFiles())?
            .toStringArray()
            .map({ URL(fileURLWithPath: $0) })
    }
    
    func getCommonTags(for fileUrls: [URL]) -> [Tag] {
        let fileTags = fileUrls.map({ tagger.getTags(from: $0) })
        
        // Figure out which tags all files have in common
        if fileTags.allSatisfy({ $0.map({ $1 }).sorted().elementsEqual(fileTags[0].map({ $1 }).sorted()) }) {
            return fileTags[0]
        }
        
        return []
    }
    
    func setTags(_ tags: [Tag], for fileUrls: [URL]) {
        fileUrls.forEach { fileUrl in
            try? tagger.set(tags: tags, to: fileUrl)
        }
    }
    
    func refreshImage(forAction action: String, withContext context: Any, withPayload payload: [AnyHashable : Any], forDevice deviceID: String) {
        if action.starts(with: "me.hckr.findertags.custom-tag") {
            let settings = payload["settings"] as? [AnyHashable : Any];
            if let tagColor = settings?["color"] as? String,
                let imagePath = Bundle.main.path(forResource: "images/\(tagColor)TagKey@2x", ofType: "png"),
                let imageData:NSData = NSData.init(contentsOfFile: imagePath) {
                let base64ImageData = imageData.base64EncodedString(options: .lineLength64Characters)
                let base64Image = "data:image/png;base64,\(base64ImageData)"
                connectionManager?.setImage(base64Image, withContext: context, withTarget: ESDSDKTarget.HardwareAndSoftware.rawValue)
            }
        }
        if action.starts(with: "me.hckr.findertags.color-wheel") {
            let settings = payload["settings"] as? [AnyHashable : Any];
            if let image = settings?["image"] as? String {
                connectionManager?.setImage(image, withContext: context, withTarget: ESDSDKTarget.HardwareAndSoftware.rawValue)
            }
        }
    }
    
    func refreshTitle(forAction action: String, withContext context: Any, withPayload payload: [AnyHashable : Any], forDevice deviceID: String) {
        if action.starts(with: "me.hckr.findertags.custom-tag") {
            let settings = payload["settings"] as? [AnyHashable : Any];
            let tagName = settings?["tag"] as? String
            let title = tagName != nil && tagName != "" ? tagName : "Custom"
            connectionManager?.setTitle(title, withContext: context, withTarget: ESDSDKTarget.HardwareAndSoftware.rawValue)
        }
        if action.starts(with: "me.hckr.findertags.tag-") {
            let colorName = action.replacingOccurrences(of: "me.hckr.findertags.tag-", with: "").capitalized;
            let localizedTag = tagger.localize(tag: (color(for: colorName), colorName))
            let title = localizedTag.1
            connectionManager?.setTitle(title, withContext: context, withTarget: ESDSDKTarget.HardwareAndSoftware.rawValue)
        }
    }
    
    public func keyDown(forAction action: String, withContext context: Any, withPayload payload: [AnyHashable : Any], forDevice deviceID: String) {
        guard let selectedFileUrls = getSelectedFileUrls() else { return }
        
        // Clear all tags from the selected files
        if action.starts(with: "me.hckr.findertags.clear-tags") {
            setTags([], for: selectedFileUrls)
        }
        // Rotate color, which replace the current color by the next color on the color wheel
        if action.starts(with: "me.hckr.findertags.color-wheel") {
            let tags = getCommonTags(for: selectedFileUrls)
            let settings = payload["settings"] as? [AnyHashable : Any];
            // Map color wheel configuration to a list of color tag tuples (enum: Color, tagName: String)
            let colorWheelTags = (settings?["tags"] as? [[AnyHashable : Any]])?
                .map { ($0["color"] as! String, $0["enabled"] as! Bool) }
                .filter { (_, enabled) in enabled }
                .compactMap { (colorName, _) in colorTags.first(where: { $1.capitalized == colorName.capitalized }) };
            let enabledColorTags = colorWheelTags != nil ? colorWheelTags! : colorTags
            let nextTags: [Tag] = {
                let index = tags.count == 0 ? -1 : enabledColorTags.firstIndex(where: { $0.1.capitalized == tags[0].1.capitalized }) ?? -1
                let nextIndex = index == enabledColorTags.count - 1 ? -1 : index + 1
                return nextIndex == -1 ? [] : [enabledColorTags[nextIndex]]
            }();
            setTags(nextTags, for: selectedFileUrls)
        }
        // Add or remove (toggle) a custom tag
        if action.starts(with: "me.hckr.findertags.custom-tag") {
            let settings = payload["settings"] as? [AnyHashable : Any];
            if let tagName = settings?["tag"] as? String,
                let tagColor = settings?["color"] as? String,
                tagName != "" {
                let localizedTag = tagger.delocalize(tag: (color(for: tagColor), tagName))
                let tags = getCommonTags(for: selectedFileUrls)
                if tags.contains(where: { $0.1.capitalized == localizedTag.1.capitalized }) {
                    setTags(tags.filter({ $0.1.capitalized != localizedTag.1.capitalized }), for: selectedFileUrls)
                } else {
                    setTags(tags + [localizedTag], for: selectedFileUrls)
                }
            } else {
                connectionManager?.showAlert(forContext: context)
            }
        }
        // Add or remove (toggle) a single color
        else if action.starts(with: "me.hckr.findertags.tag-") {
            let colorName = action.replacingOccurrences(of: "me.hckr.findertags.tag-", with: "").capitalized;
            let tags = getCommonTags(for: selectedFileUrls)
            
            if tags.contains(where: { $0.1.capitalized == colorName.capitalized }) {
                setTags(tags.filter({ $0.1 != colorName }), for: selectedFileUrls)
            } else {
                let newTag = (color(for: colorName), colorName)
                setTags(tags + [newTag], for: selectedFileUrls)
            }
        }
    }
    
    public func keyUp(forAction action: String, withContext context: Any, withPayload payload: [AnyHashable : Any], forDevice deviceID: String) {
        // Nothing to do
    }
    
    public func willAppear(forAction action: String, withContext context: Any, withPayload payload: [AnyHashable : Any], forDevice deviceID: String) {
        refreshImage(forAction: action, withContext: context, withPayload: payload, forDevice: deviceID)
        refreshTitle(forAction: action, withContext: context, withPayload: payload, forDevice: deviceID)
    }
    
    public func willDisappear(forAction action: String, withContext context: Any, withPayload payload: [AnyHashable : Any], forDevice deviceID: String) {
        // Nothing to do
    }
    public func deviceDidConnect(_ deviceID: String, withDeviceInfo deviceInfo: [AnyHashable : Any]) {
        // Nothing to do
    }
    
    public func deviceDidDisconnect(_ deviceID: String) {
        // Nothing to do
    }
    
    public func applicationDidLaunch(_ applicationInfo: [AnyHashable : Any]) {
        // Nothing to do
    }
    
    public func applicationDidTerminate(_ applicationInfo: [AnyHashable : Any]) {
        // Nothing to do
    }
    
    public func didReceiveSettings(forAction action: String, withContext context: Any, withPayload payload: [AnyHashable : Any], forDevice deviceID: String) {
        refreshImage(forAction: action, withContext: context, withPayload: payload, forDevice: deviceID)
        refreshTitle(forAction: action, withContext: context, withPayload: payload, forDevice: deviceID)
    }
}

