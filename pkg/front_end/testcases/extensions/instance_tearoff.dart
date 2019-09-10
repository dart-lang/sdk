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
  int genericMethod<T extends num>(T t) {
    print('Extension1.genericMethod<$T>($t) on $this');
    return field + t;
  }
}


extension Extension2 on Class2 {
  int method() {
    print('Extension2.method on $this');
    return field + 2;
  }
  int genericMethod<T extends num>(T t) {
    print('Extension2.genericMethod<$T>($t) on $this');
    return field + t + 3;
  }
}

main() {
  testExtension1();
  testExtension2();
}

testExtension1() {
  Class1 c0 = new Class1(0);
  Class1 c1 = new Class1(1);
  var tearOff0 = c0.method;
  expect(0, tearOff0());
  c0 = new Class1(-4);
  expect(0, tearOff0());
  var tearOff1 = c1.method;
  expect(1, tearOff1());
  c1 = new Class1(-7);
  expect(1, tearOff1());
  var genericTearOff0 = c0.genericMethod;
  expect(38, genericTearOff0(42));
  expect(38, genericTearOff0<num>(42));
  var genericTearOff1 = c1.genericMethod;
  expect(35, genericTearOff1(42));
  expect(35, genericTearOff1<num>(42));
}

testExtension2() {
  Class2 c0 = new Class2(0);
  Class2 c1 = new Class2(1);
  var tearOff0 = c0.method;
  expect(2, tearOff0());
  c0 = new Class2(-4);
  expect(2, tearOff0());
  var tearOff1 = c1.method;
  expect(3, tearOff1());
  c1 = new Class2(-7);
  expect(3, tearOff1());
  var genericTearOff0 = c0.genericMethod;
  expect(41, genericTearOff0(42));
  expect(41, genericTearOff0<num>(42));
  var genericTearOff1 = c1.genericMethod;
  expect(38, genericTearOff1(42));
  expect(38, genericTearOff1<num>(42));
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Mismatch: expected=$expected, actual=$actual';
  }
}