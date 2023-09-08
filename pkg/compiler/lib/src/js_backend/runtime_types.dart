// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.runtime_types;

import '../common.dart';
import '../common/elements.dart'
    show ElementEnvironment, JCommonElements, JElementEnvironment;
import '../common/names.dart' show Names;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js/js.dart' as jsAst;
import '../js_model/js_world.dart';
import '../options.dart';
import '../universe/codegen_world_builder.dart';
import '../universe/feature.dart';
import 'runtime_types_codegen.dart';
import 'runtime_types_resolution.dart';

typedef OnVariableCallback = jsAst.Expression Function(
    TypeVariableType variable);

/// Interface for the needed runtime type checks.
abstract class RuntimeTypesChecks {
  /// Returns the required runtime type checks.
  TypeChecks get requiredChecks;

  /// Return all classes needed for runtime type information.
  Iterable<ClassEntity> get requiredClasses;
}

class TrivialTypesChecks implements RuntimeTypesChecks {
  final TypeChecks _typeChecks;
  final Set<ClassEntity> _allClasses;

  TrivialTypesChecks(this._typeChecks)
      : _allClasses = _typeChecks.classes.toSet();

  @override
  TypeChecks get requiredChecks => _typeChecks;

  @override
  Iterable<ClassEntity> get requiredClasses => _allClasses;
}

/// Interface for computing the needed runtime type checks.
abstract class RuntimeTypesChecksBuilder {
  void registerTypeVariableBoundsSubtypeCheck(
      DartType typeArgument, DartType bound);

  /// Registers that a generic [instantiation] is used.
  void registerGenericInstantiation(GenericInstantiation instantiation);

  /// Computes the [RuntimeTypesChecks] for the data in this builder.
  RuntimeTypesChecks computeRequiredChecks(
      CodegenWorld codegenWorld, CompilerOptions options);

  bool get rtiChecksBuilderClosed;
}

class TrivialRuntimeTypesChecksBuilder implements RuntimeTypesChecksBuilder {
  final JClosedWorld _closedWorld;
  final TrivialRuntimeTypesSubstitutions _substitutions;
  @override
  bool rtiChecksBuilderClosed = false;

  TrivialRuntimeTypesChecksBuilder(this._closedWorld, this._substitutions);

  ElementEnvironment get _elementEnvironment => _closedWorld.elementEnvironment;

  @override
  void registerTypeVariableBoundsSubtypeCheck(
      DartType typeArgument, DartType bound) {}

  @override
  void registerGenericInstantiation(GenericInstantiation instantiation) {}

  @override
  RuntimeTypesChecks computeRequiredChecks(
      CodegenWorld codegenWorld, CompilerOptions options) {
    rtiChecksBuilderClosed = true;

    Map<ClassEntity, ClassUse> classUseMap = {};
    for (ClassEntity cls in _closedWorld.classHierarchy
        .getClassSet(_closedWorld.commonElements.objectClass)
        .subtypes()) {
      ClassUse classUse = ClassUse()
        ..directInstance = true
        ..checkedInstance = true
        ..typeArgument = true
        ..checkedTypeArgument = true
        ..typeLiteral = true
        ..functionType = _computeFunctionType(_elementEnvironment, cls);
      classUseMap[cls] = classUse;
    }
    TypeChecks typeChecks = _substitutions._computeChecks(classUseMap);
    return TrivialTypesChecks(typeChecks);
  }

  Set<ClassEntity> computeCheckedClasses(
      CodegenWorldBuilder codegenWorldBuilder, Set<DartType> implicitIsChecks) {
    return _closedWorld.classHierarchy
        .getClassSet(_closedWorld.commonElements.objectClass)
        .subtypes()
        .toSet();
  }

  Set<FunctionType> computeCheckedFunctions(
      CodegenWorldBuilder codegenWorldBuilder, Set<DartType> implicitIsChecks) {
    return {};
  }
}

