// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class TextWrappingImplementation extends CharacterDataWrappingImplementation implements Text {
  factory TextWrappingImplementation(String content) {
    return new TextWrappingImplementation._wrap(
        dom.document.createTextNode(content));
  }

  TextWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  String get wholeText() => _ptr.wholeText;

  Text replaceWholeText([String content = null]) {
    if (content === null) {
      return LevelDom.wrapText(_ptr.replaceWholeText());
    } else {
      return LevelDom.wrapText(_ptr.replaceWholeText(content));
    }
  }

  Text splitText([int offset = null]) {
    if (offset === null) {
      return LevelDom.wrapText(_ptr.splitText());
    } else {
      return LevelDom.wrapText(_ptr.splitText(offset));
    }
  }
}
