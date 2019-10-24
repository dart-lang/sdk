// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<T extends num> {
  T field1;
  T field2;

  Class(this.field1, this.field2);
}

extension Extension1<T extends num> on Class<T> {
  static String latestType;
  T get field {
    latestType = '$T';
    return field1;
  }
  void set field(T value) {
    latestType = '$T';
    field1 = value;
  }
  T method() {
    latestType = '$T';
    return field1;
  }
  T genericMethod<S extends num>(S t) {
    latestType = '$T:$S';
    return field1 + t;
  }
}

extension Extension2<T extends num> on Class<T> {
  T get field => field2;
  void set field(T value) {
    field2 = value;
  }
  T method() => field2;
  T genericMethod<S extends num>(S t) => field2 + t;
}

main() {
  Class<int> c = new Class<int>(42, 87);
  expect(42, Extension1<num>(c).field);
  expect('num', Extension1.latestType);
  expect(42, Extension1<int>(c).field);
  expect('int', Extension1.latestType);
  expect(87, Extension2<num>(c).field);

  expect(42, Extension1<num>(c).method());
  expect('num', Extension1.latestType);
  expect(42, Extension1<int>(c).method());
  expect('int', Extension1.latestType);
  expect(87, Extension2<num>(c).method());
  var tearOffNumber1 = Extension1<num>(c).method;
  var tearOffInteger1 = Extension1<int>(c).method;
  var tearOff2 = Extension2<num>(c).method;
  expect(42, tearOffNumber1());
  expect('num', Extension1.latestType);
  expect(42, tearOffInteger1());
  expect('int', Extension1.latestType);
  expect(87, tearOff2());
  expect(52, Extension1<num>(c).genericMethod(10));
  expect('num:int', Extension1.latestType);
  expect(52, Extension1<int>(c).genericMethod(10));
  expect('int:int', Extension1.latestType);
  expect(97, Extension2<num>(c).genericMethod(10));
  expect(52, Extension1<num>(c).genericMethod<num>(10));
  expect('num:num', Extension1.latestType);
  expect(52, Extension1<int>(c).genericMethod<num>(10));
  expect('int:num', Extension1.latestType);
  expect(97, Extension2<num>(c).genericMethod<num>(10));
  expect(52, Extension1(c).genericMethod(10));
  expect('int:int', Extension1.latestType);
  expect(52, Extension1(c).genericMethod<num>(10));
  expect('int:num', Extension1.latestType);
  expect(52, Extension1(c).genericMethod<int>(10));
  expect('int:int', Extension1.latestType);
  var genericTearOffNumber1 = Extension1<num>(c).genericMethod;
  var genericTearOffInteger1 = Extension1<int>(c).genericMethod;
  var genericTearOff2 = Extension2<num>(c).genericMethod;
  expect(52, genericTearOffNumber1(10));
  expect('num:int', Extension1.latestType);
  expect(52, genericTearOffInteger1(10));
  expect('int:int', Extension1.latestType);
  expect(97, genericTearOff2(10));
  expect(52, genericTearOffNumber1<num>(10));
  expect('num:num', Extension1.latestType);
  expect(52, genericTearOffInteger1<num>(10));
  expect('int:num', Extension1.latestType);
  expect(97, genericTearOff2<num>(10));
  expect(23, Extension1<num>(c).field = 23);
  expect('num', Extension1.latestType);
  expect(23, Extension1<int>(c).field = 23);
  expect('int', Extension1.latestType);
  expect(67, Extension2<num>(c).field = 67);
  expect(23, Extension1<num>(c).field);
  expect(67, Extension2<num>(c).field);
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Mismatch: expected=$expected, actual=$actual';
  }
}