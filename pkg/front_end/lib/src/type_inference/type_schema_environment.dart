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
import 'type_schema.dart' show UnknownType;

typedef GeneratedTypeConstraint
    = shared.GeneratedTypeConstraint<VariableDeclaration>;

typedef MergedTypeConstraint = shared.MergedTypeConstraint<VariableDeclaration,
    TypeDeclarationType, TypeDeclaration>;

typedef UnknownTypeConstraintOrigin = shared.UnknownTypeConstraintOrigin<
    VariableDeclaration, TypeDeclarationType, TypeDeclaration>;

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

  // Coverage-ignore(suite): Not run.
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
        isSubtypeOf(type1, coreTypes.numNonNullableRawType)) {
      // If e is an expression of the form e1 + e2, e1 - e2, e1 * e2, e1 % e2
      // or e1.remainder(e2), where C is the context type of e and T is the
      // static type of e1, and where T is a non-Never subtype of num, then:
      if (isSubtypeOf(coreTypes.intNonNullableRawType, contextType) &&
          !isSubtypeOf(coreTypes.numNonNullableRawType, contextType) &&
          isSubtypeOf(type1, coreTypes.intNonNullableRawType)) {
        // If int <: C, not num <: C, and T <: int, then the context type of
        // e2 is int.
        return coreTypes.intNonNullableRawType;
      } else if (isSubtypeOf(coreTypes.doubleNonNullableRawType, contextType) &&
          !isSubtypeOf(coreTypes.numNonNullableRawType, contextType) &&
          !isSubtypeOf(type1, coreTypes.doubleNonNullableRawType)) {
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
        isSubtypeOf(receiverType, coreTypes.numNonNullableRawType)) {
      // If e is an expression of the form e1.clamp(e2, e3) where C is the
      // context type of e and T is the static type of e1 where T is a
      // non-Never subtype of num, then:
      if (isSubtypeOf(coreTypes.intNonNullableRawType, contextType) &&
          !isSubtypeOf(coreTypes.numNonNullableRawType, contextType) &&
          isSubtypeOf(receiverType, coreTypes.intNonNullableRawType)) {
        // If int <: C, not num <: C, and T <: int, then the context type of
        // e2 and e3 is int.
        return coreTypes.intNonNullableRawType;
      } else if (isSubtypeOf(coreTypes.doubleNonNullableRawType, contextType) &&
          !isSubtypeOf(coreTypes.numNonNullableRawType, contextType) &&
          isSubtypeOf(receiverType, coreTypes.doubleNonNullableRawType)) {
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
      required InferenceDataForTesting? dataForTesting,
      required bool inferenceUsingBoundsIsEnabled}) {
    List<DartType> inferredTypes =
        previouslyInferredTypes?.toList(growable: false) ??
            new List.filled(typeParametersToInfer.length, const UnknownType());

    for (int i = 0; i < typeParametersToInfer.length; i++) {
      StructuralParameter typeParam = typeParametersToInfer[i];

      DartType typeParamBound = typeParam.bound;
      DartType? extendsConstraint;
      if (!operations.isBoundOmitted(typeParam)) {
        extendsConstraint = new FunctionTypeInstantiator.fromIterables(
                typeParametersToInfer, inferredTypes)
            .substitute(typeParamBound);
      }

      MergedTypeConstraint constraint = constraints[typeParam]!;
      if (preliminary) {
        inferredTypes[i] = operations.inferTypeParameterFromContext(
                previouslyInferredTypes?[i], constraint, extendsConstraint,
                isContravariant:
                    typeParam.variance == shared.Variance.contravariant,
                isLegacyCovariant: typeParam.isLegacyCovariant,
                constraints: constraints,
                typeParameterToInfer: typeParam,
                typeParametersToInfer: typeParametersToInfer,
                dataForTesting: dataForTesting,
                inferenceUsingBoundsIsEnabled: inferenceUsingBoundsIsEnabled)
            as DartType;
      } else {
        inferredTypes[i] = operations.inferTypeParameterFromAll(
                previouslyInferredTypes?[i], constraint, extendsConstraint,
                isContravariant:
                    typeParam.variance == shared.Variance.contravariant,
                isLegacyCovariant: typeParam.isLegacyCovariant,
                constraints: constraints,
                typeParameterToInfer: typeParam,
                typeParametersToInfer: typeParametersToInfer,
                dataForTesting: dataForTesting,
                inferenceUsingBoundsIsEnabled: inferenceUsingBoundsIsEnabled)
            as DartType;
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
              new TypeParameterType.withDefaultNullability(
                  helperTypeParameters[i]);
        } else {
          assert(operations
              .isKnownType(new SharedTypeSchemaView(inferredTypes[i])));
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
  IsSubtypeOf performSubtypeCheck(DartType subtype, DartType supertype) {
    if (subtype is UnknownType) return const IsSubtypeOf.success();

    DartType unwrappedSupertype = supertype;
    while (unwrappedSupertype is FutureOrType) {
      unwrappedSupertype = unwrappedSupertype.typeArgument;
    }
    if (unwrappedSupertype is UnknownType) {
      return const IsSubtypeOf.success();
    }
    return super.performSubtypeCheck(subtype, supertype);
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
        returnContextType =
            new FreeTypeParameterEliminator(coreTypes: coreTypes)
                .eliminateToLeast(returnContextType!);
      }
      gatherer.tryConstrainUpper(declaredReturnType!, returnContextType!,
          treeNodeForTesting: treeNodeForTesting);
    }
    return gatherer;
  }

  // Coverage-ignore(suite): Not run.
  /// Determine if the given [type] satisfies the given type [constraint].
  bool typeSatisfiesConstraint(DartType type, MergedTypeConstraint constraint) {
    return isSubtypeOf(constraint.lower.unwrapTypeSchemaView(), type) &&
        isSubtypeOf(type, constraint.upper.unwrapTypeSchemaView());
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
        dataForTesting: dataForTesting,
        inferenceUsingBoundsIsEnabled: inferenceUsingBoundsIsEnabled);

    for (int i = 0; i < inferredTypes.length; i++) {
      inferredTypes[i] = demoteTypeInLibrary(inferredTypes[i]);
    }
    return inferredTypes;
  }
}

class AllTypeParameterEliminator extends Substitution {
  final DartType bottomType;
  final DartType topType;

  AllTypeParameterEliminator(this.bottomType, this.topType);

  @override
  DartType getSubstitute(TypeParameter parameter, bool upperBound) {
    return upperBound ? bottomType : topType;
  }
}
