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
    required LookupScope scope,
    required Annotatable annotatable,
    required List<Annotation> annotations,
  }) {
    _ResolverContext context = new _ResolverContext(
      typeInferenceEngine: _typeInferenceEngine,
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      scope: scope,
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
    _ResolverContext context = new _ResolverContext(
      typeInferenceEngine: _typeInferenceEngine,
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      scope: scope,
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
    ArgumentsImpl arguments;
    if (token != null) {
      result = bodyBuilder.buildEnumConstant(token: token);
      arguments = result.arguments;
      arguments.positional.insertAll(0, enumSyntheticArguments);
      arguments.argumentsOriginalOrder?.insertAll(0, enumSyntheticArguments);
    } else {
      arguments = new ArgumentsImpl(enumSyntheticArguments);
    }
    if (typeArguments != null) {
      arguments.setExplicitTypeArguments(typeArguments);
    } else if (enumTypeParameterCount != 0) {
      arguments.types.addAll(
        new List<DartType>.filled(enumTypeParameterCount, const UnknownType()),
      );
    }
    setParents(enumSyntheticArguments, arguments);
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
        arguments: arguments,
        fileUri: fileUri,
        fileOffset: fileOffset,
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
      scope: scope,
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
      scope: scope,
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
    LookupScope typeParameterScope =
        functionBodyBuildingContext.typeParameterScope;
    LocalScope formalParameterScope = functionBodyBuildingContext
        .computeFormalParameterScope(typeParameterScope);
    BodyBuilderContext bodyBuilderContext = functionBodyBuildingContext
        .createBodyBuilderContext();

    _ResolverContext context = new _ResolverContext(
      typeInferenceEngine: _typeInferenceEngine,
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      scope: formalParameterScope,
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
      scope: typeParameterScope,
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
    List<Initializer>? initializers = result.initializers;
    bool needsImplicitSuperInitializer = result.needsImplicitSuperInitializer;
    if (isConst) {
      List<FormalParameterBuilder>? formals = bodyBuilderContext.formals;
      List<Object>? superParametersAsArguments = formals != null
          ? _createSuperParametersAsArguments(
              assignedVariables: context.typeInferrer.assignedVariables,
              formals: formals,
            )
          : null;
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
        superParametersAsArguments: superParametersAsArguments,
        fileUri: fileUri,
        needsImplicitSuperInitializer: needsImplicitSuperInitializer,
        constantContext: constantContext,
        initializers: initializers,
      );
    }
    context.performBacklog(result.annotations);
  }

  List<Initializer>? buildInitializersUnfinished({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required LookupScope typeParameterScope,
    required Uri fileUri,
    required Token beginInitializers,
    required bool isConst,
  }) {
    _ResolverContext context = new _ResolverContext(
      typeInferenceEngine: _typeInferenceEngine,
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      scope: typeParameterScope,
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
    required LookupScope scope,
    required Token metadata,
    required Annotatable annotatable,
  }) {
    _ResolverContext context = new _ResolverContext(
      typeInferenceEngine: _typeInferenceEngine,
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      scope: scope,
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
      scope: scope,
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
    LookupScope typeParameterScope =
        functionBodyBuildingContext.typeParameterScope;
    LocalScope formalParameterScope = functionBodyBuildingContext
        .computeFormalParameterScope(typeParameterScope);
    BodyBuilderContext bodyBuilderContext = functionBodyBuildingContext
        .createBodyBuilderContext();
    _ResolverContext context = new _ResolverContext(
      typeInferenceEngine: _typeInferenceEngine,
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      scope: typeParameterScope,
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
        initializers: null,
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
    LookupScope typeParameterScope =
        functionBodyBuildingContext.typeParameterScope;
    LocalScope formalParameterScope = functionBodyBuildingContext
        .computeFormalParameterScope(typeParameterScope);
    BodyBuilderContext bodyBuilderContext = functionBodyBuildingContext
        .createBodyBuilderContext();
    _ResolverContext context = new _ResolverContext(
      typeInferenceEngine: _typeInferenceEngine,
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      scope: typeParameterScope,
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
    required LookupScope scope,
    required Token token,
    required Procedure procedure,
    required List<VariableDeclarationImpl> extraKnownVariables,
    required ExpressionEvaluationHelper expressionEvaluationHelper,
    required VariableDeclaration? extensionThis,
  }) {
    _ResolverContext context = new _ResolverContext(
      typeInferenceEngine: _typeInferenceEngine,
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      scope: scope,
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
    for (VariableDeclarationImpl extraVariable in extraKnownVariables) {
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
    required ArgumentsImpl arguments,
    required Uri fileUri,
    required int fileOffset,
  }) {
    Expression? result = problemReporting.checkStaticArguments(
      compilerContext: compilerContext,
      target: target,
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
        arguments,
        isConst: true,
      )..fileOffset = fileOffset;
      problemReporting.checkBoundsInConstructorInvocation(
        libraryFeatures: libraryFeatures,
        constructor: target,
        typeArguments: arguments.types,
        typeEnvironment: typeEnvironment,
        fileUri: fileUri,
        fileOffset: fileOffset,
      );
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
        arguments,
        isConst: true,
      )..fileOffset = fileOffset;
      problemReporting.checkBoundsInFactoryInvocation(
        libraryFeatures: libraryFeatures,
        factory: target,
        typeArguments: arguments.types,
        typeEnvironment: typeEnvironment,
        fileUri: fileUri,
        fileOffset: fileOffset,
        inferred: !arguments.hasExplicitTypeArguments,
      );
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

  List<Object>? _createSuperParametersAsArguments({
    required AssignedVariables assignedVariables,
    required List<FormalParameterBuilder> formals,
  }) {
    List<Object>? superParametersAsArguments;
    for (int i = 0; i < formals.length; i++) {
      FormalParameterBuilder formal = formals[i];
      if (formal.isSuperInitializingFormal) {
        if (formal.isNamed) {
          (superParametersAsArguments ??= <Object>[]).add(
            new NamedExpression(
              formal.name,
              _createVariableGet(
                assignedVariables: assignedVariables,
                variable: formal.variable as VariableDeclarationImpl,
                fileOffset: formal.fileOffset,
              ),
            )..fileOffset = formal.fileOffset,
          );
        } else {
          (superParametersAsArguments ??= <Object>[]).add(
            _createVariableGet(
              assignedVariables: assignedVariables,
              variable: formal.variable as VariableDeclarationImpl,
              fileOffset: formal.fileOffset,
            ),
          );
        }
      }
    }
    return superParametersAsArguments;
  }

  /// Helper method to create a [VariableGet] of the [variable] using
  /// [fileOffset] as the file offset.
  VariableGet _createVariableGet({
    required AssignedVariables assignedVariables,
    required VariableDeclarationImpl variable,
    required int fileOffset,
  }) {
    if (!variable.isLocalFunction && !variable.isWildcard) {
      assignedVariables.read(variable);
    }
    return new VariableGet(variable)..fileOffset = fileOffset;
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

  void _finishConstructor({
    required _ResolverContext context,
    required CompilerContext compilerContext,
    required ProblemReporting problemReporting,
    required SourceLibraryBuilder libraryBuilder,
    required LibraryFeatures libraryFeatures,
    required BodyBuilderContext bodyBuilderContext,
    required AsyncMarker asyncModifier,
    required Statement? body,
    required List<Object /* Expression | NamedExpression */>?
    superParametersAsArguments,
    required Uri fileUri,
    required bool needsImplicitSuperInitializer,
    required ConstantContext constantContext,
    required List<Initializer>? initializers,
  }) {
    const Forest forest = const Forest();
    AssignedVariables assignedVariables = context.assignedVariables;

    /// Quotes below are from [Dart Programming Language Specification, 4th
    /// Edition](
    /// https://ecma-international.org/publications/files/ECMA-ST/ECMA-408.pdf).
    assert(
      () {
        if (superParametersAsArguments == null) {
          return true;
        }
        for (Object superParameterAsArgument in superParametersAsArguments) {
          if (superParameterAsArgument is! Expression &&
              superParameterAsArgument is! NamedExpression) {
            return false;
          }
        }
        return true;
      }(),
      "Expected 'superParametersAsArguments' "
      "to contain nothing but Expressions and NamedExpressions.",
    );
    assert(
      () {
        if (superParametersAsArguments == null) {
          return true;
        }
        int previousOffset = -1;
        for (Object superParameterAsArgument in superParametersAsArguments) {
          int offset;
          if (superParameterAsArgument is Expression) {
            offset = superParameterAsArgument.fileOffset;
          } else if (superParameterAsArgument is NamedExpression) {
            offset = superParameterAsArgument.value.fileOffset;
          } else {
            return false;
          }
          if (previousOffset > offset) {
            return false;
          }
          previousOffset = offset;
        }
        return true;
      }(),
      "Expected 'superParametersAsArguments' "
      "to be sorted by occurrence in file.",
    );

    FunctionNode function = bodyBuilderContext.function;

    Set<String>? namedSuperParameterNames;
    List<Expression>? positionalSuperParametersAsArguments;
    List<NamedExpression>? namedSuperParametersAsArguments;
    List<FormalParameterBuilder>? formals = bodyBuilderContext.formals;
    if (superParametersAsArguments != null) {
      for (Object superParameterAsArgument in superParametersAsArguments) {
        if (superParameterAsArgument is Expression) {
          (positionalSuperParametersAsArguments ??= <Expression>[]).add(
            superParameterAsArgument,
          );
        } else {
          NamedExpression namedSuperParameterAsArgument =
              superParameterAsArgument as NamedExpression;
          (namedSuperParametersAsArguments ??= <NamedExpression>[]).add(
            namedSuperParameterAsArgument,
          );
          (namedSuperParameterNames ??= <String>{}).add(
            namedSuperParameterAsArgument.name,
          );
        }
      }
    } else if (formals != null) {
      for (FormalParameterBuilder formal in formals) {
        if (formal.isSuperInitializingFormal) {
          // Coverage-ignore-block(suite): Not run.
          if (formal.isNamed) {
            NamedExpression superParameterAsArgument = new NamedExpression(
              formal.name,
              _createVariableGet(
                assignedVariables: assignedVariables,
                variable: formal.variable as VariableDeclarationImpl,
                fileOffset: formal.fileOffset,
              ),
            )..fileOffset = formal.fileOffset;
            (namedSuperParametersAsArguments ??= <NamedExpression>[]).add(
              superParameterAsArgument,
            );
            (namedSuperParameterNames ??= <String>{}).add(formal.name);
            (superParametersAsArguments ??= <Object>[]).add(
              superParameterAsArgument,
            );
          } else {
            Expression superParameterAsArgument = _createVariableGet(
              assignedVariables: assignedVariables,
              variable: formal.variable as VariableDeclarationImpl,
              fileOffset: formal.fileOffset,
            );
            (positionalSuperParametersAsArguments ??= <Expression>[]).add(
              superParameterAsArgument,
            );
            (superParametersAsArguments ??= <Object>[]).add(
              superParameterAsArgument,
            );
          }
        }
      }
    }

    if (initializers != null && initializers.isNotEmpty) {
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
      if (last is SuperInitializer) {
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
        } else if (libraryFeatures.superParameters.isEnabled) {
          ArgumentsImpl arguments = last.arguments as ArgumentsImpl;

          if (positionalSuperParametersAsArguments != null) {
            if (arguments.positional.isNotEmpty) {
              problemReporting.addProblem(
                codePositionalSuperParametersAndArguments,
                arguments.fileOffset,
                noLength,
                fileUri,
                context: <LocatedMessage>[
                  codeSuperInitializerParameter.withLocation(
                    fileUri,
                    (positionalSuperParametersAsArguments.first as VariableGet)
                        .variable
                        .fileOffset,
                    noLength,
                  ),
                ],
              );
            } else {
              arguments.positional.addAll(positionalSuperParametersAsArguments);
              setParents(positionalSuperParametersAsArguments, arguments);
              arguments.positionalAreSuperParameters = true;
            }
          }
          if (namedSuperParametersAsArguments != null) {
            // TODO(cstefantsova): Report name conflicts.
            arguments.named.addAll(namedSuperParametersAsArguments);
            setParents(namedSuperParametersAsArguments, arguments);
            arguments.namedSuperParameterNames = namedSuperParameterNames;
          }
          if (superParametersAsArguments != null) {
            arguments.argumentsOriginalOrder?.insertAll(
              0,
              superParametersAsArguments,
            );
          }
        }
      } else if (last is RedirectingInitializer) {
        if (bodyBuilderContext.isEnumClass &&
            libraryFeatures.enhancedEnums.isEnabled) {
          ArgumentsImpl arguments = last.arguments as ArgumentsImpl;
          List<Expression> enumSyntheticArguments = [
            new VariableGet(function.positionalParameters[0])
              ..parent = last.arguments,
            new VariableGet(function.positionalParameters[1])
              ..parent = last.arguments,
          ];
          arguments.positional.insertAll(0, enumSyntheticArguments);
          arguments.argumentsOriginalOrder?.insertAll(
            0,
            enumSyntheticArguments,
          );
        }
      }

      List<InitializerInferenceResult> inferenceResults =
          new List<InitializerInferenceResult>.generate(
            initializers.length,
            (index) => bodyBuilderContext.inferInitializer(
              typeInferrer: context.typeInferrer,
              fileUri: fileUri,
              initializer: initializers[index],
            ),
            growable: false,
          );

      if (!bodyBuilderContext.isExternalConstructor) {
        for (InitializerInferenceResult result in inferenceResults) {
          if (!bodyBuilderContext.addInferredInitializer(
            compilerContext,
            problemReporting,
            result,
            fileUri,
          )) {
            // Erroneous initializer, implicit super call is not needed.
            needsImplicitSuperInitializer = false;
          }
        }
      }
    }

    if (asyncModifier != AsyncMarker.Sync) {
      bodyBuilderContext.addInitializer(
        compilerContext,
        problemReporting,
        _buildInvalidInitializer(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: codeConstructorNotSync,
            fileUri: fileUri,
            fileOffset: body!.fileOffset,
            length: noLength,
          ),
        ),
        fileUri,
      );
      needsImplicitSuperInitializer = false;
    }
    if (needsImplicitSuperInitializer) {
      /// >If no superinitializer is provided, an implicit superinitializer
      /// >of the form super() is added at the end of the constructor's
      /// >initializer list, unless the enclosing class is class Object.
      Initializer? initializer;
      ArgumentsImpl arguments;
      List<Expression>? positionalArguments;
      List<NamedExpression>? namedArguments;
      if (libraryFeatures.superParameters.isEnabled) {
        positionalArguments = positionalSuperParametersAsArguments;
        namedArguments = namedSuperParametersAsArguments;
      }
      if (bodyBuilderContext.isEnumClass) {
        assert(
          function.positionalParameters.length >= 2 &&
              function.positionalParameters[0].name == "#index" &&
              function.positionalParameters[1].name == "#name",
        );
        (positionalArguments ??= <Expression>[]).insertAll(0, [
          new VariableGet(function.positionalParameters[0]),
          new VariableGet(function.positionalParameters[1]),
        ]);
      }

      int argumentsOffset = -1;
      if (superParametersAsArguments != null) {
        for (Object argument in superParametersAsArguments) {
          assert(argument is Expression || argument is NamedExpression);
          int currentArgumentOffset;
          if (argument is Expression) {
            currentArgumentOffset = argument.fileOffset;
          } else {
            currentArgumentOffset = (argument as NamedExpression).fileOffset;
          }
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

      if (positionalArguments != null || namedArguments != null) {
        arguments = forest.createArguments(
          argumentsOffset,
          positionalArguments ?? <Expression>[],
          named: namedArguments,
        );
      } else {
        arguments = forest.createArgumentsEmpty(argumentsOffset);
      }

      arguments.positionalAreSuperParameters =
          positionalSuperParametersAsArguments != null;
      arguments.namedSuperParameterNames = namedSuperParameterNames;

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
              context: libraryBuilder.loader.target.context,
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
              arguments: arguments,
              fileOffset: bodyBuilderContext.memberNameOffset,
              fileUri: fileUri,
              typeParameters: const <TypeParameter>[],
            )
            case LocatedMessage argumentIssue) {
          List<int>? positionalSuperParametersIssueOffsets;
          if (positionalSuperParametersAsArguments != null) {
            for (
              int positionalSuperParameterIndex =
                  superTarget.function.positionalParameters.length;
              positionalSuperParameterIndex <
                  positionalSuperParametersAsArguments.length;
              positionalSuperParameterIndex++
            ) {
              (positionalSuperParametersIssueOffsets ??= []).add(
                positionalSuperParametersAsArguments[ // force line break
                    positionalSuperParameterIndex]
                    .fileOffset,
              );
            }
          }

          List<int>? namedSuperParametersIssueOffsets;
          if (namedSuperParametersAsArguments != null) {
            Set<String> superTargetNamedParameterNames = {
              for (VariableDeclaration namedParameter
                  in superTarget.function.namedParameters)
                if (namedParameter // Coverage-ignore(suite): Not run.
                        .name !=
                    null)
                  // Coverage-ignore(suite): Not run.
                  namedParameter.name!,
            };
            for (NamedExpression namedSuperParameter
                in namedSuperParametersAsArguments) {
              if (!superTargetNamedParameterNames.contains(
                namedSuperParameter.name,
              )) {
                (namedSuperParametersIssueOffsets ??= []).add(
                  namedSuperParameter.fileOffset,
                );
              }
            }
          }

          Initializer? errorMessageInitializer;
          if (positionalSuperParametersIssueOffsets != null) {
            for (int issueOffset in positionalSuperParametersIssueOffsets) {
              Expression errorMessageExpression = problemReporting.buildProblem(
                compilerContext: compilerContext,
                message: codeMissingPositionalSuperConstructorParameter,
                fileUri: fileUri,
                fileOffset: issueOffset,
                length: noLength,
              );
              errorMessageInitializer ??= _buildInvalidInitializer(
                errorMessageExpression,
              );
              needsImplicitSuperInitializer = false;
            }
          }
          if (namedSuperParametersIssueOffsets != null) {
            for (int issueOffset in namedSuperParametersIssueOffsets) {
              Expression errorMessageExpression = problemReporting.buildProblem(
                compilerContext: compilerContext,
                message: codeMissingNamedSuperConstructorParameter,
                fileUri: fileUri,
                fileOffset: issueOffset,
                length: noLength,
              );
              errorMessageInitializer ??= _buildInvalidInitializer(
                errorMessageExpression,
              );
              needsImplicitSuperInitializer = false;
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
          initializer = new SuperInitializer(superTarget, arguments)
            ..fileOffset = bodyBuilderContext.memberNameOffset
            ..isSynthetic = true;
          needsImplicitSuperInitializer = false;
        }
      }
      if (libraryFeatures.superParameters.isEnabled) {
        InitializerInferenceResult inferenceResult = bodyBuilderContext
            .inferInitializer(
              typeInferrer: context.typeInferrer,
              fileUri: fileUri,
              initializer: initializer,
            );
        if (!bodyBuilderContext.addInferredInitializer(
          compilerContext,
          problemReporting,
          inferenceResult,
          fileUri,
        )) {
          // Erroneous initializer, implicit super call is not needed.
          needsImplicitSuperInitializer = false;
        }
      } else {
        if (!bodyBuilderContext.addInitializer(
          compilerContext,
          problemReporting,
          initializer,
          fileUri,
        )) {
          // Erroneous initializer, implicit super call is not needed.
          needsImplicitSuperInitializer = false;
        }
      }
    }
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
    required List<Initializer>? initializers,
    required ConstantContext constantContext,
    required bool needsImplicitSuperInitializer,
  }) {
    const Forest forest = const Forest();
    AssignedVariables assignedVariables = context.assignedVariables;

    // Create variable get expressions for super parameters before finishing
    // the analysis of the assigned variables. Creating the expressions later
    // that point results in a flow analysis error.
    List<Object>? superParametersAsArguments;
    if (formals != null) {
      List<FormalParameterBuilder>? formalParameters = formals.parameters;
      if (formalParameters != null) {
        superParametersAsArguments = _createSuperParametersAsArguments(
          assignedVariables: assignedVariables,
          formals: formalParameters,
        );
      }
    }
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
        superParametersAsArguments: superParametersAsArguments,
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

  Initializer _buildInvalidInitializer(Expression expression) {
    return new ShadowInvalidInitializer(
      new VariableDeclaration.forValue(expression),
    )..fileOffset = expression.fileOffset;
  }
}
