// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.runtime_types;

import '../common.dart';
import '../common/names.dart' show Identifiers;
import '../common_elements.dart'
    show
        CommonElements,
        ElementEnvironment,
        JCommonElements,
        JElementEnvironment;
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../ir/runtime_type_analysis.dart';
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js_emitter/js_emitter.dart' show Emitter;
import '../options.dart';
import '../serialization/serialization.dart';
import '../universe/class_hierarchy.dart';
import '../universe/codegen_world_builder.dart';
import '../universe/feature.dart';
import '../universe/resolution_world_builder.dart';
import '../universe/selector.dart';
import '../universe/world_builder.dart';
import '../world.dart' show JClosedWorld, KClosedWorld;
import 'backend_usage.dart';
import 'namer.dart';
import 'native_data.dart';

/// For each class, stores the possible class subtype tests that could succeed.
abstract class TypeChecks {
  /// Get the set of checks required for class [element].
  ClassChecks operator [](ClassEntity element);

  /// Get the iterable for all classes that need type checks.
  Iterable<ClassEntity> get classes;
}

typedef jsAst.Expression OnVariableCallback(TypeVariableType variable);
typedef bool ShouldEncodeTypedefCallback(TypedefType variable);

/// Interface for the classes and methods that need runtime types.
abstract class RuntimeTypesNeed {
  /// Deserializes a [RuntimeTypesNeed] object from [source].
  factory RuntimeTypesNeed.readFromDataSource(
      DataSource source, ElementEnvironment elementEnvironment) {
    bool isTrivial = source.readBool();
    if (isTrivial) {
      return const TrivialRuntimeTypesNeed();
    }
    return new RuntimeTypesNeedImpl.readFromDataSource(
        source, elementEnvironment);
  }

  /// Serializes this [RuntimeTypesNeed] to [sink].
  void writeToDataSink(DataSink sink);

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

  /// Returns `true` if a dynamic call of [selector] needs to pass type
  /// arguments.
  bool selectorNeedsTypeArguments(Selector selector);

  /// Returns `true` if a generic instantiation on an expression of type
  /// [functionType] with the given [typeArgumentCount] needs to pass type
  /// arguments.
  // TODO(johnniwinther): Use [functionType].
  bool instantiationNeedsTypeArguments(
      DartType functionType, int typeArgumentCount);
}

class TrivialRuntimeTypesNeed implements RuntimeTypesNeed {
  const TrivialRuntimeTypesNeed();

  void writeToDataSink(DataSink sink) {
    sink.writeBool(true); // Is trivial.
  }

