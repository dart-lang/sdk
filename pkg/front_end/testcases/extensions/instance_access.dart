// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class1 {
  int field;

  Class1(this.field);

  String toString() => 'Class1($field)';
}

class Class2 {
  int field;

  Class2(this.field);

  String toString() => 'Class2($field)';
}

extension Extension1 on Class1 {
  int method() {
    print('Extension1.method on $this');
    return field;
  }
  num genericMethod<T extends num>(T t) {
    print('Extension1.genericMethod<$T>($t) on $this');
    return field + t;
  }
  int get property {
    print('Extension1.property get on $this');
    return field;
  }
  set property(int value) {
    field = value;
    print('Extension1.property set($value) on $this');
    value++;
  }
}


extension Extension2 on Class2 {
  int method() {
    print('Extension2.method on $this');
    return field + 3;
  }
  num genericMethod<T extends num>(T t) {
    print('Extension2.genericMethod<$T>($t) on $this');
    return field + t + 4;
  }
  int get property {
    print('Extension2.property get on $this');
    return field + 5;
  }
  set property(int value) {
    print('Extension2.property set($value) on $this');
    value++;
    field = value;
  }
}

main() {
  Class1 c10 = new Class1(0);
  Class1 c11 = new Class1(1);
  testExtension1(c10, c11, c10, c11);
  Class2 c20 = new Class2(0);
  Class2 c21 = new Class2(1);
  testExtension2(c20, c21, c20);
}

testExtension1(Class1 c0, Class1 c1, Class1? c0n, Class1? c1n) {
  expect(0, c0.method());
  expect(1, c1.method());
  expect(1, c1n?.method());
  expect(42, c0.genericMethod(42));
  expect(43, c0.genericMethod<num>(43));
  expect(88, c1.genericMethod(87));
  expect(89, c1.genericMethod<num>(88));
  expect(0, c0.property);
  expect(0, c0n?.property);
  expect(42, c0.property = 42);
  expect(1, c1.property);
  expect(87, c0.property = 87);
  expect(27, c0.property = c1.property = 27);
  expect(37, c1.property = c0.property = 37);
  expect(77, c1.property = c0.property = c1.property = 77);
  expect(67, c0.property = c1.property = c0.property = 67);
}

testExtension2(Class2 c0, Class2 c1, Class2? c0n) {
  expect(3, c0.method());
  expect(3, c0n?.method());
  expect(4, c1.method());
  expect(46, c0.genericMethod(42));
  expect(47, c0.genericMethod<num>(43));
  expect(92, c1.genericMethod(87));
  expect(93, c1.genericMethod<num>(88));
  expect(5, c0.property);
  expect(5, c0n?.property);
  expect(42, c0.property = 42);
  expect(48, c0.property);
  expect(6, c1.property);
  expect(43, c1.property = 43);
  expect(49, c1.property);
  expect(49, c0.property = c1.property);
  expect(55, c1.property = c0.property);
  expect(61, c1.property = c0.property = c1.property);
  expect(67, c0.property = c1.property = c0.property);
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Mismatch: expected=$expected, actual=$actual';
  }
}