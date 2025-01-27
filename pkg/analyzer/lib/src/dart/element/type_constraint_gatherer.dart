// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart'
    as shared
    show
        TypeConstraintGenerator,
        TypeConstraintGeneratorMixin,
        TypeConstraintGeneratorState;
import 'package:_fe_analyzer_shared/src/type_inference/type_constraint.dart'
    as shared
    show
        GeneratedTypeConstraint,
        MergedTypeConstraint,
        TypeConstraintGenerationDataForTesting,
        TypeConstraintFromArgument,
        TypeConstraintFromExtendsClause,
        TypeConstraintFromFunctionContext,
        TypeConstraintFromReturnType,
        TypeConstraintOrigin,
        UnknownTypeConstraintOrigin;
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';

/// Instance of [shared.GeneratedTypeConstraint] specific to the Analyzer.
typedef GeneratedTypeConstraint
    = shared.GeneratedTypeConstraint<PromotableElementImpl2>;

/// Instance of [shared.MergedTypeConstraint] specific to the Analyzer.
typedef MergedTypeConstraint = shared.MergedTypeConstraint<
    PromotableElementImpl2, InterfaceTypeImpl, InterfaceElementImpl2>;

/// Instance of [shared.TypeConstraintFromArgument] specific to the Analyzer.
typedef TypeConstraintFromArgument = shared.TypeConstraintFromArgument<
    PromotableElementImpl2, InterfaceTypeImpl, InterfaceElementImpl2>;

/// Instance of [shared.TypeConstraintFromExtendsClause] specific to the Analyzer.
typedef TypeConstraintFromExtendsClause
    = shared.TypeConstraintFromExtendsClause<PromotableElementImpl2,
        InterfaceTypeImpl, InterfaceElementImpl2>;

/// Instance of [shared.TypeConstraintFromFunctionContext] specific to the Analyzer.
typedef TypeConstraintFromFunctionContext
    = shared.TypeConstraintFromFunctionContext<PromotableElementImpl2,
        InterfaceTypeImpl, InterfaceElementImpl2>;

/// Instance of [shared.TypeConstraintFromReturnType] specific to the Analyzer.
typedef TypeConstraintFromReturnType = shared.TypeConstraintFromReturnType<
    PromotableElementImpl2, InterfaceTypeImpl, InterfaceElementImpl2>;

typedef TypeConstraintGenerationDataForTesting
    = shared.TypeConstraintGenerationDataForTesting<PromotableElementImpl2,
        AstNodeImpl>;

/// Instance of [shared.TypeConstraintOrigin] specific to the Analyzer.
typedef TypeConstraintOrigin = shared.TypeConstraintOrigin<
    PromotableElementImpl2, InterfaceTypeImpl, InterfaceElementImpl2>;

/// Instance of [shared.UnknownTypeConstraintOrigin] specific to the Analyzer.
typedef UnknownTypeConstraintOrigin = shared.UnknownTypeConstraintOrigin<
    PromotableElementImpl2, InterfaceTypeImpl, InterfaceElementImpl2>;

