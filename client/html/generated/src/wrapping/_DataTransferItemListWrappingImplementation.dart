// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DataTransferItemListWrappingImplementation extends DOMWrapperBase implements DataTransferItemList {
  DataTransferItemListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  void add(String data, String type) {
    _ptr.add(data, type);
    return;
  }

  void clear() {
    _ptr.clear();
    return;
  }

  DataTransferItem item(int index) {
    return LevelDom.wrapDataTransferItem(_ptr.item(index));
  }
}
