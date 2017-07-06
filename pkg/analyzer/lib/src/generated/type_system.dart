// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.type_system;

import 'dart:collection';
import 'dart:math' as math;

import 'package:analyzer/dart/ast/ast.dart' show AstNode;
import 'package:analyzer/dart/ast/token.dart' show Keyword, TokenType;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart' show TypeParameterMember;
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart' show StrongModeCode;
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/utilities_dart.dart' show ParameterKind;

bool _isBottom(DartType t, {bool dynamicIsBottom: false}) {
  return (t.isDynamic && dynamicIsBottom) ||
      t.isBottom ||
      t.isDartCoreNull ||
      identical(t, UnknownInferredType.instance);
}

bool _isTop(DartType t, {bool dynamicIsBottom: false}) {
  // TODO(leafp): Document the rules in play here
  if (t.isDartAsyncFutureOr) {
    return _isTop((t as InterfaceType).typeArguments[0]);
  }
  return (t.isDynamic && !dynamicIsBottom) ||
      t.isObject ||
      identical(t, UnknownInferredType.instance);
}

typedef bool _GuardedSubtypeChecker<T>(T t1, T t2, Set<TypeImpl> visitedTypes);

/**
 * Implementation of [TypeSystem] using the strong mode rules.
 * https://github.com/dart-lang/dev_compiler/blob/master/STRONG_MODE.md
 */
class StrongTypeSystemImpl extends TypeSystem {
  static bool _comparingTypeParameterBounds = false;

  /**
   * True if implicit casts should be allowed, otherwise false.
   *
   * This affects the behavior of [isAssignableTo].
   */
  final bool implicitCasts;

  /**
   * A list of non-nullable type names (e.g., 'int', 'bool', etc.).
   */
  final List<String> nonnullableTypes;

  final TypeProvider typeProvider;

  StrongTypeSystemImpl(this.typeProvider,
      {this.implicitCasts: true,
      this.nonnullableTypes: AnalysisOptionsImpl.NONNULLABLE_TYPES});

  @override
  bool get isStrong => true;

  bool anyParameterType(FunctionType ft, bool predicate(DartType t)) {
    return ft.parameters.any((p) => predicate(p.type));
  }

  @override
  FunctionType functionTypeToConcreteType(FunctionType t) {
    // TODO(jmesserly): should we use a real "fuzzyArrow" bit on the function
    // type? That would allow us to implement this in the subtype relation.
    // TODO(jmesserly): we'll need to factor this differently if we want to
    // move CodeChecker's functionality into existing analyzer. Likely we can
    // let the Expression have a strict arrow, then in places were we do
    // inference, convert back to a fuzzy arrow.

    if (!t.parameters.any((p) => p.type.isDynamic)) {
      return t;
    }
    ParameterElement shave(ParameterElement p) {
      if (p.type.isDynamic) {
        return new ParameterElementImpl.synthetic(
            p.name, typeProvider.objectType, p.parameterKind);
      }
      return p;
    }

    List<ParameterElement> parameters = t.parameters.map(shave).toList();
    FunctionElementImpl function = new FunctionElementImpl("", -1);
    function.isSynthetic = true;
    function.returnType = t.returnType;
    function.shareTypeParameters(t.typeFormals);
    function.shareParameters(parameters);
    return function.type = new FunctionTypeImpl(function);
  }

  /**
   * Given a type t, if t is an interface type with a call method
   * defined, return the definite function type for the call method,
   * otherwise return null.
   */
  FunctionType getCallMethodDefiniteType(DartType t) {
    var type = getCallMethodType(t);
    if (type == null) return type;
    return functionTypeToConcreteType(type);
  }

  /**
   * Given a type t, if t is an interface type with a call method
   * defined, return the function type for the call method, otherwise
   * return null.
   */
  FunctionType getCallMethodType(DartType t) {
    if (t is InterfaceType) {
      return t.lookUpInheritedMethod("call")?.type;
    }
    return null;
  }

