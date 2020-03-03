// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.type_environment;

import 'ast.dart';
import 'class_hierarchy.dart';
import 'core_types.dart';
import 'type_algebra.dart';

import 'src/future_or.dart';
import 'src/hierarchy_based_type_environment.dart'
    show HierarchyBasedTypeEnvironment;

typedef void ErrorHandler(TreeNode node, String message);

abstract class TypeEnvironment extends SubtypeTester {
  final CoreTypes coreTypes;

  /// An error handler for use in debugging, or `null` if type errors should not
  /// be tolerated.  See [typeError].
  ErrorHandler errorHandler;

  TypeEnvironment.fromSubclass(this.coreTypes);

  factory TypeEnvironment(CoreTypes coreTypes, ClassHierarchy hierarchy) {
    return new HierarchyBasedTypeEnvironment(coreTypes, hierarchy);
  }

  Class get intClass => coreTypes.intClass;
  Class get numClass => coreTypes.numClass;
  Class get functionClass => coreTypes.functionClass;
  Class get futureOrClass => coreTypes.futureOrClass;
  Class get objectClass => coreTypes.objectClass;

  InterfaceType get objectLegacyRawType => coreTypes.objectLegacyRawType;
  InterfaceType get objectNullableRawType => coreTypes.objectNullableRawType;
  InterfaceType get nullType => coreTypes.nullType;
  InterfaceType get functionLegacyRawType => coreTypes.functionLegacyRawType;

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

  /// Returns the type `Stream<E>` with the given [nullability] and [type]
  /// as `E`.
  InterfaceType streamType(DartType type, Nullability nullability) {
    return new InterfaceType(
        coreTypes.streamClass, nullability, <DartType>[type]);
  }

  /// Returns the type `Future<E>` with the given [nullability] and [type]
  /// as `E`.
  InterfaceType futureType(DartType type, Nullability nullability) {
    return new InterfaceType(
        coreTypes.futureClass, nullability, <DartType>[type]);
  }

  /// Removes a level of `Future<>` types wrapping a type.
  ///
  /// This implements the function `flatten` from the spec, which unwraps a
  /// layer of Future or FutureOr from a type.
  DartType unfutureType(DartType type) {
    if (type is InterfaceType) {
      if (type.classNode == coreTypes.futureOrClass ||
          type.classNode == coreTypes.futureClass) {
        return type.typeArguments[0];
      }
      // It is a compile-time error to implement, extend, or mixin FutureOr so
      // we aren't concerned with it.  If a class implements multiple
      // instantiations of Future, getTypeAsInstanceOf is responsible for
      // picking the least one in the sense required by the spec.
      List<DartType> futureArguments =
          getTypeArgumentsAsInstanceOf(type, coreTypes.futureClass);
      if (futureArguments != null) {
        return futureArguments[0];
      }
    }
    return type;
  }

  /// Returns the type of the element in the for-in statement [node] with
  /// [iterableType] as the static type of the iterable expression.
  ///
  /// The [iterableType] must be a subclass of `Stream` or `Iterable` depending
  /// on whether `node.isAsync` is `true` or not.
  DartType forInElementType(ForInStatement node, DartType iterableType) {
    // TODO(johnniwinther): Update this to use the type of
    //  `iterable.iterator.current` if inference is updated accordingly.
    while (iterableType is TypeParameterType) {
      TypeParameterType typeParameterType = iterableType;
      iterableType =
          typeParameterType.promotedBound ?? typeParameterType.parameter.bound;
    }
    if (node.isAsync) {
      List<DartType> typeArguments =
          getTypeArgumentsAsInstanceOf(iterableType, coreTypes.streamClass);
      return typeArguments.single;
    } else {
      List<DartType> typeArguments =
          getTypeArgumentsAsInstanceOf(iterableType, coreTypes.iterableClass);
      return typeArguments.single;
    }
  }

  /// Called if the computation of a static type failed due to a type error.
  ///
  /// This should never happen in production.  The frontend should report type
  /// errors, and either recover from the error during translation or abort
  /// compilation if unable to recover.
  ///
  /// By default, this throws an exception, since programs in kernel are assumed
  /// to be correctly typed.
  ///
  /// An [errorHandler] may be provided in order to override the default
  /// behavior and tolerate the presence of type errors.  This can be useful for
  /// debugging IR producers which are required to produce a strongly typed IR.
  void typeError(TreeNode node, String message) {
    if (errorHandler != null) {
      errorHandler(node, message);
    } else {
      throw '$message in $node';
    }
  }

