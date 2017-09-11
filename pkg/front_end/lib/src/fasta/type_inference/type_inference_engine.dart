// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:front_end/src/base/instrumentation.dart';
import 'package:front_end/src/dependency_walker.dart' as dependencyWalker;
import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart';
import 'package:front_end/src/fasta/problems.dart' show unhandled;
import 'package:front_end/src/fasta/type_inference/type_inference_listener.dart';
import 'package:front_end/src/fasta/type_inference/type_inferrer.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_environment.dart';
import 'package:kernel/ast.dart'
    show
        Class,
        DartType,
        DynamicType,
        Field,
        FormalSafety,
        FunctionType,
        InterfaceSafety,
        InterfaceType,
        Location,
        Member,
        Procedure,
        TypeParameter,
        TypeParameterType,
        VariableDeclaration;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_algebra.dart';

import '../deprecated_problems.dart' show Crash;
import '../messages.dart' show getLocationFromNode;

/// Data structure for tracking dependencies among fields, getters, and setters
/// that require type inference.
///
/// TODO(paulberry): see if it's possible to make this class more lightweight
/// by changing the API so that the walker is passed to computeDependencies().
/// (This should allow us to drop the _typeInferenceEngine field).
class AccessorNode extends dependencyWalker.Node<AccessorNode> {
  final TypeInferenceEngineImpl _typeInferenceEngine;

  final ShadowMember member;

  bool isImmediatelyEvident = false;

  InferenceState state = InferenceState.NotInferredYet;

  /// If [state] is [InferenceState.Inferring], and type inference for this
  /// accessor is waiting on type inference of some other accessor, the accessor
  /// that is being waited on.
  ///
  /// Otherwise `null`.
  AccessorNode currentDependency;

  final overrides = <Member>[];

  final crossOverrides = <Member>[];

  AccessorNode(this._typeInferenceEngine, this.member);

  List<Member> get candidateOverrides {
    if (isTrivialSetter) {
      return const [];
    } else if (overrides.isNotEmpty) {
      return overrides;
    } else {
      return crossOverrides;
    }
  }

  @override
  bool get isEvaluated => state == InferenceState.Inferred;

  /// Indicates whether this accessor is a setter for which the only type we
  /// have to infer is its return type.
  bool get isTrivialSetter {
    var member = this.member;
    if (member is ShadowProcedure &&
        member.isSetter &&
        member.function != null) {
      var parameters = member.function.positionalParameters;
      return parameters.length > 0 &&
          !ShadowVariableDeclaration.isImplicitlyTyped(parameters[0]);
    }
    return false;
  }

  @override
  List<AccessorNode> computeDependencies() {
    return _typeInferenceEngine.computeAccessorDependencies(this);
  }

  @override
  String toString() => member.toString();
}

/// Enum tracking the type inference state of an accessor or method.
enum InferenceState {
  /// The accessor or method's type has not been inferred yet.
  NotInferredYet,

  /// Type inference is in progress for the accessor or method.
  ///
  /// This means that code is currently on the stack which is attempting to
  /// determine the type of the accessor or method.
  Inferring,

  /// The accessor or method's type has been inferred.
  Inferred
}

/// Data structure for tracking dependencies among methods that require type
/// inference.
class MethodNode {
  final ShadowProcedure procedure;

  InferenceState state = InferenceState.NotInferredYet;

  final overrides = <Procedure>[];

  MethodNode(this.procedure);

  @override
  String toString() => procedure.toString();
}

/// Keeps track of the global state for the type inference that occurs outside
/// of method bodies and initializers.
///
/// This class describes the interface for use by clients of type inference
/// (e.g. DietListener).  Derived classes should derive from
/// [TypeInferenceEngineImpl].
abstract class TypeInferenceEngine {
  ClassHierarchy get classHierarchy;

  CoreTypes get coreTypes;

  /// Annotates the formal parameters of any methods in [cls] to indicate the
  /// circumstances in which they require runtime type checks.
  void computeFormalSafety(Class cls);

  /// Creates a disabled type inferrer (intended for debugging and profiling
  /// only).
  TypeInferrer createDisabledTypeInferrer();

