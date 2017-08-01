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

  Location.empty();
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

  Value get thisInstance {
    return containsThis()
        ? lookupThis().value
        : throw "Invalid reference to 'this' expression";
  }

  Environment.empty() : parent = null;
  Environment(this.parent);

  bool contains(VariableDeclaration variable) {
    for (Binding b in bindings) {
      if (identical(b.variable, variable)) return true;
    }
    return parent?.contains(variable) ?? false;
  }

  bool containsThis() {
    for (Binding b in bindings) {
      if (identical(b.variable.name, 'this')) return true;
    }
    return parent?.containsThis() ?? false;
  }

  Binding lookupBinding(VariableDeclaration variable) {
    assert(contains(variable));
    for (Binding b in bindings) {
      if (identical(b.variable, variable)) return b;
    }
    return parent.lookupBinding(variable);
  }

  Location lookupThis() {
    assert(containsThis());
    for (Binding b in bindings) {
      if (identical(b.variable.name, 'this')) return b.location;
    }
    return parent.lookupThis();
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

  Environment extendWithThis(ObjectValue v) {
    assert(!containsThis());
    return extend(new VariableDeclaration('this'), v);
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
          _getArgumentExpressions(node.arguments, node.target.function);
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
      ConstructorInvocation node, EvalConfiguration config) {
    ApplicationContinuation cont =
        new ConstructorInvocationA(node.target, config.continuation);
    var args = _getArgumentExpressions(node.arguments, node.target.function);

    return new EvalListConfiguration(args, config.environment, cont);
  }

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
      ThisExpression node, EvalConfiguration config) {
    return new ValuePassingConfiguration(
        config.continuation, config.environment.thisInstance);
  }

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

/// Applies the expression continuation to the provided value.
class NewSK extends StatementContinuation {
  final ExpressionContinuation continuation;
  final Location location;

  NewSK(this.continuation, this.location);

  Configuration call(Environment _) =>
      new ValuePassingConfiguration(continuation, location.value);
}

class ConstructorBodySK extends StatementContinuation {
  final Statement body;
  final Environment environment;
  // TODO(zhivkag): Add component for exception handler.
  final StatementContinuation continuation;

  ConstructorBodySK(this.body, this.environment, this.continuation);

