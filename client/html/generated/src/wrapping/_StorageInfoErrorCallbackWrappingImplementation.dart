// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StorageInfoErrorCallbackWrappingImplementation extends DOMWrapperBase implements StorageInfoErrorCallback {
  StorageInfoErrorCallbackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool handleEvent(DOMException error) {
    return _ptr.handleEvent(LevelDom.unwrap(error));
  }

  String get typeName() { return "StorageInfoErrorCallback"; }
}
