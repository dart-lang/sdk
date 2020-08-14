// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  new C(42);
  //  ^
  // [cfe] Can't use 'C' because it is declared more than once.
  //   ^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTRA_POSITIONAL_ARGUMENTS
}

class C {
  final d;
  //    ^
  // [cfe] Final field 'd' is not initialized.

  C() {}
//^
// [analyzer] COMPILE_TIME_ERROR.FINAL_NOT_INITIALIZED_CONSTRUCTOR
  C(this.d) {}
//^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_CONSTRUCTOR
// [cfe] 'C' is already declared in this scope.
}
