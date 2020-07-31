// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the use type arguments on constant maps.

library map_literal9_test;

import "package:expect/expect.dart";

void main() {
  var m1 = const {"[object Object]": 0, "1": 1};
  Expect.isFalse(m1.containsKey(new Object()));
  Expect.isNull(m1[new Object()]);
  Expect.isFalse(m1.containsKey(1));
  Expect.isNull(m1[1]);

  var m2 = const {"[object Object]": 0, "1": 1, "__proto__": 2};
  Expect.isFalse(m2.containsKey(new Object()));
  Expect.isNull(m2[new Object()]);
  Expect.isFalse(m2.containsKey(1));
  Expect.isNull(m2[1]);
}
