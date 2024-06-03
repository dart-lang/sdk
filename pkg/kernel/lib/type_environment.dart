// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.type_environment;

import 'ast.dart';
import 'class_hierarchy.dart';
import 'core_types.dart';
import 'type_algebra.dart';

import 'src/bounds_checks.dart';
import 'src/hierarchy_based_type_environment.dart'
    show HierarchyBasedTypeEnvironment;
import 'src/types.dart';

typedef void ErrorHandler(TreeNode node, String message);

abstract class TypeEnvironment extends Types {
  @override
  final CoreTypes coreTypes;

  TypeEnvironment.fromSubclass(this.coreTypes, ClassHierarchyBase base)
      : super(base);

  factory TypeEnvironment(CoreTypes coreTypes, ClassHierarchy hierarchy) {
    return new HierarchyBasedTypeEnvironment(coreTypes, hierarchy);
  }

  @override
  ClassHierarchy get hierarchy;

  Class get functionClass => coreTypes.functionClass;
  Class get objectClass => coreTypes.objectClass;

  InterfaceType get objectLegacyRawType => coreTypes.objectLegacyRawType;
  InterfaceType get objectNonNullableRawType =>
      coreTypes.objectNonNullableRawType;
  InterfaceType get objectNullableRawType => coreTypes.objectNullableRawType;

  /// Returns the type `List<E>` with the given [nullability] and [elementType]
  /// as `E`.
  InterfaceType listType(DartType elementType, Nullability nullability) {
    return new InterfaceType(
        coreTypes.listClass, nullability, <DartType>[elementType]);
  }

  /// Returns the type `Set<E>` with the given [nullability] and [elementType]
  /// as `E`.
  InterfaceType setType(DartType elementType, Nullability nullability) {
    return new InterfaceType(
        coreTypes.setClass, nullability, <DartType>[elementType]);
  }

  /// Returns the type `Map<K,V>` with the given [nullability], [key] as `K`
  /// and [value] is `V`.
  InterfaceType mapType(DartType key, DartType value, Nullability nullability) {
    return new InterfaceType(
        coreTypes.mapClass, nullability, <DartType>[key, value]);
  }

  /// Returns the type `Iterable<E>` with the given [nullability] and [type]
  /// as `E`.
  InterfaceType iterableType(DartType type, Nullability nullability) {
    return new InterfaceType(
        coreTypes.iterableClass, nullability, <DartType>[type]);
  }

  /// Returns the type `Future<E>` with the given [nullability] and [type]
  /// as `E`.
  InterfaceType futureType(DartType type, Nullability nullability) {
    return new InterfaceType(
        coreTypes.futureClass, nullability, <DartType>[type]);
  }

  DartType? _futureTypeOf(DartType t) {
    // We say that S is the "future type of a type" T in the following cases,
    // using the first applicable case:
    //
    // * T implements S and there is a U such that S is Future<U>.
    // * T is S bounded and there is a U such that S is FutureOr<U>,
    //   Future<U>?, or FutureOr<U>?.
    //
    // When none of these cases are applicable, we say that T does not have a
    // future type.
    DartType resolved = t.nonTypeVariableBound;
    if (resolved is TypeDeclarationType) {
      DartType? futureType =
          getTypeAsInstanceOf(resolved, coreTypes.futureClass, coreTypes);
      if (futureType != null) {
        // TODO(johnniwinther): The two implementations are inconsistent wrt.
        //  how [isNonNullableByDefault] is treated.
        return futureType.withDeclaredNullability(resolved.declaredNullability);
      }
    } else if (resolved is FutureOrType) {
      return resolved;
    }
    return null;
  }

  DartType flatten(DartType t) {
    // We define the auxiliary function flatten(T) as follows, using the first
    // applicable case:
    //
    // * If T is S? for some S then flatten(T) = flatten(S)?.
    // * If T is X & S for some type variable X and type S then
    //   - if S has future type U then flatten(T) = flatten(U).
    //   - otherwise, flatten(T) = flatten(X).
    // * If T has future type Future<S> or FutureOr<S> then flatten(T) = S.
    // * If T has future type Future<S>? or FutureOr<S>? then flatten(T) = S?.
    // * Otherwise, flatten(T) = T.
    if (t is IntersectionType) {
      DartType bound = t.right;
      DartType? futureType = _futureTypeOf(bound);
      if (futureType != null) {
        return flatten(futureType);
      } else {
        return flatten(t.left);
      }
    } else {
      DartType? futureType = _futureTypeOf(t);
      if (futureType is InterfaceType) {
        assert(futureType.classNode == coreTypes.futureClass);
        DartType typeArgument = futureType.typeArguments.single;
        return typeArgument.withDeclaredNullability(
            combineNullabilitiesForSubstitution(
                combineNullabilitiesForSubstitution(
                    typeArgument.declaredNullability,
                    futureType.declaredNullability),
                t.declaredNullability));
      } else if (futureType is FutureOrType) {
        DartType typeArgument = futureType.typeArgument;
        return typeArgument.withDeclaredNullability(
            combineNullabilitiesForSubstitution(
                combineNullabilitiesForSubstitution(
                    typeArgument.declaredNullability,
                    futureType.declaredNullability),
                t.declaredNullability));
      } else {
        return t;
      }
    }
  }

  /// Computes the underlying type of a union type
  ///
  /// Dart doesn't have generalized union types, but two specific ones: the
  /// FutureOr<T> type, which can be seen as a union of T and Future<T>, and the
  /// nullable type T?, which can be seen as the union of T and Null. In both
  /// cases the union type can be seen as application of the corresponding type
  /// constructor, FutureOr or ?, to the underlying type T. [getUnionFreeType]
  /// computes the underlying type of the given union type, accounting for
  /// potential nesting of the union types.
  ///
  /// The following are examples of the union-free types computed on for the
  /// given types.
  ///
  ///     getUnionFreeType(int) = int
  ///     getUnionFreeType(int?) = int
  ///     getUnionFreeType(FutureOr<int>) = int
  ///     getUnionFreeType(FutureOr<int?>?) = int
  DartType getUnionFreeType(DartType type) {
    if (isNullableTypeConstructorApplication(type)) {
      return getUnionFreeType(computeTypeWithoutNullabilityMarker(type,
          isNonNullableByDefault: true));
    } else if (type is FutureOrType) {
      return getUnionFreeType(type.typeArgument);
    } else {
      return type;
    }
  }

