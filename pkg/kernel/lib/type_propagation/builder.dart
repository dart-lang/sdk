// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.type_propagation.builder;

import '../ast.dart';
import '../class_hierarchy.dart';
import 'constraints.dart';
import 'canonicalizer.dart';
import 'visualizer.dart';
import '../core_types.dart';

/// Generates a [ConstraintSystem] to be solved by [Solver].
class Builder {
  final Program program;
  final ClassHierarchy hierarchy;
  final CoreTypes coreTypes;
  final ConstraintSystem constraints;
  final FieldNames fieldNames;
  final Visualizer visualizer;

  final Map<Field, int> fields = <Field, int>{};
  final Map<Procedure, int> tearOffs = <Procedure, int>{};
  final Map<VariableDeclaration, int> functionParameters =
      <VariableDeclaration, int>{};
  final Map<Procedure, int> returnValues = <Procedure, int>{};

  int bottomNode;
  int dynamicNode;
  int boolNode;
  int intNode;
  int doubleNode;
  int stringNode;
  int symbolNode;
  int typeNode;
  int listNode;
  int mapNode;
  int nullNode;
  int iterableNode;
  int futureNode;
  int streamNode;
  int functionValueNode;

  int iteratorField;
  int currentField;

  bool verbose;

  Builder(Program program,
      {ClassHierarchy hierarchy,
      FieldNames names,
      CoreTypes coreTypes,
      Visualizer visualizer,
      bool verbose: false})
      : this._internal(
            program,
            hierarchy ?? new ClassHierarchy(program),
            names ?? new FieldNames(),
            coreTypes ?? new CoreTypes(program),
            visualizer,
            verbose);

  Builder._internal(this.program, ClassHierarchy hierarchy, FieldNames names,
      this.coreTypes, Visualizer visualizer, this.verbose)
      : this.hierarchy = hierarchy,
        this.fieldNames = names,
        this.visualizer = visualizer,
        this.constraints = new ConstraintSystem(hierarchy.classes.length) {
    if (visualizer != null) {
      visualizer.builder = this;
      visualizer.constraints = constraints;
      visualizer.fieldNames = fieldNames;
      for (int i = 0; i < hierarchy.classes.length; ++i) {
        visualizer.annotateVariable(i, hierarchy.classes[i]);
      }
    }

    bottomNode = newVariable(null, 'bottom');
    dynamicNode = getClassValue(coreTypes.objectClass);
    boolNode = getClassValue(coreTypes.boolClass);
    intNode = getClassValue(coreTypes.intClass);
    doubleNode = getClassValue(coreTypes.doubleClass);
    stringNode = getClassValue(coreTypes.stringClass);
    symbolNode = getClassValue(coreTypes.symbolClass);
    typeNode = getClassValue(coreTypes.typeClass);
    listNode = getClassValue(coreTypes.listClass);
    mapNode = getClassValue(coreTypes.mapClass);
    iterableNode = getClassValue(coreTypes.iterableClass);
    futureNode = getClassValue(coreTypes.futureClass);
    streamNode = getClassValue(coreTypes.streamClass);
    functionValueNode = getClassValue(coreTypes.functionClass);
    nullNode = bottomNode; // Assume anything might be null so don't propagate.

    iteratorField = getPropertyField(Names.iterator);
    currentField = getPropertyField(Names.current);

    for (Library library in program.libraries) {
      for (Procedure procedure in library.procedures) {
        buildStaticMethod(procedure);
      }
      for (Field field in library.fields) {
        buildStaticField(field);
      }
      for (Class class_ in library.classes) {
        for (Procedure procedure in class_.procedures) {
          if (procedure.isStatic) {
            buildStaticMethod(procedure);
          } else {
            buildInstanceMethod(procedure);
          }
        }
        for (Field field in class_.fields) {
          if (field.isStatic) {
            buildStaticField(field);
          } else {
            buildInstanceField(field);
          }
        }
        for (Constructor constructor in class_.constructors) {
          buildConstructor(constructor);
        }
      }
    }
  }

  int newVariable([TreeNode node, String info]) {
    int variable = constraints.newVariable();
    visualizer?.annotateVariable(variable, node, info);
    return variable;
  }

  int getField(Field field) {
    return fields[field] ??= newVariable(field);
  }

  int getFunctionParameter(VariableDeclaration node) {
    return functionParameters[node] ??= newVariable(node, 'parameter');
  }

  int getReturnValue(Procedure node) {
    return returnValues[node] ??= newVariable(node, 'return');
  }

