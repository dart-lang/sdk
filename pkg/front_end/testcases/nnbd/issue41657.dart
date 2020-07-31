// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final isLegacySubtyping1a = <Null>[] is List<int>;
const isLegacySubtyping1b = <Null>[] is List<int>;
final isLegacySubtyping2a = <int?>[] is List<int>;
const isLegacySubtyping2b = <int?>[] is List<int>;
//final assertLegacySubtyping2 = <Null>[] as List<int>;
const assertLegacySubtyping1 = <Null>[] as List<int>;
//final assertLegacySubtyping2 = <int?>[] as List<int>;
const assertLegacySubtyping2 = <int?>[] as List<int>;

void main() {
  expect(isLegacySubtyping1a, isLegacySubtyping1b);
  expect(isLegacySubtyping2a, isLegacySubtyping2b);
}

expect(expected, actual) {
  if (expected != actual) throw "Expected $expected, actual $actual";
}
