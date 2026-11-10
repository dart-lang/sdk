// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests `==` and `hashCode` of records with 19, 20 and 21 fields.
///
/// dart2wasm generates a `hashCode` for each record shape. It calls
/// `Object.hash` with the shape id and the fields. `Object.hash` has 20
/// positional parameters. A record with 20 fields made a call with 21
/// arguments, and dart2wasm crashed.

import 'package:expect/expect.dart';

@pragma('vm:never-inline')
@pragma('dart2js:never-inline')
@pragma('wasm:never-inline')
Object positional19(int b) => (
  b,
  b + 1,
  b + 2,
  b + 3,
  b + 4,
  b + 5,
  b + 6,
  b + 7,
  b + 8,
  b + 9,
  b + 10,
  b + 11,
  b + 12,
  b + 13,
  b + 14,
  b + 15,
  b + 16,
  b + 17,
  b + 18,
);

@pragma('vm:never-inline')
@pragma('dart2js:never-inline')
@pragma('wasm:never-inline')
Object positional20(int b) => (
  b,
  b + 1,
  b + 2,
  b + 3,
  b + 4,
  b + 5,
  b + 6,
  b + 7,
  b + 8,
  b + 9,
  b + 10,
  b + 11,
  b + 12,
  b + 13,
  b + 14,
  b + 15,
  b + 16,
  b + 17,
  b + 18,
  b + 19,
);

@pragma('vm:never-inline')
@pragma('dart2js:never-inline')
@pragma('wasm:never-inline')
Object positional21(int b) => (
  b,
  b + 1,
  b + 2,
  b + 3,
  b + 4,
  b + 5,
  b + 6,
  b + 7,
  b + 8,
  b + 9,
  b + 10,
  b + 11,
  b + 12,
  b + 13,
  b + 14,
  b + 15,
  b + 16,
  b + 17,
  b + 18,
  b + 19,
  b + 20,
);

@pragma('vm:never-inline')
@pragma('dart2js:never-inline')
@pragma('wasm:never-inline')
Object named19(int b) => (
  f1: b,
  f2: b + 1,
  f3: b + 2,
  f4: b + 3,
  f5: b + 4,
  f6: b + 5,
  f7: b + 6,
  f8: b + 7,
  f9: b + 8,
  f10: b + 9,
  f11: b + 10,
  f12: b + 11,
  f13: b + 12,
  f14: b + 13,
  f15: b + 14,
  f16: b + 15,
  f17: b + 16,
  f18: b + 17,
  f19: b + 18,
);

@pragma('vm:never-inline')
@pragma('dart2js:never-inline')
@pragma('wasm:never-inline')
Object named20(int b) => (
  f1: b,
  f2: b + 1,
  f3: b + 2,
  f4: b + 3,
  f5: b + 4,
  f6: b + 5,
  f7: b + 6,
  f8: b + 7,
  f9: b + 8,
  f10: b + 9,
  f11: b + 10,
  f12: b + 11,
  f13: b + 12,
  f14: b + 13,
  f15: b + 14,
  f16: b + 15,
  f17: b + 16,
  f18: b + 17,
  f19: b + 18,
  f20: b + 19,
);

@pragma('vm:never-inline')
@pragma('dart2js:never-inline')
@pragma('wasm:never-inline')
Object named21(int b) => (
  f1: b,
  f2: b + 1,
  f3: b + 2,
  f4: b + 3,
  f5: b + 4,
  f6: b + 5,
  f7: b + 6,
  f8: b + 7,
  f9: b + 8,
  f10: b + 9,
  f11: b + 10,
  f12: b + 11,
  f13: b + 12,
  f14: b + 13,
  f15: b + 14,
  f16: b + 15,
  f17: b + 16,
  f18: b + 17,
  f19: b + 18,
  f20: b + 19,
  f21: b + 20,
);

void check(Object Function(int) make) {
  final r1 = make(1);
  final r2 = make(1);
  final r3 = make(2);

  Expect.equals(r1, r2);
  Expect.equals(r1.hashCode, r2.hashCode);
  Expect.equals(r1.hashCode, r1.hashCode);
  Expect.notEquals(r1, r3);

  final map = <Object, String>{r1: 'first'};
  map[r2] = 'second';
  Expect.equals(1, map.length);
  Expect.equals('second', map[r1]);
  Expect.isNull(map[r3]);
  map[r3] = 'third';
  Expect.equals(2, map.length);
  Expect.equals('third', map[r3]);

  Expect.equals(2, {r1, r2, r3}.length);
}

void main() {
  check(positional19);
  check(positional20);
  check(positional21);
  check(named19);
  check(named20);
  check(named21);
}
