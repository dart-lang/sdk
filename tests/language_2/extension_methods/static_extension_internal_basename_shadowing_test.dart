// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

///////////////////////////////////////////////////////////////////////
// The following tests check that setters or getters in an extension
// correctly shadow members with the same basename in the surrounding
// scope.
///////////////////////////////////////////////////////////////////////

String get topLevelGetter => "-1";
void set topLevelSetter(String _) {}
String topLevelField = "-3";
String topLevelMethod(String x) => "-4";

// Location that extension setters write to.
int _storeTo = null;
// Check that the most recent setter call set the value
// of _storeTo.
void checkSetter(int x) {
  int written = _storeTo;
  _storeTo = null;
  Expect.equals(written, x);
}

// Check that an instance getter in an extension shadows top level
// members with the same basename.
extension E1 on A1 {
  int get topLevelSetter => 1;
  int get topLevelField => 2;
  int get topLevelMethod => 3;
  void test() {
    // Reading the local getters is valid
    Expect.equals(topLevelSetter + 1, 2);
    Expect.equals(topLevelField + 1, 3);
    Expect.equals(topLevelMethod + 1, 4);
  }
}

class A1 {}

// Check that an instance setter in an extension shadows top level
// members with the same basename.
extension E2 on A2 {
  void set topLevelGetter(int x) {
    _storeTo = x;
  }

  void set topLevelField(int x) {
    _storeTo = x;
  }

  void set topLevelMethod(int x) {
    _storeTo = x;
  }

  void test() {
    checkSetter(topLevelGetter = 42);
    checkSetter(topLevelField = 42);
    checkSetter(topLevelMethod = 42);
  }
}

class A2 {}

// Check that a static getter in an extension shadows top level
// members with the same basename.
extension E3 on A3 {
  static int get topLevelSetter => 1;
  static int get topLevelField => 2;
  static int get topLevelMethod => 3;
  void test() {
    // Reading the local getters is valid
    Expect.equals(topLevelSetter + 1, 2);
    Expect.equals(topLevelField + 1, 3);
    Expect.equals(topLevelMethod + 1, 4);
  }
}

class A3 {}

// Check that a static setter in an extension shadows top level
// members with the same basename.
extension E4 on A4 {
  static void set topLevelGetter(int x) {
    _storeTo = x;
  }

  static void set topLevelField(int x) {
    _storeTo = x;
  }

  static void set topLevelMethod(int x) {
    _storeTo = x;
  }

  void test() {
    checkSetter(topLevelGetter = 42);
    checkSetter(topLevelField = 42);
    checkSetter(topLevelMethod = 42);
  }
}

class A4 {}

// Define extensions on A6.
extension E5 on A6 {
  void set extensionSetter(int x) {}
  int extensionMethod(int x) => -3;
}

// Check that an instance getter in an extension shadows extension
// members with the same basename from a different extension.
extension E6 on A6 {
  int get extensionSetter => 1;
  int get extensionMethod => 3;
  void test() {
    // Reading the local getters is valid
    Expect.equals(extensionSetter + 1, 2);
    Expect.equals(extensionMethod + 1, 4);
  }
}

class A6 {}

// Check that an instance getter in a class shadows extension
// members with the same basename from extension E5.
class A7 extends A6 {
  int get extensionSetter => 1;
  int get extensionMethod => 3;
  void test() {
    // Reading the local getters is valid
    Expect.equals(extensionSetter + 1, 2);
    Expect.equals(extensionMethod + 1, 4);
  }
}

// Define extensions on A8.
extension E7 on A8 {
  int get extensionGetter => -1;
  int extensionMethod(int x) => -3;
}

// Check that an instance setter in an extension shadows extension
// members with the same basename from a different extension.
extension E8 on A8 {
  void set extensionGetter(int x) {
    _storeTo = x;
  }

  void set extensionMethod(int x) {
    _storeTo = x;
  }

  void test() {
    checkSetter(extensionGetter = 42);
    checkSetter(extensionMethod = 42);
  }
}

class A8 {}

// Check that an instance setter in a class shadows extension
// members with the same basename from extension E7.
class A9 extends A8 {
  void set extensionGetter(int x) {
    _storeTo = x;
  }

  void set extensionMethod(int x) {
    _storeTo = x;
  }

  void test() {
    checkSetter(extensionGetter = 42);
    checkSetter(extensionMethod = 42);
  }
}

// Define extensions on A10.
extension E9 on A10 {
  void set extensionSetter(int x) {}
  void set extensionFieldSetter(int x) {}
  int extensionMethod(int x) => -3;
}

// Check that a static getter in an extension shadows extension
// members with the same basename from a different extension.
extension E10 on A10 {
  static int get extensionSetter => 1;
  static final int extensionFieldSetter = 2;
  static int get extensionMethod => 3;
  void test() {
    // Reading the local getters is valid
    Expect.equals(extensionSetter + 1, 2);
    Expect.equals(extensionFieldSetter + 1, 3);
    Expect.equals(extensionMethod + 1, 4);
  }
}

class A10 {}

// Check that a static getter in a class shadows extension
// members with the same basename from extension E9.
class A11 extends A10 {
  static int get extensionSetter => 1;
  static final int extensionFieldSetter = 2;
  static int get extensionMethod => 3;
  void test() {
    // Reading the local getters is valid
    Expect.equals(extensionSetter + 1, 2);
    Expect.equals(extensionFieldSetter + 1, 3);
    Expect.equals(extensionMethod + 1, 4);
  }
}

// Define extensions on A12.
extension E11 on A12 {
  int get extensionGetter => -1;
  int extensionMethod(int x) => -3;
}

// Check that a static setter in an extension shadows extension
// members with the same basename from a different extension.
extension E12 on A12 {
  static void set extensionGetter(int x) {
    _storeTo = x;
  }

  static void set extensionMethod(int x) {
    _storeTo = x;
  }

  void test() {
    checkSetter(extensionGetter = 42);
    checkSetter(extensionMethod = 42);
  }
}

class A12 {}

// Check that a static setter in a class shadows extension
// members with the same basename from extension E11.
class A13 extends A12 {
  static void set extensionGetter(int x) {
    _storeTo = x;
  }

  static void set extensionMethod(int x) {
    _storeTo = x;
  }

  void test() {
    checkSetter(extensionGetter = 42);
    checkSetter(extensionMethod = 42);
  }
}

void main() {
  A1().test();
  A2().test();
  A3().test();
  A4().test();
  A6().test();
  A7().test();
  A8().test();
  A9().test();
  A10().test();
  A11().test();
  A12().test();
  A13().test();
}
