// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'dart:math' as math;

import 'package:front_end/src/fasta/type_inference/type_constraint_gatherer.dart';
import 'package:front_end/src/fasta/type_inference/type_schema.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_elimination.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

/// A constraint on a type parameter that we're inferring.
class TypeConstraint {
  /// The lower bound of the type being constrained.  This bound must be a
  /// subtype of the type being constrained.
  DartType lower;

  /// The upper bound of the type being constrained.  The type being constrained
  /// must be a subtype of this bound.
  DartType upper;

  TypeConstraint()
      : lower = const UnknownType(),
        upper = const UnknownType();

  TypeConstraint._(this.lower, this.upper);

  TypeConstraint clone() => new TypeConstraint._(lower, upper);

  String toString() =>
      '${typeSchemaToString(lower)} <: <type> <: ${typeSchemaToString(upper)}';
}

class TypeSchemaEnvironment extends TypeEnvironment {
  @override
  final bool strongMode;

  TypeSchemaEnvironment(
      CoreTypes coreTypes, ClassHierarchy hierarchy, this.strongMode)
      : super(coreTypes, hierarchy);

  /// Modify the given [constraint]'s lower bound to include [lower].
  void addLowerBound(TypeConstraint constraint, DartType lower) {
    constraint.lower = getLeastUpperBound(constraint.lower, lower);
  }

  /// Modify the given [constraint]'s upper bound to include [upper].
  void addUpperBound(TypeConstraint constraint, DartType upper) {
    constraint.upper = getGreatestLowerBound(constraint.upper, upper);
  }

  /// Implements the function "flatten" defined in the spec, where T is [type]:
  ///
  ///     If T = Future<S> then flatten(T) = flatten(S).
  ///
  ///     Otherwise if T <: Future then let S be a type such that T << Future<S>
  ///     and for all R, if T << Future<R> then S << R.  Then flatten(T) = S.
  ///
  ///     In any other circumstance, flatten(T) = T.
  DartType flattenFutures(DartType type) {
    if (type is InterfaceType) {
      if (identical(type.classNode, coreTypes.futureClass)) {
        return flattenFutures(type.typeArguments[0]);
      }
      InterfaceType futureBase =
          hierarchy.getTypeAsInstanceOf(type, coreTypes.futureClass);
      if (futureBase != null) {
        return futureBase.typeArguments[0];
      }
    }
    return type;
  }

