// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=-1 --stacktrace-filter=completeError --stress-async-stacks

// Stress test for async stack traces.

import 'dart:async';
import "package:expect/expect.dart";

class A {
  Future<List<int>> read() => new Future.error(123);
}

Future<A> haha() => new Future.microtask(() => new A());

Future<List<int>> mm() async => (await haha()).read();

foo() async => await mm();

main() async {
  var x;
  try {
    x = await foo();
  } catch (e) {
    Expect.equals(123, e);
    return;
  }
  Expect.isTrue(false);
}
