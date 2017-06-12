// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:front_end/src/base/instrumentation.dart';
import 'package:front_end/src/dependency_walker.dart' as dependencyWalker;
import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_listener.dart';
import 'package:front_end/src/fasta/type_inference/type_inferrer.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_environment.dart';
import 'package:kernel/ast.dart' show DartType, DynamicType;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';

/// Data structure for tracking dependencies between fields that require type
/// inference.
///
/// TODO(paulberry): see if it's possible to make this class more lightweight
/// by changing the API so that the walker is passed to computeDependencies().
/// (This should allow us to drop the _typeInferenceEngine field).
class FieldNode extends dependencyWalker.Node<FieldNode> {
  final TypeInferenceEngineImpl _typeInferenceEngine;

  final KernelField _field;

  final dependencies = <FieldNode>[];

  FieldNode(this._typeInferenceEngine, this._field);

  @override
  bool get isEvaluated => _typeInferenceEngine.isFieldInferred(_field);

  @override
  List<FieldNode> computeDependencies() {
    return dependencies;
  }
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
  TypeInferrer createLocalTypeInferrer(Uri uri, TypeInferenceListener listener);

  /// Creates a [TypeInferrer] object which is ready to perform type inference
  /// on the given [field].
  TypeInferrer createTopLevelTypeInferrer(
      KernelField field, TypeInferenceListener listener);

  /// Performs the second phase of top level initializer inference, which is to
  /// visit all fields and top level variables that were passed to [recordField]
  /// in topologically-sorted order and assign their types.
  void finishTopLevel();

  /// Gets the list of top level type inference dependencies of the given
  /// [field].
  List<FieldNode> getFieldDependencies(KernelField field);

  /// Gets ready to do top level type inference for the program having the given
  /// [hierarchy], using the given [coreTypes].
  void prepareTopLevel(CoreTypes coreTypes, ClassHierarchy hierarchy);

  /// Records that the given [field] will need top level type inference.
  void recordField(KernelField field);
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

  final fieldNodes = <FieldNode>[];

  @override
  CoreTypes coreTypes;

  @override
  ClassHierarchy classHierarchy;

  TypeSchemaEnvironment typeSchemaEnvironment;

  TypeInferenceEngineImpl(this.instrumentation, this.strongMode);

  /// Clears the initializer of [field].
  void clearFieldInitializer(KernelField field);

  /// Creates a [FieldNode] to track dependencies of the given [field].
  FieldNode createFieldNode(KernelField field);

  /// Queries whether the given [field] has an initializer.
  bool fieldHasInitializer(KernelField field);

  @override
  void finishTopLevel() {
    for (var fieldNode in fieldNodes) {
      if (fieldNode.isEvaluated) continue;
      new _FieldWalker().walk(fieldNode);
    }
  }

  /// Gets the declared type of the given [field], or `null` if the type is
  /// implicit.
  DartType getFieldDeclaredType(KernelField field);

  /// Gets the character offset of the declaration of [field] within its
  /// compilation unit.
  int getFieldOffset(KernelField field);

  /// Retrieve the [TypeInferrer] for the given [field], which was created by
  /// a previous call to [createTopLevelTypeInferrer].
  TypeInferrerImpl getFieldTypeInferrer(KernelField field);

  /// Gets the URI of the compilation unit the [field] is declared in.
  /// TODO(paulberry): can we remove this?
  String getFieldUri(KernelField field);

  /// Performs type inference on the given [field].
  void inferField(KernelField field, bool updateType) {
    if (fieldHasInitializer(field)) {
      var typeInferrer = getFieldTypeInferrer(field);
      var type = getFieldDeclaredType(field);
      var inferredType = typeInferrer.inferDeclarationType(
          typeInferrer.inferFieldInitializer(field, type, type == null));
      if (type == null && strongMode && updateType) {
        instrumentation?.record(
            Uri.parse(typeInferrer.uri),
            getFieldOffset(field),
            'topType',
            new InstrumentationValueForType(inferredType));
        setFieldInferredType(field, inferredType);
      }
      // TODO(paulberry): if type != null, then check that the type of the
      // initializer is assignable to it.
      // TODO(paulberry): the following is a hack so that outlines don't contain
      // initializers.  But it means that we rebuild the initializers when doing
      // a full compile.  There should be a better way.
      clearFieldInitializer(field);
    }
  }

  /// Makes a note that the given [field] is part of a circularity, so its type
  /// can't be inferred.
  void inferFieldCircular(KernelField field) {
    // TODO(paulberry): report the appropriate error.
    if (getFieldDeclaredType(field) == null) {
      var uri = getFieldTypeInferrer(field).uri;
      var inferredType = const DynamicType();
      instrumentation?.record(Uri.parse(uri), getFieldOffset(field), 'topType',
          new InstrumentationValueForType(inferredType));
      setFieldInferredType(field, inferredType);
    }
  }

  /// Determines if top level type inference has been completed for [field].
  bool isFieldInferred(KernelField field);

  @override
  void prepareTopLevel(CoreTypes coreTypes, ClassHierarchy hierarchy) {
    this.coreTypes = coreTypes;
    this.classHierarchy = hierarchy;
    this.typeSchemaEnvironment =
        new TypeSchemaEnvironment(coreTypes, hierarchy);
  }

  @override
  void recordField(KernelField field) {
    fieldNodes.add(createFieldNode(field));
  }

  /// Stores [inferredType] as the inferred type of [field].
  void setFieldInferredType(KernelField field, DartType inferredType);
}

/// Subtype of [dependencyWalker.DependencyWalker] which is specialized to
/// perform top level type inference.
class _FieldWalker extends dependencyWalker.DependencyWalker<FieldNode> {
  _FieldWalker();

  @override
  void evaluate(FieldNode f) {
    f._typeInferenceEngine.inferField(f._field, true);
  }

  @override
  void evaluateScc(List<FieldNode> scc) {
    // Mark every field as part of a circularity.
    for (var f in scc) {
      f._typeInferenceEngine.inferFieldCircular(f._field);
    }
    // Perform type inference on the initializers of every field, but don't
    // update the inferred types.
    for (var f in scc) {
      f._typeInferenceEngine.inferField(f._field, false);
    }
  }
}
