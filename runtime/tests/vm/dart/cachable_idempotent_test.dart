// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:expect/expect.dart';

void main() {
  testMultipleIncrement();
  reset();
  testMultipleCallSites();
  reset();
  testManyArguments();
  reset();
  testNonIntArguments();
  reset();
  testLargeInt();
  reset();
  testIntArguments();
  reset();
  testDoubleArguments();
  print('done');
}

@pragma('vm:force-optimize')
void testMultipleIncrement() {
  int result = 0;
  final counter = makeCounter(100000);
  while (counter()) {
    // We this calls with a cacheable call,
    // which will lead to the counter no longer being incremented.
    // Make sure to return the value, so we can see that the boxing and
    // unboxing works as expected.
    result = cachedIncrement(/*must be const*/ 3);
  }
  // Since this call site is force optimized, we should never recompile and thus
  // we only ever increment the global counter once.
  Expect.equals(3, result);
}

/// A global counter, except for the call sites are being cached.
///
/// Arguments passed to this function must be const.
/// Call sites should be rewritten to cache using the pool.
@pragma('vm:never-inline')
@pragma('vm:cachable-idempotent')
int cachedIncrement(int amount) {
  return _globalCounter += amount;
}

int _globalCounter = 0;

void reset() {
  print('reset');
  _globalCounter = 0;
}

/// Helper for vm:force-optimize for loops without instance calls.
///
/// A for loop uses the `operator+` on int.
bool Function() makeCounter(int count) {
  return () => count-- >= 0;
}

@pragma('vm:force-optimize')
void testMultipleCallSites() {
  int result = 0;
  final counter = makeCounter(10);
  result = cachedIncrement(1);
  while (counter()) {
    result = cachedIncrement(10);
    result = cachedIncrement(10);
  }
  result = cachedIncrement(100);
  // All call sites are cached individually.
  // Even if the arguments are identical.
  Expect.equals(result, 121);
}

@pragma('vm:force-optimize')
void testManyArguments() {
  final result = manyArguments(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
  Expect.equals(55, result);
}

@pragma('vm:never-inline')
@pragma('vm:cachable-idempotent')
int manyArguments(int i1, int i2, int i3, int i4, int i5, int i6, int i7,
    int i8, int i9, int i10) {
  return i1 + i2 + i3 + i4 + i5 + i6 + i7 + i8 + i9 + i10;
}

@pragma('vm:force-optimize')
void testNonIntArguments() {
  final result = lotsOfConstArguments(
    "foo",
    3.0,
    3,
    const _MyClass(_MyClass(42)),
  );

  Expect.equals(37, result);
}

@pragma('vm:never-inline')
@pragma('vm:cachable-idempotent')
int lotsOfConstArguments(String s, double d, int i, _MyClass m) {
  return [s, d, i, m].toString().length;
}

final class _MyClass {
  final Object i;
  const _MyClass(this.i);

  @override
  String toString() => '_MyClass($i)';
}

@pragma('vm:force-optimize')
void testLargeInt() {
  final counter = makeCounter(10);
  while (counter()) {
    if (is64bitsArch()) {
      final result1 = cachedIncrement(0x7FFFFFFFFFFFFFFF);
      Expect.equals(0x7FFFFFFFFFFFFFFF, result1);
      _globalCounter = 0;
      final result2 = cachedIncrement(0x8000000000000000);
      Expect.equals(0x8000000000000000, result2);
      _globalCounter = 0;
      final result3 = cachedIncrement(0xFFFFFFFFFFFFFFFF);
      Expect.equals(0xFFFFFFFFFFFFFFFF, result3);
    } else {
      final result1 = cachedIncrement(0x7FFFFFFF);
      Expect.equals(0x7FFFFFFF, result1);
      _globalCounter = 0;
      final result2 = cachedIncrement(0x80000000);
      Expect.equals(0x80000000, result2);
      _globalCounter = 0;
      final result3 = cachedIncrement(0xFFFFFFFF);
      Expect.equals(0xFFFFFFFF, result3);
    }
  }
}

bool is64bitsArch() => sizeOf<Pointer>() == 8;

@pragma('vm:force-optimize')
void testIntArguments() {
  final result = lotsOfIntArguments(
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
  );
  Expect.equals(36, result);

  // Do a second call with different values to prevent the argument values
  // propagating to the function body in TFA.
  final result2 = lotsOfIntArguments(
    101,
    102,
    103,
    104,
    105,
    106,
    107,
    108,
  );
  Expect.equals(836, result2);
}

@pragma('vm:never-inline')
@pragma('vm:cachable-idempotent')
int lotsOfIntArguments(
  int d1,
  int d2,
  int d3,
  int d4,
  int d5,
  int d6,
  int d7,
  int d8,
) {
  print([d1, d2, d3, d4, d5, d6, d7, d8]);
  return (d1 + d2 + d3 + d4 + d5 + d6 + d7 + d8).floor();
}

@pragma('vm:force-optimize')
void testDoubleArguments() {
  final result = lotsOfDoubleArguments(
    1.0,
    2.0,
    3.0,
    4.0,
    5.0,
    6.0,
    7.0,
    8.0,
  );
  Expect.equals(36, result);

  // Do a second call with different values to prevent the argument values
  // propagating to the function body in TFA.
  final result2 = lotsOfDoubleArguments(
    101.0,
    102.0,
    103.0,
    104.0,
    105.0,
    106.0,
    107.0,
    108.0,
  );
  Expect.equals(836, result2);
}

@pragma('vm:never-inline')
@pragma('vm:cachable-idempotent')
int lotsOfDoubleArguments(
  double d1,
  double d2,
  double d3,
  double d4,
  double d5,
  double d6,
  double d7,
  double d8,
) {
  print([d1, d2, d3, d4, d5, d6, d7, d8]);
  return (d1 + d2 + d3 + d4 + d5 + d6 + d7 + d8).floor();
}
