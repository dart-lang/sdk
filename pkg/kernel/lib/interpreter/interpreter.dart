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
    StatementConfiguration configuration =
        new StatementConfiguration(statementBlock, new State.initial());
    visitor.trampolinedExecution(configuration);
  }
}

class Binding {
  final VariableDeclaration variable;
  Value value;

  Binding(this.variable, this.value);
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

class InstanceEnvironment extends Environment {
  final ObjectValue _thisInstance;
  Value get thisInstance => _thisInstance;

  InstanceEnvironment(this._thisInstance, Environment env) : super(env);
}

/// Evaluate expressions.
class Evaluator
    extends ExpressionVisitor1<Configuration, ExpressionConfiguration> {
  Configuration eval(Expression expr, ExpressionConfiguration config) =>
      expr.accept1(this, config);

  Configuration evalList(List<InterpreterExpression> list, Environment env,
      ApplicationContinuation cont) {
    if (list.isNotEmpty) {
      return new ExpressionConfiguration(list.first.expression, env,
          new ExpressionListContinuation(list.first, list.skip(1), env, cont));
    }
    return new ExpressionListContinuationConfiguration(
        cont, <InterpreterValue>[]);
  }

  Configuration defaultExpression(
      Expression node, ExpressionConfiguration config) {
    throw new NotImplemented('Evaluation for expressions of type '
        '${node.runtimeType} is not implemented.');
  }

  Configuration visitInvalidExpression1(
      InvalidExpression node, ExpressionConfiguration config) {
    throw 'Invalid expression at ${node.location.toString()}';
  }

  Configuration visitVariableGet(
      VariableGet node, ExpressionConfiguration config) {
    Value value = config.environment.lookup(node.variable);
    return new ContinuationConfiguration(config.continuation, value);
  }

  Configuration visitVariableSet(
      VariableSet node, ExpressionConfiguration config) {
    var cont = new VariableSetContinuation(
        node.variable, config.environment, config.continuation);
    return new ExpressionConfiguration(node.value, config.environment, cont);
  }

  Configuration visitPropertyGet(
      PropertyGet node, ExpressionConfiguration config) {
    var cont = new PropertyGetContinuation(node.name, config.continuation);
    return new ExpressionConfiguration(node.receiver, config.environment, cont);
  }

  Configuration visitPropertySet(
      PropertySet node, ExpressionConfiguration config) {
    var cont = new PropertySetContinuation(
        node.value, node.name, config.environment, config.continuation);
    return new ExpressionConfiguration(node.receiver, config.environment, cont);
  }

  Configuration visitStaticGet(
          StaticGet node, ExpressionConfiguration config) =>
      defaultExpression(node, config);
  Configuration visitStaticSet(
          StaticSet node, ExpressionConfiguration config) =>
      defaultExpression(node, config);

  Configuration visitStaticInvocation(
      StaticInvocation node, ExpressionConfiguration config) {
    if ('print' == node.name.toString()) {
      var cont = new PrintContinuation(config.continuation);
      return new ExpressionConfiguration(
          node.arguments.positional.first, config.environment, cont);
    } else {
      log.info('static-invocation-${node.target.name.toString()}\n');

      List<InterpreterExpression> args =
          _createArgumentExpressionList(node.arguments, node.target.function);
      ApplicationContinuation cont = new StaticInvocationApplication(
          node.target.function, config.continuation);
      return new ExpressionListConfiguration(args, config.environment, cont);
    }
  }

  Configuration visitMethodInvocation(
      MethodInvocation node, ExpressionConfiguration config) {
    // Currently supports only method invocation with <2 arguments and is used
    // to evaluate implemented operators for int, double and String values.
    var cont = new MethodInvocationContinuation(
        node.arguments, node.name, config.environment, config.continuation);

    return new ExpressionConfiguration(node.receiver, config.environment, cont);
  }

  Configuration visitConstructorInvocation(
      ConstructorInvocation node, ExpressionConfiguration config) {
    ApplicationContinuation cont =
        new ConstructorInvocationApplication(node.target, config.continuation);
    var args =
        _createArgumentExpressionList(node.arguments, node.target.function);

    return new ExpressionListConfiguration(args, config.environment, cont);
  }

  Configuration visitNot(Not node, ExpressionConfiguration config) {
    return new ExpressionConfiguration(node.operand, config.environment,
        new NotContinuation(config.continuation));
  }

  Configuration visitLogicalExpression(
      LogicalExpression node, ExpressionConfiguration config) {
    if ('||' == node.operator) {
      var cont = new OrContinuation(
          node.right, config.environment, config.continuation);
      return new ExpressionConfiguration(node.left, config.environment, cont);
    } else {
      assert('&&' == node.operator);
      var cont = new AndContinuation(
          node.right, config.environment, config.continuation);
      return new ExpressionConfiguration(node.left, config.environment, cont);
    }
  }

  Configuration visitConditionalExpression(
      ConditionalExpression node, ExpressionConfiguration config) {
    var cont = new ConditionalContinuation(
        node.then, node.otherwise, config.environment, config.continuation);
    return new ExpressionConfiguration(
        node.condition, config.environment, cont);
  }

  Configuration visitStringConcatenation(
      StringConcatenation node, ExpressionConfiguration config) {
    var cont = new StringConcatenationContinuation(config.continuation);
    var expressions = node.expressions
        .map((Expression e) => new PositionalExpression(e))
        .toList();
    return new ExpressionListConfiguration(
        expressions, config.environment, cont);
  }

  Configuration visitThisExpression(
      ThisExpression node, ExpressionConfiguration config) {
    return new ContinuationConfiguration(
        config.continuation, config.environment.thisInstance);
  }

  // Evaluation of BasicLiterals.
  Configuration visitStringLiteral(
      StringLiteral node, ExpressionConfiguration config) {
    return new ContinuationConfiguration(
        config.continuation, new StringValue(node.value));
  }

  Configuration visitIntLiteral(
      IntLiteral node, ExpressionConfiguration config) {
    return new ContinuationConfiguration(
        config.continuation, new IntValue(node.value));
  }

  Configuration visitDoubleLiteral(
      DoubleLiteral node, ExpressionConfiguration config) {
    return new ContinuationConfiguration(
        config.continuation, new DoubleValue(node.value));
  }

  Configuration visitBoolLiteral(
      BoolLiteral node, ExpressionConfiguration config) {
    Value value = node.value ? Value.trueInstance : Value.falseInstance;
    return new ContinuationConfiguration(config.continuation, value);
  }

  Configuration visitNullLiteral(
      NullLiteral node, ExpressionConfiguration config) {
    return new ContinuationConfiguration(
        config.continuation, Value.nullInstance);
  }

  Configuration visitLet(Let node, ExpressionConfiguration config) {
    var letCont = new LetContinuation(
        node.variable, node.body, config.environment, config.continuation);
    return new ExpressionConfiguration(
        node.variable.initializer, config.environment, letCont);
  }
}

/// Represents a state for statement execution.
class State {
  final Environment environment;
  final Label labels;
  final StatementConfiguration statementConfiguration;

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
  final StatementConfiguration configuration;
  final Label enclosingLabel;

