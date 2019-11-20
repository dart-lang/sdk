// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Dart test program const map literals.

class MapLiteral2NegativeTest<T> {
  test() {
    var m = const <String, T>{"a": 0};
    //      ^
    // [cfe] Constant evaluation error:
    //                     ^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_TYPE_ARGUMENT_IN_CONST_MAP
    // [cfe] Type variables can't be used as constants.
    //                             ^
    // [analyzer] STATIC_WARNING.MAP_VALUE_TYPE_NOT_ASSIGNABLE
  }
}

main() {
  MapLiteral2NegativeTest<int>().test();
}
