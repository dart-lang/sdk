// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a setter has a single argument.

import 'dart:async';

set tooFew() {}
//  ^^^^^^
// [analyzer] SYNTACTIC_ERROR.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER
//        ^
// [cfe] A setter should have exactly one formal parameter.

set tooMany(value, var extra) {}
//  ^^^^^^^
// [analyzer] SYNTACTIC_ERROR.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER
//         ^
// [cfe] A setter should have exactly one formal parameter.

int? set wrongReturnType1(_) => 1;
// [error column 1, length 4]
// [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
// [cfe] The return type of the setter must be 'void' or absent.

FutureOr<void> set wrongReturnType2(_) {}
// [error column 1, length 14]
// [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
// [cfe] The return type of the setter must be 'void' or absent.

Never set wrongReturnType3(_) => throw 1;
// [error column 1, length 5]
// [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
// [cfe] The return type of the setter must be 'void' or absent.

int get nonSubtypes1 => 1;
set nonSubtypes1(String _) {}

int? get nonSubtypes2 => 1;
set nonSubtypes2(int _) {}

FutureOr<int> get nonSubtypes3 => 1;
set nonSubtypes3(int _) {}

dynamic get nonSubtypes4 => 1;
set nonSubtypes4(int _) {}

class C {
  static int? set staticWrongReturnType1(_) => 1;
  //     ^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
  // [cfe] The return type of the setter must be 'void' or absent.

  static FutureOr<void> set staticWrongReturnType2(_) {}
  //     ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
  // [cfe] The return type of the setter must be 'void' or absent.

  static Never set staticWrongReturnType3(_) => throw 1;
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
  // [cfe] The return type of the setter must be 'void' or absent.

  int? set wrongReturnType1(_) => 1;
  // [error column 3, length 4]
  // [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
  // [cfe] The return type of the setter must be 'void' or absent.

  FutureOr<void> set wrongReturnType2(_) {}
  // [error column 3, length 14]
  // [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
  // [cfe] The return type of the setter must be 'void' or absent.

  Never set wrongReturnType3(_) => throw 1;
  // [error column 3, length 5]
  // [analyzer] COMPILE_TIME_ERROR.NON_VOID_RETURN_FOR_SETTER
  // [cfe] The return type of the setter must be 'void' or absent.

  static int get staticNonSubtypes1 => 1;
  static set staticNonSubtypes1(String _) {}

  static int? get staticNonSubtypes2 => 1;
  static set staticNonSubtypes2(int _) {}

  static FutureOr<int> get staticNonSubtypes3 => 1;
  static set staticNonSubtypes3(int _) {}

  static dynamic get staticNonSubtypes4 => 1;
  static set staticNonSubtypes4(int _) {}

  int get nonSubtypes1 => 1;
  set nonSubtypes1(String _) {}

  int? get nonSubtypes2 => 1;
  set nonSubtypes2(int _) {}

  FutureOr<int> get nonSubtypes3 => 1;
  set nonSubtypes3(int _) {}

  dynamic get nonSubtypes4 => 1;
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
