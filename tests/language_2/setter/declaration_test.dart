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

/*space*/ int set wrongReturnType1(_) {}
//        ^^^
// [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
// [cfe] unspecified

/*space*/ FutureOr<void> set wrongReturnType2(_) {}
//        ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
// [cfe] unspecified

/*space*/ Never set wrongReturnType3(_) {}
//        ^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
// [cfe] unspecified

class C {
  static int set staticWrongReturnType1(_) => 1;
  //     ^^^
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

  /*space*/ int set wrongReturnType1(_) {}
  //        ^^^
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

  static int get staticNonAssignableTypes1 => 1;
  //             ^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.GETTER_NOT_ASSIGNABLE_SETTER_TYPES
  // [cfe] unspecified
  static set staticNonAssignableTypes1(String _) {}

  static num get staticAssignableTypes1 => 1;
  static set staticAssignableTypes1(int _) {}

  static FutureOr<int> get staticAssignableTypes2 => 1;
  static set staticAssignableTypes2(int _) {}

  static dynamic get staticAssignableTypes3 => 1;
  static set staticAssignableTypes3(int _) {}

  int get nonAssignableTypes1 => 1;
  //      ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.GETTER_NOT_ASSIGNABLE_SETTER_TYPES
  // [cfe] unspecified
  set nonAssignableTypes1(String _) {}

  num get assignableTypes1 => 1;
  set assignableTypes1(int _) {}

  FutureOr<int> get assignableTypes2 => 1;
  set assignableTypes2(int _) {}

  dynamic get assignableTypes3 => 1;
  set assignableTypes3(int _) {}
}

main() {
  tooFew = 1;
  tooMany = 1;
  wrongReturnType1 = 1;
  wrongReturnType2 = 1;
  wrongReturnType3 = 1;
  C.staticWrongReturnType1 = 4;
  C.staticWrongReturnType2 = 4;
  C.staticWrongReturnType3 = 4;
  C().wrongReturnType1 = 5;
  C().wrongReturnType2 = 5;
  C().wrongReturnType3 = 5;
  var x1 = C.staticNonAssignableTypes1;
  C.staticNonAssignableTypes1 = '' as dynamic;
  var y1 = C.staticAssignableTypes1;
  C.staticAssignableTypes1 = '' as dynamic;
  var y2 = C.staticAssignableTypes2;
  C.staticAssignableTypes2 = '' as dynamic;
  var y3 = C.staticAssignableTypes3;
  C.staticAssignableTypes3 = '' as dynamic;
  var z1 = C().nonAssignableTypes1;
  C().nonAssignableTypes1 = '' as dynamic;
  var w1 = C().assignableTypes1;
  C().assignableTypes1 = '' as dynamic;
  var w2 = C().assignableTypes2;
  C().assignableTypes2 = '' as dynamic;
  var w3 = C().assignableTypes3;
  C().assignableTypes3 = '' as dynamic;
}
