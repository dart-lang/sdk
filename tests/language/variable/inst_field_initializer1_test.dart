// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Catch illegal access to 'this' in initialized instance fields.

class A {
  var x = 5;
  var arr = [x]; // Illegal access to 'this'.
  //         ^
  // [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
  // [cfe] Can't access 'this' in a field initializer to read 'x'.
  //         ^
  // [analyzer] STATIC_WARNING.TOP_LEVEL_INSTANCE_GETTER
}

void main() {
  A();
}
