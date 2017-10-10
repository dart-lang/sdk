// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:front_end/src/base/instrumentation.dart';
import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart';
import 'package:front_end/src/fasta/problems.dart' show unhandled;
import 'package:front_end/src/fasta/type_inference/type_inference_listener.dart';
import 'package:front_end/src/fasta/type_inference/type_inferrer.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_environment.dart';
import 'package:kernel/ast.dart'
    show
        Class,
        DartType,
        DartTypeVisitor,
        DynamicType,
        Field,
        FunctionType,
        InterfaceType,
        Location,
        Member,
        Procedure,
        TypeParameter,
        TypeParameterType,
        TypedefType,
        VariableDeclaration;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_algebra.dart';

import '../deprecated_problems.dart' show Crash;
import '../messages.dart' show getLocationFromNode;

/// Data structure for tracking dependencies among fields, getters, and setters
/// that require type inference.
class AccessorNode extends InferenceNode {
  final TypeInferenceEngineImpl _typeInferenceEngine;

  final ShadowMember member;

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
  void resolveInternal() {
    var member = this.member;
    if (_typeInferenceEngine.strongMode) {
      var typeInferrer = _typeInferenceEngine.getMemberTypeInferrer(member);
      if (!isTrivialSetter) {
        var inferredType =
            _typeInferenceEngine.tryInferAccessorByInheritance(this);
        if (inferredType == null) {
          if (member is ShadowField) {
            inferredType = typeInferrer.inferDeclarationType(
                typeInferrer.inferFieldTopLevel(member, null, true));
          } else {
            inferredType = const DynamicType();
          }
        }
        if (isCircular) {
          // TODO(paulberry): report the appropriate error.
          inferredType = const DynamicType();
        }
        member.setInferredType(
            _typeInferenceEngine, typeInferrer.uri, inferredType);
      }
    }
    // TODO(paulberry): if type != null, then check that the type of the
    // initializer is assignable to it.
    // TODO(paulberry): the following is a hack so that outlines don't contain
    // initializers.  But it means that we rebuild the initializers when doing
    // a full compile.  There should be a better way.
    if (member is ShadowField) {
      member.initializer = null;
    }
  }

  @override
  String toString() => member.toString();
}

/// Visitor to check whether a given type mentions any of a class's type
/// parameters in a covariant fashion.
class IncludesTypeParametersCovariantly extends DartTypeVisitor<bool> {
  bool _inCovariantContext = true;

  final List<TypeParameter> _typeParametersToSearchFor;

  IncludesTypeParametersCovariantly(this._typeParametersToSearchFor);

  @override
  bool defaultDartType(DartType node) => false;

  @override
  bool visitFunctionType(FunctionType node) {
    if (node.returnType.accept(this)) return true;
    try {
      _inCovariantContext = !_inCovariantContext;
      for (var parameter in node.positionalParameters) {
        if (parameter.accept(this)) return true;
      }
      for (var parameter in node.namedParameters) {
        if (parameter.type.accept(this)) return true;
      }
      return false;
    } finally {
      _inCovariantContext = !_inCovariantContext;
    }
  }

  @override
  bool visitInterfaceType(InterfaceType node) {
    for (var argument in node.typeArguments) {
      if (argument.accept(this)) return true;
    }
    return false;
  }

  @override
  bool visitTypedefType(TypedefType node) {
    return node.unalias.accept(this);
  }

  @override
  bool visitTypeParameterType(TypeParameterType node) {
    return _inCovariantContext &&
        _typeParametersToSearchFor.contains(node.parameter);
  }
}

/// Base class for tracking dependencies during top level type inference.
///
/// Fields, accessors, and methods can have their types inferred in a variety of
/// ways; there will a derived class for each kind of inference.
abstract class InferenceNode {
  /// The node currently being evaluated, or `null` if no node is being
  /// evaluated.
  static InferenceNode _currentNode;

  /// Indicates whether the type inference corresponding to this node has been
  /// completed.
  bool _isResolved = false;

  /// Indicates whether this node participates in a circularity.
  bool _isCircular = false;

  /// If this node is currently being evaluated, and its evaluation caused a
  /// recursive call to another node's [resolve] method, a pointer to the latter
  /// node; otherwise `null`.
  InferenceNode _nextNode;

  /// Indicates whether this node participates in a circularity.
  ///
  /// This may be called at the end of [resolveInternal] to check whether a
  /// circularity was detected during evaluation.
  bool get isCircular => _isCircular;

  /// Evaluates this node, properly accounting for circularities.
  void resolve() {
    if (_isResolved) return;
    if (_nextNode != null || identical(_currentNode, this)) {
      // An accessor depends on itself (possibly by way of intermediate
      // accessors).  Mark all accessors involved as circular.
      var node = this;
      do {
        node._isCircular = true;
        node._isResolved = true;
        node = node._nextNode;
      } while (node != null);
    } else {
      var previousNode = _currentNode;
      assert(previousNode?._nextNode == null);
      _currentNode = this;
      previousNode?._nextNode = this;
      resolveInternal();
      assert(identical(_currentNode, this));
      previousNode?._nextNode = null;
      _currentNode = previousNode;
      _isResolved = true;
    }
  }

  /// Evaluates this node, possibly by making recursive calls to the [resolve]
  /// method of this node or other nodes.
  ///
  /// Circularity detection is handled by [resolve], which calls this method.
  /// Once this method has made all recursive calls to [resolve], it may use
  /// [isCircular] to detect whether a circularity has occurred.
  void resolveInternal();
}

