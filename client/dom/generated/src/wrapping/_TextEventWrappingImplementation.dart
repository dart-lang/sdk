// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _TextEventWrappingImplementation extends _UIEventWrappingImplementation implements TextEvent {
  _TextEventWrappingImplementation() : super() {}

  static create__TextEventWrappingImplementation() native {
    return new _TextEventWrappingImplementation();
  }

  String get data() { return _get_data(this); }
  static String _get_data(var _this) native;

  void initTextEvent(String typeArg, bool canBubbleArg, bool cancelableArg, DOMWindow viewArg, String dataArg) {
    _initTextEvent(this, typeArg, canBubbleArg, cancelableArg, viewArg, dataArg);
    return;
  }
  static void _initTextEvent(receiver, typeArg, canBubbleArg, cancelableArg, viewArg, dataArg) native;

  String get typeName() { return "TextEvent"; }
}
