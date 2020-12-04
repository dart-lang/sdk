// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart' hide MapEntry;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/type_algebra.dart' show Substitution;

import 'package:kernel/type_environment.dart';

import 'package:kernel/src/hierarchy_based_type_environment.dart'
    show HierarchyBasedTypeEnvironment;

import 'standard_bounds.dart' show TypeSchemaStandardBounds;

import 'type_constraint_gatherer.dart' show TypeConstraintGatherer;

import 'type_demotion.dart';

import 'type_schema.dart' show UnknownType, typeSchemaToString, isKnown;

import 'type_schema_elimination.dart' show greatestClosure, leastClosure;

// TODO(paulberry): try to push this functionality into kernel.
FunctionType substituteTypeParams(
    FunctionType type,
    Map<TypeParameter, DartType> substitutionMap,
    List<TypeParameter> newTypeParameters) {
  Substitution substitution = Substitution.fromMap(substitutionMap);
  return new FunctionType(
      type.positionalParameters.map(substitution.substituteType).toList(),
      substitution.substituteType(type.returnType),
      type.nullability,
      namedParameters: type.namedParameters
          .map((named) => new NamedType(
              named.name, substitution.substituteType(named.type),
              isRequired: named.isRequired))
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
    with TypeSchemaStandardBounds {
  final ClassHierarchy hierarchy;

  TypeSchemaEnvironment(CoreTypes coreTypes, this.hierarchy)
      : super(coreTypes, hierarchy);

  InterfaceType get objectNonNullableRawType {
    return coreTypes.objectNonNullableRawType;
  }

  InterfaceType functionRawType(Nullability nullability) {
    return coreTypes.functionRawType(nullability);
  }

  InterfaceType objectRawType(Nullability nullability) {
    return coreTypes.objectRawType(nullability);
  }

  /// Modify the given [constraint]'s lower bound to include [lower].
  void addLowerBound(
      TypeConstraint constraint, DartType lower, Library clientLibrary) {
    constraint.lower =
        getStandardUpperBound(constraint.lower, lower, clientLibrary);
  }

  /// Modify the given [constraint]'s upper bound to include [upper].
  void addUpperBound(
      TypeConstraint constraint, DartType upper, Library clientLibrary) {
    constraint.upper =
        getStandardLowerBound(constraint.upper, upper, clientLibrary);
  }

  @override
  DartType getTypeOfSpecialCasedBinaryOperator(DartType type1, DartType type2,
      {bool isNonNullableByDefault: false}) {
    if (isNonNullableByDefault) {
      return super.getTypeOfSpecialCasedBinaryOperator(type1, type2,
          isNonNullableByDefault: isNonNullableByDefault);
    } else {
      // TODO(paulberry): this matches what is defined in the spec.  It would be
      // nice if we could change kernel to match the spec and not have to
      // override.
      if (type1 is InterfaceType && type1.classNode == coreTypes.intClass) {
        if (type2 is InterfaceType && type2.classNode == coreTypes.intClass) {
          return type2.withDeclaredNullability(type1.nullability);
        }
        if (type2 is InterfaceType &&
            type2.classNode == coreTypes.doubleClass) {
          return type2.withDeclaredNullability(type1.nullability);
        }
      }
      return coreTypes.numRawType(type1.nullability);
    }
  }

  DartType getContextTypeOfSpecialCasedBinaryOperator(
      DartType contextType, DartType type1, DartType type2,
      {bool isNonNullableByDefault: false}) {
    if (isNonNullableByDefault) {
      if (contextType is! NeverType &&
          type1 is! NeverType &&
          isSubtypeOf(contextType, coreTypes.numNonNullableRawType,
              SubtypeCheckMode.withNullabilities) &&
          isSubtypeOf(type1, coreTypes.numNonNullableRawType,
              SubtypeCheckMode.withNullabilities)) {
        // If e is an expression of the form e1 + e2, e1 - e2, e1 * e2, e1 % e2
        // or e1.remainder(e2), where C is the context type of e and T is the
        // static type of e1, and where T is a non-Never subtype of num, then:
        if (isSubtypeOf(coreTypes.intNonNullableRawType, contextType,
                SubtypeCheckMode.withNullabilities) &&
            !isSubtypeOf(coreTypes.numNonNullableRawType, contextType,
                SubtypeCheckMode.withNullabilities) &&
            isSubtypeOf(type1, coreTypes.intNonNullableRawType,
                SubtypeCheckMode.withNullabilities)) {
          // If int <: C, not num <: C, and T <: int, then the context type of
          // e2 is int.
          return coreTypes.intNonNullableRawType;
        } else if (isSubtypeOf(coreTypes.doubleNonNullableRawType, contextType,
                SubtypeCheckMode.withNullabilities) &&
            !isSubtypeOf(coreTypes.numNonNullableRawType, contextType,
                SubtypeCheckMode.withNullabilities) &&
            !isSubtypeOf(type1, coreTypes.doubleNonNullableRawType,
                SubtypeCheckMode.withNullabilities)) {
          // If double <: C, not num <: C, and not T <: double, then the context
          // type of e2 is double.
          return coreTypes.doubleNonNullableRawType;
        } else {
          // Otherwise, the context type of e2 is num.
          return coreTypes.numNonNullableRawType;
        }
      }
    }
    return type2;
  }

  DartType getContextTypeOfSpecialCasedTernaryOperator(
      DartType contextType, DartType receiverType, DartType operandType,
      {bool isNonNullableByDefault: false}) {
    if (isNonNullableByDefault) {
      if (receiverType is! NeverType &&
          isSubtypeOf(receiverType, coreTypes.numNonNullableRawType,
              SubtypeCheckMode.withNullabilities)) {
        // If e is an expression of the form e1.clamp(e2, e3) where C is the
        // context type of e and T is the static type of e1 where T is a
        // non-Never subtype of num, then:
        if (isSubtypeOf(coreTypes.intNonNullableRawType, contextType,
                SubtypeCheckMode.withNullabilities) &&
            !isSubtypeOf(coreTypes.numNonNullableRawType, contextType,
                SubtypeCheckMode.withNullabilities) &&
            isSubtypeOf(receiverType, coreTypes.intNonNullableRawType,
                SubtypeCheckMode.withNullabilities)) {
          // If int <: C, not num <: C, and T <: int, then the context type of
          // e2 and e3 is int.
          return coreTypes.intNonNullableRawType;
        } else if (isSubtypeOf(coreTypes.doubleNonNullableRawType, contextType,
                SubtypeCheckMode.withNullabilities) &&
            !isSubtypeOf(coreTypes.numNonNullableRawType, contextType,
                SubtypeCheckMode.withNullabilities) &&
            isSubtypeOf(receiverType, coreTypes.doubleNonNullableRawType,
                SubtypeCheckMode.withNullabilities)) {
          // If double <: C, not num <: C, and T <: double, then the context
          // type of e2 and e3 is double.
          return coreTypes.doubleNonNullableRawType;
        } else {
          // Otherwise the context type of e2 an e3 is num
          return coreTypes.numNonNullableRawType;
        }
      }
    }
    return operandType;
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
      Library clientLibrary,
      {bool isConst: false}) {
    assert((formalTypes?.length ?? 0) == (actualTypes?.length ?? 0));
    if (typeParametersToInfer.isEmpty) {
      return;
    }

    // Create a TypeConstraintGatherer that will allow certain type parameters
    // to be inferred. It will optimistically assume these type parameters can
    // be subtypes (or supertypes) as necessary, and track the constraints that
    // are implied by this.
    TypeConstraintGatherer gatherer =
        new TypeConstraintGatherer(this, typeParametersToInfer, clientLibrary);

    if (!isEmptyContext(returnContextType)) {
      if (isConst) {
        returnContextType = new TypeVariableEliminator(
                clientLibrary.isNonNullableByDefault
                    ? const NeverType(Nullability.nonNullable)
                    : const NullType(),
                clientLibrary.isNonNullableByDefault
                    ? objectNullableRawType
                    : objectLegacyRawType)
            .substituteType(returnContextType);
      }
      gatherer.tryConstrainUpper(declaredReturnType, returnContextType);
    }

    if (formalTypes != null) {
      for (int i = 0; i < formalTypes.length; i++) {
        // Try to pass each argument to each parameter, recording any type
        // parameter bounds that were implied by this assignment.
        gatherer.tryConstrainLower(formalTypes[i], actualTypes[i]);
      }
    }

    inferTypeFromConstraints(gatherer.computeConstraints(clientLibrary),
        typeParametersToInfer, inferredTypes, clientLibrary,
        downwardsInferPhase: formalTypes == null);

    for (int i = 0; i < inferredTypes.length; i++) {
      inferredTypes[i] = demoteTypeInLibrary(inferredTypes[i], clientLibrary);
    }
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
  void inferTypeFromConstraints(
      Map<TypeParameter, TypeConstraint> constraints,
      List<TypeParameter> typeParametersToInfer,
      List<DartType> inferredTypes,
      Library clientLibrary,
      {bool downwardsInferPhase: false}) {
    List<DartType> typesFromDownwardsInference =
        downwardsInferPhase ? null : inferredTypes.toList(growable: false);

    for (int i = 0; i < typeParametersToInfer.length; i++) {
      TypeParameter typeParam = typeParametersToInfer[i];

      DartType typeParamBound = typeParam.bound;
      DartType extendsConstraint;
      if (!hasOmittedBound(typeParam)) {
        extendsConstraint =
            Substitution.fromPairs(typeParametersToInfer, inferredTypes)
                .substituteType(typeParamBound);
      }

      TypeConstraint constraint = constraints[typeParam];
      if (downwardsInferPhase) {
        inferredTypes[i] = _inferTypeParameterFromContext(
            constraint, extendsConstraint, clientLibrary);
      } else {
        inferredTypes[i] = _inferTypeParameterFromAll(
            typesFromDownwardsInference[i],
            constraint,
            extendsConstraint,
            clientLibrary,
            isContravariant: typeParam.variance == Variance.contravariant,
            preferUpwardsInference: !typeParam.isLegacyCovariant);
      }
    }
  }

  @override
  IsSubtypeOf performNullabilityAwareSubtypeCheck(
      DartType subtype, DartType supertype) {
    if (subtype is UnknownType) return const IsSubtypeOf.always();
    DartType unwrappedSupertype = supertype;
    while (unwrappedSupertype is FutureOrType) {
      unwrappedSupertype = (unwrappedSupertype as FutureOrType).typeArgument;
    }
    if (unwrappedSupertype is UnknownType) {
      return const IsSubtypeOf.always();
    }
    return super.performNullabilityAwareSubtypeCheck(subtype, supertype);
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
  bool isSpecialCasesBinaryForReceiverType(
      Procedure member, DartType receiverType,
      {bool isNonNullableByDefault}) {
    assert(isNonNullableByDefault != null);
    if (!isNonNullableByDefault) {
      // TODO(paulberry): this matches what is defined in the spec.  It would be
      // nice if we could change kernel to match the spec and not have to
      // override.
      if (member.name.text == 'remainder') return false;
      if (!(receiverType is InterfaceType &&
          identical(receiverType.classNode, coreTypes.intClass))) {
        return false;
      }
    }
    return isSpecialCasedBinaryOperator(member,
        isNonNullableByDefault: isNonNullableByDefault);
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
  ///
  /// If [isContravariant] is `true`, then we are solving for a contravariant
  /// type parameter which means we choose the upper bound rather than the
  /// lower bound for normally covariant type parameters.
  DartType solveTypeConstraint(
      TypeConstraint constraint, DartType topType, DartType bottomType,
      {bool grounded: false, bool isContravariant: false}) {
    assert(bottomType == const NeverType(Nullability.nonNullable) ||
        bottomType == const NullType());
    if (!isContravariant) {
      // Prefer the known bound, if any.
      if (isKnown(constraint.lower)) return constraint.lower;
      if (isKnown(constraint.upper)) return constraint.upper;

      // Otherwise take whatever bound has partial information,
      // e.g. `Iterable<?>`
      if (constraint.lower is! UnknownType) {
        return grounded
            ? leastClosure(constraint.lower, topType, bottomType)
            : constraint.lower;
      } else if (constraint.upper is! UnknownType) {
        return grounded
            ? greatestClosure(constraint.upper, topType, bottomType)
            : constraint.upper;
      } else {
        return grounded ? const DynamicType() : const UnknownType();
      }
    } else {
      // Prefer the known bound, if any.
      if (isKnown(constraint.upper)) return constraint.upper;
      if (isKnown(constraint.lower)) return constraint.lower;

      // Otherwise take whatever bound has partial information,
      // e.g. `Iterable<?>`
      if (constraint.upper is! UnknownType) {
        return grounded
            ? greatestClosure(constraint.upper, topType, bottomType)
            : constraint.upper;
      } else if (constraint.lower is! UnknownType) {
        return grounded
            ? leastClosure(constraint.lower, topType, bottomType)
            : constraint.lower;
      } else {
        return grounded ? bottomType : const UnknownType();
      }
    }
  }

  /// Determine if the given [type] satisfies the given type [constraint].
  bool typeSatisfiesConstraint(DartType type, TypeConstraint constraint) {
    return isSubtypeOf(
            constraint.lower, type, SubtypeCheckMode.withNullabilities) &&
        isSubtypeOf(type, constraint.upper, SubtypeCheckMode.withNullabilities);
  }

  DartType _inferTypeParameterFromAll(
      DartType typeFromContextInference,
      TypeConstraint constraint,
      DartType extendsConstraint,
      Library clientLibrary,
      {bool isContravariant: false,
      bool preferUpwardsInference: false}) {
    // See if we already fixed this type from downwards inference.
    // If so, then we aren't allowed to change it based on argument types unless
    // [preferUpwardsInference] is true.
    if (!preferUpwardsInference && isKnown(typeFromContextInference)) {
      return typeFromContextInference;
    }

    if (extendsConstraint != null) {
      constraint = constraint.clone();
      addUpperBound(constraint, extendsConstraint, clientLibrary);
    }

    return solveTypeConstraint(
        constraint,
        clientLibrary.isNonNullableByDefault
            ? coreTypes.objectNullableRawType
            : const DynamicType(),
        clientLibrary.isNonNullableByDefault
            ? const NeverType(Nullability.nonNullable)
            : const NullType(),
        grounded: true,
        isContravariant: isContravariant);
  }

  DartType _inferTypeParameterFromContext(TypeConstraint constraint,
      DartType extendsConstraint, Library clientLibrary) {
    DartType t = solveTypeConstraint(
        constraint,
        clientLibrary.isNonNullableByDefault
            ? coreTypes.objectNullableRawType
            : const DynamicType(),
        clientLibrary.isNonNullableByDefault
            ? const NeverType(Nullability.nonNullable)
            : const NullType());
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
      addUpperBound(constraint, extendsConstraint, clientLibrary);
      return solveTypeConstraint(
          constraint,
          clientLibrary.isNonNullableByDefault
              ? coreTypes.objectNullableRawType
              : const DynamicType(),
          clientLibrary.isNonNullableByDefault
              ? const NeverType(Nullability.nonNullable)
              : const NullType());
    }
    return t;
  }
}

class TypeVariableEliminator extends Substitution {
  final DartType bottomType;
  final DartType topType;

  TypeVariableEliminator(this.bottomType, this.topType);

  @override
  DartType getSubstitute(TypeParameter parameter, bool upperBound) {
    return upperBound ? bottomType : topType;
  }
}
