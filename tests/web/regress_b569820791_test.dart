// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

import 'package:expect/expect.dart';

void main() {
  testJSArrayRemoveLastOnEmpty();
  testJSArrayInsertAllLazyIterableEvaluatedOnce();
  testJSArraySetAllIndexRangeCheckOnEmptyIterable();
}

void testJSArrayRemoveLastOnEmpty() {
  final emptyNonNullable = <JSNumber>[].toJS.toDart;
  Expect.throws<Error>(() => emptyNonNullable.removeLast());

  final emptyNullable = <JSNumber?>[].toJS.toDart;
  Expect.throws<Error>(() => emptyNullable.removeLast());
}

void testJSArrayInsertAllLazyIterableEvaluatedOnce() {
  final list = makeJSList([1, 2, 3]);
  int evaluationCount = 0;
  final lazy = [10, 20].map((x) {
    evaluationCount++;
    return x.toJS;
  });
  list.insertAll(1, lazy);
  Expect.equals(2, evaluationCount);
  Expect.listEquals([1, 10, 20, 2, 3], toIntList(list));
}

void testJSArraySetAllIndexRangeCheckOnEmptyIterable() {
  Expect.throwsRangeError(
    () => makeJSList([1, 2, 3]).setAll(-1, <JSNumber>[].map((x) => x)),
  );
  Expect.throwsRangeError(
    () => makeJSList([1, 2, 3]).setAll(4, <JSNumber>[].map((x) => x)),
  );
}

List<JSNumber> makeJSList(List<int> values) =>
    <JSNumber>[for (final v in values) v.toJS].toJS.toDart;

List<int> toIntList(List<JSNumber> jsList) => [
  for (final v in jsList) v.toDartInt,
];
