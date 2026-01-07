// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show FormalParameterKind;
import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:_fe_analyzer_shared/src/type_inference/assigned_variables.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/clone.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_environment.dart';

import '../api_prototype/experimental_flags.dart';
import '../api_prototype/lowering_predicates.dart';
import '../base/compiler_context.dart';
import '../base/constant_context.dart' show ConstantContext;
import '../base/crash.dart';
import '../base/extension_scope.dart';
import '../base/identifiers.dart';
import '../base/local_scope.dart';
import '../base/lookup_result.dart';
import '../base/messages.dart';
import '../base/modifiers.dart';
import '../base/problems.dart';
import '../base/scope.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/type_builder.dart';
import '../dill/dill_type_parameter_builder.dart';
import '../fragment/fragment.dart';
import '../source/check_helper.dart';
import '../source/offset_map.dart';
import '../source/source_constructor_builder.dart';
import '../source/source_library_builder.dart';
import '../type_inference/external_ast_helper.dart';
import '../type_inference/inference_results.dart';
import '../type_inference/inference_visitor.dart'
    show ExpressionEvaluationHelper;
import '../type_inference/type_inference_engine.dart';
import '../type_inference/type_inferrer.dart'
    show TypeInferrer, InferredFunctionBody;
import '../type_inference/type_schema.dart';
import 'benchmarker.dart' show Benchmarker, BenchmarkSubdivides;
import 'body_builder.dart';
import 'body_builder_context.dart';
import 'forest.dart';
import 'internal_ast.dart';

part 'resolver_helpers.dart';

class Resolver {
  final ClassHierarchy _classHierarchy;

  final CoreTypes _coreTypes;

  final TypeInferenceEngineImpl _typeInferenceEngine;

  final Benchmarker? _benchmarker;

