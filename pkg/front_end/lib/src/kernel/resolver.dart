// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';

import '../base/constant_context.dart' show ConstantContext;
import '../base/local_scope.dart';
import '../base/scope.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../fragment/fragment.dart';
import '../source/offset_map.dart';
import '../source/source_constructor_builder.dart';
import '../source/source_library_builder.dart';
import '../type_inference/inference_visitor.dart'
    show ExpressionEvaluationHelper;
import '../type_inference/type_inference_engine.dart';
import '../type_inference/type_inferrer.dart' show TypeInferrer;
import 'benchmarker.dart' show Benchmarker, BenchmarkSubdivides;
import 'body_builder.dart';
import 'body_builder_context.dart';
import 'internal_ast.dart';

part 'resolver_helpers.dart';

class Resolver {
  final ClassHierarchy _classHierarchy;

  final CoreTypes _coreTypes;

  final TypeInferenceEngineImpl _typeInferenceEngine;

  final Benchmarker? _benchmarker;

  Resolver({
    required ClassHierarchy classHierarchy,
    required CoreTypes coreTypes,
    required TypeInferenceEngineImpl typeInferenceEngine,
    required Benchmarker? benchmarker,
  }) : this._classHierarchy = classHierarchy,
       this._coreTypes = coreTypes,
       _typeInferenceEngine = typeInferenceEngine,
       _benchmarker = benchmarker;

  void buildAnnotations({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required Uri annotationsFileUri,
    required LookupScope scope,
    required Annotatable annotatable,
    required List<Annotation> annotations,
  }) {
    BodyBuilder bodyBuilder = _createBodyBuilderForOutlineExpression(
      libraryBuilder,
      bodyBuilderContext,
      scope,
      annotationsFileUri,
    );
    List<int> indicesOfAnnotationsToBeInferred = [];
    for (Annotation annotation in annotations) {
      Expression expression = bodyBuilder.buildUnfinishedAnnotation(
        atToken: annotation.atToken,
      );
      if (annotation.createFileUriExpression) {
        expression = new FileUriExpression(
          expression,
          annotation.metadataBuilder.fileUri,
        )..fileOffset = annotation.metadataBuilder.atOffset;
      }
      // Record the index of [annotation] in `annotatable.annotations` in order
      // to perform inference only on the new annotations, and to be able to
      // store inferred [Expression] to the corresponding [MetadataBuilder]
      // after inference.
      int annotationIndex = annotation.annotationIndex =
          annotatable.annotations.length;
      indicesOfAnnotationsToBeInferred.add(annotationIndex);
      // It is important for the inference and backlog computations that the
      // annotation is already a child of [parent].
      // TODO(johnniwinther): Is the parent relation still needed?
      annotatable.addAnnotation(expression);
    }
    bodyBuilder.inferUnfinishedAnnotations(
      parent: annotatable,
      annotations: annotatable.annotations,
      indices: indicesOfAnnotationsToBeInferred,
    );
    for (Annotation annotation in annotations) {
      annotation.expression =
          annotatable.annotations[annotation.annotationIndex];
    }
  }

  (Expression, DartType?) buildEnumConstant({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required LookupScope scope,
    required Token? token,
    required List<Expression> enumSyntheticArguments,
    required int enumTypeParameterCount,
    required List<DartType>? typeArguments,
    required MemberBuilder? constructorBuilder,
    required Uri fileUri,
    required int fileOffset,
    required String fullConstructorNameForErrors,
  }) {
    // We need to create a BodyBuilder to solve the following: 1) if
    // the arguments token is provided, we'll use the BodyBuilder to
    // parse them and perform inference, 2) if the type arguments
    // aren't provided, but required, we'll use it to infer them, and
    // 3) in case of erroneous code the constructor invocation should
    // be built via a body builder to detect potential errors.
    BodyBuilder bodyBuilder = _createBodyBuilderForOutlineExpression(
      libraryBuilder,
      bodyBuilderContext,
      scope,
      fileUri,
    );
    return bodyBuilder.buildEnumConstant(
      token: token,
      enumSyntheticArguments: enumSyntheticArguments,
      enumTypeParameterCount: enumTypeParameterCount,
      typeArguments: typeArguments,
      constructorBuilder: constructorBuilder,
      fileOffset: fileOffset,
      fullConstructorNameForErrors: fullConstructorNameForErrors,
    );
  }

