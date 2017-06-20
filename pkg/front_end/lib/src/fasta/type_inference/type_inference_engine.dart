// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:front_end/src/base/instrumentation.dart';
import 'package:front_end/src/dependency_walker.dart' as dependencyWalker;
import 'package:front_end/src/fasta/errors.dart';
import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_listener.dart';
import 'package:front_end/src/fasta/type_inference/type_inferrer.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_environment.dart';
import 'package:kernel/ast.dart'
    show Class, DartType, DynamicType, Field, InterfaceType, Member, Procedure;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_algebra.dart';

/// Data structure for tracking dependencies among fields, getters, and setters
/// that require type inference.
///
/// TODO(paulberry): see if it's possible to make this class more lightweight
/// by changing the API so that the walker is passed to computeDependencies().
/// (This should allow us to drop the _typeInferenceEngine field).
class AccessorNode extends dependencyWalker.Node<AccessorNode> {
  final TypeInferenceEngineImpl _typeInferenceEngine;

  final KernelMember member;

  bool isImmediatelyEvident = false;

  AccessorState state = AccessorState.NotInferredYet;

  /// If [state] is [AccessorState.Inferring], and type inference for this
  /// accessor is waiting on type inference of some other accessor, the accessor
  /// that is being waited on.
  ///
  /// Otherwise `null`.
  AccessorNode currentDependency;

  final overrides = <Member>[];

  final crossOverrides = <Member>[];

  AccessorNode(this._typeInferenceEngine, this.member);

  get candidateOverrides => overrides.isNotEmpty ? overrides : crossOverrides;

  @override
  bool get isEvaluated => state == AccessorState.Inferred;

  @override
  List<AccessorNode> computeDependencies() {
    return _typeInferenceEngine.computeAccessorDependencies(this);
  }

  @override
  String toString() => member.toString();
}

/// Enum tracking the type inference state of an accessor.
enum AccessorState {
  /// The accessor's type has not been inferred yet.
  NotInferredYet,

  /// Type inference is in progress for the accessor.
  ///
  /// This means that code is currently on the stack which is attempting to
  /// determine the type of the accessor.
  Inferring,

  /// The accessor's type has been inferred.
  Inferred
}

/// Keeps track of the global state for the type inference that occurs outside
/// of method bodies and initalizers.
///
/// This class describes the interface for use by clients of type inference
/// (e.g. DietListener).  Derived classes should derive from
/// [TypeInferenceEngineImpl].
abstract class TypeInferenceEngine {
  ClassHierarchy get classHierarchy;

  CoreTypes get coreTypes;

  /// Creates a type inferrer for use inside of a method body declared in a file
  /// with the given [uri].
  TypeInferrer createLocalTypeInferrer(
      Uri uri, TypeInferenceListener listener, InterfaceType thisType);

  /// Creates a [TypeInferrer] object which is ready to perform type inference
  /// on the given [field].
  TypeInferrer createTopLevelTypeInferrer(TypeInferenceListener listener,
      InterfaceType thisType, KernelMember member);

  /// Performs the second phase of top level initializer inference, which is to
  /// visit all accessors and top level variables that were passed to
  /// [recordAccessor] in topologically-sorted order and assign their types.
  void finishTopLevel();

  /// Gets ready to do top level type inference for the program having the given
  /// [hierarchy], using the given [coreTypes].
  void prepareTopLevel(CoreTypes coreTypes, ClassHierarchy hierarchy);

  /// Records that the given initializing [formal] will need top level type
  /// inference.
  void recordInitializingFormal(KernelVariableDeclaration formal);

  /// Records that the given [member] will need top level type inference.
  void recordMember(KernelMember member);
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