  late CloneVisitorNotMembers _simpleCloner = new CloneVisitorNotMembers();

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
    required ExtensionScope extensionScope,
    required LookupScope scope,
    required Annotatable annotatable,
    required List<Annotation> annotations,
  }) {
    _ResolverContext context = new _ResolverContext(
      typeInferenceEngine: _typeInferenceEngine,
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      extensionScope: extensionScope,
      fileUri: annotationsFileUri,
    );
    // TODO(johnniwinther): Should this be `ConstantContext.required`?
    ConstantContext constantContext = ConstantContext.none;
    BodyBuilder bodyBuilder = _createBodyBuilder(
      context: context,
      bodyBuilderContext: bodyBuilderContext,
      scope: scope,
      constantContext: constantContext,
    );
    List<int> indicesOfAnnotationsToBeInferred = [];

    for (Annotation annotation in annotations) {
      Expression expression = bodyBuilder.buildAnnotation(
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
    context.inferSingleTargetAnnotation(
      singleTarget: new SingleTargetAnnotations(
        annotatable,
        indicesOfAnnotationsToBeInferred,
      ),
    );
    // TODO(johnniwinther): We need to process annotations within annotations.
    context.performBacklog(null);

    for (Annotation annotation in annotations) {
      annotation.expression =
          annotatable.annotations[annotation.annotationIndex];
    }
  }

  (Expression, DartType?) buildEnumConstant({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ExtensionScope extensionScope,
    required LookupScope scope,
    required Token? token,
    required List<Argument> enumSyntheticArguments,
    required int enumTypeParameterCount,
    required TypeArguments? typeArguments,
    required MemberBuilder? constructorBuilder,
    required Uri fileUri,
    required int fileOffset,
    required String fullConstructorNameForErrors,
  }) {
    _ResolverContext context = new _ResolverContext(
      typeInferenceEngine: _typeInferenceEngine,
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      extensionScope: extensionScope,
      fileUri: fileUri,
    );
    CompilerContext compilerContext = libraryBuilder.loader.target.context;
    ProblemReporting problemReporting = libraryBuilder;
    LibraryFeatures libraryFeatures = libraryBuilder.libraryFeatures;

    ConstantContext constantContext = ConstantContext.inferred;

    // We need to create a BodyBuilder to solve the following: 1) if
    // the arguments token is provided, we'll use the BodyBuilder to
    // parse them and perform inference, 2) if the type arguments
    // aren't provided, but required, we'll use it to infer them, and
    // 3) in case of erroneous code the constructor invocation should
    // be built via a body builder to detect potential errors.
    BodyBuilder bodyBuilder = _createBodyBuilder(
      context: context,
      bodyBuilderContext: bodyBuilderContext,
      scope: scope,
      constantContext: constantContext,
    );
    BuildEnumConstantResult? result;
    ActualArguments arguments;
    if (token != null) {
      result = bodyBuilder.buildEnumConstant(token: token);
      arguments = result.arguments;
      arguments.prependArguments(
        enumSyntheticArguments,
        positionalCount: enumSyntheticArguments.length,
      );
    } else {
      arguments = new ActualArguments(
        argumentList: enumSyntheticArguments,
        hasNamedBeforePositional: false,
        positionalCount: enumSyntheticArguments.length,
      );
    }
    Expression initializer;
    DartType? fieldType;
    if (constructorBuilder == null ||
        constructorBuilder is! SourceConstructorBuilder) {
      initializer = _buildUnresolvedError(
        compilerContext: compilerContext,
        problemReporting: problemReporting,
        name: fullConstructorNameForErrors,
        fileUri: fileUri,
        fileOffset: fileOffset,
      );
    } else {
      initializer = _buildConstructorInvocation(
        compilerContext: compilerContext,
        problemReporting: problemReporting,
        libraryFeatures: libraryFeatures,
        typeEnvironment: context.typeEnvironment,
        target: constructorBuilder.invokeTarget,
        typeArguments: typeArguments,
        arguments: arguments,
        fileUri: fileUri,
        fileOffset: fileOffset,
        hasInferredTypeArguments: false,
      );
      ExpressionInferenceResult inferenceResult = context.typeInferrer
          .inferFieldInitializer(
            fileUri: fileUri,
            declaredType: const UnknownType(),
            initializer: initializer,
          );
      initializer = inferenceResult.expression;
      fieldType = inferenceResult.inferredType;
    }
    context.performBacklog(result?.annotations);

    return (initializer, fieldType);
  }

  ExpressionInferenceResult buildFieldInitializer({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required Uri fileUri,
    required ExtensionScope extensionScope,
    required LookupScope scope,
    required bool isLate,
    DartType? declaredFieldType,
    required Token startToken,
    required InferenceDataForTesting? inferenceDataForTesting,
  }) {
    _ResolverContext context = new _ResolverContext(
      typeInferenceEngine: _typeInferenceEngine,
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      extensionScope: extensionScope,
      fileUri: fileUri,
    );
    ConstantContext constantContext = bodyBuilderContext.constantContext;
    BodyBuilder bodyBuilder = _createBodyBuilder(
      context: context,
      bodyBuilderContext: bodyBuilderContext,
      scope: scope,
      constantContext: constantContext,
    );
    BuildFieldInitializerResult result = bodyBuilder.buildFieldInitializer(
      startToken: startToken,
      isLate: isLate,
    );
    ExpressionInferenceResult expressionInferenceResult = context.typeInferrer
        .inferFieldInitializer(
          fileUri: fileUri,
          declaredType: declaredFieldType,
          initializer: result.initializer,
        );
    context.performBacklog(result.annotations);
    return expressionInferenceResult;
  }

  void buildFields({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required Uri fileUri,
    required OffsetMap offsetMap,
    required ExtensionScope extensionScope,
    required LookupScope scope,
    required InferenceDataForTesting? inferenceDataForTesting,
    required Token startToken,
    required Token? metadata,
    required bool isTopLevel,
  }) {
    // TODO(paulberry): don't re-parse the field if we've already parsed it
    // for type inference.
    _ResolverContext context = new _ResolverContext(
      typeInferenceEngine: _typeInferenceEngine,
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      extensionScope: extensionScope,
      fileUri: fileUri,
      inferenceDataForTesting: inferenceDataForTesting,
    );
    ConstantContext constantContext = bodyBuilderContext.constantContext;
    BodyBuilder bodyBuilder = _createBodyBuilder(
      context: context,
      bodyBuilderContext: bodyBuilderContext,
      scope: scope,
      constantContext: constantContext,
    );
    BuildFieldsResult result = bodyBuilder.buildFields(
      startToken: startToken,
      metadata: metadata,
      isTopLevel: isTopLevel,
    );
    for (MapEntry<Identifier, Expression?> entry
        in result.fieldInitializers.entries) {
      Identifier identifier = entry.key;
      Expression? initializer = entry.value;
      FieldFragment fieldFragment = offsetMap.lookupField(identifier);
      fieldFragment.declaration.buildFieldInitializer(
        typeInferrer: context.typeInferrer,
        coreTypes: _coreTypes,
        fileUri: fileUri,
        initializer: initializer,
      );
    }
    context.performBacklog(result.annotations);
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

    CompilerContext compilerContext = libraryBuilder.loader.target.context;
    ProblemReporting problemReporting = libraryBuilder;
    LibraryFeatures libraryFeatures = libraryBuilder.libraryFeatures;
    ExtensionScope extensionScope = functionBodyBuildingContext.extensionScope;
    LookupScope typeParameterScope =
        functionBodyBuildingContext.typeParameterScope;
    LocalScope formalParameterScope =
        functionBodyBuildingContext.formalParameterScope;
    BodyBuilderContext bodyBuilderContext = functionBodyBuildingContext
        .createBodyBuilderContext();

    _ResolverContext context = new _ResolverContext(
      typeInferenceEngine: _typeInferenceEngine,
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      extensionScope: extensionScope,
      fileUri: fileUri,
      inferenceDataForTesting:
          functionBodyBuildingContext.inferenceDataForTesting,
    );
    ConstantContext constantContext = bodyBuilderContext.constantContext;
    BodyBuilder bodyBuilder = _createBodyBuilder(
      context: context,
      bodyBuilderContext: bodyBuilderContext,
      scope: typeParameterScope,
      thisVariable: functionBodyBuildingContext.thisVariable,
      thisTypeParameters: functionBodyBuildingContext.thisTypeParameters,
      formalParameterScope: formalParameterScope,
      constantContext: constantContext,
    );
    Token token = startToken;
    try {
      BuildFunctionBodyResult result = bodyBuilder.buildFunctionBody(
        startToken: startToken,
        metadata: metadata,
        kind: functionBodyBuildingContext.memberKind,
      );
      _finishFunction(
        context: context,
        compilerContext: compilerContext,
        problemReporting: problemReporting,
        libraryBuilder: libraryBuilder,
        libraryFeatures: libraryFeatures,
        formals: result.formals,
        asyncModifier: result.asyncModifier,
        body: result.body,
        fileUri: fileUri,
        bodyBuilderContext: bodyBuilderContext,
        thisVariable: functionBodyBuildingContext.thisVariable,
        initializers: result.initializers,
        constantContext: constantContext,
        needsImplicitSuperInitializer: result.needsImplicitSuperInitializer,
      );
      context.performBacklog(result.annotations);
    }
    // Coverage-ignore(suite): Not run.
    on DebugAbort {
      rethrow;
    } catch (e, s) {
      throw new Crash(fileUri, token.charOffset, e, s);
    }
    _benchmarker
        // Coverage-ignore(suite): Not run.
        ?.endSubdivide();
  }

  void buildInitializers({
    required SourceLibraryBuilder libraryBuilder,
    required SourceConstructorBuilder constructorBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ExtensionScope extensionScope,
    required LookupScope typeParameterScope,
    required LocalScope? formalParameterScope,
    required Uri fileUri,
    required Token beginInitializers,
    required bool isConst,
  }) {
    _ResolverContext context = new _ResolverContext(
      typeInferenceEngine: _typeInferenceEngine,
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      extensionScope: extensionScope,
      fileUri: fileUri,
    );

    CompilerContext compilerContext = libraryBuilder.loader.target.context;
    ProblemReporting problemReporting = libraryBuilder;
    LibraryFeatures libraryFeatures = libraryBuilder.libraryFeatures;
    ConstantContext constantContext = isConst
        ? ConstantContext.required
        : ConstantContext.none;
    BodyBuilder bodyBuilder = _createBodyBuilder(
      context: context,
      bodyBuilderContext: bodyBuilderContext,
      scope: typeParameterScope,
      constantContext: constantContext,
      formalParameterScope: formalParameterScope,
    );
    constructorBuilder.inferFormalTypes(_classHierarchy);
    BuildInitializersResult result = bodyBuilder.buildInitializers(
      beginInitializers: beginInitializers,
    );
    List<Initializer> initializers = result.initializers;
    bool needsImplicitSuperInitializer = result.needsImplicitSuperInitializer;
    if (isConst) {
      List<FormalParameterBuilder>? formals = bodyBuilderContext.formals;
      _SuperParameterArguments? superParameterArguments =
          _createSuperParameterArguments(
            assignedVariables: context.typeInferrer.assignedVariables,
            formals: formals,
          );
      _declareFormals(
        typeInferrer: context.typeInferrer,
        bodyBuilderContext: bodyBuilderContext,
        thisVariable: null,
      );
      _finishConstructor(
        context: context,
        compilerContext: compilerContext,
        problemReporting: problemReporting,
        libraryBuilder: libraryBuilder,
        libraryFeatures: libraryFeatures,
        bodyBuilderContext: bodyBuilderContext,
        asyncModifier: AsyncMarker.Sync,
        body: null,
        superParameterArguments: superParameterArguments,
        fileUri: fileUri,
        needsImplicitSuperInitializer: needsImplicitSuperInitializer,
        constantContext: constantContext,
        initializers: initializers,
      );
    }
    context.performBacklog(result.annotations);
  }

  List<Initializer> buildInitializersUnfinished({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ExtensionScope extensionScope,
    required LookupScope typeParameterScope,
    required Uri fileUri,
    required Token beginInitializers,
    required bool isConst,
  }) {
    _ResolverContext context = new _ResolverContext(
      typeInferenceEngine: _typeInferenceEngine,
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      extensionScope: extensionScope,
      fileUri: fileUri,
    );
    ConstantContext constantContext = isConst
        ? ConstantContext.required
        : ConstantContext.none;
    BodyBuilder bodyBuilder = _createBodyBuilder(
      context: context,
      bodyBuilderContext: bodyBuilderContext,
      scope: typeParameterScope,
      constantContext: constantContext,
    );
    return bodyBuilder.buildInitializersUnfinished(
      beginInitializers: beginInitializers,
    );
  }

  List<Expression>? buildMetadata({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required Uri fileUri,
    required ExtensionScope extensionScope,
    required LookupScope scope,
    required Token metadata,
    required Annotatable annotatable,
  }) {
    _ResolverContext context = new _ResolverContext(
      typeInferenceEngine: _typeInferenceEngine,
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      extensionScope: extensionScope,
      fileUri: fileUri,
    );
    ConstantContext constantContext = bodyBuilderContext.constantContext;
    BodyBuilder bodyBuilder = _createBodyBuilder(
      context: context,
      bodyBuilderContext: bodyBuilderContext,
      scope: scope,
      constantContext: constantContext,
    );
    BuildMetadataListResult result = bodyBuilder.buildMetadataList(
      metadata: metadata,
    );

    // The invocation of [resolveRedirectingFactoryTargets] below may change the
    // root nodes of the annotation expressions.  We need to have a parent of
    // the annotation nodes before the resolution is performed, to collect and
    // return them later.  If [parent] is not provided, [temporaryParent] is
    // used.
    // TODO(johnniwinther): Do we still need this.

    for (Expression expression in result.expressions) {
      annotatable.addAnnotation(expression);
    }
    context.inferSingleTargetAnnotation(
      singleTarget: new SingleTargetAnnotations(annotatable),
    );
    List<Expression> expressions = annotatable.annotations;
    context.performBacklog(result.annotations);
    return expressions;
  }

  Expression buildParameterInitializer({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ExtensionScope extensionScope,
    required LookupScope scope,
    required Uri fileUri,
    required Token initializerToken,
    required DartType declaredType,
    required bool hasDeclaredInitializer,
  }) {
    _ResolverContext context = new _ResolverContext(
      typeInferenceEngine: _typeInferenceEngine,
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      extensionScope: extensionScope,
      fileUri: fileUri,
    );
    ConstantContext constantContext = ConstantContext.required;
    BodyBuilder bodyBuilder = _createBodyBuilder(
      context: context,
      bodyBuilderContext: bodyBuilderContext,
      scope: scope,
      constantContext: constantContext,
    );
    BuildParameterInitializerResult result = bodyBuilder
        .buildParameterInitializer(initializerToken: initializerToken);
    Expression initializer = context.typeInferrer.inferParameterInitializer(
      fileUri: fileUri,
      initializer: result.initializer,
      declaredType: declaredType,
      hasDeclaredInitializer: hasDeclaredInitializer,
    );
    context.performBacklog(result.annotations);
    return initializer;
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

    CompilerContext compilerContext = libraryBuilder.loader.target.context;
    ProblemReporting problemReporting = libraryBuilder;
    LibraryFeatures libraryFeatures = libraryBuilder.libraryFeatures;
    ExtensionScope extensionScope = functionBodyBuildingContext.extensionScope;
    LookupScope typeParameterScope =
        functionBodyBuildingContext.typeParameterScope;
    LocalScope formalParameterScope =
        functionBodyBuildingContext.formalParameterScope;
    BodyBuilderContext bodyBuilderContext = functionBodyBuildingContext
        .createBodyBuilderContext();
    _ResolverContext context = new _ResolverContext(
      typeInferenceEngine: _typeInferenceEngine,
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      extensionScope: extensionScope,
      fileUri: fileUri,
      inferenceDataForTesting:
          functionBodyBuildingContext.inferenceDataForTesting,
    );
    ConstantContext constantContext = bodyBuilderContext.constantContext;
    BodyBuilder bodyBuilder = _createBodyBuilder(
      context: context,
      bodyBuilderContext: bodyBuilderContext,
      scope: typeParameterScope,
      thisVariable: functionBodyBuildingContext.thisVariable,
      thisTypeParameters: functionBodyBuildingContext.thisTypeParameters,
      formalParameterScope: formalParameterScope,
      constantContext: constantContext,
    );
    try {
      BuildPrimaryConstructorResult result = bodyBuilder
          .buildPrimaryConstructor(startToken: startToken);
      FormalParameters? formals = result.formals;
      _finishFunction(
        context: context,
        compilerContext: compilerContext,
        problemReporting: problemReporting,
        libraryBuilder: libraryBuilder,
        libraryFeatures: libraryFeatures,
        formals: formals,
        asyncModifier: AsyncMarker.Sync,
        body: null,
        fileUri: fileUri,
        bodyBuilderContext: bodyBuilderContext,
        thisVariable: functionBodyBuildingContext.thisVariable,
        initializers: result.initializers,
        constantContext: constantContext,
        needsImplicitSuperInitializer: bodyBuilderContext
            .needsImplicitSuperInitializer(_coreTypes),
      );
      context.performBacklog(result.annotations);
    }
    // Coverage-ignore(suite): Not run.
    on DebugAbort {
      rethrow;
    } catch (e, s) {
      throw new Crash(fileUri, startToken.charOffset, e, s);
    }
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
    ExtensionScope extensionScope = functionBodyBuildingContext.extensionScope;
    LookupScope typeParameterScope =
        functionBodyBuildingContext.typeParameterScope;
    LocalScope formalParameterScope =
        functionBodyBuildingContext.formalParameterScope;
    BodyBuilderContext bodyBuilderContext = functionBodyBuildingContext
        .createBodyBuilderContext();
    _ResolverContext context = new _ResolverContext(
      typeInferenceEngine: _typeInferenceEngine,
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      extensionScope: extensionScope,
      fileUri: fileUri,
      inferenceDataForTesting:
          functionBodyBuildingContext.inferenceDataForTesting,
    );
    ConstantContext constantContext = bodyBuilderContext.constantContext;
    BodyBuilder bodyBuilder = _createBodyBuilder(
      context: context,
      bodyBuilderContext: bodyBuilderContext,
      scope: typeParameterScope,
      thisVariable: functionBodyBuildingContext.thisVariable,
      thisTypeParameters: functionBodyBuildingContext.thisTypeParameters,
      formalParameterScope: formalParameterScope,
      constantContext: constantContext,
    );
    BuildRedirectingFactoryMethodResult result = bodyBuilder
        .buildRedirectingFactoryMethod(token: token, metadata: metadata);
    context.performBacklog(result.annotations);
    _benchmarker
        // Coverage-ignore(suite): Not run.
        ?.endSubdivide();
  }

  // Coverage-ignore(suite): Not run.
  Expression buildSingleExpression({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required Uri fileUri,
    required ExtensionScope extensionScope,
    required LookupScope scope,
    required Token token,
    required Procedure procedure,
    required List<ExpressionVariable> extraKnownVariables,
    required ExpressionEvaluationHelper expressionEvaluationHelper,
    required VariableDeclaration? extensionThis,
  }) {
    _ResolverContext context = new _ResolverContext(
      typeInferenceEngine: _typeInferenceEngine,
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      extensionScope: extensionScope,
      fileUri: fileUri,
    );

    LibraryFeatures libraryFeatures = libraryBuilder.libraryFeatures;
    ConstantContext constantContext = bodyBuilderContext.constantContext;
    BodyBuilder bodyBuilder = _createBodyBuilder(
      context: context,
      bodyBuilderContext: bodyBuilderContext,
      scope: scope,
      thisVariable: extensionThis,
      constantContext: constantContext,
    );
    int fileOffset = token.charOffset;

    FunctionNode parameters = procedure.function;

    List<NominalParameterBuilder>? typeParameterBuilders;
    for (TypeParameter typeParameter in parameters.typeParameters) {
      typeParameterBuilders ??= <NominalParameterBuilder>[];
      typeParameterBuilders.add(
        new DillNominalParameterBuilder(
          typeParameter,
          loader: libraryBuilder.loader,
        ),
      );
    }
    int wildcardVariableIndex = 0;
    List<FormalParameterBuilder>? formals =
        parameters.positionalParameters.length == 0
        ? null
        : new List<FormalParameterBuilder>.generate(
            parameters.positionalParameters.length,
            (int i) {
              VariableDeclaration formal = parameters.positionalParameters[i];
              String formalName = formal.name!;
              bool isWildcard =
                  libraryFeatures.wildcardVariables.isEnabled &&
                  formalName == '_';
              if (isWildcard) {
                formalName = createWildcardFormalParameterName(
                  wildcardVariableIndex,
                );
                wildcardVariableIndex++;
              }
              return new FormalParameterBuilder(
                FormalParameterKind.requiredPositional,
                Modifiers.empty,
                const ImplicitTypeBuilder(),
                formalName,
                formal.fileOffset,
                fileUri: fileUri,
                hasImmediatelyDeclaredInitializer: false,
                isWildcard: isWildcard,
              )..variable = formal;
            },
            growable: false,
          );

    BuildSingleExpressionResult result = bodyBuilder.buildSingleExpression(
      token: token,
      extraKnownVariables: extraKnownVariables,
      fileOffset: fileOffset,
      typeParameterBuilders: typeParameterBuilders,
      formals: formals,
    );
    Expression expression = result.expression;
    if (formals != null) {
      for (int i = 0; i < formals.length; i++) {
        VariableDeclaration variable = formals[i].variable!;
        context.typeInferrer.flowAnalysis.declare(
          variable,
          new SharedTypeView(variable.type),
          initialized: true,
        );
      }
    }
    for (ExpressionVariable extraVariable in extraKnownVariables) {
      context.typeInferrer.flowAnalysis.declare(
        extraVariable,
        new SharedTypeView(extraVariable.type),
        initialized: true,
      );
    }

    ReturnStatementImpl fakeReturn = new ReturnStatementImpl(true, expression);

    InferredFunctionBody inferredFunctionBody = context.typeInferrer
        .inferFunctionBody(
          fileUri: fileUri,
          fileOffset: fileOffset,
          returnType: const DynamicType(),
          asyncMarker: AsyncMarker.Sync,
          body: fakeReturn,
          expressionEvaluationHelper: expressionEvaluationHelper,
        );
    assert(
      fakeReturn == inferredFunctionBody.body,
      "Previously implicit assumption about inferFunctionBody "
      "not returning anything different.",
    );
    context.performBacklog(result.annotations);
    return fakeReturn.expression!;
  }

  Expression _buildConstructorInvocation({
    required CompilerContext compilerContext,
    required ProblemReporting problemReporting,
    required LibraryFeatures libraryFeatures,
    required TypeEnvironment typeEnvironment,
    required Member target,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    required Uri fileUri,
    required int fileOffset,
    required bool hasInferredTypeArguments,
  }) {
    Expression? result = problemReporting.checkStaticArguments(
      compilerContext: compilerContext,
      target: target,
      explicitTypeArguments: typeArguments,
      arguments: arguments,
      fileOffset: fileOffset,
      fileUri: fileUri,
    );
    if (result != null) {
      return result;
    }

    if (target is Constructor) {
      if (!target.isConst) {
        return problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: codeNonConstConstructor,
          fileUri: fileUri,
          fileOffset: fileOffset,
          length: noLength,
        );
      }
      Expression node = new InternalConstructorInvocation(
        target,
        typeArguments,
        arguments,
        isConst: true,
      )..fileOffset = fileOffset;
      if (typeArguments != null) {
        problemReporting.checkBoundsInConstructorInvocation(
          libraryFeatures: libraryFeatures,
          constructor: target,
          explicitOrInferredTypeArguments: typeArguments.types,
          typeEnvironment: typeEnvironment,
          fileUri: fileUri,
          fileOffset: fileOffset,
          hasInferredTypeArguments: hasInferredTypeArguments,
        );
      }
      return node;
    } else {
      // Coverage-ignore-block(suite): Not run.
      Procedure procedure = target as Procedure;
      if (!procedure.isConst) {
        return problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: codeNonConstConstructor,
          fileUri: fileUri,
          fileOffset: fileOffset,
          length: noLength,
        );
      }
      FactoryConstructorInvocation node = new FactoryConstructorInvocation(
        target,
        typeArguments,
        arguments,
        isConst: true,
      )..fileOffset = fileOffset;
      if (typeArguments != null) {
        problemReporting.checkBoundsInFactoryInvocation(
          libraryFeatures: libraryFeatures,
          factory: target,
          explicitOrInferredTypeArguments: typeArguments.types,
          typeEnvironment: typeEnvironment,
          fileUri: fileUri,
          fileOffset: fileOffset,
          hasInferredTypeArguments: hasInferredTypeArguments,
        );
      }
      return node;
    }
  }

  Expression _buildUnresolvedError({
    required CompilerContext compilerContext,
    required ProblemReporting problemReporting,
    required String name,
    required Uri fileUri,
    required int fileOffset,
  }) {
    int length = name.length;
    int periodIndex = name.lastIndexOf(".");
    if (periodIndex != -1) {
      length -= periodIndex + 1;
    }
    LocatedMessage message = codeConstructorNotFound
        .withArgumentsOld(name)
        .withLocation(fileUri, fileOffset, length);
    return problemReporting.buildProblem(
      compilerContext: compilerContext,
      message: message.messageObject,
      fileUri: fileUri,
      fileOffset: message.charOffset,
      length: message.length,
      errorHasBeenReported: false,
    );
  }

  BodyBuilder _createBodyBuilder({
    required _ResolverContext context,
    required BodyBuilderContext bodyBuilderContext,
    required LookupScope scope,
    required ConstantContext constantContext,
    VariableDeclaration? thisVariable,
    List<TypeParameter>? thisTypeParameters,
    LocalScope? formalParameterScope,
  }) {
    _benchmarker
    // Coverage-ignore(suite): Not run.
    ?.beginSubdivide(BenchmarkSubdivides.resolver_createBodyBuilder);
    BodyBuilder result = _createBodyBuilderInternal(
      context: context,
      bodyBuilderContext: bodyBuilderContext,
      scope: scope,
      formalParameterScope: formalParameterScope,
      thisVariable: thisVariable,
      thisTypeParameters: thisTypeParameters,
      constantContext: constantContext,
    );
    _benchmarker
        // Coverage-ignore(suite): Not run.
        ?.endSubdivide();
    return result;
  }

  BodyBuilder _createBodyBuilderInternal({
    required _ResolverContext context,
    required BodyBuilderContext bodyBuilderContext,
    required LookupScope scope,
    required LocalScope? formalParameterScope,
    required VariableDeclaration? thisVariable,
    required List<TypeParameter>? thisTypeParameters,
    required ConstantContext constantContext,
  }) {
    return new BodyBuilderImpl(
      libraryBuilder: context.libraryBuilder,
      context: bodyBuilderContext,
      enclosingScope: new EnclosingLocalScope(scope),
      extensionScope: context.extensionScope,
      formalParameterScope: formalParameterScope,
      hierarchy: _classHierarchy,
      coreTypes: _coreTypes,
      thisVariable: thisVariable,
      thisTypeParameters: thisTypeParameters,
      uri: context.fileUri,
      assignedVariables: context.assignedVariables,
      typeEnvironment: context.typeEnvironment,
      constantContext: constantContext,
    );
  }

  _SuperParameterArguments? _createSuperParameterArguments({
    required AssignedVariables assignedVariables,
    required List<FormalParameterBuilder>? formals,
  }) {
    if (formals == null) {
      return null;
    }
    List<Argument>? superParametersAsArguments;
    int positionalCount = 0;
    int? firstPositionalOffset;
    for (int i = 0; i < formals.length; i++) {
      FormalParameterBuilder formal = formals[i];
      if (formal.isSuperInitializingFormal) {
        if (formal.isNamed) {
          (superParametersAsArguments ??= []).add(
            new SuperNamedArgument(
              new NamedExpression(
                formal.name,
                _createVariableGet(
                  assignedVariables: assignedVariables,
                  variable: formal.variable as VariableDeclarationImpl,
                  fileOffset: formal.fileOffset,
                ),
              )..fileOffset = formal.fileOffset,
            ),
          );
        } else {
          positionalCount++;
          firstPositionalOffset ??= formal.fileOffset;
          (superParametersAsArguments ??= []).add(
            new SuperPositionalArgument(
              _createVariableGet(
                assignedVariables: assignedVariables,
                variable: formal.variable as VariableDeclarationImpl,
                fileOffset: formal.fileOffset,
              ),
            ),
          );
        }
      }
    }
    if (superParametersAsArguments == null) {
      return null;
    }
    return new _SuperParameterArguments(
      superParametersAsArguments,
      positionalCount: positionalCount,
      firstPositionalOffset: firstPositionalOffset ?? -1,
    );
  }

  /// Helper method to create a [VariableGet] of the [variable] using
  /// [fileOffset] as the file offset.
  VariableGet _createVariableGet({
    required AssignedVariables assignedVariables,
    required InternalExpressionVariable variable,
    required int fileOffset,
  }) {
    if (!variable.isLocalFunction && !variable.isWildcard) {
      assignedVariables.read(variable);
    }
    return new VariableGet(variable.astVariable)..fileOffset = fileOffset;
  }

  void _declareFormals({
    required TypeInferrer typeInferrer,
    required BodyBuilderContext bodyBuilderContext,
    required VariableDeclaration? thisVariable,
  }) {
    if (thisVariable != null && bodyBuilderContext.isConstructor) {
      // `thisVariable` usually appears in `_context.formals`, but for a
      // constructor, it doesn't. So declare it separately.
      typeInferrer.flowAnalysis.declare(
        thisVariable,
        new SharedTypeView(thisVariable.type),
        initialized: true,
      );
    }
    List<FormalParameterBuilder>? formals = bodyBuilderContext.formals;
    if (formals != null) {
      for (int i = 0; i < formals.length; i++) {
        FormalParameterBuilder parameter = formals[i];
        VariableDeclaration variable = parameter.variable!;
        typeInferrer.flowAnalysis.declare(
          variable,
          new SharedTypeView(variable.type),
          initialized: true,
        );
      }
    }
  }

  void _finishInitializers({
    required CompilerContext compilerContext,
    required ProblemReporting problemReporting,
    required SourceLibraryBuilder libraryBuilder,
    required LibraryFeatures libraryFeatures,
    required BodyBuilderContext bodyBuilderContext,
    required TypeInferrer typeInferrer,
    required Uri fileUri,
    required List<Initializer> initializers,
    required _SuperParameterArguments? superParameterArguments,
    required bool needsImplicitSuperInitializer,
    required AsyncMarker asyncModifier,
    required int? asyncModifierFileOffset,
  }) {
    FunctionNode function = bodyBuilderContext.function;
    _InitializerBuilder initializerBuilder = new _InitializerBuilder();

    if (initializers.isNotEmpty) {
      if (bodyBuilderContext.isMixinClass) {
        // Report an error if a mixin class has a constructor with an
        // initializer.
        problemReporting.buildProblem(
          compilerContext: compilerContext,
          message: codeIllegalMixinDueToConstructors.withArgumentsOld(
            bodyBuilderContext.className,
          ),
          fileUri: fileUri,
          fileOffset: bodyBuilderContext.memberNameOffset,
          length: noLength,
        );
      }
      Initializer last = initializers.last;
      if (last is InternalSuperInitializer) {
        if (bodyBuilderContext.isEnumClass) {
          initializers[initializers.length - 1] = _buildInvalidInitializer(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: codeEnumConstructorSuperInitializer,
              fileUri: fileUri,
              fileOffset: last.fileOffset,
              length: noLength,
            ),
          )..parent = last.parent;
          needsImplicitSuperInitializer = false;
        } else if (superParameterArguments != null) {
          bool insertNamedOnly = false;
          ActualArguments arguments = last.arguments;
          if (superParameterArguments.positionalCount > 0) {
            if (arguments.positionalCount > 0) {
              problemReporting.addProblem(
                codePositionalSuperParametersAndArguments,
                arguments.fileOffset,
                noLength,
                fileUri,
                context: <LocatedMessage>[
                  codeSuperInitializerParameter.withLocation(
                    fileUri,
                    superParameterArguments.firstPositionalOffset,
                    noLength,
                  ),
                ],
              );
              insertNamedOnly = true;
            }
          }
          if (insertNamedOnly) {
            /// Error case: Don't insert positional argument when  positional
            /// arguments already exist.
            arguments.prependArguments(
              superParameterArguments.arguments
                  .whereType<NamedArgument>()
                  .toList(),
              positionalCount: 0,
            );
          } else {
            arguments.prependArguments(
              superParameterArguments.arguments,
              positionalCount: superParameterArguments.positionalCount,
            );
          }
        }
      } else if (last is InternalRedirectingInitializer) {
        if (bodyBuilderContext.isEnumClass &&
            libraryFeatures.enhancedEnums.isEnabled) {
          ActualArguments arguments = last.arguments;
          List<Expression> enumSyntheticArguments = [
            new VariableGet(function.positionalParameters[0])
              ..parent = last.arguments,
            new VariableGet(function.positionalParameters[1])
              ..parent = last.arguments,
          ];
          arguments.prependArguments([
            new PositionalArgument(enumSyntheticArguments[0]),
            new PositionalArgument(enumSyntheticArguments[1]),
          ], positionalCount: 2);
        }
      }

      List<InitializerInferenceResult> inferenceResults =
          new List<InitializerInferenceResult>.generate(
            initializers.length,
            (index) => bodyBuilderContext.inferInitializer(
              typeInferrer: typeInferrer,
              fileUri: fileUri,
              initializer: initializers[index],
            ),
            growable: false,
          );

      if (!bodyBuilderContext.isExternalConstructor) {
        for (InitializerInferenceResult result in inferenceResults) {
          if (!initializerBuilder.addInitializer(
            compilerContext,
            problemReporting,
            bodyBuilderContext,
            result,
            fileUri: fileUri,
          )) {
            // Erroneous initializer, implicit super call is not needed.
            needsImplicitSuperInitializer = false;
          }
        }
      }
    }

    if (asyncModifier != AsyncMarker.Sync) {
      initializers.add(
        _buildInvalidInitializer(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: codeConstructorNotSync,
            fileUri: fileUri,
            fileOffset: asyncModifierFileOffset!,
            length: noLength,
          ),
        ),
      );
      needsImplicitSuperInitializer = false;
    }
    if (needsImplicitSuperInitializer) {
      /// >If no superinitializer is provided, an implicit superinitializer
      /// >of the form super() is added at the end of the constructor's
      /// >initializer list, unless the enclosing class is class Object.
      Initializer? initializer;
      ActualArguments arguments;
      List<Argument>? argumentsOriginalOrder;
      int positionalCount = 0;
      if (superParameterArguments != null) {
        argumentsOriginalOrder = superParameterArguments.arguments;
        positionalCount += superParameterArguments.positionalCount;
      }
      if (bodyBuilderContext.isEnumClass) {
        assert(
          function.positionalParameters.length >= 2 &&
              function.positionalParameters[0].name == "#index" &&
              function.positionalParameters[1].name == "#name",
        );
        Expression indexExpression = new VariableGet(
          function.positionalParameters[0],
        );
        Expression nameExpression = new VariableGet(
          function.positionalParameters[1],
        );
        (argumentsOriginalOrder ??= []).insertAll(0, [
          new PositionalArgument(indexExpression),
          new PositionalArgument(nameExpression),
        ]);
        positionalCount += 2;
      }

      int argumentsOffset = -1;
      if (superParameterArguments != null) {
        for (Argument argument in superParameterArguments.arguments) {
          int currentArgumentOffset = argument.expression.fileOffset;
          argumentsOffset = argumentsOffset <= currentArgumentOffset
              ? argumentsOffset
              : currentArgumentOffset;
        }
      }
      SuperInitializer? explicitSuperInitializer;
      if (initializers case [..., SuperInitializer superInitializer]
          when argumentsOffset == // Coverage-ignore(suite): Not run.
              -1) {
        // Coverage-ignore-block(suite): Not run.
        argumentsOffset = superInitializer.fileOffset;
        explicitSuperInitializer = superInitializer;
      }
      if (argumentsOffset == -1) {
        argumentsOffset = bodyBuilderContext.memberNameOffset;
      }

      const Forest forest = const Forest();
      if (argumentsOriginalOrder != null) {
        arguments = forest.createArguments(
          argumentsOffset,
          arguments: argumentsOriginalOrder,
          hasNamedBeforePositional: false,
          positionalCount: positionalCount,
        );
      } else {
        arguments = forest.createArgumentsEmpty(argumentsOffset);
      }

      MemberLookupResult? result = bodyBuilderContext.lookupSuperConstructor(
        '',
        libraryBuilder.nameOriginBuilder,
      );
      Constructor? superTarget;
      if (result != null) {
        if (result.isInvalidLookup) {
          int length = bodyBuilderContext.memberNameLength;
          if (length == 0) {
            length = bodyBuilderContext.className.length;
          }
          initializer = _buildInvalidInitializer(
            LookupResult.createDuplicateExpression(
              result,
              context: compilerContext,
              name: '',
              fileUri: fileUri,
              fileOffset: bodyBuilderContext.memberNameOffset,
              length: noLength,
            ),
          );
          needsImplicitSuperInitializer = false;
        } else {
          MemberBuilder? memberBuilder = result.getable;
          Member? member = memberBuilder?.invokeTarget;
          if (member is Constructor) {
            superTarget = member;
          }
        }
      }
      if (initializer == null) {
        if (superTarget == null) {
          String superclass = bodyBuilderContext.superClassName;
          int length = bodyBuilderContext.memberNameLength;
          if (length == 0) {
            length = bodyBuilderContext.className.length;
          }
          initializer = _buildInvalidInitializer(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: codeSuperclassHasNoDefaultConstructor.withArgumentsOld(
                superclass,
              ),
              fileUri: fileUri,
              fileOffset: bodyBuilderContext.memberNameOffset,
              length: length,
            ),
          );
          needsImplicitSuperInitializer = false;
        } else if (problemReporting.checkArgumentsForFunction(
              function: superTarget.function,
              explicitTypeArguments: null,
              arguments: arguments,
              fileOffset: bodyBuilderContext.memberNameOffset,
              fileUri: fileUri,
              typeParameters: const <TypeParameter>[],
            )
            case LocatedMessage argumentIssue) {
          Initializer? errorMessageInitializer;
          if (superParameterArguments != null) {
            int positionalSuperParameterCount =
                superTarget.function.positionalParameters.length;
            Set<String> superTargetNamedParameterNames = {
              for (VariableDeclaration namedParameter
                  in superTarget.function.namedParameters)
                ?namedParameter // Coverage-ignore(suite): Not run.
                    .name,
            };
            int positionalIndex = 0;
            for (Argument argument in superParameterArguments.arguments) {
              switch (argument) {
                case PositionalArgument():
                  if (positionalIndex >= positionalSuperParameterCount) {
                    InvalidExpression errorMessageExpression = problemReporting
                        .buildProblem(
                          compilerContext: compilerContext,
                          message:
                              codeMissingPositionalSuperConstructorParameter,
                          fileUri: fileUri,
                          fileOffset: argument.expression.fileOffset,
                          length: noLength,
                        );
                    errorMessageInitializer ??= _buildInvalidInitializer(
                      errorMessageExpression,
                    );
                    needsImplicitSuperInitializer = false;
                  }
                  positionalIndex++;
                case NamedArgument():
                  if (!superTargetNamedParameterNames.contains(
                    argument.namedExpression.name,
                  )) {
                    InvalidExpression errorMessageExpression = problemReporting
                        .buildProblem(
                          compilerContext: compilerContext,
                          message: codeMissingNamedSuperConstructorParameter,
                          fileUri: fileUri,
                          fileOffset: argument.namedExpression.fileOffset,
                          length: noLength,
                        );
                    errorMessageInitializer ??= _buildInvalidInitializer(
                      errorMessageExpression,
                    );
                    needsImplicitSuperInitializer = false;
                  }
              }
            }
          }
          if (explicitSuperInitializer == null) {
            errorMessageInitializer ??= _buildInvalidInitializer(
              problemReporting.buildProblem(
                compilerContext: compilerContext,
                message: codeImplicitSuperInitializerMissingArguments
                    .withArgumentsOld(superTarget.enclosingClass.name),
                fileUri: fileUri,
                fileOffset: argumentIssue.charOffset,
                length: argumentIssue.length,
              ),
            );
            needsImplicitSuperInitializer = false;
          }
          // Coverage-ignore-block(suite): Not run.
          errorMessageInitializer ??= _buildInvalidInitializer(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: argumentIssue.messageObject,
              fileUri: fileUri,
              fileOffset: argumentIssue.charOffset,
              length: argumentIssue.length,
            ),
          );
          needsImplicitSuperInitializer = false;
          initializer = errorMessageInitializer;
        } else {
          if (bodyBuilderContext.isConstConstructor && !superTarget.isConst) {
            problemReporting.addProblem(
              codeConstConstructorWithNonConstSuper,
              bodyBuilderContext.memberNameOffset,
              superTarget.name.text.length,
              fileUri,
            );
          }
          initializer = new InternalSuperInitializer(
            superTarget,
            arguments,
            isSynthetic: true,
          )..fileOffset = bodyBuilderContext.memberNameOffset;
          needsImplicitSuperInitializer = false;
        }
      }
      InitializerInferenceResult inferenceResult = bodyBuilderContext
          .inferInitializer(
            typeInferrer: typeInferrer,
            fileUri: fileUri,
            initializer: initializer,
          );
      if (!initializerBuilder.addInitializer(
        compilerContext,
        problemReporting,
        bodyBuilderContext,
        inferenceResult,
        fileUri: fileUri,
      )) {
        // Erroneous initializer, implicit super call is not needed.
        needsImplicitSuperInitializer = false;
      }
    }
    bodyBuilderContext.registerInitializers(initializerBuilder.initializers);
  }

  void _finishConstructor({
    required _ResolverContext context,
    required CompilerContext compilerContext,
    required ProblemReporting problemReporting,
    required SourceLibraryBuilder libraryBuilder,
    required LibraryFeatures libraryFeatures,
    required BodyBuilderContext bodyBuilderContext,
    required AsyncMarker asyncModifier,
    required Statement? body,
    required _SuperParameterArguments? superParameterArguments,
    required Uri fileUri,
    required bool needsImplicitSuperInitializer,
    required ConstantContext constantContext,
    required List<Initializer> initializers,
  }) {
    _finishInitializers(
      compilerContext: compilerContext,
      problemReporting: problemReporting,
      libraryBuilder: libraryBuilder,
      libraryFeatures: libraryFeatures,
      bodyBuilderContext: bodyBuilderContext,
      typeInferrer: context.typeInferrer,
      fileUri: fileUri,
      initializers: initializers,
      superParameterArguments: superParameterArguments,
      needsImplicitSuperInitializer: needsImplicitSuperInitializer,
      asyncModifier: asyncModifier,
      asyncModifierFileOffset: body?.fileOffset,
    );

    if (body == null && !bodyBuilderContext.isExternalConstructor) {
      /// >If a generative constructor c is not a redirecting constructor
      /// >and no body is provided, then c implicitly has an empty body {}.
      /// We use an empty statement instead.
      bodyBuilderContext.registerNoBodyConstructor();
    } else if (body != null &&
        bodyBuilderContext.isMixinClass &&
        !bodyBuilderContext.isFactory) {
      // Report an error if a mixin class has a non-factory constructor with a
      // body.
      problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: codeIllegalMixinDueToConstructors.withArgumentsOld(
          bodyBuilderContext.className,
        ),
        fileUri: fileUri,
        fileOffset: bodyBuilderContext.memberNameOffset,
        length: noLength,
      );
    }
  }

  void _finishFunction({
    required _ResolverContext context,
    required CompilerContext compilerContext,
    required ProblemReporting problemReporting,
    required SourceLibraryBuilder libraryBuilder,
    required LibraryFeatures libraryFeatures,
    required FormalParameters? formals,
    required AsyncMarker asyncModifier,
    required Statement? body,
    required Uri fileUri,
    required BodyBuilderContext bodyBuilderContext,
    required VariableDeclaration? thisVariable,
    required List<Initializer> initializers,
    required ConstantContext constantContext,
    required bool needsImplicitSuperInitializer,
  }) {
    const Forest forest = const Forest();
    AssignedVariables assignedVariables = context.assignedVariables;

    // Create variable get expressions for super parameters before finishing
    // the analysis of the assigned variables. Creating the expressions later
    // that point results in a flow analysis error.
    _SuperParameterArguments? superParameterArguments =
        _createSuperParameterArguments(
          assignedVariables: assignedVariables,
          formals: formals?.parameters,
        );
    assignedVariables.finish();

    FunctionNode function = bodyBuilderContext.function;
    _declareFormals(
      typeInferrer: context.typeInferrer,
      bodyBuilderContext: bodyBuilderContext,
      thisVariable: thisVariable,
    );
    if (formals?.parameters != null) {
      for (int i = 0; i < formals!.parameters!.length; i++) {
        FormalParameterBuilder parameter = formals.parameters![i];
        Expression? initializer = parameter.variable!.initializer;
        bool inferInitializer;
        if (parameter.isSuperInitializingFormal) {
          // Super-parameters can inherit the default value from the super
          // constructor so we only handle explicit default values here.
          inferInitializer = parameter.hasImmediatelyDeclaredInitializer;
        } else if (initializer != null) {
          inferInitializer = true;
        } else {
          inferInitializer = parameter.isOptional;
        }
        if (inferInitializer) {
          if (!parameter.initializerWasInferred) {
            // Coverage-ignore(suite): Not run.
            initializer ??= forest.createNullLiteral(
              // TODO(ahe): Should store: originParameter.fileOffset
              // https://github.com/dart-lang/sdk/issues/32289
              noLocation,
            );
            VariableDeclaration originParameter = bodyBuilderContext
                .getFormalParameter(i);
            initializer = context.typeInferrer.inferParameterInitializer(
              fileUri: fileUri,
              initializer: initializer,
              declaredType: originParameter.type,
              hasDeclaredInitializer: parameter.hasDeclaredInitializer,
            );
            originParameter.initializer = initializer..parent = originParameter;
            if (initializer is InvalidExpression) {
              originParameter.isErroneouslyInitialized = true;
            }
            parameter.initializerWasInferred = true;
          }
          VariableDeclaration? tearOffParameter = bodyBuilderContext
              .getTearOffParameter(i);
          if (tearOffParameter != null) {
            Expression tearOffInitializer = _simpleCloner.cloneInContext(
              initializer!,
            );
            tearOffParameter.initializer = tearOffInitializer
              ..parent = tearOffParameter;
            tearOffParameter.isErroneouslyInitialized =
                parameter.variable!.isErroneouslyInitialized;
          }
        }
      }
    }

    if (bodyBuilderContext.isConstructor) {
      _finishConstructor(
        context: context,
        compilerContext: compilerContext,
        problemReporting: problemReporting,
        libraryBuilder: libraryBuilder,
        libraryFeatures: libraryFeatures,
        bodyBuilderContext: bodyBuilderContext,
        asyncModifier: asyncModifier,
        body: body,
        superParameterArguments: superParameterArguments,
        fileUri: fileUri,
        needsImplicitSuperInitializer: needsImplicitSuperInitializer,
        constantContext: constantContext,
        initializers: initializers,
      );
    } else if (body != null) {
      bodyBuilderContext.setAsyncModifier(asyncModifier);
    }

    InferredFunctionBody? inferredFunctionBody;
    if (body != null) {
      inferredFunctionBody = context.typeInferrer.inferFunctionBody(
        fileUri: fileUri,
        fileOffset: bodyBuilderContext.memberNameOffset,
        returnType: bodyBuilderContext.returnTypeContext,
        asyncMarker: asyncModifier,
        body: body,
      );
      body = inferredFunctionBody.body;
      function.emittedValueType = inferredFunctionBody.emittedValueType;
      assert(
        function.asyncMarker == AsyncMarker.Sync ||
            function.emittedValueType != null,
      );
    }

    if (bodyBuilderContext.returnType is! OmittedTypeBuilder) {
      problemReporting.checkAsyncReturnType(
        libraryBuilder: libraryBuilder,
        typeEnvironment: context.typeInferrer.typeSchemaEnvironment,
        asyncModifier: asyncModifier,
        returnType: function.returnType,
        fileUri: fileUri,
        fileOffset: bodyBuilderContext.memberNameOffset,
        length: bodyBuilderContext.memberNameLength,
      );
    }

    if (bodyBuilderContext.isSetter) {
      if (formals?.parameters == null ||
          formals!.parameters!.length != 1 ||
          formals.parameters!.single.isOptionalPositional) {
        int charOffset =
            formals?.charOffset ??
            // Coverage-ignore(suite): Not run.
            body?.fileOffset ??
            // Coverage-ignore(suite): Not run.
            bodyBuilderContext.memberNameOffset;
        if (body == null) {
          body = new EmptyStatement()..fileOffset = charOffset;
        }
        if (bodyBuilderContext.formals != null) {
          // Illegal parameters were removed by the function builder.
          // Add them as local variable to put them in scope of the body.
          List<Statement> statements = <Statement>[];
          List<FormalParameterBuilder> formals = bodyBuilderContext.formals!;
          for (int i = 0; i < formals.length; i++) {
            FormalParameterBuilder parameter = formals[i];
            VariableDeclaration variable = parameter.variable!;
            // #this should not be redeclared.
            if (i == 0 && identical(variable, thisVariable)) {
              continue;
            }
            statements.add(parameter.variable!);
          }
          statements.add(body);
          body = forest.createBlock(charOffset, noLocation, statements);
        }
        body = forest.createBlock(charOffset, noLocation, <Statement>[
          forest.createExpressionStatement(
            noLocation,
            // This error is added after type inference is done, so we
            // don't need to wrap errors in SyntheticExpressionJudgment.
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: codeSetterWithWrongNumberOfFormals,
              fileUri: fileUri,
              fileOffset: charOffset,
              length: noLength,
            ),
          ),
          body,
        ]);
      }
    }
    // No-such-method forwarders get their bodies injected during outline
    // building, so we should skip them here.
    bool isNoSuchMethodForwarder =
        (function.parent is Procedure &&
        (function.parent as Procedure).isNoSuchMethodForwarder);
    if (body != null) {
      if (bodyBuilderContext.isExternalFunction || isNoSuchMethodForwarder) {
        body = new Block(<Statement>[
          new ExpressionStatement(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: codeExternalMethodWithBody,
              fileUri: fileUri,
              fileOffset: body.fileOffset,
              length: noLength,
            ),
          )..fileOffset = body.fileOffset,
          body,
        ])..fileOffset = body.fileOffset;
      }
      bodyBuilderContext.registerFunctionBody(body);
    }
  }

  Initializer _buildInvalidInitializer(InvalidExpression expression) {
    return new InvalidInitializer(expression.message)
      ..fileOffset = expression.fileOffset;
  }
}
