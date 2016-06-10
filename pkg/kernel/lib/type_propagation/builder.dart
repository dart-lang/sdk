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
  final Map<TypeParameter, int> functionTypeParameters = <TypeParameter, int>{};

  /// Maps a class index to the result of [getInterfaceEscapeVariable].
  final List<int> interfaceEscapeVariables;

  /// Maps a class index to the result of [getExternalInstanceVariable].
  final List<int> externalClassVariables;

  final List<int> externalClassWorklist = <int>[];

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
        this.constraints = new ConstraintSystem(hierarchy.classes.length),
        this.interfaceEscapeVariables = new List<int>(hierarchy.classes.length),
        this.externalClassVariables = new List<int>(hierarchy.classes.length) {
    if (visualizer != null) {
      visualizer.builder = this;
      visualizer.constraints = constraints;
      visualizer.fieldNames = fieldNames;
      for (int i = 0; i < hierarchy.classes.length; ++i) {
        visualizer.annotateVariable(i, hierarchy.classes[i]);
      }
    }

    bottomNode = newVariable(null, 'bottom');
    dynamicNode = getExternalInstanceVariable(coreTypes.objectClass);
    boolNode = getExternalInstanceVariable(coreTypes.boolClass);
    intNode = getExternalInstanceVariable(coreTypes.intClass);
    doubleNode = getExternalInstanceVariable(coreTypes.doubleClass);
    stringNode = getExternalInstanceVariable(coreTypes.stringClass);
    symbolNode = getExternalInstanceVariable(coreTypes.symbolClass);
    typeNode = getExternalInstanceVariable(coreTypes.typeClass);
    listNode = getExternalInstanceVariable(coreTypes.listClass);
    mapNode = getExternalInstanceVariable(coreTypes.mapClass);
    iterableNode = getExternalInstanceVariable(coreTypes.iterableClass);
    futureNode = getExternalInstanceVariable(coreTypes.futureClass);
    streamNode = getExternalInstanceVariable(coreTypes.streamClass);
    functionValueNode = getExternalInstanceVariable(coreTypes.functionClass);
    nullNode = bottomNode; // Assume anything might be null so don't propagate.

    iteratorField = getPropertyField(Names.iterator);
    currentField = getPropertyField(Names.current);

    for (Library library in program.libraries) {
      for (Procedure procedure in library.procedures) {
        buildProcedure(procedure, null);
      }
      for (Field field in library.fields) {
        buildStaticField(field);
      }
      for (Class class_ in library.classes) {
        int host = getInstanceVariable(class_);
        for (Procedure procedure in class_.procedures) {
          if (!procedure.isAbstract) {
            buildProcedure(procedure, host);
          }
        }
        for (Field field in class_.fields) {
          if (field.isStatic) {
            buildStaticField(field);
          } else {
            buildInstanceField(field, host);
          }
        }
        for (Constructor constructor in class_.constructors) {
          buildConstructor(constructor, host);
        }
      }
    }

    // Build constraints mocking the external interfaces.
    while (externalClassWorklist.isNotEmpty) {
      int classIndex = externalClassWorklist.removeLast();
      _buildExternalClassValue(classIndex);
    }
  }

  int newVariable([TreeNode node, String info]) {
    int variable = constraints.newVariable();
    visualizer?.annotateVariable(variable, node, info);
    return variable;
  }

  /// Returns a variable that should contain all values that may be contained
  /// in the given field.
  ///
  /// For instance fields, do not assign to this variable, but rather emit a
  /// store to the the receiver object.
  int getFieldVariable(Field field) {
    return fields[field] ??= newVariable(field);
  }

  int getParameterVariable(VariableDeclaration node) {
    return functionParameters[node] ??= newVariable(node, 'parameter');
  }

  /// Returns the variable representing all the values that would be checked
  /// against the given function type parameter in checked mode.
  ///
  /// This is used to model the behavior of external generic methods.
  ///
  /// For example:
  ///
  ///     class List {
  ///         external static factory List<T> filled<T>(int length, T value);
  ///     }
  ///
  /// A variable `v` representing `T` will be generated. All values that are
  /// passed into the `value` parameter will flow into `v`, and `v` will
  /// in turn flow into the type parameter field of `List`, because the method
  /// returns `List<T>`.  Also see [FieldNames.getTypeParameterField].
  int getFunctionTypeParameterVariable(TypeParameter node) {
    return functionTypeParameters[node] ??= newVariable(node);
  }

  int getReturnVariable(Procedure node) {
    return returnValues[node] ??= newVariable(node, 'return');
  }

  /// Returns a variable containing the torn-off copy of the given procedure.
  int getTearOffVariable(Procedure node) {
    return tearOffs[node] ??= _makeTearOffVariable(node);
  }

  int _makeTearOffVariable(Procedure node) {
    int variable = newVariable(node, 'function');
    constraints.addAllocateFunction(newFunctionValue(node.function), variable);
    return variable;
  }

  /// Returns a new function value annotated with given AST node.
  ///
  /// Note that the returned value is not a variable. Add a function allocation
  /// constraint to move it into a variable.
  int newFunctionValue(FunctionNode node) {
    int functionValue = constraints.newFunctionValue();
    visualizer?.annotateFunction(functionValue, node);
    return functionValue;
  }

  /// Returns a variable containing the instances of the given class.
  int getInstanceVariable(Class node) {
    return hierarchy.getClassIndex(node);
  }

  /// Returns a variable containing the external instances of the given class.
  ///
  /// An "external instance of C" is an instance allocated by external code,
  /// and is either a direct instance of C or an instance of an external class
  /// that implements C.
  ///
  /// For the moment, basic types like `int` and `bool` are treated as external
  /// instances of their respective classes.
  ///
  /// Unlike [getInstanceVariable], this method ensures that the relevant
  /// constraints have been generated to model an external implementation of the
  /// class.
  int getExternalInstanceVariable(Class node) {
    int classIndex = hierarchy.getClassIndex(node);
    int externalObject = externalClassVariables[classIndex];
    if (externalObject == null) {
      // TODO(asgerf): For now we use the same abstract object for internal
      // and external instances, but we may want to change this.
      externalObject = classIndex;
      externalClassVariables[classIndex] = externalObject;
      externalClassWorklist.add(classIndex);
    }
    return externalObject;
  }

  void _buildExternalClassValue(int index) {
    Class node = hierarchy.classes[index];
    int externalObject = externalClassVariables[index];
    for (Member member in hierarchy.getInterfaceMembers(node, setters: false)) {
      _buildExternalInterfaceMember(member, externalObject);
    }
    for (Member member in hierarchy.getInterfaceMembers(node, setters: true)) {
      _buildExternalInterfaceMember(member, externalObject);
    }
  }

  void _buildExternalInterfaceMember(Member member, int object) {
    TypeEnvironment environment = new TypeEnvironment(this, thisValue: object);
    int propertyField = fieldNames.getPropertyField(member.name);
    if (member is Field) {
      int value = buildCovariantType(member.type, environment);
      addStore(object, propertyField, value);
    } else {
      Procedure procedure = member;
      FunctionNode function = procedure.function;
      if (procedure.isGetter) {
        int value = buildCovariantType(function.returnType, environment);
        addStore(object, propertyField, value);
      } else if (procedure.isSetter) {
        int value = getLoad(object, propertyField);
        buildContravariantType(
            function.positionalParameters[0].type, environment, value);
      } else {
        int externalMember = buildCovariantFunctionType(function, environment);
        addStore(object, propertyField, externalMember);
      }
    }
  }

  /// Returns a variable that is exposed to external calls through the
  /// given interface.
  ///
  /// For example, consider this code with a simplified version of SendPort:
  ///
  ///     abstract class SendPort {
  ///         void send(dynamic x);
  ///     }
  ///
  ///     class MySendPort implements SendPort {
  ///         void send(x) { ... }
  ///     }
  ///
  ///     external void spawnFunction(SendPort readyPort);
  ///
  ///     main() {
  ///         spawnFunction(new MySendPort());
  ///     }
  ///
  /// We must ensure that the parameter to `MySendPort::send` is inferred to
  /// be unknown because the external function `spawnFunction` may cause an
  /// invocation of its `send` method with an unknown argument.
  ///
  /// The interface escape variable for this version of `SendPort` would be a
  /// variable `v` with constraints corresponding to a call `v.send(<dynamic>)`.
  ///
  /// Values that escape into an external parameter typed as `SendPort`, such
  /// as `new MySendPort()` must then be made to flow into `v`.
  int getInterfaceEscapeVariable(Class node) {
    int index = hierarchy.getClassIndex(node);
    return interfaceEscapeVariables[index] ??
        _buildInterfaceEscapeVariable(node, index);
  }

  int _buildInterfaceEscapeVariable(Class node, int index) {
    int escapingObject = constraints.newVariable();
    visualizer?.annotateVariable(escapingObject, node, 'escape point');
    interfaceEscapeVariables[index] = escapingObject;
    for (Member member in hierarchy.getInterfaceMembers(node, setters: false)) {
      _buildEscapingInterfaceMember(member, escapingObject);
    }
    for (Member member in hierarchy.getInterfaceMembers(node, setters: true)) {
      _buildEscapingInterfaceMember(member, escapingObject);
    }
    return escapingObject;
  }

  /// Models the behavior of external code invoking [member] on
  /// [escapingObject].
  void _buildEscapingInterfaceMember(Member member, int escapingObject) {
    TypeEnvironment environment =
        new TypeEnvironment(this, thisValue: escapingObject);
    int propertyField = fieldNames.getPropertyField(member.name);
    if (member is Field) {
      int escapingMember = getLoad(escapingObject, propertyField);
      buildContravariantType(member.type, environment, escapingMember);
    } else {
      Procedure procedure = member;
      FunctionNode function = procedure.function;
      if (procedure.isGetter) {
        int escapingMember = getLoad(escapingObject, propertyField);
        buildContravariantType(
            function.returnType, environment, escapingMember);
      } else if (procedure.isSetter) {
        VariableDeclaration parameter = function.positionalParameters[0];
        int escapingMember = getLoad(escapingObject, propertyField);
        int field = fieldNames.getPositionalParameterField(1, 0);
        int value = buildCovariantType(parameter.type, environment);
        addStore(escapingMember, field, value);
      } else {
        int escapingMember = getLoad(escapingObject, propertyField);
        buildContravariantFunctionType(function, environment, escapingMember);
      }
    }
  }

  /// Returns a variable with the possible values of [type] as provided by
  /// external code.
  int buildCovariantType(DartType type, TypeEnvironment environment) {
    return new CovariantExternalTypeVisitor(this, environment).visit(type);
  }

  /// Like [buildCovariantType], but for the function type implied by the
  /// type annotations on a function AST node.
  int buildCovariantFunctionType(
      FunctionNode node, TypeEnvironment environment) {
    return new CovariantExternalTypeVisitor(this, environment)
        .buildFunctionNode(node);
  }

  /// Generates constraints to model the behavior of [input] escaping into
  /// external code through a parameter annotated with [type].
  void buildContravariantType(
      DartType type, TypeEnvironment environment, int input) {
    new ContravariantExternalTypeVisitor(this, environment, input).visit(type);
  }

  /// Like [buildContravariantType], but for the function type implied by the
  /// type annotations on a function AST node.
  void buildContravariantFunctionType(
      FunctionNode node, TypeEnvironment environment, int input) {
    new ContravariantExternalTypeVisitor(this, environment, input)
        .buildFunctionNode(node);
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

  void buildStaticField(Field field) {
    int value = nullNode;
    if (field.initializer != null) {
      var environment = new Environment(this);
      value = new ExpressionBuilder(this, environment).build(field.initializer);
    }
    constraints.addAssign(value, getFieldVariable(field));
  }

  void buildProcedure(Procedure node, int host) {
    if (node.isAbstract) return;
    int functionValue = getTearOffVariable(node);
    int returnValue = getReturnVariable(node);
    var environment =
        new Environment(this, returnValue: returnValue, thisValue: host);
    buildFunctionNode(node.function, environment,
        addTypeBasedSummary: node.isExternal, functionValue: functionValue);
    if (host != null) {
      int propertyName = fieldNames.getPropertyField(node.name);
      if (node.isGetter) {
        addStore(host, propertyName, returnValue);
      } else if (node.isSetter) {
        addLoad(host, propertyName,
            getParameterVariable(node.function.positionalParameters[0]));
      } else {
        addStore(host, propertyName, functionValue);
      }
    }
  }

  void buildInstanceField(Field node, int host) {
    int value = nullNode;
    if (node.initializer != null) {
      var environment = new Environment(this);
      value = new ExpressionBuilder(this, environment).build(node.initializer);
    }
    int field = getPropertyField(node.name);
    addStore(host, field, value);
    // Ensure all values stored in the field are propagated to the variable,
    // as this variable is part of the inference output.
    // TODO(asgerf): We could avoid this redundancy by exposing the Solver's
    //   internal storage locations for field values.
    addLoad(host, field, getFieldVariable(node));
  }

  void buildConstructor(Constructor node, int host) {
    var environment = new Environment(this, thisValue: host);
    buildFunctionNode(node.function, environment);
    InitializerBuilder builder = new InitializerBuilder(this, environment);
    for (Initializer initializer in node.initializers) {
      builder.build(initializer);
    }
  }

  void buildFunctionNode(FunctionNode node, Environment environment,
      {int functionValue, bool addTypeBasedSummary: false}) {
    int minArity = node.requiredParameterCount;
    int maxArity = node.positionalParameters.length;
    for (int i = 0; i < node.positionalParameters.length; ++i) {
      var parameter = node.positionalParameters[i];
      int value = getParameterVariable(parameter);
      environment.localVariables[parameter] = value;
      if (functionValue != null) {
        for (int arity = minArity; arity <= maxArity; ++arity) {
          addLoad(functionValue, getPositionalParameterField(arity, i), value);
        }
      }
      if (addTypeBasedSummary) {
        buildContravariantType(parameter.type, environment, value);
      }
    }
    for (int i = 0; i < node.namedParameters.length; ++i) {
      var parameter = node.namedParameters[i];
      int value = getParameterVariable(parameter);
      environment.localVariables[parameter] = value;
      if (functionValue != null) {
        for (int arity = minArity; arity <= maxArity; ++arity) {
          addLoad(functionValue, getNamedParameterField(arity, parameter.name),
              value);
        }
      }
      if (addTypeBasedSummary) {
        buildContravariantType(parameter.type, environment, value);
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
    if (addTypeBasedSummary) {
      int returnFromType = buildCovariantType(node.returnType, environment);
      constraints.addAssign(returnFromType, environment.returnValue);
    }
    if (node.body != null) {
      new StatementBuilder(this, environment).build(node.body);
    }
  }

  /// Returns true if we can assume that externals treat the given types as
  /// covariant.
  ///
  /// For example, if an external method returns a `List`, the values stored
  /// in the list from user code are not considered escaping.
  bool isAssumedCovariant(Class classNode) {
    return classNode == coreTypes.listClass ||
        classNode == coreTypes.mapClass ||
        classNode == coreTypes.iterableClass ||
        classNode == coreTypes.iteratorClass ||
        classNode == coreTypes.futureClass ||
        classNode == coreTypes.streamClass;
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
  static const int _TagTypeParameter = 5;

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

  /// Field representing the values that would be checked against the given
  /// type parameter in checked mode.
  ///
  /// The type-based modeling of externals uses this to handle types that
  /// involve type variables.  Roughly speaking, we assume that a method whose
  /// return type is a type variable T can return any value that was passed into
  /// any parameter of type T.  In particular, this is used to model the
  /// external backend storage in collection types.
  ///
  /// This field keeps track of the values that may flow into and out of a
  /// type variable for a given instance.
  int getTypeParameterField(TypeParameter parameter) {
    return _table.get2(_TagTypeParameter, parameter);
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
      case _TagTypeParameter:
        return 'type-param(${tuple[1]})';
      default:
        return '!error';
    }
  }
}

class TypeEnvironment {
  final Builder builder;
  int thisValue;

  TypeEnvironment(this.builder, {this.thisValue});
}

class Environment extends TypeEnvironment {
  final Map<VariableDeclaration, int> localVariables =
      <VariableDeclaration, int>{};
  int returnValue;

  Environment(Builder builder, {int thisValue, this.returnValue})
      : super(builder, thisValue: thisValue);

  int getVariable(VariableDeclaration variable) {
    return localVariables[variable] ??= builder.newVariable(variable);
  }
}

class ExpressionBuilder extends ExpressionVisitor<int> {
  final Builder builder;
  final Environment environment;

  ConstraintSystem get constraints => builder.constraints;
  Visualizer get visualizer => builder.visualizer;
  FieldNames get fieldNames => builder.fieldNames;

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
    int field = fieldNames.getPropertyField(node.name);
    return builder.getLoad(object, field);
  }

  int visitPropertySet(PropertySet node) {
    int object = build(node.receiver);
    int field = fieldNames.getPropertyField(node.name);
    int value = build(node.value);
    builder.addStore(object, field, value);
    return value;
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
        return builder.getReturnVariable(target);
      } else {
        return builder.getTearOffVariable(target);
      }
    }
    return builder.getFieldVariable(node.target);
  }

  int visitStaticSet(StaticSet node) {
    int value = build(node.value);
    int field = builder.getFieldVariable(node.target);
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
            builder.getParameterVariable(function.positionalParameters[i]);
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
          int parameter = builder.getParameterVariable(namedParameter);
          constraints.addAssign(argument, parameter);
          break;
        }
      }
    }
  }

  int visitSuperMethodInvocation(SuperMethodInvocation node) {
    passArgumentsToFunction(node.arguments, node.target.function);
    return builder.getReturnVariable(node.target);
  }

  int visitStaticInvocation(StaticInvocation node) {
    passArgumentsToFunction(node.arguments, node.target.function);
    return builder.getReturnVariable(node.target);
  }

  int visitConstructorInvocation(ConstructorInvocation node) {
    passArgumentsToFunction(node.arguments, node.target.function);
    return builder.getInstanceVariable(node.target.enclosingClass);
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
    var object = builder.listNode;
    TypeParameter parameter = builder.coreTypes.listClass.typeParameters.single;
    int field = fieldNames.getTypeParameterField(parameter);
    for (int i = 0; i < node.expressions.length; ++i) {
      int value = build(node.expressions[i]);
      builder.addStore(object, field, value);
    }
    return object;
  }

  int visitMapLiteral(MapLiteral node) {
    var object = builder.mapNode;
    List<TypeParameter> parameters = builder.coreTypes.mapClass.typeParameters;
    int keys = fieldNames.getTypeParameterField(parameters[0]);
    int values = fieldNames.getTypeParameterField(parameters[1]);
    for (int i = 0; i < node.entries.length; ++i) {
      var entry = node.entries[i];
      builder.addStore(object, keys, build(entry.key));
      builder.addStore(object, values, build(entry.value));
    }
    return object;
  }

  int visitAwaitExpression(AwaitExpression node) {
    return unsupported(node);
  }

  int visitFunctionExpression(FunctionExpression node) {
    int variable = builder.newVariable(node);
    constraints.addAllocateFunction(
        builder.newFunctionValue(node.function), variable);
    builder.buildFunctionNode(node.function, environment,
        functionValue: variable);
    return variable;
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
    int variable = builder.newVariable(node);
    environment.localVariables[node.variable] = variable;
    constraints.addAllocateFunction(
        builder.newFunctionValue(node.function), variable);
    builder.buildFunctionNode(node.function, environment,
        functionValue: variable);
  }
}

