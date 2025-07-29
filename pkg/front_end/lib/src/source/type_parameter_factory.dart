// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../base/messages.dart';
import '../builder/declaration_builders.dart';
import '../builder/metadata_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/synthesized_type_builder.dart';
import '../builder/type_builder.dart';
import '../fragment/fragment.dart';
import 'source_type_parameter_builder.dart';

class TypeParameterFactory {
  List<TypeParameterBuilder>? _typeParameterBuilders = [];

  bool get isEmpty => _typeParameterBuilders?.isEmpty ?? true;

  void _registerTypeParameter(TypeParameterBuilder builder) {
    assert(
        _typeParameterBuilders != null,
        "TypeParameterFactory has already been emptied, trying to register "
        "$builder.");
    _typeParameterBuilders!.add(builder);
  }

  List<TypeParameterBuilder> collectTypeParameters() {
    assert(
        _typeParameterBuilders != null,
        "TypeParameterFactory has already been emptied, trying to collect type "
        "parameters.");
    List<TypeParameterBuilder> result = _typeParameterBuilders!;
    _typeParameterBuilders = null;
    return result;
  }

  SourceStructuralParameterBuilder createStructuralParameterBuilder(
      StructuralParameterDeclaration declaration,
      {List<MetadataBuilder>? metadata}) {
    SourceStructuralParameterBuilder builder =
        new SourceStructuralParameterBuilder(declaration, metadata: metadata);
    _registerTypeParameter(builder);
    return builder;
  }

  SourceNominalParameterBuilder createNominalParameterBuilder(
      TypeParameterFragment fragment) {
    SourceNominalParameterBuilder builder = new SourceNominalParameterBuilder(
        new RegularNominalParameterDeclaration(fragment),
        bound: fragment.bound,
        variableVariance: fragment.variance);
    _registerTypeParameter(builder);
    fragment.builder = builder;
    return builder;
  }

  List<SourceNominalParameterBuilder>? createNominalParameterBuilders(
      List<TypeParameterFragment>? fragments) {
    if (fragments == null) return null;
    List<SourceNominalParameterBuilder> list = [];
    for (TypeParameterFragment fragment in fragments) {
      list.add(createNominalParameterBuilder(fragment));
    }
    return list;
  }

  /// Creates a [NominalParameterCopy] object containing a copy of
  /// [oldParameterBuilders], adding any newly created parameters in
  /// [unboundNominalParameters] for later processing.
  ///
  /// This is used for adding copies of class type parameters to factory
  /// methods and unnamed mixin applications, and for adding copies of
  /// extension type parameters to extension instance methods.
  NominalParameterCopy? copyTypeParameters(
      {required List<NominalParameterBuilder>? oldParameterBuilders,
      List<TypeParameterFragment>? oldParameterFragments,
      required TypeParameterKind kind,
      required InstanceTypeParameterAccessState instanceTypeParameterAccess}) {
    assert(
        oldParameterFragments == null ||
            oldParameterBuilders?.length == oldParameterFragments.length,
        "Invalid type parameter fragment count. "
        "Expected ${oldParameterBuilders?.length}, "
        "found ${oldParameterFragments.length}.");
    if (oldParameterBuilders == null || oldParameterBuilders.isEmpty) {
      return null;
    }

    List<TypeBuilder> newTypeArguments = [];
    Map<NominalParameterBuilder, TypeBuilder> substitutionMap =
        new Map.identity();
    Map<SourceNominalParameterBuilder, NominalParameterBuilder>
        newToOldVariableMap = new Map.identity();

    List<SourceNominalParameterBuilder> newVariableBuilders =
        <SourceNominalParameterBuilder>[];
    for (int index = 0; index < oldParameterBuilders.length; index++) {
      NominalParameterBuilder oldVariable = oldParameterBuilders[index];
      TypeParameterFragment? oldFragment = oldParameterFragments?[index];
      Uri fileUri = (oldFragment?.fileUri ?? oldVariable.fileUri)!;
      int fileOffset = oldFragment?.nameOffset ?? oldVariable.fileOffset;
      SourceNominalParameterBuilder newVariable =
          new SourceNominalParameterBuilder(
              new SyntheticNominalParameterDeclaration(oldVariable,
                  kind: kind, fileUri: fileUri, fileOffset: fileOffset),
              variableVariance: oldVariable.parameter.isLegacyCovariant
                  ? null
                  :
                  // Coverage-ignore(suite): Not run.
                  oldVariable.variance);
      newVariableBuilders.add(newVariable);
      newToOldVariableMap[newVariable] = oldVariable;
      _registerTypeParameter(newVariable);
    }
    for (int i = 0; i < newVariableBuilders.length; i++) {
      NominalParameterBuilder oldVariableBuilder = oldParameterBuilders[i];
      TypeBuilder newTypeArgument =
          new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
              newVariableBuilders[i], const NullabilityBuilder.omitted(),
              instanceTypeParameterAccess: instanceTypeParameterAccess);
      substitutionMap[oldVariableBuilder] = newTypeArgument;
      newTypeArguments.add(newTypeArgument);

      if (oldVariableBuilder.bound != null) {
        newVariableBuilders[i].bound = new SynthesizedTypeBuilder(
            oldVariableBuilder.bound!, newToOldVariableMap, substitutionMap);
      }
    }
    return new NominalParameterCopy(newVariableBuilders, newTypeArguments,
        substitutionMap, newToOldVariableMap);
  }
}