  @override
  bool classNeedsTypeArguments(ClassEntity cls) => true;

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
      DartType functionType, int typeArgumentCount) {
    return true;
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

  /// Computes the [RuntimeTypesNeed] for the data registered with this builder.
  RuntimeTypesNeed computeRuntimeTypesNeed(
      ResolutionWorldBuilder resolutionWorldBuilder,
      KClosedWorld closedWorld,
      CompilerOptions options);
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
  RuntimeTypesNeed computeRuntimeTypesNeed(
      ResolutionWorldBuilder resolutionWorldBuilder,
      KClosedWorld closedWorld,
      CompilerOptions options) {
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

  @override
  Iterable<ClassEntity> getReferencedClasses(FunctionType type) => _allClasses;
}

/// Interface for computing the needed runtime type checks.
abstract class RuntimeTypesChecksBuilder {
  void registerTypeVariableBoundsSubtypeCheck(
      DartType typeArgument, DartType bound);

  /// Registers that a generic [instantiation] is used.
  void registerGenericInstantiation(GenericInstantiation instantiation);

  /// Computes the [RuntimeTypesChecks] for the data in this builder.
  RuntimeTypesChecks computeRequiredChecks(
      CodegenWorldBuilder codegenWorldBuilder, CompilerOptions options);

  bool get rtiChecksBuilderClosed;
}

class TrivialRuntimeTypesChecksBuilder implements RuntimeTypesChecksBuilder {
  final JClosedWorld _closedWorld;
  final TrivialRuntimeTypesSubstitutions _substitutions;
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
      CodegenWorldBuilder codegenWorldBuilder, CompilerOptions options) {
    rtiChecksBuilderClosed = true;

    Map<ClassEntity, ClassUse> classUseMap = <ClassEntity, ClassUse>{};
    for (ClassEntity cls in _closedWorld.classHierarchy
        .getClassSet(_closedWorld.commonElements.objectClass)
        .subtypes()) {
      ClassUse classUse = new ClassUse()
        ..directInstance = true
        ..checkedInstance = true
        ..typeArgument = true
        ..checkedTypeArgument = true
        ..typeLiteral = true
        ..functionType = _computeFunctionType(_elementEnvironment, cls);
      classUseMap[cls] = classUse;
    }
    TypeChecks typeChecks = _substitutions._requiredChecks =
        _substitutions._computeChecks(classUseMap);
    return new TrivialTypesChecks(typeChecks);
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
  JClosedWorld get _closedWorld;
  TypeChecks get _requiredChecks;

  JElementEnvironment get _elementEnvironment =>
      _closedWorld.elementEnvironment;
  DartTypes get _types => _closedWorld.dartTypes;
  RuntimeTypesNeed get _rtiNeed => _closedWorld.rtiNeed;

  /// Compute the required type checks and substitutions for the given
  /// instantiated and checked classes.
  TypeChecks _computeChecks(Map<ClassEntity, ClassUse> classUseMap) {
    // Run through the combination of instantiated and checked
    // arguments and record all combination where the element of a checked
    // argument is a superclass of the element of an instantiated type.
    TypeCheckMapping result = new TypeCheckMapping();
    Set<ClassEntity> handled = new Set<ClassEntity>();

    // Empty usage object for classes with no direct rti usage.
    final ClassUse emptyUse = new ClassUse();

    /// Compute the $isX and $asX functions need for [cls].
    ClassChecks computeChecks(ClassEntity cls) {
      if (!handled.add(cls)) return result[cls];

      ClassUse classUse = classUseMap[cls] ?? emptyUse;
      ClassChecks checks = new ClassChecks(classUse.functionType);
      result[cls] = checks;

      // Find the superclass from which [cls] inherits checks.
      ClassEntity superClass = _elementEnvironment.getSuperClass(cls,
          skipUnnamedMixinApplications: true);
      ClassChecks superChecks;
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
        Substitution substitution = computeSubstitution(cls, cls);
        // We need [cls] at runtime - even if [cls] is not instantiated. Either
        // as a type argument, for a type literal or for an is-test if [cls] is
        // native.
        checks.add(new TypeCheck(cls, substitution, needsIs: isNativeClass));
      }

      // Compute the set of classes that [cls] inherited properties from.
      //
      // This set reflects the emitted class hierarchy and therefore uses
      // `getEffectiveMixinClass` to find the inherited mixins.
      Set<ClassEntity> inheritedClasses = new Set<ClassEntity>();
      ClassEntity other = cls;
      while (other != null) {
        inheritedClasses.add(other);
        if (classUse.instance &&
            _elementEnvironment.isMixinApplication(other)) {
          // We don't mixin [other] if [cls] isn't instantiated, directly or
          // indirectly.
          inheritedClasses
              .add(_elementEnvironment.getEffectiveMixinClass(other));
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
          TypeCheck checkFromSuperClass =
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
              checks.add(new TypeCheck(checkedClass, null, needsIs: false));
            } else {
              // [cls] implements [checkedClass] differently from [superClass]
              // so the inherited substitution function needs to be replaced.
              if (implementsCheckedTrivially) {
                // We need an explicit trivial substitution function for
                // [checkedClass] that overrides the inherited function.
                checks.add(new TypeCheck(checkedClass,
                    isCheckedGeneric ? const Substitution.trivial() : null,
                    needsIs: false));
              } else {
                // We need a non-trivial substitution function for
                // [checkedClass].
                checks.add(new TypeCheck(
                    checkedClass, computeSubstitution(cls, checkedClass),
                    needsIs: false));
              }
            }
          } else {
            // The superclass has no substitution function for [checkedClass].
            if (implementsCheckedTrivially) {
              // We don't add an explicit substitution function for
              // [checkedClass] because the substitution is trivial and doesn't
              // need to override an inherited function.
              checks.add(new TypeCheck(checkedClass, null, needsIs: needsIs));
            } else {
              // We need a non-trivial substitution function for
              // [checkedClass].
              checks.add(new TypeCheck(
                  checkedClass, computeSubstitution(cls, checkedClass),
                  needsIs: needsIs));
            }
          }
        }
      }

      for (InterfaceType type in _types.getSupertypes(cls)) {
        processSupertype(type);
      }
      FunctionType callType = _types.getCallType(_types.getThisType(cls));
      if (callType != null) {
        processSupertype(_closedWorld.commonElements.functionType);
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
    Set<ClassEntity> instantiated = new Set<ClassEntity>();
    ArgumentCollector collector = new ArgumentCollector();
    for (ClassEntity target in checks.classes) {
      ClassChecks classChecks = checks[target];
      for (TypeCheck check in classChecks.checks) {
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
    for (TypeCheck check in _requiredChecks[cls].checks) {
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
    if (_closedWorld.nativeData.isJsInteropClass(cls)) {
      int typeArguments = target.typeArguments.length;
      // Generic JS-interop class need an explicit substitution to mark
      // the type arguments as `any` type.
      return new Substitution.jsInterop(typeArguments);
    } else if (typeVariables.isEmpty && !alwaysGenerateFunction) {
      return new Substitution.list(target.typeArguments);
    } else {
      return new Substitution.function(target.typeArguments, typeVariables);
    }
  }
}

class TrivialRuntimeTypesSubstitutions extends RuntimeTypesSubstitutionsMixin {
  final JClosedWorld _closedWorld;
  TypeChecks _requiredChecks;

  TrivialRuntimeTypesSubstitutions(this._closedWorld);
}

/// Interface for computing substitutions need for runtime type checks.
abstract class RuntimeTypesSubstitutions {
  bool isTrivialSubstitution(ClassEntity cls, ClassEntity check);

  Substitution getSubstitution(ClassEntity cls, ClassEntity other);

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

  /// Returns the JavaScript template to determine at runtime if a type object
  /// is a FutureOr type.
  jsAst.Template get templateForIsFutureOrType;

  /// Returns the JavaScript template to determine at runtime if a type object
  /// is the void type.
  jsAst.Template get templateForIsVoidType;

  /// Returns the JavaScript template to determine at runtime if a type object
  /// is the dynamic type.
  jsAst.Template get templateForIsDynamicType;

  /// Returns the JavaScript template to determine at runtime if a type object
  /// is a type argument of js-interop class.
  jsAst.Template get templateForIsJsInteropTypeArgument;

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

  /// Compute type arguments of classes that use one of their type variables in
  /// is-checks and add the is-checks that they imply.
  ///
  /// This function must be called after all is-checks have been registered.
  ///
  /// TODO(karlklose): move these computations into a function producing an
  /// immutable datastructure.
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
      DataSource source, ElementEnvironment elementEnvironment) {
    source.begin(tag);
    Set<ClassEntity> classesNeedingTypeArguments =
        source.readClasses<ClassEntity>().toSet();
    Set<FunctionEntity> methodsNeedingSignature =
        source.readMembers<FunctionEntity>().toSet();
    Set<FunctionEntity> methodsNeedingTypeArguments =
        source.readMembers<FunctionEntity>().toSet();
    Set<Selector> selectorsNeedingTypeArguments =
        source.readList(() => new Selector.readFromDataSource(source)).toSet();
    Set<int> instantiationsNeedingTypeArguments =
        source.readList(source.readInt).toSet();
    source.end(tag);
    return new RuntimeTypesNeedImpl(
        elementEnvironment,
        classesNeedingTypeArguments,
        methodsNeedingSignature,
        methodsNeedingTypeArguments,
        null,
        null,
        selectorsNeedingTypeArguments,
        instantiationsNeedingTypeArguments);
  }

  void writeToDataSink(DataSink sink) {
    sink.writeBool(false); // Is _not_ trivial.
    sink.begin(tag);
    sink.writeClasses(classesNeedingTypeArguments);
    sink.writeMembers(methodsNeedingSignature);
    sink.writeMembers(methodsNeedingTypeArguments);
    assert(localFunctionsNeedingSignature == null);
    assert(localFunctionsNeedingTypeArguments == null);
    sink.writeList(selectorsNeedingTypeArguments,
        (Selector selector) => selector.writeToDataSink(sink));
    sink.writeList(instantiationsNeedingTypeArguments, sink.writeInt);
    sink.end(tag);
  }

  bool checkClass(covariant ClassEntity cls) => true;

  bool classNeedsTypeArguments(ClassEntity cls) {
    assert(checkClass(cls));
    if (!_elementEnvironment.isGenericClass(cls)) return false;
    return classesNeedingTypeArguments.contains(cls);
  }

  bool methodNeedsSignature(FunctionEntity function) {
    return methodsNeedingSignature.contains(function);
  }

  bool methodNeedsTypeArguments(FunctionEntity function) {
    if (function.parameterStructure.typeParameters == 0) return false;
    return methodsNeedingTypeArguments.contains(function);
  }

  @override
  bool selectorNeedsTypeArguments(Selector selector) {
    if (selector.callStructure.typeArgumentCount == 0) return false;
    return selectorsNeedingTypeArguments.contains(selector);
  }

  @override
  bool instantiationNeedsTypeArguments(
      DartType functionType, int typeArgumentCount) {
    return instantiationsNeedingTypeArguments.contains(typeArgumentCount);
  }
}

class TypeVariableTests {
  List<RtiNode> _nodes = <RtiNode>[];
  Map<ClassEntity, ClassNode> _classes = <ClassEntity, ClassNode>{};
  Map<Entity, MethodNode> _methods = <Entity, MethodNode>{};
  Map<Selector, Set<Entity>> _appliedSelectorMap;
  Map<GenericInstantiation, Set<Entity>> _instantiationMap;

  /// All explicit is-tests.
  final Set<DartType> explicitIsChecks;

  /// All implicit is-tests.
  final Set<DartType> implicitIsChecks = new Set<DartType>();

  TypeVariableTests(
      ElementEnvironment elementEnvironment,
      CommonElements commonElements,
      DartTypes types,
      WorldBuilder worldBuilder,
      Set<GenericInstantiation> genericInstantiations,
      {bool forRtiNeeds: true})
      : explicitIsChecks = new Set<DartType>.from(worldBuilder.isChecks) {
    _setupDependencies(
        elementEnvironment, commonElements, worldBuilder, genericInstantiations,
        forRtiNeeds: forRtiNeeds);
    _propagateTests(commonElements, elementEnvironment, worldBuilder);
    if (forRtiNeeds) {
      _propagateLiterals(elementEnvironment, worldBuilder);
    }
    _collectResults(commonElements, elementEnvironment, types, worldBuilder,
        forRtiNeeds: forRtiNeeds);
  }

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
  Iterable<ClassEntity> get classTestsForTesting =>
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
  Iterable<ClassEntity> get directClassTestsForTesting =>
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
  Iterable<Entity> get methodTestsForTesting =>
      _methods.values.where((n) => n.hasTest).map((n) => n.function).toSet();

  /// Methods that explicitly use their type variables in is-tests.
  ///
  /// For instance `m` in:
  ///
  ///     m<T>(o) => o is T;
  ///     main() => m<int>(0);
  ///
  Iterable<Entity> get directMethodTestsForTesting => _methods.values
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
  /// Here `A` needs type arguments at runtime because the key entity `B` needs
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

  /// Calls [f] for each selector that applies to generic [targets].
  void forEachAppliedSelector(void f(Selector selector, Set<Entity> targets)) {
    _appliedSelectorMap.forEach(f);
  }

  /// Calls [f] for each generic instantiation that applies to generic
  /// closurized [targets].
  void forEachGenericInstantiation(
      void f(GenericInstantiation instantiation, Set<Entity> targets)) {
    _instantiationMap?.forEach(f);
  }

  ClassNode _getClassNode(ClassEntity cls) {
    return _classes.putIfAbsent(cls, () {
      ClassNode node = new ClassNode(cls);
      _nodes.add(node);
      return node;
    });
  }

  MethodNode _getMethodNode(ElementEnvironment elementEnvironment,
      WorldBuilder worldBuilder, Entity function) {
    return _methods.putIfAbsent(function, () {
      MethodNode node;
      if (function is FunctionEntity) {
        Name instanceName;
        bool isCallTarget;
        bool isNoSuchMethod;
        if (function.isInstanceMember) {
          isCallTarget = worldBuilder.closurizedMembers.contains(function);
          instanceName = function.memberName;
          isNoSuchMethod = instanceName.text == Identifiers.noSuchMethod_;
        } else {
          isCallTarget = worldBuilder.closurizedStatics.contains(function);
          isNoSuchMethod = false;
        }
        node = new MethodNode(function, function.parameterStructure,
            isCallTarget: isCallTarget,
            instanceName: instanceName,
            isNoSuchMethod: isNoSuchMethod);
      } else {
        ParameterStructure parameterStructure = new ParameterStructure.fromType(
            elementEnvironment.getLocalFunctionType(function));
        node = new MethodNode(function, parameterStructure, isCallTarget: true);
      }
      _nodes.add(node);
      return node;
    });
  }

  void _setupDependencies(
      ElementEnvironment elementEnvironment,
      CommonElements commonElements,
      WorldBuilder worldBuilder,
      Set<GenericInstantiation> genericInstantiations,
      {bool forRtiNeeds: true}) {
    /// Register that if `node.entity` needs type arguments then so do entities
    /// whose type variables occur in [type].
    ///
    /// For instance if `A` needs type arguments then so does `B` in:
    ///
    ///   class A<T> {}
    ///   class B<T> { m() => new A<T>(); }
    ///
    void registerDependencies(RtiNode node, DartType type) {
      type.forEachTypeVariable((TypeVariableType typeVariable) {
        Entity typeDeclaration = typeVariable.element.typeDeclaration;
        if (typeDeclaration is ClassEntity) {
          node.addDependency(_getClassNode(typeDeclaration));
        } else {
          node.addDependency(_getMethodNode(
              elementEnvironment, worldBuilder, typeDeclaration));
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
      _getClassNode(commonElements.jsArrayClass)
          .addDependency(_getClassNode(commonElements.listClass));
    }
    if (commonElements.mapLiteralClass != null) {
      _getClassNode(commonElements.mapLiteralClass)
          .addDependency(_getClassNode(commonElements.mapClass));
    }

    void processCheckedType(DartType type) {
      if (type is InterfaceType) {
        // Register that if [cls] needs type arguments then so do the entities
        // that declare type variables occurring in [type].
        ClassEntity cls = type.element;
        registerDependencies(_getClassNode(cls), type);
      }
      if (type is FutureOrType) {
        // [type] is `FutureOr<X>`.

        // For the implied `is Future<X>` test, register that if `Future` needs
        // type arguments then so do the entities that declare type variables
        // occurring in `type.typeArgument`.
        registerDependencies(
            _getClassNode(commonElements.futureClass), type.typeArgument);
        // Process `type.typeArgument` for the implied `is X` test.
        processCheckedType(type.typeArgument);
      }
    }

    worldBuilder.isChecks.forEach(processCheckedType);

    worldBuilder.instantiatedTypes.forEach((InterfaceType type) {
      // Register that if [cls] needs type arguments then so do the entities
      // that declare type variables occurring in [type].
      ClassEntity cls = type.element;
      registerDependencies(_getClassNode(cls), type);
    });

    worldBuilder.forEachStaticTypeArgument(
        (Entity entity, Iterable<DartType> typeArguments) {
      for (DartType type in typeArguments) {
        // Register that if [entity] needs type arguments then so do the
        // entities that declare type variables occurring in [type].
        registerDependencies(
            _getMethodNode(elementEnvironment, worldBuilder, entity), type);
      }
    });

    // TODO(johnniwinther): Cached here because the world builders computes
    // this lazily. Track this set directly in the world builders .
    Iterable<FunctionEntity> genericInstanceMethods =
        worldBuilder.genericInstanceMethods;
    worldBuilder.forEachDynamicTypeArgument(
        (Selector selector, Iterable<DartType> typeArguments) {
      void processEntity(Entity entity) {
        MethodNode node =
            _getMethodNode(elementEnvironment, worldBuilder, entity);
        if (node.selectorApplies(selector)) {
          for (DartType type in typeArguments) {
            // Register that if `node.entity` needs type arguments then so do
            // the entities that declare type variables occurring in [type].
            registerDependencies(node, type);
          }
        }
      }

      genericInstanceMethods.forEach(processEntity);
      worldBuilder.genericLocalFunctions.forEach(processEntity);
      worldBuilder.closurizedStatics.forEach(processEntity);
      worldBuilder.userNoSuchMethods.forEach(processEntity);
    });

    for (GenericInstantiation instantiation in genericInstantiations) {
      void processEntity(Entity entity) {
        MethodNode node =
            _getMethodNode(elementEnvironment, worldBuilder, entity);
        if (node.parameterStructure.typeParameters ==
            instantiation.typeArguments.length) {
          if (forRtiNeeds) {
            _instantiationMap ??= <GenericInstantiation, Set<Entity>>{};
            _instantiationMap
                .putIfAbsent(instantiation, () => new Set<Entity>())
                .add(entity);
          }
          for (DartType type in instantiation.typeArguments) {
            // Register that if `node.entity` needs type arguments then so do
            // the entities that declare type variables occurring in [type].
            registerDependencies(node, type);
          }
        }
      }

      worldBuilder.closurizedMembers.forEach(processEntity);
      worldBuilder.closurizedStatics.forEach(processEntity);
      worldBuilder.genericLocalFunctions.forEach(processEntity);
    }
  }

  void _propagateTests(CommonElements commonElements,
      ElementEnvironment elementEnvironment, WorldBuilder worldBuilder) {
    void processTypeVariableType(TypeVariableType type, {bool direct: true}) {
      TypeVariableEntity variable = type.element;
      if (variable.typeDeclaration is ClassEntity) {
        _getClassNode(variable.typeDeclaration).markTest(direct: direct);
      } else {
        _getMethodNode(
                elementEnvironment, worldBuilder, variable.typeDeclaration)
            .markTest(direct: direct);
      }
    }

    void processType(DartType type, {bool direct: true}) {
      if (type is FutureOrType) {
        _getClassNode(commonElements.futureClass).markIndirectTest();
        processType(type.typeArgument, direct: false);
      } else {
        type.forEachTypeVariable((TypeVariableType type) {
          processTypeVariableType(type, direct: direct);
        });
      }
    }

    worldBuilder.isChecks.forEach(processType);
  }

  void _propagateLiterals(
      ElementEnvironment elementEnvironment, WorldBuilder worldBuilder) {
    worldBuilder.typeVariableTypeLiterals
        .forEach((TypeVariableType typeVariableType) {
      TypeVariableEntity variable = typeVariableType.element;
      if (variable.typeDeclaration is ClassEntity) {
        _getClassNode(variable.typeDeclaration).markDirectLiteral();
      } else {
        _getMethodNode(
                elementEnvironment, worldBuilder, variable.typeDeclaration)
            .markDirectLiteral();
      }
    });
  }

  void _collectResults(
      CommonElements commonElements,
      ElementEnvironment elementEnvironment,
      DartTypes types,
      WorldBuilder worldBuilder,
      {bool forRtiNeeds: true}) {
    /// Register the implicit is-test of [type].
    ///
    /// If [type] is of the form `FutureOr<X>`, also register the implicit
    /// is-tests of `Future<X>` and `X`.
    void addImplicitCheck(DartType type) {
      if (implicitIsChecks.add(type)) {
        if (type is FutureOrType) {
          addImplicitCheck(commonElements.futureType(type.typeArgument));
          addImplicitCheck(type.typeArgument);
        }
      }
    }

    void addImplicitChecks(Iterable<DartType> types) {
      types.forEach(addImplicitCheck);
    }

    worldBuilder.isChecks.forEach((DartType type) {
      if (type is FutureOrType) {
        addImplicitCheck(commonElements.futureType(type.typeArgument));
        addImplicitCheck(type.typeArgument);
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
            addImplicitCheck(argument.unaliased);
          }
        }
      }
    });

    worldBuilder.forEachStaticTypeArgument(
        (Entity function, Iterable<DartType> typeArguments) {
      if (!_getMethodNode(elementEnvironment, worldBuilder, function).hasTest) {
        return;
      }
      addImplicitChecks(typeArguments);
    });

    if (forRtiNeeds) {
      _appliedSelectorMap = <Selector, Set<Entity>>{};
    }

    worldBuilder.forEachDynamicTypeArgument(
        (Selector selector, Iterable<DartType> typeArguments) {
      for (MethodNode node in _methods.values) {
        if (node.selectorApplies(selector)) {
          if (forRtiNeeds) {
            _appliedSelectorMap
                .putIfAbsent(selector, () => new Set<Entity>())
                .add(node.entity);
          }
          if (node.hasTest) {
            addImplicitChecks(typeArguments);
          }
        }
      }
    });
  }

  String dump({bool verbose: false}) {
    StringBuffer sb = new StringBuffer();

    void addNode(RtiNode node) {
      if (node.hasUse || node.dependencies.isNotEmpty || verbose) {
        sb.write(' $node');
        String comma = '';
        if (node._testState & 1 != 0) {
          sb.write(' direct test');
          comma = ',';
        }
        if (node._testState & 2 != 0) {
          sb.write('$comma indirect test');
          comma = ',';
        }
        if (node._literalState & 1 != 0) {
          sb.write('$comma direct literal');
          comma = ',';
        }
        if (node._literalState & 2 != 0) {
          sb.write('$comma indirect literal');
          comma = ',';
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
  int _literalState = 0;

  Iterable<RtiNode> get dependencies => _dependencies ?? const <RtiNode>[];

  bool get hasDirectTest => _testState & 1 != 0;
  bool get hasIndirectTest => _testState & 2 != 0;

  bool get hasTest => _testState != 0;

  bool get hasDirectLiteral => _literalState & 1 != 0;
  bool get hasIndirectLiteral => _literalState & 2 != 0;

  bool get hasLiteral => _literalState != 0;

  bool get hasUse => hasTest || hasLiteral;

  /// Register that if [entity] needs type arguments then so does `node.entity`.
  bool addDependency(RtiNode node) {
    if (entity == node.entity) {
      // Skip trivial dependencies; if [entity] needs type arguments so does
      // [entity]!
      return false;
    }
    _dependencies ??= new Set<RtiNode>();
    return _dependencies.add(node);
  }

  void markTest({bool direct}) {
    setTestState(direct ? 1 : 2);
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

  void markDirectLiteral() {
    setLiteralState(1);
  }

  void markIndirectLiteral() {
    setLiteralState(2);
  }

  void setLiteralState(int value) {
    if (_literalState != value) {
      if (_literalState == 0) {
        _literalState |= value;
        if (_dependencies != null) {
          for (RtiNode node in _dependencies) {
            node.markIndirectLiteral();
          }
        }
      } else {
        _literalState = value;
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
  final bool isNoSuchMethod;

  MethodNode(this.function, this.parameterStructure,
      {this.isCallTarget, this.instanceName, this.isNoSuchMethod: false});

  Entity get entity => function;

  bool selectorApplies(Selector selector) {
    if (isNoSuchMethod) return true;
    return (isCallTarget && selector.isClosureCall ||
            instanceName == selector.memberName) &&
        selector.callStructure.signatureApplies(parameterStructure);
  }

  String get kind => 'method';

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('MethodNode(');
    sb.write('function=$function');
    sb.write(',parameterStructure=$parameterStructure');
    sb.write(',isCallTarget=$isCallTarget');
    sb.write(',instanceName=$instanceName');
    sb.write(')');
    return sb.toString();
  }
}

class RuntimeTypesNeedBuilderImpl extends _RuntimeTypesBase
    implements RuntimeTypesNeedBuilder {
  final ElementEnvironment _elementEnvironment;

  final Set<ClassEntity> classesUsingTypeVariableLiterals =
      new Set<ClassEntity>();

  final Set<FunctionEntity> methodsUsingTypeVariableLiterals =
      new Set<FunctionEntity>();

  final Set<Local> localFunctionsUsingTypeVariableLiterals = new Set<Local>();

  Map<Selector, Set<Entity>> selectorsNeedingTypeArgumentsForTesting;

  Map<GenericInstantiation, Set<Entity>>
      instantiationsNeedingTypeArgumentsForTesting;

  final Set<GenericInstantiation> _genericInstantiations =
      new Set<GenericInstantiation>();

  TypeVariableTests typeVariableTestsForTesting;

  RuntimeTypesNeedBuilderImpl(this._elementEnvironment, DartTypes types)
      : super(types);

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
  RuntimeTypesNeed computeRuntimeTypesNeed(
      ResolutionWorldBuilder resolutionWorldBuilder,
      KClosedWorld closedWorld,
      CompilerOptions options) {
    TypeVariableTests typeVariableTests = new TypeVariableTests(
        closedWorld.elementEnvironment,
        closedWorld.commonElements,
        closedWorld.dartTypes,
        resolutionWorldBuilder,
        _genericInstantiations);
    Set<ClassEntity> classesNeedingTypeArguments = new Set<ClassEntity>();
    Set<FunctionEntity> methodsNeedingSignature = new Set<FunctionEntity>();
    Set<FunctionEntity> methodsNeedingTypeArguments = new Set<FunctionEntity>();
    Set<Local> localFunctionsNeedingSignature = new Set<Local>();
    Set<Local> localFunctionsNeedingTypeArguments = new Set<Local>();
    Set<Entity> processedEntities = new Set<Entity>();

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

    Set<Local> localFunctions = resolutionWorldBuilder.localFunctions.toSet();
    Set<FunctionEntity> closurizedMembers =
        resolutionWorldBuilder.closurizedMembersWithFreeTypeVariables.toSet();

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

      Set<Local> localFunctionsToRemove;
      Set<FunctionEntity> closurizedMembersToRemove;
      for (Local function in localFunctions) {
        FunctionType functionType =
            _elementEnvironment.getLocalFunctionType(function);
        if (potentialSubtypeOf == null ||
            closedWorld.dartTypes
                .isPotentialSubtype(functionType, potentialSubtypeOf,
                    // TODO(johnniwinther): Use register generic instantiations
                    // instead.
                    assumeInstantiations: _genericInstantiations.isNotEmpty)) {
          functionType.forEachTypeVariable((TypeVariableType typeVariable) {
            Entity typeDeclaration = typeVariable.element.typeDeclaration;
            if (!processedEntities.contains(typeDeclaration)) {
              potentiallyNeedTypeArguments(typeDeclaration);
            }
          });
          localFunctionsNeedingSignature.add(function);
          localFunctionsToRemove ??= new Set<Local>();
          localFunctionsToRemove.add(function);
        }
      }
      for (FunctionEntity function in closurizedMembers) {
        if (checkFunctionType(_elementEnvironment.getFunctionType(function))) {
          methodsNeedingSignature.add(function);
          closurizedMembersToRemove ??= new Set<FunctionEntity>();
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

    if (resolutionWorldBuilder.isMemberUsed(
        closedWorld.commonElements.invocationTypeArgumentGetter)) {
      // If `Invocation.typeArguments` is live, mark all user-defined
      // implementations of `noSuchMethod` as needing type arguments.
      for (MemberEntity member in resolutionWorldBuilder.userNoSuchMethods) {
        potentiallyNeedTypeArguments(member);
      }
    }

    if (options.parameterCheckPolicy.isEmitted) {
      void checkFunction(Entity function, FunctionType type) {
        for (FunctionTypeVariable typeVariable in type.typeVariables) {
          DartType bound = typeVariable.bound;
          if (!bound.isDynamic &&
              !bound.isVoid &&
              bound != closedWorld.commonElements.objectType) {
            potentiallyNeedTypeArguments(function);
            break;
          }
        }
      }

      for (FunctionEntity method in resolutionWorldBuilder.genericMethods) {
        checkFunction(method, _elementEnvironment.getFunctionType(method));
      }

      for (Local function in resolutionWorldBuilder.genericLocalFunctions) {
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

    Set<ClassEntity> classesDirectlyNeedingRuntimeType = new Set<ClassEntity>();

    Iterable<ClassEntity> impliedClasses(DartType type) {
      if (type is InterfaceType) {
        return [type.element];
      } else if (type is DynamicType) {
        return [commonElements.objectClass];
      } else if (type is FunctionType) {
        // TODO(johnniwinther): Include only potential function type subtypes.
        return [commonElements.functionClass];
      } else if (type is VoidType) {
        // No classes implied.
      } else if (type is FunctionTypeVariable) {
        return impliedClasses(type.bound);
      } else if (type is FutureOrType) {
        return [commonElements.futureClass]
          ..addAll(impliedClasses(type.typeArgument));
      } else if (type is TypeVariableType) {
        // TODO(johnniwinther): Can we do better?
        return impliedClasses(
            _elementEnvironment.getTypeVariableBound(type.element));
      }
      throw new UnsupportedError('Unexpected type $type');
    }

    void addClass(ClassEntity cls) {
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
              impliedClasses(runtimeTypeUse.argumentType);

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
      allClassesNeedingRuntimeType = new Set<ClassEntity>();
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
      for (Local function in resolutionWorldBuilder.genericLocalFunctions) {
        potentiallyNeedTypeArguments(function);
      }
      for (Local function in localFunctions) {
        FunctionType functionType =
            _elementEnvironment.getLocalFunctionType(function);
        functionType.forEachTypeVariable((TypeVariableType typeVariable) {
          Entity typeDeclaration = typeVariable.element.typeDeclaration;
          if (!processedEntities.contains(typeDeclaration)) {
            potentiallyNeedTypeArguments(typeDeclaration);
          }
        });
        localFunctionsNeedingSignature.addAll(localFunctions);
      }
      for (FunctionEntity function
          in resolutionWorldBuilder.closurizedMembersWithFreeTypeVariables) {
        methodsNeedingSignature.add(function);
        potentiallyNeedTypeArguments(function.enclosingClass);
      }
    }

    Set<Selector> selectorsNeedingTypeArguments = new Set<Selector>();
    typeVariableTests
        .forEachAppliedSelector((Selector selector, Set<Entity> targets) {
      for (Entity target in targets) {
        if (methodsNeedingTypeArguments.contains(target) ||
            localFunctionsNeedingTypeArguments.contains(target)) {
          selectorsNeedingTypeArguments.add(selector);
          if (retainDataForTesting) {
            selectorsNeedingTypeArgumentsForTesting ??=
                <Selector, Set<Entity>>{};
            selectorsNeedingTypeArgumentsForTesting
                .putIfAbsent(selector, () => new Set<Entity>())
                .add(target);
          } else {
            return;
          }
        }
      }
    });
    Set<int> instantiationsNeedingTypeArguments = new Set<int>();
    typeVariableTests.forEachGenericInstantiation(
        (GenericInstantiation instantiation, Set<Entity> targets) {
      for (Entity target in targets) {
        if (methodsNeedingTypeArguments.contains(target) ||
            localFunctionsNeedingTypeArguments.contains(target)) {
          // TODO(johnniwinther): Use the static type of the instantiated
          // expression.
          instantiationsNeedingTypeArguments
              .add(instantiation.typeArguments.length);
          if (retainDataForTesting) {
            instantiationsNeedingTypeArgumentsForTesting ??=
                <GenericInstantiation, Set<Entity>>{};
            instantiationsNeedingTypeArgumentsForTesting
                .putIfAbsent(instantiation, () => new Set<Entity>())
                .add(target);
          } else {
            return;
          }
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

    return new RuntimeTypesNeedImpl(
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

class _RuntimeTypesChecks implements RuntimeTypesChecks {
  final RuntimeTypesSubstitutions _substitutions;
  final TypeChecks requiredChecks;
  final Iterable<ClassEntity> _typeLiterals;
  final Iterable<ClassEntity> _typeArguments;

  _RuntimeTypesChecks(this._substitutions, this.requiredChecks,
      this._typeLiterals, this._typeArguments);

  @override
  Iterable<ClassEntity> get requiredClasses {
    Set<ClassEntity> required = new Set<ClassEntity>();
    required.addAll(_typeArguments);
    required.addAll(_typeLiterals);
    required
        .addAll(_substitutions.getClassesUsedInSubstitutions(requiredChecks));
    return required;
  }

  @override
  Iterable<ClassEntity> getReferencedClasses(FunctionType type) {
    FunctionArgumentCollector collector = new FunctionArgumentCollector();
    collector.collect(type);
    return collector.classes;
  }
}

class RuntimeTypesImpl extends _RuntimeTypesBase
    with RuntimeTypesSubstitutionsMixin
    implements RuntimeTypesChecksBuilder {
  final JClosedWorld _closedWorld;

  // The set of type arguments tested against type variable bounds.
  final Set<DartType> checkedTypeArguments = new Set<DartType>();
  // The set of tested type variable bounds.
  final Set<DartType> checkedBounds = new Set<DartType>();

  TypeChecks cachedRequiredChecks;

  bool rtiChecksBuilderClosed = false;

  RuntimeTypesImpl(this._closedWorld) : super(_closedWorld.dartTypes);

  JCommonElements get _commonElements => _closedWorld.commonElements;
  JElementEnvironment get _elementEnvironment =>
      _closedWorld.elementEnvironment;
  RuntimeTypesNeed get _rtiNeed => _closedWorld.rtiNeed;

  @override
  TypeChecks get _requiredChecks => cachedRequiredChecks;

  Map<ClassEntity, ClassUse> classUseMapForTesting;

  final Set<GenericInstantiation> _genericInstantiations =
      new Set<GenericInstantiation>();

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

  RuntimeTypesChecks computeRequiredChecks(
      CodegenWorldBuilder codegenWorldBuilder, CompilerOptions options) {
    TypeVariableTests typeVariableTests = new TypeVariableTests(
        _elementEnvironment,
        _commonElements,
        _types,
        codegenWorldBuilder,
        _genericInstantiations,
        forRtiNeeds: false);
    Set<DartType> explicitIsChecks = typeVariableTests.explicitIsChecks;
    Set<DartType> implicitIsChecks = typeVariableTests.implicitIsChecks;

    Map<ClassEntity, ClassUse> classUseMap = <ClassEntity, ClassUse>{};
    if (retainDataForTesting) {
      classUseMapForTesting = classUseMap;
    }

    Set<FunctionType> checkedFunctionTypes = new Set<FunctionType>();
    Set<ClassEntity> typeLiterals = new Set<ClassEntity>();
    Set<ClassEntity> typeArguments = new Set<ClassEntity>();

    TypeVisitor liveTypeVisitor =
        new TypeVisitor(onClass: (ClassEntity cls, {TypeVisitorState state}) {
      ClassUse classUse = classUseMap.putIfAbsent(cls, () => new ClassUse());
      switch (state) {
        case TypeVisitorState.typeArgument:
          classUse.typeArgument = true;
          typeArguments.add(cls);
          break;
        case TypeVisitorState.typeLiteral:
          classUse.typeLiteral = true;
          typeLiterals.add(cls);
          break;
        case TypeVisitorState.direct:
          break;
      }
    });

    TypeVisitor testedTypeVisitor =
        new TypeVisitor(onClass: (ClassEntity cls, {TypeVisitorState state}) {
      ClassUse classUse = classUseMap.putIfAbsent(cls, () => new ClassUse());
      switch (state) {
        case TypeVisitorState.typeArgument:
          classUse.typeArgument = true;
          classUse.checkedTypeArgument = true;
          typeArguments.add(cls);
          break;
        case TypeVisitorState.typeLiteral:
          break;
        case TypeVisitorState.direct:
          classUse.checkedInstance = true;
          break;
      }
    });

    codegenWorldBuilder.instantiatedClasses.forEach((ClassEntity cls) {
      ClassUse classUse = classUseMap.putIfAbsent(cls, () => new ClassUse());
      classUse.instance = true;
    });

    codegenWorldBuilder.instantiatedTypes.forEach((InterfaceType type) {
      liveTypeVisitor.visitType(type, TypeVisitorState.direct);
      ClassUse classUse =
          classUseMap.putIfAbsent(type.element, () => new ClassUse());
      classUse.directInstance = true;
      FunctionType callType = _types.getCallType(type);
      if (callType != null) {
        testedTypeVisitor.visitType(callType, TypeVisitorState.direct);
      }
    });

    for (FunctionEntity element
        in codegenWorldBuilder.staticFunctionsNeedingGetter) {
      FunctionType functionType = _elementEnvironment.getFunctionType(element);
      testedTypeVisitor.visitType(functionType, TypeVisitorState.direct);
    }

    for (FunctionEntity element in codegenWorldBuilder.closurizedMembers) {
      FunctionType functionType = _elementEnvironment.getFunctionType(element);
      testedTypeVisitor.visitType(functionType, TypeVisitorState.direct);
    }

    void processMethodTypeArguments(_, Set<DartType> typeArguments) {
      for (DartType typeArgument in typeArguments) {
        liveTypeVisitor.visit(typeArgument, TypeVisitorState.typeArgument);
      }
    }

    codegenWorldBuilder.forEachStaticTypeArgument(processMethodTypeArguments);
    codegenWorldBuilder.forEachDynamicTypeArgument(processMethodTypeArguments);
    codegenWorldBuilder.liveTypeArguments.forEach((DartType type) {
      liveTypeVisitor.visitType(type, TypeVisitorState.typeArgument);
    });
    codegenWorldBuilder.constTypeLiterals.forEach((DartType type) {
      liveTypeVisitor.visitType(type, TypeVisitorState.typeLiteral);
    });

    bool isFunctionChecked = false;

    void processCheckedType(DartType t) {
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
      ClassFunctionType functionType =
          _computeFunctionType(_elementEnvironment, cls);
      if (functionType != null) {
        ClassUse classUse = classUseMap.putIfAbsent(cls, () => new ClassUse());
        classUse.functionType = functionType;
      }
    }

    // Collect classes that are 'live' either through instantiation or use in
    // type arguments.
    List<ClassEntity> liveClasses = <ClassEntity>[];
    classUseMap.forEach((ClassEntity cls, ClassUse classUse) {
      if (classUse.isLive) {
        liveClasses.add(cls);
      }
    });
    liveClasses.forEach(processClass);

    if (options.parameterCheckPolicy.isEmitted) {
      for (FunctionEntity method in codegenWorldBuilder.genericMethods) {
        if (_rtiNeed.methodNeedsTypeArguments(method)) {
          for (TypeVariableType typeVariable
              in _elementEnvironment.getFunctionTypeVariables(method)) {
            DartType bound =
                _elementEnvironment.getTypeVariableBound(typeVariable.element);
            processCheckedType(bound);
            liveTypeVisitor.visit(bound, TypeVisitorState.typeArgument);
          }
        }
      }
    }

    cachedRequiredChecks = _computeChecks(classUseMap);
    rtiChecksBuilderClosed = true;
    return new _RuntimeTypesChecks(
        this, cachedRequiredChecks, typeArguments, typeLiterals);
  }
}

/// Computes the function type of [cls], if any.
///
/// In Dart 1, any class with a `call` method has a function type, in Dart 2
/// only closure classes have a function type.
ClassFunctionType _computeFunctionType(
    ElementEnvironment elementEnvironment, ClassEntity cls) {
  FunctionEntity signatureFunction;
  if (cls.isClosure) {
    // Use signature function if available.
    signatureFunction =
        elementEnvironment.lookupLocalClassMember(cls, Identifiers.signature);
    if (signatureFunction == null) {
      // In Dart 2, a closure only needs its function type if it has a
      // signature function.
      return null;
    }
  } else {
    // Only closures have function type in Dart 2.
    return null;
  }
  MemberEntity call =
      elementEnvironment.lookupLocalClassMember(cls, Identifiers.call);
  if (call != null && call.isFunction) {
    FunctionEntity callFunction = call;
    FunctionType callType = elementEnvironment.getFunctionType(callFunction);
    return new ClassFunctionType(callFunction, callType, signatureFunction);
  }
  return null;
}

class RuntimeTypesEncoderImpl implements RuntimeTypesEncoder {
  final Namer namer;
  final ElementEnvironment _elementEnvironment;
  final CommonElements commonElements;
  final TypeRepresentationGenerator _representationGenerator;
  final RuntimeTypesNeed _rtiNeed;

  RuntimeTypesEncoderImpl(this.namer, NativeBasicData nativeData,
      this._elementEnvironment, this.commonElements, this._rtiNeed)
      : _representationGenerator =
            new TypeRepresentationGenerator(namer, nativeData);

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

  /// Returns the JavaScript template to determine at runtime if a type object
  /// is a FutureOr type.
  @override
  jsAst.Template get templateForIsFutureOrType {
    return _representationGenerator.templateForIsFutureOrType;
  }

  /// Returns the JavaScript template to determine at runtime if a type object
  /// is the void type.
  @override
  jsAst.Template get templateForIsVoidType {
    return _representationGenerator.templateForIsVoidType;
  }

  /// Returns the JavaScript template to determine at runtime if a type object
  /// is the dynamic type.
  @override
  jsAst.Template get templateForIsDynamicType {
    return _representationGenerator.templateForIsDynamicType;
  }

  @override
  jsAst.Template get templateForIsJsInteropTypeArgument {
    return _representationGenerator.templateForIsJsInteropTypeArgument;
  }

  @override
  jsAst.Expression getTypeRepresentation(
      Emitter emitter, DartType type, OnVariableCallback onVariable,
      [ShouldEncodeTypedefCallback shouldEncodeTypedef]) {
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
    if (contextClass != null &&
        // We only generate folding using 'computeSignature' if [contextClass]
        // has reified type arguments. The 'computeSignature' function might not
        // be emitted (if it's not needed elsewhere) and the generated signature
        // will have `undefined` as its type variables in any case.
        //
        // This is needed specifically for --lax-runtime-type-to-string which
        // may require a signature on a method that uses class type variables
        // while at the same time not needing type arguments on the class.
        _rtiNeed.classNeedsTypeArguments(contextClass)) {
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

  /// Compute a JavaScript expression that describes the necessary substitution
  /// for type arguments in a subtype test.
  ///
  /// The result can be:
  ///  1) `null`, if no substituted check is necessary, because the type
  ///     variables are the same or there are no type variables in the class
  ///     that is checked for.
  ///  2) A list expression describing the type arguments to be used in the
  ///     subtype check, if the type arguments to be used in the check do not
  ///     depend on the type arguments of the object.
  ///  3) A function mapping the type variables of the object to be checked to
  ///     a list expression.
  @override
  jsAst.Expression getSubstitutionCode(
      Emitter emitter, Substitution substitution) {
    if (substitution.isTrivial) {
      return new jsAst.LiteralNull();
    }

    if (substitution.isJsInterop) {
      return js(
          'function() { return # }',
          _representationGenerator
              .getJsInteropTypeArguments(substitution.length));
    }

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
    implements DartTypeVisitor<jsAst.Expression, Emitter> {
  final Namer namer;
  final NativeBasicData _nativeData;

  OnVariableCallback onVariable;
  ShouldEncodeTypedefCallback shouldEncodeTypedef;
  Map<TypeVariableType, jsAst.Expression> typedefBindings;
  List<FunctionTypeVariable> functionTypeVariables = <FunctionTypeVariable>[];

  TypeRepresentationGenerator(this.namer, this._nativeData);

  /// Creates a type representation for [type]. [onVariable] is called to
  /// provide the type representation for type variables.
  jsAst.Expression getTypeRepresentation(
      Emitter emitter,
      DartType type,
      OnVariableCallback onVariable,
      ShouldEncodeTypedefCallback encodeTypedef) {
    assert(typedefBindings == null);
    this.onVariable = onVariable;
    this.shouldEncodeTypedef =
        (encodeTypedef != null) ? encodeTypedef : (TypedefType type) => false;
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

  jsAst.Expression getVoidValue() => js('-1');

  jsAst.Expression getJsInteropTypeArgumentValue() => js('-2');
  @override
  jsAst.Expression visit(DartType type, Emitter emitter) =>
      type.accept(this, emitter);

  jsAst.Expression visitTypeVariableType(
      TypeVariableType type, Emitter emitter) {
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

  jsAst.Expression getJsInteropTypeArguments(int count,
      {jsAst.Expression name}) {
    List<jsAst.Expression> elements = <jsAst.Expression>[];
    if (name != null) {
      elements.add(name);
    }
    for (int i = 0; i < count; i++) {
      elements.add(getJsInteropTypeArgumentValue());
    }
    return new jsAst.ArrayInitializer(elements);
  }

  jsAst.Expression visitInterfaceType(InterfaceType type, Emitter emitter) {
    jsAst.Expression name = getJavaScriptClassName(type.element, emitter);
    jsAst.Expression result;
    if (type.typeArguments.isEmpty) {
      result = name;
    } else {
      // Visit all type arguments. This is done even for jsinterop classes to
      // enforce the invariant that [onVariable] is called for each type
      // variable in the type.
      result = visitList(type.typeArguments, emitter, head: name);
      if (_nativeData.isJsInteropClass(type.element)) {
        // Replace type arguments of generic jsinterop classes with 'any' type.
        result =
            getJsInteropTypeArguments(type.typeArguments.length, name: name);
      }
    }
    return result;
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

  /// Returns the JavaScript template to determine at runtime if a type object
  /// is a FutureOr type.
  jsAst.Template get templateForIsFutureOrType {
    return jsAst.js.expressionTemplateFor("'${namer.futureOrTag}' in #");
  }

  /// Returns the JavaScript template to determine at runtime if a type object
  /// is the void type.
  jsAst.Template get templateForIsVoidType {
    return jsAst.js.expressionTemplateFor("# === -1");
  }

  /// Returns the JavaScript template to determine at runtime if a type object
  /// is the dynamic type.
  jsAst.Template get templateForIsDynamicType {
    return jsAst.js.expressionTemplateFor("# == null");
  }

  jsAst.Template get templateForIsJsInteropTypeArgument {
    return jsAst.js.expressionTemplateFor("# === -2");
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

    if (!type.returnType.treatAsDynamic) {
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

  jsAst.Expression visitVoidType(VoidType type, Emitter emitter) {
    return getVoidValue();
  }

  jsAst.Expression visitTypedefType(TypedefType type, Emitter emitter) {
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
        typedefBindings[variable] = onVariable(variable);
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

  @override
  jsAst.Expression visitFutureOrType(FutureOrType type, Emitter emitter) {
    List<jsAst.Property> properties = <jsAst.Property>[];

    void addProperty(String name, jsAst.Expression value) {
      properties.add(new jsAst.Property(js.string(name), value));
    }

    // Type representations for FutureOr have a property which is a tag marking
    // them as FutureOr types. The value is not used, so '1' is just a dummy.
    addProperty(namer.futureOrTag, js.number(1));
    if (!type.typeArgument.treatAsDynamic) {
      addProperty(namer.futureOrTypeTag, visit(type.typeArgument, emitter));
    }

    return new jsAst.ObjectInitializer(properties);
  }
}

class TypeCheckMapping implements TypeChecks {
  final Map<ClassEntity, ClassChecks> map = new Map<ClassEntity, ClassChecks>();

  ClassChecks operator [](ClassEntity element) {
    ClassChecks result = map[element];
    return result != null ? result : const ClassChecks.empty();
  }

  void operator []=(ClassEntity element, ClassChecks checks) {
    map[element] = checks;
  }

  Iterable<ClassEntity> get classes => map.keys;

  String toString() {
    StringBuffer sb = new StringBuffer();
    for (ClassEntity holder in classes) {
      for (TypeCheck check in this[holder].checks) {
        sb.write('${holder.name} <: ${check.cls.name}, ');
      }
    }
    return '[$sb]';
  }
}

class ArgumentCollector extends DartTypeVisitor<dynamic, bool> {
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

  visitTypedefType(TypedefType type, bool isTypeArgument) {
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

class FunctionArgumentCollector extends DartTypeVisitor<dynamic, bool> {
  final Set<ClassEntity> classes = new Set<ClassEntity>();

  FunctionArgumentCollector();

  collect(DartType type, {bool inFunctionType: false}) {
    visit(type, inFunctionType);
  }

  collectAll(Iterable<DartType> types, {bool inFunctionType: false}) {
    for (DartType type in types) {
      visit(type, inFunctionType);
    }
  }

  visitTypedefType(TypedefType type, bool inFunctionType) {
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
    collectAll(type.typeVariables.map((type) => type.bound),
        inFunctionType: true);
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
  final bool isTrivial;
  final bool isFunction;
  final List<DartType> arguments;
  final List<DartType> parameters;
  final int length;

  const Substitution.trivial()
      : isTrivial = true,
        isFunction = false,
        length = null,
        arguments = const <DartType>[],
        parameters = const <DartType>[];

  Substitution.list(this.arguments)
      : isTrivial = false,
        isFunction = false,
        length = null,
        parameters = const <DartType>[];

  Substitution.function(this.arguments, this.parameters)
      : isTrivial = false,
        isFunction = true,
        length = null;

  Substitution.jsInterop(this.length)
      : isTrivial = false,
        isFunction = false,
        arguments = const <DartType>[],
        parameters = const <DartType>[];

  bool get isJsInterop => length != null;

  String toString() => 'Substitution(isTrivial=$isTrivial,'
      'isFunction=$isFunction,isJsInterop=$isJsInterop,arguments=$arguments,'
      'parameters=$parameters,length=$length)';
}

/// A pair of a class that we need a check against and the type argument
/// substitution for this check.
class TypeCheck {
  final ClassEntity cls;
  final bool needsIs;
  final Substitution substitution;
  final int hashCode = _nextHash = (_nextHash + 100003).toUnsigned(30);
  static int _nextHash = 0;

  TypeCheck(this.cls, this.substitution, {this.needsIs: true});

  String toString() =>
      'TypeCheck(cls=$cls,needsIs=$needsIs,substitution=$substitution)';
}

enum TypeVisitorState { direct, typeArgument, typeLiteral }

class TypeVisitor extends DartTypeVisitor<void, TypeVisitorState> {
  Set<FunctionTypeVariable> _visitedFunctionTypeVariables =
      new Set<FunctionTypeVariable>();

  final void Function(ClassEntity entity, {TypeVisitorState state}) onClass;
  final void Function(TypeVariableEntity entity, {TypeVisitorState state})
      onTypeVariable;
  final void Function(FunctionType type, {TypeVisitorState state})
      onFunctionType;

  TypeVisitor({this.onClass, this.onTypeVariable, this.onFunctionType});

  visitType(DartType type, TypeVisitorState state) => type.accept(this, state);

  visitTypes(List<DartType> types, TypeVisitorState state) {
    for (DartType type in types) {
      visitType(type, state);
    }
  }

  @override
  void visitTypeVariableType(TypeVariableType type, TypeVisitorState state) {
    if (onTypeVariable != null) {
      onTypeVariable(type.element, state: state);
    }
  }

  @override
  visitInterfaceType(InterfaceType type, TypeVisitorState state) {
    if (onClass != null) {
      onClass(type.element, state: state);
    }
    visitTypes(
        type.typeArguments,
        state == TypeVisitorState.typeLiteral
            ? state
            : TypeVisitorState.typeArgument);
  }

  @override
  visitFunctionType(FunctionType type, TypeVisitorState state) {
    if (onFunctionType != null) {
      onFunctionType(type, state: state);
    }
    // Visit all nested types as type arguments; these types are not runtime
    // instances but runtime type representations.
    state = state == TypeVisitorState.typeLiteral
        ? state
        : TypeVisitorState.typeArgument;
    visitType(type.returnType, state);
    visitTypes(type.parameterTypes, state);
    visitTypes(type.optionalParameterTypes, state);
    visitTypes(type.namedParameterTypes, state);
    _visitedFunctionTypeVariables.removeAll(type.typeVariables);
  }

  @override
  visitTypedefType(TypedefType type, TypeVisitorState state) {
    visitType(type.unaliased, state);
  }

  @override
  visitFunctionTypeVariable(FunctionTypeVariable type, TypeVisitorState state) {
    if (_visitedFunctionTypeVariables.add(type)) {
      visitType(type.bound, state);
    }
  }
}

/// [TypeCheck]s need for a single class.
class ClassChecks {
  final Map<ClassEntity, TypeCheck> _map;

  final ClassFunctionType functionType;

  ClassChecks(this.functionType) : _map = <ClassEntity, TypeCheck>{};

  const ClassChecks.empty()
      : _map = const <ClassEntity, TypeCheck>{},
        functionType = null;

  void add(TypeCheck check) {
    _map[check.cls] = check;
  }

  TypeCheck operator [](ClassEntity cls) => _map[cls];

  Iterable<TypeCheck> get checks => _map.values;

  String toString() {
    return 'ClassChecks($checks)';
  }
}

/// Data needed for generating a signature function for the function type of
/// a class.
class ClassFunctionType {
  /// The `call` function that defines the function type.
  final FunctionEntity callFunction;

  /// The type of the `call` function.
  final FunctionType callType;

  /// The signature function for the function type.
  ///
  /// This is used for Dart 2.
  final FunctionEntity signatureFunction;

  ClassFunctionType(this.callFunction, this.callType, this.signatureFunction);
}

/// Runtime type usage for a class.
class ClassUse {
  /// Whether the class is directly or indirectly instantiated.
  ///
  /// For instance `A` and `B` in:
  ///
  ///     class A {}
  ///     class B extends A {}
  ///     main() => new B();
  ///
  bool instance = false;

  /// Whether the class is directly instantiated.
  ///
  /// For instance `B` in:
  ///
  ///     class A {}
  ///     class B extends A {}
  ///     main() => new B();
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
  ///     main() => new List<A>() is List<String>;
  ///
  bool typeArgument = false;

  /// Whether the class is checked as a type argument at runtime.
  ///
  /// For instance `A` in:
  ///
  ///     class A {}
  ///     main() => new List<String>() is List<A>;
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
  ClassFunctionType functionType;

  /// `true` if the class is 'live' either through instantiation or use in
  /// type arguments.
  bool get isLive => directInstance || typeArgument;

  String toString() {
    List<String> properties = <String>[];
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