  /// Creates a type inferrer for use inside of a method body declared in a file
  /// with the given [uri].
  TypeInferrer createLocalTypeInferrer(
      Uri uri, TypeInferenceListener listener, InterfaceType thisType);

  /// Creates a [TypeInferrer] object which is ready to perform type inference
  /// on the given [field].
  TypeInferrer createTopLevelTypeInferrer(TypeInferenceListener listener,
      InterfaceType thisType, ShadowMember member);

  /// Performs the second phase of top level initializer inference, which is to
  /// visit all accessors and top level variables that were passed to
  /// [recordAccessor] in topologically-sorted order and assign their types.
  void finishTopLevel();

  /// Gets ready to do top level type inference for the program having the given
  /// [hierarchy], using the given [coreTypes].
  void prepareTopLevel(CoreTypes coreTypes, ClassHierarchy hierarchy);

  /// Records that the given initializing [formal] will need top level type
  /// inference.
  void recordInitializingFormal(ShadowVariableDeclaration formal);

  /// Records that the given [member] will need top level type inference.
  void recordMember(ShadowMember member);
}

/// Derived class containing generic implementations of
/// [TypeInferenceEngineImpl].
///
/// This class contains as much of the implementation of type inference as
/// possible without knowing the identity of the type parameter.  It defers to
/// abstract methods for everything else.
abstract class TypeInferenceEngineImpl extends TypeInferenceEngine {
  /// Enables "expanded top level inference", which allows top level inference
  /// to support all expressions, not just those defined as "immediately
  /// evident" by https://github.com/dart-lang/sdk/pull/28218.
  static const bool expandedTopLevelInference = true;

  /// Enables "fused top level inference", which fuses dependency collection and
  /// type inference of a field into a single step (a dependency is detected at
  /// the time type inference attempts to read the depended-upon type, and this
  /// triggers a recursive evaluation of the depended-upon type).
  ///
  /// This avoids some unnecessary dependencies, since we now know for sure
  /// whether a dependency will be needed at the time we evaluate it.
  ///
  /// Requires [expandedTopLevelInference] to be `true`.
  static const bool fusedTopLevelInference = true;

  /// Enables "full top level inference", which allows a top level or static
  /// field's inferred type to depend on the type of an instance field (provided
  /// there are no circular dependencies).
  ///
  /// Requires [fusedTopLevelInference] to be `true`.
  static const bool fullTopLevelInference = true;

  final Instrumentation instrumentation;

  final bool strongMode;

  final accessorNodes = <AccessorNode>[];

  final methodNodes = <MethodNode>[];

  final initializingFormals = <ShadowVariableDeclaration>[];

  @override
  CoreTypes coreTypes;

  @override
  ClassHierarchy classHierarchy;

  TypeSchemaEnvironment typeSchemaEnvironment;

  TypeInferenceEngineImpl(this.instrumentation, this.strongMode);

  /// Computes type inference dependencies for the given [accessorNode].
  List<AccessorNode> computeAccessorDependencies(AccessorNode accessorNode) {
    // If the accessor's type is going to be determined by inheritance, then its
    // dependencies are determined by inheritance too.
    var candidateOverrides = accessorNode.candidateOverrides;
    if (candidateOverrides.isNotEmpty) {
      var dependencies = <AccessorNode>[];
      for (var override in candidateOverrides) {
        var dep = ShadowMember.getAccessorNode(override);
        if (dep != null) dependencies.add(dep);
      }
      accessorNode.isImmediatelyEvident = true;
      return dependencies;
    }

    // Otherwise its dependencies are based on the initializer expression.
    var member = accessorNode.member;
    if (member is ShadowField) {
      if (expandedTopLevelInference) {
        // In expanded top level inference, we determine the dependencies by
        // doing a "dry run" of top level inference and recording which static
        // fields were accessed.
        var typeInferrer = getMemberTypeInferrer(member);
        if (typeInferrer == null) {
          // This can happen when there are errors in the field declaration.
          return const [];
        } else {
          typeInferrer.startDryRun();
          typeInferrer.listener.dryRunEnter(member.initializer);
          typeInferrer.inferFieldTopLevel(member, null, true);
          typeInferrer.listener.dryRunExit(member.initializer);
          accessorNode.isImmediatelyEvident = true;
          return typeInferrer.finishDryRun();
        }
      } else {
        // In non-expanded top level inference, we determine the dependencies by
        // calling `collectDependencies`; as a side effect this flags any
        // expressions that are not "immediately evident".
        // TODO(paulberry): get rid of this mode once we are sure we no longer
        // need it.
        var collector = new ShadowDependencyCollector();
        collector.collectDependencies(member.initializer);
        accessorNode.isImmediatelyEvident = collector.isImmediatelyEvident;
        return collector.dependencies;
      }
    } else {
      // Member is a getter/setter that doesn't override anything, so we can't
      // infer a type for it; therefore it has no dependencies.
      return const [];
    }
  }