class NominalParameterCopy {
  final List<SourceNominalParameterBuilder> newParameterBuilders;
  final List<TypeBuilder> newTypeArguments;
  final Map<NominalParameterBuilder, TypeBuilder> substitutionMap;
  final Map<SourceNominalParameterBuilder, NominalParameterBuilder>
      newToOldParameterMap;

  NominalParameterCopy(this.newParameterBuilders, this.newTypeArguments,
      this.substitutionMap, this.newToOldParameterMap);

  /// Creates a [SynthesizedTypeBuilder] for [typeBuilder] in the context of
  /// [newParameterBuilders].
  TypeBuilder createInContext(TypeBuilder typeBuilder) {
    return new SynthesizedTypeBuilder(
        typeBuilder, newToOldParameterMap, substitutionMap);
  }
}

void checkTypeParameterDependencies(ProblemReporting problemReporting,
    List<TypeParameterBuilder> typeParameters) {
  Map<TypeParameterBuilder, TraversalState> typeParametersTraversalState =
      <TypeParameterBuilder, TraversalState>{};
  for (int i = 0; i < typeParameters.length; i++) {
    TypeParameterBuilder typeParameter = typeParameters[i];
    if ((typeParametersTraversalState[typeParameter] ??=
            TraversalState.unvisited) ==
        TraversalState.unvisited) {
      TypeParameterCyclicDependency? dependency =
          typeParameter.findCyclicDependency(
              typeParametersTraversalState: typeParametersTraversalState);
      if (dependency != null) {
        Message message;
        if (dependency.viaTypeParameters != null) {
          message = templateCycleInTypeParameters.withArguments(
              dependency.typeParameterBoundOfItself.name,
              dependency.viaTypeParameters!.map((v) => v.name).join("', '"));
        } else {
          message = templateDirectCycleInTypeParameters
              .withArguments(dependency.typeParameterBoundOfItself.name);
        }
        problemReporting.addProblem(
            message,
            dependency.typeParameterBoundOfItself.fileOffset,
            dependency.typeParameterBoundOfItself.name.length,
            dependency.typeParameterBoundOfItself.fileUri);

        typeParameter.bound = new NamedTypeBuilderImpl(
            new SyntheticTypeName(typeParameter.name, typeParameter.fileOffset),
            const NullabilityBuilder.omitted(),
            fileUri: typeParameter.fileUri,
            charOffset: typeParameter.fileOffset,
            instanceTypeParameterAccess:
                InstanceTypeParameterAccessState.Unexpected)
          ..bind(
              problemReporting,
              new InvalidBuilder(
                  typeParameter.name,
                  message.withLocation(
                      dependency.typeParameterBoundOfItself.fileUri!,
                      dependency.typeParameterBoundOfItself.fileOffset,
                      dependency.typeParameterBoundOfItself.name.length)));
      }
    }
  }
  _computeTypeParameterNullabilities(typeParameters);
}

void _computeTypeParameterNullabilities(
    List<TypeParameterBuilder> typeParameters) {
  Map<TypeParameterBuilder, TraversalState> typeParametersTraversalState =
      <TypeParameterBuilder, TraversalState>{};
  for (int i = 0; i < typeParameters.length; i++) {
    TypeParameterBuilder typeParameter = typeParameters[i];
    if ((typeParametersTraversalState[typeParameter] ??=
            TraversalState.unvisited) ==
        TraversalState.unvisited) {
      typeParameter.computeNullability(
          typeParametersTraversalState: typeParametersTraversalState);
    }
  }
}
