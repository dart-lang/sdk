// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

testGetRange(list, start, end, bool isModifiable) {
  Expect.throwsRangeError(() => list.getRange(-1, 0));
  Expect.throwsRangeError(() => list.getRange(0, -1));
  Expect.throwsRangeError(() => list.getRange(1, 0));
  Expect.throwsRangeError(() => list.getRange(0, list.length + 1));
  Expect.throwsRangeError(
      () => list.getRange(list.length + 1, list.length + 1));
  Iterable iterable = list.getRange(start, end);
  Expect.isFalse(iterable is List);
  if (start == end) {
    Expect.isTrue(iterable.isEmpty);
    return;
  }

  var iterator = iterable.iterator;
  for (int i = start; i < end; i++) {
    Expect.isTrue(iterator.moveNext());
    Expect.equals(iterator.current, list[i]);
  }
  Expect.isFalse(iterator.moveNext());

  if (isModifiable) {
    for (int i = 0; i < list.length; i++) {
      list[i]++;
    }

    iterator = iterable.iterator;
    for (int i = start; i < end; i++) {
      Expect.isTrue(iterator.moveNext());
      Expect.equals(iterator.current, list[i]);
    }
  }
}

main() {
  testGetRange([1, 2], 0, 1, true);
  testGetRange([], 0, 0, true);
  testGetRange([1, 2, 3], 0, 0, true);
  testGetRange([1, 2, 3], 1, 3, true);
  testGetRange(const [1, 2], 0, 1, false);
  testGetRange(const [], 0, 0, false);
  testGetRange(const [1, 2, 3], 0, 0, false);
  testGetRange(const [1, 2, 3], 1, 3, false);
  testGetRange("abcd".codeUnits, 0, 1, false);
  testGetRange("abcd".codeUnits, 0, 0, false);
  testGetRange("abcd".codeUnits, 1, 3, false);

  Expect.throwsRangeError(() => [1].getRange(-1, 1));
  Expect.throwsRangeError(() => [3].getRange(0, -1));
  Expect.throwsRangeError(() => [4].getRange(1, 0));

  var list = [1, 2, 3, 4];
  var iterable = list.getRange(1, 3);
  Expect.equals(2, iterable.first);
  Expect.equals(3, iterable.last);
  list.length = 1;
  Expect.isTrue(iterable.isEmpty);
  list.add(99);
  Expect.equals(99, iterable.single);
  list.add(499);
  Expect.equals(499, iterable.last);
  Expect.equals(2, iterable.length);
}
