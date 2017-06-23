// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class C {
  // Since this field is final and already initialized, the specification says
  // that a runtime error occurs when attempting to initialize it in the
  // constructor. When used as a compile-time constant, this causes a
  // compile-time error.
  final x = 1;

  const C(
      this. //# 01: compile-time error
      this. //# 02: compile-time error 
      x
    )
    : x = 2 //# 03: compile-time error
    : x = 2 //# 04: compile-time error
    ;
}

instantiateC() {
  const C(0); //# 01: continued
  const C(0); //# 03: continued
  new C(0);
}

main() {
  bool shouldThrow = false;
  shouldThrow = true; //# 02: continued
  shouldThrow = true; //# 04: continued
  if (shouldThrow) {
    Expect.throws(instantiateC());
  } else {
    instantiateC();
  }
}
