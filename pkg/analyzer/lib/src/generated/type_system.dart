// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.type_system;

import 'dart:collection';
import 'dart:math' as math;

import 'package:analyzer/dart/ast/token.dart' show TokenType;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/utilities_dart.dart' show ParameterKind;
import 'package:analyzer/src/generated/utilities_general.dart'
    show JenkinsSmiHash;

typedef bool _GuardedSubtypeChecker<T>(T t1, T t2, Set<Element> visited);

/**
 * Implementation of [TypeSystem] using the strong mode rules.
 * https://github.com/dart-lang/dev_compiler/blob/master/STRONG_MODE.md
 */
class StrongTypeSystemImpl extends TypeSystem {
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

  StrongTypeSystemImpl(
      {this.implicitCasts: true,
      this.nonnullableTypes: AnalysisOptionsImpl.NONNULLABLE_TYPES});

  bool anyParameterType(FunctionType ft, bool predicate(DartType t)) {
    return ft.parameters.any((p) => predicate(p.type));
  }

  @override
  bool canPromoteToType(DartType to, DartType from) {
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
      return true;
    }
    // For a type parameter `T extends U`, allow promoting from the upper bound
    // `U` to `S` where `S <: U`.
    //
    // This does restrict the variable, because `S </: T`, it can no longer be
    // used as a `T` without another cast.
    //
    // However the members you could access from a variable of type `T`, were
    // already those on the upper bound `U`. So all members on `U` will be
    // accessible, as well as those on `S`. Pragmatically this feels like a
    // useful enough trade-off to allow promotion.
    //
    // (In general we would need union types to support this feature precisely.)
    if (from is TypeParameterType) {
      return isSubtypeOf(to, from.resolveToBound(DynamicTypeImpl.instance));
    }

