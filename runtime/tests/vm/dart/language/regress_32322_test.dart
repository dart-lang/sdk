// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that optimizing compiler does not perform an illegal code motion
// past CheckNull instruction.

import "package:expect/expect.dart";

class C {
  final String padding = "";
  final String field = "1"; // Note: need padding to hit an object header
  // of the next object after [null] object when
  // doing illegal null.field read. Need to hit
  // object header to cause crash.
}

int foofoo(C? p) {
  int sum = 0;
  for (var i = 0; i < 10; i++) {
    // Note: need redundant instructions in the loop to trigger Canonicalize
    // after CSE. Canonicalize then would illegally remove the Redefinition.
    sum += p!.field.length;
    sum += p.field.length;
  }
  return sum;
}

void main() {
  Expect.equals(20, foofoo(new C()));
  Expect.throwsTypeError(() => foofoo(null));
}
