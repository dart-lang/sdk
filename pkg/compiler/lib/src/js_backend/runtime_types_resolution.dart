// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.runtime_types_resolution;

import '../common.dart';
import '../common/elements.dart' show CommonElements, ElementEnvironment;
import '../common/names.dart' show Identifiers;
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../ir/runtime_type_analysis.dart';
import '../kernel/kelements.dart';
import '../kernel/kernel_world.dart';
import '../options.dart';
import '../serialization/serialization.dart';
import '../universe/class_hierarchy.dart';
import '../universe/class_set.dart';
import '../universe/feature.dart';
import '../universe/selector.dart';
import '../world.dart';
import 'backend_usage.dart';

abstract class RtiNode {
  Entity get entity;

  Set<RtiNode>? _dependencies;
  Set<RtiNode> get dependencies => _dependencies ?? const {};

  bool _hasTest = false;
  bool get hasTest => _hasTest;

  /// Register that if [entity] needs type arguments then so does `node.entity`.
  bool addDependency(RtiNode node) {
    if (entity == node.entity) {
      // Skip trivial dependencies; if [entity] needs type arguments so does
      // [entity]!
      return false;
    }
    return (_dependencies ??= {}).add(node);
  }

  void markTest() {
    if (!hasTest) {
      _hasTest = true;
      for (RtiNode node in dependencies) {
        node.markTest();
      }
    }
  }

  String get kind;

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write(kind);
    sb.write(':');
    sb.write(entity);
    return sb.toString();
  }
}

class ClassNode extends RtiNode {
  final ClassEntity cls;

  ClassNode(this.cls);

  @override
  Entity get entity => cls;

  @override
  String get kind => 'class';
}

abstract class CallableNode extends RtiNode {
  bool selectorApplies(Selector selector, BuiltWorld world);
}

class MethodNode extends CallableNode {
  final Entity function;
  final ParameterStructure parameterStructure;
  final bool isCallTarget;
  final Name? instanceName;
  final bool isNoSuchMethod;

  MethodNode(this.function, this.parameterStructure,
      {required this.isCallTarget,
      this.instanceName,
      this.isNoSuchMethod = false});

  @override
  Entity get entity => function;

  @override
  bool selectorApplies(Selector selector, BuiltWorld world) {
    if (isNoSuchMethod) return true;
    return (isCallTarget && selector.isClosureCall ||
            instanceName == selector.memberName) &&
        selector.callStructure.signatureApplies(parameterStructure);
  }

  @override
  String get kind => 'method';

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write('MethodNode(');
    sb.write('function=$function');
    sb.write(',parameterStructure=$parameterStructure');
    sb.write(',isCallTarget=$isCallTarget');
    sb.write(',instanceName=$instanceName');
    sb.write(')');
    return sb.toString();
  }
}

bool _isProperty(Entity entity) =>
    entity is MemberEntity && (entity is FieldEntity || entity.isGetter);

class CallablePropertyNode extends CallableNode {
  final MemberEntity property;
  final DartType type;

  CallablePropertyNode(this.property, this.type)
      : assert(_isProperty(property));

  @override
  Entity get entity => property;

  @override
  String get kind => 'callable-property';

  @override
  bool selectorApplies(Selector selector, BuiltWorld world) {
    if (property.memberName != selector.memberName) return false;
    final myType = type;
    return myType is! FunctionType ||
        selector.callStructure
            .signatureApplies(ParameterStructure.fromType(myType));
  }

  @override
  String toString() => 'CallablePropertyNode(property=$property)';
}

class TypeVariableTests {
  final ElementEnvironment _elementEnvironment;
  final CommonElements _commonElements;
  final BuiltWorld _world;
  final Set<GenericInstantiation> _genericInstantiations;
  final bool forRtiNeeds;

  final Map<ClassEntity, ClassNode> _classes = {};
  final Map<Entity, MethodNode> _methods = {};
  final Map<MemberEntity, CallablePropertyNode> _callableProperties = {};
  final Map<Selector, Set<Entity>> _appliedSelectorMap = {};
  final Map<Entity, Set<GenericInstantiation>> _instantiationMap = {};
  final Map<ClassEntity, Set<InterfaceType>> _classInstantiationMap = {};

  /// All explicit is-tests.
  final Set<DartType> explicitIsChecks;

  /// All implicit is-tests.
  final Set<DartType> implicitIsChecks = {};

  TypeVariableTests(this._elementEnvironment, this._commonElements, this._world,
      this._genericInstantiations,
      {this.forRtiNeeds = true})
      : explicitIsChecks = _world.isChecks.toSet() {
    _setupDependencies();
    _propagateTests();
    _collectResults();
  }

  ClassHierarchy get _classHierarchy => _world.classHierarchy;

  DartTypes get _dartTypes => _commonElements.dartTypes;

  /// Classes whose type variables are explicitly or implicitly used in
  /// is-tests.
  ///
  /// For instance `A` and `B` in:
  ///
  ///     class A<T> {
  ///       m(o) => o is T;
  ///     }
  ///     class B<S> {
  ///       m(o) => A<S>().m(o);
  ///     }
  ///     main() => B<int>().m(0);
  ///
  Iterable<ClassEntity> get classTestsForTesting =>
      _classes.values.where((n) => n.hasTest).map((n) => n.cls).toSet();

  /// Methods that explicitly or implicitly use their type variables in
  /// is-tests.
  ///
  /// For instance `m1` and `m2`in:
  ///
  ///     m1<T>(o) => o is T;
  ///     m2<S>(o) => m1<S>(o);
  ///     main() => m2<int>(0);
  ///
  Iterable<Entity> get methodTestsForTesting =>
      _methods.values.where((n) => n.hasTest).map((n) => n.function).toSet();

