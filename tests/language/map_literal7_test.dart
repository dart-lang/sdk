// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the use type arguments on constant maps.

library map_literal7_test;

import "package:expect/expect.dart";

void main() {
  var m1 = const {"0": 0, "1": 1};
  Expect.isTrue(m1 is Map);
  Expect.isTrue(m1 is Map<String, int>);
  Expect.isTrue(m1 is Map<int, dynamic>);
  Expect.isTrue(m1 is Map<dynamic, String>);

  var m2 = const <String, int>{"0": 0, "1": 1};
  Expect.isTrue(m2 is Map);
  Expect.isTrue(m2 is Map<String, int>);
  Expect.isFalse(m2 is Map<int, dynamic>);
  Expect.isFalse(m2 is Map<dynamic, String>);
}
