// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library stream_min_max_test;

import 'dart:async';
import 'dart:isolate';
import '../../../pkg/unittest/lib/unittest.dart';
import 'event_helper.dart';

const int big = 1000000;
const double inf = double.INFINITY;
List intList = const [-0, 0, -1, 1, -10, 10, -big, big];
List doubleList = const [-0.0, 0.0, -1.0, 1.0, -10.0, 10.0, -inf, inf];

main() {
  testMinMax(name, iterable, min, max, [int compare(a, b)]) {
    test("$name-min", () {
      StreamController c = new StreamController();
      Future f = c.stream.min(compare);
      f.then(expectAsync1((v) { Expect.equals(min, v);}));
      new Events.fromIterable(iterable).replay(c);
    });
    test("$name-max", () {
      StreamController c = new StreamController();
      Future f = c.stream.max(compare);
      f.then(expectAsync1((v) { Expect.equals(max, v);}));
      new Events.fromIterable(iterable).replay(c);
    });
  }

  testMinMax("const-int", intList, -big, big);
  testMinMax("list-int", intList.toList(), -big, big);
  testMinMax("set-int", intList.toSet(), -big, big);

  testMinMax("const-double", doubleList, -inf, inf);
  testMinMax("list-double", doubleList.toList(), -inf, inf);
  testMinMax("set-double", doubleList.toSet(), -inf, inf);

  int reverse(a, b) => b.compareTo(a);
  testMinMax("rev-int", intList, big, -big, reverse);
  testMinMax("rev-double", doubleList, inf, -inf, reverse);
}