  // TODO(johnniwinther): Merge this with [buildFieldInitializer2].
  DartType buildFieldInitializer1({
    required SourceLibraryBuilder libraryBuilder,
    required Uri fileUri,
    required LookupScope scope,
    required InterfaceType? enclosingClassThisType,
    required InferenceDataForTesting? inferenceDataForTesting,
    required BodyBuilderContext bodyBuilderContext,
    required Token startToken,
    required bool isConst,
    required bool isLate,
  }) {
    TypeInferrer typeInferrer = _typeInferenceEngine.createTopLevelTypeInferrer(
      fileUri,
      enclosingClassThisType,
      libraryBuilder,
      scope,
      inferenceDataForTesting,
    );
    BodyBuilder bodyBuilder = _createBodyBuilderForField(
      libraryBuilder,
      bodyBuilderContext,
      scope,
      typeInferrer,
      fileUri,
    );
    ConstantContext constantContext = isConst
        ? ConstantContext.inferred
        : ConstantContext.none;
    Expression initializer = bodyBuilder.buildFieldInitializerUnfinished(
      startToken: startToken,
      constantContext: constantContext,
      isLate: isLate,
    );
    DartType inferredType = typeInferrer.inferImplicitFieldType(
      fileUri: fileUri,
      constantContext: constantContext,
      initializer: initializer,
    );
    return inferredType;
  }

  Expression buildFieldInitializer2({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required Uri fileUri,
    required LookupScope scope,
    required bool isConst,
    required DartType fieldType,
    required Token startToken,
  }) {
    BodyBuilder bodyBuilder = _createBodyBuilderForOutlineExpression(
      libraryBuilder,
      bodyBuilderContext,
      scope,
      fileUri,
    );
    return bodyBuilder.buildFieldInitializer2(
      startToken: startToken,
      isConst: isConst,
      fileUri: fileUri,
      declaredFieldType: fieldType,
    );
  }

  void buildFields({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required Uri fileUri,
    required OffsetMap offsetMap,
    required LookupScope scope,
    required InferenceDataForTesting? inferenceDataForTesting,
    required Token startToken,
    required Token? metadata,
    required bool isTopLevel,
  }) {
    // TODO(paulberry): don't re-parse the field if we've already parsed it
    // for type inference.
    BodyBuilder bodyBuilder = _createBodyBuilder(
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      fileUri: fileUri,
      scope: scope,
      inferenceDataForTesting: inferenceDataForTesting,
    );
    bodyBuilder.buildFields(
      offsetMap: offsetMap,
      startToken: startToken,
      metadata: metadata,
      isTopLevel: isTopLevel,
    );
  }

  void buildFunctionBody({
    required SourceLibraryBuilder libraryBuilder,
    required FunctionBodyBuildingContext functionBodyBuildingContext,
    required Uri fileUri,
    required Token startToken,
    required Token? metadata,
  }) {
    _benchmarker
    // Coverage-ignore(suite): Not run.
    ?.beginSubdivide(BenchmarkSubdivides.resolver_buildFunctionBody);
    BodyBuilder bodyBuilder = _createBodyBuilderForFunctionBody(
      libraryBuilder: libraryBuilder,
      fileUri: fileUri,
      functionBodyBuildingContext: functionBodyBuildingContext,
    );

    bodyBuilder.buildFunctionBody(
      startToken: startToken,
      metadata: metadata,
      kind: functionBodyBuildingContext.memberKind,
    );
    _benchmarker
        // Coverage-ignore(suite): Not run.
        ?.endSubdivide();
  }

