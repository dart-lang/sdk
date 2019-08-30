// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  int field1 = 42;
  int field2 = 87;
}

extension Extension1 on Class {
  int get field => field1;
  void set field(int value) {
    field1 = value;
  }
  int method() => field1;
  int genericMethod<T extends num>(T t) => field1 + t;
}

extension Extension2 on Class {
  int get field => field2;
  void set field(int value) {
    field2 = value;
  }
  int method() => field2;
  int genericMethod<T extends num>(T t) => field2 + t;
}

main() {
  Class c = new Class();
  expect(42, Extension1(c).field);
  expect(87, Extension2(c).field);
  expect(42, Extension1(c).method());
  expect(87, Extension2(c).method());
  var tearOff1 = Extension1(c).method;
  var tearOff2 = Extension2(c).method;
  expect(42, tearOff1());
  expect(87, tearOff2());
  expect(52, Extension1(c).genericMethod(10));
  expect(97, Extension2(c).genericMethod(10));
  expect(52, Extension1(c).genericMethod<num>(10));
  expect(97, Extension2(c).genericMethod<num>(10));
  var genericTearOff1 = Extension1(c).genericMethod;
  var genericTearOff2 = Extension2(c).genericMethod;
  expect(52, genericTearOff1(10));
  expect(97, genericTearOff2(10));
  expect(52, genericTearOff1<num>(10));
  expect(97, genericTearOff2<num>(10));
  expect(23, Extension1(c).field = 23);
  expect(67, Extension2(c).field = 67);
  expect(23, Extension1(c).field);
  expect(67, Extension2(c).field);
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Mismatch: expected=$expected, actual=$actual';
  }
}