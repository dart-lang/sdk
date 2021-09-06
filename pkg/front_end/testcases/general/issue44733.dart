// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class B extends A with C {}

mixin C on D {}

B get x => super.x;
void f() {
  switch (x.y.z) {
  }
}

abstract class E {}

abstract class D {
  E get y {}
}

abstract class A {
  F get y => super.y as F;
}

main() {}