  /// Computes the greatest lower bound of [type1] and [type2].
  DartType getGreatestLowerBound(DartType type1, DartType type2,
      {dynamicIsBottom: false}) {
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

    // The GLB of top and any type is just that type.
    // Also GLB of bottom and any type is bottom.
    if (_isTop(type1, dynamicIsBottom: dynamicIsBottom) ||
        _isBottom(type2, dynamicIsBottom: dynamicIsBottom)) {
      return type2;
    }
    if (_isTop(type2, dynamicIsBottom: dynamicIsBottom) ||
        _isBottom(type1, dynamicIsBottom: dynamicIsBottom)) {
      return type1;
    }

    // Treat void as top-like for GLB. This only comes into play with the
    // return types of two functions whose GLB is being taken. We allow a
    // non-void-returning function to subtype a void-returning one, so match
    // that logic here by treating the non-void arm as the subtype for GLB.
    if (type1.isVoid) {
      return type2;
    }
    if (type2.isVoid) {
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
    return typeProvider.bottomType;
  }

  /**
   * Compute the least supertype of [type], which is known to be an interface
   * type.
   *
   * In the event that the algorithm fails (which might occur due to a bug in
   * the analyzer), `null` is returned.
   */
  DartType getLeastNullableSupertype(InterfaceType type) {
    // compute set of supertypes
    List<InterfaceType> s = InterfaceTypeImpl
        .computeSuperinterfaceSet(type)
        .where(isNullableType)
        .toList();
    return InterfaceTypeImpl.computeTypeAtMaxUniqueDepth(s);
  }

  /**
   * Compute the least upper bound of two types.
   */
  @override
  DartType getLeastUpperBound(DartType type1, DartType type2,
      {bool dynamicIsBottom: false}) {
    if (isNullableType(type1) && isNonNullableType(type2)) {
      assert(type2 is InterfaceType);
      type2 = getLeastNullableSupertype(type2 as InterfaceType);
    }
    if (isNullableType(type2) && isNonNullableType(type1)) {
      assert(type1 is InterfaceType);
      type1 = getLeastNullableSupertype(type1 as InterfaceType);
    }
    return super
        .getLeastUpperBound(type1, type2, dynamicIsBottom: dynamicIsBottom);
  }

  /**
   * Given a generic function type `F<T0, T1, ... Tn>` and a context type C,
   * infer an instantiation of F, such that `F<S0, S1, ..., Sn>` <: C.
   *
   * This is similar to [inferGenericFunctionOrType], but the return type is also
   * considered as part of the solution.
   *
   * If this function is called with a [contextType] that is also
   * uninstantiated, or a [fnType] that is already instantiated, it will have
   * no effect and return [fnType].
   */
  FunctionType inferFunctionTypeInstantiation(
      FunctionType contextType, FunctionType fnType,
      {ErrorReporter errorReporter, AstNode errorNode}) {
    if (contextType.typeFormals.isNotEmpty || fnType.typeFormals.isEmpty) {
      return fnType;
    }

    // Create a TypeSystem that will allow certain type parameters to be
    // inferred. It will optimistically assume these type parameters can be
    // subtypes (or supertypes) as necessary, and track the constraints that
    // are implied by this.
    var inferrer = new _GenericInferrer(typeProvider, this, fnType.typeFormals);
    inferrer.constrainGenericFunctionInContext(fnType, contextType);

    // Infer and instantiate the resulting type.
    return inferrer.infer(fnType, fnType.typeFormals,
        errorReporter: errorReporter, errorNode: errorNode);
  }

  /// Infers a generic type, function, method, or list/map literal
  /// instantiation, using the downward context type as well as the argument
  /// types if available.
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
  T inferGenericFunctionOrType<T extends ParameterizedType>(
      T genericType,
      List<ParameterElement> parameters,
      List<DartType> argumentTypes,
      DartType returnContextType,
      {ErrorReporter errorReporter,
      AstNode errorNode,
      bool downwards: false}) {
    // TODO(jmesserly): expose typeFormals on ParameterizedType.
    List<TypeParameterElement> typeFormals = typeFormalsAsElements(genericType);
    if (typeFormals.isEmpty) {
      return genericType;
    }

    // Create a TypeSystem that will allow certain type parameters to be
    // inferred. It will optimistically assume these type parameters can be
    // subtypes (or supertypes) as necessary, and track the constraints that
    // are implied by this.
    var inferrer = new _GenericInferrer(typeProvider, this, typeFormals);

    DartType declaredReturnType =
        genericType is FunctionType ? genericType.returnType : genericType;

    if (returnContextType != null) {
      inferrer.constrainReturnType(declaredReturnType, returnContextType);
    }

    for (int i = 0; i < argumentTypes.length; i++) {
      // Try to pass each argument to each parameter, recording any type
      // parameter bounds that were implied by this assignment.
      inferrer.constrainArgument(
          argumentTypes[i], parameters[i].type, parameters[i].name,
          genericType: genericType);
    }

    return inferrer.infer(genericType, typeFormals,
        errorReporter: errorReporter,
        errorNode: errorNode,
        downwardsInferPhase: downwards);
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
      {List<bool> hasError, Map<TypeParameterType, DartType> knownTypes}) {
    List<TypeParameterElement> typeFormals = typeFormalsAsElements(type);
    int count = typeFormals.length;
    if (count == 0) {
      return type;
    }

    Set<TypeParameterType> all = new Set<TypeParameterType>();
    // all ground
    Map<TypeParameterType, DartType> defaults = knownTypes ?? {};
    // not ground
    Map<TypeParameterType, DartType> partials = {};

    for (TypeParameterElement typeParameterElement in typeFormals) {
      TypeParameterType typeParameter = typeParameterElement.type;
      all.add(typeParameter);
      if (!defaults.containsKey(typeParameter)) {
        if (typeParameter.bound == null) {
          defaults[typeParameter] = DynamicTypeImpl.instance;
        } else {
          partials[typeParameter] = typeParameter.bound;
        }
      }
    }

    List<TypeParameterType> getFreeParameters(DartType type) {
      List<TypeParameterType> parameters = null;

      void appendParameters(DartType type) {
        if (type is TypeParameterType && all.contains(type)) {
          parameters ??= <TypeParameterType>[];
          parameters.add(type);
        } else if (type is ParameterizedType) {
          type.typeArguments.forEach(appendParameters);
        }
      }

      appendParameters(type);
      return parameters;
    }

    bool hasProgress = true;
    while (hasProgress) {
      hasProgress = false;
      for (TypeParameterType parameter in partials.keys) {
        DartType value = partials[parameter];
        List<TypeParameterType> freeParameters = getFreeParameters(value);
        if (freeParameters == null) {
          defaults[parameter] = value;
          partials.remove(parameter);
          hasProgress = true;
          break;
        } else if (freeParameters.every(defaults.containsKey)) {
          defaults[parameter] = value.substitute2(
              defaults.values.toList(), defaults.keys.toList());
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
      for (TypeParameterType parameter in partials.keys) {
        domain.add(parameter);
        range.add(DynamicTypeImpl.instance);
      }
      // Set the default for an uncompleted type variable (T extends B)
      // to be Phi(B)
      for (TypeParameterType parameter in partials.keys) {
        defaults[parameter] = partials[parameter].substitute2(range, domain);
      }
    }

    List<DartType> orderedArguments =
        typeFormals.map((p) => defaults[p.type]).toList();
    return instantiateType(type, orderedArguments);
  }

  @override
  bool isAssignableTo(DartType fromType, DartType toType) {
    // TODO(leafp): Document the rules in play here

    // An actual subtype
    if (isSubtypeOf(fromType, toType)) {
      return true;
    }

    if (!implicitCasts) {
      return false;
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

    // If the subtype relation goes the other way, allow the implicit
    // downcast.
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
    if (_isTop(t)) {
      return true;
    }

    if (t is FunctionType) {
      if (!_isTop(t.returnType) ||
          anyParameterType(t, (pt) => !_isBottom(pt, dynamicIsBottom: true))) {
        return false;
      } else {
        return true;
      }
    }

    if (t is InterfaceType) {
      List<DartType> typeArguments = t.typeArguments;
      for (DartType typeArgument in typeArguments) {
        if (!_isTop(typeArgument)) return false;
      }
      return true;
    }

    // We should not see any other type aside from malformed code.
    return false;
  }

  @override
  bool isMoreSpecificThan(DartType t1, DartType t2) => isSubtypeOf(t1, t2);

  /// Check if [type] is in a set of preselected non-nullable types.
  /// [FunctionType]s are always nullable.
  bool isNonNullableType(DartType type) {
    return !isNullableType(type);
  }

  /// Opposite of [isNonNullableType].
  bool isNullableType(DartType type) {
    return type is FunctionType ||
        !nonnullableTypes.contains(_getTypeFullyQualifiedName(type));
  }

  /// Check that [f1] is a subtype of [f2] for a member override.
  ///
  /// This is different from the normal function subtyping in two ways:
  /// - we know the function types are strict arrows,
  /// - it allows opt-in covariant parameters.
  bool isOverrideSubtypeOf(FunctionType f1, FunctionType f2) {
    return FunctionTypeImpl.relate(f1, f2, isSubtypeOf, instantiateToBounds,
        parameterRelation: isOverrideSubtypeOfParameter);
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

  @override
  bool isSubtypeOf(DartType leftType, DartType rightType) {
    return _isSubtypeOf(leftType, rightType, null);
  }

  /// Given a [type] T that may have an unknown type `?`, returns a type
  /// R such that R <: T for any type substituted for `?`.
  ///
  /// In practice this will always replace `?` with either bottom or top
  /// (dynamic), depending on the position of `?`.
  DartType lowerBoundForType(DartType type) {
    return _substituteForUnknownType(type, lowerBound: true);
  }

  @override
  DartType refineBinaryExpressionType(DartType leftType, TokenType operator,
      DartType rightType, DartType currentType) {
    if (leftType is TypeParameterType &&
        leftType.element.bound == typeProvider.numType) {
      if (rightType == leftType || rightType == typeProvider.intType) {
        if (operator == TokenType.PLUS ||
            operator == TokenType.MINUS ||
            operator == TokenType.STAR ||
            operator == TokenType.PLUS_EQ ||
            operator == TokenType.MINUS_EQ ||
            operator == TokenType.STAR_EQ) {
          return leftType;
        }
      }
      if (rightType == typeProvider.doubleType) {
        if (operator == TokenType.PLUS ||
            operator == TokenType.MINUS ||
            operator == TokenType.STAR ||
            operator == TokenType.SLASH) {
          return typeProvider.doubleType;
        }
      }
      return currentType;
    }
    return super
        .refineBinaryExpressionType(leftType, operator, rightType, currentType);
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
      if (isSubtypeOf(to, from.resolveToBound(DynamicTypeImpl.instance))) {
        return new TypeParameterMember(from.element, null, to).type;
      }
    }

    return null;
  }

  @override
  DartType typeToConcreteType(DartType t) {
    if (t is FunctionType) {
      return functionTypeToConcreteType(t);
    }
    return t;
  }

  /// Given a [type] T that may have an unknown type `?`, returns a type
  /// R such that T <: R for any type substituted for `?`.
  ///
  /// In practice this will always replace `?` with either bottom or top
  /// (dynamic), depending on the position of `?`.
  DartType upperBoundForType(DartType type) {
    return _substituteForUnknownType(type);
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
        paramType = getLeastUpperBound(fType, gType, dynamicIsBottom: true);
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
      getGreatestLowerBound(f, g, dynamicIsBottom: true);

  /// Given a type return its name prepended with the URI to its containing
  /// library and separated by a comma.
  String _getTypeFullyQualifiedName(DartType type) {
    return "${type?.element?.library?.identifier},$type";
  }

  /**
   * Guard against loops in the class hierarchy
   */
  _GuardedSubtypeChecker<DartType> _guard(
      _GuardedSubtypeChecker<DartType> check) {
    return (DartType t1, DartType t2, Set<TypeImpl> visitedTypes) {
      if (visitedTypes == null) {
        visitedTypes = new HashSet<TypeImpl>();
      }
      if (t1 == null || !visitedTypes.add(t1)) {
        return false;
      }
      try {
        return check(t1, t2, visitedTypes);
      } finally {
        visitedTypes.remove(t1);
      }
    };
  }

  /**
   * This currently does not implement a very complete least upper bound
   * algorithm, but handles a couple of the very common cases that are
   * causing pain in real code.  The current algorithm is:
   * 1. If either of the types is a supertype of the other, return it.
   *    This is in fact the best result in this case.
   * 2. If the two types have the same class element, then take the
   *    pointwise least upper bound of the type arguments.  This is again
   *    the best result, except that the recursive calls may not return
   *    the true least upper bounds.  The result is guaranteed to be a
   *    well-formed type under the assumption that the input types were
   *    well-formed (and assuming that the recursive calls return
   *    well-formed types).
   * 3. Otherwise return the spec-defined least upper bound.  This will
   *    be an upper bound, might (or might not) be least, and might
   *    (or might not) be a well-formed type.
   *
   * TODO(leafp): Use matchTypes or something similar here to handle the
   *  case where one of the types is a superclass (but not supertype) of
   *  the other, e.g. LUB(Iterable<double>, List<int>) = Iterable<num>
   * TODO(leafp): Figure out the right final algorithm and implement it.
   */
  @override
  DartType _interfaceLeastUpperBound(InterfaceType type1, InterfaceType type2) {
    if (isSubtypeOf(type1, type2)) {
      return type2;
    }
    if (isSubtypeOf(type2, type1)) {
      return type1;
    }
    if (type1.element == type2.element) {
      List<DartType> tArgs1 = type1.typeArguments;
      List<DartType> tArgs2 = type2.typeArguments;

      assert(tArgs1.length == tArgs2.length);
      List<DartType> tArgs = new List(tArgs1.length);
      for (int i = 0; i < tArgs1.length; i++) {
        tArgs[i] = getLeastUpperBound(tArgs1[i], tArgs2[i]);
      }
      InterfaceTypeImpl lub = new InterfaceTypeImpl(type1.element);
      lub.typeArguments = tArgs;
      return lub;
    }
    return InterfaceTypeImpl.computeLeastUpperBound(type1, type2) ??
        typeProvider.dynamicType;
  }

  /// Check that [f1] is a subtype of [f2].
  ///
  /// This will always assume function types use fuzzy arrows, in other words
  /// that dynamic parameters of f1 and f2 are treated as bottom.
  bool _isFunctionSubtypeOf(
      FunctionType f1, FunctionType f2, Set<TypeImpl> visitedTypes) {
    return FunctionTypeImpl.relate(f1, f2, isSubtypeOf, instantiateToBounds,
        parameterRelation: (p1, p2) => _isSubtypeOf(
            p2.type, p1.type, visitedTypes,
            dynamicIsBottom: true));
  }

  bool _isInterfaceSubtypeOf(
      InterfaceType i1, InterfaceType i2, Set<TypeImpl> visitedTypes) {
    if (identical(i1, i2)) {
      return true;
    }

    // Guard recursive calls
    _GuardedSubtypeChecker<InterfaceType> guardedInterfaceSubtype = _guard(
        (DartType i1, DartType i2, Set<TypeImpl> visitedTypes) =>
            _isInterfaceSubtypeOf(i1, i2, visitedTypes));

    if (i1.element == i2.element) {
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

    if (i2.isDartCoreFunction && i1.element.getMethod("call") != null) {
      return true;
    }

    if (i1.isObject) {
      return false;
    }

    if (guardedInterfaceSubtype(i1.superclass, i2, visitedTypes)) {
      return true;
    }

    for (final parent in i1.interfaces) {
      if (guardedInterfaceSubtype(parent, i2, visitedTypes)) {
        return true;
      }
    }

    for (final parent in i1.mixins) {
      if (guardedInterfaceSubtype(parent, i2, visitedTypes)) {
        return true;
      }
    }

    return false;
  }

  bool _isSubtypeOf(DartType t1, DartType t2, Set<TypeImpl> visitedTypes,
      {bool dynamicIsBottom: false}) {
    if (identical(t1, t2)) {
      return true;
    }

    // The types are void, dynamic, bottom, interface types, function types,
    // FutureOr<T> and type parameters.
    //
    // We proceed by eliminating these different classes from consideration.

    // Trivially true.
    //
    // Note that `?` is treated as a top and a bottom type during inference,
    // so it's also covered here.
    if (_isTop(t2, dynamicIsBottom: dynamicIsBottom) ||
        _isBottom(t1, dynamicIsBottom: dynamicIsBottom)) {
      return true;
    }

    // Trivially false.
    if (_isTop(t1, dynamicIsBottom: dynamicIsBottom) ||
        _isBottom(t2, dynamicIsBottom: dynamicIsBottom)) {
      return false;
    }

    // Handle FutureOr<T> union type.
    if (t1 is InterfaceType && t1.isDartAsyncFutureOr) {
      var t1TypeArg = t1.typeArguments[0];
      if (t2 is InterfaceType && t2.isDartAsyncFutureOr) {
        var t2TypeArg = t2.typeArguments[0];
        // FutureOr<A> <: FutureOr<B> iff A <: B
        return isSubtypeOf(t1TypeArg, t2TypeArg);
      }

      // given t1 is Future<A> | A, then:
      // (Future<A> | A) <: t2 iff Future<A> <: t2 and A <: t2.
      var t1Future = typeProvider.futureType.instantiate([t1TypeArg]);
      return isSubtypeOf(t1Future, t2) && isSubtypeOf(t1TypeArg, t2);
    }

    if (t2 is InterfaceType && t2.isDartAsyncFutureOr) {
      // given t2 is Future<A> | A, then:
      // t1 <: (Future<A> | A) iff t1 <: Future<A> or t1 <: A
      var t2TypeArg = t2.typeArguments[0];
      var t2Future = typeProvider.futureType.instantiate([t2TypeArg]);
      return isSubtypeOf(t1, t2Future) || isSubtypeOf(t1, t2TypeArg);
    }

    // S <: T where S is a type variable
    //  T is not dynamic or object (handled above)
    //  True if T == S
    //  Or true if bound of S is S' and S' <: T
    if (t1 is TypeParameterType) {
      if (t2 is TypeParameterType &&
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

    // Void only appears as the return type of a function, and we handle it
    // directly in the function subtype rules. We should not get to a point
    // where we're doing a subtype test on a "bare" void, but just in case we
    // do, handle it safely.
    // TODO(rnystrom): Determine how this can ever be reached. If it can't,
    // remove it.
    if (t1.isVoid || t2.isVoid) {
      return t1.isVoid && t2.isVoid;
    }

    // We've eliminated void, dynamic, bottom, type parameters, and FutureOr.
    // The only cases are the combinations of interface type and function type.

    // A function type can only subtype an interface type if
    // the interface type is Function
    if (t1 is FunctionType && t2 is InterfaceType) {
      return t2.isDartCoreFunction;
    }

    // Guard recursive calls
    _GuardedSubtypeChecker<FunctionType> guardedIsFunctionSubtype = _guard(
        (DartType t1, DartType t2, Set<TypeImpl> visitedTypes) =>
            _isFunctionSubtypeOf(
                t1 as FunctionType, t2 as FunctionType, visitedTypes));

    // An interface type can only subtype a function type if
    // the interface type declares a call method with a type
    // which is a super type of the function type.
    if (t1 is InterfaceType && t2 is FunctionType) {
      var callType = getCallMethodDefiniteType(t1);
      return callType != null &&
          guardedIsFunctionSubtype(callType, t2, visitedTypes);
    }

    // Two interface types
    if (t1 is InterfaceType && t2 is InterfaceType) {
      return _isInterfaceSubtypeOf(t1, t2, visitedTypes);
    }

    return guardedIsFunctionSubtype(t1, t2, visitedTypes);
  }

  DartType _substituteForUnknownType(DartType type,
      {bool lowerBound: false, dynamicIsBottom: false}) {
    if (identical(type, UnknownInferredType.instance)) {
      if (lowerBound && !dynamicIsBottom) {
        // TODO(jmesserly): this should be the bottom type, once i can be
        // reified.
        return typeProvider.nullType;
      }
      return typeProvider.dynamicType;
    }
    if (type is InterfaceTypeImpl) {
      // Generic types are covariant, so keep the constraint direction.
      var newTypeArgs = _transformList(type.typeArguments,
          (t) => _substituteForUnknownType(t, lowerBound: lowerBound));
      if (identical(type.typeArguments, newTypeArgs)) return type;
      return new InterfaceTypeImpl(type.element, type.prunedTypedefs)
        ..typeArguments = newTypeArgs;
    }
    if (type is FunctionType) {
      var parameters = type.parameters;
      var returnType = type.returnType;
      var newParameters = _transformList(parameters, (ParameterElement p) {
        // Parameters are contravariant, so flip the constraint direction.
        // Also pass dynamicIsBottom, because this is a fuzzy arrow.
        var newType = _substituteForUnknownType(p.type,
            lowerBound: !lowerBound, dynamicIsBottom: true);
        return new ParameterElementImpl.synthetic(
            p.name, newType, p.parameterKind);
      });
      // Return type is covariant.
      var newReturnType =
          _substituteForUnknownType(returnType, lowerBound: lowerBound);
      if (identical(parameters, newParameters) &&
          identical(returnType, newReturnType)) {
        return type;
      }

      var function = new FunctionElementImpl(type.name, -1)
        ..isSynthetic = true
        ..returnType = newReturnType
        ..shareTypeParameters(type.typeFormals)
        ..parameters = newParameters;
      return function.type = new FunctionTypeImpl(function);
    }
    return type;
  }

  bool _typeParameterBoundsSubtype(
      DartType t1, DartType t2, bool recursionValue) {
    if (_comparingTypeParameterBounds) {
      return recursionValue;
    }
    _comparingTypeParameterBounds = true;
    try {
      return isSubtypeOf(t1, t2);
    } finally {
      _comparingTypeParameterBounds = false;
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
    List<T> newList = null;
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

/**
 * The interface `TypeSystem` defines the behavior of an object representing
 * the type system.  This provides a common location to put methods that act on
 * types but may need access to more global data structures, and it paves the
 * way for a possible future where we may wish to make the type system
 * pluggable.
 */
abstract class TypeSystem {
  /**
   * Whether the type system is strong or not.
   */
  bool get isStrong;

  /**
   * The provider of types for the system
   */
  TypeProvider get typeProvider;

  /**
   * Make a function type concrete.
   *
   * Normally we treat dynamically typed parameters as bottom for function
   * types. This allows type tests such as `if (f is SingleArgFunction)`.
   * It also requires a dynamic check on the parameter type to call these
   * functions.
   *
   * When we convert to a strict arrow, dynamically typed parameters become
   * top. This is safe to do for known functions, like top-level or local
   * functions and static methods. Those functions must already be essentially
   * treating dynamic as top.
   *
   * Only the outer-most arrow can be strict. Any others must be fuzzy, because
   * we don't know what function value will be passed there.
   */
  FunctionType functionTypeToConcreteType(FunctionType t);

  /**
   * Compute the least upper bound of two types.
   */
  DartType getLeastUpperBound(DartType type1, DartType type2,
      {bool dynamicIsBottom: false}) {
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

    // The least upper bound of top and any type T is top.
    // The least upper bound of bottom and any type T is T.
    if (_isTop(type1, dynamicIsBottom: dynamicIsBottom) ||
        _isBottom(type2, dynamicIsBottom: dynamicIsBottom)) {
      return type1;
    }
    if (_isTop(type2, dynamicIsBottom: dynamicIsBottom) ||
        _isBottom(type1, dynamicIsBottom: dynamicIsBottom)) {
      return type2;
    }
    // The least upper bound of void and any type T != dynamic is void.
    if (type1.isVoid) {
      return type1;
    }
    if (type2.isVoid) {
      return type2;
    }

    if (type1 is TypeParameterType || type2 is TypeParameterType) {
      return _typeParameterLeastUpperBound(type1, type2);
    }

    // The least upper bound of a function type and an interface type T is the
    // least upper bound of Function and T.
    if (type1 is FunctionType && type2 is InterfaceType) {
      type1 = typeProvider.functionType;
    }
    if (type2 is FunctionType && type1 is InterfaceType) {
      type2 = typeProvider.functionType;
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
   * Return `true` if the [leftType] is assignable to the [rightType] (that is,
   * if leftType <==> rightType).
   */
  bool isAssignableTo(DartType leftType, DartType rightType);

  /**
   * Return `true` if the [leftType] is more specific than the [rightType]
   * (that is, if leftType << rightType), as defined in the Dart language spec.
   *
   * In strong mode, this is equivalent to [isSubtypeOf].
   */
  bool isMoreSpecificThan(DartType leftType, DartType rightType);

  /**
   * Return `true` if the [leftType] is a subtype of the [rightType] (that is,
   * if leftType <: rightType).
   */
  bool isSubtypeOf(DartType leftType, DartType rightType);

  /**
   * Searches the superinterfaces of [type] for implementations of [genericType]
   * and returns the most specific type argument used for that generic type.
   *
   * For example, given [type] `List<int>` and [genericType] `Iterable<T>`,
   * returns [int].
   *
   * Returns `null` if [type] does not implement [genericType].
   */
  // TODO(jmesserly): this is very similar to code used for flattening futures.
  // The only difference is, because of a lack of TypeProvider, the other method
  // has to match the Future type by its name and library. Here was are passed
  // in the correct type.
  DartType mostSpecificTypeArgument(DartType type, DartType genericType) {
    if (type is! InterfaceType) return null;

    // Walk the superinterface hierarchy looking for [genericType].
    List<DartType> candidates = <DartType>[];
    HashSet<ClassElement> visitedClasses = new HashSet<ClassElement>();
    void recurse(InterfaceType interface) {
      if (interface.element == genericType.element &&
          interface.typeArguments.isNotEmpty) {
        candidates.add(interface.typeArguments[0]);
      }
      if (visitedClasses.add(interface.element)) {
        if (interface.superclass != null) {
          recurse(interface.superclass);
        }
        interface.mixins.forEach(recurse);
        interface.interfaces.forEach(recurse);
        visitedClasses.remove(interface.element);
      }
    }

    recurse(type);

    // Since the interface may be implemented multiple times with different
    // type arguments, choose the best one.
    return InterfaceTypeImpl.findMostSpecificType(candidates, this);
  }

  /**
   * Attempts to make a better guess for the type of a binary with the given
   * [operator], given that resolution has so far produced the [currentType].
   */
  DartType refineBinaryExpressionType(DartType leftType, TokenType operator,
      DartType rightType, DartType currentType) {
    // bool
    if (operator == TokenType.AMPERSAND_AMPERSAND ||
        operator == TokenType.BAR_BAR ||
        operator == TokenType.EQ_EQ ||
        operator == TokenType.BANG_EQ) {
      return typeProvider.boolType;
    }
    DartType intType = typeProvider.intType;
    if (leftType == intType) {
      // int op double
      if (operator == TokenType.MINUS ||
          operator == TokenType.PERCENT ||
          operator == TokenType.PLUS ||
          operator == TokenType.STAR ||
          operator == TokenType.MINUS_EQ ||
          operator == TokenType.PERCENT_EQ ||
          operator == TokenType.PLUS_EQ ||
          operator == TokenType.STAR_EQ) {
        DartType doubleType = typeProvider.doubleType;
        if (rightType == doubleType) {
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
        if (rightType == intType) {
          return intType;
        }
      }
    }
    // default
    return currentType;
  }

  /**
   * Tries to promote from the first type from the second type, and returns the
   * promoted type if it succeeds, otherwise null.
   *
   * In the Dart 1 type system, it is not possible to promote from or to
   * `dynamic`, and we must be promoting to a more specific type, see
   * [isMoreSpecificThan]. Also it will always return the promote [to] type or
   * null.
   *
   * In strong mode, this can potentially return a different type, see
   * the override in [StrongTypeSystemImpl].
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
      return TypeParameterElement.EMPTY_LIST;
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
   * Make a type concrete.  A type is concrete if it is not a function
   * type, or if it is a function type with no dynamic parameters.  A
   * non-concrete function type is made concrete by replacing dynamic
   * parameters with Object.
   */
  DartType typeToConcreteType(DartType t);

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
    // TODO(rnystrom): Right now, this assumes f and g do not have any type
    // parameters. Revisit that in the presence of generic methods.
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
    return new FunctionElementImpl.synthetic(parameters, returnType).type;
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
    return options.strongMode
        ? new StrongTypeSystemImpl(context.typeProvider,
            implicitCasts: options.implicitCasts,
            nonnullableTypes: options.nonnullableTypes)
        : new TypeSystemImpl(context.typeProvider);
  }
}

/**
 * Implementation of [TypeSystem] using the rules in the Dart specification.
 */
class TypeSystemImpl extends TypeSystem {
  final TypeProvider typeProvider;

  TypeSystemImpl(this.typeProvider);

  @override
  bool get isStrong => false;

  FunctionType functionTypeToConcreteType(FunctionType t) => t;

  /**
   * Instantiate a parameterized type using `dynamic` for all generic
   * parameters.  Returns the type unchanged if there are no parameters.
   */
  DartType instantiateToBounds(DartType type, {List<bool> hasError}) {
    List<DartType> typeFormals = typeFormalsAsTypes(type);
    int count = typeFormals.length;
    if (count > 0) {
      List<DartType> typeArguments =
          new List<DartType>.filled(count, DynamicTypeImpl.instance);
      return instantiateType(type, typeArguments);
    }
    return type;
  }

  @override
  bool isAssignableTo(DartType leftType, DartType rightType) {
    return leftType.isAssignableTo(rightType);
  }

  @override
  bool isMoreSpecificThan(DartType t1, DartType t2) =>
      t1.isMoreSpecificThan(t2);

  @override
  bool isSubtypeOf(DartType leftType, DartType rightType) {
    return leftType.isSubtypeOf(rightType);
  }

  @override
  DartType tryPromoteToType(DartType to, DartType from) {
    // Declared type should not be "dynamic".
    // Promoted type should not be "dynamic".
    // Promoted type should be more specific than declared.
    if (!from.isDynamic && !to.isDynamic && to.isMoreSpecificThan(from)) {
      return to;
    } else {
      return null;
    }
  }

  @override
  DartType typeToConcreteType(DartType t) => t;

  @override
  DartType _interfaceLeastUpperBound(InterfaceType type1, InterfaceType type2) {
    InterfaceType result =
        InterfaceTypeImpl.computeLeastUpperBound(type1, type2);
    return result ?? typeProvider.dynamicType;
  }

  @override
  DartType _typeParameterLeastUpperBound(DartType type1, DartType type2) {
    type1 = type1.resolveToBound(typeProvider.objectType);
    type2 = type2.resolveToBound(typeProvider.objectType);
    return getLeastUpperBound(type1, type2);
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
  bool operator ==(Object object) => identical(object, this);

  @override
  void appendTo(StringBuffer buffer, Set<TypeImpl> types) {
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
class _GenericInferrer {
  final StrongTypeSystemImpl _typeSystem;
  final TypeProvider typeProvider;
  final Map<TypeParameterElement, List<_TypeConstraint>> _constraints;

  /// Counter internally by [_matchSubtypeOf] to see if a recursive call
  /// added anything to [_constraints].
  ///
  /// Essentially just an optimization for:
  /// `_constraints.values.expand((x) => x).length`
  int _constraintCount = 0;

  _GenericInferrer(this.typeProvider, this._typeSystem,
      Iterable<TypeParameterElement> typeFormals)
      : _constraints = new HashMap(
            equals: (x, y) => x.location == y.location,
            hashCode: (x) => x.location.hashCode) {
    for (var formal in typeFormals) {
      _constraints[formal] = [];
    }
  }

  /// Apply an argument constraint, which asserts that the [argument] staticType
  /// is a subtype of the [parameterType].
  void constrainArgument(
      DartType argumentType, DartType parameterType, String parameterName,
      {DartType genericType}) {
    var origin = new _TypeConstraintFromArgument(
        argumentType, parameterType, parameterName,
        genericType: genericType);
    _matchSubtypeOf(argumentType, parameterType, null, origin,
        covariant: false);
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
    _matchSubtypeOf(inferFnType, contextType, null, origin, covariant: true);
  }

  /// Apply a return type constraint, which asserts that the [declaredType]
  /// is a subtype of the [contextType].
  void constrainReturnType(DartType declaredType, DartType contextType) {
    var origin = new _TypeConstraintFromReturnType(declaredType, contextType);
    _matchSubtypeOf(declaredType, contextType, null, origin, covariant: true);
  }

  /// Given the constraints that were given by calling [isSubtypeOf], find the
  /// instantiation of the generic function that satisfies these constraints.
  ///
  /// If [downwardsInferPhase] is set, we are in the first pass of inference,
  /// pushing context types down. At that point we are allowed to push down
  /// `?` to precisely represent an unknown type. If [downwardsInferPhase] is
  /// false, we are on our final inference pass, have all available information
  /// including argument types, and must not conclude `?` for any type formal.
  T infer<T extends ParameterizedType>(
      T genericType, List<TypeParameterElement> typeFormals,
      {ErrorReporter errorReporter,
      AstNode errorNode,
      bool downwardsInferPhase: false}) {
    var fnTypeParams = TypeParameterTypeImpl.getTypes(typeFormals);

    // Initialize the inferred type array.
    //
    // In the downwards phase, they all start as `?` to offer reasonable
    // degradation for f-bounded type parameters.
    var inferredTypes = new List<DartType>.filled(
        fnTypeParams.length, UnknownInferredType.instance);
    var _inferTypeParameter = downwardsInferPhase
        ? _inferTypeParameterFromContext
        : _inferTypeParameterFromAll;

    for (int i = 0; i < fnTypeParams.length; i++) {
      TypeParameterType typeParam = fnTypeParams[i];

      var typeParamBound = typeParam.bound;
      _TypeConstraint extendsClause;
      if (!typeParamBound.isDynamic) {
        extendsClause = new _TypeConstraint.fromExtends(typeParam,
            typeParam.bound.substitute2(inferredTypes, fnTypeParams));
      }

      var constraints = _constraints[typeParam.element];
      inferredTypes[i] = _inferTypeParameter(constraints, extendsClause);
    }

    // If the downwards infer phase has failed, we'll catch this in the upwards
    // phase later on.
    if (downwardsInferPhase) {
      return genericType.instantiate(inferredTypes) as T;
    }

    // Check the inferred types against all of the constraints.
    var knownTypes = new HashMap<TypeParameterType, DartType>(
        equals: (x, y) => x.element == y.element,
        hashCode: (x) => x.element.hashCode);
    for (int i = 0; i < fnTypeParams.length; i++) {
      TypeParameterType typeParam = fnTypeParams[i];
      var constraints = _constraints[typeParam.element];
      var typeParamBound =
          typeParam.bound.substitute2(inferredTypes, fnTypeParams);

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
        errorReporter?.reportErrorForNode(
            StrongModeCode.COULD_NOT_INFER,
            errorNode,
            [typeParam, _formatError(typeParam, inferred, constraints)]);

        // Heuristic: even if we failed, keep the erroneous type.
        // It should satisfy at least some of the constraints (e.g. the return
        // context). If we fall back to instantiateToBounds, we'll typically get
        // more errors (e.g. because `dynamic` is the most common bound).
      }

      if (UnknownInferredType.isKnown(inferred)) {
        knownTypes[typeParam] = inferred;
      }
    }

    // Use instantiate to bounds to finish things off.
    var hasError = new List<bool>.filled(fnTypeParams.length, false);
    var result = _typeSystem.instantiateToBounds(genericType,
        hasError: hasError, knownTypes: knownTypes) as T;

    // Report any errors from instantiateToBounds.
    for (int i = 0; i < hasError.length; i++) {
      if (hasError[i]) {
        TypeParameterType typeParam = fnTypeParams[i];
        var typeParamBound =
            typeParam.bound.substitute2(inferredTypes, fnTypeParams);
        // TODO(jmesserly): improve this error message.
        errorReporter
            ?.reportErrorForNode(StrongModeCode.COULD_NOT_INFER, errorNode, [
          typeParam,
          "\nRecursive bound cannot be instantiated: '$typeParamBound'."
              "\nConsider passing explicit type argument(s) "
              "to the generic.\n\n'"
        ]);
      }
    }
    return result;
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

  String _formatError(TypeParameterType typeParam, DartType inferred,
      Iterable<_TypeConstraint> constraints) {
    var intro = "Tried to infer '$inferred' for '$typeParam'"
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
  /// - `GLB(A, FutureOr<B>) ==  GLB(FutureOr<A>, B)` (defined above),
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
            return typeProvider.futureOrType
                .instantiate([_getGreatestLowerBound(t1TypeArg, t2TypeArg)]);
          }
          // GLB(FutureOr<A>, Future<B>) == Future<GLB(A, B)>
          if (t2.isDartAsyncFuture) {
            var t2TypeArg = t2.typeArguments[0];
            return typeProvider.futureType
                .instantiate([_getGreatestLowerBound(t1TypeArg, t2TypeArg)]);
          }
        }
        // GLB(FutureOr<A>, B) == GLB(A, B)
        return _getGreatestLowerBound(t1TypeArg, t2);
      }
      if (t2 is InterfaceType && t2.isDartAsyncFutureOr) {
        // GLB(A, FutureOr<B>) ==  GLB(FutureOr<A>, B)
        return _getGreatestLowerBound(t2, t1);
      }
      // TODO(jmesserly): fix this rule once we support non-nullable types.
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

  void _matchInterfaceSubtypeOf(InterfaceType i1, InterfaceType i2,
      Set<Element> visited, _TypeConstraintOrigin origin,
      {bool covariant}) {
    if (identical(i1, i2)) {
      return;
    }

    if (i1.element == i2.element) {
      List<DartType> tArgs1 = i1.typeArguments;
      List<DartType> tArgs2 = i2.typeArguments;
      assert(tArgs1.length == tArgs2.length);
      for (int i = 0; i < tArgs1.length; i++) {
        _matchSubtypeOf(tArgs1[i], tArgs2[i], visited, origin,
            covariant: covariant);
      }
      return;
    }
    if (i2.isDartCoreFunction && i1.element.getMethod("call") != null) {
      return;
    }
    if (i1.isObject) {
      return;
    }

    // Guard against loops in the class hierarchy
    void guardedInterfaceSubtype(InterfaceType t1) {
      var visitedSet = visited ?? new HashSet<Element>();
      if (visitedSet.add(t1.element)) {
        _matchInterfaceSubtypeOf(t1, i2, visited, origin, covariant: covariant);
        visitedSet.remove(t1.element);
      }
    }

    guardedInterfaceSubtype(i1.superclass);
    for (final parent in i1.interfaces) {
      guardedInterfaceSubtype(parent);
    }
    for (final parent in i1.mixins) {
      guardedInterfaceSubtype(parent);
    }
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
  void _matchSubtypeOf(DartType t1, DartType t2, Set<Element> visited,
      _TypeConstraintOrigin origin,
      {bool covariant, bool dynamicIsBottom: false}) {
    // TODO(jmesserly): I think we should handle `dynamicIsBottom`
    // https://github.com/dart-lang/sdk/issues/29041
    if (covariant && t1 is TypeParameterType) {
      var constraints = _constraints[t1.element];
      if (constraints != null) {
        if (!identical(t2, UnknownInferredType.instance)) {
          constraints.add(new _TypeConstraint(origin, t1, upper: t2));
          _constraintCount++;
        }
        return;
      }
    }
    if (!covariant && t2 is TypeParameterType) {
      var constraints = _constraints[t2.element];
      if (constraints != null) {
        if (!identical(t1, UnknownInferredType.instance)) {
          constraints.add(new _TypeConstraint(origin, t2, lower: t1));
          _constraintCount++;
        }
        return;
      }
    }

    if (identical(t1, t2)) {
      return;
    }

    // TODO(jmesserly): this logic is taken from subtype.
    void matchSubtype(DartType t1, DartType t2) {
      _matchSubtypeOf(t1, t2, null, origin, covariant: covariant);
    }

    // Handle FutureOr<T> union type.
    if (t1 is InterfaceType && t1.isDartAsyncFutureOr) {
      var t1TypeArg = t1.typeArguments[0];
      if (t2 is InterfaceType && t2.isDartAsyncFutureOr) {
        var t2TypeArg = t2.typeArguments[0];
        // FutureOr<A> <: FutureOr<B> iff A <: B
        matchSubtype(t1TypeArg, t2TypeArg);
        return;
      }

      // given t1 is Future<A> | A, then:
      // (Future<A> | A) <: t2 iff Future<A> <: t2 and A <: t2.
      var t1Future = typeProvider.futureType.instantiate([t1TypeArg]);
      matchSubtype(t1Future, t2);
      matchSubtype(t1TypeArg, t2);
      return;
    }

    if (t2 is InterfaceType && t2.isDartAsyncFutureOr) {
      // given t2 is Future<A> | A, then:
      // t1 <: (Future<A> | A) iff t1 <: Future<A> or t1 <: A
      var t2TypeArg = t2.typeArguments[0];
      var t2Future = typeProvider.futureType.instantiate([t2TypeArg]);

      int constraintCount = _constraintCount;
      matchSubtype(t1, t2Future);

      // We only want to record these as "or" constraints, so if we matched
      // the `t1 <: Future<A>` constraint, don't add `t1 <: A` constraint, as
      // that would be interpreted incorrectly as `t1 <: Future<A> && t1 <: A`.
      if (constraintCount == _constraintCount) {
        matchSubtype(t1, t2TypeArg);
      }
      return;
    }

    // S <: T where S is a type variable
    //  T is not dynamic or object (handled above)
    //  True if T == S
    //  Or true if bound of S is S' and S' <: T

    if (t1 is TypeParameterType) {
      // Guard against recursive type parameters
      void guardedSubtype(DartType t1, DartType t2) {
        var visitedSet = visited ?? new HashSet<Element>();
        if (visitedSet.add(t1.element)) {
          matchSubtype(t1, t2);
          visitedSet.remove(t1.element);
        }
      }

      if (t2 is TypeParameterType && t1.definition == t2.definition) {
        guardedSubtype(t1.bound, t2.bound);
        return;
      }
      guardedSubtype(t1.bound, t2);
      return;
    }
    if (t2 is TypeParameterType) {
      return;
    }

    if (t1 is InterfaceType && t2 is InterfaceType) {
      _matchInterfaceSubtypeOf(t1, t2, visited, origin, covariant: covariant);
      return;
    }

    // An interface type can only subtype a function type if
    // the interface type declares a call method with a type
    // which is a super type of the function type.
    if (t1 is InterfaceType) {
      t1 = _typeSystem.getCallMethodDefiniteType(t1);
      if (t1 == null) return;
    }

    if (t1 is FunctionType && t2 is FunctionType) {
      FunctionTypeImpl.relate(
          t1,
          t2,
          (t1, t2) {
            // TODO(jmesserly): should we flip covariance when we're relating
            // type formal bounds? They're more like parameters.
            matchSubtype(t1, t2);
            return true;
          },
          _typeSystem.instantiateToBounds,
          parameterRelation: (p1, p2) {
            _matchSubtypeOf(p2.type, p1.type, null, origin,
                covariant: !covariant, dynamicIsBottom: true);
            return true;
          });
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

/// A constraint on a type parameter that we're inferring.
class _TypeConstraint extends _TypeRange {
  /// The type parameter that is constrained by [lowerBound] or [upperBound].
  final TypeParameterType typeParameter;

  /// Where this constraint comes from, used for error messages.
  ///
  /// See [toString].
  final _TypeConstraintOrigin origin;

  _TypeConstraint(this.origin, this.typeParameter,
      {DartType upper, DartType lower})
      : super(upper: upper, lower: lower);

  _TypeConstraint.fromExtends(TypeParameterType type, DartType extendsType)
      : this(new _TypeConstraintFromExtendsClause(type, extendsType), type,
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
  final DartType genericType;

  _TypeConstraintFromArgument(
      this.argumentType, this.parameterType, this.parameterName,
      {this.genericType});

  @override
  formatError() {
    // TODO(jmesserly): we should highlight the span. That would be more useful.
    // However in summary code it doesn't look like the AST node with span is
    // available.
    String prefix;
    if ((genericType.name == "List" || genericType.name == "Map") &&
        genericType?.element?.library?.isDartCore == true) {
      // This will become:
      //     "List element"
      //     "Map key"
      //     "Map value"
      prefix = "${genericType.name} $parameterName";
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
  final TypeParameterType typeParam;
  final DartType extendsType;

  _TypeConstraintFromExtendsClause(this.typeParam, this.extendsType);

  @override
  formatError() {
    return [
      "Type parameter '$typeParam'",
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
}