  /// The entities that need type arguments at runtime if the 'key entity' needs
  /// type arguments.
  ///
  /// For instance:
  ///
  ///     class A<T> {
  ///       m() => B<T>();
  ///     }
  ///     class B<T> {}
  ///     main() => A<String>().m() is B<int>;
  ///
  /// Here `A` needs type arguments at runtime because the key entity `B` needs
  /// it in order to generate the check against `B<int>`.
  ///
  /// This can also involve generic methods:
  ///
  ///    class A<T> {}
  ///    method<T>() => A<T>();
  ///    main() => method<int>() is A<int>();
  ///
  /// Here `method` need type arguments at runtime because the key entity `A`
  /// needs it in order to generate the check against `A<int>`.
  ///
  Iterable<Entity> getTypeArgumentDependencies(Entity entity) {
    Iterable<RtiNode>? dependencies;
    if (entity is ClassEntity) {
      dependencies = _classes[entity]?.dependencies;
    } else if (_isProperty(entity)) {
      dependencies = _callableProperties[entity]?.dependencies;
    } else {
      dependencies = _methods[entity]?.dependencies;
    }
    if (dependencies == null) return const [];
    return dependencies.map((n) => n.entity).toSet();
  }

  /// Calls [f] for each selector that applies to generic [targets].
  void forEachAppliedSelector(void f(Selector selector, Set<Entity> targets)) {
    _appliedSelectorMap.forEach(f);
  }

  /// Calls [f] for each generic instantiation that applies to generic
  /// closurized [targets].
  void forEachInstantiatedEntity(
      void f(Entity target, Set<GenericInstantiation> instantiations)) {
    _instantiationMap.forEach(f);
  }

  Set<GenericInstantiation> instantiationsOf(Entity target) =>
      _instantiationMap[target] ?? const {};

  Set<InterfaceType> classInstantiationsOf(ClassEntity cls) =>
      _classInstantiationMap[cls] ?? const {};

  ClassNode _getClassNode(ClassEntity cls) {
    return _classes.putIfAbsent(cls, () => ClassNode(cls));
  }

  MethodNode _getMethodNode(Entity function) {
    return _methods.putIfAbsent(function, () {
      MethodNode node;
      if (function is FunctionEntity) {
        Name? instanceName;
        bool isCallTarget;
        bool isNoSuchMethod;
        if (function.isInstanceMember) {
          isCallTarget = _world.closurizedMembers.contains(function);
          instanceName = function.memberName;
          isNoSuchMethod = instanceName.text == Identifiers.noSuchMethod_;
        } else {
          isCallTarget = _world.closurizedStatics.contains(function);
          isNoSuchMethod = false;
        }
        node = MethodNode(function, function.parameterStructure,
            isCallTarget: isCallTarget,
            instanceName: instanceName,
            isNoSuchMethod: isNoSuchMethod);
      } else {
        ParameterStructure parameterStructure = ParameterStructure.fromType(
            _elementEnvironment.getLocalFunctionType(function as Local));
        node = MethodNode(function, parameterStructure, isCallTarget: true);
      }
      return node;
    });
  }

  CallablePropertyNode _getCallablePropertyNode(
          MemberEntity property, DartType type) =>
      _callableProperties.putIfAbsent(
          property, () => CallablePropertyNode(property, type));

  void _setupDependencies() {
    /// Register that if `node.entity` needs type arguments then so do entities
    /// whose type variables occur in [type].
    ///
    /// For instance if `A` needs type arguments then so does `B` in:
    ///
    ///   class A<T> {}
    ///   class B<T> { m() => A<T>(); }
    ///
    void registerDependencies(RtiNode node, DartType type) {
      type.forEachTypeVariable((TypeVariableType typeVariable) {
        final typeDeclaration = typeVariable.element.typeDeclaration!;
        if (typeDeclaration is ClassEntity) {
          node.addDependency(_getClassNode(typeDeclaration));
        } else {
          node.addDependency(_getMethodNode(typeDeclaration));
        }
      });
    }

    void registerDependenciesForInstantiation(RtiNode node, DartType type) {
      void onInterface(InterfaceType type) {
        if (type.typeArguments.isNotEmpty) {
          node.addDependency(_getClassNode(type.element));
        }
      }

      void onTypeVariable(TypeVariableType type) {
        final declaration = type.element.typeDeclaration!;
        if (declaration is ClassEntity) {
          node.addDependency(_getClassNode(declaration));
        } else {
          node.addDependency(_getMethodNode(declaration));
        }
      }

      _DependencyVisitor(
              onInterface: onInterface, onTypeVariable: onTypeVariable)
          .run(type);
    }

    // Add the rti dependencies that are implicit in the way the backend
    // generates code: when we create a new [List], we actually create a
    // [JSArray] in the backend and we need to add type arguments to the calls
    // of the list constructor whenever we determine that [JSArray] needs type
    // arguments.
    //
    // This is need for instance for:
    //
    //    var list = <int>[];
    //    var set = list.toSet();
    //    set is Set<String>;
    //
    // It also occurs for [Map] vs [JsLinkedHashMap] in:
    //
    //    var map = <int, double>{};
    //    var set = map.keys.toSet();
    //    set is Set<String>;
    //
    // TODO(johnniwinther): Make this dependency visible from code, possibly
    // using generic methods.
    _getClassNode(_commonElements.jsArrayClass)
        .addDependency(_getClassNode(_commonElements.listClass));
    _getClassNode(_commonElements.setLiteralClass)
        .addDependency(_getClassNode(_commonElements.setClass));
    _getClassNode(_commonElements.mapLiteralClass)
        .addDependency(_getClassNode(_commonElements.mapClass));

    void processCheckedType(DartType type) {
      var typeWithoutNullability = type.withoutNullability;
      if (typeWithoutNullability is InterfaceType) {
        // Register that if [cls] needs type arguments then so do the entities
        // that declare type variables occurring in [type].
        ClassEntity cls = typeWithoutNullability.element;
        registerDependencies(_getClassNode(cls), typeWithoutNullability);
      }
      if (typeWithoutNullability is FutureOrType) {
        // [typeWithoutNullability] is `FutureOr<X>`.

        // For the implied `is Future<X>` test, register that if `Future` needs
        // type arguments then so do the entities that declare type variables
        // occurring in `type.typeArgument`.
        registerDependencies(_getClassNode(_commonElements.futureClass),
            typeWithoutNullability.typeArgument);
        // Process `type.typeArgument` for the implied `is X` test.
        processCheckedType(typeWithoutNullability.typeArgument);
      }
    }

    _world.isChecks.forEach(processCheckedType);

    _world.instantiatedTypes.forEach((InterfaceType type) {
      // Register that if [cls] needs type arguments then so do the entities
      // that declare type variables occurring in [type].
      ClassEntity cls = type.element;
      registerDependencies(_getClassNode(cls), type);
      _classInstantiationMap.putIfAbsent(cls, () => {}).add(type);
    });

    _world.forEachStaticTypeArgument(
        (Entity entity, Iterable<DartType> typeArguments) {
      for (DartType type in typeArguments) {
        // Register that if [entity] needs type arguments then so do the
        // entities that declare type variables occurring in [type].
        registerDependencies(_getMethodNode(entity), type);
      }
    });

    _world.forEachDynamicTypeArgument(
        (Selector selector, Iterable<DartType> typeArguments) {
      void processCallableNode(CallableNode node) {
        if (node.selectorApplies(selector, _world)) {
          for (DartType type in typeArguments) {
            // Register that if `node.entity` needs type arguments then so do
            // the entities that declare type variables occurring in [type].
            registerDependencies(node, type);
          }
        }
      }

      void processMethod(Entity entity) {
        MethodNode node = _getMethodNode(entity);
        processCallableNode(node);
      }

      void processCallableProperty(MemberEntity entity, DartType type) {
        CallablePropertyNode node = _getCallablePropertyNode(entity, type);
        processCallableNode(node);
      }

      _world.forEachGenericInstanceMethod(processMethod);
      _world.genericLocalFunctions.forEach(processMethod);
      _world.closurizedStatics.forEach(processMethod);
      _world.userNoSuchMethods.forEach(processMethod);
      _world.genericCallableProperties.forEach(processCallableProperty);
    });

    for (GenericInstantiation instantiation in _genericInstantiations) {
      ParameterStructure instantiationParameterStructure =
          ParameterStructure.fromType(instantiation.functionType);
      ClassEntity implementationClass = _commonElements
          .getInstantiationClass(instantiation.typeArguments.length);

      void processEntity(Entity entity) {
        MethodNode node = _getMethodNode(entity);
        // TODO(sra,johnniwinther): Use more information from the instantiation
        // site. At many sites the instantiated element known, and for other
        // sites the static type could filter more entities.
        if (node.parameterStructure == instantiationParameterStructure) {
          _instantiationMap.putIfAbsent(entity, () => {}).add(instantiation);
          for (DartType type in instantiation.typeArguments) {
            registerDependenciesForInstantiation(node, type);
            // The instantiation is implemented by a generic class (a subclass
            // of 'Closure'). The implementation of generic instantiation
            // equality places a need on the type parameters of the generic
            // class. Making the class a dependency on the instantiation's
            // parameters allows the dependency to propagate back to the helper
            // function that is called to create the instantiation.
            registerDependencies(_getClassNode(implementationClass), type);
          }
        }
      }

      _world.closurizedMembers.forEach(processEntity);
      _world.closurizedStatics.forEach(processEntity);
      _world.genericLocalFunctions.forEach(processEntity);
    }
  }

