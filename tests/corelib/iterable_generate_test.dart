// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  void test(expectedList, generatedIterable) {
    Expect.equals(expectedList.length, generatedIterable.length);
    Expect.listEquals(expectedList, generatedIterable.toList());
  }

  test([], new Iterable.generate(0));
  test([0], new Iterable.generate(1));
  test([0, 1, 2, 3, 4], new Iterable.generate(5));
  test(["0", "1", "2", "3", "4"], new Iterable.generate(5, (x) => "$x"));
  test([2, 3, 4, 5, 6], new Iterable.generate(7).skip(2));
  test([0, 1, 2, 3, 4], new Iterable.generate(7).take(5));
  test([], new Iterable.generate(5).skip(6));
  test([], new Iterable.generate(5).take(0));
  test([], new Iterable.generate(5).take(3).skip(3));
  test([], new Iterable.generate(5).skip(6).take(0));

  // Test types.

  Iterable<int> it = new Iterable<int>.generate(5);
  Expect.isTrue(it is Iterable<int>);
  Expect.isTrue(it.iterator is Iterator<int>);
  Expect.isTrue(it is! Iterable<String>);
  Expect.isTrue(it.iterator is! Iterator<String>);
  test([0, 1, 2, 3, 4], it);

  Iterable<String> st = new Iterable<String>.generate(5, (x) => "$x");
  Expect.isTrue(st is Iterable<String>);
  Expect.isTrue(st.iterator is Iterator<String>);
  Expect.isFalse(st is Iterable<int>);
  Expect.isFalse(st.iterator is Iterator<int>);
  test(["0", "1", "2", "3", "4"], st);

  if (typeAssertionsEnabled) {
    Expect.throws(() => new Iterable<String>.generate(5));
  }

  // Omitted generator function means `(int x) => x`, and the type parameters
  // must then be compatible with `int`.
  // Check that we catch invalid type parameters.

  // Valid types:
  Iterable<int> iter1 = new Iterable<int>.generate(5);
  Expect.equals(2, iter1.elementAt(2));
  Iterable<num> iter2 = new Iterable<num>.generate(5);
  Expect.equals(2, iter2.elementAt(2));
  Iterable<Object> iter3 = new Iterable<Object>.generate(5);
  Expect.equals(2, iter3.elementAt(2));
  Iterable<dynamic> iter4 = new Iterable<dynamic>.generate(5);
  Expect.equals(2, iter4.elementAt(2));

  // Invalid types:
  Expect.throws(() => new Iterable<String>.generate(5));
  if (typeAssertionsEnabled) { //                                       //# 01: ok
    Expect.throws(() => new Iterable<Null>.generate(5).elementAt(2));   //# 01: continued
  } else { //                                                           //# 01: continued
    Iterable<dynamic> iter5 = new Iterable<Null>.generate(5); //        //# 01: continued
    Expect.equals(2, iter5.elementAt(2)); //                            //# 01: continued
  } //                                                                  //# 01: continued
  Expect.throws(() => new Iterable<bool>.generate(5));

  // Regression: https://github.com/dart-lang/sdk/issues/26358
  var count = 0;
  var iter = new Iterable.generate(5, (v) {
    count++;
    return v;
  });
  Expect.equals(0, count);
  Expect.equals(2, iter.elementAt(2)); // Doesn't compute the earlier values.
  Expect.equals(1, count);
  Expect.equals(2, iter.skip(2).first); // Doesn't compute the skipped values.
  Expect.equals(2, count);
}
