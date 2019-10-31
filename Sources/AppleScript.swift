//
//  AppleScript.swift
//  Plugin
//
//  Created by Jarno Le Conté on 27/10/2019.
//  Copyright © 2019 Jarno Le Conté. All rights reserved.
//

import Foundation

func scriptForGettingSelectedFiles() -> String {
    return """
    set selectedItems to {}

    tell application "Finder"
        set selected to selection
        repeat with anItem in every item in selected
            set itemPath to POSIX path of (anItem as alias)
            copy itemPath to end of selectedItems
        end repeat
    end tell

    return selectedItems
    """
}

func executeAppleScript(source: String) -> NSAppleEventDescriptor? {
    var error: NSDictionary?
    let script = NSAppleScript.init(source: source);
    let result = script?.executeAndReturnError(&error)
    
    if (error != nil) {
        NSLog("AppleScript ERROR");
        return nil;
    }
    
    return result;
}

extension NSAppleEventDescriptor {
  func toStringArray() -> [String] {
    guard let listDescriptor = self.coerce(toDescriptorType: typeAEList) else {
      return []
    }
    return (0..<listDescriptor.numberOfItems)
      .compactMap { listDescriptor.atIndex($0 + 1)?.stringValue }
  }
}
