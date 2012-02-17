// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _PeerConnectionWrappingImplementation extends DOMWrapperBase implements PeerConnection {
  _PeerConnectionWrappingImplementation() : super() {}

  static create__PeerConnectionWrappingImplementation() native {
    return new _PeerConnectionWrappingImplementation();
  }

  MediaStreamList get localStreams() { return _get_localStreams(this); }
  static MediaStreamList _get_localStreams(var _this) native;

  EventListener get onaddstream() { return _get_onaddstream(this); }
  static EventListener _get_onaddstream(var _this) native;

  void set onaddstream(EventListener value) { _set_onaddstream(this, value); }
  static void _set_onaddstream(var _this, EventListener value) native;

  EventListener get onconnecting() { return _get_onconnecting(this); }
  static EventListener _get_onconnecting(var _this) native;

  void set onconnecting(EventListener value) { _set_onconnecting(this, value); }
  static void _set_onconnecting(var _this, EventListener value) native;

  EventListener get onmessage() { return _get_onmessage(this); }
  static EventListener _get_onmessage(var _this) native;

  void set onmessage(EventListener value) { _set_onmessage(this, value); }
  static void _set_onmessage(var _this, EventListener value) native;

  EventListener get onopen() { return _get_onopen(this); }
  static EventListener _get_onopen(var _this) native;

  void set onopen(EventListener value) { _set_onopen(this, value); }
  static void _set_onopen(var _this, EventListener value) native;

  EventListener get onremovestream() { return _get_onremovestream(this); }
  static EventListener _get_onremovestream(var _this) native;

  void set onremovestream(EventListener value) { _set_onremovestream(this, value); }
  static void _set_onremovestream(var _this, EventListener value) native;

  EventListener get onstatechange() { return _get_onstatechange(this); }
  static EventListener _get_onstatechange(var _this) native;

  void set onstatechange(EventListener value) { _set_onstatechange(this, value); }
  static void _set_onstatechange(var _this, EventListener value) native;

  int get readyState() { return _get_readyState(this); }
  static int _get_readyState(var _this) native;

  MediaStreamList get remoteStreams() { return _get_remoteStreams(this); }
  static MediaStreamList _get_remoteStreams(var _this) native;

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

  void addStream(MediaStream stream) {
    _addStream(this, stream);
    return;
  }
  static void _addStream(receiver, stream) native;

  void close() {
    _close(this);
    return;
  }
  static void _close(receiver) native;

  bool dispatchEvent(Event event) {
    return _dispatchEvent(this, event);
  }
  static bool _dispatchEvent(receiver, event) native;

  void processSignalingMessage(String message) {
    _processSignalingMessage(this, message);
    return;
  }
  static void _processSignalingMessage(receiver, message) native;

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

  void removeStream(MediaStream stream) {
    _removeStream(this, stream);
    return;
  }
  static void _removeStream(receiver, stream) native;

  void send(String text) {
    _send(this, text);
    return;
  }
  static void _send(receiver, text) native;

  String get typeName() { return "PeerConnection"; }
}