  void _propagateTests() {
    void processTypeVariableType(TypeVariableType type) {
      TypeVariableEntity variable = type.element;
      final typeDeclaration = variable.typeDeclaration!;
      if (typeDeclaration is ClassEntity) {
        _getClassNode(typeDeclaration).markTest();
      } else {
        _getMethodNode(typeDeclaration).markTest();
      }
    }

    void processType(DartType type) {
      var typeWithoutNullability = type.withoutNullability;
      if (typeWithoutNullability is FutureOrType) {
        _getClassNode(_commonElements.futureClass).markTest();
        processType(typeWithoutNullability.typeArgument);
      } else {
        typeWithoutNullability.forEachTypeVariable((TypeVariableType type) {
          processTypeVariableType(type);
        });
      }
    }

    _world.isChecks.forEach(processType);
  }

  String dump({bool verbose = false}) {
    StringBuffer sb = StringBuffer();

    void addNode(RtiNode node) {
      if (node.hasTest || node.dependencies.isNotEmpty || verbose) {
        sb.write(' $node');
        if (node.hasTest) {
          sb.write(' test');
        }
        if (node.dependencies.isNotEmpty || verbose) {
          sb.writeln(':');
          node.dependencies.forEach((n) => sb.writeln('  $n'));
        } else {
          sb.writeln();
        }
      }
    }

    void addType(DartType type) {
      sb.writeln(' $type');
    }

    sb.writeln('classes:');
    _classes.values.forEach(addNode);
    sb.writeln('methods:');
    _methods.values.forEach(addNode);
    sb.writeln('explicit is-tests:');
    explicitIsChecks.forEach(addType);
    sb.writeln('implicit is-tests:');
    implicitIsChecks.forEach(addType);

    return sb.toString();
  }

  /// Register the implicit is-test of [type].
  ///
  /// If [type] is of the form `FutureOr<X>`, also register the implicit
  /// is-tests of `Future<X>` and `X`.
  void _addImplicitCheck(DartType type) {
    var typeWithoutNullability = type.withoutNullability;
    if (implicitIsChecks.add(typeWithoutNullability)) {
      if (typeWithoutNullability is FutureOrType) {
        _addImplicitCheck(
            _commonElements.futureType(typeWithoutNullability.typeArgument));
        _addImplicitCheck(typeWithoutNullability.typeArgument);
      } else if (typeWithoutNullability is TypeVariableType) {
        _addImplicitChecksViaInstantiation(typeWithoutNullability);
      } else if (typeWithoutNullability is RecordType) {
        _addImplicitChecks(typeWithoutNullability.fields);
      }
    }
  }

  void _addImplicitChecks(Iterable<DartType> types) {
    types.forEach(_addImplicitCheck);
  }

