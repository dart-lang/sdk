// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.runtime_types;

import '../common_elements.dart' show CommonElements, ElementEnvironment;
import '../elements/elements.dart' show ClassElement;
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/resolution_types.dart'
    show
        MalformedType,
        MethodTypeVariableType,
        ResolutionDartTypeVisitor,
        ResolutionTypedefType;
import '../elements/types.dart';
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js_emitter/js_emitter.dart' show Emitter;
import '../universe/selector.dart';
import '../universe/world_builder.dart';
import '../world.dart' show ClosedWorld;
import 'backend_usage.dart';
import 'namer.dart';

/// For each class, stores the possible class subtype tests that could succeed.
abstract class TypeChecks {
  /// Get the set of checks required for class [element].
  Iterable<TypeCheck> operator [](ClassEntity element);

  /// Get the iterable for all classes that need type checks.
  Iterable<ClassEntity> get classes;
}

typedef jsAst.Expression OnVariableCallback(TypeVariableType variable);
typedef bool ShouldEncodeTypedefCallback(ResolutionTypedefType variable);

/// Interface for the classes and methods that need runtime types.
abstract class RuntimeTypesNeed {
  /// Returns `true` if [cls] needs type arguments at runtime type.
  ///
  /// This is for instance the case for generic classes used in a type test:
  ///
  ///   class C<T> {}
  ///   main() {
  ///     new C<int>() is C<int>;
  ///     new C<String>() is C<String>;
  ///   }
  ///
  bool classNeedsTypeArguments(ClassEntity cls);

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
  ///       new C<int>().method is void Function(int);
  ///       new C<String>().method is void Function(String);
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

  /// Returns `true` if a signature is needed for the call-method created for
  /// [localFunction].
  ///
  /// See [methodNeedsSignature] for more information on what a signature is
  /// and when it is needed.
  // TODO(redemption): Remove this when the old frontend is deleted.
  bool localFunctionNeedsSignature(Local localFunction);

  bool classUsesTypeVariableLiteral(ClassEntity cls);
}

class TrivialRuntimeTypesNeed implements RuntimeTypesNeed {
  const TrivialRuntimeTypesNeed();

  @override
  bool classNeedsTypeArguments(ClassEntity cls) => true;

  @override
  bool classUsesTypeVariableLiteral(ClassEntity cls) => true;

  @override
  bool localFunctionNeedsSignature(Local localFunction) => true;

  @override
  bool methodNeedsSignature(FunctionEntity method) => true;

  @override
  bool methodNeedsTypeArguments(FunctionEntity method) =>
      // TODO(johnniwinther): Align handling of type arguments passed to factory
      // constructors with type arguments passed the regular generic methods.
      !(method is ConstructorEntity && method.isFactoryConstructor);
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

  /// Computes the [RuntimeTypesNeed] for the data registered with this builder.
  RuntimeTypesNeed computeRuntimeTypesNeed(
      ResolutionWorldBuilder resolutionWorldBuilder, ClosedWorld closedWorld,
      {bool enableTypeAssertions});
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
  RuntimeTypesNeed computeRuntimeTypesNeed(
      ResolutionWorldBuilder resolutionWorldBuilder, ClosedWorld closedWorld,
      {bool enableTypeAssertions}) {
    return const TrivialRuntimeTypesNeed();
  }
}

/// Interface for the needed runtime type checks.
abstract class RuntimeTypesChecks {
  /// Returns the required runtime type checks.
  TypeChecks get requiredChecks;

  /// Return all classes that are referenced in the type of the function, i.e.,
  /// in the return type or the argument types.
  Iterable<ClassEntity> getReferencedClasses(FunctionType type);

  /// Return all classes that use type arguments.
  Iterable<ClassEntity> getRequiredArgumentClasses();

  /// Return all classes immediately used in explicit or implicit is-tests.
  ///
  /// An is-test of `o is List<String>` will add `List`, but _not_ `String` to
  /// the [checkedClasses] set.
  Iterable<ClassEntity> get checkedClasses;

  // Returns all function types immediately used in explicit or implicit
  // is-tests.
  //
  // An is-test of `of is Function(Function())` will add `Function(Function())`
  // but _not_ `Function()` to the [checkedFunctionTypes] set. An is-test
  // against a typedef will add its alias to the [checkedFunctionTypes] set.
  Iterable<FunctionType> get checkedFunctionTypes;

  /// Classes whose type variables are explicitly or implicitly used in
  /// is-tests.
  ///
  /// See [TypeVariableTests.classTests].
  Iterable<ClassEntity> get classesUsingTypeVariableTests;
}

class TrivialTypesChecks implements RuntimeTypesChecks {
  final TypeChecks _typeChecks;
  final Set<ClassEntity> _allClasses;

  TrivialTypesChecks(this._typeChecks)
      : _allClasses = _typeChecks.classes.toSet();

  @override
  TypeChecks get requiredChecks => _typeChecks;

  @override
  Iterable<ClassEntity> getRequiredArgumentClasses() => _allClasses;

  @override
  Iterable<ClassEntity> getReferencedClasses(FunctionType type) => _allClasses;

  @override
  Iterable<ClassEntity> get checkedClasses => _allClasses;

  @override
  Iterable<FunctionType> get checkedFunctionTypes => const <FunctionType>[];

  @override
  Iterable<ClassEntity> get classesUsingTypeVariableTests => _allClasses;
}

/// Interface for computing the needed runtime type checks.
abstract class RuntimeTypesChecksBuilder {
  void registerTypeVariableBoundsSubtypeCheck(
      DartType typeArgument, DartType bound);

  /// Computes the [RuntimeTypesChecks] for the data in this builder.
  RuntimeTypesChecks computeRequiredChecks(
      CodegenWorldBuilder codegenWorldBuilder);

  bool get rtiChecksBuilderClosed;
}

class TrivialRuntimeTypesChecksBuilder implements RuntimeTypesChecksBuilder {
  final ClosedWorld _closedWorld;
  final TrivialRuntimeTypesSubstitutions _substitutions;
  bool rtiChecksBuilderClosed = false;

  TrivialRuntimeTypesChecksBuilder(this._closedWorld, this._substitutions);

  ElementEnvironment get _elementEnvironment => _closedWorld.elementEnvironment;

  @override
  void registerTypeVariableBoundsSubtypeCheck(
      DartType typeArgument, DartType bound) {}

  @override
  RuntimeTypesChecks computeRequiredChecks(
      CodegenWorldBuilder codegenWorldBuilder) {
    Set<ClassEntity> classes = _closedWorld
        .getClassSet(_closedWorld.commonElements.objectClass)
        .subtypes()
        .toSet();
    rtiChecksBuilderClosed = true;
    TypeChecks typeChecks = _substitutions._requiredChecks =
        _substitutions._computeChecks(classes, classes);
    return new TrivialTypesChecks(typeChecks);
  }

  Set<ClassEntity> computeCheckedClasses(
      CodegenWorldBuilder codegenWorldBuilder, Set<DartType> implicitIsChecks) {
    return _closedWorld
        .getClassSet(_closedWorld.commonElements.objectClass)
        .subtypes()
        .toSet();
  }

  Set<FunctionType> computeCheckedFunctions(
      CodegenWorldBuilder codegenWorldBuilder, Set<DartType> implicitIsChecks) {
    return new Set<FunctionType>();
  }
}

class ClassCollector extends ArgumentCollector {
  final ElementEnvironment _elementEnvironment;

  ClassCollector(this._elementEnvironment);

  void addClass(ClassEntity cls) {
    if (classes.add(cls)) {
      _elementEnvironment.forEachSupertype(cls, (InterfaceType type) {
        collect(type, isTypeArgument: true);
      });
    }
  }
}

