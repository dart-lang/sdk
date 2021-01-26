// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var result;

class Class {
  static int staticMethod() => 1;
  static int staticMethod() => 2;

  static int get staticGetter => 1;
  static int get staticGetter => 2;

  static void set staticSetter(value) {
    result = 1;
  }

  static void set staticSetter(value) {
    result = 2;
  }

  static int staticField = 1;
  static int staticField = 2;

  static int staticFieldAndSetter1 = 1;
  static void set staticFieldAndSetter1(int value) {
    result = 2;
  }

  static void set staticFieldAndSetter2(int value) {
    result = 2;
  }

  static int staticFieldAndSetter2 = 1;

  static late final int staticLateFinalFieldAndSetter1;
  static void set staticLateFinalFieldAndSetter1(int value) {
    result = 2;
  }

  static void set staticLateFinalFieldAndSetter2(int value) {
    result = 2;
  }

  static late final int staticLateFinalFieldAndSetter2;

  static final int staticDuplicateFieldAndSetter = 1;
  static final int staticDuplicateFieldAndSetter = 2;
  static void set staticDuplicateFieldAndSetter(int value) {
    result = 3;
  }

  static final int staticFieldAndDuplicateSetter = 1;
  static void set staticFieldAndDuplicateSetter(int value) {
    result = 2;
  }

  static void set staticFieldAndDuplicateSetter(int value) {
    result = 3;
  }

  static final int staticDuplicateFieldAndDuplicateSetter = 1;
  static final int staticDuplicateFieldAndDuplicateSetter = 2;
  static void set staticDuplicateFieldAndDuplicateSetter(int value) {
    result = 3;
  }

  static void set staticDuplicateFieldAndDuplicateSetter(int value) {
    result = 4;
  }

  static int staticMethodAndSetter1() => 1;
  static void set staticMethodAndSetter1(int value) {
    result = 2;
  }

  static void set staticMethodAndSetter2(int value) {
    result = 2;
  }

  static int staticMethodAndSetter2() => 1;
}

test() {
  Class.staticMethod();
  (Class.staticMethod)();
  Class.staticGetter;
  Class.staticSetter = 0;
  Class.staticField;
  Class.staticField = 0;
  Class.staticDuplicateFieldAndSetter;
  Class.staticDuplicateFieldAndSetter = 0;
  Class.staticFieldAndDuplicateSetter;
  Class.staticFieldAndDuplicateSetter = 0;
  Class.staticDuplicateFieldAndDuplicateSetter;
  Class.staticDuplicateFieldAndDuplicateSetter = 0;
  Class.staticMethodAndSetter1 = 0;
  Class.staticMethodAndSetter2 = 0;
}

main() {
  result = null;
  Class.staticFieldAndSetter1 = 0;
  expect(null, result);
  expect(0, Class.staticFieldAndSetter1);

  result = null;
  Class.staticFieldAndSetter2 = 0;
  expect(null, result);
  expect(0, Class.staticFieldAndSetter2);

  result = null;
  Class.staticLateFinalFieldAndSetter1 = 0;
  expect(null, result);
  expect(0, Class.staticLateFinalFieldAndSetter1);

  result = null;
  Class.staticLateFinalFieldAndSetter2 = 0;
  expect(null, result);
  expect(0, Class.staticLateFinalFieldAndSetter2);

  expect(1, Class.staticMethodAndSetter1());

  expect(1, Class.staticMethodAndSetter2());
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
