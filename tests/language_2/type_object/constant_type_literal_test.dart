// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for type literals as compile-time constants.

class C<T> {
  void m() {
    const List lst = const [
      T
//    ^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [cfe] Type variables can't be used as constants.
//    ^
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_LIST_ELEMENT
    ];
  }
}

main() {
  new C().m();
}
