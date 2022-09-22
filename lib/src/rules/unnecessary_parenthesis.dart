// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Unnecessary parenthesis can be removed.';

const _details = r'''
**AVOID** using parenthesis when not needed.

**GOOD:**
```dart
a = b;
```

**BAD:**
```dart
a = (b);
```

''';

class UnnecessaryParenthesis extends LintRule {
  UnnecessaryParenthesis()
      : super(
            name: 'unnecessary_parenthesis',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addParenthesizedExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    var parent = node.parent;
    var expression = node.expression;
    if (expression is SimpleIdentifier) {
      if (parent is PropertyAccess) {
        if (parent.propertyName.name == 'hashCode' ||
            parent.propertyName.name == 'runtimeType') {
          // Code like `(String).hashCode` is allowed.
          return;
        }
      } else if (parent is MethodInvocation) {
        if (parent.methodName.name == 'noSuchMethod' ||
            parent.methodName.name == 'toString') {
          // Code like `(String).noSuchMethod()` is allowed.
          return;
        }
      }
      rule.reportLint(node);
      return;
    }

    // https://github.com/dart-lang/linter/issues/2944
    if (expression is FunctionExpression) {
      if (parent is MethodInvocation ||
          parent is PropertyAccess ||
          parent is BinaryExpression ||
          parent is IndexExpression) {
        return;
      }
    }

    if (expression is ConstructorReference) {
      if (parent is! FunctionExpressionInvocation ||
          parent.typeArguments == null) {
        rule.reportLint(node);
        return;
      }
    }

    if (parent is ParenthesizedExpression) {
      rule.reportLint(node);
      return;
    }

    // `a..b=(c..d)` is OK.
    if (expression is CascadeExpression ||
        node.thisOrAncestorMatching(
                (n) => n is Statement || n is CascadeExpression)
            is CascadeExpression) {
      return;
    }

    // Constructor field initializers are rather unguarded by delimiting
    // tokens, which can get confused with a function expression. See test
    // cases for issues #1395 and #1473.
    if (parent is ConstructorFieldInitializer &&
        _containsFunctionExpression(node)) {
      return;
    }

    if (parent is Expression) {
      if (parent is BinaryExpression) return;
      if (parent is ConditionalExpression) return;
      if (parent is CascadeExpression) return;
      if (parent is FunctionExpressionInvocation) return;

      // A prefix expression (! or -) can have an argument wrapped in
      // "unnecessary" parens if that argument has potentially confusing
      // whitespace after its first token.
      if (parent is PrefixExpression && node.expression.startsWithWhitespace) {
        return;
      }

      // Another case of the above exception, something like
      // `!(const [7]).contains(5);`, where the _parent's_ parent is the
      // PrefixExpression.
      if (parent is MethodInvocation) {
        var target = parent.target;
        if (parent.parent is PrefixExpression &&
            target == node &&
            node.expression.startsWithWhitespace) return;
      }

      // Something like `({1, 2, 3}).forEach(print);`.
      // The parens cannot be removed because then the curly brackets are not
      // interpreted as a set-or-map literal.
      if (node.wouldBeParsedAsStatementBlock) {
        return;
      }

      if (parent.precedence < node.expression.precedence) {
        rule.reportLint(node);
        return;
      }
    } else {
      rule.reportLint(node);
      return;
    }
  }

  bool _containsFunctionExpression(ParenthesizedExpression node) {
    var containsFunctionExpressionVisitor =
        _ContainsFunctionExpressionVisitor();
    node.accept(containsFunctionExpressionVisitor);
    return containsFunctionExpressionVisitor.hasFunctionExpression;
  }
}

class _ContainsFunctionExpressionVisitor extends UnifyingAstVisitor<void> {
  bool hasFunctionExpression = false;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    hasFunctionExpression = true;
  }

  @override
  void visitNode(AstNode node) {
    if (!hasFunctionExpression) {
      node.visitChildren(this);
    }
  }
}

extension on ParenthesizedExpression {
  /// Returns whether a parser would attempt to parse `this` as a statement
  /// block if the parentheses were removed.
  ///
  /// The two components that make this true are:
  /// * the parenthesized expression is a [SetOrMapLiteral] (starting with `{`),
  /// * the open parenthesis of this expression is the first token of an
  ///   [ExpressionStatement].
  bool get wouldBeParsedAsStatementBlock {
    if (expression is! SetOrMapLiteral) {
      return false;
    }
    var exprStatementAncestor = thisOrAncestorOfType<ExpressionStatement>();
    if (exprStatementAncestor == null) {
      return false;
    }
    return exprStatementAncestor.beginToken == leftParenthesis;
  }
}

extension on Expression? {
  /// Returns whether this "starts" with whitespace.
  ///
  /// That is, is there definitely whitespace after the first token?
  bool get startsWithWhitespace {
    var self = this;
    return
        // As in, `!(await foo)`.
        self is AwaitExpression ||
            // As in, `!(new Foo())`.
            (self is InstanceCreationExpression && self.keyword != null) ||
            // No TypedLiteral (ListLiteral, MapLiteral, SetLiteral) accepts `-`
            // or `!` as a prefix operator, but this method can be called
            // rescursively, so this catches things like
            // `!(const [].contains(42))`.
            (self is TypedLiteral && self.constKeyword != null) ||
            // As in, `!(const List(3).contains(7))`, and chains like
            // `-(new List(3).skip(1).take(3).skip(1).length)`.
            (self is MethodInvocation && self.target.startsWithWhitespace) ||
            // As in, `-(new List(3).length)`, and chains like
            // `-(new List(3).length.bitLength.bitLength)`.
            (self is PropertyAccess && self.target.startsWithWhitespace);
  }
}