  void _addImplicitChecksViaInstantiation(TypeVariableType variable) {
    TypeVariableEntity entity = variable.element;
    final declaration = entity.typeDeclaration!;
    if (declaration is ClassEntity) {
      classInstantiationsOf(declaration).forEach((InterfaceType type) {
        _addImplicitCheck(type.typeArguments[entity.index]);
      });
    } else {
      instantiationsOf(declaration)
          .forEach((GenericInstantiation instantiation) {
        _addImplicitCheck(instantiation.typeArguments[entity.index]);
      });
      _world.forEachStaticTypeArgument(
          (Entity function, Set<DartType> typeArguments) {
        if (declaration == function) {
          _addImplicitChecks(typeArguments);
        }
      });
      _world.forEachDynamicTypeArgument(
          (Selector selector, Set<DartType> typeArguments) {
        if (_getMethodNode(declaration).selectorApplies(selector, _world)) {
          _addImplicitChecks(typeArguments);
        }
      });
    }
  }

  void _collectResults() {
    _world.isChecks.forEach((DartType type) {
      var typeWithoutNullability = type.withoutNullability;
      if (typeWithoutNullability is FutureOrType) {
        _addImplicitCheck(
            _commonElements.futureType(typeWithoutNullability.typeArgument));
        _addImplicitCheck(typeWithoutNullability.typeArgument);
      } else if (typeWithoutNullability is TypeVariableType) {
        _addImplicitChecksViaInstantiation(typeWithoutNullability);
      } else if (typeWithoutNullability is RecordType) {
        _addImplicitChecks(typeWithoutNullability.fields);
      }
    });

    // Compute type arguments of classes that use one of their type variables in
    // is-checks and add the is-checks that they imply.
    _classes.forEach((ClassEntity cls, ClassNode node) {
      if (!node.hasTest) return;

      // Find all instantiated types that are a subtype of a class that uses
      // one of its type arguments in an is-check and add the arguments to the
      // set of is-checks.
      for (ClassEntity base in _classHierarchy.allSubtypesOf(cls)) {
        classInstantiationsOf(base).forEach((InterfaceType subtype) {
          final instance = _dartTypes.asInstanceOf(subtype, cls);
          _addImplicitChecks(instance!.typeArguments);
        });
      }
    });

    _world.forEachStaticTypeArgument(
        (Entity function, Iterable<DartType> typeArguments) {
      if (!_getMethodNode(function).hasTest) {
        return;
      }
      _addImplicitChecks(typeArguments);
    });

    _world.forEachDynamicTypeArgument(
        (Selector selector, Iterable<DartType> typeArguments) {
      for (CallableNode node in [
        ..._methods.values,
        ..._callableProperties.values
      ]) {
        if (node.selectorApplies(selector, _world)) {
          if (forRtiNeeds) {
            _appliedSelectorMap
                .putIfAbsent(selector, () => {})
                .add(node.entity);
          }
          if (node.hasTest) {
            _addImplicitChecks(typeArguments);
          }
        }
      }
    });
  }
}

class _DependencyVisitor extends DartTypeStructuralPredicateVisitor {
  void Function(InterfaceType) onInterface;
  void Function(TypeVariableType) onTypeVariable;

  _DependencyVisitor({required this.onInterface, required this.onTypeVariable});

  @override
  bool handleInterfaceType(InterfaceType type) {
    onInterface(type);
    return false;
  }

  @override
  bool handleTypeVariableType(TypeVariableType type) {
    onTypeVariable(type);
    return false;
  }
}

/// Interface for the classes and methods that need runtime types.
abstract class RuntimeTypesNeed {
  /// Deserializes a [RuntimeTypesNeed] object from [source].
  factory RuntimeTypesNeed.readFromDataSource(
      DataSourceReader source, ElementEnvironment elementEnvironment) {
    bool isTrivial = source.readBool();
    if (isTrivial) {
      return TrivialRuntimeTypesNeed(elementEnvironment);
    }
    return RuntimeTypesNeedImpl.readFromDataSource(source, elementEnvironment);
  }

  /// Serializes this [RuntimeTypesNeed] to [sink].
  void writeToDataSink(DataSinkWriter sink);

  /// Returns `true` if [cls] needs type arguments at runtime.
  ///
  /// This is for instance the case for generic classes used in a type test:
  ///
  ///   class C<T> {}
  ///   main() {
  ///     C<int>() is C<int>;
  ///     C<String>() is C<String>;
  ///   }
  ///
  bool classNeedsTypeArguments(ClassEntity cls);

  /// Returns `true` if [cls] is a generic class which does not need type
  /// arguments at runtime.
  bool classHasErasedTypeArguments(ClassEntity cls);

  /// Returns `true` if [method] needs type arguments at runtime type.
  ///
  /// This is for instance the case for generic methods that use type tests:
  ///
  ///   method<T>(T t) => t is T;
  ///   main() {
  ///     method<int>(0);
  ///     method<String>('');
  ///   }
  ///
  bool methodNeedsTypeArguments(FunctionEntity method);

  /// Returns `true` if a signature is needed for [method].
  ///
  /// A signature is a runtime method type descriptor function that creates
  /// a runtime representation of the type of the method.
  ///
  /// This is for instance needed for instance methods of generic classes that
  /// are torn off and whose type therefore potentially is used in a type test:
  ///
  ///     class C<T> {
  ///       method(T t) {}
  ///     }
  ///     main() {
  ///       C<int>().method is void Function(int);
  ///       C<String>().method is void Function(String);
  ///     }
  ///
  /// Since type of the method depends on the type argument of its enclosing
  /// class, the type of the method is a JavaScript function like:
  ///
  ///    signature: function (T) {
  ///      return {'func': true, params: [T]};
  ///    }
  ///
  bool methodNeedsSignature(FunctionEntity method);

  /// Returns `true` if a dynamic call of [selector] needs to pass type
  /// arguments.
  bool selectorNeedsTypeArguments(Selector selector);

  /// Returns `true` if a generic instantiation on an expression of type
  /// [functionType] with the given [typeArgumentCount] needs to pass type
  /// arguments.
  // TODO(johnniwinther): Use [functionType].
  bool instantiationNeedsTypeArguments(
      FunctionType? functionType, int typeArgumentCount);
}

class TrivialRuntimeTypesNeed implements RuntimeTypesNeed {
  final ElementEnvironment _elementEnvironment;

