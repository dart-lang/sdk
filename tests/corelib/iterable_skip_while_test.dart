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
  Expect.isFalse(it.moveNext());

  Iterable<int> skipWhileOdd = list1.skipWhile((x) => x.isOdd);
  it = skipWhileOdd.iterator;
  Expect.isTrue(it.moveNext());
  Expect.equals(2, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(3, it.current);
  Expect.isFalse(it.moveNext());

  Iterable<int> skipWhileLessThan3 = list1.skipWhile((x) => x < 3);
  it = skipWhileLessThan3.iterator;
  Expect.isTrue(it.moveNext());
  Expect.equals(3, it.current);
  Expect.isFalse(it.moveNext());

  Iterable<int> skipWhileFalse = list1.skipWhile((x) => false);
  it = skipWhileFalse.iterator;
  Expect.isTrue(it.moveNext());
  Expect.equals(1, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(2, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(3, it.current);
  Expect.isFalse(it.moveNext());

  Iterable<int> skipWhileEven = list1.skipWhile((x) => x.isEven);
  it = skipWhileEven.iterator;
  Expect.isTrue(it.moveNext());
  Expect.equals(1, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(2, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(3, it.current);
  Expect.isFalse(it.moveNext());

  skipWhileTrue = list2.skipWhile((x) => true);
  it = skipWhileTrue.iterator;
  Expect.isFalse(it.moveNext());

  skipWhileEven = list2.skipWhile((x) => x.isEven);
  it = skipWhileEven.iterator;
  Expect.isTrue(it.moveNext());
  Expect.equals(5, it.current);
  Expect.isFalse(it.moveNext());

  skipWhileOdd = list2.skipWhile((x) => x.isOdd);
  it = skipWhileOdd.iterator;
  Expect.isTrue(it.moveNext());
  Expect.equals(4, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(5, it.current);
  Expect.isFalse(it.moveNext());

  skipWhileFalse = list2.skipWhile((x) => false);
  it = skipWhileFalse.iterator;
  Expect.isTrue(it.moveNext());
  Expect.equals(4, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(5, it.current);
  Expect.isFalse(it.moveNext());

  Iterable<String> skipWhileFalse2 = list3.skipWhile((x) => false);
  Iterator<String> it2 = skipWhileFalse2.iterator;
  Expect.isFalse(it2.moveNext());

  Iterable<String> skipWhileTrue2 = list3.skipWhile((x) => true);
  it2 = skipWhileTrue2.iterator;
  Expect.isFalse(it2.moveNext());

  skipWhileTrue = set1.skipWhile((x) => true);
  it = skipWhileTrue.iterator;
  Expect.isFalse(it.moveNext());

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
  Expect.isTrue(it.moveNext());
  Expect.isTrue(it.moveNext());
  Expect.isTrue(it.moveNext());
  Expect.isFalse(it.moveNext());

  var dynamicSkipWhileTrue = set2.skipWhile((x) => true);
  var dynamicIt = dynamicSkipWhileTrue.iterator;
  Expect.isFalse(dynamicIt.moveNext());

  var dynamicSkipWhileFalse = set2.skipWhile((x) => false);
  dynamicIt = dynamicSkipWhileFalse.iterator;
  Expect.isFalse(dynamicIt.moveNext());
}
