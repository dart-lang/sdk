// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'utils.dart';

// Typed as dynamic to also test spreading a value of type dynamic.
const dynamic list = [1, 2, 3];
const dynamic map = {1: 1, 2: 2, 3: 3};
const dynamic set = {1, 2, 3};

const dynamic dynamicTrue = true;

void main() {
  testList();
  testMap();
  testSet();
  testShortCircuit();
  testDuplicateKeys();
  testKeyOrder();
}

void testList() {
  // Then if true.
  Expect.identical(list, const <int>[1, if (true) 2, 3]);

  // Nothing if false and no else.
  Expect.identical(list, const <int>[1, if (false) 9, 2, 3]);

  // Else if false.
  Expect.identical(list, const <int>[1, if (false) 9 else 2, 3]);

  // Only if.
  Expect.identical(const [1], const <int>[if (true) 1]);

  // If at beginning.
  Expect.identical(list, const <int>[if (true) 1, 2, 3]);

  // If in middle.
  Expect.identical(list, const <int>[1, if (true) 2, 3]);

  // If at end.
  Expect.identical(list, const <int>[1, 2, if (true) 3]);

  // Multiple ifs.
  Expect.identical(list,
      const <int>[if (true) 1, if (false) 9, 2, if (true) 3]);

  // Cast condition.
  Expect.identical(const [1], const <int>[if (dynamicTrue) 1]);

  // Does not flatten nested collection literal.
  Expect.identical(const [1], const [if (true) [1]].first);
  Expect.identical(const {1: 1}, const [if (true) {1: 1}].first);
  Expect.identical(const {1}, const [if (true) {1}].first);

  // Nested spread.
  Expect.identical(list,
      const <int>[if (true) ...<int>[1, 2], if (false) 9 else ...<int>[3]]);

  // Nested if in then.
  Expect.identical(const [1],
      const <int>[if (true) if (true) 1, if (true) if (false) 9]);

  // Nested if in else.
  Expect.identical(const [1], const <int>[if (false) 9 else if (true) 1]);
}

void testMap() {
  // Then if true.
  Expect.identical(map, const <int, int>{1: 1, if (true) 2: 2, 3: 3});

  // Nothing if false and no else.
  Expect.identical(map, const <int, int>{1: 1, if (false) 9: 9, 2: 2, 3: 3});

  // Else if false.
  Expect.identical(map,
      const <int, int>{1: 1, if (false) 9: 9 else 2: 2, 3: 3});

  // Only if.
  Expect.identical(const {1: 1}, const <int, int>{if (true) 1: 1});

  // If at beginning.
  Expect.identical(map, const <int, int>{if (true) 1: 1, 2: 2, 3: 3});

  // If in middle.
  Expect.identical(map, const <int, int>{1: 1, if (true) 2: 2, 3: 3});

  // If at end.
  Expect.identical(map, const <int, int>{1: 1, 2: 2, if (true) 3: 3});

  // Multiple ifs.
  Expect.identical(map,
      const <int, int>{if (true) 1: 1, if (false) 9: 9, 2: 2, if (true) 3: 3});

  // Cast condition.
  Expect.identical(const {1: 1}, const <int, int>{if (dynamicTrue) 1: 1});

  // Nested spread.
  Expect.identical(map, const <int, int>{
    if (true) ...<int, int>{1: 1, 2: 2},
    if (false) 9: 9 else ...<int, int>{3: 3}
  });

  // Nested if in then.
  Expect.identical(const {1: 1},
      const <int, int>{if (true) if (true) 1: 1, if (true) if (false) 9: 9});

  // Nested if in else.
  Expect.identical(const {1: 1},
      const <int, int>{if (false) 9: 9 else if (true) 1: 1});
}

