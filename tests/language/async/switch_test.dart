// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Formatting can break multitests, so don't format them.
// dart format off

import "dart:async";
import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

foo1(int a) async {
  int k = 0;
  switch (a) {
    case 1:
      await 3;
      k += 1;
      break;
    case 2:
      k += a;
      return k + 2;
  }
  return k;
}

foo2(Future<int> a) async {
  int k = 0;
  switch (await a) {
    case 1:
      await 3;
      k += 1;
      break;
    case 2:
      k += await a;
      return k + 2;
  }
  return k;
}

foo3(int a) async {
  int k = 0;
  switch (a) {
    case 1:
      k += 1;
      break;
    case 2:
      k += a;
      return k + 2;
  }
  return k;
}

foo4(value) async {
  int k = 0;
  switch (await value) {
    case 1:
      k += 1;
      break;
    case 2:
      k += 2;
      return 2 + k;
  }
  return k;
}

foo1WithDefault(int a) async {
  int k = 0;
  switch (a) {
    case 1:
      await 3;
      k += 1;
      break;
    case 2:
      k += a;
      return k + 2;
    default: k = 2;
  }
  return k;
}

foo2WithDefault(Future<int> a) async {
  int k = 0;
  switch (await a) {
    case 1:
      await 3;
      k += 1;
      break;
    case 2:
      k += await a;
      return k + 2;
    default: k = 2;
  }
  return k;
}

foo3WithDefault(int a) async {
  int k = 0;
  switch (a) {
    case 1:
      k += 1;
      break;
    case 2:
      k += a;
      return k + 2;
    default: k = 2;
  }
  return k;
}

foo4WithDefault(value) async {
  int k = 0;
  switch (await value) {
    case 1:
      k += 1;
      break;
    case 2:
      k += 2;
      return 2 + k;
    default: k = 2;
  }
  return k;
}

Future<int> futureOf(int a) async => await a;

Future test() async {
  Expect.equals(1, await foo1(1));
  Expect.equals(4, await foo1(2));
  Expect.equals(2, await foo1WithDefault(3));
  Expect.equals(0, await foo1(3));
  Expect.equals(1, await foo2(futureOf(1)));
  Expect.equals(4, await foo2(futureOf(2)));
  Expect.equals(2, await foo2WithDefault(futureOf(3)));
  Expect.equals(0, await foo2(futureOf(3)));
  Expect.equals(1, await foo3(1));
  Expect.equals(4, await foo3(2));
  Expect.equals(2, await foo3WithDefault(3));
  Expect.equals(0, await foo3(3));
  Expect.equals(1, await foo4(futureOf(1)));
  Expect.equals(4, await foo4(futureOf(2)));
  Expect.equals(2, await foo4WithDefault(futureOf(3)));
  Expect.equals(0, await foo4(futureOf(3)));
}

void main() {
  asyncStart();
  test().then((_) => asyncEnd());
}
