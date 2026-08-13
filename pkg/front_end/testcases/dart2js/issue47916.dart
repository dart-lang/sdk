// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  const factory A() = B;
}

abstract class B implements A {
  const factory B() = C;
}

class C implements B {
  const C();
}

main() {
  A.new;
}