  @override
  void computeFormalSafety(Class cls) {
    // First mark all covariant formals as unsafe.
    // TODO(paulberry): also handle fields
    for (ShadowProcedure procedure in cls.procedures) {
      if (procedure.isStatic) continue;
      if (procedure.isAbstract) continue;
      void setSafety(VariableDeclaration formal) {
        if (formal.isCovariant) {
          formal.formalSafety = FormalSafety.unsafe;
          instrumentation?.record(Uri.parse(cls.fileUri), formal.fileOffset,
              'checkFormal', new InstrumentationValueLiteral('unsafe'));
        }
      }

      procedure.function.positionalParameters.forEach(setSafety);
      procedure.function.namedParameters.forEach(setSafety);
    }

    // If any method in the class has a formal parameter whose type depends on
    // one of the class's type parameters, then there may be a mismatch between
    // the type guarantee made by the caller and the type guarantee expected by
    // the callee.  For instance, consider the code:
    //
    // class A<T> {
    //   foo(List<T> argument) {}
    // }
    // class B extends A<num> {
    //   foo(List<num> argument) {}
    // }
    // void bar(A<num> a, List<num> l) {
    //   a.foo(l);
    // }
    //
    // At the call site (in `bar`), the type system guarantees that the
    // value passed to `foo` will be an instance of `List<num>`.  But since
    // the reified type of `a` at runtime might be a subtype of `A<num>`,
    // such as `A<int>`, this is not a sufficient guarantee to ensure
    // soundness.  Therefore the type of the argument will have to be
    // checked at runtime (unless the back end can prove the check is
    // unnecessary, e.g. through whole program analysis).
    //
    // To determine whether the check is necessary, we determine, for each
    // formal parameter of each interface, the worst case set of types that
    // might be passed to that interface at runtime.  So in the example above,
    // since T has no bound, at worst case the type `List<Object>` might be
    // passed to A.foo.  Since `List<T>` is not a supertype of `List<Object>`,
    // we mark the formal parameter as semi-safe and semi-typed.
    //
    // For the semi-safe annotation, we also have to check all of thes that
    // might come in through interfaces that the concrete method implements. So
    // in the example above, `B.foo` needs a semi-typed annotation, since it may
    // be passed a `List<Object>` via the interface `A.foo`, and `List<num>` is
    // not a supertype of `List<Object>`.
    if (cls.typeParameters.isNotEmpty) {
      // Compute a substitution that illustrates the set of types the class
      // might have at runtime.  We call this the "pessimization" because it
      // substitutes the top of the class hierarchy for each type parameter, as
      // a worst case scenario.
      // TODO(paulberry): consider whether we could do better by substituting
      // type parameter bounds (this would require being careful with F-bounded
      // type parameters, so it might not be worth it)
      var pessimization = Substitution.fromPairs(cls.typeParameters,
          new List.filled(cls.typeParameters.length, const DynamicType()));
      // TODO(paulberry): also handle fields
      for (ShadowProcedure procedure in cls.procedures) {
        if (procedure.isStatic) continue;
        void computeIncomingTypes(
            int fileOffset,
            DartType declaredType,
            FormalSafety formalSafety,
            void setAdditionalIncomingTypes(List<DartType> types),
            void setInterfaceSafety(InterfaceSafety safety),
            void setFormalSafety(FormalSafety formalSafety)) {
          var pessimisticType = pessimization.substituteType(declaredType);
          if (!typeSchemaEnvironment.isSubtypeOf(
              pessimisticType, declaredType)) {
            setAdditionalIncomingTypes([pessimisticType]);
            setInterfaceSafety(InterfaceSafety.semiTyped);
            instrumentation?.record(Uri.parse(cls.fileUri), fileOffset,
                'checkInterface', new InstrumentationValueLiteral('semiTyped'));
            if (!procedure.isAbstract && formalSafety == FormalSafety.safe) {
              formalSafety = FormalSafety.semiSafe;
              instrumentation?.record(Uri.parse(cls.fileUri), fileOffset,
                  'checkFormal', new InstrumentationValueLiteral('semiSafe'));
            }
          }
        }

        void computeIncomingParameterTypes(VariableDeclaration formal) {
          ShadowVariableDeclaration shadowVariableDeclaration = formal;
          computeIncomingTypes(
              formal.fileOffset, formal.type, formal.formalSafety, (types) {
            shadowVariableDeclaration.additionalIncomingTypes = types;
          }, (safety) {
            formal.interfaceSafety = safety;
          }, (safety) {
            formal.formalSafety = safety;
          });
        }

        void computeIncomingTypeParameterTypes(TypeParameter typeParameter) {
          ShadowTypeParameter shadowTypeParameter = typeParameter;
          computeIncomingTypes(typeParameter.fileOffset, typeParameter.bound,
              typeParameter.formalSafety, (types) {
            shadowTypeParameter.additionalIncomingTypes = types;
          }, (safety) {
            typeParameter.interfaceSafety = safety;
          }, (safety) {
            typeParameter.formalSafety = safety;
          });
        }

        procedure.function.positionalParameters
            .forEach(computeIncomingParameterTypes);
        procedure.function.namedParameters
            .forEach(computeIncomingParameterTypes);
        procedure.function.typeParameters
            .forEach(computeIncomingTypeParameterTypes);
      }
    }

    // Now, propagate additional incoming types from overrides to determine
    // whether there are additional methods requiring a semi-safe annotation.
    void checkSafety(
        int fileOffset,
        List<DartType> declaredAdditionalIncomingTypes,
        List<DartType> interfaceAdditionalIncomingTypes,
        DartType declaredType,
        FormalSafety formalSafety,
        void addDeclaredAdditionalIncomingType(DartType type),
        void setFormalSafety(FormalSafety formalSafety)) {
      // TODO(paulberry): add support for generic methods (need to match up
      // method type parameters between the two methods)
      if (interfaceAdditionalIncomingTypes == null) return;
      for (var incomingType in interfaceAdditionalIncomingTypes) {
        if (typeSchemaEnvironment.isSubtypeOf(incomingType, declaredType)) {
          continue;
        }
        if (declaredAdditionalIncomingTypes != null &&
            declaredAdditionalIncomingTypes.any(
                (t) => typeSchemaEnvironment.isSubtypeOf(incomingType, t))) {
          continue;
        }
        addDeclaredAdditionalIncomingType(incomingType);
        if (formalSafety == FormalSafety.safe) {
          setFormalSafety(FormalSafety.semiSafe);
          instrumentation?.record(Uri.parse(cls.fileUri), fileOffset,
              'checkFormal', new InstrumentationValueLiteral('semiSafe'));
        }
      }
    }

    void checkParameterSafety(ShadowVariableDeclaration declaredFormal,
        VariableDeclaration interfaceFormal) {
      // TODO(paulberry): once additionalIncomingTypes is available from
      // VariableDeclaration, remove this "is" check.
      if (interfaceFormal is ShadowVariableDeclaration) {
        checkSafety(
            declaredFormal.fileOffset,
            declaredFormal.additionalIncomingTypes,
            interfaceFormal.additionalIncomingTypes,
            declaredFormal.type,
            declaredFormal.formalSafety, (type) {
          (declaredFormal.additionalIncomingTypes ??= <DartType>[]).add(type);
        }, (safety) {
          declaredFormal.formalSafety = safety;
        });
      }
    }

    void checkTypeParameterSafety(ShadowTypeParameter declaredTypeParameter,
        TypeParameter interfaceTypeParameter) {
      // TODO(paulberry): once additionalIncomingTypes is available from
      // TypeParameter, remove this "is" check.
      if (interfaceTypeParameter is ShadowTypeParameter) {
        checkSafety(
            declaredTypeParameter.fileOffset,
            declaredTypeParameter.additionalIncomingTypes,
            interfaceTypeParameter.additionalIncomingTypes,
            declaredTypeParameter.bound,
            declaredTypeParameter.formalSafety, (type) {
          (declaredTypeParameter.additionalIncomingTypes ??= <DartType>[])
              .add(type);
        }, (safety) {
          declaredTypeParameter.formalSafety = safety;
        });
      }
    }

    classHierarchy.forEachOverridePair(cls,
        (Member declaredMember, Member interfaceMember, bool isSetter) {
      if (declaredMember.isAbstract) return;
      if (!identical(declaredMember.enclosingClass, cls)) return;
      if (declaredMember.function == null || interfaceMember.function == null) {
        // TODO(paulberry): handle the case where declaredMember or
        // interfaceMember is a field.
        return;
      }
      for (int i = 0;
          i < declaredMember.function.positionalParameters.length &&
              i < interfaceMember.function.positionalParameters.length;
          i++) {
        checkParameterSafety(declaredMember.function.positionalParameters[i],
            interfaceMember.function.positionalParameters[i]);
      }
      for (var namedParameter in declaredMember.function.namedParameters) {
        var overriddenParameter =
            getNamedFormal(interfaceMember.function, namedParameter.name);
        if (overriddenParameter != null) {
          checkParameterSafety(namedParameter, overriddenParameter);
        }
      }
      for (int i = 0;
          i < declaredMember.function.typeParameters.length &&
              i < interfaceMember.function.typeParameters.length;
          i++) {
        checkTypeParameterSafety(declaredMember.function.typeParameters[i],
            interfaceMember.function.typeParameters[i]);
      }
    });
  }

