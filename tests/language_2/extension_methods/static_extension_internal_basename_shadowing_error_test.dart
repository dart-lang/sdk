// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

///////////////////////////////////////////////////////////////////////
// The following tests check that setters or getters in an extension
// correctly shadow members with the same basename in the surrounding
// scope.
///////////////////////////////////////////////////////////////////////

int get topLevelGetter => -1;
void set topLevelSetter(int _) {}
int topLevelField = -3;
int topLevelMethod(int x) => -4;

// Check that an instance getter in an extension shadows top level
// members with the same basename.
extension E1 on A1 {
  int get topLevelSetter => 1;
  int get topLevelField => 2;
  int get topLevelMethod => 3;
  void test() {
    // The instance getter shadows the global setter
    topLevelSetter = topLevelSetter + 1;
//  ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] Setter not found: 'topLevelSetter'.
    topLevelSetter++;
//  ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] Setter not found: 'topLevelSetter'.
    topLevelSetter = 0;
//  ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] Setter not found: 'topLevelSetter'.

    // The instance getter shadows the global field setter
    topLevelField = topLevelField + 1;
//  ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] Setter not found: 'topLevelField'.
    topLevelField++;
//  ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] Setter not found: 'topLevelField'.
    topLevelField = 0;
//  ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] Setter not found: 'topLevelField'.

    // The instance getter shadows the global method
    topLevelMethod(4);
//  ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION_EXPRESSION
//                ^
// [cfe] The method 'call' isn't defined for the class 'int'.
  }
}

class A1 {}

// Check that an instance setter in an extension shadows top level
// members with the same basename.
extension E2 on A2 {
  void set topLevelGetter(int _) {}
  void set topLevelField(int _) {}
  void set topLevelMethod(int _) {}
  void test() {
    // The instance setter shadows the global getter
    topLevelGetter = topLevelGetter + 1;
//                   ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'topLevelGetter'.
    topLevelGetter++;
//  ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'topLevelGetter'.
    topLevelGetter;
//  ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'topLevelGetter'.
    topLevelGetter = 3;

    // The instance setter shadows the global field getter
    topLevelField = topLevelField + 1;
//                  ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'topLevelField'.
    topLevelField++;
//  ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'topLevelField'.
    topLevelField;
//  ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'topLevelField'.

    // The instance setter shadows the global method
    topLevelMethod(4);
//  ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'topLevelMethod'.
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
    // The static getter shadows the global setter
    topLevelSetter = topLevelSetter + 1;
//  ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] Setter not found: 'topLevelSetter'.
    topLevelSetter++;
//  ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] Setter not found: 'topLevelSetter'.
    topLevelSetter = 0;
//  ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] Setter not found: 'topLevelSetter'.

    // The static getter shadows the global field setter
    topLevelField = topLevelField + 1;
//  ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] Setter not found: 'topLevelField'.
    topLevelField++;
//  ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] Setter not found: 'topLevelField'.
    topLevelField = 0;
//  ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] Setter not found: 'topLevelField'.

    // The static getter shadows the global method
    topLevelMethod(4);
//  ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION_EXPRESSION
//                   ^
// [cfe] The method 'call' isn't defined for the class 'int'.
  }
}

class A3 {}

// Check that a static setter in an extension shadows top level
// members with the same basename.
extension E4 on A4 {
  static void set topLevelGetter(int _) {}
  static void set topLevelField(int _) {}
  static void set topLevelMethod(int _) {}
  void test() {
    // The static setter shadows the global getter
    topLevelGetter = topLevelGetter + 1;
//                   ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'topLevelGetter'.
    topLevelGetter++;
//  ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'topLevelGetter'.
    topLevelGetter;
//  ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'topLevelGetter'.

    // The static setter shadows the global field getter
    topLevelField = topLevelField + 1;
//                  ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'topLevelField'.
    topLevelField++;
//  ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'topLevelField'.
    topLevelField;
//  ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'topLevelField'.

    // The static setter shadows the global method
    topLevelMethod(4);
//  ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'topLevelMethod'.
  }
}

class A4 {}

// Define extensions on A6.
extension E5 on A6 {
  void set extensionSetter(int _) {}
  int extensionMethod(int x) => -3;
}

// Check that an instance getter in an extension shadows extension
// members with the same basename from a different extension.
extension E6 on A6 {
  int get extensionSetter => 1;
  int get extensionMethod => 3;
  void test() {
    // The instance getter shadows the other extension's setter
    extensionSetter = extensionSetter + 1;
//  ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] Setter not found: 'extensionSetter'.
    extensionSetter++;
//  ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] Setter not found: 'extensionSetter'.
    extensionSetter = 0;
//  ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] Setter not found: 'extensionSetter'.

    // The instance getter shadows the other extensions method
    extensionMethod(4);
//  ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION_EXPRESSION
//                 ^
// [cfe] The method 'call' isn't defined for the class 'int'.
  }
}

class A6 {}

