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

  Iterable<int> take0 = list1.take(0);
  Iterator<int> it = take0.iterator;
  Expect.isFalse(it.moveNext());

  Iterable<int> take1 = list1.take(1);
  it = take1.iterator;
  Expect.isTrue(it.moveNext());
  Expect.equals(1, it.current);
  Expect.isFalse(it.moveNext());

  Iterable<int> take2 = list1.take(2);
  it = take2.iterator;
  Expect.isTrue(it.moveNext());
  Expect.equals(1, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(2, it.current);
  Expect.isFalse(it.moveNext());

  Iterable<int> take3 = list1.take(3);
  it = take3.iterator;
  Expect.isTrue(it.moveNext());
  Expect.equals(1, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(2, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(3, it.current);
  Expect.isFalse(it.moveNext());

  Iterable<int> take4 = list1.take(4);
  it = take4.iterator;
  Expect.isTrue(it.moveNext());
  Expect.equals(1, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(2, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(3, it.current);
  Expect.isFalse(it.moveNext());

  take4 = list1.take(4);
  take3 = take4.take(3);
  take2 = take3.take(2);
  take1 = take2.take(1);
  take0 = take1.take(0);
  it = take0.iterator;
  Expect.isFalse(it.moveNext());
  it = take1.iterator;
  Expect.isTrue(it.moveNext());
  Expect.equals(1, it.current);
  Expect.isFalse(it.moveNext());
  it = take2.iterator;
  Expect.isTrue(it.moveNext());
  Expect.equals(1, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(2, it.current);
  Expect.isFalse(it.moveNext());
  it = take3.iterator;
  Expect.isTrue(it.moveNext());
  Expect.equals(1, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(2, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(3, it.current);
  Expect.isFalse(it.moveNext());
  it = take4.iterator;
  Expect.isTrue(it.moveNext());
  Expect.equals(1, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(2, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(3, it.current);
  Expect.isFalse(it.moveNext());

  take0 = list2.take(0);
  it = take0.iterator;
  Expect.isFalse(it.moveNext());

  take1 = list2.take(1);
  it = take1.iterator;
  Expect.isTrue(it.moveNext());
  Expect.equals(4, it.current);
  Expect.isFalse(it.moveNext());

  take2 = list2.take(2);
  it = take2.iterator;
  Expect.isTrue(it.moveNext());
  Expect.equals(4, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(5, it.current);
  Expect.isFalse(it.moveNext());

  take3 = list2.take(3);
  it = take3.iterator;
  Expect.isTrue(it.moveNext());
  Expect.equals(4, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(5, it.current);
  Expect.isFalse(it.moveNext());

  Iterable<String> take02 = list3.take(0);
  Iterator<String> it2 = take02.iterator;
  Expect.isFalse(it2.moveNext());

  Iterable<String> take12 = list3.take(1);
  it2 = take12.iterator;
  Expect.isFalse(it2.moveNext());

  take0 = set1.take(0);
  it = take0.iterator;
  Expect.isFalse(it.moveNext());

  take1 = set1.take(1);
  List<int> copied = take1.toList();
  Expect.equals(1, copied.length);
  Expect.isTrue(set1.contains(copied[0]));
  it = take1.iterator;
  Expect.isTrue(it.moveNext());
  Expect.isNotNull(it.current);
  Expect.isFalse(it.moveNext());

  take2 = set1.take(2);
  copied = take2.toList();
  Expect.equals(2, copied.length);
  Expect.isTrue(set1.contains(copied[0]));
  Expect.isTrue(set1.contains(copied[1]));
  Expect.isTrue(copied[0] != copied[1]);
  it = take2.iterator;
  Expect.isTrue(it.moveNext());
  Expect.isNotNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.isNotNull(it.current);
  Expect.isFalse(it.moveNext());

  take3 = set1.take(3);
  copied = take3.toList();
  Expect.equals(3, copied.length);
  Expect.isTrue(set1.contains(copied[0]));
  Expect.isTrue(set1.contains(copied[1]));
  Expect.isTrue(set1.contains(copied[2]));
  Expect.isTrue(copied[0] != copied[1]);
  Expect.isTrue(copied[0] != copied[2]);
  Expect.isTrue(copied[1] != copied[2]);
  it = take3.iterator;
  Expect.isTrue(it.moveNext());
  Expect.isNotNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.isNotNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.isNotNull(it.current);
  Expect.isFalse(it.moveNext());

  var dynamicTake0 = set2.take(0);
  var dynamicIt = dynamicTake0.iterator;
  Expect.isFalse(dynamicIt.moveNext());

  var dynamicTake1 = set2.take(1);
  dynamicIt = dynamicTake1.iterator;
  Expect.isFalse(dynamicIt.moveNext());

  Expect.throwsRangeError(() => list1.skip(-1));
  Expect.throwsRangeError(() => list2.skip(-1));
  Expect.throwsRangeError(() => list3.skip(-1));
  Expect.throwsRangeError(() => set1.skip(-1));
  Expect.throwsRangeError(() => set2.skip(-1));
  Expect.throwsRangeError(() => list1.map((x) => x).skip(-1));
  Expect.throwsRangeError(() => list2.map((x) => x).skip(-1));
  Expect.throwsRangeError(() => list3.map((x) => x).skip(-1));
  Expect.throwsRangeError(() => set1.map((x) => x).skip(-1));
  Expect.throwsRangeError(() => set2.map((x) => x).skip(-1));
}
