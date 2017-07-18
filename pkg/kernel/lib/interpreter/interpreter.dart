// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.interpreter;

import '../ast.dart';
import '../ast.dart' as ast show Class;

import '../log.dart';
export '../log.dart';

class NotImplemented {
  String message;

  NotImplemented(this.message);

  String toString() => message;
}

class Interpreter {
  Program program;
  StatementExecuter visitor = new StatementExecuter();

  Interpreter(this.program);

  void run() {
    assert(program.libraries.isEmpty);
    Procedure mainMethod = program.mainMethod;

    if (mainMethod == null) return;

    Statement statementBlock = mainMethod.function.body;
    ExecConfiguration configuration = new ExecConfiguration(
        statementBlock, new Environment.empty(), const State.initial());
    visitor.trampolinedExecution(configuration);
  }
}

class Location {
  Value value;

  Location(this.value);
}

class Binding {
  final VariableDeclaration variable;
  final Location location;

  Binding(this.variable, this.location);
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
    return lookupBinding(variable).location.value;
  }

  void assign(VariableDeclaration variable, Value value) {
    assert(contains(variable));
    lookupBinding(variable).location.value = value;
  }

  Environment extend(VariableDeclaration variable, Value value) {
    assert(!contains(variable));
    return new Environment(this)
      ..bindings.add(new Binding(variable, new Location(value)));
  }
}

/// Evaluate expressions.
class Evaluator extends ExpressionVisitor1<Configuration, EvalConfiguration> {
  Configuration eval(Expression expr, EvalConfiguration config) =>
      expr.accept1(this, config);

  Configuration evalList(List<InterpreterExpression> list, Environment env,
      ApplicationContinuation cont) {
    if (list.isNotEmpty) {
      return new EvalConfiguration(list.first.expression, env,
          new ExpressionListEK(list.first, list.skip(1), env, cont));
    }
    return new ApplicationConfiguration(cont, <InterpreterValue>[]);
  }

  Configuration defaultExpression(Expression node, EvalConfiguration config) {
    throw new NotImplemented('Evaluation for expressions of type '
        '${node.runtimeType} is not implemented.');
  }

  Configuration visitInvalidExpression1(
      InvalidExpression node, EvalConfiguration config) {
    throw 'Invalid expression at ${node.location.toString()}';
  }

  Configuration visitVariableGet(VariableGet node, EvalConfiguration config) {
    Value value = config.environment.lookup(node.variable);
    return new ValuePassingConfiguration(config.continuation, value);
  }

  Configuration visitVariableSet(VariableSet node, EvalConfiguration config) {
    var cont = new VariableSetEK(
        node.variable, config.environment, config.continuation);
    return new EvalConfiguration(node.value, config.environment, cont);
  }

  Configuration visitPropertyGet(PropertyGet node, EvalConfiguration config) {
    var cont = new PropertyGetEK(node.name, config.continuation);
    return new EvalConfiguration(node.receiver, config.environment, cont);
  }

  Configuration visitPropertySet(PropertySet node, EvalConfiguration config) {
    var cont = new PropertySetEK(
        node.value, node.name, config.environment, config.continuation);
    return new EvalConfiguration(node.receiver, config.environment, cont);
  }

  Configuration visitStaticGet(StaticGet node, EvalConfiguration config) =>
      defaultExpression(node, config);
  Configuration visitStaticSet(StaticSet node, EvalConfiguration config) =>
      defaultExpression(node, config);

  Configuration visitStaticInvocation(
      StaticInvocation node, EvalConfiguration config) {
    if ('print' == node.name.toString()) {
      var cont = new PrintEK(config.continuation);
      return new EvalConfiguration(
          node.arguments.positional.first, config.environment, cont);
    } else {
      log.info('static-invocation-${node.target.name.toString()}\n');

      List<InterpreterExpression> args =
          _createArgumentExpressionList(node.arguments, node.target.function);
      ApplicationContinuation cont =
          new StaticInvocationA(node.target.function, config.continuation);
      return new EvalListConfiguration(args, config.environment, cont);
    }
  }

  Configuration visitMethodInvocation(
      MethodInvocation node, EvalConfiguration config) {
    // Currently supports only method invocation with <2 arguments and is used
    // to evaluate implemented operators for int, double and String values.
    var cont = new MethodInvocationEK(
        node.arguments, node.name, config.environment, config.continuation);

    return new EvalConfiguration(node.receiver, config.environment, cont);
  }

  Configuration visitConstructorInvocation(
          ConstructorInvocation node, EvalConfiguration config) =>
      defaultExpression(node, config);

  Configuration visitNot(Not node, EvalConfiguration config) {
    return new EvalConfiguration(
        node.operand, config.environment, new NotEK(config.continuation));
  }

