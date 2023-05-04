// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that `<record> is T` and `<record> as T` succeed with union types, and
// ensure the _isFutureOr specializer didn't regress anything.

import 'dart:async';
import 'package:expect/expect.dart';

@pragma('dart2js:never-inline')
void testIs<T>(dynamic x) {
  Expect.isTrue(x is T);
  Expect.isFalse(x is! T);
  Expect.identical(x, x as T);
}

@pragma('dart2js:never-inline')
void testIsNot<T>(dynamic x) {
  Expect.isTrue(x is! T);
  Expect.isFalse(x is T);
  Expect.throwsTypeError(() => x as T);
}

class Foo<T> implements Future<T> {
  void noSuchMethod(_) {}
}

typedef TestRecord = (int, bool);

void main() {
  final record = (1, true);
  final recordList = <TestRecord>[record];

  testIs<TestRecord>(record);
  testIs<TestRecord?>(record);
  testIs<FutureOr<TestRecord>>(record);
  testIs<FutureOr<TestRecord?>>(record);
  testIs<FutureOr<TestRecord>?>(record);

  testIsNot<Future<TestRecord>>(record);
  testIsNot<FutureOr<int>>(record);

  testIs<List<TestRecord>>(recordList);
  testIs<List<TestRecord?>>(recordList);
  testIs<List<FutureOr<TestRecord>>>(recordList);
  testIs<List<FutureOr<TestRecord?>>>(recordList);
  testIs<List<FutureOr<TestRecord>?>>(recordList);

  testIsNot<List<Future<TestRecord>>>(recordList);
  testIsNot<List<FutureOr<int>>>(recordList);
}
