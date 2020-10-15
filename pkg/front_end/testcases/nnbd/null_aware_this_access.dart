// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  int? m1;
  int m2 = 0;

  C get property => this;

  test() {
    this?.m1;
    this?.m1 = 42;
    this?.method();
    this?.property.m1;
    this?.property.method();
    this?[0];
    this?[0] = 0;
    this?[0] ??= 0;
    this?.property[0];
    this?.property[0] = 0;
    this?.property[0] ??= 0;
    this?.m1 ??= 42;
    this?.m2 += 2;
    this?.m2++;
    --this?.m2;
    this ?? new C();
  }

  int? operator [](int index) => 0;

  void operator []=(int index, int value) {}

  method() {}
}

class D {
  D get property => this;

  test() {
    this?[0];
    this?[0] = 0;
    this?[0] += 0;
    this?.property[0];
    this?.property[0] = 0;
    this?.property[0] += 0;
  }

  int operator [](int index) => 0;

  void operator []=(int index, int value) {}
}

main() {
  new C().test();
  new D().test();
}