  Configuration visitLogicalExpression(
      LogicalExpression node, EvalConfiguration config) {
    if ('||' == node.operator) {
      var cont = new OrEK(node.right, config.environment, config.continuation);
      return new EvalConfiguration(node.left, config.environment, cont);
    } else {
      assert('&&' == node.operator);
      var cont = new AndEK(node.right, config.environment, config.continuation);
      return new EvalConfiguration(node.left, config.environment, cont);
    }
  }

  Configuration visitConditionalExpression(
      ConditionalExpression node, EvalConfiguration config) {
    var cont = new ConditionalEK(
        node.then, node.otherwise, config.environment, config.continuation);
    return new EvalConfiguration(node.condition, config.environment, cont);
  }

  Configuration visitStringConcatenation(
      StringConcatenation node, EvalConfiguration config) {
    var cont = new StringConcatenationA(config.continuation);
    var expressions = node.expressions
        .map((Expression e) => new PositionalExpression(e))
        .toList();
    return new EvalListConfiguration(expressions, config.environment, cont);
  }

  Configuration visitThisExpression(
          ThisExpression node, EvalConfiguration config) =>
      defaultExpression(node, config);

  // Evaluation of BasicLiterals.
  Configuration visitStringLiteral(
      StringLiteral node, EvalConfiguration config) {
    return new ValuePassingConfiguration(
        config.continuation, new StringValue(node.value));
  }

  Configuration visitIntLiteral(IntLiteral node, EvalConfiguration config) {
    return new ValuePassingConfiguration(
        config.continuation, new IntValue(node.value));
  }

  Configuration visitDoubleLiteral(
      DoubleLiteral node, EvalConfiguration config) {
    return new ValuePassingConfiguration(
        config.continuation, new DoubleValue(node.value));
  }

  Configuration visitBoolLiteral(BoolLiteral node, EvalConfiguration config) {
    Value value = node.value ? Value.trueInstance : Value.falseInstance;
    return new ValuePassingConfiguration(config.continuation, value);
  }

  Configuration visitNullLiteral(NullLiteral node, EvalConfiguration config) {
    return new ValuePassingConfiguration(
        config.continuation, Value.nullInstance);
  }

  Configuration visitLet(Let node, EvalConfiguration config) {
    var letCont = new LetEK(
        node.variable, node.body, config.environment, config.continuation);
    return new EvalConfiguration(
        node.variable.initializer, config.environment, letCont);
  }
}

/// Represents a state for statement execution.
class State {
  final Label labels;
  // TODO: Add switch labels.
  // TODO: Add component for exception support.
  final ExpressionContinuation returnContinuation;
  final StatementContinuation continuation;

  State(this.labels, this.returnContinuation, this.continuation);

  const State.initial()
      : labels = null,
        returnContinuation = null,
        continuation = null;

  State withBreak(Statement stmt, Environment env) {
    Label breakLabels = new Label(stmt, env, continuation, labels);
    return new State(breakLabels, returnContinuation, continuation);
  }

  State withReturnContinuation(ExpressionContinuation returnCont) {
    return new State(labels, returnCont, continuation);
  }

  State withContinuation(StatementContinuation cont) {
    return new State(labels, returnContinuation, cont);
  }

  Label lookupLabel(LabeledStatement s) {
    assert(labels != null);
    return labels.lookupLabel(s);
  }
}

/// Represents a labeled statement, the corresponding continuation and the
/// enclosing label.
class Label {
  final LabeledStatement statement;
  final Environment environment;
  final StatementContinuation continuation;
  final Label enclosingLabel;

  Label(
      this.statement, this.environment, this.continuation, this.enclosingLabel);

  Label lookupLabel(LabeledStatement s) {
    if (identical(s, statement)) return this;
    assert(enclosingLabel != null);
    return enclosingLabel.lookupLabel(s);
  }
}

// ------------------------------------------------------------------------
//                           Configurations
// ------------------------------------------------------------------------

abstract class Configuration {
  /// Executes the current and returns the next configuration.
  Configuration step(StatementExecuter executer);
}

/// Configuration for evaluating an [Expression].
class EvalConfiguration extends Configuration {
  final Expression expression;

  /// Environment in which the expression is evaluated.
  final Environment environment;

  /// Next continuation to be applied.
  final Continuation continuation;

  EvalConfiguration(this.expression, this.environment, this.continuation);

  Configuration step(StatementExecuter executer) =>
      executer.eval(expression, this);
}

/// Configuration for evaluating a `List<InterpreterExpression>`.
class EvalListConfiguration extends Configuration {
  final List<InterpreterExpression> expressions;
  final Environment environment;
  final ApplicationContinuation continuation;

  EvalListConfiguration(this.expressions, this.environment, this.continuation);

  Configuration step(StatementExecuter executer) =>
      executer.evalList(expressions, environment, continuation);
}

