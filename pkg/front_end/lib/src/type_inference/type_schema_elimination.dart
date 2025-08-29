// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/src/replacement_visitor.dart';

import 'type_schema.dart' show UnknownType;

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
DartType greatestClosure(DartType schema, {required DartType topType}) {
  return _TypeSchemaEliminationVisitor.run(
    schema,
    computeLeastClosure: false,
    topType: topType,
  );
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
DartType leastClosure(DartType schema, {required CoreTypes coreTypes}) {
  return _TypeSchemaEliminationVisitor.run(
    schema,
    computeLeastClosure: true,
    topType: coreTypes.objectNullableRawType,
  );
}

/// Visitor that computes least and greatest closures of a type schema.
///
/// Each visitor method returns `null` if there are no `?`s contained in the
/// type, otherwise it returns the result of substituting `?` with `Null` or
/// `Object`, as appropriate.
class _TypeSchemaEliminationVisitor extends ReplacementVisitor {
  final DartType _topType;

  _TypeSchemaEliminationVisitor(this._topType);

  @override
  DartType? visitAuxiliaryType(AuxiliaryType node, Variance variance) {
    bool computeLeastClosure = variance == Variance.covariant;
    if (node is UnknownType) {
      return computeLeastClosure ? const NeverType.nonNullable() : _topType;
    }
    // Coverage-ignore-block(suite): Not run.
    throw new UnsupportedError(
      "Unsupported auxiliary type $node (${node.runtimeType}).",
    );
  }

  /// Runs an instance of the visitor on the given [schema] and returns the
  /// resulting type.  If the schema contains no instances of `?`, the original
  /// schema object is returned to avoid unnecessary allocation.
  static DartType run(
    DartType schema, {
    required bool computeLeastClosure,
    required DartType topType,
  }) {
    assert(
      topType == const DynamicType() ||
          topType is InterfaceType &&
              topType.nullability == Nullability.nullable &&
              topType.classNode.enclosingLibrary.importUri.isScheme("dart") &&
              topType.classNode.enclosingLibrary.importUri.path == "core" &&
              topType.classNode.name == "Object",
    );
    _TypeSchemaEliminationVisitor visitor = new _TypeSchemaEliminationVisitor(
      topType,
    );
    DartType? result = schema.accept1(
      visitor,
      computeLeastClosure ? Variance.covariant : Variance.contravariant,
    );
    return result ?? schema;
  }
}
