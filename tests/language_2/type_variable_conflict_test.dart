// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we report a compile-time error when a type parameter conflicts
// with an instance or static member with the same name.

import "package:expect/expect.dart";

class G1<T> {
  var T; // //# 01: compile-time error
}

class G2<T> {
  get T {} // //# 02: compile-time error
}

class G3<T> {
  T() {} // //# 03: compile-time error
}

class G4<T> {
  static var T; // //# 04: compile-time error
}

class G5<T> {
  static get T {} // //# 05: compile-time error
}

class G6<T> {
  static T() {} // //# 06: compile-time error
}

main() {
  new G1<int>();
  new G2<int>();
  new G3<int>();
  new G4<int>();
  new G5<int>();
  new G6<int>();
}
