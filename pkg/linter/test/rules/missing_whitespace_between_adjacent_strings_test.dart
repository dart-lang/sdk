// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingWhitespaceBetweenAdjacentStringsTest);
  });
}

@reflectiveTest
class MissingWhitespaceBetweenAdjacentStringsTest extends LintRuleTest {
  @override
  String get lintRule => 'missing_whitespace_between_adjacent_strings';

  test_argumentToMatches() async {
    await assertNoDiagnostics(r'''
var x = matches('(\n)+' '(\n)+' '(\n)+');
void matches(String s) {}
''');
  }

  test_argumentToRegExpConstructor() async {
    await assertNoDiagnostics(r'''
var x = RegExp('(\n)+' '(\n)+' '(\n)+');
''');
  }

  test_extraPositionalArgument() async {
    await assertDiagnostics(r'''
void f() {
  new Unresolved('aaa' 'bbb');
}
''', [
      // No lint
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 17, 10),
    ]);
  }

  test_firstPartEndsWithCarriageReturn() async {
    await assertNoDiagnostics(r'''
var x= 'long line\r' 'is long';
''');
  }

  test_firstPartEndsWithSpace() async {
    await assertNoDiagnostics(r'''
var x = 'long line ' 'is long';
''');
  }

  test_firstPartEndsWithTab() async {
    await assertNoDiagnostics(r'''
var x = 'long line\t' 'is long';
''');
  }

  test_leftPartEndsWithInteroplation() async {
    await assertNoDiagnostics(r'''
var f = 1;
var x = 'a $f' 'b';
''');
  }

  test_leftPartEndsWithInterpolation() async {
    await assertNoDiagnostics(r'''
var x = '${1 == 2 ? 'Hello ' : ''}' 'world';
''');
  }

  test_leftPartEndsWithNewline() async {
    await assertNoDiagnostics(r'''
var x = 'long line\n' 'is long';
''');
  }

  test_leftPartEndsWithOpenParenthesis() async {
    await assertNoDiagnostics(r'''
var x = '${1 + 1}(' 'long line)';
''');
  }

  test_leftPartEndsWithSpace_leftPartHasInterpolation() async {
    await assertNoDiagnostics(r'''
var f = 1;
var x = 'long $f line ' 'is long';
''');
  }

  test_leftPartHasNoSpaces() async {
    await assertNoDiagnostics(r'''
var x = 'longLineWithoutSpaceCouldBe' 'AnURL';
''');
  }

  test_noSpacesBetweenStringParts() async {
    await assertDiagnostics(r'''
var x = 'long line' 'is long';
''', [
      lint(8, 11),
    ]);
  }

  test_noSpacesBetweenStringParts_leftHasInterpolation() async {
    await assertDiagnostics(r'''
var f = 1;
var x = 'long $f line' 'is long';
''', [
      lint(19, 14),
    ]);
  }

  test_rightPartStartsWithInterpolation() async {
    await assertNoDiagnostics(r'''
var f = 1;
var x = 'a' '$f b';
''');
  }

  test_secondPartStartsWithSpace() async {
    await assertNoDiagnostics(r'''
var x = 'long line' ' is long';
''');
  }

  test_secondPartStartsWithSpace_eachHasInterpolation_doubleQuotes() async {
    await assertNoDiagnostics(r'''
var f = 1;
var x = "a $f b" " c$f";
''');
  }
}