  /// Computes the greatest lower bound of [type1] and [type2].
  DartType getGreatestLowerBound(DartType type1, DartType type2) {
    // The greatest lower bound relation is reflexive.  Note that we don't test
    // for equality because we don't want to make the algorithm quadratic.  This
    // is ok because the check is not needed for correctness; it's just a speed
    // optimization.
    if (identical(type1, type2)) {
      return type1;
    }

    // For any type T, GLB(?, T) == T.
    if (type1 is UnknownType) {
      return type2;
    }
    if (type2 is UnknownType) {
      return type1;
    }

    // The GLB of top and any type is just that type.
    // Also GLB of bottom and any type is bottom.
    if (isTop(type1) || isBottom(type2)) {
      return type2;
    }
    if (isTop(type2) || isBottom(type1)) {
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
    return const BottomType();
  }

  /// Compute the least upper bound of two types.
  DartType getLeastUpperBound(DartType type1, DartType type2) {
    // The least upper bound relation is reflexive.  Note that we don't test
    // for equality because we don't want to make the algorithm quadratic.  This
    // is ok because the check is not needed for correctness; it's just a speed
    // optimization.
    if (identical(type1, type2)) {
      return type1;
    }

    // For any type T, LUB(?, T) == T.
    if (type1 is UnknownType) {
      return type2;
    }
    if (type2 is UnknownType) {
      return type1;
    }

    // The least upper bound of void and any type T != dynamic is void.
    if (type1 is VoidType) {
      return type2 is DynamicType ? type2 : type1;
    }
    if (type2 is VoidType) {
      return type1 is DynamicType ? type1 : type2;
    }

    // The least upper bound of top and any type T is top.
    // The least upper bound of bottom and any type T is T.
    if (isTop(type1) || isBottom(type2)) {
      return type1;
    }
    if (isTop(type2) || isBottom(type1)) {
      return type2;
    }

    if (type1 is TypeParameterType || type2 is TypeParameterType) {
      return _typeParameterLeastUpperBound(type1, type2);
    }

    // The least upper bound of a function type and an interface type T is the
    // least upper bound of Function and T.
    if (type1 is FunctionType && type2 is InterfaceType) {
      type1 = rawFunctionType;
    }
    if (type2 is FunctionType && type1 is InterfaceType) {
      type2 = rawFunctionType;
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
    return const DynamicType();
  }

  @override
  DartType getTypeOfOverloadedArithmetic(DartType type1, DartType type2) {
    // TODO(paulberry): this matches what is defined in the spec.  It would be
    // nice if we could change kernel to match the spec and not have to
    // override.
    if (type1 == intType) {
      if (type2 == intType) return type2;
      if (type2 == doubleType) return type2;
    }
    return numType;
  }

  /// Infers a generic type, function, method, or list/map literal
  /// instantiation, using the downward context type as well as the argument
  /// types if available.
  ///
  /// For example, given a function type with generic type parameters, this
  /// infers the type parameters from the actual argument types.
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
  ///
  /// If non-null values for [formalTypes] and [actualTypes] are provided, this
  /// is upwards inference.  Otherwise it is downward inference.
  void inferGenericFunctionOrType(
      DartType declaredReturnType,
      List<TypeParameter> typeParametersToInfer,
      List<DartType> formalTypes,
      List<DartType> actualTypes,
      DartType returnContextType,
      List<DartType> inferredTypes) {
    if (typeParametersToInfer.isEmpty) {
      return;
    }

    // Create a TypeConstraintGatherer that will allow certain type parameters
    // to be inferred. It will optimistically assume these type parameters can
    // be subtypes (or supertypes) as necessary, and track the constraints that
    // are implied by this.
    var gatherer = new TypeConstraintGatherer(this, typeParametersToInfer);

    if (!isEmptyContext(returnContextType)) {
      gatherer.trySubtypeMatch(declaredReturnType, returnContextType);
    }

    if (formalTypes != null) {
      for (int i = 0; i < formalTypes.length; i++) {
        // Try to pass each argument to each parameter, recording any type
        // parameter bounds that were implied by this assignment.
        gatherer.trySubtypeMatch(actualTypes[i], formalTypes[i]);
      }
    }

    inferTypeFromConstraints(
        gatherer.computeConstraints(), typeParametersToInfer, inferredTypes,
        downwardsInferPhase: formalTypes == null);
  }

  /// Use the given [constraints] to substitute for type variables..
  ///
  /// [typeParametersToInfer] is the set of type parameters that should be
  /// substituted for.  [inferredTypes] should be a list of the same length.
  ///
  /// If [downwardsInferPhase] is `true`, then we are in the first pass of
  /// inference, pushing context types down.  This means we are allowed to push
  /// down `?` to precisely represent an unknown type.  [inferredTypes] should
  /// be initially populated with `?`.  These `?`s will be replaced, if
  /// appropriate, with the types that were inferred by downwards inference.
  ///
  /// If [downwardsInferPhase] is `false`, then we are in the second pass of
  /// inference, and must not conclude `?` for any type formal.  In this pass,
  /// [inferredTypes] should contain the values from the first pass.  They will
  /// be replaced with the final inferred types.
  void inferTypeFromConstraints(Map<TypeParameter, TypeConstraint> constraints,
      List<TypeParameter> typeParametersToInfer, List<DartType> inferredTypes,
      {bool downwardsInferPhase: false}) {
    List<DartType> typesFromDownwardsInference =
        downwardsInferPhase ? null : inferredTypes.toList(growable: false);

    for (int i = 0; i < typeParametersToInfer.length; i++) {
      TypeParameter typeParam = typeParametersToInfer[i];

      var typeParamBound = typeParam.bound;
      DartType extendsConstraint;
      if (!_isObjectOrDynamic(typeParamBound)) {
        extendsConstraint = Substitution
            .fromPairs(typeParametersToInfer, inferredTypes)
            .substituteType(typeParamBound);
      }

      var constraint = constraints[typeParam];
      if (downwardsInferPhase) {
        inferredTypes[i] =
            _inferTypeParameterFromContext(constraint, extendsConstraint);
      } else {
        inferredTypes[i] = _inferTypeParameterFromAll(
            typesFromDownwardsInference[i], constraint, extendsConstraint);
      }
    }

    // If the downwards infer phase has failed, we'll catch this in the upwards
    // phase later on.
    if (downwardsInferPhase) {
      return;
    }

    // Check the inferred types against all of the constraints.
    var knownTypes = <TypeParameter, DartType>{};
    for (int i = 0; i < typeParametersToInfer.length; i++) {
      TypeParameter typeParam = typeParametersToInfer[i];
      var constraint = constraints[typeParam];
      var typeParamBound = Substitution
          .fromPairs(typeParametersToInfer, inferredTypes)
          .substituteType(typeParam.bound);

      var inferred = inferredTypes[i];
      bool success = typeSatisfiesConstraint(inferred, constraint);
      if (success && !_isObjectOrDynamic(typeParamBound)) {
        // If everything else succeeded, check the `extends` constraint.
        var extendsConstraint = typeParamBound;
        success = isSubtypeOf(inferred, extendsConstraint);
      }

      if (!success) {
        // TODO(paulberry): report error.

        // Heuristic: even if we failed, keep the erroneous type.
        // It should satisfy at least some of the constraints (e.g. the return
        // context). If we fall back to instantiateToBounds, we'll typically get
        // more errors (e.g. because `dynamic` is the most common bound).
      }

      if (isKnown(inferred)) {
        knownTypes[typeParam] = inferred;
      }
    }

    // TODO(paulberry): report any errors from instantiateToBounds.
  }

  /// Given a [DartType] [type], if [type] is an uninstantiated
  /// parameterized type then instantiate the parameters to their
  /// bounds. See the issue for the algorithm description.
  ///
  /// https://github.com/dart-lang/sdk/issues/27526#issuecomment-260021397
  ///
  /// TODO(paulberry) Compute lazily and cache.
  DartType instantiateToBounds(DartType type,
      {Map<TypeParameter, DartType> knownTypes}) {
    List<TypeParameter> typeFormals = _typeFormalsAsParameters(type);
    int count = typeFormals.length;
    if (count == 0) {
      return type;
    }
    var substitution = <TypeParameter, DartType>{};
    for (TypeParameter parameter in typeFormals) {
      // Note: we treat class<T extends Object> as equivalent to class<T>; in
      // both cases they instantiate to class<dynamic>.  See dartbug.com/29561
      if (_isObjectOrDynamic(parameter.bound)) {
        substitution[parameter] = const DynamicType();
      } else {
        substitution[parameter] = parameter.bound;
      }
    }
    if (knownTypes != null) {
      type = substitute(type, knownTypes);
    }
    var result = substituteDeep(type, substitution);
    if (result != null) return result;

    // Instantiation failed due to a circularity.
    // TODO(paulberry): report the error.
    // Substitute `dynamic` for all parameters to try to allow compilation to
    // continue.  Note that [substituteDeep] is destructive of the
    // [substitution] so we create a fresh one.
    substitution = <TypeParameter, DartType>{};
    for (TypeParameter parameter in typeFormals) {
      substitution[parameter] = const DynamicType();
    }
    return substitute(type, substitution);
  }

  @override
  bool isBottom(DartType t) {
    if (t is UnknownType) {
      return true;
    } else if (t is InterfaceType &&
        identical(t.classNode, coreTypes.nullClass)) {
      return true;
    } else {
      return super.isBottom(t);
    }
  }

  bool isEmptyContext(DartType context) {
    if (context is DynamicType) {
      // Analyzer treats a type context of `dynamic` as equivalent to an empty
      // context.  TODO(paulberry): this is not spec'ed anywhere; do we still
      // want to do this?
      return true;
    }
    return context == null;
  }

  /// True if [member] is a binary operator that returns an `int` if both
  /// operands are `int`, and otherwise returns `double`.
  ///
  /// Note that this behavior depends on the receiver type, so we can only make
  /// this determination if we know the type of the receiver.
  ///
  /// This is a case of type-based overloading, which in Dart is only supported
  /// by giving special treatment to certain arithmetic operators.
  bool isOverloadedArithmeticOperatorAndType(
      Procedure member, DartType receiverType) {
    // TODO(paulberry): this matches what is defined in the spec.  It would be
    // nice if we could change kernel to match the spec and not have to
    // override.
    if (member.name.name == 'remainder') return false;
    if (!(receiverType is InterfaceType &&
        identical(receiverType.classNode, coreTypes.intClass))) {
      return false;
    }
    return isOverloadedArithmeticOperator(member);
  }

  @override
  bool isTop(DartType t) {
    if (t is UnknownType) {
      return true;
    } else {
      return super.isTop(t);
    }
  }

  /// Computes the constraint solution for a type variable based on a given set
  /// of constraints.
  ///
  /// If [grounded] is `true`, then the returned type is guaranteed to be a
  /// known type (i.e. it will not contain any instances of `?`).
  DartType solveTypeConstraint(TypeConstraint constraint,
      {bool grounded: false}) {
    // Prefer the known bound, if any.
    if (isKnown(constraint.lower)) return constraint.lower;
    if (isKnown(constraint.upper)) return constraint.upper;

    // Otherwise take whatever bound has partial information, e.g. `Iterable<?>`
    if (constraint.lower is! UnknownType) {
      return grounded
          ? leastClosure(coreTypes, constraint.lower)
          : constraint.lower;
    } else {
      return grounded
          ? greatestClosure(coreTypes, constraint.upper)
          : constraint.upper;
    }
  }

  /// Determine if the given [type] satisfies the given type [constraint].
  bool typeSatisfiesConstraint(DartType type, TypeConstraint constraint) {
    return isSubtypeOf(constraint.lower, type) &&
        isSubtypeOf(type, constraint.upper);
  }

  /// Compute the greatest lower bound of function types [f] and [g].
  ///
  /// The spec rules for GLB on function types, informally, are pretty simple:
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
  /// - For any parameter that exists in both functions, use the LUB of them as
  ///   the resulting parameter type.
  ///
  /// - Use the GLB of their return types.
  DartType _functionGreatestLowerBound(FunctionType f, FunctionType g) {
    // TODO(rnystrom,paulberry): Right now, this assumes f and g do not have any
    // type parameters. Revisit that in the presence of generic methods.

    // Calculate the LUB of each corresponding pair of parameters.
    int totalPositional =
        math.max(f.positionalParameters.length, g.positionalParameters.length);
    var positionalParameters = new List<DartType>(totalPositional);
    for (int i = 0; i < totalPositional; i++) {
      if (i < f.positionalParameters.length) {
        var fType = f.positionalParameters[i];
        if (i < g.positionalParameters.length) {
          var gType = g.positionalParameters[i];
          positionalParameters[i] = getLeastUpperBound(fType, gType);
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
            var fName = f.namedParameters[i].name;
            var gName = g.namedParameters[j].name;
            int order = fName.compareTo(gName);
            if (order < 0) {
              namedParameters.add(f.namedParameters[i++]);
            } else if (order > 0) {
              namedParameters.add(g.namedParameters[j++]);
            } else {
              namedParameters.add(new NamedType(
                  fName,
                  getLeastUpperBound(f.namedParameters[i++].type,
                      g.namedParameters[j++].type)));
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
    if (hasPositional && hasNamed) return const BottomType();

    // Calculate the GLB of the return type.
    DartType returnType = getGreatestLowerBound(f.returnType, g.returnType);
    return new FunctionType(positionalParameters, returnType,
        namedParameters: namedParameters,
        requiredParameterCount: requiredParameterCount);
  }

  /// Compute the least upper bound of function types [f] and [g].
  ///
  /// The rules for LUB on function types, informally, are pretty simple:
  ///
  /// - If the functions don't have the same number of required parameters,
  ///   always return `Function`.
  ///
  /// - Discard any optional named or positional parameters the two types do not
  ///   have in common.
  ///
  /// - Compute the GLB of each corresponding pair of parameter types, and the
  ///   LUB of the return types.  Return a function type with those types.
  DartType _functionLeastUpperBound(FunctionType f, FunctionType g) {
    // TODO(rnystrom): Right now, this assumes f and g do not have any type
    // parameters. Revisit that in the presence of generic methods.

    // If F and G differ in their number of required parameters, then the
    // least upper bound of F and G is Function.
    // TODO(paulberry): We could do better here, e.g.:
    //   LUB(([int]) -> void, (int) -> void) = (int) -> void
    if (f.requiredParameterCount != g.requiredParameterCount) {
      return coreTypes.functionClass.rawType;
    }
    int requiredParameterCount = f.requiredParameterCount;

    // Calculate the GLB of each corresponding pair of parameters.
    // Ignore any extra optional positional parameters if one has more than the
    // other.
    int totalPositional =
        math.min(f.positionalParameters.length, g.positionalParameters.length);
    var positionalParameters = new List<DartType>(totalPositional);
    for (int i = 0; i < totalPositional; i++) {
      positionalParameters[i] = getGreatestLowerBound(
          f.positionalParameters[i], g.positionalParameters[i]);
    }

    // Intersect the named parameters.
    List<NamedType> namedParameters = [];
    {
      int i = 0;
      int j = 0;
      while (true) {
        if (i < f.namedParameters.length) {
          if (j < g.namedParameters.length) {
            var fName = f.namedParameters[i].name;
            var gName = g.namedParameters[j].name;
            int order = fName.compareTo(gName);
            if (order < 0) {
              i++;
            } else if (order > 0) {
              j++;
            } else {
              namedParameters.add(new NamedType(
                  fName,
                  getGreatestLowerBound(f.namedParameters[i++].type,
                      g.namedParameters[j++].type)));
            }
          } else {
            break;
          }
        } else {
          break;
        }
      }
    }

    // Calculate the LUB of the return type.
    DartType returnType = getLeastUpperBound(f.returnType, g.returnType);
    return new FunctionType(positionalParameters, returnType,
        namedParameters: namedParameters,
        requiredParameterCount: requiredParameterCount);
  }

  DartType _inferTypeParameterFromAll(DartType typeFromContextInference,
      TypeConstraint constraint, DartType extendsConstraint) {
    // See if we already fixed this type from downwards inference.
    // If so, then we aren't allowed to change it based on argument types.
    if (isKnown(typeFromContextInference)) {
      return typeFromContextInference;
    }

    if (extendsConstraint != null) {
      constraint = constraint.clone();
      addUpperBound(constraint, extendsConstraint);
    }

    return solveTypeConstraint(constraint, grounded: true);
  }

  DartType _inferTypeParameterFromContext(
      TypeConstraint constraint, DartType extendsConstraint) {
    DartType t = solveTypeConstraint(constraint);
    if (!isKnown(t)) {
      return t;
    }

    // If we're about to make our final choice, apply the extends clause.
    // This gives us a chance to refine the choice, in case it would violate
    // the `extends` clause. For example:
    //
    //     Object obj = math.min/*<infer Object, error>*/(1, 2);
    //
    // If we consider the `T extends num` we conclude `<num>`, which works.
    if (extendsConstraint != null) {
      constraint = constraint.clone();
      addUpperBound(constraint, extendsConstraint);
      return solveTypeConstraint(constraint);
    }
    return t;
  }

  DartType _interfaceLeastUpperBound(InterfaceType type1, InterfaceType type2) {
    // This currently does not implement a very complete least upper bound
    // algorithm, but handles a couple of the very common cases that are
    // causing pain in real code.  The current algorithm is:
    // 1. If either of the types is a supertype of the other, return it.
    //    This is in fact the best result in this case.
    // 2. If the two types have the same class element, then take the
    //    pointwise least upper bound of the type arguments.  This is again
    //    the best result, except that the recursive calls may not return
    //    the true least upper bounds.  The result is guaranteed to be a
    //    well-formed type under the assumption that the input types were
    //    well-formed (and assuming that the recursive calls return
    //    well-formed types).
    // 3. Otherwise return the spec-defined least upper bound.  This will
    //    be an upper bound, might (or might not) be least, and might
    //    (or might not) be a well-formed type.
    if (isSubtypeOf(type1, type2)) {
      return type2;
    }
    if (isSubtypeOf(type2, type1)) {
      return type1;
    }
    if (type1 is InterfaceType &&
        type2 is InterfaceType &&
        identical(type1.classNode, type2.classNode)) {
      List<DartType> tArgs1 = type1.typeArguments;
      List<DartType> tArgs2 = type2.typeArguments;

      assert(tArgs1.length == tArgs2.length);
      List<DartType> tArgs = new List(tArgs1.length);
      for (int i = 0; i < tArgs1.length; i++) {
        tArgs[i] = getLeastUpperBound(tArgs1[i], tArgs2[i]);
      }
      return new InterfaceType(type1.classNode, tArgs);
    }
    return hierarchy.getClassicLeastUpperBound(type1, type2);
  }

  bool _isObjectOrDynamic(DartType type) =>
      type is DynamicType ||
      (type is InterfaceType &&
          identical(type.classNode, coreTypes.objectClass));

  /// Given a [type], returns the [TypeParameter]s corresponding to its formal
  /// type parameters (if any).
  List<TypeParameter> _typeFormalsAsParameters(DartType type) {
    if (type is TypedefType) {
      return type.typedefNode.typeParameters;
    } else if (type is InterfaceType) {
      return type.classNode.typeParameters;
    } else {
      return const [];
    }
  }

  DartType _typeParameterLeastUpperBound(DartType type1, DartType type2) {
    // This currently just implements a simple least upper bound to
    // handle some common cases.  It also avoids some termination issues
    // with the naive spec algorithm.  The least upper bound of two types
    // (at least one of which is a type parameter) is computed here as:
    // 1. If either type is a supertype of the other, return it.
    // 2. If the first type is a type parameter, replace it with its bound,
    //    with recursive occurrences of itself replaced with Object.
    //    The second part of this should ensure termination.  Informally,
    //    each type variable instantiation in one of the arguments to the
    //    least upper bound algorithm now strictly reduces the number
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
    if (isSubtypeOf(type1, type2)) {
      return type2;
    }
    if (isSubtypeOf(type2, type1)) {
      return type1;
    }
    if (type1 is TypeParameterType) {
      // TODO(paulberry): Analyzer collapses simple bounds in one step, i.e. for
      // C<T extends U, U extends List>, T gets resolved directly to List.  Do
      // we need to replicate that behavior?
      return getLeastUpperBound(
          Substitution.fromMap({type1.parameter: objectType}).substituteType(
              type1.parameter.bound),
          type2);
    } else if (type2 is TypeParameterType) {
      return getLeastUpperBound(
          type1,
          Substitution.fromMap({type2.parameter: objectType}).substituteType(
              type2.parameter.bound));
    } else {
      // We should only be called when at least one of the types is a
      // TypeParameterType
      assert(false);
      return const DynamicType();
    }
  }
}
