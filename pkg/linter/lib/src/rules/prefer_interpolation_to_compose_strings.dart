// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../ast.dart';

const _desc = r'Use interpolation to compose strings and values.';

const _details = r'''
**PREFER** using interpolation to compose strings and values.

Using interpolation when composing strings and values is usually easier to write
and read than concatenation.

**BAD:**
```dart
'Hello, ' + person.name + ' from ' + person.city + '.';
```

**GOOD:**
```dart
'Hello, ${person.name} from ${person.city}.'
```

''';

class PreferInterpolationToComposeStrings extends LintRule {
  static const LintCode code = LintCode(
      'prefer_interpolation_to_compose_strings',
      'Use interpolation to compose strings and values.',
      correctionMessage:
          'Try using string interpolation to build the composite string.');

  PreferInterpolationToComposeStrings()
      : super(
            name: 'prefer_interpolation_to_compose_strings',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addBinaryExpression(this, visitor);
  }
}

class _NodeVisitor extends UnifyingAstVisitor {
  Set<AstNode> skippedNodes;
  _NodeVisitor(this.skippedNodes);

  @override
  visitNode(AstNode node) {
    skippedNodes.add(node);

    super.visitNode(node);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final skippedNodes = <AstNode>{};

  _Visitor(this.rule);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (skippedNodes.contains(node)) {
      return;
    }
    if (node.operator.type == TokenType.PLUS) {
      var leftOperand = node.leftOperand;
      var rightOperand = node.rightOperand;
      // OK(#735): `str1 + str2`
      if (leftOperand is! StringLiteral && rightOperand is! StringLiteral) {
        return;
      }
      // OK(#2490): `str1 + r''`
      if (leftOperand is SimpleStringLiteral && leftOperand.isRaw ||
          rightOperand is SimpleStringLiteral && rightOperand.isRaw) {
        return;
      }
      // OK: `'foo' + 'bar'`
      if (leftOperand is StringLiteral && rightOperand is StringLiteral) {
        return;
      }
      // OK(https://github.com/dart-lang/sdk/issues/52610):
      // `a.toString(x: 0) + 'foo'`
      // `'foo' + a.toString(x: 0)`
      if (leftOperand.isToStringInvocationWithArguments ||
          rightOperand.isToStringInvocationWithArguments) {
        return;
      }
      if (leftOperand.staticType?.isDartCoreString ?? false) {
        rule.reportLint(node);
        node.accept(_NodeVisitor(skippedNodes));
      }
    }
  }
}
