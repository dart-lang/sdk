// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for List.shuffle.
library shuffle_test;

import "dart:typed_data";
import "dart:math" show Random;
import "package:expect/expect.dart";

main() {
  for (int size in [0, 1, 2, 3, 7, 15, 99, 1023]) {
    var numbers = new List<int>.generate(size, (x) => x);
    testShuffle(numbers.toList(growable: true));
    testShuffle(numbers.toList(growable: false));
    testShuffle(new Uint32List(size)..setAll(0, numbers));
    testShuffle(new Int32List(size)..setAll(0, numbers));
    testShuffle(new Uint16List(size)..setAll(0, numbers));
    testShuffle(new Int16List(size)..setAll(0, numbers));
    // Some numbers will be truncated in the following two.
    testShuffle(new Uint8List(size)..setAll(0, numbers));
    testShuffle(new Int8List(size)..setAll(0, numbers));
    //testShuffle(numbers.map((x) => "$x").toList());
  }

  // Check that it actually can keep the same list (regression test).
  List l = [1, 2];
  success:
  {
    for (int i = 0; i < 266; i++) {
      int first = l.first;
      l.shuffle();
      if (l.first == first) break success; // List didn't change.
    }
    // Chance of changing 266 times in a row should be < 1:1e80.
    Expect.fail("List changes every time.");
  }

  testRandom();
}

void testShuffle(list) {
  List copy = list.toList();
  list.shuffle();
  if (list.length < 2) {
    Expect.listEquals(copy, list);
    return;
  }
  // Test that the list after shuffling has the same elements as before,
  // without considering order.
  Map seen = {};
  for (var e in list) {
    seen[e] = seen.putIfAbsent(e, () => 0) + 1;
  }
  for (var e in copy) {
    int remaining = seen[e];
    remaining -= 1; // Throws if e was not in map at all.
    if (remaining == 0) {
      seen.remove(e);
    } else {
      seen[e] = remaining;
    }
  }
  Expect.isTrue(seen.isEmpty);
  // Test that shuffle actually does make a change. Repeat until the probability
  // of a proper shuffling hitting the same list again is less than 10^80
  // (arbitrary bignum - approx. number of atoms in the universe).
  //
  // The probablility of shuffling a list of length n into the same list is
  // 1/n!. If one shuffle didn't change the list, repeat shuffling until
  // probability of randomly hitting the same list every time is less than
  // 1/1e80.

  bool listsDifferent() {
    for (int i = 0; i < list.length; i++) {
      if (list[i] != copy[i]) return true;
    }
    return false;
  }

  if (list.length < 59) {
    // 59! > 1e80.
    double limit = 1e80;
    double fact = 1.0;
    for (int i = 2; i < list.length; i++) fact *= i;
    double combos = fact;

    while (!listsDifferent() && combos < limit) {
      list.shuffle();
      combos *= fact;
    }
  }
  if (!listsDifferent()) {
    Expect.fail("Didn't shuffle at all, p < 1:1e80: $list");
  }
}

// Checks that the "random" argument to shuffle is used.
testRandom() {
  List<int> randomNums = [37, 87, 42, 157, 252, 17];
  List numbers = new List.generate(25, (x) => x);
  List l1 = numbers.toList()..shuffle(new MockRandom(randomNums));
  for (int i = 0; i < 50; i++) {
    // With same random sequence, we get the same shuffling each time.
    List l2 = numbers.toList()..shuffle(new MockRandom(randomNums));
    Expect.listEquals(l1, l2);
  }
}

class MockRandom implements Random {
  final List<int> _values;
  int index = 0;
  MockRandom(this._values);

  int get _next {
    int next = _values[index];
    index = (index + 1) % _values.length;
    return next;
  }

  int nextInt(int limit) => _next % limit;

  double nextDouble() => _next / 256.0;

  bool nextBool() => _next.isEven;
}
