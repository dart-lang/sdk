// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Number {
  final int value;

  Number(this.value);

  int get hashCode => value.hashCode;

  bool operator ==(Object other) => other is Number && value == other.value;

  String toString() => 'Number($value)';
}

extension NumberExtension on Number {
  Number operator +(Number other) => new Number(value + other.value);
  Number operator -(Number other) => new Number(value - other.value);
}

class Class {
  Number field;

  Class(this.field);
}

extension ClassExtension on Class {
  Number get property => field;
  void set property(Number value) {
    field = value;
  }
}

main() {
  testLocals();
  testProperties();
}

testLocals() {
  Number n0 = new Number(0);
  Number n1 = new Number(1);
  Number n2 = new Number(2);
  Number v = n0;
  expect(n0, v);
  expect(n1, v += n1);
  expect(n2, v += n1);
  expect(n0, v -= n2);
  expect(n1, v += n1);
  expect(n0, v -= n1);
}

testProperties() {
  Number n0 = new Number(0);
  Number n1 = new Number(1);
  Number n2 = new Number(2);
  Class v = new Class(n0);
  expect(n0, v.field);
  expect(n1, v.field += n1);
  expect(n2, v.field += n1);
  expect(n0, v.field -= n2);
  expect(n1, v.field += n1);
  expect(n0, v.field -= n1);

  expect(n0, v.property);
  expect(n1, v.property += n1);
  expect(n2, v.property += n1);
  expect(n0, v.property -= n2);
  expect(n1, v.property += n1);
  expect(n0, v.property -= n1);
}


expect(expected, actual) {
  if (expected != actual) {
    throw 'Mismatch: expected=$expected, actual=$actual';
  }
}