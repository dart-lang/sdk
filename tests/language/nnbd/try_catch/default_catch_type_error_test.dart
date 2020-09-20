// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  try {} catch (error) {
    error.notAMethodOnObject();
    //    ^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'notAMethodOnObject' isn't defined for the class 'Object'.
    _takesObject(error);
  }
}

void _takesObject(Object o) {}