  /// Creates an [AccessorNode] to track dependencies of the given [member].
  AccessorNode createAccessorNode(ShadowMember member);

  /// Creates a [MethodNode] to track dependencies of the given [procedure].
  MethodNode createMethodNode(ShadowProcedure procedure);

  @override
  void finishTopLevel() {
    for (var methodNode in methodNodes) {
      inferMethodIfNeeded(methodNode);
    }
    for (var accessorNode in accessorNodes) {
      if (fusedTopLevelInference) {
        assert(expandedTopLevelInference);
        inferAccessorFused(accessorNode, null);
      } else {
        if (accessorNode.isEvaluated) continue;
        new _AccessorWalker().walk(accessorNode);
      }
    }
    for (ShadowVariableDeclaration formal in initializingFormals) {
      try {
        formal.type = _inferInitializingFormalType(formal);
      } catch (e, s) {
        Location location = getLocationFromNode(formal);
        if (location == null) {
          rethrow;
        } else {
          throw new Crash(Uri.parse(location.file), formal.fileOffset, e, s);
        }
      }
    }
  }

  /// Retrieve the [TypeInferrer] for the given [member], which was created by
  /// a previous call to [createTopLevelTypeInferrer].
  TypeInferrerImpl getMemberTypeInferrer(ShadowMember member);