mixin RuntimeTypesSubstitutionsMixin implements RuntimeTypesSubstitutions {
  JClosedWorld get _closedWorld;

  JElementEnvironment get _elementEnvironment =>
      _closedWorld.elementEnvironment;
  DartTypes get _types => _closedWorld.dartTypes;
  RuntimeTypesNeed get _rtiNeed => _closedWorld.rtiNeed;

  /// Compute the required type checks and substitutions for the given
  /// instantiated and checked classes.
  // TODO(fishythefish): Unify type checks and substitutions once old RTI is
  // removed.
  TypeChecks _computeChecks(Map<ClassEntity, ClassUse> classUseMap) {
    // Run through the combination of instantiated and checked
    // arguments and record all combination where the element of a checked
    // argument is a superclass of the element of an instantiated type.
    TypeCheckMapping result = TypeCheckMapping();
    Set<ClassEntity> handled = {};

    // Empty usage object for classes with no direct rti usage.
    final ClassUse emptyUse = ClassUse();

    /// Compute the $isX and $asX functions need for [cls].
    ClassChecks computeChecks(ClassEntity cls) {
      if (!handled.add(cls)) return result[cls];

      ClassUse classUse = classUseMap[cls] ?? emptyUse;
      ClassChecks checks = ClassChecks(classUse.functionType);
      result[cls] = checks;

      // Find the superclass from which [cls] inherits checks.
      ClassEntity? superClass = _elementEnvironment.getSuperClass(cls,
          skipUnnamedMixinApplications: true);
      ClassChecks? superChecks;
      bool extendsSuperClassTrivially = false;
      if (superClass != null) {
        // Compute the checks inherited from [superClass].
        superChecks = computeChecks(superClass);

        // Does [cls] extend [superClass] trivially?
        //
        // For instance:
        //
        //     class A<T> {}
        //     class B<S> extends A<S> {}
        //     class C<U, V> extends A<U> {}
        //     class D extends A<int> {}
        //
        // here `B` extends `A` trivially, but `C` and `D` don't.
        extendsSuperClassTrivially = isTrivialSubstitution(cls, superClass);
      }

      bool isNativeClass = _closedWorld.nativeData.isNativeClass(cls);
      if (classUse.typeArgument ||
          classUse.typeLiteral ||
          (isNativeClass && classUse.checkedInstance)) {
        Substitution? substitution = computeSubstitution(cls, cls);
        // We need [cls] at runtime - even if [cls] is not instantiated. Either
        // as a type argument, for a type literal or for an is-test if [cls] is
        // native.
        checks.add(TypeCheck(cls, substitution, needsIs: isNativeClass));
      }

      // Compute the set of classes that [cls] inherited properties from.
      //
      // This set reflects the emitted class hierarchy and therefore uses
      // `getEffectiveMixinClass` to find the inherited mixins.
      Set<ClassEntity> inheritedClasses = {};
      ClassEntity? other = cls;
      while (other != null) {
        inheritedClasses.add(other);
        if (classUse.instance &&
            _elementEnvironment.isMixinApplication(other)) {
          // We don't mixin [other] if [cls] isn't instantiated, directly or
          // indirectly.
          inheritedClasses
              .add(_elementEnvironment.getEffectiveMixinClass(other)!);
        }
        other = _elementEnvironment.getSuperClass(other);
      }

      /// Compute the needed check for [cls] against the class of the super
      /// [type].
      void processSupertype(InterfaceType type) {
        ClassEntity checkedClass = type.element;
        ClassUse checkedClassUse = classUseMap[checkedClass] ?? emptyUse;

        // Where [cls] inherits properties for [checkedClass].
        bool inheritsFromCheckedClass = inheritedClasses.contains(checkedClass);

        // If [cls] inherits properties from [checkedClass] and [checkedClass]
        // needs type arguments, [cls] must provide a substitution for
        // [checkedClass].
        //
        // For instance:
        //
        //     class M<T> {
        //        m() => T;
        //     }
        //     class S {}
        //     class C extends S with M<int> {}
        //
        // Here `C` needs an `$asM` substitution function to provide the value
        // of `T` in `M.m`.
        bool needsTypeArgumentsForCheckedClass = inheritsFromCheckedClass &&
            _rtiNeed.classNeedsTypeArguments(checkedClass);

        // Whether [checkedClass] is used in an instance test or type argument
        // test.
        //
        // For instance:
        //
        //    class A {}
        //    class B {}
        //    test(o) => o is A || o is List<B>;
        //
        // Here `A` is used in an instance test and `B` is used in a type
        // argument test.
        bool isChecked = checkedClassUse.checkedTypeArgument ||
            checkedClassUse.checkedInstance;

        if (isChecked || needsTypeArgumentsForCheckedClass) {
          // We need an $isX and/or $asX property on [cls] for [checkedClass].

          // Whether `cls` implements `checkedClass` trivially.
          //
          // For instance:
          //
          //     class A<T> {}
          //     class B<S> implements A<S> {}
          //     class C<U, V> implements A<U> {}
          //     class D implements A<int> {}
          //
          // here `B` implements `A` trivially, but `C` and `D` don't.
          bool implementsCheckedTrivially =
              isTrivialSubstitution(cls, checkedClass);

          // Whether [checkedClass] is generic.
          //
          // Currently [isTrivialSubstitution] reports that [cls] implements
          // [checkedClass] trivially if [checkedClass] is not generic. In this
          // case the substitution is not only trivial it is also not needed.
          bool isCheckedGeneric =
              _elementEnvironment.isGenericClass(checkedClass);

          // The checks for [checkedClass] inherited for [superClass].
          TypeCheck? checkFromSuperClass =
              superChecks != null ? superChecks[checkedClass] : null;

          // Whether [cls] need an explicit $isX property for [checkedClass].
          //
          // If [cls] inherits from [checkedClass] it also inherits the $isX
          // property automatically generated on [checkedClass].
          bool needsIs = !inheritsFromCheckedClass && isChecked;

          if (checkFromSuperClass != null) {
            // The superclass has a substitution function for [checkedClass].
            // Check if we can reuse this it of need to override it.
            //
            // The inherited $isX property does _not_ need to be overriding.
            if (extendsSuperClassTrivially) {
              // [cls] implements [checkedClass] the same way as [superClass]
              // so the inherited substitution function already works.
              checks.add(TypeCheck(checkedClass, null, needsIs: false));
            } else {
              // [cls] implements [checkedClass] differently from [superClass]
              // so the inherited substitution function needs to be replaced.
              if (implementsCheckedTrivially) {
                // We need an explicit trivial substitution function for
                // [checkedClass] that overrides the inherited function.
                checks.add(TypeCheck(checkedClass,
                    isCheckedGeneric ? const Substitution.trivial() : null,
                    needsIs: false));
              } else {
                // We need a non-trivial substitution function for
                // [checkedClass].
                Substitution substitution =
                    computeSubstitution(cls, checkedClass)!;
                checks
                    .add(TypeCheck(checkedClass, substitution, needsIs: false));

                for (DartType argument in substitution.arguments) {
                  argument = argument.withoutNullability;
                  if (argument is InterfaceType) {
                    computeChecks(argument.element);
                  }
                }
              }
            }
          } else {
            // The superclass has no substitution function for [checkedClass].
            if (implementsCheckedTrivially) {
              // We don't add an explicit substitution function for
              // [checkedClass] because the substitution is trivial and doesn't
              // need to override an inherited function.
              checks.add(TypeCheck(checkedClass, null, needsIs: needsIs));
            } else {
              // We need a non-trivial substitution function for
              // [checkedClass].
              Substitution substitution =
                  computeSubstitution(cls, checkedClass)!;
              checks
                  .add(TypeCheck(checkedClass, substitution, needsIs: needsIs));

              for (DartType argument in substitution.arguments) {
                argument = argument.withoutNullability;
                if (argument is InterfaceType) {
                  computeChecks(argument.element);
                }
              }
            }
          }
        }
      }

      for (InterfaceType type in _types.getSupertypes(cls)) {
        processSupertype(type);
      }
      return checks;
    }

    for (ClassEntity cls in classUseMap.keys) {
      ClassUse classUse = classUseMap[cls] ?? emptyUse;
      if (classUse.directInstance ||
          classUse.typeArgument ||
          classUse.typeLiteral) {
        // Add checks only for classes that are live either as instantiated
        // classes or type arguments passed at runtime.
        computeChecks(cls);
      }
    }

    return result;
  }

  @override
  Set<ClassEntity> getClassesUsedInSubstitutions(TypeChecks checks) {
    Set<ClassEntity> instantiated = {};
    ArgumentCollector collector = ArgumentCollector();
    for (ClassEntity target in checks.classes) {
      ClassChecks classChecks = checks[target];
      for (TypeCheck check in classChecks.checks) {
        Substitution? substitution = check.substitution;
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

    // If there are no type variables, we do not need a substitution.
    if (!_elementEnvironment.isGenericClass(check)) {
      return true;
    }

    // JS-interop classes need an explicit substitution to mark the type
    // arguments as `any` type.
    if (_closedWorld.nativeData.isJsInteropClass(cls)) {
      return false;
    }

    // If the type is the same, we do not need a substitution.
    if (cls == check) {
      return true;
    }

    InterfaceType originalType = _elementEnvironment.getThisType(cls);
    InterfaceType? type = _types.asInstanceOf(originalType, check);
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

  // TODO(sigmund): consider using the existing required checks returned by
  // `_substitutions.computeChecks` to cache existing substitutions.  Before the
  // null-safety migration this library had logic to retrieve substitutions from
  // such a cache, but the algorithm never used it. Because of that we deleted
  // the caching mechanism altogether.
  Substitution? computeSubstitution(ClassEntity cls, ClassEntity check,
      {bool alwaysGenerateFunction = false}) {
    if (isTrivialSubstitution(cls, check)) return null;

    // Unnamed mixin application classes do not need substitutions, because they
    // are never instantiated and their checks are overwritten by the class that
    // they are mixed into.
    InterfaceType type = _elementEnvironment.getThisType(cls);
    InterfaceType target = _types.asInstanceOf(type, check)!;
    List<DartType> typeVariables = type.typeArguments;
    if (_closedWorld.nativeData.isJsInteropClass(cls)) {
      int typeArguments = target.typeArguments.length;
      // Generic JS-interop class need an explicit substitution to mark
      // the type arguments as `any` type.
      return Substitution.jsInterop(typeArguments);
    } else if (typeVariables.isEmpty && !alwaysGenerateFunction) {
      return Substitution.list(target.typeArguments);
    } else {
      return Substitution.function(target.typeArguments, typeVariables);
    }
  }
}

class TrivialRuntimeTypesSubstitutions with RuntimeTypesSubstitutionsMixin {
  @override
  final JClosedWorld _closedWorld;

  TrivialRuntimeTypesSubstitutions(this._closedWorld);
}

class _RuntimeTypesChecks implements RuntimeTypesChecks {
  final RuntimeTypesSubstitutions _substitutions;
  @override
  final TypeChecks requiredChecks;
  final Iterable<ClassEntity> _typeLiterals;
  final Iterable<ClassEntity> _typeArguments;

  _RuntimeTypesChecks(this._substitutions, this.requiredChecks,
      this._typeLiterals, this._typeArguments);

  @override
  Iterable<ClassEntity> get requiredClasses {
    return {
      ..._typeArguments,
      ..._typeLiterals,
      ..._substitutions.getClassesUsedInSubstitutions(requiredChecks)
    };
  }
}

class RuntimeTypesImpl
    with RuntimeTypesSubstitutionsMixin
    implements RuntimeTypesChecksBuilder {
  @override
  final JClosedWorld _closedWorld;

  // The set of type arguments tested against type variable bounds.
  final Set<DartType> checkedTypeArguments = {};
  // The set of tested type variable bounds.
  final Set<DartType> checkedBounds = {};

  @override
  bool rtiChecksBuilderClosed = false;

  RuntimeTypesImpl(this._closedWorld);

  JCommonElements get _commonElements => _closedWorld.commonElements;
  @override
  JElementEnvironment get _elementEnvironment =>
      _closedWorld.elementEnvironment;
  @override
  RuntimeTypesNeed get _rtiNeed => _closedWorld.rtiNeed;

  Map<ClassEntity, ClassUse>? classUseMapForTesting;

  final Set<GenericInstantiation> _genericInstantiations = {};

  @override
  void registerTypeVariableBoundsSubtypeCheck(
      DartType typeArgument, DartType bound) {
    checkedTypeArguments.add(typeArgument);
    checkedBounds.add(bound);
  }

  @override
  void registerGenericInstantiation(GenericInstantiation instantiation) {
    _genericInstantiations.add(instantiation);
  }

  @override
  RuntimeTypesChecks computeRequiredChecks(
      CodegenWorld codegenWorld, CompilerOptions options) {
    TypeVariableTests typeVariableTests = TypeVariableTests(_elementEnvironment,
        _commonElements, codegenWorld, _genericInstantiations,
        forRtiNeeds: false);
    Set<DartType> explicitIsChecks = typeVariableTests.explicitIsChecks;
    Set<DartType> implicitIsChecks = typeVariableTests.implicitIsChecks;

    Map<ClassEntity, ClassUse> classUseMap = {};
    if (retainDataForTesting) {
      classUseMapForTesting = classUseMap;
    }

    Set<FunctionType> checkedFunctionTypes = {};
    Set<ClassEntity> typeLiterals = {};
    Set<ClassEntity> typeArguments = {};

    Iterable<DartType> instantiateTypeVariable(TypeVariableEntity variable) {
      Entity? declaration = variable.typeDeclaration;
      int index = variable.index;
      if (declaration is ClassEntity) {
        return typeVariableTests
            .classInstantiationsOf(declaration)
            .map((InterfaceType interface) => interface.typeArguments[index]);
      } else {
        return typeVariableTests.instantiationsOf(declaration).map(
            (GenericInstantiation instantiation) =>
                instantiation.typeArguments[index]);
      }
    }

    // The [liveTypeVisitor] is used to register class use in the type of
    // instantiated objects like `new T` and the function types of
    // tear offs and closures.
    //
    // A type found in a covariant position of such types is considered live
    // whereas a type found in a contravariant position of such types is
    // considered tested.
    //
    // For instance
    //
    //    A<B Function(C)>();
    //
    // makes A and B live but C tested.
    _TypeVisitor liveTypeVisitor = _TypeVisitor(
        onClass: (ClassEntity cls, {required TypeVisitorState state}) {
          ClassUse classUse = classUseMap.putIfAbsent(cls, () => ClassUse());
          switch (state) {
            case TypeVisitorState.covariantTypeArgument:
              classUse.typeArgument = true;
              typeArguments.add(cls);
              break;
            case TypeVisitorState.contravariantTypeArgument:
              classUse.typeArgument = true;
              classUse.checkedTypeArgument = true;
              typeArguments.add(cls);
              break;
            case TypeVisitorState.typeLiteral:
              classUse.typeLiteral = true;
              typeLiterals.add(cls);
              break;
            case TypeVisitorState.direct:
              break;
          }
        },
        instantiateTypeVariable: instantiateTypeVariable);

    // The [testedTypeVisitor] is used to register class use in type tests like
    // `o is T` and `o as T` (both implicit and explicit).
    //
    // A type found in a covariant position of such types is considered tested
    // whereas a type found in a contravariant position of such types is
    // considered live.
    //
    // For instance
    //
    //    o is A<B Function(C)>;
    //
    // makes A and B tested but C live.
    _TypeVisitor testedTypeVisitor = _TypeVisitor(
        onClass: (ClassEntity cls, {required TypeVisitorState state}) {
          ClassUse classUse = classUseMap.putIfAbsent(cls, () => ClassUse());
          switch (state) {
            case TypeVisitorState.covariantTypeArgument:
              classUse.typeArgument = true;
              classUse.checkedTypeArgument = true;
              typeArguments.add(cls);
              break;
            case TypeVisitorState.contravariantTypeArgument:
              classUse.typeArgument = true;
              typeArguments.add(cls);
              break;
            case TypeVisitorState.typeLiteral:
              break;
            case TypeVisitorState.direct:
              classUse.checkedInstance = true;
              break;
          }
        },
        instantiateTypeVariable: instantiateTypeVariable);

    codegenWorld.instantiatedClasses.forEach((ClassEntity cls) {
      ClassUse classUse = classUseMap.putIfAbsent(cls, () => ClassUse());
      classUse.instance = true;
    });

    Set<ClassEntity> visitedSuperClasses = {};
    codegenWorld.instantiatedTypes.forEach((InterfaceType type) {
      liveTypeVisitor.visitType(type, TypeVisitorState.direct);
      ClassUse classUse =
          classUseMap.putIfAbsent(type.element, () => ClassUse());
      classUse.directInstance = true;
      FunctionType? callType = _types.getCallType(type);
      if (callType != null) {
        liveTypeVisitor.visitType(callType, TypeVisitorState.direct);
      }

      // Superclass might make classes live as type arguments. For instance
      //
      //    class A {}
      //    class B<T> {}
      //    class C implements B<A> {}
      //    main() => C();
      //
      // Here `A` is live as a type argument through the liveness of `C`.
      for (InterfaceType supertype
          in _closedWorld.dartTypes.getSupertypes(type.element)) {
        if (supertype.typeArguments.isEmpty &&
            visitedSuperClasses.contains(supertype.element)) {
          // If [superclass] is not generic then a second visit cannot add more
          // information that the first. In the example above, visiting `C`
          // twice can only result in a second registration of `A` as live
          // type argument.
          break;
        }
        visitedSuperClasses.add(supertype.element);
        liveTypeVisitor.visitType(supertype, TypeVisitorState.direct);
      }
    });

    for (FunctionEntity element in codegenWorld.closurizedStatics) {
      FunctionType functionType = _elementEnvironment.getFunctionType(element);
      liveTypeVisitor.visitType(functionType, TypeVisitorState.direct);
    }

    for (FunctionEntity element in codegenWorld.closurizedMembers) {
      FunctionType functionType = _elementEnvironment.getFunctionType(element);
      liveTypeVisitor.visitType(functionType, TypeVisitorState.direct);
    }

    void processMethodTypeArguments(_, Set<DartType> typeArguments) {
      for (DartType typeArgument in typeArguments) {
        liveTypeVisitor.visit(
            typeArgument, TypeVisitorState.covariantTypeArgument);
      }
    }

    codegenWorld.forEachStaticTypeArgument(processMethodTypeArguments);
    codegenWorld.forEachDynamicTypeArgument(processMethodTypeArguments);
    codegenWorld.liveTypeArguments.forEach((DartType type) {
      liveTypeVisitor.visitType(type, TypeVisitorState.covariantTypeArgument);
    });
    codegenWorld.constTypeLiterals.forEach((DartType type) {
      liveTypeVisitor.visitType(type, TypeVisitorState.typeLiteral);
    });

    bool isFunctionChecked = false;

    void processCheckedType(DartType t) {
      t = t.withoutNullability;
      if (t is FunctionType) {
        checkedFunctionTypes.add(t);
      } else if (t is InterfaceType) {
        isFunctionChecked =
            isFunctionChecked || t.element == _commonElements.functionClass;
      }
      testedTypeVisitor.visitType(t, TypeVisitorState.direct);
    }

    explicitIsChecks.forEach(processCheckedType);
    implicitIsChecks.forEach(processCheckedType);

    // A closure class implements the function type of its `call`
    // method and needs a signature function for testing its function type
    // against typedefs and function types that are used in is-checks. Since
    // closures have a signature method iff they need it and should have a
    // function type iff they have a signature, we process all classes.
    void processClass(ClassEntity cls) {
      ClassFunctionType? functionType =
          _computeFunctionType(_elementEnvironment, cls);
      if (functionType != null) {
        ClassUse classUse = classUseMap.putIfAbsent(cls, () => ClassUse());
        classUse.functionType = functionType;
      }
    }

    // Collect classes that are 'live' either through instantiation or use in
    // type arguments.
    List<ClassEntity> liveClasses = [];
    classUseMap.forEach((ClassEntity cls, ClassUse classUse) {
      if (classUse.isLive) {
        liveClasses.add(cls);
      }
    });
    liveClasses.forEach(processClass);

    codegenWorld.forEachGenericMethod((FunctionEntity method) {
      if (_closedWorld.annotationsData
          .getParameterCheckPolicy(method)
          .isEmitted) {
        if (_rtiNeed.methodNeedsTypeArguments(method)) {
          for (TypeVariableType typeVariable
              in _elementEnvironment.getFunctionTypeVariables(method)) {
            DartType bound =
                _elementEnvironment.getTypeVariableBound(typeVariable.element);
            processCheckedType(bound);
            liveTypeVisitor.visit(
                bound, TypeVisitorState.covariantTypeArgument);
          }
        }
      }
    });

    final checks = _computeChecks(classUseMap);
    rtiChecksBuilderClosed = true;
    return _RuntimeTypesChecks(this, checks, typeArguments, typeLiterals);
  }
}

/// Computes the function type of [cls], if any.
///
/// In Dart 1, any class with a `call` method has a function type, in Dart 2
/// only closure classes have a function type.
ClassFunctionType? _computeFunctionType(
    ElementEnvironment elementEnvironment, ClassEntity cls) {
  FunctionEntity? signatureFunction;
  if (cls.isClosure) {
    // Use signature function if available.
    signatureFunction = elementEnvironment.lookupLocalClassMember(
        cls, Names.signature) as FunctionEntity?;
    if (signatureFunction == null) {
      // In Dart 2, a closure only needs its function type if it has a
      // signature function.
      return null;
    }
  } else {
    // Only closures have function type in Dart 2.
    return null;
  }
  MemberEntity? call =
      elementEnvironment.lookupLocalClassMember(cls, Names.call);
  if (call != null && call.isFunction) {
    FunctionEntity callFunction = call as FunctionEntity;
    FunctionType callType = elementEnvironment.getFunctionType(callFunction);
    return ClassFunctionType(callFunction, callType, signatureFunction);
  }
  return null;
}

class TypeCheckMapping implements TypeChecks {
  final Map<ClassEntity, ClassChecks> map = {};

  @override
  ClassChecks operator [](ClassEntity element) {
    ClassChecks? result = map[element];
    return result ?? const ClassChecks.empty();
  }

  void operator []=(ClassEntity element, ClassChecks checks) {
    map[element] = checks;
  }

  @override
  Iterable<ClassEntity> get classes => map.keys;

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    for (ClassEntity holder in classes) {
      for (TypeCheck check in this[holder].checks) {
        sb.write('${holder.name} <: ${check.cls.name}, ');
      }
    }
    return '[$sb]';
  }
}

class ArgumentCollector extends DartTypeVisitor<void, void> {
  final Set<ClassEntity> classes = {};

  void addClass(ClassEntity cls) {
    classes.add(cls);
  }

  void collect(DartType type) {
    visit(type, null);
  }

  /// Collect all types in the list as if they were arguments of an
  /// InterfaceType.
  void collectAll(List<DartType> types) => types.forEach(collect);

  @override
  void visitLegacyType(LegacyType type, _) {
    collect(type.baseType);
  }

  @override
  void visitNullableType(NullableType type, _) {
    collect(type.baseType);
  }

  @override
  void visitNeverType(NeverType type, _) {}

  @override
  void visitVoidType(VoidType type, _) {}

  @override
  void visitTypeVariableType(TypeVariableType type, _) {}

  @override
  void visitFunctionTypeVariable(FunctionTypeVariable type, _) {}

  @override
  void visitFunctionType(FunctionType type, _) {
    collect(type.returnType);
    collectAll(type.parameterTypes);
    collectAll(type.optionalParameterTypes);
    collectAll(type.namedParameterTypes);
  }

  @override
  void visitInterfaceType(InterfaceType type, _) {
    addClass(type.element);
    collectAll(type.typeArguments);
  }

  @override
  void visitRecordType(RecordType type, _) {
    collectAll(type.fields);
  }

  @override
  void visitDynamicType(DynamicType type, _) {}

  @override
  void visitErasedType(ErasedType type, _) {}

  @override
  void visitAnyType(AnyType type, _) {}

  @override
  void visitFutureOrType(FutureOrType type, _) {
    collect(type.typeArgument);
  }
}

enum TypeVisitorState {
  direct,
  covariantTypeArgument,
  contravariantTypeArgument,
  typeLiteral,
}

class _TypeVisitor extends DartTypeVisitor<void, TypeVisitorState> {
  final Set<TypeVariableType> _visitedTypeVariables = {};
  final Set<FunctionTypeVariable> _visitedFunctionTypeVariables = {};

  final void Function(ClassEntity entity, {required TypeVisitorState state})
      onClass;
  final Iterable<DartType> Function(TypeVariableEntity entity)
      instantiateTypeVariable;

  _TypeVisitor({required this.onClass, required this.instantiateTypeVariable});

  void visitType(DartType type, TypeVisitorState state) =>
      type.accept(this, state);

  TypeVisitorState covariantArgument(TypeVisitorState state) {
    switch (state) {
      case TypeVisitorState.direct:
        return TypeVisitorState.covariantTypeArgument;
      case TypeVisitorState.covariantTypeArgument:
        return TypeVisitorState.covariantTypeArgument;
      case TypeVisitorState.contravariantTypeArgument:
        return TypeVisitorState.contravariantTypeArgument;
      case TypeVisitorState.typeLiteral:
        return TypeVisitorState.typeLiteral;
    }
  }

  TypeVisitorState contravariantArgument(TypeVisitorState state) {
    switch (state) {
      case TypeVisitorState.direct:
        return TypeVisitorState.contravariantTypeArgument;
      case TypeVisitorState.covariantTypeArgument:
        return TypeVisitorState.contravariantTypeArgument;
      case TypeVisitorState.contravariantTypeArgument:
        return TypeVisitorState.covariantTypeArgument;
      case TypeVisitorState.typeLiteral:
        return TypeVisitorState.typeLiteral;
    }
  }

  void visitTypes(List<DartType> types, TypeVisitorState state) {
    for (DartType type in types) {
      visitType(type, state);
    }
  }

  @override
  void visitLegacyType(LegacyType type, TypeVisitorState state) =>
      visitType(type.baseType, state);

  @override
  void visitNullableType(NullableType type, TypeVisitorState state) =>
      visitType(type.baseType, state);

  @override
  void visitNeverType(NeverType type, TypeVisitorState state) {}

  @override
  void visitVoidType(VoidType type, TypeVisitorState state) {}

  @override
  void visitTypeVariableType(TypeVariableType type, TypeVisitorState state) {
    if (_visitedTypeVariables.add(type)) {
      for (DartType instantiation in instantiateTypeVariable(type.element)) {
        visitType(instantiation, state);
      }
    }
  }

  @override
  visitFunctionTypeVariable(FunctionTypeVariable type, TypeVisitorState state) {
    if (_visitedFunctionTypeVariables.add(type)) {
      visitType(type.bound, state);
    }
  }

  @override
  void visitFunctionType(FunctionType type, TypeVisitorState state) {
    // Visit all nested types as type arguments; these types are not runtime
    // instances but runtime type representations.
    visitType(type.returnType, covariantArgument(state));
    visitTypes(type.parameterTypes, contravariantArgument(state));
    visitTypes(type.optionalParameterTypes, contravariantArgument(state));
    visitTypes(type.namedParameterTypes, contravariantArgument(state));
    _visitedFunctionTypeVariables.removeAll(type.typeVariables);
  }

  @override
  void visitInterfaceType(InterfaceType type, TypeVisitorState state) {
    onClass(type.element, state: state);
    visitTypes(type.typeArguments, covariantArgument(state));
  }

  @override
  void visitRecordType(RecordType type, TypeVisitorState state) {
    visitTypes(type.fields, covariantArgument(state));
  }

  @override
  void visitDynamicType(DynamicType type, TypeVisitorState state) {}

  @override
  void visitErasedType(ErasedType type, TypeVisitorState state) {}

  @override
  void visitAnyType(AnyType type, TypeVisitorState state) {}

  @override
  void visitFutureOrType(FutureOrType type, TypeVisitorState state) =>
      visitType(type.typeArgument, state);
}

/// Runtime type usage for a class.
class ClassUse {
  /// Whether the class is directly or indirectly instantiated.
  ///
  /// For instance `A` and `B` in:
  ///
  ///     class A {}
  ///     class B extends A {}
  ///     main() => B();
  ///
  bool instance = false;

  /// Whether the class is directly instantiated.
  ///
  /// For instance `B` in:
  ///
  ///     class A {}
  ///     class B extends A {}
  ///     main() => B();
  ///
  bool directInstance = false;

  /// Whether objects are checked to be instances of the class.
  ///
  /// For instance `A` in:
  ///
  ///     class A {}
  ///     main() => null is A;
  ///
  bool checkedInstance = false;

  /// Whether the class is passed as a type argument at runtime.
  ///
  /// For instance `A` in:
  ///
  ///     class A {}
  ///     main() => List<A>() is List<String>;
  ///
  bool typeArgument = false;

  /// Whether the class is checked as a type argument at runtime.
  ///
  /// For instance `A` in:
  ///
  ///     class A {}
  ///     main() => List<String>() is List<A>;
  ///
  bool checkedTypeArgument = false;

  /// Whether the class is used in a constant type literal.
  ///
  /// For instance `A`:
  ///
  ///     class A {}
  ///     main() => A;
  ///
  bool typeLiteral = false;

  /// The function type of the class, if any.
  ///
  /// This is only set if the function type is needed at runtime. For instance,
  /// if no function types are checked at runtime then the function type isn't
  /// needed.
  ///
  /// Furthermore optimization might also omit function type that are known not
  /// to be valid in any subtype test.
  ClassFunctionType? functionType;

  /// `true` if the class is 'live' either through instantiation or use in
  /// type arguments.
  bool get isLive => directInstance || typeArgument;

  @override
  String toString() {
    List<String> properties = [];
    if (instance) {
      properties.add('instance');
    }
    if (directInstance) {
      properties.add('directInstance');
    }
    if (checkedInstance) {
      properties.add('checkedInstance');
    }
    if (typeArgument) {
      properties.add('typeArgument');
    }
    if (checkedTypeArgument) {
      properties.add('checkedTypeArgument');
    }
    if (typeLiteral) {
      properties.add('rtiValue');
    }
    if (functionType != null) {
      properties.add('functionType');
    }
    return 'ClassUse(${properties.join(',')})';
  }
}
