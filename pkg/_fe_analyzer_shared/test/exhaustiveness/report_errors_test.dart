// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/exhaustive.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';
import 'package:test/test.dart';

import 'env.dart';
import 'utils.dart';

void main() {
  var x = 'x';
  var y = 'y';
  var z = 'z';

  group('sealed | ', () {
    // Here, "(_)" means "sealed". A bare name is unsealed.
    //
    //     (A)
    //     / \
    //   (B) (C)
    //   / \   \
    //  D   E   F
    //         / \
    //        G   H
    var env = TestEnvironment();
    var a = env.createClass('A', isSealed: true);
    var b = env.createClass('B', isSealed: true, inherits: [a]);
    var c = env.createClass('C', isSealed: true, inherits: [a]);
    var d = env.createClass('D', inherits: [b]);
    var e = env.createClass('E', inherits: [b]);
    var f = env.createClass('F', inherits: [c]);
    var g = env.createClass('G', inherits: [f]);
    var h = env.createClass('H', inherits: [f]);

    test('exhaustiveness', () {
      // Case matching top type covers all subtypes.
      expectExhaustiveness(env, a, [a]);
      expectExhaustiveness(env, b, [a]);
      expectExhaustiveness(env, d, [a]);

      // Case matching subtype doesn't cover supertype.
      expectExhaustiveness(env, a, [
        b,
      ], errors: 'A is not exhaustively matched by B.');
      expectExhaustiveness(env, b, [b]);
      expectExhaustiveness(env, d, [b]);
      expectExhaustiveness(env, e, [b]);

      // Matching subtypes of sealed type is exhaustive.
      expectExhaustiveness(env, a, [b, c]);
      expectExhaustiveness(env, a, [d, e, f]);
      expectExhaustiveness(env, a, [b, f]);
      expectExhaustiveness(env, a, [
        c,
        d,
      ], errors: 'A is not exhaustively matched by C|D.');
      expectExhaustiveness(env, f, [
        g,
        h,
      ], errors: 'F is not exhaustively matched by G|H.');
    });

    test('unreachable case', () {
      // Same type.
      expectExhaustiveness(env, b, [b, b], errors: 'Case #2 B is unreachable.');

      // Previous case is supertype.
      expectExhaustiveness(env, b, [a, b], errors: 'Case #2 B is unreachable.');

      // Previous subtype cases cover sealed supertype.
      expectExhaustiveness(env, a, [
        b,
        c,
        a,
      ], errors: 'Case #3 A is unreachable.');
      expectExhaustiveness(env, a, [
        d,
        e,
        f,
        a,
      ], errors: 'Case #4 A is unreachable.');
      expectExhaustiveness(env, a, [
        b,
        f,
        a,
      ], errors: 'Case #3 A is unreachable.');
      expectExhaustiveness(env, a, [c, d, a]);

      // Previous subtype cases do not cover unsealed supertype.
      expectExhaustiveness(env, f, [g, h, f]);

      // Guarded case is reachable
      expectExhaustiveness(
        env,
        b,
        [d, e, d],
        caseIsGuarded: [true, false, false],
      );

      // Guarded case is unreachable
      expectExhaustiveness(
        env,
        b,
        [d, e, d],
        caseIsGuarded: [false, false, true],
        errors: 'Case #3 D is unreachable.',
      );
    });

    test('covered record destructuring |', () {
      var r = env.createRecordType({x: a, y: a, z: a});

      // Wider field is not covered.
      expectExhaustiveness(env, r, [
        ty(r, {x: b}),
        ty(r, {x: a}),
      ]);

      // Narrower field is covered.
      expectExhaustiveness(env, r, [
        ty(r, {x: a}),
        ty(r, {x: b}),
      ], errors: 'Case #2 (x: B, y: A, z: A) is unreachable.');
    });

    test('nullable sealed |', () {
      //     (A)
      //     / \
      //    B  (C)
      //       / \
      //      D   E
      var env = TestEnvironment();
      var a = env.createClass('A', isSealed: true);
      var b = env.createClass('B', inherits: [a]);
      var c = env.createClass('C', isSealed: true, inherits: [a]);
      var d = env.createClass('D', inherits: [c]);
      var e = env.createClass('E', inherits: [c]);

      // Must cover null.
      expectExhaustiveness(env, a.nullable, [
        b,
        d,
        e,
      ], errors: 'A? is not exhaustively matched by B|D|E.');

      // Can cover null with any nullable subtype.
      expectExhaustiveness(env, a.nullable, [b.nullable, c]);
      expectExhaustiveness(env, a.nullable, [b, c.nullable]);
      expectExhaustiveness(env, a.nullable, [b, d.nullable, e]);
      expectExhaustiveness(env, a.nullable, [b, d, e.nullable]);

      // Can cover null with a null space.
      expectExhaustiveness(env, a.nullable, [b, c, StaticType.nullType]);
      expectExhaustiveness(env, a.nullable, [b, d, e, StaticType.nullType]);

      // Nullable covers the non-null.
      expectExhaustiveness(env, a.nullable, [
        a.nullable,
        a,
      ], errors: 'Case #2 A is unreachable.');
      expectExhaustiveness(env, b.nullable, [
        a.nullable,
        b,
      ], errors: 'Case #2 B is unreachable.');

      // Nullable covers null.
      expectExhaustiveness(env, a.nullable, [
        a.nullable,
        StaticType.nullType,
      ], errors: 'Case #2 Null is unreachable.');
      expectExhaustiveness(env, b.nullable, [
        a.nullable,
        StaticType.nullType,
      ], errors: 'Case #2 Null is unreachable.');
    });
  });
}

void expectExhaustiveness(
  ObjectPropertyLookup objectFieldLookup,
  StaticType valueType,
  List<Object> cases, {
  List<bool>? caseIsGuarded,
  String errors = '',
}) {
  List<CaseUnreachability> caseUnreachabilities = [];
  var nonExhaustiveness = computeExhaustiveness(
    objectFieldLookup,
    valueType,
    caseIsGuarded ?? List.filled(cases.length, false),
    parseSpaces(cases),
    caseUnreachabilities: caseUnreachabilities,
  );
  expect(
    [
      ...caseUnreachabilities,
      if (nonExhaustiveness != null) nonExhaustiveness,
    ].join('\n'),
    errors,
  );
}
