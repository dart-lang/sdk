// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// A class the has a getter also provided by Object
// (higher in the class hierarchy) and thus also the
// Null class (besides X in the class hierarchy).
class X {
  int hashCode;
  X() {
    hashCode = 1;
  }
}

// Use this getter on X receiver.
int hashMe(X x) {
  int d = 0;
  for (int i = 0; i < 10; i++) {
    d += x.hashCode;
  }
  return d;
}

// Use this getter on Null class receiver.
// Only possible value is null.
int hashNull(Null x) {
  int d = 0;
  for (int i = 0; i < 10; i++) {
    d += x.hashCode;
  }
  return d;
}

main() {
  // Warm up the JIT with just an X object. Having a single receiver
  // of type X with nothing below in the hierarchy that overrides
  // hashCode could tempt the JIT to inline the getter with CHA
  // that deopts when X is subclassed in the future.
  X x = new X();
  for (int i = 0; i < 1000; i++) {
    Expect.equals(10, hashMe(x));
  }

  // However, this is a special case that also works on null
  // (calling Object's hashCode). So this should not throw an
  // exception. Had we inlined, this would have hit the null
  // check and thrown an exception.
  Expect.notEquals(0, hashMe(null));

  // Also warm up the JIT on a direct Null receiver.
  int d = 0;
  for (int i = 0; i < 1000; i++) {
    d += hashNull(null);
  }
  Expect.notEquals(0, d);
}
