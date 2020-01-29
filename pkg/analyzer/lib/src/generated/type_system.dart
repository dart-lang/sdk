// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:analyzer/dart/ast/ast.dart' show AstNode, ConstructorName;
import 'package:analyzer/dart/ast/token.dart' show Keyword, TokenType;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart' as public;
import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:analyzer/src/dart/element/display_string_builder.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart' show TypeParameterMember;
import 'package:analyzer/src/dart/element/normalize.dart';
import 'package:analyzer/src/dart/element/nullability_eliminator.dart';
import 'package:analyzer/src/dart/element/top_merge.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_schema_elimination.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/error/codes.dart' show HintCode, StrongModeCode;
import 'package:analyzer/src/generated/utilities_dart.dart' show ParameterKind;
import 'package:meta/meta.dart';

bool _isBottom(DartType t) {
  return (t.isBottom && t.nullabilitySuffix != NullabilitySuffix.question) ||
      identical(t, UnknownInferredType.instance);
}

/// Is [t] the bottom of the legacy type hierarchy.
bool _isLegacyBottom(DartType t, {@required bool orTrueBottom}) {
  return (t.isBottom && t.nullabilitySuffix == NullabilitySuffix.question) ||
      t.isDartCoreNull ||
      (orTrueBottom ? _isBottom(t) : false);
}

/// Is [t] the top of the legacy type hierarch.
bool _isLegacyTop(DartType t, {@required bool orTrueTop}) {
  if (t.isDartAsyncFutureOr) {
    return _isLegacyTop((t as InterfaceType).typeArguments[0],
        orTrueTop: orTrueTop);
  }
  if (t.isObject && t.nullabilitySuffix == NullabilitySuffix.none) {
    return true;
  }
  return orTrueTop ? _isTop(t) : false;
}

bool _isTop(DartType t) {
  if (t.isDartAsyncFutureOr) {
    return _isTop((t as InterfaceType).typeArguments[0]);
  }
  return t.isDynamic ||
      (t.isObject && t.nullabilitySuffix != NullabilitySuffix.none) ||
      t.isVoid ||
      identical(t, UnknownInferredType.instance);
}

/**
 * A type system that implements the type semantics for Dart 2.0.
 *
 * TODO(scheglov) Merge it into TypeSystemImpl.
 */
class Dart2TypeSystem extends TypeSystem {
  /**
   * False if implicit casts should always be disallowed.
   *
   * This affects the behavior of [isAssignableTo].
   */
  final bool implicitCasts;

  /// A flag indicating whether inference failures are allowed, off by default.
  ///
  /// This option is experimental and subject to change.
  final bool strictInference;

  @override
  final TypeProvider typeProvider;

  /// The cached instance of `Object?`.
  InterfaceTypeImpl _objectQuestionCached;

  /// The cached instance of `Object!`.
  InterfaceTypeImpl _objectNoneCached;

  /// The cached instance of `Null!`.
  InterfaceTypeImpl _nullNoneCached;

  Dart2TypeSystem({
    @required this.implicitCasts,
    @required bool isNonNullableByDefault,
    @required this.strictInference,
    @required this.typeProvider,
  }) : super(isNonNullableByDefault: isNonNullableByDefault);

  InterfaceTypeImpl get nullNone =>
      _nullNoneCached ??= (typeProvider.nullType as TypeImpl)
          .withNullability(NullabilitySuffix.none);

  InterfaceTypeImpl get objectNone =>
      _objectNoneCached ??= (typeProvider.objectType as TypeImpl)
          .withNullability(NullabilitySuffix.none);

  InterfaceTypeImpl get objectQuestion =>
      _objectQuestionCached ??= (typeProvider.objectType as TypeImpl)
          .withNullability(NullabilitySuffix.question);

