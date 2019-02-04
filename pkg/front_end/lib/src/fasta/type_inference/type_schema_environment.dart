// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'dart:math' as math;

import 'package:kernel/ast.dart'
    show
        BottomType,
        DartType,
        DynamicType,
        FunctionType,
        InterfaceType,
        NamedType,
        Procedure,
        TypeParameter,
        TypeParameterType,
        VoidType;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/type_algebra.dart' show Substitution;

import 'package:kernel/src/hierarchy_based_type_environment.dart'
    show HierarchyBasedTypeEnvironment;

import 'type_constraint_gatherer.dart' show TypeConstraintGatherer;

import 'type_schema.dart' show UnknownType, typeSchemaToString, isKnown;

import 'type_schema_elimination.dart' show greatestClosure, leastClosure;

// TODO(paulberry): try to push this functionality into kernel.
FunctionType substituteTypeParams(
    FunctionType type,
    Map<TypeParameter, DartType> substitutionMap,
    List<TypeParameter> newTypeParameters) {
  var substitution = Substitution.fromMap(substitutionMap);
  return new FunctionType(
      type.positionalParameters.map(substitution.substituteType).toList(),
      substitution.substituteType(type.returnType),
      namedParameters: type.namedParameters
          .map((named) => new NamedType(
              named.name, substitution.substituteType(named.type)))
          .toList(),
      typeParameters: newTypeParameters,
      requiredParameterCount: type.requiredParameterCount,
      typedefType: type.typedefType == null
          ? null
          : substitution.substituteType(type.typedefType));
}

/// Given a [FunctionType], gets the type of the named parameter with the given
/// [name], or `dynamic` if there is no parameter with the given name.
DartType getNamedParameterType(FunctionType functionType, String name) {
  return functionType.getNamedParameter(name) ?? const DynamicType();
}

/// Given a [FunctionType], gets the type of the [i]th positional parameter, or
/// `dynamic` if there is no parameter with that index.
DartType getPositionalParameterType(FunctionType functionType, int i) {
  if (i < functionType.positionalParameters.length) {
    return functionType.positionalParameters[i];
  } else {
    return const DynamicType();
  }
}

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

class TypeSchemaEnvironment extends HierarchyBasedTypeEnvironment {
  TypeSchemaEnvironment(CoreTypes coreTypes, ClassHierarchy hierarchy)
      : super(coreTypes, hierarchy);

  /// Modify the given [constraint]'s lower bound to include [lower].
  void addLowerBound(TypeConstraint constraint, DartType lower) {
    constraint.lower = getStandardUpperBound(constraint.lower, lower);
  }

  /// Modify the given [constraint]'s upper bound to include [upper].
  void addUpperBound(TypeConstraint constraint, DartType upper) {
    constraint.upper = getStandardLowerBound(constraint.upper, upper);
  }

  /// Computes the standard lower bound of [type1] and [type2].
  ///
  /// Standard lower bound is a lower bound function that imposes an
  /// ordering on the top types `void`, `dynamic`, and `object`.  This function
  /// additionally handles the unknown type that appears during type inference.
  DartType getStandardLowerBound(DartType type1, DartType type2) {
    // For all types T, SLB(T,T) = T.  Note that we don't test for equality
    // because we don't want to make the algorithm quadratic.  This is ok
    // because the check is not needed for correctness; it's just a speed
    // optimization.
    if (identical(type1, type2)) {
      return type1;
    }

    // For any type T, SLB(?, T) = SLB(T, ?) = T.
    if (type1 is UnknownType) {
      return type2;
    }
    if (type2 is UnknownType) {
      return type1;
    }

    // SLB(void, T) = SLB(T, void) = T.
    if (type1 is VoidType) {
      return type2;
    }
    if (type2 is VoidType) {
      return type1;
    }

    // SLB(dynamic, T) = SLB(T, dynamic) = T if T is not void.
    if (type1 is DynamicType) {
      return type2;
    }
    if (type2 is DynamicType) {
      return type1;
    }

    // SLB(Object, T) = SLB(T, Object) = T if T is not void or dynamic.
    if (type1 == objectType) {
      return type2;
    }
    if (type2 == objectType) {
      return type1;
    }

    // SLB(bottom, T) = SLB(T, bottom) = bottom.
    if (type1 is BottomType) return type1;
    if (type2 is BottomType) return type2;
    if (type1 == nullType) return type1;
    if (type2 == nullType) return type2;

    // Function types have structural lower bounds.
    if (type1 is FunctionType && type2 is FunctionType) {
      return _functionStandardLowerBound(type1, type2);
    }

    // Otherwise, the lower bounds  of two types is one of them it if it is a
    // subtype of the other.
    if (isSubtypeOf(type1, type2)) {
      return type1;
    }

    if (isSubtypeOf(type2, type1)) {
      return type2;
    }

    // No subtype relation, so the lower bound is bottom.
    return const BottomType();
  }

