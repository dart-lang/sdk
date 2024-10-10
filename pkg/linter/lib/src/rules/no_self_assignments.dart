// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r"Don't assign a variable to itself.";

class NoSelfAssignments extends LintRule {
  NoSelfAssignments()
      : super(
          name: LintNames.no_self_assignments,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.no_self_assignments;

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
    if (node.operator.type != TokenType.EQ) return;
    var lhs = node.leftHandSide;
    var rhs = node.rightHandSide;
    if (lhs is Identifier && rhs is Identifier) {
      if (lhs.name == rhs.name) {
        rule.reportLint(node);
      }
    }
  }
}