  InterfaceType get _interfaceTypeFunctionNone {
    return typeProvider.functionType.element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  /// Returns true iff the type [t] accepts function types, and requires an
  /// implicit coercion if interface types with a `call` method are passed in.
  ///
  /// This is true for:
  /// - all function types
  /// - the special type `Function` that is a supertype of all function types
  /// - `FutureOr<T>` where T is one of the two cases above.
  ///
  /// Note that this returns false if [t] is a top type such as Object.
  bool acceptsFunctionType(DartType t) {
    if (t == null) return false;
    if (t.isDartAsyncFutureOr) {
      return acceptsFunctionType((t as InterfaceType).typeArguments[0]);
    }
    return t is FunctionType || t.isDartCoreFunction;
  }

  bool anyParameterType(FunctionType ft, bool Function(DartType t) predicate) {
    return ft.parameters.any((p) => predicate(p.type));
  }

  /// Given a type t, if t is an interface type with a call method
  /// defined, return the function type for the call method, otherwise
  /// return null.
  FunctionType getCallMethodType(DartType t) {
    if (t is InterfaceType) {
      return t.lookUpMethod2('call', t.element.library)?.type;
    }
    return null;
  }

  /// Computes the greatest lower bound of [T1] and [T2].
  DartType getGreatestLowerBound(DartType T1, DartType T2) {
    // DOWN(T, T) = T
    if (identical(T1, T2)) {
      return T1;
    }

    // For any type T, DOWN(?, T) == T.
    if (identical(T1, UnknownInferredType.instance)) {
      return T2;
    }
    if (identical(T2, UnknownInferredType.instance)) {
      return T1;
    }

    var T1_isTop = isTop(T1);
    var T2_isTop = isTop(T2);

    // DOWN(T1, T2) where TOP(T1) and TOP(T2)
    if (T1_isTop && T2_isTop) {
      // * T1 if MORETOP(T2, T1)
      // * T2 otherwise
      if (isMoreTop(T2, T1)) {
        return T1;
      } else {
        return T2;
      }
    }

    // DOWN(T1, T2) = T2 if TOP(T1)
    if (T1_isTop) {
      return T2;
    }

    // DOWN(T1, T2) = T1 if TOP(T2)
    if (T2_isTop) {
      return T1;
    }

    var T1_isBottom = isBottom(T1);
    var T2_isBottom = isBottom(T2);

    // DOWN(T1, T2) where BOTTOM(T1) and BOTTOM(T2)
    if (T1_isBottom && T2_isBottom) {
      // * T1 if MOREBOTTOM(T1, T2)
      // * T2 otherwise
      if (isMoreBottom(T1, T2)) {
        return T1;
      } else {
        return T2;
      }
    }

    // DOWN(T1, T2) = T1 if BOTTOM(T1)
    if (T1_isBottom) {
      return T1;
    }

    // DOWN(T1, T2) = T2 if BOTTOM(T2)
    if (T2_isBottom) {
      return T2;
    }

    var T1_isNull = isNull(T1);
    var T2_isNull = isNull(T2);

    // DOWN(T1, T2) where NULL(T1) and NULL(T2)
    if (T1_isNull && T2_isNull) {
      // * T1 if MOREBOTTOM(T1, T2)
      // * T2 otherwise
      if (isMoreBottom(T1, T2)) {
        return T1;
      } else {
        return T2;
      }
    }

    var T1_impl = T1 as TypeImpl;
    var T2_impl = T2 as TypeImpl;

    var T1_nullability = T1_impl.nullabilitySuffix;
    var T2_nullability = T2_impl.nullabilitySuffix;

    // DOWN(Null, T2)
    if (T1_nullability == NullabilitySuffix.none && T1.isDartCoreNull) {
      // * Null if Null <: T2
      // * Never otherwise
      if (isSubtypeOf(nullNone, T2)) {
        return nullNone;
      } else {
        return NeverTypeImpl.instance;
      }
    }

    // DOWN(T1, Null)
    if (T2_nullability == NullabilitySuffix.none && T2.isDartCoreNull) {
      // * Null if Null <: T1
      // * Never otherwise
      if (isSubtypeOf(nullNone, T1)) {
        return nullNone;
      } else {
        return NeverTypeImpl.instance;
      }
    }

    var T1_isObject = isObject(T1);
    var T2_isObject = isObject(T2);

    // DOWN(T1, T2) where OBJECT(T1) and OBJECT(T2)
    if (T1_isObject && T2_isObject) {
      // * T1 if MORETOP(T2, T1)
      // * T2 otherwise
      if (isMoreTop(T2, T1)) {
        return T1;
      } else {
        return T2;
      }
    }

    // DOWN(T1, T2) where OBJECT(T1)
    if (T1_isObject) {
      // * T2 if T2 is non-nullable
      if (isNonNullable(T2)) {
        return T2;
      }

      // * NonNull(T2) if NonNull(T2) is non-nullable
      var T2_nonNull = promoteToNonNull(T2_impl);
      if (isNonNullable(T2_nonNull)) {
        return T2_nonNull;
      }

      // * Never otherwise
      return NeverTypeImpl.instance;
    }

    // DOWN(T1, T2) where OBJECT(T2)
    if (T2_isObject) {
      // * T1 if T1 is non-nullable
      if (isNonNullable(T1)) {
        return T1;
      }

      // * NonNull(T1) if NonNull(T1) is non-nullable
      var T1_nonNull = promoteToNonNull(T1_impl);
      if (isNonNullable(T1_nonNull)) {
        return T1_nonNull;
      }

      // * Never otherwise
      return NeverTypeImpl.instance;
    }

    // DOWN(T1*, T2*) = S* where S is DOWN(T1, T2)
    // DOWN(T1*, T2?) = S* where S is DOWN(T1, T2)
    // DOWN(T1?, T2*) = S* where S is DOWN(T1, T2)
    // DOWN(T1*, T2) = S where S is DOWN(T1, T2)
    // DOWN(T1, T2*) = S where S is DOWN(T1, T2)
    // DOWN(T1?, T2?) = S? where S is DOWN(T1, T2)
    // DOWN(T1?, T2) = S where S is DOWN(T1, T2)
    // DOWN(T1, T2?) = S where S is DOWN(T1, T2)
    if (T1_nullability != NullabilitySuffix.none ||
        T2_nullability != NullabilitySuffix.none) {
      var resultNullability = NullabilitySuffix.question;
      if (T1_nullability == NullabilitySuffix.none ||
          T2_nullability == NullabilitySuffix.none) {
        resultNullability = NullabilitySuffix.none;
      } else if (T1_nullability == NullabilitySuffix.star ||
          T2_nullability == NullabilitySuffix.star) {
        resultNullability = NullabilitySuffix.star;
      }
      var T1_none = T1_impl.withNullability(NullabilitySuffix.none);
      var T2_none = T2_impl.withNullability(NullabilitySuffix.none);
      var S = getGreatestLowerBound(T1_none, T2_none);
      return (S as TypeImpl).withNullability(resultNullability);
    }

    assert(T1_nullability == NullabilitySuffix.none);
    assert(T2_nullability == NullabilitySuffix.none);

    // TODO(scheglov) incomplete
    if (T1 is FunctionType && T2 is FunctionType) {
      return _functionGreatestLowerBound(T1, T2);
    }

    // DOWN(T1, T2) = T1 if T1 <: T2
    if (isSubtypeOf(T1, T2)) {
      return T1;
    }

    // DOWN(T1, T2) = T2 if T2 <: T1
    if (isSubtypeOf(T2, T1)) {
      return T2;
    }

    // DOWN(T1, T2) = Never otherwise
    return NeverTypeImpl.instance;
  }

  /**
   * Compute the least upper bound of two types.
   *
   * https://github.com/dart-lang/language
   * See `resources/type-system/upper-lower-bounds.md`
   */
  @override
  DartType getLeastUpperBound(DartType T1, DartType T2) {
    // UP(T, T) = T
    if (identical(T1, T2)) {
      return T1;
    }

    // For any type T, UP(?, T) == T.
    if (identical(T1, UnknownInferredType.instance)) {
      return T2;
    }
    if (identical(T2, UnknownInferredType.instance)) {
      return T1;
    }

    var T1_isTop = isTop(T1);
    var T2_isTop = isTop(T2);

    // UP(T1, T2) where TOP(T1) and TOP(T2)
    if (T1_isTop && T2_isTop) {
      // * T1 if MORETOP(T1, T2)
      // * T2 otherwise
      if (isMoreTop(T1, T2)) {
        return T1;
      } else {
        return T2;
      }
    }

    // UP(T1, T2) = T1 if TOP(T1)
    if (T1_isTop) {
      return T1;
    }

    // UP(T1, T2) = T2 if TOP(T2)
    if (T2_isTop) {
      return T2;
    }

    var T1_isBottom = isBottom(T1);
    var T2_isBottom = isBottom(T2);

    // UP(T1, T2) where BOTTOM(T1) and BOTTOM(T2)
    if (T1_isBottom && T2_isBottom) {
      // * T2 if MOREBOTTOM(T1, T2)
      // * T1 otherwise
      if (isMoreBottom(T1, T2)) {
        return T2;
      } else {
        return T1;
      }
    }

    // UP(T1, T2) = T2 if BOTTOM(T1)
    if (T1_isBottom) {
      return T2;
    }

    // UP(T1, T2) = T1 if BOTTOM(T2)
    if (T2_isBottom) {
      return T1;
    }

    var T1_isNull = isNull(T1);
    var T2_isNull = isNull(T2);

    // UP(T1, T2) where NULL(T1) and NULL(T2)
    if (T1_isNull && T2_isNull) {
      // * T2 if MOREBOTTOM(T1, T2)
      // * T1 otherwise
      if (isMoreBottom(T1, T2)) {
        return T2;
      } else {
        return T1;
      }
    }

    var T1_impl = T1 as TypeImpl;
    var T2_impl = T2 as TypeImpl;

    var T1_nullability = T1_impl.nullabilitySuffix;
    var T2_nullability = T2_impl.nullabilitySuffix;

    // UP(T1, T2) where NULL(T1)
    if (T1_isNull) {
      // * T2 if T2 is nullable
      // * T2* if Null <: T2 or T1 <: Object (that is, T1 or T2 is legacy)
      // * T2? otherwise
      if (isNullable(T2)) {
        return T2;
      } else if (T1_nullability == NullabilitySuffix.star ||
          T2_nullability == NullabilitySuffix.star) {
        return T2_impl.withNullability(NullabilitySuffix.star);
      } else {
        return makeNullable(T2);
      }
    }

    // UP(T1, T2) where NULL(T2)
    if (T2_isNull) {
      // * T1 if T1 is nullable
      // * T1* if Null <: T1 or T2 <: Object (that is, T1 or T2 is legacy)
      // * T1? otherwise
      if (isNullable(T1)) {
        return T1;
      } else if (T1_nullability == NullabilitySuffix.star ||
          T2_nullability == NullabilitySuffix.star) {
        return T1_impl.withNullability(NullabilitySuffix.star);
      } else {
        return makeNullable(T1);
      }
    }

    var T1_isObject = isObject(T1);
    var T2_isObject = isObject(T2);

    // UP(T1, T2) where OBJECT(T1) and OBJECT(T2)
    if (T1_isObject && T2_isObject) {
      // * T1 if MORETOP(T1, T2)
      // * T2 otherwise
      if (isMoreTop(T1, T2)) {
        return T1;
      } else {
        return T2;
      }
    }

    // UP(T1, T2) where OBJECT(T1)
    if (T1_isObject) {
      // * T1 if T2 is non-nullable
      // * T1? otherwise
      if (isNonNullable(T2)) {
        return T1;
      } else {
        return makeNullable(T1);
      }
    }

    // UP(T1, T2) where OBJECT(T2)
    if (T2_isObject) {
      // * T2 if T1 is non-nullable
      // * T2? otherwise
      if (isNonNullable(T1)) {
        return T2;
      } else {
        return makeNullable(T2);
      }
    }

    // UP(T1*, T2*) = S* where S is UP(T1, T2)
    // UP(T1*, T2?) = S? where S is UP(T1, T2)
    // UP(T1?, T2*) = S? where S is UP(T1, T2)
    // UP(T1*, T2) = S* where S is UP(T1, T2)
    // UP(T1, T2*) = S* where S is UP(T1, T2)
    // UP(T1?, T2?) = S? where S is UP(T1, T2)
    // UP(T1?, T2) = S? where S is UP(T1, T2)
    // UP(T1, T2?) = S? where S is UP(T1, T2)
    if (T1_nullability != NullabilitySuffix.none ||
        T2_nullability != NullabilitySuffix.none) {
      var resultNullability = NullabilitySuffix.none;
      if (T1_nullability == NullabilitySuffix.question ||
          T2_nullability == NullabilitySuffix.question) {
        resultNullability = NullabilitySuffix.question;
      } else if (T1_nullability == NullabilitySuffix.star ||
          T2_nullability == NullabilitySuffix.star) {
        resultNullability = NullabilitySuffix.star;
      }
      var T1_none = T1_impl.withNullability(NullabilitySuffix.none);
      var T2_none = T2_impl.withNullability(NullabilitySuffix.none);
      var S = getLeastUpperBound(T1_none, T2_none);
      return (S as TypeImpl).withNullability(resultNullability);
    }

    assert(T1_nullability == NullabilitySuffix.none);
    assert(T2_nullability == NullabilitySuffix.none);

    // UP(X1 extends B1, T2)
    // UP(X1 & B1, T2)
    if (T1 is TypeParameterType) {
      // T2 if X1 <: T2
      if (isSubtypeOf(T1, T2)) {
        return T2;
      }
      // otherwise X1 if T2 <: X1
      if (isSubtypeOf(T2, T1)) {
        return T1;
      }
      // otherwise UP(B1[Object/X1], T2)
      var T1_toObject = _typeParameterResolveToObjectBounds(T1);
      return getLeastUpperBound(T1_toObject, T2);
    }

    // UP(T1, X2 extends B2)
    // UP(T1, X2 & B2)
    if (T2 is TypeParameterType) {
      // X2 if T1 <: X2
      if (isSubtypeOf(T1, T2)) {
        // TODO(scheglov) How to get here?
        return T2;
      }
      // otherwise T1 if X2 <: T1
      if (isSubtypeOf(T2, T1)) {
        return T1;
      }
      // otherwise UP(T1, B2[Object/X2])
      var T2_toObject = _typeParameterResolveToObjectBounds(T2);
      return getLeastUpperBound(T1, T2_toObject);
    }

    // UP(T Function<...>(...), Function) = Function
    if (T1 is FunctionType && T2.isDartCoreFunction) {
      return T2;
    }

    // UP(Function, T Function<...>(...)) = Function
    if (T1.isDartCoreFunction && T2 is FunctionType) {
      return T1;
    }

    // UP(T Function<...>(...), S Function<...>(...)) = Function
    // And other, more interesting variants.
    if (T1 is FunctionType && T2 is FunctionType) {
      return _functionLeastUpperBound(T1, T2);
    }

    // UP(T Function<...>(...), T2) = Object
    // UP(T1, T Function<...>(...)) = Object
    if (T1 is FunctionType || T2 is FunctionType) {
      return objectNone;
    }

    // UP(T1, T2) = T2 if T1 <: T2
    // UP(T1, T2) = T1 if T2 <: T1
    // And other, more complex variants of interface types.
    var helper = InterfaceLeastUpperBoundHelper(this);
    return helper.compute(T1, T2);
  }

  /**
   * Given a generic function type `F<T0, T1, ... Tn>` and a context type C,
   * infer an instantiation of F, such that `F<S0, S1, ..., Sn>` <: C.
   *
   * This is similar to [inferGenericFunctionOrType], but the return type is
   * also considered as part of the solution.
   *
   * If this function is called with a [contextType] that is also
   * uninstantiated, or a [fnType] that is already instantiated, it will have
   * no effect and return `null`.
   */
  List<DartType> inferFunctionTypeInstantiation(
      FunctionType contextType, FunctionType fnType,
      {ErrorReporter errorReporter, AstNode errorNode}) {
    if (contextType.typeFormals.isNotEmpty || fnType.typeFormals.isEmpty) {
      return const <DartType>[];
    }

    // Create a TypeSystem that will allow certain type parameters to be
    // inferred. It will optimistically assume these type parameters can be
    // subtypes (or supertypes) as necessary, and track the constraints that
    // are implied by this.
    var inferrer = GenericInferrer(this, fnType.typeFormals);
    inferrer.constrainGenericFunctionInContext(fnType, contextType);

    // Infer and instantiate the resulting type.
    return inferrer.infer(
      fnType.typeFormals,
      errorReporter: errorReporter,
      errorNode: errorNode,
    );
  }

  /// Infers type arguments for a generic type, function, method, or
  /// list/map literal, using the downward context type as well as the
  /// argument types if available.
  ///
  /// For example, given a function type with generic type parameters, this
  /// infers the type parameters from the actual argument types, and returns the
  /// instantiated function type.
  ///
  /// Concretely, given a function type with parameter types P0, P1, ... Pn,
  /// result type R, and generic type parameters T0, T1, ... Tm, use the
  /// argument types A0, A1, ... An to solve for the type parameters.
  ///
  /// For each parameter Pi, we want to ensure that Ai <: Pi. We can do this by
  /// running the subtype algorithm, and when we reach a type parameter Tj,
  /// recording the lower or upper bound it must satisfy. At the end, all
  /// constraints can be combined to determine the type.
  ///
  /// All constraints on each type parameter Tj are tracked, as well as where
  /// they originated, so we can issue an error message tracing back to the
  /// argument values, type parameter "extends" clause, or the return type
  /// context.
  List<DartType> inferGenericFunctionOrType({
    ClassElement genericClass,
    @required List<TypeParameterElement> typeParameters,
    @required List<ParameterElement> parameters,
    @required DartType declaredReturnType,
    @required List<DartType> argumentTypes,
    @required DartType contextReturnType,
    ErrorReporter errorReporter,
    AstNode errorNode,
    bool downwards = false,
    bool isConst = false,
  }) {
    if (typeParameters.isEmpty) {
      return null;
    }

    // Create a TypeSystem that will allow certain type parameters to be
    // inferred. It will optimistically assume these type parameters can be
    // subtypes (or supertypes) as necessary, and track the constraints that
    // are implied by this.
    var inferrer = GenericInferrer(this, typeParameters);

    if (contextReturnType != null) {
      if (isConst) {
        contextReturnType = _eliminateTypeVariables(contextReturnType);
      }
      inferrer.constrainReturnType(declaredReturnType, contextReturnType);
    }

    for (int i = 0; i < argumentTypes.length; i++) {
      // Try to pass each argument to each parameter, recording any type
      // parameter bounds that were implied by this assignment.
      inferrer.constrainArgument(
        argumentTypes[i],
        parameters[i].type,
        parameters[i].name,
        genericClass: genericClass,
      );
    }

    return inferrer.infer(
      typeParameters,
      errorReporter: errorReporter,
      errorNode: errorNode,
      downwardsInferPhase: downwards,
    );
  }

  /**
   * Given a [DartType] [type], if [type] is an uninstantiated
   * parameterized type then instantiate the parameters to their
   * bounds. See the issue for the algorithm description.
   *
   * https://github.com/dart-lang/sdk/issues/27526#issuecomment-260021397
   *
   * TODO(scheglov) Move this method to elements for classes, typedefs,
   * and generic functions; compute lazily and cache.
   */
  @override
  DartType instantiateToBounds(DartType type,
      {List<bool> hasError, Map<TypeParameterElement, DartType> knownTypes}) {
    List<TypeParameterElement> typeFormals = typeFormalsAsElements(type);
    List<DartType> arguments = instantiateTypeFormalsToBounds(typeFormals,
        hasError: hasError, knownTypes: knownTypes);
    if (arguments == null) {
      return type;
    }

    return instantiateType(type, arguments);
  }

  @override
  DartType instantiateToBounds2({
    ClassElement classElement,
    FunctionTypeAliasElement functionTypeAliasElement,
    @required NullabilitySuffix nullabilitySuffix,
  }) {
    if (classElement != null) {
      var typeParameters = classElement.typeParameters;
      var typeArguments = _defaultTypeArguments(typeParameters);
      var type = classElement.instantiate(
        typeArguments: typeArguments,
        nullabilitySuffix: nullabilitySuffix,
      );
      type = toLegacyType(type);
      return type;
    } else if (functionTypeAliasElement != null) {
      var typeParameters = functionTypeAliasElement.typeParameters;
      var typeArguments = _defaultTypeArguments(typeParameters);
      var type = functionTypeAliasElement.instantiate(
        typeArguments: typeArguments,
        nullabilitySuffix: nullabilitySuffix,
      );
      type = toLegacyType(type);
      return type;
    } else {
      throw ArgumentError('Missing element');
    }
  }

  /**
   * Given uninstantiated [typeFormals], instantiate them to their bounds.
   * See the issue for the algorithm description.
   *
   * https://github.com/dart-lang/sdk/issues/27526#issuecomment-260021397
   */
  @override
  List<DartType> instantiateTypeFormalsToBounds(
      List<TypeParameterElement> typeFormals,
      {List<bool> hasError,
      Map<TypeParameterElement, DartType> knownTypes}) {
    int count = typeFormals.length;
    if (count == 0) {
      return const <DartType>[];
    }

    Set<TypeParameterElement> all = <TypeParameterElement>{};
    // all ground
    Map<TypeParameterElement, DartType> defaults = knownTypes ?? {};
    // not ground
    Map<TypeParameterElement, DartType> partials = {};

    for (TypeParameterElement typeParameter in typeFormals) {
      all.add(typeParameter);
      if (!defaults.containsKey(typeParameter)) {
        if (typeParameter.bound == null) {
          defaults[typeParameter] = DynamicTypeImpl.instance;
        } else {
          partials[typeParameter] = typeParameter.bound;
        }
      }
    }

    List<TypeParameterElement> getFreeParameters(DartType rootType) {
      List<TypeParameterElement> parameters;
      Set<DartType> visitedTypes = HashSet<DartType>();

      void appendParameters(DartType type) {
        if (type == null) {
          return;
        }
        if (visitedTypes.contains(type)) {
          return;
        }
        visitedTypes.add(type);
        if (type is TypeParameterType) {
          var element = type.element;
          if (all.contains(element)) {
            parameters ??= <TypeParameterElement>[];
            parameters.add(element);
          }
        } else {
          if (type is FunctionType) {
            appendParameters(type.returnType);
            type.parameters.map((p) => p.type).forEach(appendParameters);
          } else if (type is InterfaceType) {
            type.typeArguments.forEach(appendParameters);
          }
        }
      }

      appendParameters(rootType);
      return parameters;
    }

    bool hasProgress = true;
    while (hasProgress) {
      hasProgress = false;
      for (TypeParameterElement parameter in partials.keys) {
        DartType value = partials[parameter];
        List<TypeParameterElement> freeParameters = getFreeParameters(value);
        if (freeParameters == null) {
          defaults[parameter] = value;
          partials.remove(parameter);
          hasProgress = true;
          break;
        } else if (freeParameters.every(defaults.containsKey)) {
          defaults[parameter] =
              Substitution.fromMap(defaults).substituteType(value);
          partials.remove(parameter);
          hasProgress = true;
          break;
        }
      }
    }

    // If we stopped making progress, and not all types are ground,
    // then the whole type is malbounded and an error should be reported
    // if errors are requested, and a partially completed type should
    // be returned.
    if (partials.isNotEmpty) {
      if (hasError != null) {
        hasError[0] = true;
      }
      var domain = defaults.keys.toList();
      var range = defaults.values.toList();
      // Build a substitution Phi mapping each uncompleted type variable to
      // dynamic, and each completed type variable to its default.
      for (TypeParameterElement parameter in partials.keys) {
        domain.add(parameter);
        range.add(DynamicTypeImpl.instance);
      }
      // Set the default for an uncompleted type variable (T extends B)
      // to be Phi(B)
      for (TypeParameterElement parameter in partials.keys) {
        defaults[parameter] = Substitution.fromPairs(domain, range)
            .substituteType(partials[parameter]);
      }
    }

    List<DartType> orderedArguments =
        typeFormals.map((p) => defaults[p]).toList();
    return orderedArguments;
  }

  @override
  bool isAssignableTo(DartType fromType, DartType toType) {
    // An actual subtype
    if (isSubtypeOf(fromType, toType)) {
      return true;
    }

    // A call method tearoff
    if (fromType is InterfaceType &&
        !isNullable(fromType) &&
        acceptsFunctionType(toType)) {
      var callMethodType = getCallMethodType(fromType);
      if (callMethodType != null && isAssignableTo(callMethodType, toType)) {
        return true;
      }
    }

    // First make sure --no-implicit-casts disables all downcasts, including
    // dynamic casts.
    if (!implicitCasts) {
      return false;
    }

    // Now handle NNBD default behavior, where we disable non-dynamic downcasts.
    if (isNonNullableByDefault) {
      return fromType.isDynamic;
    }

    // Don't allow implicit downcasts between function types
    // and call method objects, as these will almost always fail.
    if (fromType is FunctionType && getCallMethodType(toType) != null) {
      return false;
    }

    // Don't allow a non-generic function where a generic one is expected. The
    // former wouldn't know how to handle type arguments being passed to it.
    // TODO(rnystrom): This same check also exists in FunctionTypeImpl.relate()
    // but we don't always reliably go through that code path. This should be
    // cleaned up to avoid the redundancy.
    if (fromType is FunctionType &&
        toType is FunctionType &&
        fromType.typeFormals.isEmpty &&
        toType.typeFormals.isNotEmpty) {
      return false;
    }

    // If the subtype relation goes the other way, allow the implicit downcast.
    if (isSubtypeOf(toType, fromType)) {
      // TODO(leafp,jmesserly): we emit warnings/hints for these in
      // src/task/strong/checker.dart, which is a bit inconsistent. That
      // code should be handled into places that use isAssignableTo, such as
      // ErrorVerifier.
      return true;
    }

    return false;
  }

  /// Return `true`  for things in the equivalence class of `Never`.
  bool isBottom(DartType type) {
    // BOTTOM(Never) is true
    if (identical(type, NeverTypeImpl.instance)) {
      return true;
    }

    // BOTTOM(X&T) is true iff BOTTOM(T)
    // BOTTOM(X extends T) is true iff BOTTOM(T)
    if (type is TypeParameterType) {
      var T = type.element.bound;
      return isBottom(T);
    }

    // BOTTOM(T) is false otherwise
    return false;
  }

  /// Defines an (almost) total order on bottom and `Null` types. This does not
  /// currently consistently order two different type variables with the same
  /// bound.
  bool isMoreBottom(DartType T, DartType S) {
    var T_impl = T as TypeImpl;
    var S_impl = S as TypeImpl;

    var T_nullability = T_impl.nullabilitySuffix;
    var S_nullability = S_impl.nullabilitySuffix;

    // MOREBOTTOM(Never, T) = true
    if (identical(T, NeverTypeImpl.instance)) {
      return true;
    }

    // MOREBOTTOM(T, Never) = false
    if (identical(S, NeverTypeImpl.instance)) {
      return false;
    }

    // MOREBOTTOM(Null, T) = true
    if (T_nullability == NullabilitySuffix.none && T.isDartCoreNull) {
      return true;
    }

    // MOREBOTTOM(T, Null) = false
    if (S_nullability == NullabilitySuffix.none && S.isDartCoreNull) {
      return false;
    }

    // MOREBOTTOM(T?, S?) = MOREBOTTOM(T, S)
    if (T_nullability == NullabilitySuffix.question &&
        S_nullability == NullabilitySuffix.question) {
      var T2 = T_impl.withNullability(NullabilitySuffix.none);
      var S2 = S_impl.withNullability(NullabilitySuffix.none);
      return isMoreBottom(T2, S2);
    }

    // MOREBOTTOM(T, S?) = true
    if (S_nullability == NullabilitySuffix.question) {
      return true;
    }

    // MOREBOTTOM(T?, S) = false
    if (T_nullability == NullabilitySuffix.question) {
      return false;
    }

    // MOREBOTTOM(T*, S*) = MOREBOTTOM(T, S)
    if (T_nullability == NullabilitySuffix.star &&
        S_nullability == NullabilitySuffix.star) {
      var T2 = T_impl.withNullability(NullabilitySuffix.none);
      var S2 = S_impl.withNullability(NullabilitySuffix.none);
      return isMoreBottom(T2, S2);
    }

    // MOREBOTTOM(T, S*) = true
    if (S_nullability == NullabilitySuffix.star) {
      return true;
    }

    // MOREBOTTOM(T*, S) = false
    if (T_nullability == NullabilitySuffix.star) {
      return false;
    }

    // Type parameters.
    if (T is TypeParameterType && S is TypeParameterType) {
      // We have eliminated the possibility that T_nullability or S_nullability
      // is anything except none by this point.
      assert(T_nullability == NullabilitySuffix.none);
      assert(S_nullability == NullabilitySuffix.none);
      var T_element = T.element;
      var S_element = S.element;
      // MOREBOTTOM(X&T, Y&S) = MOREBOTTOM(T, S)
      if (T_element is TypeParameterMember &&
          S_element is TypeParameterMember) {
        var T_bound = T_element.bound;
        var S_bound = S_element.bound;
        return isMoreBottom(T_bound, S_bound);
      }
      // MOREBOTTOM(X&T, S) = true
      if (T_element is TypeParameterMember) {
        return true;
      }
      // MOREBOTTOM(T, Y&S) = false
      if (S_element is TypeParameterMember) {
        return false;
      }
      // MOREBOTTOM(X extends T, Y extends S) = MOREBOTTOM(T, S)
      var T_bound = T_element.bound;
      var S_bound = S_element.bound;
      // The invariant of the larger algorithm that this is only called with
      // types that satisfy `BOTTOM(T)` or `NULL(T)`, and all such types, if
      // they are type variables, have bounds which themselves are
      // `BOTTOM` or `NULL` types.
      assert(T_bound != null);
      assert(S_bound != null);
      return isMoreBottom(T_bound, S_bound);
    }

    return false;
  }

  @override
  bool isMoreSpecificThan(DartType t1, DartType t2) => isSubtypeOf(t1, t2);

  /// Defines a total order on top and Object types.
  bool isMoreTop(DartType T, DartType S) {
    var T_impl = T as TypeImpl;
    var S_impl = S as TypeImpl;

    var T_nullability = T_impl.nullabilitySuffix;
    var S_nullability = S_impl.nullabilitySuffix;

    // MORETOP(void, S) = true
    if (identical(T, VoidTypeImpl.instance)) {
      return true;
    }

    // MORETOP(T, void) = false
    if (identical(S, VoidTypeImpl.instance)) {
      return false;
    }

    // MORETOP(dynamic, S) = true
    if (identical(T, DynamicTypeImpl.instance)) {
      return true;
    }

    // MORETOP(T, dynamic) = false
    if (identical(S, DynamicTypeImpl.instance)) {
      return false;
    }

    // MORETOP(Object, S) = true
    if (T_nullability == NullabilitySuffix.none && T.isDartCoreObject) {
      return true;
    }

    // MORETOP(T, Object) = false
    if (S_nullability == NullabilitySuffix.none && S.isDartCoreObject) {
      return false;
    }

    // MORETOP(T*, S*) = MORETOP(T, S)
    if (T_nullability == NullabilitySuffix.star &&
        S_nullability == NullabilitySuffix.star) {
      var T2 = T_impl.withNullability(NullabilitySuffix.none);
      var S2 = S_impl.withNullability(NullabilitySuffix.none);
      return isMoreTop(T2, S2);
    }

    // MORETOP(T, S*) = true
    if (S_nullability == NullabilitySuffix.star) {
      return true;
    }

    // MORETOP(T*, S) = false
    if (T_nullability == NullabilitySuffix.star) {
      return false;
    }

    // MORETOP(T?, S?) = MORETOP(T, S)
    if (T_nullability == NullabilitySuffix.question &&
        S_nullability == NullabilitySuffix.question) {
      var T2 = T_impl.withNullability(NullabilitySuffix.none);
      var S2 = S_impl.withNullability(NullabilitySuffix.none);
      return isMoreTop(T2, S2);
    }

    // MORETOP(T, S?) = true
    if (S_nullability == NullabilitySuffix.question) {
      return true;
    }

    // MORETOP(T?, S) = false
    if (T_nullability == NullabilitySuffix.question) {
      return false;
    }

    // MORETOP(FutureOr<T>, FutureOr<S>) = MORETOP(T, S)
    if (T is InterfaceType &&
        T.isDartAsyncFutureOr &&
        S is InterfaceType &&
        S.isDartAsyncFutureOr) {
      assert(T_nullability == NullabilitySuffix.none);
      assert(S_nullability == NullabilitySuffix.none);
      var T2 = T.typeArguments[0];
      var S2 = S.typeArguments[0];
      return isMoreTop(T2, S2);
    }

    return false;
  }

  /// Return `true` for things in the equivalence class of `Null`.
  bool isNull(DartType type) {
    var typeImpl = type as TypeImpl;
    var nullabilitySuffix = typeImpl.nullabilitySuffix;

    // NULL(Null) is true
    // Also includes `Null?` and `Null*` from the rules below.
    if (type.isDartCoreNull) {
      return true;
    }

    // NULL(T?) is true iff NULL(T) or BOTTOM(T)
    // NULL(T*) is true iff NULL(T) or BOTTOM(T)
    // Cases for `Null?` and `Null*` are already checked above.
    if (nullabilitySuffix == NullabilitySuffix.question ||
        nullabilitySuffix == NullabilitySuffix.star) {
      var T = typeImpl.withNullability(NullabilitySuffix.none);
      return isBottom(T);
    }

    // NULL(T) is false otherwise
    return false;
  }

  /// Return `true` for any type which is in the equivalence class of `Object`.
  bool isObject(DartType type) {
    TypeImpl typeImpl = type;
    if (typeImpl.nullabilitySuffix != NullabilitySuffix.none) {
      return false;
    }

    // OBJECT(Object) is true
    if (type.isDartCoreObject) {
      return true;
    }

    // OBJECT(FutureOr<T>) is OBJECT(T)
    if (type is InterfaceType && type.isDartAsyncFutureOr) {
      var T = type.typeArguments[0];
      return isObject(T);
    }

    // OBJECT(T) is false otherwise
    return false;
  }

  @override
  bool isOverrideSubtypeOf(FunctionType f1, FunctionType f2) {
    return FunctionTypeImpl.relate(f1, f2, isSubtypeOf,
        parameterRelation: isOverrideSubtypeOfParameter,
        // Type parameter bounds are invariant.
        boundsRelation: (t1, t2, p1, p2) =>
            isSubtypeOf(t1, t2) && isSubtypeOf(t2, t1));
  }

  /// Check that parameter [p2] is a subtype of [p1], given that we are
  /// checking `f1 <: f2` where `p1` is a parameter of `f1` and `p2` is a
  /// parameter of `f2`.
  ///
  /// Parameters are contravariant, so we must check `p2 <: p1` to
  /// determine if `f1 <: f2`. This is used by [isOverrideSubtypeOf].
  bool isOverrideSubtypeOfParameter(ParameterElement p1, ParameterElement p2) {
    return isSubtypeOf(p2.type, p1.type) ||
        p1.isCovariant && isSubtypeOf(p1.type, p2.type);
  }

  /// Check if [_T0] is a subtype of [_T1].
  ///
  /// Implements:
  /// https://github.com/dart-lang/language/blob/master/resources/type-system/subtyping.md#rules
  @override
  bool isSubtypeOf(DartType _T0, DartType _T1) {
    // Reflexivity: if `T0` and `T1` are the same type then `T0 <: T1`.
    if (identical(_T0, _T1)) {
      return true;
    }

    // `?` is treated as a top and a bottom type during inference.
    if (identical(_T0, UnknownInferredType.instance) ||
        identical(_T1, UnknownInferredType.instance)) {
      return true;
    }

    var T0 = _T0 as TypeImpl;
    var T1 = _T1 as TypeImpl;

    // Right Top: if `T1` is a top type (i.e. `dynamic`, or `void`, or
    // `Object?`) then `T0 <: T1`.
    if (identical(T1, DynamicTypeImpl.instance) ||
        identical(T1, VoidTypeImpl.instance) ||
        T1.nullabilitySuffix == NullabilitySuffix.question &&
            T1.isDartCoreObject) {
      return true;
    }

    // Left Top: if `T0` is `dynamic` or `void`,
    //   then `T0 <: T1` if `Object? <: T1`.
    if (identical(T0, DynamicTypeImpl.instance) ||
        identical(T0, VoidTypeImpl.instance)) {
      if (isSubtypeOf(objectQuestion, T1)) {
        return true;
      }
    }

    // Left Bottom: if `T0` is `Never`, then `T0 <: T1`.
    if (identical(T0, NeverTypeImpl.instance)) {
      return true;
    }

    // Right Object: if `T1` is `Object` then:
    var T1_nullability = T1.nullabilitySuffix;
    if (T1_nullability == NullabilitySuffix.none && T1.isDartCoreObject) {
      var T0_nullability = T0.nullabilitySuffix;
      // * if `T0` is an unpromoted type variable with bound `B`,
      //   then `T0 <: T1` iff `B <: Object`.
      // * if `T0` is a promoted type variable `X & S`,
      //   then `T0 <: T1`iff `S <: Object`.
      if (T0_nullability == NullabilitySuffix.none &&
          T0 is TypeParameterTypeImpl) {
        var bound = T0.element.bound ?? objectQuestion;
        return isSubtypeOf(bound, objectNone);
      }
      // * if `T0` is `FutureOr<S>` for some `S`,
      //   then `T0 <: T1` iff `S <: Object`
      if (T0_nullability == NullabilitySuffix.none &&
          T0 is InterfaceTypeImpl &&
          T0.isDartAsyncFutureOr) {
        return isSubtypeOf(T0.typeArguments[0], T1);
      }
      // * if `T0` is `S*` for any `S`, then `T0 <: T1` iff `S <: T1`
      if (T0_nullability == NullabilitySuffix.star) {
        return isSubtypeOf(
          T0.withNullability(NullabilitySuffix.none),
          T1,
        );
      }
      // * if `T0` is `Null`, `dynamic`, `void`, or `S?` for any `S`,
      //   then the subtyping does not hold, the result is false.
      if (T0_nullability == NullabilitySuffix.none && T0.isDartCoreNull ||
          identical(T0, DynamicTypeImpl.instance) ||
          identical(T0, VoidTypeImpl.instance) ||
          T0_nullability == NullabilitySuffix.question) {
        return false;
      }
      // Otherwise `T0 <: T1` is true.
      return true;
    }

    // Left Null: if `T0` is `Null` then:
    var T0_nullability = T0.nullabilitySuffix;
    if (T0_nullability == NullabilitySuffix.none && T0.isDartCoreNull) {
      // * If `T1` is `FutureOr<S>` for some `S`, then the query is true iff
      // `Null <: S`.
      if (T1_nullability == NullabilitySuffix.none &&
          T1 is InterfaceTypeImpl &&
          T1.isDartAsyncFutureOr) {
        var S = T1.typeArguments[0];
        return isSubtypeOf(nullNone, S);
      }
      // If `T1` is `Null`, `S?` or `S*` for some `S`, then the query is true.
      if (T1_nullability == NullabilitySuffix.none && T1.isDartCoreNull ||
          T1_nullability == NullabilitySuffix.question ||
          T1_nullability == NullabilitySuffix.star) {
        return true;
      }
      // * if `T1` is a type variable (promoted or not) the query is false
      if (T1 is TypeParameterTypeImpl) {
        return false;
      }
      // Otherwise, the query is false.
      return false;
    }

    // Left Legacy if `T0` is `S0*` then:
    if (T0_nullability == NullabilitySuffix.star) {
      // * `T0 <: T1` iff `S0 <: T1`.
      var S0 = T0.withNullability(NullabilitySuffix.none);
      return isSubtypeOf(S0, T1);
    }

    // Right Legacy `T1` is `S1*` then:
    //   * `T0 <: T1` iff `T0 <: S1?`.
    if (T1_nullability == NullabilitySuffix.star) {
      var S1 = T1.withNullability(NullabilitySuffix.question);
      return isSubtypeOf(T0, S1);
    }

    // Left FutureOr: if `T0` is `FutureOr<S0>` then:
    if (T0_nullability == NullabilitySuffix.none &&
        T0 is InterfaceTypeImpl &&
        T0.isDartAsyncFutureOr) {
      var S0 = T0.typeArguments[0];
      // * `T0 <: T1` iff `Future<S0> <: T1` and `S0 <: T1`
      if (isSubtypeOf(S0, T1)) {
        var FutureS0 = typeProvider.futureElement.instantiate(
          typeArguments: [S0],
          nullabilitySuffix: NullabilitySuffix.none,
        );
        return isSubtypeOf(FutureS0, T1);
      }
      return false;
    }

    // Left Nullable: if `T0` is `S0?` then:
    //   * `T0 <: T1` iff `S0 <: T1` and `Null <: T1`.
    if (T0_nullability == NullabilitySuffix.question) {
      var S0 = T0.withNullability(NullabilitySuffix.none);
      return isSubtypeOf(S0, T1) && isSubtypeOf(nullNone, T1);
    }

    // Right Promoted Variable: if `T1` is a promoted type variable `X1 & S1`:
    //   * `T0 <: T1` iff `T0 <: X1` and `T0 <: S1`
    if (T0 is TypeParameterTypeImpl) {
      if (T1 is TypeParameterTypeImpl && T0.definition == T1.definition) {
        var S0 = T0.element.bound ?? objectQuestion;
        var S1 = T1.element.bound ?? objectQuestion;
        if (isSubtypeOf(S0, S1)) {
          return true;
        }
      }

      var T0_element = T0.element;
      if (T0_element is TypeParameterMember) {
        return isSubtypeOf(T0_element.bound, T1);
      }
    }

    // Right FutureOr: if `T1` is `FutureOr<S1>` then:
    if (T1_nullability == NullabilitySuffix.none &&
        T1 is InterfaceTypeImpl &&
        T1.isDartAsyncFutureOr) {
      var S1 = T1.typeArguments[0];
      // `T0 <: T1` iff any of the following hold:
      // * either `T0 <: Future<S1>`
      var FutureS1 = typeProvider.futureElement.instantiate(
        typeArguments: [S1],
        nullabilitySuffix: NullabilitySuffix.none,
      );
      if (isSubtypeOf(T0, FutureS1)) {
        return true;
      }
      // * or `T0 <: S1`
      if (isSubtypeOf(T0, S1)) {
        return true;
      }
      // * or `T0` is `X0` and `X0` has bound `S0` and `S0 <: T1`
      // * or `T0` is `X0 & S0` and `S0 <: T1`
      if (T0 is TypeParameterTypeImpl) {
        var S0 = T0.element.bound ?? objectQuestion;
        if (isSubtypeOf(S0, T1)) {
          return true;
        }
      }
      // iff
      return false;
    }

    // Right Nullable: if `T1` is `S1?` then:
    if (T1_nullability == NullabilitySuffix.question) {
      var S1 = T1.withNullability(NullabilitySuffix.none);
      // `T0 <: T1` iff any of the following hold:
      // * either `T0 <: S1`
      if (isSubtypeOf(T0, S1)) {
        return true;
      }
      // * or `T0 <: Null`
      if (isSubtypeOf(T0, nullNone)) {
        return true;
      }
      // or `T0` is `X0` and `X0` has bound `S0` and `S0 <: T1`
      // or `T0` is `X0 & S0` and `S0 <: T1`
      if (T0 is TypeParameterTypeImpl) {
        var S0 = T0.element.bound ?? objectQuestion;
        return isSubtypeOf(S0, T1);
      }
      // iff
      return false;
    }

    // Super-Interface: `T0` is an interface type with super-interfaces
    // `S0,...Sn`:
    //   * and `Si <: T1` for some `i`.
    if (T0 is InterfaceTypeImpl && T1 is InterfaceTypeImpl) {
      return _isInterfaceSubtypeOf(T0, T1, null);
    }

    // Left Promoted Variable: `T0` is a promoted type variable `X0 & S0`
    //   * and `S0 <: T1`
    // Left Type Variable Bound: `T0` is a type variable `X0` with bound `B0`
    //   * and `B0 <: T1`
    if (T0 is TypeParameterTypeImpl) {
      var S0 = T0.element.bound ?? objectQuestion;
      if (isSubtypeOf(S0, T1)) {
        return true;
      }
    }

    if (T0 is FunctionTypeImpl) {
      // Function Type/Function: `T0` is a function type and `T1` is `Function`.
      if (T1.isDartCoreFunction) {
        return true;
      }
      if (T1 is FunctionTypeImpl) {
        return _isFunctionSubtypeOf(T0, T1);
      }
    }

    return false;
  }

  /// Return `true` for any type which is in the equivalence class of top types.
  bool isTop(DartType type) {
    // TOP(?) is true
    if (identical(type, UnknownInferredType.instance)) {
      return true;
    }

    // TOP(dynamic) is true
    if (identical(type, DynamicTypeImpl.instance)) {
      return true;
    }

    // TOP(void) is true
    if (identical(type, VoidTypeImpl.instance)) {
      return true;
    }

    var typeImpl = type as TypeImpl;
    var nullabilitySuffix = typeImpl.nullabilitySuffix;

    // TOP(T?) is true iff TOP(T) or OBJECT(T)
    // TOP(T*) is true iff TOP(T) or OBJECT(T)
    if (nullabilitySuffix == NullabilitySuffix.question ||
        nullabilitySuffix == NullabilitySuffix.star) {
      var T = typeImpl.withNullability(NullabilitySuffix.none);
      return isTop(T) || isObject(T);
    }

    // TOP(FutureOr<T>) is TOP(T)
    if (type is InterfaceType && type.isDartAsyncFutureOr) {
      assert(nullabilitySuffix == NullabilitySuffix.none);
      var T = type.typeArguments[0];
      return isTop(T);
    }

    // TOP(T) is false otherwise
    return false;
  }

  /**
   * Compute the canonical representation of [T].
   *
   * https://github.com/dart-lang/language
   * See `resources/type-system/normalization.md`
   */
  DartType normalize(DartType T) {
    return NormalizeHelper(this).normalize(T);
  }

  @override
  DartType refineBinaryExpressionType(DartType leftType, TokenType operator,
      DartType rightType, DartType currentType) {
    if (leftType is TypeParameterType && leftType.bound.isDartCoreNum) {
      if (rightType == leftType || rightType.isDartCoreInt) {
        if (operator == TokenType.PLUS ||
            operator == TokenType.MINUS ||
            operator == TokenType.STAR ||
            operator == TokenType.PLUS_EQ ||
            operator == TokenType.MINUS_EQ ||
            operator == TokenType.STAR_EQ) {
          if (isNonNullableByDefault) {
            return promoteToNonNull(leftType as TypeImpl);
          }
          return leftType;
        }
      }
      if (rightType.isDartCoreDouble) {
        if (operator == TokenType.PLUS ||
            operator == TokenType.MINUS ||
            operator == TokenType.STAR ||
            operator == TokenType.SLASH) {
          InterfaceTypeImpl doubleType = typeProvider.doubleType;
          if (isNonNullableByDefault) {
            return promoteToNonNull(doubleType);
          }
          return doubleType;
        }
      }
      return currentType;
    }
    return super
        .refineBinaryExpressionType(leftType, operator, rightType, currentType);
  }

  DartType toLegacyType(DartType type) {
    if (isNonNullableByDefault) return type;
    return NullabilityEliminator.perform(typeProvider, type);
  }

  /**
   * Merges two types into a single type.
   * Compute the canonical representation of [T].
   *
   * https://github.com/dart-lang/language/
   * See `accepted/future-releases/nnbd/feature-specification.md`
   * See `#classes-defined-in-opted-in-libraries`
   */
  DartType topMerge(DartType T, DartType S) {
    return TopMergeHelper(this).topMerge(T, S);
  }

  @override
  DartType tryPromoteToType(DartType to, DartType from) {
    // Allow promoting to a subtype, for example:
    //
    //     f(Base b) {
    //       if (b is SubTypeOfBase) {
    //         // promote `b` to SubTypeOfBase for this block
    //       }
    //     }
    //
    // This allows the variable to be used wherever the supertype (here `Base`)
    // is expected, while gaining a more precise type.
    if (isSubtypeOf(to, from)) {
      return to;
    }
    // For a type parameter `T extends U`, allow promoting the upper bound
    // `U` to `S` where `S <: U`, yielding a type parameter `T extends S`.
    if (from is TypeParameterType) {
      if (isSubtypeOf(to, from.bound ?? DynamicTypeImpl.instance)) {
        var declaration = from.element.declaration;
        var newElement = TypeParameterMember(declaration, null, to);
        return newElement.instantiate(
          nullabilitySuffix: from.nullabilitySuffix,
        );
      }
    }

    return null;
  }

  List<DartType> _defaultTypeArguments(
    List<TypeParameterElement> typeParameters,
  ) {
    return typeParameters.map((typeParameter) {
      var typeParameterImpl = typeParameter as TypeParameterElementImpl;
      return typeParameterImpl.defaultType;
    }).toList();
  }

  /**
   * Eliminates type variables from the context [type], replacing them with
   * `Null` or `Object` as appropriate.
   *
   * For example in `List<T> list = const []`, the context type for inferring
   * the list should be changed from `List<T>` to `List<Null>` so the constant
   * doesn't depend on the type variables `T` (because it can't be canonicalized
   * at compile time, as `T` is unknown).
   *
   * Conceptually this is similar to the "least closure", except instead of
   * eliminating `?` ([UnknownInferredType]) it eliminates all type variables
   * ([TypeParameterType]).
   *
   * The equivalent CFE code can be found in the `TypeVariableEliminator` class.
   */
  DartType _eliminateTypeVariables(DartType type) {
    return TypeVariableEliminator(typeProvider).substituteType(type);
  }

  /**
   * Compute the greatest lower bound of function types [f] and [g].
   *
   * https://github.com/dart-lang/language
   * See `resources/type-system/upper-lower-bounds.md`
   */
  DartType _functionGreatestLowerBound(FunctionType f, FunctionType g) {
    var fTypeFormals = f.typeFormals;
    var gTypeFormals = g.typeFormals;

    // The number of type parameters must be the same.
    // Otherwise the result is `Never`.
    if (fTypeFormals.length != gTypeFormals.length) {
      return NeverTypeImpl.instance;
    }

    // The bounds of type parameters must be equal.
    // Otherwise the result is `Never`.
    var freshTypeFormalTypes =
        FunctionTypeImpl.relateTypeFormals(f, g, (t, s, _, __) => t == s);
    if (freshTypeFormalTypes == null) {
      return NeverTypeImpl.instance;
    }

    var typeFormals = freshTypeFormalTypes
        .map<TypeParameterElement>((t) => t.element)
        .toList();

    f = f.instantiate(freshTypeFormalTypes);
    g = g.instantiate(freshTypeFormalTypes);

    var fParameters = f.parameters;
    var gParameters = g.parameters;

    var parameters = <ParameterElement>[];
    var fIndex = 0;
    var gIndex = 0;
    while (fIndex < fParameters.length && gIndex < gParameters.length) {
      var fParameter = fParameters[fIndex];
      var gParameter = gParameters[gIndex];
      if (fParameter.isPositional) {
        if (gParameter.isPositional) {
          fIndex++;
          gIndex++;
          parameters.add(
            ParameterElementImpl.synthetic(
              fParameter.name,
              getLeastUpperBound(fParameter.type, gParameter.type),
              fParameter.isOptional || gParameter.isOptional
                  ? ParameterKind.POSITIONAL
                  : ParameterKind.REQUIRED,
            ),
          );
        } else {
          return NeverTypeImpl.instance;
        }
      } else if (fParameter.isNamed) {
        if (gParameter.isNamed) {
          var compareNames = fParameter.name.compareTo(gParameter.name);
          if (compareNames == 0) {
            fIndex++;
            gIndex++;
            parameters.add(
              ParameterElementImpl.synthetic(
                fParameter.name,
                getLeastUpperBound(fParameter.type, gParameter.type),
                fParameter.isRequiredNamed && gParameter.isRequiredNamed
                    ? ParameterKind.NAMED_REQUIRED
                    : ParameterKind.NAMED,
              ),
            );
          } else if (compareNames < 0) {
            fIndex++;
            parameters.add(
              ParameterElementImpl.synthetic(
                fParameter.name,
                fParameter.type,
                ParameterKind.NAMED,
              ),
            );
          } else {
            assert(compareNames > 0);
            gIndex++;
            parameters.add(
              ParameterElementImpl.synthetic(
                gParameter.name,
                gParameter.type,
                ParameterKind.NAMED,
              ),
            );
          }
        } else {
          return NeverTypeImpl.instance;
        }
      }
    }

    while (fIndex < fParameters.length) {
      var fParameter = fParameters[fIndex++];
      if (fParameter.isPositional) {
        parameters.add(
          ParameterElementImpl.synthetic(
            fParameter.name,
            fParameter.type,
            ParameterKind.POSITIONAL,
          ),
        );
      } else {
        assert(fParameter.isNamed);
        parameters.add(
          ParameterElementImpl.synthetic(
            fParameter.name,
            fParameter.type,
            ParameterKind.NAMED,
          ),
        );
      }
    }

    while (gIndex < gParameters.length) {
      var gParameter = gParameters[gIndex++];
      if (gParameter.isPositional) {
        parameters.add(
          ParameterElementImpl.synthetic(
            gParameter.name,
            gParameter.type,
            ParameterKind.POSITIONAL,
          ),
        );
      } else {
        assert(gParameter.isNamed);
        parameters.add(
          ParameterElementImpl.synthetic(
            gParameter.name,
            gParameter.type,
            ParameterKind.NAMED,
          ),
        );
      }
    }

    var returnType = getGreatestLowerBound(f.returnType, g.returnType);

    return FunctionTypeImpl(
      typeFormals: typeFormals,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  /**
   * Compute the least upper bound of function types [f] and [g].
   *
   * https://github.com/dart-lang/language
   * See `resources/type-system/upper-lower-bounds.md`
   */
  DartType _functionLeastUpperBound(FunctionType f, FunctionType g) {
    var fTypeFormals = f.typeFormals;
    var gTypeFormals = g.typeFormals;

    // The number of type parameters must be the same.
    // Otherwise the result is `Function`.
    if (fTypeFormals.length != gTypeFormals.length) {
      return _interfaceTypeFunctionNone;
    }

    // The bounds of type parameters must be equal.
    // Otherwise the result is `Function`.
    var freshTypeFormalTypes =
        FunctionTypeImpl.relateTypeFormals(f, g, (t, s, _, __) => t == s);
    if (freshTypeFormalTypes == null) {
      return _interfaceTypeFunctionNone;
    }

    var typeFormals = freshTypeFormalTypes
        .map<TypeParameterElement>((t) => t.element)
        .toList();

    f = f.instantiate(freshTypeFormalTypes);
    g = g.instantiate(freshTypeFormalTypes);

    var fParameters = f.parameters;
    var gParameters = g.parameters;

    var parameters = <ParameterElement>[];
    var fIndex = 0;
    var gIndex = 0;
    while (fIndex < fParameters.length && gIndex < gParameters.length) {
      var fParameter = fParameters[fIndex];
      var gParameter = gParameters[gIndex];
      if (fParameter.isRequiredPositional) {
        if (gParameter.isRequiredPositional) {
          fIndex++;
          gIndex++;
          parameters.add(
            ParameterElementImpl.synthetic(
              fParameter.name,
              getGreatestLowerBound(fParameter.type, gParameter.type),
              ParameterKind.REQUIRED,
            ),
          );
        } else {
          break;
        }
      } else if (fParameter.isOptionalPositional) {
        if (gParameter.isOptionalPositional) {
          fIndex++;
          gIndex++;
          parameters.add(
            ParameterElementImpl.synthetic(
              fParameter.name,
              getGreatestLowerBound(fParameter.type, gParameter.type),
              ParameterKind.POSITIONAL,
            ),
          );
        } else {
          break;
        }
      } else if (fParameter.isNamed) {
        if (gParameter.isNamed) {
          var compareNames = fParameter.name.compareTo(gParameter.name);
          if (compareNames == 0) {
            fIndex++;
            gIndex++;
            parameters.add(
              ParameterElementImpl.synthetic(
                fParameter.name,
                getGreatestLowerBound(fParameter.type, gParameter.type),
                fParameter.isRequiredNamed || gParameter.isRequiredNamed
                    ? ParameterKind.NAMED_REQUIRED
                    : ParameterKind.NAMED,
              ),
            );
          } else if (compareNames < 0) {
            if (fParameter.isRequiredNamed) {
              // We cannot skip required named.
              return _interfaceTypeFunctionNone;
            } else {
              fIndex++;
            }
          } else {
            assert(compareNames > 0);
            if (gParameter.isRequiredNamed) {
              // We cannot skip required named.
              return _interfaceTypeFunctionNone;
            } else {
              gIndex++;
            }
          }
        } else {
          break;
        }
      }
    }

    while (fIndex < fParameters.length) {
      var fParameter = fParameters[fIndex++];
      if (fParameter.isNotOptional) {
        return _interfaceTypeFunctionNone;
      }
    }

    while (gIndex < gParameters.length) {
      var gParameter = gParameters[gIndex++];
      if (gParameter.isNotOptional) {
        return _interfaceTypeFunctionNone;
      }
    }

    var returnType = getLeastUpperBound(f.returnType, g.returnType);

    return FunctionTypeImpl(
      typeFormals: typeFormals,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  /// Check that [f] is a subtype of [g].
  bool _isFunctionSubtypeOf(FunctionType f, FunctionType g) {
    var fTypeFormals = f.typeFormals;
    var gTypeFormals = g.typeFormals;

    // The number of type parameters must be the same.
    if (fTypeFormals.length != gTypeFormals.length) {
      return false;
    }

    // The bounds of type parameters must be equal.
    var freshTypeFormalTypes =
        FunctionTypeImpl.relateTypeFormals(f, g, (t, s, _, __) {
      // Type parameter bounds are invariant.
      // TODO(scheglov) We do this for top types, but the spec says explicitly.
      return isSubtypeOf(t, s) && isSubtypeOf(s, t);
    });
    if (freshTypeFormalTypes == null) {
      return false;
    }

    f = f.instantiate(freshTypeFormalTypes);
    g = g.instantiate(freshTypeFormalTypes);

    if (!isSubtypeOf(f.returnType, g.returnType)) {
      return false;
    }

    var fParameters = f.parameters;
    var gParameters = g.parameters;

    var fIndex = 0;
    var gIndex = 0;
    while (fIndex < fParameters.length && gIndex < gParameters.length) {
      var fParameter = fParameters[fIndex];
      var gParameter = gParameters[gIndex];
      if (fParameter.isRequiredPositional) {
        if (gParameter.isRequiredPositional) {
          if (isSubtypeOf(gParameter.type, fParameter.type)) {
            fIndex++;
            gIndex++;
          } else {
            return false;
          }
        } else {
          return false;
        }
      } else if (fParameter.isOptionalPositional) {
        if (gParameter.isPositional) {
          if (isSubtypeOf(gParameter.type, fParameter.type)) {
            fIndex++;
            gIndex++;
          } else {
            return false;
          }
        } else {
          return false;
        }
      } else if (fParameter.isNamed) {
        if (gParameter.isNamed) {
          var compareNames = fParameter.name.compareTo(gParameter.name);
          if (compareNames == 0) {
            if (fParameter.isRequiredNamed && !gParameter.isRequiredNamed) {
              return false;
            } else if (isSubtypeOf(gParameter.type, fParameter.type)) {
              fIndex++;
              gIndex++;
            } else {
              return false;
            }
          } else if (compareNames < 0) {
            if (fParameter.isRequiredNamed) {
              return false;
            } else {
              fIndex++;
            }
          } else {
            assert(compareNames > 0);
            // The subtype must accept all parameters of the supertype.
            return false;
          }
        } else {
          break;
        }
      }
    }

    // The supertype must provide all required parameters to the subtype.
    while (fIndex < fParameters.length) {
      var fParameter = fParameters[fIndex++];
      if (fParameter.isNotOptional) {
        return false;
      }
    }

    // The subtype must accept all parameters of the supertype.
    assert(fIndex == fParameters.length);
    if (gIndex < gParameters.length) {
      return false;
    }

    return true;
  }

  bool _isInterfaceSubtypeOf(
      InterfaceType i1, InterfaceType i2, Set<ClassElement> visitedTypes) {
    // Note: we should never reach `_isInterfaceSubtypeOf` with `i2 == Object`,
    // because top types are eliminated before `isSubtypeOf` calls this.
    if (identical(i1, i2) || i2.isObject) {
      return true;
    }

    // Object cannot subtype anything but itself (handled above).
    if (i1.isObject) {
      return false;
    }

    ClassElement i1Element = i1.element;
    if (i1Element == i2.element) {
      List<DartType> tArgs1 = i1.typeArguments;
      List<DartType> tArgs2 = i2.typeArguments;
      List<TypeParameterElement> tParams = i1Element.typeParameters;

      assert(tArgs1.length == tArgs2.length);
      assert(tParams.length == tArgs1.length);

      for (int i = 0; i < tArgs1.length; i++) {
        DartType t1 = tArgs1[i];
        DartType t2 = tArgs2[i];

        // TODO (kallentu) : Clean up TypeParameterElementImpl casting once
        // variance is added to the interface.
        Variance variance = (tParams[i] as TypeParameterElementImpl).variance;
        if (variance.isCovariant) {
          if (!isSubtypeOf(t1, t2)) {
            return false;
          }
        } else if (variance.isContravariant) {
          if (!isSubtypeOf(t2, t1)) {
            return false;
          }
        } else if (variance.isInvariant) {
          if (!isSubtypeOf(t1, t2) || !isSubtypeOf(t2, t1)) {
            return false;
          }
        } else {
          throw StateError('Type parameter ${tParams[i]} has unknown '
              'variance $variance for subtype checking.');
        }
      }
      return true;
    }

    // Classes types cannot subtype `Function` or vice versa.
    if (i1.isDartCoreFunction || i2.isDartCoreFunction) {
      return false;
    }

    // Guard against loops in the class hierarchy.
    //
    // Dart 2 does not allow multiple implementations of the same generic type
    // with different type arguments. So we can track just the class element
    // to find cycles, rather than tracking the full interface type.
    visitedTypes ??= HashSet<ClassElement>();
    if (!visitedTypes.add(i1Element)) return false;

    InterfaceType superclass = i1.superclass;
    if (superclass != null &&
        _isInterfaceSubtypeOf(superclass, i2, visitedTypes)) {
      return true;
    }

    for (final parent in i1.interfaces) {
      if (_isInterfaceSubtypeOf(parent, i2, visitedTypes)) {
        return true;
      }
    }

    for (final parent in i1.mixins) {
      if (_isInterfaceSubtypeOf(parent, i2, visitedTypes)) {
        return true;
      }
    }

    if (i1Element.isMixin) {
      for (final parent in i1.superclassConstraints) {
        if (_isInterfaceSubtypeOf(parent, i2, visitedTypes)) {
          return true;
        }
      }
    }

    return false;
  }

  DartType _typeParameterResolveToObjectBounds(DartType type) {
    var element = type.element;
    type = type.resolveToBound(typeProvider.objectType);
    return Substitution.fromMap({element: typeProvider.objectType})
        .substituteType(type);
  }
}

/// Tracks upper and lower type bounds for a set of type parameters.
///
/// This class is used by calling [isSubtypeOf]. When it encounters one of
/// the type parameters it is inferring, it will record the constraint, and
/// optimistically assume the constraint will be satisfied.
///
/// For example if we are inferring type parameter A, and we ask if
/// `A <: num`, this will record that A must be a subytpe of `num`. It also
/// handles cases when A appears as part of the structure of another type, for
/// example `Iterable<A> <: Iterable<num>` would infer the same constraint
/// (due to covariant generic types) as would `() -> A <: () -> num`. In
/// contrast `(A) -> void <: (num) -> void`.
///
/// Once the lower/upper bounds are determined, [infer] should be called to
/// finish the inference. It will instantiate a generic function type with the
/// inferred types for each type parameter.
///
/// It can also optionally compute a partial solution, in case some of the type
/// parameters could not be inferred (because the constraints cannot be
/// satisfied), or bail on the inference when this happens.
///
/// As currently designed, an instance of this class should only be used to
/// infer a single call and discarded immediately afterwards.
class GenericInferrer {
  final TypeSystemImpl _typeSystem;
  final Map<TypeParameterElement, List<_TypeConstraint>> constraints = {};

  /// Buffer recording constraints recorded while performing a recursive call to
  /// [_matchSubtypeOf] that might fail, so that any constraints recorded during
  /// the failed match can be rewound.
  final _undoBuffer = <_TypeConstraint>[];

  GenericInferrer(
    this._typeSystem,
    Iterable<TypeParameterElement> typeFormals,
  ) {
    for (var formal in typeFormals) {
      constraints[formal] = [];
    }
  }

  bool get isNonNullableByDefault => _typeSystem.isNonNullableByDefault;

  TypeProvider get typeProvider => _typeSystem.typeProvider;

  /// Apply an argument constraint, which asserts that the [argument] staticType
  /// is a subtype of the [parameterType].
  void constrainArgument(
      DartType argumentType, DartType parameterType, String parameterName,
      {ClassElement genericClass}) {
    var origin = _TypeConstraintFromArgument(
      argumentType,
      parameterType,
      parameterName,
      genericClass: genericClass,
      isNonNullableByDefault: isNonNullableByDefault,
    );
    tryMatchSubtypeOf(argumentType, parameterType, origin, covariant: false);
  }

  /// Constrain a universal function type [fnType] used in a context
  /// [contextType].
  void constrainGenericFunctionInContext(
      FunctionType fnType, DartType contextType) {
    var origin = _TypeConstraintFromFunctionContext(
      fnType,
      contextType,
      isNonNullableByDefault: isNonNullableByDefault,
    );

    // Since we're trying to infer the instantiation, we want to ignore type
    // formals as we check the parameters and return type.
    var inferFnType = FunctionTypeImpl(
      typeFormals: const [],
      parameters: fnType.parameters,
      returnType: fnType.returnType,
      nullabilitySuffix: fnType.nullabilitySuffix,
    );
    tryMatchSubtypeOf(inferFnType, contextType, origin, covariant: true);
  }

  /// Apply a return type constraint, which asserts that the [declaredType]
  /// is a subtype of the [contextType].
  void constrainReturnType(DartType declaredType, DartType contextType) {
    var origin = _TypeConstraintFromReturnType(
      declaredType,
      contextType,
      isNonNullableByDefault: isNonNullableByDefault,
    );
    tryMatchSubtypeOf(declaredType, contextType, origin, covariant: true);
  }

  /// Given the constraints that were given by calling [constrainArgument] and
  /// [constrainReturnType], find the type arguments for the [typeFormals] that
  /// satisfies these constraints.
  ///
  /// If [downwardsInferPhase] is set, we are in the first pass of inference,
  /// pushing context types down. At that point we are allowed to push down
  /// `?` to precisely represent an unknown type. If [downwardsInferPhase] is
  /// false, we are on our final inference pass, have all available information
  /// including argument types, and must not conclude `?` for any type formal.
  List<DartType> infer(List<TypeParameterElement> typeFormals,
      {bool considerExtendsClause = true,
      ErrorReporter errorReporter,
      AstNode errorNode,
      bool failAtError = false,
      bool downwardsInferPhase = false}) {
    // Initialize the inferred type array.
    //
    // In the downwards phase, they all start as `?` to offer reasonable
    // degradation for f-bounded type parameters.
    var inferredTypes =
        List<DartType>.filled(typeFormals.length, UnknownInferredType.instance);

    for (int i = 0; i < typeFormals.length; i++) {
      // TODO (kallentu) : Clean up TypeParameterElementImpl casting once
      // variance is added to the interface.
      TypeParameterElementImpl typeParam = typeFormals[i];
      _TypeConstraint extendsClause;
      if (considerExtendsClause && typeParam.bound != null) {
        extendsClause = _TypeConstraint.fromExtends(
          typeParam,
          Substitution.fromPairs(typeFormals, inferredTypes)
              .substituteType(typeParam.bound),
          isNonNullableByDefault: isNonNullableByDefault,
        );
      }

      inferredTypes[i] = downwardsInferPhase
          ? _inferTypeParameterFromContext(
              constraints[typeParam], extendsClause,
              isContravariant: typeParam.variance.isContravariant)
          : _inferTypeParameterFromAll(constraints[typeParam], extendsClause,
              isContravariant: typeParam.variance.isContravariant,
              preferUpwardsInference: !typeParam.isLegacyCovariant);
    }

    // If the downwards infer phase has failed, we'll catch this in the upwards
    // phase later on.
    if (downwardsInferPhase) {
      return inferredTypes;
    }

    // Check the inferred types against all of the constraints.
    var knownTypes = <TypeParameterElement, DartType>{};
    for (int i = 0; i < typeFormals.length; i++) {
      TypeParameterElement typeParam = typeFormals[i];
      var constraints = this.constraints[typeParam];
      var typeParamBound = typeParam.bound != null
          ? Substitution.fromPairs(typeFormals, inferredTypes)
              .substituteType(typeParam.bound)
          : typeProvider.dynamicType;

      var inferred = inferredTypes[i];
      bool success =
          constraints.every((c) => c.isSatisifedBy(_typeSystem, inferred));
      if (success && !typeParamBound.isDynamic) {
        // If everything else succeeded, check the `extends` constraint.
        var extendsConstraint = _TypeConstraint.fromExtends(
          typeParam,
          typeParamBound,
          isNonNullableByDefault: isNonNullableByDefault,
        );
        constraints.add(extendsConstraint);
        success = extendsConstraint.isSatisifedBy(_typeSystem, inferred);
      }

      if (!success) {
        if (failAtError) return null;
        errorReporter?.reportErrorForNode(
            StrongModeCode.COULD_NOT_INFER,
            errorNode,
            [typeParam.name, _formatError(typeParam, inferred, constraints)]);

        // Heuristic: even if we failed, keep the erroneous type.
        // It should satisfy at least some of the constraints (e.g. the return
        // context). If we fall back to instantiateToBounds, we'll typically get
        // more errors (e.g. because `dynamic` is the most common bound).
      }

      if (inferred is FunctionType && inferred.typeFormals.isNotEmpty) {
        if (failAtError) return null;
        var typeFormals = (inferred as FunctionType).typeFormals;
        var typeFormalsStr = typeFormals.map(_elementStr).join(', ');
        errorReporter
            ?.reportErrorForNode(StrongModeCode.COULD_NOT_INFER, errorNode, [
          typeParam.name,
          ' Inferred candidate type ${_typeStr(inferred)} has type parameters'
              ' [$typeFormalsStr], but a function with'
              ' type parameters cannot be used as a type argument.'
        ]);

        // Heuristic: Using a generic function type as a bound makes subtyping
        // undecidable. Therefore, we cannot keep [inferred] unless we wish to
        // generate bogus subtyping errors. Instead generate plain [Function],
        // which is the most general function type.
        inferred = typeProvider.functionType;
      }

      if (UnknownInferredType.isKnown(inferred)) {
        knownTypes[typeParam] = inferred;
      } else if (_typeSystem.strictInference) {
        // [typeParam] could not be inferred. A result will still be returned
        // by [infer], with [typeParam] filled in as its bounds. This is
        // considered a failure of inference, under the "strict-inference"
        // mode.
        if (errorNode is ConstructorName) {
          String constructorName = '${errorNode.type}.${errorNode.name}';
          errorReporter?.reportErrorForNode(
              HintCode.INFERENCE_FAILURE_ON_INSTANCE_CREATION,
              errorNode,
              [constructorName]);
        }
        // TODO(srawlins): More inference failure cases, like functions, and
        // function expressions.
      }
    }

    // Use instantiate to bounds to finish things off.
    var hasError = List<bool>.filled(typeFormals.length, false);
    var result = _typeSystem.instantiateTypeFormalsToBounds(typeFormals,
        hasError: hasError, knownTypes: knownTypes);

    // Report any errors from instantiateToBounds.
    for (int i = 0; i < hasError.length; i++) {
      if (hasError[i]) {
        if (failAtError) return null;
        TypeParameterElement typeParam = typeFormals[i];
        var typeParamBound = Substitution.fromPairs(typeFormals, inferredTypes)
            .substituteType(typeParam.bound ?? typeProvider.objectType);
        // TODO(jmesserly): improve this error message.
        errorReporter
            ?.reportErrorForNode(StrongModeCode.COULD_NOT_INFER, errorNode, [
          typeParam.name,
          "\nRecursive bound cannot be instantiated: '$typeParamBound'."
              "\nConsider passing explicit type argument(s) "
              "to the generic.\n\n'"
        ]);
      }
    }

    return result;
  }

  /// Tries to make [i1] a subtype of [i2] and accumulate constraints as needed.
  ///
  /// The return value indicates whether the match was successful.  If it was
  /// unsuccessful, any constraints that were accumulated during the match
  /// attempt have been rewound (see [_rewindConstraints]).
  bool tryMatchSubtypeOf(DartType t1, DartType t2, _TypeConstraintOrigin origin,
      {bool covariant}) {
    int previousRewindBufferLength = _undoBuffer.length;
    bool success = _matchSubtypeOf(t1, t2, null, origin, covariant: covariant);
    if (!success) {
      _rewindConstraints(previousRewindBufferLength);
    }
    return success;
  }

  /// Choose the bound that was implied by the return type, if any.
  ///
  /// Which bound this is depends on what positions the type parameter
  /// appears in. If the type only appears only in a contravariant position,
  /// we will choose the lower bound instead.
  ///
  /// For example given:
  ///
  ///     Func1<T, bool> makeComparer<T>(T x) => (T y) => x() == y;
  ///
  ///     main() {
  ///       Func1<num, bool> t = makeComparer/* infer <num> */(42);
  ///       print(t(42.0)); /// false, no error.
  ///     }
  ///
  /// The constraints we collect are:
  ///
  /// * `num <: T`
  /// * `int <: T`
  ///
  /// ... and no upper bound. Therefore the lower bound is the best choice.
  ///
  /// If [isContravariant] is `true`, then we are solving for a contravariant
  /// type parameter which means we choose the upper bound rather than the
  /// lower bound for normally covariant type parameters.
  DartType _chooseTypeFromConstraints(Iterable<_TypeConstraint> constraints,
      {bool toKnownType = false, @required bool isContravariant}) {
    DartType lower = UnknownInferredType.instance;
    DartType upper = UnknownInferredType.instance;
    for (var constraint in constraints) {
      // Given constraints:
      //
      //     L1 <: T <: U1
      //     L2 <: T <: U2
      //
      // These can be combined to produce:
      //
      //     LUB(L1, L2) <: T <: GLB(U1, U2).
      //
      // This can then be done for all constraints in sequence.
      //
      // This resulting constraint may be unsatisfiable; in that case inference
      // will fail.
      upper = _getGreatestLowerBound(upper, constraint.upperBound);
      lower = _typeSystem.getLeastUpperBound(lower, constraint.lowerBound);
      upper = _toLegacyType(upper);
      lower = _toLegacyType(lower);
    }

    // Prefer the known bound, if any.
    // Otherwise take whatever bound has partial information, e.g. `Iterable<?>`
    //
    // For both of those, prefer the lower bound (arbitrary heuristic) or upper
    // bound if [isContravariant] is `true`
    if (isContravariant) {
      if (UnknownInferredType.isKnown(upper)) {
        return upper;
      }
      if (UnknownInferredType.isKnown(lower)) {
        return lower;
      }
      if (!identical(UnknownInferredType.instance, upper)) {
        return toKnownType
            ? greatestClosure(_typeSystem.typeProvider, upper)
            : upper;
      }
      if (!identical(UnknownInferredType.instance, lower)) {
        return toKnownType
            ? leastClosure(_typeSystem.typeProvider, lower)
            : lower;
      }
      return upper;
    } else {
      if (UnknownInferredType.isKnown(lower)) {
        return lower;
      }
      if (UnknownInferredType.isKnown(upper)) {
        return upper;
      }
      if (!identical(UnknownInferredType.instance, lower)) {
        return toKnownType
            ? leastClosure(_typeSystem.typeProvider, lower)
            : lower;
      }
      if (!identical(UnknownInferredType.instance, upper)) {
        return toKnownType
            ? greatestClosure(_typeSystem.typeProvider, upper)
            : upper;
      }
      return lower;
    }
  }

  String _elementStr(Element element) {
    return element.getDisplayString(withNullability: isNonNullableByDefault);
  }

  String _formatError(TypeParameterElement typeParam, DartType inferred,
      Iterable<_TypeConstraint> constraints) {
    var inferredStr = inferred.getDisplayString(
      withNullability: isNonNullableByDefault,
    );
    var intro = "Tried to infer '$inferredStr' for '${typeParam.name}'"
        " which doesn't work:";

    var constraintsByOrigin = <_TypeConstraintOrigin, List<_TypeConstraint>>{};
    for (var c in constraints) {
      constraintsByOrigin.putIfAbsent(c.origin, () => []).add(c);
    }

    // Only report unique constraint origins.
    Iterable<_TypeConstraint> isSatisified(bool expected) => constraintsByOrigin
        .values
        .where((l) =>
            l.every((c) => c.isSatisifedBy(_typeSystem, inferred)) == expected)
        .expand((i) => i);

    String unsatisified = _formatConstraints(isSatisified(false));
    String satisified = _formatConstraints(isSatisified(true));

    assert(unsatisified.isNotEmpty);
    if (satisified.isNotEmpty) {
      satisified = "\nThe type '$inferredStr' was inferred from:\n$satisified";
    }

    return '\n\n$intro\n$unsatisified$satisified\n\n'
        'Consider passing explicit type argument(s) to the generic.\n\n';
  }

  /// This is first calls strong mode's GLB, but if it fails to find anything
  /// (i.e. returns the bottom type), we kick in a few additional rules:
  ///
  /// - `GLB(FutureOr<A>, B)` is defined as:
  ///   - `GLB(FutureOr<A>, FutureOr<B>) == FutureOr<GLB(A, B)>`
  ///   - `GLB(FutureOr<A>, Future<B>) == Future<GLB(A, B)>`
  ///   - else `GLB(FutureOr<A>, B) == GLB(A, B)`
  /// - `GLB(A, FutureOr<B>) ==  GLB(FutureOr<B>, A)` (defined above),
  /// - else `GLB(A, B) == Null`
  DartType _getGreatestLowerBound(DartType t1, DartType t2) {
    var result = _typeSystem.getGreatestLowerBound(t1, t2);
    if (result.isBottom) {
      // See if we can do better by considering FutureOr rules.
      if (t1 is InterfaceType && t1.isDartAsyncFutureOr) {
        var t1TypeArg = t1.typeArguments[0];
        if (t2 is InterfaceType) {
          //  GLB(FutureOr<A>, FutureOr<B>) == FutureOr<GLB(A, B)>
          if (t2.isDartAsyncFutureOr) {
            var t2TypeArg = t2.typeArguments[0];
            return typeProvider
                .futureOrType2(_getGreatestLowerBound(t1TypeArg, t2TypeArg));
          }
          // GLB(FutureOr<A>, Future<B>) == Future<GLB(A, B)>
          if (t2.isDartAsyncFuture) {
            var t2TypeArg = t2.typeArguments[0];
            return typeProvider
                .futureType2(_getGreatestLowerBound(t1TypeArg, t2TypeArg));
          }
        }
        // GLB(FutureOr<A>, B) == GLB(A, B)
        return _getGreatestLowerBound(t1TypeArg, t2);
      }
      if (t2 is InterfaceType && t2.isDartAsyncFutureOr) {
        // GLB(A, FutureOr<B>) ==  GLB(FutureOr<B>, A)
        return _getGreatestLowerBound(t2, t1);
      }
      return typeProvider.nullType;
    }
    return result;
  }

  DartType _inferTypeParameterFromAll(
      List<_TypeConstraint> constraints, _TypeConstraint extendsClause,
      {@required bool isContravariant, @required bool preferUpwardsInference}) {
    // See if we already fixed this type from downwards inference.
    // If so, then we aren't allowed to change it based on argument types unless
    // [preferUpwardsInference] is true.
    DartType t = _inferTypeParameterFromContext(
        constraints.where((c) => c.isDownwards), extendsClause,
        isContravariant: isContravariant);
    if (!preferUpwardsInference && UnknownInferredType.isKnown(t)) {
      // Remove constraints that aren't downward ones; we'll ignore these for
      // error reporting, because inference already succeeded.
      constraints.removeWhere((c) => !c.isDownwards);
      return t;
    }

    if (extendsClause != null) {
      constraints = constraints.toList()..add(extendsClause);
    }

    var choice = _chooseTypeFromConstraints(constraints,
        toKnownType: true, isContravariant: isContravariant);
    return choice;
  }

  DartType _inferTypeParameterFromContext(
      Iterable<_TypeConstraint> constraints, _TypeConstraint extendsClause,
      {@required bool isContravariant}) {
    DartType t = _chooseTypeFromConstraints(constraints,
        isContravariant: isContravariant);
    if (UnknownInferredType.isUnknown(t)) {
      return t;
    }

    // If we're about to make our final choice, apply the extends clause.
    // This gives us a chance to refine the choice, in case it would violate
    // the `extends` clause. For example:
    //
    //     Object obj = math.min/*<infer Object, error>*/(1, 2);
    //
    // If we consider the `T extends num` we conclude `<num>`, which works.
    if (extendsClause != null) {
      constraints = constraints.toList()..add(extendsClause);
      return _chooseTypeFromConstraints(constraints,
          isContravariant: isContravariant);
    }
    return t;
  }

  /// Tries to make [i1] a subtype of [i2] and accumulate constraints as needed.
  ///
  /// The return value indicates whether the match was successful.  If it was
  /// unsuccessful, the caller is responsible for ignoring any constraints that
  /// were accumulated (see [_rewindConstraints]).
  bool _matchInterfaceSubtypeOf(InterfaceType i1, InterfaceType i2,
      Set<Element> visited, _TypeConstraintOrigin origin,
      {bool covariant}) {
    if (identical(i1, i2)) {
      return true;
    }

    if (i1.element == i2.element) {
      List<DartType> tArgs1 = i1.typeArguments;
      List<DartType> tArgs2 = i2.typeArguments;
      List<TypeParameterElement> tParams = i1.element.typeParameters;
      assert(tArgs1.length == tArgs2.length);
      assert(tArgs1.length == tParams.length);
      for (int i = 0; i < tArgs1.length; i++) {
        TypeParameterElement typeParameterElement = tParams[i];

        // TODO (kallentu) : Clean up TypeParameterElementImpl casting once
        // variance is added to the interface.
        Variance parameterVariance =
            (typeParameterElement as TypeParameterElementImpl).variance;
        if (parameterVariance.isCovariant) {
          if (!_matchSubtypeOf(tArgs1[i], tArgs2[i], HashSet<Element>(), origin,
              covariant: covariant)) {
            return false;
          }
        } else if (parameterVariance.isContravariant) {
          if (!_matchSubtypeOf(tArgs2[i], tArgs1[i], HashSet<Element>(), origin,
              covariant: !covariant)) {
            return false;
          }
        } else if (parameterVariance.isInvariant) {
          if (!_matchSubtypeOf(tArgs1[i], tArgs2[i], HashSet<Element>(), origin,
                  covariant: covariant) ||
              !_matchSubtypeOf(tArgs2[i], tArgs1[i], HashSet<Element>(), origin,
                  covariant: !covariant)) {
            return false;
          }
        } else {
          throw StateError("Type parameter ${tParams[i]} has unknown "
              "variance $parameterVariance for inference.");
        }
      }
      return true;
    }
    if (i1.isObject) {
      return false;
    }

    // Guard against loops in the class hierarchy
    bool guardedInterfaceSubtype(InterfaceType t1) {
      visited ??= HashSet<Element>();
      if (visited.add(t1.element)) {
        bool matched = _matchInterfaceSubtypeOf(t1, i2, visited, origin,
            covariant: covariant);
        visited.remove(t1.element);
        return matched;
      } else {
        // In the case of a recursive type parameter, consider the subtype
        // match to have failed.
        return false;
      }
    }

    // We don't need to search the entire class hierarchy, since a given
    // subclass can't appear multiple times with different generic parameters.
    // So shortcut to the first match found.
    //
    // We don't need undo logic here because if the classes don't match, nothing
    // is added to the constraint set.
    var superclass = i1.superclass;
    if (superclass != null && guardedInterfaceSubtype(superclass)) return true;
    for (final parent in i1.interfaces) {
      if (guardedInterfaceSubtype(parent)) return true;
    }
    for (final parent in i1.mixins) {
      if (guardedInterfaceSubtype(parent)) return true;
    }
    for (final parent in i1.superclassConstraints) {
      if (guardedInterfaceSubtype(parent)) return true;
    }
    return false;
  }

  /// Assert that [t1] will be a subtype of [t2], and returns if the constraint
  /// can be satisfied.
  ///
  /// [covariant] must be true if [t1] is a declared type of the generic
  /// function and [t2] is the context type, or false if the reverse. For
  /// example [covariant] is used when [t1] is the declared return type
  /// and [t2] is the context type. Contravariant would be used if [t1] is the
  /// argument type (i.e. passed in to the generic function) and [t2] is the
  /// declared parameter type.
  ///
  /// [origin] indicates where the constraint came from, for example an argument
  /// or return type.
  bool _matchSubtypeOf(DartType t1, DartType t2, Set<Element> visited,
      _TypeConstraintOrigin origin,
      {bool covariant}) {
    if (covariant && t1 is TypeParameterType) {
      var constraints = this.constraints[t1.element];
      if (constraints != null) {
        if (!identical(t2, UnknownInferredType.instance)) {
          var constraint = _TypeConstraint(origin, t1.element, upper: t2);
          constraints.add(constraint);
          _undoBuffer.add(constraint);
        }
        return true;
      }
    }
    if (!covariant && t2 is TypeParameterType) {
      var constraints = this.constraints[t2.element];
      if (constraints != null) {
        if (!identical(t1, UnknownInferredType.instance)) {
          var constraint = _TypeConstraint(origin, t2.element, lower: t1);
          constraints.add(constraint);
          _undoBuffer.add(constraint);
        }
        return true;
      }
    }

    if (identical(t1, t2)) {
      return true;
    }

    // TODO(jmesserly): this logic is taken from subtype.
    bool matchSubtype(DartType t1, DartType t2) {
      return _matchSubtypeOf(t1, t2, null, origin, covariant: covariant);
    }

    // Handle FutureOr<T> union type.
    if (t1 is InterfaceType && t1.isDartAsyncFutureOr) {
      var t1TypeArg = t1.typeArguments[0];
      if (t2 is InterfaceType && t2.isDartAsyncFutureOr) {
        var t2TypeArg = t2.typeArguments[0];
        // FutureOr<A> <: FutureOr<B> iff A <: B
        return matchSubtype(t1TypeArg, t2TypeArg);
      }

      // given t1 is Future<A> | A, then:
      // (Future<A> | A) <: t2 iff Future<A> <: t2 and A <: t2.
      var t1Future = typeProvider.futureType2(t1TypeArg);
      return matchSubtype(t1Future, t2) && matchSubtype(t1TypeArg, t2);
    }

    if (t2 is InterfaceType && t2.isDartAsyncFutureOr) {
      // given t2 is Future<A> | A, then:
      // t1 <: (Future<A> | A) iff t1 <: Future<A> or t1 <: A
      var t2TypeArg = t2.typeArguments[0];
      var t2Future = typeProvider.futureType2(t2TypeArg);

      // First we try matching `t1 <: Future<A>`.  If that succeeds *and*
      // records at least one constraint, then we proceed using that constraint.
      var previousRewindBufferLength = _undoBuffer.length;
      var success =
          tryMatchSubtypeOf(t1, t2Future, origin, covariant: covariant);

      if (_undoBuffer.length != previousRewindBufferLength) {
        // Trying to match `t1 <: Future<A>` succeeded and recorded constraints,
        // so those are the constraints we want.
        return true;
      } else {
        // Either `t1 <: Future<A>` failed to match, or it matched trivially
        // without recording any constraints (e.g. because t1 is `Null`).  We
        // want constraints, because they let us do more precise inference, so
        // go ahead and try matching `t1 <: A` to see if it records any
        // constraints.
        if (tryMatchSubtypeOf(t1, t2TypeArg, origin, covariant: covariant)) {
          // Trying to match `t1 <: A` succeeded.  If it recorded constraints,
          // those are the constraints we want.  If it didn't, then there's no
          // way we're going to get any constraints.  So either way, we want to
          // return `true` since the match suceeded and the constraints we want
          // (if any) have been recorded.
          return true;
        } else {
          // Trying to match `t1 <: A` failed.  So there's no way we are going
          // to get any constraints.  Just return `success` to indicate whether
          // the match succeeded.
          return success;
        }
      }
    }

    // S <: T where S is a type variable
    //  T is not dynamic or object (handled above)
    //  True if T == S
    //  Or true if bound of S is S' and S' <: T

    if (t1 is TypeParameterType) {
      // Guard against recursive type parameters
      //
      // TODO(jmesserly): this function isn't guarding against anything (it's
      // not passsing down `visitedSet`, so adding the element has no effect).
      bool guardedSubtype(DartType t1, DartType t2) {
        var visitedSet = visited ?? HashSet<Element>();
        if (visitedSet.add(t1.element)) {
          bool matched = matchSubtype(t1, t2);
          visitedSet.remove(t1.element);
          return matched;
        } else {
          // In the case of a recursive type parameter, consider the subtype
          // match to have failed.
          return false;
        }
      }

      if (t2 is TypeParameterType && t1.definition == t2.definition) {
        return guardedSubtype(t1.bound, t2.bound);
      }
      return guardedSubtype(t1.bound, t2);
    }
    if (t2 is TypeParameterType) {
      return false;
    }

    // TODO(mfairhurst): switch legacy Bottom checks to true Bottom checks
    // TODO(mfairhurst): switch legacy Top checks to true Top checks
    if (_isLegacyBottom(t1, orTrueBottom: true) ||
        _isLegacyTop(t2, orTrueTop: true)) return true;

    if (t1 is InterfaceType && t2 is InterfaceType) {
      return _matchInterfaceSubtypeOf(t1, t2, visited, origin,
          covariant: covariant);
    }

    if (t1 is FunctionType && t2 is FunctionType) {
      return FunctionTypeImpl.relate(t1, t2, matchSubtype,
          parameterRelation: (p1, p2) {
            return _matchSubtypeOf(p2.type, p1.type, null, origin,
                covariant: !covariant);
          },
          // Type parameter bounds are invariant.
          boundsRelation: (t1, t2, p1, p2) =>
              matchSubtype(t1, t2) && matchSubtype(t2, t1));
    }

    if (t1 is FunctionType && t2 == typeProvider.functionType) {
      return true;
    }

    return false;
  }

  /// Un-does constraints that were gathered by a failed match attempt, until
  /// [_undoBuffer] has length [previousRewindBufferLength].
  ///
  /// The intended usage is that the caller should record the length of
  /// [_undoBuffer] before attempting to make a match.  Then, if the match
  /// fails, pass the recorded length to this method to erase any constraints
  /// that were recorded during the failed match.
  void _rewindConstraints(int previousRewindBufferLength) {
    while (_undoBuffer.length > previousRewindBufferLength) {
      var constraint = _undoBuffer.removeLast();
      var element = constraint.typeParameter;
      assert(identical(constraints[element].last, constraint));
      constraints[element].removeLast();
    }
  }

  /// If in a legacy library, return the legacy version of the [type].
  /// Otherwise, return the original type.
  DartType _toLegacyType(DartType type) {
    if (isNonNullableByDefault) return type;
    return NullabilityEliminator.perform(typeProvider, type);
  }

  String _typeStr(DartType type) {
    return type.getDisplayString(withNullability: isNonNullableByDefault);
  }

  static String _formatConstraints(Iterable<_TypeConstraint> constraints) {
    List<List<String>> lineParts =
        Set<_TypeConstraintOrigin>.from(constraints.map((c) => c.origin))
            .map((o) => o.formatError())
            .toList();

    int prefixMax = lineParts.map((p) => p[0].length).fold(0, math.max);

    // Use a set to prevent identical message lines.
    // (It's not uncommon for the same constraint to show up in a few places.)
    var messageLines = Set<String>.from(lineParts.map((parts) {
      var prefix = parts[0];
      var middle = parts[1];
      var prefixPad = ' ' * (prefixMax - prefix.length);
      var middlePad = ' ' * (prefixMax);
      var end = "";
      if (parts.length > 2) {
        end = '\n  $middlePad ${parts[2]}';
      }
      return '  $prefix$prefixPad $middle$end';
    }));

    return messageLines.join('\n');
  }
}

/// The instantiation of a [ClassElement] with type arguments.
///
/// It is not a [DartType] itself, because it does not have nullability.
/// But it should be used where nullability does not make sense - to specify
/// superclasses, mixins, and implemented interfaces.
class InstantiatedClass {
  final ClassElement element;
  final List<DartType> arguments;

  final Substitution _substitution;

  InstantiatedClass(this.element, this.arguments)
      : _substitution = Substitution.fromPairs(
          element.typeParameters,
          arguments,
        );

  /// Return the [InstantiatedClass] that corresponds to the [type] - with the
  /// same element and type arguments, ignoring its nullability suffix.
  factory InstantiatedClass.of(InterfaceType type) {
    return InstantiatedClass(type.element, type.typeArguments);
  }

  @override
  int get hashCode {
    var hash = 0x3fffffff & element.hashCode;
    for (var i = 0; i < arguments.length; i++) {
      hash = 0x3fffffff & (hash * 31 + (hash ^ arguments[i].hashCode));
    }
    return hash;
  }

  /// Return the interfaces that are directly implemented by this class.
  List<InstantiatedClass> get interfaces {
    var interfaces = element.interfaces;

    var result = List<InstantiatedClass>(interfaces.length);
    for (var i = 0; i < interfaces.length; i++) {
      var interface = interfaces[i];
      var substituted = _substitution.substituteType(interface);
      result[i] = InstantiatedClass.of(substituted);
    }

    return result;
  }

  /// Return `true` if this type represents the type 'Function' defined in the
  /// dart:core library.
  bool get isDartCoreFunction {
    return element.name == 'Function' && element.library.isDartCore;
  }

  /// Return the superclass of this type, or `null` if this type represents
  /// the class 'Object'.
  InstantiatedClass get superclass {
    var supertype = element.supertype;
    if (supertype == null) return null;

    supertype = _substitution.substituteType(supertype);
    return InstantiatedClass.of(supertype);
  }

  /// Return a list containing all of the superclass constraints defined for
  /// this class. The list will be empty if this class does not represent a
  /// mixin declaration. If this class _does_ represent a mixin declaration but
  /// the declaration does not have an `on` clause, then the list will contain
  /// the type for the class `Object`.
  List<InstantiatedClass> get superclassConstraints {
    var constraints = element.superclassConstraints;

    var result = List<InstantiatedClass>(constraints.length);
    for (var i = 0; i < constraints.length; i++) {
      var constraint = constraints[i];
      var substituted = _substitution.substituteType(constraint);
      result[i] = InstantiatedClass.of(substituted);
    }

    return result;
  }

  @visibleForTesting
  InterfaceType get withNullabilitySuffixNone {
    return withNullability(NullabilitySuffix.none);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is InstantiatedClass) {
      if (element != other.element) return false;
      if (arguments.length != other.arguments.length) return false;
      for (var i = 0; i < arguments.length; i++) {
        if (arguments[i] != other.arguments[i]) return false;
      }
      return true;
    }
    return false;
  }

  @override
  String toString() {
    var buffer = StringBuffer();
    buffer.write(element.name);
    if (arguments.isNotEmpty) {
      buffer.write('<');
      buffer.write(arguments.join(', '));
      buffer.write('>');
    }
    return buffer.toString();
  }

  InterfaceType withNullability(NullabilitySuffix nullability) {
    return InterfaceTypeImpl(
      element: element,
      typeArguments: arguments,
      nullabilitySuffix: nullability,
    );
  }
}

class InterfaceLeastUpperBoundHelper {
  final TypeSystemImpl typeSystem;

  InterfaceLeastUpperBoundHelper(this.typeSystem);

  /// This currently does not implement a very complete least upper bound
  /// algorithm, but handles a couple of the very common cases that are
  /// causing pain in real code.  The current algorithm is:
  /// 1. If either of the types is a supertype of the other, return it.
  ///    This is in fact the best result in this case.
  /// 2. If the two types have the same class element and are implicitly or
  ///    explicitly covariant, then take the pointwise least upper bound of
  ///    the type arguments. This is again the best result, except that the
  ///    recursive calls may not return the true least upper bounds. The
  ///    result is guaranteed to be a well-formed type under the assumption
  ///    that the input types were well-formed (and assuming that the
  ///    recursive calls return well-formed types).
  ///    If the variance of the type parameter is contravariant, we take the
  ///    greatest lower bound of the type arguments. If the variance of the
  ///    type parameter is invariant, we verify if the type arguments satisfy
  ///    subtyping in both directions, then choose a bound.
  /// 3. Otherwise return the spec-defined least upper bound.  This will
  ///    be an upper bound, might (or might not) be least, and might
  ///    (or might not) be a well-formed type.
  ///
  /// TODO(leafp): Use matchTypes or something similar here to handle the
  ///  case where one of the types is a superclass (but not supertype) of
  ///  the other, e.g. LUB(Iterable<double>, List<int>) = Iterable<num>
  /// TODO(leafp): Figure out the right final algorithm and implement it.
  InterfaceTypeImpl compute(InterfaceTypeImpl type1, InterfaceTypeImpl type2) {
    var nullability = _chooseNullability(type1, type2);

    // Strip off nullability.
    type1 = type1.withNullability(NullabilitySuffix.none);
    type2 = type2.withNullability(NullabilitySuffix.none);

    if (typeSystem.isSubtypeOf(type1, type2)) {
      return type2.withNullability(nullability);
    }
    if (typeSystem.isSubtypeOf(type2, type1)) {
      return type1.withNullability(nullability);
    }

    if (type1.element == type2.element) {
      var args1 = type1.typeArguments;
      var args2 = type2.typeArguments;
      var params = type1.element.typeParameters;
      assert(args1.length == args2.length);
      assert(args1.length == params.length);

      var args = List<DartType>(args1.length);
      for (int i = 0; i < args1.length; i++) {
        // TODO (kallentu) : Clean up TypeParameterElementImpl casting once
        // variance is added to the interface.
        Variance parameterVariance =
            (params[i] as TypeParameterElementImpl).variance;
        if (parameterVariance.isCovariant) {
          args[i] = typeSystem.getLeastUpperBound(args1[i], args2[i]);
        } else if (parameterVariance.isContravariant) {
          if (typeSystem is TypeSystemImpl) {
            args[i] = typeSystem.getGreatestLowerBound(args1[i], args2[i]);
          } else {
            args[i] = typeSystem.getLeastUpperBound(args1[i], args2[i]);
          }
        } else if (parameterVariance.isInvariant) {
          if (!typeSystem.isSubtypeOf(args1[i], args2[i]) ||
              !typeSystem.isSubtypeOf(args2[i], args1[i])) {
            // No bound will be valid, find bound at the interface level.
            return _computeLeastUpperBound(
              InstantiatedClass.of(type1),
              InstantiatedClass.of(type2),
            ).withNullability(nullability);
          }
          // TODO (kallentu) : Fix asymmetric bounds behavior for invariant type
          //  parameters.
          args[i] = args1[i];
        } else {
          throw StateError('Type parameter ${params[i]} has unknown '
              'variance $parameterVariance for bounds calculation.');
        }
      }

      return InterfaceTypeImpl(
        element: type1.element,
        typeArguments: args,
        nullabilitySuffix: nullability,
      );
    }

    var result = _computeLeastUpperBound(
      InstantiatedClass.of(type1),
      InstantiatedClass.of(type2),
    );
    return result.withNullability(nullability);
  }

  /// Compute the least upper bound of types [i] and [j], both of which are
  /// known to be interface types.
  ///
  /// In the event that the algorithm fails (which might occur due to a bug in
  /// the analyzer), `null` is returned.
  InstantiatedClass _computeLeastUpperBound(
    InstantiatedClass i,
    InstantiatedClass j,
  ) {
    // compute set of supertypes
    var si = computeSuperinterfaceSet(i);
    var sj = computeSuperinterfaceSet(j);

    // union si with i and sj with j
    si.add(i);
    sj.add(j);

    // compute intersection, reference as set 's'
    var s = _intersection(si, sj);
    return _computeTypeAtMaxUniqueDepth(s);
  }

  /**
   * Return the length of the longest inheritance path from the [element] to
   * Object.
   */
  @visibleForTesting
  static int computeLongestInheritancePathToObject(ClassElement element) {
    return _computeLongestInheritancePathToObject(
      element,
      0,
      <ClassElement>{},
    );
  }

  /// Return all of the superinterfaces of the given [type].
  @visibleForTesting
  static Set<InstantiatedClass> computeSuperinterfaceSet(
      InstantiatedClass type) {
    var result = <InstantiatedClass>{};
    _addSuperinterfaces(result, type);
    return result;
  }

  /// Add all of the superinterfaces of the given [type] to the given [set].
  static void _addSuperinterfaces(
      Set<InstantiatedClass> set, InstantiatedClass type) {
    for (var interface in type.interfaces) {
      if (!interface.isDartCoreFunction) {
        if (set.add(interface)) {
          _addSuperinterfaces(set, interface);
        }
      }
    }

    for (var constraint in type.superclassConstraints) {
      if (!constraint.isDartCoreFunction) {
        if (set.add(constraint)) {
          _addSuperinterfaces(set, constraint);
        }
      }
    }

    var supertype = type.superclass;
    if (supertype != null && !supertype.isDartCoreFunction) {
      if (set.add(supertype)) {
        _addSuperinterfaces(set, supertype);
      }
    }
  }

  static NullabilitySuffix _chooseNullability(
    InterfaceTypeImpl type1,
    InterfaceTypeImpl type2,
  ) {
    var nullability1 = type1.nullabilitySuffix;
    var nullability2 = type2.nullabilitySuffix;
    if (nullability1 == NullabilitySuffix.question ||
        nullability2 == NullabilitySuffix.question) {
      return NullabilitySuffix.question;
    } else if (nullability1 == NullabilitySuffix.star ||
        nullability2 == NullabilitySuffix.star) {
      return NullabilitySuffix.star;
    }
    return NullabilitySuffix.none;
  }

  /// Return the length of the longest inheritance path from a subtype of the
  /// given [element] to Object, where the given [depth] is the length of the
  /// longest path from the subtype to this type. The set of [visitedElements]
  /// is used to prevent infinite recursion in the case of a cyclic type
  /// structure.
  static int _computeLongestInheritancePathToObject(
      ClassElement element, int depth, Set<ClassElement> visitedElements) {
    // Object case
    if (element.isDartCoreObject || visitedElements.contains(element)) {
      return depth;
    }
    int longestPath = 1;
    try {
      visitedElements.add(element);
      int pathLength;

      // loop through each of the superinterfaces recursively calling this
      // method and keeping track of the longest path to return
      for (InterfaceType interface in element.superclassConstraints) {
        pathLength = _computeLongestInheritancePathToObject(
            interface.element, depth + 1, visitedElements);
        if (pathLength > longestPath) {
          longestPath = pathLength;
        }
      }

      // loop through each of the superinterfaces recursively calling this
      // method and keeping track of the longest path to return
      for (InterfaceType interface in element.interfaces) {
        pathLength = _computeLongestInheritancePathToObject(
            interface.element, depth + 1, visitedElements);
        if (pathLength > longestPath) {
          longestPath = pathLength;
        }
      }

      // finally, perform this same check on the super type
      // TODO(brianwilkerson) Does this also need to add in the number of mixin
      // classes?
      InterfaceType supertype = element.supertype;
      if (supertype != null) {
        pathLength = _computeLongestInheritancePathToObject(
            supertype.element, depth + 1, visitedElements);
        if (pathLength > longestPath) {
          longestPath = pathLength;
        }
      }
    } finally {
      visitedElements.remove(element);
    }
    return longestPath;
  }

  /// Return the type from the [types] list that has the longest inheritance
  /// path to Object of unique length.
  static InstantiatedClass _computeTypeAtMaxUniqueDepth(
    List<InstantiatedClass> types,
  ) {
    // for each element in Set s, compute the largest inheritance path to Object
    List<int> depths = List<int>.filled(types.length, 0);
    int maxDepth = 0;
    for (int i = 0; i < types.length; i++) {
      depths[i] = computeLongestInheritancePathToObject(types[i].element);
      if (depths[i] > maxDepth) {
        maxDepth = depths[i];
      }
    }
    // ensure that the currently computed maxDepth is unique,
    // otherwise, decrement and test for uniqueness again
    for (; maxDepth >= 0; maxDepth--) {
      int indexOfLeastUpperBound = -1;
      int numberOfTypesAtMaxDepth = 0;
      for (int m = 0; m < depths.length; m++) {
        if (depths[m] == maxDepth) {
          numberOfTypesAtMaxDepth++;
          indexOfLeastUpperBound = m;
        }
      }
      if (numberOfTypesAtMaxDepth == 1) {
        return types[indexOfLeastUpperBound];
      }
    }
    // Should be impossible--there should always be exactly one type with the
    // maximum depth.
    assert(false);
    return null;
  }

  /**
   * Return the intersection of the [first] and [second] sets of types, where
   * intersection is based on the equality of the types themselves.
   */
  static List<InstantiatedClass> _intersection(
    Set<InstantiatedClass> first,
    Set<InstantiatedClass> second,
  ) {
    var result = first.toSet();
    result.retainAll(second);
    return result.toList();
  }
}

/// Used to check for infinite loops, if we repeat the same type comparison.
class TypeComparison {
  final DartType lhs;
  final DartType rhs;

  TypeComparison(this.lhs, this.rhs);

  @override
  int get hashCode => lhs.hashCode * 11 + rhs.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is TypeComparison) {
      return lhs == other.lhs && rhs == other.rhs;
    }

    return false;
  }

  @override
  String toString() => "$lhs vs $rhs";
}

/**
 * The interface `TypeSystem` defines the behavior of an object representing
 * the type system.  This provides a common location to put methods that act on
 * types but may need access to more global data structures, and it paves the
 * way for a possible future where we may wish to make the type system
 * pluggable.
 */
// TODO(brianwilkerson) Rename this class to TypeSystemImpl.
abstract class TypeSystem implements public.TypeSystem {
  /// If `true`, then NNBD type rules should be used.
  /// If `false`, then legacy type rules should be used.
  final bool isNonNullableByDefault;

  TypeSystem({@required this.isNonNullableByDefault});

  /**
   * The provider of types for the system
   */
  TypeProvider get typeProvider;

  @override
  DartType flatten(DartType type) {
    if (type is InterfaceType) {
      // Implement the cases:
      //  - "If T = FutureOr<S> then flatten(T) = S."
      //  - "If T = Future<S> then flatten(T) = S."
      if (type.isDartAsyncFutureOr || type.isDartAsyncFuture) {
        return type.typeArguments.isNotEmpty
            ? type.typeArguments[0]
            : DynamicTypeImpl.instance;
      }
      // Implement the case: "Otherwise if T <: Future then let S be a type
      // such that T << Future<S> and for all R, if T << Future<R> then S << R.
      // Then flatten(T) = S."
      //
      // In other words, given the set of all types R such that T << Future<R>,
      // let S be the most specific of those types, if any such S exists.
      //
      // Since we only care about the most specific type, it is sufficient to
      // look at the types appearing as a parameter to Future in the type
      // hierarchy of T.  We don't need to consider the supertypes of those
      // types, since they are by definition less specific.
      List<DartType> candidateTypes =
          _searchTypeHierarchyForFutureTypeParameters(type);
      DartType flattenResult =
          InterfaceTypeImpl.findMostSpecificType(candidateTypes, this);
      if (flattenResult != null) {
        return flattenResult;
      }
    }
    // Implement the case: "In any other circumstance, flatten(T) = T."
    return type;
  }

  List<InterfaceType> gatherMixinSupertypeConstraintsForInference(
      ClassElement mixinElement) {
    List<InterfaceType> candidates;
    if (mixinElement.isMixin) {
      candidates = mixinElement.superclassConstraints;
    } else {
      candidates = [mixinElement.supertype];
      candidates.addAll(mixinElement.mixins);
      if (mixinElement.isMixinApplication) {
        candidates.removeLast();
      }
    }
    return candidates
        .where((type) => type.element.typeParameters.isNotEmpty)
        .toList();
  }

  /**
   * Compute the least upper bound of two types.
   */
  DartType getLeastUpperBound(DartType type1, DartType type2);

  /**
   * Given a [DartType] [type], instantiate it with its bounds.
   *
   * The behavior of this method depends on the type system, for example, in
   * classic Dart `dynamic` will be used for all type arguments, whereas
   * strong mode prefers the actual bound type if it was specified.
   */
  DartType instantiateToBounds(DartType type, {List<bool> hasError});

  /**
   * Given a [DartType] [type] and a list of types
   * [typeArguments], instantiate the type formals with the
   * provided actuals.  If [type] is not a parameterized type,
   * no instantiation is done.
   */
  DartType instantiateType(DartType type, List<DartType> typeArguments) {
    if (type is FunctionType) {
      return type.instantiate(typeArguments);
    } else if (type is InterfaceTypeImpl) {
      // TODO(scheglov) Use `ClassElement.instantiate()`, don't use raw types.
      return type.element.instantiate(
        typeArguments: typeArguments,
        nullabilitySuffix: type.nullabilitySuffix,
      );
    } else {
      return type;
    }
  }

  /**
   * Given uninstantiated [typeFormals], instantiate them to their bounds.
   */
  List<DartType> instantiateTypeFormalsToBounds(
      List<TypeParameterElement> typeFormals,
      {List<bool> hasError});

  /**
   * Return `true` if the [leftType] is assignable to the [rightType] (that is,
   * if leftType <==> rightType).
   */
  @override
  bool isAssignableTo(DartType leftType, DartType rightType);

  /**
   * Return `true` if the [leftType] is more specific than the [rightType]
   * (that is, if leftType << rightType), as defined in the Dart language spec.
   *
   * In strong mode, this is equivalent to [isSubtypeOf].
   */
  @Deprecated('Use isSubtypeOf() instead.')
  bool isMoreSpecificThan(DartType leftType, DartType rightType);

  @override
  bool isNonNullable(DartType type) {
    if (type.isDynamic || type.isVoid || type.isDartCoreNull) {
      return false;
    } else if (type.nullabilitySuffix == NullabilitySuffix.question) {
      return false;
    } else if (type.isDartAsyncFutureOr) {
      return isNonNullable((type as InterfaceType).typeArguments[0]);
    } else if (type is TypeParameterType) {
      return isNonNullable(type.bound);
    }
    return true;
  }

  @override
  bool isNullable(DartType type) {
    if (type.isDynamic || type.isVoid || type.isDartCoreNull) {
      return true;
    } else if (type.nullabilitySuffix == NullabilitySuffix.question) {
      return true;
    } else if (type.isDartAsyncFutureOr) {
      return isNullable((type as InterfaceType).typeArguments[0]);
    }
    return false;
  }

  /// Check that [f1] is a subtype of [f2] for a member override.
  ///
  /// This is different from the normal function subtyping in two ways:
  /// - we know the function types are strict arrows,
  /// - it allows opt-in covariant parameters.
  bool isOverrideSubtypeOf(FunctionType f1, FunctionType f2);

  @override
  bool isPotentiallyNonNullable(DartType type) => !isNullable(type);

  @override
  bool isPotentiallyNullable(DartType type) => !isNonNullable(type);

  @override
  bool isStrictlyNonNullable(DartType type) {
    if (type.isDynamic || type.isVoid || type.isDartCoreNull) {
      return false;
    } else if (type.nullabilitySuffix != NullabilitySuffix.none) {
      return false;
    } else if (type is InterfaceType && type.isDartAsyncFutureOr) {
      return isStrictlyNonNullable(type.typeArguments[0]);
    } else if (type is TypeParameterType) {
      return isStrictlyNonNullable(type.bound);
    }
    return true;
  }

  /**
   * Return `true` if the [leftType] is a subtype of the [rightType] (that is,
   * if leftType <: rightType).
   */
  @override
  bool isSubtypeOf(DartType leftType, DartType rightType);

  @override
  DartType leastUpperBound(DartType leftType, DartType rightType) {
    return getLeastUpperBound(leftType, rightType);
  }

  /// Returns a nullable version of [type].  The result would be equivalent to
  /// the union `type | Null` (if we supported union types).
  DartType makeNullable(TypeImpl type) {
    // TODO(paulberry): handle type parameter types
    return type.withNullability(NullabilitySuffix.question);
  }

  /// Attempts to find the appropriate substitution for the [mixinElement]
  /// type parameters that can be applied to [srcTypes] to make it equal to
  /// [destTypes].  If no such substitution can be found, `null` is returned.
  List<DartType> matchSupertypeConstraints(
    ClassElement mixinElement,
    List<DartType> srcTypes,
    List<DartType> destTypes,
  ) {
    var typeParameters = mixinElement.typeParameters;
    var inferrer = GenericInferrer(this, typeParameters);
    for (int i = 0; i < srcTypes.length; i++) {
      inferrer.constrainReturnType(srcTypes[i], destTypes[i]);
      inferrer.constrainReturnType(destTypes[i], srcTypes[i]);
    }

    var inferredTypes = inferrer.infer(
      typeParameters,
      considerExtendsClause: false,
    );
    var substitution = Substitution.fromPairs(typeParameters, inferredTypes);

    for (int i = 0; i < srcTypes.length; i++) {
      if (substitution.substituteType(srcTypes[i]) != destTypes[i]) {
        // Failed to find an appropriate substitution
        return null;
      }
    }

    return inferredTypes;
  }

  /**
   * Searches the superinterfaces of [type] for implementations of [genericType]
   * and returns the most specific type argument used for that generic type.
   *
   * For a more general/robust solution, use [InterfaceTypeImpl.asInstanceOf].
   *
   * For example, given [type] `List<int>` and [genericType] `Iterable<T>`,
   * returns [int].
   *
   * Returns `null` if [type] does not implement [genericType].
   */
  DartType mostSpecificTypeArgument(DartType type, DartType genericType) {
    if (type is! InterfaceType) return null;
    if (genericType is! InterfaceType) return null;

    var asInstanceOf = (type as InterfaceTypeImpl)
        .asInstanceOf((genericType as InterfaceType).element);

    if (asInstanceOf != null) {
      return asInstanceOf.typeArguments[0];
    }

    return null;
  }

  /// Returns a non-nullable version of [type].  This is equivalent to the
  /// operation `NonNull` defined in the spec.
  @override
  DartType promoteToNonNull(DartType type) {
    if (type.isDartCoreNull) return NeverTypeImpl.instance;

    if (type is TypeParameterTypeImpl) {
      var element = type.element;
      var promotedBound =
          promoteToNonNull(element.bound ?? typeProvider.objectType);
      var identicalBound = identical(promotedBound, element.bound);
      if (identicalBound) {
        if (type.nullabilitySuffix == NullabilitySuffix.none) {
          return type;
        } else {
          return TypeParameterTypeImpl(
            element,
            nullabilitySuffix: NullabilitySuffix.none,
          );
        }
      } else {
        return TypeParameterTypeImpl(
          TypeParameterMember(element, null, promotedBound),
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }
    }

    return (type as TypeImpl).withNullability(NullabilitySuffix.none);
  }

  /**
   * Determine the type of a binary expression with the given [operator] whose
   * left operand has the type [leftType] and whose right operand has the type
   * [rightType], given that resolution has so far produced the [currentType].
   */
  DartType refineBinaryExpressionType(DartType leftType, TokenType operator,
      DartType rightType, DartType currentType) {
    // bool
    if (operator == TokenType.AMPERSAND_AMPERSAND ||
        operator == TokenType.BAR_BAR ||
        operator == TokenType.EQ_EQ ||
        operator == TokenType.BANG_EQ) {
      if (isNonNullableByDefault) {
        return promoteToNonNull(typeProvider.boolType);
      }
      return typeProvider.boolType;
    }
    if (leftType.isDartCoreInt) {
      // int op double
      if (operator == TokenType.MINUS ||
          operator == TokenType.PERCENT ||
          operator == TokenType.PLUS ||
          operator == TokenType.STAR ||
          operator == TokenType.MINUS_EQ ||
          operator == TokenType.PERCENT_EQ ||
          operator == TokenType.PLUS_EQ ||
          operator == TokenType.STAR_EQ) {
        if (rightType.isDartCoreDouble) {
          InterfaceTypeImpl doubleType = typeProvider.doubleType;
          if (isNonNullableByDefault) {
            return promoteToNonNull(doubleType);
          }
          return doubleType;
        }
      }
      // int op int
      if (operator == TokenType.MINUS ||
          operator == TokenType.PERCENT ||
          operator == TokenType.PLUS ||
          operator == TokenType.STAR ||
          operator == TokenType.TILDE_SLASH ||
          operator == TokenType.MINUS_EQ ||
          operator == TokenType.PERCENT_EQ ||
          operator == TokenType.PLUS_EQ ||
          operator == TokenType.STAR_EQ ||
          operator == TokenType.TILDE_SLASH_EQ) {
        if (rightType.isDartCoreInt) {
          InterfaceTypeImpl intType = typeProvider.intType;
          if (isNonNullableByDefault) {
            return promoteToNonNull(intType);
          }
          return intType;
        }
      }
    }
    // default
    return currentType;
  }

  @override
  DartType resolveToBound(DartType type) {
    if (type is TypeParameterTypeImpl) {
      var element = type.element;

      var bound = element.bound;
      if (bound == null) {
        return typeProvider.objectType;
      }

      NullabilitySuffix nullabilitySuffix = type.nullabilitySuffix;
      NullabilitySuffix newNullabilitySuffix;
      if (nullabilitySuffix == NullabilitySuffix.question ||
          bound.nullabilitySuffix == NullabilitySuffix.question) {
        newNullabilitySuffix = NullabilitySuffix.question;
      } else if (nullabilitySuffix == NullabilitySuffix.star ||
          bound.nullabilitySuffix == NullabilitySuffix.star) {
        newNullabilitySuffix = NullabilitySuffix.star;
      } else {
        newNullabilitySuffix = NullabilitySuffix.none;
      }

      var resolved = resolveToBound(bound) as TypeImpl;
      return resolved.withNullability(newNullabilitySuffix);
    }

    return type;
  }

  /**
   * Tries to promote from the first type from the second type, and returns the
   * promoted type if it succeeds, otherwise null.
   */
  DartType tryPromoteToType(DartType to, DartType from);

  /**
   * Given a [DartType] type, return the [TypeParameterElement]s corresponding
   * to its formal type parameters (if any).
   *
   * @param type the type whose type arguments are to be returned
   * @return the type arguments associated with the given type
   */
  List<TypeParameterElement> typeFormalsAsElements(DartType type) {
    if (type is FunctionType) {
      return type.typeFormals;
    } else if (type is InterfaceType) {
      return type.element.typeParameters;
    } else {
      return const <TypeParameterElement>[];
    }
  }

  /**
   * Starting from the given [type], search its class hierarchy for types of the
   * form Future<R>, and return a list of the resulting R's.
   */
  List<DartType> _searchTypeHierarchyForFutureTypeParameters(DartType type) {
    List<DartType> result = <DartType>[];
    HashSet<ClassElement> visitedClasses = HashSet<ClassElement>();
    void recurse(InterfaceTypeImpl type) {
      if (type.isDartAsyncFuture && type.typeArguments.isNotEmpty) {
        result.add(type.typeArguments[0]);
      }
      if (visitedClasses.add(type.element)) {
        if (type.superclass != null) {
          recurse(type.superclass);
        }
        for (InterfaceType interface in type.interfaces) {
          recurse(interface);
        }
        visitedClasses.remove(type.element);
      }
    }

    recurse(type);
    return result;
  }
}

/**
 * The [public.TypeSystem] implementation.
 */
class TypeSystemImpl extends Dart2TypeSystem {
  TypeSystemImpl({
    @required bool implicitCasts,
    @required bool isNonNullableByDefault,
    @required bool strictInference,
    @required TypeProvider typeProvider,
  }) : super(
          implicitCasts: implicitCasts,
          isNonNullableByDefault: isNonNullableByDefault,
          strictInference: strictInference,
          typeProvider: typeProvider,
        );
}

class TypeVariableEliminator extends Substitution {
  final TypeProvider _typeProvider;

  TypeVariableEliminator(this._typeProvider);

  @override
  DartType getSubstitute(TypeParameterElement parameter, bool upperBound) {
    return upperBound ? _typeProvider.nullType : _typeProvider.objectType;
  }
}

/// A type that is being inferred but is not currently known.
///
/// This type will only appear in a downward inference context for type
/// parameters that we do not know yet. Notationally it is written `?`, for
/// example `List<?>`. This is distinct from `List<dynamic>`. These types will
/// never appear in the final resolved AST.
class UnknownInferredType extends TypeImpl {
  static final UnknownInferredType instance = UnknownInferredType._();

  UnknownInferredType._() : super(UnknownInferredTypeElement.instance);

  @override
  int get hashCode => 1;

  @override
  bool get isDynamic => true;

  @Deprecated('Check element, or use getDisplayString()')
  @override
  String get name => Keyword.DYNAMIC.lexeme;

  @override
  NullabilitySuffix get nullabilitySuffix => NullabilitySuffix.star;

  @override
  bool operator ==(Object object) => identical(object, this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeUnknownInferredType();
  }

  @override
  DartType replaceTopAndBottom(TypeProvider typeProvider,
      {bool isCovariant = true}) {
    // In theory this should never happen, since we only need to do this
    // replacement when checking super-boundedness of explicitly-specified
    // types, or types produced by mixin inference or instantiate-to-bounds, and
    // the unknown type can't occur in any of those cases.
    assert(
        false, 'Attempted to check super-boundedness of a type including "?"');
    // But just in case it does, behave similar to `dynamic`.
    if (isCovariant) {
      return typeProvider.nullType;
    } else {
      return this;
    }
  }

  @override
  DartType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes) {
    int length = parameterTypes.length;
    for (int i = 0; i < length; i++) {
      if (parameterTypes[i] == this) {
        return argumentTypes[i];
      }
    }
    return this;
  }

  @override
  TypeImpl withNullability(NullabilitySuffix nullabilitySuffix) => this;

  /// Given a [type] T, return true if it does not have an unknown type `?`.
  static bool isKnown(DartType type) => !isUnknown(type);

  /// Given a [type] T, return true if it has an unknown type `?`.
  static bool isUnknown(DartType type) {
    if (identical(type, UnknownInferredType.instance)) {
      return true;
    }
    if (type is InterfaceTypeImpl) {
      return type.typeArguments.any(isUnknown);
    }
    if (type is FunctionType) {
      return isUnknown(type.returnType) ||
          type.parameters.any((p) => isUnknown(p.type));
    }
    return false;
  }
}

/// The synthetic element for [UnknownInferredType].
class UnknownInferredTypeElement extends ElementImpl
    implements TypeDefiningElement {
  static final UnknownInferredTypeElement instance =
      UnknownInferredTypeElement._();

  UnknownInferredTypeElement._() : super(Keyword.DYNAMIC.lexeme, -1) {
    setModifier(Modifier.SYNTHETIC, true);
  }

  @override
  ElementKind get kind => ElementKind.DYNAMIC;

  @override
  UnknownInferredType get type => UnknownInferredType.instance;

  @override
  T accept<T>(ElementVisitor visitor) => null;
}

/// A constraint on a type parameter that we're inferring.
class _TypeConstraint extends _TypeRange {
  /// The type parameter that is constrained by [lowerBound] or [upperBound].
  final TypeParameterElement typeParameter;

  /// Where this constraint comes from, used for error messages.
  ///
  /// See [toString].
  final _TypeConstraintOrigin origin;

  _TypeConstraint(this.origin, this.typeParameter,
      {DartType upper, DartType lower})
      : super(upper: upper, lower: lower);

  _TypeConstraint.fromExtends(
      TypeParameterElement element, DartType extendsType,
      {@required bool isNonNullableByDefault})
      : this(
            _TypeConstraintFromExtendsClause(
              element,
              extendsType,
              isNonNullableByDefault: isNonNullableByDefault,
            ),
            element,
            upper: extendsType);

  bool get isDownwards => origin is! _TypeConstraintFromArgument;

  bool isSatisifedBy(TypeSystemImpl ts, DartType type) =>
      ts.isSubtypeOf(lowerBound, type) && ts.isSubtypeOf(type, upperBound);

  /// Converts this constraint to a message suitable for a type inference error.
  @override
  String toString() => !identical(upperBound, UnknownInferredType.instance)
      ? "'$typeParameter' must extend '$upperBound'"
      : "'$lowerBound' must extend '$typeParameter'";
}

class _TypeConstraintFromArgument extends _TypeConstraintOrigin {
  final DartType argumentType;
  final DartType parameterType;
  final String parameterName;
  final ClassElement genericClass;

  _TypeConstraintFromArgument(
      this.argumentType, this.parameterType, this.parameterName,
      {this.genericClass, @required bool isNonNullableByDefault})
      : super(isNonNullableByDefault: isNonNullableByDefault);

  @override
  formatError() {
    // TODO(jmesserly): we should highlight the span. That would be more useful.
    // However in summary code it doesn't look like the AST node with span is
    // available.
    String prefix;
    if (genericClass != null &&
        (genericClass.name == "List" || genericClass.name == "Map") &&
        genericClass.library.isDartCore == true) {
      // This will become:
      //     "List element"
      //     "Map key"
      //     "Map value"
      prefix = "${genericClass.name} $parameterName";
    } else {
      prefix = "Parameter '$parameterName'";
    }

    return [
      prefix,
      "declared as     '${_typeStr(parameterType)}'",
      "but argument is '${_typeStr(argumentType)}'."
    ];
  }
}

class _TypeConstraintFromExtendsClause extends _TypeConstraintOrigin {
  final TypeParameterElement typeParam;
  final DartType extendsType;

  _TypeConstraintFromExtendsClause(this.typeParam, this.extendsType,
      {@required bool isNonNullableByDefault})
      : super(isNonNullableByDefault: isNonNullableByDefault);

  @override
  formatError() {
    return [
      "Type parameter '${typeParam.name}'",
      "declared to extend '${_typeStr(extendsType)}'."
    ];
  }
}

class _TypeConstraintFromFunctionContext extends _TypeConstraintOrigin {
  final DartType contextType;
  final DartType functionType;

  _TypeConstraintFromFunctionContext(this.functionType, this.contextType,
      {@required bool isNonNullableByDefault})
      : super(isNonNullableByDefault: isNonNullableByDefault);

  @override
  formatError() {
    return [
      "Function type",
      "declared as '${_typeStr(functionType)}'",
      "used where  '${_typeStr(contextType)}' is required."
    ];
  }
}

class _TypeConstraintFromReturnType extends _TypeConstraintOrigin {
  final DartType contextType;
  final DartType declaredType;

  _TypeConstraintFromReturnType(this.declaredType, this.contextType,
      {@required bool isNonNullableByDefault})
      : super(isNonNullableByDefault: isNonNullableByDefault);

  @override
  formatError() {
    return [
      "Return type",
      "declared as '${_typeStr(declaredType)}'",
      "used where  '${_typeStr(contextType)}' is required."
    ];
  }
}

/// The origin of a type constraint, for the purposes of producing a human
/// readable error message during type inference as well as determining whether
/// the constraint was used to fix the type parameter or not.
abstract class _TypeConstraintOrigin {
  final bool isNonNullableByDefault;

  _TypeConstraintOrigin({@required this.isNonNullableByDefault});

  List<String> formatError();

  String _typeStr(DartType type) {
    return type.getDisplayString(withNullability: isNonNullableByDefault);
  }
}

class _TypeRange {
  /// The upper bound of the type parameter. In other words, T <: upperBound.
  ///
  /// In Dart this can be written as `<T extends UpperBoundType>`.
  ///
  /// In inference, this can happen as a result of parameters of function type.
  /// For example, consider a signature like:
  ///
  ///     T reduce<T>(List<T> values, T f(T x, T y));
  ///
  /// and a call to it like:
  ///
  ///     reduce(values, (num x, num y) => ...);
  ///
  /// From the function expression's parameters, we conclude `T <: num`. We may
  /// still be able to conclude a different [lower] based on `values` or
  /// the type of the elided `=> ...` body. For example:
  ///
  ///      reduce(['x'], (num x, num y) => 'hi');
  ///
  /// Here the [lower] will be `String` and the upper bound will be `num`,
  /// which cannot be satisfied, so this is ill typed.
  final DartType upperBound;

  /// The lower bound of the type parameter. In other words, lowerBound <: T.
  ///
  /// This kind of constraint cannot be expressed in Dart, but it applies when
  /// we're doing inference. For example, consider a signature like:
  ///
  ///     T pickAtRandom<T>(T x, T y);
  ///
  /// and a call to it like:
  ///
  ///     pickAtRandom(1, 2.0)
  ///
  /// when we see the first parameter is an `int`, we know that `int <: T`.
  /// When we see `double` this implies `double <: T`.
  /// Combining these constraints results in a lower bound of `num`.
  ///
  /// In general, we choose the lower bound as our inferred type, so we can
  /// offer the most constrained (strongest) result type.
  final DartType lowerBound;

  _TypeRange({DartType lower, DartType upper})
      : lowerBound = lower ?? UnknownInferredType.instance,
        upperBound = upper ?? UnknownInferredType.instance;

  /// Formats the typeRange as a string suitable for unit testing.
  ///
  /// For example, if [typeName] is 'T' and the range has bounds int and Object
  /// respectively, the returned string will be 'int <: T <: Object'.
  @visibleForTesting
  String format(String typeName, {@required bool withNullability}) {
    String typeStr(DartType type) {
      return type.getDisplayString(withNullability: withNullability);
    }

    var lowerString = identical(lowerBound, UnknownInferredType.instance)
        ? ''
        : '${typeStr(lowerBound)} <: ';
    var upperString = identical(upperBound, UnknownInferredType.instance)
        ? ''
        : ' <: ${typeStr(upperBound)}';
    return '$lowerString$typeName$upperString';
  }

  @override
  String toString() => format('(type)', withNullability: true);
}
