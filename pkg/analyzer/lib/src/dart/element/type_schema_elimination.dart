// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/generated/type_system.dart';

/// Returns the greatest closure of the given type [schema] with respect to `?`.
///
/// The greatest closure of a type schema `P` with respect to `?` is defined as
/// `P` with every covariant occurrence of `?` replaced with `Null`, and every
/// contravariant occurrence of `?` replaced with `Object`.
///
/// If the schema contains no instances of `?`, the original schema object is
/// returned to avoid unnecessary allocation.
///
/// Note that the closure of a type schema is a proper type.
///
/// Note that the greatest closure of a type schema is always a supertype of any
/// type which matches the schema.
DartType greatestClosure(TypeProviderImpl typeProvider, DartType schema) {
  return _TypeSchemaEliminationVisitor.run(typeProvider, false, schema);
}

/// Returns the least closure of the given type [schema] with respect to `?`.
///
/// The least closure of a type schema `P` with respect to `?` is defined as
/// `P` with every covariant occurrence of `?` replaced with `Object`, and every
/// contravariant occurrence of `?` replaced with `Null`.
///
/// If the schema contains no instances of `?`, the original schema object is
/// returned to avoid unnecessary allocation.
///
/// Note that the closure of a type schema is a proper type.
///
/// Note that the least closure of a type schema is always a subtype of any type
/// which matches the schema.
DartType leastClosure(TypeProviderImpl typeProvider, DartType schema) {
  return _TypeSchemaEliminationVisitor.run(typeProvider, true, schema);
}

/// Visitor that computes least and greatest closures of a type schema.
///
/// Each visitor method returns `null` if there are no `?`s contained in the
/// type, otherwise it returns the result of substituting `?` with `Null` or
/// `Object`, as appropriate.
///
/// TODO(scheglov) Rewrite using `ReplacementVisitor`, once we have it.
class _TypeSchemaEliminationVisitor extends InternalTypeSubstitutor {
  final TypeProviderImpl _typeProvider;

  bool _isLeastClosure;

  _TypeSchemaEliminationVisitor(
    this._typeProvider,
    this._isLeastClosure,
  ) : super(null);

  @override
  List<TypeParameterElement> freshTypeParameters(
      List<TypeParameterElement> elements) {
    throw 'Create a fresh environment first';
  }

  @override
  void invertVariance() {
    super.invertVariance();
    _isLeastClosure = !_isLeastClosure;
  }

  @override
  DartType lookup(TypeParameterElement parameter, bool upperBound) {
    return null;
  }

  @override
  DartType visitUnknownInferredType(UnknownInferredType type) {
    useCounter++;
    return _isLeastClosure ? _typeProvider.nullType : _typeProvider.dynamicType;
  }

  /// Runs an instance of the visitor on the given [schema] and returns the
  /// resulting type.  If the schema contains no instances of `?`, the original
  /// schema object is returned to avoid unnecessary allocation.
  static DartType run(
    TypeProviderImpl typeProvider,
    bool isLeastClosure,
    DartType schema,
  ) {
    var visitor = _TypeSchemaEliminationVisitor(typeProvider, isLeastClosure);
    var result = visitor.visit(schema);
    assert(visitor._isLeastClosure == isLeastClosure);
    return result ?? schema;
  }
}
