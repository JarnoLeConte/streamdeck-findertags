//
//  Tags.swift
//  Plugin
//
//  Created by Jarno Le Conté on 27/10/2019.
//  Copyright © 2019 Jarno Le Conté. All rights reserved.
//

import Foundation

typealias Tag = (Color, String)

enum Color: Int {
    case Custom = 0
    case Gray = 1
    case Green = 2
    case Purple = 3
    case Blue = 4
    case Yellow = 5
    case Red = 6
    case Orange = 7
}

let colorTags: [Tag] = [
    (.Red, "Red"),
    (.Orange, "Orange"),
    (.Yellow, "Yellow"),
    (.Green, "Green"),
    (.Blue, "Blue"),
    (.Purple, "Purple"),
    (.Gray, "Gray"),
]

class Tagger {
    let localizedColorTags: [Tag] = {
        // this doesn't work if the app is Sandboxed:
        // the users would have to point to the file themselves with NSOpenPanel
        let url = URL(fileURLWithPath: "\(NSHomeDirectory())/Library/SyncedPreferences/com.apple.finder.plist")
        let keyPath = "values.FinderTagDict.value.FinderTags"
        if let d = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: d, options: [], format: nil),
            let pdict = plist as? NSDictionary,
            let ftags = pdict.value(forKeyPath: keyPath) as? [[AnyHashable: Any]] {
            var list = [(Color, String)]()
            // with '.count == 2' we ignore non-system labels
            for item in ftags where item.values.count == 2 {
                if let name = item["n"] as? String,
                    let number = item["l"] as? Int,
                    number >= 1 && number <= 7 {
                    list.append((Color(rawValue: number)!, name))
                }
            }
            
            return list.sorted { $0.0.rawValue < $1.0.rawValue }
        }
        return []
    }()
    
    func localize(tag: Tag) -> Tag {
        // Try to localize
        if colorTags.contains(where: { $1.capitalized == tag.1.capitalized }),
            let localizedTag = localizedColorTags.first(where: { $0.0 == tag.0 }) {
            return localizedTag
        }
        return tag
    }
    
    func delocalize(tag: Tag) ->  Tag {
        // Try to undo the localization
        if localizedColorTags.contains(where: { $1.capitalized == tag.1.capitalized }),
            let englishTag = colorTags.first(where: { $0.0 == tag.0 }) {
            return englishTag
        }
        return tag
    }
    
    func propertyListData(tags: [Tag]) throws -> Data {
        let labelStrings = tags.map { "\($0.1)\n\($0.0.rawValue)" }
        return try PropertyListSerialization.data(fromPropertyList: labelStrings, format: .binary, options: 0)
    }
    
    func propertyList(data: Data) throws -> [Tag] {
        let pListObject = try PropertyListSerialization.propertyList(from: data, options: PropertyListSerialization.ReadOptions(), format: nil)
        if let labelStrings = pListObject as? [String] {
            return labelStrings.map { label -> Tag in
                let components = label.components(separatedBy: "\n")
                let color = Color(rawValue: components.count >= 2 ? Int(components[1]) ?? 0 : 0) ?? .Custom
                let name = components[0]
                return (color, name)
            }
        }
        return []
    }
    
    public func set(tags: [Tag], to url: URL, localization: Bool = true) throws {
        // 'setExtendedAttributeData' is part of https://github.com/billgarrison/SOExtendedAttributes
       
        // To be sure the tags will be set correctly, we will remove existing tags first.
        // It's important that this done through the "setResourceValue:forKey:(NSURLTagNamesKey)" method
        // because it will overrule tags set by the user manually, which the xattr method (below) can't always do.
        try? (url as NSURL).setResourceValue([], forKey: URLResourceKey(rawValue: "NSURLTagNamesKey"))
        
        // Now we set the new tags, but instead of using the "setResourceValue:forKey:(NSURLTagNamesKey)"
        // which is meant to be used to set the tags, we use an other method "xattr" becaue that is the
        // only method capable of setting a color to a custom tag.
        let data = try propertyListData(tags: tags.map({ localization ? localize(tag: $0) : $0 }))
        try (url as NSURL).setExtendedAttributeData(data, name: "com.apple.metadata:_kMDItemUserTags")
    }
    
    public func getTags(from url: URL, delocalization: Bool = true) -> [Tag] {
        // data(forExtendedAttribute:) is part of https://github.com/billgarrison/SOExtendedAttributes
        if let data = try? (url as NSURL).data(forExtendedAttribute: "com.apple.metadata:_kMDItemUserTags"),
            let tags = try? propertyList(data: data) {
            return tags.map { delocalization ? delocalize(tag: $0) : $0 }
        }
        return []
    }
}
