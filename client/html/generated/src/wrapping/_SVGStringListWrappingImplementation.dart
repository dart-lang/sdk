// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGStringListWrappingImplementation extends DOMWrapperBase implements SVGStringList {
  SVGStringListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get numberOfItems() { return _ptr.numberOfItems; }

  String appendItem(String item) {
    return _ptr.appendItem(item);
  }

  void clear() {
    _ptr.clear();
    return;
  }

  String getItem(int index) {
    return _ptr.getItem(index);
  }

  String initialize(String item) {
    return _ptr.initialize(item);
  }

  String insertItemBefore(String item, int index) {
    return _ptr.insertItemBefore(item, index);
  }

  String removeItem(int index) {
    return _ptr.removeItem(index);
  }

  String replaceItem(String item, int index) {
    return _ptr.replaceItem(item, index);
  }
}