  /// True if [member] is a binary operator that returns an `int` if both
  /// operands are `int`, and otherwise returns `double`.
  ///
  /// This is a case of type-based overloading, which in Dart is only supported
  /// by giving special treatment to certain arithmetic operators.
  bool isOverloadedArithmeticOperator(Procedure member) {
    Class class_ = member.enclosingClass;
    if (class_ == coreTypes.intClass || class_ == coreTypes.numClass) {
      String name = member.name.name;
      return name == '+' ||
          name == '-' ||
          name == '*' ||
          name == 'remainder' ||
          name == '%';
    }
    return false;
  }

  /// Returns the static return type of an overloaded arithmetic operator
  /// (see [isOverloadedArithmeticOperator]) given the static type of the
  /// operands.
  ///
  /// If both types are `int`, the returned type is `int`.
  /// If either type is `double`, the returned type is `double`.
  /// If both types refer to the same type variable (typically with `num` as
  /// the upper bound), then that type variable is returned.
  /// Otherwise `num` is returned.
  DartType getTypeOfOverloadedArithmetic(DartType type1, DartType type2) {
    if (type1 == type2) return type1;

    if (type1 is InterfaceType && type2 is InterfaceType) {
      if (type1.classNode == type2.classNode) {
        return type1;
      }
      if (type1.classNode == coreTypes.doubleClass ||
          type2.classNode == coreTypes.doubleClass) {
        return coreTypes.doubleRawType(type1.nullability);
      }
    }

    return coreTypes.numRawType(type1.nullability);
  }

  /// Returns the possibly abstract interface member of [class_] with the given
  /// [name].
  ///
  /// If [setter] is `false`, only fields, methods, and getters with that name
  /// will be found.  If [setter] is `true`, only non-final fields and setters
  /// will be found.
  ///
  /// If multiple members with that name are inherited and not overridden, the
  /// member from the first declared supertype is returned.
  Member getInterfaceMember(Class cls, Name name, {bool setter: false});
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
    null, // Deliberately left empty because there's no index value for that.
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

  const IsSubtypeOf._internal(int value) : _value = value;

  /// Subtype check succeeds in both modes.
  const IsSubtypeOf.always() : this._internal(_valueAlways);

  /// Subtype check succeeds only if the nullability markers are ignored.
  ///
  /// It is assumed that if a subtype check succeeds for two types in full-NNBD
  /// mode, it also succeeds for those two types if the nullability markers on
  /// the types and all of their sub-terms are ignored (that is, in the pre-NNBD
  /// mode).  By contraposition, if a subtype check fails for two types when the
  /// nullability markers are ignored, it should also fail for those types in
  /// full-NNBD mode.
  const IsSubtypeOf.onlyIfIgnoringNullabilities()
      : this._internal(_valueOnlyIfIgnoringNullabilities);