  int getTearOff(Procedure node) {
    return tearOffs[node] ??= newVariable(node, 'function');
  }

  int getClassValue(Class node) {
    return hierarchy.getClassIndex(node);
  }

  int getJoin(int first, int second) {
    // TODO(asgerf): Avoid redundant joins in common cases.
    int joinPoint = constraints.newVariable();
    constraints..addAssign(first, joinPoint)..addAssign(second, joinPoint);
    return joinPoint;
  }

  int getLoad(int object, int field) {
    // TODO(asgerf): Canonicalize loads.
    int variable = constraints.newVariable();
    constraints.addLoad(object, field, variable);
    return variable;
  }

  void addLoad(int object, int field, int destination) {
    constraints.addLoad(object, field, destination);
  }

  int getStore(int object, int field) {
    // TODO(asgerf): Canonicalize stores.
    int variable = constraints.newVariable();
    constraints.addStore(object, field, variable);
    return variable;
  }

  void addStore(int object, int field, int value) {
    constraints.addStore(object, field, value);
  }

  int getPropertyField(Name name) {
    return fieldNames.getPropertyField(name);
  }

  int getPositionalParameterField(int arity, int position) {
    return fieldNames.getPositionalParameterField(arity, position);
  }

  int getNamedParameterField(int arity, String name) {
    return fieldNames.getNamedParameterField(arity, name);
  }

  int getReturnField(int arity) {
    return fieldNames.getReturnField(arity);
  }

  void buildStaticMethod(Procedure node) {
    var environment =
        new Environment(this, returnValue: getReturnValue(node));
    buildFunctionNode(node.function, environment,
        functionValue: getTearOff(node));
  }

  void buildStaticField(Field field) {
    int value = nullNode;
    if (field.initializer != null) {
      var environment = new Environment(this);
      value = new ExpressionBuilder(this, environment).build(field.initializer);
    }
    constraints.addAssign(value, getField(field));
  }

  void buildInstanceMethod(Procedure node) {
    var environment = new Environment(this,
        returnValue: getReturnValue(node),
        thisValue: getClassValue(node.enclosingClass));
    buildFunctionNode(node.function, environment,
        functionValue: getTearOff(node));
  }

  void buildInstanceField(Field node) {
    int value = nullNode;
    if (node.initializer != null) {
      var environment = new Environment(this);
      value = new ExpressionBuilder(this, environment).build(node.initializer);
    }
    constraints.addAssign(value, getField(node));
    var host = getClassValue(node.enclosingClass);
    int field = getPropertyField(node.name);
    addStore(host, field, value);
  }

  void buildConstructor(Constructor node) {
    var environment = new Environment(this,
        thisValue: getClassValue(node.enclosingClass));
    buildFunctionNode(node.function, environment);
  }

  void buildFunctionNode(FunctionNode node, Environment environment,
      {int functionValue}) {
    if (node.body == null) return;
    int minArity = node.requiredParameterCount;
    int maxArity = node.positionalParameters.length;
    for (int i = 0; i < node.positionalParameters.length; ++i) {
      var parameter = node.positionalParameters[i];
      int value = getFunctionParameter(parameter);
      environment.localVariables[parameter] = value;
      if (functionValue != null) {
        for (int arity = minArity; arity <= maxArity; ++arity) {
          addLoad(functionValue, getPositionalParameterField(arity, i), value);
        }
      }
    }
    for (int i = 0; i < node.namedParameters.length; ++i) {
      var parameter = node.namedParameters[i];
      int value = getFunctionParameter(parameter);
      environment.localVariables[parameter] = value;
      if (functionValue != null) {
        for (int arity = minArity; arity <= maxArity; ++arity) {
          addLoad(functionValue, getNamedParameterField(arity, parameter.name),
              value);
        }
      }
    }
    if (environment.returnValue == null) {
      environment.returnValue = newVariable(node, 'return');
    } else {
      visualizer?.annotateVariable(environment.returnValue, node, 'return');
    }
    if (functionValue != null) {
      for (int arity = minArity; arity <= maxArity; ++arity) {
        addStore(functionValue, getReturnField(arity), environment.returnValue);
      }
    }
    new StatementBuilder(this, environment).build(node.body);
  }

  Set<String> _unsupportedNodes = new Set<String>();

  int unsupported(Node node) {
    if (verbose && _unsupportedNodes.add('${node.runtimeType}')) {
      print('Unsupported: ${node.runtimeType}');
    }
    return dynamicNode;
  }
}

