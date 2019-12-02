// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Check that we correctly flag the use of an instance method from a static
/// method.

class Goofy {
  String instMethod() {
    return "woof";
  }

  static String bark() {
    return instMethod();
    //     ^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INSTANCE_MEMBER_ACCESS_FROM_STATIC
    // [cfe] Method not found: 'instMethod'.
  }
}

main() {
  Goofy.bark();
}
