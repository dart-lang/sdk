// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _TextWrappingImplementation extends _CharacterDataWrappingImplementation implements Text {
  _TextWrappingImplementation() : super() {}

  static create__TextWrappingImplementation() native {
    return new _TextWrappingImplementation();
  }

  String get wholeText() { return _get__Text_wholeText(this); }
  static String _get__Text_wholeText(var _this) native;

  Text replaceWholeText(String content = null) {
    if (content === null) {
      return _replaceWholeText(this);
    } else {
      return _replaceWholeText_2(this, content);
    }
  }
  static Text _replaceWholeText(receiver) native;
  static Text _replaceWholeText_2(receiver, content) native;

  Text splitText(int offset = null) {
    if (offset === null) {
      return _splitText(this);
    } else {
      return _splitText_2(this, offset);
    }
  }
  static Text _splitText(receiver) native;
  static Text _splitText_2(receiver, offset) native;

  String get typeName() { return "Text"; }
}
