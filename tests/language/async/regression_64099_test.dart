// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/64099.
//
// When a bool local declared outside a loop is combined with a
// non-short-circuiting binary operator (|, &, ^) whose other operand contains
// an await, dart2wasm was emitting invalid wasm where a bool (i32) was left
// on the stack across an async suspension.

import 'package:expect/expect.dart';

Future<bool> f(int i) async => i.isEven;

Future<bool> testForOrAssign(int n) async {
  bool v = false;
  for (int i = 0; i < n; i++) {
    v |= await f(i);
  }
  return v;
}

Future<bool> testWhileOrAssign(int n) async {
  bool v = false;
  int i = 0;
  while (i < n) {
    v |= await f(i);
    i++;
  }
  return v;
}

Future<bool> testAndAssign(int n) async {
  bool v = true;
  for (int i = 0; i < n; i++) {
    v &= await f(i);
  }
  return v;
}

Future<bool> testXorAssign(int n) async {
  bool v = false;
  for (int i = 0; i < n; i++) {
    v ^= await f(i);
  }
  return v;
}

Future<bool> testBinaryOrLeft(int n) async {
  bool v = false;
  for (int i = 0; i < n; i++) {
    v = v | await f(i);
  }
  return v;
}

Future<bool> testBinaryOrRight(int n) async {
  bool v = false;
  for (int i = 0; i < n; i++) {
    v = await f(i) | v;
  }
  return v;
}

Future<bool> testBinaryAndLeft(int n) async {
  bool v = true;
  for (int i = 0; i < n; i++) {
    v = v & await f(i);
  }
  return v;
}

Future<bool> testBinaryAndRight(int n) async {
  bool v = true;
  for (int i = 0; i < n; i++) {
    v = await f(i) & v;
  }
  return v;
}

Future<bool> testBinaryXorLeft(int n) async {
  bool v = false;
  for (int i = 0; i < n; i++) {
    v = v ^ await f(i);
  }
  return v;
}

Future<bool> testBinaryXorRight(int n) async {
  bool v = false;
  for (int i = 0; i < n; i++) {
    v = await f(i) ^ v;
  }
  return v;
}

Future<int> testConditionalReuse(bool cond) async {
  return cond
      ? (await Future.value(42)).abs()
      : (await Future.value("hello")).length;
}

void main() async {
  Expect.isTrue(await testForOrAssign(4));
  Expect.isFalse(await testForOrAssign(0));

  Expect.isTrue(await testWhileOrAssign(4));
  Expect.isFalse(await testWhileOrAssign(0));

  Expect.isFalse(await testAndAssign(4));
  Expect.isTrue(await testAndAssign(1));
  Expect.isFalse(await testAndAssign(2));

  Expect.isFalse(await testXorAssign(4));
  Expect.isTrue(await testXorAssign(1));

  Expect.isTrue(await testBinaryOrLeft(4));
  Expect.isTrue(await testBinaryOrRight(4));

  Expect.isFalse(await testBinaryAndLeft(4));
  Expect.isFalse(await testBinaryAndRight(4));

  Expect.isTrue(await testBinaryXorLeft(1));
  Expect.isTrue(await testBinaryXorRight(1));

  Expect.equals(42, await testConditionalReuse(true));
  Expect.equals(5, await testConditionalReuse(false));
}
