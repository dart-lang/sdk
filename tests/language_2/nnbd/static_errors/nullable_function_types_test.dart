// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

class C {
  call() {}
}

// Test calling various nullable functions produces errors.
void main() {
  Function()? nf1;
  Function? nf2;
  C c1 = new C();
  C? nc1;
  var nf3 = nc1?.call;
  Object? object;


  nf1(); //# 00: compile-time error
  nf2(); //# 01: compile-time error
  nf3(); //# 02: compile-time error
  c1(); //# 03: ok
  nc1(); //# 04: compile-time error
  object(); //# 05: compile-time error
}
