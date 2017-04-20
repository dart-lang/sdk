// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.interpreter;

import '../ast.dart';
import '../ast.dart' as ast show Class;

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
class Evaluator extends ExpressionVisitor1<Configuration, ExpressionState> {
  Configuration eval(Expression expr, ExpressionState state) =>
      expr.accept1(this, state);

  Configuration defaultExpression(Expression node, ExpressionState state) {
    throw new NotImplemented('Evaluation for expressions of type '
        '${node.runtimeType} is not implemented.');
  }

  Configuration visitInvalidExpression1(
      InvalidExpression node, ExpressionState state) {
    throw 'Invalid expression at ${node.location.toString()}';
  }

  Configuration visitVariableGet(VariableGet node, ExpressionState state) {
    Value value = state.environment.lookup(node.variable);
    return new ContinuationConfiguration(state.continuation, value);
  }

  Configuration visitVariableSet(VariableSet node, ExpressionState state) {
    var cont = new VariableSetContinuation(state, node.variable);
    return new ExpressionConfiguration(
        node.value, state.withContinuation(cont));
  }

  Configuration visitPropertyGet(PropertyGet node, ExpressionState state) {
    var cont = new PropertyGetContinuation(node.name, state);
    return new ExpressionConfiguration(
        node.receiver, state.withContinuation(cont));
  }

  Configuration visitPropertySet(PropertySet node, ExpressionState state) {
    var cont = new PropertySetContinuation(node.value, node.name, state);
    return new ExpressionConfiguration(
        node.receiver, state.withContinuation(cont));
  }

  Configuration visitStaticGet(StaticGet node, ExpressionState state) =>
      defaultExpression(node, state);
  Configuration visitStaticSet(StaticSet node, ExpressionState state) =>
      defaultExpression(node, state);

  Configuration visitStaticInvocation(
      StaticInvocation node, ExpressionState state) {
    if ('print' == node.name.toString()) {
      return new ExpressionConfiguration(node.arguments.positional.first,
          state.withContinuation(new PrintContinuation(state)));
    } else {
      // Currently supports only static invocations with no arguments.
      if (node.arguments.positional.isEmpty && node.arguments.named.isEmpty) {
        State statementState = new State.initial()
            .withExpressionContinuation(state.continuation)
            .withConfiguration(new ExitConfiguration(state.continuation));

        return new StatementConfiguration(
            node.target.function.body, statementState);
      }
      throw new NotImplemented(
          'Support for static invocation with arguments is not implemented');
    }
  }

  Configuration visitMethodInvocation(
      MethodInvocation node, ExpressionState state) {
    // Currently supports only method invocation with <2 arguments and is used
    // to evaluate implemented operators for int, double and String values.
    var cont =
        new MethodInvocationContinuation(node.arguments, node.name, state);

    return new ExpressionConfiguration(
        node.receiver, state.withContinuation(cont));
  }

  Configuration visitConstructorInvocation(
      ConstructorInvocation node, ExpressionState state) {
    Class class_ = new Class(node.target.enclosingClass.reference);

    // Currently we don't support initializers.
    // TODO: Modify to respect dart semantics for initialization.
    //  1. Init fields and eval initializers, repeat the same with super.
    //  2. Eval the Function body of the constructor.
    List<Value> fields = <Value>[];

    return new ContinuationConfiguration(
        state.continuation, new ObjectValue(class_, fields));
  }

  Configuration visitNot(Not node, ExpressionState state) {
    return new ExpressionConfiguration(
        node.operand, state.withContinuation(new NotContinuation(state)));
  }

  Configuration visitLogicalExpression(
      LogicalExpression node, ExpressionState state) {
    if ('||' == node.operator) {
      var cont = new OrContinuation(node.right, state);
      return new ExpressionConfiguration(
          node.left, state.withContinuation(cont));
    } else {
      assert('&&' == node.operator);
      var cont = new AndContinuation(node.right, state);
      return new ExpressionConfiguration(
          node.left, state.withContinuation(cont));
    }
  }

  Configuration visitConditionalExpression(
      ConditionalExpression node, ExpressionState state) {
    var cont = new ConditionalContinuation(node.then, node.otherwise, state);
    return new ExpressionConfiguration(
        node.condition, state.withContinuation(cont));
  }

  Configuration visitStringConcatenation(
      StringConcatenation node, ExpressionState state) {
    var cont = new StringConcatenationContinuation(node.expressions, state);
    return new ExpressionConfiguration(
        node.expressions.first, state.withContinuation(cont));
  }

  // Evaluation of BasicLiterals.
  Configuration visitStringLiteral(StringLiteral node, ExpressionState state) {
    return new ContinuationConfiguration(
        state.continuation, new StringValue(node.value));
  }

