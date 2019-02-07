// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart'
    show
        Class,
        DartType,
        DynamicType,
        FunctionType,
        InterfaceType,
        NamedType,
        Procedure,
        TypeParameter;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/type_algebra.dart' show Substitution;

import 'package:kernel/src/hierarchy_based_type_environment.dart'
    show HierarchyBasedTypeEnvironment;

import 'standard_bounds.dart' show StandardBounds;

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

class TypeSchemaEnvironment extends HierarchyBasedTypeEnvironment
    with StandardBounds {
  TypeSchemaEnvironment(CoreTypes coreTypes, ClassHierarchy hierarchy)
      : super(coreTypes, hierarchy);

  Class get functionClass => coreTypes.functionClass;

  InterfaceType getLegacyLeastUpperBound(
      InterfaceType type1, InterfaceType type2) {
    return hierarchy.getLegacyLeastUpperBound(type1, type2);
  }

  /// Modify the given [constraint]'s lower bound to include [lower].
  void addLowerBound(TypeConstraint constraint, DartType lower) {
    constraint.lower = getStandardUpperBound(constraint.lower, lower);
  }

  /// Modify the given [constraint]'s upper bound to include [upper].
  void addUpperBound(TypeConstraint constraint, DartType upper) {
    constraint.upper = getStandardLowerBound(constraint.upper, upper);
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
