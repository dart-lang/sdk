// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Unnecessary parentheses can be removed.';

class UnnecessaryParenthesis extends LintRule {
  UnnecessaryParenthesis()
      : super(
          name: LintNames.unnecessary_parenthesis,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.unnecessary_parenthesis;

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

    var expression = node.expression;

    // Don't over-report on records missing trailing commas.
    // `(int,) r = (3);` is OK.
    if (parent is VariableDeclaration &&
        parent.declaredElement2?.type is RecordType) {
      if (expression is! RecordLiteral) return;
    }

    // `g((3)); => g((int,) i) { }` is OK.
    if (parent is ArgumentList) {
      var element = node.correspondingParameter;
      if (element?.type is RecordType && node.expression is! RecordLiteral) {
        return;
      }
    }

    // `g(i: (3)); => g({required (int,) i}) { }` is OK.
    if (parent is NamedExpression &&
        parent.correspondingParameter?.type is RecordType) {
      if (expression is! RecordLiteral) return;
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
    if (expression is ConditionalExpression) return;

    // `(List<int>).toString()` is OK.
    if (expression is TypeLiteral) return;

    if (expression.isOneToken ||
        expression.containsNullAwareInvocationInChain) {
      if (parent is PropertyAccess) {
        var name = parent.propertyName.name;
        if (name == 'hashCode' || name == 'runtimeType') {
          // `(String).hashCode` is OK.
          return;
        }

        // Parentheses are required to stop null-aware shorting, which then
        // allows an extension getter, which extends a nullable type, to be
        // called on a `null` value.
        var target = parent.propertyName.element?.enclosingElement2;
        if (target is ExtensionElement2 &&
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
        var target = parent.methodName.element?.enclosingElement2;
        if (target is ExtensionElement2 &&
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

    if (expression is ConstructorReference) {
      if (parent is! FunctionExpressionInvocation ||
          parent.typeArguments == null) {
        rule.reportLint(node);
        return;
      }
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

    // `switch` at the beginning of a statement will be parsed as a switch
    // statement, the parenthesis are required to parse as a switch expression
    // instead.
    if (parent is ExpressionStatement && expression is SwitchExpression) {
      return;
    }

    if (expression.directlyContainsWhitespace) {
      // An expression with internal whitespace can be made more readable when
      // wrapped in parentheses in many cases. But when the parentheses are
      // inside one of the following nodes, the readability is not affected.
      // See https://github.com/dart-lang/linter/issues/2944.
      if (parent is! AssignmentExpression &&
          parent is! ConstructorFieldInitializer &&
          parent is! ExpressionFunctionBody &&
          parent is! RecordLiteral &&
          parent is! ReturnStatement &&
          parent is! VariableDeclaration &&
          parent is! YieldStatement &&
          !node.isArgument) {
        return;
      }
    }

    if (parent is Expression) {
      if (parent is BinaryExpression) return;
      if (parent is ConditionalExpression) return;
      if (parent is CascadeExpression) return;
      if (parent is FunctionExpressionInvocation &&
          expression is! PrefixedIdentifier) {
        return;
      }
      if (parent is AsExpression) return;
      if (parent is IsExpression) return;

      if (parent
          case MethodInvocation(:var target) || PropertyAccess(:var target)) {
        // Another case of the above exception, something like
        // `!(const [7]).contains(5);`, where the _parent's_ parent is the
        // PrefixExpression.
        if (parent.parent is PrefixExpression &&
            target == node &&
            expression.directlyContainsWhitespace) {
          return;
        }

        // `(p++).toString()` is OK. `(++p).toString()` is OK.
        if (expression is PostfixExpression && target == node) return;
        if (expression is PrefixExpression && target == node) return;
      }

      // Something like `({1, 2, 3}).forEach(print);`.
      // The parens cannot be removed because then the curly brackets are not
      // interpreted as a set-or-map literal.
      if (node.wouldBeParsedAsStatementBlock) return;
    }
    rule.reportLint(node);
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
  /// Returns whether this directly contains whitespace.
  bool get directlyContainsWhitespace {
    var self = this;
    return self is AsExpression ||
        self is AssignmentExpression ||
        self is AwaitExpression ||
        self is BinaryExpression ||
        self is FunctionExpression ||
        self is IsExpression ||
        self is SwitchExpression ||
        // As in, `!(new Foo())`.
        (self is InstanceCreationExpression && self.keyword != null) ||
        // No TypedLiteral (ListLiteral, MapLiteral, SetLiteral) accepts `-`
        // or `!` as a prefix operator, but this method can be called
        // recursively, so this catches things like
        // `!(const [].contains(42))`.
        (self is TypedLiteral && self.constKeyword != null) ||
        // As in, `!(const List(3).contains(7))`, and chains like
        // `-(new List(3).skip(1).take(3).skip(1).length)`.
        (self is MethodInvocation && self.target.directlyContainsWhitespace) ||
        // As in, `-(new List(3).length)`, and chains like
        // `-(new List(3).length.bitLength.bitLength)`.
        (self is PropertyAccess && self.target.directlyContainsWhitespace);
  }
}

extension on Expression {
  /// Whether this expression is directly inside an argument list or the
  /// expression of a named argument.
  bool get isArgument =>
      parent is ArgumentList ||
      (parent is NamedExpression && parent?.parent is ArgumentList);

  /// Whether this expression is a sigle token.
  ///
  /// This excludes type literals because they often need to be parenthesized.
  bool get isOneToken =>
      this is SimpleIdentifier ||
      this is StringLiteral ||
      this is IntegerLiteral ||
      this is DoubleLiteral ||
      this is NullLiteral ||
      this is BooleanLiteral;
}
