//
//  AppleScript.swift
//  Plugin
//
//  Created by Jarno Le Conté on 27/10/2019.
//  Copyright © 2019 Jarno Le Conté. All rights reserved.
//

import Foundation

// AppleScript that will add the provided tags to folders and files
// that are currently selected in the finder
func scriptForAdding(tags: [String]) -> String {
    let inlineTags = tags.map({ "\"\($0)\"" }).joined(separator: ", ")
    return """
    use framework "Foundation"
    use scripting additions

    set tagList to {\(inlineTags)}

    tell application "Finder"
    set selected to selection
    repeat with n_file in every item in selected
    (my addTags:tagList forPath:(POSIX path of (selected as alias)))
    end repeat
    end tell

    on addTags:tagList forPath:p -- add to the existing tags
    set resultList to tagList
    set u to current application's |NSURL|'s fileURLWithPath:p
    set {theResult, theTags} to u's getResourceValue:(reference) forKey:(current application's NSURLTagNamesKey) |error|:(missing value)
    if theTags ≠ missing value then -- add new tags
    set resultList to (theTags as list) & tagList
    set resultList to (current application's NSOrderedSet's orderedSetWithArray:resultList)'s allObjects()
    end if
    u's setResourceValue:resultList forKey:(current application's NSURLTagNamesKey) |error|:(missing value)
    end addTags:forPath:
    """;
}

// AppleScript that will remove the provided tags from folders and files
// that are currently selected in the finder
func scriptForRemoving(tags: [String]) -> String {
    let inlineTags = tags.map({ "\"\($0)\"" }).joined(separator: ", ")
    return """
    use framework "Foundation"
    use scripting additions

    set tagList to {\(inlineTags)}

    tell application "Finder"
    set selected to selection
    repeat with n_file in every item in selected
    (my removeTags:tagList forPath:(POSIX path of (selected as alias)))
    end repeat
    end tell

    on removeTags:tagList forPath:p -- remove from the existing tags
    set resultList to {}
    set u to current application's |NSURL|'s fileURLWithPath:p
    set {theResult, theTags} to u's getResourceValue:(reference) forKey:(current application's NSURLTagNamesKey) |error|:(missing value)
    if theTags ≠ missing value then -- remove tags
    set theTagsList to (theTags as list)
    repeat with i from 1 to count theTagsList
    if {theTagsList's item i} is not in tagList then set resultList's end to theTagsList's item i
    end repeat
    set resultList to (current application's NSOrderedSet's orderedSetWithArray:resultList)'s allObjects()
    end if
    u's setResourceValue:resultList forKey:(current application's NSURLTagNamesKey) |error|:(missing value)
    end removeTags:forPath:
    """;
}

func executeAppleScript(source: String) {
    var error: NSDictionary?
    let script = NSAppleScript.init(source: source);
    script?.executeAndReturnError(&error)
    if error != nil {
        NSLog("AppleScript ERROR");
    }
}
