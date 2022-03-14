// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int get n => 1;
}

class B {
  double get n => 2.0;
}

abstract class C implements A, B {}

abstract class D implements C {}

main() {}
