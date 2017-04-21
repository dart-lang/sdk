// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Override {
  int hash;
  int get superHash => super.hashCode;
  int get hashCode => hash;

  int foo() => hash; //   Just some function that can be closurized.

  bool operator ==(Object other) =>
      other is Override && (other as Override).hash == hash;
}

int bar() => 42; // Some global function.

main() {
  var o = new Object();
  var hash = o.hashCode;
  // Doesn't change.
  Expect.equals(hash, o.hashCode);
  Expect.equals(hash, identityHashCode(o));

  var c = new Override();
  int identityHash = c.superHash;
  hash = (identityHash == 42) ? 37 : 42;
  c.hash = hash;
  Expect.equals(hash, c.hashCode);
  Expect.equals(identityHash, identityHashCode(c));

  // These classes don't override hashCode.
  var samples = [0, 0x10000000, 1.5, -0, null, true, false, const Object()];
  for (var v in samples) {
    print(v);
    Expect.equals(v.hashCode, identityHashCode(v));
  }
  // These do, or might do, but we can still use hashCodeOf and get the same
  // result each time.
  samples = ["string", "", (x) => 42, c.foo, bar];
  for (var v in samples) {
    print(v);
    Expect.equals(v.hashCode, v.hashCode);
    Expect.equals(identityHashCode(v), identityHashCode(v));
  }
}
