// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.type_environment;

import 'package:kernel/type_algebra.dart';

import 'ast.dart';
import 'class_hierarchy.dart';
import 'core_types.dart';

import 'src/hierarchy_based_type_environment.dart'
    show HierarchyBasedTypeEnvironment;
import 'src/types.dart';

typedef void ErrorHandler(TreeNode node, String message);

abstract class TypeEnvironment extends Types {
  final CoreTypes coreTypes;

  /// An error handler for use in debugging, or `null` if type errors should not
  /// be tolerated.  See [typeError].
  ErrorHandler errorHandler;

  TypeEnvironment.fromSubclass(this.coreTypes, ClassHierarchyBase base)
      : super(base);

  factory TypeEnvironment(CoreTypes coreTypes, ClassHierarchy hierarchy) {
    return new HierarchyBasedTypeEnvironment(coreTypes, hierarchy);
  }

  Class get intClass => coreTypes.intClass;
  Class get numClass => coreTypes.numClass;
  Class get functionClass => coreTypes.functionClass;
  Class get objectClass => coreTypes.objectClass;

  InterfaceType get objectLegacyRawType => coreTypes.objectLegacyRawType;
  InterfaceType get objectNullableRawType => coreTypes.objectNullableRawType;
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

  DartType _withDeclaredNullability(DartType type, Nullability nullability) {
    if (type is NullType) return type;
    return type.withDeclaredNullability(
        uniteNullabilities(type.declaredNullability, nullability));
  }

  /// Returns the `flatten` of [type] as defined in the spec, which unwraps a
  /// layer of Future or FutureOr from a type.
  DartType flatten(DartType t) {
    // if T is S? then flatten(T) = flatten(S)?
    // otherwise if T is S* then flatten(T) = flatten(S)*
    // -- this is preserve with the calls to [_withDeclaredNullability] below.

    // otherwise if T is FutureOr<S> then flatten(T) = S
    if (t is FutureOrType) {
      return _withDeclaredNullability(t.typeArgument, t.declaredNullability);
    }

    // otherwise if T <: Future then let S be a type such that T <: Future<S>
    //   and for all R, if T <: Future<R> then S <: R; then flatten(T) = S
    DartType resolved = _resolveTypeParameterType(t);
    if (resolved is InterfaceType) {
      List<DartType> futureArguments =
          getTypeArgumentsAsInstanceOf(resolved, coreTypes.futureClass);
      if (futureArguments != null) {
        return _withDeclaredNullability(
            futureArguments.single, t.declaredNullability);
      }
    }

    // otherwise flatten(T) = T
    return t;
  }

