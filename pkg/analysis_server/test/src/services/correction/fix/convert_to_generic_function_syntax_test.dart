// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferGenericFunctionTypeAliasesTest);
    defineReflectiveTests(UseFunctionTypeSyntaxForParametersTest);
  });
}

@reflectiveTest
class PreferGenericFunctionTypeAliasesTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_GENERIC_FUNCTION_SYNTAX;

  @override
  String get lintCode => LintNames.prefer_generic_function_type_aliases;

  Future<void> test_functionTypeAlias_noParameterTypes() async {
    await resolveTestCode('''
typedef String F(x);
''');
    await assertNoFix();
  }

  Future<void> test_functionTypeAlias_noReturnType_noTypeParameters() async {
    await resolveTestCode('''
typedef String F(int x);
''');
    await assertHasFix('''
typedef F = String Function(int x);
''');
  }

  Future<void> test_functionTypeAlias_noReturnType_typeParameters() async {
    await resolveTestCode('''
typedef F<P, R>(P x);
''');
    await assertHasFix('''
typedef F<P, R> = Function(P x);
''');
  }

  Future<void> test_functionTypeAlias_returnType_noTypeParameters() async {
    await resolveTestCode('''
typedef String F(int x);
''');
    await assertHasFix('''
typedef F = String Function(int x);
''');
  }

  Future<void> test_functionTypeAlias_returnType_typeParameters() async {
    await resolveTestCode('''
typedef R F<P, R>(P x);
''');
    await assertHasFix('''
typedef F<P, R> = R Function(P x);
''');
  }
}

@reflectiveTest
class UseFunctionTypeSyntaxForParametersTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_GENERIC_FUNCTION_SYNTAX;

  @override
  String get lintCode => LintNames.use_function_type_syntax_for_parameters;

  Future<void> test_functionTypedParameter_noParameterTypes() async {
    await resolveTestCode('''
g(String f(x)) {}
''');
    await assertNoFix();
  }

  Future<void> test_functionTypedParameter_returnType() async {
    await resolveTestCode('''
g(String f(int x)) {}
''');
    await assertHasFix('''
g(String Function(int x) f) {}
''');
  }
}
