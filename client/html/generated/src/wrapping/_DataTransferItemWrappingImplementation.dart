// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DataTransferItemWrappingImplementation extends DOMWrapperBase implements DataTransferItem {
  DataTransferItemWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get kind() { return _ptr.kind; }

  String get type() { return _ptr.type; }

  Blob getAsFile() {
    return LevelDom.wrapBlob(_ptr.getAsFile());
  }

  void getAsString(StringCallback callback) {
    _ptr.getAsString(LevelDom.unwrap(callback));
    return;
  }
}
