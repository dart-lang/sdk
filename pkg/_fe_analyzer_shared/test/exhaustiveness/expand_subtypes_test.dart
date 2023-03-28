// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/exhaustive.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';
import 'package:test/test.dart';

import 'env.dart';

void main() {
  test('sealed', () {
    //   (A)
    //   /|\
    //  B C(D)
    //     / \
    //    E   F
    var env = TestEnvironment();
    var a = env.createClass('A', isSealed: true);
    env.createClass('B', inherits: [a]);
    env.createClass('C', inherits: [a]);
    var d = env.createClass('D', isSealed: true, inherits: [a]);
    env.createClass('E', inherits: [d]);
    env.createClass('F', inherits: [d]);

    expectExpand(a, 'B|C|E|F');
    expectExpand(d, 'E|F');
  });

  test('unsealed', () {
    //    A
    //   /|\
    //  B C D
    //     / \
    //    E   F
    var env = TestEnvironment();
    var a = env.createClass('A');
    env.createClass('B', inherits: [a]);
    env.createClass('C', inherits: [a]);
    var d = env.createClass('D', inherits: [a]);
    env.createClass('E', inherits: [d]);
    env.createClass('F', inherits: [d]);

    expectExpand(a, 'A');
    expectExpand(d, 'D');
  });

  test('unsealed in middle', () {
    //    (A)
    //    / \
    //   B   C
    //      / \
    //     D  (E)
    //        / \
    //       F   G
    var env = TestEnvironment();
    var a = env.createClass('A', isSealed: true);
    env.createClass('B', inherits: [a]);
    var c = env.createClass('C', inherits: [a]);
    env.createClass('D', inherits: [c]);
    var e = env.createClass('E', isSealed: true, inherits: [c]);
    env.createClass('F', inherits: [e]);
    env.createClass('G', inherits: [e]);

    expectExpand(a, 'B|C');
    expectExpand(c, 'C');
    expectExpand(e, 'F|G');
  });

  test('transitive sealed family', () {
    //     (A)
    //     / \
    //   (B) (C)
    //   / | | \
    //  D  E F  G
    //     \ /
    //      H
    var env = TestEnvironment();
    var a = env.createClass('A', isSealed: true);
    var b = env.createClass('B', isSealed: true, inherits: [a]);
    var c = env.createClass('C', isSealed: true, inherits: [a]);
    var d = env.createClass('D', inherits: [b]);
    var e = env.createClass('E', inherits: [b]);
    var f = env.createClass('F', inherits: [c]);
    env.createClass('G', inherits: [c]);
    var h = env.createClass('H', inherits: [e, f]);

    expectExpand(a, 'D|E|F|G');
    expectExpand(b, 'D|E');
    expectExpand(d, 'D');
    expectExpand(e, 'E');
    expectExpand(h, 'H');
  });

  test('sealed with multiple paths', () {
    //     (A)
    //     / \
    //   (B)  C
    //   / \ /
    //  D   E
    var env = TestEnvironment();
    var a = env.createClass('A', isSealed: true);
    var b = env.createClass('B', isSealed: true, inherits: [a]);
    var c = env.createClass('C', inherits: [a]);
    var d = env.createClass('D', inherits: [b]);
    var e = env.createClass('E', inherits: [b, c]);

    expectExpand(a, 'D|E|C');
    expectExpand(b, 'D|E');
    expectExpand(c, 'C');
    expectExpand(d, 'D');
    expectExpand(e, 'E');
  });

  test('nullable', () {
    //   (A)
    //   / \
    //  B   C
    //     / \
    //    D   E
    var env = TestEnvironment();
    var a = env.createClass('A', isSealed: true);
    env.createClass('B', inherits: [a]);
    var c = env.createClass('C', inherits: [a]);
    env.createClass('D', inherits: [c]);

    // Sealed subtype.
    expectExpand(a.nullable, 'B|C|Null');

    // Unsealed subtype.
    expectExpand(c.nullable, 'C|Null');
  });
}

void expectExpand(StaticType type, String expected) {
  expect(expandSealedSubtypes(type, const {}).join('|'), expected);
}