/// Configuration for execution of a [Statement].
class ExecConfiguration extends Configuration {
  final Statement currentStatement;
  final Environment environment;
  final State state;

  ExecConfiguration(this.currentStatement, this.environment, this.state);

  Configuration step(StatementExecuter executer) =>
      executer.exec(currentStatement, this);
}

/// Configuration for applying a [StatementContinuation] to an [Environment].
class ForwardConfiguration extends Configuration {
  final StatementContinuation continuation;
  final Environment environment;

  ForwardConfiguration(this.continuation, this.environment);

  Configuration step(StatementExecuter _) => continuation?.call(environment);
}

/// Configuration for applying [ExpressionContinuation] to a [Value].
class ValuePassingConfiguration extends Configuration {
  final ExpressionContinuation continuation;
  final Value value;

  ValuePassingConfiguration(this.continuation, this.value);

  Configuration step(StatementExecuter _) => continuation(value);
}

/// Configuration for applying an [ApplicationContinuation] to a
/// `List<InterpreterValue>`.
class ApplicationConfiguration extends Configuration {
  final ApplicationContinuation continuation;
  final List<InterpreterValue> values;

  ApplicationConfiguration(this.continuation, this.values);

  Configuration step(StatementExecuter _) => continuation(values);
}

// ------------------------------------------------------------------------
//            Interpreter Expressions and Values
// ------------------------------------------------------------------------

abstract class InterpreterExpression {
  Expression get expression;

  InterpreterValue assignValue(Value v);
}

class PositionalExpression extends InterpreterExpression {
  final Expression expression;

  PositionalExpression(this.expression);

  InterpreterValue assignValue(Value v) => new PositionalValue(v);
}

class NamedExpression extends InterpreterExpression {
  final String name;
  final Expression expression;

  NamedExpression(this.name, this.expression);
  InterpreterValue assignValue(Value v) => new NamedValue(name, v);
}

class FieldInitializerExpression extends InterpreterExpression {
  final Field field;
  final Expression expression;

  FieldInitializerExpression(this.field, this.expression);

  InterpreterValue assignValue(Value v) => new FieldInitializerValue(field, v);
}

abstract class InterpreterValue {
  Value get value;
}

class PositionalValue extends InterpreterValue {
  final Value value;

  PositionalValue(this.value);
}

class NamedValue extends InterpreterValue {
  final String name;
  final Value value;

  NamedValue(this.name, this.value);
}

class FieldInitializerValue extends InterpreterValue {
  final Field field;
  final Value value;

  FieldInitializerValue(this.field, this.value);
}

abstract class Continuation {}

// ------------------------------------------------------------------------
//                        Statement Continuations
// ------------------------------------------------------------------------

/// Represents a the continuation for the execution of the next statement of
/// the program.
///
/// There are various kinds of [StatementContinuation]s and their names are
/// suffixed with "SK".
abstract class StatementContinuation extends Continuation {
  Configuration call(Environment env);
}

/// Applies the expression continuation to the provided value.
class ExitSK extends StatementContinuation {
  final ExpressionContinuation continuation;
  final Value value;

  ExitSK(this.continuation, this.value);

  Configuration call(Environment _) =>
      new ValuePassingConfiguration(continuation, value);
}

/// Executes the next statement from a block with the corresponding environment
/// or proceeds with next statement continuation.
class BlockSK extends StatementContinuation {
  final List<Statement> statements;
  final Environment enclosingEnv;
  final State state;

  BlockSK(this.statements, this.enclosingEnv, this.state);

  BlockSK.fromConfig(this.statements, ExecConfiguration conf)
      : enclosingEnv = conf.environment,
        state = conf.state;

  Configuration call(Environment env) {
    if (statements.isEmpty) {
      return new ForwardConfiguration(state.continuation, enclosingEnv);
    }
    // Proceed with the execution statement when there are some remaining to
    // be executed.
    var cont = new BlockSK(statements.skip(1).toList(), enclosingEnv, state);
    return new ExecConfiguration(
        statements.first, env, state.withContinuation(cont));
  }
}

class NewSK extends StatementContinuation {
  final ExpressionContinuation continuation;
  final Location location;

  NewSK(this.continuation, this.location);

  Configuration call(Environment _) =>
      new ValuePassingConfiguration(continuation, location.value);
}

class WhileConditionSK extends StatementContinuation {
  final Expression condition;
  final Statement body;
  final Environment enclosingEnv;
  final State state;

  WhileConditionSK(this.condition, this.body, this.enclosingEnv, this.state);

  Configuration call(Environment _) {
    // Evaluate the condition for the while loop execution.
    var cont = new WhileConditionEK(condition, body, enclosingEnv, state);
    return new EvalConfiguration(condition, enclosingEnv, cont);
  }
}