/// Generates unique IDs for fields in the constraint system.
///
/// We use several fields in the constraint system that do not correspond to
/// Dart fields.  A "field" in this context should be seen as a storage location
/// that is specific to an instance.
class FieldNames {
  final TupleCanonicalizer _table = new TupleCanonicalizer();
  static const int _TagName = 1;
  static const int _TagPositionalParameter = 2;
  static const int _TagNamedParameter = 3;
  static const int _TagReturn = 4;

  /// Field representing the value returned from a getter, passed into a setter,
  /// or stored in a Dart field with the given name.
  int getPropertyField(Name name) {
    return _table.get2(_TagName, name);
  }

  /// Field representing the given positional parameter passed to a method
  /// invoked with the given arity.
  int getPositionalParameterField(int arity, int position) {
    return _table.get3(_TagPositionalParameter, arity, position);
  }

  /// Field representing the given named parameter passed to a method invoked
  /// with the given arity.
  int getNamedParameterField(int arity, String name) {
    return _table.get3(_TagNamedParameter, arity, name);
  }

  /// Field representing the return value of a method invoked the given arity.
  int getReturnField(int arity) {
    return _table.get2(_TagReturn, arity);
  }

  int get length => _table.length;

  String getDiagnosticNameOfField(int field) {
    List<Object> tuple = _table.getFromIndex(field);
    switch (tuple[0]) {
      case _TagName:
        return '${tuple[1]}';
      case _TagPositionalParameter:
        return 'pos(${tuple[1]},${tuple[2]})';
      case _TagNamedParameter:
        return 'named(${tuple[1]},${tuple[2]})';
      case _TagReturn:
        return 'return(${tuple[1]})';
      default:
        return '!error';
    }
  }
}

class Environment {
  final Builder builder;
  final Map<VariableDeclaration, int> localVariables =
      <VariableDeclaration, int>{};
  int thisValue;
  int returnValue;

  Environment(this.builder, {this.thisValue, this.returnValue});

  int getVariable(VariableDeclaration variable) {
    return localVariables[variable] ??= builder.newVariable(variable);
  }
}

class ExpressionBuilder extends ExpressionVisitor<int> {
  final Builder builder;
  final Environment environment;

  ConstraintSystem get constraints => builder.constraints;
  Visualizer get visualizer => builder.visualizer;
  FieldNames get names => builder.fieldNames;

  ExpressionBuilder(this.builder, this.environment);

  int build(Expression node) {
    int variable = node.accept(this);
    visualizer?.annotateVariable(variable, node);
    return variable;
  }

  int unsupported(Expression node) {
    return builder.unsupported(node);
  }

  int visitInvalidExpression(InvalidExpression node) {
    return builder.bottomNode;
  }

  int visitVariableGet(VariableGet node) {
    return environment.getVariable(node.variable);
  }

  int visitVariableSet(VariableSet node) {
    int value = build(node.value);
    int variable = environment.getVariable(node.variable);
    constraints.addAssign(value, variable);
    return value;
  }

  int visitPropertyGet(PropertyGet node) {
    int object = build(node.receiver);
    int field = names.getPropertyField(node.name);
    return builder.getLoad(object, field);
  }

  int visitPropertySet(PropertySet node) {
    int object = build(node.receiver);
    int field = names.getPropertyField(node.name);
    int value = build(node.value);
    builder.addStore(object, field, value);
    return value;
  }

  void buildArguments(Arguments node) {
    for (int i = 0; i < node.positional.length; ++i) {
      build(node.positional[i]);
    }
    for (int i = 0; i < node.named.length; ++i) {
      build(node.named[i].value);
    }
  }

  int visitSuperPropertyGet(SuperPropertyGet node) {
    return unsupported(node);
  }

  int visitSuperPropertySet(SuperPropertySet node) {
    build(node.value);
    return unsupported(node);
  }

  int visitStaticGet(StaticGet node) {
    if (node.target is Procedure) {
      Procedure target = node.target;
      if (target.isGetter) {
        return builder.getReturnValue(target);
      } else {
        return unsupported(node);
      }
    }
    return builder.getField(node.target);
  }

  int visitStaticSet(StaticSet node) {
    int value = build(node.value);
    int field = builder.getField(node.target);
    constraints.addAssign(value, field);
    return value;
  }

