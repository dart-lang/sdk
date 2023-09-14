// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Unnecessary parentheses can be removed.';

const _details = r'''
**AVOID** using parentheses when not needed.

**BAD:**
```dart
a = (b);
```

**GOOD:**
```dart
a = b;
```

Parentheses are considered unnecessary if they do not change the meaning of the
code and they do not improve the readability of the code. The goal is not to
force all developers to maintain the expression precedence table in their heads,
which is why the second condition is included. Examples of this condition
include:

* cascade expressions - it is sometimes not clear what the target of a cascade
  expression is, especially with assignments, or nested cascades. For example,
  the expression `a.b = (c..d)`.
* expressions with whitespace between tokens - it can look very strange to see
  an expression like `!await foo` which is valid and equivalent to
  `!(await foo)`.
* logical expressions - parentheses can improve the readability of the implicit
  grouping defined by precedence. For example, the expression
  `(a && b) || c && d`.
''';

class UnnecessaryParenthesis extends LintRule {
  static const LintCode code = LintCode(
      'unnecessary_parenthesis', 'Unnecessary use of parentheses.',
      correctionMessage: 'Try removing the parentheses.');

  UnnecessaryParenthesis()
      : super(
            name: 'unnecessary_parenthesis',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addParenthesizedExpression(this, visitor);
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

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    var parent = node.parent;
    // case const (a + b):
    if (parent is ConstantPattern) return;
    var expression = node.expression;
    if (expression is SimpleIdentifier ||
        expression.containsNullAwareInvocationInChain()) {
      if (parent is PropertyAccess) {
        var name = parent.propertyName.name;
        if (name == 'hashCode' || name == 'runtimeType') {
          // Code like `(String).hashCode` is allowed.
          return;
        }
      } else if (parent is MethodInvocation) {
        var name = parent.methodName.name;
        if (name == 'noSuchMethod' || name == 'toString') {
          // Code like `(String).noSuchMethod()` is allowed.
          return;
        }
      } else if (parent is PostfixExpression &&
          parent.operator.type == TokenType.BANG) {
        return;
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

    // Directly wrapped into parentheses already - always report.
    if (parent is ParenthesizedExpression ||
        parent is InterpolationExpression ||
        (parent is ArgumentList && parent.arguments.length == 1) ||
        (parent is IfStatement && node == parent.expression) ||
        (parent is IfElement && node == parent.expression) ||
        (parent is WhileStatement && node == parent.condition) ||
        (parent is DoStatement && node == parent.condition) ||
        (parent is SwitchStatement && node == parent.expression) ||
        (parent is SwitchExpression && node == parent.expression)) {
      rule.reportLint(node);
      return;
    }

    // `(foo ? bar : baz)` is OK.
    if (expression is ConditionalExpression) {
      return;
    }

    // `a..b = (c..d)` is OK.
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

    // `foo = (a == b)` is OK, `return (count != 0)` is OK.
    if (expression is BinaryExpression &&
        (expression.operator.type == TokenType.EQ_EQ ||
            expression.operator.type == TokenType.BANG_EQ)) {
      if (parent is AssignmentExpression ||
          parent is VariableDeclaration ||
          parent is ReturnStatement ||
          parent is YieldStatement ||
          parent is ConstructorFieldInitializer) {
        return;
      }
    }

    // `switch` at the beginning of a statement will be parsed as a
    // switch statement, the parenthesis are required to parse as a switch
    // expression instead.
    if (node.expression is SwitchExpression) {
      if (parent is ExpressionStatement) {
        return;
      }
    }

    if (parent is Expression) {
      if (parent is BinaryExpression) return;
      if (parent is ConditionalExpression) return;
      if (parent is CascadeExpression) return;
      if (parent is FunctionExpressionInvocation) {
        if (expression is PrefixedIdentifier) {
          rule.reportLint(node);
        }
        return;
      }
      if (parent is AsExpression) return;
      if (parent is IsExpression) return;

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

      // TODO an API to the AST for better usage
      // Precedence isn't sufficient (e.g. PostfixExpression requires parenthesis)
      if (expression is PropertyAccess ||
          expression is ConstructorReference ||
          expression is PrefixedIdentifier ||
          expression is MethodInvocation ||
          expression is IndexExpression ||
          expression is Literal ||
          parent.precedence < expression.precedence) {
        rule.reportLint(node);
      }
    } else {
      rule.reportLint(node);
    }
  }

  bool _containsFunctionExpression(ParenthesizedExpression node) {
    var containsFunctionExpressionVisitor =
        _ContainsFunctionExpressionVisitor();
    node.accept(containsFunctionExpressionVisitor);
    return containsFunctionExpressionVisitor.hasFunctionExpression;
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
            // recursively, so this catches things like
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
