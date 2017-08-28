// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:math' show min; // <-- generic: <T extends num>(T, T) -> T
import 'package:expect/expect.dart';

class C {
  T m<T extends num>(T x, T y) => min(x, y);
  int m2(int x, int y) => min(x, y);
}

typedef int Int2Int2Int(int x, int y);

void _test(Int2Int2Int f) {
  int y = f(123, 456);
  Expect.equals(y, 123);
  // `f` doesn't take type args.
  Expect.throws(() => (f as dynamic)<int>(123, 456));
}

void _testParam(T minFn<T extends num>(T x, T y)) {
  _test(minFn);
}

main() {
  // Strong mode infers: `min<int>`
  // Test simple/prefixed identifiers and property access
  _test(min);
  _test(math.min);
  _test(new C().m);

  // Test local function, variable, and parameter
  T m<T extends num>(T x, T y) => min(x, y);
  _test(m);
  final f = min;
  _test(f);
  _testParam(math.min);

  // A few misc tests for methods
  Expect.equals(123, (new C() as dynamic).m<int>(123, 456));
  Expect.throws(() => (new C() as dynamic).m2<int>(123, 456));
}