  Label(this.statement, this.configuration, this.enclosingLabel);

  Label lookupLabel(LabeledStatement s) {
    if (identical(s, statement)) return this;
    assert(enclosingLabel != null);
    return enclosingLabel.lookupLabel(s);
  }
}

abstract class Configuration {
  /// Executes the current and returns the next configuration.
  Configuration step(StatementExecuter executer);
}

/// Represents the configuration for execution of statement.
class StatementConfiguration extends Configuration {
  final Statement statement;
  final State state;

  StatementConfiguration(this.statement, this.state);

  Configuration step(StatementExecuter executer) =>
      executer.exec(statement, state);
}

class ExitConfiguration extends StatementConfiguration {
  final ExpressionContinuation returnContinuation;

  ExitConfiguration(this.returnContinuation) : super(null, null);

  Configuration step(StatementExecuter _) {
    return returnContinuation(Value.nullInstance);
  }
}

class NewInstanceConfiguration extends StatementConfiguration {
  final ExpressionContinuation continuation;
  final ObjectValue newObject;

  NewInstanceConfiguration(this.continuation, this.newObject)
      : super(null, new State.initial());

  Configuration step(StatementExecuter _) {
    return continuation(newObject);
  }
}

/// Represents the configuration for applying an [ExpressionContinuation].
class ContinuationConfiguration extends Configuration {
  final ExpressionContinuation continuation;
  final Value value;

  ContinuationConfiguration(this.continuation, this.value);