  int visitMethodInvocation(MethodInvocation node) {
    int receiver = build(node.receiver);
    int methodProperty = builder.getPropertyField(node.name);
    int function = node.name.name == 'call'
        ? receiver
        : builder.getLoad(receiver, methodProperty);
    visualizer?.annotateVariable(function, node, 'callee');
    int arity = node.arguments.positional.length;
    for (int i = 0; i < node.arguments.positional.length; ++i) {
      int field = builder.getPositionalParameterField(arity, i);
      int argument = build(node.arguments.positional[i]);
      builder.addStore(function, field, argument);
    }
    for (int i = 0; i < node.arguments.named.length; ++i) {
      NamedExpression namedNode = node.arguments.named[i];
      int field = builder.getNamedParameterField(arity, namedNode.name);
      int argument = build(namedNode.value);
      builder.addStore(function, field, argument);
    }
    return builder.getLoad(function, builder.getReturnField(arity));
  }

  void passArgumentsToFunction(Arguments node, FunctionNode function) {
    // TODO(asgerf): Check that arity matches (although mismatches are rare).
    for (int i = 0; i < node.positional.length; ++i) {
      int argument = build(node.positional[i]);
      if (i < function.positionalParameters.length) {
        int parameter =
            environment.getVariable(function.positionalParameters[i]);
        constraints.addAssign(argument, parameter);
      }
    }
    for (int i = 0; i < node.named.length; ++i) {
      NamedExpression namedNode = node.named[i];
      int argument = build(namedNode.value);
      // TODO(asgerf): Avoid the slow lookup for named parameters.
      for (int j = 0; j < function.namedParameters.length; ++j) {
        var namedParameter = function.namedParameters[j];
        if (namedParameter.name == namedNode.name) {
          int parameter = builder.getFunctionParameter(namedParameter);
          constraints.addAssign(argument, parameter);
          break;
        }
      }
    }
  }

  int visitSuperMethodInvocation(SuperMethodInvocation node) {
    passArgumentsToFunction(node.arguments, node.target.function);
    return builder.getReturnValue(node.target);
  }

  int visitStaticInvocation(StaticInvocation node) {
    passArgumentsToFunction(node.arguments, node.target.function);
    return builder.getReturnValue(node.target);
  }

  int visitConstructorInvocation(ConstructorInvocation node) {
    passArgumentsToFunction(node.arguments, node.target.function);
    return builder.getClassValue(node.target.enclosingClass);
  }

  int visitNot(Not node) {
    build(node.operand);
    return builder.boolNode;
  }

  int visitLogicalExpression(LogicalExpression node) {
    int left = build(node.left);
    int right = build(node.right);
    if (node.operator == '??') {
      return builder.getJoin(left, right);
    } else {
      return builder.boolNode;
    }
  }

  int visitConditionalExpression(ConditionalExpression node) {
    build(node.condition);
    int then = build(node.then);
    int otherwise = build(node.otherwise);
    return builder.getJoin(then, otherwise);
  }

  int visitStringConcatenation(StringConcatenation node) {
    for (int i = 0; i < node.expressions.length; ++i) {
      build(node.expressions[i]);
    }
    return builder.stringNode;
  }

  int visitIsExpression(IsExpression node) {
    build(node.operand);
    return builder.boolNode;
  }

  int visitAsExpression(AsExpression node) {
    return build(node.operand);
  }

  int visitSymbolLiteral(SymbolLiteral node) {
    return builder.symbolNode;
  }

  int visitTypeLiteral(TypeLiteral node) {
    return builder.typeNode;
  }

  int visitThisExpression(ThisExpression node) {
    return environment.thisValue;
  }

  int visitRethrow(Rethrow node) {
    return builder.bottomNode;
  }

  int visitThrow(Throw node) {
    build(node.expression);
    return builder.bottomNode;
  }

  int visitListLiteral(ListLiteral node) {
    // TODO(asgerf): The list should contain the values.
    //   This will be easier to support when we add externals.
    for (int i = 0; i < node.expressions.length; ++i) {
      build(node.expressions[i]);
    }
    return builder.listNode;
  }

  int visitMapLiteral(MapLiteral node) {
    for (int i = 0; i < node.entries.length; ++i) {
      var entry = node.entries[i];
      build(entry.key);
      build(entry.value);
    }
    return builder.mapNode;
  }

  int visitAwaitExpression(AwaitExpression node) {
    return unsupported(node);
  }

  int visitFunctionExpression(FunctionExpression node) {
    int value = builder.functionValueNode;
    builder.buildFunctionNode(node.function, environment, functionValue: value);
    return value;
  }

  int visitStringLiteral(StringLiteral node) {
    return builder.stringNode;
  }

  int visitIntLiteral(IntLiteral node) {
    return builder.intNode;
  }

