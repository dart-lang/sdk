// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that dot-shorthands work with null-aware elements with and without
// separation between `?` and `.`. (That is: `?.`, which is otherwise one
// token, is parsed as `? .` at the start of an element.)

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

void main() async {
  asyncStart();
  // Retain the whitespace, and lack of whitespace, between `?` and `.`.
  // dart format off
  var cList = <C>[
    ? .cn, ?.cn, ? .c1, ?.c2,
    ? .getNone(), ?.getNone(), ? .getSome(3), ?.getSome(4),
  ];
  // dart format on
  Expect.listEquals([c1, c2, c3, c4], cList);

  // dart format off
  var eList = <E>[
    ? .vn(), ?.vn(), ? .v1(), ?.v2(),
    ? .en, ?.en, ? .e3, ?.e4,
    ? .getNone(), ?.getNone(), ? .getSome(5), ?.getSome(6),
  ];
  // dart format on
  Expect.listEquals([e1, e2, e3, e4, e5, e6], eList);

  // dart format off
  var cMap = <C, C>{
    ? .getNone(): c0,
    ?.getNone(): c0,
    ? .getSome(1): c1,
    ?.getSome(2): c2,

    c0: ? .getNone(),
    c0: ?.getNone(),
    c3: ? .getSome(3),
    c4: ?.getSome(4),

    ? .getNone(): ? .getSome(0),
    ?.getNone(): ? .getSome(0),
    ? .getNone(): ?.getSome(0),
    ?.getNone(): ?.getSome(0),

    ? .getSome(0): ? .getNone(),
    ? .getSome(0): ?.getNone(),
    ?.getSome(0): ? .getNone(),
    ?.getSome(0): ?.getNone(),

    ? .getSome(5): ? .getSome(5),
    ?.getSome(6): ? .getSome(6),
    ? .getSome(7): ?.getSome(7),
    ?.getSome(8): ?.getSome(8),
  };
  // dart format on
  Expect.mapEquals(
    {c1: c1, c2: c2, c3: c3, c4: c4, c5: c5, c6: c6, c7: c7, c8: c8},
    cMap,
  );

  // dart format off
  var eMap = <E, E>{
    ? .getNone(): e0,
    ?.getNone(): e0,
    ? .getSome(1): e1,
    ?.getSome(2): e2,

    e0: ? .getNone(),
    e0: ?.getNone(),
    e3: ? .getSome(3),
    e4: ?.getSome(4),

    ? .getNone(): ? .getSome(0),
    ?.getNone(): ? .getSome(0),
    ? .getNone(): ?.getSome(0),
    ?.getNone(): ?.getSome(0),

    ? .getSome(0): ? .getNone(),
    ? .getSome(0): ?.getNone(),
    ?.getSome(0): ? .getNone(),
    ?.getSome(0): ?.getNone(),

    ? .getSome(5): ? .getSome(5),
    ?.getSome(6): ? .getSome(6),
    ? .getSome(7): ?.getSome(7),
    ?.getSome(8): ?.getSome(8),
  };
  // dart format on
  Expect.mapEquals(
    {e1: e1, e2: e2, e3: e3, e4: e4, e5: e5, e6: e6, e7: e7, e8: e8},
    cMap,
  );

  // dart format off
  var cSet = <C>{
     ? .cn, ?.cn, ? .c1, ?.c2,
     ? .getNone(), ?.getNone(), ? .getSome(3), ?.getSome(4),
  };
  // dart format on
  Expect.setEquals({c1, c2, c3, c4}, cSet);

  // dart format off
  var eSet = <E>{
     ? .vn(), ?.vn(), ? .v1(), ?.v2(),
     ? .en, ?.en, ? .e3, ?.e4,
     ? .getNone(), ?.getNone(), ? .getSome(5), ?.getSome(6),
  };
  // dart format on
  Expect.setEquals({e1, e2, e3, e4, e5, e6}, eSet);


  // -- Constant collections.

  // dart format off
  const ccList = <C>[
    ? .cn, ?.cn, ? .c1, ?.c1,
  ];
  // dart format on
  Expect.listEquals([c1, c1], ccList);

  // dart format off
  const ccMap = <C, C> {
    ? .cn: c0,
    ?.cn: c0,
    ? .c1: c1,
    ?.c2: c2,
    c0: ? .cn,
    c0: ?.cn,
    c3: ? .c3,
    c4: ?.c4,
    ?.cn: ?.cn,
    ? .cn: ? .cn,
    ?.c5: ?.c5,
    ? .c6: ? .c6,
  };
  // dart format on
  Expect.mapEquals({c1: c1, c2: c2, c3: c3, c4: c4, c5: c5, c6: c6}, ccMap);

  // dart format off
  const ceMap = <E, E> {
    ? .vn(): e0,
    ?.vn(): e0,
    ? .v1(): e1,
    ?.v2(): e2,
    e0: ? .vn(),
    e0: ?.vn(),
    e3: ? .v3(),
    e4: ?.v4(),
    ? .vn(): ? .vn(),
    ?.vn(): ?.vn(),
    ? .v0(): ? .vn(),
    ?.v0(): ?.vn(),
    ? .vn(): ? .v0(),
    ?.vn(): ?.v0(),
    ? .v5(): ? .v5(),
    ?.v6(): ?.v6(),
  };
  // dart format on
  Expect.mapEquals({e1: e1, e2: e2, e3: e3, e4: e4, e5: e5, e6: e6}, ceMap);

  // dart format off
  const ccSet = <C>{
     ? .cn, ?.cn, ? .c1, ?.c2,
  };
  // dart format on
  Expect.setEquals({c1, c2}, ccSet);

  // dart format off
  const ceSet = <E>{
     ? .vn(), ?.vn(), ? .v1(), ?.v2(),
     ? .en, ?.en, ? .e3, ?.e4,
  };
  // dart format on
  Expect.setEquals({e1, e2, e3, e4}, ceSet);

  // Check that this also works inside other elements:
  var yes = DateTime.now().millisecondsSinceEpoch > 0;
  var cNestList = <C>[
    // dart format off
    for (var i in [1]) ? .cn, for (var i in [1]) ?.cn,
    for (var i in [1]) ? .c1, for (var i in [1]) ?.c2,
    if (yes) ? .getNone(), if (yes) ?.getNone(),
    if (yes) ? .getSome(3), if (yes) ?.getSome(4),
    ...[? .cn, ?.cn, ? .c5, ?.c6],
    await for (var i in Stream.value(1)) ? .cn,
    await for (var i in Stream.value(1)) ?.cn,
    await for (var i in Stream.value(1)) ? .c7,
    await for (var i in Stream.value(1)) ?.c8,
    // dart format on
  ];
  Expect.listEquals([c1, c2, c3, c4, c5, c6, c7, c8], cNestList);
  var cNestMap = <C,C>{
    // dart format off
    for (var i in [1]) ? .cn: c0, for (var i in [1]) ?.cn: c0,
    for (var i in [1]) c0: ? .cn, for (var i in [1]) c0: ?.cn,
    for (var i in [1]) ? .cn: c0, for (var i in [1]) ?.cn: c0,
    for (var i in [1]) ? .cn: ? .cn, for (var i in [1]) ?.cn: ?.cn,
    for (var i in [1]) ? .c1: ? .c1, for (var i in [1]) ?.c2: ?.c2,
    if (yes) ? .getNone(): c0, if (yes) ?.getNone(): c0,
    if (yes) c0: ? .getNone(), if (yes) c0: ?.getNone(),
    if (yes) ? .getNone(): ? .getNone(), if (yes) ?.getNone(): ?.getNone(),
    if (yes) ? .getSome(3): ? .c3, if (yes) ?.getSome(4): ?.c4,
    ...{
      ? .cn: c0, ?.cn: c0, 
      c0: ? .cn, c0: ?.cn, 
      ? .cn: ? .cn, ?.cn: ?.cn, 
      ? .c5: ? .c5, ?.c6: ?.c6,
    },
    await for (var i in Stream.value(1)) ? .cn: c0,
    await for (var i in Stream.value(1)) ?.cn: c0,
    await for (var i in Stream.value(1)) c0: ? .cn,
    await for (var i in Stream.value(1)) c0: ?.cn,
    await for (var i in Stream.value(1)) ? .cn: ? .cn,
    await for (var i in Stream.value(1)) ?.cn: ?.cn,
    await for (var i in Stream.value(1)) ? .c7: ? .c7,
    await for (var i in Stream.value(1)) ?.c8: ?.c8,
    // dart format on
  };
  Expect.mapEquals({c1: c1, c2: c2, c3: c3, c4: c4, c5: c5, c6: c6, c7:c7, c8: c8}, cNestMap);

  var cNestSet = <C>{
    // dart format off
    for (var i in [1]) ? .cn, for (var i in [1]) ?.cn,
    for (var i in [1]) ? .c1, for (var i in [1]) ?.c2,
    if (yes) ? .getNone(), if (yes) ?.getNone(),
    if (yes) ? .getSome(3), if (yes) ?.getSome(4),
    ...[? .cn, ?.cn, ? .c5, ?.c6],
    await for (var i in Stream.value(1)) ? .cn,
    await for (var i in Stream.value(1)) ?.cn,
    await for (var i in Stream.value(1)) ? .c7,
    await for (var i in Stream.value(1)) ?.c8,
    // dart format on
  };
  Expect.setEquals({c1, c2, c3, c4, c5, c6, c7, c8}, cNestSet);

  asyncEnd();
}

