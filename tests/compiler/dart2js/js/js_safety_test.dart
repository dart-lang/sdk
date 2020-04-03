// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';
import 'package:compiler/src/js/js.dart' as js;
import 'package:compiler/src/js/placeholder_safety.dart';

void test(String source, int expected, {List notNull: const []}) {
  var predicate = (int pos) => !notNull.contains(pos);
  js.Template template = js.js.parseForeignJS(source);
  int actual = PlaceholderSafetyAnalysis.analyze(template.ast, predicate);
  Expect.equals(expected, actual, 'source: "$source", notNull: $notNull');
}

void main() {
  test('0', 0);

  test('#.x', 1);
  test('!!#.x', 1);
  test('#.x + 1', 1);
  test('1 + #.x', 1);
  test('#[#] + 2', 2);
  test('2 + #[#]', 2);
  test('(# & #) >>> 0', 2);

  test('#.a + #.b + #.c', 1);
  test('#.b + #.b + #.c', 2, notNull: [0]);
  test('#.c + #.b + #.c', 3, notNull: [0, 1]);
  test('#.d + #.b + #.c', 1, notNull: [1]);

  test('typeof(#) == "string"', 1);
  test('"object" === typeof #', 1);

  test('# == 1 || # == 2 || # == 3', 1);
  test('# != 1 && # != 2 && # != 3', 1);

  test('#.x == 1 || # == 1', 1);
  test('# == 1 || #.x == 1', 1);

  test('(# || 1, #)', 1); // Could also be 2.

  test('(#, null.a, #)', 1);
  test('(#, undefined.a, #)', 1);
  test('(#, (void 0).a, #)', 1);
  test('(#, "a".a, #)', 2);
  test('((#, "a").a, #)', 2);

  test('#[#][#][#][#]', 2);
  test('#[#][#][#][#]', 3, notNull: [0]);
  test('#[#][#][#][#]', 3, notNull: [0, 1, 2, 3]);

  test('#.a = #', 2);
  test('#.a.b = #', 1);
  test('#[1] = #', 2);
  test('#[1][1] = #', 1);

  test('#.a = #.a + #.a + #.a', 2);
  test('#.a = #.a + #.a + #.a', 2, notNull: [0]);
  test('#.a = #.a + #.a + #.a', 3, notNull: [1]);
  test('#.a = #.a + #.a + #.a', 4, notNull: [1, 2]);

  test('#()', 1);
  test('#(#, #)', 3);
  test('#.f(#, #)', 1);
  test('#.f(#, #)', 3, notNull: [0]);

  test('(#.a+=1, #)', 1);
  test('(#.a++, #)', 1);
  test('(++#.a, #)', 1);

  test('new Array(#)', 1);
  test('new Date(#)', 1);
  test('new Function(#)', 1);
  test('new RegExp(#)', 1);
  test('new xxx(#)', 0);
  test('String(#)', 1);
  test('# in #', 2);

  test('Object.keys(#)', 1);

  test('typeof #', 1);
  test('typeof #.foo', 1);
  test('typeof foo.#', 0);
  test('typeof Array.#', 1);

  test('throw #', 1);
  test('throw #.x', 1);

  test('(function(){})()', 0);
  test('(function(a,b){#})(#, #)', 0);
  // Placeholders in an immediate call are ok.
  test('(function(a,b){a++;b++;return a+b})(#, #)', 2);

  test('# ? # : #', 1);
  test('(# ? 1 : #, #)', 1);
  test('(# ? # : 2, #)', 1);
  test('(# ? 1 : 2, #)', 1); // Could also be 4.

  test('{A:#, B:#, C:#}', 3);
  test('[#,#,#,#]', 4);
  test('[,,,,#,#,,,]', 2);
}
