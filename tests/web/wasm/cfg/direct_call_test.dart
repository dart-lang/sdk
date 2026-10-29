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

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int get five => 5;

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int callGetter(int x) => five + x;

// Unused getter returned values need cleanup so they don't pollute the stack.
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int callGetterUnused(int x) {
  five;
  return x;
}

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
set recordedValue(int x) {
  record(x);
}

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int callCfgSetter(int x) {
  recordedValue = x;
  return recordedValue = x + 1;
}

// Declared to return `num`, but TFA infers `int`, so the wasm getter returns
// an unboxed `i64`.
@pragma('wasm:never-inline')
num get numFive => 5;

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
num callNumGetter() => numFive;

String lastDescribed = '';

// Not compiled via CFG (string interpolation and static field write).
@pragma('wasm:never-inline')
set describedObject(Object o) {
  lastDescribed = 'set: $o';
}

// Passing an unboxed `int` to an `Object` setter parameter needs boxing, while
// the assignment expression still evaluates to the unboxed `int`.
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int callObjectSetter(int x) => describedObject = x;

// The phi for `x > 0 ? a : b` gets a nullable local, but `describedObject`
// takes a non-nullable `Object`, so the setter argument needs a null check.
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
String callSetterPhi(int x, String a, String b) =>
    describedObject = (x > 0 ? a : b);

@pragma('wasm:never-inline')
Never get failGetter => throw ArgumentError('failGetter');

@pragma('wasm:never-inline')
set failSetter(int x) => throw ArgumentError.value(x);

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int callNeverGetter(int x) => x < 0 ? failGetter : x;

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int callNeverSetter(int x) {
  if (x < 0) failSetter = x;
  return x;
}

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int sum3(int a, [int b = 20, int c = 300]) => a + b + c;

// Omitted optional positional arguments are filled in with default values.
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int callSum3(int x) => sum3(x) + sum3(x, x) + sum3(x, x, x);

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
String optionalString(bool c, [String s = 'default']) => c ? s : 'other';

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
String callOptionalString(int x) => optionalString(x > 0);

@pragma('wasm:never-inline')
bool isNull([int? x]) =>
    // `==` on `int?` is not compiled via CFG.
    x == null;

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
bool callIsNull() => isNull();

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int named(int a, {int b = 20, required int c, int d = 4000}) => a + b + c + d;

// Named arguments are passed in a different order than they are declared and
// omitted optional named arguments are filled in with default values.
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int callNamed(int x) =>
    named(x, c: 300) +
    named(x, c: x, b: x) +
    named(x, d: x, c: x, b: x) +
    named(x, d: x, c: x);

@pragma('wasm:never-inline')
int logged(int x) {
  record(x);
  return x;
}

// Named arguments should be evaluated in the order they appear at the call
// site.
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int callNamedEvaluationOrder() =>
    named(logged(1), d: logged(2), c: logged(3), b: logged(4));

// Named parameters with different wasm types would fail validation if passed in
// the wrong order.
@pragma('wasm:never-inline')
@pragma('wasm:cfg')
String pickNamed({required bool c, String a = 'a', String b = 'b'}) =>
    c ? a : b;

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
String callPickNamedB(int x, String s) => pickNamed(b: s, c: x > 0);

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
String callPickNamedA(int x, String s) => pickNamed(c: x > 0, a: s);

@pragma('wasm:never-inline')
bool isNullNamed({int? x}) => x == null;

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
bool callIsNullNamed() => isNullNamed();

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

  // Static getters and setters.
  Expect.equals(8, callGetter(int3));
  Expect.equals(4, callGetterUnused(int4));
  log.clear();
  Expect.equals(6, callCfgSetter(int5));
  Expect.listEquals([5, 6], log);
  Expect.equals(5, callNumGetter());
  Expect.equals(5, callObjectSetter(int5));
  Expect.equals('set: 5', lastDescribed);
  Expect.equals('a', callSetterPhi(int1, 'a', 'b'));
  Expect.equals('set: a', lastDescribed);
  Expect.equals('b', callSetterPhi(int0, 'a', 'b'));
  Expect.equals('set: b', lastDescribed);
  describedObject = 's';
  Expect.equals('set: s', lastDescribed);
  Expect.equals(int1, callNeverGetter(int1));
  Expect.throwsArgumentError(() => callNeverGetter(negOne));
  Expect.equals(int1, callNeverSetter(int1));
  Expect.throwsArgumentError(() => callNeverSetter(negOne));

  // Optional positional parameters.
  Expect.equals((1 + 20 + 300) + (1 + 1 + 300) + (1 + 1 + 1), callSum3(int1));
  Expect.equals('default', callOptionalString(int1));
  Expect.equals('other', callOptionalString(int0));
  Expect.equals('s', optionalString(true, 's'));
  Expect.isTrue(callIsNull());
  Expect.isFalse(isNull(int1));

  // Named parameters.
  Expect.equals(
    (1 + 20 + 300 + 4000) +
        (1 + 1 + 1 + 4000) +
        (1 + 1 + 1 + 1) +
        (1 + 20 + 1 + 1),
    callNamed(int1),
  );
  log.clear();
  Expect.equals(1 + 4 + 3 + 2, callNamedEvaluationOrder());
  Expect.listEquals([1, 2, 3, 4], log);
  Expect.equals('a', callPickNamedB(int1, 's'));
  Expect.equals('s', callPickNamedB(int0, 's'));
  Expect.equals('s', callPickNamedA(int1, 's'));
  Expect.equals('b', callPickNamedA(int0, 's'));
  Expect.isTrue(callIsNullNamed());
  Expect.isFalse(isNullNamed(x: int1));
}
