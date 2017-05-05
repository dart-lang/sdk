// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:front_end/src/base/instrumentation.dart';
import 'package:front_end/src/dependency_walker.dart' as dependencyWalker;
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
class FieldNode<F> extends dependencyWalker.Node<FieldNode<F>> {
  final TypeInferenceEngineImpl _typeInferenceEngine;

  final F _field;

  final dependencies = <FieldNode<F>>[];

  FieldNode(this._typeInferenceEngine, this._field);

  @override
  bool get isEvaluated => _typeInferenceEngine.isFieldInferred(_field);

  @override
  List<FieldNode<F>> computeDependencies() {
    return dependencies;
  }
}

/// Keeps track of the global state for the type inference that occurs outside
/// of method bodies and initalizers.
///
/// This class abstracts away the representation of the underlying AST using
/// generic parameters.  TODO(paulberry): would it make more sense to abstract
/// away the representation of types as well?
///
/// Derived classes should set F to the class they use to represent field
/// declarations.
///
/// This class describes the interface for use by clients of type inference
/// (e.g. DietListener).  Derived classes should derive from
/// [TypeInferenceEngineImpl].
abstract class TypeInferenceEngine<F> {
  ClassHierarchy get classHierarchy;

  CoreTypes get coreTypes;

  /// Creates a type inferrer for use inside of a method body declared in a file
  /// with the given [uri].
  TypeInferrer<dynamic, dynamic, dynamic, F> createLocalTypeInferrer(Uri uri);

  /// Creates a [TypeInferrer] object which is ready to perform type inference
  /// on the given [field].
  TypeInferrer<dynamic, dynamic, dynamic, F> createTopLevelTypeInferrer(
      F field);

  /// Performs the second phase of top level initializer inference, which is to
  /// visit all fields and top level variables that were passed to [recordField]
  /// in topologically-sorted order and assign their types.
  void finishTopLevel();

  /// Gets the list of top level type inference dependencies of the given
  /// [field].
  List<FieldNode<F>> getFieldDependencies(F field);

  /// Gets ready to do top level type inference for the program having the given
  /// [hierarchy], using the given [coreTypes].
  void prepareTopLevel(CoreTypes coreTypes, ClassHierarchy hierarchy);

  /// Records that the given [field] will need top level type inference.
  void recordField(F field);
}

/// Derived class containing generic implementations of
/// [TypeInferenceEngineImpl].
///
/// This class contains as much of the implementation of type inference as
/// possible without knowing the identity of the type parameter.  It defers to
/// abstract methods for everything else.
abstract class TypeInferenceEngineImpl<F> extends TypeInferenceEngine<F> {
  final Instrumentation instrumentation;

  final bool strongMode;

  final fieldNodes = <FieldNode<F>>[];

  @override
  CoreTypes coreTypes;

  @override
  ClassHierarchy classHierarchy;

  TypeSchemaEnvironment typeSchemaEnvironment;

  TypeInferenceEngineImpl(this.instrumentation, this.strongMode);

  /// Clears the initializer of [field].
  void clearFieldInitializer(F field);

  /// Creates a [FieldNode] to track dependencies of the given [field].
  FieldNode<F> createFieldNode(F field);

  /// Queries whether the given [field] has an initializer.
  bool fieldHasInitializer(F field);

  @override
  void finishTopLevel() {
    for (var fieldNode in fieldNodes) {
      if (fieldNode.isEvaluated) continue;
      new _FieldWalker<F>().walk(fieldNode);
    }
  }

  /// Gets the declared type of the given [field], or `null` if the type is
  /// implicit.
  DartType getFieldDeclaredType(F field);

  /// Gets the character offset of the declaration of [field] within its
  /// compilation unit.
  int getFieldOffset(F field);

  /// Retrieve the [TypeInferrer] for the given [field], which was created by
  /// a previous call to [createTopLevelTypeInferrer].
  TypeInferrerImpl<dynamic, dynamic, dynamic, F> getFieldTypeInferrer(F field);

  /// Gets the URI of the compilation unit the [field] is declared in.
  /// TODO(paulberry): can we remove this?
  String getFieldUri(F field);

  /// Performs type inference on the given [field].
  void inferField(F field) {
    if (fieldHasInitializer(field)) {
      var typeInferrer = getFieldTypeInferrer(field);
      var type = getFieldDeclaredType(field);
      var inferredType = typeInferrer.inferDeclarationType(
          typeInferrer.inferFieldInitializer(field, type, type == null));
      if (type == null && strongMode) {
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
  void inferFieldCircular(F field) {
    // TODO(paulberry): report the appropriate error.
    if (getFieldDeclaredType(field) == null) {
      var uri = getFieldTypeInferrer(field).uri;
      instrumentation?.record(Uri.parse(uri), getFieldOffset(field), 'topType',
          const InstrumentationValueLiteral('circular'));
      setFieldInferredType(field, const DynamicType());
    }
  }

  /// Determines if top level type inference has been completed for [field].
  bool isFieldInferred(F field);

  @override
  void prepareTopLevel(CoreTypes coreTypes, ClassHierarchy hierarchy) {
    this.coreTypes = coreTypes;
    this.classHierarchy = hierarchy;
    this.typeSchemaEnvironment =
        new TypeSchemaEnvironment(coreTypes, hierarchy);
  }

  @override
  void recordField(F field) {
    fieldNodes.add(createFieldNode(field));
  }

  /// Stores [inferredType] as the inferred type of [field].
  void setFieldInferredType(F field, DartType inferredType);
}

/// Subtype of [dependencyWalker.DependencyWalker] which is specialized to
/// perform top level type inference.
class _FieldWalker<F> extends dependencyWalker.DependencyWalker<FieldNode<F>> {
  _FieldWalker();

  @override
  void evaluate(FieldNode<F> f) {
    f._typeInferenceEngine.inferField(f._field);
  }

  @override
  void evaluateScc(List<FieldNode<F>> scc) {
    for (var f in scc) {
      f._typeInferenceEngine.inferFieldCircular(f._field);
    }
    for (var f in scc) {
      f._typeInferenceEngine.inferField(f._field);
    }
  }
}
