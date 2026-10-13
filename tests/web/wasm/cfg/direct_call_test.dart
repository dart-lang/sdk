// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--cfg

import 'package:expect/expect.dart';

final List<int> log = [];

// Not compiled via CFG (uses unsupported instructions), so calls to it test
// calling AST-compiled code from CFG-compiled code.
@pragma('wasm:never-inline')
void record(int x) {
  log.add(x);
}

// Not compiled via CFG (`throw` is unsupported).
@pragma('wasm:never-inline')
Never fail(int x) => throw ArgumentError.value(x);

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int add(int a, int b) => a + b;

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int callAdd(int x, int y) => add(x, y) + 1;

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int fib(int n) => n < 2 ? n : fib(n - 1) + fib(n - 2);

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int callVoid(int x) {
  record(x);
  record(x + 1);
  return x;
}

// The `int` result of `add` is unused and has to be dropped.
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int callAddUnused(int x, int y) {
  add(x, y);
  return x;
}

// Declared to return `num`, but TFA infers `int`, so the wasm function returns
// an unboxed `i64`.
@pragma('wasm:never-inline')
num numOf(int x) => x;

// The result local has the static type `num` (boxed), so the `i64` returned by
// `numOf` needs boxing.
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
num callNumOf(int x) => numOf(x);

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
String pick(bool c, String a, String b) => c ? a : b;

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
String callPick(int x, String a, String b) => pick(x > 0, a, b);

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int callNever(int x) {
  if (x < 0) fail(x);
  return x;
}

// The phi for `x > 0 ? a : b` gets a nullable local, but `pick` takes a
// non-nullable `String`, so the argument needs a null check.
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
String callPickPhi(int x, String a, String b) => pick(true, x > 0 ? a : b, a);

// Not compiled via CFG (string interpolation is unsupported). Also called with
// a `String` from `main` so TFA can't narrow/unbox the parameter to `int`.
@pragma('wasm:never-inline')
String describe(Object o) => 'value: $o';

// Passing an unboxed `int` to an `Object` parameter needs boxing.
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
String callDescribe(int x) => describe(x);

void main() {
  final int0 = int.parse('0');
  final int1 = int.parse('1');
  final int3 = int.parse('3');
  final int4 = int.parse('4');
  final int5 = int.parse('5');
  final int10 = int.parse('10');
  final negOne = int.parse('-1');

  // CFG -> CFG call.
  Expect.equals(8, callAdd(int3, int4));

  // Recursive CFG -> CFG calls.
  Expect.equals(0, fib(int0));
  Expect.equals(1, fib(int1));
  Expect.equals(55, fib(int10));

  // CFG -> AST call of a void function, result unused.
  Expect.equals(5, callVoid(int5));
  Expect.listEquals([5, 6], log);

  // Unused non-void result.
  Expect.equals(3, callAddUnused(int3, int4));

  // Return value conversion (boxing).
  Expect.equals(5, callNumOf(int5));

  // Reference-typed arguments and results, bool argument.
  Expect.equals('a', callPick(int1, 'a', 'b'));
  Expect.equals('b', callPick(int0, 'a', 'b'));

  // Call of a function that never returns.
  Expect.equals(int1, callNever(int1));
  Expect.throwsArgumentError(() => callNever(negOne));

  // Argument conversions: null check of a nullable local and boxing.
  Expect.equals('a', callPickPhi(int1, 'a', 'b'));
  Expect.equals('b', callPickPhi(int0, 'a', 'b'));
  Expect.equals('value: 5', callDescribe(int5));
  Expect.equals('value: s', describe('s'));
}