void testSet() {
  // Then if true.
  Expect.identical(set, const <int>{1, if (true) 2, 3});

  // Nothing if false and no else.
  Expect.identical(set, const <int>{1, if (false) 9, 2, 3});

  // Else if false.
  Expect.identical(set, const <int>{1, if (false) 9 else 2, 3});

  // Only if.
  Expect.identical(const <int>{1}, const <int>{if (true) 1});

  // If at beginning.
  Expect.identical(set, const <int>{if (true) 1, 2, 3});

  // If in middle.
  Expect.identical(set, const <int>{1, if (true) 2, 3});

  // If at end.
  Expect.identical(set, const <int>{1, 2, if (true) 3});

  // Multiple ifs.
  Expect.identical(set,
      const <int>{if (true) 1, if (false) 9, 2, if (true) 3});

  // Cast condition.
  Expect.identical(const <int>{1}, const <int>{if (dynamicTrue) 1});

  // Does not flatten nested collection literal.
  Expect.identical(const <int>[1], const <List<int>>{if (true) [1]}.first);
  Expect.identical(
      const <int, int>{1: 1}, const <Map<int, int>>{if (true) {1: 1}}.first);
  Expect.identical(const <int>{1}, const <Set<int>>{if (true) {1}}.first);

  // Nested spread.
  Expect.identical(set,
      const <int>{if (true) ...<int>[1, 2], if (false) 9 else ...<int>[3]});

  // Nested if in then.
  Expect.identical(const <int>{1},
      const <int>{if (true) if (true) 1, if (true) if (false) 9});

  // Nested if in else.
  Expect.identical(const <int>{1}, const <int>{if (false) 9 else if (true) 1});
}

void testShortCircuit() {
  // A const expression that throws does not cause a compile error if it occurs
  // inside an unchosen branch of an if.

  // Store null in a dynamically-typed constant to avoid the type error on "+".
  const dynamic nil = null;

  Expect.identical(const <int>[1],
      const <int>[if (true) 1, if (false) nil + 1]);
  Expect.identical(const <int>[1, 2],
      const <int>[if (true) 1 else nil + 1, if (false) nil + 1 else 2]);

  Expect.identical(const <int, int>{1: 1}, const <int, int>{
    if (true) 1: 1,
    if (false) nil + 1: 9,
    if (false) 9: nil + 1
  });
  Expect.identical(const <int, int>{1: 1, 2: 2}, const <int, int>{
    if (true) 1: 1 else nil + 1: 9,
    if (false) 9: nil + 1 else 2: 2
  });

  Expect.identical(const <int>{1},
      const <int>{if (true) 1, if (false) nil + 1});
  Expect.identical(const <int>{1, 2},
      const <int>{if (true) 1 else nil + 1, if (false) nil + 1 else 2});

  // A const expression whose value isn't the right type does not cause a
  // compile error if it occurs inside an unchosen branch.
  const dynamic nonInt = "s";

  Expect.identical(const <int>[1], const <int>[if (true) 1, if (false) nonInt]);
  Expect.identical(const <int>[1, 2],
      const <int>[if (true) 1 else nonInt, if (false) nonInt else 2]);

  Expect.identical(const <int, int>{1: 1}, const <int, int>{
    if (true) 1: 1,
    if (false) nonInt: 9,
    if (false) 9: nonInt
  });
  Expect.identical(const <int, int>{1: 1, 2: 2}, const <int, int>{
    if (true) 1: 1 else nonInt: 9,
    if (false) 9: nonInt else 2: 2
  });

  Expect.identical(const <int>{1}, const <int>{if (true) 1, if (false) nonInt});
  Expect.identical(const <int>{1, 2},
      const <int>{if (true) 1 else nonInt, if (false) nonInt else 2});
}

void testDuplicateKeys() {
  // Duplicate keys from unchosen branches are not an error.
  Expect.mapEquals(map, <int, int>{
    1: 1,
    if (false) 1: 1,
    if (true) 2: 2 else 3: 3,
    3: 3
  });

  Expect.setEquals(set, const <int>{1, if (false) 1, if (true) 2 else 3, 3});
}

void testKeyOrder() {
  // Canonicalization isn't affected by which elements are conditional.
  Expect.identical(map,
      const <int, int>{1: 1, if (true) 2: 2, if (false) 9: 9, 3: 3});
  Expect.identical(map,
      const <int, int>{if (false) 9: 9 else 1: 1, 2: 2, if (true) 3: 3});

  Expect.identical(set, const <int>{1, if (true) 2, if (false) 9, 3});
  Expect.identical(set, const <int>{if (false) 9 else 1, 2, if (true) 3});

  // Ordering does affect canonicalization.
  Expect.notIdentical(map, const <int, int>{1: 1, if (true) 3: 3, 2: 2});
  Expect.notIdentical(set, const <int>{1, if (true) 3, 2});
}
