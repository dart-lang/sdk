// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  B b;

  A(this.b);
}

class B {
  C operator +(int i) => new C();
}

class C extends B {}

main() {
  A? a;
  a?.b++;
  B? c = a?.b++;
}
