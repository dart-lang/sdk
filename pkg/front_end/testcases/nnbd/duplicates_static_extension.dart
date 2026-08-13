// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension Extension on int {
  static int staticMethod() => 1;
  static int staticMethod() => 2;

  static int get staticGetter => 1;
  static int get staticGetter => 2;

  static void set staticSetter(value) {}

  static void set staticSetter(value) {}

  static int staticField = 1;
  static int staticField = 2;

  static int staticFieldAndSetter1 = 1;
  static void set staticFieldAndSetter1(int value) {}

  static void set staticFieldAndSetter2(int value) {}

  static int staticFieldAndSetter2 = 1;

  static late final int staticLateFinalFieldAndSetter1;
  static void set staticLateFinalFieldAndSetter1(int value) {}

  static void set staticLateFinalFieldAndSetter2(int value) {}

  static late final int staticLateFinalFieldAndSetter2;

  static final int staticDuplicateFieldAndSetter = 1;
  static final int staticDuplicateFieldAndSetter = 2;
  static void set staticDuplicateFieldAndSetter(int value) {}

  static final int staticFieldAndDuplicateSetter = 1;
  static void set staticFieldAndDuplicateSetter(int value) {}

  static void set staticFieldAndDuplicateSetter(int value) {}

  static final int staticDuplicateFieldAndDuplicateSetter = 1;
  static final int staticDuplicateFieldAndDuplicateSetter = 2;
  static void set staticDuplicateFieldAndDuplicateSetter(int value) {}

  static void set staticDuplicateFieldAndDuplicateSetter(int value) {}

  static int staticMethodAndSetter1() => 1;
  static void set staticMethodAndSetter1(int value) {}

  static void set staticMethodAndSetter2(int value) {}

  static int staticMethodAndSetter2() => 1;
}

test() {
  Extension.staticMethod();
  (Extension.staticMethod)();
  Extension.staticGetter;
  Extension.staticSetter = 0;
  Extension.staticField;
  Extension.staticField = 0;
  Extension.staticFieldAndSetter1;
  Extension.staticFieldAndSetter1 = 0;
  Extension.staticFieldAndSetter2;
  Extension.staticFieldAndSetter2 = 0;
  Extension.staticDuplicateFieldAndSetter;
  Extension.staticDuplicateFieldAndSetter = 0;
  Extension.staticFieldAndDuplicateSetter;
  Extension.staticFieldAndDuplicateSetter = 0;
  Extension.staticDuplicateFieldAndDuplicateSetter;
  Extension.staticDuplicateFieldAndDuplicateSetter = 0;
  Extension.staticMethodAndSetter1 = 0;
  Extension.staticMethodAndSetter2 = 0;
  Extension.staticLateFinalFieldAndSetter1;
  Extension.staticLateFinalFieldAndSetter1 = 0;
  Extension.staticLateFinalFieldAndSetter2;
  Extension.staticLateFinalFieldAndSetter2 = 0;
  Extension.staticMethodAndSetter1();
  Extension.staticMethodAndSetter2();
}
