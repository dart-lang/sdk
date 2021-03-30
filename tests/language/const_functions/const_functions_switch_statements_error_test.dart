// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous switch statements for const functions.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

const var1 = labelDoesNotExistSwitch(1);
//           ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
int labelDoesNotExistSwitch(int x) {
  switch (x) {
    labelOtherSwitch:
    case 1:
      break;
  }
  switch (x) {
    case 1:
      continue labelOtherSwitch;
//    ^
// [cfe] Can't find label 'labelOtherSwitch'.
//             ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.LABEL_UNDEFINED
  }
  return 0;
}

const var2 = wrongTypeSwitch(1);
//           ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
int wrongTypeSwitch(int x) {
  switch (x) {
    case "string":
      // ^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.CASE_EXPRESSION_TYPE_IS_NOT_SWITCH_EXPRESSION_SUBTYPE
      // [cfe] Type 'String' of the case expression is not a subtype of type 'int' of this switch expression.
      return 100;
  }
  return 0;
}
