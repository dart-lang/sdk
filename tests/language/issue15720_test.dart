// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js, issue 15720.

class B {}

confuse(x) {
  if (new DateTime.now() == 42) return confuse(x);
  return x;
}

main() {
  Set<B> set = new Set<B>.from([]);

  confuse(499);
  confuse(set);

  // Dart2js used to reuse a variable name, overwriting the `set` variable with
  // one of the B's.
  var t1 = new B();
  var t2 = new B();
  var t3 = new B();
  var t4 = new B();

  set.addAll([t1, t2, t3, t4]);
  confuse(7);

  set.addAll([t1, t2, t3, t4]);
}
