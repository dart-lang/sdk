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

  Iterable<int> takeWhileFalse = list1.takeWhile((x) => false);
  Iterator<int> it = takeWhileFalse.iterator;
  Expect.isNull(it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  Iterable<int> takeWhileOdd = list1.takeWhile((x) => x.isOdd);
  it = takeWhileOdd.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(1, it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  Iterable<int> takeWhileLessThan3 = list1.takeWhile((x) => x < 3);
  it = takeWhileLessThan3.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(1, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(2, it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  Iterable<int> takeEverything = list1.takeWhile((x) => true);
  it = takeEverything.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(1, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(2, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(3, it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  Iterable<int> takeWhileEven = list1.takeWhile((x) => x.isEven);
  it = takeWhileFalse.iterator;
  Expect.isNull(it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  takeWhileFalse = list2.takeWhile((x) => false);
  it = takeWhileFalse.iterator;
  Expect.isNull(it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  takeWhileEven = list2.takeWhile((x) => x.isEven);
  it = takeWhileEven.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(4, it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  takeEverything = list2.takeWhile((x) => true);
  it = takeEverything.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(4, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(5, it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  Iterable<String> takeWhileFalse2 = list3.takeWhile((x) => false);
  Iterator<String> it2 = takeWhileFalse2.iterator;
  Expect.isNull(it2.current);
  Expect.isFalse(it2.moveNext());
  Expect.isNull(it2.current);

  Iterable<String> takeEverything2 = list3.takeWhile((x) => true);
  it2 = takeEverything2.iterator;
  Expect.isNull(it2.current);
  Expect.isFalse(it2.moveNext());
  Expect.isNull(it2.current);

  takeWhileFalse = set1.takeWhile((x) => false);
  it = takeWhileFalse.iterator;
  Expect.isNull(it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  takeEverything = set1.takeWhile((x) => true);
  List<int> copied = takeEverything.toList();
  Expect.equals(3, copied.length);
  Expect.isTrue(set1.contains(copied[0]));
  Expect.isTrue(set1.contains(copied[1]));
  Expect.isTrue(set1.contains(copied[1]));
  Expect.isTrue(copied[0] != copied[1]);
  Expect.isTrue(copied[0] != copied[2]);
  Expect.isTrue(copied[1] != copied[2]);
  it = takeEverything.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.isTrue(it.current != null);
  Expect.isTrue(it.moveNext());
  Expect.isTrue(it.current != null);
  Expect.isTrue(it.moveNext());
  Expect.isTrue(it.current != null);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  takeWhileFalse = set2.takeWhile((x) => false);
  it = takeWhileFalse.iterator;
  Expect.isNull(it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  takeEverything = set2.takeWhile((x) => true);
  it = takeEverything.iterator;
  Expect.isNull(it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);
}
