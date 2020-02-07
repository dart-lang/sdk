// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import '../ast.dart' hide MapEntry;
import '../core_types.dart';

import 'future_or.dart';
import 'replacement_visitor.dart';

/// Returns normalization of [type].
DartType norm(CoreTypes coreTypes, DartType type) {
  return type.accept(new _Norm(coreTypes)) ?? type;
}

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
    if (node.classNode == coreTypes.futureOrClass) {
      DartType typeArgument = node.typeArguments.single;
      typeArgument = typeArgument.accept(this) ?? typeArgument;
      if (coreTypes.isTop(typeArgument)) {
        Nullability nullabilityAsProperty =
            computeNullability(typeArgument, coreTypes.futureOrClass);
        assert(nullabilityAsProperty == Nullability.nullable ||
            nullabilityAsProperty == Nullability.legacy);
        // [typeArgument] is nullable because it's a top type.  No need to unite
        // the nullabilities of [node] and [typeArgument].
        return typeArgument.withNullability(nullabilityAsProperty);
      } else if (typeArgument is InterfaceType &&
          typeArgument.classNode == coreTypes.objectClass &&
          typeArgument.nullability == Nullability.nonNullable) {
        assert(!coreTypes.isTop(typeArgument));
        // [typeArgument] is non-nullable, so the union of that and the
        // nullability of [node] is the nullability of [node].
        return typeArgument
            .withNullability(computeNullability(node, coreTypes.futureOrClass));
      } else if (typeArgument is NeverType &&
          typeArgument.nullability == Nullability.nonNullable) {
        assert(!coreTypes.isTop(typeArgument));
        assert(!coreTypes.isObject(typeArgument));
        // [typeArgument] is non-nullable, so the union of that and the
        // nullability of [node] is the nullability of [node].
        return new InterfaceType(
            coreTypes.futureClass,
            computeNullability(node, coreTypes.futureOrClass),
            <DartType>[typeArgument]);
      } else if (coreTypes.isNull(typeArgument)) {
        assert(!coreTypes.isTop(typeArgument));
        assert(!coreTypes.isObject(typeArgument));
        assert(!coreTypes.isBottom(typeArgument));
        return new InterfaceType(
            coreTypes.futureClass,
            uniteNullabilities(typeArgument.nullability,
                computeNullability(node, coreTypes.futureOrClass)),
            <DartType>[typeArgument]);
      }
      assert(!coreTypes.isTop(typeArgument));
      assert(!coreTypes.isObject(typeArgument));
      assert(!coreTypes.isBottom(typeArgument));
      assert(!coreTypes.isNull(typeArgument));
      return new InterfaceType(
          coreTypes.futureOrClass,
          computeNullability(node, coreTypes.futureOrClass),
          <DartType>[typeArgument]);
    }
    return super
        .visitInterfaceType(node)
        ?.withNullability(computeNullability(node, coreTypes.futureOrClass));
  }

  @override
  DartType visitTypeParameterType(TypeParameterType node) {
    if (node.promotedBound == null) {
      DartType bound = node.parameter.bound;
      if (normalizesToNever(bound)) {
        DartType result = new NeverType(Nullability.nonNullable)
            .withNullability(node.nullability);
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
        return new TypeParameterType(
            node.parameter, node.typeParameterTypeNullability);
      } else if (bound is TypeParameterType &&
          bound.parameter == node.parameter &&
          bound.typeParameterTypeNullability ==
              node.typeParameterTypeNullability &&
          bound.promotedBound == null) {
        assert(!coreTypes.isBottom(bound));
        assert(!coreTypes.isTop(bound));
        return new TypeParameterType(
            node.parameter, node.typeParameterTypeNullability);
      } else if (bound == coreTypes.objectNonNullableRawType &&
          norm(coreTypes, node.parameter.bound) ==
              coreTypes.objectNonNullableRawType) {
        return new TypeParameterType(
            node.parameter, node.typeParameterTypeNullability);
      } else if (identical(bound, node.promotedBound)) {
        // If [bound] is identical to [node.promotedBound], then the NORM
        // algorithms didn't change the promoted bound, so the [node] is
        // unchanged as well, and we return null to indicate that.
        return null;
      }
      return new TypeParameterType(
          node.parameter, node.typeParameterTypeNullability, bound);
    }
  }

  @override
  DartType visitNeverType(NeverType node) {
    if (node.nullability == Nullability.nullable) return coreTypes.nullType;
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
