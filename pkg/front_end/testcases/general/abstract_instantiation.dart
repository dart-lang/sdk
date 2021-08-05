// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {}

abstract class B implements A {
  factory B() = A;
}

test() {
  new A();
  new B();
}

main() {}