/// Creates sets of [GeneratedTypeConstraint]s for type parameters, based on an
/// attempt to make one type schema a subtype of another.
class TypeConstraintGatherer extends shared.TypeConstraintGenerator<
        PromotableElementImpl2,
        InterfaceTypeImpl,
        InterfaceElementImpl2,
        AstNodeImpl>
    with
        shared.TypeConstraintGeneratorMixin<PromotableElementImpl2,
            InterfaceTypeImpl, InterfaceElementImpl2, AstNodeImpl> {
  @override
  final Set<TypeParameterElementImpl2> typeParametersToConstrain =
      Set.identity();

  final List<GeneratedTypeConstraint> _constraints = [];
  final TypeSystemOperations _typeSystemOperations;
  final TypeConstraintGenerationDataForTesting? dataForTesting;

  TypeConstraintGatherer({
    required Iterable<TypeParameterElementImpl2> typeParameters,
    required TypeSystemOperations typeSystemOperations,
    required super.inferenceUsingBoundsIsEnabled,
    required this.dataForTesting,
  }) : _typeSystemOperations = typeSystemOperations {
    typeParametersToConstrain.addAll(typeParameters);
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
      TypeParameterElementImpl2 element, TypeImpl lower,
      {required AstNodeImpl? astNodeForTesting}) {
    GeneratedTypeConstraint generatedTypeConstraint =
        GeneratedTypeConstraint.lower(
            SharedTypeParameterView(element), SharedTypeSchemaView(lower));
    _constraints.add(generatedTypeConstraint);
    if (dataForTesting != null && astNodeForTesting != null) {
      (dataForTesting!.generatedTypeConstraints[astNodeForTesting] ??= [])
          .add(generatedTypeConstraint);
    }
  }

  @override
  void addUpperConstraintForParameter(
      TypeParameterElementImpl2 element, TypeImpl upper,
      {required AstNodeImpl? astNodeForTesting}) {
    GeneratedTypeConstraint generatedTypeConstraint =
        GeneratedTypeConstraint.upper(
            SharedTypeParameterView(element), SharedTypeSchemaView(upper));
    _constraints.add(generatedTypeConstraint);
    if (dataForTesting != null && astNodeForTesting != null) {
      (dataForTesting!.generatedTypeConstraints[astNodeForTesting] ??= [])
          .add(generatedTypeConstraint);
    }
  }

  @override
  Map<TypeParameterElementImpl2, MergedTypeConstraint> computeConstraints() {
    var result = <TypeParameterElementImpl2, MergedTypeConstraint>{};
    for (var parameter in typeParametersToConstrain) {
      result[parameter] = MergedTypeConstraint(
        lower: SharedTypeSchemaView(UnknownInferredType.instance),
        upper: SharedTypeSchemaView(UnknownInferredType.instance),
        origin: const UnknownTypeConstraintOrigin(),
      );
    }

    for (var constraint in _constraints) {
      var parameter = constraint.typeParameter
          .unwrapTypeParameterViewAsTypeParameterStructure<
              TypeParameterElementImpl2>();
      var mergedConstraint = result[parameter]!;

      mergedConstraint.mergeIn(constraint, _typeSystemOperations);
    }

    return result;
  }

  @override
  void eliminateTypeParametersInGeneratedConstraints(
      covariant List<TypeParameterElementImpl2> eliminator,
      shared.TypeConstraintGeneratorState eliminationStartState,
      {required AstNodeImpl? astNodeForTesting}) {
    var constraints = _constraints.sublist(eliminationStartState.count);
    _constraints.length = eliminationStartState.count;
    for (var constraint in constraints) {
      if (constraint.isUpper) {
        addUpperConstraintForParameter(
            constraint.typeParameter
                .unwrapTypeParameterViewAsTypeParameterStructure<
                    TypeParameterElementImpl2>(),
            typeAnalyzerOperations.leastClosureOfTypeInternal(
                constraint.constraint.unwrapTypeSchemaView(), eliminator),
            astNodeForTesting: astNodeForTesting);
      } else {
        addLowerConstraintForParameter(
            constraint.typeParameter
                .unwrapTypeParameterViewAsTypeParameterStructure<
                    TypeParameterElementImpl2>(),
            typeAnalyzerOperations.greatestClosureOfTypeInternal(
                constraint.constraint.unwrapTypeSchemaView(), eliminator),
            astNodeForTesting: astNodeForTesting);
      }
    }
  }

  @override
  List<TypeImpl>? getTypeArgumentsAsInstanceOf(
      InterfaceType type, InterfaceElementImpl2 typeDeclaration) {
    for (var interface in type.element3.allSupertypes) {
      if (interface.element3 == typeDeclaration) {
        var substitution = Substitution.fromInterfaceType(type);
        var substitutedInterface =
            substitution.substituteType(interface) as InterfaceTypeImpl;
        return substitutedInterface.typeArguments;
      }
    }
    return null;
  }

  @override
  (
    TypeImpl,
    TypeImpl, {
    List<TypeParameterElementImpl2> typeParametersToEliminate
  }) instantiateFunctionTypesAndProvideFreshTypeParameters(
      covariant FunctionTypeImpl P, covariant FunctionTypeImpl Q,
      {required bool leftSchema}) {
    // And `Z0...Zn` are fresh variables with bounds `B20, ..., B2n`.
    //   Where `B2i` is `B0i[Z0/T0, ..., Zn/Tn]` if `P` is a type schema.
    //   Or `B2i` is `B1i[Z0/S0, ..., Zn/Sn]` if `Q` is a type schema.
    // In other words, we choose the bounds for the fresh variables from
    // whichever of the two generic function types is a type schema and does
    // not contain any variables from `L`.
    var newTypeParameters = <TypeParameterElementImpl2>[];
    for (var i = 0; i < P.typeFormals.length; i++) {
      var Z = TypeParameterElementImpl('Z$i', -1);
      if (leftSchema) {
        Z.bound = P.typeFormals[i].bound;
      } else {
        Z.bound = Q.typeFormals[i].bound;
      }
      newTypeParameters.add(Z.element);
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
  void restoreState(shared.TypeConstraintGeneratorState state) {
    _constraints.length = state.count;
  }
}