  /// Returns the non-type parameter type bound of [type].
  DartType _resolveTypeParameterType(DartType type) {
    while (type is TypeParameterType) {
      TypeParameterType typeParameterType = type;
      type =
          typeParameterType.promotedBound ?? typeParameterType.parameter.bound;
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
    iterableType = _resolveTypeParameterType(iterableType);
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

  /// True if [member] is a binary operator whose return type is defined by
  /// the both operand types.
  bool isSpecialCasedBinaryOperator(Procedure member,
      {bool isNonNullableByDefault: false}) {
    if (isNonNullableByDefault) {
      Class class_ = member.enclosingClass;
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
    } else {
      Class class_ = member.enclosingClass;
      if (class_ == coreTypes.intClass || class_ == coreTypes.numClass) {
        String name = member.name.text;
        return name == '+' ||
            name == '-' ||
            name == '*' ||
            name == 'remainder' ||
            name == '%';
      }
    }
    return false;
  }

  /// True if [member] is a ternary operator whose return type is defined by
  /// the least upper bound of the operand types.
  bool isSpecialCasedTernaryOperator(Procedure member,
      {bool isNonNullableByDefault: false}) {
    if (isNonNullableByDefault) {
      Class class_ = member.enclosingClass;
      if (class_ == coreTypes.intClass || class_ == coreTypes.numClass) {
        String name = member.name.text;
        return name == 'clamp';
      }
    }
    return false;
  }

  /// Returns the static return type of a special cased binary operator
  /// (see [isSpecialCasedBinaryOperator]) given the static type of the
  /// operands.
  DartType getTypeOfSpecialCasedBinaryOperator(DartType type1, DartType type2,
      {bool isNonNullableByDefault: false}) {
    if (isNonNullableByDefault) {
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
    } else {
      type1 = _resolveTypeParameterType(type1);
      type2 = _resolveTypeParameterType(type2);

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
  }

  DartType getTypeOfSpecialCasedTernaryOperator(
      DartType type1, DartType type2, DartType type3, Library clientLibrary) {
    if (clientLibrary.isNonNullableByDefault) {
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

  final DartType subtype;

  final DartType supertype;

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
      {DartType subtype, DartType supertype})
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
          unwrappedSubtype = (unwrappedSubtype as FutureOrType).typeArgument;
        }
        while (unwrappedSupertype is FutureOrType) {
          unwrappedSupertype =
              (unwrappedSupertype as FutureOrType).typeArgument;
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

abstract class StaticTypeCache {
  DartType getExpressionType(Expression node, StaticTypeContext context);

  DartType getForInIteratorType(ForInStatement node, StaticTypeContext context);

  DartType getForInElementType(ForInStatement node, StaticTypeContext context);
}

class StaticTypeCacheImpl implements StaticTypeCache {
  Map<Expression, DartType> _expressionTypes;
  Map<ForInStatement, DartType> _forInIteratorTypes;
  Map<ForInStatement, DartType> _forInElementTypes;

  DartType getExpressionType(Expression node, StaticTypeContext context) {
    _expressionTypes ??= <Expression, DartType>{};
    return _expressionTypes[node] ??= node.getStaticTypeInternal(context);
  }

  DartType getForInIteratorType(
      ForInStatement node, StaticTypeContext context) {
    _forInIteratorTypes ??= <ForInStatement, DartType>{};
    return _forInIteratorTypes[node] ??= node.getIteratorTypeInternal(context);
  }

  DartType getForInElementType(ForInStatement node, StaticTypeContext context) {
    _forInElementTypes ??= <ForInStatement, DartType>{};
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
  InterfaceType get thisType;

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

  /// Return `true` if the current library is opted in to non-nullable by
  /// default.
  bool get isNonNullableByDefault;

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
  final TypeEnvironment typeEnvironment;

  /// The library in which the static type is computed.
  ///
  /// The `library.isNonNullableByDefault` property is used to determine the
  /// nullabilities of the static types.
  final Library _library;

  /// The static type of a `this` expression.
  final InterfaceType thisType;

  final StaticTypeCache _cache;

  /// Creates a static type context for computing static types in the body
  /// of [member].
  StaticTypeContextImpl(Member member, this.typeEnvironment,
      {StaticTypeCache cache})
      : _library = member.enclosingLibrary,
        thisType = member.enclosingClass?.getThisType(
            typeEnvironment.coreTypes, member.enclosingLibrary.nonNullable),
        _cache = cache;

  /// Creates a static type context for computing static types of annotations
  /// in [library].
  StaticTypeContextImpl.forAnnotations(this._library, this.typeEnvironment,
      {StaticTypeCache cache})
      : thisType = null,
        _cache = cache;

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

  DartType getExpressionType(Expression node) {
    if (_cache != null) {
      return _cache.getExpressionType(node, this);
    } else {
      return node.getStaticTypeInternal(this);
    }
  }

  DartType getForInIteratorType(ForInStatement node) {
    if (_cache != null) {
      return _cache.getForInIteratorType(node, this);
    } else {
      return node.getIteratorTypeInternal(this);
    }
  }

  DartType getForInElementType(ForInStatement node) {
    if (_cache != null) {
      return _cache.getForInElementType(node, this);
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
  Library _currentLibrary;
  Member _currentMember;

  _FlatStatefulStaticTypeContext(TypeEnvironment typeEnvironment)
      : super._internal(typeEnvironment);

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
  final InterfaceType _thisType;

  _StaticTypeContextState(this._node, this._library, this._thisType);
}
