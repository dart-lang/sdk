// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Dart test program const map literals.

class ListLiteral2NegativeTest<T> {
  test() {
    // Type parameter is not allowed with const.
    var m = const <T>[];
    //             ^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_TYPE_ARGUMENT_IN_CONST_LITERAL
    // [cfe] Type variables can't be used as constants.
  }
}

main() {
  ListLiteral2NegativeTest<int>().test();
}
