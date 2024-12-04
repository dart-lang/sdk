// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=null-aware-elements

import '../static_type_helper.dart';

String? stringQuestion() => null;

main() {
  <String>[?""]; // Ok.
  //       ^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR

  <num>[?""];
  //    ^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
  //     ^
  // [cfe] A value of type 'String' can't be assigned to a variable of type 'num?'.

  <String>[?stringQuestion()]; // Ok.

  <num>[?stringQuestion()];
  //    ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
  //     ^
  // [cfe] A value of type 'String?' can't be assigned to a variable of type 'num?'.

  <String>[0: ?""];
  //       ^
  // [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'int' can't be assigned to a variable of type 'String'.
  //        ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ']' before this.

  <String>[0: ?stringQuestion()];
  //       ^
  // [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'int' can't be assigned to a variable of type 'String'.
  //        ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ']' before this.

  <String>[?"": 0];
  //       ^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
  //          ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ']' before this.

  <String>[?stringQuestion(): 0];
  //                        ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ']' before this.

  <String>{?""}; // Ok.
  //       ^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR

  <bool>{?""};
  //     ^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
  //     ^^^
  // [analyzer] COMPILE_TIME_ERROR.SET_ELEMENT_TYPE_NOT_ASSIGNABLE
  //      ^
  // [cfe] A value of type 'String' can't be assigned to a variable of type 'bool?'.

  <String>{?stringQuestion()}; // Ok.

  <bool>{?stringQuestion()};
  //     ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.SET_ELEMENT_TYPE_NOT_ASSIGNABLE
  //      ^
  // [cfe] A value of type 'String?' can't be assigned to a variable of type 'bool?'.

  <String>{0: ?""};
  //       ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MAP_ENTRY_NOT_IN_MAP
  //        ^
  // [cfe] Expected ',' before this.
  //          ^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR

  <String>{0: ?stringQuestion()};
  //       ^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MAP_ENTRY_NOT_IN_MAP
  //        ^
  // [cfe] Expected ',' before this.

  <String>{?"": 0};
  //       ^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
  //       ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MAP_ENTRY_NOT_IN_MAP
  //          ^
  // [cfe] Expected ',' before this.

  <String>{?stringQuestion(): 0};
  //       ^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MAP_ENTRY_NOT_IN_MAP
  //                        ^
  // [cfe] Expected ',' before this.

  <String, Symbol>{?"": #foo}; // Ok.
  //               ^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR

  <num, Symbol>{?"": #foo};
  //            ^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
  //             ^^
  // [analyzer] COMPILE_TIME_ERROR.MAP_KEY_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'String' can't be assigned to a variable of type 'num?'.

  <String, Symbol>{?stringQuestion(): #foo}; // Ok.

  <num, Symbol>{?stringQuestion(): #foo};
  //             ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MAP_KEY_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'String?' can't be assigned to a variable of type 'num?'.

  <int, String>{0: ?""}; // Ok.
  //               ^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR

  <int, num>{0: ?""};
  //            ^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
  //             ^^
  // [analyzer] COMPILE_TIME_ERROR.MAP_VALUE_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'String' can't be assigned to a variable of type 'num?'.

  <int, String>{0: ?stringQuestion()};

  <int, num>{0: ?stringQuestion()};
  //             ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MAP_VALUE_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'String?' can't be assigned to a variable of type 'num?'.

  <int, String>{0: "", ?""};
  //                   ^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
  //                   ^^^
  // [analyzer] COMPILE_TIME_ERROR.EXPRESSION_IN_MAP
  // [cfe] Expected ':' after this.
  // [cfe] The value 'null' can't be assigned to a variable of type 'String' because 'String' is not nullable.

  <int, String>{0: "", ?stringQuestion()};
  //                   ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXPRESSION_IN_MAP
  // [cfe] Expected ':' after this.
  // [cfe] The value 'null' can't be assigned to a variable of type 'String' because 'String' is not nullable.
}
