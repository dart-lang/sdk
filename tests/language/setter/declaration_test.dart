// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a setter has a single argument.

import 'dart:async';

set tooFew() {}
//  ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER
//        ^
// [cfe] A setter should have exactly one formal parameter.

set tooMany(var value, var extra) {}
//  ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER
//         ^
// [cfe] A setter should have exactly one formal parameter.

/*space*/ int? set wrongReturnType1(_) => 1;
//        ^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
// [cfe] unspecified

/*space*/ FutureOr<void> set wrongReturnType2(_) {}
//        ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
// [cfe] unspecified

/*space*/ Never set wrongReturnType3(_) => throw 1;
//        ^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
// [cfe] unspecified

int get nonSubtypes1 => 1;
//      ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.GETTER_NOT_SUBTYPE_SETTER_TYPES
// [cfe] unspecified
set nonSubtypes1(String _) {}

int? get nonSubtypes2 => 1;
//       ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.GETTER_NOT_SUBTYPE_SETTER_TYPES
// [cfe] unspecified
set nonSubtypes2(int _) {}

FutureOr<int> get nonSubtypes3 => 1;
//                ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.GETTER_NOT_SUBTYPE_SETTER_TYPES
// [cfe] unspecified
set nonSubtypes3(int _) {}

dynamic get nonSubtypes4 => 1;
//          ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.GETTER_NOT_SUBTYPE_SETTER_TYPES
// [cfe] unspecified
set nonSubtypes4(int _) {}

class C {
  static int? set staticWrongReturnType1(_) => 1;
  //     ^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
  // [cfe] unspecified

  static FutureOr<void> set staticWrongReturnType2(_) {}
  //     ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
  // [cfe] unspecified

  static Never set staticWrongReturnType3(_) => throw 1;
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
  // [cfe] unspecified

  /*space*/ int? set wrongReturnType1(_) => 1;
  //        ^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
  // [cfe] unspecified

  /*space*/ FutureOr<void> set wrongReturnType2(_) {}
  //        ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
  // [cfe] unspecified

  /*space*/ Never set wrongReturnType3(_) => throw 1;
  //        ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
  // [cfe] unspecified

  static int get staticNonSubtypes1 => 1;
  //             ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.GETTER_NOT_SUBTYPE_SETTER_TYPES
  // [cfe] unspecified
  static set staticNonSubtypes1(String _) {}

  static int? get staticNonSubtypes2 => 1;
  //              ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.GETTER_NOT_SUBTYPE_SETTER_TYPES
  // [cfe] unspecified
  static set staticNonSubtypes2(int _) {}

  static FutureOr<int> get staticNonSubtypes3 => 1;
  //                       ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.GETTER_NOT_SUBTYPE_SETTER_TYPES
  // [cfe] unspecified
  static set staticNonSubtypes3(int _) {}

  static dynamic get staticNonSubtypes4 => 1;
  //                 ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.GETTER_NOT_SUBTYPE_SETTER_TYPES
  // [cfe] unspecified
  static set staticNonSubtypes4(int _) {}

  int get nonSubtypes1 => 1;
  //      ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.GETTER_NOT_SUBTYPE_SETTER_TYPES
  // [cfe] unspecified
  set nonSubtypes1(String _) {}

  int? get nonSubtypes2 => 1;
  //       ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.GETTER_NOT_SUBTYPE_SETTER_TYPES
  // [cfe] unspecified
  set nonSubtypes2(int _) {}

  FutureOr<int> get nonSubtypes3 => 1;
  //                ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.GETTER_NOT_SUBTYPE_SETTER_TYPES
  // [cfe] unspecified
  set nonSubtypes3(int _) {}

  dynamic get nonSubtypes4 => 1;
  //          ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.GETTER_NOT_SUBTYPE_SETTER_TYPES
  // [cfe] unspecified
  set nonSubtypes4(int _) {}
}

main() {
  tooFew = 1;
  tooMany = 1;
  wrongReturnType1 = 1;
  wrongReturnType2 = 1;
  wrongReturnType3 = 1;
  C.staticWrongReturnType1 = 1;
  C.staticWrongReturnType2 = 1;
  C.staticWrongReturnType3 = 1;
  C().wrongReturnType1 = 1;
  C().wrongReturnType2 = 1;
  C().wrongReturnType3 = 1;
  var x1 = C.staticNonSubtypes1;
  C.staticNonSubtypes1 = '' as dynamic;
  var x2 = C.staticNonSubtypes2;
  C.staticNonSubtypes2 = 1 as dynamic;
  var x3 = C.staticNonSubtypes3;
  C.staticNonSubtypes3 = 1 as dynamic;
  var y1 = nonSubtypes1;
  nonSubtypes1 = '' as dynamic;
  var y2 = nonSubtypes2;
  nonSubtypes2 = 1 as dynamic;
  var y3 = nonSubtypes3;
  nonSubtypes3 = 1 as dynamic;
  var z1 = C().nonSubtypes1;
  C().nonSubtypes1 = '' as dynamic;
  var z2 = C().nonSubtypes2;
  C().nonSubtypes2 = 1 as dynamic;
  var z3 = C().nonSubtypes3;
  C().nonSubtypes3 = 1 as dynamic;
}
