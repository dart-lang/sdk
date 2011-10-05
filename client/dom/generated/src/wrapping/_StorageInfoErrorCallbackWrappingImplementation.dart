// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _StorageInfoErrorCallbackWrappingImplementation extends DOMWrapperBase implements StorageInfoErrorCallback {
  _StorageInfoErrorCallbackWrappingImplementation() : super() {}

  static create__StorageInfoErrorCallbackWrappingImplementation() native {
    return new _StorageInfoErrorCallbackWrappingImplementation();
  }

  bool handleEvent(DOMException error) {
    return _handleEvent(this, error);
  }
  static bool _handleEvent(receiver, error) native;

  String get typeName() { return "StorageInfoErrorCallback"; }
}
