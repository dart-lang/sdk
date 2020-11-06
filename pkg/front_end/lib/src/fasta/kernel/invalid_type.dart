// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/visitor.dart';

import '../type_inference/type_schema.dart';

/// Check if [type] contains [InvalidType] as its part.
///
/// The helper function is intended for stopping cascading errors because of
/// occurrences of [InvalidType].  In most cases it's safe to assume that if an
/// [InvalidType] was produced, an error was reported as the part of its
/// creation, so other errors raising, for example, from inability to assign to
/// a variable of an [InvalidType], could be omitted.
bool containsInvalidType(DartType type) {
  return type.accept1(const _InvalidTypeFinder(), <TypedefType>{});
}

class _InvalidTypeFinder implements DartTypeVisitor1<bool, Set<TypedefType>> {
  const _InvalidTypeFinder();

  @override
  bool defaultDartType(DartType node, Set<TypedefType> visitedTypedefs) {
    if (node is UnknownType) return false;
    throw new StateError("Unhandled type ${node.runtimeType}.");
  }

  @override
  bool visitDynamicType(DynamicType node, Set<TypedefType> visitedTypedefs) =>
      false;

  @override
  bool visitVoidType(VoidType node, Set<TypedefType> visitedTypedefs) => false;

  @override
  bool visitInvalidType(InvalidType node, Set<TypedefType> visitedTypedefs) =>
      true;

  @override
  bool visitInterfaceType(
      InterfaceType node, Set<TypedefType> visitedTypedefs) {
    for (DartType typeArgument in node.typeArguments) {
      if (typeArgument.accept1(this, visitedTypedefs)) return true;
    }
    return false;
  }

  @override
  bool visitFutureOrType(FutureOrType node, Set<TypedefType> visitedTypedefs) {
    return node.typeArgument.accept1(this, visitedTypedefs);
  }

  @override
  bool visitNeverType(NeverType node, Set<TypedefType> visitedTypedefs) =>
      false;

  @override
  bool visitNullType(NullType node, Set<TypedefType> visitedTypedefs) => false;

  @override
  bool visitBottomType(BottomType node, Set<TypedefType> visitedTypedefs) =>
      false;

  @override
  bool visitFunctionType(FunctionType node, Set<TypedefType> visitedTypedefs) {
    if (node.returnType.accept1(this, visitedTypedefs)) return true;
    for (TypeParameter typeParameter in node.typeParameters) {
      if (typeParameter.bound.accept1(this, visitedTypedefs)) return true;
      // TODO(dmitryas): Check defaultTypes as well if they cause cascading
      // errors.
    }
    for (DartType parameter in node.positionalParameters) {
      if (parameter.accept1(this, visitedTypedefs)) return true;
    }
    for (NamedType parameter in node.namedParameters) {
      if (parameter.type.accept1(this, visitedTypedefs)) return true;
    }
    if (node.typedefType != null && visitedTypedefs.add(node.typedefType)) {
      if (node.typedefType.accept1(this, visitedTypedefs)) return true;
    }
    return false;
  }

  @override
  bool visitTypedefType(TypedefType node, Set<TypedefType> visitedTypedefs) {
    // The unaliased type should be checked, but it's faster to check the type
    // arguments and the RHS separately than do the unaliasing because it avoids
    // type substitution.
    for (DartType typeArgument in node.typeArguments) {
      if (typeArgument.accept1(this, visitedTypedefs)) return true;
    }
    if (node.typedefNode.type.accept1(this, visitedTypedefs)) return true;
    return false;
  }

  @override
  bool visitTypeParameterType(
      TypeParameterType node, Set<TypedefType> visitedTypedefs) {
    // node.parameter.bound is not checked because such a bound doesn't
    // automatically means that the potential errors related to the occurrences
    // of the type-parameter type itself are reported.
    if (node.promotedBound != null &&
        node.promotedBound.accept1(this, visitedTypedefs)) {
      return true;
    }
    return false;
  }
}
