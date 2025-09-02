// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:linter/src/analyzer.dart';

class NoSoloTests extends LintRule {
  static const LintCode code = LinterLintCode.noSoloTests;

  NoSoloTests()
    : super(name: 'no_solo_tests', description: "Don't commit soloed tests.");

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (context.isInTestDirectory) {
      var visitor = _Visitor(this);
      registry.addMethodDeclaration(this, visitor);
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // TODO(pq): we *could* ensure we're in a reflective test too.
    // Handle both 'solo_test_' and 'solo_fail_'.
    if (node.name.lexeme.startsWith('solo_')) {
      rule.reportAtToken(node.name);
      return;
    }

    for (var annotation in node.metadata) {
      if (annotation.isSoloTest) {
        rule.reportAtNode(annotation);
      }
    }
  }
}

extension on Annotation {
  bool get isSoloTest {
    var element = this.element;
    return element is GetterElement &&
        element.name == 'soloTest' &&
        element.library.name == 'test_reflective_loader';
  }
}
