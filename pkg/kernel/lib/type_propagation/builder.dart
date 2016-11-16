// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.type_propagation.builder;

import '../ast.dart';
import '../class_hierarchy.dart';
import '../core_types.dart';
import 'canonicalizer.dart';
import 'constraints.dart';
import 'type_propagation.dart';
import 'visualizer.dart';

/// Maps AST nodes to constraint variables at the level of function boundaries.
///
/// Bindings internally in a function are only preserved by the [Visualizer].
class VariableMapping {
  /// Variable holding all values that may flow into the given field.
  final Map<Field, int> fields = <Field, int>{};

  /// Variable holding all values that may be returned from the given function.
  final Map<FunctionNode, int> returns = <FunctionNode, int>{};

  /// Variable holding all values that may be passed into the given function
  /// parameter (possibly through a default parameter value).
  final Map<VariableDeclaration, int> parameters = <VariableDeclaration, int>{};

  /// Variable holding the function object for the given function.
  final Map<FunctionNode, int> functions = <FunctionNode, int>{};

  static VariableMapping make(int _) => new VariableMapping();
}

/// Maps AST nodes to the lattice employed by the constraint system.
class LatticeMapping {
  /// Lattice point containing the torn-off functions originating from an
  /// instance procedure that overrides the given procedure.
  final Map<Procedure, int> functionsOverridingMethod = <Procedure, int>{};

  /// Lattice point containing all torn-off functions originating from an
  /// instance procedure of the given name,
  ///
  /// This ensures that calls to a method with unknown receiver may still
  /// recover some information about the callee based on the name alone.
  final Map<Name, int> functionsWithName = <Name, int>{};

  /// Maps a class index to a lattice point containing all values that are
  /// subtypes of that class.
  final List<int> subtypesOfClass;

  /// Maps a class index to a lattice point containing all values that are
  /// subclasses of that class.
  final List<int> subclassesOfClass;

  LatticeMapping(int numberOfClasses)
      : subtypesOfClass = new List<int>(numberOfClasses),
        subclassesOfClass = new List<int>(numberOfClasses);
}

/// Generates a [ConstraintSystem] to be solved by [Solver].
class Builder {
  final Program program;
  final ClassHierarchy hierarchy;
  final CoreTypes coreTypes;
  final ConstraintSystem constraints;
  final FieldNames fieldNames;
  final Visualizer visualizer;

  final LatticeMapping lattice;

  /// Bindings for all members. The values inferred for these variables is the
  /// output of the analysis.
  ///
  /// For static members, these are the canonical variables representing the
  /// member.
  ///
  /// For instance members, these are the context-insensitive joins over all
  /// the specialized copies of the instance member.
  final VariableMapping global = new VariableMapping();

  /// Maps a class index to the bindings for instance members specific to that
  /// class as the host class.
  final List<VariableMapping> classMapping;

  final Map<TypeParameter, int> functionTypeParameters = <TypeParameter, int>{};

  /// Variable holding the result of the declaration-site field initializer
  /// for the given field.
  final Map<Field, int> declarationSiteFieldInitializer = <Field, int>{};

  /// Maps a class index to the result of [getInterfaceEscapeVariable].
  final List<int> interfaceEscapeVariables;

  /// Maps a class index to the result of [getExternalInstanceVariable].
  final List<int> externalClassVariables;
  final List<int> externalClassValues;

  final List<int> externalClassWorklist = <int>[];

  final Uint31PairMap<int> _stores = new Uint31PairMap<int>();
  final Uint31PairMap<int> _loads = new Uint31PairMap<int>();
  final List<InferredValue> _baseTypeOfLatticePoint = <InferredValue>[];

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

  /// Lattice point containing all function values.
  int latticePointForAllFunctions;