  /// Performs type inference on the given [accessorNode].
  void inferAccessor(AccessorNode accessorNode) {
    assert(accessorNode.state == InferenceState.NotInferredYet);
    accessorNode.state = InferenceState.Inferring;
    var member = accessorNode.member;
    if (strongMode) {
      var typeInferrer = getMemberTypeInferrer(member);
      if (member is ShadowProcedure && member.isSetter) {
        ShadowProcedure.inferSetterReturnType(member, this, typeInferrer.uri);
      }
      if (!accessorNode.isTrivialSetter) {
        var inferredType = tryInferAccessorByInheritance(accessorNode);
        if (inferredType == null) {
          if (member is ShadowField) {
            typeInferrer.isImmediatelyEvident = true;
            inferredType = accessorNode.isImmediatelyEvident
                ? typeInferrer.inferDeclarationType(
                    typeInferrer.inferFieldTopLevel(member, null, true))
                : const DynamicType();
            if (!typeInferrer.isImmediatelyEvident) {
              inferredType = const DynamicType();
            }
          } else {
            inferredType = const DynamicType();
          }
        }
        if (accessorNode.state == InferenceState.Inferred) {
          // A circularity must have been detected; at the time it was detected,
          // inference for this node was completed.
          return;
        }
        member.setInferredType(this, typeInferrer.uri, inferredType);
      }
    }
    accessorNode.state = InferenceState.Inferred;
    // TODO(paulberry): if type != null, then check that the type of the
    // initializer is assignable to it.
    // TODO(paulberry): the following is a hack so that outlines don't contain
    // initializers.  But it means that we rebuild the initializers when doing
    // a full compile.  There should be a better way.
    if (member is ShadowField) {
      member.initializer = null;
    }
  }

