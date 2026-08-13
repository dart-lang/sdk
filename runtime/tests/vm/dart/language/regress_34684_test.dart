// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// No LICM on array bounds check (dartbug.com/34684).
//
// VMOptions=--deterministic --optimization_counter_threshold=10

import "package:expect/expect.dart";

List<int?> foo(int n, int k) {
  var l = new List<int?>.filled(1, null);
  var j = n - 1;
  for (var i = 0; i < k; i++) {
    l[j] = 10; // do not hoist
  }
  return l;
}

int x = -1;

List<int?> bar(int n, int k) {
  x = -1;
  var l = new List<int?>.filled(n, null);
  for (var i = 0; i < k; i++) {
    x = i;
    l[4] = 10; // do not hoist
  }
  return l;
}

void main() {
  List<int?>? l;

  for (int i = 0; i < 20; ++i) {
    l = foo(1, 0);
    Expect.equals(1, l.length);
    Expect.equals(null, l[0]);

    l = foo(2, 0);
    Expect.equals(1, l.length);
    Expect.equals(null, l[0]);

    l = foo(i, 0);
    Expect.equals(1, l.length);
    Expect.equals(null, l[0]);

    l = foo(1, 1);
    Expect.equals(1, l.length);
    Expect.equals(10, l[0]);

    l = foo(1, i + 1);
    Expect.equals(1, l.length);
    Expect.equals(10, l[0]);

    try {
      l = foo(-i, 1);
    } catch (_) {
      l = null;
    }
    Expect.equals(null, l);

    l = bar(5, 0);
    Expect.equals(5, l.length);
    Expect.equals(null, l[4]);
    Expect.equals(-1, x);

    l = bar(5, i + 1);
    Expect.equals(5, l.length);
    Expect.equals(10, l[4]);
    Expect.equals(i, x);

    try {
      l = bar(1, i + 1);
    } catch (_) {
      l = null;
    }
    Expect.equals(null, l);
    Expect.equals(0, x);
  }
}
