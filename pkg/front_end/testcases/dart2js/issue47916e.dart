// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  const factory A() = B;
}

abstract class B implements A {
  const factory B() = C.named;
}

class C implements B {
  static C named() => new C();
}

test() {
  A.new;
  B.new;
  C.named;
}

main() {}
