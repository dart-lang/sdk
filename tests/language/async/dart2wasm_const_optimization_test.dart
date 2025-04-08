// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasm special-cases async functions with some simple bodies. Check that
// calling these functions still creates a microtask, and awaiting them yields
// to the scheduler.

import 'dart:async';

import 'package:expect/expect.dart';

f1() async => const ["a", "b", "c"];

f2() async {
  return const ["x", "y", "z"];
}

f3() async {}

f4() async => "in f4";

f5() async {
  return "in f5";
}

checkScheduling(f, checkExpectedValue) async {
  final List<int> log = [];
  scheduleMicrotask(() {
    log.add(1);
  });
  log.add(0);
  checkExpectedValue(await f());
  log.add(2);
  Expect.listEquals([0, 1, 2], log);
}

void main() async {
  checkScheduling(f1, (value) => Expect.listEquals(["a", "b", "c"], value));
  checkScheduling(f2, (value) => Expect.listEquals(["x", "y", "z"], value));
  checkScheduling(f3, (value) => Expect.equals(null, value));
  checkScheduling(f4, (value) => Expect.equals("in f4", value));
  checkScheduling(f5, (value) => Expect.equals("in f5", value));
}
