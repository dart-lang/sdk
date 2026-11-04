// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Adapted from tests/web/wasm/cfg/direct_call_test.dart.

// Equivalent of Expect.equals until package:expect is supported.
void expectEquals(int expected, int actual) =>
    print(expected == actual ? 'pass' : 'fail');

int sum3(int a, [int b = 20, int c = 300]) => a + b + c;

// Omitted optional positional arguments are filled in with default values.
int callSum3(int x) => sum3(x) + sum3(x, x) + sum3(x, x, x);

String optionalString(bool c, [String s = 'default']) => c ? s : 'other';

String callOptionalString(int x) => optionalString(x > 0);

int named(int a, {int b = 20, required int c, int d = 4000}) => a + b + c + d;

// Named arguments are passed in a different order than they are declared and
// omitted optional named arguments are filled in with default values.
int callNamed(int x) =>
    named(x, c: 300) +
    named(x, c: x, b: x) +
    named(x, d: x, c: x, b: x) +
    named(x, d: x, c: x);

// Named parameters with different types would fail to unbox if passed in the
// wrong order.
String pickNamed({required bool c, String a = 'a', String b = 'b'}) =>
    c ? a : b;

String callPickNamedB(int x, String s) => pickNamed(b: s, c: x > 0);

String callPickNamedA(int x, String s) => pickNamed(c: x > 0, a: s);

class C {
  int sum3(int a, [int b = 20, int c = 300]) => a + b + c;

  int named(int a, {int b = 20, required int c, int d = 4000}) => a + b + c + d;
}

void main() {
  // Optional positional parameters.
  expectEquals((1 + 20 + 300) + (1 + 1 + 300) + (1 + 1 + 1), callSum3(1));
  print(callOptionalString(1)); // default
  print(callOptionalString(0)); // other
  print(optionalString(true, 's')); // s

  // Named parameters.
  expectEquals(
    (1 + 20 + 300 + 4000) +
        (1 + 1 + 1 + 4000) +
        (1 + 1 + 1 + 1) +
        (1 + 20 + 1 + 1),
    callNamed(1),
  );
  print(callPickNamedB(1, 's')); // a
  print(callPickNamedB(0, 's')); // s
  print(callPickNamedA(1, 's')); // s
  print(callPickNamedA(0, 's')); // b

  // Instance methods.
  expectEquals(1 + 1 + 300, C().sum3(1, 1));
  expectEquals(1 + 1 + 1 + 4000, C().named(1, c: 1, b: 1));
}
