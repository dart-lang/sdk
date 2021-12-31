// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer_utilities/check/check.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../util/ast_check.dart';
import '../../util/token_check.dart';
import 'parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtraneousModifierTest);
  });
}

@reflectiveTest
class ExtraneousModifierTest extends ParserDiagnosticsTest {
  test_simpleFormalParameter_const() async {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(const a);
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXTRANEOUS_MODIFIER, 14, 5),
    ]);
    check(parseResult.findNode.simpleFormalParameter('a);'))
      ..keyword.isKeywordConst
      ..type.isNull
      ..identifier.isNotNull;
  }

  test_simpleFormalParameter_var() async {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(var a);
}
''');
    parseResult.assertNoErrors();
    check(parseResult.findNode.simpleFormalParameter('a);'))
      ..keyword.isKeywordVar
      ..type.isNull
      ..identifier.isNotNull;
  }

  test_superFormalParameter_var() async {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(var super.a);
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXTRANEOUS_MODIFIER, 14, 3),
    ]);
    check(parseResult.findNode.superFormalParameter('super.a'))
      ..keyword.isKeywordVar
      ..superKeyword.isKeywordSuper
      ..type.isNull
      ..identifier.isNotNull
      ..typeParameters.isNull
      ..parameters.isNull;
  }
}
