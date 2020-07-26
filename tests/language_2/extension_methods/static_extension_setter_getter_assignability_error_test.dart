// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It is an error to have a setter and a getter in an extension where
// the return type of the getter is not assignable to the argument type
// of the setter.
extension E1 on int {
  static int get property => 1;
  //     ^^
  // [cfe] unspecified
  //             ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.GETTER_NOT_ASSIGNABLE_SETTER_TYPES
  static void set property(String value) {}
  //                       ^^
  // [cfe] unspecified
  int get property2 => 1;
  //  ^^
  // [cfe] unspecified
  //      ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.GETTER_NOT_ASSIGNABLE_SETTER_TYPES
  void set property2(String x) {}
  //                 ^^
  // [cfe] unspecified
}

void main() {}