  /// True if [member] is a binary operator whose return type is defined by
  /// the both operand types.
  bool isSpecialCasedBinaryOperator(Procedure member) {
    Class? class_ = member.enclosingClass;
    // TODO(johnniwinther): Do we need to recognize backend implementation
    //  methods?
    if (class_ == coreTypes.intClass ||
        class_ == coreTypes.numClass ||
        class_ == coreTypes.doubleClass) {
      String name = member.name.text;
      return name == '+' ||
          name == '-' ||
          name == '*' ||
          name == 'remainder' ||
          name == '%';
    }
    return false;
  }

  /// True if [member] is a ternary operator whose return type is defined by
  /// the least upper bound of the operand types.
  bool isSpecialCasedTernaryOperator(Procedure member) {
    Class? class_ = member.enclosingClass;
    if (class_ == coreTypes.intClass || class_ == coreTypes.numClass) {
      String name = member.name.text;
      return name == 'clamp';
    }
    return false;
  }

  /// Returns the static return type of a special cased binary operator
  /// (see [isSpecialCasedBinaryOperator]) given the static type of the
  /// operands.
  DartType getTypeOfSpecialCasedBinaryOperator(DartType type1, DartType type2) {
    // Let e be an expression of one of the forms e1 + e2, e1 - e2, e1 * e2,
    // e1 % e2 or e1.remainder(e2), where the static type of e1 is a non-Never
    // type T and T <: num, and where the static type of e2 is S and S is
    // assignable to num. Then:
    if (type1 is! NeverType &&
            isSubtypeOf(type1, coreTypes.numNonNullableRawType,
                SubtypeCheckMode.withNullabilities) &&
            type2 is DynamicType ||
        isSubtypeOf(type2, coreTypes.numNonNullableRawType,
            SubtypeCheckMode.withNullabilities)) {
      if (isSubtypeOf(type1, coreTypes.doubleNonNullableRawType,
          SubtypeCheckMode.withNullabilities)) {
        // If T <: double then the static type of e is double. This includes S
        // being dynamic or Never.
        return coreTypes.doubleNonNullableRawType;
      } else if (type2 is! NeverType &&
          isSubtypeOf(type2, coreTypes.doubleNonNullableRawType,
              SubtypeCheckMode.withNullabilities)) {
        // If S <: double and not S <:Never, then the static type of e is
        // double.
        return coreTypes.doubleNonNullableRawType;
      } else if (isSubtypeOf(type1, coreTypes.intNonNullableRawType,
              SubtypeCheckMode.withNullabilities) &&
          type2 is! NeverType &&
          isSubtypeOf(type2, coreTypes.intNonNullableRawType,
              SubtypeCheckMode.withNullabilities)) {
        // If T <: int , S <: int and not S <: Never, then the static type of
        // e is int.
        return coreTypes.intNonNullableRawType;
      } else if (type2 is! NeverType &&
          isSubtypeOf(type2, type1, SubtypeCheckMode.withNullabilities)) {
        // Otherwise the static type of e is num.
        return coreTypes.numNonNullableRawType;
      }
    }
    // Otherwise the static type of e is num.
    return coreTypes.numNonNullableRawType;
  }

  DartType getTypeOfSpecialCasedTernaryOperator(
      DartType type1, DartType type2, DartType type3) {
    // Let e be a normal invocation of the form e1.clamp(e2, e3), where the
    // static types of e1, e2 and e3 are T1, T2 and T3 respectively, and where
    // T1, T2, and T3 are all non-Never subtypes of num. Then:
    if (type1 is! NeverType && type2 is! NeverType && type3 is! NeverType
        /* We skip the check that all types are subtypes of num because, if
          not, we'll compute the static type to be num, anyway.*/
        ) {
      if (isSubtypeOf(type1, coreTypes.intNonNullableRawType,
              SubtypeCheckMode.withNullabilities) &&
          isSubtypeOf(type2, coreTypes.intNonNullableRawType,
              SubtypeCheckMode.withNullabilities) &&
          isSubtypeOf(type3, coreTypes.intNonNullableRawType,
              SubtypeCheckMode.withNullabilities)) {
        // If T1, T2 and T3 are all subtypes of int, the static type of e is
        // int.
        return coreTypes.intNonNullableRawType;
      } else if (isSubtypeOf(type1, coreTypes.doubleNonNullableRawType,
              SubtypeCheckMode.withNullabilities) &&
          isSubtypeOf(type2, coreTypes.doubleNonNullableRawType,
              SubtypeCheckMode.withNullabilities) &&
          isSubtypeOf(type3, coreTypes.doubleNonNullableRawType,
              SubtypeCheckMode.withNullabilities)) {
        // If T1, T2 and T3 are all subtypes of double, the static type of e
        // is double.
        return coreTypes.doubleNonNullableRawType;
      }
    }
    // Otherwise the static type of e is num.
    return coreTypes.numNonNullableRawType;
  }

  bool _isRawTypeArgumentEquivalent(
      TypeDeclarationType type, int typeArgumentIndex,
      {required SubtypeCheckMode subtypeCheckMode}) {
    assert(0 <= typeArgumentIndex &&
        typeArgumentIndex < type.typeArguments.length);
    DartType typeArgument = type.typeArguments[typeArgumentIndex];
    DartType defaultType =
        type.typeDeclaration.typeParameters[typeArgumentIndex].defaultType;
    return areMutualSubtypes(typeArgument, defaultType, subtypeCheckMode);
  }

