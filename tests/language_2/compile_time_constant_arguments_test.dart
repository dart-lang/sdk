// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  const A(a);
  const A.named({a: 42});
  const A.optional([a]);
}

main() {
  const A(1);
  const A();
  //     ^^
  // [analyzer] COMPILE_TIME_ERROR.NOT_ENOUGH_POSITIONAL_ARGUMENTS
  // [cfe] Too few positional arguments: 1 required, 0 given.
  const A(1, 2);
  //     ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTRA_POSITIONAL_ARGUMENTS
  // [cfe] Too many positional arguments: 1 allowed, but 2 found.
  const A.named();
  const A.named(b: 1);
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_NAMED_PARAMETER
  // [cfe] No named parameter with the name 'b'.
  const A.named(a: 1, a: 2);
  //                  ^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_NAMED_ARGUMENT
  // [cfe] Duplicated named argument 'a'.
  const A.named(a: 1, b: 2);
  //                  ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_NAMED_PARAMETER
  // [cfe] No named parameter with the name 'b'.
  const A.optional();
  const A.optional(42);
  const A.optional(42, 54);
  //              ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTRA_POSITIONAL_ARGUMENTS
  // [cfe] Too many positional arguments: 1 allowed, but 2 found.
}
