// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  int get m1 => 0;
  void set m2(int x) {}
}

extension Extension0 on Class {
  void set m1(int x) {}
  int get m2 => 0;
  void set m3(int x) {}
  int get m4 => 0;
}

extension Extension1 on Class {
  int get m3 => 0;
  void set m4(int x) {}
}

main() {
  var c = new Class();
  expect(0, c.m1);
  c.m2 = 2;
}

errors() {
  var c = new Class();
  expect(0, c.m2);
  c.m1 = 2;
  c.m3;
  c.m3 = 2;
  c.m4;
  c.m4 = 2;
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Mismatch: expected=$expected, actual=$actual';
  }
}