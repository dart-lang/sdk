// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import '../ast.dart';

/// Returns the type defined as `NonNull(type)` in the nnbd specification.
DartType computeNonNull(DartType type) {
  return type.accept(const _NonNullVisitor()) ?? type;
}

/// Visitor that computes the `NonNull` function defined in the nnbd
/// specification.
///
/// The visitor returns `null` if `NonNull(T) = T`.
class _NonNullVisitor implements DartTypeVisitor<DartType?> {
  const _NonNullVisitor();

  @override
  DartType? defaultDartType(DartType node) {
    throw new UnsupportedError(
        "Unexpected DartType ${node} (${node.runtimeType})");
  }

  @override
  DartType? visitDynamicType(DynamicType node) {
    // NonNull(dynamic) = dynamic
    return null;
  }

  @override
  DartType? visitFunctionType(FunctionType node) {
    // NonNull(T0 Function(...)) = T0 Function(...)
    //
    // NonNull(T?) = NonNull(T)
    //
    // NonNull(T*) = NonNull(T)
    if (node.declaredNullability == Nullability.nonNullable) {
      return null;
    }
    return node.withDeclaredNullability(Nullability.nonNullable);
  }

  @override
  DartType? visitFutureOrType(FutureOrType node) {
    // NonNull(FutureOr<T>) = FutureOr<T>
    //
    // NonNull(T?) = NonNull(T)
    //
    // NonNull(T*) = NonNull(T)

    // Note that we should _not_ compute NonNull of the type argument. Consider
    //
    //     NonNull(FutureOr<int?>?)
    //
    // We have that
    //
    //     FutureOr<int?>? = Future<int?>? | int?
    //
    // and therefore that
    //
    //     NonNull(FutureOr<int?>?) = NonNull(FutureOr<int?>?) | NonNull(int?)
    //                              = FutureOr<int?> | int
    //
    // but that means that while `null` is not a possible value from `int` it
    // is still a possible value from awaiting the future. Taking NonNull on
    // the type argument as well as on the `FutureOr`:
    //
    //     NonNull(FutureOr<int?>?) = NonNull(FutureOr<NonNull(int?)>?)
    //                              = FutureOr<int>
    //
    // would be wrong since it would compute that the awaited result could not
    // be `null`.

    if (node.declaredNullability == Nullability.nonNullable) {
      return null;
    }
    return new FutureOrType(node.typeArgument, Nullability.nonNullable);
  }

  @override
  DartType? visitInterfaceType(InterfaceType node) {
    // NonNull(C<T1, ... , Tn>) = C<T1, ... , Tn> for class C other
    // than Null (including Object).
    //
    // NonNull(Function) = Function
    //
    // NonNull(T?) = NonNull(T)
    //
    // NonNull(T*) = NonNull(T)
    if (node.declaredNullability == Nullability.nonNullable) {
      return null;
    }
    return node.withDeclaredNullability(Nullability.nonNullable);
  }

  @override
  DartType? visitExtensionType(ExtensionType node) {
    // NonNull(C<T1, ... , Tn>) = C<T1, ... , Tn> for class C other
    // than Null (including Object).
    //
    // NonNull(T?) = NonNull(T)
    //
    // NonNull(T*) = NonNull(T)
    if (node.declaredNullability == Nullability.nonNullable) {
      return null;
    }
    return node.withDeclaredNullability(Nullability.nonNullable);
  }

  @override
  DartType? visitInvalidType(InvalidType node) => null;

  @override
  DartType? visitNeverType(NeverType node) {
    // NonNull(Never) = Never
    //
    // NonNull(T?) = NonNull(T)
    //
    // NonNull(T*) = NonNull(T)
    if (node.declaredNullability == Nullability.nonNullable) {
      return null;
    }
    return const NeverType.nonNullable();
  }

  @override
  DartType? visitNullType(NullType node) {
    // NonNull(Null) = Never
    return const NeverType.nonNullable();
  }

  @override
  DartType? visitTypeParameterType(TypeParameterType node) {
    // NonNull(X) = X & NonNull(B), where B is the bound of X.
    //
    // NonNull(X & T) = X & NonNull(T)
    //
    // NonNull(T?) = NonNull(T)
    //
    // NonNull(T*) = NonNull(T)
    if (node.nullability == Nullability.nonNullable) {
      return null;
    }
    if (node.promotedBound != null) {
      // NonNull(X & T) = X & NonNull(T)

      if (node.promotedBound!.nullability == Nullability.nonNullable) {
        // The promoted bound is already non-nullable so we set the declared
        // nullability to non-nullable.
        return node.withDeclaredNullability(Nullability.nonNullable);
      }
      DartType? promotedBound = node.promotedBound!.accept(this);
      if (promotedBound == null) {
        // The promoted bound could not be made non-nullable so we set the
        // declared nullability to undetermined.
        if (node.declaredNullability == Nullability.undetermined) {
          return null;
        }
        return new TypeParameterType.intersection(
            node.parameter, Nullability.undetermined, node.promotedBound!);
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
      // NonNull(X) = X & NonNull(B), where B is the bound of X.
      if (node.bound.nullability == Nullability.nonNullable) {
        // The bound is already non-nullable so we set the declared nullability
        // to non-nullable.
        return node.withDeclaredNullability(Nullability.nonNullable);
      }
      DartType? bound = node.bound.accept(this);
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
  DartType? visitTypedefType(TypedefType node) {
    // NonNull(C<T1, ... , Tn>) = C<T1, ... , Tn> for class C other
    // than Null (including Object).
    //
    // NonNull(T?) = NonNull(T)
    //
    // NonNull(T*) = NonNull(T)
    if (node.declaredNullability == Nullability.nonNullable) {
      return null;
    }
    return node.withDeclaredNullability(Nullability.nonNullable);
  }

  @override
  DartType? visitVoidType(VoidType node) {
    // NonNull(void) = void
    return null;
  }
}
