// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:compiler/src/native/native.dart';
import 'package:compiler/src/js/js.dart' as js;

void test(String source, NativeThrowBehavior expectedThrowBehavior) {
  js.Template template = js.js.parseForeignJS(source);
  NativeThrowBehavior throwBehavior =
      new ThrowBehaviorVisitor().analyze(template.ast);
  Expect.equals(expectedThrowBehavior, throwBehavior, 'source "$source"');
}

void main() {
  final MAY = NativeThrowBehavior.MAY;
  final MUST = NativeThrowBehavior.MUST;
  final NEVER = NativeThrowBehavior.NEVER;
  final NULL_NSM = NativeThrowBehavior.MAY_THROW_ONLY_ON_FIRST_ARGUMENT_ACCESS;

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
  test('Object', NEVER);

  test('typeof #', NEVER);
  test('typeof console', NEVER);
  test('typeof foo.#', MAY);
  test('typeof #.foo', NULL_NSM);

  test('throw 123', MUST);
  test('throw #', MUST);
  test('throw #.x', MUST); // Could be better: is also an NSM guard.
  test('throw #.x = 123', MUST);
}
