// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DOMApplicationCacheWrappingImplementation extends DOMWrapperBase implements DOMApplicationCache {
  _DOMApplicationCacheWrappingImplementation() : super() {}

  static create__DOMApplicationCacheWrappingImplementation() native {
    return new _DOMApplicationCacheWrappingImplementation();
  }

  EventListener get oncached() { return _get_oncached(this); }
  static EventListener _get_oncached(var _this) native;

  void set oncached(EventListener value) { _set_oncached(this, value); }
  static void _set_oncached(var _this, EventListener value) native;

  EventListener get onchecking() { return _get_onchecking(this); }
  static EventListener _get_onchecking(var _this) native;

  void set onchecking(EventListener value) { _set_onchecking(this, value); }
  static void _set_onchecking(var _this, EventListener value) native;

  EventListener get ondownloading() { return _get_ondownloading(this); }
  static EventListener _get_ondownloading(var _this) native;

  void set ondownloading(EventListener value) { _set_ondownloading(this, value); }
  static void _set_ondownloading(var _this, EventListener value) native;

  EventListener get onerror() { return _get_onerror(this); }
  static EventListener _get_onerror(var _this) native;

  void set onerror(EventListener value) { _set_onerror(this, value); }
  static void _set_onerror(var _this, EventListener value) native;

  EventListener get onnoupdate() { return _get_onnoupdate(this); }
  static EventListener _get_onnoupdate(var _this) native;

  void set onnoupdate(EventListener value) { _set_onnoupdate(this, value); }
  static void _set_onnoupdate(var _this, EventListener value) native;

  EventListener get onobsolete() { return _get_onobsolete(this); }
  static EventListener _get_onobsolete(var _this) native;

  void set onobsolete(EventListener value) { _set_onobsolete(this, value); }
  static void _set_onobsolete(var _this, EventListener value) native;

  EventListener get onprogress() { return _get_onprogress(this); }
  static EventListener _get_onprogress(var _this) native;

  void set onprogress(EventListener value) { _set_onprogress(this, value); }
  static void _set_onprogress(var _this, EventListener value) native;

  EventListener get onupdateready() { return _get_onupdateready(this); }
  static EventListener _get_onupdateready(var _this) native;

  void set onupdateready(EventListener value) { _set_onupdateready(this, value); }
  static void _set_onupdateready(var _this, EventListener value) native;

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
