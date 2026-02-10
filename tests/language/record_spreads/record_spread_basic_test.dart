// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=record-spreads

/// Test basic record spreading functionality.

import "package:expect/expect.dart";

void main() {
  // Spread positional-only record.
  var pair = (1, 2);
  var triple = (...pair, 3);
  Expect.equals(1, triple.$1);
  Expect.equals(2, triple.$2);
  Expect.equals(3, triple.$3);

  // Spread named-only record.
  var named = (a: 1, b: 2);
  var spreadNamed = (...named);
  Expect.equals(1, spreadNamed.a);
  Expect.equals(2, spreadNamed.b);

  // Spread mixed record (positional + named).
  var mixed = (1, a: 2);
  var spreadMixed = (...mixed);
  Expect.equals(1, spreadMixed.$1);
  Expect.equals(2, spreadMixed.a);

  // Spread with additional positional fields.
  var base = (1, 2);
  var extended = (...base, 3, 4);
  Expect.equals(1, extended.$1);
  Expect.equals(2, extended.$2);
  Expect.equals(3, extended.$3);
  Expect.equals(4, extended.$4);

  // Spread with additional named fields.
  var point = (1, 2);
  var colorPoint = (...point, color: 'red');
  Expect.equals(1, colorPoint.$1);
  Expect.equals(2, colorPoint.$2);
  Expect.equals('red', colorPoint.color);

  // Multiple spreads.
  var a = (1, 2);
  var b = (3, 4);
  var combined = (...a, ...b);
  Expect.equals(1, combined.$1);
  Expect.equals(2, combined.$2);
  Expect.equals(3, combined.$3);
  Expect.equals(4, combined.$4);

  // Multiple spreads with named fields from different sources.
  var coords = (x: 1, y: 2);
  var style = (color: 'blue');
  var styled = (...coords, ...style);
  Expect.equals(1, styled.x);
  Expect.equals(2, styled.y);
  Expect.equals('blue', styled.color);

  // Spread of single-element record.
  var single = (42,);
  var fromSingle = (...single, 99);
  Expect.equals(42, fromSingle.$1);
  Expect.equals(99, fromSingle.$2);

  // Spread mixed with both positional and named additional fields.
  var pos = (10, 20);
  var full = (...pos, 30, name: 'test');
  Expect.equals(10, full.$1);
  Expect.equals(20, full.$2);
  Expect.equals(30, full.$3);
  Expect.equals('test', full.name);

  // Spread of empty-like scenarios: named-only spread + positional.
  var namedOnly = (x: 100);
  var withPositional = (1, ...namedOnly);
  Expect.equals(1, withPositional.$1);
  Expect.equals(100, withPositional.x);

  // Nested spread: spread a record that was itself built with a spread.
  var inner = (1, 2);
  var middle = (...inner, 3);
  var outer = (...middle, 4);
  Expect.equals(1, outer.$1);
  Expect.equals(2, outer.$2);
  Expect.equals(3, outer.$3);
  Expect.equals(4, outer.$4);
}