/// Keeps track of the global state for the type inference that occurs outside
/// of method bodies and initializers.
///
/// This class describes the interface for use by clients of type inference
/// (e.g. DietListener).  Derived classes should derive from
/// [TypeInferenceEngineImpl].
abstract class TypeInferenceEngine {
  ClassHierarchy get classHierarchy;

  void set classHierarchy(ClassHierarchy classHierarchy);

  CoreTypes get coreTypes;

  TypeSchemaEnvironment get typeSchemaEnvironment;

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
  void finishTopLevelFields();

  /// Performs the third phase of top level inference, which is to visit all
  /// initializing formals and infer their types (if necessary) from the
  /// corresponding fields.
  void finishTopLevelInitializingFormals();

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
  final Instrumentation instrumentation;

  final bool strongMode;

  final accessorNodes = <AccessorNode>[];

  final initializingFormals = <ShadowVariableDeclaration>[];

  @override
  CoreTypes coreTypes;

  @override
  ClassHierarchy classHierarchy;

  TypeSchemaEnvironment typeSchemaEnvironment;

  TypeInferenceEngineImpl(this.instrumentation, this.strongMode);

  @override
  void computeFormalSafety(Class cls) {
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
    // class C extends B {
    //   foo(List<Object> argument) {}
    // }
    // void bar(A<Object> a) {
    //   a.foo(<Object>[1, 2.0, 'hi']);
    // }
    // void baz(B b) {
    //   b.foo(<Object>[1, 2.0, 'hi']); // Compile-time error
    // }
    //
    //
    // At the call site in `bar`, we know that the value passed to `foo` is an
    // instance of `List<Object>`.  But `bar` might have been called as
    // `bar(new A<num>())`, in which case passing `List<Object>` to `a.foo` would
    // violate soundness.  Therefore `A.foo` will have to check the type of its
    // argument at runtime (unless the back end can prove the check is
    // unnecessary, e.g. through whole program analysis).
    //
    // The same check needs to be compiled into `B.foo`, since it's possible
    // that `bar` might have been called as `bar(new B())`.
    //
    // However, if the call to `foo` occurs via the interface target `B.foo`,
    // no check is needed, since the class B is not generic, so the front end is
    // able to check the types completely at compile time and issue an error if
    // they don't match, as illustrated in `baz`.
    //
    // We represent this by marking A.foo's argument as both "semi-typed" and
    // "semi-safe", whereas B.foo's argument is simply "semi-safe".  The rule is
    // that a check only needs to be performed if the interface target's
    // parameter is marked as "semi-typed" AND the actual target's parameter is
    // marked as "semi-safe".
    //
    // A parameter is marked as "semi-typed" if it refers to one of the class's
    // generic parameters in a covariant position; a parameter is marked as
    // "semi-safe" if it is semi-typed or it overrides a parameter that is
    // semi-safe.  (In other words, the "semi-safe" annotation is inherited).
    //
    // Note that this a slightly conservative analysis; it mark C.foo's argument
    // as "semi-safe" even though technically it's not necessary to do so (since
    // every possible call to C.foo is guaranteed to pass in a subtype of
    // List<Object>).  In principle we could improve on this, but it would
    // require a lot of bookkeeping, and it doesn't seem worth it.
    if (cls.typeParameters.isNotEmpty) {
      var needsCheckVisitor =
          new IncludesTypeParametersCovariantly(cls.typeParameters);
      for (var procedure in cls.procedures) {
        if (procedure.isStatic) continue;

        void handleParameter(VariableDeclaration formal) {
          if (formal.type.accept(needsCheckVisitor)) {
            formal.isGenericCovariantImpl = true;
            formal.isGenericCovariantInterface = true;
          }
        }

        void handleTypeParameter(TypeParameter typeParameter) {
          if (typeParameter.bound.accept(needsCheckVisitor)) {
            typeParameter.isGenericCovariantImpl = true;
            typeParameter.isGenericCovariantInterface = true;
          }
        }

        procedure.function.positionalParameters.forEach(handleParameter);
        procedure.function.namedParameters.forEach(handleParameter);
        procedure.function.typeParameters.forEach(handleTypeParameter);
      }
      for (var field in cls.fields) {
        if (field.isStatic) continue;

        if (field.type.accept(needsCheckVisitor)) {
          field.isGenericCovariantImpl = true;
          field.isGenericCovariantInterface = true;
        }
      }
    }
  }

  /// Creates an [AccessorNode] to track dependencies of the given [member].
  AccessorNode createAccessorNode(ShadowMember member);

  @override
  void finishTopLevelFields() {
    for (var accessorNode in accessorNodes) {
      accessorNode.resolve();
    }
  }

  @override
  void finishTopLevelInitializingFormals() {
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
    if (!(member is ShadowProcedure && !member.isGetter && !member.isSetter)) {
      accessorNodes.add(createAccessorNode(member));
    }
  }

  DartType tryInferAccessorByInheritance(AccessorNode accessorNode) {
    DartType inferredType;
    for (var override in accessorNode.candidateOverrides) {
      var nextInferredType = _computeOverriddenAccessorType(
          override, accessorNode.member.enclosingClass);
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

  DartType _computeOverriddenAccessorType(Member override, Class thisClass) {
    AccessorNode dependency = ShadowMember.getInferenceNode(override);
    if (dependency != null) {
      dependency.resolve();
    }
    DartType overriddenType;
    if (override is Field) {
      overriddenType = override.type;
    } else if (override is Procedure) {
      // TODO(paulberry): handle the case where override needs its type
      // inferred first.
      if (override.isGetter) {
        overriddenType = override.getterType;
      } else if (override.isSetter) {
        overriddenType = override.setterType;
      } else {
        // Illegal override; will be reported elsewhere.
        overriddenType = const DynamicType();
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
}