class InitializerBuilder extends InitializerVisitor<Null> {
  final Builder builder;
  final Environment environment;
  ExpressionBuilder expressionBuilder;

  FieldNames get fieldNames => builder.fieldNames;

  InitializerBuilder(this.builder, this.environment) {
    expressionBuilder = new ExpressionBuilder(builder, environment);
  }

  void build(Initializer node) {
    node.accept(this);
  }

  int buildExpression(Expression node) {
    return expressionBuilder.build(node);
  }

  visitInvalidInitializer(InvalidInitializer node) {}

  visitFieldInitializer(FieldInitializer node) {
    builder.addStore(
        environment.thisValue,
        fieldNames.getPropertyField(node.field.name),
        buildExpression(node.value));
  }

  visitSuperInitializer(SuperInitializer node) {
    expressionBuilder.passArgumentsToFunction(
        node.arguments, node.target.function);
  }

  visitRedirectingInitializer(RedirectingInitializer node) {
    expressionBuilder.passArgumentsToFunction(
        node.arguments, node.target.function);
  }
}

class Names {
  static final Name current = new Name('current');
  static final Name iterator = new Name('iterator');
  static final Name then = new Name('then');
}

/// Returns a variable with the possible values of a given type, as provided
/// by external code.
class CovariantExternalTypeVisitor extends DartTypeVisitor<int> {
  final Builder builder;
  final TypeEnvironment environment;

