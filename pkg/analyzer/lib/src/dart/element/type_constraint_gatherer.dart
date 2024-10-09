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

/// Creates sets of [TypeConstraint]s for type parameters, based on an attempt
/// to make one type schema a subtype of another.
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
      _addUpper(P_element, Q, nodeForTesting: nodeForTesting);
      return true;
    }

    // If `Q` is a type variable `X` in `L`, then the match holds:
    //   Under constraint `P <: X <: _`.
    var Q_nullability = Q.nullabilitySuffix;
    if (_typeSystemOperations.matchInferableParameter(SharedTypeView(Q))
        case var Q_element?
        when Q_nullability == NullabilitySuffix.none &&
            _typeParameters.contains(Q_element)) {
      _addLower(Q_element, P, nodeForTesting: nodeForTesting);
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
    if (performSubtypeConstraintGenerationForFutureOr(P, Q,
        leftSchema: leftSchema, astNodeForTesting: nodeForTesting)) {
      return true;
    }

    // If `Q` is `Q0?` the match holds under constraint set `C`:
    if (Q_nullability == NullabilitySuffix.question) {
      var Q0 = _typeSystemOperations
          .withNullabilitySuffix(SharedTypeView(Q), NullabilitySuffix.none)
          .unwrapTypeView();
      var rewind = _constraints.length;

      // If `P` is `P0?` and `P0` is a subtype match for `Q0` under
      // constraint set `C`.
      if (P_nullability == NullabilitySuffix.question) {
        var P0 = _typeSystemOperations
            .withNullabilitySuffix(SharedTypeView(P), NullabilitySuffix.none)
            .unwrapTypeView();
        if (trySubtypeMatch(P0, Q0, leftSchema,
            nodeForTesting: nodeForTesting)) {
          return true;
        }
      }

      // Or if `P` is `dynamic` or `void` and `Object` is a subtype match
      // for `Q0` under constraint set `C`.
      if (P is SharedDynamicTypeStructure || P is SharedVoidTypeStructure) {
        if (trySubtypeMatch(_typeSystem.objectNone, Q0, leftSchema,
            nodeForTesting: nodeForTesting)) {
          return true;
        }
      }

      // Or if `P` is a subtype match for `Q0` under non-empty
      // constraint set `C`.
      var P_matches_Q0 =
          trySubtypeMatch(P, Q0, leftSchema, nodeForTesting: nodeForTesting);
      if (P_matches_Q0 && _constraints.length != rewind) {
        return true;
      }

      // Or if `P` is a subtype match for `Null` under constraint set `C`.
      if (trySubtypeMatch(P, _typeSystem.nullNone, leftSchema,
          nodeForTesting: nodeForTesting)) {
        return true;
      }

      // Or if `P` is a subtype match for `Q0` under empty
      // constraint set `C`.
      if (P_matches_Q0) {
        return true;
      }
    }

    // If `P` is `FutureOr<P0>` the match holds under constraint set `C1 + C2`:
    if (_typeSystemOperations.matchFutureOrInternal(P) case var P0?
        when P_nullability == NullabilitySuffix.none) {
      var rewind = _constraints.length;

      // If `Future<P0>` is a subtype match for `Q` under constraint set `C1`.
      // And if `P0` is a subtype match for `Q` under constraint set `C2`.
      var future_P0 = _typeSystemOperations.futureTypeInternal(P0);
      if (trySubtypeMatch(future_P0, Q, leftSchema,
              nodeForTesting: nodeForTesting) &&
          trySubtypeMatch(P0, Q, leftSchema, nodeForTesting: nodeForTesting)) {
        return true;
      }

      _constraints.length = rewind;
    }

    // If `P` is `P0?` the match holds under constraint set `C1 + C2`:
    if (P_nullability == NullabilitySuffix.question) {
      var P0 = _typeSystemOperations
          .withNullabilitySuffix(SharedTypeView(P), NullabilitySuffix.none)
          .unwrapTypeView();
      var rewind = _constraints.length;

      // If `P0` is a subtype match for `Q` under constraint set `C1`.
      // And if `Null` is a subtype match for `Q` under constraint set `C2`.
      if (trySubtypeMatch(P0, Q, leftSchema, nodeForTesting: nodeForTesting) &&
          trySubtypeMatch(_typeSystem.nullNone, Q, leftSchema,
              nodeForTesting: nodeForTesting)) {
        return true;
      }

      _constraints.length = rewind;
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

    if (P is FunctionType && Q is FunctionType) {
      return _functionType(P, Q, leftSchema, nodeForTesting: nodeForTesting);
    }

    // A type `P` is a subtype match for `Record` with respect to `L` under no
    // constraints:
    //   If `P` is a record type or `Record`.
    if (Q_nullability == NullabilitySuffix.none && Q.isDartCoreRecord) {
      if (P is SharedRecordTypeStructure<DartType>) {
        return true;
      }
    }

    if (P is SharedRecordTypeStructure<DartType> &&
        Q is SharedRecordTypeStructure<DartType>) {
      return _recordType(P as RecordTypeImpl, Q as RecordTypeImpl, leftSchema,
          nodeForTesting: nodeForTesting);
    }

    return false;
  }

  void _addLower(TypeParameterElement element, DartType lower,
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

  void _addUpper(TypeParameterElement element, DartType upper,
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

  /// Matches [P] against [Q], where [P] and [Q] are both function types.
  ///
  /// If [P] is a subtype of [Q] under some constraints, the constraints making
  /// the relation possible are recorded to [_constraints], and `true` is
  /// returned. Otherwise, [_constraints] is left unchanged (or rolled back),
  /// and `false` is returned.
  bool _functionType(FunctionType P, FunctionType Q, bool leftSchema,
      {required AstNode? nodeForTesting}) {
    if (P.nullabilitySuffix != NullabilitySuffix.none) {
      return false;
    }

    if (Q.nullabilitySuffix != NullabilitySuffix.none) {
      return false;
    }

    var P_typeFormals = P.typeFormals;
    var Q_typeFormals = Q.typeFormals;
    if (P_typeFormals.length != Q_typeFormals.length) {
      return false;
    }

    if (P_typeFormals.isEmpty && Q_typeFormals.isEmpty) {
      return performSubtypeConstraintGenerationForFunctionTypes(P, Q,
          leftSchema: leftSchema, astNodeForTesting: nodeForTesting);
    }

    // We match two generic function types:
    // `<T0 extends B00, ..., Tn extends B0n>F0`
    // `<S0 extends B10, ..., Sn extends B1n>F1`
    // with respect to `L` under constraint set `C2`:
    var rewind = _constraints.length;

    // If `B0i` is a subtype match for `B1i` with constraint set `Ci0`.
    // If `B1i` is a subtype match for `B0i` with constraint set `Ci1`.
    // And `Ci2` is `Ci0 + Ci1`.
    for (var i = 0; i < P_typeFormals.length; i++) {
      var B0 = P_typeFormals[i].bound ?? _typeSystem.objectQuestion;
      var B1 = Q_typeFormals[i].bound ?? _typeSystem.objectQuestion;
      if (!trySubtypeMatch(B0, B1, leftSchema,
          nodeForTesting: nodeForTesting)) {
        _constraints.length = rewind;
        return false;
      }
      if (!trySubtypeMatch(B1, B0, !leftSchema,
          nodeForTesting: nodeForTesting)) {
        _constraints.length = rewind;
        return false;
      }
    }

    // And `Z0...Zn` are fresh variables with bounds `B20, ..., B2n`.
    //   Where `B2i` is `B0i[Z0/T0, ..., Zn/Tn]` if `P` is a type schema.
    //   Or `B2i` is `B1i[Z0/S0, ..., Zn/Sn]` if `Q` is a type schema.
    // In other words, we choose the bounds for the fresh variables from
    // whichever of the two generic function types is a type schema and does
    // not contain any variables from `L`.
    var newTypeParameters = <TypeParameterElement>[];
    for (var i = 0; i < P_typeFormals.length; i++) {
      var Z = TypeParameterElementImpl('Z$i', -1);
      if (leftSchema) {
        Z.bound = P_typeFormals[i].bound;
      } else {
        Z.bound = Q_typeFormals[i].bound;
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
    if (!performSubtypeConstraintGenerationForFunctionTypes(
        P_instantiated, Q_instantiated,
        leftSchema: leftSchema, astNodeForTesting: nodeForTesting)) {
      _constraints.length = rewind;
      return false;
    }

    // And `C1` is `C02 + ... + Cn2 + C0`.
    // And `C2` is `C1` with each constraint replaced with its closure
    // with respect to `[Z0, ..., Zn]`.
    // TODO(scheglov): do closure

    return true;
  }

  /// Matches [P] against [Q], where [P] and [Q] are both record types.
  ///
  /// If [P] is a subtype of [Q] under some constraints, the constraints making
  /// the relation possible are recorded to [_constraints], and `true` is
  /// returned. Otherwise, [_constraints] is left unchanged (or rolled back),
  /// and `false` is returned.
  bool _recordType(RecordTypeImpl P, RecordTypeImpl Q, bool leftSchema,
      {required AstNode? nodeForTesting}) {
    // If `P` is `(M0, ..., Mk)` and `Q` is `(N0, ..., Nk)`, then the match
    // holds under constraints `C0 + ... + Ck`:
    //   If `Mi` is a subtype match for `Ni` with respect to L under
    //   constraints `Ci`.
    if (P.nullabilitySuffix != NullabilitySuffix.none) {
      return false;
    }

    if (Q.nullabilitySuffix != NullabilitySuffix.none) {
      return false;
    }

    var positionalP = P.positionalFields;
    var positionalQ = Q.positionalFields;
    if (positionalP.length != positionalQ.length) {
      return false;
    }

    var namedP = P.namedFields;
    var namedQ = Q.namedFields;
    if (namedP.length != namedQ.length) {
      return false;
    }

    var rewind = _constraints.length;

    for (var i = 0; i < positionalP.length; i++) {
      var fieldP = positionalP[i];
      var fieldQ = positionalQ[i];
      if (!trySubtypeMatch(fieldP.type, fieldQ.type, leftSchema,
          nodeForTesting: nodeForTesting)) {
        _constraints.length = rewind;
        return false;
      }
    }

    for (var i = 0; i < namedP.length; i++) {
      var fieldP = namedP[i];
      var fieldQ = namedQ[i];
      if (fieldP.name != fieldQ.name) {
        _constraints.length = rewind;
        return false;
      }
      if (!trySubtypeMatch(fieldP.type, fieldQ.type, leftSchema,
          nodeForTesting: nodeForTesting)) {
        _constraints.length = rewind;
        return false;
      }
    }

    return true;
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
