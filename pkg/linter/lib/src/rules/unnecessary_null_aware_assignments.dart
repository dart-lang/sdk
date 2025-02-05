// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Avoid `null` in `null`-aware assignment.';

class UnnecessaryNullAwareAssignments extends LintRule {
  UnnecessaryNullAwareAssignments()
      : super(
          name: LintNames.unnecessary_null_aware_assignments,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.unnecessary_null_aware_assignments;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addAssignmentExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (node.writeElement2 is SetterElement) return;

    if (node.operator.type == TokenType.QUESTION_QUESTION_EQ &&
        node.rightHandSide.isNullLiteral) {
      rule.reportLint(node);
    }
  }
}
