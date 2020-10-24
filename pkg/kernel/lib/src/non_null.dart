// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import '../ast.dart';
import '../core_types.dart';

/// Returns the type defines as `NonNull(type)` in the nnbd specification.
DartType computeNonNull(CoreTypes coreTypes, DartType type) {
  return type.accept1(const _NonNullVisitor(), coreTypes) ?? type;
}

/// Visitor that computes the `NonNull` function defined in the nnbd
/// specification.
///
/// The visitor returns `null` if `NonNull(T) = T`.
class _NonNullVisitor implements DartTypeVisitor1<DartType, CoreTypes> {
  const _NonNullVisitor();

  @override
  DartType defaultDartType(DartType node, CoreTypes coreTypes) {
    throw new UnsupportedError(
        "Unexpected DartType ${node} (${node.runtimeType})");
  }

  @override
  DartType visitBottomType(BottomType node, CoreTypes coreTypes) => null;

  @override
  DartType visitDynamicType(DynamicType node, CoreTypes coreTypes) => null;

  @override
  DartType visitFunctionType(FunctionType node, CoreTypes coreTypes) {
    if (node.declaredNullability == Nullability.nonNullable) {
      return null;
    }
    return node.withDeclaredNullability(Nullability.nonNullable);
  }

  @override
  DartType visitFutureOrType(FutureOrType node, CoreTypes coreTypes) {
    DartType typeArgument = node.typeArgument.accept1(this, coreTypes);
    if (node.declaredNullability == Nullability.nonNullable &&
        typeArgument == null) {
      return null;
    }
    return new FutureOrType(
        typeArgument ?? node.typeArgument, Nullability.nonNullable);
  }

  @override
  DartType visitInterfaceType(InterfaceType node, CoreTypes coreTypes) {
    if (node == coreTypes.nullType) {
      return const NeverType(Nullability.nonNullable);
    }
    if (node.declaredNullability == Nullability.nonNullable) {
      return null;
    }
    return node.withDeclaredNullability(Nullability.nonNullable);
  }

  @override
  DartType visitInvalidType(InvalidType node, CoreTypes coreTypes) => null;

  @override
  DartType visitNeverType(NeverType node, CoreTypes coreTypes) {
    if (node.declaredNullability == Nullability.nonNullable) {
      return null;
    }
    return const NeverType(Nullability.nonNullable);
  }

  @override
  DartType visitTypeParameterType(TypeParameterType node, CoreTypes coreTypes) {
    if (node.nullability == Nullability.nonNullable) {
      return null;
    }
    if (node.promotedBound != null) {
      if (node.promotedBound.nullability == Nullability.nonNullable) {
        // The promoted bound is already non-nullable so we set the declared
        // nullability to non-nullable.
        return node.withDeclaredNullability(Nullability.nonNullable);
      }
      DartType promotedBound = node.promotedBound.accept1(this, coreTypes);
      if (promotedBound == null) {
        // The promoted bound could not be made non-nullable so we set the
        // declared nullability to undetermined.
        if (node.declaredNullability == Nullability.undetermined) {
          return null;
        }
        return new TypeParameterType.intersection(
            node.parameter, Nullability.undetermined, node.promotedBound);
      } else if (promotedBound.nullability == Nullability.nonNullable) {
        // The bound could be made non-nullable so we use it as the promoted
        // bound.
        return new TypeParameterType.intersection(
            node.parameter, Nullability.nonNullable, promotedBound);
      } else {
        // The bound could not be made non-nullable so we use it as the promoted
        // bound with undetermined nullability.
        return new TypeParameterType.intersection(
            node.parameter, Nullability.undetermined, promotedBound);
      }
    } else {
      if (node.bound.nullability == Nullability.nonNullable) {
        // The bound is already non-nullable so we set the declared nullability
        // to non-nullable.
        return node.withDeclaredNullability(Nullability.nonNullable);
      }
      DartType bound = node.bound.accept1(this, coreTypes);
      if (bound == null) {
        // The bound could not be made non-nullable so we set the declared
        // nullability to undetermined.
        if (node.declaredNullability == Nullability.undetermined) {
          return null;
        }
        return node.withDeclaredNullability(Nullability.undetermined);
      } else {
        // The nullability is fully determined by the bound so we pass the
        // default nullability for the declared nullability.
        return new TypeParameterType.intersection(
            node.parameter,
            TypeParameterType.computeNullabilityFromBound(node.parameter),
            bound);
      }
    }
  }

  @override
  DartType visitTypedefType(TypedefType node, CoreTypes coreTypes) {
    if (node.declaredNullability == Nullability.nonNullable) {
      return null;
    }
    return node.withDeclaredNullability(Nullability.nonNullable);
  }

  @override
  DartType visitVoidType(VoidType node, CoreTypes coreTypes) => null;
}