  /// Computes sufficiency of a shape check for the given types.
  ///
  /// In expressions of the form `e is T` and `e as T` the static type of the
  /// expression `e` is [expressionStaticType], and the type `T` is
  /// [checkTargetType].
  TypeShapeCheckSufficiency computeTypeShapeCheckSufficiency(
      {required DartType expressionStaticType,
      required DartType checkTargetType,
      required SubtypeCheckMode subtypeCheckMode}) {
    if (!IsSubtypeOf.basedSolelyOnNullabilities(
            expressionStaticType, checkTargetType)
        .inMode(subtypeCheckMode)) {
      return TypeShapeCheckSufficiency.insufficient;
    } else if (checkTargetType is InterfaceType &&
        expressionStaticType is InterfaceType) {
      // Analyze if an interface shape check is sufficient.

      // If `T` in `e is/as T` doesn't have type arguments, there's nothing more to
      // check besides the shape.
      // TODO(cstefantsova): Investigate if [expressionStaticType] can be of any
      // kind for the following sufficiency check to work.
      if (checkTargetType.typeArguments.isEmpty) {
        return TypeShapeCheckSufficiency.interfaceShape;
      }

      // If all of the type arguments of `A<T1, ..., Tn>` in `e is/as A<T1,
      // ..., Tn>` are mutual subtypes with the default values for the
      // corresponding type parameters, they don't need to be checked because
      // in a well-bounded type the type arguments must be subtypes of the
      // default types.
      bool targetTypeArgumentsAreDefaultTypes = true;
      List<TypeParameter> checkTargetTypeOwnTypeParameters =
          checkTargetType.classNode.typeParameters;
      assert(checkTargetType.typeArguments.length ==
          checkTargetTypeOwnTypeParameters.length);
      for (int typeParameterIndex = 0;
          typeParameterIndex < checkTargetTypeOwnTypeParameters.length;
          typeParameterIndex++) {
        // TODO(cstefantsova): Investigate if super-bounded types can appear as
        // [checkTargetType]s. In that case a subtype check should be done
        // instead of the mutual subtype check.
        if (!_isRawTypeArgumentEquivalent(checkTargetType, typeParameterIndex,
            subtypeCheckMode: subtypeCheckMode)) {
          targetTypeArgumentsAreDefaultTypes = false;
          break;
        }
      }
      // TODO(cstefantsova): Investigate if [expressionStaticType] can be of any
      // kind for the following sufficiency check to work.
      if (targetTypeArgumentsAreDefaultTypes) {
        return TypeShapeCheckSufficiency.interfaceShape;
      }

      // If `A<T1, ..., Tn>` in `e is/as A<T1, ... Tn>` has non-trivial type
      // arguments, but `e` is of static type `B` without type arguments, where
      // `B` is a name of an interface, and `A` is a subclass of `B`, we have
      // the following relation holding for any valid `S1`, ..., `Sn`: `A<S1,
      // ..., Sn> <: B`, and we can't skip the type argument checks.
      if (expressionStaticType.typeArguments.isEmpty) {
        return TypeShapeCheckSufficiency.insufficient;
      }

      // The computation of the sufficiency of the shape check is based on the
      // following observations. Let `T` be `A<T1, ..., Tn>` and `B<S1, ...,
      // Sk>` be the static type of `e` in `e as/is T`. Let `A` be a subclass
      // of `B` and let `B<Q1, ..., Qk>` be `A<T1, ..., Tn>` taken as an
      // instance of `B`.
      //
      // Then the shape check is sufficient if (1) `B<S1, ..., Sk>` is a
      // subtype of `B<Q1, ..., Qk>`, and (2) `A<T1, ..., Tn>` is the only
      // instance of `A` that yields `B<Q1, ..., Qk>` being taken as an
      // instance of `B`.
      //
      // For example, consider the following:
      //
      //   class C1<X> {}
      //   class C2<Y> extends C1<Y> {}
      //
      // If we need to determine the sufficiency of a shape check in the
      // expression `e is C2<num>` where `e` is of static type `C1<int>`, we
      // compute (condition (2)) `C2<num>` as an instance of `C1`, which yields
      // `C1<num>`.  Obviously, `C2<TYPE>` taken as an instance of `C1` won't
      // yield `C1<num>` for any `TYPE` that isn't `num`.  Additionally
      // (condition (1)), `C1<int>` is a subtype of `C1<num>`. Therefore, we
      // conclude the shape check is sufficient in `e is C2<num>`.
      //
      // As an example of a case where the shape check isn't sufficient,
      // consider the following:
      //
      //   class D1<X> {}
      //   class D2 extends D1<int> {}
      //   class D3<Y> extends D2 {}
      //
      // In the expression `e is D3<num>` let `e` be of static type `D1<int>`.
      // Taken as an instance of `D1`, `D3<num>` yields `D1<int>`, and
      // `D1<int>` is a subtype of `D1<int>` (condition (1)). However,
      // `D3<num>` isn't the only instance of `D3` that yields `D1<int>` when
      // taken as an instance of `D1` (failed condition (2)). Examples of other
      // such instances are `D3<String>` or `D3<bool>`.  Therefore, we conclude
      // that the shape check is insufficient in the expression `e is D3<num>`,
      // which proves true when we consider the possibility of the runtime type
      // of the value of `e` being `D3<String>` or `D3<bool>`.
      //
      // Finally, we can relax condition (2) by allowing multiple instances of
      // `A<T1, ..., Tn>` yielding the same `B<Q1, ..., Qk>` being taken as an
      // instance of `B` in case `A<T1, ..., Tn>` is a supertype of all such
      // types. Let's call `AA` the set of all instances of `A` that yield
      // `B<Q1, ..., Qk>` when taken as an instance of `B`.  We replace
      // condition (2) with the relaxed condition (2*) requiring that `A<T1,
      // ..., Tn>` is such that for every `Ti` either `Ti` is the type argument
      // in the i-th position for all instances in `AA` or `Ti` is the default
      // type for the i-th type parameter of `A`.
      //
      // Consider the following example.
      //
      //   class E1<X> {}
      //   class E2<Y1, Y2> extends E1<Y1> {}
      //
      // In the expression `e is E2<num, dynamic>` let `e` be of static type
      // `E1<int>`. Taken as an instance of `E1`, `E2<num, dynamic>` yields
      // `E1<num>`. Condition (1) is satisfied because `E1<int>` is a subtype
      // `E1<num>`. Then, to check the condition (2*), we notice that `E2<num,
      // TYPE>` yields `E1<num>` for any type `TYPE` taken as an instance of
      // `E1`. The first type argument of `E2<num, dynamic>` is the same in all
      // such types, and the second type argument is the default type for the
      // second parameter of `E2`, so condition (2*) is satisfied. We conclude
      // that the shape check is sufficient in `e is E2<enum, dynamic>`.

      // First, we compute `B<Q1, ..., Qk>`, which is `A<T1, ..., Tn>` taken as
      // an instance of `B` in `e is/as A<T1, ..., Tn>`, where `B<S1, ..., Sk>`
      // is the static type of `e`.
      InterfaceType? testedAgainstTypeAsOperandClass = hierarchy
          .getInterfaceTypeAsInstanceOfClass(
              checkTargetType, expressionStaticType.classNode)
          ?.withDeclaredNullability(checkTargetType.declaredNullability);

      // If `A<T1, ..., Tn>` isn't an instance of `B`, the full type check
      // should be done.
      if (testedAgainstTypeAsOperandClass == null) {
        return TypeShapeCheckSufficiency.insufficient;
      } else {
        // If `A<T1, ..., Tn>` is an instance of `B`, we proceed to checking
        // condition (2*).  For that we compute `A<X1, ..., Xn>` as an instance
        // of `B`, where `X1`, ..., `Xn` are the type variables declared by
        // `A`.  The resulting type is `B<R1, ..., Rk>`, where `R1`, ..., `Rk`
        // may contain occurrences of `X1`, ..., `Xn`.
        InterfaceType unsubstitutedTestedAgainstTypeAsOperandClass =
            hierarchy.getInterfaceTypeAsInstanceOfClass(
                new InterfaceType(checkTargetType.classNode,
                    checkTargetType.declaredNullability, [
                  for (TypeParameter typeParameter
                      in checkTargetTypeOwnTypeParameters)
                    new TypeParameterType(
                        typeParameter,
                        TypeParameterType.computeNullabilityFromBound(
                            typeParameter))
                ]),
                expressionStaticType.classNode)!;
        // Now we search for the occurrences of `X1`, ..., `Xn` in `B<R1,
        // ..., Rk>`. Those that are found indicate the positions in `A<T1,
        // ..., Tn>` that are fixed and supposed to be the same for every
        // instance of `A` that yields `B<Q1, ..., Qk>` when taken as an
        // instance of `B`.  The other positions, that is, the indices of
        // `Xi` that don't occur in `B<R1, ..., Rk>`, are supposed to hold
        // the default types for the corresponding parameter of `A` in order
        // to satisfy condition (2*).
        OccurrenceCollectorVisitor occurrenceCollectorVisitor =
            new OccurrenceCollectorVisitor(
                checkTargetTypeOwnTypeParameters.toSet());
        occurrenceCollectorVisitor
            .visit(unsubstitutedTestedAgainstTypeAsOperandClass);

        // Check that those of `Xi` that don't occur in `B<R1, ..., Rk>`
        // indicate the positions of type arguments in `A<T1, ..., Tn>`
        // that are equivalent to default types.
        bool allNonOccurringAreDefaultTypes = true;
        for (int typeParameterIndex = 0;
            typeParameterIndex < checkTargetTypeOwnTypeParameters.length;
            typeParameterIndex++) {
          if (!occurrenceCollectorVisitor.occurred.contains(
                  checkTargetTypeOwnTypeParameters[typeParameterIndex]) &&
              !_isRawTypeArgumentEquivalent(checkTargetType, typeParameterIndex,
                  subtypeCheckMode: subtypeCheckMode)) {
            allNonOccurringAreDefaultTypes = false;
            break;
          }
        }

        if (allNonOccurringAreDefaultTypes) {
          // Condition (2*) is satisfied. We need to check condition (1).
          return isSubtypeOf(
                  expressionStaticType,
                  testedAgainstTypeAsOperandClass,
                  SubtypeCheckMode.withNullabilities)
              ? TypeShapeCheckSufficiency.interfaceShape
              : TypeShapeCheckSufficiency.insufficient;
        } else {
          // Condition (2*) is not satisfied.
          return TypeShapeCheckSufficiency.insufficient;
        }
      }
    } else if (checkTargetType is RecordType &&
        expressionStaticType is RecordType) {
      bool isTopRecordTypeForTheShape = true;
      for (DartType positional in checkTargetType.positional) {
        if (!isTop(positional)) {
          isTopRecordTypeForTheShape = false;
          break;
        }
      }
      for (NamedType named in checkTargetType.named) {
        if (!isTop(named.type)) {
          isTopRecordTypeForTheShape = false;
          break;
        }
      }
      if (isTopRecordTypeForTheShape) {
        // TODO(cstefantsova): Investigate if [expressionStaticType] can be of
        // any kind for the following sufficiency check to work.
        return TypeShapeCheckSufficiency.recordShape;
      }

      if (isSubtypeOf(
          expressionStaticType, checkTargetType, subtypeCheckMode)) {
        return TypeShapeCheckSufficiency.recordShape;
      } else {
        return TypeShapeCheckSufficiency.insufficient;
      }
    } else if (checkTargetType is FunctionType &&
        expressionStaticType is FunctionType) {
      if (checkTargetType.typeParameters.isEmpty &&
          expressionStaticType.typeParameters.isEmpty) {
        bool isTopFunctionTypeForTheShape = true;
        for (DartType positional in checkTargetType.positionalParameters) {
          if (!isBottom(positional)) {
            isTopFunctionTypeForTheShape = false;
          }
        }
        for (NamedType named in checkTargetType.namedParameters) {
          if (!isBottom(named.type)) {
            isTopFunctionTypeForTheShape = false;
          }
        }
        if (!isTop(checkTargetType.returnType)) {
          isTopFunctionTypeForTheShape = false;
        }

        if (isTopFunctionTypeForTheShape) {
          // TODO(cstefantsova): Investigate if [expressionStaticType] can be of
          // any kind for the following sufficiency check to work.
          return TypeShapeCheckSufficiency.functionShape;
        }
      }

      if (isSubtypeOf(
          expressionStaticType, checkTargetType, subtypeCheckMode)) {
        return TypeShapeCheckSufficiency.functionShape;
      } else {
        return TypeShapeCheckSufficiency.insufficient;
      }
    } else if (checkTargetType is FutureOrType &&
        expressionStaticType is FutureOrType) {
      if (isTop(checkTargetType.typeArgument)) {
        // TODO(cstefantsova): Investigate if [expressionStaticType] can be of
        // any kind for the following sufficiency check to work.
        return TypeShapeCheckSufficiency.futureOrShape;
      } else if (isSubtypeOf(expressionStaticType.typeArgument,
          checkTargetType.typeArgument, subtypeCheckMode)) {
        return TypeShapeCheckSufficiency.futureOrShape;
      } else {
        return TypeShapeCheckSufficiency.insufficient;
      }
    } else {
      return TypeShapeCheckSufficiency.insufficient;
    }
  }
}

