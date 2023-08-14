// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "package:expect/expect.dart";

/**
 * Verify static compilation errors on strings and lists.
 */
class CoreStaticTypesTest {
  static testMain() {
    testStringOperators();
    testStringMethods();
    testListOperators();
  }

  static testStringOperators() {
    var q = "abcdef";
    q['hello'];
    //^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
    q[0] = 'x';
//   ^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
// [cfe] The operator '[]=' isn't defined for the class 'String'.
  }

  static testStringMethods() {
    var s = "abcdef";
    s.startsWith(1);
    //           ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'int' can't be assigned to the parameter type 'Pattern'.
    s.endsWith(1);
    //         ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'int' can't be assigned to the parameter type 'String'.
  }

  static testListOperators() {
    var a = [1, 2, 3, 4];
    a['0'];
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
    a['0'] = 99;
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
  }
}

main() {
  CoreStaticTypesTest.testMain();
}
