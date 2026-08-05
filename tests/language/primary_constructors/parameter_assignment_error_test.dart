// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that assignment to non-declaring primary constructor parameters are
// illegal in the initializer list and field initializer. The corresponding
// regular constructor variants in 'parameters_assignment_test.dart' are
// legal.

class S0 {
  S0(x);
}

class C0(int? i) extends S0 {
  this : super((i = 0) == 0);
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_PRIMARY_CONSTRUCTOR_PARAMETER
  // [cfe] A primary constructor parameter can't be assigned to in an initializer.
}

class C1(int? i) {
  bool field = (i = 0) == 0;
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_PRIMARY_CONSTRUCTOR_PARAMETER
  // [cfe] A primary constructor parameter can't be assigned to in an initializer.
}
