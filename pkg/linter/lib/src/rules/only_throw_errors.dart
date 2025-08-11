// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../util/dart_type_utilities.dart';

const _desc =
    r'Only throw instances of classes extending either Exception or Error.';

final Set<InterfaceTypeDefinition> _interfaceDefinitions = {
  InterfaceTypeDefinition('Exception', 'dart.core'),
  InterfaceTypeDefinition('Error', 'dart.core'),
};

bool _isThrowable(DartType? type) {
  var typeForInterfaceCheck = type?.typeForInterfaceCheck;
  return typeForInterfaceCheck == null ||
      typeForInterfaceCheck is DynamicType ||
      type is NeverType ||
      typeForInterfaceCheck.implementsAnyInterface(_interfaceDefinitions);
}

class OnlyThrowErrors extends LintRule {
  OnlyThrowErrors()
    : super(name: LintNames.only_throw_errors, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.only_throw_errors;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addThrowExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitThrowExpression(ThrowExpression node) {
    if (node.expression is Literal) {
      rule.reportAtNode(node.expression);
      return;
    }

    if (!_isThrowable(node.expression.staticType)) {
      rule.reportAtNode(node.expression);
    }
  }
}
