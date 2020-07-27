// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class I {
  void call();
}

class C implements I {
  void call([int x = 0]) {}
}

main() {
  I i = new C();
  // The tear off is attempting to tear off a call method whose type is a
  // supertype of the target type. Since we no longer allow implicit downcasts,
  // this is a static error.
  void Function([int]) f = i;
  //                       ^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] unspecified
}
