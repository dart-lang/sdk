// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class IC {
  int count = 0;
  String toString() => "${count++}";
}

testJoin(String expect, Iterable iterable, [String separator = ""]) {
  if (?separator) {
    Expect.equals(expect, iterable.join(separator));
  } else {
    Expect.equals(expect, iterable.join());
  }
}

testCollections() {
  testJoin("", [], ",");
  testJoin("", [], "");
  testJoin("", []);
  testJoin("", new Set(), ",");
  testJoin("", new Set(), "");
  testJoin("", new Set());

  testJoin("42", [42], ",");
  testJoin("42", [42], "");
  testJoin("42", [42]);
  testJoin("42", new Set()..add(42), ",");
  testJoin("42", new Set()..add(42), "");
  testJoin("42", new Set()..add(42));

  testJoin("a,b,c,d", ["a", "b", "c", "d"], ",");
  testJoin("abcd", ["a", "b", "c", "d"], "");
  testJoin("abcd", ["a", "b", "c", "d"]);
  testJoin("null,b,c,d", [null,"b","c","d"], ",");
  testJoin("1,2,3,4", [1, 2, 3, 4], ",");
  var ic = new IC();
  testJoin("0,1,2,3", [ic, ic, ic, ic], ",");

  var set = new Set()..add(1)..add(2)..add(3);
  var perm = new Set()..add("123")..add("132")..add("213")
                      ..add("231")..add("312")..add("321");
  var setString = set.join();
  Expect.isTrue(perm.contains(setString), "set: $setString");

  void testArray(array) {
    testJoin("1,3,5,7,9", array.where((i) => i.isOdd), ",");
    testJoin("0,2,4,6,8,10,12,14,16,18", array.map((i) => i * 2), ",");
    testJoin("5,6,7,8,9", array.skip(5), ",");
    testJoin("5,6,7,8,9", array.skipWhile((i) => i < 5), ",");
    testJoin("0,1,2,3,4", array.take(5), ",");
    testJoin("0,1,2,3,4", array.takeWhile((i) => i < 5), ",");
  }
  testArray([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
  var fixedArray = new List(10);
  for (int i = 0; i < 10; i++) {
    fixedArray[i] = i;
  }
  testArray(fixedArray);
  testArray(const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);

  testJoin("a,b,c,d", ["a", "b", "c", "d"].map((x) => x), ",");
  testJoin("abcd", ["a", "b", "c", "d"].map((x) => x), "");
  testJoin("abcd", ["a", "b", "c", "d"].map((x) => x));
  testJoin("null,b,c,d", [null,"b","c","d"].map((x) => x), ",");
  testJoin("1,2,3,4", [1, 2, 3, 4].map((x) => x), ",");
  testJoin("4,5,6,7", [ic, ic, ic, ic].map((x) => x), ",");
}

main() {
  testCollections();
  // TODO(lrn): test scalar lists.
}
