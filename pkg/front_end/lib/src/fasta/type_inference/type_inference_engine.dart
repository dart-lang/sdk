// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart'
    show
        Constructor,
        DartType,
        DartTypeVisitor,
        DynamicType,
        FunctionType,
        InterfaceType,
        Node,
        TypeParameter,
        TypeParameterType,
        TypedefType,
        VariableDeclaration;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';

import '../../base/instrumentation.dart';

import '../builder/library_builder.dart';

import '../kernel/kernel_shadow_ast.dart';

import '../messages.dart' show noLength, templateCantInferTypeDueToCircularity;

import '../source/source_library_builder.dart';

import 'type_inference_listener.dart' show TypeInferenceListener;

import 'type_inferrer.dart';

import 'type_schema_environment.dart';

/// Concrete class derived from [InferenceNode] to represent type inference of a
/// field based on its initializer.
class FieldInitializerInferenceNode extends InferenceNode {
  final TypeInferenceEngine _typeInferenceEngine;

  /// The field whose type should be inferred.
  final ShadowField field;

  final LibraryBuilder _library;

  FieldInitializerInferenceNode(
      this._typeInferenceEngine, this.field, this._library);

  @override
  void resolveInternal() {
    if (_typeInferenceEngine.strongMode) {
      var typeInferrer = _typeInferenceEngine.getFieldTypeInferrer(field);
      // Note: in the event that there is erroneous code, it's possible for
      // typeInferrer to be null.  If this happens, just skip type inference for
      // this field.
      if (typeInferrer != null) {
        var inferredType = typeInferrer
            .inferDeclarationType(typeInferrer.inferFieldTopLevel(field, true));
        if (isCircular) {
          // Report the appropriate error.
          _library.addCompileTimeError(
              templateCantInferTypeDueToCircularity
                  .withArguments(field.name.name),
              field.fileOffset,
              noLength,
              field.fileUri);
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
  ClassHierarchy classHierarchy;

  CoreTypes coreTypes;

  /// Indicates whether the "prepare" phase of type inference is complete.
  bool isTypeInferencePrepared = false;

  TypeSchemaEnvironment typeSchemaEnvironment;

  final staticInferenceNodes = <FieldInitializerInferenceNode>[];

  /// A map containing constructors with initializing formals whose types
  /// need to be inferred.
  ///
  /// This is represented as a map from a constructor to its library
  /// builder because the builder is used to report errors due to cyclic
  /// inference dependencies.
  final Map<Constructor, LibraryBuilder> toBeInferred = {};

  /// A map containing constructors in the process of being inferred.
  ///
  /// This is used to detect cyclic inference dependencies.  It is represented
  /// as a map from a constructor to its library builder because the builder
  /// is used to report errors.
  final Map<Constructor, LibraryBuilder> beingInferred = {};

  final Instrumentation instrumentation;

  final bool strongMode;

  TypeInferenceEngine(this.instrumentation, this.strongMode);

  /// Creates a disabled type inferrer (intended for debugging and profiling
  /// only).
  TypeInferrer createDisabledTypeInferrer();

  /// Creates a type inferrer for use inside of a method body declared in a file
  /// with the given [uri].
  TypeInferrer createLocalTypeInferrer(
      Uri uri,
      TypeInferenceListener<int, Node, int> listener,
      InterfaceType thisType,
      SourceLibraryBuilder library);

  /// Creates a [TypeInferrer] object which is ready to perform type inference
  /// on the given [field].
  TypeInferrer createTopLevelTypeInferrer(
      TypeInferenceListener<int, Node, int> listener,
      InterfaceType thisType,
      ShadowField field);

  /// Retrieve the [TypeInferrer] for the given [field], which was created by
  /// a previous call to [createTopLevelTypeInferrer].
  TypeInferrerImpl getFieldTypeInferrer(ShadowField field);

  /// Performs the second phase of top level initializer inference, which is to
  /// visit all accessors and top level variables that were passed to
  /// [recordAccessor] in topologically-sorted order and assign their types.
  void finishTopLevelFields() {
    for (var node in staticInferenceNodes) {
      node.resolve();
    }
    staticInferenceNodes.clear();
  }

  /// Performs the third phase of top level inference, which is to visit all
  /// constructors still needing inference and infer the types of their
  /// initializing formals from the corresponding fields.
  void finishTopLevelInitializingFormals() {
    // Field types have all been inferred so there cannot be a cyclic
    // dependency.
    for (Constructor constructor in toBeInferred.keys) {
      for (var declaration in constructor.function.positionalParameters) {
        inferInitializingFormal(declaration, constructor);
      }
      for (var declaration in constructor.function.namedParameters) {
        inferInitializingFormal(declaration, constructor);
      }
    }
    toBeInferred.clear();
  }

  void inferInitializingFormal(VariableDeclaration formal, Constructor parent) {
    if (formal.type == null) {
      for (ShadowField field in parent.enclosingClass.fields) {
        if (field.name.name == formal.name) {
          if (field.inferenceNode != null) {
            field.inferenceNode.resolve();
          }
          formal.type = field.type;
          return;
        }
      }
      // We did not find the corresponding field, so the program is erroneous.
      // The error should have been reported elsewhere and type inference
      // should continue by inferring dynamic.
      formal.type = const DynamicType();
    }
  }

  /// Gets ready to do top level type inference for the component having the
  /// given [hierarchy], using the given [coreTypes].
  void prepareTopLevel(CoreTypes coreTypes, ClassHierarchy hierarchy) {
    this.coreTypes = coreTypes;
    this.classHierarchy = hierarchy;
    this.typeSchemaEnvironment =
        new TypeSchemaEnvironment(coreTypes, hierarchy, strongMode);
  }

  /// Records that the given static [field] will need top level type inference.
  void recordStaticFieldInferenceCandidate(
      ShadowField field, LibraryBuilder library) {
    var node = new FieldInitializerInferenceNode(this, field, library);
    ShadowField.setInferenceNode(field, node);
    staticInferenceNodes.add(node);
  }
}
