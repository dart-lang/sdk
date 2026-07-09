// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:expect/expect.dart';

// Check that NaN is detected as an invalid index for system Lists, Strings and
// typed lists.
//
// There are several methods called `dynamicCallN` for various N that are called
// with different indexable collection implementations to exercise various
// dart2js optimizations based on knowing (or not knowing) the concrete type of
// the List argument.

void main() {
  int nan = makeIntNaN();
  Expect.isFalse(nan <= 0);
  Expect.isFalse(nan >= 0);

  List<int> ints = [1, 2, 3, 4];
  final bytes = Uint8List(3)
    ..[0] = 100
    ..[1] = 101
    ..[2] = 102;
  final words = Int16List(3)
    ..[0] = 16000
    ..[1] = 16001
    ..[2] = 16002;

  Expect.throws(() => ints[nan], anyError, 'List[nan]');
  Expect.throws(() => 'abc'[nan], anyError, 'String[nan]');
  Expect.throws(() => bytes[nan], anyError, 'UInt8List[nan]');
  Expect.throws(() => words[nan], anyError, 'Int16List[nan]');

  // [dynamicCall1] Seeded with JSIndexable and Map, so is doing a complete
  // interceptor dispatch.
  Expect.equals(2, dynamicCall1(ints, 1));
  Expect.equals('b', dynamicCall1('abc', 1));
  Expect.equals(2, dynamicCall1({'a': 1, 'b': 2, 'c': 3}, 'b'));

  Expect.throws(() => dynamicCall1(ints, nan), anyError, 'dynamic List');
  Expect.throws(() => dynamicCall1('AB', nan), anyError, 'dynamic String');
  Expect.throws(() => dynamicCall1(bytes, nan), anyError, 'dynamic Uint8List');
  Expect.throws(() => dynamicCall1(words, nan), anyError, 'dynamic Int16list');

  var a = <int>[];
  Expect.throws(() => a.removeLast(), contains('-1'));

  // [dynamicCall2] seeded with JSIndexable only, so can be optimized to a
  // JavaScript indexing operation.
  Expect.equals(2, dynamicCall2(ints, 1));
  Expect.equals('b', dynamicCall2('abc', 1));

  Expect.throws(() => dynamicCall2(ints, nan), anyError, 'JSIndexable List');
  Expect.throws(() => dynamicCall2('AB', nan), anyError, 'JSIndexable String');

  // [dynamicCall3] Seeded with List of known length only, various indexes. The
  // upper bound is fixed.
  Expect.throws(() => dynamicCall3(ints, nan), anyError, 'known length nan');
  Expect.throws(() => dynamicCall3(ints, null), anyError, 'known length null');

  // [dynamicCall4] Seeded with List of known length only.
  Expect.throws(() => dynamicCall4(ints, nan), anyError, 'dynamic[] List');

  // [dynamicCall5] Seeded with List of unknown length only.
  Expect.throws(() => dynamicCall5(ints, nan), anyError, 'dynamic[] List');
  Expect.throws(() => dynamicCall5(a, nan), anyError, 'dynamic[] List');

  // [dynamicCall6] Seeded with Uint8List only.
  Expect.throws(() => dynamicCall6(bytes, nan), anyError, 'dynamic Uint8List');
}

bool anyError(error) => true;

bool Function(dynamic) contains(Pattern pattern) =>
    (error) => '$error'.contains(pattern);

@pragma('dart2js:noInline')
dynamic dynamicCall1(dynamic indexable, dynamic index) {
  return indexable[index];
}

@pragma('dart2js:noInline')
dynamic dynamicCall2(dynamic indexable, dynamic index) {
  return indexable[index];
}

@pragma('dart2js:noInline')
dynamic dynamicCall3(dynamic indexable, dynamic index) {
  return indexable[index];
}

@pragma('dart2js:noInline')
dynamic dynamicCall4(dynamic indexable, dynamic index) {
  return indexable[index];
}

@pragma('dart2js:noInline')
dynamic dynamicCall5(dynamic indexable, dynamic index) {
  return indexable[index];
}

@pragma('dart2js:noInline')
dynamic dynamicCall6(dynamic indexable, dynamic index) {
  return indexable[index];
}

int makeIntNaN() {
  int n = 2;
  // Overflow to Infinity.
  for (int i = 0; i < 10; i++, n *= n) {}
  // Infinity - Infinity = NaN.
  return n - n;
}
