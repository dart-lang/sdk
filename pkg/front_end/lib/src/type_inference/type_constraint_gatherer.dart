// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart'
    as shared
    show
        TypeConstraintGenerator,
        TypeConstraintGeneratorMixin,
        TypeConstraintGeneratorState;
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/type_algebra.dart';

import 'type_inference_engine.dart';
import 'type_schema.dart';
import 'type_schema_environment.dart';

/// Creates a collection of [TypeConstraint]s corresponding to type parameters,
/// based on an attempt to make one type schema a subtype of another.
class TypeConstraintGatherer extends shared.TypeConstraintGenerator<
        DartType,
        NamedType,
        VariableDeclaration,
        StructuralParameter,
        TypeDeclarationType,
        TypeDeclaration,
        TreeNode>
    with
        shared.TypeConstraintGeneratorMixin<
            DartType,
            NamedType,
            VariableDeclaration,
            StructuralParameter,
            TypeDeclarationType,
            TypeDeclaration,
            TreeNode> {
  final List<GeneratedTypeConstraint> _protoConstraints = [];

  @override
  final List<StructuralParameter> typeParametersToConstrain;

  final OperationsCfe typeOperations;

  final TypeSchemaEnvironment _environment;

  final TypeInferenceResultForTesting? _inferenceResultForTesting;

  TypeConstraintGatherer(
      this._environment, Iterable<StructuralParameter> typeParameters,
      {required OperationsCfe typeOperations,
      required TypeInferenceResultForTesting? inferenceResultForTesting,
      required super.inferenceUsingBoundsIsEnabled})
      : typeOperations = typeOperations,
        typeParametersToConstrain =
            new List<StructuralParameter>.of(typeParameters),
        _inferenceResultForTesting = inferenceResultForTesting;

  @override
  bool get enableDiscrepantObliviousnessOfNullabilitySuffixOfFutureOr => true;

  @override
  shared.TypeConstraintGeneratorState get currentState {
    return new shared.TypeConstraintGeneratorState(_protoConstraints.length);
  }

  @override
  void restoreState(shared.TypeConstraintGeneratorState state) {
    _protoConstraints.length = state.count;
  }

  @override
  OperationsCfe get typeAnalyzerOperations => typeOperations;

  @override
  (DartType, DartType, {List<StructuralParameter> typeParametersToEliminate})
      instantiateFunctionTypesAndProvideFreshTypeParameters(
          covariant FunctionType p, covariant FunctionType q,
          {required bool leftSchema}) {
    FunctionType instantiatedP;
    FunctionType instantiatedQ;
    if (leftSchema) {
      List<DartType> typeParametersForAlphaRenaming =
          new List<DartType>.generate(
              p.typeFormals.length,
              (int i) => new StructuralParameterType.forAlphaRenaming(
                  q.typeParameters[i], p.typeParameters[i]));
      instantiatedP = p.withoutTypeParameters;
      instantiatedQ = FunctionTypeInstantiator.instantiate(
          q, typeParametersForAlphaRenaming);
    } else {
      // Coverage-ignore-block(suite): Not run.
      List<DartType> typeParametersForAlphaRenaming =
          new List<DartType>.generate(
              p.typeFormals.length,
              (int i) => new StructuralParameterType.forAlphaRenaming(
                  p.typeParameters[i], q.typeParameters[i]));
      instantiatedP = FunctionTypeInstantiator.instantiate(
          p, typeParametersForAlphaRenaming);
      instantiatedQ = q.withoutTypeParameters;
    }

    return (
      instantiatedP,
      instantiatedQ,
      typeParametersToEliminate: leftSchema
          ? p.typeParameters
          :
          // Coverage-ignore(suite): Not run.
          q.typeParameters
    );
  }

  @override
  void eliminateTypeParametersInGeneratedConstraints(
      covariant List<StructuralParameter> typeParametersToEliminate,
      shared.TypeConstraintGeneratorState eliminationStartState,
      {required TreeNode? astNodeForTesting}) {
    List<GeneratedTypeConstraint> constraints =
        _protoConstraints.sublist(eliminationStartState.count);
    _protoConstraints.length = eliminationStartState.count;
    for (GeneratedTypeConstraint constraint in constraints) {
      if (constraint.isUpper) {
        addUpperConstraintForParameter(
            constraint.typeParameter,
            typeOperations.leastClosureOfTypeInternal(
                constraint.constraint.unwrapTypeSchemaView(),
                typeParametersToEliminate),
            astNodeForTesting: astNodeForTesting);
      } else {
        addLowerConstraintForParameter(
            constraint.typeParameter,
            typeOperations.greatestClosureOfTypeInternal(
                constraint.constraint.unwrapTypeSchemaView(),
                typeParametersToEliminate),
            astNodeForTesting: astNodeForTesting);
      }
    }
  }

  /// Applies all the argument constraints implied by trying to make
  /// [actualTypes] assignable to [formalTypes].
  void constrainArguments(
      List<DartType> formalTypes, List<DartType> actualTypes,
      {required TreeNode? treeNodeForTesting}) {
    assert(formalTypes.length == actualTypes.length);
    for (int i = 0; i < formalTypes.length; i++) {
      // Try to pass each argument to each parameter, recording any type
      // parameter bounds that were implied by this assignment.
      tryConstrainLower(formalTypes[i], actualTypes[i],
          treeNodeForTesting: treeNodeForTesting);
    }
  }

  // Coverage-ignore(suite): Not run.
  Member? getInterfaceMember(Class class_, Name name, {bool setter = false}) {
    return _environment.hierarchy
        .getInterfaceMember(class_, name, setter: setter);
  }

  @override
  List<DartType>? getTypeArgumentsAsInstanceOf(
      TypeDeclarationType type, TypeDeclaration typeDeclaration) {
    return _environment.getTypeArgumentsAsInstanceOf(type, typeDeclaration);
  }

  /// Returns the set of type constraints that was gathered.
  Map<StructuralParameter, MergedTypeConstraint> computeConstraints() {
    Map<StructuralParameter, MergedTypeConstraint> result = {};
    for (StructuralParameter parameter in typeParametersToConstrain) {
      result[parameter] = new MergedTypeConstraint(
          lower: new SharedTypeSchemaView(const UnknownType()),
          upper: new SharedTypeSchemaView(const UnknownType()),
          origin: const UnknownTypeConstraintOrigin());
    }
    for (GeneratedTypeConstraint protoConstraint in _protoConstraints) {
      result[protoConstraint.typeParameter]!
          .mergeIn(protoConstraint, typeOperations);
    }
    return result;
  }

  /// Tries to constrain type parameters in [type], so that [bound] <: [type].
  ///
  /// Doesn't change the already accumulated set of constraints if [bound] isn't
  /// a subtype of [type] under any set of constraints.
  bool tryConstrainLower(DartType type, DartType bound,
      {required TreeNode? treeNodeForTesting}) {
    return performSubtypeConstraintGenerationInternal(bound, type,
        leftSchema: true, astNodeForTesting: treeNodeForTesting);
  }

  /// Tries to constrain type parameters in [type], so that [type] <: [bound].
  ///
  /// Doesn't change the already accumulated set of constraints if [type] isn't
  /// a subtype of [bound] under any set of constraints.
  bool tryConstrainUpper(DartType type, DartType bound,
      {required TreeNode? treeNodeForTesting}) {
    return performSubtypeConstraintGenerationInternal(type, bound,
        leftSchema: false, astNodeForTesting: treeNodeForTesting);
  }

  @override
  void addLowerConstraintForParameter(
      StructuralParameter parameter, DartType lower,
      {required TreeNode? astNodeForTesting}) {
    GeneratedTypeConstraint generatedTypeConstraint =
        new GeneratedTypeConstraint.lower(
            parameter, new SharedTypeSchemaView(lower));
    if (astNodeForTesting != null && _inferenceResultForTesting != null) {
      // Coverage-ignore-block(suite): Not run.
      (_inferenceResultForTesting
              .generatedTypeConstraints[astNodeForTesting] ??= [])
          .add(generatedTypeConstraint);
    }
    _protoConstraints.add(generatedTypeConstraint);
  }

  @override
  void addUpperConstraintForParameter(
      StructuralParameter parameter, DartType upper,
      {required TreeNode? astNodeForTesting}) {
    GeneratedTypeConstraint generatedTypeConstraint =
        new GeneratedTypeConstraint.upper(
            parameter, new SharedTypeSchemaView(upper));
    if (astNodeForTesting != null && _inferenceResultForTesting != null) {
      // Coverage-ignore-block(suite): Not run.
      (_inferenceResultForTesting
              .generatedTypeConstraints[astNodeForTesting] ??= [])
          .add(generatedTypeConstraint);
    }
    _protoConstraints.add(generatedTypeConstraint);
  }

  @override
  bool performSubtypeConstraintGenerationInternal(DartType p, DartType q,
      {required bool leftSchema, required TreeNode? astNodeForTesting}) {
    if (p is SharedInvalidTypeStructure<DartType> ||
        q is SharedInvalidTypeStructure<DartType>) {
      return false;
    }

    // If the type parameters being constrained occur in the supertype (that is,
    // [q]), the subtype (that is, [p]) is not allowed to contain them.  To
    // check that, the assert below uses the equivalence of the following: X ->
    // Y  <=>  !X || Y.
    assert(
        !leftSchema ||
            !containsStructuralParameter(p, typeParametersToConstrain.toSet(),
                unhandledTypeHandler: (DartType type, ignored) =>
                    type is UnknownType
                        ? false
                        :
                        // Coverage-ignore(suite): Not run.
                        throw new UnsupportedError(
                            "Unsupported type '${type.runtimeType}'.")),
        "Failed implication check: "
        "constrainSupertype -> !containsStructuralParameter(q)");

    // If the type parameters being constrained occur in the supertype (that is,
    // [q]), the supertype is not allowed to contain [UnknownType] as its part,
    // that is, the supertype should be fully known.  To check that, the assert
    // below uses the equivalence of the following: X -> Y  <=>  !X || Y.
    assert(
        !leftSchema || isKnown(q),
        "Failed implication check: "
        "constrainSupertype -> isKnown(q)");

    // If the type parameters being constrained occur in the subtype (that is,
    // [p]), the subtype is not allowed to contain [UnknownType] as its part,
    // that is, the subtype should be fully known.  To check that, the assert
    // below uses the equivalence of the following: X -> Y  <=>  !X || Y.
    assert(
        leftSchema || isKnown(p),
        "Failed implication check: "
        "!constrainSupertype -> isKnown(p)");

    // If the type parameters being constrained occur in the subtype (that is,
    // [p]), the supertype (that is, [q]) is not allowed to contain them.  To
    // check that, the assert below uses the equivalence of the following: X ->
    // Y  <=>  !X || Y.
    assert(
        leftSchema ||
            !containsStructuralParameter(q, typeParametersToConstrain.toSet(),
                unhandledTypeHandler: (DartType type, ignored) =>
                    type is UnknownType
                        ? false
                        :
                        // Coverage-ignore(suite): Not run.
                        throw new UnsupportedError(
                            "Unsupported type '${type.runtimeType}'.")),
        "Failed implication check: "
        "!constrainSupertype -> !containsStructuralParameter(q)");

    return super.performSubtypeConstraintGenerationInternal(p, q,
        leftSchema: leftSchema, astNodeForTesting: astNodeForTesting);
  }
}
