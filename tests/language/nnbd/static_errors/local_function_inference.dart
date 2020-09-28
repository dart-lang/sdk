// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that the type of a local function is an error if local function type
/// inference requires the type of the function being inferred.

void main() {
  f() {
    return 3;
  }

  f().arglebargle;
  //  ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'arglebargle' isn't defined for the class 'int'.
  f().isEven; // Inferred type is int

  g() {
    if (f() == 3) {
      return g();
    } else {
      return 3;
    }
  }
  //  ^
  // [analyzer] undefined
  // [cfe] undefined
}
