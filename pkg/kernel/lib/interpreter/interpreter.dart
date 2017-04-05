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
    Continuation cont = new Continuation(statementBlock, new State.initial());
    visitor.trampolinedExecution(cont);
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
class Evaluator extends ExpressionVisitor1<Value> {
  Value eval(Expression expr, Environment env) => expr.accept1(this, env);

  Value defaultExpression(Expression node, env) {
    throw new NotImplemented('Evaluation for expressions of type '
        '${node.runtimeType} is not implemented.');
  }

  Value visitInvalidExpression1(InvalidExpression node, env) {
    throw 'Invalid expression at ${node.location.toString()}';
  }

  Value visitVariableGet(VariableGet node, env) {
    return env.lookup(node.variable);
  }

  Value visitVariableSet(VariableSet node, env) {
    return env.assign(node.variable, eval(node.value, env));
  }

  Value visitPropertyGet(PropertyGet node, env) {
    Value receiver = eval(node.receiver, env);
    return receiver.class_.lookupGetter(node.name)(receiver);
  }

  Value visitPropertySet(PropertySet node, env) {
    Value receiver = eval(node.receiver, env);
    Value value = eval(node.value, env);
    receiver.class_.lookupSetter(node.name)(receiver, value);
    return value;
  }

  Value visitDirectPropertyGet(DirectPropertyGet node, env) {
    Value receiver = eval(node.receiver, env);
    return receiver.class_.getProperty(receiver, node.target);
  }

  Value visitDirectPropertySet(DirectPropertySet node, env) {
    Value receiver = eval(node.receiver, env);
    Value value = eval(node.value, env);
    receiver.class_.setProperty(receiver, node.target, value);
    return value;
  }

  Value visitStaticGet(StaticGet node, env) => defaultExpression(node, env);
  Value visitStaticSet(StaticSet node, env) => defaultExpression(node, env);

  Value visitStaticInvocation(StaticInvocation node, env) {
    if ('print' == node.name.toString()) {
      // Special evaluation of print.
      var res = eval(node.arguments.positional[0], env);
      print(res.value);
      return Value.nullInstance;
    } else {
      throw new NotImplemented('Support for statement type '
          '${node.runtimeType} is not implemented');
    }
  }

  Value visitMethodInvocation(MethodInvocation node, env) {
    // Currently supports only method invocation with <2 arguments and is used
    // to evaluate implemented operators for int, double and String values.
    var receiver = eval(node.receiver, env);
    if (node.arguments.positional.isNotEmpty) {
      var argValue = eval(node.arguments.positional.first, env);
      return receiver.invokeMethod(node.name, argValue);
    } else {
      return receiver.invokeMethod(node.name);
    }
  }

  Value visitConstructorInvocation(ConstructorInvocation node, env) {
    Class class_ = new Class(node.target.enclosingClass.reference);

    Environment emptyEnv = new Environment.empty();
    // Currently we don't support initializers.
    // TODO: Modify to respect dart semantics for initialization.
    //  1. Init fields and eval initializers, repeat the same with super.
    //  2. Eval the Function body of the constructor.
    List<Value> fields = class_.instanceFields
        .map((Field f) => eval(f.initializer ?? new NullLiteral(), emptyEnv))
        .toList(growable: false);

    return new ObjectValue(class_, fields);
  }

  Value visitNot(Not node, env) {
    Value operand = eval(node.operand, env).toBoolean();
    return identical(operand, Value.trueInstance)
        ? Value.falseInstance
        : Value.trueInstance;
  }

  Value visitLogicalExpression(LogicalExpression node, env) {
    if ('||' == node.operator) {
      BoolValue left = eval(node.left, env).toBoolean();
      return identical(left, Value.trueInstance)
          ? Value.trueInstance
          : eval(node.right, env).toBoolean();
    } else {
      assert('&&' == node.operator);
      BoolValue left = eval(node.left, env).toBoolean();
      return identical(left, Value.falseInstance)
          ? Value.falseInstance
          : eval(node.right, env).toBoolean();
    }
  }

