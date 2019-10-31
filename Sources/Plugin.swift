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
    var knownContexts: [Any] = []
    let tagger = Tagger()
    let colorTags: [Tag] = [
        (.Red, "Red"),
        (.Orange, "Orange"),
        (.Yellow, "Yellow"),
        (.Green, "Green"),
        (.Blue, "Blue"),
        (.Purple, "Purple"),
        (.Gray, "Gray"),
    ]

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
    
    public func keyDown(forAction action: String, withContext context: Any, withPayload payload: [AnyHashable : Any], forDevice deviceID: String) {
        guard let selectedFileUrls = getSelectedFileUrls() else { return }
        
        // Clear all tags from the selected files
        if action.starts(with: "me.hckr.findertags.clear-tags") {
            setTags([], for: selectedFileUrls)
        }
        // Rotate color, which replace the current color by the next color on the color wheel
        if action.starts(with: "me.hckr.findertags.color-wheel") {
            let tags = getCommonTags(for: selectedFileUrls)
            let nextTags: [Tag] = {
                let index = tags.count == 0 ? -1 : colorTags.firstIndex(where: { $0.1 == tags[0].1 }) ?? -1
                let nextIndex = index == colorTags.count - 1 ? -1 : index + 1
                return nextIndex == -1 ? [] : [colorTags[nextIndex]]
            }();
            setTags(nextTags, for: selectedFileUrls)
        }
        // Add or remove (toggle) a custom tag
        if action.starts(with: "me.hckr.findertags.custom-tag") {
            let settings = payload["settings"] as? [AnyHashable : Any];
            if let tagName = settings?["tag"] as? String,
                let tagColor = settings?["color"] as? String {
                let tags = getCommonTags(for: selectedFileUrls)
                if tags.contains(where: { $0.1 == tagName }) {
                    setTags(tags.filter({ $0.1 != tagName }), for: selectedFileUrls)
                } else {
                    let newTag = (color(for: tagColor), tagName)
                    setTags(tags + [newTag], for: selectedFileUrls)
                }
            } else {
                connectionManager?.showAlert(forContext: context)
            }
        }
        // Add or remove (toggle) a single color
        else if action.starts(with: "me.hckr.findertags.tag-") {
            let colorName = action.replacingOccurrences(of: "me.hckr.findertags.tag-", with: "").capitalized;
            let tags = getCommonTags(for: selectedFileUrls)
            
            if tags.contains(where: { $0.1 == colorName }) {
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
        // Add the context to the list of known contexts
        knownContexts.append(context)
    }
    
    public func willDisappear(forAction action: String, withContext context: Any, withPayload payload: [AnyHashable : Any], forDevice deviceID: String) {
        // Remove the context from the list of known contexts
        knownContexts.removeAll { isEqualContext($0, context) }
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
}

