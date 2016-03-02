// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.type_system;

import 'dart:collection';
import 'dart:math' as math;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/utilities_dart.dart';

typedef bool _GuardedSubtypeChecker<T>(T t1, T t2, Set<Element> visited);

/**
 * Implementation of [TypeSystem] using the strong mode rules.
 * https://github.com/dart-lang/dev_compiler/blob/master/STRONG_MODE.md
 */
class StrongTypeSystemImpl extends TypeSystem {
  final _specTypeSystem = new TypeSystemImpl();

  StrongTypeSystemImpl();

  bool anyParameterType(FunctionType ft, bool predicate(DartType t)) {
    return ft.parameters.any((p) => predicate(p.type));
  }

  @override
  bool canPromoteToType(DartType to, DartType from) => isSubtypeOf(to, from);

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

  @override
  DartType getLeastUpperBound(
      TypeProvider typeProvider, DartType type1, DartType type2) {
    // TODO(leafp): Implement a strong mode version of this.
    return _specTypeSystem.getLeastUpperBound(typeProvider, type1, type2);
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
        new _StrongInferenceTypeSystem(typeProvider, fnType.typeFormals);

    // Since we're trying to infer the instantiation, we want to ignore type
    // formals as we check the parameters and return type.
    var inferFnType =
        fnType.instantiate(TypeParameterTypeImpl.getTypes(fnType.typeFormals));
    if (!inferringTypeSystem.isSubtypeOf(inferFnType, contextType)) {
      return fnType;
    }

    // Try to infer and instantiate the resulting type.
    var resultType =
        inferringTypeSystem._infer(fnType, allowPartialSolution: false);

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
        new _StrongInferenceTypeSystem(typeProvider, fnType.typeFormals);

    if (returnContextType != null) {
      inferringTypeSystem.isSubtypeOf(fnType.returnType, returnContextType);
    }

    for (int i = 0; i < argumentTypes.length; i++) {
      // Try to pass each argument to each parameter, recording any type
      // parameter bounds that were implied by this assignment.
      inferringTypeSystem.isSubtypeOf(
          argumentTypes[i], correspondingParameterTypes[i]);
    }

    // We are okay inferring some type variables and not others.
    //
    // This lets our return type be as precise as possible, which will help
    // make any type information resulting from it more precise.
    //
    // This is simply a heuristic: the code is incorrect, and we'll issue an
    // error on this call, to indicate that types don't match.
    return inferringTypeSystem._infer(fnType, allowPartialSolution: true);
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

    // Don't allow implicit downcasts between function types
    // and call method objects, as these will almost always fail.
    if ((fromType is FunctionType && getCallMethodType(toType) != null) ||
        (toType is FunctionType && getCallMethodType(fromType) != null)) {
      return false;
    }

    // If the subtype relation goes the other way, allow the implicit downcast.
    // TODO(leafp): Emit warnings and hints for these in some way.
    // TODO(leafp): Consider adding a flag to disable these?  Or just rely on
    //   --warnings-as-errors?
    if (isSubtypeOf(toType, fromType) ||
        _specTypeSystem.isAssignableTo(toType, fromType)) {
      // TODO(leafp): error if type is known to be exact (literal,
      //  instance creation).
      // TODO(leafp): Warn on composite downcast.
      // TODO(leafp): hint on object/dynamic downcast.
      // TODO(leafp): Consider allowing assignment casts.
      return true;
    }

    return false;
  }

