// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/test_utilities/lint_registration_mixin.dart';
import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnignorableIgnoreTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnignorableIgnoreTest extends PubPackageResolutionTest
    with LintRegistrationMixin {
  @override
  Future<void> tearDown() {
    unregisterLintRules();
    return super.tearDown();
  }

  test_file_lowerCase() async {
    writeTestPackageAnalysisOptionsFile(
      analysisOptionsContent(unignorableNames: ['undefined_annotation']),
    );
    await resolveTestCodeWithDiagnostics(r'''
// ignore_for_file: undefined_annotation
//                  ^^^^^^^^^^^^^^^^^^^^
// [diag.unignorableIgnore] The diagnostic 'undefined_annotation' can't be ignored.
@x int a = 0;
// [diag.undefinedAnnotation][column 1][length 2] Undefined name 'x' used as an annotation.
''');
  }

  test_file_upperCase() async {
    writeTestPackageAnalysisOptionsFile(
      analysisOptionsContent(unignorableNames: ['UNDEFINED_ANNOTATION']),
    );
    await resolveTestCodeWithDiagnostics(r'''
// ignore_for_file: UNDEFINED_ANNOTATION
//                  ^^^^^^^^^^^^^^^^^^^^
// [diag.unignorableIgnore] The diagnostic 'undefined_annotation' can't be ignored.
@x int a = 0;
// [diag.undefinedAnnotation][column 1][length 2] Undefined name 'x' used as an annotation.
''');
  }

  test_line() async {
    writeTestPackageAnalysisOptionsFile(
      analysisOptionsContent(unignorableNames: ['undefined_annotation']),
    );
    await resolveTestCodeWithDiagnostics(r'''
// ignore: undefined_annotation
//         ^^^^^^^^^^^^^^^^^^^^
// [diag.unignorableIgnore] The diagnostic 'undefined_annotation' can't be ignored.
@x int a = 0;
// [diag.undefinedAnnotation][column 1][length 2] Undefined name 'x' used as an annotation.
''');
  }

  test_lint() async {
    writeTestPackageAnalysisOptionsFile(
      analysisOptionsContent(
        unignorableNames: ['avoid_int'],
        rules: ['avoid_int'],
      ),
    );
    var avoidIntRule = _AvoidIntRule();
    registerLintRule(avoidIntRule);
    await resolveTestCodeWithDiagnostics(r'''
// ignore: avoid_int
//         ^^^^^^^^^
// [diag.unignorableIgnore] The diagnostic 'avoid_int' can't be ignored.
int a = 0;
// [diag.avoidInt][column 1][length 3] Avoid int.
''');
  }
}

class _AvoidIntRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_int',
    'Avoid int.',
    correctionMessage: 'Try avoiding int.',
    uniqueName: 'avoid_int',
  );

  _AvoidIntRule() : super(name: 'avoid_int', description: '');

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _AvoidIntVisitor(this);
    registry.addNamedType(this, visitor);
  }
}

class _AvoidIntVisitor extends SimpleAstVisitor {
  final AnalysisRule rule;

  _AvoidIntVisitor(this.rule);

  @override
  void visitNamedType(NamedType node) {
    if (node.name.lexeme == 'int') {
      rule.reportAtToken(node.name);
    }
  }
}
