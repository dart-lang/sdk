// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MediaQueryListWrappingImplementation extends DOMWrapperBase implements MediaQueryList {
  MediaQueryListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get matches() { return _ptr.matches; }

  String get media() { return _ptr.media; }

  void addListener(MediaQueryListListener listener) {
    _ptr.addListener(LevelDom.unwrap(listener));
    return;
  }

  void removeListener(MediaQueryListListener listener) {
    _ptr.removeListener(LevelDom.unwrap(listener));
    return;
  }
}
