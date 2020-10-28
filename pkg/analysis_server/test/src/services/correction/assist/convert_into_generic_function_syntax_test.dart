// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertIntoGenericFunctionSyntaxTest);
  });
}

@reflectiveTest
class ConvertIntoGenericFunctionSyntaxTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_INTO_GENERIC_FUNCTION_SYNTAX;

  Future<void> test_functionTypeAlias_insideParameterList() async {
    await resolveTestCode('''
typedef String F(int x, int y);
''');
    await assertNoAssistAt('x,');
  }

  Future<void> test_functionTypeAlias_noParameterTypes() async {
    await resolveTestCode('''
typedef String F(x);
''');
    await assertNoAssistAt('def');
  }

  Future<void> test_functionTypeAlias_noReturnType_noTypeParameters() async {
    await resolveTestCode('''
typedef String F(int x);
''');
    await assertHasAssistAt('def', '''
typedef F = String Function(int x);
''');
  }

  Future<void> test_functionTypeAlias_noReturnType_typeParameters() async {
    await resolveTestCode('''
typedef F<P, R>(P x);
''');
    await assertHasAssistAt('def', '''
typedef F<P, R> = Function(P x);
''');
  }

  Future<void> test_functionTypeAlias_returnType_noTypeParameters() async {
    await resolveTestCode('''
typedef String F(int x);
''');
    await assertHasAssistAt('def', '''
typedef F = String Function(int x);
''');
  }

  Future<void> test_functionTypeAlias_returnType_typeParameters() async {
    await resolveTestCode('''
typedef R F<P, R>(P x);
''');
    await assertHasAssistAt('def', '''
typedef F<P, R> = R Function(P x);
''');
  }

  Future<void> test_functionTypedParameter_insideParameterList() async {
    await resolveTestCode('''
g(String f(int x, int y)) {}
''');
    await assertNoAssistAt('x,');
  }

  Future<void> test_functionTypedParameter_noParameterTypes() async {
    await resolveTestCode('''
g(String f(x)) {}
''');
    await assertNoAssistAt('f(');
  }

  Future<void>
      test_functionTypedParameter_noReturnType_noTypeParameters() async {
    await resolveTestCode('''
g(f(int x)) {}
''');
    await assertHasAssistAt('f(', '''
g(Function(int x) f) {}
''');
  }

  Future<void> test_functionTypedParameter_returnType() async {
    await resolveTestCode('''
g(String f(int x)) {}
''');
    await assertHasAssistAt('f(', '''
g(String Function(int x) f) {}
''');
  }
}