    return false;
  }

  @override
  FunctionType functionTypeToConcreteType(
      TypeProvider typeProvider, FunctionType t) {
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
    function.synthetic = true;
    function.returnType = t.returnType;
    function.shareTypeParameters(t.typeFormals);
    function.shareParameters(parameters);
    return function.type = new FunctionTypeImpl(function);
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
  DartType getGreatestLowerBound(
      TypeProvider provider, DartType type1, DartType type2,
      {dynamicIsBottom: false}) {
    // The greatest lower bound relation is reflexive.
    if (identical(type1, type2)) {
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
      return _functionGreatestLowerBound(provider, type1, type2);
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
    return provider.bottomType;
  }

  /**
   * Compute the least upper bound of two types.
   */
  @override
  DartType getLeastUpperBound(
      TypeProvider typeProvider, DartType type1, DartType type2,
      {bool dynamicIsBottom: false}) {
    if (isNullableType(type1) && isNonNullableType(type2)) {
      assert(type2 is InterfaceType);
      type2 = getLeastNullableSupertype(type2 as InterfaceType);
    }
    if (isNullableType(type2) && isNonNullableType(type1)) {
      assert(type1 is InterfaceType);
      type1 = getLeastNullableSupertype(type1 as InterfaceType);
    }
    return super.getLeastUpperBound(typeProvider, type1, type2,
        dynamicIsBottom: dynamicIsBottom);
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
   * Given a generic function type `F<T0, T1, ... Tn>` and a context type C,
   * infer an instantiation of F, such that `F<S0, S1, ..., Sn>` <: C.
   *
   * This is similar to [inferGenericFunctionCall], but the return type is also
   * considered as part of the solution.
   *
   * If this function is called with a [contextType] that is also
   * uninstantiated, or a [fnType] that is already instantiated, it will have
   * no effect and return [fnType].
   */
  FunctionType inferFunctionTypeInstantiation(TypeProvider typeProvider,
      FunctionType contextType, FunctionType fnType) {
    if (contextType.typeFormals.isNotEmpty || fnType.typeFormals.isEmpty) {
      return fnType;
    }

    // Create a TypeSystem that will allow certain type parameters to be
    // inferred. It will optimistically assume these type parameters can be
    // subtypes (or supertypes) as necessary, and track the constraints that
    // are implied by this.
    var inferringTypeSystem =
        new _StrongInferenceTypeSystem(typeProvider, this, fnType.typeFormals);

    // Since we're trying to infer the instantiation, we want to ignore type
    // formals as we check the parameters and return type.
    var inferFnType =
        fnType.instantiate(TypeParameterTypeImpl.getTypes(fnType.typeFormals));
    if (!inferringTypeSystem.isSubtypeOf(inferFnType, contextType)) {
      return fnType;
    }

    // Try to infer and instantiate the resulting type.
    var resultType = inferringTypeSystem._infer(fnType);

    // If the instantiation failed (because some type variable constraints
    // could not be solved, in other words, we could not find a valid subtype),
    // then return the original type, so the error is in terms of it.
    //
    // It would be safe to return a partial solution here, but the user
    // experience may be better if we simply do not infer in this case.
    return resultType ?? fnType;
  }

  /// Given a function type with generic type parameters, infer the type
  /// parameters from the actual argument types, and return the instantiated
  /// function type. If we can't, returns the original function type.
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
  /// As a simplification, we do not actually store all constraints on each type
  /// parameter Tj. Instead we track Uj and Lj where U is the upper bound and
  /// L is the lower bound of that type parameter.
  FunctionType inferGenericFunctionCall(
      TypeProvider typeProvider,
      FunctionType fnType,
      List<DartType> correspondingParameterTypes,
      List<DartType> argumentTypes,
      DartType returnContextType) {
    if (fnType.typeFormals.isEmpty) {
      return fnType;
    }

    // Create a TypeSystem that will allow certain type parameters to be
    // inferred. It will optimistically assume these type parameters can be
    // subtypes (or supertypes) as necessary, and track the constraints that
    // are implied by this.
    var inferringTypeSystem =
        new _StrongInferenceTypeSystem(typeProvider, this, fnType.typeFormals);

    if (returnContextType != null) {
      inferringTypeSystem.isSubtypeOf(fnType.returnType, returnContextType);
    }

    for (int i = 0; i < argumentTypes.length; i++) {
      // Try to pass each argument to each parameter, recording any type
      // parameter bounds that were implied by this assignment.
      inferringTypeSystem.isSubtypeOf(
          argumentTypes[i], correspondingParameterTypes[i]);
    }

    return inferringTypeSystem._infer(fnType);
  }

  /**
   * Given a [DartType] [type], if [type] is an uninstantiated
   * parameterized type then instantiate the parameters to their
   * bounds. Specifically, if [type] is of the form
   * `<T0 extends B0, ... Tn extends Bn>.F` or
   * `class C<T0 extends B0, ... Tn extends Bn> {...}`
   * (where Bi is implicitly dynamic if absent),
   * compute `{I0/T0, ..., In/Tn}F or C<I0, ..., In>` respectively
   * where I_(i+1) = {I0/T0, ..., Ii/Ti, dynamic/T_(i+1)}B_(i+1).
   * That is, we instantiate the generic with its bounds, replacing
   * each Ti in Bi with dynamic to get Ii, and then replacing Ti with
   * Ii in all of the remaining bounds.
   */
  DartType instantiateToBounds(DartType type) {
    List<TypeParameterElement> typeFormals = typeFormalsAsElements(type);
    int count = typeFormals.length;
    if (count == 0) {
      return type;
    }

    // We build up a substitution replacing bound parameters with
    // their instantiated bounds, {substituted/variables}
    List<DartType> substituted = new List<DartType>();
    List<DartType> variables = new List<DartType>();
    for (int i = 0; i < count; i++) {
      TypeParameterElement param = typeFormals[i];
      DartType bound = param.bound ?? DynamicTypeImpl.instance;
      DartType variable = param.type;
      // For each Ti extends Bi, first compute Ii by replacing
      // Ti in Bi with dynamic (simultaneously replacing all
      // of the previous Tj (j < i) with their instantiated bounds.
      substituted.add(DynamicTypeImpl.instance);
      variables.add(variable);
      // Now update the substitution to replace Ti with Ii instead
      // of dynamic in subsequent rounds.
      substituted[i] = bound.substitute2(substituted, variables);
    }

    return instantiateType(type, substituted);
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
    if ((fromType is FunctionType && getCallMethodType(toType) != null) ||
        (toType is FunctionType && getCallMethodType(fromType) != null)) {
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
    if (isSubtypeOf(toType, fromType) || toType.isAssignableTo(fromType)) {
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

  @override
  bool isSubtypeOf(DartType leftType, DartType rightType) {
    return _isSubtypeOf(leftType, rightType, null);
  }

  @override
  DartType refineBinaryExpressionType(
      TypeProvider typeProvider,
      DartType leftType,
      TokenType operator,
      DartType rightType,
      DartType currentType) {
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
    return super.refineBinaryExpressionType(
        typeProvider, leftType, operator, rightType, currentType);
  }

  @override
  DartType typeToConcreteType(TypeProvider typeProvider, DartType t) {
    if (t is FunctionType) {
      return functionTypeToConcreteType(typeProvider, t);
    }
    return t;
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
  DartType _functionGreatestLowerBound(
      TypeProvider provider, FunctionType f, FunctionType g) {
    // Calculate the LUB of each corresponding pair of parameters.
    List<ParameterElement> parameters = [];

    bool hasPositional = false;
    bool hasNamed = false;
    addParameter(
        String name, DartType fType, DartType gType, ParameterKind kind) {
      DartType paramType;
      if (fType != null && gType != null) {
        // If both functions have this parameter, include both of their types.
        paramType =
            getLeastUpperBound(provider, fType, gType, dynamicIsBottom: true);
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
    if (hasPositional && hasNamed) return provider.bottomType;

    // Calculate the GLB of the return type.
    DartType returnType =
        getGreatestLowerBound(provider, f.returnType, g.returnType);
    return new FunctionElementImpl.synthetic(parameters, returnType).type;
  }

  @override
  DartType _functionParameterBound(
          TypeProvider provider, DartType f, DartType g) =>
      getGreatestLowerBound(provider, f, g, dynamicIsBottom: true);

  /**
   * Guard against loops in the class hierarchy
   */
  _GuardedSubtypeChecker<DartType> _guard(
      _GuardedSubtypeChecker<DartType> check) {
    return (DartType t1, DartType t2, Set<Element> visited) {
      Element element = t1.element;
      if (visited == null) {
        visited = new HashSet<Element>();
      }
      if (element == null || !visited.add(element)) {
        return false;
      }
      try {
        return check(t1, t2, visited);
      } finally {
        visited.remove(element);
      }
    };
  }

  /// If [t1] or [t2] is a type parameter we are inferring, update its bound.
  /// Returns `true` if we could possibly find a compatible type,
  /// otherwise `false`.
  bool _inferTypeParameterSubtypeOf(
      DartType t1, DartType t2, Set<Element> visited) {
    return false;
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
   *    the true least uppper bounds.  The result is guaranteed to be a
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
  DartType _interfaceLeastUpperBound(
      TypeProvider provider, InterfaceType type1, InterfaceType type2) {
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
        tArgs[i] = getLeastUpperBound(provider, tArgs1[i], tArgs2[i]);
      }
      InterfaceTypeImpl lub = new InterfaceTypeImpl(type1.element);
      lub.typeArguments = tArgs;
      return lub;
    }
    return InterfaceTypeImpl.computeLeastUpperBound(type1, type2) ??
        provider.dynamicType;
  }

  /**
   * Check that [f1] is a subtype of [f2].
   *
   * This will always assume function types use fuzzy arrows, in other words
   * that dynamic parameters of f1 and f2 are treated as bottom.
   */
  bool _isFunctionSubtypeOf(FunctionType f1, FunctionType f2) {
    return FunctionTypeImpl.relate(
        f1,
        f2,
        (DartType t1, DartType t2) =>
            _isSubtypeOf(t2, t1, null, dynamicIsBottom: true),
        instantiateToBounds,
        returnRelation: isSubtypeOf);
  }

  bool _isInterfaceSubtypeOf(
      InterfaceType i1, InterfaceType i2, Set<Element> visited) {
    // Guard recursive calls
    _GuardedSubtypeChecker<InterfaceType> guardedInterfaceSubtype = _guard(
        (DartType i1, DartType i2, Set<Element> visited) =>
            _isInterfaceSubtypeOf(i1, i2, visited));

    if (i1 == i2) {
      return true;
    }

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

    if (guardedInterfaceSubtype(i1.superclass, i2, visited)) {
      return true;
    }

    for (final parent in i1.interfaces) {
      if (guardedInterfaceSubtype(parent, i2, visited)) {
        return true;
      }
    }

    for (final parent in i1.mixins) {
      if (guardedInterfaceSubtype(parent, i2, visited)) {
        return true;
      }
    }

    return false;
  }

  bool _isSubtypeOf(DartType t1, DartType t2, Set<Element> visited,
      {bool dynamicIsBottom: false}) {
    // Guard recursive calls
    _GuardedSubtypeChecker<DartType> guardedSubtype = _guard(_isSubtypeOf);
    _GuardedSubtypeChecker<DartType> guardedInferTypeParameter =
        _guard(_inferTypeParameterSubtypeOf);
    if (t1 == t2) {
      return true;
    }

    // The types are void, dynamic, bottom, interface types, function types,
    // and type parameters. We proceed by eliminating these different classes
    // from consideration.

    // Trivially true.
    if (_isTop(t2, dynamicIsBottom: dynamicIsBottom) ||
        _isBottom(t1, dynamicIsBottom: dynamicIsBottom)) {
      return true;
    }

    // Trivially false.
    if (_isTop(t1, dynamicIsBottom: dynamicIsBottom) ||
        _isBottom(t2, dynamicIsBottom: dynamicIsBottom)) {
      return guardedInferTypeParameter(t1, t2, visited);
    }

    // S <: T where S is a type variable
    //  T is not dynamic or object (handled above)
    //  S != T (handled above)
    //  So only true if bound of S is S' and
    //  S' <: T
    if (t1 is TypeParameterType) {
      if (guardedInferTypeParameter(t1, t2, visited)) {
        return true;
      }
      DartType bound = t1.element.bound;
      return bound == null ? false : guardedSubtype(bound, t2, visited);
    }

    if (t2 is TypeParameterType) {
      return guardedInferTypeParameter(t1, t2, visited);
    }

    // Void only appears as the return type of a function, and we handle it
    // directly in the function subtype rules. We should not get to a point
    // where we're doing a subtype test on a "bare" void, but just in case we
    // do, handle it safely.
    // TODO(rnystrom): Determine how this can ever be reached. If it can't,
    // remove it.
    if (t1.isVoid || t2.isVoid) {
      return false;
    }

    // We've eliminated void, dynamic, bottom, and type parameters.  The only
    // cases are the combinations of interface type and function type.

    // A function type can only subtype an interface type if
    // the interface type is Function
    if (t1 is FunctionType && t2 is InterfaceType) {
      return t2.isDartCoreFunction;
    }

    // An interface type can only subtype a function type if
    // the interface type declares a call method with a type
    // which is a super type of the function type.
    if (t1 is InterfaceType && t2 is FunctionType) {
      var callType = getCallMethodType(t1);
      return (callType != null) && _isFunctionSubtypeOf(callType, t2);
    }

    // Two interface types
    if (t1 is InterfaceType && t2 is InterfaceType) {
      return _isInterfaceSubtypeOf(t1, t2, visited);
    }

    return _isFunctionSubtypeOf(t1 as FunctionType, t2 as FunctionType);
  }

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

  /// Given a type return its name prepended with the URI to its containing
  /// library and separated by a comma.
  String _getTypeFullyQualifiedName(DartType type) {
    return "${type?.element?.library?.identifier},$type";
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
  DartType _typeParameterLeastUpperBound(
      TypeProvider provider, DartType type1, DartType type2) {
    if (isSubtypeOf(type1, type2)) {
      return type2;
    }
    if (isSubtypeOf(type2, type1)) {
      return type1;
    }
    if (type1 is TypeParameterType) {
      type1 = type1
          .resolveToBound(provider.objectType)
          .substitute2([provider.objectType], [type1]);
      return getLeastUpperBound(provider, type1, type2);
    }
    // We should only be called when at least one of the types is a
    // TypeParameterType
    type2 = type2
        .resolveToBound(provider.objectType)
        .substitute2([provider.objectType], [type2]);
    return getLeastUpperBound(provider, type1, type2);
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
   * Returns `true` if we can promote to the first type from the second type.
   *
   * In the standard Dart type system, it is not possible to promote from or to
   * `dynamic`, and we must be promoting to a more specific type, see
   * [isMoreSpecificThan].
   *
   * In strong mode, this is equivalent to [isSubtypeOf].
   */
  bool canPromoteToType(DartType to, DartType from);

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
  FunctionType functionTypeToConcreteType(
      TypeProvider typeProvider, FunctionType t);

  /**
   * Compute the least upper bound of two types.
   */
  DartType getLeastUpperBound(
      TypeProvider typeProvider, DartType type1, DartType type2,
      {bool dynamicIsBottom: false}) {
    // The least upper bound relation is reflexive.
    if (identical(type1, type2)) {
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
      return _typeParameterLeastUpperBound(typeProvider, type1, type2);
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
      return _interfaceLeastUpperBound(typeProvider, type1, type2);
    }

    if (type1 is FunctionType && type2 is FunctionType) {
      return _functionLeastUpperBound(typeProvider, type1, type2);
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
  DartType instantiateToBounds(DartType type);

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
  DartType refineBinaryExpressionType(
      TypeProvider typeProvider,
      DartType leftType,
      TokenType operator,
      DartType rightType,
      DartType currentType) {
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
  DartType typeToConcreteType(TypeProvider typeProvider, DartType t);

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
  DartType _functionLeastUpperBound(
      TypeProvider provider, FunctionType f, FunctionType g) {
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
      return provider.functionType;
    }

    // Calculate the LUB of each corresponding pair of parameters.
    List<ParameterElement> parameters = [];

    for (int i = 0; i < fRequired.length; i++) {
      parameters.add(new ParameterElementImpl.synthetic(
          fRequiredNames[i],
          _functionParameterBound(provider, fRequired[i], gRequired[i]),
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
          _functionParameterBound(provider, fPositional[i], gPositional[i]),
          ParameterKind.POSITIONAL));
    }

    Map<String, DartType> fNamed = f.namedParameterTypes;
    Map<String, DartType> gNamed = g.namedParameterTypes;
    for (String name in fNamed.keys.toSet()..retainAll(gNamed.keys)) {
      parameters.add(new ParameterElementImpl.synthetic(
          name,
          _functionParameterBound(provider, fNamed[name], gNamed[name]),
          ParameterKind.NAMED));
    }

    // Calculate the LUB of the return type.
    DartType returnType =
        getLeastUpperBound(provider, f.returnType, g.returnType);
    return new FunctionElementImpl.synthetic(parameters, returnType).type;
  }

  /**
   * Calculates the appropriate upper or lower bound of a pair of parameters
   * for two function types whose least upper bound is being calculated.
   *
   * In spec mode, this uses least upper bound, which... doesn't really make
   * much sense. Strong mode overrides this to use greatest lower bound.
   */
  DartType _functionParameterBound(
          TypeProvider provider, DartType f, DartType g) =>
      getLeastUpperBound(provider, f, g);

  /**
   * Given two [InterfaceType]s [type1] and [type2] return their least upper
   * bound in a type system specific manner.
   */
  DartType _interfaceLeastUpperBound(
      TypeProvider provider, InterfaceType type1, InterfaceType type2);

  /**
   * Given two [DartType]s [type1] and [type2] at least one of which is a
   * [TypeParameterType], return their least upper bound in a type system
   * specific manner.
   */
  DartType _typeParameterLeastUpperBound(
      TypeProvider provider, DartType type1, DartType type2);

  /**
   * Create either a strong mode or regular type system based on context.
   */
  static TypeSystem create(AnalysisContext context) {
    var options = context.analysisOptions as AnalysisOptionsImpl;
    return options.strongMode
        ? new StrongTypeSystemImpl(
            implicitCasts: options.implicitCasts,
            nonnullableTypes: options.nonnullableTypes)
        : new TypeSystemImpl();
  }
}

/**
 * Implementation of [TypeSystem] using the rules in the Dart specification.
 */
class TypeSystemImpl extends TypeSystem {
  TypeSystemImpl();

  @override
  bool canPromoteToType(DartType to, DartType from) {
    // Declared type should not be "dynamic".
    // Promoted type should not be "dynamic".
    // Promoted type should be more specific than declared.
    return !from.isDynamic && !to.isDynamic && to.isMoreSpecificThan(from);
  }

  @override
  FunctionType functionTypeToConcreteType(
          TypeProvider typeProvider, FunctionType t) =>
      t;

  /**
   * Instantiate a parameterized type using `dynamic` for all generic
   * parameters.  Returns the type unchanged if there are no parameters.
   */
  DartType instantiateToBounds(DartType type) {
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
  DartType typeToConcreteType(TypeProvider typeProvider, DartType t) => t;

  @override
  DartType _interfaceLeastUpperBound(
      TypeProvider provider, InterfaceType type1, InterfaceType type2) {
    InterfaceType result =
        InterfaceTypeImpl.computeLeastUpperBound(type1, type2);
    return result ?? provider.dynamicType;
  }

  @override
  DartType _typeParameterLeastUpperBound(
      TypeProvider provider, DartType type1, DartType type2) {
    type1 = type1.resolveToBound(provider.objectType);
    type2 = type2.resolveToBound(provider.objectType);
    return getLeastUpperBound(provider, type1, type2);
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
/// Once the lower/upper bounds are determined, [_infer] should be called to
/// finish the inference. It will instantiate a generic function type with the
/// inferred types for each type parameter.
///
/// It can also optionally compute a partial solution, in case some of the type
/// parameters could not be inferred (because the constraints cannot be
/// satisfied), or bail on the inference when this happens.
///
/// As currently designed, an instance of this class should only be used to
/// infer a single call and discarded immediately afterwards.
class _StrongInferenceTypeSystem extends StrongTypeSystemImpl {
  final TypeProvider _typeProvider;

  /// The outer strong mode type system, used for GLB and LUB, so we don't
  /// recurse into our constraint solving code.
  final StrongTypeSystemImpl _typeSystem;
  final Map<TypeParameterType, _TypeParameterBound> _bounds;

  _StrongInferenceTypeSystem(this._typeProvider, this._typeSystem,
      Iterable<TypeParameterElement> typeFormals)
      : _bounds = new Map.fromIterable(typeFormals,
            key: (t) => t.type, value: (t) => new _TypeParameterBound());

  /// Given the constraints that were given by calling [isSubtypeOf], find the
  /// instantiation of the generic function that satisfies these constraints.
  FunctionType _infer(FunctionType fnType) {
    List<TypeParameterType> fnTypeParams =
        TypeParameterTypeImpl.getTypes(fnType.typeFormals);

    // Initialize the inferred type array.
    //
    // They all start as `dynamic` to offer reasonable degradation for f-bounded
    // type parameters.
    var inferredTypes = new List<DartType>.filled(
        fnTypeParams.length, DynamicTypeImpl.instance,
        growable: false);

    for (int i = 0; i < fnTypeParams.length; i++) {
      TypeParameterType typeParam = fnTypeParams[i];

      // Apply the `extends` clause for the type parameter, if any.
      //
      // Assumption: if the current type parameter has an "extends" clause
      // that refers to another type variable we are inferring, it will appear
      // before us or in this list position. For example:
      //
      //     <TFrom, TTo extends TFrom>
      //
      // We may infer TTo is TFrom. In that case, we already know what TFrom
      // is inferred as, so we can substitute it now. This also handles more
      // complex cases such as:
      //
      //     <TFrom, TTo extends Iterable<TFrom>>
      //
      // Or if the type parameter's bound depends on itself such as:
      //
      //     <T extends Clonable<T>>
      DartType declaredUpperBound = typeParam.element.bound;
      if (declaredUpperBound != null) {
        // Assert that the type parameter is a subtype of its bound.
        _inferTypeParameterSubtypeOf(typeParam,
            declaredUpperBound.substitute2(inferredTypes, fnTypeParams), null);
      }

      // Now we've computed lower and upper bounds for each type parameter.
      //
      // To decide on which type to assign, we look at the return type and see
      // if the type parameter occurs in covariant or contravariant positions.
      //
      // If the type is "passed in" at all, or if our lower bound was bottom,
      // we choose the upper bound as being the most useful.
      //
      // Otherwise we choose the more precise lower bound.
      _TypeParameterVariance variance =
          new _TypeParameterVariance.from(typeParam, fnType.returnType);

      _TypeParameterBound bound = _bounds[typeParam];
      inferredTypes[i] =
          variance.passedIn || bound.lower.isBottom ? bound.upper : bound.lower;

      // See if the constraints on the type variable are satisfied.
      //
      // If not, bail out of the analysis, unless a partial solution was
      // requested. If we are willing to accept a partial solution, fall back to
      // the known upper bound (if any) or `dynamic` for this unsolvable type
      // variable.
      if (inferredTypes[i].isBottom ||
          !isSubtypeOf(inferredTypes[i],
              bound.upper.substitute2(inferredTypes, fnTypeParams)) ||
          !isSubtypeOf(bound.lower.substitute2(inferredTypes, fnTypeParams),
              inferredTypes[i])) {
        // Inference failed. Bail.
        return null;
      }
    }

    // Return the instantiated type.
    return fnType.instantiate(inferredTypes);
  }

  @override
  bool _inferTypeParameterSubtypeOf(
      DartType t1, DartType t2, Set<Element> visited) {
    if (t1 is TypeParameterType) {
      _TypeParameterBound bound = _bounds[t1];
      if (bound != null) {
        // Ensure T1 <: T2, where T1 is a type parameter we are inferring.
        // T2 is an upper bound, so merge it with our existing upper bound.
        //
        // We already know T1 <: U, for some U.
        // So update U to reflect the new constraint T1 <: GLB(U, T2)
        //
        bound.upper =
            _typeSystem.getGreatestLowerBound(_typeProvider, bound.upper, t2);
        // Optimistically assume we will be able to satisfy the constraint.
        return true;
      }
    }
    if (t2 is TypeParameterType) {
      _TypeParameterBound bound = _bounds[t2];
      if (bound != null) {
        // Ensure T1 <: T2, where T2 is a type parameter we are inferring.
        // T1 is a lower bound, so merge it with our existing lower bound.
        //
        // We already know L <: T2, for some L.
        // So update L to reflect the new constraint LUB(L, T1) <: T2
        //
        bound.lower =
            _typeSystem.getLeastUpperBound(_typeProvider, bound.lower, t1);
        // Optimistically assume we will be able to satisfy the constraint.
        return true;
      }
    }
    return false;
  }
}

/// An [upper] and [lower] bound for a type variable.
class _TypeParameterBound {
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
  DartType upper = DynamicTypeImpl.instance;

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
  DartType lower = BottomTypeImpl.instance;
}

/// Records what positions a type parameter is used in.
class _TypeParameterVariance {
  /// The type parameter is a value passed out. It must satisfy T <: S,
  /// where T is the type parameter and S is what it's assigned to.
  ///
  /// For example, this could be the return type, or a parameter to a parameter:
  ///
  ///     TOut method<TOut>(void f(TOut t));
  bool passedOut = false;

  /// The type parameter is a value passed in. It must satisfy S <: T,
  /// where T is the type parameter and S is what's being assigned to it.
  ///
  /// For example, this could be a parameter type, or the parameter of the
  /// return value:
  ///
  ///     typedef void Func<T>(T t);
  ///     Func<TIn> method<TIn>(TIn t);
  bool passedIn = false;

  _TypeParameterVariance.from(TypeParameterType typeParam, DartType type) {
    _visitType(typeParam, type, false);
  }

  void _visitFunctionType(
      TypeParameterType typeParam, FunctionType type, bool paramIn) {
    for (ParameterElement p in type.parameters) {
      // If a lambda L is passed in to a function F, the parameters are
      // "passed out" of F into L. Thus we invert the "passedIn" state.
      _visitType(typeParam, p.type, !paramIn);
    }
    // If a lambda L is passed in to a function F, and we call L, the result of
    // L is then "passed in" to F. So we keep the "passedIn" state.
    _visitType(typeParam, type.returnType, paramIn);
  }

  void _visitInterfaceType(
      TypeParameterType typeParam, InterfaceType type, bool paramIn) {
    // Currently in "strong mode" generic type parameters are covariant.
    //
    // This means we treat them as "out" type parameters similar to the result
    // of a function, and thus they follow the same rules.
    //
    // For example, we pass in Iterable<T> as a parameter. Then we iterate over
    // it. The "T" is essentially an input. So it keeps the same state.
    // Similarly, if we return an Iterable<T> it's equivalent to returning a T.
    for (DartType typeArg in type.typeArguments) {
      _visitType(typeParam, typeArg, paramIn);
    }
  }

  void _visitType(TypeParameterType typeParam, DartType type, bool paramIn) {
    if (type == typeParam) {
      if (paramIn) {
        passedIn = true;
      } else {
        passedOut = true;
      }
    } else if (type is FunctionType) {
      _visitFunctionType(typeParam, type, paramIn);
    } else if (type is InterfaceType) {
      _visitInterfaceType(typeParam, type, paramIn);
    }
  }
}

/**
 * A special union type of `Future<T> | T` used for Strong Mode inference.
 */
class FutureUnionType extends TypeImpl {
  // TODO(jmesserly): a Set would be better.
  //
  // For now we know `Future<T> | T` is the only valid use, so we can rely on
  // the order, which simplifies some things.
  //
  // This will need clean up before this can function as a real union type.
  final List<DartType> _types;

  /**
   * Creates a union of `Future< flatten(T) > | flatten(T)`.
   */
  factory FutureUnionType(
      DartType type, TypeProvider provider, TypeSystem system) {
    type = type.flattenFutures(system);

    // The order of these types is important: T could be a type variable, so
    // we want to try and match `Future<T>` before we try and match `T`.
    return new FutureUnionType._([
      provider.futureType.instantiate([type]),
      type
    ]);
  }

  FutureUnionType._(this._types) : super(null, null);

  DartType get futureOfType => _types[0];

  DartType get type => _types[1];

  Iterable<DartType> get types => _types;

  @override
  void appendTo(StringBuffer buffer) {
    buffer.write('(');
    for (int i = 0; i < _types.length; i++) {
      if (i != 0) {
        buffer.write(' | ');
      }
      (_types[i] as TypeImpl).appendTo(buffer);
    }
    buffer.write(')');
  }

  @override
  int get hashCode {
    int hash = 0;
    for (var t in types) {
      hash = JenkinsSmiHash.combine(hash, t.hashCode);
    }
    return JenkinsSmiHash.finish(hash);
  }

  @override
  bool operator ==(Object obj) {
    if (obj is FutureUnionType) {
      if (identical(obj, this)) return true;
      return types.length == obj.types.length &&
          types.toSet().containsAll(obj.types);
    }
    return false;
  }

  @override
  bool isMoreSpecificThan(DartType type,
          [bool withDynamic = false, Set<Element> visitedElements]) =>
      throw new UnsupportedError(
          'Future unions are not part of the Dart 1 type system');

  @override
  TypeImpl pruned(List<FunctionTypeAliasElement> prune) =>
      throw new UnsupportedError('Future unions are not substituted');

  @override
  DartType substitute2(List<DartType> args, List<DartType> params,
          [List<FunctionTypeAliasElement> prune]) =>
      throw new UnsupportedError('Future unions are not used in typedefs');

  /**
   * Creates a union of `T | Future<T>`, unless `T` is already a future-union,
   * in which case it simply returns `T`
   */
  static DartType from(
      DartType type, TypeProvider provider, TypeSystem system) {
    if (type is FutureUnionType) {
      return type;
    }
    return new FutureUnionType(type, provider, system);
  }
}

bool _isBottom(DartType t, {bool dynamicIsBottom: false}) {
  return (t.isDynamic && dynamicIsBottom) || t.isBottom;
}

bool _isTop(DartType t, {bool dynamicIsBottom: false}) {
  // TODO(leafp): Document the rules in play here
  return (t.isDynamic && !dynamicIsBottom) || t.isObject;
}
