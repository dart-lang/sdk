// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart';

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/type_algebra.dart'
    show
        FreshTypeParameters,
        NullabilityAwareFreeTypeVariableEliminator,
        Substitution,
        getFreshTypeParameters,
        substitute;

import 'package:kernel/type_environment.dart';

import 'package:kernel/src/bounds_checks.dart' show calculateBounds;

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
      requiredParameterCount: type.requiredParameterCount);
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

  @override
  String toString() =>
      '${typeSchemaToString(lower)} <: <type> <: ${typeSchemaToString(upper)}';
}

class TypeSchemaEnvironment extends HierarchyBasedTypeEnvironment
    with TypeSchemaStandardBounds {
  @override
  final ClassHierarchy hierarchy;

  TypeSchemaEnvironment(CoreTypes coreTypes, this.hierarchy)
      : super(coreTypes, hierarchy);

  InterfaceType functionRawType(Nullability nullability) {
    return coreTypes.functionRawType(nullability);
  }

  InterfaceType objectRawType(Nullability nullability) {
    return coreTypes.objectRawType(nullability);
  }

  /// Modify the given [constraint]'s lower bound to include [lower].
  void addLowerBound(TypeConstraint constraint, DartType lower,
      {required bool isNonNullableByDefault}) {
    constraint.lower = getStandardUpperBound(constraint.lower, lower,
        isNonNullableByDefault: isNonNullableByDefault);
  }

  /// Modify the given [constraint]'s upper bound to include [upper].
  void addUpperBound(TypeConstraint constraint, DartType upper,
      {required bool isNonNullableByDefault}) {
    constraint.upper = getStandardLowerBound(constraint.upper, upper,
        isNonNullableByDefault: isNonNullableByDefault);
  }

  /// Performs partial (either downwards or horizontal) inference, producing a
  /// set of inferred types that may contain references to the "unknown type".
  List<DartType> choosePreliminaryTypes(
          TypeConstraintGatherer gatherer,
          List<TypeParameter> typeParametersToInfer,
          List<DartType>? previouslyInferredTypes,
          {required bool isNonNullableByDefault}) =>
      _chooseTypes(gatherer, typeParametersToInfer, previouslyInferredTypes,
          isNonNullableByDefault: isNonNullableByDefault, preliminary: true);

  @override
  DartType getTypeOfSpecialCasedBinaryOperator(DartType type1, DartType type2,
      {bool isNonNullableByDefault = false}) {
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
      {bool isNonNullableByDefault = false}) {
    if (isNonNullableByDefault) {
      if (contextType is! NeverType &&
          type1 is! NeverType &&
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
      {bool isNonNullableByDefault = false}) {
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
        identical(bound.classReference, coreTypes.objectClass.reference) &&
        parameter.defaultType is DynamicType;
  }

  /// Use the given [constraints] to substitute for type variables.
  ///
  /// [typeParametersToInfer] is the set of type parameters that should be
  /// substituted for.  [previouslyInferredTypes], if present, should be the set
  /// of types inferred by the last call to this method; it should be a list of
  /// the same length.
  ///
  /// If [preliminary] is `true`, then we not in the final pass of inference.
  /// This means we are allowed to return `?` to precisely represent an unknown
  /// type.
  ///
  /// If [preliminary] is `false`, then we are in the final pass of inference,
  /// and must not conclude `?` for any type formal.
  List<DartType> inferTypeFromConstraints(
      Map<TypeParameter, TypeConstraint> constraints,
      List<TypeParameter> typeParametersToInfer,
      List<DartType>? previouslyInferredTypes,
      {required bool isNonNullableByDefault,
      bool preliminary = false}) {
    List<DartType> inferredTypes =
        previouslyInferredTypes?.toList(growable: false) ??
            new List.filled(typeParametersToInfer.length, const UnknownType());

    for (int i = 0; i < typeParametersToInfer.length; i++) {
      TypeParameter typeParam = typeParametersToInfer[i];

      DartType typeParamBound = typeParam.bound;
      DartType? extendsConstraint;
      if (!hasOmittedBound(typeParam)) {
        extendsConstraint =
            Substitution.fromPairs(typeParametersToInfer, inferredTypes)
                .substituteType(typeParamBound);
      }

      TypeConstraint constraint = constraints[typeParam]!;
      if (preliminary) {
        inferredTypes[i] = _inferTypeParameterFromContext(
            previouslyInferredTypes?[i], constraint, extendsConstraint,
            isNonNullableByDefault: isNonNullableByDefault,
            isLegacyCovariant: typeParam.isLegacyCovariant);
      } else {
        inferredTypes[i] = _inferTypeParameterFromAll(
            previouslyInferredTypes?[i], constraint, extendsConstraint,
            isNonNullableByDefault: isNonNullableByDefault,
            isContravariant: typeParam.variance == Variance.contravariant,
            isLegacyCovariant: typeParam.isLegacyCovariant);
      }
    }

    if (!preliminary) {
      assert(typeParametersToInfer.length == inferredTypes.length);
      FreshTypeParameters freshTypeParameters =
          getFreshTypeParameters(typeParametersToInfer);
      List<TypeParameter> helperTypeParameters =
          freshTypeParameters.freshTypeParameters;

      Map<TypeParameter, DartType> inferredSubstitution =
          <TypeParameter, DartType>{};
      for (int i = 0; i < helperTypeParameters.length; ++i) {
        if (inferredTypes[i] is UnknownType) {
          inferredSubstitution[helperTypeParameters[i]] =
              new TypeParameterType.forAlphaRenaming(
                  helperTypeParameters[i], helperTypeParameters[i]);
        } else {
          assert(isKnown(inferredTypes[i]));
          inferredSubstitution[helperTypeParameters[i]] = inferredTypes[i];
        }
      }
      for (int i = 0; i < helperTypeParameters.length; ++i) {
        if (inferredTypes[i] is UnknownType) {
          helperTypeParameters[i].bound =
              substitute(helperTypeParameters[i].bound, inferredSubstitution);
        } else {
          helperTypeParameters[i].bound = inferredTypes[i];
        }
      }
      List<DartType> instantiatedTypes = calculateBounds(
          helperTypeParameters, coreTypes.objectClass,
          isNonNullableByDefault: isNonNullableByDefault);
      for (int i = 0; i < instantiatedTypes.length; ++i) {
        if (inferredTypes[i] is UnknownType) {
          inferredTypes[i] = instantiatedTypes[i];
        }
      }
    }

    return inferredTypes;
  }

  @override
  IsSubtypeOf performNullabilityAwareSubtypeCheck(
      DartType subtype, DartType supertype) {
    if (subtype is UnknownType) return const IsSubtypeOf.always();

    DartType unwrappedSupertype = supertype;
    while (unwrappedSupertype is FutureOrType) {
      unwrappedSupertype = unwrappedSupertype.typeArgument;
    }
    if (unwrappedSupertype is UnknownType) {
      return const IsSubtypeOf.always();
    }
    return super.performNullabilityAwareSubtypeCheck(subtype, supertype);
  }

  // TODO(johnniwinther): Should [context] be non-nullable?
  bool isEmptyContext(DartType? context) {
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
      {required bool isNonNullableByDefault}) {
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

  /// Prepares to infer type arguments for a generic type, function, method, or
  /// list/map literal, initializing a [TypeConstraintGatherer] using the
  /// downward context type.
  TypeConstraintGatherer setupGenericTypeInference(DartType? declaredReturnType,
      List<TypeParameter> typeParametersToInfer, DartType? returnContextType,
      {required bool isNonNullableByDefault, bool isConst = false}) {
    assert(typeParametersToInfer.isNotEmpty);

    // Create a TypeConstraintGatherer that will allow certain type parameters
    // to be inferred. It will optimistically assume these type parameters can
    // be subtypes (or supertypes) as necessary, and track the constraints that
    // are implied by this.
    TypeConstraintGatherer gatherer = new TypeConstraintGatherer(
        this, typeParametersToInfer,
        isNonNullableByDefault: isNonNullableByDefault);

    if (!isEmptyContext(returnContextType)) {
      if (isConst) {
        if (isNonNullableByDefault) {
          returnContextType = new NullabilityAwareFreeTypeVariableEliminator(
                  bottomType: const NeverType.nonNullable(),
                  topType: objectNullableRawType,
                  topFunctionType: functionRawType(Nullability.nonNullable))
              .eliminateToLeast(returnContextType!);
        } else {
          returnContextType =
              new TypeVariableEliminator(const NullType(), objectLegacyRawType)
                  .substituteType(returnContextType!);
        }
      }
      gatherer.tryConstrainUpper(declaredReturnType!, returnContextType!);
    }
    return gatherer;
  }

  /// Computes the constraint solution for a type variable based on a given set
  /// of constraints.
  ///
  /// If [grounded] is `true`, then the returned type is guaranteed to be a
  /// known type (i.e. it will not contain any instances of `?`) if it is
  /// constrained at all.  The returned type for unconstrained variables is
  /// [UnknownType].
  ///
  /// If [isContravariant] is `true`, then we are solving for a contravariant
  /// type parameter which means we choose the upper bound rather than the
  /// lower bound for normally covariant type parameters.
  DartType solveTypeConstraint(
      TypeConstraint constraint, DartType topType, DartType bottomType,
      {bool grounded = false, bool isContravariant = false}) {
    assert(bottomType == const NeverType.nonNullable() ||
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
        return const UnknownType();
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
        return const UnknownType();
      }
    }
  }

  /// Determine if the given [type] satisfies the given type [constraint].
  bool typeSatisfiesConstraint(DartType type, TypeConstraint constraint) {
    return isSubtypeOf(
            constraint.lower, type, SubtypeCheckMode.withNullabilities) &&
        isSubtypeOf(type, constraint.upper, SubtypeCheckMode.withNullabilities);
  }

  /// Performs upwards inference, producing a final set of inferred types that
  /// does not  contain references to the "unknown type".
  List<DartType> chooseFinalTypes(
          TypeConstraintGatherer gatherer,
          List<TypeParameter> typeParametersToInfer,
          List<DartType>? previouslyInferredTypes,
          {required bool isNonNullableByDefault}) =>
      _chooseTypes(gatherer, typeParametersToInfer, previouslyInferredTypes,
          isNonNullableByDefault: isNonNullableByDefault, preliminary: false);

  /// Computes (or recomputes) a set of [inferredTypes] based on the constraints
  /// that have been recorded so far.
  List<DartType> _chooseTypes(
      TypeConstraintGatherer gatherer,
      List<TypeParameter> typeParametersToInfer,
      List<DartType>? previouslyInferredTypes,
      {required bool isNonNullableByDefault,
      required bool preliminary}) {
    List<DartType> inferredTypes = inferTypeFromConstraints(
        gatherer.computeConstraints(
            isNonNullableByDefault: isNonNullableByDefault),
        typeParametersToInfer,
        previouslyInferredTypes,
        isNonNullableByDefault: isNonNullableByDefault,
        preliminary: preliminary);

    for (int i = 0; i < inferredTypes.length; i++) {
      inferredTypes[i] = demoteTypeInLibrary(inferredTypes[i],
          isNonNullableByDefault: isNonNullableByDefault);
    }
    return inferredTypes;
  }

  DartType _inferTypeParameterFromAll(DartType? typeFromPreviousInference,
      TypeConstraint constraint, DartType? extendsConstraint,
      {required bool isNonNullableByDefault,
      bool isContravariant = false,
      bool isLegacyCovariant = true}) {
    // See if we already fixed this type in a previous inference step.
    // If so, then we aren't allowed to change it unless [isLegacyCovariant] is
    // false.
    if (typeFromPreviousInference != null &&
        isLegacyCovariant &&
        isKnown(typeFromPreviousInference)) {
      return typeFromPreviousInference;
    }

    if (extendsConstraint != null) {
      constraint = constraint.clone();
      addUpperBound(constraint, extendsConstraint,
          isNonNullableByDefault: isNonNullableByDefault);
    }

    return solveTypeConstraint(
        constraint,
        isNonNullableByDefault
            ? coreTypes.objectNullableRawType
            : const DynamicType(),
        isNonNullableByDefault
            ? const NeverType.nonNullable()
            : const NullType(),
        grounded: true,
        isContravariant: isContravariant);
  }

  DartType _inferTypeParameterFromContext(DartType? typeFromPreviousInference,
      TypeConstraint constraint, DartType? extendsConstraint,
      {required bool isNonNullableByDefault, bool isLegacyCovariant = true}) {
    // See if we already fixed this type in a previous inference step.
    // If so, then we aren't allowed to change it unless [isLegacyCovariant] is
    // false.
    if (isLegacyCovariant &&
        typeFromPreviousInference != null &&
        isKnown(typeFromPreviousInference)) {
      return typeFromPreviousInference;
    }

    DartType t = solveTypeConstraint(
        constraint,
        isNonNullableByDefault
            ? coreTypes.objectNullableRawType
            : const DynamicType(),
        isNonNullableByDefault
            ? const NeverType.nonNullable()
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
      addUpperBound(constraint, extendsConstraint,
          isNonNullableByDefault: isNonNullableByDefault);
      return solveTypeConstraint(
          constraint,
          isNonNullableByDefault
              ? coreTypes.objectNullableRawType
              : const DynamicType(),
          isNonNullableByDefault
              ? const NeverType.nonNullable()
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
