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

/// Evaluate expressions.
class Evaluator
    extends ExpressionVisitor1<Configuration, ExpressionConfiguration> {
  Configuration eval(Expression expr, ExpressionConfiguration config) =>
      expr.accept1(this, config);

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
      var cont = new ActualArgumentsContinuation(node.arguments,
          node.target.function, config.environment, config.continuation);
      return cont.createCurrentConfiguration();
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
    Class class_ = new Class(node.target.enclosingClass.reference);

    // Currently we don't support initializers.
    // TODO: Modify to respect dart semantics for initialization.
    //  1. Init fields and eval initializers, repeat the same with super.
    //  2. Eval the Function body of the constructor.
    List<Value> fields = <Value>[];

    return new ContinuationConfiguration(
        config.continuation, new ObjectValue(class_, fields));
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
    var cont = new StringConcatenationContinuation(
        node.expressions, config.environment, config.continuation);
    return new ExpressionConfiguration(
        node.expressions.first, config.environment, cont);
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

  Configuration step(StatementExecuter executer) {
    return returnContinuation(Value.nullInstance);
  }
}

/// Represents the configuration for applying an [ExpressionContinuation].
class ContinuationConfiguration extends Configuration {
  final ExpressionContinuation continuation;
  final Value value;

  ContinuationConfiguration(this.continuation, this.value);

  Configuration step(StatementExecuter executer) => continuation(value);
}

/// Represents the configuration for evaluating an [Expression].
class ExpressionConfiguration extends Configuration {
  final Expression expression;

  /// Environment in which the expression is evaluated.
  final Environment environment;

  /// Next continuation to be applied.
  final ExpressionContinuation continuation;

  ExpressionConfiguration(this.expression, this.environment, this.continuation);

  Configuration step(StatementExecuter executer) =>
      executer.eval(expression, this);
}

/// Represents an expression continuation.
abstract class ExpressionContinuation {
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
/// TODO: Add checks for validation of arguments according to spec.
class ActualArgumentsContinuation extends ExpressionContinuation {
  final Arguments arguments;
  final FunctionNode functionNode;
  final Environment environment;
  final ExpressionContinuation continuation;

  final List<Value> _positional = <Value>[];
  int _currentPositional = 0;
  final Map<String, Value> _named = <String, Value>{};
  int _currentNamed = 0;

  ActualArgumentsContinuation(
      this.arguments, this.functionNode, this.environment, this.continuation);

  Configuration call(Value v) {
    if (_currentPositional < arguments.positional.length) {
      _positional.add(v);
      _currentPositional++;
    } else {
      assert(_currentNamed < arguments.named.length);
      String name = arguments.named[_currentNamed].name;
      _named[name] = v;
      _currentNamed++;
    }

    return createCurrentConfiguration();
  }

  Configuration createCurrentConfiguration() {
    // Next argument to evaluate is a provided positional argument.
    if (_currentPositional < arguments.positional.length) {
      return new ExpressionConfiguration(
          arguments.positional[_currentPositional], environment, this);
    }
    // Next argument to evaluate is a provided named argument.
    if (_currentNamed < arguments.named.length) {
      return new ExpressionConfiguration(
          arguments.named[_currentNamed].value, environment, this);
    }

    // TODO: check if the number of actual arguments is larger then the number
    // of required arguments and smaller then the number of formal arguments.

    return new OptionalArgumentsContinuation(
            _positional, _named, functionNode, environment, continuation)
        .createCurrentConfiguration();
  }
}

class OptionalArgumentsContinuation extends ExpressionContinuation {
  final List<Value> positional;
  final Map<String, Value> named;
  final FunctionNode functionNode;
  final Environment environment;
  final ExpressionContinuation continuation;

  final Map<String, VariableDeclaration> _missingFormalNamed =
      <String, VariableDeclaration>{};

  int _currentPositional;
  String _currentNamed;

  OptionalArgumentsContinuation(this.positional, this.named, this.functionNode,
      this.environment, this.continuation) {
    _currentPositional = positional.length;
    assert(_currentPositional >= functionNode.requiredParameterCount);

    for (VariableDeclaration vd in functionNode.namedParameters) {
      if (named[vd.name] == null) {
        _missingFormalNamed[vd.name] = vd;
      }
    }
  }

  Configuration call(Value v) {
    if (_currentPositional < functionNode.positionalParameters.length) {
      // Value is a optional positional argument
      positional.add(v);
      _currentPositional++;
    } else {
      // Value is a optional named argument.
      assert(named[_currentNamed] == null);
      named[_currentNamed] = v;
    }

    return createCurrentConfiguration();
  }

  /// Creates the current configuration for the evaluation of invocation a
  /// function.
  Configuration createCurrentConfiguration() {
    if (_currentPositional < functionNode.positionalParameters.length) {
      // Next argument to evaluate is a missing positional argument.
      // Evaluate its initializer.
      return new ExpressionConfiguration(
          functionNode.positionalParameters[_currentPositional].initializer,
          environment,
          this);
    }
    if (named.length < functionNode.namedParameters.length) {
      // Next argument to evaluate is a missing named argument.
      // Evaluate its initializer.
      _currentNamed = _missingFormalNamed.keys.first;
      Expression initializer = _missingFormalNamed[_currentNamed].initializer;
      _missingFormalNamed.remove(_currentNamed);
      return new ExpressionConfiguration(initializer, environment, this);
    }

    Environment newEnv = _createEnvironment();
    State bodyState = new State.initial()
        .withExpressionContinuation(continuation)
        .withConfiguration(new ExitConfiguration(continuation))
        .withEnvironment(newEnv);

    return new StatementConfiguration(functionNode.body, bodyState);
  }

  /// Creates an environment binding actual argument values to formal parameters
  /// of the function in a new environment, which is used to execute the
  /// body od the function.
  Environment _createEnvironment() {
    Environment newEnv = new Environment.empty();
    // Add positional parameters.
    for (int i = 0; i < positional.length; ++i) {
      newEnv.expand(functionNode.positionalParameters[i], positional[i]);
    }
    // Add named parameters.
    for (VariableDeclaration v in functionNode.namedParameters) {
      newEnv.expand(v, named[v.name.toString()]);
    }

    return newEnv;
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

class StringConcatenationContinuation extends ExpressionContinuation {
  final List<Expression> expressions;
  final Environment environment;
  final ExpressionContinuation continuation;

  int _currentPosition = 0;
  final List<Value> _values = <Value>[];

  StringConcatenationContinuation(
      this.expressions, this.environment, this.continuation);

  Configuration call(Value value) {
    _values.add(value);
    if (_values.length == expressions.length) {
      StringBuffer res = new StringBuffer();

      for (int i = 0; i < expressions.length; i++) {
        res.write(_values[i].value);
      }

      Value value = new StringValue(res.toString());
      return new ContinuationConfiguration(continuation, value);
    }
    return new ExpressionConfiguration(
        expressions[++_currentPosition], environment, this);
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