/// Tri-state logical result of a nullability-aware subtype check.
class IsSubtypeOf {
  /// Internal value constructed via [IsSubtypeOf.never].
  ///
  /// The integer values of [_valueNever], [_valueOnlyIfIgnoringNullabilities],
  /// and [_valueAlways] are important for the implementations of [_andValues],
  /// [_all], and [and].  They should be kept in sync.
  static const int _valueNever = 0;

  /// Internal value constructed via [IsSubtypeOf.onlyIfIgnoringNullabilities].
  static const int _valueOnlyIfIgnoringNullabilities = 1;

  /// Internal value constructed via [IsSubtypeOf.always].
  static const int _valueAlways = 3;

  static const List<IsSubtypeOf> _all = const <IsSubtypeOf>[
    const IsSubtypeOf.never(),
    const IsSubtypeOf.onlyIfIgnoringNullabilities(),
    // There's no value for this index so we use `IsSubtypeOf.never()` as a
    // dummy value.
    const IsSubtypeOf.never(),
    const IsSubtypeOf.always()
  ];

  /// Combines results of subtype checks on parts into the overall result.
  ///
  /// It's an implementation detail for [and].  See the comment on [and] for
  /// more details and examples.  Both [value1] and [value2] should be chosen
  /// from [_valueNever], [_valueOnlyIfIgnoringNullabilities], and
  /// [_valueAlways].  The method produces the result which is one of
  /// [_valueNever], [_valueOnlyIfIgnoringNullabilities], and [_valueAlways].
  static int _andValues(int value1, int value2) => value1 & value2;

