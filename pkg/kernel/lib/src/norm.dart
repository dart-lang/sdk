// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart';
import '../core_types.dart';
import '../type_algebra.dart';

import 'replacement_visitor.dart';

/// Returns normalization of [type].
DartType norm(CoreTypes coreTypes, DartType type) {
  return type.accept1(new _Norm(coreTypes), Variance.covariant) ?? type;
}

/// Returns normalization of [supertype].
Supertype normSupertype(CoreTypes coreTypes, Supertype supertype) {
  if (supertype.typeArguments.isEmpty) return supertype;
  _Norm normVisitor = new _Norm(coreTypes);
  List<DartType>? typeArguments = null;
  for (int i = 0; i < supertype.typeArguments.length; ++i) {
    DartType? typeArgument =
        supertype.typeArguments[i].accept1(normVisitor, Variance.covariant);
    if (typeArgument != null) {
      typeArguments ??= supertype.typeArguments.toList();
      typeArguments[i] = typeArgument;
    }
  }
  if (typeArguments == null) return supertype;
  return new Supertype(supertype.classNode, typeArguments);
}

/// Visitor implementing the NORM algorithm.
///
/// Visitor's methods return null if the type is unchanged by the NORM
/// algorithm.  The algorithm is specified at
/// https://github.com/dart-lang/language/blob/master/resources/type-system/normalization.md
class _Norm extends ReplacementVisitor {
  final CoreTypes coreTypes;

  _Norm(this.coreTypes);

  @override
  DartType? visitInterfaceType(InterfaceType node, int variance) {
    return super
        .visitInterfaceType(node, variance)
        ?.withDeclaredNullability(node.nullability);
  }

  @override
  DartType visitFutureOrType(FutureOrType node, int variance) {
    DartType typeArgument = node.typeArgument;
    typeArgument = typeArgument.accept1(this, variance) ?? typeArgument;
    if (coreTypes.isTop(typeArgument)) {
      assert(typeArgument.nullability == Nullability.nullable ||
          typeArgument.nullability == Nullability.legacy);
      // [typeArgument] is nullable because it's a top type.  No need to unite
      // the nullabilities of [node] and [typeArgument].
      return typeArgument;
    } else if (typeArgument is InterfaceType &&
        typeArgument.classNode == coreTypes.objectClass &&
        typeArgument.nullability == Nullability.nonNullable) {
      assert(!coreTypes.isTop(typeArgument));
      // [typeArgument] is non-nullable, so the union of that and the
      // nullability of [node] is the nullability of [node].
      return typeArgument.withDeclaredNullability(node.nullability);
    } else if (typeArgument is NeverType &&
        typeArgument.nullability == Nullability.nonNullable) {
      assert(!coreTypes.isTop(typeArgument));
      assert(!coreTypes.isObject(typeArgument));
      // [typeArgument] is non-nullable, so the union of that and the
      // nullability of [node] is the nullability of [node].
      return new InterfaceType(
          coreTypes.futureClass, node.nullability, <DartType>[typeArgument]);
    } else if (coreTypes.isNull(typeArgument)) {
      assert(!coreTypes.isTop(typeArgument));
      assert(!coreTypes.isObject(typeArgument));
      assert(!coreTypes.isBottom(typeArgument));
      return new InterfaceType(
          coreTypes.futureClass,
          uniteNullabilities(typeArgument.nullability, node.nullability),
          <DartType>[typeArgument]);
    }
    assert(!coreTypes.isTop(typeArgument));
    assert(!coreTypes.isObject(typeArgument));
    assert(!coreTypes.isBottom(typeArgument));
    assert(!coreTypes.isNull(typeArgument));
    // TODO(johnniwinther): We should return `null` if [typeArgument] is
    // the same as `node.typeArgument`.
    return new FutureOrType(typeArgument, node.nullability);
  }

  @override
  DartType? visitTypeParameterType(TypeParameterType node, int variance) {
    DartType bound = node.parameter.bound;
    if (normalizesToNever(bound)) {
      DartType result = NeverType.fromNullability(node.nullability);
      return result.accept1(this, variance) ?? result;
    }
    assert(!coreTypes.isBottom(bound));
    // If the bound isn't Never, the type is already normalized.
    return null;
  }

  @override
  DartType? visitIntersectionType(IntersectionType node, int variance) {
    DartType right = node.right;
    right = right.accept1(this, variance) ?? right;
    if (right is NeverType && right.nullability == Nullability.nonNullable) {
      return right;
    } else if (coreTypes.isTop(right)) {
      assert(!coreTypes.isBottom(right));
      assert(right.nullability == Nullability.nullable);
      return node.left;
    } else if (right is TypeParameterType &&
        right.parameter == node.left.parameter &&
        right.declaredNullability == node.left.declaredNullability) {
      assert(!coreTypes.isBottom(right));
      assert(!coreTypes.isTop(right));
      return node.left;
    } else if (right == coreTypes.objectNonNullableRawType &&
        norm(coreTypes, node.left.parameter.bound) ==
            coreTypes.objectNonNullableRawType) {
      return node.left;
    } else if (identical(right, node.right)) {
      // If [bound] is identical to [node.right], then the NORM
      // algorithms didn't change the promoted bound, so the [node] is
      // unchanged as well, and we return null to indicate that.
      return null;
    }
    return new IntersectionType(node.left, right);
  }

  @override
  DartType? visitNeverType(NeverType node, int variance) {
    if (node.nullability == Nullability.nullable) return const NullType();
    return null;
  }

  bool normalizesToNever(DartType type) {
    if (type is NeverType && type.nullability == Nullability.nonNullable) {
      return true;
    } else if (type is TypeParameterType) {
      return normalizesToNever(type.parameter.bound);
    } else if (type is IntersectionType) {
      return normalizesToNever(type.right);
    }
    return false;
  }
}
