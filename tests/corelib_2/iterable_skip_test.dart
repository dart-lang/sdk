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

  Iterable<int> skip0 = list1.skip(0);
  Expect.isTrue(skip0 is! List);
  Iterator<int> it = skip0.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(1, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(2, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(3, it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  Iterable<int> skip1 = list1.skip(1);
  Expect.isTrue(skip1 is! List);
  Expect.isTrue(skip1.skip(2).skip(1) is! List);
  it = skip1.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(2, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(3, it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  Iterable<int> skip2 = list1.skip(2);
  Expect.isTrue(skip2 is! List);
  Expect.isTrue(skip2.skip(2).skip(1) is! List);
  it = skip2.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(3, it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  Iterable<int> skip3 = list1.skip(3);
  Expect.isTrue(skip3 is! List);
  Expect.isTrue(skip3.skip(2).skip(1) is! List);
  it = skip3.iterator;
  Expect.isNull(it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  Iterable<int> skip4 = list1.skip(4);
  Expect.isTrue(skip4 is! List);
  Expect.isTrue(skip4.skip(2).skip(1) is! List);
  it = skip4.iterator;
  Expect.isNull(it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  skip0 = list1.skip(0);
  skip1 = skip0.skip(1);
  skip2 = skip1.skip(1);
  skip3 = skip2.skip(1);
  skip4 = skip3.skip(1);
  it = skip0.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(1, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(2, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(3, it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);
  it = skip1.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(2, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(3, it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);
  it = skip2.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(3, it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);
  it = skip3.iterator;
  Expect.isNull(it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);
  it = skip4.iterator;
  Expect.isNull(it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  skip0 = list2.skip(0);
  Expect.isTrue(skip0 is! List);
  Expect.isTrue(skip0.skip(2).skip(1) is! List);
  it = skip0.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(4, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(5, it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  skip1 = list2.skip(1);
  Expect.isTrue(skip1 is! List);
  Expect.isTrue(skip1.skip(2).skip(1) is! List);
  it = skip1.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(5, it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  skip2 = list2.skip(2);
  Expect.isTrue(skip2 is! List);
  Expect.isTrue(skip2.skip(2).skip(1) is! List);
  it = skip2.iterator;
  Expect.isNull(it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  skip3 = list2.skip(3);
  Expect.isTrue(skip3 is! List);
  Expect.isTrue(skip3.skip(2).skip(1) is! List);
  it = skip3.iterator;
  Expect.isNull(it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  Iterable<String> skip02 = list3.skip(0);
  Expect.isTrue(skip02 is! List);
  Expect.isTrue(skip02.skip(2).skip(1) is! List);
  Iterator<String> it2 = skip02.iterator;
  Expect.isNull(it2.current);
  Expect.isFalse(it2.moveNext());
  Expect.isNull(it2.current);

  Iterable<String> skip12 = list3.skip(1);
  Expect.isTrue(skip12 is! List);
  Expect.isTrue(skip12.skip(2).skip(1) is! List);
  it2 = skip12.iterator;
  Expect.isNull(it2.current);
  Expect.isFalse(it2.moveNext());
  Expect.isNull(it2.current);

  skip0 = set1.skip(0);
  List<int> copied = skip0.toList();
  Expect.equals(3, copied.length);
  Expect.isTrue(set1.contains(copied[0]));
  Expect.isTrue(set1.contains(copied[1]));
  Expect.isTrue(set1.contains(copied[2]));
  Expect.isTrue(copied[0] != copied[1]);
  Expect.isTrue(copied[0] != copied[2]);
  Expect.isTrue(copied[1] != copied[2]);
  it = skip0.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.isNotNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.isNotNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.isNotNull(it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  skip1 = set1.skip(1);
  copied = skip1.toList();
  Expect.equals(2, copied.length);
  Expect.isTrue(set1.contains(copied[0]));
  Expect.isTrue(set1.contains(copied[1]));
  Expect.isTrue(copied[0] != copied[1]);
  it = skip1.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.isNotNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.isNotNull(it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  skip2 = set1.skip(2);
  copied = skip2.toList();
  Expect.equals(1, copied.length);
  Expect.isTrue(set1.contains(copied[0]));
  it = skip2.iterator;
  Expect.isNull(it.current);
  Expect.isTrue(it.moveNext());
  Expect.isNotNull(it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  skip3 = set1.skip(3);
  it = skip3.iterator;
  Expect.isNull(it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  skip4 = set1.skip(4);
  it = skip4.iterator;
  Expect.isNull(it.current);
  Expect.isFalse(it.moveNext());
  Expect.isNull(it.current);

  var dynamicSkip0 = set2.skip(0);
  var dynamicIt = dynamicSkip0.iterator;
  Expect.isNull(dynamicIt.current);
  Expect.isFalse(dynamicIt.moveNext());
  Expect.isNull(dynamicIt.current);

  var dynamicSkip1 = set2.skip(1);
  dynamicIt = dynamicSkip1.iterator;
  Expect.isNull(dynamicIt.current);
  Expect.isFalse(dynamicIt.moveNext());
  Expect.isNull(dynamicIt.current);

  testSkipTake(Iterable input, int skip, int take) {
    List expected = [];
    Iterator iter = input.iterator;
    for (int i = 0; i < skip; i++) iter.moveNext();
    for (int i = 0; i < take; i++) {
      if (!iter.moveNext()) break;
      expected.add(iter.current);
    }
    Expect.listEquals(expected, input.skip(skip).take(take).toList());
  }

  List longList = [1, 4, 5, 3, 8, 11, 12, 6, 9, 10, 13, 7, 2, 14, 15];
  Set bigSet = longList.toSet();

  for (Iterable collection in [longList, longList.reversed, bigSet]) {
    testSkipTake(collection, 0, 0);
    testSkipTake(collection, 0, 5);
    testSkipTake(collection, 0, 15);
    testSkipTake(collection, 0, 25);
    testSkipTake(collection, 5, 0);
    testSkipTake(collection, 5, 5);
    testSkipTake(collection, 5, 10);
    testSkipTake(collection, 5, 20);
    testSkipTake(collection, 15, 0);
    testSkipTake(collection, 15, 5);
    testSkipTake(collection, 20, 0);
    testSkipTake(collection, 20, 5);
    Expect.throwsRangeError(() => longList.skip(-1));
  }
}
