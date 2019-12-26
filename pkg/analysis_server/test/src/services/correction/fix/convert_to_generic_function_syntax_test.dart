// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToGenericFunctionSyntaxTest);
  });
}

@reflectiveTest
class ConvertToGenericFunctionSyntaxTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_GENERIC_FUNCTION_SYNTAX;

  @override
  String get lintCode => LintNames.prefer_generic_function_type_aliases;

  test_functionTypeAlias_noParameterTypes() async {
    await resolveTestUnit('''
typedef String /*LINT*/F(x);
''');
    await assertNoFix();
  }

  test_functionTypeAlias_noReturnType_noTypeParameters() async {
    await resolveTestUnit('''
typedef String /*LINT*/F(int x);
''');
    await assertHasFix('''
typedef F = String Function(int x);
''');
  }

  test_functionTypeAlias_noReturnType_typeParameters() async {
    await resolveTestUnit('''
typedef /*LINT*/F<P, R>(P x);
''');
    await assertHasFix('''
typedef /*LINT*/F<P, R> = Function(P x);
''');
  }

  test_functionTypeAlias_returnType_noTypeParameters() async {
    await resolveTestUnit('''
typedef String /*LINT*/F(int x);
''');
    await assertHasFix('''
typedef F = String Function(int x);
''');
  }

  test_functionTypeAlias_returnType_typeParameters() async {
    await resolveTestUnit('''
typedef R /*LINT*/F<P, R>(P x);
''');
    await assertHasFix('''
typedef F<P, R> = R Function(P x);
''');
  }

  test_functionTypedParameter_noParameterTypes() async {
    await resolveTestUnit('''
g(String /*LINT*/f(x)) {}
''');
    await assertNoFix();
  }

  test_functionTypedParameter_returnType() async {
    await resolveTestUnit('''
g(String /*LINT*/f(int x)) {}
''');
    await assertHasFix('''
g(String Function(int x) f) {}
''');
  }
}
