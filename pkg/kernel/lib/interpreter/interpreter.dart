// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernerl.interpreter;

import '../ast.dart';

class NotImplemented {
  String message;

  NotImplemented(this.message);

  String toString() => message;
}

class Interpreter {
  Program program;
  Evaluator evaluator = new Evaluator();

  Interpreter(this.program);

  void run() {
    assert(program.libraries.isEmpty);
    Procedure mainMethod = program.mainMethod;
    Statement statementBlock = mainMethod.function.body;
    // Executes only ExpressionStatements and VariableDeclarations in the top
    // BlockStatement.
    if (statementBlock is Block) {
      var env = new Environment.empty();

      for (Statement s in statementBlock.statements) {
        if (s is ExpressionStatement) {
          evaluator.eval(s.expression, env);
        } else if (s is VariableDeclaration) {
          var value = evaluator.eval(s.initializer ?? new NullLiteral(), env);
          env.expand(s, value);
        } else {
          throw new NotImplemented('Evaluation for statement type '
              '${s.runtimeType} is not implemented.');
        }
      }
    } else {
      throw new NotImplemented('Evaluation for statement type '
          '${statementBlock.runtimeType} is not implemented.');
    }
  }
}

class InvalidExpressionError {
  InvalidExpression expression;

  InvalidExpressionError(this.expression);

  String toString() =>
      'Invalid expression at ${expression.location.toString()}';
}

class Binding {
  final VariableDeclaration variable;
  Value value;

  Binding(this.variable, this.value);
}

class Environment {
  final List<Binding> bindings = <Binding>[];
  final Environment parent;

  Environment.empty() : parent = null;
  Environment(this.parent);

  bool contains(VariableDeclaration variable) {
    for (Binding b in bindings.reversed) {
      if (identical(b.variable, variable)) return true;
    }
    return parent?.contains(variable) ?? false;
  }

  Binding lookupBinding(VariableDeclaration variable) {
    assert(contains(variable));
    for (Binding b in bindings) {
      if (identical(b.variable, variable)) return b;
    }
    return parent.lookupBinding(variable);
  }

  Value lookup(VariableDeclaration variable) {
    return lookupBinding(variable).value;
  }

  void assign(VariableDeclaration variable, Value value) {
    assert(contains(variable));
    lookupBinding(variable).value = value;
  }

  void expand(VariableDeclaration variable, Value value) {
    assert(!contains(variable));
    bindings.add(new Binding(variable, value));
  }
}

class Evaluator extends ExpressionVisitor1<Value> {
  Value eval(Expression expr, Environment env) => expr.accept1(this, env);

  Value defaultExpression(Expression node, env) {
    throw new NotImplemented('Evaluation for expressions of type '
        '${node.runtimeType} is not implemented.');
  }

  Value visitInvalidExpression1(InvalidExpression node, env) {
    throw new InvalidExpressionError(node);
  }

  Value visitVariableGet(VariableGet node, env) {
    return env.lookup(node.variable);
  }

  Value visitVariableSet(VariableSet node, env) {
    return env.assign(node.variable, eval(node.value, env));
  }

  Value visitStaticInvocation(StaticInvocation node, env) {
    if ('print' == node.name.toString()) {
      // Special evaluation of print.
      var res = eval(node.arguments.positional[0], env);
      print(res.value);
      return new NullValue();
    } else {
      throw new NotImplemented('Support for statement type '
          '${node.runtimeType} is not implemented');
    }
  }

  Value visitNot(Not node, env) {
    return new BoolValue(!eval(node.operand, env).asBool);
  }

  Value visitLogicalExpression(LogicalExpression node, env) {
    if ('||' == node.operator) {
      bool left = eval(node.left, env).asBool;
      return left
          ? new BoolValue(true)
          : new BoolValue(eval(node.right, env).asBool);
    } else {
      assert('&&' == node.operator);
      bool left = eval(node.left, env).asBool;
      return !left
          ? new BoolValue(false)
          : new BoolValue(eval(node.right, env).asBool);
    }
  }

  Value visitConditionalExpression(ConditionalExpression node, env) {
    if (eval(node.condition, env).asBool) {
      return eval(node.then, env);
    } else {
      return eval(node.otherwise, env);
    }
  }

  Value visitStringConcatenation(StringConcatenation node, env) {
    StringBuffer res = new StringBuffer();
    for (Expression e in node.expressions) {
      res.write(eval(e, env).value);
    }
    return new StringValue(res.toString());
  }

  // Evaluation of BasicLiterals.
  Value visitStringLiteral(StringLiteral node, env) =>
      new StringValue(node.value);
  Value visitIntLiteral(IntLiteral node, env) => new IntValue(node.value);
  Value visitDoubleLiteral(DoubleLiteral node, env) =>
      new DoubleValue(node.value);
  Value visitBoolLiteral(BoolLiteral node, env) => new BoolValue(node.value);
  Value visitNullLiteral(NullLiteral node, env) => new NullValue();

  Value visitLet(Let node, env) {
    var value = eval(node.variable.initializer, env);
    var letEnv = new Environment(env);
    letEnv.expand(node.variable, value);
    return eval(node.body, letEnv);
  }
}

abstract class Value {
  Object get value;
  bool get asBool;
}

class StringValue extends Value {
  String value;

  bool get asBool => false;

  StringValue(this.value);
}

class IntValue extends Value {
  int value;

  bool get asBool => false;

  IntValue(this.value);
}

class DoubleValue extends Value {
  double value;

  bool get asBool => false;

  DoubleValue(this.value);
}

class BoolValue extends Value {
  bool value;

  bool get asBool => value;

  BoolValue(this.value);
}

class NullValue extends Value {
  Object get value => null;
  bool get asBool => false;
}

Object error(obj) {
  // TODO: Implement accordingly with support for error handling.
  throw new ArgumentError(obj);
}
