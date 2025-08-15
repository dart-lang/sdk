// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Unnecessary `toList()` in spreads.';

class UnnecessaryToListInSpreads extends LintRule {
  UnnecessaryToListInSpreads()
    : super(name: LintNames.unnecessary_to_list_in_spreads, description: _desc);

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.unnecessaryToListInSpreads;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addSpreadElement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitSpreadElement(SpreadElement node) {
    var expression = node.expression;
    if (expression is! MethodInvocation) {
      return;
    }
    var target = expression.target;
    if (expression.methodName.name == 'toList' &&
        target != null &&
        target.staticType.implementsInterface('Iterable', 'dart.core')) {
      rule.reportAtNode(expression.methodName);
    }
  }
}