  /// Combines results of the checks on alternatives into the overall result.
  ///
  /// It's an implementation detail for [or].  See the comment on [or] for more
  /// details and examples.  Both [value1] and [value2] should be chosen from
  /// [_valueNever], [_valueOnlyIfIgnoringNullabilities], and [_valueAlways].
  /// The method produces the result which is one of [_valueNever],
  /// [_valueOnlyIfIgnoringNullabilities], and [_valueAlways].
  static int _orValues(int value1, int value2) => value1 | value2;

  /// The only state of an [IsSubtypeOf] object.
  final int _value;

  final DartType? subtype;

  final DartType? supertype;

  const IsSubtypeOf._internal(int value, this.subtype, this.supertype)
      : _value = value;

  /// Subtype check succeeds in both modes.
  const IsSubtypeOf.always() : this._internal(_valueAlways, null, null);

  /// Subtype check succeeds only if the nullability markers are ignored.
  ///
  /// It is assumed that if a subtype check succeeds for two types in full-NNBD
  /// mode, it also succeeds for those two types if the nullability markers on
  /// the types and all of their sub-terms are ignored (that is, in the pre-NNBD
  /// mode).  By contraposition, if a subtype check fails for two types when the
  /// nullability markers are ignored, it should also fail for those types in
  /// full-NNBD mode.
  const IsSubtypeOf.onlyIfIgnoringNullabilities(
      {DartType? subtype, DartType? supertype})
      : this._internal(_valueOnlyIfIgnoringNullabilities, subtype, supertype);

  /// Subtype check fails in both modes.
  const IsSubtypeOf.never() : this._internal(_valueNever, null, null);

  /// Checks if two types are in relation based solely on their nullabilities.
  ///
  /// This is useful on its own if the types are known to be the same modulo the
  /// nullability attribute, but mostly it's useful to combine the result from
  /// [IsSubtypeOf.basedSolelyOnNullabilities] via [and] with the partial
  /// results obtained from other type parts. For example, the overall result
  /// for `List<int>? <: List<num>*` can be computed as `Ra.and(Rn)` where `Ra`
  /// is the result of a subtype check on the arguments `int` and `num`, and
  /// `Rn` is the result of [IsSubtypeOf.basedSolelyOnNullabilities] on the
  /// types `List<int>?` and `List<num>*`.
  factory IsSubtypeOf.basedSolelyOnNullabilities(
      DartType subtype, DartType supertype) {
    if (subtype is InvalidType) {
      if (supertype is InvalidType) {
        return const IsSubtypeOf.always();
      }
      return new IsSubtypeOf.onlyIfIgnoringNullabilities(
          subtype: subtype, supertype: supertype);
    }
    if (supertype is InvalidType) {
      return new IsSubtypeOf.onlyIfIgnoringNullabilities(
          subtype: subtype, supertype: supertype);
    }

    return _basedSolelyOnNullabilitiesNotInvalidType(subtype, supertype);
  }

  /// Checks if two types are in relation based solely on their nullabilities
  /// and where the caller knows that neither type is a `InvalidType`.
  factory IsSubtypeOf.basedSolelyOnNullabilitiesNotInvalidType(
      DartType subtype, DartType supertype) {
    return _basedSolelyOnNullabilitiesNotInvalidType(subtype, supertype);
  }

  @pragma("vm:prefer-inline")
  static IsSubtypeOf _basedSolelyOnNullabilitiesNotInvalidType(
      DartType subtype, DartType supertype) {
    if (subtype.isPotentiallyNullable && supertype.isPotentiallyNonNullable) {
      // It's a special case to test X% <: X%, FutureOr<X%> <: FutureOr<X%>,
      // FutureOr<FutureOr<X%>> <: FutureOr<FutureOr<X%>>, etc, where X is a
      // type parameter.  In that case, the nullabilities of the subtype and the
      // supertype are related, that is, they are both nullable or non-nullable
      // at run time.
      if (subtype.nullability == Nullability.undetermined &&
          supertype.nullability == Nullability.undetermined) {
        DartType unwrappedSubtype = subtype;
        DartType unwrappedSupertype = supertype;
        while (unwrappedSubtype is FutureOrType) {
          unwrappedSubtype = unwrappedSubtype.typeArgument;
        }
        while (unwrappedSupertype is FutureOrType) {
          unwrappedSupertype = unwrappedSupertype.typeArgument;
        }
        if (unwrappedSubtype.nullability == unwrappedSupertype.nullability) {
          // The relationship between the types must be established elsewhere.
          return const IsSubtypeOf.always();
        }
      }
      return new IsSubtypeOf.onlyIfIgnoringNullabilities(
          subtype: subtype, supertype: supertype);
    }
    return const IsSubtypeOf.always();
  }

