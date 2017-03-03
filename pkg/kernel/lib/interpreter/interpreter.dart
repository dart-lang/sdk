// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernerl.interpreter;

import 'dart:collection';
import '../ast.dart';

class NotImplemented {
  String message;

  NotImplemented(this.message);

  String toString() => message;
}

class Interpreter {
  Program program;

  Interpreter(this.program);

  void evalProgram() {
    assert(program.libraries.isEmpty);
    Procedure mainMethod = program.mainMethod;
    Statement statementBlock = mainMethod.function.body;
    // Evaluate only statement with one expression, ExpressionStatement, which
    // is StaticInvocation of the method print.
    if (statementBlock is Block) {
      Statement statement = statementBlock.statements.first;
      if (statement is ExpressionStatement) {
        statement.expression.accept1(new ExpressionEval1(),
            new ExpressionState(new HashMap<String, Object>()));
      }
    } else {
      throw new NotImplemented('Evaluation for statement type '
          '${statementBlock.runtimeType} is not implemented');
    }
  }
}

class InvalidExpressionError {
  InvalidExpression expression;

  InvalidExpressionError(this.expression);

  String toString() => 'Invalid expression at '
      '${expression.location.toString()}';
}

class ExpressionState {
  Map<String, Object> environment;

  ExpressionState(this.environment);
}

class ExpressionEval1 extends ExpressionVisitor1<Object> {
  @override
  Object defaultExpression(Expression node, arg) {
    throw new NotImplemented('Evaluation for expressions of type '
        '${node.runtimeType} is not implemented.');
  }

  Object visitInvalidExpression1(InvalidExpression node, arg) =>
      throw new InvalidExpressionError(node);

  Object visitStaticInvocation(StaticInvocation node, arg) {
    if ('print' == node.name.toString()) {
      // Special evaluation of print.
      var res = node.arguments.positional[0].accept1(this, arg);
      print(res);
    } else {
      throw new NotImplemented('Support for statement type '
          '${node.runtimeType} is not implemented');
    }
  }

  // Evaluation of BasicLiterals.
  Object visitStringLiteral(StringLiteral node, arg) => node.value;
  Object visitIntLiteral(IntLiteral node, arg) => node.value;
  Object visitDoubleLiteral(DoubleLiteral node, arg) => node.value;
  Object visitBoolLiteral(BoolLiteral node, arg) => node.value;
  Object visitNullLiteral(NullLiteral node, arg) => node.value;
}
