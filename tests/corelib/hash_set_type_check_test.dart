// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of hash set type checking.

library hash_set_type_check_test;

import "package:expect/expect.dart";
import 'dart:collection';

// TODO: all this test does now is verify that lookup takes a non-T
//       should merge this with `hash_test_test`.
testSet(Set<String> newSet()) {
  Set<String> s = newSet();
  Expect.isNull(s.lookup(1));
}

void main() {
  testSet(() => new Set<String>());
  testSet(() => new HashSet<String>());
  testSet(() => new LinkedHashSet<String>());
  testSet(() => new Set<String>.identity());
  testSet(() => new HashSet<String>.identity());
  testSet(() => new LinkedHashSet<String>.identity());
  testSet(() => new HashSet<String>(
      equals: (x, y) => identical(x, y), hashCode: (x) => identityHashCode(x)));
  testSet(() => new LinkedHashSet<String>(
      equals: (x, y) => identical(x, y), hashCode: (x) => identityHashCode(x)));
}
