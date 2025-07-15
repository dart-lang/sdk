// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r"Unnecessary use of 'unawaited'.";

class UnnecessaryUnawaited extends LintRule {
  UnnecessaryUnawaited()
    : super(name: LintNames.unnecessary_unawaited, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.unnecessary_unawaited;

  @override
  void registerNodeProcessors(NodeLintRegistry registry, RuleContext context) {
    var visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!node.isUnawaitedFunction) return;
    if (node.target != null) return;

    // If there are 0 or more than 1 arguments, then a different error is
    // reported.
    if (node.argumentList.arguments.length != 1) return;

    var argument = node.argumentList.arguments.first;
    var element = switch (argument.unParenthesized) {
      BinaryExpression(:var element) => element,
      MethodInvocation(:var methodName) => methodName.element,
      PrefixExpression(:var element) => element,
      PrefixedIdentifier(:var identifier) => identifier.element,
      PropertyAccess(:var propertyName) => propertyName.element,
      SimpleIdentifier(:var element) => element,
      _ => null,
    };
    if (element is! Annotatable) return;
    if (element.hasAwaitNotRequired) {
      rule.reportAtNode(node.methodName);
    }
  }
}

extension on MethodInvocation {
  bool get isUnawaitedFunction =>
      methodName.name == 'unawaited' &&
      methodName.element?.library?.name == 'dart.async';
}
