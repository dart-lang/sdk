// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'Await only futures.';

class AwaitOnlyFutures extends LintRule {
  AwaitOnlyFutures()
    : super(name: LintNames.await_only_futures, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.await_only_futures;

  @override
  void registerNodeProcessors(NodeLintRegistry registry, RuleContext context) {
    var visitor = _Visitor(this, context);
    registry.addAwaitExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitAwaitExpression(AwaitExpression node) {
    if (node.expression is NullLiteral) return;

    var type = node.expression.staticType;
    if (type == null || type is DynamicType) return;
    type = context.typeSystem.promoteToNonNull(type);
    if (type.isDartAsyncFutureOr) return;
    if (type.element is ExtensionTypeElement) return;
    if (type is InvalidType) return;

    if (context.typeSystem.isAssignableTo(
      type,
      context.typeProvider.futureDynamicType,
    )) {
      return;
    }

    rule.reportAtToken(node.awaitKeyword, arguments: [type]);
  }
}
