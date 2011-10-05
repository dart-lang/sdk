// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CryptoWrappingImplementation extends DOMWrapperBase implements Crypto {
  _CryptoWrappingImplementation() : super() {}

  static create__CryptoWrappingImplementation() native {
    return new _CryptoWrappingImplementation();
  }

  void getRandomValues(ArrayBufferView array) {
    _getRandomValues(this, array);
    return;
  }
  static void _getRandomValues(receiver, array) native;

  String get typeName() { return "Crypto"; }
}