  /// Combines results for the type parts into the overall result for the type.
  ///
  /// For example, the result of `A<B1, C1> <: A<B2, C2>` can be computed from
  /// the results of the checks `B1 <: B2` and `C1 <: C2`.  Using the binary
  /// outcome of the checks, the combination of the check results on parts is
  /// simply done via `&&`, and [and] is the analog to `&&` for the ternary
  /// outcome.  So, in the example above the overall result is computed as
  /// `Rb.and(Rc)` where `Rb` is the result of `B1 <: B2`, `Rc` is the result
  /// of `C1 <: C2`.
  IsSubtypeOf and(IsSubtypeOf other) {
    int resultValue = _andValues(_value, other._value);
    if (resultValue == IsSubtypeOf._valueOnlyIfIgnoringNullabilities) {
      // If the type mismatch is due to nullabilities, the mismatching parts are
      // remembered in either 'this' or [other].  In that case we need to return
      // exactly one of those objects, so that the information about mismatching
      // parts is propagated upwards.
      if (_value == IsSubtypeOf._valueOnlyIfIgnoringNullabilities) {
        return this;
      } else {
        assert(other._value == IsSubtypeOf._valueOnlyIfIgnoringNullabilities);
        return other;
      }
    } else {
      return _all[resultValue];
    }
  }

  /// Shorts the computation of [and] if `this` is [IsSubtypeOf.never].
  ///
  /// Use this instead of [and] for optimization in case the argument to [and]
  /// is, for example, a potentially expensive subtype check.  Unlike [and],
  /// [andSubtypeCheckFor] will immediately return if `this` was constructed as
  /// [IsSubtypeOf.never] because the right-hand side will not change the
  /// overall result anyway.
  IsSubtypeOf andSubtypeCheckFor(
      DartType subtype, DartType supertype, Types tester) {
    if (_value == _valueNever) return this;
    return this
        .and(tester.performNullabilityAwareSubtypeCheck(subtype, supertype));
  }

  /// Combines results of the checks on alternatives into the overall result.
  ///
  /// For example, the result of `T <: FutureOr<S>` can be computed from the
  /// results of the checks `T <: S` and `T <: Future<S>`.  Using the binary
  /// outcome of the checks, the combination of the check results on parts is
  /// simply done via logical "or", and [or] is the analog to "or" for the
  /// ternary outcome.  So, in the example above the overall result is computed
  /// as `Rs.or(Rf)` where `Rs` is the result of `T <: S`, `Rf` is the result of
  /// `T <: Future<S>`.
  IsSubtypeOf or(IsSubtypeOf other) {
    int resultValue = _orValues(_value, other._value);
    if (resultValue == IsSubtypeOf._valueOnlyIfIgnoringNullabilities) {
      // If the type mismatch is due to nullabilities, the mismatching parts are
      // remembered in either 'this' or [other].  In that case we need to return
      // exactly one of those objects, so that the information about mismatching
      // parts is propagated upwards.
      if (_value == IsSubtypeOf._valueOnlyIfIgnoringNullabilities) {
        return this;
      } else {
        assert(other._value == IsSubtypeOf._valueOnlyIfIgnoringNullabilities);
        return other;
      }
    } else {
      return _all[resultValue];
    }
  }

  /// Shorts the computation of [or] if `this` is [IsSubtypeOf.always].
  ///
  /// Use this instead of [or] for optimization in case the argument to [or] is,
  /// for example, a potentially expensive subtype check.  Unlike [or],
  /// [orSubtypeCheckFor] will immediately return if `this` was constructed
  /// as [IsSubtypeOf.always] because the right-hand side will not change the
  /// overall result anyway.
  IsSubtypeOf orSubtypeCheckFor(
      DartType subtype, DartType supertype, Types tester) {
    if (_value == _valueAlways) return this;
    return this
        .or(tester.performNullabilityAwareSubtypeCheck(subtype, supertype));
  }

  bool isSubtypeWhenIgnoringNullabilities() {
    return _value != _valueNever;
  }

  bool isSubtypeWhenUsingNullabilities() {
    return _value == _valueAlways;
  }

  @override
  String toString() {
    switch (_value) {
      case _valueAlways:
        return "IsSubtypeOf.always";
      case _valueNever:
        return "IsSubtypeOf.never";
      case _valueOnlyIfIgnoringNullabilities:
        return "IsSubtypeOf.onlyIfIgnoringNullabilities";
    }
    return "IsSubtypeOf.<unknown value '${_value}'>";
  }

  bool inMode(SubtypeCheckMode subtypeCheckMode) {
    switch (subtypeCheckMode) {
      case SubtypeCheckMode.withNullabilities:
        return isSubtypeWhenUsingNullabilities();
      case SubtypeCheckMode.ignoringNullabilities:
        return isSubtypeWhenIgnoringNullabilities();
    }
  }
}

enum SubtypeCheckMode {
  withNullabilities,
  ignoringNullabilities,
}

abstract class StaticTypeCache {
  DartType getExpressionType(Expression node, StaticTypeContext context);

  DartType getForInIteratorType(ForInStatement node, StaticTypeContext context);

  DartType getForInElementType(ForInStatement node, StaticTypeContext context);
}

class StaticTypeCacheImpl implements StaticTypeCache {
  late Map<Expression, DartType> _expressionTypes = {};
  late Map<ForInStatement, DartType> _forInIteratorTypes = {};
  late Map<ForInStatement, DartType> _forInElementTypes = {};

  @override
  DartType getExpressionType(Expression node, StaticTypeContext context) {
    return _expressionTypes[node] ??= node.getStaticTypeInternal(context);
  }

  @override
  DartType getForInIteratorType(
      ForInStatement node, StaticTypeContext context) {
    return _forInIteratorTypes[node] ??= node.getIteratorTypeInternal(context);
  }

  @override
  DartType getForInElementType(ForInStatement node, StaticTypeContext context) {
    return _forInElementTypes[node] ??= node.getElementTypeInternal(context);
  }
}

/// Context object needed for computing `Expression.getStaticType`.
///
/// The [StaticTypeContext] provides access to the [TypeEnvironment] and the
/// current 'this type' as well as determining the nullability state of the
/// enclosing library.
abstract class StaticTypeContext {
  /// The [TypeEnvironment] used for the static type computation.
  ///
  /// This provides access to the core types and the class hierarchy.
  TypeEnvironment get typeEnvironment;

  /// The static type of a `this` expression.
  InterfaceType? get thisType;

