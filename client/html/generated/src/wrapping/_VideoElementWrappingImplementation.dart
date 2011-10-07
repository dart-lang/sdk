// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class VideoElementWrappingImplementation extends MediaElementWrappingImplementation implements VideoElement {
  VideoElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get height() { return _ptr.height; }

  void set height(int value) { _ptr.height = value; }

  String get poster() { return _ptr.poster; }

  void set poster(String value) { _ptr.poster = value; }

  int get videoHeight() { return _ptr.videoHeight; }

  int get videoWidth() { return _ptr.videoWidth; }

  int get webkitDecodedFrameCount() { return _ptr.webkitDecodedFrameCount; }

  bool get webkitDisplayingFullscreen() { return _ptr.webkitDisplayingFullscreen; }

  int get webkitDroppedFrameCount() { return _ptr.webkitDroppedFrameCount; }

  bool get webkitSupportsFullscreen() { return _ptr.webkitSupportsFullscreen; }

  int get width() { return _ptr.width; }

  void set width(int value) { _ptr.width = value; }

  void webkitEnterFullScreen() {
    _ptr.webkitEnterFullScreen();
    return;
  }

  void webkitEnterFullscreen() {
    _ptr.webkitEnterFullscreen();
    return;
  }

  void webkitExitFullScreen() {
    _ptr.webkitExitFullScreen();
    return;
  }

  void webkitExitFullscreen() {
    _ptr.webkitExitFullscreen();
    return;
  }
}
