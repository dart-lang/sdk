// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show FormalParameterKind;
import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:_fe_analyzer_shared/src/type_inference/assigned_variables.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:front_end/src/codes/diagnostic.dart' as diag;
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
import '../util/helpers.dart';
import 'assigned_variables_impl.dart';
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
      thisVariable: null,
      thisTypeParameters: null,
      formalParameterScope: null,
      internalThisVariable: null,
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
      thisVariable: null,
      thisTypeParameters: null,
      formalParameterScope: null,
      internalThisVariable: null,
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
            inferenceDefaultType: InferenceDefaultType.Dynamic,
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
    required InferenceDefaultType inferenceDefaultType,
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
      thisVariable: null,
      thisTypeParameters: null,
      formalParameterScope: null,
      // TODO(cstefantsova): Should a [ThisVariable] be created here?
      internalThisVariable: null,
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
          inferenceDefaultType: inferenceDefaultType,
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
    List<FormalParameterBuilder>? primaryConstructorInitializerScopeParameters =
        bodyBuilderContext.primaryConstructorInitializerScopeParameters;
    BodyBuilder bodyBuilder = _createBodyBuilder(
      context: context,
      bodyBuilderContext: bodyBuilderContext,
      scope: scope,
      constantContext: constantContext,
      thisVariable: null,
      thisTypeParameters: null,
      formalParameterScope: null,
      // TODO(cstefantsova): Should a [ThisVariable] be created here?
      internalThisVariable: null,
    );
    BuildFieldsResult result = bodyBuilder.buildFields(
      startToken: startToken,
      metadata: metadata,
      isTopLevel: isTopLevel,
    );
    _declareFormals(
      typeInferrer: context.typeInferrer,
      bodyBuilderContext: bodyBuilderContext,
      thisVariable: null,
      formals: primaryConstructorInitializerScopeParameters,
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
    ThisVariable? internalThisVariable = bodyBuilderContext
        .createInternalThisVariable();
    BodyBuilder bodyBuilder = _createBodyBuilder(
      context: context,
      bodyBuilderContext: bodyBuilderContext,
      scope: typeParameterScope,
      thisVariable: functionBodyBuildingContext.thisVariable,
      thisTypeParameters: functionBodyBuildingContext.thisTypeParameters,
      formalParameterScope: formalParameterScope,
      constantContext: constantContext,
      internalThisVariable: internalThisVariable,
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
        asyncMarker: result.asyncMarker,
        body: result.body,
        fileUri: fileUri,
        bodyBuilderContext: bodyBuilderContext,
        thisVariable: functionBodyBuildingContext.thisVariable,
        initializers: result.initializers,
        constantContext: constantContext,
        internalThisVariable: internalThisVariable,
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
    ConstantContext constantContext = bodyBuilderContext.constantContext;
    BodyBuilder bodyBuilder = _createBodyBuilder(
      context: context,
      bodyBuilderContext: bodyBuilderContext,
      scope: typeParameterScope,
      constantContext: constantContext,
      formalParameterScope: formalParameterScope,
      thisVariable: null,
      thisTypeParameters: null,
      // TODO(cstefantsova): Should [ThisVariable] be created here?
      internalThisVariable: null,
    );
    constructorBuilder.inferFormalTypes(_classHierarchy);
    BuildInitializersResult result = bodyBuilder.buildInitializers(
      beginInitializers: beginInitializers,
    );
    List<Initializer> initializers = result.initializers;
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
        formals: bodyBuilderContext.formals,
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
      thisVariable: null,
      thisTypeParameters: null,
      // TODO(johnniwinther): Should we provide this?
      formalParameterScope: null,
      // TODO(cstefantsova): Should a [ThisVariable] be created here?
      internalThisVariable: null,
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
      thisVariable: null,
      thisTypeParameters: null,
      formalParameterScope: null,
      internalThisVariable: null,
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
      thisVariable: null,
      thisTypeParameters: null,
      formalParameterScope: null,
      internalThisVariable: null,
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
    required bool finishFunction,
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
    ThisVariable? internalThisVariable = bodyBuilderContext
        .createInternalThisVariable();
    BodyBuilder bodyBuilder = _createBodyBuilder(
      context: context,
      bodyBuilderContext: bodyBuilderContext,
      scope: typeParameterScope,
      thisVariable: functionBodyBuildingContext.thisVariable,
      thisTypeParameters: functionBodyBuildingContext.thisTypeParameters,
      formalParameterScope: formalParameterScope,
      constantContext: constantContext,
      internalThisVariable: internalThisVariable,
    );
    try {
      BuildPrimaryConstructorResult result = bodyBuilder
          .buildPrimaryConstructor(startToken: startToken);
      if (finishFunction) {
        _finishFunction(
          context: context,
          compilerContext: compilerContext,
          problemReporting: problemReporting,
          libraryBuilder: libraryBuilder,
          libraryFeatures: libraryFeatures,
          asyncMarker: AsyncMarker.Sync,
          body: null,
          fileUri: fileUri,
          bodyBuilderContext: bodyBuilderContext,
          thisVariable: functionBodyBuildingContext.thisVariable,
          initializers: result.initializers,
          constantContext: constantContext,
          internalThisVariable: internalThisVariable,
        );

        context.performBacklog(result.annotations);
      }
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

  void buildPrimaryConstructorBody({
    required SourceLibraryBuilder libraryBuilder,
    required SourceConstructorBuilder constructorBuilder,
    required FunctionBodyBuildingContext functionBodyBuildingContext,
    required Uri fileUri,
    required Token startToken,
    required Token? metadata,
  }) {
    _benchmarker
    // Coverage-ignore(suite): Not run.
    ?.beginSubdivide(
      BenchmarkSubdivides.diet_listener_buildPrimaryConstructorBody,
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
    );

    CompilerContext compilerContext = libraryBuilder.loader.target.context;
    ProblemReporting problemReporting = libraryBuilder;
    LibraryFeatures libraryFeatures = libraryBuilder.libraryFeatures;
    ConstantContext constantContext = bodyBuilderContext.constantContext;
    ThisVariable? internalThisVariable = bodyBuilderContext
        .createInternalThisVariable();
    BodyBuilder bodyBuilder = _createBodyBuilder(
      context: context,
      bodyBuilderContext: bodyBuilderContext,
      scope: typeParameterScope,
      constantContext: constantContext,
      formalParameterScope: formalParameterScope,
      thisVariable: functionBodyBuildingContext.thisVariable,
      thisTypeParameters: functionBodyBuildingContext.thisTypeParameters,
      internalThisVariable: internalThisVariable,
    );
    constructorBuilder.inferFormalTypes(_classHierarchy);
    try {
      BuildPrimaryConstructorBodyResult result = bodyBuilder
          .buildPrimaryConstructorBody(
            startToken: startToken,
            metadata: metadata,
          );
      _finishFunction(
        context: context,
        compilerContext: compilerContext,
        problemReporting: problemReporting,
        libraryBuilder: libraryBuilder,
        libraryFeatures: libraryFeatures,
        bodyBuilderContext: bodyBuilderContext,
        asyncMarker: result.asyncMarker,
        body: result.body,
        fileUri: fileUri,
        constantContext: constantContext,
        initializers: result.initializers,
        thisVariable: functionBodyBuildingContext.thisVariable,
        internalThisVariable: internalThisVariable,
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
      internalThisVariable: null,
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
    ThisVariable? internalThisVariable = bodyBuilderContext
        .createInternalThisVariable();
    BodyBuilder bodyBuilder = _createBodyBuilder(
      context: context,
      bodyBuilderContext: bodyBuilderContext,
      scope: scope,
      thisVariable: extensionThis,
      constantContext: constantContext,
      // TODO(johnniwinther): Should we provide these?
      thisTypeParameters: null,
      formalParameterScope: null,
      internalThisVariable: internalThisVariable,
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
                kind: FormalParameterKind.requiredPositional,
                modifiers: Modifiers.empty,
                type: const ImplicitTypeBuilder(),
                name: formalName,
                nameOffset: null,
                fileOffset: formal.fileOffset,
                fileUri: fileUri,
                hasImmediatelyDeclaredInitializer: false,
                isWildcard: isWildcard,
                isClosureContextLoweringEnabled: libraryBuilder
                    .loader
                    .target
                    .backendTarget
                    .flags
                    .isClosureContextLoweringEnabled,
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

    // TODO(cstefantsova): Remove special-casing over
    // ExpressionCompilerProcedureBodyBuildContext below by computing formals in
    // it.
    List<VariableDeclaration> formalParameters =
        bodyBuilderContext is ExpressionCompilerProcedureBodyBuildContext
        ? []
        : <VariableDeclaration>[
            for (FormalParameterBuilder formal
                in bodyBuilderContext.formals ?? [])
              formal.variable!,
          ];
    InferredFunctionBody inferredFunctionBody = context.typeInferrer
        .inferFunctionBody(
          fileUri: fileUri,
          fileOffset: fileOffset,
          returnType: const DynamicType(),
          asyncMarker: AsyncMarker.Sync,
          body: fakeReturn,
          expressionEvaluationHelper: expressionEvaluationHelper,
          parameters: formalParameters,
          internalThisVariable: internalThisVariable,
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
          message: diag.nonConstConstructor,
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
          message: diag.nonConstConstructor,
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
    LocatedMessage message = diag.constructorNotFound
        .withArguments(name: name)
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
    required VariableDeclaration? thisVariable,
    required List<TypeParameter>? thisTypeParameters,
    required LocalScope? formalParameterScope,
    required ThisVariable? internalThisVariable,
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
      internalThisVariable: internalThisVariable,
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
    required ThisVariable? internalThisVariable,
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
      internalThisVariable: internalThisVariable,
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
    required List<FormalParameterBuilder>? formals,
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
    if (formals != null) {
      for (int i = 0; i < formals.length; i++) {
        FormalParameterBuilder parameter = formals[i];
        VariableDeclaration variable = parameter.variable!;
        // TODO(62401): Remove the cast when the flow analysis uses
        // [InternalExpressionVariable]s.
        typeInferrer.flowAnalysis.declare(
          (variable as InternalExpressionVariable).astVariable,
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
    required _SuperParameterArguments? superParameterArguments,
    required Uri fileUri,
    required ConstantContext constantContext,
    required List<Initializer> initializers,
  }) {
    _InitializerBuilder initializerBuilder = new _InitializerBuilder(
      compilerContext: compilerContext,
      problemReporting: problemReporting,
      bodyBuilderContext: bodyBuilderContext,
      typeInferrer: context.typeInferrer,
      coreTypes: _coreTypes,
      fileUri: fileUri,
    );
    initializerBuilder.processInitializers(
      libraryBuilder: libraryBuilder,
      libraryFeatures: libraryFeatures,
      superParameterArguments: superParameterArguments,
      initializers: initializers,
      asyncMarker: asyncModifier,
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
        message: diag.illegalMixinDueToConstructors.withArguments(
          className: bodyBuilderContext.className,
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
    required AsyncMarker asyncMarker,
    required Statement? body,
    required Uri fileUri,
    required BodyBuilderContext bodyBuilderContext,
    required VariableDeclaration? thisVariable,
    required List<Initializer> initializers,
    required ConstantContext constantContext,
    required ThisVariable? internalThisVariable,
  }) {
    const Forest forest = const Forest();
    AssignedVariables assignedVariables = context.assignedVariables;

    // Create variable get expressions for super parameters before finishing
    // the analysis of the assigned variables. Creating the expressions later
    // that point results in a flow analysis error.
    _SuperParameterArguments? superParameterArguments =
        _createSuperParameterArguments(
          assignedVariables: assignedVariables,
          formals: bodyBuilderContext.formals,
        );
    assignedVariables.finish();

    _declareFormals(
      typeInferrer: context.typeInferrer,
      bodyBuilderContext: bodyBuilderContext,
      thisVariable: thisVariable,
      formals: bodyBuilderContext.formals,
    );
    if (bodyBuilderContext.formals != null) {
      // TODO(johnniwinther): Avoid the need for this.
      int declaredParameterIndex = 0;
      for (FormalParameterBuilder parameter in bodyBuilderContext.formals!) {
        if (parameter.isExtensionThis) continue;
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
            VariableDeclaration originParameter = parameter.variable!;
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
              .getTearOffParameter(declaredParameterIndex);
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
        declaredParameterIndex++;
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
        asyncModifier: asyncMarker,
        body: body,
        superParameterArguments: superParameterArguments,
        fileUri: fileUri,
        constantContext: constantContext,
        initializers: initializers,
      );
    }

    DartType returnType = bodyBuilderContext.returnTypeContext;
    if (bodyBuilderContext.returnTypeBuilder is! OmittedTypeBuilder) {
      problemReporting.checkAsyncReturnType(
        libraryBuilder: libraryBuilder,
        typeEnvironment: context.typeInferrer.typeSchemaEnvironment,
        asyncMarker: asyncMarker,
        returnType: returnType,
        returnTypeBuilder: bodyBuilderContext.returnTypeBuilder,
        fileUri: fileUri,
      );
    }

    InferredFunctionBody? inferredFunctionBody;
    if (body != null) {
      inferredFunctionBody = context.typeInferrer.inferFunctionBody(
        fileUri: fileUri,
        fileOffset: bodyBuilderContext.memberNameOffset,
        returnType: returnType,
        asyncMarker: asyncMarker,
        body: body,
        parameters: <VariableDeclaration>[
          for (FormalParameterBuilder formal
              in bodyBuilderContext.formals ?? [])
            formal.variable!,
        ],
        internalThisVariable: internalThisVariable,
      );
      body = inferredFunctionBody.body;
    } else {
      // Normalize abstract members markers to sync.
      asyncMarker = AsyncMarker.Sync;
    }

    // No-such-method forwarders get their bodies injected during outline
    // building, so we should skip them here.
    bool isNoSuchMethodForwarder = bodyBuilderContext.isNoSuchMethodForwarder;
    if (body != null) {
      if (bodyBuilderContext.isExternalFunction || isNoSuchMethodForwarder) {
        body = new Block(<Statement>[
          new ExpressionStatement(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: diag.externalMethodWithBody,
              fileUri: fileUri,
              fileOffset: body.fileOffset,
              length: noLength,
            ),
          )..fileOffset = body.fileOffset,
          body,
        ])..fileOffset = body.fileOffset;
      }
    }
    DartType? emittedValueType = inferredFunctionBody?.emittedValueType;
    assert(
      !(asyncMarker == AsyncMarker.Sync && emittedValueType != null),
      "Unexpected emitted value type for sync function.",
    );
    assert(
      !(asyncMarker != AsyncMarker.Sync && emittedValueType == null),
      "Missing emitted value type for non-sync function.",
    );
    bodyBuilderContext.registerFunctionBody(
      body: body,
      scopeProviderInfo: inferredFunctionBody?.scopeProviderInfo,
      asyncMarker: asyncMarker,
      emittedValueType: emittedValueType,
    );
  }
}
