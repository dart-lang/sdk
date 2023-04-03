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
      expectReportErrors(env, a, [a]);
      expectReportErrors(env, b, [a]);
      expectReportErrors(env, d, [a]);

      // Case matching subtype doesn't cover supertype.
      expectReportErrors(env, a, [b], 'A is not exhaustively matched by B.');
      expectReportErrors(env, b, [b]);
      expectReportErrors(env, d, [b]);
      expectReportErrors(env, e, [b]);

      // Matching subtypes of sealed type is exhaustive.
      expectReportErrors(env, a, [b, c]);
      expectReportErrors(env, a, [d, e, f]);
      expectReportErrors(env, a, [b, f]);
      expectReportErrors(
          env, a, [c, d], 'A is not exhaustively matched by C|D.');
      expectReportErrors(
          env, f, [g, h], 'F is not exhaustively matched by G|H.');
    });

    test('unreachable case', () {
      // Same type.
      expectReportErrors(env, b, [b, b], 'Case #2 B is unreachable.');

      // Previous case is supertype.
      expectReportErrors(env, b, [a, b], 'Case #2 B is unreachable.');

      // Previous subtype cases cover sealed supertype.
      expectReportErrors(env, a, [b, c, a], 'Case #3 A is unreachable.');
      expectReportErrors(env, a, [d, e, f, a], 'Case #4 A is unreachable.');
      expectReportErrors(env, a, [b, f, a], 'Case #3 A is unreachable.');
      expectReportErrors(env, a, [c, d, a]);

      // Previous subtype cases do not cover unsealed supertype.
      expectReportErrors(env, f, [g, h, f]);
    });

    test('covered record destructuring |', () {
      var r = env.createRecordType({x: a, y: a, z: a});

      // Wider field is not covered.
      expectReportErrors(env, r, [
        ty(r, {x: b}),
        ty(r, {x: a}),
      ]);

      // Narrower field is covered.
      expectReportErrors(
          env,
          r,
          [
            ty(r, {x: a}),
            ty(r, {x: b}),
          ],
          'Case #2 (x: B, y: A, z: A) is unreachable.');
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
      expectReportErrors(env, a.nullable, [b, d, e],
          'A? is not exhaustively matched by B|D|E.');

      // Can cover null with any nullable subtype.
      expectReportErrors(env, a.nullable, [b.nullable, c]);
      expectReportErrors(env, a.nullable, [b, c.nullable]);
      expectReportErrors(env, a.nullable, [b, d.nullable, e]);
      expectReportErrors(env, a.nullable, [b, d, e.nullable]);

      // Can cover null with a null space.
      expectReportErrors(env, a.nullable, [b, c, StaticType.nullType]);
      expectReportErrors(env, a.nullable, [b, d, e, StaticType.nullType]);

      // Nullable covers the non-null.
      expectReportErrors(
          env, a.nullable, [a.nullable, a], 'Case #2 A is unreachable.');
      expectReportErrors(
          env, b.nullable, [a.nullable, b], 'Case #2 B is unreachable.');

      // Nullable covers null.
      expectReportErrors(env, a.nullable, [a.nullable, StaticType.nullType],
          'Case #2 Null is unreachable.');
      expectReportErrors(env, b.nullable, [a.nullable, StaticType.nullType],
          'Case #2 Null is unreachable.');
    });
  });
}

void expectReportErrors(ObjectPropertyLookup objectFieldLookup,
    StaticType valueType, List<Object> cases,
    [String errors = '']) {
  expect(
      reportErrors(objectFieldLookup, valueType, parseSpaces(cases)).join('\n'),
      errors);
}
