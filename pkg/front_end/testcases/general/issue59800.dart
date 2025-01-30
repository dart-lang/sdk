// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  final int? foo;
  const A(this.foo);
}

const int? CNull = null;
const int? CInt = 0;
const A CANull = const A(null);
const A CAInt = const A(0);

const int C1 = 0!; // Error.
const int C2 = null!; // Error.
const int C3 = CInt!; // Error.
const int C4 = CNull!; // Error.
const int C5 = CAInt.foo!; // Error.
const int C6 = CANull.foo!; // Error.
const int C7 = "".length!; // Error.
const int C8 = ""!.length; // Error.
const int C9 = ""!.length!; // Error.

test() {
  return [C1, C2, C3, C4, C5, C6, C7, C8, C9];
}

main() {}
