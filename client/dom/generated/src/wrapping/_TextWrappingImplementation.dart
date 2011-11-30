// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _TextWrappingImplementation extends _CharacterDataWrappingImplementation implements Text {
  _TextWrappingImplementation() : super() {}

  static create__TextWrappingImplementation() native {
    return new _TextWrappingImplementation();
  }

  String get wholeText() { return _get_wholeText(this); }
  static String _get_wholeText(var _this) native;

  Text replaceWholeText(String content) {
    return _replaceWholeText(this, content);
  }
  static Text _replaceWholeText(receiver, content) native;

  Text splitText(int offset) {
    return _splitText(this, offset);
  }
  static Text _splitText(receiver, offset) native;

  String get typeName() { return "Text"; }
}
