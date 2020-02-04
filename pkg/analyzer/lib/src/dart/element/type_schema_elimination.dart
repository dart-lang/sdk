// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:meta/meta.dart';

/// Visitor that computes least and greatest closures of a type schema.
///
/// Each visitor method returns `null` if there are no `?`s contained in the
/// type, otherwise it returns the result of substituting `?` with [_bottomType]
/// or [_topType], as appropriate.
///
/// TODO(scheglov) Rewrite using `ReplacementVisitor`, once we have it.
class TypeSchemaEliminationVisitor extends InternalTypeSubstitutor {
  final DartType _topType;
  final DartType _bottomType;

  bool _isLeastClosure;

  TypeSchemaEliminationVisitor._(
    this._topType,
    this._bottomType,
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
    return _isLeastClosure ? _bottomType : _topType;
  }

  /// Runs an instance of the visitor on the given [schema] and returns the
  /// resulting type.  If the schema contains no instances of `?`, the original
  /// schema object is returned to avoid unnecessary allocation.
  static DartType run({
    @required DartType topType,
    @required DartType bottomType,
    @required bool isLeastClosure,
    @required DartType schema,
  }) {
    var visitor = TypeSchemaEliminationVisitor._(
      topType,
      bottomType,
      isLeastClosure,
    );
    var result = visitor.visit(schema);
    assert(visitor._isLeastClosure == isLeastClosure);
    return result ?? schema;
  }
}
