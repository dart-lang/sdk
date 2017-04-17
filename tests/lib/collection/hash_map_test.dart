// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";
import "package:expect/expect.dart";

void main() {
  // Test customized maps.
  // Regression test for issue http://dartbug.com/18109

  hash(s) => s.toLowerCase().hashCode;
  equals(a, b) => a.toLowerCase() == b.toLowerCase();

  for (var m in [
    new HashMap<String, int>(equals: equals, hashCode: hash),
    new LinkedHashMap<String, int>(equals: equals, hashCode: hash),
  ]) {
    m["Abel"] = 42;
    for (var key in ["Abel", "abel", "ABEL", "Abel"]) {
      Expect.isTrue(m.containsKey(key), "contains $key in ${m.runtimeType} $m");
      Expect.equals(42, m[key], "get $key in ${m.runtimeType} $m");
      Expect.equals(42, m.remove(key), "remove $key in ${m.runtimeType} $m");
      m[key] = 42;
    }
  }

  abshash(n) => n.abs();
  abseq(a, b) => a.abs() == b.abs();
  for (var m in [
    new HashMap<int, int>(equals: abseq, hashCode: abshash),
    new LinkedHashMap<int, int>(equals: abseq, hashCode: abshash),
  ]) {
    m[1] = 42;
    for (var key in [1, -1, 1]) {
      Expect.isTrue(m.containsKey(key), "contains $key in ${m.runtimeType} $m");
      Expect.equals(42, m[key], "get $key in ${m.runtimeType} $m");
      Expect.equals(42, m.remove(key), "remove $key in ${m.runtimeType} $m");
      m[key] = 42;
    }
  }
}