  Configuration visitIntLiteral(IntLiteral node, ExpressionState state) {
    return new ContinuationConfiguration(
        state.continuation, new IntValue(node.value));
  }

  Configuration visitDoubleLiteral(DoubleLiteral node, ExpressionState state) {
    return new ContinuationConfiguration(
        state.continuation, new DoubleValue(node.value));
  }

  Configuration visitBoolLiteral(BoolLiteral node, ExpressionState state) {
    Value value = node.value ? Value.trueInstance : Value.falseInstance;
    return new ContinuationConfiguration(state.continuation, value);
  }

  Configuration visitNullLiteral(NullLiteral node, ExpressionState state) {
    return new ContinuationConfiguration(
        state.continuation, Value.nullInstance);
  }

  Configuration visitLet(Let node, ExpressionState state) {
    var letCont = new LetContinuation(node.variable, node.body, state);
    return new ExpressionConfiguration(
        node.variable.initializer, state.withContinuation(letCont));
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

/// Represents a state for expression evaluation.
class ExpressionState {
  /// Environment in which the expression is evaluated.
  final Environment environment;

  /// Next continuation to be applied.
  final ExpressionContinuation continuation;

  ExpressionState(this.environment, this.continuation);

  ExpressionState.fromStatementState(State state)
      : this(state.environment,
            new ExpressionStatementContinuation(state.statementConfiguration));

  ExpressionState withEnvironment(Environment env) {
    return new ExpressionState(env, continuation);
  }

  ExpressionState withContinuation(ExpressionContinuation cont) {
    return new ExpressionState(environment, cont);
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
  final ExpressionState state;

  ExpressionConfiguration(this.expression, this.state);

  Configuration step(StatementExecuter executer) =>
      executer.eval(expression, state);
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
  final ExpressionState state;

  PrintContinuation(this.state);

  Configuration call(Value v) {
    print(v.value);
    return new ContinuationConfiguration(
        state.continuation, Value.nullInstance);
  }
}

class PropertyGetContinuation extends ExpressionContinuation {
  final Name name;
  final ExpressionState state;

  PropertyGetContinuation(this.name, this.state);

  Configuration call(Value receiver) {
    // TODO: CPS the invocation of the getter.
    Value propertyValue = receiver.class_.lookupGetter(name)(receiver);
    return new ContinuationConfiguration(state.continuation, propertyValue);
  }
}

class PropertySetContinuation extends ExpressionContinuation {
  final Expression value;
  final Name setterName;
  final ExpressionState state;

  PropertySetContinuation(this.value, this.setterName, this.state);

  Configuration call(Value receiver) {
    var cont = new SetterContinuation(receiver, setterName, state);
    return new ExpressionConfiguration(value, state.withContinuation(cont));
  }
}

class SetterContinuation extends ExpressionContinuation {
  final Value receiver;
  final Name name;
  final ExpressionState state;

  SetterContinuation(this.receiver, this.name, this.state);

  Configuration call(Value v) {
    Setter setter = receiver.class_.lookupSetter(name);
    setter(receiver, v);
    return new ContinuationConfiguration(state.continuation, v);
  }
}

class StaticInvocationContinuation extends ExpressionContinuation {
  final ExpressionState state;

  StaticInvocationContinuation(this.state);

  Configuration call(Value v) {
    return new ContinuationConfiguration(state.continuation, v);
  }
}

class MethodInvocationContinuation extends ExpressionContinuation {
  final Arguments arguments;
  final Name methodName;
  final ExpressionState state;

  MethodInvocationContinuation(this.arguments, this.methodName, this.state);

  Configuration call(Value receiver) {
    if (arguments.positional.isEmpty) {
      Value returnValue = receiver.invokeMethod(methodName);
      return new ContinuationConfiguration(state.continuation, returnValue);
    }
    var cont =
        new ArgumentsContinuation(receiver, methodName, arguments, state);

    return new ExpressionConfiguration(
        arguments.positional.first, state.withContinuation(cont));
  }
}

class ArgumentsContinuation extends ExpressionContinuation {
  final Value receiver;
  final Name methodName;
  final Arguments arguments;
  final ExpressionState state;

  ArgumentsContinuation(
      this.receiver, this.methodName, this.arguments, this.state);

  Configuration call(Value value) {
    // Currently evaluates only one argument, for simple method invocations
    // with 1 argument.
    Value returnValue = receiver.invokeMethod(methodName, value);
    return new ContinuationConfiguration(state.continuation, returnValue);
  }
}

class VariableSetContinuation extends ExpressionContinuation {
  final ExpressionState state;
  final VariableDeclaration variable;

  VariableSetContinuation(this.state, this.variable);

  Configuration call(Value value) {
    state.environment.assign(variable, value);
    return new ContinuationConfiguration(state.continuation, value);
  }
}

class NotContinuation extends ExpressionContinuation {
  final ExpressionState state;

  NotContinuation(this.state);

  Configuration call(Value value) {
    Value notValue = identical(Value.trueInstance, value)
        ? Value.falseInstance
        : Value.trueInstance;
    return new ContinuationConfiguration(state.continuation, notValue);
  }
}

class OrContinuation extends ExpressionContinuation {
  final Expression right;
  final ExpressionState state;

  OrContinuation(this.right, this.state);

  Configuration call(Value left) {
    return identical(Value.trueInstance, left)
        ? new ContinuationConfiguration(state.continuation, Value.trueInstance)
        : new ExpressionConfiguration(right, state);
  }
}

class AndContinuation extends ExpressionContinuation {
  final Expression right;
  final ExpressionState state;

  AndContinuation(this.right, this.state);

  Configuration call(Value left) {
    return identical(Value.falseInstance, left)
        ? new ContinuationConfiguration(state.continuation, Value.falseInstance)
        : new ExpressionConfiguration(right, state);
  }
}

class ConditionalContinuation extends ExpressionContinuation {
  final Expression then;
  final Expression otherwise;
  final ExpressionState state;

  ConditionalContinuation(this.then, this.otherwise, this.state);

  Configuration call(Value value) {
    return identical(Value.trueInstance, value)
        ? new ExpressionConfiguration(then, state)
        : new ExpressionConfiguration(otherwise, state);
  }
}

class StringConcatenationContinuation extends ExpressionContinuation {
  final List<Expression> expressions;
  final ExpressionState state;

  int _currentPosition = 0;
  final List<Value> _values = <Value>[];

  StringConcatenationContinuation(this.expressions, this.state);

  Configuration call(Value value) {
    _values.add(value);
    if (_values.length == expressions.length) {
      StringBuffer res = new StringBuffer();

      for (int i = 0; i < expressions.length; i++) {
        res.write(_values[i].value);
      }

      Value value = new StringValue(res.toString());
      return new ContinuationConfiguration(state.continuation, value);
    }
    return new ExpressionConfiguration(
        expressions[++_currentPosition], state.withContinuation(this));
  }
}

class LetContinuation extends ExpressionContinuation {
  final VariableDeclaration variable;
  final Expression letBody;
  final ExpressionState state;

  LetContinuation(this.variable, this.letBody, this.state);

  Configuration call(Value value) {
    var letState = state.withEnvironment(new Environment(state.environment));
    letState.environment.expand(variable, value);
    return new ExpressionConfiguration(letBody, letState);
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
      return new StatementConfiguration(then, state);
    } else if (otherwise != null) {
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
  Configuration eval(Expression expression, ExpressionState state) =>
      evaluator.eval(expression, state);

  Configuration defaultStatement(Statement node, State state) {
    throw notImplemented(
        m: "Execution is not implemented for statement:\n$node ");
  }

  Configuration visitInvalidStatement(InvalidStatement node, State state) {
    throw "Invalid statement at ${node.location}";
  }

  Configuration visitExpressionStatement(
      ExpressionStatement node, State state) {
    return new ExpressionConfiguration(
        node.expression, new ExpressionState.fromStatementState(state));
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
    var expState = new ExpressionState.fromStatementState(state);
    var cont = new IfConditionContinuation(node.then, node.otherwise, state);
    return new ExpressionConfiguration(
        node.condition, expState.withContinuation(cont));
  }

  Configuration visitLabeledStatement(LabeledStatement node, State state) {
    return new StatementConfiguration(node.body, state.withBreak(node));
  }

  Configuration visitBreakStatement(BreakStatement node, State state) {
    return state.lookupLabel(node.target).configuration;
  }

  Configuration visitWhileStatement(WhileStatement node, State state) {
    var expState = new ExpressionState.fromStatementState(state);
    var cont = new WhileConditionContinuation(node, state);

    return new ExpressionConfiguration(
        node.condition, expState.withContinuation(cont));
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
    // The new ExpressionState contains the next expression continuation.
    var expState = new ExpressionState.fromStatementState(state)
        .withContinuation(state.returnContinuation);
    return new ExpressionConfiguration(
        node.expression ?? new NullLiteral(), expState);
  }

  Configuration visitVariableDeclaration(
      VariableDeclaration node, State state) {
    if (node.initializer != null) {
      var expState = new ExpressionState.fromStatementState(state);
      var cont = new VariableInitializerContinuation(
          node, state.environment, state.statementConfiguration);
      return new ExpressionConfiguration(
          node.initializer, expState.withContinuation(cont));
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
      value == other.value ? Value.trueInstance : Value.falseInstance;

  Value invokeMethod(Name name, [Value arg]) {
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
