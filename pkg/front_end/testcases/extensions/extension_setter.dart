// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  int field;
  int? nullableField;

  Class(this.field);
}

extension Extension on Class {
  int get simpleSetter => field;

  set simpleSetter(int value) {
    field = value;
  }

  int? get simpleNullableSetter => nullableField;

  set simpleNullableSetter(int? value) {
    nullableField = value;
  }

  int get mutatingSetter => field;

  set mutatingSetter(int value) {
    value = value + 1;
    field = value;
  }

  int get setterWithReturn => field;

  set setterWithReturn(int value) {
    if (value < 0) {
      field = -value;
      return;
    }
    field = value;
  }

  int get setterWithClosure => field;

  set setterWithClosure(int value) {
    abs(value) {
      return value < 0 ? -value : value;
    }

    field = abs(value);
  }

  testInternal() {
    expect(-1, field);

    simpleSetter = 0;
    expect(0, field);
    expect(1, simpleSetter = 1);

    mutatingSetter = 0;
    expect(1, field);
    expect(2, mutatingSetter = 2);
    expect(3, field);

    setterWithReturn = 1;
    expect(1, field);
    setterWithReturn = -2;
    expect(2, field);
    expect(3, setterWithReturn = 3);
    expect(3, field);
    expect(-4, setterWithReturn = -4);
    expect(4, field);

    setterWithClosure = 1;
    expect(1, field);
    setterWithClosure = -2;
    expect(2, field);
    expect(3, setterWithClosure = 3);
    expect(3, field);
    expect(-4, setterWithClosure = -4);
    expect(4, field);
  }
}

class GenericClass<T> {}

extension GenericExtension<T> on GenericClass<T> {
  set setter(T value) {}
}

main() {
  var c = new Class(-1);
  test(c, c);
}

test(Class c, Class? cn) {
  expect(-1, c.field);

  c.simpleSetter = 0;
  expect(0, c.field);
  expect(1, c.simpleSetter = 1);
  Extension(c).simpleSetter = 2;
  expect(2, c.field);
  expect(3, Extension(c).simpleSetter = 3);

  c.mutatingSetter = 0;
  expect(1, c.field);
  expect(2, c.mutatingSetter = 2);
  expect(3, c.field);
  Extension(c).mutatingSetter = 4;
  expect(5, c.field);
  expect(6, Extension(c).mutatingSetter = 6);
  expect(7, c.field);

  c.setterWithReturn = 1;
  expect(1, c.field);
  c.setterWithReturn = -2;
  expect(2, c.field);
  expect(3, c.setterWithReturn = 3);
  expect(3, c.field);
  expect(-4, c.setterWithReturn = -4);
  expect(4, c.field);
  Extension(c).setterWithReturn = 5;
  expect(5, c.field);
  Extension(c).setterWithReturn = -6;
  expect(6, c.field);
  expect(7, Extension(c).setterWithReturn = 7);
  expect(7, c.field);
  expect(-8, Extension(c).setterWithReturn = -8);
  expect(8, c.field);

  c.setterWithClosure = 1;
  expect(1, c.field);
  c.setterWithClosure = -2;
  expect(2, c.field);
  expect(3, c.setterWithClosure = 3);
  expect(3, c.field);
  expect(-4, c.setterWithClosure = -4);
  expect(4, c.field);
  Extension(c).setterWithClosure = 5;
  expect(5, c.field);
  Extension(c).setterWithClosure = -6;
  expect(6, c.field);
  expect(7, Extension(c).setterWithClosure = 7);
  expect(7, c.field);
  expect(-8, Extension(c).setterWithClosure = -8);
  expect(8, c.field);

  c.simpleSetter = 0;
  expect(0, cn?.field);
  expect(1, cn?.simpleSetter = 1);
  Extension(c).simpleSetter = 2;
  expect(2, cn?.field);
  expect(3, Extension(c).simpleSetter = 3);

  c.mutatingSetter = 0;
  expect(1, cn?.field);
  expect(2, cn?.mutatingSetter = 2);
  expect(3, cn?.field);
  Extension(c).mutatingSetter = 4;
  expect(5, cn?.field);
  expect(6, Extension(c).mutatingSetter = 6);
  expect(7, cn?.field);

  cn?.setterWithReturn = 1;
  expect(1, cn?.field);
  cn?.setterWithReturn = -2;
  expect(2, cn?.field);
  expect(3, cn?.setterWithReturn = 3);
  expect(3, cn?.field);
  expect(-4, cn?.setterWithReturn = -4);
  expect(4, cn?.field);
  Extension(c).setterWithReturn = 5;
  expect(5, cn?.field);
  Extension(c).setterWithReturn = -6;
  expect(6, cn?.field);
  expect(7, Extension(c).setterWithReturn = 7);
  expect(7, cn?.field);
  expect(-8, Extension(c).setterWithReturn = -8);
  expect(8, cn?.field);

  cn?.setterWithClosure = 1;
  expect(1, cn?.field);
  cn?.setterWithClosure = -2;
  expect(2, cn?.field);
  expect(3, cn?.setterWithClosure = 3);
  expect(3, cn?.field);
  expect(-4, cn?.setterWithClosure = -4);
  expect(4, cn?.field);
  Extension(c).setterWithClosure = 5;
  expect(5, cn?.field);
  Extension(c).setterWithClosure = -6;
  expect(6, cn?.field);
  expect(7, Extension(c).setterWithClosure = 7);
  expect(7, cn?.field);
  expect(-8, Extension(c).setterWithClosure = -8);
  expect(8, cn?.field);

  c.nullableField = null;
  c.simpleNullableSetter ??= 1;
  expect(1, c.nullableField);
  expect(1, c.simpleNullableSetter ??= 2);
  c.nullableField = null;
  expect(2, c.simpleNullableSetter ??= 2);

  cn?.nullableField = null;
  cn?.simpleNullableSetter ??= 1;
  expect(1, cn?.nullableField);
  expect(1, cn?.simpleNullableSetter ??= 2);
  cn?.nullableField = null;
  expect(2, cn?.simpleNullableSetter ??= 2);

  new Class(-1).testInternal();

  GenericClass<int> genericClass = new GenericClass<int>();
  expect(1, GenericExtension(genericClass).setter = 1);
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Mismatch: expected=$expected, actual=$actual';
  }
}