  /// Subtype check fails in both modes.
  const IsSubtypeOf.never() : this._internal(_valueNever);

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
      DartType subtype, DartType supertype, Class futureOrClass) {
    if (subtype is InvalidType) {
      if (supertype is InvalidType) {
        return const IsSubtypeOf.always();
      }
      return const IsSubtypeOf.onlyIfIgnoringNullabilities();
    }
    if (supertype is InvalidType) {
      return const IsSubtypeOf.onlyIfIgnoringNullabilities();
    }

    if (subtype.isPotentiallyNullable && supertype.isPotentiallyNonNullable) {
      // It's a special case to test X% <: X%, FutureOr<X%> <: FutureOr<X%>,
      // FutureOr<FutureOr<X%>> <: FutureOr<FutureOr<X%>>, etc, where X is a
      // type parameter.  In that case, the nullabilities of the subtype and the
      // supertype are related, that is, they are both nullable or non-nullable
      // at run time.
      if (computeNullability(subtype, futureOrClass) ==
              Nullability.undetermined &&
          computeNullability(supertype, futureOrClass) ==
              Nullability.undetermined) {
        DartType unwrappedSubtype = subtype;
        DartType unwrappedSupertype = supertype;
        while (unwrappedSubtype is InterfaceType &&
            unwrappedSubtype.classNode == futureOrClass) {
          unwrappedSubtype =
              (unwrappedSubtype as InterfaceType).typeArguments.single;
        }
        while (unwrappedSupertype is InterfaceType &&
            unwrappedSupertype.classNode == futureOrClass) {
          unwrappedSupertype =
              (unwrappedSupertype as InterfaceType).typeArguments.single;
        }
        if (unwrappedSubtype is TypeParameterType &&
            unwrappedSubtype.promotedBound == null &&
            unwrappedSupertype is TypeParameterType &&
            unwrappedSupertype.promotedBound == null &&
            unwrappedSubtype.parameter == unwrappedSupertype.parameter) {
          return const IsSubtypeOf.always();
        }
      }
      return const IsSubtypeOf.onlyIfIgnoringNullabilities();
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
    return _all[_andValues(_value, other._value)];
  }

  /// Shorts the computation of [and] if `this` is [IsSubtypeOf.never].
  ///
  /// Use this instead of [and] for optimization in case the argument to [and]
  /// is, for example, a potentially expensive subtype check.  Unlike [and],
  /// [andSubtypeCheckFor] will immediately return if `this` was constructed as
  /// [IsSubtypeOf.never] because the right-hand side will not change the
  /// overall result anyway.
  IsSubtypeOf andSubtypeCheckFor(
      DartType subtype, DartType supertype, SubtypeTester tester) {
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
    return _all[_orValues(_value, other._value)];
  }

  /// Shorts the computation of [or] if `this` is [IsSubtypeOf.always].
  ///
  /// Use this instead of [or] for optimization in case the argument to [or] is,
  /// for example, a potentially expensive subtype check.  Unlike [or],
  /// [orSubtypeCheckFor] will immediately return if `this` was constructed
  /// as [IsSubtypeOf.always] because the right-hand side will not change the
  /// overall result anyway.
  IsSubtypeOf orSubtypeCheckFor(
      DartType subtype, DartType supertype, SubtypeTester tester) {
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
}

enum SubtypeCheckMode {
  withNullabilities,
  ignoringNullabilities,
}

/// The part of [TypeEnvironment] that deals with subtype tests.
///
/// This lives in a separate class so it can be tested independently of the SDK.
abstract class SubtypeTester {
  InterfaceType get objectLegacyRawType;
  InterfaceType get objectNullableRawType;
  InterfaceType get nullType;
  InterfaceType get functionLegacyRawType;
  Class get objectClass;
  Class get functionClass;
  Class get futureOrClass;
  InterfaceType futureType(DartType type, Nullability nullability);

  static List<Object> typeChecks;

  InterfaceType getTypeAsInstanceOf(InterfaceType type, Class superclass,
      Library clientLibrary, CoreTypes coreTypes);

  List<DartType> getTypeArgumentsAsInstanceOf(
      InterfaceType type, Class superclass);

  /// Determines if the given type is at the top of the type hierarchy.  May be
  /// overridden in subclasses.
  bool isTop(DartType type) {
    return type is DynamicType ||
        type is VoidType ||
        type == objectLegacyRawType ||
        type == objectNullableRawType;
  }

  /// Can be use to collect type checks. To use:
  /// 1. Rename `isSubtypeOf` to `_isSubtypeOf`.
  /// 2. Rename `_collect_isSubtypeOf` to `isSubtypeOf`.
  /// 3. Comment out the call to `_isSubtypeOf` below.
  // ignore:unused_element
  bool _collect_isSubtypeOf(
      DartType subtype, DartType supertype, SubtypeCheckMode mode) {
    bool result = true;
    //result = _isSubtypeOf(subtype, supertype, mode);
    typeChecks ??= <Object>[];
    typeChecks.add([subtype, supertype, result]);
    return result;
  }

  /// Returns true if [subtype] is a subtype of [supertype].
  bool isSubtypeOf(
      DartType subtype, DartType supertype, SubtypeCheckMode mode) {
    IsSubtypeOf result =
        performNullabilityAwareSubtypeCheck(subtype, supertype);
    switch (mode) {
      case SubtypeCheckMode.ignoringNullabilities:
        return result.isSubtypeWhenIgnoringNullabilities();
      case SubtypeCheckMode.withNullabilities:
        return result.isSubtypeWhenUsingNullabilities();
      default:
        throw new StateError("Unhandled subtype checking mode '$mode'");
    }
  }

  /// Performs a nullability-aware subtype check.
  ///
  /// The outcome is described in the comments to [IsSubtypeOf].
  IsSubtypeOf performNullabilityAwareSubtypeCheck(
      DartType subtype, DartType supertype) {
    subtype = subtype.unalias;
    supertype = supertype.unalias;
    if (identical(subtype, supertype)) return const IsSubtypeOf.always();
    if (subtype is BottomType) return const IsSubtypeOf.always();
    if (subtype is NeverType) {
      return supertype is BottomType
          ? const IsSubtypeOf.never()
          : new IsSubtypeOf.basedSolelyOnNullabilities(
              subtype, supertype, futureOrClass);
    }
    if (subtype == nullType) {
      // TODO(dmitryas): Remove InvalidType from subtype relation.
      if (supertype is InvalidType) {
        // The return value is supposed to keep the backward compatibility.
        return const IsSubtypeOf.always();
      }

      Nullability supertypeNullability =
          computeNullability(supertype, futureOrClass);
      if (supertypeNullability == Nullability.nullable ||
          supertypeNullability == Nullability.legacy) {
        return const IsSubtypeOf.always();
      }
      // See rule 4 of the subtype rules from the Dart Language Specification.
      return supertype is BottomType || supertype is NeverType
          ? const IsSubtypeOf.never()
          : const IsSubtypeOf.onlyIfIgnoringNullabilities();
    }
    if (isTop(supertype)) return const IsSubtypeOf.always();

    // Handle FutureOr<T> union type.
    if (subtype is InterfaceType &&
        identical(subtype.classNode, futureOrClass)) {
      var subtypeArg = subtype.typeArguments[0];
      if (supertype is InterfaceType &&
          identical(supertype.classNode, futureOrClass)) {
        DartType supertypeArg = supertype.typeArguments[0];
        Nullability subtypeNullability =
            computeNullabilityOfFutureOr(subtype, futureOrClass);
        Nullability supertypeNullability =
            computeNullabilityOfFutureOr(supertype, futureOrClass);
        // The following is an optimized is-subtype-of test for the case where
        // both LHS and RHS are FutureOrs.  It's based on the following:
        // FutureOr<X> <: FutureOr<Y> iff X <: Y OR (X <: Future<Y> AND
        // Future<X> <: Y).
        //
        // The correctness of that can be shown as follows:
        //   1. FutureOr<X> <: Y iff X <: Y AND Future<X> <: Y
        //   2. X <: FutureOr<Y> iff X <: Y OR X <: Future<Y>
        //   3. 1,2 => FutureOr<X> <: FutureOr<Y> iff
        //          (X <: Y OR X <: Future<Y>) AND
        //            (Future<X> <: Y OR Future<X> <: Future<Y>)
        //   4. X <: Y iff Future<X> <: Future<Y>
        //   5. 3,4 => FutureOr<X> <: FutureOr<Y> iff
        //          (X <: Y OR X <: Future<Y>) AND
        //            (X <: Y OR Future<X> <: Y) iff
        //          X <: Y OR (X <: Future<Y> AND Future<X> <: Y)
        return performNullabilityAwareSubtypeCheck(subtypeArg, supertypeArg)
            .or(performNullabilityAwareSubtypeCheck(subtypeArg,
                    futureType(supertypeArg, Nullability.nonNullable))
                .andSubtypeCheckFor(
                    futureType(subtypeArg, Nullability.nonNullable),
                    supertypeArg,
                    this))
            .and(new IsSubtypeOf.basedSolelyOnNullabilities(
                subtype.withNullability(subtypeNullability),
                supertype.withNullability(supertypeNullability),
                futureOrClass));
      }

      // given t1 is Future<A> | A, then:
      // (Future<A> | A) <: t2 iff Future<A> <: t2 and A <: t2.
      return performNullabilityAwareSubtypeCheck(subtypeArg, supertype)
          .andSubtypeCheckFor(
              futureType(subtypeArg, Nullability.nonNullable), supertype, this)
          .and(new IsSubtypeOf.basedSolelyOnNullabilities(
              subtype, supertype, futureOrClass));
    }

    if (supertype is InterfaceType && supertype.classNode == objectClass) {
      assert(supertype.nullability == Nullability.nonNullable);
      return new IsSubtypeOf.basedSolelyOnNullabilities(
          subtype, supertype, futureOrClass);
    }

    if (supertype is InterfaceType &&
        identical(supertype.classNode, futureOrClass)) {
      // given t2 is Future<A> | A, then:
      // t1 <: (Future<A> | A) iff t1 <: Future<A> or t1 <: A
      Nullability unitedNullability =
          computeNullabilityOfFutureOr(supertype, futureOrClass);
      DartType supertypeArg = supertype.typeArguments[0];
      DartType supertypeFuture = futureType(supertypeArg, unitedNullability);
      return performNullabilityAwareSubtypeCheck(subtype, supertypeFuture)
          .orSubtypeCheckFor(
              subtype, supertypeArg.withNullability(unitedNullability), this);
    }

    if (subtype is InterfaceType && supertype is InterfaceType) {
      Class supertypeClass = supertype.classNode;
      List<DartType> upcastTypeArguments =
          getTypeArgumentsAsInstanceOf(subtype, supertypeClass);
      if (upcastTypeArguments == null) return const IsSubtypeOf.never();
      IsSubtypeOf result = const IsSubtypeOf.always();
      for (int i = 0; i < upcastTypeArguments.length; ++i) {
        // Termination: the 'supertype' parameter decreases in size.
        int variance = supertypeClass.typeParameters[i].variance;
        DartType leftType = upcastTypeArguments[i];
        DartType rightType = supertype.typeArguments[i];
        if (variance == Variance.contravariant) {
          result = result
              .and(performNullabilityAwareSubtypeCheck(rightType, leftType));
          if (!result.isSubtypeWhenIgnoringNullabilities()) {
            return const IsSubtypeOf.never();
          }
        } else if (variance == Variance.invariant) {
          result = result.and(
              performNullabilityAwareMutualSubtypesCheck(leftType, rightType));
          if (!result.isSubtypeWhenIgnoringNullabilities()) {
            return const IsSubtypeOf.never();
          }
        } else {
          result = result
              .and(performNullabilityAwareSubtypeCheck(leftType, rightType));
          if (!result.isSubtypeWhenIgnoringNullabilities()) {
            return const IsSubtypeOf.never();
          }
        }
      }
      return result.and(new IsSubtypeOf.basedSolelyOnNullabilities(
          subtype, supertype, futureOrClass));
    }
    if (subtype is TypeParameterType) {
      if (supertype is TypeParameterType) {
        IsSubtypeOf result = const IsSubtypeOf.always();
        if (subtype.parameter == supertype.parameter) {
          if (supertype.promotedBound != null) {
            return performNullabilityAwareSubtypeCheck(
                    subtype,
                    new TypeParameterType(supertype.parameter,
                        supertype.typeParameterTypeNullability))
                .andSubtypeCheckFor(subtype, supertype.bound, this);
          } else {
            // Promoted bound should always be a subtype of the declared bound.
            // TODO(dmitryas): Use the following assertion when type promotion
            // is updated.
            // assert(subtype.promotedBound == null ||
            //     performNullabilityAwareSubtypeCheck(
            //         subtype.bound, supertype.bound)
            //         .isSubtypeWhenUsingNullabilities());
            assert(subtype.promotedBound == null ||
                performNullabilityAwareSubtypeCheck(
                        subtype.bound, supertype.bound)
                    .isSubtypeWhenIgnoringNullabilities());
            result = const IsSubtypeOf.always();
          }
        } else {
          result =
              performNullabilityAwareSubtypeCheck(subtype.bound, supertype);
        }
        if (subtype.nullability == Nullability.undetermined &&
            supertype.nullability == Nullability.undetermined) {
          // The two nullabilities are undetermined, but are connected via
          // additional constraint, namely that they will be equal at run time.
          return result;
        }
        return result.and(new IsSubtypeOf.basedSolelyOnNullabilities(
            subtype, supertype, futureOrClass));
      }
      // Termination: if there are no cyclically bound type parameters, this
      // recursive call can only occur a finite number of times, before reaching
      // a shrinking recursive call (or terminating).
      return performNullabilityAwareSubtypeCheck(subtype.bound, supertype).and(
          new IsSubtypeOf.basedSolelyOnNullabilities(
              subtype, supertype, futureOrClass));
    }
    if (subtype is FunctionType) {
      if (supertype is InterfaceType && supertype.classNode == functionClass) {
        return new IsSubtypeOf.basedSolelyOnNullabilities(
            subtype, supertype, futureOrClass);
      }
      if (supertype is FunctionType) {
        return _performNullabilityAwareFunctionSubtypeCheck(subtype, supertype);
      }
    }
    return const IsSubtypeOf.never();
  }

  IsSubtypeOf performNullabilityAwareMutualSubtypesCheck(
      DartType type1, DartType type2) {
    // TODO(dmitryas): Replace it with one recursive descent instead of two.
    return performNullabilityAwareSubtypeCheck(type1, type2)
        .andSubtypeCheckFor(type2, type1, this);
  }

  IsSubtypeOf _performNullabilityAwareFunctionSubtypeCheck(
      FunctionType subtype, FunctionType supertype) {
    if (subtype.requiredParameterCount > supertype.requiredParameterCount) {
      return const IsSubtypeOf.never();
    }
    if (subtype.positionalParameters.length <
        supertype.positionalParameters.length) {
      return const IsSubtypeOf.never();
    }
    if (subtype.typeParameters.length != supertype.typeParameters.length) {
      return const IsSubtypeOf.never();
    }

    IsSubtypeOf result = const IsSubtypeOf.always();
    if (subtype.typeParameters.isNotEmpty) {
      var substitution = <TypeParameter, DartType>{};
      for (int i = 0; i < subtype.typeParameters.length; ++i) {
        var subParameter = subtype.typeParameters[i];
        var superParameter = supertype.typeParameters[i];
        substitution[subParameter] = new TypeParameterType.forAlphaRenaming(
            subParameter, superParameter);
      }
      for (int i = 0; i < subtype.typeParameters.length; ++i) {
        var subParameter = subtype.typeParameters[i];
        var superParameter = supertype.typeParameters[i];
        var subBound = substitute(subParameter.bound, substitution);
        // Termination: if there are no cyclically bound type parameters, this
        // recursive call can only occur a finite number of times before
        // reaching a shrinking recursive call (or terminating).
        result = result.and(performNullabilityAwareMutualSubtypesCheck(
            superParameter.bound, subBound));
        if (!result.isSubtypeWhenIgnoringNullabilities()) {
          return const IsSubtypeOf.never();
        }
      }
      subtype = substitute(subtype.withoutTypeParameters, substitution);
    }
    result = result.and(performNullabilityAwareSubtypeCheck(
        subtype.returnType, supertype.returnType));
    if (!result.isSubtypeWhenIgnoringNullabilities()) {
      return const IsSubtypeOf.never();
    }
    for (int i = 0; i < supertype.positionalParameters.length; ++i) {
      var supertypeParameter = supertype.positionalParameters[i];
      var subtypeParameter = subtype.positionalParameters[i];
      // Termination: Both types shrink in size.
      result = result.and(performNullabilityAwareSubtypeCheck(
          supertypeParameter, subtypeParameter));
      if (!result.isSubtypeWhenIgnoringNullabilities()) {
        return const IsSubtypeOf.never();
      }
    }
    int subtypeNameIndex = 0;
    for (NamedType supertypeParameter in supertype.namedParameters) {
      while (subtypeNameIndex < subtype.namedParameters.length &&
          subtype.namedParameters[subtypeNameIndex].name !=
              supertypeParameter.name) {
        ++subtypeNameIndex;
      }
      if (subtypeNameIndex == subtype.namedParameters.length) {
        return const IsSubtypeOf.never();
      }
      NamedType subtypeParameter = subtype.namedParameters[subtypeNameIndex];
      // Termination: Both types shrink in size.
      result = result.and(performNullabilityAwareSubtypeCheck(
          supertypeParameter.type, subtypeParameter.type));
      if (!result.isSubtypeWhenIgnoringNullabilities()) {
        return const IsSubtypeOf.never();
      }
    }
    return result.and(new IsSubtypeOf.basedSolelyOnNullabilities(
        subtype, supertype, futureOrClass));
  }
}

/// Context object needed for computing `Expression.getStaticType`.
///
/// The [StaticTypeContext] provides access to the [TypeEnvironment] and the
/// current 'this type' as well as determining the nullability state of the
/// enclosing library.
// TODO(johnniwinther): Support static type caching through [StaticTypeContext].
class StaticTypeContext {
  /// The [TypeEnvironment] used for the static type computation.
  ///
  /// This provides access to the core types and the class hierarchy.
  final TypeEnvironment typeEnvironment;

  /// The library in which the static type is computed.
  ///
  /// The `library.isNonNullableByDefault` property is used to determine the
  /// nullabilities of the static types.
  final Library _library;

  /// The static type of a `this` expression.
  final InterfaceType thisType;

  /// Creates a static type context for computing static types in the body
  /// of [member].
  StaticTypeContext(Member member, this.typeEnvironment)
      : _library = member.enclosingLibrary,
        thisType = member.enclosingClass?.getThisType(
            typeEnvironment.coreTypes, member.enclosingLibrary.nonNullable);

  /// Creates a static type context for computing static types of annotations
  /// in [library].
  StaticTypeContext.forAnnotations(this._library, this.typeEnvironment)
      : thisType = null;

  /// The [Nullability] used for non-nullable types.
  ///
  /// For opt out libraries this is [Nullability.legacy].
  Nullability get nonNullable => _library.nonNullable;

  /// The [Nullability] used for nullable types.
  ///
  /// For opt out libraries this is [Nullability.legacy].
  Nullability get nullable => _library.nullable;

  /// Return `true` if the current library is opted in to non-nullable by
  /// default.
  bool get isNonNullableByDefault => _library.isNonNullableByDefault;

  /// Returns the mode under which the current library was compiled.
  NonNullableByDefaultCompiledMode get nonNullableByDefaultCompiledMode =>
      _library.nonNullableByDefaultCompiledMode;
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
  Library _currentLibrary;
  Member _currentMember;

  _FlatStatefulStaticTypeContext(TypeEnvironment typeEnvironment)
      : super._internal(typeEnvironment);

  @override
  Library get _library {
    Library library = _currentLibrary ?? _currentMember?.enclosingLibrary;
    assert(library != null,
        "No library currently associated with StaticTypeContext.");
    return library;
  }

  @override
  InterfaceType get thisType {
    assert(_currentMember != null,
        "No member currently associated with StaticTypeContext.");
    return _currentMember?.enclosingClass?.getThisType(
        typeEnvironment.coreTypes, _currentMember.enclosingLibrary.nonNullable);
  }

  @override
  Nullability get nonNullable => _library?.nonNullable;

  @override
  Nullability get nullable => _library?.nullable;

  @override
  bool get isNonNullableByDefault => _library.isNonNullableByDefault;

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
}

/// Implementation of [StatefulStaticTypeContext] that use a stack to change
/// state when entering and leaving libraries and members.
class _StackedStatefulStaticTypeContext extends StatefulStaticTypeContext {
  final List<_StaticTypeContextState> _contextStack =
      <_StaticTypeContextState>[];

  _StackedStatefulStaticTypeContext(TypeEnvironment typeEnvironment)
      : super._internal(typeEnvironment);

  @override
  Library get _library {
    assert(_contextStack.isNotEmpty,
        "No library currently associated with StaticTypeContext.");
    return _contextStack.last._library;
  }

  @override
  InterfaceType get thisType {
    assert(_contextStack.isNotEmpty,
        "No this type currently associated with StaticTypeContext.");
    return _contextStack.last._thisType;
  }

  @override
  Nullability get nonNullable => _library?.nonNullable;

  @override
  Nullability get nullable => _library?.nullable;

  @override
  bool get isNonNullableByDefault => _library?.isNonNullableByDefault;

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
}

class _StaticTypeContextState {
  final TreeNode _node;
  final Library _library;
  final InterfaceType _thisType;

  _StaticTypeContextState(this._node, this._library, this._thisType);
}
