// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMTokenListWrappingImplementation extends DOMWrapperBase implements DOMTokenList {
  DOMTokenListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  void add(String token) {
    _ptr.add(token);
    return;
  }

  bool contains(String token) {
    return _ptr.contains(token);
  }

  String item(int index) {
    return _ptr.item(index);
  }

  void remove(String token) {
    _ptr.remove(token);
    return;
  }

  bool toggle(String token) {
    return _ptr.toggle(token);
  }
}
