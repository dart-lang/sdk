// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It is an error for a `sync*` function to have return type `void`.

void f1() sync* {
  // [error column 1, length 4]
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE
  // ^
  // [cfe] Functions marked 'sync*' can't have return type 'void'.
}

class C {
  static void f2() sync* {
    //   ^^^^
    // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE
    //        ^
    // [cfe] Functions marked 'sync*' can't have return type 'void'.
  }

  void f3() sync* {
    // [error column 3, length 4]
    // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE
    // ^
    // [cfe] Functions marked 'sync*' can't have return type 'void'.
  }
}

void main() {
  void f4() sync* {
    // [error column 3, length 4]
    // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE
    // ^
    // [cfe] Functions marked 'sync*' can't have return type 'void'.
  }

  // No function literal: It is probably not possible to infer the
  // return type `void` for a function literal marked `sync*`.
}
