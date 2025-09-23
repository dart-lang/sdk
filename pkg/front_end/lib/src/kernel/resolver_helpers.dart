// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'resolver.dart';

typedef BodyBuilderCreator = ({
  BodyBuilderCreatorUnnamed create,
  BodyBuilderCreatorForField createForField,
  BodyBuilderCreatorForOutlineExpression createForOutlineExpression,
});

typedef BodyBuilderCreatorForField =
    BodyBuilder Function(
      SourceLibraryBuilder libraryBuilder,
      BodyBuilderContext bodyBuilderContext,
      LookupScope enclosingScope,
      TypeInferrer typeInferrer,
      Uri uri,
    );

typedef BodyBuilderCreatorForOutlineExpression =
    BodyBuilder Function(
      SourceLibraryBuilder library,
      BodyBuilderContext bodyBuilderContext,
      LookupScope scope,
      Uri fileUri, {
      LocalScope? formalParameterScope,
    });

typedef BodyBuilderCreatorUnnamed =
    BodyBuilder Function({
      required SourceLibraryBuilder libraryBuilder,
      required BodyBuilderContext context,
      required LookupScope enclosingScope,
      LocalScope? formalParameterScope,
      required ClassHierarchy hierarchy,
      required CoreTypes coreTypes,
      VariableDeclaration? thisVariable,
      List<TypeParameter>? thisTypeParameters,
      required Uri uri,
      required TypeInferrer typeInferrer,
      required ConstantContext constantContext,
    });

// Coverage-ignore(suite): Not run.
class ResolverForTesting extends Resolver {
  final BodyBuilderCreator bodyBuilderCreator;

  ResolverForTesting({
    required super.classHierarchy,
    required super.coreTypes,
    required super.typeInferenceEngine,
    required super.benchmarker,
    required this.bodyBuilderCreator,
  });

  @override
  BodyBuilder _createBodyBuilderForField(
    SourceLibraryBuilder libraryBuilder,
    BodyBuilderContext bodyBuilderContext,
    LookupScope enclosingScope,
    TypeInferrer typeInferrer,
    Uri uri,
  ) {
    return bodyBuilderCreator.createForField(
      libraryBuilder,
      bodyBuilderContext,
      enclosingScope,
      typeInferrer,
      uri,
    );
  }

  @override
  BodyBuilder _createBodyBuilderForOutlineExpression(
    SourceLibraryBuilder libraryBuilder,
    BodyBuilderContext bodyBuilderContext,
    LookupScope scope,
    Uri fileUri, {
    LocalScope? formalParameterScope,
  }) {
    return bodyBuilderCreator.createForOutlineExpression(
      libraryBuilder,
      bodyBuilderContext,
      scope,
      fileUri,
      formalParameterScope: formalParameterScope,
    );
  }

  @override
  BodyBuilder _createBodyBuilderInternal({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required Uri fileUri,
    required LookupScope scope,
    required LocalScope? formalParameterScope,
    required VariableDeclaration? thisVariable,
    required List<TypeParameter>? thisTypeParameters,
    required TypeInferrer typeInferrer,
    required ConstantContext constantContext,
  }) {
    return bodyBuilderCreator.create(
      libraryBuilder: libraryBuilder,
      context: bodyBuilderContext,
      enclosingScope: scope,
      formalParameterScope: formalParameterScope,
      hierarchy: _classHierarchy,
      coreTypes: _coreTypes,
      thisVariable: thisVariable,
      thisTypeParameters: thisTypeParameters,
      uri: fileUri,
      typeInferrer: typeInferrer,
      constantContext: constantContext,
    );
  }
}
