// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";
import "package:expect/expect.dart";

void main() {
  // Test customized sets.
  // Regression test for issue http://dartbug.com/18109

  int hash(s) => s.toLowerCase().hashCode;
  bool equals(a, b) => a.toLowerCase() == b.toLowerCase();

  for (var m in [
    new HashSet<String>(equals: equals, hashCode: hash),
    new LinkedHashSet<String>(equals: equals, hashCode: hash),
  ]) {
    m.add("Abel");
    var prev = "Abel";
    for (var key in ["Abel", "abel", "ABEL", "Abel"]) {
      Expect.isTrue(m.contains(key), "contains $key in ${m.runtimeType} $m");
      Expect.equals(prev, m.lookup(key), "lookup $key in ${m.runtimeType} $m");
      Expect.isTrue(m.remove(key), "remove $key in ${m.runtimeType} $m");
      m.add(key);
      prev = key;
    }
  }

  int abshash(n) => n.abs();
  bool abseq(a, b) => a.abs() == b.abs();
  for (var m in [
    new HashSet<int>(equals: abseq, hashCode: abshash),
    new LinkedHashSet<int>(equals: abseq, hashCode: abshash),
  ]) {
    m.add(1);
    var prev = 1;
    for (var key in [1, -1, 1]) {
      Expect.isTrue(m.contains(key), "contains $key in ${m.runtimeType} $m");
      Expect.equals(prev, m.lookup(key), "lookup $key in ${m.runtimeType} $m");
      Expect.isTrue(m.remove(key), "remove $key in ${m.runtimeType} $m");
      m.add(key);
      prev = key;
    }
  }
}
