// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:expect/expect.dart';

class Wrap {
  final int id = ++_ids;
  final Object datum;
  Wrap(this.datum);

  static int _ids = 0;

  int get hashCode => datum.hashCode;

  bool operator ==(Object other) => other is Wrap && datum == other.datum;

  String toString() => 'Wrap.$id($datum)';

  // Equality under two equivalence classes by `id`.
  static bool sameZ2(Wrap a, Wrap b) => a.id.isEven == b.id.isEven;
}

void check(Map m) {
  final wrap1a = Wrap(1);
  final wrap1b = Wrap(1);
  final wrap1c = Wrap(1);

  Expect.isTrue(wrap1a == wrap1b);
  Expect.isTrue(wrap1a == wrap1c);
  Expect.isFalse(identical(wrap1a, wrap1b));
  Expect.isFalse(identical(wrap1a, wrap1c));

  Expect.isFalse(Wrap.sameZ2(wrap1a, wrap1b));
  Expect.isTrue(Wrap.sameZ2(wrap1a, wrap1c));

  m[wrap1a] = 100;

  // `keys.contains` must be consistent with `containsKey`.
  Expect.equals(m.containsKey(wrap1a), m.keys.contains(wrap1a), 'wrap1a');
  Expect.equals(m.containsKey(wrap1b), m.keys.contains(wrap1b), 'wrap1b');
  Expect.equals(m.containsKey(wrap1c), m.keys.contains(wrap1c), 'wrap1c');
}

void main() {
  check({});
  check(Map());
  check(HashMap());
  check(LinkedHashMap());

  check(Map.identity());
  check(HashMap.identity());
  check(LinkedHashMap.identity());

  check(
    HashMap<Wrap, int>(
      hashCode: (Wrap w) => 0,
      equals: Wrap.sameZ2,
      isValidKey: (x) => x is Wrap,
    ),
  );

  check(
    LinkedHashMap<Wrap, int>(
      hashCode: (Wrap w) => 0,
      equals: Wrap.sameZ2,
      isValidKey: (x) => x is Wrap,
    ),
  );
}
