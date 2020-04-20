// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Base {
  final String name;
  const Base(this.name);
}

class C extends Base {
  const C(String s)
      // Call super constructor with wrong argument count.
      : super();
      //     ^^
      // [analyzer] COMPILE_TIME_ERROR.NOT_ENOUGH_POSITIONAL_ARGUMENTS
      // [cfe] Too few positional arguments: 1 required, 0 given.
}

main() {
  const C("str");
}
