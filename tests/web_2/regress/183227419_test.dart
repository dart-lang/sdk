// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.10

// Regression test for variable allocator live range bug.
//
// Pre-fix, this program would crash because t2 was reused before it was dead.
//
//     algo$1: function(n) {
//       var t1 = this.ax,
//         t2 = t1 == null;
//       if ((t2 ? null : t1.a) == null)
//         return;
//       t2 = n + 1;  // the old value of t2 is used below!
//       (t2 ? null : t1.a).parameters.addAll$2(0, t2, t2);
//     }
//
// Several things were necessary to tickle the bug:
//
//  [A] The repeated test that gets shared from the two null-aware `ax?.a`
//      expressions.
//  [B] A null-aware `parameters?.` that is optimized away because `parameters`
//      is always non-null.
//  [C] A repeated expression after the optimized null-aware access.

class Thing {
  @pragma('dart2js:noInline')
  void addAll(x, y) {}
}

class A {
  Thing parameters = Thing();
}

class AX {
  A a;
  AX(this.a);
}

class Host {
  AX ax;
  Host(this.ax);

  algo(int n) {
    if (ax?.a == null) return;
    ax?.a.parameters?.addAll(n + 1, n + 1);
  }
}

main() {
  Host(null).algo(1);
  Host(AX(A())).algo(2);
  Host(AX(null)).algo(3);
}
