// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  void foo() {}
}

abstract class I {
  void foo([a]);
}

abstract class B extends A {
  void foo([a]);
}

class C extends B {}

class D extends A implements I {}

abstract class E extends A implements I {}

class F extends E {}

main() {}