  Configuration step(StatementExecuter _) => continuation(value);
}

/// Represents the configuration for applying an [ApplicationContinuation].
class ExpressionListContinuationConfiguration extends Configuration {
  final ApplicationContinuation continuation;
  final List<InterpreterValue> values;

  ExpressionListContinuationConfiguration(this.continuation, this.values);

  Configuration step(StatementExecuter _) => continuation(values);
}

/// Represents the configuration for evaluating an [Expression].
class ExpressionConfiguration extends Configuration {
  final Expression expression;

  /// Environment in which the expression is evaluated.
  final Environment environment;

  /// Next continuation to be applied.
  final Continuation continuation;

  ExpressionConfiguration(this.expression, this.environment, this.continuation);

  Configuration step(StatementExecuter executer) =>
      executer.eval(expression, this);
}

/// Represents the configuration for evaluating a list of expressions.
class ExpressionListConfiguration extends Configuration {
  final List<InterpreterExpression> expressions;
  final Environment environment;
  final Continuation continuation;

  ExpressionListConfiguration(
      this.expressions, this.environment, this.continuation);

  Configuration step(StatementExecuter executer) =>
      executer.evalList(expressions, environment, continuation);
}

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

/// Represents the application continuation for static invocation.
class StaticInvocationApplication extends ApplicationContinuation {
  final FunctionNode function;
  final ExpressionContinuation continuation;

  StaticInvocationApplication(this.function, this.continuation);

  Configuration call(List<InterpreterValue> argValues) {
    Environment functionEnv =
        ApplicationContinuation.createEnvironment(function, argValues);

    State bodyState = new State.initial()
        .withExpressionContinuation(continuation)
        .withConfiguration(new ExitConfiguration(continuation))
        .withEnvironment(functionEnv);
    return new StatementConfiguration(function.body, bodyState);
  }
}

/// Represents the application continuation for constructor invocation applied
/// on the list of evaluated arguments.
class ConstructorInvocationApplication extends ApplicationContinuation {
  final Constructor constructor;
  final ExpressionContinuation continuation;

  ConstructorInvocationApplication(this.constructor, this.continuation);

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
class RedirectingConstructorApplication extends ApplicationContinuation {
  final Constructor constructor;
  final Environment environment;
  final StatementConfiguration configuration;