// ------------------------------------------------------------------------
//                       Application Continuations
// ------------------------------------------------------------------------

/// Represents the continuation called after the evaluation of argument
/// expressions.
///
/// There are various kinds of [ApplicationContinuation] and their names are
/// suffixed with "A".
abstract class ApplicationContinuation extends Continuation {
  Configuration call(List<InterpreterValue> values);

  /// Binds actual argument values to formal parameters of the function in a
  /// new environment or in the provided initial environment.
  /// TODO: Add checks for validation of arguments according to spec.
  static Environment createEnvironment(
      FunctionNode function, List<InterpreterValue> args,
      [Environment parentEnv]) {
    Environment newEnv = new Environment(parentEnv ?? new Environment.empty());

    List<PositionalValue> positional = args.reversed
        .where((InterpreterValue av) => av is PositionalValue)
        .toList();

    // Add positional parameters.
    for (int i = 0; i < positional.length; ++i) {
      newEnv =
          newEnv.extend(function.positionalParameters[i], positional[i].value);
    }

    Map<String, Value> named = new Map.fromIterable(
        args.where((InterpreterValue av) => av is NamedValue),
        key: (NamedValue av) => av.name,
        value: (NamedValue av) => av.value);

    // Add named parameters.
    for (VariableDeclaration v in function.namedParameters) {
      newEnv = newEnv.extend(v, named[v.name.toString()]);
    }

    return newEnv;
  }
}

/// Represents the application continuation called after the evaluation of all
/// argument expressions for an invocation.
class ValueA extends ApplicationContinuation {
  final InterpreterValue value;
  final ApplicationContinuation applicationContinuation;

  ValueA(this.value, this.applicationContinuation);

  Configuration call(List<InterpreterValue> args) {
    args.add(value);
    return new ApplicationConfiguration(applicationContinuation, args);
  }
}

class StringConcatenationA extends ApplicationContinuation {
  final ExpressionContinuation continuation;

  StringConcatenationA(this.continuation);

  Configuration call(List<InterpreterValue> values) {
    StringBuffer result = new StringBuffer();
    for (InterpreterValue v in values.reversed) {
      result.write(v.value.value);
    }
    return new ValuePassingConfiguration(
        continuation, new StringValue(result.toString()));
  }
}

/// Represents the application continuation for static invocation.
class StaticInvocationA extends ApplicationContinuation {
  final FunctionNode function;
  final ExpressionContinuation continuation;

  StaticInvocationA(this.function, this.continuation);

  Configuration call(List<InterpreterValue> argValues) {
    Environment functionEnv =
        ApplicationContinuation.createEnvironment(function, argValues);
    State bodyState = new State(
        null, continuation, new ExitSK(continuation, Value.nullInstance));

    return new ExecConfiguration(function.body, functionEnv, bodyState);
  }
}

// ------------------------------------------------------------------------
//                           Expression Continuations
// ------------------------------------------------------------------------

/// Represents an expression continuation.
///
/// There are various kinds of [ExpressionContinuation]s and their names are
/// suffixed with "EK".
abstract class ExpressionContinuation extends Continuation {
  Configuration call(Value v);
}

/// Represents a continuation that returns the next [ExecConfiguration]
/// to be executed.
class ExpressionEK extends ExpressionContinuation {
  final StatementContinuation continuation;
  final Environment environment;

  ExpressionEK(this.continuation, this.environment);

  Configuration call(Value _) {
    return new ForwardConfiguration(continuation, environment);
  }
}

class PrintEK extends ExpressionContinuation {
  final ExpressionContinuation continuation;

  PrintEK(this.continuation);

  Configuration call(Value v) {
    log.info('print(${v.value.runtimeType}: ${v.value})\n');
    print(v.value);
    return new ValuePassingConfiguration(continuation, Value.nullInstance);
  }
}

class PropertyGetEK extends ExpressionContinuation {
  final Name name;
  final ExpressionContinuation continuation;

  PropertyGetEK(this.name, this.continuation);

  Configuration call(Value receiver) {
    // TODO: CPS the invocation of the getter.
    Value propertyValue = receiver.class_.lookupGetter(name)(receiver);
    return new ValuePassingConfiguration(continuation, propertyValue);
  }
}

class PropertySetEK extends ExpressionContinuation {
  final Expression value;
  final Name setterName;
  final Environment environment;
  final ExpressionContinuation continuation;

  PropertySetEK(
      this.value, this.setterName, this.environment, this.continuation);

  Configuration call(Value receiver) {
    var cont = new SetterEK(receiver, setterName, continuation);
    return new EvalConfiguration(value, environment, cont);
  }
}

class SetterEK extends ExpressionContinuation {
  final Value receiver;
  final Name name;
  final ExpressionContinuation continuation;

  SetterEK(this.receiver, this.name, this.continuation);