  /// Makes a note that the given [accessorNode] is part of a circularity, so
  /// its type can't be inferred.
  void inferAccessorCircular(AccessorNode accessorNode) {
    var member = accessorNode.member;
    // TODO(paulberry): report the appropriate error.
    var uri = getMemberTypeInferrer(member).uri;
    accessorNode.state = InferenceState.Inferred;
    member.setInferredType(this, uri, const DynamicType());
    // TODO(paulberry): the following is a hack so that outlines don't contain
    // initializers.  But it means that we rebuild the initializers when doing
    // a full compile.  There should be a better way.
    if (member is ShadowField) {
      member.initializer = null;
    }
  }

  /// Performs fused type inference on the given [accessorNode].
  void inferAccessorFused(AccessorNode accessorNode, AccessorNode dependant) {
    switch (accessorNode.state) {
      case InferenceState.Inferred:
        // Already inferred.  Nothing to do.
        break;
      case InferenceState.Inferring:
        // An accessor depends on itself (possibly by way of intermediate
        // accessors).  Mark all accessors involved as circular and infer a type
        // of `dynamic` for them.
        var node = accessorNode;
        while (node != null) {
          var nextNode = node.currentDependency;
          inferAccessorCircular(node);
          node.currentDependency = null;
          node = nextNode;
        }
        break;
      case InferenceState.NotInferredYet:
        // Mark the "dependant" accessor (if any) as depending on this one, and
        // invoke accessor inference for this node.
        dependant?.currentDependency = accessorNode;
        // All accessors are "immediately evident" when doing fused inference.
        accessorNode.isImmediatelyEvident = true;
        inferAccessor(accessorNode);
        dependant?.currentDependency = null;
        break;
    }
  }

  /// Performs type inference on the given [methodNode].
  void inferMethodIfNeeded(MethodNode methodNode) {
    switch (methodNode.state) {
      case InferenceState.Inferred:
        // Already inferred.  Nothing to do.
        break;
      case InferenceState.Inferring:
        // An method depends on itself (possibly by way of intermediate
        // methods).  This should never happen, because it would require a
        // circular class hierarchy (which Fasta prevents).
        dynamic parent = methodNode.procedure.parent;
        unhandled("Circular method inference", "inferMethodIfNeeded",
            methodNode.procedure.fileOffset, Uri.parse(parent.fileUri));
        break;
      case InferenceState.NotInferredYet:
        methodNode.state = InferenceState.Inferring;
        _inferMethod(methodNode);
        methodNode.state = InferenceState.Inferred;
        break;
    }
  }

  @override
  void prepareTopLevel(CoreTypes coreTypes, ClassHierarchy hierarchy) {
    this.coreTypes = coreTypes;
    this.classHierarchy = hierarchy;
    this.typeSchemaEnvironment =
        new TypeSchemaEnvironment(coreTypes, hierarchy, strongMode);
  }

