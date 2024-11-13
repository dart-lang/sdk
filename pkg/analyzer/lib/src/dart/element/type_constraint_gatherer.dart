// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart'
    as shared
    show
        TypeConstraintGenerator,
        TypeConstraintGeneratorMixin,
        TypeConstraintGeneratorState;
import 'package:_fe_analyzer_shared/src/type_inference/type_constraint.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';

/// Creates sets of [GeneratedTypeConstraint]s for type parameters, based on an
/// attempt to make one type schema a subtype of another.
class TypeConstraintGatherer extends shared.TypeConstraintGenerator<
        DartType,
        ParameterElement,
        PromotableElement,
        TypeParameterElement,
        InterfaceType,
        InterfaceElement,
        AstNode>
    with
        shared.TypeConstraintGeneratorMixin<
            DartType,
            ParameterElement,
            PromotableElement,
            TypeParameterElement,
            InterfaceType,
            InterfaceElement,
            AstNode> {
  final TypeSystemImpl _typeSystem;
  final Set<TypeParameterElement> _typeParameters = Set.identity();
  final List<
      GeneratedTypeConstraint<DartType, TypeParameterElement,
          PromotableElement>> _constraints = [];
  final TypeSystemOperations _typeSystemOperations;
  final TypeConstraintGenerationDataForTesting? dataForTesting;

  TypeConstraintGatherer({
    required TypeSystemImpl typeSystem,
    required Iterable<TypeParameterElement> typeParameters,
    required TypeSystemOperations typeSystemOperations,
    required super.inferenceUsingBoundsIsEnabled,
    required this.dataForTesting,
  })  : _typeSystem = typeSystem,
        _typeSystemOperations = typeSystemOperations {
    _typeParameters.addAll(typeParameters);
  }

  @override
  shared.TypeConstraintGeneratorState get currentState {
    return shared.TypeConstraintGeneratorState(_constraints.length);
  }

  @override
  bool get enableDiscrepantObliviousnessOfNullabilitySuffixOfFutureOr => false;

  bool get isConstraintSetEmpty => _constraints.isEmpty;

  @override
  TypeSystemOperations get typeAnalyzerOperations => _typeSystemOperations;

  @override
  void addLowerConstraintForParameter(
      TypeParameterElement element, DartType lower,
      {required AstNode? nodeForTesting}) {
    GeneratedTypeConstraint<DartType, TypeParameterElement, PromotableElement>
        generatedTypeConstraint = GeneratedTypeConstraint<
            DartType,
            TypeParameterElement,
            PromotableElement>.lower(element, SharedTypeSchemaView(lower));
    _constraints.add(generatedTypeConstraint);
    if (dataForTesting != null && nodeForTesting != null) {
      (dataForTesting!.generatedTypeConstraints[nodeForTesting] ??= [])
          .add(generatedTypeConstraint);
    }
  }

  @override
  void addUpperConstraintForParameter(
      TypeParameterElement element, DartType upper,
      {required AstNode? nodeForTesting}) {
    GeneratedTypeConstraint<DartType, TypeParameterElement, PromotableElement>
        generatedTypeConstraint = GeneratedTypeConstraint<
            DartType,
            TypeParameterElement,
            PromotableElement>.upper(element, SharedTypeSchemaView(upper));
    _constraints.add(generatedTypeConstraint);
    if (dataForTesting != null && nodeForTesting != null) {
      (dataForTesting!.generatedTypeConstraints[nodeForTesting] ??= [])
          .add(generatedTypeConstraint);
    }
  }

  /// Returns the set of type constraints that was gathered.
  Map<
      TypeParameterElement,
      MergedTypeConstraint<DartType, TypeParameterElement, PromotableElement,
          InterfaceType, InterfaceElement>> computeConstraints() {
    var result = <TypeParameterElement,
        MergedTypeConstraint<DartType, TypeParameterElement, PromotableElement,
            InterfaceType, InterfaceElement>>{};
    for (var parameter in _typeParameters) {
      result[parameter] = MergedTypeConstraint<DartType, TypeParameterElement,
          PromotableElement, InterfaceType, InterfaceElement>(
        lower: SharedTypeSchemaView(UnknownInferredType.instance),
        upper: SharedTypeSchemaView(UnknownInferredType.instance),
        origin: const UnknownTypeConstraintOrigin(),
      );
    }

    for (var constraint in _constraints) {
      var parameter = constraint.typeParameter;
      var mergedConstraint = result[parameter]!;

      mergedConstraint.mergeIn(constraint, _typeSystemOperations);
    }

    return result;
  }

  @override
  void eliminateTypeParametersInGeneratedConstraints(
      covariant List<TypeParameterElement> eliminator,
      shared.TypeConstraintGeneratorState eliminationStartState,
      {required AstNode? astNodeForTesting}) {
    var constraints = _constraints.sublist(eliminationStartState.count);
    _constraints.length = eliminationStartState.count;
    for (var constraint in constraints) {
      if (constraint.isUpper) {
        addUpperConstraintForParameter(
            constraint.typeParameter,
            typeAnalyzerOperations.leastClosureOfTypeInternal(
                constraint.constraint.unwrapTypeSchemaView(), eliminator),
            nodeForTesting: astNodeForTesting);
      } else {
        addLowerConstraintForParameter(
            constraint.typeParameter,
            typeAnalyzerOperations.greatestClosureOfTypeInternal(
                constraint.constraint.unwrapTypeSchemaView(), eliminator),
            nodeForTesting: astNodeForTesting);
      }
    }
  }

  @override
  List<DartType>? getTypeArgumentsAsInstanceOf(
      InterfaceType type, InterfaceElement typeDeclaration) {
    for (var interface in type.element.allSupertypes) {
      if (interface.element == typeDeclaration) {
        var substitution = Substitution.fromInterfaceType(type);
        var substitutedInterface =
            substitution.substituteType(interface) as InterfaceType;
        return substitutedInterface.typeArguments;
      }
    }
    return null;
  }

  @override
  (DartType, DartType, {List<TypeParameterElement> typeParametersToEliminate})
      instantiateFunctionTypesAndProvideFreshTypeParameters(
          covariant FunctionType P, covariant FunctionType Q,
          {required bool leftSchema}) {
    // And `Z0...Zn` are fresh variables with bounds `B20, ..., B2n`.
    //   Where `B2i` is `B0i[Z0/T0, ..., Zn/Tn]` if `P` is a type schema.
    //   Or `B2i` is `B1i[Z0/S0, ..., Zn/Sn]` if `Q` is a type schema.
    // In other words, we choose the bounds for the fresh variables from
    // whichever of the two generic function types is a type schema and does
    // not contain any variables from `L`.
    var newTypeParameters = <TypeParameterElement>[];
    for (var i = 0; i < P.typeFormals.length; i++) {
      var Z = TypeParameterElementImpl('Z$i', -1);
      if (leftSchema) {
        Z.bound = P.typeFormals[i].bound;
      } else {
        Z.bound = Q.typeFormals[i].bound;
      }
      newTypeParameters.add(Z);
    }

    // And `F0[Z0/T0, ..., Zn/Tn]` is a subtype match for
    // `F1[Z0/S0, ..., Zn/Sn]` with respect to `L` under constraints `C0`.
    var typeArguments = newTypeParameters
        .map((e) => e.instantiate(nullabilitySuffix: NullabilitySuffix.none))
        .toList();
    var P_instantiated = P.instantiate(typeArguments);
    var Q_instantiated = Q.instantiate(typeArguments);

    return (
      P_instantiated,
      Q_instantiated,
      typeParametersToEliminate: newTypeParameters
    );
  }

  @override
  bool performSubtypeConstraintGenerationInternal(DartType p, DartType q,
      {required bool leftSchema, required AstNode? astNodeForTesting}) {
    return trySubtypeMatch(p, q, leftSchema, nodeForTesting: astNodeForTesting);
  }

  @override
  void restoreState(shared.TypeConstraintGeneratorState state) {
    _constraints.length = state.count;
  }

  /// Tries to match [P] as a subtype for [Q].
  ///
  /// If [P] is a subtype of [Q] under some constraints, the constraints making
  /// the relation possible are recorded to [_constraints], and `true` is
  /// returned. Otherwise, [_constraints] is left unchanged (or rolled back),
  /// and `false` is returned.
  bool trySubtypeMatch(DartType P, DartType Q, bool leftSchema,
      {required AstNode? nodeForTesting}) {
    // If `P` is `_` then the match holds with no constraints.
    if (P is SharedUnknownTypeStructure) {
      return true;
    }

    // If `Q` is `_` then the match holds with no constraints.
    if (Q is SharedUnknownTypeStructure) {
      return true;
    }

    // If `P` is a type variable `X` in `L`, then the match holds:
    //   Under constraint `_ <: X <: Q`.
    var P_nullability = P.nullabilitySuffix;
    if (_typeSystemOperations.matchInferableParameter(SharedTypeView(P))
        case var P_element?
        when P_nullability == NullabilitySuffix.none &&
            _typeParameters.contains(P_element)) {
      addUpperConstraintForParameter(P_element, Q,
          nodeForTesting: nodeForTesting);
      return true;
    }

    // If `Q` is a type variable `X` in `L`, then the match holds:
    //   Under constraint `P <: X <: _`.
    var Q_nullability = Q.nullabilitySuffix;
    if (_typeSystemOperations.matchInferableParameter(SharedTypeView(Q))
        case var Q_element?
        when Q_nullability == NullabilitySuffix.none &&
            _typeParameters.contains(Q_element) &&
            (!inferenceUsingBoundsIsEnabled ||
                (Q_element.bound == null ||
                    _typeSystemOperations.isSubtypeOfInternal(
                        P,
                        _typeSystemOperations.greatestClosureOfTypeInternal(
                            Q_element.bound!, [..._typeParameters]))))) {
      addLowerConstraintForParameter(Q_element, P,
          nodeForTesting: nodeForTesting);
      return true;
    }

    // If `P` and `Q` are identical types, then the subtype match holds
    // under no constraints.
    if (P == Q) {
      return true;
    }

    // Note that it's not necessary to rewind [_constraints] to its prior state
    // in case [performSubtypeConstraintGenerationForFutureOr] returns false, as
    // [performSubtypeConstraintGenerationForFutureOr] handles the rewinding of
    // the state itself.
    if (performSubtypeConstraintGenerationForRightFutureOr(P, Q,
        leftSchema: leftSchema, astNodeForTesting: nodeForTesting)) {
      return true;
    }

    if (performSubtypeConstraintGenerationForRightNullableType(P, Q,
        leftSchema: leftSchema, astNodeForTesting: nodeForTesting)) {
      return true;
    }

    // If `P` is `FutureOr<P0>` the match holds under constraint set `C1 + C2`:
    if (performSubtypeConstraintGenerationForLeftFutureOr(P, Q,
        leftSchema: leftSchema, astNodeForTesting: nodeForTesting)) {
      return true;
    }

    // If `P` is `P0?` the match holds under constraint set `C1 + C2`:
    if (performSubtypeConstraintGenerationForLeftNullableType(P, Q,
        leftSchema: leftSchema, astNodeForTesting: nodeForTesting)) {
      return true;
    }

    // If `Q` is `dynamic`, `Object?`, or `void` then the match holds under
    // no constraints.
    if (Q is SharedDynamicTypeStructure ||
        Q is SharedVoidTypeStructure ||
        Q == _typeSystemOperations.objectQuestionType.unwrapTypeView()) {
      return true;
    }

    // If `P` is `Never` then the match holds under no constraints.
    if (_typeSystemOperations.isNever(SharedTypeView(P))) {
      return true;
    }

    // If `Q` is `Object`, then the match holds under no constraints:
    //  Only if `P` is non-nullable.
    if (Q == _typeSystemOperations.objectType.unwrapTypeView()) {
      return _typeSystem.isNonNullable(P);
    }

    // If `P` is `Null`, then the match holds under no constraints:
    //  Only if `Q` is nullable.
    if (P_nullability == NullabilitySuffix.none &&
        _typeSystemOperations.isNull(SharedTypeView(P))) {
      return _typeSystem.isNullable(Q);
    }

    // If `P` is a type variable `X` with bound `B` (or a promoted type
    // variable `X & B`), the match holds with constraint set `C`:
    //   If `B` is a subtype match for `Q` with constraint set `C`.
    // Note: we have already eliminated the case that `X` is a variable in `L`.
    if (P_nullability == NullabilitySuffix.none && P is TypeParameterTypeImpl) {
      var B = P.promotedBound ?? P.element.bound;
      if (B != null &&
          trySubtypeMatch(B, Q, leftSchema, nodeForTesting: nodeForTesting)) {
        return true;
      }
    }

    bool? result = performSubtypeConstraintGenerationForTypeDeclarationTypes(
        P, Q,
        leftSchema: leftSchema, astNodeForTesting: nodeForTesting);
    if (result != null) {
      return result;
    }

    // If `Q` is `Function` then the match holds under no constraints:
    //   If `P` is a function type.
    if (_typeSystemOperations.isDartCoreFunction(SharedTypeView(Q))) {
      if (P is SharedFunctionTypeStructure) {
        return true;
      }
    }

    if (performSubtypeConstraintGenerationForFunctionTypes(P, Q,
        leftSchema: leftSchema, astNodeForTesting: nodeForTesting)) {
      return true;
    }

    // A type `P` is a subtype match for `Record` with respect to `L` under no
    // constraints:
    //   If `P` is a record type or `Record`.
    if (_typeSystemOperations.isDartCoreRecord(SharedTypeView(Q))) {
      if (P is SharedRecordTypeStructure<DartType>) {
        return true;
      }
    }

    if (performSubtypeConstraintGenerationForRecordTypes(P, Q,
        leftSchema: leftSchema, astNodeForTesting: nodeForTesting)) {
      return true;
    }

    return false;
  }
}

/// Data structure maintaining intermediate type inference results, such as
/// type constraints, for testing purposes.  Under normal execution, no
/// instance of this class should be created.
class TypeConstraintGenerationDataForTesting {
  /// Map from nodes requiring type inference to the generated type constraints
  /// for the node.
  final Map<
      AstNode,
      List<
          GeneratedTypeConstraint<DartType, TypeParameterElement,
              PromotableElement>>> generatedTypeConstraints = {};

  /// Merges [other] into the receiver, combining the constraints.
  ///
  /// The method reuses data structures from [other] whenever possible, to
  /// avoid extra memory allocations. This process is destructive to [other]
  /// because the changes made to the reused structures will be visible to
  /// [other].
  void mergeIn(TypeConstraintGenerationDataForTesting other) {
    for (AstNode node in other.generatedTypeConstraints.keys) {
      List<
          GeneratedTypeConstraint<DartType, TypeParameterElement,
              PromotableElement>>? constraints = generatedTypeConstraints[node];
      if (constraints != null) {
        constraints.addAll(other.generatedTypeConstraints[node]!);
      } else {
        generatedTypeConstraints[node] = other.generatedTypeConstraints[node]!;
      }
    }
  }
}
