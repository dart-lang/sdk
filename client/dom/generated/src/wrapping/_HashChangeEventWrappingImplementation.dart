// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HashChangeEventWrappingImplementation extends _EventWrappingImplementation implements HashChangeEvent {
  _HashChangeEventWrappingImplementation() : super() {}

  static create__HashChangeEventWrappingImplementation() native {
    return new _HashChangeEventWrappingImplementation();
  }

  String get newURL() { return _get_newURL(this); }
  static String _get_newURL(var _this) native;

  String get oldURL() { return _get_oldURL(this); }
  static String _get_oldURL(var _this) native;

  void initHashChangeEvent(String type, bool canBubble, bool cancelable, String oldURL, String newURL) {
    _initHashChangeEvent(this, type, canBubble, cancelable, oldURL, newURL);
    return;
  }
  static void _initHashChangeEvent(receiver, type, canBubble, cancelable, oldURL, newURL) native;

  String get typeName() { return "HashChangeEvent"; }
}
