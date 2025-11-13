// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Unnecessary `.new` constructor name.';

class UnnecessaryConstructorName extends AnalysisRule {
  UnnecessaryConstructorName()
    : super(name: LintNames.unnecessary_constructor_name, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.unnecessaryConstructorName;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
    registry.addRepresentationConstructorName(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var parent = node.parent;
    if (parent is ExtensionTypeDeclaration &&
        parent.representation.constructorName == null) {
      return;
    }

    _check(node.name);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _check(node.constructorName.name?.token);
  }

  @override
  void visitRepresentationConstructorName(RepresentationConstructorName node) {
    _check(node.name);
  }

  void _check(Token? name) {
    if (name != null && name.lexeme == 'new') {
      rule.reportAtToken(name);
    }
  }
}