  int visitDoubleLiteral(DoubleLiteral node) {
    return builder.doubleNode;
  }

  int visitBoolLiteral(BoolLiteral node) {
    return builder.boolNode;
  }

  int visitNullLiteral(NullLiteral node) {
    return builder.nullNode;
  }

  int visitLet(Let node) {
    environment.localVariables[node.variable] =
        build(node.variable.initializer);
    return build(node.body);
  }
}

class StatementBuilder extends StatementVisitor {
  final Builder builder;
  final Environment environment;
  ExpressionBuilder expressionBuilder;

  ConstraintSystem get constraints => builder.constraints;
  Visualizer get visualizer => builder.visualizer;
  FieldNames get names => builder.fieldNames;

  StatementBuilder(this.builder, this.environment) {
    expressionBuilder = new ExpressionBuilder(builder, environment);
  }

  void build(Statement node) {
    node.accept(this);
  }

  void buildOptional(Statement node) {
    if (node != null) {
      node.accept(this);
    }
  }

  int buildExpression(Expression node) {
    return expressionBuilder.build(node);
  }

  void unsupported(Statement node) {
    builder.unsupported(node);
  }

  visitInvalidStatement(InvalidStatement node) {}

  visitExpressionStatement(ExpressionStatement node) {
    buildExpression(node.expression);
  }

  visitBlock(Block node) {
    for (int i = 0; i < node.statements.length; ++i) {
      build(node.statements[i]);
    }
  }

  visitEmptyStatement(EmptyStatement node) {}

  visitAssertStatement(AssertStatement node) {
    unsupported(node);
  }

  visitLabeledStatement(LabeledStatement node) {
    build(node.body);
  }

  visitBreakStatement(BreakStatement node) {}

  visitWhileStatement(WhileStatement node) {
    buildExpression(node.condition);
    build(node.body);
  }

  visitDoStatement(DoStatement node) {
    build(node.body);
    buildExpression(node.condition);
  }

  visitForStatement(ForStatement node) {
    for (int i = 0; i < node.variables.length; ++i) {
      build(node.variables[i]);
    }
    if (node.condition != null) {
      buildExpression(node.condition);
    }
    for (int i = 0; i < node.updates.length; ++i) {
      buildExpression(node.updates[i]);
    }
    build(node.body);
  }

  visitForInStatement(ForInStatement node) {
    int iterable = buildExpression(node.iterable);
    int iterator = builder.getLoad(iterable, builder.iteratorField);
    int current = builder.getLoad(iterator, builder.currentField);
    int variable = environment.getVariable(node.variable);
    constraints.addAssign(current, variable);
    build(node.body);
  }

  visitSwitchStatement(SwitchStatement node) {
    buildExpression(node.expression);
    for (int i = 0; i < node.cases.length; ++i) {
      // There is no need to visit the expression since constants cannot
      // have side effects.
      build(node.cases[i].body);
    }
  }

  visitContinueSwitchStatement(ContinueSwitchStatement node) {}

  visitIfStatement(IfStatement node) {
    buildExpression(node.condition);
    build(node.then);
    buildOptional(node.otherwise);
  }

  visitReturnStatement(ReturnStatement node) {
    if (node.expression != null) {
      int value = buildExpression(node.expression);
      constraints.addAssign(value, environment.returnValue);
    }
  }

  visitTryCatch(TryCatch node) {
    build(node.body);
    for (int i = 0; i < node.catches.length; ++i) {
      Catch catchNode = node.catches[i];
      if (catchNode.exception != null) {
        environment.localVariables[catchNode.exception] = builder.dynamicNode;
      }
      if (catchNode.stackTrace != null) {
        environment.localVariables[catchNode.stackTrace] = builder.dynamicNode;
      }
      build(catchNode.body);
    }
  }

  visitTryFinally(TryFinally node) {
    build(node.body);
    build(node.finalizer);
  }

  visitYieldStatement(YieldStatement node) {
    unsupported(node);
  }

  visitVariableDeclaration(VariableDeclaration node) {
    int value = node.initializer == null
        ? builder.nullNode
        : buildExpression(node.initializer);
    int variable = environment.getVariable(node);
    constraints.addAssign(value, variable);
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    environment.localVariables[node.variable] = builder.functionValueNode;
    builder.buildFunctionNode(node.function, environment,
        functionValue: builder.functionValueNode);
  }
}

class Names {
  static final Name current = new Name('current');
  static final Name iterator = new Name('iterator');
  static final Name then = new Name('then');
}
