// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class A {
  factory A() = B;
  factory A.aaa1() = B.bbb1;
  factory A.aaa2() = B.bbb2;
}

class B implements A {
  factory B() = C;
  factory B.bbb1() = C.ccc1;
  factory B.bbb2() = C.ccc2;
}

class C implements B {
  C();
  C.ccc1();
  C.ccc2();
}
