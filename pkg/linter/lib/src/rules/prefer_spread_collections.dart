// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/ast/ast.dart'; // ignore: implementation_imports

import '../analyzer.dart';

const _desc = r'Use spread collections when possible.';

class PreferSpreadCollections extends LintRule {
  PreferSpreadCollections()
      : super(
          name: LintNames.prefer_spread_collections,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.prefer_spread_collections;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation invocation) {
    if (invocation.methodName.name != 'addAll' ||
        !invocation.isCascaded ||
        invocation.argumentList.arguments.length != 1) {
      return;
    }

    var cascade = invocation.thisOrAncestorOfType<CascadeExpression>();
    var sections = cascade?.cascadeSections;
    var target = cascade?.target;
    // TODO(pq): add support for Set literals.
    if (target is! ListLiteral ||
        (target is ListLiteralImpl && target.inConstantContext) ||
        (sections != null && sections.first != invocation)) {
      return;
    }

    var argument = invocation.argumentList.arguments.first;
    if (argument is ListLiteral) {
      // Handled by: prefer_inlined_adds
      return;
    }

    rule.reportLint(invocation.methodName);
  }
}