// Fixed non-null values used in tests and expectations.
const C c0 = C(0); // Not used as expected value anywhere.
const C c1 = C(1);
const C c2 = C(2);
const C c3 = C(3);
const C c4 = C(4);
const C c5 = C(5);
const C c6 = C(6);
const C c7 = C(7);
const C c8 = C(8);

const E e0 = E._(c0); // Not used as expected value anywhere.
const E e1 = E._(c1);
const E e2 = E._(c2);
const E e3 = E._(c3);
const E e4 = E._(c4);
const E e5 = E._(c5);
const E e6 = E._(c6);
const E e7 = E._(c7);
const E e8 = E._(c8);

// Has primitive equality for use in map tests.
class C {
  final int value;
  const C(this.value);

  // Getters (const even, for use in const collection tests).
  static const C? cn = null;
  static const C? c0 = C(0); // Not used as expected value anywhere.
  static const C? c1 = C(1);
  static const C? c2 = C(2);
  static const C? c3 = C(3);
  static const C? c4 = C(4);
  static const C? c5 = C(5);
  static const C? c6 = C(6);
  static const C? c7 = C(7);
  static const C? c8 = C(8);

  // Methods.
  static C? getNone() => null;
  static C? getSome(int value) => values[value];

  static const values = [c0, c1, c2, c3, c4, c5, c6, c7, c8];
  String toString() => "C($value)";
}

// A type which is not nullable, but can still be null.
extension type const E._(C? _) {
  E(int? value) : this._(value == null ? null : C.values[value]);

  // Constructors.
  const E.vn() : this._(null);
  const E.v0() : this._(c0);
  const E.v1() : this._(c1);
  const E.v2() : this._(c2);
  const E.v3() : this._(c3);
  const E.v4() : this._(c4);
  const E.v5() : this._(c5);
  const E.v6() : this._(c6);

  // Getters.
  static const E en = E._(null);
  static const E e1 = E._(c1);
  static const E e2 = E._(c2);
  static const E e3 = E._(c3);
  static const E e4 = E._(c4);
  static const E e5 = E._(c5);
  static const E e6 = E._(c6);

  // Methods.
  static E getNone() => E._(null);
  static E getSome(int value) => E._(C.getSome(value));
}