  Configuration call(Value v) {
    Setter setter = receiver.class_.lookupSetter(name);
    setter(receiver, v);
    return new ValuePassingConfiguration(continuation, v);
  }
}

/// Represents a continuation to be called after the evaluation of an actual
/// argument for function invocation.
class ExpressionListEK extends ExpressionContinuation {
  final InterpreterExpression currentExpression;
  final List<InterpreterExpression> expressions;
  final Environment environment;
  final ApplicationContinuation applicationContinuation;

  ExpressionListEK(this.currentExpression, this.expressions, this.environment,
      this.applicationContinuation);

  Configuration call(Value v) {
    ValueA app =
        new ValueA(currentExpression.assignValue(v), applicationContinuation);
    return new EvalListConfiguration(expressions, environment, app);
  }
}

class MethodInvocationEK extends ExpressionContinuation {
  final Arguments arguments;
  final Name methodName;
  final Environment environment;
  final ExpressionContinuation continuation;

  MethodInvocationEK(
      this.arguments, this.methodName, this.environment, this.continuation);

  Configuration call(Value receiver) {
    if (arguments.positional.isEmpty) {
      Value returnValue = receiver.invokeMethod(methodName);
      return new ValuePassingConfiguration(continuation, returnValue);
    }
    var cont = new ArgumentsEK(
        receiver, methodName, arguments, environment, continuation);

    return new EvalConfiguration(arguments.positional.first, environment, cont);
  }
}

class ArgumentsEK extends ExpressionContinuation {
  final Value receiver;
  final Name methodName;
  final Arguments arguments;
  final Environment environment;
  final ExpressionContinuation continuation;

  ArgumentsEK(this.receiver, this.methodName, this.arguments, this.environment,
      this.continuation);

  Configuration call(Value value) {
    // Currently evaluates only one argument, for simple method invocations
    // with 1 argument.
    Value returnValue = receiver.invokeMethod(methodName, value);
    return new ValuePassingConfiguration(continuation, returnValue);
  }
}

class VariableSetEK extends ExpressionContinuation {
  final VariableDeclaration variable;
  final Environment environment;
  final ExpressionContinuation continuation;

  VariableSetEK(this.variable, this.environment, this.continuation);

  Configuration call(Value value) {
    environment.assign(variable, value);
    return new ValuePassingConfiguration(continuation, value);
  }
}

class NotEK extends ExpressionContinuation {
  final ExpressionContinuation continuation;

  NotEK(this.continuation);

  Configuration call(Value value) {
    Value notValue = identical(Value.trueInstance, value)
        ? Value.falseInstance
        : Value.trueInstance;
    return new ValuePassingConfiguration(continuation, notValue);
  }
}

class OrEK extends ExpressionContinuation {
  final Expression right;
  final Environment environment;
  final ExpressionContinuation continuation;

  OrEK(this.right, this.environment, this.continuation);

  Configuration call(Value left) {
    return identical(Value.trueInstance, left)
        ? new ValuePassingConfiguration(continuation, Value.trueInstance)
        : new EvalConfiguration(right, environment, continuation);
  }
}

class AndEK extends ExpressionContinuation {
  final Expression right;
  final Environment environment;
  final ExpressionContinuation continuation;

  AndEK(this.right, this.environment, this.continuation);

  Configuration call(Value left) {
    return identical(Value.falseInstance, left)
        ? new ValuePassingConfiguration(continuation, Value.falseInstance)
        : new EvalConfiguration(right, environment, continuation);
  }
}

class ConditionalEK extends ExpressionContinuation {
  final Expression then;
  final Expression otherwise;
  final Environment environment;
  final ExpressionContinuation continuation;

  ConditionalEK(this.then, this.otherwise, this.environment, this.continuation);

  Configuration call(Value value) {
    return identical(Value.trueInstance, value)
        ? new EvalConfiguration(then, environment, continuation)
        : new EvalConfiguration(otherwise, environment, continuation);
  }
}

class LetEK extends ExpressionContinuation {
  final VariableDeclaration variable;
  final Expression letBody;
  final Environment environment;
  final ExpressionContinuation continuation;

  LetEK(this.variable, this.letBody, this.environment, this.continuation);

  Configuration call(Value value) {
    var letEnv = new Environment(environment);
    letEnv.extend(variable, value);
    return new EvalConfiguration(letBody, letEnv, continuation);
  }
}

/// Represents the continuation for the condition expression in [WhileStatement].
class WhileConditionEK extends ExpressionContinuation {
  final Expression condition;
  final Statement body;
  final Environment enclosingEnv;
  final State state;

  WhileConditionEK(this.condition, this.body, this.enclosingEnv, this.state);

