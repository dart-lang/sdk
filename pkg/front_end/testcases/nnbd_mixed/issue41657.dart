// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final isLegacySubtyping1a = const <Null>[] is List<int>;
const isLegacySubtyping1b = const <Null>[] is List<int>;
final isLegacySubtyping2a = const <int?>[] is List<int>;
const isLegacySubtyping2b = const <int?>[] is List<int>;
final assertLegacySubtyping1a = const <Null>[] as List<int>;
const assertLegacySubtyping1b = const <Null>[] as List<int>;
final assertLegacySubtyping2a = const <int?>[] as List<int>;
const assertLegacySubtyping2b = const <int?>[] as List<int>;

void main() {
  expect(isLegacySubtyping1a, isLegacySubtyping1b);
  expect(isLegacySubtyping2a, isLegacySubtyping2b);
  expect(assertLegacySubtyping1a, assertLegacySubtyping1b);
  expect(assertLegacySubtyping2a, assertLegacySubtyping2b);
}

expect(expected, actual) {
  if (expected != actual) throw "Expected $expected, actual $actual";
}
