// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.interpreter;

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

  Value visitPropertyGet(PropertyGet node, env) {
    Value receiver = eval(node.receiver, env);
    return receiver.classDeclaration.lookupGetter(node.name)(receiver);
  }

  Value visitPropertySet(PropertySet node, env) {
    Value receiver = eval(node.receiver, env);
    Value value = eval(node.value, env);
    receiver.classDeclaration.lookupSetter(node.name)(receiver, value);
    return value;
  }

  Value visitDirectPropertyGet(DirectPropertyGet node, env) {
    Value receiver = eval(node.receiver, env);
    return receiver.classDeclaration.getProperty(receiver, node.target);
  }

  Value visitDirectPropertySet(DirectPropertySet node, env) {
    Value receiver = eval(node.receiver, env);
    Value value = eval(node.value, env);
    receiver.classDeclaration.setProperty(receiver, node.target, value);
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
    ClassDeclaration classDeclaration =
        new ClassDeclaration(node.target.enclosingClass.reference);

    Environment emptyEnv = new Environment.empty();
    // Currently we don't support initializers.
    // TODO: Modify to respect dart semantics for initialization.
    //  1. Init fields and eval initializers, repeat the same with super.
    //  2. Eval the Function body of the constructor.
    List<Value> fields = classDeclaration.instanceFields
        .map((Field f) => eval(f.initializer, emptyEnv))
        .toList(growable: false);

    return new ObjectValue(classDeclaration, fields);
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

typedef Value Getter(Value receiver);
typedef void Setter(Value receiver, Value value);

// TODO(zhivkag): Change misleading name.
// This is representation of a class in the interpreter, not a declaration.
class ClassDeclaration {
  static final Map<Reference, ClassDeclaration> _classes =
      <Reference, ClassDeclaration>{};

  ClassDeclaration superclass;
  List<Field> instanceFields = <Field>[];
  List<Field> staticFields = <Field>[];
  // Implicit getters and setters for instance Fields.
  Map<Name, Getter> getters = <Name, Getter>{};
  Map<Name, Setter> setters = <Name, Setter>{};
  // The initializers of static fields are evaluated the first time the field
  // is accessed.
  List<Value> staticFieldValues = <Value>[];

  List<Procedure> methods = <Procedure>[];

  factory ClassDeclaration(Reference classRef) {
    if (_classes.containsKey(classRef)) {
      return _classes[classRef];
    }
    _classes[classRef] = new ClassDeclaration._internal(classRef.asClass);
    return _classes[classRef];
  }

  ClassDeclaration._internal(Class currentClass) {
    if (currentClass.superclass != null) {
      superclass = new ClassDeclaration(currentClass.superclass.reference);
    }

    _populateInstanceFields(currentClass);

    // Populate implicit setters and getters.
    for (int i = 0; i < instanceFields.length; i++) {
      Field f = instanceFields[i];
      assert(f.hasImplicitGetter);
      getters[f.name] = (Value receiver) => receiver.fields[i];
      if (f.hasImplicitSetter) {
        setters[f.name] =
            (Value receiver, Value value) => receiver.fields[i] = value;
      }
    }
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
    if (superclass != null) return lookupSetter(name);
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

  // Populates with the instance fields of the current class and all its
  // superclasses recursively.
  _populateInstanceFields(Class class_) {
    for (Field f in class_.fields) {
      if (f.isInstanceMember) {
        instanceFields.add(f);
      }
    }

    if (class_.superclass != null) {
      _populateInstanceFields(class_.superclass);
    }
  }
}

abstract class Value {
  ClassDeclaration get classDeclaration;
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
  ClassDeclaration classDeclaration;
  List<Value> fields;
  Object get value => this;

  ObjectValue(this.classDeclaration, this.fields);
}

abstract class LiteralValue extends Value {
  ClassDeclaration get classDeclaration =>
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
