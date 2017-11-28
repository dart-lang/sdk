// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  List<int> list1 = <int>[1, 2, 3];
  List<int> list2 = const <int>[4, 5];
  List<String> list3 = <String>[];
  Set<int> set1 = new Set<int>();
  set1..add(11)..add(12)..add(13);
  Set set2 = new Set();

  Iterable<int> skipWhileTrue = list1.skipWhile((x) => true);
  Iterator<int> it = skipWhileTrue.iterator;
  Expect.isNull(it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  Iterable<int> skipWhileOdd = list1.skipWhile((x) => x.isOdd);
  it = skipWhileOdd.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(2, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(3, it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  Iterable<int> skipWhileLessThan3 = list1.skipWhile((x) => x < 3);
  it = skipWhileLessThan3.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(3, it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  Iterable<int> skipWhileFalse = list1.skipWhile((x) => false);
  it = skipWhileFalse.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(1, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(2, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(3, it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  Iterable<int> skipWhileEven = list1.skipWhile((x) => x.isEven);
  it = skipWhileEven.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(1, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(2, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(3, it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  skipWhileTrue = list2.skipWhile((x) => true);
  it = skipWhileTrue.iterator;
  Expect.isNull(it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  skipWhileEven = list2.skipWhile((x) => x.isEven);
  it = skipWhileEven.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(5, it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  skipWhileOdd = list2.skipWhile((x) => x.isOdd);
  it = skipWhileOdd.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(4, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(5, it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  skipWhileFalse = list2.skipWhile((x) => false);
  it = skipWhileFalse.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(4, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(5, it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  Iterable<String> skipWhileFalse2 = list3.skipWhile((x) => false);
  Iterator<String> it2 = skipWhileFalse2.iterator;
  Expect.isNull(it2.current);
  Expect.isFalse(it2.moveNext());
  Expect.isNull(it2.current);

  Iterable<String> skipWhileTrue2 = list3.skipWhile((x) => true);
  it2 = skipWhileTrue2.iterator;
  Expect.isNull(it2.current);
  Expect.isFalse(it2.moveNext());
  Expect.isNull(it2.current);

  skipWhileTrue = set1.skipWhile((x) => true);
  it = skipWhileTrue.iterator;
  Expect.isNull(it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  skipWhileFalse = set1.skipWhile((x) => false);
  List<int> copied = skipWhileFalse.toList();
  Expect.equals(3, copied.length);
  Expect.isTrue(set1.contains(copied[0]));
  Expect.isTrue(set1.contains(copied[1]));
  Expect.isTrue(set1.contains(copied[1]));
  Expect.isTrue(copied[0] != copied[1]);
  Expect.isTrue(copied[0] != copied[2]);
  Expect.isTrue(copied[1] != copied[2]);
  it = skipWhileFalse.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.isTrue(it.current != null);
  Expect.isTrue(it.moveNext());
  Expect.isTrue(it.current != null);
  Expect.isTrue(it.moveNext());
  Expect.isTrue(it.current != null);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  skipWhileTrue = set2.skipWhile((x) => true);
  it = skipWhileTrue.iterator;
  Expect.isNull(it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  skipWhileFalse = set2.skipWhile((x) => false);
  it = skipWhileFalse.iterator;
  Expect.isNull(it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);
}
