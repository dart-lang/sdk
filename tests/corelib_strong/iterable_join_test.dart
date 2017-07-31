// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class IC {
  int count = 0;
  String toString() => "${count++}";
}

testJoin(String expect, Iterable iterable, [String separator]) {
  if (separator != null) {
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
  testJoin("null,b,c,d", [null, "b", "c", "d"], ",");
  testJoin("1,2,3,4", [1, 2, 3, 4], ",");
  var ic = new IC();
  testJoin("0,1,2,3", [ic, ic, ic, ic], ",");

  var set = new Set()..add(1)..add(2)..add(3);
  var perm = new Set()
    ..add("123")
    ..add("132")
    ..add("213")
    ..add("231")
    ..add("312")
    ..add("321");
  var setString = set.join();
  Expect.isTrue(perm.contains(setString), "set: $setString");

  void testArray(List<int> array) {
    testJoin("1,3,5,7,9", array.where((i) => i.isOdd), ",");
    testJoin("0,2,4,6,8,10,12,14,16,18", array.map((i) => i * 2), ",");
    testJoin("5,6,7,8,9", array.skip(5), ",");
    testJoin("5,6,7,8,9", array.skipWhile((i) => i < 5), ",");
    testJoin("0,1,2,3,4", array.take(5), ",");
    testJoin("0,1,2,3,4", array.takeWhile((i) => i < 5), ",");
  }

  testArray([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
  var fixedArray = new List<int>(10);
  for (int i = 0; i < 10; i++) {
    fixedArray[i] = i;
  }
  testArray(fixedArray);
  testArray(const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);

  testJoin("a,b,c,d", ["a", "b", "c", "d"].map((x) => x), ",");
  testJoin("abcd", ["a", "b", "c", "d"].map((x) => x), "");
  testJoin("abcd", ["a", "b", "c", "d"].map((x) => x));
  testJoin("null,b,c,d", [null, "b", "c", "d"].map((x) => x), ",");
  testJoin("1,2,3,4", [1, 2, 3, 4].map((x) => x), ",");
  testJoin("4,5,6,7", [ic, ic, ic, ic].map((x) => x), ",");
}

void testStringVariants() {
  // ASCII
  testJoin("axbxcxd", ["a", "b", "c", "d"], "x");
  testJoin("a\u2000b\u2000c\u2000d", ["a", "b", "c", "d"], "\u2000");
  testJoin("abcd", ["a", "b", "c", "d"], "");
  testJoin("abcd", ["a", "b", "c", "d"]);
  // Non-ASCII
  testJoin("axbxcx\u2000", ["a", "b", "c", "\u2000"], "x");
  testJoin("a\u2000b\u2000c\u2000\u2000", ["a", "b", "c", "\u2000"], "\u2000");
  testJoin("abc\u2000", ["a", "b", "c", "\u2000"], "");
  testJoin("abc\u2000", ["a", "b", "c", "\u2000"]);
  // Long-ASCII
  testJoin("ax" * 255 + "a", new List.generate(256, (_) => "a"), "x");
  testJoin("a" * 256, new List.generate(256, (_) => "a"));
  // Long-Non-ASCII
  testJoin("a\u2000" * 255 + "a", new List.generate(256, (_) => "a"), "\u2000");
  testJoin("\u2000" * 256, new List.generate(256, (_) => "\u2000"));
  testJoin(
      "\u2000x" * 255 + "\u2000", new List.generate(256, (_) => "\u2000"), "x");

  var o1 = new Stringable("x");
  var o2 = new Stringable("\ufeff");
  testJoin("xa" * 3 + "x", [o1, o1, o1, o1], "a");
  testJoin("x" * 4, [o1, o1, o1, o1], "");
  testJoin("x" * 4, [o1, o1, o1, o1]);

  testJoin("\ufeffx" * 3 + "\ufeff", [o2, o2, o2, o2], "x");
  testJoin("\ufeff" * 4, [o2, o2, o2, o2], "");
  testJoin("\ufeff" * 4, [o2, o2, o2, o2]);

  testJoin("a\u2000x\ufeff", ["a", "\u2000", o1, o2]);
  testJoin("a\u2000\ufeffx", ["a", "\u2000", o2, o1]);
  testJoin("ax\u2000\ufeff", ["a", o1, "\u2000", o2]);
  testJoin("ax\ufeff\u2000", ["a", o1, o2, "\u2000"]);
  testJoin("a\ufeffx\u2000", ["a", o2, o1, "\u2000"]);
  testJoin("a\ufeff\u2000x", ["a", o2, "\u2000", o1]);

  testJoin("\u2000ax\ufeff", ["\u2000", "a", o1, o2]);
  testJoin("\u2000a\ufeffx", ["\u2000", "a", o2, o1]);
  testJoin("xa\u2000\ufeff", [o1, "a", "\u2000", o2]);
  testJoin("xa\ufeff\u2000", [o1, "a", o2, "\u2000"]);
  testJoin("\ufeffax\u2000", [o2, "a", o1, "\u2000"]);
  testJoin("\ufeffa\u2000x", [o2, "a", "\u2000", o1]);

  testJoin("\u2000xa\ufeff", ["\u2000", o1, "a", o2]);
  testJoin("\u2000\ufeffax", ["\u2000", o2, "a", o1]);
  testJoin("x\u2000a\ufeff", [o1, "\u2000", "a", o2]);
  testJoin("x\ufeffa\u2000", [o1, o2, "a", "\u2000"]);
  testJoin("\ufeffxa\u2000", [o2, o1, "a", "\u2000"]);
  testJoin("\ufeff\u2000ax", [o2, "\u2000", "a", o1]);

  testJoin("\u2000x\ufeffa", ["\u2000", o1, o2, "a"]);
  testJoin("\u2000\ufeffxa", ["\u2000", o2, o1, "a"]);
  testJoin("x\u2000\ufeffa", [o1, "\u2000", o2, "a"]);
  testJoin("x\ufeff\u2000a", [o1, o2, "\u2000", "a"]);
  testJoin("\ufeffx\u2000a", [o2, o1, "\u2000", "a"]);
  testJoin("\ufeff\u2000xa", [o2, "\u2000", o1, "a"]);
}

class Stringable {
  final String value;
  Stringable(this.value);
  String toString() => value;
}

main() {
  testCollections();
  testStringVariants();
  // TODO(lrn): test scalar lists.
}
