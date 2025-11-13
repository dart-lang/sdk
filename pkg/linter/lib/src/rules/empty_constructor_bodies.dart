// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Use `;` instead of `{}` for empty constructor bodies.';

class EmptyConstructorBodies extends AnalysisRule {
  EmptyConstructorBodies()
    : super(name: LintNames.empty_constructor_bodies, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.emptyConstructorBodies;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var body = node.body;
    if (body is BlockFunctionBody) {
      var block = body.block;
      if (block.statements.isEmpty) {
        if (block.endToken.precedingComments == null) {
          rule.reportAtNode(block);
        }
      }
    }
  }
}