  final initializingFormals = <KernelVariableDeclaration>[];

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
        var dep = KernelMember.getAccessorNode(override);
        if (dep != null) dependencies.add(dep);
      }
      accessorNode.isImmediatelyEvident = true;
      return dependencies;
    }

    // Otherwise its dependencies are based on the initializer expression.
    var member = accessorNode.member;
    if (member is KernelField) {
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
        var collector = new KernelDependencyCollector();
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

  /// Creates an [AccessorNode] to track dependencies of the given [member].
  AccessorNode createAccessorNode(KernelMember member);

  @override
  void finishTopLevel() {
    for (var accessorNode in accessorNodes) {
      if (fusedTopLevelInference) {
        assert(expandedTopLevelInference);
        inferAccessorFused(accessorNode, null);
      } else {
        if (accessorNode.isEvaluated) continue;
        new _AccessorWalker().walk(accessorNode);
      }
    }
    for (var formal in initializingFormals) {
      formal.type = _inferInitializingFormalType(formal);
    }
  }

  /// Retrieve the [TypeInferrer] for the given [member], which was created by
  /// a previous call to [createTopLevelTypeInferrer].
  TypeInferrerImpl getMemberTypeInferrer(KernelMember member);

  /// Performs type inference on the given [accessorNode].
  void inferAccessor(AccessorNode accessorNode) {
    assert(accessorNode.state == AccessorState.NotInferredYet);
    accessorNode.state = AccessorState.Inferring;
    var member = accessorNode.member;
    if (strongMode) {
      var inferredType = tryInferAccessorByInheritance(accessorNode);
      var typeInferrer = getMemberTypeInferrer(member);
      if (inferredType == null) {
        if (member is KernelField) {
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
      if (accessorNode.state == AccessorState.Inferred) {
        // A circularity must have been detected; at the time it was detected,
        // inference for this node was completed.
        return;
      }
      member.setInferredType(this, typeInferrer.uri, inferredType);
    }
    accessorNode.state = AccessorState.Inferred;
    // TODO(paulberry): if type != null, then check that the type of the
    // initializer is assignable to it.
    // TODO(paulberry): the following is a hack so that outlines don't contain
    // initializers.  But it means that we rebuild the initializers when doing
    // a full compile.  There should be a better way.
    if (member is KernelField) {
      member.initializer = null;
    }
  }

  /// Makes a note that the given [accessorNode] is part of a circularity, so
  /// its type can't be inferred.
  void inferAccessorCircular(AccessorNode accessorNode) {
    var member = accessorNode.member;
    // TODO(paulberry): report the appropriate error.
    var uri = getMemberTypeInferrer(member).uri;
    accessorNode.state = AccessorState.Inferred;
    member.setInferredType(this, uri, const DynamicType());
    // TODO(paulberry): the following is a hack so that outlines don't contain
    // initializers.  But it means that we rebuild the initializers when doing
    // a full compile.  There should be a better way.
    if (member is KernelField) {
      member.initializer = null;
    }
  }

  /// Performs fused type inference on the given [accessorNode].
  void inferAccessorFused(AccessorNode accessorNode, AccessorNode dependant) {
    switch (accessorNode.state) {
      case AccessorState.Inferred:
        // Already inferred.  Nothing to do.
        break;
      case AccessorState.Inferring:
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
      case AccessorState.NotInferredYet:
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

  @override
  void prepareTopLevel(CoreTypes coreTypes, ClassHierarchy hierarchy) {
    this.coreTypes = coreTypes;
    this.classHierarchy = hierarchy;
    this.typeSchemaEnvironment =
        new TypeSchemaEnvironment(coreTypes, hierarchy, strongMode);
  }

  @override
  void recordInitializingFormal(KernelVariableDeclaration formal) {
    initializingFormals.add(formal);
  }

  @override
  void recordMember(KernelMember member) {
    accessorNodes.add(createAccessorNode(member));
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

  DartType _computeOverriddenAccessorType(
      Member override, AccessorNode accessorNode) {
    if (fusedTopLevelInference) {
      AccessorNode dependency = KernelMember.getAccessorNode(override);
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
      throw internalError(
          'Unexpected overridden member type: ${override.runtimeType}');
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

  DartType _inferInitializingFormalType(KernelVariableDeclaration formal) {
    assert(KernelVariableDeclaration.isImplicitlyTyped(formal));
    Class enclosingClass = formal.parent.parent.parent;
    for (var field in enclosingClass.fields) {
      if (field.name.name == formal.name) {
        return field.type;
      }
    }
    // No matching field.  The error should be reported elsewhere.
    return const DynamicType();
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
