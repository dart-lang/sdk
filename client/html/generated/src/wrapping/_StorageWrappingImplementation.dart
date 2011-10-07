// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StorageWrappingImplementation extends DOMWrapperBase implements Storage {
  StorageWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  void clear() {
    _ptr.clear();
    return;
  }

  String getItem(String key) {
    return _ptr.getItem(key);
  }

  String key(int index) {
    return _ptr.key(index);
  }

  void removeItem(String key) {
    _ptr.removeItem(key);
    return;
  }

  void setItem(String key, String data) {
    _ptr.setItem(key, data);
    return;
  }
}
