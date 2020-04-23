// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  void set foo(int value) {}
  int get bar => null;
}

class B {
  void set foo(double value) {}
  double get bar => null;
}

class C {
  void set foo(num value) {}
  Null get bar => null;
}

class D implements C, A, B {
  noSuchMethod(_) => null;
}

main() {}
