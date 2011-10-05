// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLVideoElementWrappingImplementation extends _HTMLMediaElementWrappingImplementation implements HTMLVideoElement {
  _HTMLVideoElementWrappingImplementation() : super() {}

  static create__HTMLVideoElementWrappingImplementation() native {
    return new _HTMLVideoElementWrappingImplementation();
  }

  int get height() { return _get__HTMLVideoElement_height(this); }
  static int _get__HTMLVideoElement_height(var _this) native;

  void set height(int value) { _set__HTMLVideoElement_height(this, value); }
  static void _set__HTMLVideoElement_height(var _this, int value) native;

  String get poster() { return _get__HTMLVideoElement_poster(this); }
  static String _get__HTMLVideoElement_poster(var _this) native;

  void set poster(String value) { _set__HTMLVideoElement_poster(this, value); }
  static void _set__HTMLVideoElement_poster(var _this, String value) native;

  int get videoHeight() { return _get__HTMLVideoElement_videoHeight(this); }
  static int _get__HTMLVideoElement_videoHeight(var _this) native;

  int get videoWidth() { return _get__HTMLVideoElement_videoWidth(this); }
  static int _get__HTMLVideoElement_videoWidth(var _this) native;

  int get webkitDecodedFrameCount() { return _get__HTMLVideoElement_webkitDecodedFrameCount(this); }
  static int _get__HTMLVideoElement_webkitDecodedFrameCount(var _this) native;

  bool get webkitDisplayingFullscreen() { return _get__HTMLVideoElement_webkitDisplayingFullscreen(this); }
  static bool _get__HTMLVideoElement_webkitDisplayingFullscreen(var _this) native;

  int get webkitDroppedFrameCount() { return _get__HTMLVideoElement_webkitDroppedFrameCount(this); }
  static int _get__HTMLVideoElement_webkitDroppedFrameCount(var _this) native;

  bool get webkitSupportsFullscreen() { return _get__HTMLVideoElement_webkitSupportsFullscreen(this); }
  static bool _get__HTMLVideoElement_webkitSupportsFullscreen(var _this) native;

  int get width() { return _get__HTMLVideoElement_width(this); }
  static int _get__HTMLVideoElement_width(var _this) native;

  void set width(int value) { _set__HTMLVideoElement_width(this, value); }
  static void _set__HTMLVideoElement_width(var _this, int value) native;

  void webkitEnterFullScreen() {
    _webkitEnterFullScreen(this);
    return;
  }
  static void _webkitEnterFullScreen(receiver) native;

  void webkitEnterFullscreen() {
    _webkitEnterFullscreen(this);
    return;
  }
  static void _webkitEnterFullscreen(receiver) native;

  void webkitExitFullScreen() {
    _webkitExitFullScreen(this);
    return;
  }
  static void _webkitExitFullScreen(receiver) native;

  void webkitExitFullscreen() {
    _webkitExitFullscreen(this);
    return;
  }
  static void _webkitExitFullscreen(receiver) native;

  String get typeName() { return "HTMLVideoElement"; }
}