  void buildInitializers({
    required SourceLibraryBuilder libraryBuilder,
    required SourceConstructorBuilder constructorBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required LookupScope typeParameterScope,
    required LocalScope? formalParameterScope,
    required Uri fileUri,
    required Token beginInitializers,
    required bool isConst,
  }) {
    BodyBuilder bodyBuilder = _createBodyBuilderForOutlineExpression(
      libraryBuilder,
      bodyBuilderContext,
      typeParameterScope,
      fileUri,
      formalParameterScope: formalParameterScope,
    );
    bodyBuilder.buildInitializers(
      beginInitializers: beginInitializers,
      constructorBuilder: constructorBuilder,
      isConst: isConst,
    );
  }

  List<Initializer>? buildInitializersUnfinished({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required LookupScope typeParameterScope,
    required Uri fileUri,
    required Token beginInitializers,
    required bool isConst,
  }) {
    BodyBuilder bodyBuilder = _createBodyBuilderForOutlineExpression(
      libraryBuilder,
      bodyBuilderContext,
      typeParameterScope,
      fileUri,
    );
    return bodyBuilder.buildInitializersUnfinished(
      beginInitializers: beginInitializers,
      isConst: isConst,
    );
  }

  List<Expression>? buildMetadata({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required Uri fileUri,
    required LookupScope scope,
    required Token metadata,
    required Annotatable? parent,
  }) {
    BodyBuilder bodyBuilder = _createBodyBuilder(
      libraryBuilder: libraryBuilder,
      fileUri: fileUri,
      bodyBuilderContext: bodyBuilderContext,
      scope: scope,
    );
    return bodyBuilder.buildMetadataList(metadata: metadata, parent: parent);
  }

  Expression buildParameterInitializer({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required LookupScope scope,
    required Uri fileUri,
    required Token initializerToken,
    required DartType declaredType,
    required bool hasDeclaredInitializer,
  }) {
    BodyBuilder bodyBuilder = _createBodyBuilderForOutlineExpression(
      libraryBuilder,
      bodyBuilderContext,
      scope,
      fileUri,
    );
    return bodyBuilder.buildParameterInitializer(
      initializerToken: initializerToken,
      declaredType: declaredType,
      hasDeclaredInitializer: hasDeclaredInitializer,
    );
  }

  void buildPrimaryConstructor({
    required SourceLibraryBuilder libraryBuilder,
    required FunctionBodyBuildingContext functionBodyBuildingContext,
    required Uri fileUri,
    required Token startToken,
  }) {
    _benchmarker
    // Coverage-ignore(suite): Not run.
    ?.beginSubdivide(BenchmarkSubdivides.diet_listener_buildPrimaryConstructor);
    BodyBuilder bodyBuilder = _createBodyBuilderForFunctionBody(
      libraryBuilder: libraryBuilder,
      fileUri: fileUri,
      functionBodyBuildingContext: functionBodyBuildingContext,
    );
    bodyBuilder.buildPrimaryConstructor(startToken: startToken);
    _benchmarker
        // Coverage-ignore(suite): Not run.
        ?.endSubdivide();
  }

  void buildRedirectingFactoryMethod({
    required SourceLibraryBuilder libraryBuilder,
    required FunctionBodyBuildingContext functionBodyBuildingContext,
    required Uri fileUri,
    required Token token,
    required Token? metadata,
  }) {
    _benchmarker
    // Coverage-ignore(suite): Not run.
    ?.beginSubdivide(
      BenchmarkSubdivides.diet_listener_buildRedirectingFactoryMethod,
    );
    BodyBuilder bodyBuilder = _createBodyBuilderForFunctionBody(
      libraryBuilder: libraryBuilder,
      fileUri: fileUri,
      functionBodyBuildingContext: functionBodyBuildingContext,
    );
    bodyBuilder.buildRedirectingFactoryMethod(token: token, metadata: metadata);
    _benchmarker
        // Coverage-ignore(suite): Not run.
        ?.endSubdivide();
  }

  // Coverage-ignore(suite): Not run.
  Expression buildSingleExpression({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required Uri fileUri,
    required LookupScope scope,
    required Token token,
    required Procedure procedure,
    required List<VariableDeclarationImpl> extraKnownVariables,
    required ExpressionEvaluationHelper expressionEvaluationHelper,
    required VariableDeclaration? extensionThis,
  }) {
    BodyBuilder bodyBuilder = _createBodyBuilder(
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      fileUri: fileUri,
      scope: scope,
      thisVariable: extensionThis,
    );
    return bodyBuilder.buildSingleExpression(
      token: token,
      procedure: procedure,
      extraKnownVariables: extraKnownVariables,
      expressionEvaluationHelper: expressionEvaluationHelper,
    );
  }