  FieldNames get fieldNames => builder.fieldNames;

  CovariantExternalTypeVisitor(this.builder, this.environment);

  void visitContravariant(DartType type, int input) {
    return new ContravariantExternalTypeVisitor(builder, environment, input)
        .visit(type);
  }

  int visit(DartType type) => type.accept(this);

  int visitInvalidType(InvalidType node) {
    return builder.bottomNode;
  }

  int visitDynamicType(DynamicType node) {
    return builder.dynamicNode;
  }

  int visitVoidType(VoidType node) {
    return builder.nullNode;
  }

  int visitInterfaceType(InterfaceType node) {
    int object = builder.getExternalInstanceVariable(node.classNode);
    for (int i = 0; i < node.typeArguments.length; ++i) {
      int field =
          fieldNames.getTypeParameterField(node.classNode.typeParameters[i]);
      int outputValue = visit(node.typeArguments[i]);
      builder.addStore(object, field, outputValue);
      if (!builder.isAssumedCovariant(node.classNode)) {
        int userValue = builder.getLoad(object, field);
        visitContravariant(node.typeArguments[i], userValue);
      }
    }
    return object;
  }

  int visitTypeParameterType(TypeParameterType node) {
    if (node.parameter.parent is Class) {
      assert(environment.thisValue != null);
      return builder.getLoad(environment.thisValue,
          fieldNames.getTypeParameterField(node.parameter));
    } else {
      return builder.getFunctionTypeParameterVariable(node.parameter);
    }
  }

