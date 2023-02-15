// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'env.dart';
import 'utils.dart';

void main() {
  group('nested records', () {
    //   (A)
    //   / \
    //  B   C
    var env = TestEnvironment();
    var a = env.createClass('A', isSealed: true);
    var b = env.createClass('B', inherits: [a]);
    var c = env.createClass('C', inherits: [a]);
    var t = env.createClass('T', fields: {'x': a, 'y': b});
    var u = env.createClass('U', fields: {'w': t, 'z': t});

    expectExhaustiveOnlyAll(u, [
      rec(w: rec(x: a), z: t),
    ]);

    expectExhaustiveOnlyAll(u, [
      rec(w: rec(x: a, y: a), z: rec(x: a, y: a)),
    ]);

    expectExhaustiveOnlyAll(u, [
      rec(w: rec(x: a, y: b), z: rec(x: a, y: b)),
    ]);

    expectExhaustiveOnlyAll(u, [
      rec(w: rec(x: b), z: t),
      rec(w: rec(x: c), z: t),
    ]);

    expectExhaustiveOnlyAll(u, [
      rec(w: rec(x: b, y: b), z: rec(x: b, y: b)),
      rec(w: rec(x: b, y: b), z: rec(x: c, y: b)),
      rec(w: rec(x: c, y: b), z: rec(x: b, y: b)),
      rec(w: rec(x: c, y: b), z: rec(x: c, y: b)),
    ]);
  });

  group('nested with different fields of same name', () {
    // A B C D
    var env = TestEnvironment();
    var a = env.createClass('A');
    var b = env.createClass('B', fields: {'x': a});
    var c = env.createClass('C', fields: {'x': b});
    var d = env.createClass('D', fields: {'x': c});

    expectExhaustiveOnlyAll(d, [
      rec(x: rec(x: rec(x: a))),
    ]);
  });
}
