// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class I {
  foo([a]);
}

abstract class A {
  foo() {}
}

abstract class B extends A implements I {}

class C extends B {
  foo([a]) {}
}

void main() {}
