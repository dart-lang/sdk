// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/context/declared_variables.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const alwaysFalse =
    'Always false because indexOf is always greater or equal -1.';
const alwaysTrue = 'Always true because indexOf is always greater or equal -1.';

const desc = 'Use contains for Lists and Strings.';
const details = '''
**DO NOT** use `.indexOf` to see if a collection contains an element.

Calling `.indexOf` to see if a collection contains something is difficult to read and may have poor performance.

Instead, prefer `.contains`.

**GOOD:**
```
if (!lunchBox.contains('sandwich') return 'so hungry...';
```

**BAD:**
```
if (lunchBox.indexOf('sandwich') == -1 return 'so hungry...';
```
''';

const useContains = 'Use contains instead of indexOf';

class PreferContainsOverIndexOf extends LintRule {
  PreferContainsOverIndexOf()
      : super(
            name: 'prefer_contains',
            description: desc,
            details: details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new _Visitor(this);

  void reportLintWithDescription(AstNode node, String description) {
    if (node != null) {
      reporter.reportErrorForNode(new _LintCode(name, description), node, []);
    }
  }
}

class _Visitor extends SimpleAstVisitor {
  final PreferContainsOverIndexOf rule;

  _Visitor(this.rule);

  @override
  visitSimpleIdentifier(SimpleIdentifier identifier) {
    // Should be "indexOf".
    final Element propertyElement = identifier.bestElement;
    if (propertyElement?.name != 'indexOf') {
      return;
    }

    AstNode indexOfAccess;
    InterfaceType type;

    final AstNode parent = identifier.parent;
    if (parent is MethodInvocation && identifier == parent.methodName) {
      indexOfAccess = parent;
      if (parent.target?.bestType is! InterfaceType) {
        return;
      }
      type = parent.target?.bestType;
    } else {
      return;
    }

    if (!DartTypeUtilities
        .implementsAnyInterface(type, <InterfaceTypeDefinition>[
      new InterfaceTypeDefinition('Iterable', 'dart.core'),
      new InterfaceTypeDefinition('String', 'dart.core'),
    ])) {
      return;
    }

    // Going up in AST structure to find binary comparison operator for this
    // `indexOf` access. Most of the time it will be a parent, but sometimes
    // it can be wrapped in parentheses or `as` operator.
    AstNode search = indexOfAccess;
    while (
        search != null && search is Expression && search is! BinaryExpression) {
      search = search.parent;
    }

    if (search is! BinaryExpression) {
      return;
    }

    final BinaryExpression binaryExpression = search;
    final Token operator = binaryExpression.operator;

    final AnalysisContext context = propertyElement.context;
    final TypeProvider typeProvider = context.typeProvider;
    final TypeSystem typeSystem = context.typeSystem;

    final DeclaredVariables declaredVariables = context.declaredVariables;

    // Comparing constants with result of indexOf.

    final ConstantVisitor visitor = new ConstantVisitor(
        new ConstantEvaluationEngine(typeProvider, declaredVariables,
            typeSystem: typeSystem),
        new ErrorReporter(
            AnalysisErrorListener.NULL_LISTENER, rule.reporter.source));

    final DartObjectImpl rightValue =
        binaryExpression.rightOperand.accept(visitor);
    if (rightValue?.type?.name == 'int') {
      // Constant is on right side of comparison operator
      _checkConstant(binaryExpression, rightValue.toIntValue(), operator.type);
      return;
    }

    final DartObjectImpl leftValue =
        binaryExpression.leftOperand.accept(visitor);
    if (leftValue?.type?.name == 'int') {
      // Constants is on left side of comparison operator
      _checkConstant(binaryExpression, leftValue.toIntValue(),
          _invertedTokenType(operator.type));
    }
  }

  void _checkConstant(Expression expression, int value, TokenType type) {
    if (value == -1) {
      if (type == TokenType.EQ_EQ ||
          type == TokenType.BANG_EQ ||
          type == TokenType.LT_EQ ||
          type == TokenType.GT) {
        rule.reportLintWithDescription(expression, useContains);
      } else if (type == TokenType.LT) {
        // indexOf < -1 is always false
        rule.reportLintWithDescription(expression, alwaysFalse);
      } else if (type == TokenType.GT_EQ) {
        // indexOf >= -1 is always true
        rule.reportLintWithDescription(expression, alwaysTrue);
      }
    } else if (value == 0) {
      // 'indexOf >= 0' is same as 'contains',
      // and 'indexOf < 0' is same as '!contains'
      if (type == TokenType.GT_EQ || type == TokenType.LT) {
        rule.reportLintWithDescription(expression, useContains);
      }
    } else if (value < -1) {
      // 'indexOf' is always >= -1, so comparing with lesser values makes
      // no sense.
      if (type == TokenType.EQ_EQ ||
          type == TokenType.LT_EQ ||
          type == TokenType.LT) {
        rule.reportLintWithDescription(expression, alwaysFalse);
      } else if (type == TokenType.BANG_EQ ||
          type == TokenType.GT_EQ ||
          type == TokenType.GT) {
        rule.reportLintWithDescription(expression, alwaysTrue);
      }
    }
  }

  TokenType _invertedTokenType(TokenType type) {
    switch (type) {
      case TokenType.LT_EQ:
        return TokenType.GT_EQ;

      case TokenType.LT:
        return TokenType.GT;

      case TokenType.GT:
        return TokenType.LT;

      case TokenType.GT_EQ:
        return TokenType.LT_EQ;

      default:
        return type;
    }
  }
}

// TODO create common MultiMessageLintCode class
class _LintCode extends LintCode {
  static final registry = <String, LintCode>{};

  factory _LintCode(String name, String message) => registry.putIfAbsent(
      name + message, () => new _LintCode._(name, message));

  _LintCode._(String name, String message) : super(name, message);
}
