extension Collection {
    subscript(optionallyAt index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

/*
 * Copyright 2010-2018 JetBrains s.r.o. and Kotlin Programming Language contributors.
 * Use of this source code is governed by the Apache 2.0 license that can be found in the
 * https://github.com/JetBrains/kotlin/blob/master/license/LICENSE.txt file.
 *
 * The below code was modified from the original.
 */

extension String {
    // Modified from Kotlin (Apache License, Version 2.0). See LICENSE in this repo
    public func substring(startOffset: Int, endOffset: Int) -> String {
        let substringStartIndex = index(startIndex, offsetBy: startOffset)
        let substringEndIndex = index(startIndex, offsetBy: endOffset)
        return String(self[substringStartIndex ..< substringEndIndex])
    }

    public func substring(startOffset: Int) -> String {
        let endOffset = startOffset + 1
        if endOffset > count {
            return ""
        }
        return substring(startOffset: startOffset, endOffset: endOffset)
    }

    subscript(intIndex intIndex: Int) -> String {
        substring(startOffset: intIndex)
    }

    func slice(_ offset: Int) -> String {
        substring(startOffset: offset, endOffset: count)
    }
}
