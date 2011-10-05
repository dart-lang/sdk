// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _StorageInfoQuotaCallbackWrappingImplementation extends DOMWrapperBase implements StorageInfoQuotaCallback {
  _StorageInfoQuotaCallbackWrappingImplementation() : super() {}

  static create__StorageInfoQuotaCallbackWrappingImplementation() native {
    return new _StorageInfoQuotaCallbackWrappingImplementation();
  }

  bool handleEvent(int grantedQuotaInBytes) {
    return _handleEvent(this, grantedQuotaInBytes);
  }
  static bool _handleEvent(receiver, grantedQuotaInBytes) native;

  String get typeName() { return "StorageInfoQuotaCallback"; }
}