  const TrivialRuntimeTypesNeed(this._elementEnvironment);

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeBool(true); // Is trivial.
  }

  @override
  bool classNeedsTypeArguments(ClassEntity cls) =>
      _elementEnvironment.isGenericClass(cls);

  @override
  bool classHasErasedTypeArguments(ClassEntity cls) => false;

  @override
  bool methodNeedsSignature(FunctionEntity method) => true;

  @override
  bool methodNeedsTypeArguments(FunctionEntity method) =>
      // TODO(johnniwinther): Align handling of type arguments passed to factory
      // constructors with type arguments passed the regular generic methods.
      !(method is ConstructorEntity && method.isFactoryConstructor);

  @override
  bool selectorNeedsTypeArguments(Selector selector) => true;

  @override
  bool instantiationNeedsTypeArguments(
      FunctionType? functionType, int typeArgumentCount) {
    return true;
  }
}

class RuntimeTypesNeedImpl implements RuntimeTypesNeed {
  /// Tag used for identifying serialized [RuntimeTypesNeed] objects in a
  /// debugging data stream.
  static const String tag = 'runtime-types-need';

  final ElementEnvironment _elementEnvironment;
  final Set<ClassEntity> classesNeedingTypeArguments;
  final Set<FunctionEntity> methodsNeedingSignature;
  final Set<FunctionEntity> methodsNeedingTypeArguments;
  final Set<Local> localFunctionsNeedingSignature;
  final Set<Local> localFunctionsNeedingTypeArguments;
  final Set<Selector> selectorsNeedingTypeArguments;
  final Set<int> instantiationsNeedingTypeArguments;

  RuntimeTypesNeedImpl(
      this._elementEnvironment,
      this.classesNeedingTypeArguments,
      this.methodsNeedingSignature,
      this.methodsNeedingTypeArguments,
      this.localFunctionsNeedingSignature,
      this.localFunctionsNeedingTypeArguments,
      this.selectorsNeedingTypeArguments,
      this.instantiationsNeedingTypeArguments);

  factory RuntimeTypesNeedImpl.readFromDataSource(
      DataSourceReader source, ElementEnvironment elementEnvironment) {
    source.begin(tag);
    Set<ClassEntity> classesNeedingTypeArguments =
        source.readClasses<ClassEntity>().toSet();
    Set<FunctionEntity> methodsNeedingSignature =
        source.readMembers<FunctionEntity>().toSet();
    Set<FunctionEntity> methodsNeedingTypeArguments =
        source.readMembers<FunctionEntity>().toSet();
    Set<Selector> selectorsNeedingTypeArguments =
        source.readList(() => Selector.readFromDataSource(source)).toSet();
    Set<int> instantiationsNeedingTypeArguments =
        source.readList(source.readInt).toSet();
    source.end(tag);
    return RuntimeTypesNeedImpl(
        elementEnvironment,
        classesNeedingTypeArguments,
        methodsNeedingSignature,
        methodsNeedingTypeArguments,
        const {},
        const {},
        selectorsNeedingTypeArguments,
        instantiationsNeedingTypeArguments);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeBool(false); // Is _not_ trivial.
    sink.begin(tag);
    sink.writeClasses(classesNeedingTypeArguments);
    sink.writeMembers(methodsNeedingSignature);
    sink.writeMembers(methodsNeedingTypeArguments);
    assert(localFunctionsNeedingSignature.isEmpty);
    assert(localFunctionsNeedingTypeArguments.isEmpty);
    sink.writeList(selectorsNeedingTypeArguments,
        (Selector selector) => selector.writeToDataSink(sink));
    sink.writeList(instantiationsNeedingTypeArguments, sink.writeInt);
    sink.end(tag);
  }

  @override
  bool classNeedsTypeArguments(ClassEntity cls) {
    if (!_elementEnvironment.isGenericClass(cls)) return false;
    return classesNeedingTypeArguments.contains(cls);
  }

  @override
  bool classHasErasedTypeArguments(ClassEntity cls) {
    if (!_elementEnvironment.isGenericClass(cls)) return false;
    return !classesNeedingTypeArguments.contains(cls);
  }

  @override
  bool methodNeedsSignature(FunctionEntity function) {
    return methodsNeedingSignature.contains(function);
  }

  @override
  bool methodNeedsTypeArguments(FunctionEntity function) {
    return methodsNeedingTypeArguments.contains(function);
  }

  @override
  bool selectorNeedsTypeArguments(Selector selector) {
    if (selector.callStructure.typeArgumentCount == 0) return false;
    return selectorsNeedingTypeArguments.contains(selector);
  }

  @override
  bool instantiationNeedsTypeArguments(
      FunctionType? functionType, int typeArgumentCount) {
    return instantiationsNeedingTypeArguments.contains(typeArgumentCount);
  }
}

/// Interface for computing classes and methods that need runtime types.
abstract class RuntimeTypesNeedBuilder {
  /// Registers that [cls] uses one of its type variables as a literal.
  void registerClassUsingTypeVariableLiteral(ClassEntity cls);

  /// Registers that [method] uses one of its type variables as a literal.
  void registerMethodUsingTypeVariableLiteral(FunctionEntity method);

  /// Registers that [localFunction] uses one of its type variables as a
  /// literal.
  void registerLocalFunctionUsingTypeVariableLiteral(Local localFunction);

  /// Registers that a generic [instantiation] is used.
  void registerGenericInstantiation(GenericInstantiation instantiation);

  /// Registers a [TypeVariableType] literal on this [RuntimeTypesNeedBuilder].
  void registerTypeVariableLiteral(TypeVariableType variable);

  /// Computes the [RuntimeTypesNeed] for the data registered with this builder.
  RuntimeTypesNeed computeRuntimeTypesNeed(
      KClosedWorld closedWorld, CompilerOptions options);
}

class TrivialRuntimeTypesNeedBuilder implements RuntimeTypesNeedBuilder {
  const TrivialRuntimeTypesNeedBuilder();

  @override
  void registerClassUsingTypeVariableLiteral(ClassEntity cls) {}

  @override
  void registerMethodUsingTypeVariableLiteral(FunctionEntity method) {}

  @override
  void registerLocalFunctionUsingTypeVariableLiteral(Local localFunction) {}

