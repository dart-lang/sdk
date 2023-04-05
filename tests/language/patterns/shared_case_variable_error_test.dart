// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=patterns,records

import "package:expect/expect.dart";

main() {
  // Variables in shared cases must agree on finality if used in the body.
  switch ((0, 1)) {
    case (0, int x):
    case (1, final int x):
      print(x);
      //    ^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_PATTERN_VARIABLE_IN_SHARED_CASE_SCOPE
      // [cfe] Variable pattern 'x' doesn't have the same type or finality in all cases.
  }

  switch ((0, 1)) {
    case (2, var x):
    case (3, final x):
      print(x);
      //    ^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_PATTERN_VARIABLE_IN_SHARED_CASE_SCOPE
      // [cfe] Variable pattern 'x' doesn't have the same type or finality in all cases.
  }

  // Variables in shared cases must agree on type if used in the body.
  switch ((0, 1)) {
    case (0, int x):
    case (1, num x):
      print(x);
      //    ^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_PATTERN_VARIABLE_IN_SHARED_CASE_SCOPE
      // [cfe] Variable pattern 'x' doesn't have the same type or finality in all cases.
  }

  switch ((0, 's')) {
    case (0, int x):
    case (2, var x): // Infer String.
      print(x);
      //    ^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_PATTERN_VARIABLE_IN_SHARED_CASE_SCOPE
      // [cfe] Variable pattern 'x' doesn't have the same type or finality in all cases.
  }

  // Variables must be defined in all cases if used in body.
  switch ((0, 1)) {
    case (0, var unique):
    case (1, var inTwo):
    case (2, var inTwo):
      print(unique);
      //    ^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_PATTERN_VARIABLE_IN_SHARED_CASE_SCOPE
      // [cfe] The variable 'unique' is available in some, but not all cases that share this body.

      print(inTwo);
      //    ^^^^^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_PATTERN_VARIABLE_IN_SHARED_CASE_SCOPE
      // [cfe] The variable 'inTwo' is available in some, but not all cases that share this body.
  }

  // Mismatched variable types because of inference from a promoted type.
  Object value = 1;
  // Promote value to int.
  if (value is int) {
    switch ((0, value)) {
      case (0, var a):
      case (1, Object a):
        print(a);
        //    ^
        // [analyzer] COMPILE_TIME_ERROR.INVALID_PATTERN_VARIABLE_IN_SHARED_CASE_SCOPE
        // [cfe] Variable pattern 'a' doesn't have the same type or finality in all cases.
    }
  }
}
