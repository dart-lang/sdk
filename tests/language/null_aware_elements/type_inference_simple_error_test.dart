// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=null-aware-elements

import '../static_type_helper.dart';

String? stringQuestion() => null;

main() {
  <String>[?""]; // Ok.

  <num>[?""];
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE

  <String>[?stringQuestion()]; // Ok.

  <num>[?stringQuestion()];
  //    ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE

  <String>[0: ?""];
  //       ^
  // [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
  //        ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [web] Expected ']' before this.

  <String>[0: ?stringQuestion()];
  //       ^
  // [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
  //        ^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [web] Expected ']' before this.

  <String>[?"": 0];
  //       ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MAP_ENTRY_NOT_IN_MAP

  <String>[?stringQuestion(): 0];
  //       ^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MAP_ENTRY_NOT_IN_MAP

  <String>{?""}; // Ok.

  <bool>{?""};
  //     ^^^
  // [analyzer] COMPILE_TIME_ERROR.SET_ELEMENT_TYPE_NOT_ASSIGNABLE

  <String>{?stringQuestion()}; // Ok.

  <bool>{?stringQuestion()};
  //     ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.SET_ELEMENT_TYPE_NOT_ASSIGNABLE

  <String>{0: ?""};
  //       ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MAP_ENTRY_NOT_IN_MAP

  <String>{0: ?stringQuestion()};
  //       ^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MAP_ENTRY_NOT_IN_MAP

  <String>{?"": 0};
  //       ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MAP_ENTRY_NOT_IN_MAP

  <String>{?stringQuestion(): 0};
  //       ^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MAP_ENTRY_NOT_IN_MAP

  <String, Symbol>{?"": #foo}; // Ok.

  <num, Symbol>{?"": #foo};
  //             ^^
  // [analyzer] COMPILE_TIME_ERROR.MAP_KEY_TYPE_NOT_ASSIGNABLE

  <String, Symbol>{?stringQuestion(): #foo}; // Ok.

  <num, Symbol>{?stringQuestion(): #foo};
  //             ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MAP_KEY_TYPE_NOT_ASSIGNABLE

  <int, String>{0: ?""}; // Ok.

  <int, num>{0: ?""};
  //             ^^
  // [analyzer] COMPILE_TIME_ERROR.MAP_VALUE_TYPE_NOT_ASSIGNABLE

  <int, String>{0: ?stringQuestion()};

  <int, num>{0: ?stringQuestion()};
  //             ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MAP_VALUE_TYPE_NOT_ASSIGNABLE

  <int, String>{0: "", ?""};
  //                   ^^^
  // [analyzer] COMPILE_TIME_ERROR.EXPRESSION_IN_MAP

  <int, String>{0: "", ?stringQuestion()};
  //                   ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXPRESSION_IN_MAP
}