  BodyBuilder _createBodyBuilder({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required Uri fileUri,
    required LookupScope scope,
    VariableDeclaration? thisVariable,
    List<TypeParameter>? thisTypeParameters,
    LocalScope? formalParameterScope,
    InferenceDataForTesting? inferenceDataForTesting,
  }) {
    _benchmarker
    // Coverage-ignore(suite): Not run.
    ?.beginSubdivide(BenchmarkSubdivides.resolver_createBodyBuilder);
    // Note: we set thisType regardless of whether we are building a static
    // member, since that provides better error recovery.
    // TODO(johnniwinther): Provide a dummy this on static extension methods
    // for better error recovery?
    TypeInferrer typeInferrer = _typeInferenceEngine.createLocalTypeInferrer(
      fileUri,
      bodyBuilderContext.thisType,
      libraryBuilder,
      scope,
      inferenceDataForTesting,
    );
    ConstantContext constantContext = bodyBuilderContext.constantContext;
    BodyBuilder result = _createBodyBuilderInternal(
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      fileUri: fileUri,
      scope: scope,
      formalParameterScope: formalParameterScope,
      thisVariable: thisVariable,
      thisTypeParameters: thisTypeParameters,
      typeInferrer: typeInferrer,
      constantContext: constantContext,
    );
    _benchmarker
        // Coverage-ignore(suite): Not run.
        ?.endSubdivide();
    return result;
  }

  BodyBuilder _createBodyBuilderForField(
    SourceLibraryBuilder libraryBuilder,
    BodyBuilderContext bodyBuilderContext,
    LookupScope enclosingScope,
    TypeInferrer typeInferrer,
    Uri uri,
  ) {
    return new BodyBuilderImpl.forField(
      libraryBuilder,
      bodyBuilderContext,
      enclosingScope,
      typeInferrer,
      uri,
    );
  }

  BodyBuilder _createBodyBuilderForFunctionBody({
    required SourceLibraryBuilder libraryBuilder,
    required Uri fileUri,
    required FunctionBodyBuildingContext functionBodyBuildingContext,
  }) {
    final LookupScope typeParameterScope =
        functionBodyBuildingContext.typeParameterScope;
    final LocalScope formalParameterScope = functionBodyBuildingContext
        .computeFormalParameterScope(typeParameterScope);
    return _createBodyBuilder(
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: functionBodyBuildingContext
          .createBodyBuilderContext(),
      fileUri: fileUri,
      scope: typeParameterScope,
      thisVariable: functionBodyBuildingContext.thisVariable,
      thisTypeParameters: functionBodyBuildingContext.thisTypeParameters,
      formalParameterScope: formalParameterScope,
      inferenceDataForTesting:
          functionBodyBuildingContext.inferenceDataForTesting,
    );
  }

  BodyBuilder _createBodyBuilderForOutlineExpression(
    SourceLibraryBuilder libraryBuilder,
    BodyBuilderContext bodyBuilderContext,
    LookupScope scope,
    Uri fileUri, {
    LocalScope? formalParameterScope,
  }) {
    return new BodyBuilderImpl.forOutlineExpression(
      libraryBuilder,
      bodyBuilderContext,
      scope,
      fileUri,
      formalParameterScope: formalParameterScope,
    );
  }

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
    return new BodyBuilderImpl(
      libraryBuilder: libraryBuilder,
      context: bodyBuilderContext,
      enclosingScope: new EnclosingLocalScope(scope),
      formalParameterScope: formalParameterScope,
      hierarchy: _classHierarchy,
      coreTypes: _coreTypes,
      thisVariable: thisVariable,
      thisTypeParameters: thisTypeParameters,
      uri: fileUri,
      typeInferrer: typeInferrer,
    )..constantContext = constantContext;
  }
}
