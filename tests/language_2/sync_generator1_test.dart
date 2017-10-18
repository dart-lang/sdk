// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Simple test program for sync* generator functions.

// VMOptions=--optimization_counter_threshold=10

import "package:expect/expect.dart";

sum10() sync* {
  var s = 0;
  for (var k = 1; k <= 10; k++) {
    s += k;
    yield s;
  }
}

class Range {
  int start, end;
  Range(this.start, this.end);
  elements() sync* {
    var e = start;
    while (e <= end) yield e++;
  }

  get yield sync* {
    // yield is a legal member name here.
    var e = start;
    while (e <= end) yield e++;
  }
}

get sync sync* {
  // sync is a legal identifier.
  yield "sync";
}

einsZwei() sync* {
  yield 1;
  yield* [2, 3];
  yield* [];
  yield 5;
  yield [6];
}

dreiVier() sync* {
  // Throws type error: yielded object is not an iterable.
  yield* 3; //# 01: compile-time error
}

main() {
  for (int i = 0; i < 10; i++) {
    var sums = sum10();
    print(sums);
    Expect.isTrue(sums is Iterable);
    Expect.equals(10, sums.length);
    Expect.equals(1, sums.first);
    Expect.equals(55, sums.last);
    var q = "";
    for (var n in sums.take(3)) {
      q += "$n ";
    }
    Expect.equals("1 3 6 ", q);

    var r = new Range(10, 12);
    var elems1 = r.elements();
    print(elems1);
    var elems2 = r.yield;
    print(elems2);
    // Walk the elements of each iterable and compare them.
    var i = elems1.iterator;
    Expect.isTrue(i is Iterator);
    elems2.forEach((e) {
      Expect.isTrue(i.moveNext());
      Expect.equals(e, i.current);
    });

    print(sync);
    Expect.equals("sync", sync.single);

    print(einsZwei());
    Expect.equals("(1, 2, 3, 5, [6])", einsZwei().toString());

    Expect.throws(() => dreiVier().toString()); //# 01: continued
  }
}
