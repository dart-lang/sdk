// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_constraint.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';

import 'mini_ast.dart';
import 'mini_types.dart';

class TypeConstraintGatherer
    extends TypeConstraintGenerator<Var, Type, String, Node>
    with TypeConstraintGeneratorMixin<Var, Type, String, Node> {
  @override
  final Set<TypeParameter> typeParametersToConstrain = <TypeParameter>{};

  @override
  final bool enableDiscrepantObliviousnessOfNullabilitySuffixOfFutureOr;

  @override
  final MiniAstOperations typeAnalyzerOperations = MiniAstOperations();

  final constraints = <String>[];

  TypeConstraintGatherer(
    Set<String> typeVariablesBeingConstrained, {
    this.enableDiscrepantObliviousnessOfNullabilitySuffixOfFutureOr = false,
  }) : super(inferenceUsingBoundsIsEnabled: false) {
    for (var typeVariableName in typeVariablesBeingConstrained) {
      typeParametersToConstrain.add(
        TypeRegistry.addTypeParameter(typeVariableName),
      );
    }
  }

  @override
  TypeConstraintGeneratorState get currentState =>
      TypeConstraintGeneratorState(constraints.length);

  @override
  void addLowerConstraintForParameter(
    TypeParameter typeParameter,
    Type lower, {
    required Node? astNodeForTesting,
  }) {
    constraints.add('$lower <: $typeParameter');
  }

  @override
  void addUpperConstraintForParameter(
    TypeParameter typeParameter,
    Type upper, {
    required Node? astNodeForTesting,
  }) {
    constraints.add('$typeParameter <: $upper');
  }

  @override
  Map<TypeParameter, MergedTypeConstraint<Var, Type, String, Node>>
  computeConstraints() {
    // TODO(cstefantsova): implement computeConstraints
    throw UnimplementedError();
  }

  @override
  void eliminateTypeParametersInGeneratedConstraints(
    Object eliminator,
    TypeConstraintGeneratorState eliminationStartState, {
    required Node? astNodeForTesting,
  }) {
    // TODO(paulberry): implement eliminateTypeParametersInGeneratedConstraints
  }

  @override
  List<Type>? getTypeArgumentsAsInstanceOf(Type type, String typeDeclaration) {
    // We just have a few cases hardcoded here to make the tests work.
    // TODO(paulberry): if this gets too unwieldy, replace it with a more
    // general implementation.
    switch ((type, typeDeclaration)) {
      case (PrimaryType(name: 'List', :var args), 'Iterable'):
        // List<T> inherits from Iterable<T>
        return args;
      case (PrimaryType(name: 'MyListOfInt'), 'List'):
        // MyListOfInt inherits from List<int>
        return [Type('int')];
      case (PrimaryType(name: 'Future'), 'int'):
      case (PrimaryType(name: 'int'), 'String'):
      case (PrimaryType(name: 'List'), 'Future'):
      case (PrimaryType(name: 'String'), 'int'):
      case (PrimaryType(name: 'Future'), 'String'):
        // Unrelated types
        return null;
      default:
        throw UnimplementedError(
          'getTypeArgumentsAsInstanceOf($type, $typeDeclaration)',
        );
    }
  }

  @override
  (Type, Type, {List<TypeParameter> typeParametersToEliminate})
  instantiateFunctionTypesAndProvideFreshTypeParameters(
    SharedFunctionType p,
    SharedFunctionType q, {
    required bool leftSchema,
  }) {
    // TODO(paulberry): implement instantiateFunctionTypesAndProvideEliminator
    throw UnimplementedError();
  }

  @override
  void restoreState(TypeConstraintGeneratorState state) {
    constraints.length = state.count;
  }
}
