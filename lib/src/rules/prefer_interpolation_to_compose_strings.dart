// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Use interpolation to compose strings and values.';

const _details = r'''

**PREFER** using interpolation to compose strings and values.

Using interpolation when composing strings and values is usually easier to write
and read than concatenation.

**BAD:**
```
'Hello, ' + name + '! You are ' + (year - birth) + ' years old.';
```

**GOOD:**
```
'Hello, $name! You are ${year - birth} years old.';
```

''';

class PreferInterpolationToComposeStrings extends LintRule {
  PreferInterpolationToComposeStrings()
      : super(
            name: 'prefer_interpolation_to_compose_strings',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new _Visitor(this);
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  final skippedNodes = new Set<AstNode>();

  _Visitor(this.rule);

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    if (skippedNodes.contains(node)) {
      return;
    }
    if (node.operator.type == TokenType.PLUS_EQ &&
        (DartTypeUtilities.isClass(
                node.leftHandSide.bestType, 'String', 'dart.core') ||
            DartTypeUtilities.isClass(
                node.rightHandSide.bestType, 'String', 'dart.core'))) {
      DartTypeUtilities.traverseNodesInDFS(node).forEach(skippedNodes.add);
      rule.reportLint(node);
    }
  }

  @override
  visitBinaryExpression(BinaryExpression node) {
    if (skippedNodes.contains(node)) {
      return;
    }
    if (node.operator.type == TokenType.PLUS) {
      if (node.leftOperand is StringLiteral &&
          node.rightOperand is StringLiteral) {
        return;
      }
      if (DartTypeUtilities.isClass(
              node.leftOperand.bestType, 'String', 'dart.core') ||
          DartTypeUtilities.isClass(
              node.rightOperand.bestType, 'String', 'dart.core')) {
        DartTypeUtilities.traverseNodesInDFS(node).forEach(skippedNodes.add);
        rule.reportLint(node);
      }
    }
  }
}
