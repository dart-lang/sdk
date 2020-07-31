// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): this is a copy of the language test of the same name,
// we can remove this copy when we're running against those tests.
import "package:expect/expect.dart";

Iterable<int> foo1() sync* {
  yield 1;
}

Iterable<int?> foo2(p) sync* {
  bool t = false;
  yield null;
  while (true) {
    a:
    for (int i = 0; i < p; i++) {
      if (!t) {
        for (int j = 0; j < 3; j++) {
          yield -1;
          t = true;
          break a;
        }
      }
      yield i;
    }
  }
}

// p is copied to all Iterators from the Iterable returned by foo3.
// Also each iterator will have its own i.
Iterable<int> foo3(int p) sync* {
  int i = 0;
  i++;
  p++;
  yield p + i;
}

void testCapturingInSyncStar() {
  int localL0 = 0;

  nested1(int paramL1) sync* {
    int localL1 = 0;
    localL0 += 10;
    paramL1 += 100;

    nested2(int paramL2) sync* {
      int localL2 = 0;
      localL0 += 1000;
      paramL1 += 10000;
      localL1 += 100000;
      paramL2 += 1000000;
      localL2 += 10000000;

      yield localL0 + paramL1 + localL1 + paramL2 + localL2;
    }

    yield nested2(0);
  }

  Iterable t1 = nested1(0);

  Iterator it11 = t1.iterator;
  Iterator it12 = t1.iterator;
  it11.moveNext();
  it12.moveNext();

  Iterable t2 = it11.current;
  Iterable t3 = it12.current;
  Iterator it21 = t2.iterator;
  Iterator it22 = t2.iterator;
  Iterator it31 = t3.iterator;
  Iterator it32 = t3.iterator;

  it21.moveNext();
  it22.moveNext();
  it31.moveNext();
  it32.moveNext();

  Expect.equals(11111120, it21.current);
  Expect.equals(11222120, it22.current);
  Expect.equals(11113120, it31.current);
  Expect.equals(11224120, it32.current);
}

main() {
  Expect.listEquals([1], foo1().toList());
  Expect.listEquals(
      [null, -1, 0, 1, 2, 3, 0, 1, 2, 3], foo2(4).take(10).toList());
  Iterable t = foo3(0);
  Iterator it1 = t.iterator;
  Iterator it2 = t.iterator; //# copyParameters: ok
  it1.moveNext();
  it2.moveNext(); //# copyParameters: continued
  Expect.equals(2, it1.current);
  // TODO(sigurdm): Check up on the spec here.
  Expect.equals(2, it2.current); // //# copyParameters: continued
  Expect.isFalse(it1.moveNext());
  // Test that two `moveNext()` calls are fine.
  Expect.isFalse(it1.moveNext());
  Expect.isFalse(it2.moveNext()); //# copyParameters: continued
  Expect.isFalse(it2.moveNext()); //# copyParameters: continued

  testCapturingInSyncStar(); //# capturing: ok
}
