// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CryptoWrappingImplementation extends DOMWrapperBase implements Crypto {
  CryptoWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void getRandomValues(ArrayBufferView array) {
    _ptr.getRandomValues(LevelDom.unwrap(array));
    return;
  }
}
