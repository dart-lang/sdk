// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// Typed as dynamic to also test spreading a value of type dynamic.
const dynamic list = [1, 2, 3, 4];
const dynamic map = {1: 1, 2: 2, 3: 3, 4: 4};
const dynamic set = {1, 2, 3, 4};

void main() {
  testList();
  testMap();
  testSet();
  testKeyOrder();
}

void testList() {
  // Only spread.
  Expect.identical(list, const <int>[...list]);
  Expect.identical(list, const <int>[...set]);

  // Spread at beginning.
  Expect.identical(list, const <int>[...<int>[1, 2], 3, 4]);

  // Spread in middle.
  Expect.identical(list, const <int>[1, ...<int>[2, 3], 4]);

  // Spread at end.
  Expect.identical(list, const <int>[1, 2, ...<int>[3, 4]]);

  // Empty spreads.
  Expect.identical(list,
      const <int>[...<int>[], 1, 2, ...<int>[], 3, 4, ...<int>[]]);

  // Multiple spreads.
  Expect.identical(list,
      const <int>[...<int>[1], 2, ...<int>[3, 4]]);

  // Nested spreads.
  Expect.identical(list,
      const <int>[...<int>[...<int>[1, 2], ...<int>[3, 4]]]);

  // Null-aware.
  Expect.identical(list,
      const <int>[1, ...?<int>[2, 3], ...?(null), ...?<int>[4]]);

  // Does not deep flatten.
  Expect.identical(
      const <Object>[1, 2, <int>[3], 4],
      const <Object>[1, ...<Object>[2, <int>[3], 4]]);

  // Establishes const context.
  Expect.identical(const <Symbol>[Symbol("sym")],
      const <Symbol>[...<Symbol>[Symbol("sym")]]);
}

void testMap() {
  // Only spread.
  Expect.identical(map, const <int, int>{...map});

  // Spread at beginning.
  Expect.identical(map,
      const <int, int>{...<int, int>{1: 1, 2: 2}, 3: 3, 4: 4});

  // Spread in middle.
  Expect.identical(map,
      const <int, int>{1: 1, ...<int, int>{2: 2, 3: 3}, 4: 4});

  // Spread at end.
  Expect.identical(map,
      const <int, int>{1: 1, 2: 2, ...<int, int>{3: 3, 4: 4}});

  // Empty spreads.
  Expect.identical(map, const <int, int>{
    ...<int, int>{},
    1: 1,
    2: 2,
    ...<int, int>{},
    3: 3,
    4: 4,
    ...<int, int>{}
  });

  // Multiple spreads.
  Expect.identical(map,
      const <int, int>{...<int, int>{1: 1}, 2: 2, ...<int, int>{3: 3, 4: 4}});

  // Nested spreads.
  Expect.identical(map, const <int, int>{
    ...<int, int>{
      ...<int, int>{1: 1, 2: 2},
      ...<int, int>{3: 3, 4: 4}
    }
  });

  // Null-aware.
  Expect.identical(map, const <int, int>{
    1: 1,
    ...?<int, int>{2: 2, 3: 3},
    ...?(null),
    ...?<int, int>{4: 4}
  });

  // Does not deep flatten.
  Expect.identical(const <int, Object>{
    1: 1,
    2: 2,
    3: <int, int>{3: 3},
    4: 4
  }, const <int, Object>{
    1: 1,
    ...<int, Object>{
      2: 2,
      3: <int, int>{3: 3},
      4: 4
    }
  });

  // Establishes const context.
  Expect.identical(const <Symbol, Symbol>{
    Symbol("sym"): Symbol("bol")
  }, const <Symbol, Symbol>{
    ...<Symbol, Symbol>{Symbol("sym"): Symbol("bol")}
  });
}

void testSet() {
  // Only spread.
  Expect.identical(set, const <int>{...set});
  Expect.identical(set, const <int>{...list});

  // Spread at beginning.
  Expect.identical(set, const <int>{...<int>[1, 2], 3, 4});

  // Spread in middle.
  Expect.identical(set, const <int>{1, ...<int>[2, 3], 4});

  // Spread at end.
  Expect.identical(set, const <int>{1, 2, ...<int>[3, 4]});

  // Empty spreads.
  Expect.identical(set,
      const <int>{...<int>[], 1, 2, ...<int>[], 3, 4, ...<int>[]});

  // Multiple spreads.
  Expect.identical(set, const <int>{...<int>[1], 2, ...<int>[3, 4]});

  // Nested spreads.
  Expect.identical(set, const <int>{...<int>{...<int>[1, 2], ...<int>[3, 4]}});

  // Null-aware.
  Expect.identical(set,
      const <int>{1, ...?<int>[2, 3], ...?(null), ...?<int>[4]});

  // Does not deep flatten.
  Expect.identical(const <Object>{1, 2, <int>{3}, 4},
      const <Object>{1, ...<Object>{2, <int>{3}, 4}});

  // Establishes const context.
  Expect.identical(const <Symbol>{Symbol("sym")},
      const <Symbol>{...<Symbol>{Symbol("sym")}});
}

void testKeyOrder() {
  // Canonicalization isn't affected by which elements are spread.
  Expect.identical(map,
      const <int, int>{1: 1, ...<int, int>{2: 2, 3: 3}, 4: 4});
  Expect.identical(map,
      const <int, int>{1: 1, ...<int, int>{2: 2}, 3: 3, ...<int, int>{4: 4}});

  Expect.identical(set, const <int>{1, ...<int>{2, 3}, 4});
  Expect.identical(set, const <int>{1, ...<int>{2}, 3, ...<int>{4}});

  // Ordering does affect canonicalization.
  Expect.notIdentical(const <int, int>{1: 1, 2: 2, 3: 3},
      const <int, int>{1: 1, ...<int, int>{3: 3, 2: 2}});
  Expect.notIdentical(const <int>{1, 2, 3}, const <int>{1, ...<int>{3, 2}});
}
