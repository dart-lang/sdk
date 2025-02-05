// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=null-aware-elements

import 'package:expect/expect.dart';

const nullConst = null;

var nullVar = null;

const intConst = 0;

const stringConst = "";

var intVar = 0;

var stringVar = "";


const list1 = [?nullVar, intConst, stringConst];
//            ^
// [cfe] Constant evaluation error:
//              ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_LIST_ELEMENT
// [cfe] Not a constant expression.

const list2 = [?null, ?nullVar, intConst, stringConst];
//            ^
// [cfe] Constant evaluation error:
//                     ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_LIST_ELEMENT
// [cfe] Not a constant expression.

const set1 = {nullConst, null, intConst, stringConst};
//           ^
// [cfe] Constant evaluation error:
//                       ^^^^
// [analyzer] COMPILE_TIME_ERROR.EQUAL_ELEMENTS_IN_CONST_SET

const set2 = {0, ?intConst, stringConst};
//           ^
// [cfe] Constant evaluation error:
//               ^
// [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
//                ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.EQUAL_ELEMENTS_IN_CONST_SET

const set3 = {null, intConst, "", ?stringConst};
//           ^
// [cfe] Constant evaluation error:
//                                ^
// [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
//                                 ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.EQUAL_ELEMENTS_IN_CONST_SET

const set4 = {?nullVar, intConst, stringConst};
//           ^
// [cfe] Constant evaluation error:
//             ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_SET_ELEMENT
// [cfe] Not a constant expression.

const set5 = {nullConst, ?intVar, stringConst};
//           ^
// [cfe] Constant evaluation error:
//                       ^
// [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
//                        ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_SET_ELEMENT
// [cfe] Not a constant expression.

const set6 = {nullConst, intConst, ?stringVar};
//           ^
// [cfe] Constant evaluation error:
//                                 ^
// [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
//                                  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_SET_ELEMENT
// [cfe] Not a constant expression.

const map1 = {null: 1, nullConst: 1, intConst: 1, stringConst: 1};
//           ^
// [cfe] Constant evaluation error:
//                     ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.EQUAL_KEYS_IN_CONST_MAP

const map2 = {?nullVar: 1, intConst: 1, stringConst: 1};
//    ^
// [cfe] Constant evaluation error:
//             ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_MAP_KEY
// [cfe] Not a constant expression.

const map3 = {null: ?nullVar, intConst: 1, stringConst: 1};
//    ^
// [cfe] Constant evaluation error:
//                   ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_MAP_VALUE
// [cfe] Not a constant expression.

const map4 = {null: 1, ?intVar: 1, stringConst: 1};
//    ^
// [cfe] Constant evaluation error:
//                     ^
// [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
//                      ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_MAP_KEY
// [cfe] Not a constant expression.

const map5 = {null: 1, 0: ?intVar, stringConst: 1};
//    ^
// [cfe] Constant evaluation error:
//                        ^
// [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
//                         ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_MAP_VALUE
// [cfe] Not a constant expression.

const map6 = {null: 1, 0: 1, ?stringVar: 1};
//    ^
// [cfe] Constant evaluation error:
//                           ^
// [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
//                            ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_MAP_KEY
// [cfe] Not a constant expression.

const map7 = {null: 1, 0: 1, "": ?stringVar};
//    ^
// [cfe] Constant evaluation error:
//                               ^
// [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
//                                ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_MAP_VALUE
// [cfe] Not a constant expression.

const map8 = {null: 1, nullConst: ?intConst, stringConst: 1};
//    ^
// [cfe] Constant evaluation error:
//                     ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.EQUAL_KEYS_IN_CONST_MAP
//                                ^
// [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR

const map9 = {intConst: null, ?0: intConst, null: 1, stringConst: 1};
//    ^
// [cfe] Constant evaluation error:
//                            ^
// [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
//                             ^
// [analyzer] COMPILE_TIME_ERROR.EQUAL_KEYS_IN_CONST_MAP

const map10 = {intConst: null, 0: ?intConst, null: 1, stringConst: 1};
//    ^
// [cfe] Constant evaluation error:
//                             ^
// [analyzer] COMPILE_TIME_ERROR.EQUAL_KEYS_IN_CONST_MAP
//                                ^
// [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR

main() {}
