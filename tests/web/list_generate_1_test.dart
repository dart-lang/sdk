// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

dynamic function = 'function';
dynamic growable = 'growable';
dynamic length = 'length';

// Use top level dynamic variables so this call is not lowered.  This function
// and the callers (test1, test2) are not inlined to prevent store-forwarding of
// the top-level variables.
@pragma('dart2js:noInline')
List<T> general<T>() => List<T>.generate(length, function, growable: growable);

void main() {
  function = (int i) => i;
  growable = true;
  length = 5;

  test1();

  int k = 0;
  function = (int u) => seq3(u += 10, k += 100, () => u += k + 100000);
  growable = false;
  length = 5;

  test2();
}

@pragma('dart2js:noInline')
void test1() {
  // Simple test.
  final r1 = List<num>.generate(5, (i) => i, growable: true);
  final r2 = general<num>();

  Expect.equals('[0, 1, 2, 3, 4]', '$r1');
  Expect.equals('[0, 1, 2, 3, 4]', '$r2');
}

// A sequence of two operations in expression form, returning the last value.
T seq2<T>(dynamic a, T b) => b;
T seq3<T>(dynamic a, dynamic b, T c) => c;

@pragma('dart2js:noInline')
void test2() {
  // Test with a complex environment.
  int c = 0;
  final r1 = List<int Function()>.generate(
    5,
    (i) => seq3(i += 10, c += 100, () => i += c + 100000),
    growable: false,
  );
  final r2 = general<int Function()>();

  final e12 = r1[2];
  final e22 = r2[2];

  final s123 = [e12(), e12(), e12()];
  final s223 = [e22(), e22(), e22()];

  // 'i' is bound to the loop variable (2 for element at [2]).
  // 'i' is incremented by 10, so the low digits are '12'
  // 'c' is shared by all closures, and has been incremented to 500 at end of
  // construction, so each call increments 'i' by 100500.
  Expect.equals('[100512, 201012, 301512]', '$s123');
  Expect.equals('[100512, 201012, 301512]', '$s123');
}
