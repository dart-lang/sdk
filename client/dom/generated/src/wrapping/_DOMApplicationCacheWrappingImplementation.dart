// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DOMApplicationCacheWrappingImplementation extends DOMWrapperBase implements DOMApplicationCache {
  _DOMApplicationCacheWrappingImplementation() : super() {}

  static create__DOMApplicationCacheWrappingImplementation() native {
    return new _DOMApplicationCacheWrappingImplementation();
  }

  int get status() { return _get_status(this); }
  static int _get_status(var _this) native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _addEventListener_DOMApplicationCache(this, type, listener);
      return;
    } else {
      _addEventListener_DOMApplicationCache_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _addEventListener_DOMApplicationCache(receiver, type, listener) native;
  static void _addEventListener_DOMApplicationCache_2(receiver, type, listener, useCapture) native;

  bool dispatchEvent(Event evt) {
    return _dispatchEvent_DOMApplicationCache(this, evt);
  }
  static bool _dispatchEvent_DOMApplicationCache(receiver, evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _removeEventListener_DOMApplicationCache(this, type, listener);
      return;
    } else {
      _removeEventListener_DOMApplicationCache_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _removeEventListener_DOMApplicationCache(receiver, type, listener) native;
  static void _removeEventListener_DOMApplicationCache_2(receiver, type, listener, useCapture) native;

  void swapCache() {
    _swapCache(this);
    return;
  }
  static void _swapCache(receiver) native;

  void update() {
    _update(this);
    return;
  }
  static void _update(receiver) native;

  String get typeName() { return "DOMApplicationCache"; }
}
