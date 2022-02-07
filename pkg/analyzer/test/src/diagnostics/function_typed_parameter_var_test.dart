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
    defineReflectiveTests(FunctionTypedParameterVarTest);
  });
}

@reflectiveTest
class FunctionTypedParameterVarTest extends ParserDiagnosticsTest {
  test_superFormalParameter_var_functionTyped() async {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(var super.a<T>());
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR, 14, 3),
    ]);
    check(parseResult.findNode.superFormalParameter('super.a'))
      ..keyword.isNull
      ..superKeyword.isKeywordSuper
      ..type.isNull
      ..identifier.isNotNull
      ..typeParameters.isNotNull.typeParameters.hasLength(1)
      ..parameters.isNotNull;
  }
}