  bool isGroundType(DartType t) {
    // TODO(leafp): Revisit this.
    if (t is TypeParameterType) return false;
    if (_isTop(t)) return true;

    if (t is FunctionType) {
      if (!_isTop(t.returnType) ||
          anyParameterType(t, (pt) => !_isBottom(pt, dynamicIsBottom: true))) {
        return false;
      } else {
        return true;
      }
    }

    if (t is InterfaceType) {
      var typeArguments = t.typeArguments;
      for (var typeArgument in typeArguments) {
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

  bool _isBottom(DartType t, {bool dynamicIsBottom: false}) {
    return (t.isDynamic && dynamicIsBottom) || t.isBottom;
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
    _GuardedSubtypeChecker<InterfaceType> guardedInterfaceSubtype =
        _guard(_isInterfaceSubtypeOf);

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

    // The types are void, dynamic, bottom, interface types, function types
    // and type parameters.  We proceed by eliminating these different classes
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

  // TODO(leafp): Document the rules in play here
  bool _isTop(DartType t, {bool dynamicIsBottom: false}) {
    return (t.isDynamic && !dynamicIsBottom) || t.isObject;
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
   * Compute the least upper bound of two types.
   */
  DartType getLeastUpperBound(
      TypeProvider typeProvider, DartType type1, DartType type2);

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
   * Create either a strong mode or regular type system based on context.
   */
  static TypeSystem create(AnalysisContext context) {
    return (context.analysisOptions.strongMode)
        ? new StrongTypeSystemImpl()
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
  DartType getLeastUpperBound(
      TypeProvider typeProvider, DartType type1, DartType type2) {
    // The least upper bound relation is reflexive.
    if (identical(type1, type2)) {
      return type1;
    }
    // The least upper bound of dynamic and any type T is dynamic.
    if (type1.isDynamic) {
      return type1;
    }
    if (type2.isDynamic) {
      return type2;
    }
    // The least upper bound of void and any type T != dynamic is void.
    if (type1.isVoid) {
      return type1;
    }
    if (type2.isVoid) {
      return type2;
    }
    // The least upper bound of bottom and any type T is T.
    if (type1.isBottom) {
      return type2;
    }
    if (type2.isBottom) {
      return type1;
    }

    // Let U be a type variable with upper bound B.  The least upper bound of U
    // and a type T is the least upper bound of B and T.
    type1 = type1.resolveToBound(typeProvider.objectType);
    type2 = type2.resolveToBound(typeProvider.objectType);

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
      InterfaceType result =
          InterfaceTypeImpl.computeLeastUpperBound(type1, type2);
      if (result == null) {
        return typeProvider.dynamicType;
      }
      return result;
    } else if (type1 is FunctionType && type2 is FunctionType) {
      return _functionLeastUpperBound(typeProvider, type1, type2);
    } else {
      // Should never happen.  As a defensive measure, return the dynamic type.
      assert(false);
      return typeProvider.dynamicType;
    }
  }

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
          getLeastUpperBound(provider, fRequired[i], gRequired[i]),
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
          getLeastUpperBound(provider, fPositional[i], gPositional[i]),
          ParameterKind.POSITIONAL));
    }

    Map<String, DartType> fNamed = f.namedParameterTypes;
    Map<String, DartType> gNamed = g.namedParameterTypes;
    for (String name in fNamed.keys.toSet()..retainAll(gNamed.keys)) {
      parameters.add(new ParameterElementImpl.synthetic(
          name,
          getLeastUpperBound(provider, fNamed[name], gNamed[name]),
          ParameterKind.NAMED));
    }

    // Calculate the LUB of the return type.
    DartType returnType =
        getLeastUpperBound(provider, f.returnType, g.returnType);

    FunctionElementImpl function = new FunctionElementImpl("", -1);
    function.synthetic = true;
    function.returnType = returnType;
    function.parameters = parameters;

    function.type = new FunctionTypeImpl(function);
    return function.type;
  }
}

/// Tracks upper and lower type bounds for a set of type parameters.
class _StrongInferenceTypeSystem extends StrongTypeSystemImpl {
  final TypeProvider _typeProvider;
  final Map<TypeParameterType, _TypeParameterBound> _bounds;

  _StrongInferenceTypeSystem(
      this._typeProvider, Iterable<TypeParameterElement> typeFormals)
      : _bounds =
            new Map.fromIterable(typeFormals, key: (t) => t.type, value: (t) {
          _TypeParameterBound bound = new _TypeParameterBound();
          if (t.bound != null) bound.upper = t.bound;
          return bound;
        });

  /// Given the constraints that were given by calling [isSubtypeOf], find the
  /// instantiation of the generic function that satisfies these constraints.
  FunctionType _infer(FunctionType fnType, {bool allowPartialSolution: false}) {
    List<TypeParameterType> fnTypeParams =
        TypeParameterTypeImpl.getTypes(fnType.typeFormals);

    var inferredTypes = new List<DartType>.from(fnTypeParams, growable: false);
    for (int i = 0; i < fnTypeParams.length; i++) {
      TypeParameterType typeParam = fnTypeParams[i];
      _TypeParameterBound bound = _bounds[typeParam];

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

      inferredTypes[i] =
          variance.passedIn || bound.lower.isBottom ? bound.upper : bound.lower;

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
      inferredTypes[i] =
          inferredTypes[i].substitute2(inferredTypes, fnTypeParams);

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
        // Unless a partial solution was requested, bail.
        if (!allowPartialSolution) {
          return null;
        }

        inferredTypes[i] = DynamicTypeImpl.instance;
        if (typeParam.element.bound != null) {
          inferredTypes[i] =
              typeParam.element.bound.substitute2(inferredTypes, fnTypeParams);
        }
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
        _GuardedSubtypeChecker<DartType> guardedSubtype = _guard(_isSubtypeOf);

        DartType newUpper = t2;
        if (guardedSubtype(bound.upper, newUpper, visited)) {
          // upper bound already covers this. Nothing to do.
        } else if (guardedSubtype(newUpper, bound.upper, visited)) {
          // update to the new, more precise upper bound.
          bound.upper = newUpper;
        } else {
          // Failed to find an upper bound. Use bottom to signal no solution.
          bound.upper = BottomTypeImpl.instance;
        }
        // Optimistically assume we will be able to satisfy the constraint.
        return true;
      }
    }
    if (t2 is TypeParameterType) {
      _TypeParameterBound bound = _bounds[t2];
      if (bound != null) {
        bound.lower = getLeastUpperBound(_typeProvider, bound.lower, t1);
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
      // If a lambda L is passed in to a function F, the the parameters are
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
