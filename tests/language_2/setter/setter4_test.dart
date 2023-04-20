// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test to catch error reporting bugs in class fields declarations.
// Should be an error because we have a setter overriding a function name.

// @dart = 2.9

class A {
  int a() {
    return 1;
  }

  void set a(var val) {
    //     ^
    // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
    // [cfe] 'a' is already declared in this scope.
    int i = val;
  }
}

main() {}