  Configuration call(Value v) {
    if (identical(v, Value.falseInstance)) {
      return new ForwardConfiguration(state.continuation, enclosingEnv);
    }
    var cont = new WhileConditionSK(condition, body, enclosingEnv, state);
    return new ExecConfiguration(
        body, enclosingEnv, state.withContinuation(cont));
  }
}

/// Represents the continuation for the condition expression in [IfStatement].
class IfConditionEK extends ExpressionContinuation {
  final Statement then;
  final Statement otherwise;
  final Environment environment;
  final State state;

  IfConditionEK(this.then, this.otherwise, this.environment, this.state);

  Configuration call(Value v) {
    if (identical(v, Value.trueInstance)) {
      log.info("if-then\n");
      return new ExecConfiguration(then, environment, state);
    } else if (otherwise != null) {
      log.info("if-otherwise\n");
      return new ExecConfiguration(otherwise, environment, state);
    }
    return new ForwardConfiguration(state.continuation, environment);
  }
}

/// Represents the continuation for the initializer expression in
/// [VariableDeclaration].
class VariableInitializerEK extends ExpressionContinuation {
  final VariableDeclaration variable;
  final Environment environment;
  final StatementContinuation continuation;

  VariableInitializerEK(this.variable, this.environment, this.continuation);

  Configuration call(Value v) {
    return new ForwardConfiguration(
        continuation, environment.extend(variable, v));
  }
}

/// Executes statements.
///
/// Execution of a statement completes in one of the following ways:
/// - It completes normally, in which case the execution proceeds to applying
/// the next continuation.
/// - It breaks with a label, in which case the corresponding continuation is
/// returned and applied.
/// - It returns with or without value, in which case the return continuation is
/// returned and applied accordingly.
/// - It throws, in which case the handler is returned and applied accordingly.
class StatementExecuter
    extends StatementVisitor1<Configuration, ExecConfiguration> {
  Evaluator evaluator = new Evaluator();

  void trampolinedExecution(Configuration configuration) {
    while (configuration != null) {
      configuration = configuration.step(this);
    }
  }

  Configuration exec(Statement statement, ExecConfiguration conf) =>
      statement.accept1(this, conf);
  Configuration eval(Expression expression, EvalConfiguration config) =>
      evaluator.eval(expression, config);
  Configuration evalList(
          List<InterpreterExpression> es, Environment env, Continuation cont) =>
      evaluator.evalList(es, env, cont);

  Configuration defaultStatement(Statement node, ExecConfiguration conf) {
    throw notImplemented(
        m: "Execution is not implemented for statement:\n$node ");
  }

  Configuration visitInvalidStatement(
      InvalidStatement node, ExecConfiguration conf) {
    throw "Invalid statement at ${node.location}";
  }

  Configuration visitExpressionStatement(
      ExpressionStatement node, ExecConfiguration conf) {
    var cont = new ExpressionEK(conf.state.continuation, conf.environment);
    return new EvalConfiguration(node.expression, conf.environment, cont);
  }

  Configuration visitBlock(Block node, ExecConfiguration conf) {
    if (node.statements.isEmpty) {
      return new ForwardConfiguration(
          conf.state.continuation, conf.environment);
    }

    var env = new Environment(conf.environment);
    var cont = new BlockSK.fromConfig(node.statements.skip(1).toList(), conf);
    return new ExecConfiguration(
        node.statements.first, env, conf.state.withContinuation(cont));
  }

  Configuration visitEmptyStatement(
      EmptyStatement node, ExecConfiguration conf) {
    return new ForwardConfiguration(conf.state.continuation, conf.environment);
  }

  Configuration visitIfStatement(IfStatement node, ExecConfiguration conf) {
    var cont = new IfConditionEK(
        node.then, node.otherwise, conf.environment, conf.state);

    return new EvalConfiguration(node.condition, conf.environment, cont);
  }

  Configuration visitLabeledStatement(
      LabeledStatement node, ExecConfiguration conf) {
    return new ExecConfiguration(node.body, conf.environment,
        conf.state.withBreak(node, conf.environment));
  }

  Configuration visitBreakStatement(
      BreakStatement node, ExecConfiguration conf) {
    Label l = conf.state.lookupLabel(node.target);
    return new ForwardConfiguration(l.continuation, l.environment);
  }

  Configuration visitWhileStatement(
      WhileStatement node, ExecConfiguration conf) {
    var cont = new WhileConditionEK(
        node.condition, node.body, conf.environment, conf.state);

    return new EvalConfiguration(node.condition, conf.environment, cont);
  }

  Configuration visitDoStatement(DoStatement node, ExecConfiguration conf) {
    var cont = new WhileConditionSK(
        node.condition, node.body, conf.environment, conf.state);

    return new ExecConfiguration(
        node.body, conf.environment, conf.state.withContinuation(cont));
  }

  Configuration visitReturnStatement(
      ReturnStatement node, ExecConfiguration conf) {
    assert(conf.state.returnContinuation != null);
    log.info('return\n');
    if (node.expression == null) {
      return new ValuePassingConfiguration(
          conf.state.returnContinuation, Value.nullInstance);
    }

    return new EvalConfiguration(
        node.expression, conf.environment, conf.state.returnContinuation);
  }

  Configuration visitVariableDeclaration(
      VariableDeclaration node, ExecConfiguration conf) {
    if (node.initializer != null) {
      var cont = new VariableInitializerEK(
          node, conf.environment, conf.state.continuation);
      return new EvalConfiguration(node.initializer, conf.environment, cont);
    }
    return new ForwardConfiguration(conf.state.continuation,
        conf.environment.extend(node, Value.nullInstance));
  }
}

