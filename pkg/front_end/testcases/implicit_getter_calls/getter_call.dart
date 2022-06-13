// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

bool enableRead = true;

int read(int value) => enableRead ? value : -1;

int method1() => 0;
int method2(int a) => -a;
int method3(int a, int b) => a - b;
int method4(int a, [int b = 0]) => a - b;
int method5([int a = 0, int b = 0]) => a - b;
int method6(int a, {int b = 0}) => a - b;
int method7({int a = 0, int b = 0}) => a - b;

class Class {
  Function field1a = method1;
  int Function() field1b = method1;
  int Function(int a) field2 = method2;
  int Function(int a, int b) field3 = method3;
  int Function(int a, [int b]) field4 = method4;
  int Function([int a, int b]) field5 = method5;
  int Function(int a, {int b}) field6 = method6;
  int Function({int a, int b}) field7 = method7;

  Function get getter1a => method1;
  int Function() get getter1b => method1;
  int Function(int a) get getter2 => method2;
  int Function(int a, int b) get getter3 => method3;
  int Function(int a, [int b]) get getter4 => method4;
  int Function([int a, int b]) get getter5 => method5;
  int Function(int a, {int b}) get getter6 => method6;
  int Function({int a, int b}) get getter7 => method7;
}

class Subclass extends Class {
  Function get field1a {
    enableRead = false;
    return method1;
  }

  int Function() get field1b {
    enableRead = false;
    return method1;
  }

  int Function(int a) get field2 {
    enableRead = false;
    return method2;
  }

  int Function(int a, int b) get field3 {
    enableRead = false;
    return method3;
  }

  int Function(int a, [int b]) get field4 {
    enableRead = false;
    return method4;
  }

  int Function([int a, int b]) get field5 {
    enableRead = false;
    return method5;
  }

  int Function(int a, {int b}) get field6 {
    enableRead = false;
    return method6;
  }

  int Function({int a, int b}) get field7 {
    enableRead = false;
    return method7;
  }

  Function get getter1a {
    enableRead = false;
    return method1;
  }

  int Function() get getter1b {
    enableRead = false;
    return method1;
  }

  int Function(int a) get getter2 {
    enableRead = false;
    return method2;
  }

  int Function(int a, int b) get getter3 {
    enableRead = false;
    return method3;
  }

  int Function(int a, [int b]) get getter4 {
    enableRead = false;
    return method4;
  }

  int Function([int a, int b]) get getter5 {
    enableRead = false;
    return method5;
  }

  int Function(int a, {int b}) get getter6 {
    enableRead = false;
    return method6;
  }

  int Function({int a, int b}) get getter7 {
    enableRead = false;
    return method7;
  }
}

main() {
  callField(new Class());
  callGetter(new Class());

  callField(new Subclass());
  callGetter(new Subclass());
}

callField(Class c) {
  expect(0, c.field1a());
  expect(0, c.field1b());
  expect(-42, c.field2(read(42)));
  expect(-11, c.field3(read(12), read(23)));
  expect(12, c.field4(read(12)));
  expect(-11, c.field4(read(12), read(23)));
  expect(0, c.field5());
  expect(12, c.field5(read(12)));
  expect(-11, c.field5(read(12), read(23)));
  expect(12, c.field6(read(12)));
  expect(-11, c.field6(read(12), b: read(23)));
  expect(0, c.field7());
  expect(12, c.field7(a: read(12)));
  expect(-23, c.field7(b: read(23)));
  expect(-11, c.field7(a: read(12), b: read(23)));
  expect(-11, c.field7(b: read(23), a: read(12)));
}

callGetter(Class c) {
  expect(0, c.getter1a());
  expect(0, c.getter1b());
  expect(-42, c.getter2(read(42)));
  expect(-11, c.getter3(read(12), read(23)));
  expect(12, c.getter4(read(12)));
  expect(-11, c.getter4(read(12), read(23)));
  expect(0, c.getter5());
  expect(12, c.getter5(read(12)));
  expect(-11, c.getter5(read(12), read(23)));
  expect(12, c.getter6(read(12)));
  expect(-11, c.getter6(read(12), b: read(23)));
  expect(0, c.getter7());
  expect(12, c.getter7(a: read(12)));
  expect(-23, c.getter7(b: read(23)));
  expect(-11, c.getter7(a: read(12), b: read(23)));
  expect(-11, c.getter7(b: read(23), a: read(12)));
}

expect(expected, actual) {
  enableRead = true;
  if (expected != actual) throw 'Expected $expected, $actual';
}
