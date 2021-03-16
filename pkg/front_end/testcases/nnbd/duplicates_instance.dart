// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var result;

class Class {
  int instanceMethod() => 1;
  int instanceMethod() => 2;

  int get instanceGetter => 1;
  int get instanceGetter => 2;

  void set instanceSetter(value) {
    result = 1;
  }

  void set instanceSetter(value) {
    result = 2;
  }

  int instanceField = 1;
  int instanceField = 2;

  int instanceFieldAndSetter1 = 1;
  void set instanceFieldAndSetter1(int value) {
    result = 2;
  }

  void set instanceFieldAndSetter2(int value) {
    result = 2;
  }

  int instanceFieldAndSetter2 = 1;

  late final int instanceLateFinalFieldAndSetter1;
  void set instanceLateFinalFieldAndSetter1(int value) {
    result = 2;
  }

  void set instanceLateFinalFieldAndSetter2(int value) {
    result = 2;
  }

  late final int instanceLateFinalFieldAndSetter2;

  final int instanceDuplicateFieldAndSetter = 1;
  final int instanceDuplicateFieldAndSetter = 2;
  void set instanceDuplicateFieldAndSetter(int value) {
    result = 3;
  }

  final int instanceFieldAndDuplicateSetter = 1;
  void set instanceFieldAndDuplicateSetter(int value) {
    result = 2;
  }

  void set instanceFieldAndDuplicateSetter(int value) {
    result = 3;
  }

  final int instanceDuplicateFieldAndDuplicateSetter = 1;
  final int instanceDuplicateFieldAndDuplicateSetter = 2;
  void set instanceDuplicateFieldAndDuplicateSetter(int value) {
    result = 3;
  }

  void set instanceDuplicateFieldAndDuplicateSetter(int value) {
    result = 4;
  }

  int instanceMethodAndSetter1() => 1;
  void set instanceMethodAndSetter1(int value) {
    result = 2;
  }

  void set instanceMethodAndSetter2(int value) {
    result = 2;
  }

  int instanceMethodAndSetter2() => 1;
}

test() {
  Class c = new Class();
  c.instanceMethod();
  (c.instanceMethod)();
  c.instanceGetter;
  c.instanceSetter = 0;
  c.instanceField;
  c.instanceField = 0;
  c.instanceDuplicateFieldAndSetter;
  c.instanceDuplicateFieldAndSetter = 0;
  c.instanceFieldAndDuplicateSetter;
  c.instanceFieldAndDuplicateSetter = 0;
  c.instanceDuplicateFieldAndDuplicateSetter;
  c.instanceDuplicateFieldAndDuplicateSetter = 0;
}

main() {
  Class c = new Class();
  c.instanceFieldAndSetter1 = 0;
  expect(null, result);
  expect(0, c.instanceFieldAndSetter1);

  result = null;
  c.instanceFieldAndSetter2 = 0;
  expect(null, result);
  expect(0, c.instanceFieldAndSetter2);

  result = null;
  c.instanceLateFinalFieldAndSetter1 = 0;
  expect(null, result);
  expect(0, c.instanceLateFinalFieldAndSetter1);

  result = null;
  c.instanceLateFinalFieldAndSetter2 = 0;
  expect(null, result);
  expect(0, c.instanceLateFinalFieldAndSetter2);

  result = null;
  expect(1, c.instanceMethodAndSetter1());
  c.instanceMethodAndSetter1 = 0;
  expect(2, result);

  result = null;
  expect(1, c.instanceMethodAndSetter2());
  c.instanceMethodAndSetter2 = 0;
  expect(2, result);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}

throws(dynamic Function() f) {
  try {
    f();
  } catch (e) {
    print(e);
    return;
  }
  throw 'Expected exception.';
}
