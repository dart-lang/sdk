// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "package:expect/expect.dart";

void main() {
  // Test object startIndex
  "hello".replaceFirst("h", "X", new Object());
  //                             ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CAST_NEW_EXPR
  //                                 ^
  // [cfe] The constructor returns type 'Object' that isn't of expected type 'int'.

  // Test object startIndex
  "hello".replaceFirstMapped("h", (_) => "X", new Object());
  //                                          ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CAST_NEW_EXPR
  //                                              ^
  // [cfe] The constructor returns type 'Object' that isn't of expected type 'int'.

  "foo-bar".replaceFirstMapped("bar", (v) {
    return 42;
    //     ^^
    // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE_FROM_CLOSURE
    // [cfe] A value of type 'int' can't be assigned to a variable of type 'String'.
  });

  "hello".replaceRange(0, 0, 42);
  //                         ^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'int' can't be assigned to the parameter type 'String'.
  "hello".replaceRange(0, 0, ["x"]);
  //                         ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'List<String>' can't be assigned to the parameter type 'String'.
}

// Fails to return a String on toString, throws if converted by "$naughty".
class Naughty {
  toString() => this;
  //            ^^^^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
  // [cfe] A value of type 'Naughty' can't be assigned to a variable of type 'String'.
}
