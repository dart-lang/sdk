// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../ast.dart';
import '../class_hierarchy.dart';
import '../core_types.dart';
import '../type_algebra.dart';
import 'non_null.dart';

mixin StandardBounds {
  ClassHierarchyBase get hierarchy;

  bool isSubtypeOf(DartType subtype, DartType supertype);

  bool areMutualSubtypes(DartType s, DartType t);

  CoreTypes get coreTypes => hierarchy.coreTypes;

  /// Checks the value of the MORETOP predicate for [s] and [t].
  ///
  /// For the definition of MORETOP see the following:
  /// https://github.com/dart-lang/language/blob/master/resources/type-system/upper-lower-bounds.md#helper-predicates
  bool moretop(DartType s, DartType t) {
    assert(coreTypes.isTop(s) || coreTypes.isObject(s));
    assert(coreTypes.isTop(t) || coreTypes.isObject(t));

    switch ((s, t)) {
      // MORETOP(void, T) = true.
      case (VoidType(), _):
        return true;

      // MORETOP(S, void) = false.
      case (_, VoidType()):
        return false;

      // MORETOP(dynamic, T) = true.
      case (DynamicType(), _):
        return true;

      // MORETOP(S, dynamic) = false.
      case (_, DynamicType()):
        return false;

      // MORETOP(Object, T) = true.
      case (
            InterfaceType(
              classNode: Class sClassNode,
              declaredNullability: Nullability.nonNullable
            ),
            _
          )
          when sClassNode == coreTypes.objectClass:
        return true;

      // MORETOP(S, Object) = false.
      case (
            _,
            InterfaceType(
              classNode: Class tClassNode,
              declaredNullability: Nullability.nonNullable
            )
          )
          when tClassNode == coreTypes.objectClass:
        return false;

      // MORETOP(S?, T?) == MORETOP(S, T).
      case (
          DartType(declaredNullability: Nullability.nullable),
          DartType(declaredNullability: Nullability.nullable)
        ):
        DartType nonNullableS =
            s.withDeclaredNullability(Nullability.nonNullable);
        assert(!identical(s, nonNullableS));
        DartType nonNullableT =
            t.withDeclaredNullability(Nullability.nonNullable);
        assert(!identical(t, nonNullableT));
        return moretop(nonNullableS, nonNullableT);

      // MORETOP(S, T?) = true.
      case (
          DartType(declaredNullability: Nullability.nonNullable),
          DartType(declaredNullability: Nullability.nullable)
        ):
        return true;

      // MORETOP(S?, T) = false.
      case (
          DartType(declaredNullability: Nullability.nullable),
          DartType(declaredNullability: Nullability.nonNullable)
        ):
        return false;

      // MORETOP(FutureOr<S>, FutureOr<T>) = MORETOP(S, T).
      case (
          FutureOrType(
            typeArgument: DartType sTypeArgument,
            declaredNullability: Nullability.nonNullable
          ),
          FutureOrType(
            typeArgument: DartType tTypeArgument,
            declaredNullability: Nullability.nonNullable
          )
        ):
        return moretop(sTypeArgument, tTypeArgument);

      case (InterfaceType(), _):
      case (_, InterfaceType()):
      case (ExtensionType(), _):
      case (_, ExtensionType()):
      case (FunctionType(), _):
      case (_, FunctionType()):
      case (RecordType(), _):
      case (_, RecordType()):
      case (NeverType(), _):
      case (_, NeverType()):
      case (NullType(), _):
      case (_, NullType()):
      case (FutureOrType(), _):
      case (_, FutureOrType()):
      case (TypeParameterType(), _):
      case (_, TypeParameterType()):
      case (StructuralParameterType(), _):
      case (_, StructuralParameterType()):
      case (IntersectionType(), _):
      case (_, IntersectionType()):
      case (TypedefType(), _):
      case (_, TypedefType()):
      case (InvalidType(), _):
      case (_, InvalidType()):
      case (AuxiliaryType(), _):
      case (FunctionTypeParameterType(), _):
      case (ClassTypeParameterType(), _):
        throw new UnsupportedError("moretop($s, $t)");
    }
  }

  /// Checks the value of the MOREBOTTOM predicate for [s] and [t].
  ///
  /// For the definition of MOREBOTTOM see the following:
  /// https://github.com/dart-lang/language/blob/master/resources/type-system/upper-lower-bounds.md#helper-predicates
  bool morebottom(DartType s, DartType t) {
    assert(coreTypes.isBottom(s) || coreTypes.isNull(s));
    assert(coreTypes.isBottom(t) || coreTypes.isNull(t));

    switch ((s, t)) {
      // MOREBOTTOM(Never, T) = true.
      case (NeverType(declaredNullability: Nullability.nonNullable), _):
        return true;

      // MOREBOTTOM(S, Never) = false.
      case (_, NeverType(declaredNullability: Nullability.nonNullable)):
        return false;

      // MOREBOTTOM(Null, T) = true.
      case (NullType(), _):
        return true;

      // MOREBOTTOM(S, Null) = false.
      case (_, NullType()):
        return false;

      // MOREBOTTOM(S?, T?) = MOREBOTTOM(S, T).
      case (
          DartType(declaredNullability: Nullability.nullable),
          DartType(declaredNullability: Nullability.nullable)
        ):
        DartType nonNullableS =
            s.withDeclaredNullability(Nullability.nonNullable);
        assert(s != nonNullableS);
        DartType nonNullableT =
            t.withDeclaredNullability(Nullability.nonNullable);
        assert(t != nonNullableT);
        return morebottom(nonNullableS, nonNullableT);

      // MOREBOTTOM(S, T?) = true.
      case (
          DartType(declaredNullability: Nullability.nonNullable),
          DartType(declaredNullability: Nullability.nullable)
        ):
        return true;

      // MOREBOTTOM(S?, T) = false.
      case (
          DartType(declaredNullability: Nullability.nullable),
          DartType(declaredNullability: Nullability.nonNullable)
        ):
        return false;

      // MOREBOTTOM(X&S, Y&T) = MOREBOTTOM(S, T).
      case (
          IntersectionType(right: DartType sRight),
          IntersectionType(right: DartType tRight)
        ):
        return morebottom(sRight, tRight);

      // MOREBOTTOM(X&S, T) = true.
      case (IntersectionType(), _):
        return true;

      // MOREBOTTOM(S, X&T) = false.
      case (_, IntersectionType()):
        return false;

      // MOREBOTTOM(X extends S, Y extends T) = MOREBOTTOM(S, T).
      case (
          TypeParameterType(parameter: TypeParameter sParameter),
          TypeParameterType(parameter: TypeParameter tParameter)
        ):
        return morebottom(sParameter.bound, tParameter.bound);

      case (DynamicType(), _):
      case (_, DynamicType()):
      case (VoidType(), _):
      case (_, VoidType()):
      case (NeverType(), _):
      case (_, NeverType()):
      case (FunctionType(), _):
      case (_, FunctionType()):
      case (TypedefType(), _):
      case (_, TypedefType()):
      case (FutureOrType(), _):
      case (_, FutureOrType()):
      case (TypeParameterType(), _):
      case (_, TypeParameterType()):
      case (StructuralParameterType(), _):
      case (_, StructuralParameterType()):
      case (RecordType(), _):
      case (_, RecordType()):
      case (InterfaceType(), _):
      case (_, InterfaceType()):
      case (ExtensionType(), _):
      case (_, ExtensionType()):
      case (InvalidType(), _):
      case (_, InvalidType()):
      case (AuxiliaryType(), _):
      case (FunctionTypeParameterType(), _):
      case (ClassTypeParameterType(), _):
        throw new UnsupportedError("morebottom($s, $t)");
    }
  }

  /// Computes the standard lower bound of [type1] and [type2].
  ///
  /// Standard lower bound is a lower bound function that imposes an
  /// ordering on the top types `void`, `dynamic`, and `object`.  This function
  /// additionally handles the unknown type that appears during type inference.
  DartType getStandardLowerBound(DartType type1, DartType type2) {
    if (type1 is InvalidType || type2 is InvalidType) {
      return const InvalidType();
    }
    return _getStandardLowerBound(type1, type2);
  }

  DartType _getStandardLowerBound(DartType type1, DartType type2) {
    // DOWN(T, T) = T.
    if (type1 == type2) return type1;

    return getStandardLowerBoundInternal(type1, type2);
  }

  DartType getStandardLowerBoundInternal(DartType type1, DartType type2) {
    DartType type1WithoutNullabilityMarker =
        computeTypeWithoutNullabilityMarker(type1);
    DartType type2WithoutNullabilityMarker =
        computeTypeWithoutNullabilityMarker(type2);
    bool isType1WithoutNullabilityMarker =
        isTypeWithoutNullabilityMarker(type1);
    bool isType2WithoutNullabilityMarker =
        isTypeWithoutNullabilityMarker(type2);

    switch ((type1, type2)) {
      case (InvalidType(), _):
      case (_, InvalidType()):
        return const InvalidType();

      case (TypedefType typedefType1, _):
        return getStandardLowerBoundInternal(typedefType1.unalias, type2);
      case (_, TypedefType typedefType2):
        return getStandardLowerBoundInternal(type1, typedefType2.unalias);

      // DOWN(T1, T2) where TOP(T1) and TOP(T2) =
      //   T1 if MORETOP(T2, T1)
      //   T2 otherwise
      // DOWN(T1, T2) = T2 if TOP(T1)
      // DOWN(T1, T2) = T1 if TOP(T2)
      case (DynamicType(), DynamicType()):
      case (DynamicType(), VoidType()):
      case (VoidType(), DynamicType()):
      case (VoidType(), VoidType()):
      case (_, _) when coreTypes.isTop(type1) && coreTypes.isTop(type2):
        return moretop(type2, type1) ? type1 : type2;
      case (DynamicType(), _):
      case (VoidType(), _):
      case (_, _) when coreTypes.isTop(type1):
        return type2;
      case (_, DynamicType()):
      case (_, VoidType()):
      case (_, _) when coreTypes.isTop(type2):
        return type1;

      // DOWN(T1, T2) where BOTTOM(T1) and BOTTOM(T2) =
      //   T1 if MOREBOTTOM(T1, T2)
      //   T2 otherwise
      // DOWN(T1, T2) = T2 if BOTTOM(T2)
      // DOWN(T1, T2) = T1 if BOTTOM(T1)
      case (
          NeverType(nullability: Nullability.nonNullable),
          NeverType(nullability: Nullability.nonNullable)
        ):
      case (_, _) when coreTypes.isBottom(type1) && coreTypes.isBottom(type2):
        return morebottom(type1, type2) ? type1 : type2;
      case (NeverType(nullability: Nullability.nonNullable), _):
      case (_, _) when coreTypes.isBottom(type1):
        return type1;
      case (_, NeverType(nullability: Nullability.nonNullable)):
      case (_, _) when coreTypes.isBottom(type2):
        return type2;

      // DOWN(T1, T2) where NULL(T1) and NULL(T2) =
      //   T1 if MOREBOTTOM(T1, T2)
      //   T2 otherwise
      // DOWN(Null, T2) =
      //   Null if Null <: T2
      //   Never otherwise
      // DOWN(T1, Null) =
      //  Null if Null <: T1
      //  Never otherwise
      case (NullType(), NullType()):
      case (
          NeverType(nullability: Nullability.nullable),
          NeverType(nullability: Nullability.nullable)
        ):
      case (_, _) when coreTypes.isNull(type1) && coreTypes.isNull(type2):
        return morebottom(type1, type2) ? type1 : type2;
      case (NullType(), DartType(declaredNullability: Nullability.nullable)):
      case (
          NeverType(nullability: Nullability.nullable),
          DartType(declaredNullability: Nullability.nullable)
        ):
      case (_, DartType(declaredNullability: Nullability.nullable))
          when coreTypes.isNull(type1):
        return type1;
      case (NullType(), _):
      case (NeverType(nullability: Nullability.nullable), _):
      case (_, _) when coreTypes.isNull(type1):
        return const NeverType.nonNullable();
      case (DartType(declaredNullability: Nullability.nullable), NullType()):
      case (
          DartType(declaredNullability: Nullability.nullable),
          NeverType(nullability: Nullability.nullable)
        ):
      case (DartType(declaredNullability: Nullability.nullable), _)
          when coreTypes.isNull(type2):
        return type2;
      case (_, NullType()):
      case (_, NeverType(nullability: Nullability.nullable)):
      case (_, _) when coreTypes.isNull(type2):
        return const NeverType.nonNullable();

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
      case (_, _) when coreTypes.isObject(type1) && coreTypes.isObject(type2):
        return moretop(type2, type1) ? type1 : type2;
      case (_, DartType(nullability: Nullability.nonNullable))
          when coreTypes.isObject(type1):
        return type2;
      case (_, _) when coreTypes.isObject(type1):
        if (computeNonNull(type2) case DartType nonNullType2
            when nonNullType2.nullability == Nullability.nonNullable) {
          return nonNullType2;
        } else {
          return const NeverType.nonNullable();
        }
      case (DartType(nullability: Nullability.nonNullable), _)
          when coreTypes.isObject(type2):
        return type1;
      case (_, _) when coreTypes.isObject(type2):
        if (computeNonNull(type1) case DartType nonNullType1
            when nonNullType1.nullability == Nullability.nonNullable) {
          return nonNullType1;
        } else {
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
      case (_, _)
          when isType1WithoutNullabilityMarker &&
              !isType2WithoutNullabilityMarker:
        return _getStandardLowerBound(type1, type2WithoutNullabilityMarker);
      case (_, _)
          when !isType1WithoutNullabilityMarker &&
              isType2WithoutNullabilityMarker:
        return _getStandardLowerBound(type1WithoutNullabilityMarker, type2);
      case (_, _)
          when isNullableTypeConstructorApplication(type1) &&
              isNullableTypeConstructorApplication(type2):
        return _getStandardLowerBound(
                type1WithoutNullabilityMarker, type2WithoutNullabilityMarker)
            .withDeclaredNullability(Nullability.nullable);

      case (FunctionType functionType1, FunctionType functionType2):
        return _getFunctionStandardLowerBound(functionType1, functionType2);

      case (RecordType recordType1, RecordType recordType2):
        return _getRecordStandardLowerBound(recordType1, recordType2);

      // DOWN(T1, T2) = T1 if T1 <: T2.
      // DOWN(T1, T2) = T2 if T2 <: T1.
      //
      // We use the non-nullable variants of the two types to determine T1 <:
      // T2 without using the nullability of the outermost type. The result
      // uses [intersectNullabilities] to compute the resulting type if the
      // subtype relation is established.
      case (_, _)
          when isSubtypeOf(
              greatestClosureForLowerBound(type1WithoutNullabilityMarker),
              greatestClosureForLowerBound(type2WithoutNullabilityMarker)):
        return type1.withDeclaredNullability(intersectNullabilities(
            type1.declaredNullability, type2.declaredNullability));
      case (_, _)
          when isSubtypeOf(
              greatestClosureForLowerBound(type2WithoutNullabilityMarker),
              greatestClosureForLowerBound(type1WithoutNullabilityMarker)):
        return type2.withDeclaredNullability(intersectNullabilities(
            type2.declaredNullability, type1.declaredNullability));

      // See
      // https://github.com/dart-lang/sdk/issues/37439#issuecomment-519654959.
      //
      // GLB(FutureOr<A>, FutureOr<B>) == FutureOr<GLB(A, B)>
      case (
          FutureOrType(typeArgument: DartType t1),
          FutureOrType(typeArgument: DartType t2)
        ):
        DartType argument = getStandardLowerBound(t1, t2);
        return new FutureOrType(argument, argument.declaredNullability);
      // GLB(FutureOr<A>, Future<B>) == Future<GLB(A, B)>
      case (
            FutureOrType(typeArgument: DartType t1),
            InterfaceType(
              classNode: Class classNode2,
              typeArguments: [DartType t2]
            )
          )
          when classNode2 == coreTypes.futureClass:
        return new InterfaceType(
            coreTypes.futureClass,
            intersectNullabilities(
                type1.declaredNullability, type2.declaredNullability),
            <DartType>[getStandardLowerBound(t1, t2)]);
      // GLB(FutureOr<A>, B) == GLB(A, B)
      case (FutureOrType(typeArgument: DartType t1), DartType t2):
        return getStandardLowerBound(t1, t2);

      // The if-statement below handles the following rule:
      //     GLB(A, FutureOr<B>) ==  GLB(FutureOr<B>, A)
      // It's broken down into sub-cases instead of making a recursive call
      // to avoid making the checks that were already made above.  Note that
      // at this point it's not possible for type1 to be a FutureOr.
      //
      // GLB(Future<A>, FutureOr<B>) == Future<GLB(B, A)>
      case (
            InterfaceType(
              classNode: Class classNode1,
              typeArguments: [DartType t1]
            ),
            FutureOrType(typeArgument: DartType t2)
          )
          when classNode1 == coreTypes.futureClass:
        return new InterfaceType(
            coreTypes.futureClass,
            intersectNullabilities(
                type1.declaredNullability, type2.declaredNullability),
            <DartType>[getStandardLowerBound(t2, t1)]);
      // GLB(A, FutureOr<B>) == GLB(B, A)
      case (DartType t1, FutureOrType(typeArgument: DartType t2)):
        return getStandardLowerBound(t2, t1);

      // DOWN(T1, T2) = Never otherwise.
      case (InterfaceType(), _):
      case (_, InterfaceType()):
      case (RecordType(), _):
      case (_, RecordType()):
      case (ExtensionType(), _):
      case (_, ExtensionType()):
      case (TypeParameterType(), _):
      case (_, TypeParameterType()):
      case (StructuralParameterType(), _):
      case (_, StructuralParameterType()):
      case (IntersectionType(), _):
      case (_, IntersectionType()):
        return NeverType.fromNullability(combineNullabilitiesForSubstitution(
            inner: Nullability.nonNullable,
            outer: intersectNullabilities(
                type1.declaredNullability, type2.declaredNullability)));

      case (NeverType(nullability: Nullability.undetermined), _):
      case (_, NeverType(nullability: Nullability.undetermined)):
        throw new StateError("Unsupported nullability for NeverType: "
            "'${Nullability.undetermined}'.");

      case (AuxiliaryType(), _):
      case (_, AuxiliaryType()):
        throw new StateError("Unsupported type combination: "
            "getStandardUpperBoundInternal("
            "${type1.runtimeType}, ${type2.runtimeType}"
            ")");

      case (FunctionTypeParameterType(), _):
      case (_, FunctionTypeParameterType()):
        throw new StateError("Unimplemented for type combination: "
            "getStandardUpperBoundInternal("
            "${type1.runtimeType}, ${type2.runtimeType}"
            ")");

      case (ClassTypeParameterType(), _):
      case (_, ClassTypeParameterType()):
        throw new StateError("Unimplemented for type combination: "
            "getStandardUpperBoundInternal("
            "${type1.runtimeType}, ${type2.runtimeType}"
            ")");
    }
  }

  /// Computes the standard upper bound of two types.
  ///
  /// Standard upper bound is an upper bound function that imposes an ordering
  /// on the top types 'void', 'dynamic', and `object`.  This function
  /// additionally handles the unknown type that appears during type inference.
  DartType getStandardUpperBound(DartType type1, DartType type2) {
    if (type1 is InvalidType || type2 is InvalidType) {
      return const InvalidType();
    }
    return _getStandardUpperBound(type1, type2);
  }

  DartType _getStandardUpperBound(DartType type1, DartType type2) {
    // UP(T, T) = T
    if (type1 == type2) return type1;

    return getStandardUpperBoundInternal(type1, type2);
  }

  DartType getStandardUpperBoundInternal(DartType type1, DartType type2) {
    DartType typeWithoutNullabilityMarker1 =
        computeTypeWithoutNullabilityMarker(type1);
    DartType typeWithoutNullabilityMarker2 =
        computeTypeWithoutNullabilityMarker(type2);

    switch ((type1, type2)) {
      case (InvalidType(), _):
      case (_, InvalidType()):
        return const InvalidType();

      case (TypedefType typedefType1, _):
        return getStandardUpperBoundInternal(typedefType1.unalias, type2);
      case (_, TypedefType typedefType2):
        return getStandardUpperBoundInternal(type1, typedefType2.unalias);

      // UP(T1, T2) where TOP(T1) and TOP(T2) =
      //   T1 if MORETOP(T1, T2)
      //   T2 otherwise
      // UP(T1, T2) = T1 if TOP(T1)
      // UP(T1, T2) = T2 if TOP(T2)
      case (DynamicType(), DynamicType()):
      case (DynamicType(), VoidType()):
      case (VoidType(), DynamicType()):
      case (VoidType(), VoidType()):
      case (_, _) when coreTypes.isTop(type1) && coreTypes.isTop(type2):
        return moretop(type1, type2) ? type1 : type2;
      case (DynamicType(), _):
      case (VoidType(), _):
      case (_, _) when coreTypes.isTop(type1):
        return type1;
      case (_, DynamicType()):
      case (_, VoidType()):
      case (_, _) when coreTypes.isTop(type2):
        return type2;

      // UP(T1, T2) where BOTTOM(T1) and BOTTOM(T2) =
      //   T2 if MOREBOTTOM(T1, T2)
      //   T1 otherwise
      // UP(T1, T2) = T2 if BOTTOM(T1)
      // UP(T1, T2) = T1 if BOTTOM(T2)
      case (
          NeverType(nullability: Nullability.nonNullable),
          NeverType(nullability: Nullability.nonNullable)
        ):
      case (_, _) when coreTypes.isBottom(type1) && coreTypes.isBottom(type2):
        return morebottom(type1, type2) ? type2 : type1;
      case (NeverType(nullability: Nullability.nonNullable), _):
      case (_, _) when coreTypes.isBottom(type1):
        return type2;
      case (_, NeverType(nullability: Nullability.nonNullable)):
      case (_, _) when coreTypes.isBottom(type2):
        return type1;

      case (IntersectionType intersectionType1, _):
        return _getIntersectionStandardUpperBound(intersectionType1, type2);
      case (_, IntersectionType intersectionType2):
        return _getIntersectionStandardUpperBound(intersectionType2, type1);

      // UP(T1, T2) where NULL(T1) and NULL(T2) =
      //   T2 if MOREBOTTOM(T1, T2)
      //   T1 otherwise
      // UP(T1, T2) where NULL(T1) =
      //   T2 if T2 is nullable
      //   T2? otherwise
      // UP(T1, T2) where NULL(T2) =
      //   T1 if T1 is nullable
      //   T1? otherwise
      case (NullType(), NullType()):
      case (
          NeverType(nullability: Nullability.nullable),
          NeverType(nullability: Nullability.nullable)
        ):
      case (_, _) when coreTypes.isNull(type1) && coreTypes.isNull(type2):
        return morebottom(type1, type2) ? type2 : type1;
      case (NullType(), _):
      case (NeverType(nullability: Nullability.nullable), _):
      case (_, _) when coreTypes.isNull(type1):
        return type2.withDeclaredNullability(Nullability.nullable);
      case (_, NullType()):
      case (_, NeverType(nullability: Nullability.nullable)):
      case (_, _) when coreTypes.isNull(type2):
        return type1.withDeclaredNullability(Nullability.nullable);

      // UP(T1, T2) where OBJECT(T1) and OBJECT(T2) =
      //   T1 if MORETOP(T1, T2)
      //   T2 otherwise
      // UP(T1, T2) where OBJECT(T1) =
      //   T1 if T2 is non-nullable
      //   T1? otherwise
      // UP(T1, T2) where OBJECT(T2) =
      //   T2 if T1 is non-nullable
      //   T2? otherwise
      case (_, _) when coreTypes.isObject(type1) && coreTypes.isObject(type2):
        return moretop(type1, type2) ? type1 : type2;
      case (_, _)
          when coreTypes.isObject(type1) &&
              type2.nullability == Nullability.nonNullable:
        return type1;
      case (_, _) when coreTypes.isObject(type1):
        return type1.withDeclaredNullability(Nullability.nullable);
      case (_, _)
          when coreTypes.isObject(type2) &&
              type1.nullability == Nullability.nonNullable:
        return type2;
      case (_, _) when coreTypes.isObject(type2):
        return type2.withDeclaredNullability(Nullability.nullable);

      // UP(T1*, T2*) = S* where S is UP(T1, T2)
      // UP(T1*, T2?) = S? where S is UP(T1, T2)
      // UP(T1?, T2*) = S? where S is UP(T1, T2)
      // UP(T1*, T2) = S* where S is UP(T1, T2)
      // UP(T1, T2*) = S* where S is UP(T1, T2)
      // UP(T1?, T2?) = S? where S is UP(T1, T2)
      // UP(T1?, T2) = S? where S is UP(T1, T2)
      // UP(T1, T2?) = S? where S is UP(T1, T2)
      case (_, _) when isNullableTypeConstructorApplication(type1):
      case (_, _) when isNullableTypeConstructorApplication(type2):
        return _getStandardUpperBound(
                computeTypeWithoutNullabilityMarker(type1),
                computeTypeWithoutNullabilityMarker(type2))
            .withDeclaredNullability(Nullability.nullable);

      case (TypeParameterType typeParameterType1, _):
        return _getTypeVariableStandardUpperBound(type1, type2,
            bound1: typeParameterType1.bound,
            nominalEliminationTarget: typeParameterType1.parameter);
      case (StructuralParameterType structuralParameterType1, _):
        return _getTypeVariableStandardUpperBound(type1, type2,
            bound1: structuralParameterType1.bound,
            structuralEliminationTarget: structuralParameterType1.parameter);
      case (_, TypeParameterType typeParameterType2):
        return _getTypeVariableStandardUpperBound(type2, type1,
            bound1: typeParameterType2.bound,
            nominalEliminationTarget: typeParameterType2.parameter);
      case (_, StructuralParameterType structuralParameterType2):
        return _getTypeVariableStandardUpperBound(type2, type1,
            bound1: structuralParameterType2.bound,
            structuralEliminationTarget: structuralParameterType2.parameter);

      case (FunctionType functionType1, FunctionType functionType2):
        return _getFunctionStandardUpperBound(functionType1, functionType2);
      case (FunctionType(), InterfaceType interfaceType2)
          when interfaceType2.classNode == coreTypes.functionClass:
        // UP(T Function<...>(...), Function) = Function
        return coreTypes.functionRawType(uniteNullabilities(
            type1.declaredNullability, type2.declaredNullability));
      case (FunctionType(), _):
        // UP(T Function<...>(...), T2) = UP(Object, T2)
        return _getStandardUpperBound(
            coreTypes.objectNonNullableRawType, type2);
      case (InterfaceType interfaceType1, FunctionType())
          when interfaceType1.classNode == coreTypes.functionClass:
        // UP(Function, T Function<...>(...)) = Function
        return coreTypes.functionRawType(uniteNullabilities(
            type1.declaredNullability, type2.declaredNullability));
      case (_, FunctionType()):
        // UP(T1, T Function<...>(...)) = UP(T1, Object)
        return _getStandardUpperBound(
            type1, coreTypes.objectNonNullableRawType);

      case (RecordType recordType1, RecordType recordType2):
        return _getRecordStandardUpperBound(recordType1, recordType2);
      case (RecordType(), InterfaceType interfaceType2)
          when interfaceType2.classNode == coreTypes.recordClass:
        // UP(Record(...), Record) = Record
        return coreTypes.recordRawType(uniteNullabilities(
            type1.declaredNullability, type2.declaredNullability));
      case (RecordType(), _):
        // UP(Record(...), T2) = UP(Object, T2)
        return _getStandardUpperBound(
            coreTypes.objectNonNullableRawType, type2);
      case (InterfaceType interfaceType1, RecordType())
          when interfaceType1.classNode == coreTypes.recordClass:
        // UP(Record, Record(...)) = Record
        return coreTypes.recordRawType(uniteNullabilities(
            type1.declaredNullability, type2.declaredNullability));
      case (_, RecordType()):
        // UP(T1, Record(...)) = UP(T1, Object)
        return _getStandardUpperBound(
            type1, coreTypes.objectNonNullableRawType);

      // UP(FutureOr<T1>, FutureOr<T2>) = FutureOr<T3> where T3 = UP(T1, T2)
      // UP(Future<T1>, FutureOr<T2>) = FutureOr<T3> where T3 = UP(T1, T2)
      // UP(FutureOr<T1>, Future<T2>) = FutureOr<T3> where T3 = UP(T1, T2)
      // UP(T1, FutureOr<T2>) = FutureOr<T3> where T3 = UP(T1, T2)
      // UP(FutureOr<T1>, T2) = FutureOr<T3> where T3 = UP(T1, T2)
      case (
          FutureOrType(typeArgument: DartType t1),
          FutureOrType(typeArgument: DartType t2)
        ):
      case (
            FutureOrType(typeArgument: DartType t1),
            InterfaceType(
              typeArguments: [DartType t2],
              classNode: Class classNode2
            )
          )
          when classNode2 == coreTypes.futureClass:
      case (FutureOrType(typeArgument: DartType t1), DartType t2):
      case (
            InterfaceType(
              typeArguments: [DartType t1],
              classNode: Class classNode1
            ),
            FutureOrType(typeArgument: DartType t2)
          )
          when classNode1 == coreTypes.futureClass:
      case (DartType t1, FutureOrType(typeArgument: DartType t2)):
        return new FutureOrType(
            getStandardUpperBound(t1, t2),
            uniteNullabilities(
                type1.declaredNullability, type2.declaredNullability));

      // We use the non-nullable variants of the two interfaces types to
      // determine T1 <: T2 without using the nullability of the outermost
      // type. The result uses [uniteNullabilities] to compute the resulting
      // type if the subtype relation is established.
      case (_, _)
          when isSubtypeOf(
              leastClosureForUpperBound(typeWithoutNullabilityMarker1),
              leastClosureForUpperBound(typeWithoutNullabilityMarker2)):
        // UP(T1, T2) = T2 if T1 <: T2
        //   Note that both types must be interface or extension types at this
        //   point.
        return type2.withDeclaredNullability(
            uniteNullabilities(type1.nullability, type2.nullability));
      case (_, _)
          when isSubtypeOf(
              leastClosureForUpperBound(typeWithoutNullabilityMarker2),
              leastClosureForUpperBound(typeWithoutNullabilityMarker1)):
        // UP(T1, T2) = T1 if T2 <: T1
        //   Note that both types must be interface or extension types at this
        //   point.
        return type1.withDeclaredNullability(uniteNullabilities(
            type1.declaredNullability, type2.declaredNullability));

      case (
          TypeDeclarationType typeDeclarationType1,
          TypeDeclarationType typeDeclarationType2
        ):
        if (typeDeclarationType1.typeDeclarationReference ==
            typeDeclarationType2.typeDeclarationReference) {
          // UP(C<T0, ..., Tn>, C<S0, ..., Sn>) = C<R0,..., Rn> where Ri is
          // UP(Ti, Si)

          TypeDeclaration typeDeclaration =
              typeDeclarationType1.typeDeclaration;
          List<TypeParameter> typeParameters = typeDeclaration.typeParameters;
          List<DartType> leftArguments = typeDeclarationType1.typeArguments;
          List<DartType> rightArguments = typeDeclarationType2.typeArguments;
          int n = typeParameters.length;
          List<DartType> typeArguments = new List<DartType>.of(leftArguments);
          for (int i = 0; i < n; ++i) {
            Variance variance = typeParameters[i].variance;
            if (variance == Variance.contravariant) {
              typeArguments[i] =
                  _getStandardLowerBound(leftArguments[i], rightArguments[i]);
            } else if (variance == Variance.invariant) {
              if (!areMutualSubtypes(leftArguments[i], rightArguments[i])) {
                return _getLegacyLeastUpperBound(
                    typeDeclarationType1, typeDeclarationType2);
              }
            } else {
              typeArguments[i] =
                  _getStandardUpperBound(leftArguments[i], rightArguments[i]);
            }
          }
          switch (typeDeclaration) {
            case Class():
              return new InterfaceType(
                  typeDeclaration,
                  uniteNullabilities(
                      type1.declaredNullability, type2.declaredNullability),
                  typeArguments);
            case ExtensionTypeDeclaration():
              return new ExtensionType(
                  typeDeclaration,
                  uniteNullabilities(
                      type1.declaredNullability, type2.declaredNullability),
                  typeArguments);
          }
        } else {
          // UP(C0<T0, ..., Tn>, C1<S0, ..., Sk>)
          //   = least upper bound of two interfaces as in Dart 1.
          return _getLegacyLeastUpperBound(
              typeDeclarationType1, typeDeclarationType2);
        }

      case (NeverType(nullability: Nullability.undetermined), _):
      case (_, NeverType(nullability: Nullability.undetermined)):
        throw new StateError("Unsupported nullability for NeverType: "
            "'${Nullability.undetermined}'.");

      case (AuxiliaryType(), _):
      case (_, AuxiliaryType()):
        throw new StateError("Unsupported type combination: "
            "getStandardUpperBoundInternal("
            "${type1.runtimeType}, ${type2.runtimeType}"
            ")");

      case (FunctionTypeParameterType(), _):
      case (_, FunctionTypeParameterType()):
        throw new StateError("Unimplemented for type combination: "
            "getStandardUpperBoundInternal("
            "${type1.runtimeType}, ${type2.runtimeType}"
            ")");

      case (ClassTypeParameterType(), _):
      case (_, ClassTypeParameterType()):
        throw new StateError("Unimplemented for type combination: "
            "getStandardUpperBoundInternal("
            "${type1.runtimeType}, ${type2.runtimeType}"
            ")");
    }
  }

  DartType _getLegacyLeastUpperBound(
      TypeDeclarationType type1, TypeDeclarationType type2) {
    if (type1 is InterfaceType && type2 is InterfaceType) {
      return hierarchy.getLegacyLeastUpperBound(type1, type2);
    } else if (type1 is ExtensionType || type2 is ExtensionType) {
      // This mimics the legacy least upper bound implementation for regular
      // classes, where the least upper bound is found as the single common
      // supertype with the highest class hierarchy depth.

      // TODO(johnniwinther): Move this computation to [ClassHierarchyBase] and
      // cache it there.
      // TODO(johnniwinther): Handle non-extension type supertypes.
      Map<ExtensionTypeDeclaration, int> extensionTypeDeclarationDepth = {};

      int computeExtensionTypeDeclarationDepth(
          ExtensionTypeDeclaration extensionTypeDeclaration,
          List<InterfaceType> superInterfaceType) {
        int? depth = extensionTypeDeclarationDepth[extensionTypeDeclaration];
        if (depth == null) {
          int maxDepth = 0;
          for (DartType implemented in extensionTypeDeclaration.implements) {
            if (implemented is ExtensionType) {
              int supertypeDepth = computeExtensionTypeDeclarationDepth(
                  implemented.extensionTypeDeclaration, superInterfaceType);
              if (supertypeDepth >= maxDepth) {
                maxDepth = supertypeDepth + 1;
              }
            } else if (implemented is InterfaceType) {
              superInterfaceType.add(implemented);
            }
          }
          depth = extensionTypeDeclarationDepth[extensionTypeDeclaration] =
              maxDepth;
        }
        return depth;
      }

      // TODO(johnniwinther): Handle non-extension type supertypes.
      void computeSuperTypes(ExtensionType type, List<ExtensionType> supertypes,
          List<InterfaceType> superInterfaceTypes) {
        computeExtensionTypeDeclarationDepth(
            type.extensionTypeDeclaration, superInterfaceTypes);
        supertypes.add(type);
        for (DartType implemented in type.extensionTypeDeclaration.implements) {
          if (implemented is ExtensionType) {
            ExtensionType supertype =
                hierarchy.getExtensionTypeAsInstanceOfExtensionTypeDeclaration(
                    type, implemented.extensionTypeDeclaration)!;
            computeSuperTypes(supertype, supertypes, superInterfaceTypes);
          }
        }
      }

      List<ExtensionType> supertypes1 = [];
      List<InterfaceType> superInterfaceTypes1 = [];
      if (type1 is ExtensionType) {
        computeSuperTypes(type1, supertypes1, superInterfaceTypes1);
      } else {
        type1 as InterfaceType;
        superInterfaceTypes1 = <InterfaceType>[type1];
      }
      List<ExtensionType> supertypes2 = [];
      List<InterfaceType> superInterfaceTypes2 = [];
      if (type2 is ExtensionType) {
        computeSuperTypes(type2, supertypes2, superInterfaceTypes2);
      } else {
        type2 as InterfaceType;
        superInterfaceTypes2 = <InterfaceType>[type2];
      }

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

      return hierarchy.getLegacyLeastUpperBoundFromSupertypeLists(
          type1, type2, superInterfaceTypes1, superInterfaceTypes2);
    }
    if (type1 is ExtensionType && type1.isPotentiallyNullable ||
        type2 is ExtensionType && type2.isPotentiallyNullable) {
      return coreTypes.objectNullableRawType;
    } else {
      return coreTypes.objectRawType(
          uniteNullabilities(type1.nullability, type2.nullability));
    }
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
  DartType _getFunctionStandardLowerBound(FunctionType f, FunctionType g) {
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
    if (g.typeParameters.length == m) {
      boundsMatch = true;
      if (m != 0) {
        List<DartType> fParametersAsArguments = [
          for (StructuralParameter parameter in f.typeParameters)
            new StructuralParameterType.withDefaultNullability(parameter)
        ];
        FunctionTypeInstantiator instantiator =
            FunctionTypeInstantiator.fromInstantiation(
                g, fParametersAsArguments);
        for (int i = 0; i < m && boundsMatch; ++i) {
          // TODO(cstefantsova): Figure out if a procedure for syntactic
          // equality should be used instead.
          if (!areMutualSubtypes(f.typeParameters[i].bound,
              instantiator.substitute(g.typeParameters[i].bound))) {
            boundsMatch = false;
          }
        }
        g = instantiator.substitute(g.withoutTypeParameters) as FunctionType;
      }
    }
    if (!boundsMatch) return fallbackResult;
    int maxPos =
        math.max(f.positionalParameters.length, g.positionalParameters.length);
    int minPos =
        math.min(f.positionalParameters.length, g.positionalParameters.length);

    List<StructuralParameter> typeParameters = f.typeParameters;

    List<DartType> positionalParameters =
        new List<DartType>.filled(maxPos, dummyDartType);
    for (int i = 0; i < minPos; ++i) {
      positionalParameters[i] = _getStandardUpperBound(
          f.positionalParameters[i], g.positionalParameters[i]);
    }
    for (int i = minPos; i < f.positionalParameters.length; ++i) {
      positionalParameters[i] = f.positionalParameters[i];
    }
    for (int i = minPos; i < g.positionalParameters.length; ++i) {
      positionalParameters[i] = g.positionalParameters[i];
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
              : new NamedType(named2.name, named2.type, isRequired: false);
          ++j;
        } else {
          named = new NamedType(
              named1.name, _getStandardUpperBound(named1.type, named2.type),
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
        namedParameters
            .add(new NamedType(named2.name, named2.type, isRequired: false));
        ++j;
      }
    }

    DartType returnType = _getStandardLowerBound(f.returnType, g.returnType);

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
  DartType _getRecordStandardLowerBound(RecordType r1, RecordType r2) {
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

    List<DartType> positional = new List<DartType>.generate(positionalLength,
        (i) => _getStandardLowerBound(r1.positional[i], r2.positional[i]));

    List<NamedType> named = new List<NamedType>.generate(
        namedLength,
        (i) => new NamedType(r1.named[i].name,
            _getStandardLowerBound(r1.named[i].type, r2.named[i].type)));

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
  DartType _getFunctionStandardUpperBound(FunctionType f, FunctionType g) {
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
    FunctionTypeInstantiator? instantiator;
    if (g.typeParameters.length == m) {
      boundsMatch = true;
      if (m != 0) {
        List<DartType> fTypeParametersAsTypes = [
          for (StructuralParameter parameter in f.typeParameters)
            new StructuralParameterType.withDefaultNullability(parameter)
        ];
        instantiator = FunctionTypeInstantiator.fromIterables(
            g.typeParameters, fTypeParametersAsTypes);
        for (int i = 0; i < m && boundsMatch; ++i) {
          // TODO(cstefantsova): Figure out if a procedure for syntactic
          // equality should be used instead.
          if (!areMutualSubtypes(f.typeParameters[i].bound,
              instantiator.substitute(g.typeParameters[i].bound))) {
            boundsMatch = false;
          }
        }
      }
    }
    if (!boundsMatch) return fallbackResult;
    int minPos =
        math.min(f.positionalParameters.length, g.positionalParameters.length);

    List<StructuralParameter> typeParameters = f.typeParameters;

    List<DartType> positionalParameters =
        new List<DartType>.filled(minPos, dummyDartType);
    for (int i = 0; i < minPos; ++i) {
      positionalParameters[i] = _getStandardLowerBound(
          f.positionalParameters[i],
          instantiator != null
              ? instantiator.substitute(g.positionalParameters[i])
              : g.positionalParameters[i]);
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
              _getStandardLowerBound(
                  named1.type,
                  instantiator != null
                      ? instantiator.substitute(named2.type)
                      : named2.type),
              isRequired: named1.isRequired || named2.isRequired));
          ++i;
          ++j;
        }
      }
    }

    DartType returnType = _getStandardUpperBound(
        f.returnType,
        instantiator != null
            ? instantiator.substitute(g.returnType)
            : g.returnType);

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
  DartType _getRecordStandardUpperBound(RecordType r1, RecordType r2) {
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

    List<DartType> positional = new List<DartType>.generate(positionalLength,
        (i) => _getStandardUpperBound(r1.positional[i], r2.positional[i]));

    List<NamedType> named = new List<NamedType>.generate(
        namedLength,
        (i) => new NamedType(r1.named[i].name,
            _getStandardUpperBound(r1.named[i].type, r2.named[i].type)));

    return new RecordType(positional, named,
        uniteNullabilities(r1.declaredNullability, r2.declaredNullability));
  }

  DartType _getTypeVariableStandardUpperBound(DartType type1, DartType type2,
      {required DartType bound1,
      TypeParameter? nominalEliminationTarget,
      StructuralParameter? structuralEliminationTarget}) {
    assert(type1 is TypeParameterType || type1 is StructuralParameterType);
    assert(nominalEliminationTarget != null &&
            structuralEliminationTarget == null ||
        nominalEliminationTarget == null &&
            structuralEliminationTarget != null);

    // UP(X1 extends B1, T2) =
    //   T2 if X1 <: T2
    //   otherwise X1 if T2 <: X1
    //   otherwise UP(B1a, T2)
    //     where B1a is the greatest closure of B1 with respect to X1,
    //     as defined in [inference.md].

    if (isSubtypeOf(
        leastClosureForUpperBound(type1), leastClosureForUpperBound(type2))) {
      return type2.withDeclaredNullability(combineNullabilitiesForSubstitution(
          inner: type2.nullability,
          outer: uniteNullabilities(
              type1.declaredNullability, type2.nullability)));
    }
    if (isSubtypeOf(
        leastClosureForUpperBound(type2), leastClosureForUpperBound(type1))) {
      return type1.withDeclaredNullability(combineNullabilitiesForSubstitution(
          inner: type1.declaredNullability,
          outer: uniteNullabilities(
              type1.declaredNullability, type2.nullability)));
    }
    TypeParameterEliminator eliminator = new TypeParameterEliminator(
        structuralEliminationTargets: {
          if (structuralEliminationTarget != null) structuralEliminationTarget
        },
        nominalEliminationTargets: {
          if (nominalEliminationTarget != null) nominalEliminationTarget
        },
        coreTypes: coreTypes,
        unhandledTypeHandler: (type, recursor) => false);
    DartType result =
        _getStandardUpperBound(eliminator.eliminateToGreatest(bound1), type2);
    return result.withDeclaredNullability(combineNullabilitiesForSubstitution(
        inner: result.declaredNullability,
        outer:
            uniteNullabilities(bound1.declaredNullability, type2.nullability)));
  }

  DartType _getIntersectionStandardUpperBound(
      IntersectionType type1, DartType type2) {
    // UP(X1 & B1, T2) =
    //   T2 if X1 <: T2
    //   otherwise X1 if T2 <: X1
    //   otherwise UP(B1a, T2)
    //     where B1a is the greatest closure of B1 with respect to X1,
    //     as defined in [inference.md].
    DartType demoted = type1.left;
    if (isSubtypeOf(
        leastClosureForUpperBound(demoted), leastClosureForUpperBound(type2))) {
      return type2.withDeclaredNullability(uniteNullabilities(
          type1.declaredNullability, type2.declaredNullability));
    }
    if (isSubtypeOf(
        leastClosureForUpperBound(type2), leastClosureForUpperBound(demoted))) {
      return demoted.withDeclaredNullability(uniteNullabilities(
          demoted.declaredNullability, type2.declaredNullability));
    }
    TypeParameterEliminator eliminator = new TypeParameterEliminator(
        structuralEliminationTargets: {},
        nominalEliminationTargets: {type1.left.parameter},
        coreTypes: coreTypes,
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

    return _getStandardUpperBound(
            eliminator.eliminateToGreatest(type1.right), type2)
        .withDeclaredNullability(resultingNullability);
  }

  /// Compute the greatest closure of [typeSchema] for subtyping in DOWN.
  ///
  /// > We add the axiom that DOWN(T, _) == T and the symmetric version.
  /// > We replace all uses of T1 <: T2 in the DOWN algorithm by S1 <: S2 where
  /// >   Si is the greatest closure of Ti with respect to _.
  ///
  /// The specification of using the greatest closure in DOWN can be found at
  /// https://github.com/dart-lang/language/blob/main/resources/type-system/inference.md#upper-bound
  DartType greatestClosureForLowerBound(DartType typeSchema) => typeSchema;

  /// Compute the least closure of [typeSchema] for subtyping in UP.
  ///
  /// Taking closures of type schemas in UP is specified as follows:
  ///
  /// > We add the axiom that UP(T, _) == T and the symmetric version.
  /// > We replace all uses of T1 <: T2 in the UP algorithm by S1 <: S2 where Si
  /// >   is the least closure of Ti with respect to _.
  ///
  /// The specification of using the least closure in UP can be found at
  /// https://github.com/dart-lang/language/blob/main/resources/type-system/inference.md#upper-bound
  DartType leastClosureForUpperBound(DartType typeSchema) => typeSchema;
}