  Configuration call(Environment _) {
    return new ExecConfiguration(
        body, environment, new State(null, null, continuation));
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

/// Represents the application continuation for constructor invocation applied
/// on the list of evaluated arguments when a constructor is invoked with new.
///
/// It creates the newly allocated object instance.
class ConstructorInvocationA extends ApplicationContinuation {
  final Constructor constructor;
  final ExpressionContinuation continuation;

  ConstructorInvocationA(this.constructor, this.continuation);

  Configuration call(List<InterpreterValue> argValues) {
    Environment ctrEnv = ApplicationContinuation.createEnvironment(
        constructor.function, argValues);

    var newObject = new ObjectValue(constructor.enclosingClass);
    var cont = new InitializationEK(
        constructor, ctrEnv, new NewSK(continuation, new Location(newObject)));

    return new ValuePassingConfiguration(cont, newObject);
  }
}

/// Represents the application continuation applied on the list of evaluated
/// field initializer expressions.
class InstanceFieldsA extends ApplicationContinuation {
  final Constructor constructor;
  final Location location;
  final Environment environment;
  final ConstructorBodySK continuation;

  final Class _currentClass;

  InstanceFieldsA(
      this.constructor, this.location, this.environment, this.continuation)
      : _currentClass = new Class(constructor.enclosingClass.reference);

  Configuration call(List<InterpreterValue> fieldValues) {
    for (FieldInitializerValue f in fieldValues) {
      // Directly set the field with the corresponding implicit setter.
      _currentClass.implicitSetters[f.field.name](location.value, f.value);
    }

    // TODO(zhivkag): Execute constructor initializer list before initializing
    // fields in immediately enclosing class to null.
    _initializeNullFields(_currentClass, location.value);
    return new ForwardConfiguration(continuation, environment);
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
    Value propertyValue = receiver.class_.lookupImplicitGetter(name)(receiver);
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
    Setter setter = receiver.class_.lookupImplicitSetter(name);
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

/// Expression continuation that further initializes the newly allocated object
/// instance with running the constructor.
class InitializationEK extends ExpressionContinuation {
  final Constructor constructor;
  final Environment environment;
  // TODO(zhivkag): Add components for exception handling support
  final StatementContinuation continuation;

  InitializationEK(this.constructor, this.environment, this.continuation);

  Configuration call(Value value) {
    if (constructor.enclosingClass.superclass.superclass != null) {
      throw 'Support for super constructors in not implemented.';
    }

    if (constructor.initializers.isNotEmpty &&
        !(constructor.initializers.last is SuperInitializer)) {
      throw 'Support for initializers is not implemented.';
    }

    // The statement body is captured by the next statement continuation and
    // expressions for field initialization are evaluated.
    var ctrEnv = environment.extendWithThis(value);
    var bodyCont =
        new ConstructorBodySK(constructor.function.body, ctrEnv, continuation);
    var initializers = _getFieldInitializers(constructor.enclosingClass);
    var fieldsCont =
        new InstanceFieldsA(constructor, new Location(value), ctrEnv, bodyCont);
    return new EvalListConfiguration(
        initializers, new Environment.empty(), fieldsCont);
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
    ;
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

  /// The immediate superclass, or `null` if this is the root class object.
  Class superclass;

  /// The class definitions from the `implements` clause.
  final List<Supertype> interfaces = <Supertype>[];

  /// Implicit getters for instance fields.
  Map<Name, Getter> implicitGetters = <Name, Getter>{};

  /// Implicit setters for non final instance fields.
  Map<Name, Setter> implicitSetters = <Name, Setter>{};

  /// Instance methods, explicit getters and setters.
  Map<Name, Procedure> methods = <Name, Procedure>{};

  int get instanceSize => implicitGetters.length;

  factory Class(Reference classRef) {
    return _classes.putIfAbsent(
        classRef, () => new Class._internal(classRef.asClass));
  }

  Class._internal(ast.Class currentClass) {
    if (currentClass.superclass != null) {
      superclass = new Class(currentClass.superclass.reference);
    }

    _populateImplicitGettersAndSetters(currentClass);
    _populateInstanceMethods(currentClass);
  }

  Getter lookupImplicitGetter(Name name) {
    Getter getter = implicitGetters[name];
    if (getter != null) return getter;
    if (superclass != null) return superclass.lookupImplicitGetter(name);
    return (Value receiver) => notImplemented(obj: name);
  }

  Setter lookupImplicitSetter(Name name) {
    Setter setter = implicitSetters[name];
    if (setter != null) return setter;
    if (superclass != null) return superclass.lookupImplicitSetter(name);
    return (Value receiver, Value value) => notImplemented(obj: name);
  }

  /// Populates implicit getters and setters for the current class and its
  /// superclass recursively.
  _populateImplicitGettersAndSetters(ast.Class class_) {
    if (class_.superclass != null) {
      _populateImplicitGettersAndSetters(class_.superclass);
    }

    for (Field f in class_.fields) {
      if (f.isStatic) continue;
      assert(f.hasImplicitGetter);

      int currentFieldIndex = implicitGetters.length;
      // Shadowing an inherited getter with the same name.
      implicitGetters[f.name] =
          (Value receiver) => receiver.fields[currentFieldIndex].value;
      if (f.hasImplicitSetter) {
        // Shadowing an inherited setter with the same name.
        implicitSetters[f.name] = (Value receiver, Value value) =>
            receiver.fields[currentFieldIndex].value = value;
      }
    }
  }

  /// Populates instance methods, getters and setters for the current class and
  /// its super class recursively.
  _populateInstanceMethods(ast.Class class_) {
    if (class_.superclass != null) {
      _populateInstanceMethods(class_.superclass);
    }

    for (Member m in class_.members) {
      if (m is Procedure) {
        // Shadowing an inherited method, getter or setter with the same name.
        methods[m.name] = m;
      }
    }
  }
}

abstract class Value {
  Class get class_;
  List<Location> get fields;
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
  final Class class_;
  final List<Location> fields;
  Object get value => this;

  ObjectValue(ast.Class classDeclaration)
      : class_ = new Class(classDeclaration.reference),
        fields = new List<Location>(classDeclaration.fields.length) {
    for (int i = 0; i < fields.length; i++) {
      // Create fresh locations for each field.
      fields[i] = new Location.empty();
    }
  }
}

abstract class LiteralValue extends Value {
  Class get class_ =>
      notImplemented(m: "Loading class for literal is not implemented.");
  List<Location> get fields =>
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
List<InterpreterExpression> _getArgumentExpressions(
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

/// Creates a list of all field expressions to be evaluated.
///
/// A field expression is an initializer expression for a given field defined
/// when the field was created.
List<InterpreterExpression> _getFieldInitializers(ast.Class class_) {
  var fieldInitializers = new List<InterpreterExpression>();

  for (Field f in class_.fields) {
    if (f.initializer != null) {
      fieldInitializers.add(new FieldInitializerExpression(f, f.initializer));
    }
  }

  return fieldInitializers;
}

/// Initializes all non initialized fields from the provided class to
/// `Value.nullInstance` in the provided value.
void _initializeNullFields(Class class_, Value value) {
  int startIndex = class_.superclass?.instanceSize ?? 0;
  for (int i = startIndex; i < class_.instanceSize; i++) {
    if (value.fields[i].value == null) {
      value.fields[i].value = Value.nullInstance;
    }
  }
}
