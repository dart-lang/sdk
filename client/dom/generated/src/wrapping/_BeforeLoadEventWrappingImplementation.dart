// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _BeforeLoadEventWrappingImplementation extends _EventWrappingImplementation implements BeforeLoadEvent {
  _BeforeLoadEventWrappingImplementation() : super() {}

  static create__BeforeLoadEventWrappingImplementation() native {
    return new _BeforeLoadEventWrappingImplementation();
  }

  String get url() { return _get__BeforeLoadEvent_url(this); }
  static String _get__BeforeLoadEvent_url(var _this) native;

  void initBeforeLoadEvent(String type, bool canBubble, bool cancelable, String url) {
    _initBeforeLoadEvent(this, type, canBubble, cancelable, url);
    return;
  }
  static void _initBeforeLoadEvent(receiver, type, canBubble, cancelable, url) native;

  String get typeName() { return "BeforeLoadEvent"; }
}
