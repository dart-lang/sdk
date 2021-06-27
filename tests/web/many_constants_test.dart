// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This program has many similar constants that should all have distinct
// identities. They are sufficiently similar to have name collisions and need
// ordering by constant value.

import "package:expect/expect.dart";

enum E { A, B, C, D }

class Z {
  final a, b, c, d, e, f;
  const Z({this.a: 1, this.b: 1, this.c: 1, this.d: 1, this.e: 1, this.f: 1});
}

const c1 = const {};
const c2 = const <int, int>{};
const c3 = const <dynamic, int>{};
const c4 = const <int, dynamic>{};
const l1 = const [];
const l2 = const <int>[];
const l3 = const <String>[];
const l4 = const <num>[];

const ll1 = const [1, 2, 3, 4, 5, 6, 7];
const ll2 = const [1, 8, 3, 4, 5, 6, 7];
const ll3 = const [1, 2, 8, 4, 5, 6, 7];
const ll4 = const [1, 2, 3, 4, 8, 6, 7];

const m1 = const <dynamic, dynamic>{1: 1, 2: 2};
const m2 = const <dynamic, dynamic>{1: 2, 2: 1};
const m3 = const <dynamic, dynamic>{1: 1, 2: 1};
const m4 = const <dynamic, dynamic>{1: 2, 2: 2};
const m5 = const <dynamic, dynamic>{2: 1, 1: 2};
const m6 = const <dynamic, dynamic>{2: 2, 1: 1};
const m7 = const <dynamic, dynamic>{2: 1, 1: 1};
const m8 = const <dynamic, dynamic>{2: 2, 1: 2};
const m9 = const <int, int>{1: 1, 2: 2};
const mA = const <int, int>{1: 2, 2: 1};
const mB = const <int, int>{1: 1, 2: 1};
const mC = const <int, int>{1: 2, 2: 2};

const mE1 = const {E.A: E.B};
const mE2 = const {E.A: E.C};
const mE3 = const {E.A: 0, E.B: 0};
const mE4 = const {E.A: 0, E.C: 0};
const mE5 = const {E.A: 0, E.B: 0, E.C: 4};
const mE6 = const {E.A: 0, E.B: 0, E.C: 2};
const mE7 = const {E.A: 0, E.B: 0, E.C: 3};
const mE8 = const {E.A: 0, E.B: 0, E.C: 1};

const z1 = const Z(f: 3);
const z2 = const Z(f: 2);
const z3 = const Z(f: 1);
const z4 = const Z(e: 2);
const z5 = const Z(d: 3);
const z6 = const Z(d: 2);

makeAll() => {
      'E.A': E.A,
      'E.B': E.B,
      'E.C': E.C,
      'E.D': E.D,
      'c1': c1,
      'c2': c2,
      'c3': c3,
      'c4': c4,
      'l1': l1,
      'l2': l2,
      'l3': l3,
      'l4': l4,
      'll1': ll1,
      'll2': ll2,
      'll3': ll3,
      'l4': ll4,
      'm1': m1,
      'm2': m2,
      'm3': m3,
      'm4': m4,
      'm5': m5,
      'm6': m6,
      'm7': m7,
      'm8': m8,
      'm9': m9,
      'mA': mA,
      'mB': mB,
      'mC': mC,
      'mE1': mE1,
      'mE2': mE2,
      'mE3': mE3,
      'mE4': mE4,
      'mE5': mE5,
      'mE6': mE6,
      'mE7': mE7,
      'mE8': mE8,
      'z1': z1,
      'z2': z2,
      'z3': z3,
      'z4': z4,
      'z5': z5,
      'z6': z6,
    };

main() {
  var all1 = makeAll();
  var all2 = makeAll();

  for (var name1 in all1.keys) {
    var e1 = all1[name1];
    for (var name2 in all2.keys) {
      if (name1 == name2) continue;
      var e2 = all2[name2];
      Expect.isFalse(
          identical(e1, e2), 'Different instances  $name1: $e1  $name2: $e2');
    }
  }
}