  /// The enclosing library of this context.
  Library get enclosingLibrary;

  /// Creates a static type context for computing static types in the body
  /// of [member].
  factory StaticTypeContext(Member member, TypeEnvironment typeEnvironment,
      {StaticTypeCache cache}) = StaticTypeContextImpl;

  /// Creates a static type context for computing static types of annotations
  /// in [library].
  factory StaticTypeContext.forAnnotations(
      Library library, TypeEnvironment typeEnvironment,
      {StaticTypeCache cache}) = StaticTypeContextImpl.forAnnotations;

  /// The [Nullability] used for non-nullable types.
  ///
  /// For opt out libraries this is [Nullability.legacy].
  Nullability get nonNullable;

  /// The [Nullability] used for nullable types.
  ///
  /// For opt out libraries this is [Nullability.legacy].
  Nullability get nullable;

  /// Returns the mode under which the current library was compiled.
  NonNullableByDefaultCompiledMode get nonNullableByDefaultCompiledMode;

  /// Returns the static type of [node].
  DartType getExpressionType(Expression node);

  /// Returns the static type of the iterator in for-in statement [node].
  DartType getForInIteratorType(ForInStatement node);

  /// Returns the static type of the element in for-in statement [node].
  DartType getForInElementType(ForInStatement node);
}

class StaticTypeContextImpl implements StaticTypeContext {
  /// The [TypeEnvironment] used for the static type computation.
  ///
  /// This provides access to the core types and the class hierarchy.
  @override
  final TypeEnvironment typeEnvironment;

  /// The library in which the static type is computed.
  ///
  /// The `library.isNonNullableByDefault` property is used to determine the
  /// nullabilities of the static types.
  final Library _library;

  /// The static type of a `this` expression.
  @override
  final InterfaceType? thisType;

  final StaticTypeCache? _cache;

  /// Creates a static type context for computing static types in the body
  /// of [member].
  StaticTypeContextImpl(Member member, TypeEnvironment typeEnvironment,
      {StaticTypeCache? cache})
      : this.direct(member.enclosingLibrary, typeEnvironment,
            thisType: member.enclosingClass?.getThisType(
                typeEnvironment.coreTypes, member.enclosingLibrary.nonNullable),
            cache: cache);

  /// Creates a static type context for computing static types in the body of
  /// a member, provided the enclosing [_library] and [thisType].
  StaticTypeContextImpl.direct(this._library, this.typeEnvironment,
      {this.thisType, StaticTypeCache? cache})
      : _cache = cache;

  /// Creates a static type context for computing static types of annotations
  /// in [library].
  StaticTypeContextImpl.forAnnotations(
      Library library, TypeEnvironment typeEnvironment,
      {StaticTypeCache? cache})
      : this.direct(library, typeEnvironment, cache: cache);

  @override
  Library get enclosingLibrary => _library;

  /// The [Nullability] used for non-nullable types.
  ///
  /// For opt out libraries this is [Nullability.legacy].
  @override
  Nullability get nonNullable => _library.nonNullable;

  /// The [Nullability] used for nullable types.
  ///
  /// For opt out libraries this is [Nullability.legacy].
  @override
  Nullability get nullable => _library.nullable;

  /// Returns the mode under which the current library was compiled.
  @override
  NonNullableByDefaultCompiledMode get nonNullableByDefaultCompiledMode =>
      _library.nonNullableByDefaultCompiledMode;

  @override
  DartType getExpressionType(Expression node) {
    if (_cache != null) {
      return _cache!.getExpressionType(node, this);
    } else {
      return node.getStaticTypeInternal(this);
    }
  }

  @override
  DartType getForInIteratorType(ForInStatement node) {
    if (_cache != null) {
      return _cache!.getForInIteratorType(node, this);
    } else {
      return node.getIteratorTypeInternal(this);
    }
  }

  @override
  DartType getForInElementType(ForInStatement node) {
    if (_cache != null) {
      return _cache!.getForInElementType(node, this);
    } else {
      return node.getElementTypeInternal(this);
    }
  }
}

/// Implementation of [StaticTypeContext] that update its state when entering
/// and leaving libraries and members.
abstract class StatefulStaticTypeContext implements StaticTypeContext {
  @override
  final TypeEnvironment typeEnvironment;

  /// Creates a [StatefulStaticTypeContext] that supports entering multiple
  /// libraries and/or members successively.
  factory StatefulStaticTypeContext.stacked(TypeEnvironment typeEnvironment) =
      _StackedStatefulStaticTypeContext;

  /// Creates a [StatefulStaticTypeContext] that only supports entering one
  /// library and/or member at a time.
  factory StatefulStaticTypeContext.flat(TypeEnvironment typeEnvironment) =
      _FlatStatefulStaticTypeContext;

  StatefulStaticTypeContext._internal(this.typeEnvironment);

  /// Updates the [nonNullable] and [thisType] to match static type context for
  /// the member [node].
  ///
  /// This should be called before computing static types on the body of member
  /// [node].
  void enterMember(Member node);

  /// Reverts the [nonNullable] and [thisType] values to the previous state.
  ///
  /// This should be called after computing static types on the body of member
  /// [node].
  void leaveMember(Member node);

  /// Updates the [nonNullable] and [thisType] to match static type context for
  /// the library [node].
  ///
  /// This should be called before computing static types on annotations in the
  /// library [node].
  void enterLibrary(Library node);

  /// Reverts the [nonNullable] and [thisType] values to the previous state.
  ///
  /// This should be called after computing static types on annotations in the
  /// library [node].
  void leaveLibrary(Library node);
}

/// Implementation of [StatefulStaticTypeContext] that only supports entering
/// one library and/or at a time.
class _FlatStatefulStaticTypeContext extends StatefulStaticTypeContext {
  Library? _currentLibrary;
  Member? _currentMember;

  _FlatStatefulStaticTypeContext(TypeEnvironment typeEnvironment)
      : super._internal(typeEnvironment);

  @override
  Library get enclosingLibrary => _library;

  Library get _library {
    Library? library = _currentLibrary ?? _currentMember?.enclosingLibrary;
    assert(library != null,
        "No library currently associated with StaticTypeContext.");
    return library!;
  }

  @override
  InterfaceType? get thisType {
    assert(_currentMember != null,
        "No member currently associated with StaticTypeContext.");
    return _currentMember?.enclosingClass?.getThisType(
        typeEnvironment.coreTypes,
        _currentMember!.enclosingLibrary.nonNullable);
  }

