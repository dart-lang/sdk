// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// If a constant constructor contains an initializer, or an initializing
// formal, for a final field which itself has an initializer at its
// declaration, then a compile-time error should be reported regardless of
// whether the constructor is called with "const" or "new".

import "package:expect/expect.dart";

class C {
  final x = 1;
  const C() : x = 2; //# 01: compile-time error
  const C() : x = 2; //# 02: compile-time error
  const C(this.x); //# 03: compile-time error
  const C(this.x); //# 04: compile-time error
}

main() {
  const C(); //# 01: continued
  new C(); //# 02: continued
  const C(2); //# 03: continued
  new C(2); //# 04: continued
}
