// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart' hide MapEntry;
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
DartType greatestClosure(DartType schema, DartType bottomType) {
  assert(bottomType == const NeverType(Nullability.nonNullable) ||
      bottomType is InterfaceType &&
          bottomType.classNode.enclosingLibrary.importUri.scheme == "dart" &&
          bottomType.classNode.enclosingLibrary.importUri.path == "core" &&
          bottomType.classNode.name == "Null");
  return _TypeSchemaEliminationVisitor.run(false, schema, bottomType);
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
DartType leastClosure(DartType schema, DartType bottomType) {
  assert(bottomType == const NeverType(Nullability.nonNullable) ||
      bottomType is InterfaceType &&
          bottomType.classNode.enclosingLibrary.importUri.scheme == "dart" &&
          bottomType.classNode.enclosingLibrary.importUri.path == "core" &&
          bottomType.classNode.name == "Null");
  return _TypeSchemaEliminationVisitor.run(true, schema, bottomType);
}

/// Visitor that computes least and greatest closures of a type schema.
///
/// Each visitor method returns `null` if there are no `?`s contained in the
/// type, otherwise it returns the result of substituting `?` with `Null` or
/// `Object`, as appropriate.
class _TypeSchemaEliminationVisitor extends ReplacementVisitor {
  final DartType bottomType;

  bool isLeastClosure;

  _TypeSchemaEliminationVisitor(this.isLeastClosure, this.bottomType);

  void changeVariance() {
    isLeastClosure = !isLeastClosure;
  }

  @override
  DartType defaultDartType(DartType node) {
    if (node is UnknownType) {
      return isLeastClosure ? bottomType : const DynamicType();
    }
    return null;
  }

  /// Runs an instance of the visitor on the given [schema] and returns the
  /// resulting type.  If the schema contains no instances of `?`, the original
  /// schema object is returned to avoid unnecessary allocation.
  static DartType run(
      bool isLeastClosure, DartType schema, DartType bottomType) {
    _TypeSchemaEliminationVisitor visitor =
        new _TypeSchemaEliminationVisitor(isLeastClosure, bottomType);
    DartType result = schema.accept(visitor);
    assert(visitor.isLeastClosure == isLeastClosure);
    return result ?? schema;
  }
}