  @override
  void recordInitializingFormal(ShadowVariableDeclaration formal) {
    initializingFormals.add(formal);
  }

  @override
  void recordMember(ShadowMember member) {
    if (member is ShadowProcedure && !member.isGetter && !member.isSetter) {
      methodNodes.add(createMethodNode(member));
    } else {
      accessorNodes.add(createAccessorNode(member));
    }
  }

  DartType tryInferAccessorByInheritance(AccessorNode accessorNode) {
    DartType inferredType;
    for (var override in accessorNode.candidateOverrides) {
      var nextInferredType =
          _computeOverriddenAccessorType(override, accessorNode);
      if (inferredType == null) {
        inferredType = nextInferredType;
      } else if (inferredType != nextInferredType) {
        // Overrides don't have matching types.
        // TODO(paulberry): report an error
        return const DynamicType();
      }
    }
    return inferredType;
  }

  List<FunctionType> _computeMethodOverriddenTypes(MethodNode methodNode) {
    var overriddenTypes = <FunctionType>[];
    for (var override in methodNode.overrides) {
      MethodNode overrideNode = ShadowProcedure.getMethodNode(override);
      if (overrideNode != null) {
        inferMethodIfNeeded(overrideNode);
      }
      if (override.function == null) {
        // This can happen if there are errors.  Just skip this override.
        continue;
      }
      var overriddenType = override.function.functionType;
      var superclass = override.enclosingClass;
      if (!superclass.typeParameters.isEmpty) {
        var thisClass = methodNode.procedure.enclosingClass;
        var superclassInstantiation = classHierarchy
            .getClassAsInstanceOf(thisClass, superclass)
            .asInterfaceType;
        overriddenType = Substitution
            .fromInterfaceType(superclassInstantiation)
            .substituteType(overriddenType);
      }
      var methodTypeParameters = methodNode.procedure.function.typeParameters;
      if (overriddenType.typeParameters.length != methodTypeParameters.length) {
        // Generic arity mismatch.  Don't do any inference for this method.
        // TODO(paulberry): report an error.
        return <FunctionType>[];
      } else if (overriddenType.typeParameters.isNotEmpty) {
        var substitutionMap = <TypeParameter, DartType>{};
        for (int i = 0; i < methodTypeParameters.length; i++) {
          substitutionMap[overriddenType.typeParameters[i]] =
              new TypeParameterType(methodTypeParameters[i]);
        }
        overriddenType = substituteTypeParams(
            overriddenType, substitutionMap, methodTypeParameters);
      }
      overriddenTypes.add(overriddenType);
    }
    return overriddenTypes;
  }

  DartType _computeOverriddenAccessorType(
      Member override, AccessorNode accessorNode) {
    if (fusedTopLevelInference) {
      AccessorNode dependency = ShadowMember.getAccessorNode(override);
      if (dependency != null) {
        inferAccessorFused(dependency, accessorNode);
      }
    }
    DartType overriddenType;
    if (override is Field) {
      overriddenType = override.type;
    } else if (override is Procedure) {
      // TODO(paulberry): handle the case where override needs its type
      // inferred first.
      if (override.isGetter) {
        overriddenType = override.getterType;
      } else {
        overriddenType = override.setterType;
      }
    } else {
      dynamic parent = override.parent;
      return unhandled(
          "${override.runtimeType}",
          "_computeOverriddenAccessorType",
          override.fileOffset,
          Uri.parse(parent.fileUri));
    }
    var superclass = override.enclosingClass;
    if (superclass.typeParameters.isEmpty) return overriddenType;
    var thisClass = accessorNode.member.enclosingClass;
    var superclassInstantiation = classHierarchy
        .getClassAsInstanceOf(thisClass, superclass)
        .asInterfaceType;
    return Substitution
        .fromInterfaceType(superclassInstantiation)
        .substituteType(overriddenType);
  }

