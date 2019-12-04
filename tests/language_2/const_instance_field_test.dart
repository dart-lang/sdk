// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that const instance fields are compile-time errors.

class C {
  const field = 0;
//^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INSTANCE_FIELD
// [cfe] Only static fields can be declared as const.
}

void main() {
  new C();
}
