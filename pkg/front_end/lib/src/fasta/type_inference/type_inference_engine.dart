// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:front_end/src/base/instrumentation.dart';
import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_listener.dart';
import 'package:front_end/src/fasta/type_inference/type_inferrer.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_environment.dart';
import 'package:kernel/ast.dart'
    show
        Class,
        DartType,
        DartTypeVisitor,
        DynamicType,
        FunctionType,
        InterfaceType,
        Location,
        TypeParameter,
        TypeParameterType,
        TypedefType;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';

import '../deprecated_problems.dart' show Crash;
import '../messages.dart' show getLocationFromNode;

/// Concrete class derived from [InferenceNode] to represent type inference of a
/// field based on its initializer.
class FieldInitializerInferenceNode extends InferenceNode {
  final TypeInferenceEngineImpl _typeInferenceEngine;

  /// The field whose type should be inferred.
  final ShadowField field;

  FieldInitializerInferenceNode(this._typeInferenceEngine, this.field);

  @override
  void resolveInternal() {
    if (_typeInferenceEngine.strongMode) {
      var typeInferrer = _typeInferenceEngine.getFieldTypeInferrer(field);
      // Note: in the event that there is erroneous code, it's possible for
      // typeInferrer to be null.  If this happens, just skip type inference for
      // this field.
      if (typeInferrer != null) {
        var inferredType = typeInferrer.inferDeclarationType(
            typeInferrer.inferFieldTopLevel(field, null, true));
        if (isCircular) {
          // TODO(paulberry): report the appropriate error.
          inferredType = const DynamicType();
        }
        field.setInferredType(
            _typeInferenceEngine, typeInferrer.uri, inferredType);
        // TODO(paulberry): if type != null, then check that the type of the
        // initializer is assignable to it.
      }
    }
    // TODO(paulberry): the following is a hack so that outlines don't contain
    // initializers.  But it means that we rebuild the initializers when doing
    // a full compile.  There should be a better way.
    field.initializer = null;
  }

  @override
  String toString() => field.toString();
}

/// Visitor to check whether a given type mentions any of a class's type
/// parameters in a covariant fashion.
class IncludesTypeParametersCovariantly extends DartTypeVisitor<bool> {
  bool inCovariantContext = true;

  final List<TypeParameter> _typeParametersToSearchFor;

  IncludesTypeParametersCovariantly(this._typeParametersToSearchFor);

  @override
  bool defaultDartType(DartType node) => false;

  @override
  bool visitFunctionType(FunctionType node) {
    if (node.returnType.accept(this)) return true;
    try {
      inCovariantContext = !inCovariantContext;
      for (var parameter in node.positionalParameters) {
        if (parameter.accept(this)) return true;
      }
      for (var parameter in node.namedParameters) {
        if (parameter.type.accept(this)) return true;
      }
      return false;
    } finally {
      inCovariantContext = !inCovariantContext;
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
    return inCovariantContext &&
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

  /// Indicates whether the "prepare" phase of type inference is complete.
  void set isTypeInferencePrepared(bool value);

  TypeSchemaEnvironment get typeSchemaEnvironment;

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
      InterfaceType thisType, ShadowField field);

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

  /// Records that the given static [field] will need top level type inference.
  void recordStaticFieldInferenceCandidate(ShadowField field);
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

  final staticInferenceNodes = <FieldInitializerInferenceNode>[];

  final initializingFormals = <ShadowVariableDeclaration>[];

  @override
  CoreTypes coreTypes;

  @override
  ClassHierarchy classHierarchy;

  TypeSchemaEnvironment typeSchemaEnvironment;

  @override
  bool isTypeInferencePrepared = false;

  TypeInferenceEngineImpl(this.instrumentation, this.strongMode);

  @override
  void finishTopLevelFields() {
    for (var node in staticInferenceNodes) {
      node.resolve();
    }
    staticInferenceNodes.clear();
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

  /// Retrieve the [TypeInferrer] for the given [field], which was created by
  /// a previous call to [createTopLevelTypeInferrer].
  TypeInferrerImpl getFieldTypeInferrer(ShadowField field);

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

  void recordStaticFieldInferenceCandidate(ShadowField field) {
    var node = new FieldInitializerInferenceNode(this, field);
    ShadowField.setInferenceNode(field, node);
    staticInferenceNodes.add(node);
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
