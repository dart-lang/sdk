// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  void method([int a]);
}

class B implements A {
  noSuchMethod(_) => null;
}

class C implements B {
  void method([int a = 0]) {}
}