  @override
  void registerGenericInstantiation(GenericInstantiation instantiation) {}

  @override
  void registerTypeVariableLiteral(TypeVariableType variable) {}

  @override
  RuntimeTypesNeed computeRuntimeTypesNeed(
      KClosedWorld closedWorld, CompilerOptions options) {
    return TrivialRuntimeTypesNeed(closedWorld.elementEnvironment);
  }
}

class RuntimeTypesNeedBuilderImpl implements RuntimeTypesNeedBuilder {
  final ElementEnvironment _elementEnvironment;

  final Set<ClassEntity> classesUsingTypeVariableLiterals = {};

  final Set<FunctionEntity> methodsUsingTypeVariableLiterals = {};

  final Set<Local> localFunctionsUsingTypeVariableLiterals = {};

  Map<Selector, Set<Entity>>? selectorsNeedingTypeArgumentsForTesting;

  Map<Entity, Set<GenericInstantiation>>?
      _instantiatedEntitiesNeedingTypeArgumentsForTesting;

  Map<Entity, Set<GenericInstantiation>>
      get instantiatedEntitiesNeedingTypeArgumentsForTesting =>
          _instantiatedEntitiesNeedingTypeArgumentsForTesting ?? const {};

  final Set<GenericInstantiation> _genericInstantiations = {};

  TypeVariableTests? typeVariableTestsForTesting;

  RuntimeTypesNeedBuilderImpl(this._elementEnvironment);

  @override
  void registerClassUsingTypeVariableLiteral(ClassEntity cls) {
    classesUsingTypeVariableLiterals.add(cls);
  }

  @override
  void registerMethodUsingTypeVariableLiteral(FunctionEntity method) {
    methodsUsingTypeVariableLiterals.add(method);
  }

  @override
  void registerLocalFunctionUsingTypeVariableLiteral(Local localFunction) {
    localFunctionsUsingTypeVariableLiterals.add(localFunction);
  }

  @override
  void registerGenericInstantiation(GenericInstantiation instantiation) {
    _genericInstantiations.add(instantiation);
  }

  @override
  void registerTypeVariableLiteral(TypeVariableType variable) {
    final typeDeclaration = variable.element.typeDeclaration;
    assert(typeDeclaration != null);
    if (typeDeclaration is ClassEntity) {
      registerClassUsingTypeVariableLiteral(typeDeclaration);
    } else if (typeDeclaration is FunctionEntity) {
      registerMethodUsingTypeVariableLiteral(typeDeclaration);
    } else if (typeDeclaration is Local) {
      registerLocalFunctionUsingTypeVariableLiteral(typeDeclaration);
    }
  }

