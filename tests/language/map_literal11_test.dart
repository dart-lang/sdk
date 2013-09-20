// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the use of reliance on identity for keys in constant maps.

library map_literal11_test;

import "package:expect/expect.dart";


class A {
  static int accessCount = 0;

  final int field;

  const A(this.field);
  int get hashCode => accessCount++;
}

void main() {
  // Non-constant map are not based on identity.
  var m1 = {const A(0): 0, const A(1): 1, null: 2, "3": 3, 4: 4};
  Expect.isFalse(m1.containsKey(const A(0)));
  Expect.isFalse(m1.containsKey(const A(1)));
  Expect.isTrue(m1.containsKey(null));
  Expect.isTrue(m1.containsKey("3"));
  Expect.isTrue(m1.containsKey(4));
  Expect.isNull(m1[const A(0)]);
  Expect.isNull(m1[const A(1)]);
  Expect.equals(2, m1[null]);
  Expect.equals(3, m1["3"]);
  Expect.equals(4, m1[4]);

  // Constant map are based on identity.
  var m2 = const {const A(0): 0, const A(1): 1, null: 2, "3": 3, 4: 4};
  Expect.isTrue(m2.containsKey(const A(0)));
  Expect.isTrue(m2.containsKey(const A(1)));
  Expect.isTrue(m2.containsKey(null));
  Expect.isTrue(m2.containsKey("3"));
  Expect.isTrue(m2.containsKey(4));
  Expect.equals(0, m2[const A(0)]);
  Expect.equals(1, m2[const A(1)]);
  Expect.equals(2, m2[null]);
  Expect.equals(3, m2["3"]);
  Expect.equals(4, m2[4]);
}