  @override
  Nullability get nonNullable => _library.nonNullable;

  @override
  Nullability get nullable => _library.nullable;

  @override
  NonNullableByDefaultCompiledMode get nonNullableByDefaultCompiledMode =>
      _library.nonNullableByDefaultCompiledMode;

  /// Updates the [nonNullable] and [thisType] to match static type context for
  /// the member [node].
  ///
  /// This should be called before computing static types on the body of member
  /// [node].
  ///
  /// Only one member can be entered at a time.
  @override
  void enterMember(Member node) {
    assert(_currentMember == null, "Already in context of $_currentMember");
    _currentMember = node;
  }

  /// Reverts the [nonNullable] and [thisType] values to the previous state.
  ///
  /// This should be called after computing static types on the body of member
  /// [node].
  @override
  void leaveMember(Member node) {
    assert(
        _currentMember == node,
        "Inconsistent static type context stack: "
        "Trying to leave $node but current is ${_currentMember}.");
    _currentMember = null;
  }

  /// Updates the [nonNullable] and [thisType] to match static type context for
  /// the library [node].
  ///
  /// This should be called before computing static types on annotations in the
  /// library [node].
  ///
  /// Only one library can be entered at a time, and not while a member is
  /// entered through [enterMember].
  @override
  void enterLibrary(Library node) {
    assert(_currentLibrary == null, "Already in context of $_currentLibrary");
    assert(_currentMember == null, "Already in context of $_currentMember");
    _currentLibrary = node;
  }

  /// Reverts the [nonNullable] and [thisType] values to the previous state.
  ///
  /// This should be called after computing static types on annotations in the
  /// library [node].
  @override
  void leaveLibrary(Library node) {
    assert(
        _currentLibrary == node,
        "Inconsistent static type context stack: "
        "Trying to leave $node but current is ${_currentLibrary}.");
    _currentLibrary = null;
  }

  @override
  DartType getExpressionType(Expression node) =>
      node.getStaticTypeInternal(this);

  @override
  DartType getForInIteratorType(ForInStatement node) =>
      node.getIteratorTypeInternal(this);

  @override
  DartType getForInElementType(ForInStatement node) =>
      node.getElementTypeInternal(this);
}

/// Implementation of [StatefulStaticTypeContext] that use a stack to change
/// state when entering and leaving libraries and members.
class _StackedStatefulStaticTypeContext extends StatefulStaticTypeContext {
  final List<_StaticTypeContextState> _contextStack =
      <_StaticTypeContextState>[];

  _StackedStatefulStaticTypeContext(TypeEnvironment typeEnvironment)
      : super._internal(typeEnvironment);

  @override
  Library get enclosingLibrary => _library;

  Library get _library {
    assert(_contextStack.isNotEmpty,
        "No library currently associated with StaticTypeContext.");
    return _contextStack.last._library;
  }

  @override
  InterfaceType? get thisType {
    assert(_contextStack.isNotEmpty,
        "No this type currently associated with StaticTypeContext.");
    return _contextStack.last._thisType;
  }

  @override
  Nullability get nonNullable => _library.nonNullable;

  @override
  Nullability get nullable => _library.nullable;

  @override
  NonNullableByDefaultCompiledMode get nonNullableByDefaultCompiledMode =>
      _library.nonNullableByDefaultCompiledMode;

  /// Updates the [library] and [thisType] to match static type context for
  /// the member [node].
  ///
  /// This should be called before computing static types on the body of member
  /// [node].
  @override
  void enterMember(Member node) {
    _contextStack.add(new _StaticTypeContextState(
        node,
        node.enclosingLibrary,
        node.enclosingClass?.getThisType(
            typeEnvironment.coreTypes, node.enclosingLibrary.nonNullable)));
  }

  /// Reverts the [library] and [thisType] values to the previous state.
  ///
  /// This should be called after computing static types on the body of member
  /// [node].
  @override
  void leaveMember(Member node) {
    _StaticTypeContextState state = _contextStack.removeLast();
    assert(
        state._node == node,
        "Inconsistent static type context stack: "
        "Trying to leave $node but current is ${state._node}.");
  }

  /// Updates the [library] and [thisType] to match static type context for
  /// the library [node].
  ///
  /// This should be called before computing static types on annotations in the
  /// library [node].
  @override
  void enterLibrary(Library node) {
    _contextStack.add(new _StaticTypeContextState(node, node, null));
  }

  /// Reverts the [library] and [thisType] values to the previous state.
  ///
  /// This should be called after computing static types on annotations in the
  /// library [node].
  @override
  void leaveLibrary(Library node) {
    _StaticTypeContextState state = _contextStack.removeLast();
    assert(
        state._node == node,
        "Inconsistent static type context stack: "
        "Trying to leave $node but current is ${state._node}.");
  }

  @override
  DartType getExpressionType(Expression node) =>
      node.getStaticTypeInternal(this);

  @override
  DartType getForInIteratorType(ForInStatement node) =>
      node.getIteratorTypeInternal(this);

  @override
  DartType getForInElementType(ForInStatement node) =>
      node.getElementTypeInternal(this);
}

class _StaticTypeContextState {
  final TreeNode _node;
  final Library _library;
  final InterfaceType? _thisType;

  _StaticTypeContextState(this._node, this._library, this._thisType);
}

/// Describes whether only performing a shape check is sufficient for a
/// successful type check.
///
/// In the following code, in expression `a is B<num>` it is sufficient just to
/// check that the value stored in `a` has the shape `B<_>`, and the checks of
/// the type arguments can be omitted. In contrast, in expression `a is B<int>`
/// the check of the type arguments can't be skipped.
///
///   class A<X> {}
///   class B<Y> extends A<Y> {}
///
///   test(A<num> a) {
///     a is B<num>;
///     a is B<int>;
///   }
enum TypeShapeCheckSufficiency {
  /// Indicates that only the shape of the interface type needs to be checked.
  interfaceShape,

  /// Indicates that only the shape of the record type needs to be checked.
  recordShape,

  /// Indicates that only the shape of the function type needs to be checked.
  functionShape,

  /// Indicates that only the shape of the FutureOr type needs to be checked.
  futureOrShape,

  /// Indicates that a shape check is insufficient, and the full check is
  /// required.
  insufficient;
}
