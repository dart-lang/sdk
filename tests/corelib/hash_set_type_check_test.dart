// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of hash set type checking.

library hash_set_type_check_test;

import "package:expect/expect.dart";
import 'dart:collection';

testSet(Set<String> newSet()) {
  Set<String> s = newSet();
  Expect.throws(() => s.add(1), (e) => e is Error);
  Expect.isNull(s.lookup(1));
}

void testIdentitySet(Set create()) {
  Set<String> s = create();
  Expect.throws(() => s.add(1), (e) => e is Error);
  Expect.isNull(s.lookup(1));
}

bool get inCheckedMode {
  try {
    var i = 1;
    String j = i;
  } catch (_) {
    return true;
  }
  return false;
}

void main() {
  if (!inCheckedMode) return;

  testSet(() => new Set<String>());
  testSet(() => new HashSet<String>());
  testSet(() => new LinkedHashSet<String>());
  testIdentitySet(() => new Set<String>.identity());
  testIdentitySet(() => new HashSet<String>.identity());
  testIdentitySet(() => new LinkedHashSet<String>.identity());
  testIdentitySet(() => new HashSet<String>(
      equals: (x, y) => identical(x, y), hashCode: (x) => identityHashCode(x)));
  testIdentitySet(() => new LinkedHashSet<String>(
      equals: (x, y) => identical(x, y), hashCode: (x) => identityHashCode(x)));
}
