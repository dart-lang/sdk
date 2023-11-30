// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../ast.dart';
import '../extensions.dart';

const _desc = r'Use `isEmpty` for Iterables and Maps.';
const _details = r'''
**DON'T** use `length` to see if a collection is empty.

The `Iterable` contract does not require that a collection know its length or be
able to provide it in constant time.  Calling `length` just to see if the
collection contains anything can be painfully slow.

Instead, there are faster and more readable getters: `isEmpty` and
`isNotEmpty`.  Use the one that doesn't require you to negate the result.

**BAD:**
```dart
if (lunchBox.length == 0) return 'so hungry...';
if (words.length != 0) return words.join(' ');
```

**GOOD:**
```dart
if (lunchBox.isEmpty) return 'so hungry...';
if (words.isNotEmpty) return words.join(' ');
```

''';

class PreferIsEmpty extends LintRule {
  // TODO(brianwilkerson): Both `alwaysFalse` and `alwaysTrue` should be warnings
  //  rather than lints because they represent a bug rather than a style
  //  preference.
  static const LintCode alwaysFalse = LintCode(
      'prefer_is_empty',
      "The comparison is always 'false' because the length is always greater "
          'than or equal to 0.');

  static const LintCode alwaysTrue = LintCode(
      'prefer_is_empty',
      "The comparison is always 'true' because the length is always greater "
          'than or equal to 0.');

  static const LintCode useIsEmpty = LintCode(
      'prefer_is_empty',
      "Use 'isEmpty' instead of 'length' to test whether the collection is "
          'empty.',
      correctionMessage: "Try rewriting the expression to use 'isEmpty'.");

  static const LintCode useIsNotEmpty = LintCode(
      'prefer_is_empty',
      "Use 'isNotEmpty' instead of 'length' to test whether the collection is "
          'empty.',
      correctionMessage: "Try rewriting the expression to use 'isNotEmpty'.");

  PreferIsEmpty()
      : super(
            name: 'prefer_is_empty',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  List<LintCode> get lintCodes =>
      [alwaysFalse, alwaysTrue, useIsEmpty, useIsNotEmpty];

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addBinaryExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferIsEmpty rule;

  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    // TODO(pq): not evaluating constants deliberately but we *should*.
    // see: https://github.com/dart-lang/linter/issues/2818
    var value = getIntValue(node.rightOperand, null);
    if (value != null) {
      if (_isLengthAccess(node.leftOperand)) {
        _check(node, value, constantOnRight: true);
      }
    } else {
      value = getIntValue(node.leftOperand, null);
      if (value != null) {
        if (_isLengthAccess(node.rightOperand)) {
          _check(node, value, constantOnRight: false);
        }
      }
    }
  }

  void _check(BinaryExpression expression, int value,
      {required bool constantOnRight}) {
    // Don't lint if we're in a const constructor initializer.
    var constructorInitializer =
        expression.thisOrAncestorOfType<ConstructorInitializer>();
    if (constructorInitializer != null) {
      var constructorDecl = constructorInitializer.parent;
      if (constructorDecl is! ConstructorDeclaration ||
          constructorDecl.constKeyword != null) {
        return;
      }
    }

    // Or in a const context.
    // See: https://github.com/dart-lang/linter/issues/1719
    if (expression.inConstantContext) {
      return;
    }

    var operator = expression.operator;
    if (value == 0) {
      if (operator.type == TokenType.EQ_EQ ||
          operator.type == TokenType.LT_EQ) {
        rule.reportLint(expression, errorCode: PreferIsEmpty.useIsEmpty);
      } else if (operator.type == TokenType.GT ||
          operator.type == TokenType.BANG_EQ) {
        rule.reportLint(expression, errorCode: PreferIsEmpty.useIsNotEmpty);
      } else if (operator.type == TokenType.LT) {
        rule.reportLint(expression, errorCode: PreferIsEmpty.alwaysFalse);
      } else if (operator.type == TokenType.GT_EQ) {
        rule.reportLint(expression, errorCode: PreferIsEmpty.alwaysTrue);
      }
    } else if (value == 1) {
      if (constantOnRight) {
        // 'length >= 1' is same as 'isNotEmpty',
        // and 'length < 1' is same as 'isEmpty'
        if (operator.type == TokenType.GT_EQ) {
          rule.reportLint(expression, errorCode: PreferIsEmpty.useIsNotEmpty);
        } else if (operator.type == TokenType.LT) {
          rule.reportLint(expression, errorCode: PreferIsEmpty.useIsEmpty);
        }
      } else {
        // '1 <= length' is same as 'isNotEmpty',
        // and '1 > length' is same as 'isEmpty'
        if (operator.type == TokenType.LT_EQ) {
          rule.reportLint(expression, errorCode: PreferIsEmpty.useIsNotEmpty);
        } else if (operator.type == TokenType.GT) {
          rule.reportLint(expression, errorCode: PreferIsEmpty.useIsEmpty);
        }
      }
    } else if (value < 0) {
      if (constantOnRight) {
        // 'length' is always >= 0, so comparing with negative makes no sense.
        if (operator.type == TokenType.EQ_EQ ||
            operator.type == TokenType.LT_EQ ||
            operator.type == TokenType.LT) {
          rule.reportLint(expression, errorCode: PreferIsEmpty.alwaysFalse);
        } else if (operator.type == TokenType.BANG_EQ ||
            operator.type == TokenType.GT_EQ ||
            operator.type == TokenType.GT) {
          rule.reportLint(expression, errorCode: PreferIsEmpty.alwaysTrue);
        }
      } else {
        // 'length' is always >= 0, so comparing with negative makes no sense.
        if (operator.type == TokenType.EQ_EQ ||
            operator.type == TokenType.GT_EQ ||
            operator.type == TokenType.GT) {
          rule.reportLint(expression, errorCode: PreferIsEmpty.alwaysFalse);
        } else if (operator.type == TokenType.BANG_EQ ||
            operator.type == TokenType.LT_EQ ||
            operator.type == TokenType.LT) {
          rule.reportLint(expression, errorCode: PreferIsEmpty.alwaysTrue);
        }
      }
    }
  }

  // TODO(pq): consider sharing
  T? _drillDownTo<T extends Expression>(Expression expression,
      {required bool ignoreParens, required bool ignoreAs}) {
    var search = expression;
    // ignore: literal_only_boolean_expressions
    while (true) {
      if (ignoreParens && search is ParenthesizedExpression) {
        search = search.expression;
      } else if (ignoreAs && search is AsExpression) {
        search = search.expression;
      } else {
        break;
      }
    }

    return search is T ? search : null;
  }

  bool _isLengthAccess(Expression operand) {
    var node = _drillDownTo(operand, ignoreParens: true, ignoreAs: true);
    if (node == null) {
      return false;
    }

    SimpleIdentifier? identifier;
    InterfaceType? type;

    if (node is PrefixedIdentifier) {
      identifier = node.identifier;
      var operandType = node.prefix.staticType;
      if (operandType is InterfaceType) {
        type = operandType;
      }
    } else if (node is PropertyAccess) {
      identifier = node.propertyName;
      var parentType = node.target?.staticType;
      if (parentType is InterfaceType) {
        type = parentType;
      }
    }

    if (identifier?.name != 'length') {
      return false;
    }

    // Should be subtype of Iterable, Map or String.
    if (type == null ||
        !type.implementsInterface('Iterable', 'dart.core') &&
            !type.implementsInterface('Map', 'dart.core') &&
            !type.isDartCoreString) {
      return false;
    }

    return true;
  }
}
