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
    ExecConfiguration configuration =
        new ExecConfiguration(statementBlock, new State.initial());
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

  Value get thisInstance => (parent != null)
      ? parent.thisInstance
      : throw "Invalid reference to 'this' expression";

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

  void expand(VariableDeclaration variable, Value value) {
    assert(!contains(variable));
    bindings.add(new Binding(variable, new Location(value)));
  }
}

class InstanceEnvironment extends Environment {
  final ObjectValue _thisInstance;
  Value get thisInstance => _thisInstance;

  InstanceEnvironment(this._thisInstance, Environment env) : super(env);
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
      ConstructorInvocation node, EvalConfiguration config) {
    ApplicationContinuation cont =
        new ConstructorInvocationA(node.target, config.continuation);
    var args =
        _createArgumentExpressionList(node.arguments, node.target.function);

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
  final Environment environment;
  final Label labels;
  final ExecConfiguration statementConfiguration;

  final ExpressionContinuation returnContinuation;

  State(this.environment, this.labels, this.statementConfiguration,
      this.returnContinuation);

  State.initial() : this(new Environment.empty(), null, null, null);

  State withEnvironment(Environment env) {
    return new State(env, labels, statementConfiguration, returnContinuation);
  }

  State withBreak(Statement stmt) {
    Label breakLabels = new Label(stmt, statementConfiguration, labels);
    return new State(
        environment, breakLabels, statementConfiguration, returnContinuation);
  }

  State withConfiguration(Configuration config) {
    return new State(environment, labels, config, returnContinuation);
  }

  State withExpressionContinuation(ExpressionContinuation cont) {
    return new State(environment, labels, statementConfiguration, cont);
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
  final ExecConfiguration configuration;
  final Label enclosingLabel;

  Label(this.statement, this.configuration, this.enclosingLabel);

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

/// Represents the configuration for evaluating an [Expression].
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

/// Represents the configuration for evaluating a list of expressions.
class EvalListConfiguration extends Configuration {
  final List<InterpreterExpression> expressions;
  final Environment environment;
  final Continuation continuation;

  EvalListConfiguration(this.expressions, this.environment, this.continuation);

  Configuration step(StatementExecuter executer) =>
      executer.evalList(expressions, environment, continuation);
}

/// Represents the configuration for execution of statement.
class ExecConfiguration extends Configuration {
  final Statement statement;
  final State state;

  ExecConfiguration(this.statement, this.state);

  Configuration step(StatementExecuter executer) =>
      executer.exec(statement, state);
}

class ExitConfiguration extends ExecConfiguration {
  final ExpressionContinuation returnContinuation;

  ExitConfiguration(this.returnContinuation) : super(null, null);

  Configuration step(StatementExecuter _) {
    return returnContinuation(Value.nullInstance);
  }
}

class NewInstanceConfiguration extends ExecConfiguration {
  final ExpressionContinuation continuation;
  final ObjectValue newObject;

  NewInstanceConfiguration(this.continuation, this.newObject)
      : super(null, new State.initial());

  Configuration step(StatementExecuter _) {
    return continuation(newObject);
  }
}

/// Represents the configuration for applying an [ExpressionContinuation].
class ValuePassingConfiguration extends Configuration {
  final ExpressionContinuation continuation;
  final Value value;

  ValuePassingConfiguration(this.continuation, this.value);

  Configuration step(StatementExecuter _) => continuation(value);
}

/// Represents the configuration for applying an [ApplicationContinuation].
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

class LocalInitializerExpression extends InterpreterExpression {
  final VariableDeclaration variable;

  Expression get expression => variable.initializer;

  LocalInitializerExpression(this.variable);

  InterpreterValue assignValue(Value v) =>
      new LocalInitializerValue(variable, v);
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

class LocalInitializerValue extends InterpreterValue {
  final VariableDeclaration variable;
  final Value value;

  LocalInitializerValue(this.variable, this.value);
}

class FieldInitializerValue extends InterpreterValue {
  final Field field;
  final Value value;

  FieldInitializerValue(this.field, this.value);
}

abstract class Continuation {}

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
    Environment newEnv = new Environment(parentEnv);
    List<PositionalValue> positional = args.reversed
        .where((InterpreterValue av) => av is PositionalValue)
        .toList();

    // Add positional parameters.
    for (int i = 0; i < positional.length; ++i) {
      newEnv.expand(function.positionalParameters[i], positional[i].value);
    }

    Map<String, Value> named = new Map.fromIterable(
        args.where((InterpreterValue av) => av is NamedValue),
        key: (NamedValue av) => av.name,
        value: (NamedValue av) => av.value);

    // Add named parameters.
    for (VariableDeclaration v in function.namedParameters) {
      newEnv.expand(v, named[v.name.toString()]);
    }

    return newEnv;
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

    State bodyState = new State.initial()
        .withExpressionContinuation(continuation)
        .withConfiguration(new ExitConfiguration(continuation))
        .withEnvironment(functionEnv);
    return new ExecConfiguration(function.body, bodyState);
  }
}

/// Represents the application continuation for constructor invocation applied
/// on the list of evaluated arguments.
class ConstructorInvocationA extends ApplicationContinuation {
  final Constructor constructor;
  final ExpressionContinuation continuation;

  ConstructorInvocationA(this.constructor, this.continuation);

  Configuration call(List<InterpreterValue> argValues) {
    Environment ctrEnv = ApplicationContinuation.createEnvironment(
        constructor.function, argValues);

    var class_ = new Class(constructor.enclosingClass.reference);
    var newObject =
        new ObjectValue(class_, new List<Value>(class_.instanceSize));

    return new ObjectInitializationConfiguration(
        constructor,
        new InstanceEnvironment(newObject, ctrEnv),
        new NewInstanceConfiguration(continuation, newObject));
  }
}

/// Represents the application continuation for redirecting constructor
/// invocation applied on the list of evaluated arguments.
class RedirectingConstructorA extends ApplicationContinuation {
  final Constructor constructor;
  final Environment environment;
  final ExecConfiguration configuration;

  RedirectingConstructorA(
      this.constructor, this.environment, this.configuration);

  Configuration call(List<InterpreterValue> argValues) {
    Value object = environment.thisInstance;
    Environment ctrEnv = ApplicationContinuation.createEnvironment(
        constructor.function,
        argValues,
        new InstanceEnvironment(object, new Environment.empty()));

    return new ObjectInitializationConfiguration(
        constructor, ctrEnv, configuration);
  }
}

/// Represents the application continuation for super constructor
/// invocation applied on the list of evaluated arguments.
class SuperConstructorA extends ApplicationContinuation {
  final Constructor constructor;
  final Environment environment;
  final ExecConfiguration configuration;

  SuperConstructorA(this.constructor, this.environment, this.configuration);

  Configuration call(List<InterpreterValue> argValues) {
    Value object = environment.thisInstance;

    Environment superEnv = ApplicationContinuation.createEnvironment(
        constructor.function,
        argValues,
        new InstanceEnvironment(object, new Environment.empty()));

    return new ObjectInitializationConfiguration(
        constructor, superEnv, configuration);
  }
}

/// Represents the configuration for execution of initializer and
/// constructor body statements for initialization of a newly allocated object.
class ObjectInitializationConfiguration extends Configuration {
  final Constructor constructor;
  final Environment environment;
  final ExecConfiguration configuration;

  ObjectInitializationConfiguration(
      this.constructor, this.environment, this.configuration);

  Configuration step(StatementExecuter _) {
    if (constructor.initializers.isNotEmpty &&
        constructor.initializers.last is RedirectingInitializer) {
      // Constructor is redirecting.
      Initializer initializer = constructor.initializers.first;
      if (initializer is RedirectingInitializer) {
        var app = new RedirectingConstructorA(
            initializer.target, environment, configuration);
        var args = _createArgumentExpressionList(
            initializer.arguments, initializer.target.function);

        return new EvalListConfiguration(args, environment, app);
      }
      // Redirecting initializer is not the only initializer.
      for (Initializer i in constructor.initializers.reversed.skip(1)) {
        assert(i is LocalInitializer);
      }
      var class_ = new Class(constructor.enclosingClass.reference);
      var initEnv = new Environment(environment);
      var cont = new InitializerEK(
          class_, initEnv, constructor.initializers, configuration);
      return new EvalConfiguration(
          (initializer as LocalInitializer).variable.initializer,
          initEnv,
          cont);
    }

    // Set head of configurations to be executed to configuration for current
    // constructor body.
    var state = new State.initial()
        .withEnvironment(environment)
        .withConfiguration(configuration);
    var bodyConfig = new ExecConfiguration(constructor.function.body, state);

    // Initialize fields in immediately enclosing class.
    var cont = new InstanceFieldsA(constructor, environment, bodyConfig);
    var fieldExpressions = _createInstanceInitializers(constructor);

    return new EvalListConfiguration(
        fieldExpressions, new Environment.empty(), cont);
  }

  /// Creates a list of expressions for instance field initializers in
  /// immediately enclosing class.
  static List<InterpreterExpression> _createInstanceInitializers(
      Constructor ctr) {
    Class currentClass = new Class(ctr.enclosingClass.reference);
    List<InterpreterExpression> es = <InterpreterExpression>[];

    for (int i = currentClass.superclass?.instanceSize ?? 0;
        i < currentClass.instanceSize;
        i++) {
      Field current = currentClass.instanceFields[i];
      if (current.initializer != null) {
        es.add(new FieldInitializerExpression(current, current.initializer));
      }
    }

    return es;
  }
}

/// Represents the application continuation applied on the list of evaluated
/// field initializer expressions.
class InstanceFieldsA extends ApplicationContinuation {
  final Constructor constructor;
  final Environment environment;
  final ExecConfiguration configuration;

  final Class _currentClass;
  final ObjectValue _newObject;

  InstanceFieldsA(this.constructor, this.environment, this.configuration)
      : _currentClass = new Class(constructor.enclosingClass.reference),
        _newObject = environment.thisInstance;

  Configuration call(List<InterpreterValue> fieldValues) {
    for (FieldInitializerValue current in fieldValues.reversed) {
      _currentClass.setProperty(_newObject, current.field, current.value);
    }

    if (constructor.initializers.isEmpty) {
      _initializeNullFields(_currentClass, _newObject);
      return configuration;
    }

    // Produce next configuration.
    if (constructor.initializers.first is SuperInitializer) {
      // SuperInitializer appears last in the initializer list.
      assert(constructor.initializers.length == 1);
      SuperInitializer current = constructor.initializers.first;
      var args = _createArgumentExpressionList(
          current.arguments, current.target.function);

      var superApp =
          new SuperConstructorA(current.target, environment, configuration);
      _initializeNullFields(_currentClass, _newObject);
      return new EvalListConfiguration(args, environment, superApp);
    }

    Class class_ = new Class(constructor.enclosingClass.reference);
    Environment initEnv = new Environment(environment);

    var cont = new InitializerEK(
        class_, initEnv, constructor.initializers, configuration);
    return new EvalConfiguration(
        _getExpression(constructor.initializers.first), initEnv, cont);
  }
}

/// Represents the expression continuation applied on the list of evaluated
/// initializer expressions preceding a super call in the list.
class InitializerEK extends ExpressionContinuation {
  final Class currentClass;
  final Environment initializerEnvironment;
  final List<Initializer> initializers;
  final ExecConfiguration configuration;

  InitializerEK(this.currentClass, this.initializerEnvironment,
      this.initializers, this.configuration);

  Configuration call(Value v) {
    ObjectValue newObject = initializerEnvironment.thisInstance;
    Initializer current = initializers.first;
    if (current is FieldInitializer) {
      currentClass.setProperty(newObject, current.field, v);
    } else if (current is LocalInitializer) {
      initializerEnvironment.expand(current.variable, v);
    } else {
      throw 'Assigning value $v to ${current.runtimeType}';
    }

    if (initializers.length <= 1) {
      _initializeNullFields(currentClass, newObject);
      return configuration;
    }

    Initializer next = initializers[1];

    if (next is RedirectingInitializer) {
      // RedirectingInitializer appears last in the initializer list.
      assert(initializers.length == 2);
      var app = new RedirectingConstructorA(
          next.target, initializerEnvironment, configuration);
      var args =
          _createArgumentExpressionList(next.arguments, next.target.function);
      return new EvalListConfiguration(args, initializerEnvironment, app);
    }

    if (next is SuperInitializer) {
      // SuperInitializer appears last in the initializer list.
      assert(initializers.length == 2);
      var args =
          _createArgumentExpressionList(next.arguments, next.target.function);
      var superApp = new SuperConstructorA(
          next.target, initializerEnvironment, configuration);
      _initializeNullFields(currentClass, newObject);
      return new EvalListConfiguration(args, initializerEnvironment, superApp);
    }

    var cont = new InitializerEK(currentClass, initializerEnvironment,
        initializers.skip(1).toList(), configuration);
    return new EvalConfiguration(
        _getExpression(next), initializerEnvironment, cont);
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
  final ExecConfiguration configuration;

  ExpressionEK(this.configuration);

  Configuration call(Value _) {
    return configuration;
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
    letEnv.expand(variable, value);
    return new EvalConfiguration(letBody, letEnv, continuation);
  }
}

/// Represents the continuation for the condition expression in [WhileStatement].
class WhileConditionEK extends ExpressionContinuation {
  final WhileStatement node;
  final State state;

  WhileConditionEK(this.node, this.state);

  ExecConfiguration call(Value v) {
    if (identical(v, Value.trueInstance)) {
      // Add configuration for the While statement to the linked list.
      ExecConfiguration config = new ExecConfiguration(node, state);
      // Configuration for the body of the loop.
      return new ExecConfiguration(node.body, state.withConfiguration(config));
    }

    return state.statementConfiguration;
  }
}

/// Represents the continuation for the condition expression in [IfStatement].
class IfConditionEK extends ExpressionContinuation {
  final Statement then;
  final Statement otherwise;
  final State state;

  IfConditionEK(this.then, this.otherwise, this.state);

  ExecConfiguration call(Value v) {
    if (identical(v, Value.trueInstance)) {
      log.info("if-then\n");
      return new ExecConfiguration(then, state);
    } else if (otherwise != null) {
      log.info("if-otherwise\n");
      return new ExecConfiguration(otherwise, state);
    }
    return state.statementConfiguration;
  }
}

/// Represents the continuation for the initializer expression in
/// [VariableDeclaration].
class VariableInitializerEK extends ExpressionContinuation {
  final VariableDeclaration variable;
  final Environment environment;
  final ExecConfiguration nextConfiguration;

  VariableInitializerEK(
      this.variable, this.environment, this.nextConfiguration);

  ExecConfiguration call(Value v) {
    environment.expand(variable, v);
    return nextConfiguration;
  }
}

/// Executes statements.
///
/// Execution of a statement completes in one of the following ways:
/// - it completes normally, in which case the execution proceeds to applying
/// the next continuation
/// - it breaks with a label, in which case the corresponding continuation is
/// returned and applied
/// - it returns with or without value, TBD
/// - it throws, TBD
class StatementExecuter extends StatementVisitor1<Configuration, State> {
  Evaluator evaluator = new Evaluator();

  void trampolinedExecution(Configuration configuration) {
    while (configuration != null) {
      configuration = configuration.step(this);
    }
  }

  Configuration exec(Statement statement, State state) =>
      statement.accept1(this, state);
  Configuration eval(Expression expression, EvalConfiguration config) =>
      evaluator.eval(expression, config);
  Configuration evalList(
          List<InterpreterExpression> es, Environment env, Continuation cont) =>
      evaluator.evalList(es, env, cont);

  Configuration defaultStatement(Statement node, State state) {
    throw notImplemented(
        m: "Execution is not implemented for statement:\n$node ");
  }

  Configuration visitInvalidStatement(InvalidStatement node, State state) {
    throw "Invalid statement at ${node.location}";
  }

  Configuration visitExpressionStatement(
      ExpressionStatement node, State state) {
    var cont = new ExpressionEK(state.statementConfiguration);
    return new EvalConfiguration(node.expression, state.environment, cont);
  }

  Configuration visitBlock(Block node, State state) {
    if (node.statements.isEmpty) {
      return state.statementConfiguration;
    }
    State blockState =
        state.withEnvironment(new Environment(state.environment));
    ExecConfiguration configuration = state.statementConfiguration;
    for (Statement s in node.statements.reversed) {
      configuration =
          new ExecConfiguration(s, blockState.withConfiguration(configuration));
    }
    return configuration;
  }

  Configuration visitEmptyStatement(EmptyStatement node, State state) {
    return state.statementConfiguration;
  }

  Configuration visitIfStatement(IfStatement node, State state) {
    var cont = new IfConditionEK(node.then, node.otherwise, state);

    return new EvalConfiguration(node.condition, state.environment, cont);
  }

  Configuration visitLabeledStatement(LabeledStatement node, State state) {
    return new ExecConfiguration(node.body, state.withBreak(node));
  }

  Configuration visitBreakStatement(BreakStatement node, State state) {
    return state.lookupLabel(node.target).configuration;
  }

  Configuration visitWhileStatement(WhileStatement node, State state) {
    var cont = new WhileConditionEK(node, state);

    return new EvalConfiguration(node.condition, state.environment, cont);
  }

  Configuration visitDoStatement(DoStatement node, State state) {
    WhileStatement whileStatement =
        new WhileStatement(node.condition, node.body);
    ExecConfiguration configuration =
        new ExecConfiguration(whileStatement, state);

    return new ExecConfiguration(
        node.body, state.withConfiguration(configuration));
  }

  Configuration visitReturnStatement(ReturnStatement node, State state) {
    assert(state.returnContinuation != null);
    log.info('return\n');
    if (node.expression == null) {
      return new ValuePassingConfiguration(
          state.returnContinuation, Value.nullInstance);
    }

    return new EvalConfiguration(
        node.expression, state.environment, state.returnContinuation);
  }

  Configuration visitVariableDeclaration(
      VariableDeclaration node, State state) {
    if (node.initializer != null) {
      var cont = new VariableInitializerEK(
          node, state.environment, state.statementConfiguration);
      return new EvalConfiguration(node.initializer, state.environment, cont);
    }
    state.environment.expand(node, Value.nullInstance);
    return state.statementConfiguration;
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
