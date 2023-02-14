// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'env.dart';
import 'utils.dart';

void main() {
  group('sealed subtypes |', () {
    //   (A)
    //   / \
    //  B   C
    var env = TestEnvironment();
    var a = env.createClass('A', isSealed: true);
    var b = env.createClass('B', inherits: [a]);
    var c = env.createClass('C', inherits: [a]);
    var t = env.createClass('T', fields: {'x': a, 'y': a});

    expectExhaustiveOnlyAll(t, [
      ty(t, {'x': b, 'y': b}),
      ty(t, {'x': b, 'y': c}),
      ty(t, {'x': c, 'y': b}),
      ty(t, {'x': c, 'y': c}),
    ]);
  });

  group('sealed subtypes medium |', () {
    //   (A)
    //   /|\
    //  B C D
    var env = TestEnvironment();
    var a = env.createClass('A', isSealed: true);
    var b = env.createClass('B', inherits: [a]);
    var c = env.createClass('C', inherits: [a]);
    var d = env.createClass('D', inherits: [a]);
    var t = env.createClass('T', fields: {'y': a, 'z': a});

    expectExhaustiveOnlyAll(t, [
      ty(t, {'y': b, 'z': b}),
      ty(t, {'y': b, 'z': c}),
      ty(t, {'y': b, 'z': d}),
      ty(t, {'y': c, 'z': b}),
      ty(t, {'y': c, 'z': c}),
      ty(t, {'y': c, 'z': d}),
      ty(t, {'y': d, 'z': b}),
      ty(t, {'y': d, 'z': c}),
      ty(t, {'y': d, 'z': d}),
    ]);
  });

  group('sealed subtypes large |', () {
    //   (A)
    //   /|\
    //  B C D
    var env = TestEnvironment();
    var a = env.createClass('A', isSealed: true);
    var b = env.createClass('B', inherits: [a]);
    var c = env.createClass('C', inherits: [a]);
    var d = env.createClass('D', inherits: [a]);
    var t = env.createClass('T', fields: {'w': a, 'x': a, 'y': a, 'z': a});

    expectExhaustiveOnlyAll(t, [
      ty(t, {'w': b, 'x': b, 'y': b, 'z': b}),
      ty(t, {'w': b, 'x': b, 'y': b, 'z': c}),
      ty(t, {'w': b, 'x': b, 'y': b, 'z': d}),
      ty(t, {'w': b, 'x': b, 'y': c, 'z': b}),
      ty(t, {'w': b, 'x': b, 'y': c, 'z': c}),
      ty(t, {'w': b, 'x': b, 'y': c, 'z': d}),
      ty(t, {'w': b, 'x': b, 'y': d, 'z': b}),
      ty(t, {'w': b, 'x': b, 'y': d, 'z': c}),
      ty(t, {'w': b, 'x': b, 'y': d, 'z': d}),
      ty(t, {'w': b, 'x': c, 'y': b, 'z': b}),
      ty(t, {'w': b, 'x': c, 'y': b, 'z': c}),
      ty(t, {'w': b, 'x': c, 'y': b, 'z': d}),
      ty(t, {'w': b, 'x': c, 'y': c, 'z': b}),
      ty(t, {'w': b, 'x': c, 'y': c, 'z': c}),
      ty(t, {'w': b, 'x': c, 'y': c, 'z': d}),
      ty(t, {'w': b, 'x': c, 'y': d, 'z': b}),
      ty(t, {'w': b, 'x': c, 'y': d, 'z': c}),
      ty(t, {'w': b, 'x': c, 'y': d, 'z': d}),
      ty(t, {'w': b, 'x': d, 'y': b, 'z': b}),
      ty(t, {'w': b, 'x': d, 'y': b, 'z': c}),
      ty(t, {'w': b, 'x': d, 'y': b, 'z': d}),
      ty(t, {'w': b, 'x': d, 'y': c, 'z': b}),
      ty(t, {'w': b, 'x': d, 'y': c, 'z': c}),
      ty(t, {'w': b, 'x': d, 'y': c, 'z': d}),
      ty(t, {'w': b, 'x': d, 'y': d, 'z': b}),
      ty(t, {'w': b, 'x': d, 'y': d, 'z': c}),
      ty(t, {'w': b, 'x': d, 'y': d, 'z': d}),
      ty(t, {'w': c, 'x': b, 'y': b, 'z': b}),
      ty(t, {'w': c, 'x': b, 'y': b, 'z': c}),
      ty(t, {'w': c, 'x': b, 'y': b, 'z': d}),
      ty(t, {'w': c, 'x': b, 'y': c, 'z': b}),
      ty(t, {'w': c, 'x': b, 'y': c, 'z': c}),
      ty(t, {'w': c, 'x': b, 'y': c, 'z': d}),
      ty(t, {'w': c, 'x': b, 'y': d, 'z': b}),
      ty(t, {'w': c, 'x': b, 'y': d, 'z': c}),
      ty(t, {'w': c, 'x': b, 'y': d, 'z': d}),
      ty(t, {'w': c, 'x': c, 'y': b, 'z': b}),
      ty(t, {'w': c, 'x': c, 'y': b, 'z': c}),
      ty(t, {'w': c, 'x': c, 'y': b, 'z': d}),
      ty(t, {'w': c, 'x': c, 'y': c, 'z': b}),
      ty(t, {'w': c, 'x': c, 'y': c, 'z': c}),
      ty(t, {'w': c, 'x': c, 'y': c, 'z': d}),
      ty(t, {'w': c, 'x': c, 'y': d, 'z': b}),
      ty(t, {'w': c, 'x': c, 'y': d, 'z': c}),
      ty(t, {'w': c, 'x': c, 'y': d, 'z': d}),
      ty(t, {'w': c, 'x': d, 'y': b, 'z': b}),
      ty(t, {'w': c, 'x': d, 'y': b, 'z': c}),
      ty(t, {'w': c, 'x': d, 'y': b, 'z': d}),
      ty(t, {'w': c, 'x': d, 'y': c, 'z': b}),
      ty(t, {'w': c, 'x': d, 'y': c, 'z': c}),
      ty(t, {'w': c, 'x': d, 'y': c, 'z': d}),
      ty(t, {'w': c, 'x': d, 'y': d, 'z': b}),
      ty(t, {'w': c, 'x': d, 'y': d, 'z': c}),
      ty(t, {'w': c, 'x': d, 'y': d, 'z': d}),
      ty(t, {'w': d, 'x': b, 'y': b, 'z': b}),
      ty(t, {'w': d, 'x': b, 'y': b, 'z': c}),
      ty(t, {'w': d, 'x': b, 'y': b, 'z': d}),
      ty(t, {'w': d, 'x': b, 'y': c, 'z': b}),
      ty(t, {'w': d, 'x': b, 'y': c, 'z': c}),
      ty(t, {'w': d, 'x': b, 'y': c, 'z': d}),
      ty(t, {'w': d, 'x': b, 'y': d, 'z': b}),
      ty(t, {'w': d, 'x': b, 'y': d, 'z': c}),
      ty(t, {'w': d, 'x': b, 'y': d, 'z': d}),
      ty(t, {'w': d, 'x': c, 'y': b, 'z': b}),
      ty(t, {'w': d, 'x': c, 'y': b, 'z': c}),
      ty(t, {'w': d, 'x': c, 'y': b, 'z': d}),
      ty(t, {'w': d, 'x': c, 'y': c, 'z': b}),
      ty(t, {'w': d, 'x': c, 'y': c, 'z': c}),
      ty(t, {'w': d, 'x': c, 'y': c, 'z': d}),
      ty(t, {'w': d, 'x': c, 'y': d, 'z': b}),
      ty(t, {'w': d, 'x': c, 'y': d, 'z': c}),
      ty(t, {'w': d, 'x': c, 'y': d, 'z': d}),
      ty(t, {'w': d, 'x': d, 'y': b, 'z': b}),
      ty(t, {'w': d, 'x': d, 'y': b, 'z': c}),
      ty(t, {'w': d, 'x': d, 'y': b, 'z': d}),
      ty(t, {'w': d, 'x': d, 'y': c, 'z': b}),
      ty(t, {'w': d, 'x': d, 'y': c, 'z': c}),
      ty(t, {'w': d, 'x': d, 'y': c, 'z': d}),
      ty(t, {'w': d, 'x': d, 'y': d, 'z': b}),
      ty(t, {'w': d, 'x': d, 'y': d, 'z': c}),
      ty(t, {'w': d, 'x': d, 'y': d, 'z': d}),
    ]);
  });

  group('sealed transitive subtypes |', () {
    //     (A)
    //     / \
    //   (B) (C)
    //   / \   \
    //  D   E   F
    var env = TestEnvironment();
    var a = env.createClass('A', isSealed: true);
    var b = env.createClass('B', isSealed: true, inherits: [a]);
    var c = env.createClass('C', isSealed: true, inherits: [a]);
    var d = env.createClass('D', inherits: [b]);
    var e = env.createClass('E', inherits: [b]);
    var f = env.createClass('F', inherits: [c]);

    var t = env.createClass('T', fields: {'x': a, 'y': a});
    expectExhaustiveOnlyAll(t, [
      ty(t, {'x': a, 'y': a}),
    ]);

    expectExhaustiveOnlyAll(t, [
      ty(t, {'x': b, 'y': b}),
      ty(t, {'x': b, 'y': c}),
      ty(t, {'x': c, 'y': b}),
      ty(t, {'x': c, 'y': c}),
    ]);

    expectExhaustiveOnlyAll(t, [
      ty(t, {'x': b, 'y': d}),
      ty(t, {'x': b, 'y': e}),
      ty(t, {'x': b, 'y': f}),
      ty(t, {'x': c, 'y': d}),
      ty(t, {'x': c, 'y': e}),
      ty(t, {'x': c, 'y': f}),
    ]);
  });

  group('unsealed subtypes |', () {
    //    A
    //   / \
    //  B   C
    var env = TestEnvironment();
    var a = env.createClass('A');
    var b = env.createClass('B', inherits: [a]);
    var c = env.createClass('C', inherits: [a]);

    // Not exhaustive even when known subtypes covered.
    var t = env.createClass('T', fields: {'x': a, 'y': a});
    expectNeverExhaustive(t, [
      ty(t, {'x': b, 'y': b}),
      ty(t, {'x': b, 'y': c}),
      ty(t, {'x': c, 'y': b}),
      ty(t, {'x': c, 'y': c}),
    ]);

    // Exhaustive if field static type is a covered subtype.
    var u = env.createClass('U', fields: {'x': b, 'y': c});
    expectExhaustiveOnlyAll(u, [
      ty(u, {'x': b, 'y': c}),
    ]);
  });

  group('different fields |', () {
    //   (A)
    //   / \
    //  B   C
    var env = TestEnvironment();
    var a = env.createClass('A', isSealed: true);
    var b = env.createClass('B', inherits: [a]);
    var c = env.createClass('C', inherits: [a]);
    var t = env.createClass('T', fields: {'x': a, 'y': a, 'z': a});

    expectNeverExhaustive(t, [
      ty(t, {'x': b}),
      ty(t, {'y': b}),
      ty(t, {'z': b}),
    ]);

    expectExhaustiveOnlyAll(t, [
      ty(t, {'x': b, 'y': a}),
      ty(t, {'x': c, 'z': a}),
    ]);

    expectExhaustiveOnlyAll(t, [
      ty(t, {'x': b, 'y': b}),
      ty(t, {'x': b, 'y': c}),
      ty(t, {'x': c, 'y': b}),
      ty(t, {'x': c, 'y': c}),
    ]);
  });

  group('field types |', () {
    //   (A)
    //   / \
    //  B   C
    var env = TestEnvironment();
    var a = env.createClass('A', isSealed: true);
    var b = env.createClass('B', inherits: [a]);
    var c = env.createClass('C', inherits: [a]);
    var t = env.createClass('T', fields: {'x': a, 'y': b, 'z': c});

    expectExhaustiveOnlyAll(t, [
      ty(t, {'x': a, 'y': b, 'z': c}),
    ]);

    expectExhaustiveOnlyAll(t, [
      ty(t, {'x': b}),
      ty(t, {'x': c}),
    ]);

    expectExhaustiveOnlyAll(t, [
      ty(t, {'y': b}),
    ]);

    expectExhaustiveOnlyAll(t, [
      ty(t, {'z': c}),
    ]);
  });
}
