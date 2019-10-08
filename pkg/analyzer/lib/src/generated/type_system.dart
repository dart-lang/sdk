// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart' show AstNode, ConstructorName;
import 'package:analyzer/dart/ast/token.dart' show Keyword, TokenType;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart' as public;
import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart' show TypeParameterMember;
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/error/codes.dart' show HintCode, StrongModeCode;
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/utilities_dart.dart' show ParameterKind;
import 'package:meta/meta.dart';

/**
 * `void`, `dynamic`, and `Object` are all equivalent. However, this makes
 * LUB/GLB indeterministic. Therefore, for the cases of LUB/GLB, we have some
 * types which are more top than others.
 *
 * So, `void` < `Object` < `dynamic` for the purposes of LUB and GLB.
 *
 * This is expressed by their topiness (higher = more toppy).
 */
int _getTopiness(DartType t) {
  // TODO(mfairhurst): switch legacy Top checks to true Top checks
  assert(_isLegacyTop(t, orTrueTop: true), 'only Top types have a topiness');

  // Highest top
  if (t.isVoid) return 3;
  if (t.isDynamic) return 2;
  if (t.isObject) return 1;
  if (t.isDartAsyncFutureOr)
    return -3 + _getTopiness((t as InterfaceType).typeArguments[0]);
  // Lowest top

  assert(false, 'a Top type without a defined topiness');

  // Try to ensure that if this happens, its less toppy than an actual Top type.
  return -100000;
}

bool _isBottom(DartType t) {
  return (t.isBottom &&
          (t as TypeImpl).nullabilitySuffix != NullabilitySuffix.question) ||
      identical(t, UnknownInferredType.instance);
}

/// Is [t] the bottom of the legacy type hierarchy.
bool _isLegacyBottom(DartType t, {@required bool orTrueBottom}) {
  return (t.isBottom &&
          (t as TypeImpl).nullabilitySuffix == NullabilitySuffix.question) ||
      t.isDartCoreNull ||
      (orTrueBottom ? _isBottom(t) : false);
}

/// Is [t] the top of the legacy type hierarch.
bool _isLegacyTop(DartType t, {@required bool orTrueTop}) {
  if (t.isDartAsyncFutureOr) {
    return _isLegacyTop((t as InterfaceType).typeArguments[0],
        orTrueTop: orTrueTop);
  }
  if (t.isObject &&
      (t as TypeImpl).nullabilitySuffix == NullabilitySuffix.none) {
    return true;
  }
  return orTrueTop ? _isTop(t) : false;
}

bool _isTop(DartType t) {
  if (t.isDartAsyncFutureOr) {
    return _isTop((t as InterfaceType).typeArguments[0]);
  }
  return t.isDynamic ||
      (t.isObject &&
          (t as TypeImpl).nullabilitySuffix != NullabilitySuffix.none) ||
      t.isVoid ||
      identical(t, UnknownInferredType.instance);
}

/**
 * A type system that implements the type semantics for Dart 2.0.
 */
class Dart2TypeSystem extends TypeSystem {
  /// Track types currently being compared via type parameter bounds so that we
  /// can detect recursion.
  static Set<TypeComparison> _typeParameterBoundsComparisons =
      new HashSet<TypeComparison>();

  /**
   * False if implicit casts should always be disallowed, otherwise the
   * [FeatureSet] will be used.
   *
   * This affects the behavior of [isAssignableTo].
   */
  final bool implicitCasts;

  /// A flag indicating whether inference failures are allowed, off by default.
  ///
  /// This option is experimental and subject to change.
  final bool strictInference;

  final TypeProvider typeProvider;

  Dart2TypeSystem(this.typeProvider,
      {this.implicitCasts: true, this.strictInference: false});

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

  bool anyParameterType(FunctionType ft, bool predicate(DartType t)) {
    return ft.parameters.any((p) => predicate(p.type));
  }

  /// Given a type t, if t is an interface type with a call method
  /// defined, return the function type for the call method, otherwise
  /// return null.
  FunctionType getCallMethodType(DartType t) {
    if (t is InterfaceType) {
      return t.lookUpInheritedMethod("call")?.type;
    }
    return null;
  }

