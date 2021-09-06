// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/accessor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/code_template.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/parameter_reference.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/value_generator.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'data_driven_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CodeTemplateTest);
  });
}

@reflectiveTest
class CodeTemplateTest extends DataDrivenFixProcessorTest {
  Future<void> test_text_variable() async {
    await _assertTemplateResult('a0', [
      _text('a'),
      _variable(0),
    ]);
  }

  Future<void> test_text_variable_text() async {
    await _assertTemplateResult('a0b', [
      _text('a'),
      _variable(0),
      _text('b'),
    ]);
  }

  Future<void> test_textOnly() async {
    await _assertTemplateResult('a', [
      _text('a'),
    ]);
  }

  Future<void> test_variable_text() async {
    await _assertTemplateResult('0a', [
      _variable(0),
      _text('a'),
    ]);
  }

  Future<void> test_variable_text_variable() async {
    await _assertTemplateResult('0a1', [
      _variable(0),
      _text('a'),
      _variable(1),
    ]);
  }

  Future<void> test_variableOnly() async {
    await _assertTemplateResult('0', [
      _variable(0),
    ]);
  }

  Future<void> _assertTemplateResult(
      String expectedResult, List<TemplateComponent> components) async {
    await resolveTestCode('''
void f() {
  g(0, 1);
}
void g(int x, int y) {}
''');
    var unit = testAnalysisResult.unit;
    var function = unit.declarations[0] as FunctionDeclaration;
    var body = function.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var node = statement.expression;
    var template = CodeTemplate(CodeTemplateKind.expression, components, null);
    var builder = ChangeBuilder(session: session);
    var context = TemplateContext(node, CorrectionUtils(testAnalysisResult));
    await builder.addDartFileEdit(testFile, (builder) {
      builder.addInsertion(0, (builder) {
        template.writeOn(builder, context);
      });
    });
    var result = builder.sourceChange.edits[0].edits[0].replacement;
    expect(result, expectedResult);
  }

  TemplateText _text(String text) => TemplateText(text);

  TemplateVariable _variable(int index) => TemplateVariable(
      CodeFragment([ArgumentAccessor(PositionalParameterReference(index))]));
}
