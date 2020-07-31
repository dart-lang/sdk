// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

T f<T>(T x) => x;

class C {
  T f<T>(T x) => x;
  static T g<T>(T x) => x;
}

class D extends C {
  void test() {
    int Function(int) func;
    func = super. /*@target=C.f*/ f;
  }
}

void test() {
  T h<T>(T x) => x;
  int Function(int) func;
  func = f;
  func = new C(). /*@target=C.f*/ f;
  func = C.g;
  func = h;
}

main() {}
