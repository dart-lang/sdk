// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r"Don't explicitly initialize variables to `null`.";

class AvoidInitToNull extends LintRule {
  AvoidInitToNull()
    : super(name: LintNames.avoid_init_to_null, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.avoidInitToNull;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addVariableDeclaration(this, visitor);
    registry.addDefaultFormalParameter(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  bool isNullable(DartType type) => context.typeSystem.isNullable(type);

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    var declaredElement = node.declaredFragment?.element;
    if (declaredElement == null) return;

    if (declaredElement is SuperFormalParameterElement) {
      var superConstructorParameter = declaredElement.superConstructorParameter;
      if (superConstructorParameter is! FormalParameterElement) return;
      var defaultValue = superConstructorParameter.defaultValueCode ?? 'null';
      if (defaultValue != 'null') return;
    }

    if (node.defaultValue.isNullLiteral && isNullable(declaredElement.type)) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    var declaredElement = node.declaredFragment?.element;
    if (declaredElement != null &&
        !node.isConst &&
        !node.isFinal &&
        node.initializer.isNullLiteral &&
        isNullable(declaredElement.type)) {
      rule.reportAtNode(node);
    }
  }
}
