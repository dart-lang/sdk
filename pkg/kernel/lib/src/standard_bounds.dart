// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'dart:math' as math;

import '../ast.dart';
import '../class_hierarchy.dart';
import '../core_types.dart';
import '../type_algebra.dart';
import '../type_environment.dart';
import 'legacy_erasure.dart';
import 'non_null.dart';

mixin StandardBounds {
  ClassHierarchyBase get hierarchy;

  bool isSubtypeOf(DartType subtype, DartType supertype, SubtypeCheckMode mode);

  bool areMutualSubtypes(DartType s, DartType t, SubtypeCheckMode mode);

  CoreTypes get coreTypes => hierarchy.coreTypes;

  /// Checks the value of the MORETOP predicate for [s] and [t].
  ///
  /// For the definition of MORETOP see the following:
  /// https://github.com/dart-lang/language/blob/master/resources/type-system/upper-lower-bounds.md#helper-predicates
  bool moretop(DartType s, DartType t) {
    assert(coreTypes.isTop(s) || coreTypes.isObject(s));
    assert(coreTypes.isTop(t) || coreTypes.isObject(t));

    // MORETOP(void, T) = true.
    if (s is VoidType) return true;

    // MORETOP(S, void) = false.
    if (t is VoidType) return false;

    // MORETOP(dynamic, T) = true.
    if (s is DynamicType) return true;

    // MORETOP(S, dynamic) = false.
    if (t is DynamicType) return false;

    // MORETOP(Object, T) = true.
    if (s is InterfaceType &&
        s.classNode == coreTypes.objectClass &&
        s.declaredNullability == Nullability.nonNullable) {
      return true;
    }

    // MORETOP(S, Object) = false.
    if (t is InterfaceType &&
        t.classNode == coreTypes.objectClass &&
        t.declaredNullability == Nullability.nonNullable) {
      return false;
    }

    // MORETOP(S*, T*) = MORETOP(S, T).
    if (s.declaredNullability == Nullability.legacy &&
        t.declaredNullability == Nullability.legacy) {
      DartType nonNullableS =
          s.withDeclaredNullability(Nullability.nonNullable);
      assert(!identical(s, nonNullableS));
      DartType nonNullableT =
          t.withDeclaredNullability(Nullability.nonNullable);
      assert(!identical(t, nonNullableT));
      return moretop(nonNullableS, nonNullableT);
    }

    // MORETOP(S, T*) = true.
    if (s.declaredNullability == Nullability.nonNullable &&
        t.declaredNullability == Nullability.legacy) {
      return true;
    }

    // MORETOP(S*, T) = false.
    if (s.declaredNullability == Nullability.legacy &&
        t.declaredNullability == Nullability.nonNullable) {
      return false;
    }

    // MORETOP(S?, T?) == MORETOP(S, T).
    if (s.declaredNullability == Nullability.nullable &&
        t.declaredNullability == Nullability.nullable) {
      DartType nonNullableS =
          s.withDeclaredNullability(Nullability.nonNullable);
      assert(!identical(s, nonNullableS));
      DartType nonNullableT =
          t.withDeclaredNullability(Nullability.nonNullable);
      assert(!identical(t, nonNullableT));
      return moretop(nonNullableS, nonNullableT);
    }

    // MORETOP(S, T?) = true.
    if (s.declaredNullability == Nullability.nonNullable &&
        t.declaredNullability == Nullability.nullable) {
      return true;
    }

    // MORETOP(S?, T) = false.
    if (s.declaredNullability == Nullability.nullable &&
        t.declaredNullability == Nullability.nonNullable) {
      return false;
    }

    // TODO(cstefantsova): Update the following after the spec is updated.
    if (s.declaredNullability == Nullability.nullable &&
        t.declaredNullability == Nullability.legacy) {
      return true;
    }
    if (s.declaredNullability == Nullability.legacy &&
        t.declaredNullability == Nullability.nullable) {
      return false;
    }

    // MORETOP(FutureOr<S>, FutureOr<T>) = MORETOP(S, T).
    if (s is FutureOrType &&
        s.declaredNullability == Nullability.nonNullable &&
        t is FutureOrType &&
        t.declaredNullability == Nullability.nonNullable) {
      return moretop(s.typeArgument, t.typeArgument);
    }

    throw new UnsupportedError("moretop($s, $t)");
  }

  /// Checks the value of the MOREBOTTOM predicate for [s] and [t].
  ///
  /// For the definition of MOREBOTTOM see the following:
  /// https://github.com/dart-lang/language/blob/master/resources/type-system/upper-lower-bounds.md#helper-predicates
  bool morebottom(DartType s, DartType t) {
    assert(coreTypes.isBottom(s) || coreTypes.isNull(s));
    assert(coreTypes.isBottom(t) || coreTypes.isNull(t));

    // MOREBOTTOM(Never, T) = true.
    if (s is NeverType && s.declaredNullability == Nullability.nonNullable) {
      return true;
    }

    // MOREBOTTOM(S, Never) = false.
    if (t is NeverType && t.declaredNullability == Nullability.nonNullable) {
      return false;
    }

    // MOREBOTTOM(Null, T) = true.
    if (s is NullType) {
      return true;
    }

    // MOREBOTTOM(S, Null) = false.
    if (t is NullType) {
      return false;
    }

    // MOREBOTTOM(S?, T?) = MOREBOTTOM(S, T).
    if (t.declaredNullability == Nullability.nullable &&
        s.declaredNullability == Nullability.nullable) {
      DartType nonNullableS =
          s.withDeclaredNullability(Nullability.nonNullable);
      assert(s != nonNullableS);
      DartType nonNullableT =
          t.withDeclaredNullability(Nullability.nonNullable);
      assert(t != nonNullableT);
      return morebottom(nonNullableS, nonNullableT);
    }

    // MOREBOTTOM(S, T?) = true.
    if (s.declaredNullability == Nullability.nonNullable &&
        t.declaredNullability == Nullability.nullable) {
      return true;
    }

    // MOREBOTTOM(S?, T) = false.
    if (s.declaredNullability == Nullability.nullable &&
        t.declaredNullability == Nullability.nonNullable) {
      return false;
    }

    // MOREBOTTOM(S*, T*) = MOREBOTTOM(S, T)
    if (s.declaredNullability == Nullability.legacy &&
        t.declaredNullability == Nullability.legacy) {
      DartType nonNullableS =
          s.withDeclaredNullability(Nullability.nonNullable);
      assert(s != nonNullableS);
      DartType nonNullableT =
          t.withDeclaredNullability(Nullability.nonNullable);
      assert(t != nonNullableT);
      return morebottom(nonNullableS, nonNullableT);
    }

    // MOREBOTTOM(S, T*) = true.
    if (s.declaredNullability == Nullability.nonNullable &&
        t.declaredNullability == Nullability.legacy) {
      return true;
    }

    // MOREBOTTOM(S*, T) = false.
    if (s.declaredNullability == Nullability.legacy &&
        t.declaredNullability == Nullability.nonNullable) {
      return false;
    }

    // TODO(cstefantsova): Update the following after the spec is updated.
    if (s.declaredNullability == Nullability.nullable &&
        t.declaredNullability == Nullability.legacy) {
      return true;
    }
    if (s.declaredNullability == Nullability.legacy &&
        t.declaredNullability == Nullability.nullable) {
      return false;
    }

    // MOREBOTTOM(X&S, Y&T) = MOREBOTTOM(S, T).
    if (s is IntersectionType && t is IntersectionType) {
      return morebottom(s.right, t.right);
    }

    // MOREBOTTOM(X&S, T) = true.
    if (s is IntersectionType) {
      return true;
    }

    // MOREBOTTOM(S, X&T) = false.
    if (t is IntersectionType) {
      return false;
    }

    // MOREBOTTOM(X extends S, Y extends T) = MOREBOTTOM(S, T).
    if (s is TypeParameterType && t is TypeParameterType) {
      return morebottom(s.parameter.bound, t.parameter.bound);
    }

    throw new UnsupportedError("morebottom($s, $t)");
  }

  /// Computes the standard lower bound of [type1] and [type2].
  ///
  /// Standard lower bound is a lower bound function that imposes an
  /// ordering on the top types `void`, `dynamic`, and `object`.  This function
  /// additionally handles the unknown type that appears during type inference.
  DartType getStandardLowerBound(DartType type1, DartType type2,
      {required bool isNonNullableByDefault}) {
    if (type1 is InvalidType || type2 is InvalidType) {
      return const InvalidType();
    }
    if (isNonNullableByDefault) {
      return _getNullabilityAwareStandardLowerBound(type1, type2,
          isNonNullableByDefault: isNonNullableByDefault);
    }
    return _getNullabilityObliviousStandardLowerBound(
        legacyErasure(type1), legacyErasure(type2),
        isNonNullableByDefault: isNonNullableByDefault);
  }

  DartType _getNullabilityAwareStandardLowerBound(
      DartType type1, DartType type2,
      {required bool isNonNullableByDefault}) {
    // DOWN(T, T) = T.
    if (type1 == type2) return type1;

    return getNullabilityAwareStandardLowerBoundInternal(type1, type2,
        isNonNullableByDefault: isNonNullableByDefault);
  }

  DartType getNullabilityAwareStandardLowerBoundInternal(
      DartType type1, DartType type2,
      {required bool isNonNullableByDefault}) {
    if (type1 is InvalidType || type2 is InvalidType) {
      return const InvalidType();
    }

    // DOWN(T1, T2) where TOP(T1) and TOP(T2) =
    //   T1 if MORETOP(T2, T1)
    //   T2 otherwise
    // DOWN(T1, T2) = T2 if TOP(T1)
    // DOWN(T1, T2) = T1 if TOP(T2)
    if (coreTypes.isTop(type1)) {
      if (coreTypes.isTop(type2)) return moretop(type2, type1) ? type1 : type2;
      return type2;
    } else if (coreTypes.isTop(type2)) {
      return type1;
    }

    // DOWN(T1, T2) where BOTTOM(T1) and BOTTOM(T2) =
    //   T1 if MOREBOTTOM(T1, T2)
    //   T2 otherwise
    // DOWN(T1, T2) = T2 if BOTTOM(T2)
    // DOWN(T1, T2) = T1 if BOTTOM(T1)
    if (coreTypes.isBottom(type1)) {
      if (coreTypes.isBottom(type2)) {
        return morebottom(type1, type2) ? type1 : type2;
      }
      return type1;
    } else if (coreTypes.isBottom(type2)) {
      return type2;
    }

    // DOWN(T1, T2) where NULL(T1) and NULL(T2) =
    //   T1 if MOREBOTTOM(T1, T2)
    //   T2 otherwise
    // DOWN(Null, T2) =
    //   Null if Null <: T2
    //   Never otherwise
    // DOWN(T1, Null) =
    //  Null if Null <: T1
    //  Never otherwise
    if (coreTypes.isNull(type1)) {
      if (coreTypes.isNull(type2)) {
        return morebottom(type1, type2) ? type1 : type2;
      }
      Nullability type2Nullability = type2.declaredNullability;
      if (type2Nullability == Nullability.legacy ||
          type2Nullability == Nullability.nullable) {
        return type1;
      }
      return const NeverType.nonNullable();
    } else if (coreTypes.isNull(type2)) {
      Nullability type1Nullability = type1.declaredNullability;
      if (type1Nullability == Nullability.legacy ||
          type1Nullability == Nullability.nullable) {
        return type2;
      }
      return const NeverType.nonNullable();
    }

    // DOWN(T1, T2) where OBJECT(T1) and OBJECT(T2) =
    //   T1 if MORETOP(T2, T1)
    //   T2 otherwise
    // DOWN(T1, T2) where OBJECT(T1) =
    //   T2 if T2 is non-nullable
    //   NonNull(T2) if NonNull(T2) is non-nullable
    //   Never otherwise
    // DOWN(T1, T2) where OBJECT(T2) =
    //   T1 if T1 is non-nullable
    //   NonNull(T1) if NonNull(T1) is non-nullable
    //   Never otherwise
    if (coreTypes.isObject(type1)) {
      if (coreTypes.isObject(type2)) {
        return moretop(type2, type1) ? type1 : type2;
      }
      if (type2.nullability == Nullability.nonNullable) {
        return type2;
      }
      type2 = computeNonNull(type2);
      if (type2.nullability == Nullability.nonNullable) {
        return type2;
      }
      return const NeverType.nonNullable();
    } else if (coreTypes.isObject(type2)) {
      if (type1.nullability == Nullability.nonNullable) {
        return type1;
      }
      type1 = computeNonNull(type1);
      if (type1.nullability == Nullability.nonNullable) {
        return type1;
      }
      return const NeverType.nonNullable();
    }

    // DOWN(T1*, T2*) = S* where S is DOWN(T1, T2)
    // DOWN(T1*, T2?) = S* where S is DOWN(T1, T2)
    // DOWN(T1?, T2*) = S* where S is DOWN(T1, T2)
    // DOWN(T1*, T2) = S where S is DOWN(T1, T2)
    // DOWN(T1, T2*) = S where S is DOWN(T1, T2)
    // DOWN(T1?, T2?) = S? where S is DOWN(T1, T2)
    // DOWN(T1?, T2) = S where S is DOWN(T1, T2)
    // DOWN(T1, T2?) = S where S is DOWN(T1, T2)
    {
      bool type1HasNullabilityMarker = !isTypeWithoutNullabilityMarker(type1,
          isNonNullableByDefault: isNonNullableByDefault);
      bool type2HasNullabilityMarker = !isTypeWithoutNullabilityMarker(type2,
          isNonNullableByDefault: isNonNullableByDefault);
      if (type1HasNullabilityMarker && !type2HasNullabilityMarker) {
        return _getNullabilityAwareStandardLowerBound(
            computeTypeWithoutNullabilityMarker(type1,
                isNonNullableByDefault: isNonNullableByDefault),
            type2,
            isNonNullableByDefault: isNonNullableByDefault);
      } else if (!type1HasNullabilityMarker && type2HasNullabilityMarker) {
        return _getNullabilityAwareStandardLowerBound(
            type1,
            computeTypeWithoutNullabilityMarker(type2,
                isNonNullableByDefault: isNonNullableByDefault),
            isNonNullableByDefault: isNonNullableByDefault);
      } else if (isLegacyTypeConstructorApplication(type1,
              isNonNullableByDefault: isNonNullableByDefault) ||
          isLegacyTypeConstructorApplication(type2,
              isNonNullableByDefault: isNonNullableByDefault)) {
        return _getNullabilityAwareStandardLowerBound(
                computeTypeWithoutNullabilityMarker(type1,
                    isNonNullableByDefault: isNonNullableByDefault),
                computeTypeWithoutNullabilityMarker(type2,
                    isNonNullableByDefault: isNonNullableByDefault),
                isNonNullableByDefault: isNonNullableByDefault)
            .withDeclaredNullability(Nullability.legacy);
      } else if (isNullableTypeConstructorApplication(type1) &&
          isNullableTypeConstructorApplication(type2)) {
        return _getNullabilityAwareStandardLowerBound(
                computeTypeWithoutNullabilityMarker(type1,
                    isNonNullableByDefault: isNonNullableByDefault),
                computeTypeWithoutNullabilityMarker(type2,
                    isNonNullableByDefault: isNonNullableByDefault),
                isNonNullableByDefault: isNonNullableByDefault)
            .withDeclaredNullability(Nullability.nullable);
      }
    }

    if (type1 is FunctionType && type2 is FunctionType) {
      return _getNullabilityAwareFunctionStandardLowerBound(type1, type2,
          isNonNullableByDefault: isNonNullableByDefault);
    }

    if (type1 is RecordType && type2 is RecordType) {
      return _getNullabilityAwareRecordStandardLowerBound(type1, type2,
          isNonNullableByDefault: isNonNullableByDefault);
    }

    // DOWN(T1, T2) = T1 if T1 <: T2.
    // DOWN(T1, T2) = T2 if T2 <: T1.

    // We use the non-nullable variants of the two types to determine T1 <: T2
    // without using the nullability of the outermost type. The result uses
    // [intersectNullabilities] to compute the resulting type if the subtype
    // relation is established.
    DartType typeWithoutNullabilityMarker1 =
        computeTypeWithoutNullabilityMarker(type1,
            isNonNullableByDefault: isNonNullableByDefault);
    DartType typeWithoutNullabilityMarker2 =
        computeTypeWithoutNullabilityMarker(type2,
            isNonNullableByDefault: isNonNullableByDefault);
    if (isSubtypeOf(typeWithoutNullabilityMarker1,
        typeWithoutNullabilityMarker2, SubtypeCheckMode.withNullabilities)) {
      return type1.withDeclaredNullability(intersectNullabilities(
          type1.declaredNullability, type2.declaredNullability));
    }
    if (isSubtypeOf(typeWithoutNullabilityMarker2,
        typeWithoutNullabilityMarker1, SubtypeCheckMode.withNullabilities)) {
      return type2.withDeclaredNullability(intersectNullabilities(
          type1.declaredNullability, type2.declaredNullability));
    }

    // See https://github.com/dart-lang/sdk/issues/37439#issuecomment-519654959.
    if (type1 is FutureOrType) {
      if (type2 is FutureOrType) {
        // GLB(FutureOr<A>, FutureOr<B>) == FutureOr<GLB(A, B)>
        DartType argument = getStandardLowerBound(
            type1.typeArgument, type2.typeArgument,
            isNonNullableByDefault: isNonNullableByDefault);
        return new FutureOrType(argument, argument.declaredNullability);
      }
      if (type2 is InterfaceType && type2.classNode == coreTypes.futureClass) {
        // GLB(FutureOr<A>, Future<B>) == Future<GLB(A, B)>
        return new InterfaceType(
            coreTypes.futureClass,
            intersectNullabilities(
                type1.declaredNullability, type2.declaredNullability),
            <DartType>[
              getStandardLowerBound(type1.typeArgument, type2.typeArguments[0],
                  isNonNullableByDefault: isNonNullableByDefault)
            ]);
      }
      // GLB(FutureOr<A>, B) == GLB(A, B)
      return getStandardLowerBound(type1.typeArgument, type2,
          isNonNullableByDefault: isNonNullableByDefault);
    }
    // The if-statement below handles the following rule:
    //     GLB(A, FutureOr<B>) ==  GLB(FutureOr<B>, A)
    // It's broken down into sub-cases instead of making a recursive call to
    // avoid making the checks that were already made above.  Note that at this
    // point it's not possible for type1 to be a FutureOr.
    if (type2 is FutureOrType) {
      if (type1 is InterfaceType && type1.classNode == coreTypes.futureClass) {
        // GLB(Future<A>, FutureOr<B>) == Future<GLB(B, A)>
        return new InterfaceType(
            coreTypes.futureClass,
            intersectNullabilities(
                type1.declaredNullability, type2.declaredNullability),
            <DartType>[
              getStandardLowerBound(type2.typeArgument, type1.typeArguments[0],
                  isNonNullableByDefault: isNonNullableByDefault)
            ]);
      }
      // GLB(A, FutureOr<B>) == GLB(B, A)
      return getStandardLowerBound(type2.typeArgument, type1,
          isNonNullableByDefault: isNonNullableByDefault);
    }

    // DOWN(T1, T2) = Never otherwise.
    return NeverType.fromNullability(intersectNullabilities(
        type1.declaredNullability, type2.declaredNullability));
  }

  DartType _getNullabilityObliviousStandardLowerBound(
      DartType type1, DartType type2,
      {required bool isNonNullableByDefault}) {
    // Do legacy erasure on the argument, so that the result types that are
    // computed from arguments are legacy.
    type1 = type1 is NullType
        ? type1
        : type1.withDeclaredNullability(Nullability.legacy);
    type2 = type2 is NullType
        ? type2
        : type2.withDeclaredNullability(Nullability.legacy);

    // For all types T, SLB(T,T) = T.  Note that we don't test for equality
    // because we don't want to make the algorithm quadratic.  This is ok
    // because the check is not needed for correctness; it's just a speed
    // optimization.
    if (identical(type1, type2)) {
      return type1;
    }

    return getNullabilityObliviousStandardLowerBoundInternal(type1, type2,
        isNonNullableByDefault: isNonNullableByDefault);
  }

  DartType getNullabilityObliviousStandardLowerBoundInternal(
      DartType type1, DartType type2,
      {required bool isNonNullableByDefault}) {
    // SLB(void, T) = SLB(T, void) = T.
    if (type1 is VoidType) {
      return type2;
    }
    if (type2 is VoidType) {
      return type1;
    }

    // SLB(dynamic, T) = SLB(T, dynamic) = T if T is not void.
    if (type1 is DynamicType) {
      return type2;
    }
    if (type2 is DynamicType) {
      return type1;
    }

    // SLB(Object, T) = SLB(T, Object) = T if T is not void or dynamic.
    if (type1 == coreTypes.objectLegacyRawType) {
      return type2;
    }
    if (type2 == coreTypes.objectLegacyRawType) {
      return type1;
    }

    // SLB(bottom, T) = SLB(T, bottom) = bottom.
    if (type1 is NullType) return type1;
    if (type2 is NullType) return type2;

    // Function types have structural lower bounds.
    if (type1 is FunctionType && type2 is FunctionType) {
      return _getNullabilityObliviousFunctionStandardLowerBound(type1, type2,
          isNonNullableByDefault: isNonNullableByDefault);
    }

    // Otherwise, the lower bounds  of two types is one of them it if it is a
    // subtype of the other.
    if (isSubtypeOf(type1, type2, SubtypeCheckMode.ignoringNullabilities)) {
      return type1;
    }

    if (isSubtypeOf(type2, type1, SubtypeCheckMode.ignoringNullabilities)) {
      return type2;
    }

    // See https://github.com/dart-lang/sdk/issues/37439#issuecomment-519654959.
    if (type1 is FutureOrType) {
      if (type2 is FutureOrType) {
        // GLB(FutureOr<A>, FutureOr<B>) == FutureOr<GLB(A, B)>
        DartType argument = getStandardLowerBound(
            type1.typeArgument, type2.typeArgument,
            isNonNullableByDefault: isNonNullableByDefault);
        return new FutureOrType(argument, argument.declaredNullability);
      }
      if (type2 is InterfaceType && type2.classNode == coreTypes.futureClass) {
        // GLB(FutureOr<A>, Future<B>) == Future<GLB(A, B)>
        return new InterfaceType(
            coreTypes.futureClass,
            intersectNullabilities(
                type1.declaredNullability, type2.declaredNullability),
            <DartType>[
              getStandardLowerBound(type1.typeArgument, type2.typeArguments[0],
                  isNonNullableByDefault: isNonNullableByDefault)
            ]);
      }
      // GLB(FutureOr<A>, B) == GLB(A, B)
      return getStandardLowerBound(type1.typeArgument, type2,
          isNonNullableByDefault: isNonNullableByDefault);
    }
    // The if-statement below handles the following rule:
    //     GLB(A, FutureOr<B>) ==  GLB(FutureOr<B>, A)
    // It's broken down into sub-cases instead of making a recursive call to
    // avoid making the checks that were already made above.  Note that at this
    // point it's not possible for type1 to be a FutureOr.
    if (type2 is FutureOrType) {
      if (type1 is FutureOrType) {
        // GLB(Future<A>, FutureOr<B>) == Future<GLB(B, A)>
        return new InterfaceType(
            coreTypes.futureClass,
            intersectNullabilities(
                type1.declaredNullability, type2.declaredNullability),
            <DartType>[
              getStandardLowerBound(type2.typeArgument, type1.typeArgument,
                  isNonNullableByDefault: isNonNullableByDefault)
            ]);
      }
      // GLB(A, FutureOr<B>) == GLB(B, A)
      return getStandardLowerBound(type2.typeArgument, type1,
          isNonNullableByDefault: isNonNullableByDefault);
    }

    // No subtype relation, so the lower bound is bottom.
    if (isNonNullableByDefault) {
      return const NeverType.nonNullable();
    } else {
      return const NeverType.legacy();
    }
  }

  /// Computes the standard upper bound of two types.
  ///
  /// Standard upper bound is an upper bound function that imposes an ordering
  /// on the top types 'void', 'dynamic', and `object`.  This function
  /// additionally handles the unknown type that appears during type inference.
  DartType getStandardUpperBound(DartType type1, DartType type2,
      {required bool isNonNullableByDefault}) {
    if (type1 is InvalidType || type2 is InvalidType) {
      return const InvalidType();
    }
    if (isNonNullableByDefault) {
      return _getNullabilityAwareStandardUpperBound(type1, type2,
          isNonNullableByDefault: isNonNullableByDefault);
    }
    return _getNullabilityObliviousStandardUpperBound(
        legacyErasure(type1), legacyErasure(type2), isNonNullableByDefault);
  }

  DartType _getNullabilityAwareStandardUpperBound(
      DartType type1, DartType type2,
      {required bool isNonNullableByDefault}) {
    // UP(T, T) = T
    if (type1 == type2) return type1;

    return getNullabilityAwareStandardUpperBoundInternal(type1, type2,
        isNonNullableByDefault: isNonNullableByDefault);
  }

  DartType getNullabilityAwareStandardUpperBoundInternal(
      DartType type1, DartType type2,
      {required bool isNonNullableByDefault}) {
    if (type1 is InvalidType || type2 is InvalidType) {
      return const InvalidType();
    }

    // UP(T1, T2) where TOP(T1) and TOP(T2) =
    //   T1 if MORETOP(T1, T2)
    //   T2 otherwise
    // UP(T1, T2) = T1 if TOP(T1)
    // UP(T1, T2) = T2 if TOP(T2)
    if (coreTypes.isTop(type1)) {
      if (coreTypes.isTop(type2)) return moretop(type1, type2) ? type1 : type2;
      return type1;
    } else if (coreTypes.isTop(type2)) {
      return type2;
    }

    // UP(T1, T2) where BOTTOM(T1) and BOTTOM(T2) =
    //   T2 if MOREBOTTOM(T1, T2)
    //   T1 otherwise
    // UP(T1, T2) = T2 if BOTTOM(T1)
    // UP(T1, T2) = T1 if BOTTOM(T2)
    if (coreTypes.isBottom(type1)) {
      if (coreTypes.isBottom(type2)) {
        return morebottom(type1, type2) ? type2 : type1;
      }
      return type2;
    } else if (coreTypes.isBottom(type2)) {
      return type1;
    }

    // UP(T1, T2) where NULL(T1) and NULL(T2) =
    //   T2 if MOREBOTTOM(T1, T2)
    //   T1 otherwise
    // UP(T1, T2) where NULL(T1) =
    //   T2 if T2 is nullable
    //   T2? otherwise
    // UP(T1, T2) where NULL(T2) =
    //   T1 if T1 is nullable
    //   T1? otherwise
    if (coreTypes.isNull(type1)) {
      if (coreTypes.isNull(type2)) {
        return morebottom(type1, type2) ? type2 : type1;
      }
      if (type2 is IntersectionType) {
        // Intersection types are treated specially because of the semantics of
        // the declared nullability and the fact that the point of declaration
        // of the intersection type is taken as the point of declaration of the
        // corresponding type-parameter type.
        //
        // In case of the upper bound, both the left-hand side and the
        // right-hand side should be updated.
        return new IntersectionType(
            type2.left.withDeclaredNullability(Nullability.nullable),
            type2.right.withDeclaredNullability(Nullability.nullable));
      } else {
        return type2.withDeclaredNullability(Nullability.nullable);
      }
    } else if (coreTypes.isNull(type2)) {
      if (type1 is IntersectionType) {
        // Intersection types are treated specially because of the semantics of
        // the declared nullability and the fact that the point of declaration
        // of the intersection type is taken as the point of declaration of the
        // corresponding type-parameter type.
        //
        // In case of the upper bound, both the left-hand side and the
        // right-hand side should be updated.
        return new IntersectionType(
            type1.left.withDeclaredNullability(Nullability.nullable),
            type1.right.withDeclaredNullability(Nullability.nullable));
      } else {
        return type1.withDeclaredNullability(Nullability.nullable);
      }
    }

    // UP(T1, T2) where OBJECT(T1) and OBJECT(T2) =
    //   T1 if MORETOP(T1, T2)
    //   T2 otherwise
    // UP(T1, T2) where OBJECT(T1) =
    //   T1 if T2 is non-nullable
    //   T1? otherwise
    // UP(T1, T2) where OBJECT(T2) =
    //   T2 if T1 is non-nullable
    //   T2? otherwise
    if (coreTypes.isObject(type1)) {
      if (coreTypes.isObject(type2)) {
        return moretop(type1, type2) ? type1 : type2;
      }
      if (type2.nullability == Nullability.nonNullable) {
        return type1;
      }
      return type1.withDeclaredNullability(Nullability.nullable);
    } else if (coreTypes.isObject(type2)) {
      if (type1.nullability == Nullability.nonNullable) {
        return type2;
      }
      return type2.withDeclaredNullability(Nullability.nullable);
    }

    // UP(T1*, T2*) = S* where S is UP(T1, T2)
    // UP(T1*, T2?) = S? where S is UP(T1, T2)
    // UP(T1?, T2*) = S? where S is UP(T1, T2)
    // UP(T1*, T2) = S* where S is UP(T1, T2)
    // UP(T1, T2*) = S* where S is UP(T1, T2)
    // UP(T1?, T2?) = S? where S is UP(T1, T2)
    // UP(T1?, T2) = S? where S is UP(T1, T2)
    // UP(T1, T2?) = S? where S is UP(T1, T2)
    if (isNullableTypeConstructorApplication(type1) ||
        isNullableTypeConstructorApplication(type2)) {
      return _getNullabilityAwareStandardUpperBound(
              computeTypeWithoutNullabilityMarker(type1,
                  isNonNullableByDefault: isNonNullableByDefault),
              computeTypeWithoutNullabilityMarker(type2,
                  isNonNullableByDefault: isNonNullableByDefault),
              isNonNullableByDefault: isNonNullableByDefault)
          .withDeclaredNullability(Nullability.nullable);
    }
    if (isLegacyTypeConstructorApplication(type1,
            isNonNullableByDefault: isNonNullableByDefault) ||
        isLegacyTypeConstructorApplication(type2,
            isNonNullableByDefault: isNonNullableByDefault)) {
      return _getNullabilityAwareStandardUpperBound(
              computeTypeWithoutNullabilityMarker(type1,
                  isNonNullableByDefault: isNonNullableByDefault),
              computeTypeWithoutNullabilityMarker(type2,
                  isNonNullableByDefault: isNonNullableByDefault),
              isNonNullableByDefault: isNonNullableByDefault)
          .withDeclaredNullability(Nullability.legacy);
    }

    if (type1 is TypeParameterType) {
      return _getNullabilityAwareTypeParameterStandardUpperBound(
          type1, type2, isNonNullableByDefault);
    }

    if (type1 is IntersectionType) {
      return _getNullabilityAwareIntersectionStandardUpperBound(
          type1, type2, isNonNullableByDefault);
    }

    if (type2 is TypeParameterType) {
      return _getNullabilityAwareTypeParameterStandardUpperBound(
          type2, type1, isNonNullableByDefault);
    }

    if (type2 is IntersectionType) {
      return _getNullabilityAwareIntersectionStandardUpperBound(
          type2, type1, isNonNullableByDefault);
    }

    if (type1 is FunctionType) {
      if (type2 is FunctionType) {
        return _getNullabilityAwareFunctionStandardUpperBound(
            type1, type2, isNonNullableByDefault);
      }

      if (type2 is InterfaceType &&
          type2.classNode == coreTypes.functionClass) {
        // UP(T Function<...>(...), Function) = Function
        return coreTypes.functionRawType(uniteNullabilities(
            type1.declaredNullability, type2.declaredNullability));
      }

      // UP(T Function<...>(...), T2) = UP(Object, T2)
      return _getNullabilityAwareStandardUpperBound(
          coreTypes.objectNonNullableRawType, type2,
          isNonNullableByDefault: isNonNullableByDefault);
    } else if (type2 is FunctionType) {
      if (type1 is InterfaceType &&
          type1.classNode == coreTypes.functionClass) {
        // UP(Function, T Function<...>(...)) = Function
        return coreTypes.functionRawType(uniteNullabilities(
            type1.declaredNullability, type2.declaredNullability));
      }

      // UP(T1, T Function<...>(...)) = UP(T1, Object)
      return _getNullabilityAwareStandardUpperBound(
          type1, coreTypes.objectNonNullableRawType,
          isNonNullableByDefault: isNonNullableByDefault);
    }

    if (type1 is RecordType) {
      if (type2 is RecordType) {
        return _getNullabilityAwareRecordStandardUpperBound(
            type1, type2, isNonNullableByDefault);
      }

      if (type2 is InterfaceType && type2.classNode == coreTypes.recordClass) {
        // UP(Record(...), Record) = Record
        return coreTypes.recordRawType(uniteNullabilities(
            type1.declaredNullability, type2.declaredNullability));
      }

      // UP(Record(...), T2) = UP(Object, T2)
      return _getNullabilityAwareStandardUpperBound(
          coreTypes.objectNonNullableRawType, type2,
          isNonNullableByDefault: isNonNullableByDefault);
    } else if (type2 is RecordType) {
      if (type1 is InterfaceType && type1.classNode == coreTypes.recordClass) {
        // UP(Record, Record(...)) = Record
        return coreTypes.recordRawType(uniteNullabilities(
            type1.declaredNullability, type2.declaredNullability));
      }

      // UP(T1, Record(...)) = UP(T1, Object)
      return _getNullabilityAwareStandardUpperBound(
          type1, coreTypes.objectNonNullableRawType,
          isNonNullableByDefault: isNonNullableByDefault);
    }

    // UP(FutureOr<T1>, FutureOr<T2>) = FutureOr<T3> where T3 = UP(T1, T2)
    // UP(Future<T1>, FutureOr<T2>) = FutureOr<T3> where T3 = UP(T1, T2)
    // UP(FutureOr<T1>, Future<T2>) = FutureOr<T3> where T3 = UP(T1, T2)
    // UP(T1, FutureOr<T2>) = FutureOr<T3> where T3 = UP(T1, T2)
    // UP(FutureOr<T1>, T2) = FutureOr<T3> where T3 = UP(T1, T2)
    if (type1 is FutureOrType) {
      DartType t1 = type1.typeArgument;
      DartType t2;
      if (type2 is InterfaceType && type2.classNode == coreTypes.futureClass) {
        t2 = type2.typeArguments.single;
      } else if (type2 is FutureOrType) {
        t2 = type2.typeArgument;
      } else {
        t2 = type2;
      }
      return new FutureOrType(
          getStandardUpperBound(t1, t2,
              isNonNullableByDefault: isNonNullableByDefault),
          uniteNullabilities(
              type1.declaredNullability, type2.declaredNullability));
    } else if (type2 is FutureOrType) {
      DartType t2 = type2.typeArgument;
      DartType t1;
      if (type1 is InterfaceType && type1.classNode == coreTypes.futureClass) {
        t1 = type1.typeArguments.single;
      } else {
        t1 = type1;
      }
      return new FutureOrType(
          getStandardUpperBound(t1, t2,
              isNonNullableByDefault: isNonNullableByDefault),
          uniteNullabilities(
              type1.declaredNullability, type2.declaredNullability));
    }

    // UP(T1, T2) = T2 if T1 <: T2
    //   Note that both types must be interface or extension types at this
    //   point.
    assert(type1 is InterfaceType || type1 is ExtensionType,
        "Expected type1 to be an interface type, got '${type1.runtimeType}'.");
    assert(type2 is InterfaceType || type2 is ExtensionType,
        "Expected type2 to be an interface type, got '${type2.runtimeType}'.");

    // We use the non-nullable variants of the two interfaces types to determine
    // T1 <: T2 without using the nullability of the outermost type. The result
    // uses [uniteNullabilities] to compute the resulting type if the subtype
    // relation is established.
    DartType typeWithoutNullabilityMarker1 =
        computeTypeWithoutNullabilityMarker(type1,
            isNonNullableByDefault: isNonNullableByDefault);
    DartType typeWithoutNullabilityMarker2 =
        computeTypeWithoutNullabilityMarker(type2,
            isNonNullableByDefault: isNonNullableByDefault);

    if (isSubtypeOf(typeWithoutNullabilityMarker1,
        typeWithoutNullabilityMarker2, SubtypeCheckMode.withNullabilities)) {
      return type2.withDeclaredNullability(
          uniteNullabilities(type1.nullability, type2.nullability));
    }

    // UP(T1, T2) = T1 if T2 <: T1
    //   Note that both types must be interface or extension types at this
    //   point.
    if (isSubtypeOf(typeWithoutNullabilityMarker2,
        typeWithoutNullabilityMarker1, SubtypeCheckMode.withNullabilities)) {
      return type1.withDeclaredNullability(uniteNullabilities(
          type1.declaredNullability, type2.declaredNullability));
    }

    // UP(C<T0, ..., Tn>, C<S0, ..., Sn>) = C<R0,..., Rn> where Ri is UP(Ti, Si)
    Class? cls;
    ExtensionTypeDeclaration? extensionTypeDeclaration;
    List<TypeParameter>? typeParameters;
    List<DartType>? leftArguments;
    List<DartType>? rightArguments;
    if (type1 is InterfaceType && type2 is InterfaceType) {
      if (type1.classNode == type2.classNode) {
        cls = type1.classNode;
        typeParameters = cls.typeParameters;
        leftArguments = type1.typeArguments;
        rightArguments = type2.typeArguments;
      }
    }
    if (type1 is ExtensionType && type2 is ExtensionType) {
      if (type1.extensionTypeDeclaration == type2.extensionTypeDeclaration) {
        extensionTypeDeclaration = type1.extensionTypeDeclaration;
        leftArguments = type1.typeArguments;
        rightArguments = type2.typeArguments;
      }
    }

    if (typeParameters != null &&
        leftArguments != null &&
        rightArguments != null) {
      int n = typeParameters.length;
      List<DartType> typeArguments = new List<DartType>.of(leftArguments);
      for (int i = 0; i < n; ++i) {
        int variance = typeParameters[i].variance;
        if (variance == Variance.contravariant) {
          typeArguments[i] = _getNullabilityAwareStandardLowerBound(
              leftArguments[i], rightArguments[i],
              isNonNullableByDefault: isNonNullableByDefault);
        } else if (variance == Variance.invariant) {
          if (!areMutualSubtypes(leftArguments[i], rightArguments[i],
              SubtypeCheckMode.withNullabilities)) {
            return _getLegacyLeastUpperBound(type1, type2,
                isNonNullableByDefault: isNonNullableByDefault);
          }
        } else {
          typeArguments[i] = _getNullabilityAwareStandardUpperBound(
              leftArguments[i], rightArguments[i],
              isNonNullableByDefault: isNonNullableByDefault);
        }
      }
      if (cls != null) {
        return new InterfaceType(
            cls,
            uniteNullabilities(
                type1.declaredNullability, type2.declaredNullability),
            typeArguments);
      } else {
        return new ExtensionType(
            extensionTypeDeclaration!,
            uniteNullabilities(
                type1.declaredNullability, type2.declaredNullability),
            typeArguments);
      }
    }

    // UP(C0<T0, ..., Tn>, C1<S0, ..., Sk>)
    //   = least upper bound of two interfaces as in Dart 1.
    return _getLegacyLeastUpperBound(type1, type2,
        isNonNullableByDefault: isNonNullableByDefault);
  }

  DartType _getLegacyLeastUpperBound(DartType type1, DartType type2,
      {required bool isNonNullableByDefault}) {
    if (type1 is InterfaceType && type2 is InterfaceType) {
      return hierarchy.getLegacyLeastUpperBound(type1, type2,
          isNonNullableByDefault: isNonNullableByDefault);
    } else if (type1 is ExtensionType && type2 is ExtensionType) {
      // This mimics the legacy least upper bound implementation for regular
      // classes, where the least upper bound is found as the single common
      // supertype with the highest class hierarchy depth.

      // TODO(johnniwinther): Move this computation to [ClassHierarchyBase] and
      // cache it there.
      // TODO(johnniwinther): Handle non-extension type supertypes.
      Map<ExtensionTypeDeclaration, int> extensionTypeDeclarationDepth = {};

      int computeExtensionTypeDeclarationDepth(
          ExtensionTypeDeclaration extensionTypeDeclaration) {
        int? depth = extensionTypeDeclarationDepth[extensionTypeDeclaration];
        if (depth == null) {
          int maxDepth = 0;
          for (DartType implemented in extensionTypeDeclaration.implements) {
            if (implemented is ExtensionType) {
              int supertypeDepth = computeExtensionTypeDeclarationDepth(
                  implemented.extensionTypeDeclaration);
              if (supertypeDepth >= maxDepth) {
                maxDepth = supertypeDepth + 1;
              }
            }
          }
          depth = extensionTypeDeclarationDepth[extensionTypeDeclaration] =
              maxDepth;
        }
        return depth;
      }

      // TODO(johnniwinther): Handle non-extension type supertypes.
      void computeSuperTypes(
          ExtensionType type, List<ExtensionType> supertypes) {
        computeExtensionTypeDeclarationDepth(type.extensionTypeDeclaration);
        supertypes.add(type);
        for (DartType implemented in type.extensionTypeDeclaration.implements) {
          if (implemented is ExtensionType) {
            ExtensionType supertype = hierarchy.getExtensionTypeAsInstanceOf(
                type, implemented.extensionTypeDeclaration,
                isNonNullableByDefault: isNonNullableByDefault)!;
            computeSuperTypes(supertype, supertypes);
          }
        }
      }

      List<ExtensionType> supertypes1 = [];
      computeSuperTypes(type1, supertypes1);
      List<ExtensionType> supertypes2 = [];
      computeSuperTypes(type2, supertypes2);

      Set<ExtensionType> set = supertypes1.toSet()..retainAll(supertypes2);
      Map<int, List<ExtensionType>> commonSupertypesByDepth = {};
      for (ExtensionType type in set) {
        (commonSupertypesByDepth[extensionTypeDeclarationDepth[
                type.extensionTypeDeclaration]!] ??= [])
            .add(type);
      }
      int maxDepth = -1;
      ExtensionType? candidate;
      for (MapEntry<int, List<ExtensionType>> entry
          in commonSupertypesByDepth.entries) {
        if (entry.key > maxDepth && entry.value.length == 1) {
          maxDepth = entry.key;
          candidate = entry.value.single;
        }
      }
      if (candidate != null) {
        return candidate;
      }
    }
    return coreTypes.objectRawType(
        uniteNullabilities(type1.nullability, type2.nullability));
  }

  /// Computes the nullability-aware lower bound of two function types.
  ///
  /// The algorithm is defined as follows:
  /// DOWN(
  ///   <X0 extends B00, ..., Xm extends B0m>(P00, ..., P0k) -> T0,
  ///   <X0 extends B10, ..., Xm extends B1m>(P10, ..., P1l) -> T1)
  /// =
  ///   <X0 extends B20, ..., Xm extends B2m>(P20, ..., P2q) -> R0
  /// if:
  ///   each B0i and B1i are equal types (syntactically),
  ///   q is max(k, l),
  ///   R0 is DOWN(T0, T1),
  ///   B2i is B0i,
  ///   P2i is UP(P0i, P1i) for i <= than min(k, l),
  ///   P2i is P0i for k < i <= q,
  ///   P2i is P1i for l < i <= q, and
  ///   P2i is optional if P0i or P1i is optional.
  ///
  /// DOWN(
  ///   <X0 extends B00, ..., Xm extends B0m>(P00, ..., P0k, Named0) -> T0,
  ///   <X0 extends B10, ..., Xm extends B1m>(P10, ..., P1k, Named1) -> T1)
  /// =
  ///   <X0 extends B20, ..., Xm extends B2m>(P20, ..., P2k, Named2) -> R0
  /// if:
  ///   each B0i and B1i are equal types (syntactically),
  ///   R0 is DOWN(T0, T1),
  ///   B2i is B0i,
  ///   P2i is UP(P0i, P1i),
  ///   Named2 contains R2i xi for each xi in both Named0 and Named1,
  ///     where R0i xi is in Named0,
  ///     where R1i xi is in Named1,
  ///     and R2i is UP(R0i, R1i),
  ///     and R2i xi is required if xi is required in both Named0 and Named1,
  ///   Named2 contains R0i xi for each xi in Named0 and not Named1,
  ///     where xi is optional in Named2,
  ///   Named2 contains R1i xi for each xi in Named1 and not Named0, and
  ///     where xi is optional in Named2.
  /// DOWN(T Function<...>(...), S Function<...>(...)) = Never otherwise.
  DartType _getNullabilityAwareFunctionStandardLowerBound(
      FunctionType f, FunctionType g,
      {required bool isNonNullableByDefault}) {
    bool haveNamed =
        f.namedParameters.isNotEmpty || g.namedParameters.isNotEmpty;
    bool haveOptionalPositional =
        f.requiredParameterCount < f.positionalParameters.length ||
            g.requiredParameterCount < g.positionalParameters.length;

    // The fallback result for whenever the following rule applies:
    //     DOWN(T Function<...>(...), S Function<...>(...)) = Never otherwise.
    final DartType fallbackResult = NeverType.fromNullability(
        intersectNullabilities(f.declaredNullability, g.declaredNullability));

    if (haveNamed && haveOptionalPositional) return fallbackResult;
    if (haveNamed &&
        f.positionalParameters.length != g.positionalParameters.length) {
      return fallbackResult;
    }

    int m = f.typeParameters.length;
    bool boundsMatch = false;
    Substitution substitution = Substitution.empty;
    if (g.typeParameters.length == m) {
      boundsMatch = true;
      if (m != 0) {
        Map<TypeParameter, DartType> substitutionMap =
            <TypeParameter, DartType>{};
        for (int i = 0; i < m; ++i) {
          substitutionMap[g.typeParameters[i]] =
              new TypeParameterType.forAlphaRenaming(
                  g.typeParameters[i], f.typeParameters[i]);
        }
        substitution = Substitution.fromMap(substitutionMap);
        for (int i = 0; i < m && boundsMatch; ++i) {
          // TODO(cstefantsova): Figure out if a procedure for syntactic
          // equality should be used instead.
          if (!areMutualSubtypes(
              f.typeParameters[i].bound,
              substitution.substituteType(g.typeParameters[i].bound),
              SubtypeCheckMode.withNullabilities)) {
            boundsMatch = false;
          }
        }
      }
    }
    if (!boundsMatch) return fallbackResult;
    int maxPos =
        math.max(f.positionalParameters.length, g.positionalParameters.length);
    int minPos =
        math.min(f.positionalParameters.length, g.positionalParameters.length);

    List<TypeParameter> typeParameters = f.typeParameters;

    List<DartType> positionalParameters =
        new List<DartType>.filled(maxPos, dummyDartType);
    for (int i = 0; i < minPos; ++i) {
      positionalParameters[i] = _getNullabilityAwareStandardUpperBound(
          f.positionalParameters[i],
          substitution.substituteType(g.positionalParameters[i]),
          isNonNullableByDefault: isNonNullableByDefault);
    }
    for (int i = minPos; i < f.positionalParameters.length; ++i) {
      positionalParameters[i] = f.positionalParameters[i];
    }
    for (int i = minPos; i < g.positionalParameters.length; ++i) {
      positionalParameters[i] =
          substitution.substituteType(g.positionalParameters[i]);
    }

    List<NamedType> namedParameters = <NamedType>[];
    {
      // Assuming that the named parameters of both types are sorted
      // lexicographically.
      int i = 0;
      int j = 0;
      while (i < f.namedParameters.length && j < g.namedParameters.length) {
        NamedType named1 = f.namedParameters[i];
        NamedType named2 = g.namedParameters[j];
        int order = named1.name.compareTo(named2.name);
        NamedType named;
        if (order < 0) {
          named = new NamedType(named1.name, named1.type, isRequired: false);
          ++i;
        } else if (order > 0) {
          named = !named2.isRequired
              ? named2
              : new NamedType(
                  named2.name, substitution.substituteType(named2.type),
                  isRequired: false);
          ++j;
        } else {
          named = new NamedType(
              named1.name,
              _getNullabilityAwareStandardUpperBound(
                  named1.type, substitution.substituteType(named2.type),
                  isNonNullableByDefault: isNonNullableByDefault),
              isRequired: named1.isRequired && named2.isRequired);
          ++i;
          ++j;
        }
        namedParameters.add(named);
      }
      while (i < f.namedParameters.length) {
        NamedType named1 = f.namedParameters[i];
        namedParameters.add(!named1.isRequired
            ? named1
            : new NamedType(named1.name, named1.type, isRequired: false));
        ++i;
      }
      while (j < g.namedParameters.length) {
        NamedType named2 = g.namedParameters[j];
        namedParameters.add(new NamedType(
            named2.name, substitution.substituteType(named2.type),
            isRequired: false));
        ++j;
      }
    }

    DartType returnType = _getNullabilityAwareStandardLowerBound(
        f.returnType, substitution.substituteType(g.returnType),
        isNonNullableByDefault: isNonNullableByDefault);

    return new FunctionType(positionalParameters, returnType,
        intersectNullabilities(f.declaredNullability, g.declaredNullability),
        namedParameters: namedParameters,
        typeParameters: typeParameters,
        requiredParameterCount:
            math.min(f.requiredParameterCount, g.requiredParameterCount));
  }

  /// Computes the nullability-aware lower bound of two record types.
  ///
  /// The algorithm is defined as follows:
  /// DOWN((P00, ..., P0k, Named0), (P10, ..., P1k, Named1)) =
  ///   (P20, ..., P2k, Named2)
  /// if:
  ///   P2i is DOWN(P0i, P1i),
  ///   Named0 contains R0i xi
  ///       if Named1 contains R1i xi
  ///   Named1 contains R1i xi
  ///       if Named0 contains R0i xi
  ///   Named2 contains exactly R2i xi
  ///       for each xi in both Named0 and Named1
  ///     where R0i xi is in Named0
  ///     where R1i xi is in Named1
  ///     and R2i is UP(R0i, R1i)
  /// DOWN(Record(...), Record(...)) = Never otherwise.
  DartType _getNullabilityAwareRecordStandardLowerBound(
      RecordType r1, RecordType r2,
      {required bool isNonNullableByDefault}) {
    // The fallback result for whenever the following rule applies:
    //     DOWN(Record(...), Record(...)) = Never otherwise.
    late final DartType fallbackResult = NeverType.fromNullability(
        intersectNullabilities(r1.declaredNullability, r2.declaredNullability));

    if (r1.positional.length != r2.positional.length ||
        r1.named.length != r2.named.length) {
      return fallbackResult;
    }

    int positionalLength = r1.positional.length;
    int namedLength = r1.named.length;

    for (int i = 0; i < namedLength; i++) {
      if (r1.named[i].name != r2.named[i].name) {
        return fallbackResult;
      }
    }

    List<DartType> positional = new List<DartType>.generate(
        positionalLength,
        (i) => _getNullabilityAwareStandardLowerBound(
            r1.positional[i], r2.positional[i],
            isNonNullableByDefault: isNonNullableByDefault));

    List<NamedType> named = new List<NamedType>.generate(
        namedLength,
        (i) => new NamedType(
            r1.named[i].name,
            _getNullabilityAwareStandardLowerBound(
                r1.named[i].type, r2.named[i].type,
                isNonNullableByDefault: isNonNullableByDefault)));

    return new RecordType(positional, named,
        intersectNullabilities(r1.declaredNullability, r2.declaredNullability));
  }

  /// Computes the nullability-aware lower bound of two function types.
  ///
  /// UP(
  ///   <X0 extends B00, ... Xm extends B0m>(P00, ... P0k) -> T0,
  ///   <X0 extends B10, ... Xm extends B1m>(P10, ... P1l) -> T1)
  /// =
  ///   <X0 extends B20, ..., Xm extends B2m>(P20, ..., P2q) -> R0
  /// if:
  ///   each B0i and B1i are equal types (syntactically)
  ///   Both have the same number of required positional parameters
  ///   q is min(k, l)
  ///   R0 is UP(T0, T1)
  ///   B2i is B0i
  ///   P2i is DOWN(P0i, P1i)
  /// UP(
  ///   <X0 extends B00, ... Xm extends B0m>(P00, ... P0k, Named0) -> T0,
  ///   <X0 extends B10, ... Xm extends B1m>(P10, ... P1k, Named1) -> T1)
  /// =
  ///   <X0 extends B20, ..., Xm extends B2m>(P20, ..., P2k, Named2) -> R0
  /// if:
  ///   each B0i and B1i are equal types (syntactically)
  ///   All positional parameters are required
  ///   R0 is UP(T0, T1)
  ///   B2i is B0i
  ///   P2i is DOWN(P0i, P1i)
  ///   Named0 contains R0i xi
  ///       if R1i xi is a required named parameter in Named1
  ///   Named1 contains R1i xi
  ///       if R0i xi is a required named parameter in Named0
  ///   Named2 contains exactly R2i xi
  ///       for each xi in both Named0 and Named1
  ///     where R0i xi is in Named0
  ///     where R1i xi is in Named1
  ///     and R2i is DOWN(R0i, R1i)
  ///     and R2i xi is required
  ///         if xi is required in either Named0 or Named1
  /// UP(T Function<...>(...), S Function<...>(...)) = Function otherwise
  DartType _getNullabilityAwareFunctionStandardUpperBound(
      FunctionType f, FunctionType g, bool isNonNullableByDefault) {
    bool haveNamed =
        f.namedParameters.isNotEmpty || g.namedParameters.isNotEmpty;
    bool haveOptionalPositional =
        f.requiredParameterCount < f.positionalParameters.length ||
            g.requiredParameterCount < g.positionalParameters.length;

    // The return value for whenever the following applies:
    //     UP(T Function<...>(...), S Function<...>(...)) = Function otherwise
    final DartType fallbackResult = coreTypes.functionRawType(
        uniteNullabilities(f.declaredNullability, g.declaredNullability));

    if (haveNamed && haveOptionalPositional) return fallbackResult;
    if (!haveNamed && f.requiredParameterCount != g.requiredParameterCount) {
      return fallbackResult;
    }
    // Here we perform a quick check on the function types to figure out if we
    // can compute a non-trivial upper bound for them.  The check isn't merged
    // with the computation of the non-trivial upper bound itself to avoid
    // performing unnecessary computations.
    if (haveNamed) {
      if (f.positionalParameters.length != g.positionalParameters.length) {
        return fallbackResult;
      }
      // Assuming that the named parameters are sorted lexicographically in
      // both type1 and type2.
      int i = 0;
      int j = 0;
      while (i < f.namedParameters.length && j < g.namedParameters.length) {
        NamedType named1 = f.namedParameters[i];
        NamedType named2 = g.namedParameters[j];
        int order = named1.name.compareTo(named2.name);
        if (order < 0) {
          if (named1.isRequired) return fallbackResult;
          ++i;
        } else if (order > 0) {
          if (named2.isRequired) return fallbackResult;
          ++j;
        } else {
          ++i;
          ++j;
        }
      }
      while (i < f.namedParameters.length) {
        if (f.namedParameters[i].isRequired) return fallbackResult;
        ++i;
      }
      while (j < g.namedParameters.length) {
        if (g.namedParameters[j].isRequired) return fallbackResult;
        ++j;
      }
    }

    int m = f.typeParameters.length;
    bool boundsMatch = false;
    Substitution substitution = Substitution.empty;
    if (g.typeParameters.length == m) {
      boundsMatch = true;
      if (m != 0) {
        Map<TypeParameter, DartType> substitutionMap =
            <TypeParameter, DartType>{};
        for (int i = 0; i < m; ++i) {
          substitutionMap[g.typeParameters[i]] =
              new TypeParameterType.forAlphaRenaming(
                  g.typeParameters[i], f.typeParameters[i]);
        }
        substitution = Substitution.fromMap(substitutionMap);
        for (int i = 0; i < m && boundsMatch; ++i) {
          // TODO(cstefantsova): Figure out if a procedure for syntactic
          // equality should be used instead.
          if (!areMutualSubtypes(
              f.typeParameters[i].bound,
              substitution.substituteType(g.typeParameters[i].bound),
              SubtypeCheckMode.withNullabilities)) {
            boundsMatch = false;
          }
        }
      }
    }
    if (!boundsMatch) return fallbackResult;
    int minPos =
        math.min(f.positionalParameters.length, g.positionalParameters.length);

    List<TypeParameter> typeParameters = f.typeParameters;

    List<DartType> positionalParameters =
        new List<DartType>.filled(minPos, dummyDartType);
    for (int i = 0; i < minPos; ++i) {
      positionalParameters[i] = _getNullabilityAwareStandardLowerBound(
          f.positionalParameters[i],
          substitution.substituteType(g.positionalParameters[i]),
          isNonNullableByDefault: isNonNullableByDefault);
    }

    List<NamedType> namedParameters = <NamedType>[];
    {
      // Assuming that the named parameters of both types are sorted
      // lexicographically.
      int i = 0;
      int j = 0;
      while (i < f.namedParameters.length && j < g.namedParameters.length) {
        NamedType named1 = f.namedParameters[i];
        NamedType named2 = g.namedParameters[j];
        int order = named1.name.compareTo(named2.name);
        if (order < 0) {
          ++i;
        } else if (order > 0) {
          ++j;
        } else {
          namedParameters.add(new NamedType(
              named1.name,
              _getNullabilityAwareStandardLowerBound(
                  named1.type, substitution.substituteType(named2.type),
                  isNonNullableByDefault: isNonNullableByDefault),
              isRequired: named1.isRequired || named2.isRequired));
          ++i;
          ++j;
        }
      }
    }

    DartType returnType = _getNullabilityAwareStandardUpperBound(
        f.returnType, substitution.substituteType(g.returnType),
        isNonNullableByDefault: isNonNullableByDefault);

    return new FunctionType(positionalParameters, returnType,
        uniteNullabilities(f.declaredNullability, g.declaredNullability),
        namedParameters: namedParameters,
        typeParameters: typeParameters,
        requiredParameterCount: f.requiredParameterCount);
  }

  /// Computes the nullability-aware lower bound of two record types.
  ///
  /// UP((P00, ... P0k, Named0), (P10, ... P1k, Named1)) =
  ///   (P20, ..., P2k, Named2)
  /// if:
  ///   P2i is UP(P0i, P1i)
  ///   Named0 contains R0i xi
  ///       if Named1 contains R1i xi
  ///   Named1 contains R1i xi
  ///       if Named0 contains R0i xi
  ///   Named2 contains exactly R2i xi
  ///       for each xi in both Named0 and Named1
  ///     where R0i xi is in Named0
  ///     where R1i xi is in Named1
  ///     and R2i is UP(R0i, R1i)
  /// UP(Record(...), Record(...)) = Record otherwise
  DartType _getNullabilityAwareRecordStandardUpperBound(
      RecordType r1, RecordType r2, bool isNonNullableByDefault) {
    // The return value for whenever the following applies:
    //     UP(Record(...), Record(...)) = Record otherwise
    late final DartType fallbackResult = coreTypes.recordRawType(
        uniteNullabilities(r1.declaredNullability, r2.declaredNullability));

    // Here we perform a quick check on the function types to figure out if we
    // can compute a non-trivial upper bound for them.
    if (r1.positional.length != r2.positional.length ||
        r1.named.length != r2.named.length) {
      return fallbackResult;
    }

    int positionalLength = r1.positional.length;
    int namedLength = r1.named.length;

    for (int i = 0; i < namedLength; i++) {
      // The named parameters of record types are assumed to be sorted
      // lexicographically.
      if (r1.named[i].name != r2.named[i].name) {
        return fallbackResult;
      }
    }

    List<DartType> positional = new List<DartType>.generate(
        positionalLength,
        (i) => _getNullabilityAwareStandardUpperBound(
            r1.positional[i], r2.positional[i],
            isNonNullableByDefault: isNonNullableByDefault));

    List<NamedType> named = new List<NamedType>.generate(
        namedLength,
        (i) => new NamedType(
            r1.named[i].name,
            _getNullabilityAwareStandardUpperBound(
                r1.named[i].type, r2.named[i].type,
                isNonNullableByDefault: isNonNullableByDefault)));

    return new RecordType(positional, named,
        uniteNullabilities(r1.declaredNullability, r2.declaredNullability));
  }

  DartType _getNullabilityAwareTypeParameterStandardUpperBound(
      TypeParameterType type1, DartType type2, bool isNonNullableByDefault) {
    // UP(X1 extends B1, T2) =
    //   T2 if X1 <: T2
    //   otherwise X1 if T2 <: X1
    //   otherwise UP(B1a, T2)
    //     where B1a is the greatest closure of B1 with respect to X1,
    //     as defined in [inference.md].
    if (isSubtypeOf(type1, type2, SubtypeCheckMode.withNullabilities)) {
      return type2.withDeclaredNullability(
          uniteNullabilities(type1.declaredNullability, type2.nullability));
    }
    if (isSubtypeOf(type2, type1, SubtypeCheckMode.withNullabilities)) {
      return type1.withDeclaredNullability(
          uniteNullabilities(type1.declaredNullability, type2.nullability));
    }
    NullabilityAwareTypeVariableEliminator eliminator =
        new NullabilityAwareTypeVariableEliminator(
            eliminationTargets: <TypeParameter>{type1.parameter},
            bottomType: const NeverType.nonNullable(),
            topType: coreTypes.objectNullableRawType,
            topFunctionType: coreTypes.functionNonNullableRawType,
            unhandledTypeHandler: (type, recursor) => false);
    return _getNullabilityAwareStandardUpperBound(
            eliminator.eliminateToGreatest(type1.parameter.bound), type2,
            isNonNullableByDefault: isNonNullableByDefault)
        .withDeclaredNullability(uniteNullabilities(
            type1.declaredNullability,
            uniteNullabilities(
                type1.parameter.bound.declaredNullability, type2.nullability)));
  }

  DartType _getNullabilityAwareIntersectionStandardUpperBound(
      IntersectionType type1, DartType type2, bool isNonNullableByDefault) {
    // UP(X1 & B1, T2) =
    //   T2 if X1 <: T2
    //   otherwise X1 if T2 <: X1
    //   otherwise UP(B1a, T2)
    //     where B1a is the greatest closure of B1 with respect to X1,
    //     as defined in [inference.md].
    DartType demoted = type1.left;
    if (isSubtypeOf(demoted, type2, SubtypeCheckMode.withNullabilities)) {
      return type2.withDeclaredNullability(uniteNullabilities(
          type1.declaredNullability, type2.declaredNullability));
    }
    if (isSubtypeOf(type2, demoted, SubtypeCheckMode.withNullabilities)) {
      return demoted.withDeclaredNullability(uniteNullabilities(
          demoted.declaredNullability, type2.declaredNullability));
    }
    NullabilityAwareTypeVariableEliminator eliminator =
        new NullabilityAwareTypeVariableEliminator(
            eliminationTargets: <TypeParameter>{type1.left.parameter},
            bottomType: const NeverType.nonNullable(),
            topType: coreTypes.objectNullableRawType,
            topFunctionType: coreTypes.functionNonNullableRawType,
            unhandledTypeHandler: (type, recursor) => false);
    Nullability resultingNullability =
        uniteNullabilities(type1.right.declaredNullability, type2.nullability);

    // If the resulting nullability is [Nullability.undetermined], one of the
    // types can be nullable at run time. The upper bound is supposed to be a
    // supertype to both of the types under all conditions, so we interpret the
    // undetermined case as [Nullability.nullable].
    resultingNullability = resultingNullability == Nullability.undetermined
        ? Nullability.nullable
        : resultingNullability;

    return _getNullabilityAwareStandardUpperBound(
            eliminator.eliminateToGreatest(type1.right), type2,
            isNonNullableByDefault: isNonNullableByDefault)
        .withDeclaredNullability(resultingNullability);
  }

  DartType _getNullabilityObliviousStandardUpperBound(
      DartType type1, DartType type2, bool isNonNullableByDefault) {
    /*assert(type1 == legacyErasure(coreTypes, type1),
        "Non-legacy type $type1 in inference.");
    assert(type2 == legacyErasure(coreTypes, type2),
        "Non-legacy type $type2 in inference.");*/
    // For all types T, SUB(T,T) = T.  Note that we don't test for equality
    // because we don't want to make the algorithm quadratic.  This is ok
    // because the check is not needed for correctness; it's just a speed
    // optimization.
    if (identical(type1, type2)) {
      return type1;
    }

    return getNullabilityObliviousStandardUpperBoundInternal(type1, type2,
        isNonNullableByDefault: isNonNullableByDefault);
  }

  DartType getNullabilityObliviousStandardUpperBoundInternal(
      DartType type1, DartType type2,
      {required bool isNonNullableByDefault}) {
    // SUB(void, T) = SUB(T, void) = void.
    if (type1 is VoidType) {
      return type1;
    }
    if (type2 is VoidType) {
      return type2;
    }

    // SUB(dynamic, T) = SUB(T, dynamic) = dynamic if T is not void.
    if (type1 is DynamicType) {
      return type1;
    }
    if (type2 is DynamicType) {
      return type2;
    }

    // SUB(Object, T) = SUB(T, Object) = Object if T is not void or dynamic.
    if (type1 == coreTypes.objectLegacyRawType) {
      return type1;
    }
    if (type2 == coreTypes.objectLegacyRawType) {
      return type2;
    }

    // SUB(bottom, T) = SUB(T, bottom) = T.
    if (type1 is NullType) return type2;
    if (type2 is NullType) return type1;

    if (type1 is TypeParameterType || type2 is TypeParameterType) {
      return _getNullabilityObliviousTypeParameterStandardUpperBound(
          type1, type2, isNonNullableByDefault);
    }

    // The standard upper bound of a function type and an interface type T is
    // the standard upper bound of Function and T.
    if (type1 is FunctionType &&
        (type2 is InterfaceType || type2 is FutureOrType)) {
      type1 = coreTypes.functionLegacyRawType;
    }
    if (type2 is FunctionType &&
        (type1 is InterfaceType || type2 is FutureOrType)) {
      type2 = coreTypes.functionLegacyRawType;
    }

    // At this point type1 and type2 should both either be interface types or
    // function types.
    if (type1 is InterfaceType && type2 is InterfaceType) {
      return _getInterfaceStandardUpperBound(
          type1, type2, isNonNullableByDefault);
    }

    if (type1 is FunctionType && type2 is FunctionType) {
      return _getNullabilityObliviousFunctionStandardUpperBound(
          type1, type2, isNonNullableByDefault);
    }

    // UP(FutureOr<T1>, FutureOr<T2>) = FutureOr<T3> where T3 = UP(T1, T2)
    // UP(Future<T1>, FutureOr<T2>) = FutureOr<T3> where T3 = UP(T1, T2)
    // UP(FutureOr<T1>, Future<T2>) = FutureOr<T3> where T3 = UP(T1, T2)
    // UP(T1, FutureOr<T2>) = FutureOr<T3> where T3 = UP(T1, T2)
    // UP(FutureOr<T1>, T2) = FutureOr<T3> where T3 = UP(T1, T2)
    if (type1 is FutureOrType) {
      DartType t1 = type1.typeArgument;
      DartType t2;
      if (type2 is InterfaceType && type2.classNode == coreTypes.futureClass) {
        t2 = type2.typeArguments.single;
      } else if (type2 is FutureOrType) {
        t2 = type2.typeArgument;
      } else {
        t2 = type2;
      }
      return new FutureOrType(
          getStandardUpperBound(t1, t2,
              isNonNullableByDefault: isNonNullableByDefault),
          uniteNullabilities(
              type1.declaredNullability, type2.declaredNullability));
    } else if (type2 is FutureOrType) {
      DartType t2 = type2.typeArgument;
      DartType t1;
      if (type1 is InterfaceType && type1.classNode == coreTypes.futureClass) {
        t1 = type1.typeArguments.single;
      } else {
        t1 = type1;
      }
      return new FutureOrType(
          getStandardUpperBound(t1, t2,
              isNonNullableByDefault: isNonNullableByDefault),
          uniteNullabilities(
              type1.declaredNullability, type2.declaredNullability));
    }

    if (type1 is InvalidType || type2 is InvalidType) {
      return const InvalidType();
    }

    // Should never happen. As a defensive measure, return the dynamic type.
    assert(false, "type1 = $type1; type2 = $type2");
    return const DynamicType();
  }

  /// Compute the standard lower bound of function types [f] and [g].
  ///
  /// The spec rules for SLB on function types, informally, are pretty simple:
  ///
  /// - If a parameter is required in both, it stays required.
  ///
  /// - If a positional parameter is optional or missing in one, it becomes
  ///   optional.  (This is because we're trying to build a function type which
  ///   is a subtype of both [f] and [g], meaning it accepts all possible inputs
  ///   that [f] and [g] accept.)
  ///
  /// - Named parameters are unioned together.
  ///
  /// - For any parameter that exists in both functions, use the SUB of them as
  ///   the resulting parameter type.
  ///
  /// - Use the SLB of their return types.
  DartType _getNullabilityObliviousFunctionStandardLowerBound(
      FunctionType f, FunctionType g,
      {required bool isNonNullableByDefault}) {
    // TODO(rnystrom,paulberry): Right now, this assumes f and g do not have any
    // type parameters. Revisit that in the presence of generic methods.

    // Calculate the SUB of each corresponding pair of parameters.
    int totalPositional =
        math.max(f.positionalParameters.length, g.positionalParameters.length);
    List<DartType> positionalParameters =
        new List<DartType>.filled(totalPositional, dummyDartType);
    for (int i = 0; i < totalPositional; i++) {
      if (i < f.positionalParameters.length) {
        DartType fType = f.positionalParameters[i];
        if (i < g.positionalParameters.length) {
          DartType gType = g.positionalParameters[i];
          positionalParameters[i] = getStandardUpperBound(fType, gType,
              isNonNullableByDefault: isNonNullableByDefault);
        } else {
          positionalParameters[i] = fType;
        }
      } else {
        positionalParameters[i] = g.positionalParameters[i];
      }
    }

    // Parameters that are required in both functions are required in the
    // result.  Parameters that are optional or missing in either end up
    // optional.
    int requiredParameterCount =
        math.min(f.requiredParameterCount, g.requiredParameterCount);
    bool hasPositional = requiredParameterCount < totalPositional;

    // Union the named parameters together.
    List<NamedType> namedParameters = [];
    {
      int i = 0;
      int j = 0;
      while (true) {
        if (i < f.namedParameters.length) {
          if (j < g.namedParameters.length) {
            String fName = f.namedParameters[i].name;
            String gName = g.namedParameters[j].name;
            int order = fName.compareTo(gName);
            if (order < 0) {
              namedParameters.add(f.namedParameters[i++]);
            } else if (order > 0) {
              namedParameters.add(g.namedParameters[j++]);
            } else {
              namedParameters.add(new NamedType(
                  fName,
                  getStandardUpperBound(
                      f.namedParameters[i++].type, g.namedParameters[j++].type,
                      isNonNullableByDefault: isNonNullableByDefault)));
            }
          } else {
            namedParameters.addAll(f.namedParameters.skip(i));
            break;
          }
        } else {
          namedParameters.addAll(g.namedParameters.skip(j));
          break;
        }
      }
    }
    bool hasNamed = namedParameters.isNotEmpty;

    // Edge case. Dart does not support functions with both optional positional
    // and named parameters. If we would synthesize that, give up.
    if (hasPositional && hasNamed) {
      if (isNonNullableByDefault) {
        return const NeverType.nonNullable();
      } else {
        return const NeverType.legacy();
      }
    }

    // Calculate the SLB of the return type.
    DartType returnType = getStandardLowerBound(f.returnType, g.returnType,
        isNonNullableByDefault: isNonNullableByDefault);
    return new FunctionType(positionalParameters, returnType,
        intersectNullabilities(f.declaredNullability, g.declaredNullability),
        namedParameters: namedParameters,
        requiredParameterCount: requiredParameterCount);
  }

  /// Compute the standard upper bound of function types [f] and [g].
  ///
  /// The rules for SUB on function types, informally, are pretty simple:
  ///
  /// - If the functions don't have the same number of required parameters,
  ///   always return `Function`.
  ///
  /// - Discard any optional named or positional parameters the two types do not
  ///   have in common.
  ///
  /// - Compute the SLB of each corresponding pair of parameter types, and the
  ///   SUB of the return types.  Return a function type with those types.
  DartType _getNullabilityObliviousFunctionStandardUpperBound(
      FunctionType f, FunctionType g, bool isNonNullableByDefault) {
    // TODO(rnystrom): Right now, this assumes f and g do not have any type
    // parameters. Revisit that in the presence of generic methods.

    // If F and G differ in their number of required parameters, then the
    // standard upper bound of F and G is Function.
    // TODO(paulberry): We could do better here, e.g.:
    //   SUB(([int]) -> void, (int) -> void) = (int) -> void
    if (f.requiredParameterCount != g.requiredParameterCount) {
      return new InterfaceType(
          coreTypes.functionClass,
          uniteNullabilities(f.declaredNullability, g.declaredNullability),
          const <DynamicType>[]);
    }
    int requiredParameterCount = f.requiredParameterCount;

    // Calculate the SLB of each corresponding pair of parameters.
    // Ignore any extra optional positional parameters if one has more than the
    // other.
    int totalPositional =
        math.min(f.positionalParameters.length, g.positionalParameters.length);
    List<DartType> positionalParameters =
        new List<DartType>.filled(totalPositional, dummyDartType);
    for (int i = 0; i < totalPositional; i++) {
      positionalParameters[i] = getStandardLowerBound(
          f.positionalParameters[i], g.positionalParameters[i],
          isNonNullableByDefault: isNonNullableByDefault);
    }

    // Intersect the named parameters.
    List<NamedType> namedParameters = [];
    {
      int i = 0;
      int j = 0;
      while (true) {
        if (i < f.namedParameters.length) {
          if (j < g.namedParameters.length) {
            String fName = f.namedParameters[i].name;
            String gName = g.namedParameters[j].name;
            int order = fName.compareTo(gName);
            if (order < 0) {
              i++;
            } else if (order > 0) {
              j++;
            } else {
              namedParameters.add(new NamedType(
                  fName,
                  getStandardLowerBound(
                      f.namedParameters[i++].type, g.namedParameters[j++].type,
                      isNonNullableByDefault: isNonNullableByDefault)));
            }
          } else {
            break;
          }
        } else {
          break;
        }
      }
    }

    // Calculate the SUB of the return type.
    DartType returnType = getStandardUpperBound(f.returnType, g.returnType,
        isNonNullableByDefault: isNonNullableByDefault);
    return new FunctionType(positionalParameters, returnType,
        uniteNullabilities(f.declaredNullability, g.declaredNullability),
        namedParameters: namedParameters,
        requiredParameterCount: requiredParameterCount);
  }

  DartType _getInterfaceStandardUpperBound(
      InterfaceType type1, InterfaceType type2, bool isNonNullableByDefault) {
    // This currently does not implement a very complete standard upper bound
    // algorithm, but handles a couple of the very common cases that are
    // causing pain in real code.  The current algorithm is:
    // 1. If either of the types is a supertype of the other, return it.
    //    This is in fact the best result in this case.
    // 2. If the two types have the same class element and is implicitly or
    //    explicitly covariant, then take the pointwise standard upper bound of
    //    the type arguments. This is again the best result, except that the
    //    recursive calls may not return the true standard upper bounds.  The
    //    result is guaranteed to be a well-formed type under the assumption
    //    that the input types were well-formed (and assuming that the
    //    recursive calls return well-formed types).
    //    If the variance of the type parameter is contravariant, we take the
    //    standard lower bound of the type arguments. If the variance of the
    //    type parameter is invariant, we verify if the type arguments satisfy
    //    subtyping in both directions, then choose a bound.
    // 3. Otherwise return the spec-defined standard upper bound.  This will
    //    be an upper bound, might (or might not) be least, and might
    //    (or might not) be a well-formed type.
    if (isSubtypeOf(type1, type2, SubtypeCheckMode.withNullabilities)) {
      return type2;
    }
    if (isSubtypeOf(type2, type1, SubtypeCheckMode.withNullabilities)) {
      return type1;
    }
    if (identical(type1.classNode, type2.classNode)) {
      List<DartType> tArgs1 = type1.typeArguments;
      List<DartType> tArgs2 = type2.typeArguments;
      List<TypeParameter> tParams = type1.classNode.typeParameters;

      assert(tArgs1.length == tArgs2.length);
      assert(tArgs1.length == tParams.length);
      List<DartType> tArgs = new List.filled(tArgs1.length, dummyDartType);
      for (int i = 0; i < tArgs1.length; i++) {
        if (tParams[i].variance == Variance.contravariant) {
          tArgs[i] = getStandardLowerBound(tArgs1[i], tArgs2[i],
              isNonNullableByDefault: isNonNullableByDefault);
        } else if (tParams[i].variance == Variance.invariant) {
          if (!areMutualSubtypes(
              tArgs1[i], tArgs2[i], SubtypeCheckMode.withNullabilities)) {
            // No bound will be valid, find bound at the interface level.
            return hierarchy.getLegacyLeastUpperBound(type1, type2,
                isNonNullableByDefault: isNonNullableByDefault);
          }
          // TODO (kallentu) : Fix asymmetric bounds behavior for invariant type
          //  parameters.
          tArgs[i] = tArgs1[i];
        } else {
          tArgs[i] = getStandardUpperBound(tArgs1[i], tArgs2[i],
              isNonNullableByDefault: isNonNullableByDefault);
        }
      }
      return new InterfaceType(
          type1.classNode,
          uniteNullabilities(
              type1.declaredNullability, type2.declaredNullability),
          tArgs);
    }
    return hierarchy.getLegacyLeastUpperBound(type1, type2,
        isNonNullableByDefault: isNonNullableByDefault);
  }

  DartType _getNullabilityObliviousTypeParameterStandardUpperBound(
      DartType type1, DartType type2, bool isNonNullableByDefault) {
    // This currently just implements a simple standard upper bound to
    // handle some common cases.  It also avoids some termination issues
    // with the naive spec algorithm.  The standard upper bound of two types
    // (at least one of which is a type parameter) is computed here as:
    // 1. If either type is a supertype of the other, return it.
    // 2. If the first type is a type parameter, replace it with its bound,
    //    with recursive occurrences of itself replaced with Object.
    //    The second part of this should ensure termination.  Informally,
    //    each type variable instantiation in one of the arguments to the
    //    standard upper bound algorithm now strictly reduces the number
    //    of bound variables in scope in that argument position.
    // 3. If the second type is a type parameter, do the symmetric operation
    //    to #2.
    //
    // It's not immediately obvious why this is symmetric in the case that both
    // of them are type parameters.  For #1, symmetry holds since subtype
    // is antisymmetric.  For #2, it's clearly not symmetric if upper bounds of
    // bottom are allowed.  Ignoring this (for various reasons, not least
    // of which that there's no way to write it), there's an informal
    // argument (that might even be right) that you will always either
    // end up expanding both of them or else returning the same result no matter
    // which order you expand them in.  A key observation is that
    // identical(expand(type1), type2) => subtype(type1, type2)
    // and hence the contra-positive.
    //
    // TODO(leafp): Think this through and figure out what's the right
    // definition.  Be careful about termination.
    //
    // I suspect in general a reasonable algorithm is to expand the innermost
    // type variable first.  Alternatively, you could probably choose to treat
    // it as just an instance of the interface type upper bound problem, with
    // the "inheritance" chain extended by the bounds placed on the variables.
    if (isSubtypeOf(type1, type2, SubtypeCheckMode.ignoringNullabilities)) {
      return type2;
    }
    if (isSubtypeOf(type2, type1, SubtypeCheckMode.ignoringNullabilities)) {
      return type1;
    }
    if (type1 is TypeParameterType) {
      // TODO(paulberry): Analyzer collapses simple bounds in one step, i.e. for
      // C<T extends U, U extends List>, T gets resolved directly to List.  Do
      // we need to replicate that behavior?
      return getStandardUpperBound(
          Substitution.fromMap({type1.parameter: coreTypes.objectLegacyRawType})
              .substituteType(type1.parameter.bound),
          type2,
          isNonNullableByDefault: isNonNullableByDefault);
    } else if (type2 is TypeParameterType) {
      return getStandardUpperBound(
          type1,
          Substitution.fromMap({type2.parameter: coreTypes.objectLegacyRawType})
              .substituteType(type2.parameter.bound),
          isNonNullableByDefault: isNonNullableByDefault);
    } else {
      // We should only be called when at least one of the types is a
      // TypeParameterType
      assert(false);
      return const DynamicType();
    }
  }
}