  /// Computes the standard upper bound of two types.
  ///
  /// Standard upper bound is an upper bound function that imposes an ordering
  /// on the top types 'void', 'dynamic', and `object`.  This function
  /// additionally handles the unknown type that appears during type inference.
  DartType getStandardUpperBound(DartType type1, DartType type2) {
    // For all types T, SUB(T,T) = T.  Note that we don't test for equality
    // because we don't want to make the algorithm quadratic.  This is ok
    // because the check is not needed for correctness; it's just a speed
    // optimization.
    if (identical(type1, type2)) {
      return type1;
    }

    // For any type T, SUB(?, T) = SUB(T, ?) = T.
    if (type1 is UnknownType) {
      return type2;
    }
    if (type2 is UnknownType) {
      return type1;
    }

    // SUB(void, T) = SUB(T, void) = void.
    if (type1 is VoidType) {
      return type1;
    }
    if (type2 is VoidType) {
      return type2;
    }

    // SUB(dynamic, T) = SUB(T, dynamic) = dynamic if T is not void.
    if (type1 is DynamicType) {
      return type1;
    }
    if (type2 is DynamicType) {
      return type2;
    }

    // SUB(Obect, T) = SUB(T, Object) = Object if T is not void or dynamic.
    if (type1 == objectType) {
      return type1;
    }
    if (type2 == objectType) {
      return type2;
    }

    // SUB(bottom, T) = SUB(T, bottom) = T.
    if (type1 is BottomType) return type2;
    if (type2 is BottomType) return type1;
    if (type1 == nullType) return type2;
    if (type2 == nullType) return type1;

    if (type1 is TypeParameterType || type2 is TypeParameterType) {
      return _typeParameterStandardUpperBound(type1, type2);
    }

    // The standard upper bound of a function type and an interface type T is
    // the standard upper bound of Function and T.
    if (type1 is FunctionType && type2 is InterfaceType) {
      type1 = rawFunctionType;
    }
    if (type2 is FunctionType && type1 is InterfaceType) {
      type2 = rawFunctionType;
    }

    // At this point type1 and type2 should both either be interface types or
    // function types.
    if (type1 is InterfaceType && type2 is InterfaceType) {
      return _interfaceStandardUpperBound(type1, type2);
    }

    if (type1 is FunctionType && type2 is FunctionType) {
      return _functionStandardUpperBound(type1, type2);
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
      List<DartType> inferredTypes,
      {bool isConst: false}) {
    if (typeParametersToInfer.isEmpty) {
      return;
    }

    // Create a TypeConstraintGatherer that will allow certain type parameters
    // to be inferred. It will optimistically assume these type parameters can
    // be subtypes (or supertypes) as necessary, and track the constraints that
    // are implied by this.
    var gatherer = new TypeConstraintGatherer(this, typeParametersToInfer);

    if (!isEmptyContext(returnContextType)) {
      if (isConst) {
        returnContextType = new TypeVariableEliminator(coreTypes)
            .substituteType(returnContextType);
      }
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

  bool hasOmittedBound(TypeParameter parameter) {
    // If the bound was omitted by the programmer, the Kernel representation for
    // the parameter will look similar to the following:
    //
    //     T extends Object = dynamic
    //
    // Note that it's not possible to receive [Object] as [TypeParameter.bound]
    // and `dynamic` as [TypeParameter.defaultType] from the front end in any
    // other way.
    DartType bound = parameter.bound;
    return bound is InterfaceType &&
        identical(bound.classNode, coreTypes.objectClass) &&
        parameter.defaultType is DynamicType;
  }

  /// Use the given [constraints] to substitute for type variables.
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
      if (!hasOmittedBound(typeParam)) {
        extendsConstraint =
            Substitution.fromPairs(typeParametersToInfer, inferredTypes)
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
      var typeParamBound =
          Substitution.fromPairs(typeParametersToInfer, inferredTypes)
              .substituteType(typeParam.bound);

      var inferred = inferredTypes[i];
      bool success = typeSatisfiesConstraint(inferred, constraint);
      if (success && !hasOmittedBound(typeParam)) {
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

  @override
  bool isSubtypeOf(DartType subtype, DartType supertype) {
    if (subtype is UnknownType) return true;
    if (subtype == Null && supertype is UnknownType) return true;
    return super.isSubtypeOf(subtype, supertype);
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

  /// Compute the standard lower bound of function types [f] and [g].
  ///
  /// The spec rules for SLB on function types, informally, are pretty simple:
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
  /// - For any parameter that exists in both functions, use the SUB of them as
  ///   the resulting parameter type.
  ///
  /// - Use the SLB of their return types.
  DartType _functionStandardLowerBound(FunctionType f, FunctionType g) {
    // TODO(rnystrom,paulberry): Right now, this assumes f and g do not have any
    // type parameters. Revisit that in the presence of generic methods.

    // Calculate the SUB of each corresponding pair of parameters.
    int totalPositional =
        math.max(f.positionalParameters.length, g.positionalParameters.length);
    var positionalParameters = new List<DartType>(totalPositional);
    for (int i = 0; i < totalPositional; i++) {
      if (i < f.positionalParameters.length) {
        var fType = f.positionalParameters[i];
        if (i < g.positionalParameters.length) {
          var gType = g.positionalParameters[i];
          positionalParameters[i] = getStandardUpperBound(fType, gType);
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
                  getStandardUpperBound(f.namedParameters[i++].type,
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

    // Calculate the SLB of the return type.
    DartType returnType = getStandardLowerBound(f.returnType, g.returnType);
    return new FunctionType(positionalParameters, returnType,
        namedParameters: namedParameters,
        requiredParameterCount: requiredParameterCount);
  }

  /// Compute the standard upper bound of function types [f] and [g].
  ///
  /// The rules for SUB on function types, informally, are pretty simple:
  ///
  /// - If the functions don't have the same number of required parameters,
  ///   always return `Function`.
  ///
  /// - Discard any optional named or positional parameters the two types do not
  ///   have in common.
  ///
  /// - Compute the SLB of each corresponding pair of parameter types, and the
  ///   SUB of the return types.  Return a function type with those types.
  DartType _functionStandardUpperBound(FunctionType f, FunctionType g) {
    // TODO(rnystrom): Right now, this assumes f and g do not have any type
    // parameters. Revisit that in the presence of generic methods.

    // If F and G differ in their number of required parameters, then the
    // standard upper bound of F and G is Function.
    // TODO(paulberry): We could do better here, e.g.:
    //   SUB(([int]) -> void, (int) -> void) = (int) -> void
    if (f.requiredParameterCount != g.requiredParameterCount) {
      return coreTypes.functionClass.rawType;
    }
    int requiredParameterCount = f.requiredParameterCount;

    // Calculate the SLB of each corresponding pair of parameters.
    // Ignore any extra optional positional parameters if one has more than the
    // other.
    int totalPositional =
        math.min(f.positionalParameters.length, g.positionalParameters.length);
    var positionalParameters = new List<DartType>(totalPositional);
    for (int i = 0; i < totalPositional; i++) {
      positionalParameters[i] = getStandardLowerBound(
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
                  getStandardLowerBound(f.namedParameters[i++].type,
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

    // Calculate the SUB of the return type.
    DartType returnType = getStandardUpperBound(f.returnType, g.returnType);
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

  DartType _interfaceStandardUpperBound(
      InterfaceType type1, InterfaceType type2) {
    // This currently does not implement a very complete standard upper bound
    // algorithm, but handles a couple of the very common cases that are
    // causing pain in real code.  The current algorithm is:
    // 1. If either of the types is a supertype of the other, return it.
    //    This is in fact the best result in this case.
    // 2. If the two types have the same class element, then take the
    //    pointwise standard upper bound of the type arguments.  This is again
    //    the best result, except that the recursive calls may not return
    //    the true standard upper bounds.  The result is guaranteed to be a
    //    well-formed type under the assumption that the input types were
    //    well-formed (and assuming that the recursive calls return
    //    well-formed types).
    // 3. Otherwise return the spec-defined standard upper bound.  This will
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
        tArgs[i] = getStandardUpperBound(tArgs1[i], tArgs2[i]);
      }
      return new InterfaceType(type1.classNode, tArgs);
    }
    return hierarchy.getLegacyLeastUpperBound(type1, type2);
  }

  DartType _typeParameterStandardUpperBound(DartType type1, DartType type2) {
    // This currently just implements a simple standard upper bound to
    // handle some common cases.  It also avoids some termination issues
    // with the naive spec algorithm.  The standard upper bound of two types
    // (at least one of which is a type parameter) is computed here as:
    // 1. If either type is a supertype of the other, return it.
    // 2. If the first type is a type parameter, replace it with its bound,
    //    with recursive occurrences of itself replaced with Object.
    //    The second part of this should ensure termination.  Informally,
    //    each type variable instantiation in one of the arguments to the
    //    standard upper bound algorithm now strictly reduces the number
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
      return getStandardUpperBound(
          Substitution.fromMap({type1.parameter: objectType})
              .substituteType(type1.parameter.bound),
          type2);
    } else if (type2 is TypeParameterType) {
      return getStandardUpperBound(
          type1,
          Substitution.fromMap({type2.parameter: objectType})
              .substituteType(type2.parameter.bound));
    } else {
      // We should only be called when at least one of the types is a
      // TypeParameterType
      assert(false);
      return const DynamicType();
    }
  }
}

class TypeVariableEliminator extends Substitution {
  final CoreTypes _coreTypes;

  TypeVariableEliminator(this._coreTypes);

  @override
  DartType getSubstitute(TypeParameter parameter, bool upperBound) {
    return upperBound
        ? _coreTypes.nullClass.rawType
        : _coreTypes.objectClass.rawType;
  }
}