  RedirectingConstructorApplication(
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
class SuperConstructorApplication extends ApplicationContinuation {
  final Constructor constructor;
  final Environment environment;
  final StatementConfiguration configuration;

  SuperConstructorApplication(
      this.constructor, this.environment, this.configuration);

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
  final StatementConfiguration configuration;

  ObjectInitializationConfiguration(
      this.constructor, this.environment, this.configuration);

  Configuration step(StatementExecuter _) {
    if (constructor.initializers.isNotEmpty &&
        constructor.initializers.last is RedirectingInitializer) {
      // Constructor is redirecting.
      Initializer initializer = constructor.initializers.first;
      if (initializer is RedirectingInitializer) {
        var app = new RedirectingConstructorApplication(
            initializer.target, environment, configuration);
        var args = _createArgumentExpressionList(
            initializer.arguments, initializer.target.function);

        return new ExpressionListConfiguration(args, environment, app);
      }
      // Redirecting initializer is not the only initializer.
      for (Initializer i in constructor.initializers.reversed.skip(1)) {
        assert(i is LocalInitializer);
      }
      var class_ = new Class(constructor.enclosingClass.reference);
      var initEnv = new Environment(environment);
      var cont = new InitializerContinuation(
          class_, initEnv, constructor.initializers, configuration);
      return new ExpressionConfiguration(
          (initializer as LocalInitializer).variable.initializer,
          initEnv,
          cont);
    }

    // Set head of configurations to be executed to configuration for current
    // constructor body.
    var state = new State.initial()
        .withEnvironment(environment)
        .withConfiguration(configuration);
    var bodyConfig =
        new StatementConfiguration(constructor.function.body, state);

    // Initialize fields in immediately enclosing class.
    var cont =
        new InstanceFieldsApplication(constructor, environment, bodyConfig);
    var fieldExpressions = _createInstanceInitializers(constructor);

    return new ExpressionListConfiguration(
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
class InstanceFieldsApplication extends ApplicationContinuation {
  final Constructor constructor;
  final Environment environment;
  final StatementConfiguration configuration;

  final Class _currentClass;
  final ObjectValue _newObject;

  InstanceFieldsApplication(
      this.constructor, this.environment, this.configuration)
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

      var superApp = new SuperConstructorApplication(
          current.target, environment, configuration);
      _initializeNullFields(_currentClass, _newObject);
      return new ExpressionListConfiguration(args, environment, superApp);
    }

    Class class_ = new Class(constructor.enclosingClass.reference);
    Environment initEnv = new Environment(environment);

    var cont = new InitializerContinuation(
        class_, initEnv, constructor.initializers, configuration);
    return new ExpressionConfiguration(
        _getExpression(constructor.initializers.first), initEnv, cont);
  }
}

/// Represents the expression continuation applied on the list of evaluated
/// initializer expressions preceding a super call in the list.
class InitializerContinuation extends ExpressionContinuation {
  final Class currentClass;
  final Environment initializerEnvironment;
  final List<Initializer> initializers;
  final StatementConfiguration configuration;

  InitializerContinuation(this.currentClass, this.initializerEnvironment,
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
      var app = new RedirectingConstructorApplication(
          next.target, initializerEnvironment, configuration);
      var args =
          _createArgumentExpressionList(next.arguments, next.target.function);
      return new ExpressionListConfiguration(args, initializerEnvironment, app);
    }

    if (next is SuperInitializer) {
      // SuperInitializer appears last in the initializer list.
      assert(initializers.length == 2);
      var args =
          _createArgumentExpressionList(next.arguments, next.target.function);
      var superApp = new SuperConstructorApplication(
          next.target, initializerEnvironment, configuration);
      _initializeNullFields(currentClass, newObject);
      return new ExpressionListConfiguration(
          args, initializerEnvironment, superApp);
    }

    var cont = new InitializerContinuation(currentClass, initializerEnvironment,
        initializers.skip(1).toList(), configuration);
    return new ExpressionConfiguration(
        _getExpression(next), initializerEnvironment, cont);
  }
}

/// Represents the application continuation called after the evaluation of all
/// argument expressions for an invocation.
class ValueApplication extends ApplicationContinuation {
  final InterpreterValue value;
  final ApplicationContinuation applicationContinuation;

  ValueApplication(this.value, this.applicationContinuation);

  Configuration call(List<InterpreterValue> args) {
    args.add(value);
    return new ExpressionListContinuationConfiguration(
        applicationContinuation, args);
  }
}

/// Represents an expression continuation.
abstract class ExpressionContinuation extends Continuation {
  Configuration call(Value v);
}

/// Represents a continuation that returns the next [StatementConfiguration]
/// to be executed.
class ExpressionStatementContinuation extends ExpressionContinuation {
  final StatementConfiguration configuration;

  ExpressionStatementContinuation(this.configuration);

  Configuration call(Value _) {
    return configuration;
  }
}

class PrintContinuation extends ExpressionContinuation {
  final ExpressionContinuation continuation;

  PrintContinuation(this.continuation);

  Configuration call(Value v) {
    log.info('print(${v.value.runtimeType}: ${v.value})\n');
    print(v.value);
    return new ContinuationConfiguration(continuation, Value.nullInstance);
  }
}

class PropertyGetContinuation extends ExpressionContinuation {
  final Name name;
  final ExpressionContinuation continuation;

  PropertyGetContinuation(this.name, this.continuation);

  Configuration call(Value receiver) {
    // TODO: CPS the invocation of the getter.
    Value propertyValue = receiver.class_.lookupGetter(name)(receiver);
    return new ContinuationConfiguration(continuation, propertyValue);
  }
}

class PropertySetContinuation extends ExpressionContinuation {
  final Expression value;
  final Name setterName;
  final Environment environment;
  final ExpressionContinuation continuation;

  PropertySetContinuation(
      this.value, this.setterName, this.environment, this.continuation);

  Configuration call(Value receiver) {
    var cont = new SetterContinuation(receiver, setterName, continuation);
    return new ExpressionConfiguration(value, environment, cont);
  }
}

class SetterContinuation extends ExpressionContinuation {
  final Value receiver;
  final Name name;
  final ExpressionContinuation continuation;

  SetterContinuation(this.receiver, this.name, this.continuation);

  Configuration call(Value v) {
    Setter setter = receiver.class_.lookupSetter(name);
    setter(receiver, v);
    return new ContinuationConfiguration(continuation, v);
  }
}

/// Represents a continuation to be called after the evaluation of an actual
/// argument for function invocation.
class ExpressionListContinuation extends ExpressionContinuation {
  final InterpreterExpression currentExpression;
  final List<InterpreterExpression> expressions;
  final Environment environment;
  final ApplicationContinuation applicationContinuation;

  ExpressionListContinuation(this.currentExpression, this.expressions,
      this.environment, this.applicationContinuation);

  Configuration call(Value v) {
    ValueApplication app = new ValueApplication(
        currentExpression.assignValue(v), applicationContinuation);
    return new ExpressionListConfiguration(expressions, environment, app);
  }
}

class MethodInvocationContinuation extends ExpressionContinuation {
  final Arguments arguments;
  final Name methodName;
  final Environment environment;
  final ExpressionContinuation continuation;

  MethodInvocationContinuation(
      this.arguments, this.methodName, this.environment, this.continuation);

  Configuration call(Value receiver) {
    if (arguments.positional.isEmpty) {
      Value returnValue = receiver.invokeMethod(methodName);
      return new ContinuationConfiguration(continuation, returnValue);
    }
    var cont = new ArgumentsContinuation(
        receiver, methodName, arguments, environment, continuation);

    return new ExpressionConfiguration(
        arguments.positional.first, environment, cont);
  }
}

class ArgumentsContinuation extends ExpressionContinuation {
  final Value receiver;
  final Name methodName;
  final Arguments arguments;
  final Environment environment;
  final ExpressionContinuation continuation;

  ArgumentsContinuation(this.receiver, this.methodName, this.arguments,
      this.environment, this.continuation);

  Configuration call(Value value) {
    // Currently evaluates only one argument, for simple method invocations
    // with 1 argument.
    Value returnValue = receiver.invokeMethod(methodName, value);
    return new ContinuationConfiguration(continuation, returnValue);
  }
}

class VariableSetContinuation extends ExpressionContinuation {
  final VariableDeclaration variable;
  final Environment environment;
  final ExpressionContinuation continuation;

  VariableSetContinuation(this.variable, this.environment, this.continuation);

  Configuration call(Value value) {
    environment.assign(variable, value);
    return new ContinuationConfiguration(continuation, value);
  }
}

class NotContinuation extends ExpressionContinuation {
  final ExpressionContinuation continuation;

  NotContinuation(this.continuation);

  Configuration call(Value value) {
    Value notValue = identical(Value.trueInstance, value)
        ? Value.falseInstance
        : Value.trueInstance;
    return new ContinuationConfiguration(continuation, notValue);
  }
}

class OrContinuation extends ExpressionContinuation {
  final Expression right;
  final Environment environment;
  final ExpressionContinuation continuation;

  OrContinuation(this.right, this.environment, this.continuation);

  Configuration call(Value left) {
    return identical(Value.trueInstance, left)
        ? new ContinuationConfiguration(continuation, Value.trueInstance)
        : new ExpressionConfiguration(right, environment, continuation);
  }
}

class AndContinuation extends ExpressionContinuation {
  final Expression right;
  final Environment environment;
  final ExpressionContinuation continuation;

  AndContinuation(this.right, this.environment, this.continuation);

  Configuration call(Value left) {
    return identical(Value.falseInstance, left)
        ? new ContinuationConfiguration(continuation, Value.falseInstance)
        : new ExpressionConfiguration(right, environment, continuation);
  }
}

class ConditionalContinuation extends ExpressionContinuation {
  final Expression then;
  final Expression otherwise;
  final Environment environment;
  final ExpressionContinuation continuation;

  ConditionalContinuation(
      this.then, this.otherwise, this.environment, this.continuation);

  Configuration call(Value value) {
    return identical(Value.trueInstance, value)
        ? new ExpressionConfiguration(then, environment, continuation)
        : new ExpressionConfiguration(otherwise, environment, continuation);
  }
}

class StringConcatenationContinuation extends ApplicationContinuation {
  final ExpressionContinuation continuation;

  StringConcatenationContinuation(this.continuation);

  Configuration call(List<InterpreterValue> values) {
    StringBuffer result = new StringBuffer();
    for (InterpreterValue v in values.reversed) {
      result.write(v.value.value);
    }
    return new ContinuationConfiguration(
        continuation, new StringValue(result.toString()));
  }
}

class LetContinuation extends ExpressionContinuation {
  final VariableDeclaration variable;
  final Expression letBody;
  final Environment environment;
  final ExpressionContinuation continuation;

  LetContinuation(
      this.variable, this.letBody, this.environment, this.continuation);

  Configuration call(Value value) {
    var letEnv = new Environment(environment);
    letEnv.expand(variable, value);
    return new ExpressionConfiguration(letBody, letEnv, continuation);
  }
}

/// Represents the continuation for the condition expression in [WhileStatement].
class WhileConditionContinuation extends ExpressionContinuation {
  final WhileStatement node;
  final State state;

  WhileConditionContinuation(this.node, this.state);

  StatementConfiguration call(Value v) {
    if (identical(v, Value.trueInstance)) {
      // Add configuration for the While statement to the linked list.
      StatementConfiguration config = new StatementConfiguration(node, state);
      // Configuration for the body of the loop.
      return new StatementConfiguration(
          node.body, state.withConfiguration(config));
    }

    return state.statementConfiguration;
  }
}

/// Represents the continuation for the condition expression in [IfStatement].
class IfConditionContinuation extends ExpressionContinuation {
  final Statement then;
  final Statement otherwise;
  final State state;

  IfConditionContinuation(this.then, this.otherwise, this.state);

  StatementConfiguration call(Value v) {
    if (identical(v, Value.trueInstance)) {
      log.info("if-then\n");
      return new StatementConfiguration(then, state);
    } else if (otherwise != null) {
      log.info("if-otherwise\n");
      return new StatementConfiguration(otherwise, state);
    }
    return state.statementConfiguration;
  }
}

/// Represents the continuation for the initializer expression in
/// [VariableDeclaration].
class VariableInitializerContinuation extends ExpressionContinuation {
  final VariableDeclaration variable;
  final Environment environment;
  final StatementConfiguration nextConfiguration;

  VariableInitializerContinuation(
      this.variable, this.environment, this.nextConfiguration);

  StatementConfiguration call(Value v) {
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
  Configuration eval(Expression expression, ExpressionConfiguration config) =>
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
    var cont =
        new ExpressionStatementContinuation(state.statementConfiguration);
    return new ExpressionConfiguration(
        node.expression, state.environment, cont);
  }

  Configuration visitBlock(Block node, State state) {
    if (node.statements.isEmpty) {
      return state.statementConfiguration;
    }
    State blockState =
        state.withEnvironment(new Environment(state.environment));
    StatementConfiguration configuration = state.statementConfiguration;
    for (Statement s in node.statements.reversed) {
      configuration = new StatementConfiguration(
          s, blockState.withConfiguration(configuration));
    }
    return configuration;
  }

  Configuration visitEmptyStatement(EmptyStatement node, State state) {
    return state.statementConfiguration;
  }

  Configuration visitIfStatement(IfStatement node, State state) {
    var cont = new IfConditionContinuation(node.then, node.otherwise, state);

    return new ExpressionConfiguration(node.condition, state.environment, cont);
  }

  Configuration visitLabeledStatement(LabeledStatement node, State state) {
    return new StatementConfiguration(node.body, state.withBreak(node));
  }

  Configuration visitBreakStatement(BreakStatement node, State state) {
    return state.lookupLabel(node.target).configuration;
  }

  Configuration visitWhileStatement(WhileStatement node, State state) {
    var cont = new WhileConditionContinuation(node, state);

    return new ExpressionConfiguration(node.condition, state.environment, cont);
  }

  Configuration visitDoStatement(DoStatement node, State state) {
    WhileStatement whileStatement =
        new WhileStatement(node.condition, node.body);
    StatementConfiguration configuration =
        new StatementConfiguration(whileStatement, state);

    return new StatementConfiguration(
        node.body, state.withConfiguration(configuration));
  }

  Configuration visitReturnStatement(ReturnStatement node, State state) {
    assert(state.returnContinuation != null);
    log.info('return\n');
    if (node.expression == null) {
      return new ContinuationConfiguration(
          state.returnContinuation, Value.nullInstance);
    }

    return new ExpressionConfiguration(
        node.expression, state.environment, state.returnContinuation);
  }

  Configuration visitVariableDeclaration(
      VariableDeclaration node, State state) {
    if (node.initializer != null) {
      var cont = new VariableInitializerContinuation(
          node, state.environment, state.statementConfiguration);
      return new ExpressionConfiguration(
          node.initializer, state.environment, cont);
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
