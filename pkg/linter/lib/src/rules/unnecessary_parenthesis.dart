// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

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
            categories: {Category.style});

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context.typeSystem);
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
  final TypeSystem typeSystem;

  _Visitor(this.rule, this.typeSystem);

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    var parent = node.parent;
    // `case const (a + b):` is OK.
    if (parent is ConstantPattern) return;

    // `[...(p as List)]` is OK.
    if (parent is SpreadElement) return;

    // Don't over-report on records missing trailing commas.
    // `(int,) r = (3);` is OK.
    if (parent is VariableDeclaration &&
        parent.declaredElement?.type is RecordType) {
      if (node.expression is! RecordLiteral) return;
    }
    // `g((3)); => g((int,) i) { }` is OK.
    if (parent is ArgumentList) {
      var element = node.staticParameterElement;
      if (element?.type is RecordType && node.expression is! RecordLiteral) {
        return;
      }
    }
    // `g(i: (3)); => g({required (int,) i}) { }` is OK.
    if (parent is NamedExpression &&
        parent.staticParameterElement?.type is RecordType) {
      if (node.expression is! RecordLiteral) return;
    }

    var expression = node.expression;
    if (expression is SimpleIdentifier ||
        expression.containsNullAwareInvocationInChain()) {
      if (parent is PropertyAccess) {
        var name = parent.propertyName.name;
        if (name == 'hashCode' || name == 'runtimeType') {
          // `(String).hashCode` is OK.
          return;
        }

        // Parentheses are required to stop null-aware shorting, which then
        // allows an extension getter, which extends a nullable type, to be
        // called on a `null` value.
        var target = parent.propertyName.staticElement?.enclosingElement;
        if (target is ExtensionElement &&
            typeSystem.isNullable(target.extendedType)) {
          return;
        }
      } else if (parent is MethodInvocation) {
        var name = parent.methodName.name;
        if (name == 'noSuchMethod' || name == 'toString') {
          // `(String).noSuchMethod()` is OK.
          return;
        }

        // Parentheses are required to stop null-aware shorting, which then
        // allows an extension method, which extends a nullable type, to be
        // called on a `null` value.
        var target = parent.methodName.staticElement?.enclosingElement;
        if (target is ExtensionElement &&
            typeSystem.isNullable(target.extendedType)) {
          return;
        }
      } else if (parent is PostfixExpression &&
          parent.operator.type == TokenType.BANG) {
        return;
      } else if (expression is IndexExpression && expression.isNullAware) {
        if (parent is ConditionalExpression &&
            identical(parent.thenExpression, node)) {
          // In `a ? (b?[c]) : d`, the parentheses are necessary to prevent the
          // second `?` from being interpreted as the start of a nested
          // conditional expression (see
          // https://github.com/dart-lang/linter/issues/4812).
          return;
        } else if (parent is MapLiteralEntry && identical(parent.key, node)) {
          // In `{(a?[b]): c}`, the parentheses are necessary to prevent the
          // second `?` from being interpreted as the start of a nested
          // conditional expression (see
          // https://github.com/dart-lang/linter/issues/4812).
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
    //
    // We cannot just look at the immediate `parent`. Take this example of a
    // constructor:
    //
    // ```dart
    // C(bool Function()? e) : e = e ??= (() => true);
    // ```
    //
    // The parentheses in question are not an immediate child of a constructor
    // field initializer; they are the right side of `e ??= ...`, which is an
    // immediate child of a constructor field initializer. There can be any
    // number of expressions like this in between. The important principle is
    // that `=>` must not be "bare", such that it can be interpreted as the
    // delimiter for the constructor body.
    if (node.isBareInConstructorFieldInitializer &&
        node.containsFunctionExpression) {
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

      // TODO(asashour): an API to the AST for better usage
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
}

extension on ParenthesizedExpression {
  bool get containsFunctionExpression {
    var visitor = _ContainsFunctionExpressionVisitor();
    accept(visitor);
    return visitor.hasFunctionExpression;
  }

  bool get isBareInConstructorFieldInitializer {
    var ancestor = parent;
    while (ancestor != null) {
      if (ancestor is ConstructorFieldInitializer) return true;
      if (ancestor is FunctionBody || ancestor is MethodInvocation) {
        // The delimiters (e.g. parentheses) in such an ancestor mean that
        // `this` is not a "bare" expression within the constructor field
        // initializer.
        return false;
      }
      ancestor = ancestor.parent;
    }
    return false;
  }

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