  int visitFunctionType(FunctionType node) {
    // TODO: Handle arity range.
    int arity = node.positionalParameters.length;
    int function = builder.functionValueNode;
    for (int i = 0; i < node.positionalParameters.length; ++i) {
      int field = fieldNames.getPositionalParameterField(arity, i);
      int argument = builder.getLoad(function, field);
      visitContravariant(node.positionalParameters[i], argument);
    }
    node.namedParameters.forEach((String name, DartType type) {
      int field = fieldNames.getNamedParameterField(arity, name);
      int argument = builder.getLoad(function, field);
      visitContravariant(type, argument);
    });
    int returnValue = visit(node.returnType);
    builder.addStore(function, fieldNames.getReturnField(arity), returnValue);
    return function;
  }

  /// Equivalent to visiting the FunctionType for the given function.
  int buildFunctionNode(FunctionNode node) {
    // TODO: Handle arity range.
    int arity = node.positionalParameters.length;
    int function = builder.functionValueNode;
    for (int i = 0; i < node.positionalParameters.length; ++i) {
      int field = fieldNames.getPositionalParameterField(arity, i);
      int argument = builder.getLoad(function, field);
      visitContravariant(node.positionalParameters[i].type, argument);
    }
    for (int i = 0; i < node.namedParameters.length; ++i) {
      VariableDeclaration variable = node.namedParameters[i];
      int field = fieldNames.getNamedParameterField(arity, variable.name);
      int argument = builder.getLoad(function, field);
      visitContravariant(variable.type, argument);
    }
    int returnValue = visit(node.returnType);
    builder.addStore(function, fieldNames.getReturnField(arity), returnValue);
    return function;
  }
}

