// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLVideoElementWrappingImplementation extends _HTMLMediaElementWrappingImplementation implements HTMLVideoElement {
  _HTMLVideoElementWrappingImplementation() : super() {}

  static create__HTMLVideoElementWrappingImplementation() native {
    return new _HTMLVideoElementWrappingImplementation();
  }

  int get height() { return _get_height(this); }
  static int _get_height(var _this) native;

  void set height(int value) { _set_height(this, value); }
  static void _set_height(var _this, int value) native;

  String get poster() { return _get_poster(this); }
  static String _get_poster(var _this) native;

  void set poster(String value) { _set_poster(this, value); }
  static void _set_poster(var _this, String value) native;

  int get videoHeight() { return _get_videoHeight(this); }
  static int _get_videoHeight(var _this) native;

  int get videoWidth() { return _get_videoWidth(this); }
  static int _get_videoWidth(var _this) native;

  int get webkitDecodedFrameCount() { return _get_webkitDecodedFrameCount(this); }
  static int _get_webkitDecodedFrameCount(var _this) native;

  bool get webkitDisplayingFullscreen() { return _get_webkitDisplayingFullscreen(this); }
  static bool _get_webkitDisplayingFullscreen(var _this) native;

  int get webkitDroppedFrameCount() { return _get_webkitDroppedFrameCount(this); }
  static int _get_webkitDroppedFrameCount(var _this) native;

  bool get webkitSupportsFullscreen() { return _get_webkitSupportsFullscreen(this); }
  static bool _get_webkitSupportsFullscreen(var _this) native;

  int get width() { return _get_width(this); }
  static int _get_width(var _this) native;

  void set width(int value) { _set_width(this, value); }
  static void _set_width(var _this, int value) native;

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
