// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MediaStreamWrappingImplementation extends DOMWrapperBase implements MediaStream {
  _MediaStreamWrappingImplementation() : super() {}

  static create__MediaStreamWrappingImplementation() native {
    return new _MediaStreamWrappingImplementation();
  }

  String get label() { return _get__MediaStream_label(this); }
  static String _get__MediaStream_label(var _this) native;

  EventListener get onended() { return _get__MediaStream_onended(this); }
  static EventListener _get__MediaStream_onended(var _this) native;

  void set onended(EventListener value) { _set__MediaStream_onended(this, value); }
  static void _set__MediaStream_onended(var _this, EventListener value) native;

  int get readyState() { return _get__MediaStream_readyState(this); }
  static int _get__MediaStream_readyState(var _this) native;

  MediaStreamTrackList get tracks() { return _get__MediaStream_tracks(this); }
  static MediaStreamTrackList _get__MediaStream_tracks(var _this) native;

  void addEventListener(String type, EventListener listener, bool useCapture = null) {
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

  bool dispatchEvent(Event event) {
    return _dispatchEvent(this, event);
  }
  static bool _dispatchEvent(receiver, event) native;

  void removeEventListener(String type, EventListener listener, bool useCapture = null) {
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

  String get typeName() { return "MediaStream"; }
}
