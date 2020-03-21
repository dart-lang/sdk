// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';
import 'package:compiler/src/native/behavior.dart';
import 'package:compiler/src/native/js.dart';
import 'package:compiler/src/js/js.dart' as js;

void test(String source, NativeThrowBehavior expectedThrowBehavior) {
  js.Template template = js.js.parseForeignJS(source);
  NativeThrowBehavior throwBehavior =
      new ThrowBehaviorVisitor().analyze(template.ast);
  Expect.equals(expectedThrowBehavior, throwBehavior, 'source "$source"');
}

void main() {
  final MAY = NativeThrowBehavior.MAY;
  final NEVER = NativeThrowBehavior.NEVER;
  final NULL_NSM = NativeThrowBehavior.NULL_NSM;
  final NULL_NSM_THEN_MAY = NativeThrowBehavior.NULL_NSM_THEN_MAY;

  test('0', NEVER);
  test('void 0', NEVER);
  test('#', NEVER);
  test('void #', NEVER);
  test('# + 1', NEVER);
  test('!#', NEVER);
  test('!!#', NEVER);
  test('~#', NEVER);
  test('~~#', NEVER);
  test('-#', NEVER);
  test('+#', NEVER);
  test('-(-#)', NEVER);
  test('+#', NEVER);

  test('# * #', NEVER);
  test('# / #', NEVER);
  test('# % #', NEVER);
  test('# + #', NEVER);
  test('# - #', NEVER);

  test('# << #', NEVER);
  test('# >> #', NEVER);
  test('# >>> #', NEVER);

  test('# < #', NEVER);
  test('# > #', NEVER);
  test('# <= #', NEVER);
  test('# >= #', NEVER);

  test('# == #', NEVER);
  test('# != #', NEVER);
  test('# === #', NEVER);
  test('# !== #', NEVER);

  test('# & #', NEVER);
  test('# ^ #', NEVER);
  test('# | #', NEVER);

  test('# , #', NEVER);

  test('typeof(#) == "string"', NEVER);
  test('"object" === typeof #', NEVER);

  test('# == 1 || # == 2 || # == 3', NEVER);
  test('# != 1 && # != 2 && # != 3', NEVER);

  test('#.x', NULL_NSM);
  test('!!#.x', NULL_NSM);
  test('#.x + 1', NULL_NSM);
  test('1 + #.x', NULL_NSM);
  test('#[#] + 2', NULL_NSM);
  test('2 + #[#]', NULL_NSM);

  test('#.x == 1 || # == 1', NULL_NSM);
  test('# == 1 || #.x == 1', MAY);

  test('#[#][#]', MAY);
  test('# + #[#]', MAY);
  test('#()', MAY);
  test('(function(){})()', MAY);

  test('new Date(#)', MAY);
  test('# in #', MAY);

  test('console', MAY);
  test('Array', NEVER);
  test('Math', NEVER);
  test('Object', NEVER);

  test('typeof #', NEVER);
  test('typeof console', NEVER);
  test('typeof foo.#', MAY);
  test('typeof #.foo', NULL_NSM);

  test('throw 123', MAY);
  test('throw #', MAY);
  test('throw #.x', NULL_NSM_THEN_MAY);
  test('throw #.x = 123', MAY);

  test('#.f()', NULL_NSM_THEN_MAY);
  test('#.f(#, #)', NULL_NSM_THEN_MAY);
  test('#[#](#, #)', NULL_NSM_THEN_MAY);
  test('#[f()](#, #)', MAY); // f() evaluated before

  test('[]', NEVER);
  test('[,,6,,,]', NEVER);
  test('[#.f()]', NULL_NSM_THEN_MAY);
  test('[,,#.f(),,f(),,]', NULL_NSM_THEN_MAY);
  test('[,,f(),,#.f(),,]', MAY);

  test('{}', NEVER);
  test('{one: 1}', NEVER);
  test('{one: #.f()}', NULL_NSM_THEN_MAY);
  test('{one: #.f(), two: f()}', NULL_NSM_THEN_MAY);
  test('{one: f(), two: #.f()}', MAY);
}
