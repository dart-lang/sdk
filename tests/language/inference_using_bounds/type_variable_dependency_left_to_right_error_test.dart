// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inference-using-bounds

class A<X extends Iterable<Y>, Y> {
  A(X x);
  Y? y;
}

main() {
  // Inferred as A<List<num>, num>.
  A(<num>[])..y = "wrong";
  //              ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'String' can't be assigned to a variable of type 'num?'.
}