/// Generates constraints to model the behavior of a value escaping into
/// external code through a given type.
class ContravariantExternalTypeVisitor extends DartTypeVisitor<Null> {
  final Builder builder;
  final TypeEnvironment environment;
  final int input;

  FieldNames get fieldNames => builder.fieldNames;
  ConstraintSystem get constraints => builder.constraints;

  ContravariantExternalTypeVisitor(this.builder, this.environment, this.input);

  void visit(DartType type) {
    type.accept(this);
  }

  void visitContravariant(DartType type, int input) {
    return new ContravariantExternalTypeVisitor(builder, environment, input)
        .visit(type);
  }

  int visitCovariant(DartType type) {
    return new CovariantExternalTypeVisitor(builder, environment).visit(type);
  }

  visitInvalidType(InvalidType node) {}

  visitDynamicType(DynamicType node) {}

  visitVoidType(VoidType node) {}

  visitInterfaceType(InterfaceType node) {
    int escapePoint = builder.getInterfaceEscapeVariable(node.classNode);
    constraints.addAssign(input, escapePoint);
  }

  visitTypeParameterType(TypeParameterType node) {
    if (node.parameter.parent is Class) {
      assert(environment.thisValue != null);
      builder.addStore(environment.thisValue,
          fieldNames.getTypeParameterField(node.parameter), input);
    } else {
      constraints.addAssign(
          input, builder.getFunctionTypeParameterVariable(node.parameter));
    }
  }

