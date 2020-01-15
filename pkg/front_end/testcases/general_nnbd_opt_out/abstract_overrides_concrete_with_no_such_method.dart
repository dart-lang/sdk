// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

abstract class A {
  A foo() => null;
}

abstract class B extends A {
  B foo();
}

class C {
  noSuchMethod(_) => null;
}

class D extends C implements B {}

main() {}