  Value visitConditionalExpression(ConditionalExpression node, env) {
    var condition = eval(node.condition, env).toBoolean();
    return identical(condition, Value.trueInstance)
        ? eval(node.then, env)
        : eval(node.otherwise, env);
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
  Value visitBoolLiteral(BoolLiteral node, env) =>
      node.value ? Value.trueInstance : Value.falseInstance;
  Value visitNullLiteral(NullLiteral node, env) => Value.nullInstance;

  Value visitLet(Let node, env) {
    var value = eval(node.variable.initializer, env);
    var letEnv = new Environment(env);
    letEnv.expand(node.variable, value);
    return eval(node.body, letEnv);
  }
}

/// Represents a state which consists of current environment, continuation to be
/// applied and the current label.
class State {
  final Environment environment;
  final Label labels;
  final Continuation continuation;

  State(this.environment, this.labels, this.continuation);
  State.initial() : this(new Environment.empty(), null, null);

  State withEnvironment(Environment env) {
    return new State(env, labels, continuation);
  }

  State withBreak(Statement stmt) {
    return new State(
        environment, new Label(stmt, continuation, labels), continuation);
  }

  State withContinuation(Continuation cont) {
    return new State(environment, labels, cont);
  }

  Label lookupLabel(LabeledStatement s) {
    assert(labels != null);
    return labels.lookupLabel(s);
  }
}

/// Represent the continuation for execution of statement.
class Continuation {
  final Statement statement;
  final State state;

  Continuation(this.statement, this.state);
}

/// Represents a labeled statement, the corresponding continuation and the
/// enclosing label.
class Label {
  final LabeledStatement statement;
  final Continuation continuation;
  final Label enclosingLabel;

  Label(this.statement, this.continuation, this.enclosingLabel);

  Label lookupLabel(LabeledStatement s) {
    if (identical(s, statement)) return this;
    assert(enclosingLabel != null);
    return enclosingLabel.lookupLabel(s);
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
class StatementExecuter extends StatementVisitor1<Continuation> {
  Evaluator evaluator = new Evaluator();

  void trampolinedExecution(Continuation continuation) {
    while (continuation != null) {
      continuation = exec(continuation.statement, continuation.state);
    }
  }

  Continuation exec(Statement statement, state) =>
      statement.accept1(this, state);
  Value eval(Expression expression, env) => evaluator.eval(expression, env);

  Continuation defaultStatement(Statement node, state) {
    throw notImplemented(
        m: "Execution is not implemented for statement:\n$node ");
  }

  Continuation visitInvalidStatement(InvalidStatement node, state) {
    throw "Invalid statement at ${node.location}";
  }

  Continuation visitExpressionStatement(ExpressionStatement node, state) {
    eval(node.expression, state.environment);
    return state.continuation;
  }

  Continuation visitBlock(Block node, state) {
    if (node.statements.isEmpty) {
      return state.continuation;
    }
    State blockState =
        state.withEnvironment(new Environment(state.environment));
    Continuation cont = state.continuation;
    for (Statement s in node.statements.reversed) {
      cont = new Continuation(s, blockState.withContinuation(cont));
    }
    return cont;
  }

  Continuation visitEmptyStatement(EmptyStatement node, state) {
    return state.continuation;
  }

  Continuation visitIfStatement(IfStatement node, state) {
    Value cond = eval(node.condition, state.environment).toBoolean();
    if (identical(Value.trueInstance, cond)) {
      return new Continuation(node.then, state);
    } else if (node.otherwise != null) {
      return new Continuation(node.otherwise, state);
    }
    return state.continuation;
  }

  Continuation visitLabeledStatement(LabeledStatement node, state) {
    return new Continuation(node.body, state.withBreak(node));
  }

  Continuation visitBreakStatement(BreakStatement node, state) {
    return state.lookupLabel(node.target).continuation;
  }

  Continuation visitWhileStatement(WhileStatement node, state) {
    Value cond = eval(node.condition, state.environment).toBoolean();
    if (identical(Value.trueInstance, cond)) {
      // Add continuation for the While statement to the linked list.
      Continuation cont = new Continuation(node, state);
      // Continuation for the body of the loop.
      return new Continuation(node.body, state.withContinuation(cont));
    }
    return state.continuation;
  }

  Continuation visitDoStatement(DoStatement node, state) {
    WhileStatement whileStatement =
        new WhileStatement(node.condition, node.body);
    Continuation cont = new Continuation(whileStatement, state);
    return new Continuation(node.body, state.withContinuation(cont));
  }

  Continuation visitVariableDeclaration(VariableDeclaration node, state) {
    Value value = node.initializer != null
        ? eval(node.initializer, state.environment)
        : Value.nullInstance;
    state.environment.expand(node, value);
    return state.continuation;
  }
}

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
