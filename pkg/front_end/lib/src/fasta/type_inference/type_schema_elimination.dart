// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:front_end/src/fasta/type_inference/type_schema.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

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
DartType greatestClosure(CoreTypes coreTypes, DartType schema) =>
    _TypeSchemaEliminationVisitor.run(coreTypes, false, schema);

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
DartType leastClosure(CoreTypes coreTypes, DartType schema) =>
    _TypeSchemaEliminationVisitor.run(coreTypes, true, schema);

/// Visitor that computes least and greatest closures of a type schema.
///
/// Each visitor method returns `null` if there are no `?`s contained in the
/// type, otherwise it returns the result of substituting `?` with `Null` or
/// `Object`, as appropriate.
class _TypeSchemaEliminationVisitor extends TypeSchemaVisitor<DartType> {
  final DartType nullType;

  bool isLeastClosure;

  _TypeSchemaEliminationVisitor(CoreTypes coreTypes, this.isLeastClosure)
      : nullType = coreTypes.nullClass.rawType;

  @override
  DartType visitFunctionType(FunctionType node) {
    DartType newReturnType = node.returnType.accept(this);
    isLeastClosure = !isLeastClosure;
    List<DartType> newPositionalParameters = null;
    for (int i = 0; i < node.positionalParameters.length; i++) {
      DartType substitution = node.positionalParameters[i].accept(this);
      if (substitution != null) {
        newPositionalParameters ??=
            node.positionalParameters.toList(growable: false);
        newPositionalParameters[i] = substitution;
      }
    }
    List<NamedType> newNamedParameters = null;
    for (int i = 0; i < node.namedParameters.length; i++) {
      DartType substitution = node.namedParameters[i].type.accept(this);
      if (substitution != null) {
        newNamedParameters ??= node.namedParameters.toList(growable: false);
        newNamedParameters[i] =
            new NamedType(node.namedParameters[i].name, substitution);
      }
    }
    isLeastClosure = !isLeastClosure;
    if (newReturnType == null &&
        newPositionalParameters == null &&
        newNamedParameters == null) {
      // No types had to be substituted.
      return null;
    } else {
      return new FunctionType(
          newPositionalParameters ?? node.positionalParameters,
          newReturnType ?? node.returnType,
          namedParameters: newNamedParameters ?? node.namedParameters,
          typeParameters: node.typeParameters,
          requiredParameterCount: node.requiredParameterCount);
    }
  }

  @override
  DartType visitInterfaceType(InterfaceType node) {
    List<DartType> newTypeArguments = null;
    for (int i = 0; i < node.typeArguments.length; i++) {
      DartType substitution = node.typeArguments[i].accept(this);
      if (substitution != null) {
        newTypeArguments ??= node.typeArguments.toList(growable: false);
        newTypeArguments[i] = substitution;
      }
    }
    if (newTypeArguments == null) {
      // No type arguments needed to be substituted.
      return null;
    } else {
      return new InterfaceType(node.classNode, newTypeArguments);
    }
  }

  @override
  DartType visitUnknownType(UnknownType node) =>
      isLeastClosure ? nullType : const DynamicType();

  /// Runs an instance of the visitor on the given [schema] and returns the
  /// resulting type.  If the schema contains no instances of `?`, the original
  /// schema object is returned to avoid unnecessary allocation.
  static DartType run(
      CoreTypes coreTypes, bool isLeastClosure, DartType schema) {
    var visitor = new _TypeSchemaEliminationVisitor(coreTypes, isLeastClosure);
    var result = schema.accept(visitor);
    assert(visitor.isLeastClosure == isLeastClosure);
    return result ?? schema;
  }
}