  visitFunctionType(FunctionType node) {
    // TODO: Handle arity range.
    int arity = node.positionalParameters.length;
    for (int i = 0; i < node.positionalParameters.length; ++i) {
      int argument = visitCovariant(node.positionalParameters[i]);
      int field = fieldNames.getPositionalParameterField(arity, i);
      builder.addStore(input, field, argument);
    }
    node.namedParameters.forEach((String name, DartType type) {
      int argument = visitCovariant(type);
      int field = fieldNames.getNamedParameterField(arity, name);
      builder.addStore(input, field, argument);
    });
    int returnLocation =
        builder.getLoad(input, fieldNames.getReturnField(arity));
    visitContravariant(node.returnType, returnLocation);
  }

  /// Equivalent to visiting the FunctionType for the given function.
  void buildFunctionNode(FunctionNode node) {
    // TODO: Handle arity range.
    int arity = node.positionalParameters.length;
    for (int i = 0; i < node.positionalParameters.length; ++i) {
      int argument = visitCovariant(node.positionalParameters[i].type);
      int field = fieldNames.getPositionalParameterField(arity, i);
      builder.addStore(input, field, argument);
    }
    for (int i = 0; i < node.namedParameters.length; ++i) {
      VariableDeclaration variable = node.namedParameters[i];
      int argument = visitCovariant(variable.type);
      int field = fieldNames.getNamedParameterField(arity, variable.name);
      builder.addStore(input, field, argument);
    }
    int returnLocation =
        builder.getLoad(input, fieldNames.getReturnField(arity));
    visitContravariant(node.returnType, returnLocation);
  }
}
