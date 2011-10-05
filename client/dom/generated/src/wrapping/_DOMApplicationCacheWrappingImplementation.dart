// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DOMApplicationCacheWrappingImplementation extends DOMWrapperBase implements DOMApplicationCache {
  _DOMApplicationCacheWrappingImplementation() : super() {}

  static create__DOMApplicationCacheWrappingImplementation() native {
    return new _DOMApplicationCacheWrappingImplementation();
  }

  EventListener get oncached() { return _get__DOMApplicationCache_oncached(this); }
  static EventListener _get__DOMApplicationCache_oncached(var _this) native;

  void set oncached(EventListener value) { _set__DOMApplicationCache_oncached(this, value); }
  static void _set__DOMApplicationCache_oncached(var _this, EventListener value) native;

  EventListener get onchecking() { return _get__DOMApplicationCache_onchecking(this); }
  static EventListener _get__DOMApplicationCache_onchecking(var _this) native;

  void set onchecking(EventListener value) { _set__DOMApplicationCache_onchecking(this, value); }
  static void _set__DOMApplicationCache_onchecking(var _this, EventListener value) native;

  EventListener get ondownloading() { return _get__DOMApplicationCache_ondownloading(this); }
  static EventListener _get__DOMApplicationCache_ondownloading(var _this) native;

  void set ondownloading(EventListener value) { _set__DOMApplicationCache_ondownloading(this, value); }
  static void _set__DOMApplicationCache_ondownloading(var _this, EventListener value) native;

  EventListener get onerror() { return _get__DOMApplicationCache_onerror(this); }
  static EventListener _get__DOMApplicationCache_onerror(var _this) native;

  void set onerror(EventListener value) { _set__DOMApplicationCache_onerror(this, value); }
  static void _set__DOMApplicationCache_onerror(var _this, EventListener value) native;

  EventListener get onnoupdate() { return _get__DOMApplicationCache_onnoupdate(this); }
  static EventListener _get__DOMApplicationCache_onnoupdate(var _this) native;

  void set onnoupdate(EventListener value) { _set__DOMApplicationCache_onnoupdate(this, value); }
  static void _set__DOMApplicationCache_onnoupdate(var _this, EventListener value) native;

  EventListener get onobsolete() { return _get__DOMApplicationCache_onobsolete(this); }
  static EventListener _get__DOMApplicationCache_onobsolete(var _this) native;

  void set onobsolete(EventListener value) { _set__DOMApplicationCache_onobsolete(this, value); }
  static void _set__DOMApplicationCache_onobsolete(var _this, EventListener value) native;

  EventListener get onprogress() { return _get__DOMApplicationCache_onprogress(this); }
  static EventListener _get__DOMApplicationCache_onprogress(var _this) native;

  void set onprogress(EventListener value) { _set__DOMApplicationCache_onprogress(this, value); }
  static void _set__DOMApplicationCache_onprogress(var _this, EventListener value) native;

  EventListener get onupdateready() { return _get__DOMApplicationCache_onupdateready(this); }
  static EventListener _get__DOMApplicationCache_onupdateready(var _this) native;

  void set onupdateready(EventListener value) { _set__DOMApplicationCache_onupdateready(this, value); }
  static void _set__DOMApplicationCache_onupdateready(var _this, EventListener value) native;

  int get status() { return _get__DOMApplicationCache_status(this); }
  static int _get__DOMApplicationCache_status(var _this) native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _addEventListener(this, type, listener);
      return;
    } else {
      _addEventListener_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _addEventListener(receiver, type, listener) native;
  static void _addEventListener_2(receiver, type, listener, useCapture) native;

  bool dispatchEvent(Event evt) {
    return _dispatchEvent(this, evt);
  }
  static bool _dispatchEvent(receiver, evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _removeEventListener(this, type, listener);
      return;
    } else {
      _removeEventListener_2(this, type, listener, useCapture);
      return;
    }
  }
  static void _removeEventListener(receiver, type, listener) native;
  static void _removeEventListener_2(receiver, type, listener, useCapture) native;

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
