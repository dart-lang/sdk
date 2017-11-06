// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test to catch error reporting bugs in class fields declarations.

import "package:expect/expect.dart";

class C {
  // illegal: var cannot follow final
  final var a = 0;// //# 00: syntax error
  // illegal: final field declaration, must be initialized
  final a; // //# 01: compile-time error
  final a = 0; // //# none: ok
}

main() {
  var val = new C();
  Expect.equals(val.a, 0);
}
