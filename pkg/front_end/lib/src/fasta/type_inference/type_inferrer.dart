// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:front_end/src/base/instrumentation.dart';
import 'package:front_end/src/dependency_walker.dart' as dependencyWalker;
import 'package:kernel/ast.dart' show DartType, DynamicType, Member;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';

/// Data structure for tracking dependencies between fields that require type
/// inference.
///
/// TODO(paulberry): see if it's possible to make this class more lightweight
/// by changing the API so that the walker is passed to computeDependencies().
/// (This should allow us to drop the _typeInferrer field).
class FieldNode<F> extends dependencyWalker.Node<FieldNode<F>> {
  final TypeInferrer _typeInferrer;

  final F _field;

  final dependencies = <FieldNode<F>>[];

  FieldNode(this._typeInferrer, this._field);

  @override
  bool get isEvaluated => _typeInferrer.isFieldInferred(_field);

  @override
  List<FieldNode<F>> computeDependencies() {
    return dependencies;
  }
}

/// Abstract implementation of type inference which is independent of the
/// underlying AST representation (but still uses DartType from kernel).
///
/// TODO(paulberry): would it make more sense to abstract away the
/// representation of types as well?
///
/// Derived classes should set S, E, V, and F to the class they use to represent
/// statements, expressions, variable declarations, and field declarations,
/// respectively.
abstract class TypeInferrer<S, E, V, F> {
  final Instrumentation instrumentation;

  final bool strongMode;

  final fieldNodes = <FieldNode<F>>[];

  CoreTypes coreTypes;

  ClassHierarchy classHierarchy;

  /// The URI of the code for which type inference is currently being
  /// performed--this is used for testing.
  String uri;

  /// Indicates whether we are currently performing top level inference.
  bool isTopLevel = false;

  TypeInferrer(this.instrumentation, this.strongMode);

  /// Cleares the initializer of [field].
  void clearFieldInitializer(F field);

  /// Creates a [FieldNode] to track dependencies of the given [field].
  FieldNode<F> createFieldNode(F field);

  /// Gets the declared type of the given [field], or `null` if the type is
  /// implicit.
  DartType getFieldDeclaredType(F field);

  /// Gets the list of top level type inference dependencies of the given
  /// [field].
  List<FieldNode<F>> getFieldDependencies(F field);

  /// Gets the initializer for the given [field], or `null` if there is no
  /// initializer.
  E getFieldInitializer(F field);

  /// Gets the [FieldNode] corresponding to the given [readTarget], if any.
  FieldNode<F> getFieldNodeForReadTarget(Member readTarget);

  /// Gets the character offset of the declaration of [field] within its
  /// compilation unit.
  int getFieldOffset(F field);

  /// Gets the URI of the compilation unit the [field] is declared in.
  String getFieldUri(F field);

  /// Performs type inference on a method with the given method [body].
  ///
  /// [uri] is the URI of the file the method is contained in--this is used for
  /// testing.
  void inferBody(S body, Uri uri) {
    this.uri = uri.toString();
    inferStatement(body);
  }

  /// Performs type inference on the given [expression].
  ///
  /// [typeContext] is the expected type of the expression, based on surrounding
  /// code.  [typeNeeded] indicates whether it is necessary to compute the
  /// actual type of the expression.  If [typeNeeded] is `true`, the actual type
  /// of the expression is returned; otherwise `null` is returned.
  ///
  /// Derived classes should override this method with logic that dispatches on
  /// the expression type and calls the appropriate specialized "infer" method.
  DartType inferExpression(E expression, DartType typeContext, bool typeNeeded);

  /// Performs type inference on the given [field].
  void inferField(F field) {
    var initializer = getFieldInitializer(field);
    if (initializer != null) {
      var type = getFieldDeclaredType(field);
      uri = getFieldUri(field);
      isTopLevel = true;
      var inferredType = inferExpression(initializer, type, type == null);
      if (type == null && strongMode) {
        instrumentation?.record(
            'topType',
            Uri.parse(uri),
            getFieldOffset(field),
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
      var uri = getFieldUri(field);
      instrumentation?.record('topType', Uri.parse(uri), getFieldOffset(field),
          const InstrumentationValueLiteral('circular'));
      setFieldInferredType(field, const DynamicType());
    }
  }

  /// Performs the core type inference algorithm for integer literals.
  ///
  /// [typeContext], [typeNeeded], and the return value behave as described in
  /// [inferExpression].
  DartType inferIntLiteral(DartType typeContext, bool typeNeeded) {
    return typeNeeded ? coreTypes.intClass.rawType : null;
  }

  /// Performs type inference on the given [statement].
  ///
  /// Derived classes should override this method with logic that dispatches on
  /// the statement type and calls the appropriate specialized "infer" method.
  void inferStatement(S statement);

  /// Performs the core type inference algorithm for static variable getters.
  ///
  /// [typeContext], [typeNeeded], and the return value behave as described in
  /// [inferExpression].
  ///
  /// [getterType] is the type of the field being referenced, or the return type
  /// of the getter.
  DartType inferStaticGet(
      DartType typeContext, bool typeNeeded, DartType getterType) {
    return typeNeeded ? getterType : null;
  }

  /// Performs the core type inference algorithm for variable declarations.
  ///
  /// [declaredType] is the declared type of the variable, or `null` if the type
  /// should be inferred.  [initializer] is the initializer expression.
  /// [offset] is the character offset of the variable declaration (for
  /// instrumentation).  [setType] is a callback that will be used to set the
  /// inferred type.
  void inferVariableDeclaration(DartType declaredType, E initializer,
      int offset, void setType(DartType type)) {
    if (initializer == null) return;
    var inferredType =
        inferExpression(initializer, declaredType, declaredType == null);
    if (strongMode && declaredType == null) {
      instrumentation?.record('type', Uri.parse(uri), offset,
          new InstrumentationValueForType(inferredType));
      setType(inferredType);
    }
  }

  /// Determines if top level type inference has been completed for [field].
  bool isFieldInferred(F field);

  /// Performs top level type inference for all fields that have been passed to
  /// [recordField].
  void performInitializerInference() {
    for (var fieldNode in fieldNodes) {
      if (fieldNode.isEvaluated) continue;
      new _FieldWalker<F>().walk(fieldNode);
    }
  }

  /// Records that the given [field] will need top level type inference.
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
    f._typeInferrer.inferField(f._field);
  }

  @override
  void evaluateScc(List<FieldNode<F>> scc) {
    for (var f in scc) {
      f._typeInferrer.inferFieldCircular(f._field);
    }
    for (var f in scc) {
      f._typeInferrer.inferField(f._field);
    }
  }
}
