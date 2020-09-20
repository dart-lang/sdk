// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It is an error for a `sync*` function to have return type `void`.

/*space*/ void f1() sync* {
  //      ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified
}

class C {
  static void f2() sync* {
    //   ^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  /*space*/ void f3() sync* {
    //      ^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

void main() {
  /*space*/ void f4() sync* {
    //      ^^^^
    // [analyzer] unspecified
    // [cfe] unspecified
  }

  // No function literal: It is probably not possible to infer the
  // return type `void` for a function literal marked `sync*`.
}
