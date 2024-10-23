// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/type_inference/type_constraint.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/src/bounds_checks.dart' show calculateBounds;
import 'package:kernel/src/hierarchy_based_type_environment.dart'
    show HierarchyBasedTypeEnvironment;
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import 'standard_bounds.dart' show TypeSchemaStandardBounds;
import 'type_constraint_gatherer.dart' show TypeConstraintGatherer;
import 'type_demotion.dart';
import 'type_inference_engine.dart';
import 'type_schema.dart' show UnknownType, isKnown;
import 'type_schema_elimination.dart' show greatestClosure, leastClosure;

typedef GeneratedTypeConstraint = shared.GeneratedTypeConstraint<DartType,
    StructuralParameter, VariableDeclaration>;

typedef MergedTypeConstraint = shared.MergedTypeConstraint<
    DartType,
    StructuralParameter,
    VariableDeclaration,
    TypeDeclarationType,
    TypeDeclaration>;

typedef UnknownTypeConstraintOrigin = shared.UnknownTypeConstraintOrigin<
    DartType,
    VariableDeclaration,
    StructuralParameter,
    TypeDeclarationType,
    TypeDeclaration>;

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

class TypeSchemaEnvironment extends HierarchyBasedTypeEnvironment
    with TypeSchemaStandardBounds {
  @override
  final ClassHierarchy hierarchy;

  TypeSchemaEnvironment(CoreTypes coreTypes, this.hierarchy)
      : super(coreTypes, hierarchy);

  InterfaceType functionRawType(Nullability nullability) {
    return coreTypes.functionRawType(nullability);
  }

  /// Performs partial (either downwards or horizontal) inference, producing a
  /// set of inferred types that may contain references to the "unknown type".
  List<DartType> choosePreliminaryTypes(
          TypeConstraintGatherer gatherer,
          List<StructuralParameter> typeParametersToInfer,
          List<DartType>? previouslyInferredTypes,
          {required bool inferenceUsingBoundsIsEnabled,
          required InferenceDataForTesting? dataForTesting,
          required TreeNode? treeNodeForTesting}) =>
      _chooseTypes(gatherer, typeParametersToInfer, previouslyInferredTypes,
          preliminary: true,
          inferenceUsingBoundsIsEnabled: inferenceUsingBoundsIsEnabled,
          dataForTesting: dataForTesting,
          treeNodeForTesting: treeNodeForTesting);

  DartType getContextTypeOfSpecialCasedBinaryOperator(
      DartType contextType, DartType type1, DartType type2) {
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
    return type2;
  }

  DartType getContextTypeOfSpecialCasedTernaryOperator(
      DartType contextType, DartType receiverType, DartType operandType) {
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
    return operandType;
  }

  bool hasOmittedBound(StructuralParameter parameter) {
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

  /// Use the given [constraints] to substitute for type parameters.
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
      Map<StructuralParameter, MergedTypeConstraint> constraints,
      List<StructuralParameter> typeParametersToInfer,
      List<DartType>? previouslyInferredTypes,
      {bool preliminary = false,
      required OperationsCfe operations,
      required bool inferenceUsingBoundsIsEnabled}) {
    List<DartType> inferredTypes =
        previouslyInferredTypes?.toList(growable: false) ??
            new List.filled(typeParametersToInfer.length, const UnknownType());

    for (int i = 0; i < typeParametersToInfer.length; i++) {
      StructuralParameter typeParam = typeParametersToInfer[i];

      DartType typeParamBound = typeParam.bound;
      DartType? extendsConstraint;
      Map<StructuralParameter, MergedTypeConstraint>? constraintsFromBound;
      if (!hasOmittedBound(typeParam)) {
        extendsConstraint = new FunctionTypeInstantiator.fromIterables(
                typeParametersToInfer, inferredTypes)
            .substitute(typeParamBound);

        MergedTypeConstraint? mergedTypeConstraint = constraints[typeParam];
        if (inferenceUsingBoundsIsEnabled) {
          // The type parameter's bound may refer to itself (or other type
          // parameters), so we might have to create an additional constraint.
          // Consider this example from
          // https://github.com/dart-lang/language/issues/3009:
          //
          //     class A<X extends A<X>> {}
          //     class B extends A<B> {}
          //     class C extends B {}
          //     void f<X extends A<X>>(X x) {}
          //     void main() {
          //       f(C()); // should infer f<B>(C()).
          //     }
          //
          // In order for `f(C())` to be inferred as `f<B>(C())`, we need to
          // generate the constraint `X <: B`. To do this, we first take the
          // lower constraint we've accumulated so far (which, in this example,
          // is `C`, due to the presence of the actual argument `C()`), and use
          // subtype constraint generation to match it against the explicit
          // bound (which is `A<X>`; hence we perform `C <# A<X>`). If this
          // produces any constraints (i.e. `X <: B` in this example), then they
          // are added to the set of constraints just before choosing the final
          // type.

          if (mergedTypeConstraint != null &&
              mergedTypeConstraint.lower
                  is! SharedUnknownTypeSchemaView<DartType>) {
            TypeConstraintGatherer extendsConstraintGatherer =
                new TypeConstraintGatherer(this, typeParametersToInfer,
                    typeOperations: operations,
                    inferenceUsingBoundsIsEnabled:
                        inferenceUsingBoundsIsEnabled,
                    inferenceResultForTesting: null);
            extendsConstraintGatherer.tryConstrainLower(typeParamBound,
                mergedTypeConstraint.lower.unwrapTypeSchemaView(),
                treeNodeForTesting: null);
            constraintsFromBound =
                extendsConstraintGatherer.computeConstraints();
          }
        }
      }

      MergedTypeConstraint constraint = constraints[typeParam]!;
      if (preliminary) {
        inferredTypes[i] = _inferTypeParameterFromContext(
            previouslyInferredTypes?[i], constraint, extendsConstraint,
            isLegacyCovariant: typeParam.isLegacyCovariant,
            operations: operations,
            constraintsFromBound: constraintsFromBound,
            constraints: constraints,
            typeParameterToInfer: typeParam,
            typeParametersToInfer: typeParametersToInfer);
      } else {
        inferredTypes[i] = _inferTypeParameterFromAll(
            previouslyInferredTypes?[i], constraint, extendsConstraint,
            isContravariant:
                typeParam.variance == shared.Variance.contravariant,
            isLegacyCovariant: typeParam.isLegacyCovariant,
            operations: operations,
            constraintsFromBound: constraintsFromBound,
            constraints: constraints,
            typeParameterToInfer: typeParam,
            typeParametersToInfer: typeParametersToInfer);
      }
    }

    if (!preliminary) {
      assert(typeParametersToInfer.length == inferredTypes.length);
      FreshTypeParametersFromStructuralParameters freshTypeParameters =
          getFreshTypeParametersFromStructuralParameters(typeParametersToInfer);
      List<TypeParameter> helperTypeParameters =
          freshTypeParameters.freshTypeParameters;

      Map<TypeParameter, DartType> inferredSubstitution = {};
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
      List<DartType> instantiatedTypes =
          calculateBounds(helperTypeParameters, coreTypes.objectClass);
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

  @override
  // Coverage-ignore(suite): Not run.
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
  TypeConstraintGatherer setupGenericTypeInference(
      DartType? declaredReturnType,
      List<StructuralParameter> typeParametersToInfer,
      DartType? returnContextType,
      {bool isConst = false,
      required OperationsCfe typeOperations,
      required bool inferenceUsingBoundsIsEnabled,
      required TypeInferenceResultForTesting? inferenceResultForTesting,
      required TreeNode? treeNodeForTesting}) {
    assert(typeParametersToInfer.isNotEmpty);

    // Create a TypeConstraintGatherer that will allow certain type parameters
    // to be inferred. It will optimistically assume these type parameters can
    // be subtypes (or supertypes) as necessary, and track the constraints that
    // are implied by this.
    TypeConstraintGatherer gatherer = new TypeConstraintGatherer(
        this, typeParametersToInfer,
        typeOperations: typeOperations,
        inferenceUsingBoundsIsEnabled: inferenceUsingBoundsIsEnabled,
        inferenceResultForTesting: inferenceResultForTesting);

    if (!isEmptyContext(returnContextType)) {
      if (isConst) {
        returnContextType = new NullabilityAwareFreeTypeParameterEliminator(
                bottomType: const NeverType.nonNullable(),
                topType: objectNullableRawType,
                topFunctionType: functionRawType(Nullability.nonNullable))
            .eliminateToLeast(returnContextType!);
      }
      gatherer.tryConstrainUpper(declaredReturnType!, returnContextType!,
          treeNodeForTesting: treeNodeForTesting);
    }
    return gatherer;
  }

  /// Computes the constraint solution for a type parameter based on a given set
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
      MergedTypeConstraint constraint, DartType topType, DartType bottomType,
      {bool grounded = false, bool isContravariant = false}) {
    assert(bottomType == const NeverType.nonNullable() ||
        // Coverage-ignore(suite): Not run.
        bottomType == const NullType());
    if (!isContravariant) {
      // Prefer the known bound, if any.
      if (isKnown(constraint.lower.unwrapTypeSchemaView())) {
        return constraint.lower.unwrapTypeSchemaView();
      }
      if (isKnown(constraint.upper.unwrapTypeSchemaView())) {
        return constraint.upper.unwrapTypeSchemaView();
      }

      // Otherwise take whatever bound has partial information,
      // e.g. `Iterable<?>`
      if (constraint.lower is! SharedUnknownTypeSchemaView<DartType>) {
        return grounded
            ? leastClosure(
                constraint.lower.unwrapTypeSchemaView(), topType, bottomType)
            : constraint.lower.unwrapTypeSchemaView();
      } else if (constraint.upper is! UnknownType) {
        return grounded
            ? greatestClosure(
                constraint.upper.unwrapTypeSchemaView(), topType, bottomType)
            : constraint.upper.unwrapTypeSchemaView();
      } else {
        return const UnknownType();
      }
    } else {
      // Prefer the known bound, if any.
      if (isKnown(constraint.upper.unwrapTypeSchemaView())) {
        // Coverage-ignore-block(suite): Not run.
        return constraint.upper.unwrapTypeSchemaView();
      }
      if (isKnown(constraint.lower.unwrapTypeSchemaView())) {
        return constraint.lower.unwrapTypeSchemaView();
      }

      // Otherwise take whatever bound has partial information,
      // e.g. `Iterable<?>`
      if (constraint.upper is! UnknownType) {
        // Coverage-ignore-block(suite): Not run.
        return grounded
            ? greatestClosure(
                constraint.upper.unwrapTypeSchemaView(), topType, bottomType)
            : constraint.upper.unwrapTypeSchemaView();
      } else if (constraint.lower is! UnknownType) {
        return grounded
            ? leastClosure(
                constraint.lower.unwrapTypeSchemaView(), topType, bottomType)
            :
            // Coverage-ignore(suite): Not run.
            constraint.lower.unwrapTypeSchemaView();
      } else {
        return const UnknownType();
      }
    }
  }

  // Coverage-ignore(suite): Not run.
  /// Determine if the given [type] satisfies the given type [constraint].
  bool typeSatisfiesConstraint(DartType type, MergedTypeConstraint constraint) {
    return isSubtypeOf(constraint.lower.unwrapTypeSchemaView(), type,
            SubtypeCheckMode.withNullabilities) &&
        isSubtypeOf(type, constraint.upper.unwrapTypeSchemaView(),
            SubtypeCheckMode.withNullabilities);
  }

  /// Performs upwards inference, producing a final set of inferred types that
  /// does not  contain references to the "unknown type".
  List<DartType> chooseFinalTypes(
          TypeConstraintGatherer gatherer,
          List<StructuralParameter> typeParametersToInfer,
          List<DartType>? previouslyInferredTypes,
          {required bool inferenceUsingBoundsIsEnabled,
          required InferenceDataForTesting? dataForTesting,
          required TreeNode? treeNodeForTesting}) =>
      _chooseTypes(gatherer, typeParametersToInfer, previouslyInferredTypes,
          preliminary: false,
          inferenceUsingBoundsIsEnabled: inferenceUsingBoundsIsEnabled,
          dataForTesting: dataForTesting,
          treeNodeForTesting: treeNodeForTesting);

  /// Computes (or recomputes) a set of [inferredTypes] based on the constraints
  /// that have been recorded so far.
  List<DartType> _chooseTypes(
      TypeConstraintGatherer gatherer,
      List<StructuralParameter> typeParametersToInfer,
      List<DartType>? previouslyInferredTypes,
      {required bool preliminary,
      required bool inferenceUsingBoundsIsEnabled,
      required InferenceDataForTesting? dataForTesting,
      required TreeNode? treeNodeForTesting}) {
    List<DartType> inferredTypes = inferTypeFromConstraints(
        gatherer.computeConstraints(),
        typeParametersToInfer,
        previouslyInferredTypes,
        preliminary: preliminary,
        operations: gatherer.typeOperations,
        inferenceUsingBoundsIsEnabled: inferenceUsingBoundsIsEnabled);

    for (int i = 0; i < inferredTypes.length; i++) {
      inferredTypes[i] = demoteTypeInLibrary(inferredTypes[i]);
    }
    return inferredTypes;
  }

  DartType _inferTypeParameterFromAll(DartType? typeFromPreviousInference,
      MergedTypeConstraint constraint, DartType? extendsConstraint,
      {bool isContravariant = false,
      bool isLegacyCovariant = true,
      required OperationsCfe operations,
      required Map<StructuralParameter, MergedTypeConstraint>?
          constraintsFromBound,
      required Map<StructuralParameter, MergedTypeConstraint> constraints,
      required StructuralParameter typeParameterToInfer,
      required List<StructuralParameter> typeParametersToInfer}) {
    // See if we already fixed this type in a previous inference step.
    // If so, then we aren't allowed to change it unless [isLegacyCovariant] is
    // false.
    if (typeFromPreviousInference != null &&
        isLegacyCovariant &&
        isKnown(typeFromPreviousInference)) {
      return typeFromPreviousInference;
    }

    if (constraintsFromBound != null) {
      _mergeInConstraintsFromBound(
          constraints: constraints,
          constraintsFromBound: constraintsFromBound,
          typeParametersToInfer: typeParametersToInfer,
          operations: operations);
      constraint = constraints[typeParameterToInfer]!;
    }

    if (extendsConstraint != null) {
      constraint = constraint.clone();
      constraint.mergeInTypeSchemaUpper(
          new SharedTypeSchemaView(extendsConstraint), operations);
    }

    return solveTypeConstraint(constraint, coreTypes.objectNullableRawType,
        const NeverType.nonNullable(),
        grounded: true, isContravariant: isContravariant);
  }

  void _mergeInConstraintsFromBound(
      {required Map<StructuralParameter, MergedTypeConstraint>
          constraintsFromBound,
      required List<StructuralParameter> typeParametersToInfer,
      required Map<StructuralParameter, MergedTypeConstraint> constraints,
      required OperationsCfe operations}) {
    for (StructuralParameter typeParamToUpdate in typeParametersToInfer) {
      MergedTypeConstraint? constraintFromBoundForTypeParam =
          constraintsFromBound[typeParamToUpdate];
      if (constraintFromBoundForTypeParam != null) {
        constraints[typeParamToUpdate]?.mergeInTypeSchemaUpper(
            constraintFromBoundForTypeParam.upper, operations);
        constraints[typeParamToUpdate]?.mergeInTypeSchemaLower(
            constraintFromBoundForTypeParam.lower, operations);
      }
    }
  }

  DartType _inferTypeParameterFromContext(DartType? typeFromPreviousInference,
      MergedTypeConstraint constraint, DartType? extendsConstraint,
      {bool isLegacyCovariant = true,
      required OperationsCfe operations,
      required Map<StructuralParameter, MergedTypeConstraint>?
          constraintsFromBound,
      required Map<StructuralParameter, MergedTypeConstraint> constraints,
      required List<StructuralParameter> typeParametersToInfer,
      required StructuralParameter typeParameterToInfer}) {
    // See if we already fixed this type in a previous inference step.
    // If so, then we aren't allowed to change it unless [isLegacyCovariant] is
    // false.
    if (isLegacyCovariant &&
        typeFromPreviousInference != null &&
        isKnown(typeFromPreviousInference)) {
      return typeFromPreviousInference;
    }

    DartType t = solveTypeConstraint(constraint,
        coreTypes.objectNullableRawType, const NeverType.nonNullable());
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

    if (constraintsFromBound != null) {
      // Coverage-ignore-block(suite): Not run.
      _mergeInConstraintsFromBound(
          constraintsFromBound: constraintsFromBound,
          typeParametersToInfer: typeParametersToInfer,
          constraints: constraints,
          operations: operations);
      constraint = constraints[typeParameterToInfer]!;
    }

    if (extendsConstraint != null) {
      constraint = constraint.clone();
      constraint.mergeInTypeSchemaUpper(
          new SharedTypeSchemaView(extendsConstraint), operations);
      return solveTypeConstraint(constraint, coreTypes.objectNullableRawType,
          const NeverType.nonNullable());
    }

    return t;
  }
}

class TypeParameterEliminator extends Substitution {
  final DartType bottomType;
  final DartType topType;

  TypeParameterEliminator(this.bottomType, this.topType);

  @override
  DartType getSubstitute(TypeParameter parameter, bool upperBound) {
    return upperBound ? bottomType : topType;
  }
}