  Member identicalFunction;

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
        this.constraints = new ConstraintSystem(),
        this.classMapping = new List<VariableMapping>.generate(
            hierarchy.classes.length, VariableMapping.make),
        this.interfaceEscapeVariables = new List<int>(hierarchy.classes.length),
        this.externalClassVariables = new List<int>(hierarchy.classes.length),
        this.externalClassValues = new List<int>(hierarchy.classes.length),
        this.lattice = new LatticeMapping(hierarchy.classes.length) {
    if (visualizer != null) {
      visualizer.builder = this;
      visualizer.constraints = constraints;
      visualizer.fieldNames = fieldNames;
    }

    // Build the subtype lattice points.
    // The order in which lattice points are created determines how ambiguous
    // upper bounds are resolved.  The lattice point with highest index among
    // the potential upper bounds is the result of a join.
    // We create all the subtype lattice point before all the subclass lattice
    // points, to ensure that subclass information takes precedence over
    // subtype information.
    for (int i = 0; i < hierarchy.classes.length; ++i) {
      Class class_ = hierarchy.classes[i];
      List<int> supers = <int>[];
      if (class_.supertype != null) {
        supers.add(getLatticePointForSubtypesOfClass(class_.superclass));
      }
      if (class_.mixedInType != null) {
        supers.add(getLatticePointForSubtypesOfClass(class_.mixedInClass));
      }
      for (Supertype supertype in class_.implementedTypes) {
        supers.add(getLatticePointForSubtypesOfClass(supertype.classNode));
      }
      int subtypePoint = newLatticePoint(supers, class_,
          i == 0 ? BaseClassKind.Subclass : BaseClassKind.Subtype);
      lattice.subtypesOfClass[i] = subtypePoint;
      visualizer?.annotateLatticePoint(subtypePoint, class_, 'subtype');
    }

    // Build the lattice points for subclasses and exact classes.
    for (int i = 0; i < hierarchy.classes.length; ++i) {
      Class class_ = hierarchy.classes[i];
      int subtypePoint = lattice.subtypesOfClass[i];
      assert(subtypePoint != null);
      int subclassPoint;
      if (class_.supertype == null) {
        subclassPoint = subtypePoint;
      } else {
        subclassPoint = newLatticePoint(<int>[
          getLatticePointForSubclassesOf(class_.superclass),
          subtypePoint
        ], class_, BaseClassKind.Subclass);
      }
      lattice.subclassesOfClass[i] = subclassPoint;
      int concretePoint =
          newLatticePoint(<int>[subclassPoint], class_, BaseClassKind.Exact);
      int value = constraints.newValue(concretePoint);
      int variable = constraints.newVariable();
      // We construct the constraint system so the first N variables and values
      // correspond to the N classes in the program.
      assert(variable == i);
      assert(value == -i);
      visualizer?.annotateLatticePoint(subclassPoint, class_, 'subclass');
      visualizer?.annotateLatticePoint(concretePoint, class_, 'concrete');
      visualizer?.annotateVariable(variable, class_);
      visualizer?.annotateValue(value, class_);
      addInput(value, ValueBit.other, variable);
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
    nullNode = newVariable(null, 'Null');

    iteratorField = getPropertyField(Names.iterator);
    currentField = getPropertyField(Names.current);

    latticePointForAllFunctions =
        getLatticePointForSubtypesOfClass(coreTypes.functionClass);

    identicalFunction = coreTypes.getCoreProcedure('dart:core', 'identical');

    // Seed bitmasks for built-in values.
    constraints.addBitmaskInput(ValueBit.null_, nullNode);
    constraints.addBitmaskInput(ValueBit.all, dynamicNode);

    for (Library library in program.libraries) {
      for (Procedure procedure in library.procedures) {
        buildProcedure(null, procedure);
      }
      for (Field field in library.fields) {
        buildStaticField(field);
      }
      for (Class class_ in library.classes) {
        for (Procedure procedure in class_.procedures) {
          if (procedure.isStatic) {
            buildProcedure(null, procedure);
          }
        }
        for (Field field in class_.fields) {
          if (field.isStatic) {
            buildStaticField(field);
          }
        }
        if (!class_.isAbstract) {
          buildInstanceValue(class_);
        }
      }
    }

    // We don't track the values flowing into the identical function, as it
    // causes a lot of spurious escape.  Every class that inherits Object.==
    // would escape its 'this' value into a dynamic context.
    // Mark the identical() parameters as 'dynamic' so the output is sound.
    for (int i = 0; i < 2; ++i) {
      constraints.addAssign(
          dynamicNode,
          getSharedParameterVariable(
              identicalFunction.function.positionalParameters[i]));
    }

    // Build constraints mocking the external interfaces.
    while (externalClassWorklist.isNotEmpty) {
      int classIndex = externalClassWorklist.removeLast();
      _buildExternalClassValue(classIndex);
    }
  }

  int newLatticePoint(
      List<int> parentLatticePoints, Class baseClass, BaseClassKind kind) {
    _baseTypeOfLatticePoint.add(new InferredValue(baseClass, kind, 0));
    return constraints.newLatticePoint(parentLatticePoints);
  }

  void addInput(int value, int bitmask, int destination) {
    constraints.addAllocation(value, destination);
    constraints.addBitmaskInput(bitmask, destination);
  }

  /// Returns an [InferredValue] with the base type relation for the given
  /// lattice point but whose bitmask is 0.  The bitmask must be filled in
  /// before this value is exposed to analysis clients.
  InferredValue getBaseTypeOfLatticePoint(int latticePoint) {
    return _baseTypeOfLatticePoint[latticePoint];
  }

  /// Returns the lattice point containing all subtypes of the given class.
  int getLatticePointForSubtypesOfClass(Class classNode) {
    int index = hierarchy.getClassIndex(classNode);
    return lattice.subtypesOfClass[index];
  }

  /// Returns the lattice point containing all subclasses of the given class.
  int getLatticePointForSubclassesOf(Class classNode) {
    int index = hierarchy.getClassIndex(classNode);
    return lattice.subclassesOfClass[index];
  }

  /// Returns the lattice point containing all function implementing the given
  /// instance method.
  int getLatticePointForFunctionsOverridingMethod(Procedure node) {
    assert(!node.isStatic);
    if (node.isAccessor) return latticePointForAllFunctions;
    if (node.enclosingClass.supertype == null)
      return latticePointForAllFunctions;
    return lattice.functionsOverridingMethod[node] ??=
        _makeLatticePointForFunctionsOverridingMethod(node);
  }

  int _makeLatticePointForFunctionsOverridingMethod(Procedure node) {
    Class host = node.enclosingClass;
    Member superMember = host.supertype == null
        ? null
        : hierarchy.getInterfaceMember(host.superclass, node.name);
    int super_;
    if (superMember is Procedure && !superMember.isAccessor) {
      super_ = getLatticePointForFunctionsOverridingMethod(superMember);
    } else {
      super_ = getLatticePointForFunctionsWithName(node.name);
    }
    int point = newLatticePoint(
        <int>[super_], coreTypes.functionClass, BaseClassKind.Subtype);
    visualizer?.annotateLatticePoint(point, node, 'overriders');
    return point;
  }

  int newVariable([TreeNode node, String info]) {
    int variable = constraints.newVariable();
    visualizer?.annotateVariable(variable, node, info);
    return variable;
  }

  VariableMapping getClassMapping(Class host) {
    if (host == null) return global;
    int index = hierarchy.getClassIndex(host);
    return classMapping[index];
  }

  /// Returns a variable that should contain all values that may be contained
  /// in any copy the given field (hence "shared" between the copies).
  int getSharedFieldVariable(Field field) {
    return global.fields[field] ??= newVariable(field);
  }

  /// Returns a variable representing the given field on the given class.
  ///
  /// If the field is static, [host] should be `null`.
  int getFieldVariable(Class host, Field field) {
    if (host == null) return getSharedFieldVariable(field);
    VariableMapping mapping = getClassMapping(host);
    return mapping.fields[field] ??= _makeFieldVariable(host, field);
  }

  int _makeFieldVariable(Class host, Field field) {
    // Create a variable specific to this host class, and add an assignment
    // to the global sink for this field.
    assert(host != null);
    int variable = newVariable(field);
    int sink = getSharedFieldVariable(field);
    constraints.addSink(variable, sink);
    visualizer?.annotateSink(variable, sink, field);
    return variable;
  }

  /// Variable containing all values that may be passed into the given parameter
  /// of any instantiation of the given function (hence "shared" between them).
  int getSharedParameterVariable(VariableDeclaration node) {
    return global.parameters[node] ??= newVariable(node, 'shared parameter');
  }

  int getParameterVariable(Class host, VariableDeclaration node) {
    if (host == null) return getSharedParameterVariable(node);
    VariableMapping mapping = getClassMapping(host);
    return mapping.parameters[node] ??= _makeParameterVariable(host, node);
  }

  int _makeParameterVariable(Class host, VariableDeclaration node) {
    assert(host != null);
    int variable = newVariable(node, 'parameter');
    int sink = getSharedParameterVariable(node);
    constraints.addSink(variable, sink);
    visualizer?.annotateSink(variable, sink, node);
    return variable;
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

  /// Variable containing all values that may be returned from any instantiation
  /// of the given function (hence "shared" between them).
  int getSharedReturnVariable(FunctionNode node) {
    return global.returns[node] ??= newVariable(node, 'return');
  }

  int getReturnVariable(Class host, Procedure node) {
    if (host == null) return getSharedReturnVariable(node.function);
    VariableMapping mapping = getClassMapping(host);
    return mapping.returns[node.function] ??= _makeReturnVariable(host, node);
  }

  int _makeReturnVariable(Class host, Procedure node) {
    assert(host != null);
    int variable = newVariable(node, 'return');
    int sink = getSharedReturnVariable(node.function);
    constraints.addSink(variable, sink);
    visualizer?.annotateSink(variable, sink, node);
    return variable;
  }

  /// Returns a variable containing all the function objects for all
  /// instantiations of the given function.
  int getSharedTearOffVariable(FunctionNode node) {
    return global.functions[node] ??= newVariable(node);
  }

  /// Returns a variable containing the torn-off copy of the given function
  /// occurring in static context.
  int getStaticTearOffVariable(FunctionNode node) {
    return global.functions[node] ??= _makeStaticTearOffVariable(node);
  }

  int _makeStaticTearOffVariable(FunctionNode node) {
    return newFunction(node);
  }

  /// Returns a variable containing the torn-off copy of the given procedure.
  int getTearOffVariable(Class host, Procedure node) {
    if (host == null) return getStaticTearOffVariable(node.function);
    VariableMapping mapping = getClassMapping(host);
    return mapping.functions[node.function] ??=
        _makeTearOffVariable(host, node);
  }

  int _makeTearOffVariable(Class host, Procedure node) {
    int variable = newFunction(node.function, node);
    int sink = getSharedTearOffVariable(node.function);
    constraints.addSink(variable, sink);
    visualizer?.annotateSink(variable, sink, node);
    return variable;
  }

  /// Returns the variable holding the result of a 'get' selector dispatched
  /// to the given member, or `null` if the member cannot respond to a 'get'
  /// selector.
  int getMemberGetter(Class host, Member member) {
    if (member is Field) {
      return getFieldVariable(host, member);
    } else if (member is Procedure) {
      if (member.isGetter) {
        return getReturnVariable(host, member);
      } else if (!member.isAccessor) {
        return getTearOffVariable(host, member);
      }
    }
    return null;
  }

  /// Returns the variable holding the argument to a 'set' selector dispatched
  /// to the given member, or `null` if the member cannot respond to a 'set'
  /// selector.
  int getMemberSetter(Class host, Member member) {
    if (member is Field && !member.isFinal) {
      return getFieldVariable(host, member);
    } else if (member is Procedure && member.isSetter) {
      return getParameterVariable(
          host, member.function.positionalParameters[0]);
    }
    return null;
  }

  /// Returns a lattice point containing all instance methods with the given
  /// name.
  int getLatticePointForFunctionsWithName(Name name) {
    if (name == null) return latticePointForAllFunctions;
    return lattice.functionsWithName[name] ??=
        _makeLatticePointForFunctionsWithName(name);
  }

  int _makeLatticePointForFunctionsWithName(Name name) {
    int point = newLatticePoint(<int>[latticePointForAllFunctions],
        coreTypes.functionClass, BaseClassKind.Subtype);
    visualizer?.annotateLatticePoint(point, null, 'Methods of name $name');
    return point;
  }

  /// Returns a variable holding a new function value annotated with given AST
  /// node.
  ///
  /// If the function is the body of an instance procedure, it should be passed
  /// as [member] to ensure an effective lattice is built for it.
  /// Otherwise, [member] should be omitted.
  int newFunction(FunctionNode node, [Procedure member]) {
    assert(node != null);
    int functionVariable = newVariable(node);
    int baseLatticePoint = member == null
        ? latticePointForAllFunctions
        : getLatticePointForFunctionsOverridingMethod(member);
    int latticePoint = newLatticePoint(<int>[baseLatticePoint],
        coreTypes.functionClass, BaseClassKind.Subtype);
    visualizer?.annotateLatticePoint(latticePoint, member, 'function');
    int minArity = node.requiredParameterCount;
    int maxArity = node.positionalParameters.length;
    int functionValue = constraints.newValue(latticePoint);
    for (int i = 0; i < node.positionalParameters.length; ++i) {
      int variable = newVariable();
      for (int arity = minArity; arity <= maxArity; ++arity) {
        int field = fieldNames.getPositionalParameterField(arity, i);
        constraints.setStoreLocation(functionValue, field, variable);
        constraints.setLoadLocation(functionValue, field, variable);
      }
    }
    for (int i = 0; i < node.namedParameters.length; ++i) {
      int variable = newVariable();
      for (int arity = minArity; arity <= maxArity; ++arity) {
        int field = fieldNames.getNamedParameterField(
            arity, node.namedParameters[i].name);
        constraints.setStoreLocation(functionValue, field, variable);
        constraints.setLoadLocation(functionValue, field, variable);
      }
    }
    int returnVariable = newVariable();
    for (int arity = minArity; arity <= maxArity; ++arity) {
      int returnField = fieldNames.getReturnField(arity);
      constraints.setStoreLocation(functionValue, returnField, returnVariable);
      constraints.setLoadLocation(functionValue, returnField, returnVariable);
    }
    visualizer?.annotateFunction(functionValue, node);
    visualizer?.annotateValue(functionValue, member, 'function');
    addInput(functionValue, ValueBit.other, functionVariable);
    constraints.setLoadLocation(
        functionValue, fieldNames.callHandlerField, functionVariable);
    constraints.setLoadLocation(functionValue,
        fieldNames.getPropertyField(Names.call_), functionVariable);
    return functionVariable;
  }

  /// Returns a variable containing the concrete instances of the given class.
  int getInstanceVariable(Class node) {
    assert(!node.isAbstract);
    return hierarchy.getClassIndex(node);
  }

  /// Returns the value representing the concrete instances of the given class.
  int getInstanceValue(Class node) {
    assert(!node.isAbstract);
    // Values are negated to help distinguish them from variables and
    // lattice points.
    return -hierarchy.getClassIndex(node);
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
    return externalClassVariables[classIndex] ??=
        _makeExternalInstanceVariable(node, classIndex);
  }

  int getValueBitForExternalClass(Class node) {
    if (node == coreTypes.intClass) {
      return ValueBit.integer;
    } else if (node == coreTypes.doubleClass) {
      return ValueBit.double_;
    } else if (node == coreTypes.stringClass) {
      return ValueBit.string;
    } else {
      return ValueBit.other;
    }
  }

  int _makeExternalInstanceVariable(Class node, int classIndex) {
    if (node == coreTypes.numClass) {
      // Don't build an interface based on the "num" class, instead treat it
      // as the union of "int" and "double".
      int variable = newVariable(node);
      constraints.addAssign(intNode, variable);
      constraints.addAssign(doubleNode, variable);
      return variable;
    }
    int baseLatticePoint = getLatticePointForSubtypesOfClass(node);
    // TODO(asgerf): Use more fine-grained handling of externals, based on
    //   metadata or on a specification read from a separate file (issue #22).
    int latticePoint =
        newLatticePoint(<int>[baseLatticePoint], node, BaseClassKind.Subtype);
    visualizer?.annotateLatticePoint(latticePoint, node, 'external');
    int value = constraints.newValue(latticePoint);
    int variable = newVariable(node, 'external');
    addInput(value, getValueBitForExternalClass(node), variable);
    externalClassValues[classIndex] = value;
    externalClassWorklist.add(classIndex);
    return variable;
  }

  void _buildExternalClassValue(int index) {
    Class node = hierarchy.classes[index];
    int variable = externalClassVariables[index];
    int externalObject = externalClassValues[index];
    Name previousName = null;
    for (Member member in hierarchy.getInterfaceMembers(node, setters: false)) {
      // Do not generate an interface member for a given name more than once.
      // This can happen if a class inherits two methods through different
      // inheritance paths.
      if (member.name == previousName) continue;
      previousName = member.name;
      _buildExternalInterfaceMember(node, member, externalObject, variable,
          isSetter: false);
    }
    previousName = null;
    for (Member member in hierarchy.getInterfaceMembers(node, setters: true)) {
      if (member.name == previousName) continue;
      previousName = member.name;
      _buildExternalInterfaceMember(node, member, externalObject, variable,
          isSetter: true);
    }
    for (TypeParameter parameter in node.typeParameters) {
      int field = fieldNames.getTypeParameterField(parameter);
      int location = newVariable(parameter);
      constraints.setStoreLocation(externalObject, field, location);
      constraints.setLoadLocation(externalObject, field, location);
    }
  }

  void _buildExternalInterfaceMember(
      Class host, Member member, int object, int variable,
      {bool isSetter}) {
    // TODO(asgerf): Handle nullability of return values.
    TypeEnvironment environment =
        new TypeEnvironment(this, host, member, thisVariable: variable);
    int propertyField = fieldNames.getPropertyField(member.name);
    if (member is Field) {
      int fieldType = buildCovariantType(member.type, environment);
      if (isSetter) {
        constraints.setStoreLocation(object, propertyField, fieldType);
      } else {
        constraints.setLoadLocation(object, propertyField, fieldType);
      }
    } else {
      Procedure procedure = member;
      FunctionNode function = procedure.function;
      if (procedure.isGetter) {
        int returned = buildCovariantType(function.returnType, environment);
        constraints.setLoadLocation(object, propertyField, returned);
      } else if (procedure.isSetter) {
        int escaping = environment.getLoad(variable, propertyField);
        buildContravariantType(
            function.positionalParameters[0].type, environment, escaping);
      } else {
        int externalMember = buildCovariantFunctionType(function, environment);
        constraints.setLoadLocation(object, propertyField, externalMember);
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
      _buildEscapingInterfaceMember(node, member, escapingObject);
    }
    for (Member member in hierarchy.getInterfaceMembers(node, setters: true)) {
      _buildEscapingInterfaceMember(node, member, escapingObject);
    }
    return escapingObject;
  }

  /// Models the behavior of external code invoking [member] on
  /// [escapingObject].
  void _buildEscapingInterfaceMember(
      Class host, Member member, int escapingObject) {
    TypeEnvironment environment =
        new TypeEnvironment(this, host, member, thisVariable: escapingObject);
    int propertyField = fieldNames.getPropertyField(member.name);
    if (member is Field) {
      int escapingMember = environment.getLoad(escapingObject, propertyField);
      buildContravariantType(member.type, environment, escapingMember);
    } else {
      Procedure procedure = member;
      FunctionNode function = procedure.function;
      if (procedure.isGetter) {
        int escapingMember = environment.getLoad(escapingObject, propertyField);
        buildContravariantType(
            function.returnType, environment, escapingMember);
      } else if (procedure.isSetter) {
        VariableDeclaration parameter = function.positionalParameters[0];
        int argument = buildCovariantType(parameter.type, environment);
        environment.addStore(escapingObject, propertyField, argument);
      } else {
        int escapingMember = environment.getLoad(escapingObject, propertyField);
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

  void buildInstanceValue(Class host) {
    int value = getInstanceValue(host);
    for (Member target in hierarchy.getDispatchTargets(host, setters: false)) {
      var getter = getMemberGetter(host, target);
      constraints.setLoadLocation(value, getPropertyField(target.name), getter);
    }
    for (Member target in hierarchy.getDispatchTargets(host, setters: true)) {
      constraints.setStoreLocation(
          value, getPropertyField(target.name), getMemberSetter(host, target));
    }
    for (Class node = host; node != null; node = node.superclass) {
      for (Procedure procedure in node.mixin.procedures) {
        if (!procedure.isStatic) {
          buildProcedure(host, procedure);
        }
      }
      for (Constructor constructor in node.constructors) {
        buildConstructor(host, constructor);
      }
    }
    // If the object is callable as a function, set up its call handler.
    Member callHandler = hierarchy.getDispatchTarget(host, Names.call_);
    if (callHandler != null) {
      if (callHandler is Procedure && !callHandler.isAccessor) {
        constraints.setLoadLocation(value, fieldNames.callHandlerField,
            getTearOffVariable(host, callHandler));
      } else {
        // Generate `this.[call] = this.call.[call]` where [call] is the
        // call handler field, corresponding to repeatedly reading "call".
        var environment = new TypeEnvironment(this, host, callHandler);
        int getter = getMemberGetter(host, callHandler);
        constraints.setLoadLocation(value, fieldNames.callHandlerField,
            environment.getLoad(getter, fieldNames.callHandlerField));
      }
    }
  }

  void buildStaticField(Field field) {
    var environment = new Environment(this, null, field);
    int initializer = field.initializer == null
        ? nullNode
        : new StatementBuilder(this, environment)
            .buildExpression(field.initializer);
    environment.addAssign(initializer, getSharedFieldVariable(field));
  }

  void buildProcedure(Class hostClass, Procedure node) {
    if (node.isAbstract) return;
    int host = hostClass == null ? null : getInstanceVariable(hostClass);
    int function = getTearOffVariable(hostClass, node);
    int returnVariable = getReturnVariable(hostClass, node);
    var environment = new Environment(this, hostClass, node,
        returnVariable: returnVariable, thisVariable: host);
    buildFunctionNode(node.function, environment,
        addTypeBasedSummary: node.isExternal, function: function);
  }

  int getDeclarationSiteFieldInitializer(Field field) {
    if (field.initializer == null) return nullNode;
    return declarationSiteFieldInitializer[field] ??=
        _makeDeclarationSiteFieldInitializer(field);
  }

  int _makeDeclarationSiteFieldInitializer(Field field) {
    final initializerEnvironment = new Environment(this, null, field);
    return new StatementBuilder(this, initializerEnvironment)
        .buildExpression(field.initializer);
  }

  void buildConstructor(Class hostClass, Constructor node) {
    int host = getInstanceVariable(hostClass);
    var environment =
        new Environment(this, hostClass, node, thisVariable: host);
    buildFunctionNode(node.function, environment);
    InitializerBuilder builder = new InitializerBuilder(this, environment);
    Set<Field> initializedFields = new Set<Field>();
    for (Initializer initializer in node.initializers) {
      builder.build(initializer);
      if (initializer is FieldInitializer) {
        initializedFields.add(initializer.field);
      }
    }
    for (Field field in node.enclosingClass.mixin.fields) {
      if (field.isInstanceMember) {
        // Note: ensure the initializer is built even if it is not used.
        int initializer = getDeclarationSiteFieldInitializer(field);
        if (!initializedFields.contains(field)) {
          int variable = getFieldVariable(hostClass, field);
          environment.addAssign(initializer, variable);
        }
      }
    }
  }

  /// Builds constraints to model the behavior of the given function.
  ///
  /// If the function is external, [addTypeBasedSummary] should be `true`;
  /// its parameter and return type are then used to model its behavior instead
  /// of the body.
  ///
  /// [function] should be a variable holding the function object itself, if
  /// such an object exists (which is always the case except for constructors,
  /// which currently do have function values).
  void buildFunctionNode(FunctionNode node, Environment environment,
      {int function, bool addTypeBasedSummary: false}) {
    var expressionBuilder =
        new StatementBuilder(this, environment).expressionBuilder;
    int minArity = node.requiredParameterCount;
    int maxArity = node.positionalParameters.length;
    for (int i = 0; i < node.positionalParameters.length; ++i) {
      var parameter = node.positionalParameters[i];
      int variable = getParameterVariable(environment.host, parameter);
      environment.localVariables[parameter] = variable;
      if (function != null) {
        for (int arity = minArity; arity <= maxArity; ++arity) {
          if (i < arity) {
            environment.addLoad(
                function, getPositionalParameterField(arity, i), variable);
          }
        }
      }
      if (i >= node.requiredParameterCount) {
        int parameterDefault = parameter.initializer == null
            ? nullNode
            : expressionBuilder.build(parameter.initializer);
        environment.addAssign(parameterDefault, variable);
      }
      if (addTypeBasedSummary) {
        buildContravariantType(parameter.type, environment, variable);
      }
    }
    for (int i = 0; i < node.namedParameters.length; ++i) {
      var parameter = node.namedParameters[i];
      int variable = getParameterVariable(environment.host, parameter);
      environment.localVariables[parameter] = variable;
      if (function != null) {
        for (int arity = minArity; arity <= maxArity; ++arity) {
          environment.addLoad(function,
              getNamedParameterField(arity, parameter.name), variable);
        }
      }
      int parameterDefault = parameter.initializer == null
          ? nullNode
          : expressionBuilder.build(parameter.initializer);
      environment.addAssign(parameterDefault, variable);
      if (addTypeBasedSummary) {
        buildContravariantType(parameter.type, environment, variable);
      }
    }
    if (environment.returnVariable == null) {
      environment.returnVariable = newVariable(node, 'return');
      environment.addSink(
          environment.returnVariable, getSharedReturnVariable(node));
    } else {
      visualizer?.annotateVariable(environment.returnVariable, node, 'return');
    }
    if (function != null) {
      for (int arity = minArity; arity <= maxArity; ++arity) {
        environment.addStore(
            function, getReturnField(arity), environment.returnVariable);
      }
    }
    if (addTypeBasedSummary) {
      int returnFromType = buildCovariantType(node.returnType, environment);
      environment.addAssign(returnFromType, environment.returnVariable);
    } else if (node.body != null) {
      Completion completes =
          new StatementBuilder(this, environment).build(node.body);
      if (completes == Completion.Maybe) {
        // Null is returned when control falls over the end.
        environment.addAssign(nullNode, environment.returnVariable);
      }
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
  static const int _TagCallHandler = 6;

  /// Field mapping an object to the function value that should be invoked when
  /// the object is called as a function.
  ///
  /// This is the equivalent of repeatedly reading the "call" property of an
  /// object until a function value is found.
  int callHandlerField;

  FieldNames() {
    callHandlerField = _table.get1(_TagCallHandler);
  }

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
      case _TagCallHandler:
        return 'call-handler()';
      default:
        return '!error';
    }
  }
}

class TypeEnvironment {
  final Builder builder;
  final Class host;
  final Member member;
  int thisVariable;

  ConstraintSystem get constraints => builder.constraints;
  Visualizer get visualizer => builder.visualizer;

  TypeEnvironment(this.builder, this.host, this.member, {this.thisVariable});

  void addAssign(int source, int destination) {
    constraints.addAssign(source, destination);
    visualizer?.annotateAssign(source, destination, member);
  }

  int getJoin(int first, int second) {
    // TODO(asgerf): Avoid redundant joins in common cases.
    int joinPoint = constraints.newVariable();
    addAssign(first, joinPoint);
    addAssign(second, joinPoint);
    return joinPoint;
  }

  int getLoad(int object, int field) {
    int variable = builder._loads.lookup(object, field);
    if (variable != null) return variable;
    variable = constraints.newVariable();
    constraints.addLoad(object, field, variable);
    visualizer?.annotateLoad(object, field, variable, member);
    builder._loads.put(variable);
    return variable;
  }

  void addLoad(int object, int field, int destination) {
    constraints.addLoad(object, field, destination);
    visualizer?.annotateLoad(object, field, destination, member);
  }

  int getStore(int object, int field) {
    int variable = builder._stores.lookup(object, field);
    if (variable != null) return variable;
    variable = constraints.newVariable();
    constraints.addStore(object, field, variable);
    visualizer?.annotateStore(object, field, variable, member);
    builder._stores.put(variable);
    return variable;
  }

  void addStore(int object, int field, int source) {
    addAssign(source, getStore(object, field));
  }

  void addSink(int source, int sink) {
    constraints.addSink(source, sink);
    visualizer?.annotateSink(source, sink, member);
  }
}

class Environment extends TypeEnvironment {
  final Map<VariableDeclaration, int> localVariables;
  int returnVariable;

  Environment(Builder builder, Class host, Member member,
      {int thisVariable, this.returnVariable})
      : localVariables = <VariableDeclaration, int>{},
        super(builder, host, member, thisVariable: thisVariable);

  Environment.inner(Environment outer, {this.returnVariable})
      : localVariables = outer.localVariables,
        super(outer.builder, outer.host, outer.member,
            thisVariable: outer.thisVariable);

  int getVariable(VariableDeclaration variable) {
    return localVariables[variable] ??= builder.newVariable(variable);
  }
}

class ExpressionBuilder extends ExpressionVisitor<int> {
  final Builder builder;
  final Environment environment;
  final StatementBuilder statementBuilder;

  ConstraintSystem get constraints => builder.constraints;
  Visualizer get visualizer => builder.visualizer;
  FieldNames get fieldNames => builder.fieldNames;

  ExpressionBuilder(this.builder, this.statementBuilder, this.environment);

  int build(Expression node) {
    int variable = node.accept(this);
    visualizer?.annotateVariable(variable, node);
    return variable;
  }

  int unsupported(Expression node) {
    return builder.unsupported(node);
  }

  defaultExpression(Expression node) {
    return unsupported(node);
  }

  int visitInvalidExpression(InvalidExpression node) {
    return builder.bottomNode;
  }

  int visitVariableGet(VariableGet node) {
    return environment.getVariable(node.variable);
  }

  int visitVariableSet(VariableSet node) {
    int rightHandSide = build(node.value);
    int variable = environment.getVariable(node.variable);
    environment.addAssign(rightHandSide, variable);
    return rightHandSide;
  }

  int visitPropertyGet(PropertyGet node) {
    if (node.receiver is ThisExpression) {
      Class host = environment.host;
      Member target = builder.hierarchy.getDispatchTarget(host, node.name);
      int source = builder.getMemberGetter(host, target);
      return source == null ? builder.bottomNode : source;
    }
    int object = build(node.receiver);
    int field = fieldNames.getPropertyField(node.name);
    return environment.getLoad(object, field);
  }

  int visitPropertySet(PropertySet node) {
    int object = build(node.receiver);
    int rightHandSide = build(node.value);
    if (node.receiver is ThisExpression) {
      Class host = environment.host;
      Member target =
          builder.hierarchy.getDispatchTarget(host, node.name, setter: true);
      int destination = builder.getMemberSetter(host, target);
      if (destination != null) {
        environment.addAssign(rightHandSide, destination);
      }
      return rightHandSide;
    }
    int field = fieldNames.getPropertyField(node.name);
    environment.addStore(object, field, rightHandSide);
    return rightHandSide;
  }

  int visitDirectPropertyGet(DirectPropertyGet node) {
    return builder.getMemberGetter(environment.host, node.target);
  }

  int visitDirectPropertySet(DirectPropertySet node) {
    int rightHandSide = build(node.value);
    int destination = builder.getMemberSetter(environment.host, node.target);
    if (destination != null) {
      environment.addAssign(rightHandSide, destination);
    }
    return rightHandSide;
  }

  int visitSuperPropertyGet(SuperPropertyGet node) {
    return unsupported(node);
  }

  int visitSuperPropertySet(SuperPropertySet node) {
    build(node.value);
    return unsupported(node);
  }

  int visitStaticGet(StaticGet node) {
    return builder.getMemberGetter(null, node.target);
  }

  int visitStaticSet(StaticSet node) {
    int rightHandSide = build(node.value);
    int destination = builder.getMemberSetter(null, node.target);
    assert(destination != null); // Static accessors must be valid.
    environment.addAssign(rightHandSide, destination);
    return rightHandSide;
  }

  int visitMethodInvocation(MethodInvocation node) {
    // Resolve calls on 'this' directly.
    if (node.receiver is ThisExpression) {
      Class host = environment.host;
      Member target = builder.hierarchy.getDispatchTarget(host, node.name);
      if (target is Procedure && !target.isAccessor) {
        FunctionNode function = target.function;
        passArgumentsToFunction(node.arguments, host, function);
        return builder.getReturnVariable(host, target);
      }
    }
    // Dispatch call dynamically.
    int receiver = build(node.receiver);
    int methodProperty = builder.getPropertyField(node.name);
    int function = node.name.name == 'call'
        ? receiver
        : environment.getLoad(receiver, methodProperty);
    // We have to dispatch through any number of 'call' getters to get to
    // the actual function.  The 'call handler' field unfolds all the 'call'
    // getters and refers directly to the actual function (if it exists).
    // TODO(asgerf): When we have strong mode types, skip the 'call handler'
    //     load if the static type system resolves the target to a method.
    //     It is only needed for getters, fields, and untyped calls.
    int handler = environment.getLoad(function, fieldNames.callHandlerField);
    visualizer?.annotateVariable(function, node, 'function');
    visualizer?.annotateVariable(handler, node, 'call handler');
    int arity = node.arguments.positional.length;
    for (int i = 0; i < node.arguments.positional.length; ++i) {
      int field = builder.getPositionalParameterField(arity, i);
      int argument = build(node.arguments.positional[i]);
      environment.addStore(handler, field, argument);
    }
    for (int i = 0; i < node.arguments.named.length; ++i) {
      NamedExpression namedNode = node.arguments.named[i];
      int field = builder.getNamedParameterField(arity, namedNode.name);
      int argument = build(namedNode.value);
      environment.addStore(handler, field, argument);
    }
    return environment.getLoad(handler, builder.getReturnField(arity));
  }

  void passArgumentsToFunction(
      Arguments node, Class host, FunctionNode function) {
    // TODO(asgerf): Check that arity matches (although mismatches are rare).
    for (int i = 0; i < node.positional.length; ++i) {
      int argument = build(node.positional[i]);
      if (i < function.positionalParameters.length) {
        int parameter = builder.getParameterVariable(
            host, function.positionalParameters[i]);
        environment.addAssign(argument, parameter);
      }
    }
    for (int i = 0; i < node.named.length; ++i) {
      NamedExpression namedNode = node.named[i];
      int argument = build(namedNode.value);
      // TODO(asgerf): Avoid the slow lookup for named parameters.
      for (int j = 0; j < function.namedParameters.length; ++j) {
        var namedParameter = function.namedParameters[j];
        if (namedParameter.name == namedNode.name) {
          int parameter = builder.getParameterVariable(host, namedParameter);
          environment.addAssign(argument, parameter);
          break;
        }
      }
    }
  }

  int visitDirectMethodInvocation(DirectMethodInvocation node) {
    // TODO(asgerf): Support cases where the receiver is not 'this'.
    passArgumentsToFunction(
        node.arguments, environment.host, node.target.function);
    return builder.getReturnVariable(environment.host, node.target);
  }

  int visitSuperMethodInvocation(SuperMethodInvocation node) {
    return unsupported(node);
  }

  void passArgumentsNowhere(Arguments node) {
    for (int i = 0; i < node.positional.length; ++i) {
      build(node.positional[i]);
    }
    for (int i = 0; i < node.named.length; ++i) {
      build(node.named[i].value);
    }
  }

  int visitStaticInvocation(StaticInvocation node) {
    if (node.target == builder.identicalFunction) {
      // Ignore calls to identical() as they cause a lot of spurious escape.
      passArgumentsNowhere(node.arguments);
      return builder.boolNode;
    }
    passArgumentsToFunction(node.arguments, null, node.target.function);
    return builder.getReturnVariable(null, node.target);
  }

  int visitConstructorInvocation(ConstructorInvocation node) {
    Class host = node.target.enclosingClass;
    passArgumentsToFunction(node.arguments, host, node.target.function);
    return builder.getInstanceVariable(host);
  }

  int visitNot(Not node) {
    build(node.operand);
    return builder.boolNode;
  }

  int visitLogicalExpression(LogicalExpression node) {
    build(node.left);
    build(node.right);
    return builder.boolNode;
  }

  int visitConditionalExpression(ConditionalExpression node) {
    build(node.condition);
    int then = build(node.then);
    int otherwise = build(node.otherwise);
    return environment.getJoin(then, otherwise);
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
    return environment.thisVariable;
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
      int content = build(node.expressions[i]);
      environment.addStore(object, field, content);
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
      environment.addStore(object, keys, build(entry.key));
      environment.addStore(object, values, build(entry.value));
    }
    return object;
  }

  int visitAwaitExpression(AwaitExpression node) {
    return unsupported(node);
  }

  int visitFunctionExpression(FunctionExpression node) {
    return buildInnerFunction(node.function);
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

  int buildInnerFunction(FunctionNode node, {VariableDeclaration self}) {
    int variable = builder.newFunction(node);
    if (self != null) {
      assert(!environment.localVariables.containsKey(self));
      environment.localVariables[self] = variable;
    }
    Environment inner = new Environment.inner(environment);
    builder.buildFunctionNode(node, inner, function: variable);
    return variable;
  }
}

/// Indicates whether a statement can complete normally.
enum Completion {
  /// The statement might complete normally.
  Maybe,

  /// The statement never completes normally, because it throws, returns,
  /// breaks, loops forever, etc.
  Never,
}

Completion neverCompleteIf(bool condition) {
  return condition ? Completion.Never : Completion.Maybe;
}

Completion completeIfBoth(Completion first, Completion second) {
  return first == Completion.Maybe && second == Completion.Maybe
      ? Completion.Maybe
      : Completion.Never;
}

Completion completeIfEither(Completion first, Completion second) {
  return first == Completion.Maybe || second == Completion.Maybe
      ? Completion.Maybe
      : Completion.Never;
}

bool _isTrueConstant(Expression node) {
  return node is BoolLiteral && node.value == true;
}

bool _isThrowing(Expression node) {
  return node is Throw || node is Rethrow;
}

/// Translates a statement to constraints.
///
/// The visit methods return a [Completion] indicating if the statement can
/// complete normally.  This is used to check if null can be returned due to
/// control falling over the end of the method.
class StatementBuilder extends StatementVisitor<Completion> {
  final Builder builder;
  final Environment environment;
  ExpressionBuilder expressionBuilder;

  ConstraintSystem get constraints => builder.constraints;
  Visualizer get visualizer => builder.visualizer;
  FieldNames get names => builder.fieldNames;

  StatementBuilder(this.builder, this.environment) {
    expressionBuilder = new ExpressionBuilder(builder, this, environment);
  }

  Completion build(Statement node) => node.accept(this);

  Completion buildOptional(Statement node) {
    return node != null ? node.accept(this) : Completion.Maybe;
  }

  int buildExpression(Expression node) {
    return expressionBuilder.build(node);
  }

  void unsupported(Statement node) {
    builder.unsupported(node);
  }

  Completion visitInvalidStatement(InvalidStatement node) => Completion.Never;

  visitExpressionStatement(ExpressionStatement node) {
    buildExpression(node.expression);
    return neverCompleteIf(_isThrowing(node.expression));
  }

  visitBlock(Block node) {
    for (int i = 0; i < node.statements.length; ++i) {
      if (build(node.statements[i]) == Completion.Never) {
        return Completion.Never;
      }
    }
    return Completion.Maybe;
  }

  visitEmptyStatement(EmptyStatement node) => Completion.Maybe;

  visitAssertStatement(AssertStatement node) {
    unsupported(node);
    return Completion.Maybe;
  }

  visitLabeledStatement(LabeledStatement node) {
    build(node.body);
    // We don't track reachability of breaks in the body, so just assume we
    // might hit a break.
    return Completion.Maybe;
  }

  visitBreakStatement(BreakStatement node) => Completion.Never;

  visitWhileStatement(WhileStatement node) {
    buildExpression(node.condition);
    build(node.body);
    return neverCompleteIf(_isTrueConstant(node.condition));
  }

  visitDoStatement(DoStatement node) {
    build(node.body);
    buildExpression(node.condition);
    return neverCompleteIf(_isTrueConstant(node.condition));
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
    return neverCompleteIf(_isTrueConstant(node.condition));
  }

  visitForInStatement(ForInStatement node) {
    int iterable = buildExpression(node.iterable);
    int iterator = environment.getLoad(iterable, builder.iteratorField);
    int current = environment.getLoad(iterator, builder.currentField);
    int variable = environment.getVariable(node.variable);
    environment.addAssign(current, variable);
    build(node.body);
    return Completion.Maybe;
  }

  visitSwitchStatement(SwitchStatement node) {
    buildExpression(node.expression);
    Completion lastCanComplete = Completion.Maybe;
    for (int i = 0; i < node.cases.length; ++i) {
      // There is no need to visit the expression since constants cannot
      // have side effects.
      // Note that only the last case can actually fall out of the switch,
      // as the others will throw an exception if they fall through.
      // Also note that breaks from the switch have been desugared to breaks
      // to a [LabeledStatement].
      lastCanComplete = build(node.cases[i].body);
    }
    return lastCanComplete;
  }

  visitContinueSwitchStatement(ContinueSwitchStatement node) {
    return Completion.Never;
  }

  visitIfStatement(IfStatement node) {
    buildExpression(node.condition);
    Completion thenCompletes = build(node.then);
    Completion elseCompletes = buildOptional(node.otherwise);
    return completeIfEither(thenCompletes, elseCompletes);
  }

  visitReturnStatement(ReturnStatement node) {
    if (node.expression != null) {
      int returned = buildExpression(node.expression);
      environment.addAssign(returned, environment.returnVariable);
    }
    return Completion.Never;
  }

  visitTryCatch(TryCatch node) {
    Completion bodyCompletes = build(node.body);
    Completion catchCompletes = Completion.Never;
    for (int i = 0; i < node.catches.length; ++i) {
      Catch catchNode = node.catches[i];
      if (catchNode.exception != null) {
        environment.localVariables[catchNode.exception] = builder.dynamicNode;
      }
      if (catchNode.stackTrace != null) {
        environment.localVariables[catchNode.stackTrace] = builder.dynamicNode;
      }
      if (build(catchNode.body) == Completion.Maybe) {
        catchCompletes = Completion.Maybe;
      }
    }
    return completeIfEither(bodyCompletes, catchCompletes);
  }

  visitTryFinally(TryFinally node) {
    Completion bodyCompletes = build(node.body);
    Completion finalizerCompletes = build(node.finalizer);
    return completeIfBoth(bodyCompletes, finalizerCompletes);
  }

  visitYieldStatement(YieldStatement node) {
    unsupported(node);
    return Completion.Maybe;
  }

  visitVariableDeclaration(VariableDeclaration node) {
    int initializer = node.initializer == null
        ? builder.nullNode
        : buildExpression(node.initializer);
    int variable = environment.getVariable(node);
    environment.addAssign(initializer, variable);
    return neverCompleteIf(_isThrowing(node.initializer));
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    expressionBuilder.buildInnerFunction(node.function, self: node.variable);
    return Completion.Maybe;
  }
}

class InitializerBuilder extends InitializerVisitor<Null> {
  final Builder builder;
  final Environment environment;
  ExpressionBuilder expressionBuilder;

  FieldNames get fieldNames => builder.fieldNames;

  InitializerBuilder(this.builder, this.environment) {
    expressionBuilder =
        new StatementBuilder(builder, environment).expressionBuilder;
  }

  void build(Initializer node) {
    node.accept(this);
  }

  int buildExpression(Expression node) {
    return expressionBuilder.build(node);
  }

  visitInvalidInitializer(InvalidInitializer node) {}

  visitFieldInitializer(FieldInitializer node) {
    int fieldVariable = builder.getFieldVariable(environment.host, node.field);
    int rightHandSide = buildExpression(node.value);
    environment.addAssign(rightHandSide, fieldVariable);
  }

  visitSuperInitializer(SuperInitializer node) {
    expressionBuilder.passArgumentsToFunction(
        node.arguments, environment.host, node.target.function);
  }

  visitRedirectingInitializer(RedirectingInitializer node) {
    expressionBuilder.passArgumentsToFunction(
        node.arguments, environment.host, node.target.function);
  }

  visitLocalInitializer(LocalInitializer node) {
    environment.localVariables[node.variable] =
        buildExpression(node.variable.initializer);
  }
}

class Names {
  static final Name current = new Name('current');
  static final Name iterator = new Name('iterator');
  static final Name then = new Name('then');
  static final Name call_ = new Name('call');
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
      environment.addStore(object, field, outputValue);
      if (!builder.isAssumedCovariant(node.classNode)) {
        int userValue = environment.getLoad(object, field);
        visitContravariant(node.typeArguments[i], userValue);
      }
    }
    return object;
  }

  int visitTypeParameterType(TypeParameterType node) {
    if (node.parameter.parent is Class) {
      assert(environment.thisVariable != null);
      return environment.getLoad(environment.thisVariable,
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
      int argument = environment.getLoad(function, field);
      visitContravariant(node.positionalParameters[i], argument);
    }
    for (int i = 0; i < node.namedParameters.length; ++i) {
      var parameter = node.namedParameters[i];
      int field = fieldNames.getNamedParameterField(arity, parameter.name);
      int argument = environment.getLoad(function, field);
      visitContravariant(parameter.type, argument);
    }
    int returnVariable = visit(node.returnType);
    environment.addStore(
        function, fieldNames.getReturnField(arity), returnVariable);
    return function;
  }

  /// Equivalent to visiting the FunctionType for the given function.
  int buildFunctionNode(FunctionNode node) {
    int minArity = node.requiredParameterCount;
    int maxArity = node.positionalParameters.length;
    Member member = node.parent is Member ? node.parent : null;
    int function = builder.newFunction(node, member);
    for (int arity = minArity; arity <= maxArity; ++arity) {
      for (int i = 0; i < arity; ++i) {
        int field = fieldNames.getPositionalParameterField(arity, i);
        int argument = environment.getLoad(function, field);
        visitContravariant(node.positionalParameters[i].type, argument);
      }
    }
    for (int i = 0; i < node.namedParameters.length; ++i) {
      VariableDeclaration variable = node.namedParameters[i];
      for (int arity = minArity; arity <= maxArity; ++arity) {
        int field = fieldNames.getNamedParameterField(arity, variable.name);
        int argument = environment.getLoad(function, field);
        visitContravariant(variable.type, argument);
      }
    }
    int returnVariable = visit(node.returnType);
    for (int arity = minArity; arity <= maxArity; ++arity) {
      environment.addStore(
          function, fieldNames.getReturnField(arity), returnVariable);
    }
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
    environment.addAssign(input, escapePoint);
  }

  visitTypeParameterType(TypeParameterType node) {
    if (node.parameter.parent is Class) {
      assert(environment.thisVariable != null);
      environment.addStore(environment.thisVariable,
          fieldNames.getTypeParameterField(node.parameter), input);
    } else {
      environment.addAssign(
          input, builder.getFunctionTypeParameterVariable(node.parameter));
    }
  }

  visitFunctionType(FunctionType node) {
    int minArity = node.requiredParameterCount;
    int maxArity = node.positionalParameters.length;
    for (int i = 0; i < node.positionalParameters.length; ++i) {
      int argument = visitCovariant(node.positionalParameters[i]);
      for (int arity = minArity; arity <= maxArity; ++arity) {
        int field = fieldNames.getPositionalParameterField(arity, i);
        environment.addStore(input, field, argument);
      }
    }
    for (var parameter in node.namedParameters) {
      int argument = visitCovariant(parameter.type);
      for (int arity = minArity; arity <= maxArity; ++arity) {
        int field = fieldNames.getNamedParameterField(arity, parameter.name);
        environment.addStore(input, field, argument);
      }
    }
    for (int arity = minArity; arity <= maxArity; ++arity) {
      int returnLocation =
          environment.getLoad(input, fieldNames.getReturnField(arity));
      visitContravariant(node.returnType, returnLocation);
    }
  }

  /// Equivalent to visiting the FunctionType for the given function.
  void buildFunctionNode(FunctionNode node) {
    int minArity = node.requiredParameterCount;
    int maxArity = node.positionalParameters.length;
    for (int arity = minArity; arity <= maxArity; ++arity) {
      for (int i = 0; i < arity; ++i) {
        int argument = visitCovariant(node.positionalParameters[i].type);
        int field = fieldNames.getPositionalParameterField(arity, i);
        environment.addStore(input, field, argument);
      }
    }
    for (int i = 0; i < node.namedParameters.length; ++i) {
      VariableDeclaration variable = node.namedParameters[i];
      int argument = visitCovariant(variable.type);
      for (int arity = minArity; arity <= maxArity; ++arity) {
        int field = fieldNames.getNamedParameterField(arity, variable.name);
        environment.addStore(input, field, argument);
      }
    }
    for (int arity = minArity; arity <= maxArity; ++arity) {
      int returnLocation =
          environment.getLoad(input, fieldNames.getReturnField(arity));
      visitContravariant(node.returnType, returnLocation);
    }
  }
}
