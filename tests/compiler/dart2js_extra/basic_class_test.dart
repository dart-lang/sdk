// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
}

class SubA extends A {
}

class B {
}

void main() {
  A a;
  SubA subA;
  B b;
  a = a;
  a = subA;
  a = b; /// 01: static type warning
  subA = a;
  subA = subA;
  subA = b; /// 02: static type warning
  b = a; /// 03: static type warning
  b = subA; /// 04: static type warning
  b = b;
}