// Check that an instance getter in a class shadows extension
// members with the same basename from extension E5.
class A7 extends A6 {
  int get extensionSetter => 1;
  int get extensionMethod => 3;
  void test() {
    // The instance getter shadows the other extension's setter
    extensionSetter = extensionSetter + 1;
//  ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] The setter 'extensionSetter' isn't defined for the class 'A7'.
    extensionSetter++;
//  ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] The setter 'extensionSetter' isn't defined for the class 'A7'.
    extensionSetter = 0;
//  ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] The setter 'extensionSetter' isn't defined for the class 'A7'.

    // The instance getter shadows the other extensions method
    extensionMethod(4);
//  ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION_EXPRESSION
//                 ^
// [cfe] 'extensionMethod' isn't a function or method and can't be invoked.
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
  void set extensionGetter(int _) {}
  void set extensionMethod(int _) {}
  void test() {
    // The instance setter shadows the other extension's getter
    extensionGetter = extensionGetter + 1;
//                    ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'extensionGetter'.
    extensionGetter++;
//  ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'extensionGetter'.
    extensionGetter;
//  ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'extensionGetter'.

    // The instance setter shadows the other extension's method.
    extensionMethod(4);
//  ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'extensionMethod'.
  }
}

class A8 {}

// Check that an instance setter in a class shadows extension
// members with the same basename from extension E7.
class A9 extends A8 {
  void set extensionGetter(int _) {}
  void set extensionMethod(int _) {}
  void test() {
    // The instance setter shadows the other extension's getter
    extensionGetter = extensionGetter + 1;
//                    ^^
// [analyzer] unspecified
// [cfe] The getter 'extensionGetter' isn't defined for the class 'A9'.
    extensionGetter++;
//  ^^
// [analyzer] unspecified
// [cfe] The getter 'extensionGetter' isn't defined for the class 'A9'.
    extensionGetter;
//  ^^
// [analyzer] unspecified
// [cfe] The getter 'extensionGetter' isn't defined for the class 'A9'.

    // The instance setter shadows the other extension's method.
    extensionMethod(4);
//  ^^
// [analyzer] unspecified
// [cfe] The method 'extensionMethod' isn't defined for the class 'A9'.
  }
}

// Define extensions on A10.
extension E9 on A10 {
  void set extensionSetter(int _) {}
  void set extensionFieldSetter(int _) {}
  int extensionMethod(int x) => -3;
}

// Check that a static getter in an extension shadows extension
// members with the same basename from a different extension.
extension E10 on A10 {
  static int get extensionSetter => 1;
  static final int extensionFieldSetter = 2;
  static int get extensionMethod => 3;
  void test() {
    // The static getter shadows the other extension's setter
    extensionSetter = extensionSetter + 1;
//  ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] Setter not found: 'extensionSetter'.
    extensionSetter++;
//  ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] Setter not found: 'extensionSetter'.
    extensionSetter = 0;
//  ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] Setter not found: 'extensionSetter'.

    // The static field shadows the other extension's setter
    extensionFieldSetter = extensionFieldSetter + 1;
//  ^^
// [analyzer] unspecified
// [cfe] Setter not found: 'extensionFieldSetter'.
    extensionFieldSetter++;
//  ^^
// [analyzer] unspecified
// [cfe] Setter not found: 'extensionFieldSetter'.
    extensionFieldSetter = 0;
//  ^^
// [analyzer] unspecified
// [cfe] Setter not found: 'extensionFieldSetter'.

    // The static getter shadows the other extensions method
    extensionMethod(4);
//  ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION_EXPRESSION
//                     ^
// [cfe] The method 'call' isn't defined for the class 'int'.
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
    // The static getter shadows the other extension's setter
    extensionSetter = extensionSetter + 1;
//  ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] Setter not found: 'extensionSetter'.
    extensionSetter++;
//  ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] Setter not found: 'extensionSetter'.
    extensionSetter = 0;
//  ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] Setter not found: 'extensionSetter'.

    // The static field shadows the other extension's setter
    extensionFieldSetter = extensionFieldSetter + 1;
//  ^^
// [analyzer] unspecified
// [cfe] Setter not found: 'extensionFieldSetter'.
    extensionFieldSetter++;
//  ^^
// [analyzer] unspecified
// [cfe] Setter not found: 'extensionFieldSetter'.
    extensionFieldSetter = 0;
//  ^^
// [analyzer] unspecified
// [cfe] Setter not found: 'extensionFieldSetter'.

    // The static getter shadows the other extensions method
    extensionMethod(4);
//  ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION_EXPRESSION
//                 ^
// [cfe] The method 'call' isn't defined for the class 'int'.
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
  static void set extensionGetter(int _) {}
  static void set extensionMethod(int _) {}
  void test() {
    // The static setter shadows the other extension's getter
    extensionGetter = extensionGetter + 1;
//                    ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'extensionGetter'.
    extensionGetter++;
//  ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'extensionGetter'.
    extensionGetter;
//  ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'extensionGetter'.

    // The static setter shadows the other extension's method.
    extensionMethod(4);
//  ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'extensionMethod'.
  }
}

class A12 {}

// Check that a static setter in a class shadows extension
// members with the same basename from extension E11.
class A13 extends A12 {
  static void set extensionGetter(int _) {}
  static void set extensionMethod(int _) {}
  void test() {
    // The static setter shadows the other extension's getter
    extensionGetter = extensionGetter + 1;
//                    ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'extensionGetter'.
    extensionGetter++;
//  ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'extensionGetter'.
    extensionGetter;
//  ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'extensionGetter'.

    // The static setter shadows the other extension's method.
    extensionMethod(4);
//  ^^
// [analyzer] unspecified
// [cfe] Getter not found: 'extensionMethod'.
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
