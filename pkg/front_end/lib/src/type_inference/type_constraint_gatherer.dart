// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/nullability_suffix.dart'
    show NullabilitySuffix;
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

  final List<StructuralParameter> _parametersToConstrain;

  final OperationsCfe typeOperations;

  final TypeSchemaEnvironment _environment;

  final TypeInferenceResultForTesting? _inferenceResultForTesting;

  TypeConstraintGatherer(
      this._environment, Iterable<StructuralParameter> typeParameters,
      {required OperationsCfe typeOperations,
      required TypeInferenceResultForTesting? inferenceResultForTesting})
      : typeOperations = typeOperations,
        _parametersToConstrain =
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
    for (StructuralParameter parameter in _parametersToConstrain) {
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
    return _isNullabilityAwareSubtypeMatch(bound, type,
        constrainSupertype: true, treeNodeForTesting: treeNodeForTesting);
  }

  /// Tries to constrain type parameters in [type], so that [type] <: [bound].
  ///
  /// Doesn't change the already accumulated set of constraints if [type] isn't
  /// a subtype of [bound] under any set of constraints.
  bool tryConstrainUpper(DartType type, DartType bound,
      {required TreeNode? treeNodeForTesting}) {
    return _isNullabilityAwareSubtypeMatch(type, bound,
        constrainSupertype: false, treeNodeForTesting: treeNodeForTesting);
  }

  /// Add constraint: [lower] <: [parameter] <: TOP.
  void _constrainParameterLower(StructuralParameter parameter, DartType lower,
      {required TreeNode? treeNodeForTesting}) {
    GeneratedTypeConstraint generatedTypeConstraint =
        new GeneratedTypeConstraint.lower(
            parameter, new SharedTypeSchemaView(lower));
    if (treeNodeForTesting != null && _inferenceResultForTesting != null) {
      // Coverage-ignore-block(suite): Not run.
      (_inferenceResultForTesting
              .generatedTypeConstraints[treeNodeForTesting] ??= [])
          .add(generatedTypeConstraint);
    }
    _protoConstraints.add(generatedTypeConstraint);
  }

  /// Add constraint: BOTTOM <: [parameter] <: [upper].
  void _constrainParameterUpper(StructuralParameter parameter, DartType upper,
      {required TreeNode? treeNodeForTesting}) {
    GeneratedTypeConstraint generatedTypeConstraint =
        new GeneratedTypeConstraint.upper(
            parameter, new SharedTypeSchemaView(upper));
    if (treeNodeForTesting != null && _inferenceResultForTesting != null) {
      // Coverage-ignore-block(suite): Not run.
      (_inferenceResultForTesting
              .generatedTypeConstraints[treeNodeForTesting] ??= [])
          .add(generatedTypeConstraint);
    }
    _protoConstraints.add(generatedTypeConstraint);
  }

  @override
  bool performSubtypeConstraintGenerationInternal(DartType p, DartType q,
      {required bool leftSchema, required TreeNode? astNodeForTesting}) {
    return _isNullabilityAwareSubtypeMatch(p, q,
        constrainSupertype: leftSchema, treeNodeForTesting: astNodeForTesting);
  }

  /// Matches [p] against [q] as a subtype against supertype.
  ///
  /// If [p] is a subtype of [q] under some constraints, the constraints making
  /// the relation possible are recorded to [_protoConstraints], and `true` is
  /// returned. Otherwise, [_protoConstraints] is left unchanged (or rolled
  /// back), and `false` is returned.
  ///
  /// If [constrainSupertype] is true, the type parameters to constrain occur in
  /// [supertype]; otherwise, they occur in [subtype].  If one type contains the
  /// type parameters to constrain, the other one isn't allowed to contain them.
  /// The type that contains the type parameters isn't allowed to also contain
  /// [UnknownType], that is, to be a type schema.
  bool _isNullabilityAwareSubtypeMatch(DartType p, DartType q,
      {required bool constrainSupertype,
      required TreeNode? treeNodeForTesting}) {
    // If the type parameters being constrained occur in the supertype (that is,
    // [q]), the subtype (that is, [p]) is not allowed to contain them.  To
    // check that, the assert below uses the equivalence of the following: X ->
    // Y  <=>  !X || Y.
    assert(
        !constrainSupertype ||
            !containsStructuralTypeVariable(p, _parametersToConstrain.toSet(),
                unhandledTypeHandler: (DartType type, ignored) =>
                    type is UnknownType
                        ? false
                        :
                        // Coverage-ignore(suite): Not run.
                        throw new UnsupportedError(
                            "Unsupported type '${type.runtimeType}'.")),
        "Failed implication check: "
        "constrainSupertype -> !containsTypeVariable(q)");

    // If the type parameters being constrained occur in the supertype (that is,
    // [q]), the supertype is not allowed to contain [UnknownType] as its part,
    // that is, the supertype should be fully known.  To check that, the assert
    // below uses the equivalence of the following: X -> Y  <=>  !X || Y.
    assert(
        !constrainSupertype || isKnown(q),
        "Failed implication check: "
        "constrainSupertype -> isKnown(q)");

    // If the type parameters being constrained occur in the subtype (that is,
    // [p]), the subtype is not allowed to contain [UnknownType] as its part,
    // that is, the subtype should be fully known.  To check that, the assert
    // below uses the equivalence of the following: X -> Y  <=>  !X || Y.
    assert(
        constrainSupertype || isKnown(p),
        "Failed implication check: "
        "!constrainSupertype -> isKnown(p)");

    // If the type parameters being constrained occur in the subtype (that is,
    // [p]), the supertype (that is, [q]) is not allowed to contain them.  To
    // check that, the assert below uses the equivalence of the following: X ->
    // Y  <=>  !X || Y.
    assert(
        constrainSupertype ||
            !containsStructuralTypeVariable(q, _parametersToConstrain.toSet(),
                unhandledTypeHandler: (DartType type, ignored) =>
                    type is UnknownType
                        ? false
                        :
                        // Coverage-ignore(suite): Not run.
                        throw new UnsupportedError(
                            "Unsupported type '${type.runtimeType}'.")),
        "Failed implication check: "
        "!constrainSupertype -> !containsTypeVariable(q)");

    if (p is InvalidType || q is InvalidType) return false;

    // If P is _ then the match holds with no constraints.
    if (p is SharedUnknownTypeStructure) return true;

    // If Q is _ then the match holds with no constraints.
    if (q is SharedUnknownTypeStructure) return true;

    // If P is a type variable X in L, then the match holds:
    //
    // Under constraint _ <: X <: Q.
    NullabilitySuffix pNullability = p.nullabilitySuffix;
    if (typeOperations.matchInferableParameter(new SharedTypeView(p))
        case StructuralParameter pParameter?
        when pNullability == NullabilitySuffix.none &&
            _parametersToConstrain.contains(pParameter)) {
      _constrainParameterUpper(pParameter, q,
          treeNodeForTesting: treeNodeForTesting);
      return true;
    }

    // If Q is a type variable X in L, then the match holds:
    //
    // Under constraint P <: X <: _.
    NullabilitySuffix qNullability = q.nullabilitySuffix;
    if (typeOperations.matchInferableParameter(new SharedTypeView(q))
        case StructuralParameter qParameter?
        when qNullability == NullabilitySuffix.none &&
            _parametersToConstrain.contains(qParameter)) {
      _constrainParameterLower(qParameter, p,
          treeNodeForTesting: treeNodeForTesting);
      return true;
    }

    // If P and Q are identical types, then the subtype match holds under no
    // constraints.
    //
    // We're only checking primitive types for equality, because the algorithm
    // will recurse over non-primitive types anyway.
    if (identical(p, q) ||
        isPrimitiveDartType(p) && isPrimitiveDartType(q) && p == q) {
      return true;
    }

    if (performSubtypeConstraintGenerationForFutureOr(p, q,
        leftSchema: constrainSupertype,
        astNodeForTesting: treeNodeForTesting)) {
      return true;
    }

    // If Q is Q0? the match holds under constraint set C:
    //
    // If P is P0? and P0 is a subtype match for Q0 under constraint set C.
    // Or if P is dynamic or void and Object is a subtype match for Q0 under
    // constraint set C.
    // Or if P is a subtype match for Q0 under non-empty constraint set C.
    // Or if P is a subtype match for Null under constraint set C.
    // Or if P is a subtype match for Q0 under empty constraint set C.
    if (qNullability == NullabilitySuffix.question) {
      final int baseConstraintCount = _protoConstraints.length;
      final DartType rawP = typeOperations
          .withNullabilitySuffix(new SharedTypeView(p), NullabilitySuffix.none)
          .unwrapTypeView();
      final DartType rawQ = typeOperations
          .withNullabilitySuffix(new SharedTypeView(q), NullabilitySuffix.none)
          .unwrapTypeView();

      if (pNullability == NullabilitySuffix.question &&
          _isNullabilityAwareSubtypeMatch(rawP, rawQ,
              constrainSupertype: constrainSupertype,
              treeNodeForTesting: treeNodeForTesting)) {
        return true;
      }

      if ((p is SharedDynamicTypeStructure || p is SharedVoidTypeStructure) &&
          _isNullabilityAwareSubtypeMatch(
              typeOperations.objectType.unwrapTypeView(), rawQ,
              constrainSupertype: constrainSupertype,
              treeNodeForTesting: treeNodeForTesting)) {
        return true;
      }

      bool isMatchWithRawQ = _isNullabilityAwareSubtypeMatch(p, rawQ,
          constrainSupertype: constrainSupertype,
          treeNodeForTesting: treeNodeForTesting);
      bool matchWithRawQAddsConstraints =
          _protoConstraints.length != baseConstraintCount;
      if (isMatchWithRawQ && matchWithRawQAddsConstraints) {
        return true;
      }

      if (_isNullabilityAwareSubtypeMatch(
          p, typeOperations.nullType.unwrapTypeView(),
          constrainSupertype: constrainSupertype,
          treeNodeForTesting: treeNodeForTesting)) {
        return true;
      }

      if (isMatchWithRawQ && !matchWithRawQAddsConstraints) {
        return true;
      }
    }

    // If P is FutureOr<P0> the match holds under constraint set C1 + C2:
    //
    // If Future<P0> is a subtype match for Q under constraint set C1.
    // And if P0 is a subtype match for Q under constraint set C2.
    if (typeOperations.matchFutureOrInternal(p) case DartType p0?) {
      final int baseConstraintCount = _protoConstraints.length;
      if (_isNullabilityAwareSubtypeMatch(
              typeOperations.futureTypeInternal(p0), q,
              constrainSupertype: constrainSupertype,
              treeNodeForTesting: treeNodeForTesting) &&
          // Coverage-ignore(suite): Not run.
          _isNullabilityAwareSubtypeMatch(p0, q,
              constrainSupertype: constrainSupertype,
              treeNodeForTesting: treeNodeForTesting)) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;
    }

    // If P is P0? the match holds under constraint set C1 + C2:
    //
    // If P0 is a subtype match for Q under constraint set C1.
    // And if Null is a subtype match for Q under constraint set C2.
    if (pNullability == NullabilitySuffix.question) {
      final int baseConstraintCount = _protoConstraints.length;
      if (_isNullabilityAwareSubtypeMatch(
              typeOperations
                  .withNullabilitySuffix(
                      new SharedTypeView(p), NullabilitySuffix.none)
                  .unwrapTypeView(),
              q,
              constrainSupertype: constrainSupertype,
              treeNodeForTesting: treeNodeForTesting) &&
          _isNullabilityAwareSubtypeMatch(
              typeOperations.nullType.unwrapTypeView(), q,
              constrainSupertype: constrainSupertype,
              treeNodeForTesting: treeNodeForTesting)) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;
    }

    // If Q is dynamic, Object?, or void then the match holds under no
    // constraints.
    if (q is SharedDynamicTypeStructure ||
        q is SharedVoidTypeStructure ||
        q == typeOperations.objectQuestionType.unwrapTypeView()) {
      return true;
    }

    // If P is Never then the match holds under no constraints.
    if (typeOperations.isNever(new SharedTypeView(p))) {
      return true;
    }

    // If Q is Object, then the match holds under no constraints:
    //
    // Only if P is non-nullable.
    if (q == typeOperations.objectType.unwrapTypeView()) {
      return typeOperations.isNonNullable(new SharedTypeSchemaView(p));
    }

    // If P is Null, then the match holds under no constraints:
    //
    // Only if Q is nullable.
    if (typeOperations.isNull(new SharedTypeView(p))) {
      return q.nullability == Nullability.nullable;
    }

    // If P is a type variable X with bound B (or a promoted type variable X &
    // B), the match holds with constraint set C:
    //
    // If B is a subtype match for Q with constraint set C.  Note that we have
    // already eliminated the case that X is a variable in L.
    if (p is TypeParameterType) {
      // Coverage-ignore-block(suite): Not run.
      if (_isNullabilityAwareSubtypeMatch(p.bound, q,
          constrainSupertype: constrainSupertype,
          treeNodeForTesting: treeNodeForTesting)) {
        return true;
      }
    } else if (p is StructuralParameterType) {
      // Coverage-ignore-block(suite): Not run.
      if (_isNullabilityAwareSubtypeMatch(p.bound, q,
          constrainSupertype: constrainSupertype,
          treeNodeForTesting: treeNodeForTesting)) {
        return true;
      }
    }

    bool? constraintGenerationResult =
        performSubtypeConstraintGenerationForTypeDeclarationTypes(p, q,
            leftSchema: constrainSupertype,
            astNodeForTesting: treeNodeForTesting);
    if (constraintGenerationResult != null) {
      return constraintGenerationResult;
    }

    // If Q is Function then the match holds under no constraints:
    //
    // If P is a function type.
    if (typeOperations.isDartCoreFunction(new SharedTypeView(q)) &&
        // Coverage-ignore(suite): Not run.
        p is FunctionType) {
      return true;
    }

    if (performSubtypeConstraintGenerationForFunctionTypes(p, q,
        leftSchema: constrainSupertype,
        astNodeForTesting: treeNodeForTesting)) {
      return true;
    }

    // A generic function type <T0 extends B00, ..., Tn extends B0n>F0 is a
    // subtype match for a generic function type <S0 extends B10, ..., Sn
    // extends B1n>F1 with respect to L under constraint set C2
    //
    // If B0i is a subtype match for B1i with constraint set Ci0.  And B1i is a
    // subtype match for B0i with constraint set Ci1.  And Ci2 is Ci0 + Ci1.
    //
    // And Z0...Zn are fresh variables with bounds B20, ..., B2n, Where B2i is
    // B0i[Z0/T0, ..., Zn/Tn] if P is a type schema.  Or B2i is B1i[Z0/S0, ...,
    // Zn/Sn] if Q is a type schema.  In other words, we choose the bounds for
    // the fresh variables from whichever of the two generic function types is a
    // type schema and does not contain any variables from L.
    //
    // And F0[Z0/T0, ..., Zn/Tn] is a subtype match for F1[Z0/S0, ..., Zn/Sn]
    // with respect to L under constraints C0.  And C1 is C02 + ... + Cn2 + C0.
    // And C2 is C1 with each constraint replaced with its closure with respect
    // to [Z0, ..., Zn].
    if (p is FunctionType &&
        q is FunctionType &&
        p.typeParameters.isNotEmpty &&
        q.typeParameters.isNotEmpty &&
        p.typeParameters.length == q.typeParameters.length) {
      final int baseConstraintCount = _protoConstraints.length;

      bool isMatch = true;
      for (int i = 0; isMatch && i < p.typeParameters.length; ++i) {
        isMatch = isMatch &&
            _isNullabilityAwareSubtypeMatch(
                p.typeParameters[i].bound, q.typeParameters[i].bound,
                constrainSupertype: constrainSupertype,
                treeNodeForTesting: treeNodeForTesting) &&
            _isNullabilityAwareSubtypeMatch(
                q.typeParameters[i].bound, p.typeParameters[i].bound,
                constrainSupertype: !constrainSupertype,
                treeNodeForTesting: treeNodeForTesting);
      }
      if (isMatch) {
        List<DartType> typeParametersOfPAsTypesForQ =
            new List<DartType>.generate(
                p.typeParameters.length,
                (int i) => new StructuralParameterType.forAlphaRenaming(
                    q.typeParameters[i], p.typeParameters[i]));
        FunctionType instantiatedP = p.withoutTypeParameters;
        FunctionType instantiatedQ = FunctionTypeInstantiator.instantiate(
            q, typeParametersOfPAsTypesForQ);
        if (_isNullabilityAwareSubtypeMatch(instantiatedP, instantiatedQ,
            constrainSupertype: constrainSupertype,
            treeNodeForTesting: treeNodeForTesting)) {
          List<GeneratedTypeConstraint> constraints =
              _protoConstraints.sublist(baseConstraintCount);
          _protoConstraints.length = baseConstraintCount;
          NullabilityAwareTypeVariableEliminator eliminator =
              new NullabilityAwareTypeVariableEliminator(
                  structuralEliminationTargets: p.typeParameters.toSet(),
                  nominalEliminationTargets: {},
                  bottomType: typeOperations.neverType.unwrapTypeView(),
                  topType: typeOperations.objectQuestionType.unwrapTypeView(),
                  topFunctionType:
                      _environment.coreTypes.functionNonNullableRawType,
                  unhandledTypeHandler:
                      // Coverage-ignore(suite): Not run.
                      (DartType type, ignored) => type is UnknownType
                          ? false
                          :
                          // Coverage-ignore(suite): Not run.
                          throw new UnsupportedError(
                              "Unsupported type '${type.runtimeType}'."));
          for (GeneratedTypeConstraint constraint in constraints) {
            if (constraint.isUpper) {
              _constrainParameterUpper(
                  constraint.typeParameter,
                  eliminator.eliminateToLeast(
                      constraint.constraint.unwrapTypeSchemaView()),
                  treeNodeForTesting: treeNodeForTesting);
            } else {
              _constrainParameterLower(
                  constraint.typeParameter,
                  eliminator.eliminateToGreatest(
                      constraint.constraint.unwrapTypeSchemaView()),
                  treeNodeForTesting: treeNodeForTesting);
            }
          }
          return true;
        }
      }
      // Coverage-ignore-block(suite): Not run.
      _protoConstraints.length = baseConstraintCount;
    }

    // A type P is a subtype match for Record with respect to L under no
    // constraints:
    //
    // If P is a record type or Record.
    if (q == _environment.coreTypes.recordNonNullableRawType &&
        p is RecordType) {
      return true;
    }

    // A record type `(M0,..., Mk, {M{k+1} d{k+1}, ..., Mm dm])` is a subtype
    // match for a record type `(N0,..., Nk, {N{k+1} d{k+1}, ..., Nm dm])` with
    // respect to `L` under constraints `C0 + ... + Cm`
    // If for `i` in `0...m`, `Mi` is a subtype match for `Ni` with respect to
    // `L` under constraints `Ci`.
    if (p is SharedRecordTypeStructure<DartType> &&
        q is SharedRecordTypeStructure<DartType> &&
        (p as RecordType).positional.length ==
            (q as RecordType).positional.length &&
        p.named.length == q.named.length) {
      bool sameNames = true;
      for (int i = 0; sameNames && i < p.named.length; i++) {
        if (p.named[i].name != q.named[i].name) {
          sameNames = false;
        }
      }
      if (sameNames) {
        final int baseConstraintCount = _protoConstraints.length;
        bool isMatch = true;
        for (int i = 0; isMatch && i < p.positional.length; i++) {
          isMatch = isMatch &&
              _isNullabilityAwareSubtypeMatch(p.positional[i], q.positional[i],
                  constrainSupertype: constrainSupertype,
                  treeNodeForTesting: treeNodeForTesting);
        }
        for (int i = 0; isMatch && i < p.named.length; i++) {
          isMatch = isMatch &&
              _isNullabilityAwareSubtypeMatch(p.named[i].type, q.named[i].type,
                  constrainSupertype: constrainSupertype,
                  treeNodeForTesting: treeNodeForTesting);
        }
        // Coverage-ignore-block(suite): Not run.
        if (isMatch) return true;
        _protoConstraints.length = baseConstraintCount;
      }
    }

    return false;
  }
}