  DartType _inferInitializingFormalType(ShadowVariableDeclaration formal) {
    assert(ShadowVariableDeclaration.isImplicitlyTyped(formal));
    var enclosingClass = formal.parent?.parent?.parent;
    if (enclosingClass is Class) {
      for (var field in enclosingClass.fields) {
        if (field.name.name == formal.name) {
          return field.type;
        }
      }
    }
    // No matching field, or something else has gone wrong (e.g. initializing
    // formal outside of a class declaration).  The error should be reported
    // elsewhere, so just infer `dynamic`.
    return const DynamicType();
  }

  void _inferMethod(MethodNode methodNode) {
    var typeInferrer = getMemberTypeInferrer(methodNode.procedure);

    // First collect types of overridden methods
    var overriddenTypes = _computeMethodOverriddenTypes(methodNode);

    // Now infer types.
    DartType matchTypes(Iterable<DartType> types) {
      if (!strongMode) return const DynamicType();
      var iterator = types.iterator;
      if (!iterator.moveNext()) {
        // No overridden types.  Infer `dynamic`.
        return const DynamicType();
      }
      var inferredType = iterator.current;
      while (iterator.moveNext()) {
        if (inferredType != iterator.current) {
          // TODO(paulberry): Types don't match.  Report an error.
          return const DynamicType();
        }
      }
      return inferredType;
    }

    if (ShadowProcedure.hasImplicitReturnType(methodNode.procedure)) {
      var inferredType =
          matchTypes(overriddenTypes.map((type) => type.returnType));
      instrumentation?.record(
          Uri.parse(typeInferrer.uri),
          methodNode.procedure.fileOffset,
          'topType',
          new InstrumentationValueForType(inferredType));
      methodNode.procedure.function.returnType = inferredType;
    }
    var positionalParameters =
        methodNode.procedure.function.positionalParameters;
    for (int i = 0; i < positionalParameters.length; i++) {
      if (ShadowVariableDeclaration
          .isImplicitlyTyped(positionalParameters[i])) {
        // Note that if the parameter is not present in the overridden method,
        // getPositionalParameterType treats it as dynamic.  This is consistent
        // with the behavior called for in the informal top level type inference
        // spec, which says:
        //
        //     If there is no corresponding parameter position in the overridden
        //     method to infer from and the signatures are compatible, it is
        //     treated as dynamic (e.g. overriding a one parameter method with a
        //     method that takes a second optional parameter).  Note: if there
        //     is no corresponding parameter position in the overriden method to
        //     infer from and the signatures are incompatible (e.g. overriding a
        //     one parameter method with a method that takes a second
        //     non-optional parameter), the inference result is not defined and
        //     tools are free to either emit an error, or to defer the error to
        //     override checking.
        var inferredType = matchTypes(
            overriddenTypes.map((type) => getPositionalParameterType(type, i)));
        instrumentation?.record(
            Uri.parse(typeInferrer.uri),
            positionalParameters[i].fileOffset,
            'topType',
            new InstrumentationValueForType(inferredType));
        positionalParameters[i].type = inferredType;
      }
    }
    var namedParameters = methodNode.procedure.function.namedParameters;
    for (int i = 0; i < namedParameters.length; i++) {
      if (ShadowVariableDeclaration.isImplicitlyTyped(namedParameters[i])) {
        var name = namedParameters[i].name;
        var inferredType = matchTypes(
            overriddenTypes.map((type) => getNamedParameterType(type, name)));
        instrumentation?.record(
            Uri.parse(typeInferrer.uri),
            namedParameters[i].fileOffset,
            'topType',
            new InstrumentationValueForType(inferredType));
        namedParameters[i].type = inferredType;
      }
    }
  }
}

/// Subtype of [dependencyWalker.DependencyWalker] which is specialized to
/// perform top level type inference.
class _AccessorWalker extends dependencyWalker.DependencyWalker<AccessorNode> {
  _AccessorWalker();

  @override
  void evaluate(AccessorNode f) {
    f._typeInferenceEngine.inferAccessor(f);
  }

  @override
  void evaluateScc(List<AccessorNode> scc) {
    // Mark every accessor as part of a circularity.
    for (var f in scc) {
      f._typeInferenceEngine.inferAccessorCircular(f);
    }
  }
}
