// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

extension type A(num _it) {
  void foo() {
    if (_it is int) {
      _it.isEven;
    }
  }
}

extension type B(num _it) {
  void foo() {
    if (_it is int) {
      _it.isEven;
    }
  }
}

extension type C(num _it2) implements A {
  void foo() {
    if (_it is int) {
      _it.isEven;
    }
    if (_it2 is int) {
      _it2.isEven;
    }
  }
}
