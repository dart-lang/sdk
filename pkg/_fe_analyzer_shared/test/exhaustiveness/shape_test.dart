// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/key.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/shape.dart';
import 'package:test/test.dart';

import 'env.dart';

void main() {
  group('isSubshapeOf() |', () {
    var env = TestEnvironment();
    var a = env.createClass('A');
    var b = env.createClass('B', inherits: [a]);
    var b2 = env.createClass('B2', inherits: [a]);
    var c = env.createClass('C', inherits: [b]);
    var d = env.createClass('D', inherits: [c]);

    test('subshape includes self', () {
      expect(a.isSubshapeOf(a), isTrue);
      expect(b.isSubshapeOf(b), isTrue);
      expect(c.isSubshapeOf(c), isTrue);
      expect(d.isSubshapeOf(d), isTrue);
    });

    test('immediate', () {
      expect(a.isSubshapeOf(b), isFalse);
      expect(b.isSubshapeOf(a), isTrue);

      expect(b.isSubshapeOf(c), isFalse);
      expect(c.isSubshapeOf(b), isTrue);

      expect(c.isSubshapeOf(d), isFalse);
      expect(d.isSubshapeOf(c), isTrue);
    });

    test('transitive', () {
      expect(a.isSubshapeOf(c), isFalse);
      expect(c.isSubshapeOf(a), isTrue);

      expect(b.isSubshapeOf(d), isFalse);
      expect(d.isSubshapeOf(b), isTrue);

      expect(a.isSubshapeOf(d), isFalse);
      expect(d.isSubshapeOf(a), isTrue);
    });

    test('unrelated', () {
      expect(b.isSubshapeOf(b2), isFalse);
      expect(b2.isSubshapeOf(b), isFalse);

      expect(c.isSubshapeOf(b2), isFalse);
      expect(b2.isSubshapeOf(c), isFalse);

      expect(d.isSubshapeOf(b2), isFalse);
      expect(b2.isSubshapeOf(d), isFalse);
    });

    test('multiple supershapes', () {
      //      I1   I2   I3
      //        \ /  \ /
      //        I12  I23
      //           \/
      //          I123
      var i1 = env.createClass('I1');
      var i2 = env.createClass('I2');
      var i3 = env.createClass('I3');
      var i12 = env.createClass('I12', inherits: [i1, i2]);
      var i23 = env.createClass('I23', inherits: [i2, i3]);
      var i123 = env.createClass('I123', inherits: [i12, i23]);

      expect(i1.isSubshapeOf(i2), isFalse);
      expect(i2.isSubshapeOf(i1), isFalse);
      expect(i2.isSubshapeOf(i3), isFalse);
      expect(i3.isSubshapeOf(i2), isFalse);
      expect(i1.isSubshapeOf(i3), isFalse);
      expect(i3.isSubshapeOf(i1), isFalse);

      expect(i1.isSubshapeOf(i12), isFalse);
      expect(i12.isSubshapeOf(i1), isTrue);
      expect(i2.isSubshapeOf(i12), isFalse);
      expect(i12.isSubshapeOf(i2), isTrue);
      expect(i3.isSubshapeOf(i12), isFalse);
      expect(i12.isSubshapeOf(i3), isFalse);

      expect(i1.isSubshapeOf(i23), isFalse);
      expect(i23.isSubshapeOf(i1), isFalse);
      expect(i2.isSubshapeOf(i23), isFalse);
      expect(i23.isSubshapeOf(i2), isTrue);
      expect(i3.isSubshapeOf(i23), isFalse);
      expect(i23.isSubshapeOf(i3), isTrue);

      expect(i1.isSubshapeOf(i123), isFalse);
      expect(i123.isSubshapeOf(i1), isTrue);
      expect(i2.isSubshapeOf(i123), isFalse);
      expect(i123.isSubshapeOf(i2), isTrue);
      expect(i3.isSubshapeOf(i123), isFalse);
      expect(i123.isSubshapeOf(i3), isTrue);
      expect(i12.isSubshapeOf(i123), isFalse);
      expect(i123.isSubshapeOf(i12), isTrue);
      expect(i23.isSubshapeOf(i123), isFalse);
      expect(i123.isSubshapeOf(i23), isTrue);
    });
  });

  test('nullable', () {
    var env = TestEnvironment();
    var a = env.createClass('A');
    var b = env.createClass('B', inherits: [a]);

    expect(Shape.nullShape.isSubshapeOf(a), isFalse);
    expect(Shape.nullShape.isSubshapeOf(b), isFalse);
    expect(Shape.nullShape.isSubshapeOf(a.nullable), isTrue);
    expect(Shape.nullShape.isSubshapeOf(b.nullable), isTrue);

    expect(a.isSubshapeOf(Shape.nullShape), isFalse);
    expect(b.isSubshapeOf(Shape.nullShape), isFalse);
    expect(a.nullable.isSubshapeOf(Shape.nullShape), isFalse);
    expect(b.nullable.isSubshapeOf(Shape.nullShape), isFalse);

    expect(a.isSubshapeOf(a.nullable), isTrue);
    expect(a.nullable.isSubshapeOf(a), isFalse);
    expect(a.nullable.isSubshapeOf(a.nullable), isTrue);

    expect(a.isSubshapeOf(b.nullable), isFalse);
    expect(a.nullable.isSubshapeOf(b), isFalse);
    expect(a.nullable.isSubshapeOf(b.nullable), isFalse);

    expect(b.isSubshapeOf(a.nullable), isTrue);
    expect(b.nullable.isSubshapeOf(a), isFalse);
    expect(b.nullable.isSubshapeOf(a.nullable), isTrue);
  });

  test('properties', () {
    var env = TestEnvironment();
    var a = env.createClass('A');
    var b = env.createClass('B');
    var c = env.createClass('C', fields: {'x': a, 'y': b});
    var d = env.createClass('D', fields: {'w': a});
    var e = env.createClass('E', inherits: [c, d], fields: {'z': b});

    expect(a.properties, isEmpty);
    expect(b.properties, isEmpty);

    expect(c.properties, hasLength(2));
    expect(c.properties[NameKey('x')], a);
    expect(c.properties[NameKey('y')], b);

    // Properties are inherited.
    expect(e.properties, hasLength(4));
    expect(e.properties[NameKey('x')], a);
    expect(e.properties[NameKey('y')], b);
    expect(e.properties[NameKey('w')], a);
    expect(e.properties[NameKey('z')], b);

    // Overridden property shapes win.
    var f = env.createClass('F', fields: {'x': a});
    var g = env.createClass('G', inherits: [f], fields: {'x': b});
    expect(g.properties, hasLength(1));
    expect(g.properties[NameKey('x')], b);
  });

  test('subshapes', () {
    var env = TestEnvironment();
    var a = env.createClass('A', isSealed: true);
    var b = env.createClass('B', inherits: [a]);
    var c = env.createClass('C', inherits: [a]);
    env.createClass('D', inherits: [c]);
    var e = env.createClass('E', isSealed: true, inherits: [a]);
    var f = env.createClass('F', inherits: [e]);

    // Gets subshapes for sealed shape.
    var aSubshapes = a.getSubshapes(const {}).toList();
    expect(
      aSubshapes,
      unorderedEquals([
        WrappedShape(b, a),
        WrappedShape(c, a),
        WrappedShape(e, a),
      ]),
    );

    // Unsealed subshape.
    var cSubshapes = c.getSubshapes(const {}).toList();
    expect(cSubshapes, unorderedEquals([]));

    // Sealed subshape.
    var eSubshapes = e.getSubshapes(const {}).toList();
    expect(eSubshapes, unorderedEquals([WrappedShape(f, e)]));
  });
}
