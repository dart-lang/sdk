// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test to catch error reporting bugs in class fields declarations.

import "package:expect/expect.dart";

class C {
  // illegal: var cannot follow final
  final var a = 0;// //# 00: syntax error
  // illegal: final field declaration, must be initialized
  final b; // //# 01: compile-time error
  final c; // //# 02: compile-time error
  final d; // //# 03: ok
  final e; // //# 04: ok
  final f = 0; // //# 05: ok

  C() {} //# 02: continued
  C(this.d) {} //# 03: continued
  C(x) : e = x {} //# 04: continued
}

main() {
  var val = new C(); //# 00: continued
  var val = new C(); //# 01: continued
  var val = new C(); //# 02: continued
  var val = new C(0); //# 03: continued
  var val = new C(0); //# 04: continued
  var val = new C(); //# 05: continued
}
