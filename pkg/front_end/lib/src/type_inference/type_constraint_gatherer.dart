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
        TypeConstraintGeneratorState,
        Variance;
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/names.dart' show callName;
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import 'type_inference_engine.dart';
import 'type_schema.dart';
import 'type_schema_environment.dart';

/// Creates a collection of [TypeConstraint]s corresponding to type parameters,
/// based on an attempt to make one type schema a subtype of another.
class TypeConstraintGatherer extends shared.TypeConstraintGenerator<
        DartType,
        VariableDeclaration,
        StructuralParameter,
        TypeDeclarationType,
        TypeDeclaration,
        TreeNode>
    with
        shared.TypeConstraintGeneratorMixin<
            DartType,
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
    return _tryNullabilityAwareSubtypeMatch(bound, type,
        constrainSupertype: true, treeNodeForTesting: treeNodeForTesting);
  }

  /// Tries to constrain type parameters in [type], so that [type] <: [bound].
  ///
  /// Doesn't change the already accumulated set of constraints if [type] isn't
  /// a subtype of [bound] under any set of constraints.
  bool tryConstrainUpper(DartType type, DartType bound,
      {required TreeNode? treeNodeForTesting}) {
    return _tryNullabilityAwareSubtypeMatch(type, bound,
        constrainSupertype: false, treeNodeForTesting: treeNodeForTesting);
  }

  // Coverage-ignore(suite): Not run.
  /// Tries to match [subtype] against [supertype].
  ///
  /// If the match succeeds, the member returns true, and the resulting type
  /// constraints are recorded for later use by [computeConstraints].  If the
  /// match fails, the member returns false, and the set of type
  /// constraints is unchanged.
  bool _tryNullabilityObliviousSubtypeMatch(
      DartType subtype, DartType supertype,
      {required TreeNode? treeNodeForTesting}) {
    int baseConstraintCount = _protoConstraints.length;
    bool isMatch = _isNullabilityObliviousSubtypeMatch(subtype, supertype,
        treeNodeForTesting: treeNodeForTesting);
    if (!isMatch) {
      _protoConstraints.length = baseConstraintCount;
    }
    return isMatch;
  }

  /// Tries to match [subtype] against [supertype].
  ///
  /// If the match succeeds, the member returns true, and the resulting type
  /// constraints are recorded for later use by [computeConstraints].  If the
  /// match fails, the member returns false, and the set of type constraints is
  /// unchanged.
  ///
  /// In contrast with [_tryNullabilityObliviousSubtypeMatch], this method
  /// distinguishes between cases when the type parameters to constraint occur
  /// in [subtype] and in [supertype].  If [constrainSupertype] is true, the
  /// type parameters to constrain occur in [supertype]; otherwise, they occur
  /// in [subtype].  If one type contains the type parameters to constrain, the
  /// other one isn't allowed to contain them.  The type that contains the type
  /// parameters isn't allowed to also contain [UnknownType], that is, to be a
  /// type schema.
  bool _tryNullabilityAwareSubtypeMatch(DartType subtype, DartType supertype,
      {required bool constrainSupertype,
      required TreeNode? treeNodeForTesting}) {
    int baseConstraintCount = _protoConstraints.length;
    bool isMatch = _isNullabilityAwareSubtypeMatch(subtype, supertype,
        constrainSupertype: constrainSupertype,
        treeNodeForTesting: treeNodeForTesting);
    if (!isMatch) {
      _protoConstraints.length = baseConstraintCount;
    }
    return isMatch;
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

  // Coverage-ignore(suite): Not run.
  bool _isFunctionSubtypeMatch(FunctionType subtype, FunctionType supertype,
      {required TreeNode? treeNodeForTesting}) {
    // A function type `(M0,..., Mn, [M{n+1}, ..., Mm]) -> R0` is a subtype
    // match for a function type `(N0,..., Nk, [N{k+1}, ..., Nr]) -> R1` with
    // respect to `L` under constraints `C0 + ... + Cr + C`
    // - If `R0` is a subtype match for a type `R1` with respect to `L` under
    //   constraints `C`:
    // - If `n <= k` and `r <= m`.
    // - And for `i` in `0...r`, `Ni` is a subtype match for `Mi` with respect
    //   to `L` under constraints `Ci`.
    // Function types with named parameters are treated analogously to the
    // positional parameter case above.
    // A generic function type `<T0 extends B0, ..., Tn extends Bn>F0` is a
    // subtype match for a generic function type `<S0 extends B0, ..., Sn
    // extends Bn>F1` with respect to `L` under constraints `Cl`:
    // - If `F0[Z0/T0, ..., Zn/Tn]` is a subtype match for `F0[Z0/S0, ...,
    //   Zn/Sn]` with respect to `L` under constraints `C`, where each `Zi` is a
    //   fresh type variable with bound `Bi`.
    // - And `Cl` is `C` with each constraint replaced with its closure with
    //   respect to `[Z0, ..., Zn]`.
    if (subtype.requiredParameterCount > supertype.requiredParameterCount) {
      return false;
    }
    if (subtype.positionalParameters.length <
        supertype.positionalParameters.length) {
      return false;
    }
    if (subtype.typeParameters.length != supertype.typeParameters.length) {
      return false;
    }
    if (subtype.typeParameters.isNotEmpty) {
      List<StructuralParameter> freshTypeVariables = [];
      List<DartType> freshTypeVariablesAsTypes = [];
      if (!_matchTypeFormals(subtype.typeParameters, supertype.typeParameters,
          freshTypeVariables, freshTypeVariablesAsTypes,
          treeNodeForTesting: treeNodeForTesting)) {
        return false;
      }

      subtype = FunctionTypeInstantiator.instantiate(
          subtype, freshTypeVariablesAsTypes);
      supertype = FunctionTypeInstantiator.instantiate(
          supertype, freshTypeVariablesAsTypes);
    }

    // Test the return types.
    if (supertype.returnType is! VoidType &&
        !_isNullabilityObliviousSubtypeMatch(
            subtype.returnType, supertype.returnType,
            treeNodeForTesting: treeNodeForTesting)) {
      return false;
    }

    // Test the parameter types.
    for (int i = 0; i < supertype.positionalParameters.length; ++i) {
      DartType supertypeParameter = supertype.positionalParameters[i];
      DartType subtypeParameter = subtype.positionalParameters[i];
      // Termination: Both types shrink in size.
      if (!_isNullabilityObliviousSubtypeMatch(
          supertypeParameter, subtypeParameter,
          treeNodeForTesting: treeNodeForTesting)) {
        return false;
      }
    }
    int subtypeNameIndex = 0;
    for (NamedType supertypeParameter in supertype.namedParameters) {
      while (subtypeNameIndex < subtype.namedParameters.length &&
          subtype.namedParameters[subtypeNameIndex].name !=
              supertypeParameter.name) {
        ++subtypeNameIndex;
      }
      if (subtypeNameIndex == subtype.namedParameters.length) return false;
      NamedType subtypeParameter = subtype.namedParameters[subtypeNameIndex];
      // Termination: Both types shrink in size.
      if (!_isNullabilityObliviousSubtypeMatch(
          supertypeParameter.type, subtypeParameter.type,
          treeNodeForTesting: treeNodeForTesting)) {
        return false;
      }
    }
    return true;
  }

  // Coverage-ignore(suite): Not run.
  /// Whether the [subtype] interface is a subtype of the [supertype] interface
  /// with respect to variance.
  bool _isNullabilityObliviousInterfaceSubtypeMatch(
      InterfaceType subtype, InterfaceType supertype,
      {required TreeNode? treeNodeForTesting}) {
    // A type `P<M0, ..., Mk>` is a subtype match for `P<N0, ..., Nk>` with
    // respect to `L` under constraints `C0 + ... + Ck`:
    // - If `Mi` is a subtype match for `Ni` with respect to `L` under
    //   constraints `Ci`.
    // A type `P<M0, ..., Mk>` is a subtype match for `Q<N0, ..., Nj>` with
    // respect to `L` under constraints `C`:
    // - If `R<B0, ..., Bj>` is the superclass of `P<M0, ..., Mk>` and `R<B0,
    //   ..., Bj>` is a subtype match for `Q<N0, ..., Nj>` with respect to `L`
    //   under constraints `C`.
    // - Or `R<B0, ..., Bj>` is one of the interfaces implemented by `P<M0, ...,
    //   Mk>` (considered in lexical order) and `R<B0, ..., Bj>` is a subtype
    //   match for `Q<N0, ..., Nj>` with respect to `L` under constraints `C`.
    // - Or `R<B0, ..., Bj>` is a mixin into `P<M0, ..., Mk>` (considered in
    //   lexical order) and `R<B0, ..., Bj>` is a subtype match for `Q<N0, ...,
    //   Nj>` with respect to `L` under constraints `C`.

    // Note that since kernel requires that no class may only appear in the set
    // of supertypes of a given type more than once, the order of the checks
    // above is irrelevant; we just need to find the matched superclass,
    // substitute, and then iterate through type variables.
    List<DartType>? matchingSupertypeOfSubtypeArguments =
        getTypeArgumentsAsInstanceOf(subtype, supertype.classNode);
    if (matchingSupertypeOfSubtypeArguments == null) return false;
    for (int i = 0; i < supertype.classNode.typeParameters.length; i++) {
      // Generate constraints and subtype match with respect to variance.
      shared.Variance parameterVariance =
          supertype.classNode.typeParameters[i].variance;
      if (parameterVariance == shared.Variance.contravariant) {
        if (!_isNullabilityObliviousSubtypeMatch(
            supertype.typeArguments[i], matchingSupertypeOfSubtypeArguments[i],
            treeNodeForTesting: treeNodeForTesting)) {
          return false;
        }
      } else if (parameterVariance == shared.Variance.invariant) {
        if (!_isNullabilityObliviousSubtypeMatch(supertype.typeArguments[i],
                matchingSupertypeOfSubtypeArguments[i],
                treeNodeForTesting: treeNodeForTesting) ||
            !_isNullabilityObliviousSubtypeMatch(
                matchingSupertypeOfSubtypeArguments[i],
                supertype.typeArguments[i],
                treeNodeForTesting: treeNodeForTesting)) {
          return false;
        }
      } else {
        if (!_isNullabilityObliviousSubtypeMatch(
            matchingSupertypeOfSubtypeArguments[i], supertype.typeArguments[i],
            treeNodeForTesting: treeNodeForTesting)) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  bool performSubtypeConstraintGenerationInternal(DartType p, DartType q,
      {required bool leftSchema, required TreeNode? astNodeForTesting}) {
    return _isNullabilityAwareSubtypeMatch(p, q,
        constrainSupertype: leftSchema, treeNodeForTesting: astNodeForTesting);
  }

  /// Matches [p] against [q] as a subtype against supertype.
  ///
  /// Returns true if [p] is a subtype of [q] under some constraints, and false
  /// otherwise.  The constraints making the relation possible are recorded to
  /// [_protoConstraints].  It is the responsibility of the caller to cleanup
  /// [_protoConstraints] in case [p] can't be a subtype of [q].
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

    if (constrainSupertype
        ? performSubtypeConstraintGenerationForFutureOrLeftSchema(
            new SharedTypeSchemaView(p), new SharedTypeView(q),
            astNodeForTesting: treeNodeForTesting)
        : performSubtypeConstraintGenerationForFutureOrRightSchema(
            new SharedTypeView(p), new SharedTypeSchemaView(q),
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
      _protoConstraints.length = baseConstraintCount;

      if ((p is SharedDynamicTypeStructure || p is SharedVoidTypeStructure) &&
          _isNullabilityAwareSubtypeMatch(
              typeOperations.objectType.unwrapTypeView(), rawQ,
              constrainSupertype: constrainSupertype,
              treeNodeForTesting: treeNodeForTesting)) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;

      bool isMatchWithRawQ = _isNullabilityAwareSubtypeMatch(p, rawQ,
          constrainSupertype: constrainSupertype,
          treeNodeForTesting: treeNodeForTesting);
      bool matchWithRawQAddsConstraints =
          _protoConstraints.length != baseConstraintCount;
      if (isMatchWithRawQ && matchWithRawQAddsConstraints) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;

      if (_isNullabilityAwareSubtypeMatch(
          p, typeOperations.nullType.unwrapTypeView(),
          constrainSupertype: constrainSupertype,
          treeNodeForTesting: treeNodeForTesting)) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;

      if (isMatchWithRawQ && !matchWithRawQAddsConstraints) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;
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
      final int baseConstraintCount = _protoConstraints.length;
      if (_isNullabilityAwareSubtypeMatch(p.bound, q,
          constrainSupertype: constrainSupertype,
          treeNodeForTesting: treeNodeForTesting)) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;
    } else if (p is StructuralParameterType) {
      // Coverage-ignore-block(suite): Not run.
      final int baseConstraintCount = _protoConstraints.length;
      if (_isNullabilityAwareSubtypeMatch(p.bound, q,
          constrainSupertype: constrainSupertype,
          treeNodeForTesting: treeNodeForTesting)) {
        return true;
      }
      _protoConstraints.length = baseConstraintCount;
    }

    bool? result = performSubtypeConstraintGenerationForTypeDeclarationTypes(
        p, q,
        leftSchema: constrainSupertype, astNodeForTesting: treeNodeForTesting);
    if (result != null) {
      return result;
    }

    // If Q is Function then the match holds under no constraints:
    //
    // If P is a function type.
    if (typeOperations.isDartCoreFunction(new SharedTypeView(q)) &&
        // Coverage-ignore(suite): Not run.
        typeOperations.isFunctionType(new SharedTypeView(p))) {
      return true;
    }

    // A function type (M0,..., Mn, [M{n+1}, ..., Mm]) -> R0 is a subtype match
    // for a function type (N0,..., Nk, [N{k+1}, ..., Nr]) -> R1 with respect to
    // L under constraints C0 + ... + Cr + C
    //
    // If R0 is a subtype match for a type R1 with respect to L under
    // constraints C.  If n <= k and r <= m.  And for i in 0...r, Ni is a
    // subtype match for Mi with respect to L under constraints Ci.
    if (typeOperations.isFunctionType(new SharedTypeView(p)) &&
        typeOperations.isFunctionType(new SharedTypeView(q)) &&
        (p as FunctionType).typeParameters.isEmpty &&
        (q as FunctionType).typeParameters.isEmpty &&
        p.namedParameters.isEmpty &&
        q.namedParameters.isEmpty &&
        p.requiredParameterCount <= q.requiredParameterCount &&
        p.positionalParameters.length >= q.positionalParameters.length) {
      final int baseConstraintCount = _protoConstraints.length;

      if (_isNullabilityAwareSubtypeMatch(p.returnType, q.returnType,
          constrainSupertype: constrainSupertype,
          treeNodeForTesting: treeNodeForTesting)) {
        bool isMatch = true;
        for (int i = 0; isMatch && i < q.positionalParameters.length; ++i) {
          isMatch = isMatch &&
              _isNullabilityAwareSubtypeMatch(
                  q.positionalParameters[i], p.positionalParameters[i],
                  constrainSupertype: !constrainSupertype,
                  treeNodeForTesting: treeNodeForTesting);
        }
        if (isMatch) return true;
      }
      // Coverage-ignore-block(suite): Not run.
      _protoConstraints.length = baseConstraintCount;
    }

    // Function types with named parameters are treated analogously to the
    // positional parameter case above.
    if (typeOperations.isFunctionType(new SharedTypeView(p)) &&
        typeOperations.isFunctionType(new SharedTypeView(q)) &&
        (p as FunctionType).typeParameters.isEmpty &&
        (q as FunctionType).typeParameters.isEmpty &&
        p.positionalParameters.length == p.requiredParameterCount &&
        q.positionalParameters.length == q.requiredParameterCount &&
        p.requiredParameterCount == q.requiredParameterCount &&
        (p.namedParameters.isNotEmpty ||
            // Coverage-ignore(suite): Not run.
            q.namedParameters.isNotEmpty)) {
      final int baseConstraintCount = _protoConstraints.length;

      if (_isNullabilityAwareSubtypeMatch(p.returnType, q.returnType,
          constrainSupertype: constrainSupertype,
          treeNodeForTesting: treeNodeForTesting)) {
        bool isMatch = true;
        for (int i = 0;
            isMatch && i < p.positionalParameters.length;
            // Coverage-ignore(suite): Not run.
            ++i) {
          // Coverage-ignore-block(suite): Not run.
          isMatch = isMatch &&
              _isNullabilityAwareSubtypeMatch(
                  q.positionalParameters[i], p.positionalParameters[i],
                  constrainSupertype: !constrainSupertype,
                  treeNodeForTesting: treeNodeForTesting);
        }
        Map<String, DartType> pNamedTypes = {};
        for (int i = 0; isMatch && i < p.namedParameters.length; ++i) {
          pNamedTypes[p.namedParameters[i].name] = p.namedParameters[i].type;
        }
        for (int i = 0; isMatch && i < q.namedParameters.length; ++i) {
          isMatch =
              isMatch && pNamedTypes.containsKey(q.namedParameters[i].name);
          isMatch = isMatch &&
              _isNullabilityAwareSubtypeMatch(q.namedParameters[i].type,
                  pNamedTypes[q.namedParameters[i].name]!,
                  constrainSupertype: !constrainSupertype,
                  treeNodeForTesting: treeNodeForTesting);
        }
        if (isMatch) return true;
      }
      // Coverage-ignore-block(suite): Not run.
      _protoConstraints.length = baseConstraintCount;
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
    if (typeOperations.isFunctionType(new SharedTypeView(p)) &&
        typeOperations.isFunctionType(new SharedTypeView(q)) &&
        (p as FunctionType).typeParameters.isNotEmpty &&
        (q as FunctionType).typeParameters.isNotEmpty &&
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
        if (isMatch) return true;
      }
    }

    return false;
  }

  // Coverage-ignore(suite): Not run.
  /// Attempts to match [subtype] as a subtype of [supertype], gathering any
  /// constraints discovered in the process.
  ///
  /// If a set of constraints was found, `true` is returned and the caller
  /// may proceed to call [computeConstraints].  Otherwise, `false` is returned.
  ///
  /// In the case where `false` is returned, some bogus constraints may have
  /// been added to [_protoConstraints].  It is the caller's responsibility to
  /// discard them if necessary.
  bool _isNullabilityObliviousSubtypeMatch(DartType subtype, DartType supertype,
      {required TreeNode? treeNodeForTesting}) {
    // The unknown type `?` is a subtype match for any type `Q` with no
    // constraints.
    if (subtype is SharedUnknownTypeStructure) return true;
    // Any type `P` is a subtype match for the unknown type `?` with no
    // constraints.
    if (supertype is SharedUnknownTypeStructure) return true;
    // A type variable `T` in `L` is a subtype match for any type schema `Q`:
    // - Under constraint `T <: Q`.

    // TODO(cstefantsova): Don't forget to remove the commented out code below.
    // [TypeParameter] objects are never the target of inference, and the
    // condition will always fail for them.

    // if (subtype is TypeParameterType &&
    //     _parametersToConstrain.contains(subtype.parameter)) {
    //   _constrainParameterUpper(subtype.parameter, supertype);
    //   return true;
    // }
    if (subtype is StructuralParameterType &&
        _parametersToConstrain.contains(subtype.parameter)) {
      _constrainParameterUpper(subtype.parameter, supertype,
          treeNodeForTesting: treeNodeForTesting);
      return true;
    }
    // A type schema `Q` is a subtype match for a type variable `T` in `L`:
    // - Under constraint `Q <: T`.

    // TODO(cstefantsova): Don't forget to remove the commented out code below.
    // [TypeParameter] objects are never the target of inference, and the
    // condition will always fail for them.

    // if (supertype is TypeParameterType &&
    //     _parametersToConstrain.contains(supertype.parameter)) {
    //   _constrainParameterLower(supertype.parameter, subtype);
    //   return true;
    // }
    if (supertype is StructuralParameterType &&
        _parametersToConstrain.contains(supertype.parameter)) {
      _constrainParameterLower(supertype.parameter, subtype,
          treeNodeForTesting: treeNodeForTesting);
      return true;
    }
    // Any two equal types `P` and `Q` are subtype matches under no constraints.
    // Note: to avoid making the algorithm quadratic, we just check for
    // identical().  If P and Q are equal but not identical, recursing through
    // the types will give the proper result.
    if (identical(subtype, supertype)) return true;

    // Handle FutureOr<T> union type.
    if (typeOperations.matchFutureOrInternal(subtype) != null) {
      DartType subtypeArg = (subtype as FutureOrType).typeArgument;
      if (supertype is FutureOrType) {
        // `FutureOr<P>` is a subtype match for `FutureOr<Q>` with respect to
        // `L` under constraints `C`:
        // - If `P` is a subtype match for `Q` with respect to `L` under
        //   constraints `C`.
        DartType supertypeArg = supertype.typeArgument;
        return _isNullabilityObliviousSubtypeMatch(subtypeArg, supertypeArg,
            treeNodeForTesting: treeNodeForTesting);
      }

      // `FutureOr<P>` is a subtype match for `Q` with respect to `L` under
      // constraints `C0 + C1`:
      // - If `Future<P>` is a subtype match for `Q` with respect to `L` under
      //   constraints `C0`.
      // - And `P` is a subtype match for `Q` with respect to `L` under
      //   constraints `C1`.
      InterfaceType subtypeFuture =
          typeOperations.futureTypeInternal(subtypeArg);
      return _isNullabilityObliviousSubtypeMatch(subtypeFuture, supertype,
              treeNodeForTesting: treeNodeForTesting) &&
          _isNullabilityObliviousSubtypeMatch(subtypeArg, supertype,
              treeNodeForTesting: treeNodeForTesting) &&
          new IsSubtypeOf.basedSolelyOnNullabilities(subtype, supertype)
              .isSubtypeWhenUsingNullabilities();
    }

    if (typeOperations.matchFutureOrInternal(supertype) != null) {
      // `P` is a subtype match for `FutureOr<Q>` with respect to `L` under
      // constraints `C`:
      // - If `P` is a subtype match for `Future<Q>` with respect to `L` under
      //   constraints `C`.
      // - Or `P` is not a subtype match for `Future<Q>` with respect to `L`
      //   under constraints `C`
      //   - And `P` is a subtype match for `Q` with respect to `L` under
      //     constraints `C`

      // Since FutureOr<S> is a union type Future<S> U S where U denotes the
      // union operation on types, T? is T U Null, T U T = T, S U T = T U S, and
      // S U (T U V) = (S U T) U V, the following is true:
      //
      //   - FutureOr<S?> = S? U Future<S?>?
      //   - FutureOr<S>? = S? U Future<S>?
      //
      // To compute the nullabilities for the two types in the union, the
      // nullability of the argument and the declared nullability of FutureOr
      // should be united.  Also, computeNullability is used to fetch the
      // nullability of the argument because it can be a FutureOr itself.
      Nullability unitedNullability = uniteNullabilities(
          (supertype as FutureOrType).typeArgument.nullability,
          supertype.nullability);
      DartType supertypeArg =
          supertype.typeArgument.withDeclaredNullability(unitedNullability);
      DartType supertypeFuture = typeOperations
          .futureTypeInternal(supertypeArg)
          .withDeclaredNullability(unitedNullability);

      // The match against FutureOr<X> succeeds if the match against either
      // Future<X> or X succeeds.  If they both succeed, the one adding new
      // constraints should be preferred.  If both matches against Future<X> and
      // X add new constraints, the former should be preferred over the latter.
      int oldProtoConstraintsLength = _protoConstraints.length;
      bool matchesFuture = _tryNullabilityObliviousSubtypeMatch(
          subtype, supertypeFuture,
          treeNodeForTesting: treeNodeForTesting);
      bool matchesArg = oldProtoConstraintsLength != _protoConstraints.length
          ? false
          : _isNullabilityObliviousSubtypeMatch(subtype, supertypeArg,
              treeNodeForTesting: treeNodeForTesting);
      return matchesFuture || matchesArg;
    }

    // Any type `P` is a subtype match for `dynamic`, `Object`, or `void` under
    // no constraints.
    if (_isTop(supertype)) return true;
    // `Null` is a subtype match for any type `Q` under no constraints.
    // Note that nullable types will change this.
    if (typeOperations.isNull(new SharedTypeView(subtype))) return true;

    // A type variable `T` not in `L` with bound `P` is a subtype match for the
    // same type variable `T` with bound `Q` with respect to `L` under
    // constraints `C`:
    // - If `P` is a subtype match for `Q` with respect to `L` under constraints
    //   `C`.
    if (subtype is TypeParameterType) {
      if (supertype is TypeParameterType &&
          identical(subtype.parameter, supertype.parameter)) {
        // Kernel doesn't yet allow a type variable to have different bounds
        // under different circumstances (see dartbug.com/29529) so for now if
        // we get here, the bounds must be the same.
        // TODO(paulberry): update this code once dartbug.com/29529 is
        // addressed.
        return true;
      }
      // A type variable `T` not in `L` with bound `P` is a subtype match for a
      // type `Q` with respect to `L` under constraints `C`:
      // - If `P` is a subtype match for `Q` with respect to `L` under
      //   constraints `C`.
      return _isNullabilityObliviousSubtypeMatch(
          subtype.parameter.bound, supertype,
          treeNodeForTesting: treeNodeForTesting);
    } else if (subtype is StructuralParameterType) {
      if (supertype is StructuralParameterType &&
          identical(subtype.parameter, supertype.parameter)) {
        // Kernel doesn't yet allow a type variable to have different bounds
        // under different circumstances (see dartbug.com/29529) so for now if
        // we get here, the bounds must be the same.
        // TODO(paulberry): update this code once dartbug.com/29529 is
        // addressed.
        return true;
      }
      // A type variable `T` not in `L` with bound `P` is a subtype match for a
      // type `Q` with respect to `L` under constraints `C`:
      // - If `P` is a subtype match for `Q` with respect to `L` under
      //   constraints `C`.
      return _isNullabilityObliviousSubtypeMatch(
          subtype.parameter.bound, supertype,
          treeNodeForTesting: treeNodeForTesting);
    }
    if (typeOperations.isInterfaceType(new SharedTypeView(subtype)) &&
        typeOperations.isInterfaceType(new SharedTypeView(supertype))) {
      return _isNullabilityObliviousInterfaceSubtypeMatch(
          subtype as InterfaceType, supertype as InterfaceType,
          treeNodeForTesting: treeNodeForTesting);
    }
    if (typeOperations.isFunctionType(new SharedTypeView(subtype))) {
      if (typeOperations.isInterfaceType(new SharedTypeView(supertype))) {
        return supertype == _environment.coreTypes.functionLegacyRawType ||
            supertype == _environment.coreTypes.objectLegacyRawType;
      } else if (supertype is FunctionType) {
        return _isFunctionSubtypeMatch(subtype as FunctionType, supertype,
            treeNodeForTesting: treeNodeForTesting);
      }
    }
    // A type `P` is a subtype match for a type `Q` with respect to `L` under
    // constraints `C`:
    // - If `P` is an interface type which implements a call method of type `F`,
    //   and `F` is a subtype match for a type `Q` with respect to `L` under
    //   constraints `C`.
    if (typeOperations.isInterfaceType(new SharedTypeView(subtype))) {
      Member? callMember =
          getInterfaceMember((subtype as InterfaceType).classNode, callName);
      if (callMember is Procedure && !callMember.isGetter) {
        DartType callType = callMember.getterType;
        callType =
            Substitution.fromInterfaceType(subtype).substituteType(callType);
        // TODO(kmillikin): The subtype check will fail if the type of a
        // generic call method is a subtype of a non-generic function type.
        // For example, if `T call<T>(T arg)` is a subtype of `S->S` for some
        // S.  However, explicitly tearing off that call method will work and
        // insert an explicit instantiation, so the implicit tear off should
        // work as well.  Figure out how to support this case.
        return _isNullabilityObliviousSubtypeMatch(callType, supertype,
            treeNodeForTesting: treeNodeForTesting);
      }
    }
    return false;
  }

  // Coverage-ignore(suite): Not run.
  bool _isTop(DartType type) =>
      type is DynamicType ||
      type is VoidType ||
      type == _environment.coreTypes.objectLegacyRawType;

  // Coverage-ignore(suite): Not run.
  /// Given two lists of function type formal parameters, checks that their
  /// bounds are compatible.
  ///
  /// The return value indicates whether a match was found.  If it was, entries
  /// are added to [substitution1] and [substitution2] which substitute a fresh
  /// set of type variables for the type parameters [params1] and [params2],
  /// respectively, allowing further comparison.
  bool _matchTypeFormals(
      List<StructuralParameter> params1,
      List<StructuralParameter> params2,
      List<StructuralParameter> freshTypeVariables,
      List<DartType> freshTypeVariablesAsTypes,
      {required TreeNode? treeNodeForTesting}) {
    assert(params1.length == params2.length);
    // TODO(paulberry): in imitation of analyzer, we're checking the bounds as
    // we build up the substitutions.  But I don't think that's correct--I think
    // we should build up both substitutions completely before checking any
    // bounds.  See dartbug.com/29629.
    for (int i = 0; i < params1.length; ++i) {
      StructuralParameter pFresh = new StructuralParameter(params2[i].name);
      freshTypeVariables.add(pFresh);
      DartType variableFresh =
          new StructuralParameterType.forAlphaRenaming(params2[i], pFresh);
      freshTypeVariablesAsTypes.add(variableFresh);
      DartType bound1 = new FunctionTypeInstantiator.fromIterables(
              params1.sublist(0, i + 1), freshTypeVariablesAsTypes)
          .substitute(params1[i].bound);
      DartType bound2 = new FunctionTypeInstantiator.fromIterables(
              params2.sublist(0, i + 1), freshTypeVariablesAsTypes)
          .substitute(params2[i].bound);
      pFresh.bound = bound2;
      if (!_isNullabilityObliviousSubtypeMatch(bound2, bound1,
          treeNodeForTesting: treeNodeForTesting)) {
        return false;
      }
    }
    return true;
  }
}