  /// Computes the greatest lower bound of [type1] and [type2].
  DartType getGreatestLowerBound(DartType type1, DartType type2) {
    // The greatest lower bound relation is reflexive.
    if (identical(type1, type2)) {
      return type1;
    }

    // For any type T, GLB(?, T) == T.
    if (identical(type1, UnknownInferredType.instance)) {
      return type2;
    }
    if (identical(type2, UnknownInferredType.instance)) {
      return type1;
    }

    // For the purpose of GLB, we say some Tops are subtypes (less toppy) than
    // the others. Return the least toppy.
    // TODO(mfairhurst): switch legacy Top checks to true Top checks
    if (_isLegacyTop(type1, orTrueTop: true) &&
        _isLegacyTop(type2, orTrueTop: true)) {
      return _getTopiness(type1) < _getTopiness(type2) ? type1 : type2;
    }

    // The GLB of top and any type is just that type.
    // Also GLB of bottom and any type is bottom.
    // TODO(mfairhurst): switch legacy Top checks to true Top checks
    // TODO(mfairhurst): switch legacy Bottom checks to true Bottom checks.
    if (_isLegacyTop(type1, orTrueTop: true) ||
        _isLegacyBottom(type2, orTrueBottom: true)) {
      return type2;
    }
    // TODO(mfairhurst): switch legacy Bottom checks to true Bottom checks
    if (_isLegacyTop(type2, orTrueTop: true) ||
        _isLegacyBottom(type1, orTrueBottom: true)) {
      return type1;
    }

    // Function types have structural GLB.
    if (type1 is FunctionType && type2 is FunctionType) {
      return _functionGreatestLowerBound(type1, type2);
    }

    // Otherwise, the GLB of two types is one of them it if it is a subtype of
    // the other.
    if (isSubtypeOf(type1, type2)) {
      return type1;
    }

    if (isSubtypeOf(type2, type1)) {
      return type2;
    }

    // No subtype relation, so no known GLB.
    // TODO(mfairhurst): implement fully NNBD GLB, and return Never (non-legacy)
    return BottomTypeImpl.instanceLegacy;
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
    var inferrer = new GenericInferrer(typeProvider, this, fnType.typeFormals);
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
    bool downwards: false,
    bool isConst: false,
  }) {
    if (typeParameters.isEmpty) {
      return null;
    }

    // Create a TypeSystem that will allow certain type parameters to be
    // inferred. It will optimistically assume these type parameters can be
    // subtypes (or supertypes) as necessary, and track the constraints that
    // are implied by this.
    var inferrer = new GenericInferrer(typeProvider, this, typeParameters);

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

  /**
   * Given uninstantiated [typeFormals], instantiate them to their bounds.
   * See the issue for the algorithm description.
   *
   * https://github.com/dart-lang/sdk/issues/27526#issuecomment-260021397
   */
  List<DartType> instantiateTypeFormalsToBounds(
      List<TypeParameterElement> typeFormals,
      {List<bool> hasError,
      Map<TypeParameterElement, DartType> knownTypes}) {
    int count = typeFormals.length;
    if (count == 0) {
      return const <DartType>[];
    }

    Set<TypeParameterElement> all = new Set<TypeParameterElement>();
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
      Set<DartType> visitedTypes = new HashSet<DartType>();

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

  /// Given the type defining [element], instantiate its type formals to
  /// their bounds.
  List<DartType> instantiateTypeFormalsToBounds2(Element element) {
    List<TypeParameterElement> typeParameters;
    if (element is ClassElement) {
      typeParameters = element.typeParameters;
    } else if (element is GenericTypeAliasElement) {
      typeParameters = element.typeParameters;
    } else {
      throw StateError('Unexpected: $element');
    }

    if (typeParameters.isEmpty) {
      return const <DartType>[];
    }

    return typeParameters
        .map((p) => (p as TypeParameterElementImpl).defaultType)
        .toList();
  }

  @override
  bool isAssignableTo(DartType fromType, DartType toType,
      {FeatureSet featureSet}) {
    // An actual subtype
    if (isSubtypeOf(fromType, toType)) {
      return true;
    }

    // A call method tearoff
    if (fromType is InterfaceType && acceptsFunctionType(toType)) {
      var callMethodType = getCallMethodType(fromType);
      if (callMethodType != null &&
          isAssignableTo(callMethodType, toType, featureSet: featureSet)) {
        return true;
      }
    }

    // First make sure --no-implicit-casts disables all downcasts, including
    // dynamic casts.
    if (!implicitCasts) {
      return false;
    }

    // Now handle NNBD default behavior, where we disable non-dynamic downcasts.
    if (featureSet != null && featureSet.isEnabled(Feature.non_nullable)) {
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

  bool isGroundType(DartType t) {
    // TODO(leafp): Revisit this.
    if (t is TypeParameterType) {
      return false;
    }
    // TODO(mfairhurst): switch legacy Top checks to true Top checks
    if (_isLegacyTop(t, orTrueTop: true)) {
      return true;
    }

    if (t is FunctionType) {
      // TODO(mfairhurst): switch legacy Top checks to true Top checks
      // TODO(mfairhurst): switch legacy Bottom checks to true Bottom checks
      if (!_isLegacyTop(t.returnType, orTrueTop: true) ||
          anyParameterType(
              t, (pt) => !_isLegacyBottom(pt, orTrueBottom: true))) {
        return false;
      } else {
        return true;
      }
    }

    if (t is InterfaceType) {
      List<DartType> typeArguments = t.typeArguments;
      for (DartType typeArgument in typeArguments) {
        // TODO(mfairhurst): switch legacy Top checks to true Top checks
        if (!_isLegacyTop(typeArgument, orTrueTop: true)) return false;
      }
      return true;
    }

    // We should not see any other type aside from malformed code.
    return false;
  }

  @override
  bool isMoreSpecificThan(DartType t1, DartType t2) => isSubtypeOf(t1, t2);

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

  /// Check if [_t1] is a subtype of [_t2].
  ///
  /// Partially updated to reflect
  /// https://github.com/dart-lang/language/blob/da5adf7eb5f2d479069d8660ed7ca7b230098510/resources/type-system/subtyping.md
  ///
  /// However, it does not correlate 1:1 and does not specialize Null vs Never
  /// cases. It also is not guaranteed to be exactly accurate vs the "spec"
  /// because it has slightly different order of operations. These should be
  /// brought in line or proven equivalent.
  @override
  bool isSubtypeOf(DartType _t1, DartType _t2) {
    var t1 = _t1 as TypeImpl;
    var t2 = _t2 as TypeImpl;

    // Convert Null to Never? so that NullabilitySuffix can handle more cases.
    if (t1.isDartCoreNull) {
      t1 = BottomTypeImpl.instanceNullable;
    }
    if (t2.isDartCoreNull) {
      t2 = BottomTypeImpl.instanceNullable;
    }

    if (identical(t1, t2)) {
      return true;
    }
    // The types are void, dynamic, bottom, interface types, function types,
    // FutureOr<T> and type parameters.
    //
    // We proceed by eliminating these different classes from consideration.

    // `?` is treated as a top and a bottom type during inference.
    if (identical(t1, UnknownInferredType.instance) ||
        identical(t2, UnknownInferredType.instance)) {
      return true;
    }

    // Trivial top case.
    if (_isTop(t2)) {
      return true;
    }

    // Legacy top case. Must be done now to find Object* <: Object.
    // TODO: handle false positives like FutureOr<Object?>* and T* extends int?.
    if (t1.nullabilitySuffix == NullabilitySuffix.star &&
        _isLegacyTop(t2, orTrueTop: false)) {
      return true;
    }

    // Having excluded RHS top, this now must be false.
    if (_isTop(t1)) {
      return false;
    }

    // Handle T1? <: T2
    if (t1.nullabilitySuffix == NullabilitySuffix.question) {
      if (t2.nullabilitySuffix == NullabilitySuffix.none) {
        // If T2 is not FutureOr<S2>, then subtype is false.
        if (!t2.isDartAsyncFutureOr) {
          return false;
        }

        // T1? <: FutureOr<S2> is true if S2 is nullable.
        final s2 = (t2 as InterfaceType).typeArguments[0];
        if (!isNullable(s2)) {
          return false;
        }
      }
    }

    // Legacy bottom cases
    if (_isLegacyBottom(t1, orTrueBottom: true)) {
      return true;
    }

    if (_isLegacyBottom(t2, orTrueBottom: true)) {
      return false;
    }

    // Handle FutureOr<T> union type.
    if (t1 is InterfaceTypeImpl && t1.isDartAsyncFutureOr) {
      var t1TypeArg = t1.typeArguments[0];
      if (t2 is InterfaceTypeImpl && t2.isDartAsyncFutureOr) {
        var t2TypeArg = t2.typeArguments[0];
        // FutureOr<A> <: FutureOr<B> iff A <: B
        return isSubtypeOf(t1TypeArg, t2TypeArg);
      }

      // given t1 is Future<A> | A, then:
      // (Future<A> | A) <: t2 iff Future<A> <: t2 and A <: t2.
      var t1Future = typeProvider.futureType2(t1TypeArg);
      return isSubtypeOf(t1Future, t2) && isSubtypeOf(t1TypeArg, t2);
    }

    if (t2 is InterfaceTypeImpl && t2.isDartAsyncFutureOr) {
      // given t2 is Future<A> | A, then:
      // t1 <: (Future<A> | A) iff t1 <: Future<A> or t1 <: A
      var t2TypeArg = t2.typeArguments[0];
      var t2Future = typeProvider.futureType2(t2TypeArg);
      return isSubtypeOf(t1, t2Future) || isSubtypeOf(t1, t2TypeArg);
    }

    // S <: T where S is a type variable
    //  T is not dynamic or object (handled above)
    //  True if T == S
    //  Or true if bound of S is S' and S' <: T
    if (t1 is TypeParameterTypeImpl) {
      if (t2 is TypeParameterTypeImpl &&
          t1.definition == t2.definition &&
          _typeParameterBoundsSubtype(t1.bound, t2.bound, true)) {
        return true;
      }

      DartType bound = t1.element.bound;
      return bound == null
          ? false
          : _typeParameterBoundsSubtype(bound, t2, false);
    }

    if (t2 is TypeParameterType) {
      return false;
    }

    // We've eliminated void, dynamic, bottom, type parameters, FutureOr,
    // nullable, and legacy nullable types. The only cases are the combinations
    // of interface type and function type.

    // A function type can only subtype an interface type if
    // the interface type is Function
    if (t1 is FunctionType && t2 is InterfaceType) {
      return t2.isDartCoreFunction;
    }

    if (t1 is InterfaceType && t2 is FunctionType) return false;

    // Two interface types
    if (t1 is InterfaceTypeImpl && t2 is InterfaceTypeImpl) {
      return _isInterfaceSubtypeOf(t1, t2, null);
    }

    return _isFunctionSubtypeOf(t1 as FunctionType, t2 as FunctionType);
  }

  /// Given a [type] T that may have an unknown type `?`, returns a type
  /// R such that R <: T for any type substituted for `?`.
  ///
  /// In practice this will always replace `?` with either bottom or top
  /// (dynamic), depending on the position of `?`.
  ///
  /// This implements the operation the spec calls "least closure", or
  /// sometimes "least closure with respect to `?`".
  DartType lowerBoundForType(DartType type) {
    return _substituteForUnknownType(type, lowerBound: true);
  }

  @override
  DartType refineBinaryExpressionType(DartType leftType, TokenType operator,
      DartType rightType, DartType currentType, FeatureSet featureSet) {
    if (leftType is TypeParameterType && leftType.bound.isDartCoreNum) {
      if (rightType == leftType || rightType.isDartCoreInt) {
        if (operator == TokenType.PLUS ||
            operator == TokenType.MINUS ||
            operator == TokenType.STAR ||
            operator == TokenType.PLUS_EQ ||
            operator == TokenType.MINUS_EQ ||
            operator == TokenType.STAR_EQ) {
          if (featureSet.isEnabled(Feature.non_nullable)) {
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
          if (featureSet.isEnabled(Feature.non_nullable)) {
            return promoteToNonNull(doubleType);
          }
          return doubleType;
        }
      }
      return currentType;
    }
    return super.refineBinaryExpressionType(
        leftType, operator, rightType, currentType, featureSet);
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
    if (from is TypeParameterTypeImpl) {
      if (isSubtypeOf(to, from.bound ?? DynamicTypeImpl.instance)) {
        var newElement = TypeParameterMember(from.element, null, to);
        return newElement.instantiate(
          nullabilitySuffix: from.nullabilitySuffix,
        );
      }
    }

    return null;
  }

  /// Given a [type] T that may have an unknown type `?`, returns a type
  /// R such that T <: R for any type substituted for `?`.
  ///
  /// In practice this will always replace `?` with either bottom or top
  /// (dynamic), depending on the position of `?`.
  ///
  /// This implements the operation the spec calls "greatest closure", or
  /// sometimes "greatest closure with respect to `?`".
  DartType upperBoundForType(DartType type) {
    return _substituteForUnknownType(type);
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
    return _substituteType(type, true, (type, lowerBound) {
      if (type is TypeParameterType) {
        return lowerBound ? typeProvider.nullType : typeProvider.objectType;
      }
      return type;
    });
  }

  /**
   * Compute the greatest lower bound of function types [f] and [g].
   *
   * The spec rules for GLB on function types, informally, are pretty simple:
   *
   * - If a parameter is required in both, it stays required.
   *
   * - If a positional parameter is optional or missing in one, it becomes
   *   optional.
   *
   * - Named parameters are unioned together.
   *
   * - For any parameter that exists in both functions, use the LUB of them as
   *   the resulting parameter type.
   *
   * - Use the GLB of their return types.
   */
  DartType _functionGreatestLowerBound(FunctionType f, FunctionType g) {
    // Calculate the LUB of each corresponding pair of parameters.
    List<ParameterElement> parameters = [];

    bool hasPositional = false;
    bool hasNamed = false;
    addParameter(
        String name, DartType fType, DartType gType, ParameterKind kind) {
      DartType paramType;
      if (fType != null && gType != null) {
        // If both functions have this parameter, include both of their types.
        paramType = getLeastUpperBound(fType, gType);
      } else {
        paramType = fType ?? gType;
      }

      parameters.add(new ParameterElementImpl.synthetic(name, paramType, kind));
    }

    // TODO(rnystrom): Right now, this assumes f and g do not have any type
    // parameters. Revisit that in the presence of generic methods.
    List<DartType> fRequired = f.normalParameterTypes;
    List<DartType> gRequired = g.normalParameterTypes;

    // We need some parameter names for in the synthesized function type.
    List<String> fRequiredNames = f.normalParameterNames;
    List<String> gRequiredNames = g.normalParameterNames;

    // Parameters that are required in both functions are required in the
    // result.
    int requiredCount = math.min(fRequired.length, gRequired.length);
    for (int i = 0; i < requiredCount; i++) {
      addParameter(fRequiredNames[i], fRequired[i], gRequired[i],
          ParameterKind.REQUIRED);
    }

    // Parameters that are optional or missing in either end up optional.
    List<DartType> fPositional = f.optionalParameterTypes;
    List<DartType> gPositional = g.optionalParameterTypes;
    List<String> fPositionalNames = f.optionalParameterNames;
    List<String> gPositionalNames = g.optionalParameterNames;

    int totalPositional = math.max(fRequired.length + fPositional.length,
        gRequired.length + gPositional.length);
    for (int i = requiredCount; i < totalPositional; i++) {
      // Find the corresponding positional parameters (required or optional) at
      // this index, if there is one.
      DartType fType;
      String fName;
      if (i < fRequired.length) {
        fType = fRequired[i];
        fName = fRequiredNames[i];
      } else if (i < fRequired.length + fPositional.length) {
        fType = fPositional[i - fRequired.length];
        fName = fPositionalNames[i - fRequired.length];
      }

      DartType gType;
      String gName;
      if (i < gRequired.length) {
        gType = gRequired[i];
        gName = gRequiredNames[i];
      } else if (i < gRequired.length + gPositional.length) {
        gType = gPositional[i - gRequired.length];
        gName = gPositionalNames[i - gRequired.length];
      }

      // The loop should not let us go past both f and g's positional params.
      assert(fType != null || gType != null);

      addParameter(fName ?? gName, fType, gType, ParameterKind.POSITIONAL);
      hasPositional = true;
    }

    // Union the named parameters together.
    // TODO(brianwilkerson) Handle the fact that named parameters can now be
    //  required.
    Map<String, DartType> fNamed = f.namedParameterTypes;
    Map<String, DartType> gNamed = g.namedParameterTypes;
    for (String name in fNamed.keys.toSet()..addAll(gNamed.keys)) {
      addParameter(name, fNamed[name], gNamed[name], ParameterKind.NAMED);
      hasNamed = true;
    }

    // Edge case. Dart does not support functions with both optional positional
    // and named parameters. If we would synthesize that, give up.
    if (hasPositional && hasNamed) return typeProvider.bottomType;

    // Calculate the GLB of the return type.
    DartType returnType = getGreatestLowerBound(f.returnType, g.returnType);
    return new FunctionElementImpl.synthetic(parameters, returnType).type;
  }

  @override
  DartType _functionParameterBound(DartType f, DartType g) =>
      getGreatestLowerBound(f, g);

  @override
  DartType _interfaceLeastUpperBound(InterfaceType type1, InterfaceType type2) {
    var helper = InterfaceLeastUpperBoundHelper(this);
    return helper.compute(type1, type2);
  }

  /// Check that [f1] is a subtype of [f2].
  bool _isFunctionSubtypeOf(FunctionType f1, FunctionType f2) {
    return FunctionTypeImpl.relate(f1, f2, isSubtypeOf,
        parameterRelation: (p1, p2) => isSubtypeOf(p2.type, p1.type),
        // Type parameter bounds are invariant.
        boundsRelation: (t1, t2, p1, p2) =>
            isSubtypeOf(t1, t2) && isSubtypeOf(t2, t1));
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

      assert(tArgs1.length == tArgs2.length);

      for (int i = 0; i < tArgs1.length; i++) {
        DartType t1 = tArgs1[i];
        DartType t2 = tArgs2[i];
        if (!isSubtypeOf(t1, t2)) {
          return false;
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
    visitedTypes ??= new HashSet<ClassElement>();
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

  /**
   * Returns the greatest or least closure of [type], which replaces `?`
   * ([UnknownInferredType]) with `dynamic` or `Null` as appropriate.
   *
   * If [lowerBound] is true, this will return the "least closure", otherwise
   * it returns the "greatest closure".
   */
  DartType _substituteForUnknownType(DartType type, {bool lowerBound: false}) {
    return _substituteType(type, lowerBound, (type, lowerBound) {
      if (identical(type, UnknownInferredType.instance)) {
        return lowerBound ? typeProvider.nullType : typeProvider.dynamicType;
      }
      return type;
    });
  }

  /**
   * Apply the [visitType] substitution to [type], using the result value if
   * different, otherwise recursively apply the substitution.
   *
   * This method is used for substituting `?` ([UnknownInferredType]) with its
   * greatest/least closure, and for eliminating type parameters for inference
   * of `const` objects.
   *
   * See also [_eliminateTypeVariables] and [_substituteForUnknownType].
   */
  DartType _substituteType(DartType type, bool lowerBound,
      DartType Function(DartType, bool) visitType) {
    // Apply the substitution to this type, and return the result if different.
    var newType = visitType(type, lowerBound);
    if (!identical(newType, type)) {
      return newType;
    }
    if (type is InterfaceTypeImpl) {
      // Generic types are covariant, so keep the constraint direction.
      var newTypeArgs = _transformList(
          type.typeArguments, (t) => _substituteType(t, lowerBound, visitType));
      if (identical(type.typeArguments, newTypeArgs)) return type;
      return new InterfaceTypeImpl(type.element,
          prunedTypedefs: type.prunedTypedefs,
          nullabilitySuffix: type.nullabilitySuffix)
        ..typeArguments = newTypeArgs;
    }
    if (type is FunctionType) {
      var parameters = type.parameters;
      var returnType = type.returnType;
      var newParameters = _transformList(parameters, (ParameterElement p) {
        // Parameters are contravariant, so flip the constraint direction.
        var newType = _substituteType(p.type, !lowerBound, visitType);
        return new ParameterElementImpl.synthetic(
            p.name,
            newType,
            // ignore: deprecated_member_use_from_same_package
            p.parameterKind);
      });
      // Return type is covariant.
      var newReturnType = _substituteType(returnType, lowerBound, visitType);
      if (identical(parameters, newParameters) &&
          identical(returnType, newReturnType)) {
        return type;
      }

      return new FunctionTypeImpl.synthetic(
        newReturnType,
        type.typeFormals,
        newParameters,
        nullabilitySuffix: (type as TypeImpl).nullabilitySuffix,
      );
    }
    return type;
  }

  bool _typeParameterBoundsSubtype(
      DartType t1, DartType t2, bool recursionValue) {
    TypeComparison comparison = TypeComparison(t1, t2);
    if (_typeParameterBoundsComparisons.contains(comparison)) {
      return recursionValue;
    }
    _typeParameterBoundsComparisons.add(comparison);
    try {
      return isSubtypeOf(t1, t2);
    } finally {
      _typeParameterBoundsComparisons.remove(comparison);
    }
  }

  /**
   * This currently just implements a simple least upper bound to
   * handle some common cases.  It also avoids some termination issues
   * with the naive spec algorithm.  The least upper bound of two types
   * (at least one of which is a type parameter) is computed here as:
   * 1. If either type is a supertype of the other, return it.
   * 2. If the first type is a type parameter, replace it with its bound,
   *    with recursive occurrences of itself replaced with Object.
   *    The second part of this should ensure termination.  Informally,
   *    each type variable instantiation in one of the arguments to the
   *    least upper bound algorithm now strictly reduces the number
   *    of bound variables in scope in that argument position.
   * 3. If the second type is a type parameter, do the symmetric operation
   *    to #2.
   *
   * It's not immediately obvious why this is symmetric in the case that both
   * of them are type parameters.  For #1, symmetry holds since subtype
   * is antisymmetric.  For #2, it's clearly not symmetric if upper bounds of
   * bottom are allowed.  Ignoring this (for various reasons, not least
   * of which that there's no way to write it), there's an informal
   * argument (that might even be right) that you will always either
   * end up expanding both of them or else returning the same result no matter
   * which order you expand them in.  A key observation is that
   * identical(expand(type1), type2) => subtype(type1, type2)
   * and hence the contra-positive.
   *
   * TODO(leafp): Think this through and figure out what's the right
   * definition.  Be careful about termination.
   *
   * I suspect in general a reasonable algorithm is to expand the innermost
   * type variable first.  Alternatively, you could probably choose to treat
   * it as just an instance of the interface type upper bound problem, with
   * the "inheritance" chain extended by the bounds placed on the variables.
   */
  @override
  DartType _typeParameterLeastUpperBound(DartType type1, DartType type2) {
    if (isSubtypeOf(type1, type2)) {
      return type2;
    }
    if (isSubtypeOf(type2, type1)) {
      return type1;
    }
    if (type1 is TypeParameterType) {
      type1 = type1
          .resolveToBound(typeProvider.objectType)
          .substitute2([typeProvider.objectType], [type1]);
      return getLeastUpperBound(type1, type2);
    }
    // We should only be called when at least one of the types is a
    // TypeParameterType
    type2 = type2
        .resolveToBound(typeProvider.objectType)
        .substitute2([typeProvider.objectType], [type2]);
    return getLeastUpperBound(type1, type2);
  }

  static List<T> _transformList<T>(List<T> list, T f(T t)) {
    List<T> newList;
    for (var i = 0; i < list.length; i++) {
      var item = list[i];
      var newItem = f(item);
      if (!identical(item, newItem)) {
        newList ??= new List.from(list);
        newList[i] = newItem;
      }
    }
    return newList ?? list;
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
  final Dart2TypeSystem _typeSystem;
  final TypeProvider typeProvider;
  final Map<TypeParameterElement, List<_TypeConstraint>> constraints = {};

  /// Buffer recording constraints recorded while performing a recursive call to
  /// [_matchSubtypeOf] that might fail, so that any constraints recorded during
  /// the failed match can be rewound.
  final _undoBuffer = <_TypeConstraint>[];

  GenericInferrer(this.typeProvider, this._typeSystem,
      Iterable<TypeParameterElement> typeFormals) {
    for (var formal in typeFormals) {
      constraints[formal] = [];
    }
  }

  /// Apply an argument constraint, which asserts that the [argument] staticType
  /// is a subtype of the [parameterType].
  void constrainArgument(
      DartType argumentType, DartType parameterType, String parameterName,
      {ClassElement genericClass}) {
    var origin = new _TypeConstraintFromArgument(
        argumentType, parameterType, parameterName,
        genericClass: genericClass);
    tryMatchSubtypeOf(argumentType, parameterType, origin, covariant: false);
  }

  /// Constrain a universal function type [fnType] used in a context
  /// [contextType].
  void constrainGenericFunctionInContext(
      FunctionType fnType, DartType contextType) {
    var origin = new _TypeConstraintFromFunctionContext(fnType, contextType);

    // Since we're trying to infer the instantiation, we want to ignore type
    // formals as we check the parameters and return type.
    var inferFnType =
        fnType.instantiate(TypeParameterTypeImpl.getTypes(fnType.typeFormals));
    tryMatchSubtypeOf(inferFnType, contextType, origin, covariant: true);
  }

  /// Apply a return type constraint, which asserts that the [declaredType]
  /// is a subtype of the [contextType].
  void constrainReturnType(DartType declaredType, DartType contextType) {
    var origin = new _TypeConstraintFromReturnType(declaredType, contextType);
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
      {bool considerExtendsClause: true,
      ErrorReporter errorReporter,
      AstNode errorNode,
      bool failAtError: false,
      bool downwardsInferPhase: false}) {
    // Initialize the inferred type array.
    //
    // In the downwards phase, they all start as `?` to offer reasonable
    // degradation for f-bounded type parameters.
    var inferredTypes = new List<DartType>.filled(
        typeFormals.length, UnknownInferredType.instance);
    var _inferTypeParameter = downwardsInferPhase
        ? _inferTypeParameterFromContext
        : _inferTypeParameterFromAll;

    for (int i = 0; i < typeFormals.length; i++) {
      TypeParameterElement typeParam = typeFormals[i];

      _TypeConstraint extendsClause;
      if (considerExtendsClause && typeParam.bound != null) {
        extendsClause = new _TypeConstraint.fromExtends(
            typeParam,
            Substitution.fromPairs(typeFormals, inferredTypes)
                .substituteType(typeParam.bound));
      }

      inferredTypes[i] =
          _inferTypeParameter(constraints[typeParam], extendsClause);
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
        var extendsConstraint =
            new _TypeConstraint.fromExtends(typeParam, typeParamBound);
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
        errorReporter
            ?.reportErrorForNode(StrongModeCode.COULD_NOT_INFER, errorNode, [
          typeParam.name,
          ' Inferred candidate type $inferred has type parameters'
              ' ${(inferred as FunctionType).typeFormals}, but a function with'
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
          errorReporter?.reportTypeErrorForNode(
              HintCode.INFERENCE_FAILURE_ON_INSTANCE_CREATION,
              errorNode,
              [constructorName]);
        }
        // TODO(srawlins): More inference failure cases, like functions, and
        // function expressions.
      }
    }

    // Use instantiate to bounds to finish things off.
    var hasError = new List<bool>.filled(typeFormals.length, false);
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
  DartType _chooseTypeFromConstraints(Iterable<_TypeConstraint> constraints,
      {bool toKnownType: false}) {
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
    }

    // Prefer the known bound, if any.
    // Otherwise take whatever bound has partial information, e.g. `Iterable<?>`
    //
    // For both of those, prefer the lower bound (arbitrary heuristic).
    if (UnknownInferredType.isKnown(lower)) {
      return lower;
    }
    if (UnknownInferredType.isKnown(upper)) {
      return upper;
    }
    if (!identical(UnknownInferredType.instance, lower)) {
      return toKnownType ? _typeSystem.lowerBoundForType(lower) : lower;
    }
    if (!identical(UnknownInferredType.instance, upper)) {
      return toKnownType ? _typeSystem.upperBoundForType(upper) : upper;
    }
    return lower;
  }

  String _formatError(TypeParameterElement typeParam, DartType inferred,
      Iterable<_TypeConstraint> constraints) {
    var intro = "Tried to infer '$inferred' for '${typeParam.name}'"
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
      satisified = "\nThe type '$inferred' was inferred from:\n$satisified";
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
      List<_TypeConstraint> constraints, _TypeConstraint extendsClause) {
    // See if we already fixed this type from downwards inference.
    // If so, then we aren't allowed to change it based on argument types.
    DartType t = _inferTypeParameterFromContext(
        constraints.where((c) => c.isDownwards), extendsClause);
    if (UnknownInferredType.isKnown(t)) {
      // Remove constraints that aren't downward ones; we'll ignore these for
      // error reporting, because inference already succeeded.
      constraints.removeWhere((c) => !c.isDownwards);
      return t;
    }

    if (extendsClause != null) {
      constraints = constraints.toList()..add(extendsClause);
    }

    var choice = _chooseTypeFromConstraints(constraints, toKnownType: true);
    return choice;
  }

  DartType _inferTypeParameterFromContext(
      Iterable<_TypeConstraint> constraints, _TypeConstraint extendsClause) {
    DartType t = _chooseTypeFromConstraints(constraints);
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
      return _chooseTypeFromConstraints(constraints);
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
      assert(tArgs1.length == tArgs2.length);
      for (int i = 0; i < tArgs1.length; i++) {
        if (!_matchSubtypeOf(
            tArgs1[i], tArgs2[i], new HashSet<Element>(), origin,
            covariant: covariant)) {
          return false;
        }
      }
      return true;
    }
    if (i1.isObject) {
      return false;
    }

    // Guard against loops in the class hierarchy
    bool guardedInterfaceSubtype(InterfaceType t1) {
      visited ??= new HashSet<Element>();
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
          var constraint = new _TypeConstraint(origin, t1.element, upper: t2);
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
          var constraint = new _TypeConstraint(origin, t2.element, lower: t1);
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
        var visitedSet = visited ?? new HashSet<Element>();
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

  static String _formatConstraints(Iterable<_TypeConstraint> constraints) {
    List<List<String>> lineParts =
        new Set<_TypeConstraintOrigin>.from(constraints.map((c) => c.origin))
            .map((o) => o.formatError())
            .toList();

    int prefixMax = lineParts.map((p) => p[0].length).fold(0, math.max);

    // Use a set to prevent identical message lines.
    // (It's not uncommon for the same constraint to show up in a few places.)
    var messageLines = new Set<String>.from(lineParts.map((parts) {
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
    return InterfaceTypeImpl.explicit(
      element,
      arguments,
      nullabilitySuffix: nullability,
    );
  }
}

class InterfaceLeastUpperBoundHelper {
  final TypeSystem typeSystem;

  InterfaceLeastUpperBoundHelper(this.typeSystem);

  /// This currently does not implement a very complete least upper bound
  /// algorithm, but handles a couple of the very common cases that are
  /// causing pain in real code.  The current algorithm is:
  /// 1. If either of the types is a supertype of the other, return it.
  ///    This is in fact the best result in this case.
  /// 2. If the two types have the same class element, then take the
  ///    pointwise least upper bound of the type arguments.  This is again
  ///    the best result, except that the recursive calls may not return
  ///    the true least upper bounds.  The result is guaranteed to be a
  ///    well-formed type under the assumption that the input types were
  ///    well-formed (and assuming that the recursive calls return
  ///    well-formed types).
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

      assert(args1.length == args2.length);
      var args = List<DartType>(args1.length);
      for (int i = 0; i < args1.length; i++) {
        args[i] = typeSystem.getLeastUpperBound(args1[i], args2[i]);
      }

      return new InterfaceTypeImpl.explicit(
        type1.element,
        args,
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
      Set<ClassElement>(),
    );
  }

  /// Return all of the superinterfaces of the given [type].
  @visibleForTesting
  static Set<InstantiatedClass> computeSuperinterfaceSet(
      InstantiatedClass type) {
    var result = Set<InstantiatedClass>();
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
    List<int> depths = new List<int>.filled(types.length, 0);
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
  DartType getLeastUpperBound(DartType type1, DartType type2) {
    // The least upper bound relation is reflexive.
    if (identical(type1, type2)) {
      return type1;
    }

    // For any type T, LUB(?, T) == T.
    if (identical(type1, UnknownInferredType.instance)) {
      return type2;
    }
    if (identical(type2, UnknownInferredType.instance)) {
      return type1;
    }

    // For the purpose of LUB, we say some Tops are subtypes (less toppy) than
    // the others. Return the most toppy.
    // TODO(mfairhurst): switch legacy Top checks to true Top checks
    if (_isLegacyTop(type1, orTrueTop: true) &&
        _isLegacyTop(type2, orTrueTop: true)) {
      return _getTopiness(type1) > _getTopiness(type2) ? type1 : type2;
    }

    // The least upper bound of top and any type T is top.
    // The least upper bound of bottom and any type T is T.
    // TODO(mfairhurst): switch legacy Top checks to true Top checks
    // TODO(mfairhurst): switch legacy Bottom checks to true Bottom checks
    if (_isLegacyTop(type1, orTrueTop: true) ||
        _isLegacyBottom(type2, orTrueBottom: true)) {
      return type1;
    }
    // TODO(mfairhurst): switch legacy Top checks to true Top checks
    // TODO(mfairhurst): switch legacy Bottom checks to true Bottom checks
    if (_isLegacyTop(type2, orTrueTop: true) ||
        _isLegacyBottom(type1, orTrueBottom: true)) {
      return type2;
    }

    if (type1 is TypeParameterType || type2 is TypeParameterType) {
      return _typeParameterLeastUpperBound(type1, type2);
    }

    // In Dart 1, the least upper bound of a function type and an interface type
    // T is the least upper bound of Function and T.
    //
    // In Dart 2, the result is `Function` iff T is `Function`, otherwise the
    // result is `Object`.
    if (type1 is FunctionType && type2 is InterfaceType) {
      return type2.isDartCoreFunction ? type2 : typeProvider.objectType;
    }
    if (type2 is FunctionType && type1 is InterfaceType) {
      return type1.isDartCoreFunction ? type1 : typeProvider.objectType;
    }

    // At this point type1 and type2 should both either be interface types or
    // function types.
    if (type1 is InterfaceType && type2 is InterfaceType) {
      return _interfaceLeastUpperBound(type1, type2);
    }

    if (type1 is FunctionType && type2 is FunctionType) {
      return _functionLeastUpperBound(type1, type2);
    }

    // Should never happen. As a defensive measure, return the dynamic type.
    assert(false);
    return typeProvider.dynamicType;
  }

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
    if (type is ParameterizedType) {
      return type.instantiate(typeArguments);
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
   * if leftType <==> rightType). Accepts a [FeatureSet] to correctly handle
   * NNBD implicit downcasts.
   */
  bool isAssignableTo(DartType leftType, DartType rightType,
      {FeatureSet featureSet});

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
    } else if ((type as TypeImpl).nullabilitySuffix ==
        NullabilitySuffix.question) {
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
    } else if ((type as TypeImpl).nullabilitySuffix ==
        NullabilitySuffix.question) {
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

  /**
   * Return `true` if the [leftType] is a subtype of the [rightType] (that is,
   * if leftType <: rightType).
   */
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
    var inferrer = new GenericInferrer(typeProvider, this, typeParameters);
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
  DartType promoteToNonNull(covariant TypeImpl type) {
    if (type.isDartCoreNull) return BottomTypeImpl.instance;

    if (type is TypeParameterTypeImpl) {
      var promotedElement = TypeParameterElementImpl.synthetic(
        type.element.name,
      );

      var bound = type.element.bound ?? typeProvider.objectType;
      promotedElement.bound = promoteToNonNull(bound);

      return TypeParameterTypeImpl(
        promotedElement,
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }

    return type.withNullability(NullabilitySuffix.none);
  }

  /**
   * Determine the type of a binary expression with the given [operator] whose
   * left operand has the type [leftType] and whose right operand has the type
   * [rightType], given that resolution has so far produced the [currentType].
   * The [featureSet] is used to determine whether any features that effect the
   * computation have been enabled.
   */
  DartType refineBinaryExpressionType(DartType leftType, TokenType operator,
      DartType rightType, DartType currentType, FeatureSet featureSet) {
    // bool
    if (operator == TokenType.AMPERSAND_AMPERSAND ||
        operator == TokenType.BAR_BAR ||
        operator == TokenType.EQ_EQ ||
        operator == TokenType.BANG_EQ) {
      if (featureSet.isEnabled(Feature.non_nullable)) {
        return promoteToNonNull(typeProvider.boolType as TypeImpl);
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
          if (featureSet.isEnabled(Feature.non_nullable)) {
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
          if (featureSet.isEnabled(Feature.non_nullable)) {
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

      var bound = element.bound as TypeImpl;
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
      return type.typeParameters;
    } else {
      return const <TypeParameterElement>[];
    }
  }

  /**
   * Given a [DartType] type, return the [DartType]s corresponding
   * to its formal type parameters (if any).
   *
   * @param type the type whose type arguments are to be returned
   * @return the type arguments associated with the given type
   */
  List<DartType> typeFormalsAsTypes(DartType type) =>
      TypeParameterTypeImpl.getTypes(typeFormalsAsElements(type));

  /**
   * Compute the least upper bound of function types [f] and [g].
   *
   * The spec rules for LUB on function types, informally, are pretty simple
   * (though unsound):
   *
   * - If the functions don't have the same number of required parameters,
   *   always return `Function`.
   *
   * - Discard any optional named or positional parameters the two types do not
   *   have in common.
   *
   * - Compute the LUB of each corresponding pair of parameter and return types.
   *   Return a function type with those types.
   */
  DartType _functionLeastUpperBound(FunctionType f, FunctionType g) {
    var fTypeFormals = f.typeFormals;
    var gTypeFormals = g.typeFormals;

    // If F and G differ in their number of type parameters, then the
    // least upper bound of F and G is Function.
    if (fTypeFormals.length != gTypeFormals.length) {
      return typeProvider.functionType;
    }

    // If F and G differ in bounds of their of type parameters, then the
    // least upper bound of F and G is Function.
    var freshTypeFormalTypes =
        FunctionTypeImpl.relateTypeFormals(f, g, (t, s, _, __) => t == s);
    if (freshTypeFormalTypes == null) {
      return typeProvider.functionType;
    }

    var typeFormals = freshTypeFormalTypes
        .map<TypeParameterElement>((t) => t.element)
        .toList();

    f = f.instantiate(freshTypeFormalTypes);
    g = g.instantiate(freshTypeFormalTypes);

    List<DartType> fRequired = f.normalParameterTypes;
    List<DartType> gRequired = g.normalParameterTypes;

    // We need some parameter names for in the synthesized function type, so
    // arbitrarily use f's.
    List<String> fRequiredNames = f.normalParameterNames;
    List<String> fPositionalNames = f.optionalParameterNames;

    // If F and G differ in their number of required parameters, then the
    // least upper bound of F and G is Function.
    if (fRequired.length != gRequired.length) {
      return typeProvider.functionType;
    }

    // Calculate the LUB of each corresponding pair of parameters.
    List<ParameterElement> parameters = [];

    for (int i = 0; i < fRequired.length; i++) {
      parameters.add(new ParameterElementImpl.synthetic(
          fRequiredNames[i],
          _functionParameterBound(fRequired[i], gRequired[i]),
          ParameterKind.REQUIRED));
    }

    List<DartType> fPositional = f.optionalParameterTypes;
    List<DartType> gPositional = g.optionalParameterTypes;

    // Ignore any extra optional positional parameters if one has more than the
    // other.
    int length = math.min(fPositional.length, gPositional.length);
    for (int i = 0; i < length; i++) {
      parameters.add(new ParameterElementImpl.synthetic(
          fPositionalNames[i],
          _functionParameterBound(fPositional[i], gPositional[i]),
          ParameterKind.POSITIONAL));
    }

    // TODO(brianwilkerson) Handle the fact that named parameters can now be
    //  required.
    Map<String, DartType> fNamed = f.namedParameterTypes;
    Map<String, DartType> gNamed = g.namedParameterTypes;
    for (String name in fNamed.keys.toSet()..retainAll(gNamed.keys)) {
      parameters.add(new ParameterElementImpl.synthetic(
          name,
          _functionParameterBound(fNamed[name], gNamed[name]),
          ParameterKind.NAMED));
    }

    // Calculate the LUB of the return type.
    DartType returnType = getLeastUpperBound(f.returnType, g.returnType);

    return FunctionTypeImpl.synthetic(returnType, typeFormals, parameters);
  }

  /**
   * Calculates the appropriate upper or lower bound of a pair of parameters
   * for two function types whose least upper bound is being calculated.
   *
   * In spec mode, this uses least upper bound, which... doesn't really make
   * much sense. Strong mode overrides this to use greatest lower bound.
   */
  DartType _functionParameterBound(DartType f, DartType g) =>
      getLeastUpperBound(f, g);

  /**
   * Given two [InterfaceType]s [type1] and [type2] return their least upper
   * bound in a type system specific manner.
   */
  DartType _interfaceLeastUpperBound(InterfaceType type1, InterfaceType type2);

  /**
   * Starting from the given [type], search its class hierarchy for types of the
   * form Future<R>, and return a list of the resulting R's.
   */
  List<DartType> _searchTypeHierarchyForFutureTypeParameters(DartType type) {
    List<DartType> result = <DartType>[];
    HashSet<ClassElement> visitedClasses = new HashSet<ClassElement>();
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

  /**
   * Given two [DartType]s [type1] and [type2] at least one of which is a
   * [TypeParameterType], return their least upper bound in a type system
   * specific manner.
   */
  DartType _typeParameterLeastUpperBound(DartType type1, DartType type2);

  /**
   * Create either a strong mode or regular type system based on context.
   */
  static TypeSystem create(AnalysisContext context) {
    var options = context.analysisOptions as AnalysisOptionsImpl;
    return new Dart2TypeSystem(context.typeProvider,
        implicitCasts: options.implicitCasts,
        strictInference: options.strictInference);
  }
}

/// A type that is being inferred but is not currently known.
///
/// This type will only appear in a downward inference context for type
/// parameters that we do not know yet. Notationally it is written `?`, for
/// example `List<?>`. This is distinct from `List<dynamic>`. These types will
/// never appear in the final resolved AST.
class UnknownInferredType extends TypeImpl {
  static final UnknownInferredType instance = new UnknownInferredType._();

  UnknownInferredType._()
      : super(UnknownInferredTypeElement.instance, Keyword.DYNAMIC.lexeme);

  @override
  int get hashCode => 1;

  @override
  bool get isDynamic => true;

  @override
  NullabilitySuffix get nullabilitySuffix => NullabilitySuffix.star;

  @override
  bool operator ==(Object object) => identical(object, this);

  @override
  void appendTo(StringBuffer buffer, Set<TypeImpl> types,
      {bool withNullability = false}) {
    buffer.write('?');
  }

  @override
  bool isMoreSpecificThan(DartType type,
      [bool withDynamic = false, Set<Element> visitedElements]) {
    // T is S
    if (identical(this, type)) {
      return true;
    }
    // else
    return withDynamic;
  }

  @override
  bool isSubtypeOf(DartType type) => true;

  @override
  bool isSupertypeOf(DartType type) => true;

  @override
  TypeImpl pruned(List<FunctionTypeAliasElement> prune) => this;

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
      List<DartType> argumentTypes, List<DartType> parameterTypes,
      [List<FunctionTypeAliasElement> prune]) {
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
      new UnknownInferredTypeElement._();

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
      TypeParameterElement element, DartType extendsType)
      : this(
            new _TypeConstraintFromExtendsClause(element, extendsType), element,
            upper: extendsType);

  bool get isDownwards => origin is! _TypeConstraintFromArgument;

  bool isSatisifedBy(TypeSystem ts, DartType type) =>
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
      {this.genericClass});

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
      "declared as     '$parameterType'",
      "but argument is '$argumentType'."
    ];
  }
}

class _TypeConstraintFromExtendsClause extends _TypeConstraintOrigin {
  final TypeParameterElement typeParam;
  final DartType extendsType;

  _TypeConstraintFromExtendsClause(this.typeParam, this.extendsType);

  @override
  formatError() {
    return [
      "Type parameter '${typeParam.name}'",
      "declared to extend '$extendsType'."
    ];
  }
}

class _TypeConstraintFromFunctionContext extends _TypeConstraintOrigin {
  final DartType contextType;
  final DartType functionType;

  _TypeConstraintFromFunctionContext(this.functionType, this.contextType);

  @override
  formatError() {
    return [
      "Function type",
      "declared as '$functionType'",
      "used where  '$contextType' is required."
    ];
  }
}

class _TypeConstraintFromReturnType extends _TypeConstraintOrigin {
  final DartType contextType;
  final DartType declaredType;

  _TypeConstraintFromReturnType(this.declaredType, this.contextType);

  @override
  formatError() {
    return [
      "Return type",
      "declared as '$declaredType'",
      "used where  '$contextType' is required."
    ];
  }
}

/// The origin of a type constraint, for the purposes of producing a human
/// readable error message during type inference as well as determining whether
/// the constraint was used to fix the type parameter or not.
abstract class _TypeConstraintOrigin {
  List<String> formatError();
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
  String format(String typeName) {
    var lowerString = identical(lowerBound, UnknownInferredType.instance)
        ? ''
        : '$lowerBound <: ';
    var upperString = identical(upperBound, UnknownInferredType.instance)
        ? ''
        : ' <: $upperBound';
    return '$lowerString$typeName$upperString';
  }

  @override
  String toString() => format('(type)');
}
