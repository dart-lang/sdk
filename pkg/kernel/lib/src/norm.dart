// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import '../ast.dart' hide MapEntry;
import '../core_types.dart';
import '../type_algebra.dart';

import 'replacement_visitor.dart';

/// Returns normalization of [type].
DartType norm(CoreTypes coreTypes, DartType type) {
  return type.accept(new _Norm(coreTypes)) ?? type;
}

/// Returns normalization of [supertype].
Supertype normSupertype(CoreTypes coreTypes, Supertype supertype) {
  if (supertype.typeArguments.isEmpty) return supertype;
  _Norm normVisitor = new _Norm(coreTypes);
  List<DartType> typeArguments = null;
  for (int i = 0; i < supertype.typeArguments.length; ++i) {
    DartType typeArgument = supertype.typeArguments[i].accept(normVisitor);
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
  DartType visitInterfaceType(InterfaceType node) {
    return super
        .visitInterfaceType(node)
        ?.withDeclaredNullability(node.nullability);
  }

  @override
  DartType visitFutureOrType(FutureOrType node) {
    DartType typeArgument = node.typeArgument;
    typeArgument = typeArgument.accept(this) ?? typeArgument;
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
    return new FutureOrType(typeArgument, node.nullability);
  }

  @override
  DartType visitTypeParameterType(TypeParameterType node) {
    if (node.promotedBound == null) {
      DartType bound = node.parameter.bound;
      if (normalizesToNever(bound)) {
        DartType result = new NeverType(Nullability.nonNullable)
            .withDeclaredNullability(node.nullability);
        return result.accept(this) ?? result;
      }
      assert(!coreTypes.isBottom(bound));
      // If the bound isn't Never, the type is already normalized.
      return null;
    } else {
      DartType bound = node.promotedBound;
      bound = bound.accept(this) ?? bound;
      if (bound is NeverType && bound.nullability == Nullability.nonNullable) {
        return bound;
      } else if (coreTypes.isTop(bound)) {
        assert(!coreTypes.isBottom(bound));
        assert(bound.nullability == Nullability.nullable);
        return new TypeParameterType(node.parameter, node.declaredNullability);
      } else if (bound is TypeParameterType &&
          bound.parameter == node.parameter &&
          bound.declaredNullability == node.declaredNullability &&
          bound.promotedBound == null) {
        assert(!coreTypes.isBottom(bound));
        assert(!coreTypes.isTop(bound));
        return new TypeParameterType(node.parameter, node.declaredNullability);
      } else if (bound == coreTypes.objectNonNullableRawType &&
          norm(coreTypes, node.parameter.bound) ==
              coreTypes.objectNonNullableRawType) {
        return new TypeParameterType(node.parameter, node.declaredNullability);
      } else if (identical(bound, node.promotedBound)) {
        // If [bound] is identical to [node.promotedBound], then the NORM
        // algorithms didn't change the promoted bound, so the [node] is
        // unchanged as well, and we return null to indicate that.
        return null;
      }
      return new TypeParameterType(
          node.parameter, node.declaredNullability, bound);
    }
  }

  @override
  DartType visitNeverType(NeverType node) {
    if (node.nullability == Nullability.nullable) return const NullType();
    return null;
  }

  bool normalizesToNever(DartType type) {
    if (type is NeverType && type.nullability == Nullability.nonNullable) {
      return true;
    } else if (type is TypeParameterType) {
      if (type.promotedBound == null) {
        return normalizesToNever(type.parameter.bound);
      } else {
        return normalizesToNever(type.promotedBound);
      }
    }
    return false;
  }
}