// ------------------------------------------------------------------------
//                                VALUES
// ------------------------------------------------------------------------

typedef Value Getter(Value receiver);
typedef void Setter(Value receiver, Value value);

class Class {
  static final Map<Reference, Class> _classes = <Reference, Class>{};

  Class superclass;
  List<Field> instanceFields = <Field>[];
  List<Field> staticFields = <Field>[];
  // Implicit getters and setters for instance Fields.
  Map<Name, Getter> getters = <Name, Getter>{};
  Map<Name, Setter> setters = <Name, Setter>{};
  // The initializers of static fields are evaluated the first time the field
  // is accessed.
  List<Value> staticFieldValues = <Value>[];

  List<Procedure> methods = <Procedure>[];

  int get instanceSize => instanceFields.length;

  factory Class(Reference classRef) {
    return _classes.putIfAbsent(
        classRef, () => new Class._internal(classRef.asClass));
  }

  Class._internal(ast.Class currentClass) {
    if (currentClass.superclass != null) {
      superclass = new Class(currentClass.superclass.reference);
    }

    _populateInstanceFields(currentClass);
    // TODO: Populate methods.
  }

  Getter lookupGetter(Name name) {
    Getter getter = getters[name];
    if (getter != null) return getter;
    if (superclass != null) return superclass.lookupGetter(name);
    return (Value receiver) => notImplemented(obj: name);
  }

  Setter lookupSetter(Name name) {
    Setter setter = setters[name];
    if (setter != null) return setter;
    if (superclass != null) return superclass.lookupSetter(name);
    return (Value receiver, Value value) => notImplemented(obj: name);
  }

  Value getProperty(ObjectValue object, Member member) {
    if (member is Field) {
      int index = instanceFields.indexOf(member);
      // TODO: throw NoSuchMethodError instead.
      if (index < 0) return notImplemented(m: 'NoSuchMethod: ${member}');
      return object.fields[index];
    }
    return notImplemented(obj: member);
  }

  Value setProperty(ObjectValue object, Member member, Value value) {
    if (member is Field) {
      int index = instanceFields.indexOf(member);
      // TODO: throw NoSuchMethodError instead.
      if (index < 0) return notImplemented(m: 'NoSuchMethod: ${member}');
      object.fields[index] = value;
      return Value.nullInstance;
    }
    return notImplemented(obj: member);
  }

  /// Populates instance variables and the corresponding implicit getters and
  /// setters for the current class and its superclass recursively.
  _populateInstanceFields(ast.Class class_) {
    if (class_.superclass != null) {
      _populateInstanceFields(class_.superclass);
    }

    for (Field f in class_.fields) {
      if (f.isStatic) continue;
      instanceFields.add(f);
      assert(f.hasImplicitGetter);

      int currentFieldIndex = instanceFields.length - 1;

      // Shadowing an inherited getter with the same name.
      getters[f.name] = (Value receiver) => receiver.fields[currentFieldIndex];
      if (f.hasImplicitSetter) {
        // Shadowing an inherited setter with the same name.
        setters[f.name] = (Value receiver, Value value) =>
            receiver.fields[currentFieldIndex] = value;
      }
    }
  }
}

abstract class Value {
  Class get class_;
  List<Value> get fields;
  Object get value;

  static final NullValue nullInstance = const NullValue();
  static final BoolValue trueInstance = const BoolValue(true);
  static final BoolValue falseInstance = const BoolValue(false);

  const Value();

  BoolValue toBoolean() {
    return identical(this, Value.trueInstance)
        ? Value.trueInstance
        : Value.falseInstance;
  }

  BoolValue equals(Value other) =>
      value == other?.value ? Value.trueInstance : Value.falseInstance;

  Value invokeMethod(Name name, [Value arg]) {
    if (name.toString() == "==") return equals(arg);
    throw notImplemented(obj: name);
  }
}

class ObjectValue extends Value {
  Class class_;
  List<Value> fields;
  Object get value => this;

  ObjectValue(this.class_, this.fields);
}

