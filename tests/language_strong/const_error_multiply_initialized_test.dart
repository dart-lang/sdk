// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// If a constant constructor contains an initializer, or an initializing
// formal, for a final field which itself has an initializer at its
// declaration, then a runtime error should occur if that constructor is
// invoked using "new", but there should be no compile-time error.  However, if
// the constructor is invoked using "const", there should be a compile-time
// error, since it is a compile-time error for evaluation of a constant object
// to result in an uncaught exception.

import "package:expect/expect.dart";

class C {
  final x = 1;
  const C() : x = 2; /// 01: compile-time error
  const C() : x = 2; /// 02: static type warning
  const C(this.x); /// 03: compile-time error
  const C(this.x); /// 04: static type warning
}

main() {
  const C(); /// 01: continued
  Expect.throws(() => new C()); /// 02: continued
  const C(2); /// 03: continued
  Expect.throws(() => new C(2)); /// 04: continued
}
