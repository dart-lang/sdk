// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

import 'package:scrape/scrape.dart';

void main(List<String> arguments) {
  Scrape()
    ..addHistogram('Null-aware types')
    ..addHistogram('Null-aware chain lengths')
    // Boolean contexts where null-aware operators are used.
    ..addHistogram('Boolean contexts')
    // Expressions used to convert a null-aware expression to a Boolean for use in
    // a Boolean context.
    ..addHistogram('Boolean conversions')
    ..addVisitor(() => NullVisitor())
    ..runCommandLine(arguments);
}

class NullVisitor extends ScrapeVisitor {
  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.operator != null &&
        node.operator.type == TokenType.QUESTION_PERIOD) {
      _nullAware(node);
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.operator.type == TokenType.QUESTION_PERIOD) {
      _nullAware(node);
    }

    super.visitPropertyAccess(node);
  }

  void _nullAware(AstNode node) {
    var parent = node.parent;

    // Parentheses are purely syntactic.
    if (parent is ParenthesizedExpression) parent = parent.parent;

    // We want to treat a chain of null-aware operators as a single unit. We
    // use the top-most node (the last method in the chain) as the "real" one
    // because its parent is the context where the whole chain appears.
    if (parent is PropertyAccess &&
            parent.operator.type == TokenType.QUESTION_PERIOD &&
            parent.target == node ||
        parent is MethodInvocation &&
            parent.operator != null &&
            parent.operator.type == TokenType.QUESTION_PERIOD &&
            parent.target == node) {
      // This node is not the root of a null-aware chain, so skip it.
      return;
    }

    // This node is the root of a null-aware chain. See how long the chain is.
    var length = 0;
    var chain = node;
    while (true) {
      if (chain is PropertyAccess &&
          chain.operator.type == TokenType.QUESTION_PERIOD) {
        chain = (chain as PropertyAccess).target;
      } else if (chain is MethodInvocation &&
          chain.operator != null &&
          chain.operator.type == TokenType.QUESTION_PERIOD) {
        chain = (chain as MethodInvocation).target;
      } else {
        break;
      }

      length++;
    }

    record('Null-aware chain lengths', length.toString());

    void recordType(String label) {
      record('Null-aware types', label);
    }

    // See if the expression is an if condition.
    _checkCondition(node);

    if (parent is ExpressionStatement) {
      recordType("Expression statement 'foo?.bar();'");
      return;
    }

    if (parent is ReturnStatement) {
      recordType("Return statement 'return foo?.bar();'");
      return;
    }

    if (parent is BinaryExpression &&
        parent.operator.type == TokenType.BANG_EQ &&
        parent.leftOperand == node &&
        parent.rightOperand is BooleanLiteral &&
        (parent.rightOperand as BooleanLiteral).value == true) {
      recordType("Compare to true 'foo?.bar() != true'");
      return;
    }

    if (parent is BinaryExpression &&
        parent.operator.type == TokenType.EQ_EQ &&
        parent.leftOperand == node &&
        parent.rightOperand is BooleanLiteral &&
        (parent.rightOperand as BooleanLiteral).value == true) {
      recordType("Compare to true 'foo?.bar() == true'");
      return;
    }

    if (parent is BinaryExpression &&
        parent.operator.type == TokenType.BANG_EQ &&
        parent.leftOperand == node &&
        parent.rightOperand is BooleanLiteral &&
        (parent.rightOperand as BooleanLiteral).value == false) {
      recordType("Compare to false 'foo?.bar() != false'");
      return;
    }

    if (parent is BinaryExpression &&
        parent.operator.type == TokenType.EQ_EQ &&
        parent.leftOperand == node &&
        parent.rightOperand is BooleanLiteral &&
        (parent.rightOperand as BooleanLiteral).value == false) {
      recordType("Compare to false 'foo?.bar() == false'");
      return;
    }

    if (parent is BinaryExpression &&
        parent.operator.type == TokenType.BANG_EQ &&
        parent.leftOperand == node &&
        parent.rightOperand is NullLiteral) {
      recordType("Compare to null 'foo?.bar() != null'");
      return;
    }

    if (parent is BinaryExpression &&
        parent.operator.type == TokenType.EQ_EQ &&
        parent.leftOperand == node &&
        parent.rightOperand is NullLiteral) {
      recordType("Compare to null 'foo?.bar() == null'");
      return;
    }

    if (parent is BinaryExpression && parent.operator.type == TokenType.EQ_EQ) {
      recordType("Compare to other expression 'foo?.bar() == bang'");
      return;
    }

    if (parent is BinaryExpression &&
        parent.operator.type == TokenType.BANG_EQ) {
      recordType("Compare to other expression 'foo?.bar() != bang'");
      return;
    }

    if (parent is BinaryExpression &&
        parent.operator.type == TokenType.QUESTION_QUESTION &&
        parent.leftOperand == node) {
      recordType("Coalesce 'foo?.bar() ?? baz'");
      return;
    }

    if (parent is BinaryExpression &&
        parent.operator.type == TokenType.QUESTION_QUESTION &&
        parent.rightOperand == node) {
      recordType("Reverse coalesce 'baz ?? foo?.bar()'");
      return;
    }

    if (parent is ConditionalExpression && parent.condition == node) {
      recordType(
          "Condition in conditional expression 'foo?.bar() ? baz : bang");
      return;
    }

    if (parent is ConditionalExpression) {
      recordType("Then or else branch of conditional 'baz ? foo?.bar() : bang");
      return;
    }

    if (parent is AsExpression && parent.expression == node) {
      recordType("Cast expression 'foo?.bar as Baz'");
      return;
    }

    if (parent is AssignmentExpression && parent.leftHandSide == node) {
      recordType("Assign target 'foo?.bar ${parent.operator} baz'");
      return;
    }

    if (parent is AssignmentExpression && parent.rightHandSide == node) {
      recordType("Assign value 'baz = foo?.bar()'");
      return;
    }

    if (parent is VariableDeclaration && parent.initializer == node) {
      recordType("Variable initializer 'var baz = foo?.bar();'");
      return;
    }

    if (parent is NamedExpression) {
      recordType("Named argument 'fn(name: foo?.bar())'");
      return;
    }

    if (parent is ArgumentList && parent.arguments.contains(node)) {
      recordType("Positional argument 'fn(foo?.bar())'");
      return;
    }

    if (parent is AwaitExpression) {
      recordType("Await 'await foo?.bar()'");
      return;
    }

    if (parent is MapLiteralEntry || parent is ListLiteral) {
      recordType("Collection literal element '[foo?.bar()]'");
      return;
    }

    if (parent is ExpressionFunctionBody) {
      recordType("Member body 'member() => foo?.bar();'");
      return;
    }

    if (parent is InterpolationExpression) {
      recordType("String interpolation '\"blah \${foo?.bar()}\"'");
      return;
    }

    if (parent is BinaryExpression) {
      recordType('Uncategorized ${parent}');
      return;
    }

    recordType('Uncategorized ${parent.runtimeType}');

    // Find the surrounding statement containing the null-aware.
    while (node is Expression) {
      node = node.parent;
    }

    printNode(node);
  }

  void _checkCondition(AstNode node) {
    String expression;

    // Look at the expression that immediately wraps the null-aware to see if
    // it deals with it somehow, like "foo?.bar ?? otherwise".
    var parent = node.parent;
    if (parent is ParenthesizedExpression) parent = parent.parent;

    if (parent is BinaryExpression &&
        (parent.operator.type == TokenType.EQ_EQ ||
            parent.operator.type == TokenType.BANG_EQ ||
            parent.operator.type == TokenType.QUESTION_QUESTION) &&
        (parent.rightOperand is NullLiteral ||
            parent.rightOperand is BooleanLiteral)) {
      var binary = parent as BinaryExpression;
      expression = 'foo?.bar ${binary.operator} ${binary.rightOperand}';

      // This does handle it, so see the context where it appears.
      node = parent as Expression;
      if (node is ParenthesizedExpression) node = node.parent as Expression;
      parent = node.parent;
      if (parent is ParenthesizedExpression) parent = parent.parent;
    }

    String context;
    if (parent is IfStatement && node == parent.condition) {
      context = 'if';
    } else if (parent is BinaryExpression &&
        parent.operator.type == TokenType.AMPERSAND_AMPERSAND) {
      context = '&&';
    } else if (parent is BinaryExpression &&
        parent.operator.type == TokenType.BAR_BAR) {
      context = '||';
    } else if (parent is WhileStatement && node == parent.condition) {
      context = 'while';
    } else if (parent is DoStatement && node == parent.condition) {
      context = 'do';
    } else if (parent is ForStatement &&
        parent.forLoopParts is ForParts &&
        node == (parent.forLoopParts as ForParts).condition) {
      context = 'for';
    } else if (parent is ConditionalExpression && node == parent.condition) {
      context = '?:';
    }

    if (context != null) {
      record('Boolean contexts', context);

      if (expression != null) {
        record('Boolean conversions', expression);
      } else {
        record('Boolean conversions', 'unknown: $node');
      }
    }
  }
}