  @override
  RuntimeTypesNeed computeRuntimeTypesNeed(
      KClosedWorld closedWorld, CompilerOptions options) {
    TypeVariableTests typeVariableTests = TypeVariableTests(
        closedWorld.elementEnvironment,
        closedWorld.commonElements,
        closedWorld,
        _genericInstantiations);
    Set<ClassEntity> classesNeedingTypeArguments = {};
    Set<FunctionEntity> methodsNeedingSignature = {};
    Set<FunctionEntity> methodsNeedingTypeArguments = {};
    Set<Local> localFunctionsNeedingSignature = {};
    Set<Local> localFunctionsNeedingTypeArguments = {};
    Set<Entity> processedEntities = {};

    // Find the classes that need type arguments at runtime. Such
    // classes are:
    // (1) used in an is check with type variables,
    // (2) dependencies of classes in (1),
    // (3) subclasses of (2) and (3).
    void potentiallyNeedTypeArguments(Entity entity) {
      // Functions with type arguments can have dependencies of each other (if
      // the functions call each other) so we keep a set to prevent infinitely
      // recursing over the same entities.
      if (processedEntities.contains(entity)) return;

      processedEntities.add(entity);
      if (entity is ClassEntity) {
        ClassEntity cls = entity;
        if (!_elementEnvironment.isGenericClass(cls)) return;
        if (classesNeedingTypeArguments.contains(cls)) return;
        classesNeedingTypeArguments.add(cls);

        // TODO(ngeoffray): This should use subclasses, not subtypes.
        closedWorld.classHierarchy.forEachStrictSubtypeOf(cls,
            (ClassEntity sub) {
          potentiallyNeedTypeArguments(sub);
          return IterationStep.CONTINUE;
        });
      } else if (entity is FunctionEntity) {
        methodsNeedingTypeArguments.add(entity);
      } else if (_isProperty(entity)) {
        // Do nothing. We just need to visit the dependencies.
      } else {
        localFunctionsNeedingTypeArguments.add(entity as Local);
      }

      Iterable<Entity> dependencies =
          typeVariableTests.getTypeArgumentDependencies(entity);
      dependencies.forEach((Entity other) {
        potentiallyNeedTypeArguments(other);
      });
    }

    Set<Local> localFunctions = closedWorld.localFunctions.toSet();
    Set<FunctionEntity> closurizedMembers =
        closedWorld.closurizedMembersWithFreeTypeVariables.toSet();

    // Check local functions and closurized members.
    void checkClosures({required DartType potentialSubtypeOf}) {
      bool checkFunctionType(FunctionType functionType) {
        final contextClass = DartTypes.getClassContext(functionType);
        if (contextClass != null &&
            (closedWorld.dartTypes
                .isPotentialSubtype(functionType, potentialSubtypeOf))) {
          potentiallyNeedTypeArguments(contextClass);
          return true;
        }
        return false;
      }

      Set<Local>? localFunctionsToRemove;
      Set<FunctionEntity>? closurizedMembersToRemove;
      for (Local function in localFunctions) {
        FunctionType functionType =
            _elementEnvironment.getLocalFunctionType(function);
        if (closedWorld.dartTypes
            .isPotentialSubtype(functionType, potentialSubtypeOf,
                // TODO(johnniwinther): Use register generic instantiations
                // instead.
                assumeInstantiations: _genericInstantiations.isNotEmpty)) {
          if (functionType.typeVariables.isNotEmpty) {
            potentiallyNeedTypeArguments(function);
          }
          functionType.forEachTypeVariable((TypeVariableType typeVariable) {
            final typeDeclaration = typeVariable.element.typeDeclaration!;
            if (!processedEntities.contains(typeDeclaration)) {
              potentiallyNeedTypeArguments(typeDeclaration);
            }
          });
          localFunctionsNeedingSignature.add(function);
          localFunctionsToRemove ??= {};
          localFunctionsToRemove.add(function);
        }
      }
      for (FunctionEntity function in closurizedMembers) {
        if (checkFunctionType(_elementEnvironment.getFunctionType(function))) {
          methodsNeedingSignature.add(function);
          closurizedMembersToRemove ??= {};
          closurizedMembersToRemove.add(function);
        }
      }
      if (localFunctionsToRemove != null) {
        localFunctions.removeAll(localFunctionsToRemove);
      }
      if (closurizedMembersToRemove != null) {
        closurizedMembers.removeAll(closurizedMembersToRemove);
      }
    }

    // Compute the set of all classes and methods that need runtime type
    // information.

    void processChecks(Set<DartType> checks) {
      checks.forEach((DartType type) {
        type = type.withoutNullability;
        if (type is InterfaceType) {
          InterfaceType itf = type;
          if (!closedWorld.dartTypes.treatAsRawType(itf)) {
            potentiallyNeedTypeArguments(itf.element);
          }
        } else {
          type.forEachTypeVariable((TypeVariableType typeVariable) {
            // This handles checks against type variables and function types
            // containing type variables.
            final typeDeclaration = typeVariable.element.typeDeclaration!;
            potentiallyNeedTypeArguments(typeDeclaration);
          });
          if (type is FunctionType) {
            checkClosures(potentialSubtypeOf: type);
          }
          if (type is FutureOrType) {
            potentiallyNeedTypeArguments(
                closedWorld.commonElements.futureClass);
          }
        }
      });
    }

    processChecks(typeVariableTests.explicitIsChecks);
    processChecks(typeVariableTests.implicitIsChecks);

    // Add the classes, methods and local functions that need type arguments
    // because they use a type variable as a literal.
    classesUsingTypeVariableLiterals.forEach(potentiallyNeedTypeArguments);
    methodsUsingTypeVariableLiterals.forEach(potentiallyNeedTypeArguments);
    localFunctionsUsingTypeVariableLiterals
        .forEach(potentiallyNeedTypeArguments);

    typeVariableTests._callableProperties.keys
        .forEach(potentiallyNeedTypeArguments);

    if (closedWorld.isMemberUsed(
        closedWorld.commonElements.invocationTypeArgumentGetter)) {
      // If `Invocation.typeArguments` is live, mark all user-defined
      // implementations of `noSuchMethod` as needing type arguments.
      for (MemberEntity member in closedWorld.userNoSuchMethods) {
        potentiallyNeedTypeArguments(member);
      }
    }

    void checkFunction(Entity function, FunctionType type) {
      for (FunctionTypeVariable typeVariable in type.typeVariables) {
        DartType bound = typeVariable.bound;
        if (!closedWorld.dartTypes.isTopType(bound)) {
          potentiallyNeedTypeArguments(function);
          break;
        }
      }
    }

    closedWorld.forEachGenericMethod((FunctionEntity method) {
      if (closedWorld.annotationsData
          .getParameterCheckPolicy(method)
          .isEmitted) {
        checkFunction(method, _elementEnvironment.getFunctionType(method));
      }
    });
    for (final function in closedWorld.genericLocalFunctions) {
      if (closedWorld.annotationsData
          // TODO(johnniwinther): Support @pragma on local functions and use
          // this here instead of the enclosing member.
          .getParameterCheckPolicy((function as KLocalFunction).memberContext)
          .isEmitted) {
        checkFunction(
            function, _elementEnvironment.getLocalFunctionType(function));
      }
    }

    BackendUsage backendUsage = closedWorld.backendUsage;
    CommonElements commonElements = closedWorld.commonElements;

    /// Set to `true` if subclasses of `Object` need runtimeType. This is
    /// only used to stop the computation early.
    bool neededOnAll = false;

    /// Set to `true` if subclasses of `Function` need runtimeType.
    bool neededOnFunctions = false;

    Set<ClassEntity> classesDirectlyNeedingRuntimeType = {};

    Iterable<ClassEntity> impliedClasses(DartType type) {
      type = type.withoutNullability;
      if (type is InterfaceType) {
        return [type.element];
      } else if (type is NeverType ||
          type is DynamicType ||
          type is VoidType ||
          type is AnyType ||
          type is ErasedType) {
        // No classes implied.
        return const [];
      } else if (type is FunctionType) {
        // TODO(johnniwinther): Include only potential function type subtypes.
        return [commonElements.functionClass];
      } else if (type is FunctionTypeVariable) {
        return impliedClasses(type.bound);
      } else if (type is FutureOrType) {
        return [
          commonElements.futureClass,
          ...impliedClasses(type.typeArgument),
        ];
      } else if (type is TypeVariableType) {
        // TODO(johnniwinther): Can we do better?
        return impliedClasses(
            _elementEnvironment.getTypeVariableBound(type.element));
      } else if (type is RecordType) {
        return [commonElements.recordClass];
      }
      throw UnsupportedError('Unexpected type $type (${type.runtimeType})');
    }

    void addClass(ClassEntity? cls) {
      if (cls != null) {
        classesDirectlyNeedingRuntimeType.add(cls);
      }
      if (cls == commonElements.objectClass) {
        neededOnAll = true;
      }
      if (cls == commonElements.functionClass) {
        neededOnFunctions = true;
      }
    }

    for (RuntimeTypeUse runtimeTypeUse in backendUsage.runtimeTypeUses) {
      switch (runtimeTypeUse.kind) {
        case RuntimeTypeUseKind.string:
          if (!options.laxRuntimeTypeToString) {
            impliedClasses(runtimeTypeUse.receiverType).forEach(addClass);
          }

          break;
        case RuntimeTypeUseKind.equals:
          Iterable<ClassEntity> receiverClasses =
              impliedClasses(runtimeTypeUse.receiverType);
          Iterable<ClassEntity> argumentClasses =
              impliedClasses(runtimeTypeUse.argumentType!);

          for (ClassEntity receiverClass in receiverClasses) {
            for (ClassEntity argumentClass in argumentClasses) {
              // TODO(johnniwinther): Special case use of `this.runtimeType`.
              SubclassResult result = closedWorld.classHierarchy
                  .commonSubclasses(receiverClass, ClassQuery.SUBTYPE,
                      argumentClass, ClassQuery.SUBTYPE);
              switch (result.kind) {
                case SubclassResultKind.EMPTY:
                  break;
                case SubclassResultKind.EXACT1:
                case SubclassResultKind.SUBCLASS1:
                case SubclassResultKind.SUBTYPE1:
                  addClass(receiverClass);
                  break;
                case SubclassResultKind.EXACT2:
                case SubclassResultKind.SUBCLASS2:
                case SubclassResultKind.SUBTYPE2:
                  addClass(argumentClass);
                  break;
                case SubclassResultKind.SET:
                  for (ClassEntity cls in result.classes) {
                    addClass(cls);
                    if (neededOnAll) break;
                  }
                  break;
              }
            }
          }
          break;
        case RuntimeTypeUseKind.unknown:
          impliedClasses(runtimeTypeUse.receiverType).forEach(addClass);
          break;
      }
      if (neededOnAll) break;
    }

    Set<ClassEntity> allClassesNeedingRuntimeType;
    if (neededOnAll) {
      neededOnFunctions = true;
      allClassesNeedingRuntimeType = closedWorld.classHierarchy
          .subclassesOf(commonElements.objectClass)
          .toSet();
    } else {
      allClassesNeedingRuntimeType = {};
      // TODO(johnniwinther): Support this operation directly in
      // [ClosedWorld] using the [ClassSet]s.
      for (ClassEntity cls in classesDirectlyNeedingRuntimeType) {
        if (!allClassesNeedingRuntimeType.contains(cls)) {
          allClassesNeedingRuntimeType
              .addAll(closedWorld.classHierarchy.subtypesOf(cls));
        }
      }
    }
    allClassesNeedingRuntimeType.forEach(potentiallyNeedTypeArguments);
    if (neededOnFunctions) {
      for (Local function in closedWorld.genericLocalFunctions) {
        potentiallyNeedTypeArguments(function);
      }
      for (Local function in localFunctions) {
        FunctionType functionType =
            _elementEnvironment.getLocalFunctionType(function);
        functionType.forEachTypeVariable((TypeVariableType typeVariable) {
          final typeDeclaration = typeVariable.element.typeDeclaration!;
          if (!processedEntities.contains(typeDeclaration)) {
            potentiallyNeedTypeArguments(typeDeclaration);
          }
        });
        localFunctionsNeedingSignature.addAll(localFunctions);
      }
      for (FunctionEntity function
          in closedWorld.closurizedMembersWithFreeTypeVariables) {
        methodsNeedingSignature.add(function);
        potentiallyNeedTypeArguments(function.enclosingClass!);
      }
    }

    Set<Selector> selectorsNeedingTypeArguments = {};
    typeVariableTests
        .forEachAppliedSelector((Selector selector, Set<Entity> targets) {
      for (Entity target in targets) {
        if (_isProperty(target) ||
            methodsNeedingTypeArguments.contains(target) ||
            localFunctionsNeedingTypeArguments.contains(target)) {
          selectorsNeedingTypeArguments.add(selector);
          if (retainDataForTesting) {
            (selectorsNeedingTypeArgumentsForTesting ??= {})
                .putIfAbsent(selector, () => {})
                .add(target);
          } else {
            return;
          }
        }
      }
    });
    Set<int> instantiationsNeedingTypeArguments = {};
    typeVariableTests.forEachInstantiatedEntity(
        (Entity target, Set<GenericInstantiation> instantiations) {
      // An instantiation needs type arguments if the class implementing the
      // instantiation needs type arguments.
      int arity = instantiations.first.typeArguments.length;
      if (!instantiationsNeedingTypeArguments.contains(arity)) {
        if (classesNeedingTypeArguments
            .contains(commonElements.getInstantiationClass(arity))) {
          instantiationsNeedingTypeArguments.add(arity);
        }
      }

      if (retainDataForTesting) {
        if (methodsNeedingTypeArguments.contains(target) ||
            localFunctionsNeedingTypeArguments.contains(target)) {
          (_instantiatedEntitiesNeedingTypeArgumentsForTesting ??= {})
              .putIfAbsent(target, () => {})
              .addAll(instantiations);
        }
      }
    });

    if (retainDataForTesting) {
      typeVariableTestsForTesting = typeVariableTests;
    }

    /*print(typeVariableTests.dump());
    print('------------------------------------------------------------------');
    print('classesNeedingTypeArguments:');
    classesNeedingTypeArguments.forEach((e) => print('  $e'));
    print('------------------------------------------------------------------');
    print('methodsNeedingSignature:');
    methodsNeedingSignature.forEach((e) => print('  $e'));
    print('------------------------------------------------------------------');
    print('methodsNeedingTypeArguments:');
    methodsNeedingTypeArguments.forEach((e) => print('  $e'));
    print('------------------------------------------------------------------');
    print('localFunctionsNeedingSignature:');
    localFunctionsNeedingSignature.forEach((e) => print('  $e'));
    print('------------------------------------------------------------------');
    print('localFunctionsNeedingTypeArguments:');
    localFunctionsNeedingTypeArguments.forEach((e) => print('  $e'));
    print('------------------------------------------------------------------');
    print('selectorsNeedingTypeArguments:');
    selectorsNeedingTypeArguments.forEach((e) => print('  $e'));
    print('instantiationsNeedingTypeArguments: '
        '$instantiationsNeedingTypeArguments');*/

    return RuntimeTypesNeedImpl(
        _elementEnvironment,
        classesNeedingTypeArguments,
        methodsNeedingSignature,
        methodsNeedingTypeArguments,
        localFunctionsNeedingSignature,
        localFunctionsNeedingTypeArguments,
        selectorsNeedingTypeArguments,
        instantiationsNeedingTypeArguments);
  }
}
