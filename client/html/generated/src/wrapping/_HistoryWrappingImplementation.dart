// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class HistoryWrappingImplementation extends DOMWrapperBase implements History {
  HistoryWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  void back() {
    _ptr.back();
    return;
  }

  void forward() {
    _ptr.forward();
    return;
  }

  void go(int distance) {
    _ptr.go(distance);
    return;
  }

  void pushState(Object data, String title, [String url = null]) {
    if (url === null) {
      _ptr.pushState(LevelDom.unwrapMaybePrimitive(data), title);
      return;
    } else {
      _ptr.pushState(LevelDom.unwrapMaybePrimitive(data), title, url);
      return;
    }
  }

  void replaceState(Object data, String title, [String url = null]) {
    if (url === null) {
      _ptr.replaceState(LevelDom.unwrapMaybePrimitive(data), title);
      return;
    } else {
      _ptr.replaceState(LevelDom.unwrapMaybePrimitive(data), title, url);
      return;
    }
  }
}