abstract class RuntimeTypesSubstitutionsMixin
    implements RuntimeTypesSubstitutions {
  ElementEnvironment get _elementEnvironment;
  DartTypes get _types;
  TypeChecks get _requiredChecks;

  TypeChecks _computeChecks(
      Iterable<ClassEntity> instantiated, Iterable<ClassEntity> checked) {
    // Run through the combination of instantiated and checked
    // arguments and record all combination where the element of a checked
    // argument is a superclass of the element of an instantiated type.
    TypeCheckMapping result = new TypeCheckMapping();
    for (ClassEntity element in instantiated) {
      if (checked.contains(element)) {
        result.add(element, element, null);
      }
      // Find all supertypes of [element] in [checkedArguments] and add checks
      // and precompute the substitutions for them.
      for (InterfaceType supertype in _types.getSupertypes(element)) {
        ClassEntity superelement = supertype.element;
        if (checked.contains(superelement)) {
          Substitution substitution =
              computeSubstitution(element, superelement);
          result.add(element, superelement, substitution);
        }
      }
    }
    return result;
  }

  @override
  Set<ClassEntity> getClassesUsedInSubstitutions(TypeChecks checks) {
    Set<ClassEntity> instantiated = new Set<ClassEntity>();
    ArgumentCollector collector = new ArgumentCollector();
    for (ClassEntity target in checks.classes) {
      instantiated.add(target);
      for (TypeCheck check in checks[target]) {
        Substitution substitution = check.substitution;
        if (substitution != null) {
          collector.collectAll(substitution.arguments);
        }
      }
    }
    return instantiated..addAll(collector.classes);

    // TODO(sra): This computation misses substitutions for reading type
    // parameters.
  }

  // TODO(karlklose): maybe precompute this value and store it in typeChecks?
  @override
  bool isTrivialSubstitution(ClassEntity cls, ClassEntity check) {
    if (cls.isClosure) {
      // TODO(karlklose): handle closures.
      return true;
    }

    // If there are no type variables or the type is the same, we do not need
    // a substitution.
    if (!_elementEnvironment.isGenericClass(check) || cls == check) {
      return true;
    }

    InterfaceType originalType = _elementEnvironment.getThisType(cls);
    InterfaceType type = _types.asInstanceOf(originalType, check);
    // [type] is not a subtype of [check]. we do not generate a check and do not
    // need a substitution.
    if (type == null) return true;

    // Run through both lists of type variables and check if the type variables
    // are identical at each position. If they are not, we need to calculate a
    // substitution function.
    List<DartType> variables = originalType.typeArguments;
    List<DartType> arguments = type.typeArguments;
    if (variables.length != arguments.length) {
      return false;
    }
    for (int index = 0; index < variables.length; index++) {
      if (variables[index] != arguments[index]) {
        return false;
      }
    }
    return true;
  }

  @override
  Substitution getSubstitution(ClassEntity cls, ClassEntity other) {
    // Look for a precomputed check.
    for (TypeCheck check in _requiredChecks[cls]) {
      if (check.cls == other) {
        return check.substitution;
      }
    }
    // There is no precomputed check for this pair (because the check is not
    // done on type arguments only.  Compute a new substitution.
    return computeSubstitution(cls, other);
  }

  Substitution computeSubstitution(ClassEntity cls, ClassEntity check,
      {bool alwaysGenerateFunction: false}) {
    if (isTrivialSubstitution(cls, check)) return null;

    // Unnamed mixin application classes do not need substitutions, because they
    // are never instantiated and their checks are overwritten by the class that
    // they are mixed into.
    InterfaceType type = _elementEnvironment.getThisType(cls);
    InterfaceType target = _types.asInstanceOf(type, check);
    List<DartType> typeVariables = type.typeArguments;
    if (typeVariables.isEmpty && !alwaysGenerateFunction) {
      return new Substitution.list(target.typeArguments);
    } else {
      return new Substitution.function(target.typeArguments, typeVariables);
    }
  }
}

class TrivialRuntimeTypesSubstitutions extends RuntimeTypesSubstitutionsMixin {
  final ElementEnvironment _elementEnvironment;
  final DartTypes _types;
  TypeChecks _requiredChecks;

  TrivialRuntimeTypesSubstitutions(this._elementEnvironment, this._types);

  @override
  TypeChecks computeChecks(
      Iterable<ClassEntity> instantiated, Iterable<ClassEntity> checked) {
    return _requiredChecks;
  }
}

/// Interface for computing substitutions need for runtime type checks.
abstract class RuntimeTypesSubstitutions {
  bool isTrivialSubstitution(ClassEntity cls, ClassEntity check);

  Substitution getSubstitution(ClassEntity cls, ClassEntity other);

  /// Compute the required type checks and substitutions for the given
  /// instantiated and checked classes.
  TypeChecks computeChecks(
      Iterable<ClassEntity> instantiated, Iterable<ClassEntity> checked);

  Set<ClassEntity> getClassesUsedInSubstitutions(TypeChecks checks);

  static bool hasTypeArguments(DartType type) {
    if (type is InterfaceType) {
      InterfaceType interfaceType = type;
      return !interfaceType.treatAsRaw;
    }
    return false;
  }
}

abstract class RuntimeTypesEncoder {
  bool isSimpleFunctionType(FunctionType type);

  jsAst.Expression getSignatureEncoding(
      Emitter emitter, DartType type, jsAst.Expression this_);

  jsAst.Expression getSubstitutionRepresentation(
      Emitter emitter, List<DartType> types, OnVariableCallback onVariable);
  jsAst.Expression getSubstitutionCode(
      Emitter emitter, Substitution substitution);

  /// Returns the JavaScript template to determine at runtime if a type object
  /// is a function type.
  jsAst.Template get templateForIsFunctionType;

  jsAst.Name get getFunctionThatReturnsNullName;

  /// Returns a [jsAst.Expression] representing the given [type]. Type variables
  /// are replaced by the [jsAst.Expression] returned by [onVariable].
  jsAst.Expression getTypeRepresentation(
      Emitter emitter, DartType type, OnVariableCallback onVariable,
      [ShouldEncodeTypedefCallback shouldEncodeTypedef]);

  String getTypeRepresentationForTypeConstant(DartType type);
}

/// Common functionality for [_RuntimeTypesNeedBuilder] and [_RuntimeTypes].
abstract class _RuntimeTypesBase {
  final DartTypes _types;

  _RuntimeTypesBase(this._types);

  /**
   * Compute type arguments of classes that use one of their type variables in
   * is-checks and add the is-checks that they imply.
   *
   * This function must be called after all is-checks have been registered.
   *
   * TODO(karlklose): move these computations into a function producing an
   * immutable datastructure.
   */
  void registerImplicitChecks(
      Set<InterfaceType> instantiatedTypes,
      Iterable<ClassEntity> classesUsingChecks,
      Set<DartType> implicitIsChecks) {
    // If there are no classes that use their variables in checks, there is
    // nothing to do.
    if (classesUsingChecks.isEmpty) return;
    // Find all instantiated types that are a subtype of a class that uses
    // one of its type arguments in an is-check and add the arguments to the
    // set of is-checks.
    for (InterfaceType type in instantiatedTypes) {
      for (ClassEntity cls in classesUsingChecks) {
        // We need the type as instance of its superclass anyway, so we just
        // try to compute the substitution; if the result is [:null:], the
        // classes are not related.
        InterfaceType instance = _types.asInstanceOf(type, cls);
        if (instance != null) {
          for (DartType argument in instance.typeArguments) {
            implicitIsChecks.add(argument.unaliased);
          }
        }
      }
    }
  }
}

class RuntimeTypesNeedImpl implements RuntimeTypesNeed {
  final ElementEnvironment _elementEnvironment;
  final BackendUsage _backendUsage;
  final Set<ClassEntity> classesNeedingTypeArguments;
  final Set<FunctionEntity> methodsNeedingSignature;
  final Set<FunctionEntity> methodsNeedingTypeArguments;
  final Set<Local> localFunctionsNeedingSignature;
  final Set<Local> localFunctionsNeedingTypeArguments;

  /// The set of classes that use one of their type variables as literals.
  final Set<ClassEntity> classesUsingTypeVariableLiterals;

