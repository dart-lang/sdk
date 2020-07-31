// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test with OSR on non-empty stack (block expression).

import 'dart:core';
import "package:expect/expect.dart";

class Z {
  @pragma('vm:never-inline')
  check(int a, int b, String c, List<int> d) {
    Expect.equals(a, 42);
    Expect.equals(b, global_bazz);
    Expect.equals(c, 'abc');
    return d;
  }
}

Z z = new Z();
int global_bazz = 123;
int global_more_bazz = 456;

@pragma('vm:never-inline')
int bazz() {
  return ++global_bazz;
}

@pragma('vm:never-inline')
int more_bazz() {
  return ++global_more_bazz;
}

@pragma('vm:never-inline')
int bar(int i) {
  return i - 1;
}

@pragma('vm:never-inline')
List<int> spread(int v, List<int> x) {
  return [v, ...x];
}

// Long running control-flow collection (block expression),
// leaves the stack non-empty during a potential OSR.
@pragma('vm:never-inline')
List<int> test1(int n) {
  return spread(more_bazz(), [for (int i = 0; i < n; i++) i]);
}

// Long running control-flow collection (block expression) inside outer
// loop, leaves the stack non-empty during a potential OSR.
List<int> test2(int n) {
  List<int> x = [];
  for (int k = 0; k < 10; k++) {
    x += spread(more_bazz(), [for (int i = 0; i < n; i++) i]);
  }
  return x;
}

// Long running control-flow collection (block expression) inside two
// outer loops, leaves the stack non-empty during a potential OSR.
List<int> test3(int n) {
  List<int> x = [];
  for (int k = 0; k < 4; k++) {
    for (int j = 0; j < 4; j++) {
      x += spread(more_bazz(), [for (int i = 0; i < n; i++) i]);
    }
  }
  return x;
}

// Long running control-flow collection (block expression),
// leaves the stack non-empty during a potential OSR.
@pragma('vm:never-inline')
List<int> test4(int n) {
  var x = [10] +
      z.check(42, bazz(), 'abc',
          [more_bazz(), for (int i = 0; i < n; i++) bar(2 * i)]);
  return x;
}

// Long running control-flow collection (block expression) inside outer
// loop, also leaves the stack non-empty during a potential OSR.
@pragma('vm:never-inline')
List<int> test5(int m, int n) {
  List<int> x = [];
  for (int k = 0; k < m; k++) {
    x += [10] +
        z.check(42, bazz(), 'abc',
            [more_bazz(), for (int i = 0; i < n; i++) bar(2 * i)]);
  }
  return x;
}

List<int> globalList = [
  1,
  for (int loc1 = 2; loc1 <= 100000; loc1++) loc1,
  100001
];

main() {
  int n = 20000;
  int g = 457;

  var a = test1(n);
  Expect.equals(a.length, n + 1);
  for (int k = 0; k < n + 1; k++) {
    int expect = (k == 0) ? g++ : k - 1;
    Expect.equals(a[k], expect);
  }

  var b = test2(n);
  Expect.equals(b.length, 10 * (n + 1));
  for (int i = 0, k = 0; i < 10 * (n + 1); i++) {
    int expect = (k == 0) ? g++ : k - 1;
    Expect.equals(b[i], expect);
    if (++k == (n + 1)) k = 0;
  }

  var c = test3(n);
  Expect.equals(c.length, 16 * (n + 1));
  for (int i = 0, k = 0; i < 16 * (n + 1); i++) {
    int expect = (k == 0) ? g++ : k - 1;
    Expect.equals(c[i], expect);
    if (++k == (n + 1)) k = 0;
  }

  var d = test4(n);
  Expect.equals(d.length, n + 2);
  for (int k = 0; k < n + 2; k++) {
    int expect = k <= 1 ? ((k == 0) ? 10 : g++) : -5 + 2 * k;
    Expect.equals(d[k], expect);
  }

  var e = test5(10, n);
  Expect.equals(e.length, 10 * (n + 2));
  for (int i = 0, k = 0; i < 10 * (n + 2); i++) {
    int expect = k <= 1 ? ((k == 0) ? 10 : g++) : -5 + 2 * k;
    Expect.equals(e[i], expect);
    if (++k == (n + 2)) k = 0;
  }

  Expect.isTrue(globalList != null);
  Expect.equals(100001, globalList.length);
  for (int i = 0; i < globalList.length; i++) {
    Expect.equals(globalList[i], i + 1);
  }
}