abstract class LiteralValue extends Value {
  Class get class_ =>
      notImplemented(m: "Loading class for literal is not implemented.");
  List<Value> get fields =>
      notImplemented(m: "Literal value does not have fields");

  const LiteralValue();
}

class StringValue extends LiteralValue {
  final String value;

  static final operators = <String, Function>{
    '[]': (StringValue v1, Value v2) => v1[v2],
    '==': (StringValue v1, Value v2) => v1.equals(v2)
  };

  StringValue(this.value);

  Value invokeMethod(Name name, [Value arg]) {
    if (!operators.containsKey(name.name)) {
      return notImplemented(obj: name);
    }
    return operators[name.name](this, arg);
  }

  // Operators
  Value operator [](Value index) => new StringValue(value[index.value]);
}

abstract class NumValue extends LiteralValue {
  num get value;

  NumValue();

  factory NumValue.fromValue(num value) {
    if (value is int) {
      return new IntValue(value);
    } else {
      assert(value is double);
      return new DoubleValue(value);
    }
  }

  static final operators = <String, Function>{
    '+': (NumValue v1, Value v2) => v1 + v2,
    '-': (NumValue v1, Value v2) => v1 - v2,
    '>': (NumValue v1, Value v2) => v1 > v2,
    '<': (NumValue v1, Value v2) => v1 < v2,
    '==': (NumValue v1, Value v2) => v1.equals(v2),
    'unary-': (NumValue v1) => -v1,
  };

  Value invokeMethod(Name name, [Value arg]) {
    if (!operators.containsKey(name.name)) return notImplemented(obj: name);
    if (arg == null) return operators[name.name](this);
    return operators[name.name](this, arg);
  }

  // Operators
  NumValue operator +(Value other) =>
      new NumValue.fromValue(value + other.value);
  NumValue operator -(Value other) =>
      new NumValue.fromValue(value - other.value);
  NumValue operator -() => new NumValue.fromValue(-value);

  BoolValue operator >(Value other) =>
      value > other.value ? Value.trueInstance : Value.falseInstance;
  BoolValue operator <(Value other) =>
      value < other.value ? Value.trueInstance : Value.falseInstance;
}

class IntValue extends NumValue {
  final int value;

  IntValue(this.value);
}

class DoubleValue extends NumValue {
  final double value;

  DoubleValue(this.value);
}

class BoolValue extends LiteralValue {
  final bool value;

  const BoolValue(this.value);
}

class NullValue extends LiteralValue {
  Object get value => null;

  const NullValue();
}

notImplemented({String m, Object obj}) {
  throw new NotImplemented(m ?? 'Evaluation for $obj is not implemented');
}

// ------------------------------------------------------------------------
//                             INTERNAL FUNCTIONS
// ------------------------------------------------------------------------
/// Creates a list of all argument expressions to be evaluated for the
/// invocation of the provided [FunctionNode] containing the actual arguments
/// and the optional argument initializers.
List<InterpreterExpression> _createArgumentExpressionList(
    Arguments providedArgs, FunctionNode fun) {
  List<InterpreterExpression> args = <InterpreterExpression>[];
  // Add positional arguments expressions.
  args.addAll(providedArgs.positional
      .map((Expression e) => new PositionalExpression(e)));

  // Add optional positional argument initializers.
  for (int i = providedArgs.positional.length;
      i < fun.positionalParameters.length;
      i++) {
    args.add(new PositionalExpression(fun.positionalParameters[i].initializer));
  }

  Map<String, NamedExpression> namedFormals = new Map.fromIterable(
      fun.namedParameters,
      key: (VariableDeclaration vd) => vd.name,
      value: (VariableDeclaration vd) =>
          new NamedExpression(vd.name, vd.initializer));

  // Add named expressions.
  for (int i = 0; i < providedArgs.named.length; i++) {
    var current = providedArgs.named[i];
    args.add(new NamedExpression(current.name, current.value));
    namedFormals.remove(current.name);
  }

  // Add missing optional named initializers.
  args.addAll(namedFormals.values);

  return args;
}

Expression _getExpression(Initializer initializer) {
  if (initializer is FieldInitializer) {
    return initializer.value;
  }
  if (initializer is LocalInitializer) {
    return initializer.variable.initializer;
  }

  throw '${initializer.runtimeType} has no epxression.';
}

/// Initializes all non initialized fields in given class with
/// [Value.nullInstance].
void _initializeNullFields(Class class_, ObjectValue newObject) {
  int superClassSize = class_.superclass?.instanceSize ?? 0;
  for (int i = superClassSize; i < class_.instanceSize; i++) {
    Field field = class_.instanceFields[i];
    if (class_.getProperty(newObject, field) == null) {
      assert(field.initializer == null);
      class_.setProperty(newObject, field, Value.nullInstance);
    }
  }
}