  RuntimeTypesNeedImpl(
      this._elementEnvironment,
      this._backendUsage,
      this.classesNeedingTypeArguments,
      this.methodsNeedingSignature,
      this.methodsNeedingTypeArguments,
      this.localFunctionsNeedingSignature,
      this.localFunctionsNeedingTypeArguments,
      this.classesUsingTypeVariableLiterals);

  bool checkClass(covariant ClassEntity cls) => true;

  bool classNeedsTypeArguments(ClassEntity cls) {
    assert(checkClass(cls));
    if (!_elementEnvironment.isGenericClass(cls)) return false;
    if (_backendUsage.isRuntimeTypeUsed) return true;
    return classesNeedingTypeArguments.contains(cls);
  }

  bool methodNeedsSignature(FunctionEntity function) {
    return _backendUsage.isRuntimeTypeUsed ||
        methodsNeedingSignature.contains(function);
  }

  bool methodNeedsTypeArguments(FunctionEntity function) {
    if (function.parameterStructure.typeParameters == 0) return false;
    if (_backendUsage.isRuntimeTypeUsed) return true;
    return methodsNeedingTypeArguments.contains(function);
  }

  bool localFunctionNeedsSignature(Local function) {
    if (localFunctionsNeedingSignature == null) {
      // [localFunctionNeedsRti] is only used by the old frontend.
      throw new UnsupportedError('RuntimeTypesNeed.localFunctionsNeedingRti');
    }
    return localFunctionsNeedingSignature.contains(function) ||
        _backendUsage.isRuntimeTypeUsed;
  }

  @override
  bool classUsesTypeVariableLiteral(ClassEntity cls) {
    return classesUsingTypeVariableLiterals.contains(cls);
  }
}

class _ResolutionRuntimeTypesNeed extends RuntimeTypesNeedImpl {
  _ResolutionRuntimeTypesNeed(
      ElementEnvironment elementEnvironment,
      BackendUsage backendUsage,
      Set<ClassEntity> classesNeedingTypeArguments,
      Set<FunctionEntity> methodsNeedingSignature,
      Set<FunctionEntity> methodsNeedingTypeArguments,
      Set<Local> localFunctionsNeedingSignature,
      Set<Local> localFunctionsNeedingTypeArguments,
      Set<ClassEntity> classesUsingTypeVariableExpression)
      : super(
            elementEnvironment,
            backendUsage,
            classesNeedingTypeArguments,
            methodsNeedingSignature,
            methodsNeedingTypeArguments,
            localFunctionsNeedingSignature,
            localFunctionsNeedingTypeArguments,
            classesUsingTypeVariableExpression);

  bool checkClass(ClassElement cls) => cls.isDeclaration;
}

class TypeVariableTests {
  List<RtiNode> _nodes = <RtiNode>[];
  Map<ClassEntity, ClassNode> _classes = <ClassEntity, ClassNode>{};
  Map<Entity, MethodNode> _methods = <Entity, MethodNode>{};

  /// All explicit is-tests.
  final Set<DartType> explicitIsChecks;

  /// All implicit is-tests.
  final Set<DartType> implicitIsChecks = new Set<DartType>();

  /// Classes whose type variables are explicitly or implicitly used in
  /// is-tests.
  ///
  /// For instance `A` and `B` in:
  ///
  ///     class A<T> {
  ///       m(o) => o is T;
  ///     }
  ///     class B<S> {
  ///       m(o) => new A<S>().m(o);
  ///     }
  ///     main() => new B<int>().m(0);
  ///
  Iterable<ClassEntity> get classTests =>
      _classes.values.where((n) => n.hasTest).map((n) => n.cls).toSet();

  /// Classes that explicitly use their type variables in is-tests.
  ///
  /// For instance `A` in:
  ///
  ///     class A<T> {
  ///       m(o) => o is T;
  ///     }
  ///     main() => new A<int>().m(0);
  ///
  Iterable<ClassEntity> get directClassTests =>
      _classes.values.where((n) => n.hasDirectTest).map((n) => n.cls).toSet();

  /// Methods that explicitly or implicitly use their type variables in
  /// is-tests.
  ///
  /// For instance `m1` and `m2`in:
  ///
  ///     m1<T>(o) => o is T;
  ///     m2<S>(o) => m1<S>(o);
  ///     main() => m2<int>(0);
  ///
  Iterable<Entity> get methodTests =>
      _methods.values.where((n) => n.hasTest).map((n) => n.function).toSet();

  /// Methods that explicitly use their type variables in is-tests.
  ///
  /// For instance `m` in:
  ///
  ///     m<T>(o) => o is T;
  ///     main() => m<int>(0);
  ///
  Iterable<Entity> get directMethodTests => _methods.values
      .where((n) => n.hasDirectTest)
      .map((n) => n.function)
      .toSet();

  /// The entities that need type arguments at runtime if the 'key entity' needs
  /// type arguments.
  ///
  /// For instance:
  ///
  ///     class A<T> {
  ///       m() => new B<T>();
  ///     }
  ///     class B<T> {}
  ///     main() => new A<String>().m() is B<int>;
  ///
  /// Here `A` need type arguments at runtime because the key entity `B` needs
  /// it in order to generate the check against `B<int>`.
  ///
  /// This can also involve generic methods:
  ///
  ///    class A<T> {}
  ///    method<T>() => new A<T>();
  ///    main() => method<int>() is A<int>();
  ///
  /// Here `method` need type arguments at runtime because the key entity `A`
  /// needs it in order to generate the check against `A<int>`.
  ///
  Iterable<Entity> getTypeArgumentDependencies(Entity entity) {
    Iterable<RtiNode> dependencies;
    if (entity is ClassEntity) {
      dependencies = _classes[entity]?.dependencies;
    } else {
      dependencies = _methods[entity]?.dependencies;
    }
    if (dependencies == null) return const <Entity>[];
    return dependencies.map((n) => n.entity).toSet();
  }

