// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Dart test program const map literals.

class MapLiteral2NegativeTest<T> {
  test() {
    var m = const <String, T>{};
    //                     ^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_TYPE_ARGUMENT_IN_CONST_LITERAL
    // [cfe] Type variables can't be used as constants.
  }
}

main() {
  MapLiteral2NegativeTest<int>().test();
}
