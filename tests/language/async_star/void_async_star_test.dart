// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It is an error for an `async*` function to have return type `void`.

import 'dart:async';

/*space*/ void f1() async* {
  //      ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified
}

class C {
  static void f2() async* {
    //   ^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  /*space*/ void f3() async* {
    //      ^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

void main() {
  /*space*/ void f4() async* {
    //      ^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // No function literal: It is probably not possible to infer the
  // return type `void` for a function literal marked `async*`.
}