  TypeVariableTests(ElementEnvironment elementEnvironment,
      CommonElements commonElements, DartTypes types, WorldBuilder worldBuilder)
      : explicitIsChecks = new Set<DartType>.from(worldBuilder.isChecks) {
    ClassNode getClassNode(ClassEntity cls) {
      return _classes.putIfAbsent(cls, () {
        ClassNode node = new ClassNode(cls);
        _nodes.add(node);
        return node;
      });
    }

    MethodNode getMethodNode(Entity function) {
      return _methods.putIfAbsent(function, () {
        MethodNode node;
        if (function is FunctionEntity) {
          Name instanceName;
          bool isCallTarget;
          if (function.isInstanceMember) {
            isCallTarget = worldBuilder.closurizedMembers.contains(function);
            instanceName = function.memberName;
          } else {
            isCallTarget = worldBuilder.closurizedStatics.contains(function);
          }
          node = new MethodNode(function, function.parameterStructure,
              isCallTarget: isCallTarget, instanceName: instanceName);
        } else {
          ParameterStructure parameterStructure =
              new ParameterStructure.fromType(
                  elementEnvironment.getLocalFunctionType(function));
          node =
              new MethodNode(function, parameterStructure, isCallTarget: true);
        }
        _nodes.add(node);
        return node;
      });
    }

    void registerDependencies(RtiNode node, DartType type) {
      type.forEachTypeVariable((TypeVariableType typeVariable) {
        Entity typeDeclaration = typeVariable.element.typeDeclaration;
        if (typeDeclaration is ClassEntity) {
          node.addDependency(getClassNode(typeDeclaration));
        } else {
          node.addDependency(getMethodNode(typeDeclaration));
        }
      });
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
    if (commonElements.jsArrayClass != null) {
      getClassNode(commonElements.jsArrayClass)
          .addDependency(getClassNode(commonElements.listClass));
    }
    if (commonElements.mapLiteralClass != null) {
      getClassNode(commonElements.mapLiteralClass)
          .addDependency(getClassNode(commonElements.mapClass));
    }

    worldBuilder.isChecks.forEach((DartType type) {
      if (type is InterfaceType) {
        registerDependencies(getClassNode(type.element), type);
      }
    });
    worldBuilder.instantiatedTypes.forEach((InterfaceType type) {
      registerDependencies(getClassNode(type.element), type);
    });

    worldBuilder.forEachStaticTypeArgument(
        (Entity entity, Iterable<DartType> typeArguments) {
      for (DartType type in typeArguments) {
        registerDependencies(getMethodNode(entity), type);
      }
    });

    worldBuilder.forEachDynamicTypeArgument(
        (Selector selector, Iterable<DartType> typeArguments) {
      for (DartType type in typeArguments) {
        // TODO(johnniwinther): Ensure that methods added here will be
        // processed for matching selectors.
        for (MethodNode method in _methods.values.toList()) {
          if (method.selectorApplies(selector)) {
            registerDependencies(method, type);
          }
        }
      }
    });

    worldBuilder.isChecks.forEach((DartType type) {
      if (type.isTypeVariable) {
        TypeVariableType typeVariableType = type;
        TypeVariableEntity variable = typeVariableType.element;
        if (variable.typeDeclaration is ClassEntity) {
          getClassNode(variable.typeDeclaration).markDirectTest();
        } else {
          getMethodNode(variable.typeDeclaration).markDirectTest();
        }
      }
    });

    // Compute type arguments of classes that use one of their type variables in
    // is-checks and add the is-checks that they imply.
    _classes.forEach((ClassEntity cls, ClassNode node) {
      if (!node.hasTest) return;
      // Find all instantiated types that are a subtype of a class that uses
      // one of its type arguments in an is-check and add the arguments to the
      // set of is-checks.
      for (InterfaceType type in worldBuilder.instantiatedTypes) {
        // We need the type as instance of its superclass anyway, so we just
        // try to compute the substitution; if the result is [:null:], the
        // classes are not related.
        InterfaceType instance = types.asInstanceOf(type, cls);
        if (instance != null) {
          for (DartType argument in instance.typeArguments) {
            implicitIsChecks.add(argument.unaliased);
          }
        }
      }
    });

    worldBuilder.forEachStaticTypeArgument(
        (Entity function, Iterable<DartType> typeArguments) {
      if (!getMethodNode(function).hasTest) return;
      implicitIsChecks.addAll(typeArguments);
    });
    worldBuilder.forEachDynamicTypeArgument(
        (Selector selector, Iterable<DartType> typeArguments) {
      for (MethodNode node in _methods.values) {
        if (!node.hasTest) continue;
        if (node.selectorApplies(selector)) {
          implicitIsChecks.addAll(typeArguments);
        }
      }
    });
  }

  String dump({bool verbose: false}) {
    StringBuffer sb = new StringBuffer();

    void addNode(RtiNode node) {
      if (node._testState != 0 || node.dependencies.isNotEmpty || verbose) {
        sb.write(' $node');
        if (node._testState & 1 != 0) {
          sb.write(' direct');
        }
        if (node._testState & 2 != 0) {
          sb.write(' indirect');
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
}

abstract class RtiNode {
  Entity get entity;
  Set<RtiNode> _dependencies;
  int _testState = 0;

  Iterable<RtiNode> get dependencies => _dependencies ?? const <RtiNode>[];

  bool get hasDirectTest => _testState & 1 != 0;
  bool get hasIndirectTest => _testState & 2 != 0;

  bool get hasTest => _testState != 0;

  bool addDependency(RtiNode node) {
    if (entity == node.entity) {
      // Skip trivial dependencies; if [entity] needs type arguments so does
      // [entity]!
      return false;
    }
    _dependencies ??= new Set<RtiNode>();
    return _dependencies.add(node);
  }

  void markDirectTest() {
    setTestState(1);
  }

  void markIndirectTest() {
    setTestState(2);
  }

  void setTestState(int value) {
    if (_testState != value) {
      if (_testState == 0) {
        _testState |= value;
        if (_dependencies != null) {
          for (RtiNode node in _dependencies) {
            node.markIndirectTest();
          }
        }
      } else {
        _testState = value;
      }
    }
  }

  String get kind;

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(kind);
    sb.write(':');
    sb.write(entity);
    return sb.toString();
  }
}

class ClassNode extends RtiNode {
  final ClassEntity cls;

  ClassNode(this.cls);

  Entity get entity => cls;

  String get kind => 'class';
}

class MethodNode extends RtiNode {
  final Entity function;
  final ParameterStructure parameterStructure;
  final bool isCallTarget;
  final Name instanceName;

  MethodNode(this.function, this.parameterStructure,
      {this.isCallTarget, this.instanceName});

  Entity get entity => function;

  bool selectorApplies(Selector selector) {
    return (isCallTarget && selector.isClosureCall ||
            instanceName == selector.memberName) &&
        selector.callStructure.signatureApplies(parameterStructure);
  }

  String get kind => 'method';
}

class RuntimeTypesNeedBuilderImpl extends _RuntimeTypesBase
    implements RuntimeTypesNeedBuilder {
  final ElementEnvironment _elementEnvironment;

  final Set<ClassEntity> classesUsingTypeVariableLiterals =
      new Set<ClassEntity>();

  final Set<FunctionEntity> methodsUsingTypeVariableLiterals =
      new Set<FunctionEntity>();

  final Set<Local> localFunctionsUsingTypeVariableLiterals = new Set<Local>();

  TypeVariableTests typeVariableTests;

  RuntimeTypesNeedBuilderImpl(this._elementEnvironment, DartTypes types)
      : super(types);

  bool checkClass(covariant ClassEntity cls) => true;

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
  RuntimeTypesNeed computeRuntimeTypesNeed(
      ResolutionWorldBuilder resolutionWorldBuilder, ClosedWorld closedWorld,
      {bool enableTypeAssertions}) {
    typeVariableTests = new TypeVariableTests(
        closedWorld.elementEnvironment,
        closedWorld.commonElements,
        closedWorld.dartTypes,
        resolutionWorldBuilder);
    Set<ClassEntity> classesNeedingTypeArguments = new Set<ClassEntity>();
    Set<FunctionEntity> methodsNeedingSignature = new Set<FunctionEntity>();
    Set<FunctionEntity> methodsNeedingTypeArguments = new Set<FunctionEntity>();
    Set<Local> localFunctionsNeedingSignature = new Set<Local>();
    Set<Local> localFunctionsNeedingTypeArguments = new Set<Local>();

    // Find the classes that need type arguments at runtime. Such
    // classes are:
    // (1) used in an is check with type variables,
    // (2) dependencies of classes in (1),
    // (3) subclasses of (2) and (3).
    void potentiallyNeedTypeArguments(Entity entity) {
      if (entity is ClassEntity) {
        ClassEntity cls = entity;
        assert(checkClass(cls));
        if (!_elementEnvironment.isGenericClass(cls)) return;
        if (classesNeedingTypeArguments.contains(cls)) return;
        classesNeedingTypeArguments.add(cls);

        // TODO(ngeoffray): This should use subclasses, not subtypes.
        closedWorld.forEachStrictSubtypeOf(cls, (ClassEntity sub) {
          potentiallyNeedTypeArguments(sub);
        });
      } else if (entity is FunctionEntity) {
        methodsNeedingTypeArguments.add(entity);
      } else {
        localFunctionsNeedingTypeArguments.add(entity);
      }

      Iterable<Entity> dependencies =
          typeVariableTests.getTypeArgumentDependencies(entity);
      dependencies.forEach((Entity other) {
        potentiallyNeedTypeArguments(other);
      });
    }

    // Check local functions and closurized members.
    void checkClosures({DartType potentialSubtypeOf}) {
      bool checkFunctionType(FunctionType functionType) {
        ClassEntity contextClass = DartTypes.getClassContext(functionType);
        if (contextClass != null &&
            (potentialSubtypeOf == null ||
                closedWorld.dartTypes
                    .isPotentialSubtype(functionType, potentialSubtypeOf))) {
          potentiallyNeedTypeArguments(contextClass);
          return true;
        }
        return false;
      }

      for (Local function
          in resolutionWorldBuilder.localFunctionsWithFreeTypeVariables) {
        if (checkFunctionType(
            _elementEnvironment.getLocalFunctionType(function))) {
          localFunctionsNeedingSignature.add(function);
        }
      }
      for (FunctionEntity function
          in resolutionWorldBuilder.closurizedMembersWithFreeTypeVariables) {
        if (checkFunctionType(_elementEnvironment.getFunctionType(function))) {
          methodsNeedingSignature.add(function);
        }
      }
    }

    // Compute the set of all classes and methods that need runtime type
    // information.

    void processChecks(Set<DartType> checks) {
      checks.forEach((DartType type) {
        if (type.isInterfaceType) {
          InterfaceType itf = type;
          if (!itf.treatAsRaw) {
            potentiallyNeedTypeArguments(itf.element);
          }
        } else {
          type.forEachTypeVariable((TypeVariableType typeVariable) {
            // This handles checks against type variables and function types
            // containing type variables.
            Entity typeDeclaration = typeVariable.element.typeDeclaration;
            potentiallyNeedTypeArguments(typeDeclaration);
          });
          if (type.isFunctionType) {
            checkClosures(potentialSubtypeOf: type);
          }
        }
      });
    }

    processChecks(typeVariableTests.explicitIsChecks);
    processChecks(typeVariableTests.implicitIsChecks);

    if (enableTypeAssertions) {
      checkClosures();
    }

    // Add the classes, methods and local functions that need type arguments
    // because they use a type variable as a literal.
    classesUsingTypeVariableLiterals.forEach(potentiallyNeedTypeArguments);
    methodsUsingTypeVariableLiterals.forEach(potentiallyNeedTypeArguments);
    localFunctionsUsingTypeVariableLiterals
        .forEach(potentiallyNeedTypeArguments);

    return _createRuntimeTypesNeed(
        _elementEnvironment,
        closedWorld.backendUsage,
        classesNeedingTypeArguments,
        methodsNeedingSignature,
        methodsNeedingTypeArguments,
        localFunctionsNeedingSignature,
        localFunctionsNeedingTypeArguments,
        classesUsingTypeVariableLiterals);
  }

  RuntimeTypesNeed _createRuntimeTypesNeed(
      ElementEnvironment elementEnvironment,
      BackendUsage backendUsage,
      Set<ClassEntity> classesNeedingTypeArguments,
      Set<FunctionEntity> methodsNeedingSignature,
      Set<FunctionEntity> methodsNeedingTypeArguments,
      Set<Local> localFunctionsNeedingSignature,
      Set<Local> localFunctionsNeedingTypeArguments,
      Set<ClassEntity> classesUsingTypeVariableExpression) {
    return new RuntimeTypesNeedImpl(
        _elementEnvironment,
        backendUsage,
        classesNeedingTypeArguments,
        methodsNeedingSignature,
        methodsNeedingTypeArguments,
        localFunctionsNeedingSignature,
        localFunctionsNeedingTypeArguments,
        classesUsingTypeVariableExpression);
  }
}

class ResolutionRuntimeTypesNeedBuilderImpl
    extends RuntimeTypesNeedBuilderImpl {
  ResolutionRuntimeTypesNeedBuilderImpl(
      ElementEnvironment elementEnvironment, DartTypes types)
      : super(elementEnvironment, types);

  bool checkClass(ClassElement cls) => cls.isDeclaration;

  RuntimeTypesNeed _createRuntimeTypesNeed(
      ElementEnvironment elementEnvironment,
      BackendUsage backendUsage,
      Set<ClassEntity> classesNeedingTypeArguments,
      Set<FunctionEntity> methodsNeedingSignature,
      Set<FunctionEntity> methodsNeedingTypeArguments,
      Set<Local> localFunctionsNeedingSignature,
      Set<Local> localFunctionsNeedingTypeArguments,
      Set<ClassEntity> classesUsingTypeVariableExpression) {
    return new _ResolutionRuntimeTypesNeed(
        _elementEnvironment,
        backendUsage,
        classesNeedingTypeArguments,
        methodsNeedingSignature,
        methodsNeedingTypeArguments,
        localFunctionsNeedingSignature,
        localFunctionsNeedingTypeArguments,
        classesUsingTypeVariableExpression);
  }
}

class _RuntimeTypesChecks implements RuntimeTypesChecks {
  final RuntimeTypesSubstitutions substitutions;
  final TypeChecks requiredChecks;
  final Iterable<ClassEntity> directlyInstantiatedArguments;
  final Iterable<ClassEntity> checkedArguments;
  final Iterable<ClassEntity> checkedClasses;
  final Iterable<FunctionType> checkedFunctionTypes;
  final TypeVariableTests typeVariableTests;

  _RuntimeTypesChecks(
      this.substitutions,
      this.requiredChecks,
      this.directlyInstantiatedArguments,
      this.checkedArguments,
      this.checkedClasses,
      this.checkedFunctionTypes,
      this.typeVariableTests);

  @override
  Iterable<ClassEntity> getRequiredArgumentClasses() {
    Set<ClassEntity> requiredArgumentClasses = new Set<ClassEntity>.from(
        substitutions.getClassesUsedInSubstitutions(requiredChecks));
    return requiredArgumentClasses
      ..addAll(directlyInstantiatedArguments)
      ..addAll(checkedArguments);
  }

  @override
  Iterable<ClassEntity> getReferencedClasses(FunctionType type) {
    FunctionArgumentCollector collector = new FunctionArgumentCollector();
    collector.collect(type);
    return collector.classes;
  }

  @override
  Iterable<ClassEntity> get classesUsingTypeVariableTests =>
      typeVariableTests.classTests;
}

class RuntimeTypesImpl extends _RuntimeTypesBase
    with RuntimeTypesSubstitutionsMixin
    implements RuntimeTypesChecksBuilder {
  final CommonElements _commentElements;
  final ElementEnvironment _elementEnvironment;

  // The set of type arguments tested against type variable bounds.
  final Set<DartType> checkedTypeArguments = new Set<DartType>();
  // The set of tested type variable bounds.
  final Set<DartType> checkedBounds = new Set<DartType>();

  TypeChecks cachedRequiredChecks;

  bool rtiChecksBuilderClosed = false;

  RuntimeTypesImpl(
      this._commentElements, this._elementEnvironment, DartTypes types)
      : super(types);

  @override
  TypeChecks get _requiredChecks => cachedRequiredChecks;

  Set<ClassEntity> directlyInstantiatedArguments;
  Set<ClassEntity> allInstantiatedArguments;

  @override
  void registerTypeVariableBoundsSubtypeCheck(
      DartType typeArgument, DartType bound) {
    checkedTypeArguments.add(typeArgument);
    checkedBounds.add(bound);
  }

  RuntimeTypesChecks computeRequiredChecks(
      CodegenWorldBuilder codegenWorldBuilder) {
    TypeVariableTests typeVariableTests = new TypeVariableTests(
        _elementEnvironment, _commentElements, _types, codegenWorldBuilder);
    Set<DartType> explicitIsChecks = typeVariableTests.explicitIsChecks;
    Set<DartType> implicitIsChecks = typeVariableTests.implicitIsChecks;

    Set<ClassEntity> checkedClasses = new Set<ClassEntity>();
    Set<FunctionType> checkedFunctionTypes = new Set<FunctionType>();

    void processType(DartType t) {
      if (t is FunctionType) {
        checkedFunctionTypes.add(t);
      } else if (t is InterfaceType) {
        checkedClasses.add(t.element);
      }
    }

    explicitIsChecks.forEach(processType);
    implicitIsChecks.forEach(processType);

    // These types are needed for is-checks against function types.
    Set<DartType> instantiatedTypesAndClosures =
        computeInstantiatedTypesAndClosures(codegenWorldBuilder);
    computeInstantiatedArguments(
        instantiatedTypesAndClosures, explicitIsChecks, implicitIsChecks);
    Set<ClassEntity> checkedArguments = computeCheckedArguments(
        instantiatedTypesAndClosures, explicitIsChecks, implicitIsChecks);
    cachedRequiredChecks =
        computeChecks(allInstantiatedArguments, checkedArguments);
    rtiChecksBuilderClosed = true;
    return new _RuntimeTypesChecks(
        this,
        cachedRequiredChecks,
        directlyInstantiatedArguments,
        checkedArguments,
        checkedClasses,
        checkedFunctionTypes,
        typeVariableTests);
  }

  Set<DartType> computeInstantiatedTypesAndClosures(
      CodegenWorldBuilder codegenWorldBuilder) {
    Set<DartType> instantiatedTypes =
        new Set<DartType>.from(codegenWorldBuilder.instantiatedTypes);
    for (InterfaceType instantiatedType
        in codegenWorldBuilder.instantiatedTypes) {
      FunctionType callType = _types.getCallType(instantiatedType);
      if (callType != null) {
        instantiatedTypes.add(callType);
      }
    }
    for (FunctionEntity element
        in codegenWorldBuilder.staticFunctionsNeedingGetter) {
      instantiatedTypes.add(_elementEnvironment.getFunctionType(element));
    }

    for (FunctionEntity element in codegenWorldBuilder.closurizedMembers) {
      instantiatedTypes.add(_elementEnvironment.getFunctionType(element));
    }
    return instantiatedTypes;
  }

  /**
   * Collects all types used in type arguments of instantiated types.
   *
   * This includes type arguments used in supertype relations, because we may
   * have a type check against this supertype that includes a check against
   * the type arguments.
   */
  void computeInstantiatedArguments(Set<DartType> instantiatedTypes,
      Set<DartType> isChecks, Set<DartType> implicitIsChecks) {
    ArgumentCollector superCollector = new ArgumentCollector();
    ArgumentCollector directCollector = new ArgumentCollector();
    FunctionArgumentCollector functionArgumentCollector =
        new FunctionArgumentCollector();

    // We need to add classes occurring in function type arguments, like for
    // instance 'I' for [: o is C<f> :] where f is [: typedef I f(); :].
    void collectFunctionTypeArguments(Iterable<DartType> types) {
      for (DartType type in types) {
        functionArgumentCollector.collect(type);
      }
    }

    collectFunctionTypeArguments(isChecks);
    collectFunctionTypeArguments(implicitIsChecks);
    collectFunctionTypeArguments(checkedBounds);

    void collectTypeArguments(Iterable<DartType> types,
        {bool isTypeArgument: false}) {
      for (DartType type in types) {
        directCollector.collect(type, isTypeArgument: isTypeArgument);
        if (type is InterfaceType) {
          ClassEntity cls = type.element;
          for (InterfaceType supertype in _types.getSupertypes(cls)) {
            superCollector.collect(supertype, isTypeArgument: isTypeArgument);
          }
        }
      }
    }

    collectTypeArguments(instantiatedTypes);
    collectTypeArguments(checkedTypeArguments, isTypeArgument: true);

    for (ClassEntity cls in superCollector.classes.toList()) {
      for (InterfaceType supertype in _types.getSupertypes(cls)) {
        superCollector.collect(supertype);
      }
    }

    directlyInstantiatedArguments = directCollector.classes
      ..addAll(functionArgumentCollector.classes);
    allInstantiatedArguments = superCollector.classes
      ..addAll(directlyInstantiatedArguments);
  }

  /// Collects all type arguments used in is-checks.
  Set<ClassEntity> computeCheckedArguments(Set<DartType> instantiatedTypes,
      Set<DartType> isChecks, Set<DartType> implicitIsChecks) {
    ArgumentCollector collector = new ArgumentCollector();
    FunctionArgumentCollector functionArgumentCollector =
        new FunctionArgumentCollector();

    // We need to add types occurring in function type arguments, like for
    // instance 'J' for [: (J j) {} is f :] where f is
    // [: typedef void f(I i); :] and 'J' is a subtype of 'I'.
    void collectFunctionTypeArguments(Iterable<DartType> types) {
      for (DartType type in types) {
        functionArgumentCollector.collect(type);
      }
    }

    collectFunctionTypeArguments(instantiatedTypes);
    collectFunctionTypeArguments(checkedTypeArguments);

    void collectTypeArguments(Iterable<DartType> types,
        {bool isTypeArgument: false}) {
      for (DartType type in types) {
        collector.collect(type, isTypeArgument: isTypeArgument);
      }
    }

    collectTypeArguments(isChecks);
    collectTypeArguments(implicitIsChecks);
    collectTypeArguments(checkedBounds, isTypeArgument: true);

    return collector.classes..addAll(functionArgumentCollector.classes);
  }

  @override
  TypeChecks computeChecks(
      Iterable<ClassEntity> instantiated, Iterable<ClassEntity> checked) {
    return _computeChecks(instantiated, checked);
  }
}

class RuntimeTypesEncoderImpl implements RuntimeTypesEncoder {
  final Namer namer;
  final ElementEnvironment _elementEnvironment;
  final CommonElements commonElements;
  final TypeRepresentationGenerator _representationGenerator;

  RuntimeTypesEncoderImpl(
      this.namer, this._elementEnvironment, this.commonElements)
      : _representationGenerator = new TypeRepresentationGenerator(namer);

  @override
  bool isSimpleFunctionType(FunctionType type) {
    if (!type.returnType.isDynamic) return false;
    if (!type.optionalParameterTypes.isEmpty) return false;
    if (!type.namedParameterTypes.isEmpty) return false;
    for (DartType parameter in type.parameterTypes) {
      if (!parameter.isDynamic) return false;
    }
    return true;
  }

  /// Returns the JavaScript template to determine at runtime if a type object
  /// is a function type.
  @override
  jsAst.Template get templateForIsFunctionType {
    return _representationGenerator.templateForIsFunctionType;
  }

  @override
  jsAst.Expression getTypeRepresentation(
      Emitter emitter, DartType type, OnVariableCallback onVariable,
      [ShouldEncodeTypedefCallback shouldEncodeTypedef]) {
    // GENERIC_METHODS: When generic method support is complete enough to
    // include a runtime value for method type variables this must be updated.
    return _representationGenerator.getTypeRepresentation(
        emitter, type, onVariable, shouldEncodeTypedef);
  }

  @override
  jsAst.Expression getSubstitutionRepresentation(
      Emitter emitter, List<DartType> types, OnVariableCallback onVariable) {
    List<jsAst.Expression> elements = types
        .map(
            (DartType type) => getTypeRepresentation(emitter, type, onVariable))
        .toList(growable: false);
    return new jsAst.ArrayInitializer(elements);
  }

  String getTypeVariableName(TypeVariableType type) {
    String name = type.element.name;
    return name.replaceAll('#', '_');
  }

  jsAst.Expression getTypeEncoding(Emitter emitter, DartType type,
      {bool alwaysGenerateFunction: false}) {
    ClassEntity contextClass = DartTypes.getClassContext(type);
    jsAst.Expression onVariable(TypeVariableType v) {
      return new jsAst.VariableUse(getTypeVariableName(v));
    }

    jsAst.Expression encoding =
        getTypeRepresentation(emitter, type, onVariable);
    if (contextClass == null && !alwaysGenerateFunction) {
      return encoding;
    } else {
      List<String> parameters = const <String>[];
      if (contextClass != null) {
        parameters = _elementEnvironment
            .getThisType(contextClass)
            .typeArguments
            .map((DartType _type) {
          TypeVariableType type = _type;
          return getTypeVariableName(type);
        }).toList();
      }
      return js('function(#) { return # }', [parameters, encoding]);
    }
  }

  @override
  jsAst.Expression getSignatureEncoding(
      Emitter emitter, DartType type, jsAst.Expression this_) {
    ClassEntity contextClass = DartTypes.getClassContext(type);
    jsAst.Expression encoding =
        getTypeEncoding(emitter, type, alwaysGenerateFunction: true);
    if (contextClass != null) {
      jsAst.Name contextName = namer.className(contextClass);
      return js('function () { return #(#, #, #); }', [
        emitter.staticFunctionAccess(commonElements.computeSignature),
        encoding,
        this_,
        js.quoteName(contextName)
      ]);
    } else {
      return encoding;
    }
  }

  /**
   * Compute a JavaScript expression that describes the necessary substitution
   * for type arguments in a subtype test.
   *
   * The result can be:
   *  1) `null`, if no substituted check is necessary, because the
   *     type variables are the same or there are no type variables in the class
   *     that is checked for.
   *  2) A list expression describing the type arguments to be used in the
   *     subtype check, if the type arguments to be used in the check do not
   *     depend on the type arguments of the object.
   *  3) A function mapping the type variables of the object to be checked to
   *     a list expression.
   */
  @override
  jsAst.Expression getSubstitutionCode(
      Emitter emitter, Substitution substitution) {
    jsAst.Expression declaration(TypeVariableType variable) {
      return new jsAst.Parameter(getVariableName(variable.element.name));
    }

    jsAst.Expression use(TypeVariableType variable) {
      return new jsAst.VariableUse(getVariableName(variable.element.name));
    }

    if (substitution.arguments.every((DartType type) => type.isDynamic)) {
      return emitter.generateFunctionThatReturnsNull();
    } else {
      jsAst.Expression value =
          getSubstitutionRepresentation(emitter, substitution.arguments, use);
      if (substitution.isFunction) {
        Iterable<jsAst.Expression> formals =
            // TODO(johnniwinther): Pass [declaration] directly to `map` when
            // `substitution.parameters` can no longer be a
            // `List<ResolutionDartType>`.
            substitution.parameters.map((type) => declaration(type));
        return js('function(#) { return # }', [formals, value]);
      } else {
        return js('function() { return # }', value);
      }
    }
  }

  String getVariableName(String name) {
    // Kernel type variable names for anonymous mixin applications have names
    // canonicalized to a non-identified, e.g. '#U0'.
    name = name.replaceAll('#', '_');
    return namer.safeVariableName(name);
  }

  @override
  jsAst.Name get getFunctionThatReturnsNullName =>
      namer.internalGlobal('functionThatReturnsNull');

  @override
  String getTypeRepresentationForTypeConstant(DartType type) {
    if (type.isDynamic) return "dynamic";
    if (type is TypedefType) {
      return namer.uniqueNameForTypeConstantElement(
          type.element.library, type.element);
    }
    if (type is FunctionType) {
      // TODO(johnniwinther): Add naming scheme for function type literals.
      // These currently only occur from kernel.
      return '()->';
    }
    InterfaceType interface = type;
    String name = namer.uniqueNameForTypeConstantElement(
        interface.element.library, interface.element);

    // Type constants can currently only be raw types, so there is no point
    // adding ground-term type parameters, as they would just be 'dynamic'.
    // TODO(sra): Since the result string is used only in constructing constant
    // names, it would result in more readable names if the final string was a
    // legal JavaScript identifier.
    if (interface.typeArguments.isEmpty) return name;
    String arguments =
        new List.filled(interface.typeArguments.length, 'dynamic').join(', ');
    return '$name<$arguments>';
  }
}

class TypeRepresentationGenerator
    implements ResolutionDartTypeVisitor<jsAst.Expression, Emitter> {
  final Namer namer;
  OnVariableCallback onVariable;
  ShouldEncodeTypedefCallback shouldEncodeTypedef;
  Map<TypeVariableType, jsAst.Expression> typedefBindings;
  List<FunctionTypeVariable> functionTypeVariables = <FunctionTypeVariable>[];

  TypeRepresentationGenerator(this.namer);

  /**
   * Creates a type representation for [type]. [onVariable] is called to provide
   * the type representation for type variables.
   */
  jsAst.Expression getTypeRepresentation(
      Emitter emitter,
      DartType type,
      OnVariableCallback onVariable,
      ShouldEncodeTypedefCallback encodeTypedef) {
    assert(typedefBindings == null);
    this.onVariable = onVariable;
    this.shouldEncodeTypedef = (encodeTypedef != null)
        ? encodeTypedef
        : (ResolutionTypedefType type) => false;
    jsAst.Expression representation = visit(type, emitter);
    this.onVariable = null;
    this.shouldEncodeTypedef = null;
    assert(functionTypeVariables.isEmpty);
    return representation;
  }

  jsAst.Expression getJavaScriptClassName(Entity element, Emitter emitter) {
    return emitter.typeAccess(element);
  }

  jsAst.Expression getDynamicValue() => js('null');

  @override
  jsAst.Expression visit(DartType type, Emitter emitter) =>
      type.accept(this, emitter);

  jsAst.Expression visitTypeVariableType(
      TypeVariableType type, Emitter emitter) {
    if (type.element.typeDeclaration is! ClassEntity) {
      /// A [TypeVariableType] from a generic method is replaced by a
      /// [DynamicType].
      /// GENERIC_METHODS: Temporary, only used with '--generic-method-syntax'.
      return getDynamicValue();
    }
    if (typedefBindings != null) {
      assert(typedefBindings[type] != null);
      return typedefBindings[type];
    }
    return onVariable(type);
  }

  jsAst.Expression visitFunctionTypeVariable(
      FunctionTypeVariable type, Emitter emitter) {
    int position = functionTypeVariables.indexOf(type);
    assert(position >= 0);
    return js.number(functionTypeVariables.length - position - 1);
  }

  jsAst.Expression visitDynamicType(DynamicType type, Emitter emitter) {
    return getDynamicValue();
  }

  jsAst.Expression visitInterfaceType(InterfaceType type, Emitter emitter) {
    jsAst.Expression name = getJavaScriptClassName(type.element, emitter);
    return type.treatAsRaw
        ? name
        : visitList(type.typeArguments, emitter, head: name);
  }

  jsAst.Expression visitList(List<DartType> types, Emitter emitter,
      {jsAst.Expression head}) {
    List<jsAst.Expression> elements = <jsAst.Expression>[];
    if (head != null) {
      elements.add(head);
    }
    for (DartType type in types) {
      jsAst.Expression element = visit(type, emitter);
      if (element is jsAst.LiteralNull) {
        elements.add(new jsAst.ArrayHole());
      } else {
        elements.add(element);
      }
    }
    return new jsAst.ArrayInitializer(elements);
  }

  /// Returns the JavaScript template to determine at runtime if a type object
  /// is a function type.
  jsAst.Template get templateForIsFunctionType {
    return jsAst.js.expressionTemplateFor("'${namer.functionTypeTag}' in #");
  }

  jsAst.Expression visitFunctionType(FunctionType type, Emitter emitter) {
    List<jsAst.Property> properties = <jsAst.Property>[];

    void addProperty(String name, jsAst.Expression value) {
      properties.add(new jsAst.Property(js.string(name), value));
    }

    // Type representations for functions have a property which is a tag marking
    // them as function types. The value is not used, so '1' is just a dummy.
    addProperty(namer.functionTypeTag, js.number(1));

    if (type.typeVariables.isNotEmpty) {
      // Generic function types have type parameters which are reduced to de
      // Bruijn indexes.
      for (FunctionTypeVariable variable in type.typeVariables.reversed) {
        functionTypeVariables.add(variable);
      }
      // TODO(sra): This emits `P.Object` for the common unbounded case. We
      // could replace the Object bounds with an array hole for a compact `[,,]`
      // representation.
      addProperty(namer.functionTypeGenericBoundsTag,
          visitList(type.typeVariables.map((v) => v.bound).toList(), emitter));
    }

    if (type.returnType.isVoid) {
      addProperty(namer.functionTypeVoidReturnTag, js('true'));
    } else if (!type.returnType.treatAsDynamic) {
      addProperty(
          namer.functionTypeReturnTypeTag, visit(type.returnType, emitter));
    }
    if (!type.parameterTypes.isEmpty) {
      addProperty(namer.functionTypeRequiredParametersTag,
          visitList(type.parameterTypes, emitter));
    }
    if (!type.optionalParameterTypes.isEmpty) {
      addProperty(namer.functionTypeOptionalParametersTag,
          visitList(type.optionalParameterTypes, emitter));
    }
    if (!type.namedParameterTypes.isEmpty) {
      List<jsAst.Property> namedArguments = <jsAst.Property>[];
      List<String> names = type.namedParameters;
      List<DartType> types = type.namedParameterTypes;
      assert(types.length == names.length);
      for (int index = 0; index < types.length; index++) {
        jsAst.Expression name = js.string(names[index]);
        namedArguments
            .add(new jsAst.Property(name, visit(types[index], emitter)));
      }
      addProperty(namer.functionTypeNamedParametersTag,
          new jsAst.ObjectInitializer(namedArguments));
    }

    // Exit generic function scope.
    if (type.typeVariables.isNotEmpty) {
      functionTypeVariables.length -= type.typeVariables.length;
    }

    return new jsAst.ObjectInitializer(properties);
  }

  jsAst.Expression visitMalformedType(MalformedType type, Emitter emitter) {
    // Treat malformed types as dynamic at runtime.
    return js('null');
  }

  jsAst.Expression visitVoidType(VoidType type, Emitter emitter) {
    // TODO(ahe): Reify void type ("null" means "dynamic").
    return js('null');
  }

  jsAst.Expression visitTypedefType(
      ResolutionTypedefType type, Emitter emitter) {
    bool shouldEncode = shouldEncodeTypedef(type);
    DartType unaliasedType = type.unaliased;

    var oldBindings = typedefBindings;
    if (typedefBindings == null) {
      // First level typedef - capture arguments for re-use within typedef body.
      //
      // The type `Map<T, Foo<Set<T>>>` contains one type variable referenced
      // twice, so there are two inputs into the HTypeInfoExpression
      // instruction.
      //
      // If Foo is a typedef, T can be reused, e.g.
      //
      //     typedef E Foo<E>(E a, E b);
      //
      // As the typedef is expanded (to (Set<T>, Set<T>) => Set<T>) it should
      // not consume additional types from the to-level input.  We prevent this
      // by capturing the types and using the captured type expressions inside
      // the typedef expansion.
      //
      // TODO(sra): We should make the type subexpression Foo<...> be a second
      // HTypeInfoExpression, with Set<T> as its input (a third
      // HTypeInfoExpression). This would share all the Set<T> subexpressions
      // instead of duplicating them. This would require HTypeInfoExpression
      // inputs to correspond to type variables AND typedefs.
      typedefBindings = <TypeVariableType, jsAst.Expression>{};
      type.forEachTypeVariable((TypeVariableType variable) {
        if (variable is! MethodTypeVariableType) {
          typedefBindings[variable] = onVariable(variable);
        }
      });
    }

    jsAst.Expression finish(jsAst.Expression result) {
      typedefBindings = oldBindings;
      return result;
    }

    if (shouldEncode) {
      jsAst.ObjectInitializer initializer = visit(unaliasedType, emitter);
      // We have to encode the aliased type.
      jsAst.Expression name = getJavaScriptClassName(type.element, emitter);
      jsAst.Expression encodedTypedef = type.treatAsRaw
          ? name
          : visitList(type.typeArguments, emitter, head: name);

      // Add it to the function-type object.
      jsAst.LiteralString tag = js.string(namer.typedefTag);
      initializer.properties.add(new jsAst.Property(tag, encodedTypedef));
      return finish(initializer);
    } else {
      return finish(visit(unaliasedType, emitter));
    }
  }
}

class TypeCheckMapping implements TypeChecks {
  final Map<ClassEntity, Set<TypeCheck>> map =
      new Map<ClassEntity, Set<TypeCheck>>();

  Iterable<TypeCheck> operator [](ClassEntity element) {
    Set<TypeCheck> result = map[element];
    return result != null ? result : const <TypeCheck>[];
  }

  void add(ClassEntity cls, ClassEntity check, Substitution substitution) {
    map.putIfAbsent(cls, () => new Set<TypeCheck>());
    map[cls].add(new TypeCheck(check, substitution));
  }

  Iterable<ClassEntity> get classes => map.keys;

  String toString() {
    StringBuffer sb = new StringBuffer();
    for (ClassEntity holder in classes) {
      for (TypeCheck check in this[holder]) {
        sb.write('${holder.name} <: ${check.cls.name}, ');
      }
    }
    return '[$sb]';
  }
}

class ArgumentCollector extends ResolutionDartTypeVisitor<dynamic, bool> {
  final Set<ClassEntity> classes = new Set<ClassEntity>();

  void addClass(ClassEntity cls) {
    classes.add(cls);
  }

  collect(DartType type, {bool isTypeArgument: false}) {
    visit(type, isTypeArgument);
  }

  /// Collect all types in the list as if they were arguments of an
  /// InterfaceType.
  collectAll(List<DartType> types, {bool isTypeArgument: false}) {
    for (DartType type in types) {
      visit(type, true);
    }
  }

  visitTypedefType(ResolutionTypedefType type, bool isTypeArgument) {
    collect(type.unaliased, isTypeArgument: isTypeArgument);
  }

  visitInterfaceType(InterfaceType type, bool isTypeArgument) {
    if (isTypeArgument) addClass(type.element);
    collectAll(type.typeArguments, isTypeArgument: true);
  }

  visitFunctionType(FunctionType type, _) {
    collect(type.returnType, isTypeArgument: true);
    collectAll(type.parameterTypes, isTypeArgument: true);
    collectAll(type.optionalParameterTypes, isTypeArgument: true);
    collectAll(type.namedParameterTypes, isTypeArgument: true);
  }
}

class FunctionArgumentCollector
    extends ResolutionDartTypeVisitor<dynamic, bool> {
  final Set<ClassEntity> classes = new Set<ClassEntity>();

  FunctionArgumentCollector();

  collect(DartType type, {bool inFunctionType: false}) {
    visit(type, inFunctionType);
  }

  collectAll(List<DartType> types, {bool inFunctionType: false}) {
    for (DartType type in types) {
      visit(type, inFunctionType);
    }
  }

  visitTypedefType(ResolutionTypedefType type, bool inFunctionType) {
    collect(type.unaliased, inFunctionType: inFunctionType);
  }

  visitInterfaceType(InterfaceType type, bool inFunctionType) {
    if (inFunctionType) {
      classes.add(type.element);
    }
    collectAll(type.typeArguments, inFunctionType: inFunctionType);
  }

  visitFunctionType(FunctionType type, _) {
    collect(type.returnType, inFunctionType: true);
    collectAll(type.parameterTypes, inFunctionType: true);
    collectAll(type.optionalParameterTypes, inFunctionType: true);
    collectAll(type.namedParameterTypes, inFunctionType: true);
  }
}

/// Representation of the substitution of type arguments when going from the
/// type of a class to one of its supertypes.
///
/// For `class B<T> extends A<List<T>, int>`, the substitution is the
/// representation of `(T) => [<List, T>, int]`. For more details of the
/// representation consult the documentation of [getSupertypeSubstitution].
//TODO(floitsch): Remove support for non-function substitutions.
class Substitution {
  final bool isFunction;
  final List<DartType> arguments;
  final List<DartType> parameters;

  Substitution.list(this.arguments)
      : isFunction = false,
        parameters = const <DartType>[];

  Substitution.function(this.arguments, this.parameters) : isFunction = true;

  String toString() => 'Substitution(isFunction=$isFunction,'
      'arguments=$arguments,parameters=$parameters)';
}

/**
 * A pair of a class that we need a check against and the type argument
 * substitution for this check.
 */
class TypeCheck {
  final ClassEntity cls;
  final Substitution substitution;
  final int hashCode = _nextHash = (_nextHash + 100003).toUnsigned(30);
  static int _nextHash = 0;

  TypeCheck(this.cls, this.substitution);

  String toString() => 'TypeCheck(cls=$cls,substitution=$substitution)';
}
