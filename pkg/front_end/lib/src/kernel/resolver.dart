// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show FormalParameterKind;
import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/clone.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_environment.dart';

import '../api_prototype/experimental_flags.dart';
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
import '../source/stack_listener_impl.dart' show AsyncModifier;
import '../type_inference/context_allocation_strategy.dart';
import '../type_inference/inference_results.dart';
import '../type_inference/inference_visitor_base.dart'
    show InferenceVisitorBase;
import '../type_inference/type_inference_engine.dart';
import '../type_inference/type_inferrer.dart'
    show
        TypeInferrer,
        InferredConstructorInitializers,
        InferredFieldInitializer,
        InferredFunctionBody;
import '../type_inference/type_schema.dart';
import '../util/expression_evaluation_helpers.dart';
import '../util/helpers.dart';
import 'assigned_variables_impl.dart';
import 'benchmarker.dart' show Benchmarker, BenchmarkSubdivides;
import 'body_builder.dart';
import 'body_builder_context.dart';
import 'expression_compilation_data.dart';
import 'external_ast_helper.dart' as extern;
import 'internal_ast.dart';
import 'internal_ast_helper.dart' as intern;

part 'resolver_helpers.dart';

class Resolver {
  final ClassHierarchy _classHierarchy;

  final CoreTypes _coreTypes;

  final TypeInferenceEngineImpl _typeInferenceEngine;

  final Benchmarker? _benchmarker;

  late CloneVisitorNotMembers _simpleCloner = new CloneVisitorNotMembers();

  new({
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

    List<InternalExpression> annotationsToBeInferred = [];
    for (Annotation annotation in annotations) {
      InternalExpression expression = bodyBuilder.buildAnnotation(
        atToken: annotation.atToken,
      );
      if (annotation.createFileUriExpression) {
        expression = intern.createFileUriExpression(
          expression: expression,
          fileUri: annotation.metadataBuilder.fileUri,
          fileOffset: annotation.metadataBuilder.atOffset,
        );
      }
      // It is important for the inference and backlog computations that the
      // annotation is already a child of [parent].
      // TODO(johnniwinther): Is the parent relation still needed?
      annotationsToBeInferred.add(expression);
    }
    List<Expression> inferredAnnotations = context.inferSingleTargetAnnotation(
      singleTarget: new SingleTargetAnnotations(
        annotatable,
        annotationsToBeInferred,
      ),
    );
    // TODO(johnniwinther): We need to process annotations within annotations.
    context.performBacklog(null);

    for (int index = 0; index < annotations.length; index++) {
      annotations[index].expression = inferredAnnotations[index];
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
            internalThisVariable: bodyBuilderContext
                .createInternalThisVariable(),
          )
          .expressionInferenceResult;
      initializer = inferenceResult.expression;
      fieldType = inferenceResult.inferredType;
    }
    context.performBacklog(result?.annotations);

    return (initializer, fieldType);
  }

  InferredFieldInitializer buildFieldInitializer({
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
    List<FormalParameterBuilder>? primaryConstructorInitializerScopeParameters =
        bodyBuilderContext.primaryConstructorInitializerScopeParameters;
    InternalThisVariable? internalThisVariable = bodyBuilderContext
        .createInternalThisVariable();
    BodyBuilder bodyBuilder = _createBodyBuilder(
      context: context,
      bodyBuilderContext: bodyBuilderContext,
      scope: scope,
      constantContext: constantContext,
      thisVariable: null,
      thisTypeParameters: null,
      formalParameterScope: null,
      internalThisVariable: internalThisVariable,
    );
    BuildFieldInitializerResult result = bodyBuilder.buildFieldInitializer(
      startToken: startToken,
      isLate: isLate,
    );
    _declareFormals(
      typeInferrer: context.typeInferrer,
      bodyBuilderContext: bodyBuilderContext,
      thisVariable: null,
      formals: primaryConstructorInitializerScopeParameters,
    );
    InferredFieldInitializer inferredFieldInitializer = context.typeInferrer
        .inferFieldInitializer(
          fileUri: fileUri,
          declaredType: declaredFieldType,
          initializer: result.initializer,
          inferenceDefaultType: inferenceDefaultType,
          internalThisVariable: internalThisVariable,
        );
    context.performBacklog(result.annotations);
    return inferredFieldInitializer;
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
        internalThisVariable: bodyBuilderContext.createInternalThisVariable(),
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
    InternalThisVariable? internalThisVariable = bodyBuilderContext
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
        asyncModifier: result.asyncModifier,
        body: result.body,
        fileUri: fileUri,
        bodyBuilderContext: bodyBuilderContext,
        thisVariable: functionBodyBuildingContext.thisVariable,
        initializers: result.initializers,
        constantContext: constantContext,
        internalThisVariable: internalThisVariable,
        forPrimaryConstructor: false,
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
    required Token? beginInitializers,
    required bool isConst,
    required bool forPrimaryConstructor,
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
    InternalThisVariable? internalThisVariable = bodyBuilderContext
        .createInternalThisVariable();
    BodyBuilder bodyBuilder = _createBodyBuilder(
      context: context,
      bodyBuilderContext: bodyBuilderContext,
      scope: typeParameterScope,
      constantContext: constantContext,
      formalParameterScope: formalParameterScope,
      thisVariable: null,
      thisTypeParameters: null,
      internalThisVariable: internalThisVariable,
    );
    constructorBuilder.inferFormalTypes(_classHierarchy);
    BuildInitializersResult result = bodyBuilder.buildInitializers(
      beginInitializers: beginInitializers,
    );
    List<InternalInitializer> initializers = result.initializers;
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
        asyncModifier: AsyncModifier.implicitSync,
        body: null,
        superParameterArguments: superParameterArguments,
        fileUri: fileUri,
        constantContext: constantContext,
        initializers: initializers,
        forPrimaryConstructor: forPrimaryConstructor,
        parameters: [
          for (FormalParameterBuilder formal
              in bodyBuilderContext.formals ?? [])
            formal.variable,
        ],
        internalThisVariable: internalThisVariable,
        contextAllocationStrategy:
            InferenceVisitorBase.createContextAllocationStrategy(),
      );
    }
    context.performBacklog(result.annotations);
  }

  List<InternalInitializer> buildInitializersUnfinished({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ExtensionScope extensionScope,
    required LookupScope typeParameterScope,
    required Uri fileUri,
    required Token? beginInitializers,
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

    List<Expression> expressions = context.inferSingleTargetAnnotation(
      singleTarget: new SingleTargetAnnotations(
        annotatable,
        result.expressions,
      ),
    );
    context.performBacklog(result.annotations);
    return expressions;
  }

  Expression buildParameterDefaultValue({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ExtensionScope extensionScope,
    required LookupScope scope,
    required Uri fileUri,
    required Token defaultValueToken,
    required DartType declaredType,
    required bool hasDeclaredDefaultValue,
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
    BuildParameterDefaultValueResult result = bodyBuilder
        .buildParameterDefaultValue(initializerToken: defaultValueToken);
    Expression defaultValue = context.typeInferrer.inferParameterDefaultValue(
      fileUri: fileUri,
      defaultValue: result.defaultValue,
      declaredType: declaredType,
      hasDeclaredDefaultValue: hasDeclaredDefaultValue,
    );
    context.performBacklog(result.annotations);
    return defaultValue;
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
    InternalThisVariable? internalThisVariable = bodyBuilderContext
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
          asyncModifier: AsyncModifier.implicitSync,
          body: null,
          fileUri: fileUri,
          bodyBuilderContext: bodyBuilderContext,
          thisVariable: functionBodyBuildingContext.thisVariable,
          initializers: result.initializers,
          constantContext: constantContext,
          internalThisVariable: internalThisVariable,
          forPrimaryConstructor: true,
        );
      }
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
    InternalThisVariable? internalThisVariable = bodyBuilderContext
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
        asyncModifier: result.asyncModifier,
        body: result.body,
        fileUri: fileUri,
        constantContext: constantContext,
        initializers: result.initializers,
        thisVariable: functionBodyBuildingContext.thisVariable,
        internalThisVariable: internalThisVariable,
        forPrimaryConstructor: true,
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
    required ExpressionCompilationData expressionCompilationData,
    required ExpressionEvaluationHelper expressionEvaluationHelper,
    required Variable? extensionThis,
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
    InternalThisVariable? internalThisVariable = bodyBuilderContext
        .createInternalThisVariable();

    int wildcardVariableIndex = 0;
    InternalVariable? internalExtensionThis;
    FormalParameterBuilder createFormalParameterBuilder(
      PositionalParameter parameter,
      String formalName,
    ) {
      InternalPositionalParameter formal = new InternalPositionalParameter(
        astVariable: parameter,
        isImplicitlyTyped: false,
        fileOffset: parameter.fileOffset,
      );
      bool isWildcard =
          libraryFeatures.wildcardVariables.isEnabled && formalName == '_';
      int? wildcardIndex;
      if (isWildcard) {
        wildcardIndex = wildcardVariableIndex++;
      }
      if (parameter == extensionThis) {
        internalExtensionThis = formal;
      }
      return new FormalParameterBuilder(
        kind: FormalParameterKind.requiredPositional,
        modifiers: Modifiers.empty,
        type: const ImplicitTypeBuilder(),
        name: formalName,
        nameOffset: null,
        fileOffset: formal.fileOffset,
        fileUri: fileUri,
        hasImmediatelyDeclaredDefaultValue: false,
        wildcardIndex: wildcardIndex,
        variable: formal,
      );
    }

    List<PositionalParameter> positionalParameters =
        expressionCompilationData.positionalParameters;
    List<FormalParameterBuilder>? formals = positionalParameters.length == 0
        ? null
        : new List<FormalParameterBuilder>.generate(
            positionalParameters.length,
            (int i) {
              PositionalParameter parameter = positionalParameters[i];
              return createFormalParameterBuilder(
                parameter,
                parameter.cosmeticName!,
              );
            },
            growable: false,
          );

    List<MapEntry<String, PositionalParameter>> extraParametersIfNotShadowing =
        expressionCompilationData.extraParametersIfNotShadowing.entries
            .toList();
    List<FormalParameterBuilder>? extraFormalsIfNotShadowing =
        extraParametersIfNotShadowing.length == 0
        ? null
        : new List<FormalParameterBuilder>.generate(
            extraParametersIfNotShadowing.length,
            (int i) {
              MapEntry<String, PositionalParameter> entry =
                  extraParametersIfNotShadowing[i];
              FormalParameterBuilder result = createFormalParameterBuilder(
                entry.value,
                entry.key,
              );
              // We don't actually pass it to the body builder which would
              // declares the normal parameters so do it here.
              context.assignedVariables.declare(result.variable);

              // Register it in the expression evaluation helper too so it can
              // actually be used on otherwise failed lookups.
              expressionEvaluationHelper.registerAdditionalScopeLookupResult(
                entry.key,
                result,
              );
              return result;
            },
            growable: false,
          );

    BodyBuilder bodyBuilder = _createBodyBuilder(
      context: context,
      bodyBuilderContext: bodyBuilderContext,
      scope: scope,
      thisVariable: internalExtensionThis,
      constantContext: constantContext,
      // TODO(johnniwinther): Should we provide these?
      thisTypeParameters: null,
      formalParameterScope: null,
      internalThisVariable: internalThisVariable,
    );
    int fileOffset = token.charOffset;

    List<NominalParameterBuilder>? typeParameterBuilders;
    for (TypeParameter typeParameter
        in expressionCompilationData.typeParameters) {
      typeParameterBuilders ??= <NominalParameterBuilder>[];
      typeParameterBuilders.add(
        new DillNominalParameterBuilder(
          typeParameter,
          loader: libraryBuilder.loader,
        ),
      );
    }

    BuildSingleExpressionResult result = bodyBuilder.buildSingleExpression(
      token: token,
      extraKnownVariables: expressionCompilationData.extraKnownVariables,
      fileOffset: fileOffset,
      typeParameterBuilders: typeParameterBuilders,
      formals: formals,
    );
    InternalExpression expression = result.expression;
    if (formals != null) {
      for (int i = 0; i < formals.length; i++) {
        InternalVariable variable = formals[i].variable;
        context.typeInferrer.flowAnalysis.declare(
          variable,
          new SharedTypeView(variable.type),
          initialized: true,
        );
      }
    }
    if (extraFormalsIfNotShadowing != null) {
      for (int i = 0; i < extraFormalsIfNotShadowing.length; i++) {
        InternalVariable variable = extraFormalsIfNotShadowing[i].variable;
        context.typeInferrer.flowAnalysis.declare(
          variable,
          new SharedTypeView(variable.type),
          initialized: true,
        );
      }
    }
    for (InternalVariable extraVariable
        in expressionCompilationData.extraKnownVariables) {
      context.typeInferrer.flowAnalysis.declare(
        extraVariable,
        new SharedTypeView(extraVariable.type),
        initialized: true,
      );
    }

    InternalReturnStatement internalReturn = intern.createReturnStatement(
      expression: expression,
      isArrow: true,
      fileOffset: TreeNode.noOffset,
    );

    InferredFunctionBody inferredFunctionBody = context.typeInferrer
        .inferFunctionBody(
          fileUri: fileUri,
          fileOffset: fileOffset,
          returnType: const DynamicType(),
          asyncModifier: AsyncModifier.implicitSync,
          body: internalReturn,
          expressionEvaluationHelper: expressionEvaluationHelper,
          contextAllocationStrategy:
              InferenceVisitorBase.createContextAllocationStrategy(),
          constructorContext: null,
        );
    ReturnStatement returnStatement =
        inferredFunctionBody.body as ReturnStatement;
    context.performBacklog(result.annotations);
    return returnStatement.expression!;
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
    ErrorText? errorText = problemReporting.checkStaticArguments(
      compilerContext: compilerContext,
      target: target,
      explicitTypeArguments: typeArguments,
      arguments: arguments,
      fileOffset: fileOffset,
      fileUri: fileUri,
    );
    if (errorText != null) {
      return intern.createInvalidExpressionFromErrorText(errorText);
    }

    if (target is Constructor) {
      if (!target.isConst) {
        return intern.createInvalidExpressionFromErrorText(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.nonConstConstructor,
            fileUri: fileUri,
            fileOffset: fileOffset,
            length: noLength,
          ),
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
        return intern.createInvalidExpressionFromErrorText(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.nonConstConstructor,
            fileUri: fileUri,
            fileOffset: fileOffset,
            length: noLength,
          ),
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
    return extern.createInvalidExpressionFromErrorText(
      problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: message.messageObject,
        fileUri: fileUri,
        fileOffset: message.charOffset,
        length: message.length,
        errorHasBeenReported: false,
      ),
    );
  }

  BodyBuilder _createBodyBuilder({
    required _ResolverContext context,
    required BodyBuilderContext bodyBuilderContext,
    required LookupScope scope,
    required ConstantContext constantContext,
    required InternalVariable? thisVariable,
    required List<TypeParameter>? thisTypeParameters,
    required LocalScope? formalParameterScope,
    required InternalThisVariable? internalThisVariable,
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
    required InternalVariable? thisVariable,
    required List<TypeParameter>? thisTypeParameters,
    required ConstantContext constantContext,
    required InternalThisVariable? internalThisVariable,
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
    required AssignedVariablesImpl assignedVariables,
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
              intern.createNamedExpression(
                formal.name,
                _createVariableGet(
                  assignedVariables: assignedVariables,
                  variable: formal.variable,
                  fileOffset: formal.fileOffset,
                ),
                fileOffset: formal.fileOffset,
              ),
            ),
          );
        } else {
          positionalCount++;
          firstPositionalOffset ??= formal.fileOffset;
          (superParametersAsArguments ??= []).add(
            new SuperPositionalArgument(
              _createVariableGet(
                assignedVariables: assignedVariables,
                variable: formal.variable,
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
  InternalExpression _createVariableGet({
    required AssignedVariablesImpl assignedVariables,
    required InternalVariable variable,
    required int fileOffset,
  }) {
    if (!variable.isLocalFunction && !variable.isWildcard) {
      assignedVariables.read(variable);
    }
    return intern.createVariableGet(variable, fileOffset: fileOffset);
  }

  void _declareFormals({
    required TypeInferrer typeInferrer,
    required BodyBuilderContext bodyBuilderContext,
    required InternalVariable? thisVariable,
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
        InternalVariable variable = parameter.variable;
        // TODO(62401): Remove the cast when the flow analysis uses
        // [InternalExpressionVariable]s.
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
    required AsyncModifier asyncModifier,
    required InternalStatement? body,
    required _SuperParameterArguments? superParameterArguments,
    required Uri fileUri,
    required ConstantContext constantContext,
    required List<InternalInitializer> initializers,
    required bool forPrimaryConstructor,
    required List<InternalVariable> parameters,
    required InternalThisVariable? internalThisVariable,
    required ContextAllocationStrategy contextAllocationStrategy,
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
      asyncModifier: asyncModifier,
      forPrimaryConstructor: forPrimaryConstructor,
      parameters: parameters,
      internalThisVariable: internalThisVariable,
      contextAllocationStrategy: contextAllocationStrategy,
      isConstructorWithoutBody: body == null,
    );

    if (body == null && !bodyBuilderContext.isExternalConstructor) {
      /// >If a generative constructor c is not a redirecting constructor
      /// >and no body is provided, then c implicitly has an empty body {}.
      /// We use an empty statement instead.
      bodyBuilderContext.registerNoBodyConstructor(
        thisVariable: internalThisVariable?.astVariable,
      );
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
        // It is allowed to have a primary constructor without a body, so
        // for primary constructors we report the error on the body and not
        // the name of the constructor.
        fileOffset: forPrimaryConstructor
            ? body.fileOffset
            : bodyBuilderContext.memberNameOffset,
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
    required AsyncModifier asyncModifier,
    required InternalStatement? body,
    required Uri fileUri,
    required BodyBuilderContext bodyBuilderContext,
    required InternalVariable? thisVariable,
    required List<InternalInitializer> initializers,
    required ConstantContext constantContext,
    required InternalThisVariable? internalThisVariable,
    required bool forPrimaryConstructor,
  }) {
    AssignedVariablesImpl assignedVariables = context.assignedVariables;

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
        Expression? defaultValue = parameter.variable.defaultValue;
        bool inferDefaultValue;
        if (parameter.isSuperInitializingFormal) {
          // Super-parameters can inherit the default value from the super
          // constructor so we only handle explicit default values here.
          inferDefaultValue = parameter.hasImmediatelyDeclaredDefaultValue;
        } else if (defaultValue != null) {
          inferDefaultValue = true;
        } else {
          inferDefaultValue = parameter.isOptional;
        }
        if (inferDefaultValue) {
          if (!parameter.defaultValueWasInferred) {
            // Coverage-ignore(suite): Not run.
            defaultValue ??= intern.createNullLiteral(
              // TODO(ahe): Should store: originParameter.fileOffset
              // https://github.com/dart-lang/sdk/issues/32289
              noLocation,
            );
            InternalFunctionParameter originParameter = parameter.variable;
            defaultValue = context.typeInferrer.inferParameterDefaultValue(
              fileUri: fileUri,
              defaultValue: defaultValue,
              declaredType: originParameter.type,
              hasDeclaredDefaultValue: parameter.hasDeclaredDefaultValue,
            );
            originParameter.updateDefaultValue(defaultValue);
            if (defaultValue is InvalidExpression) {
              originParameter.hasErroneousDefaultValue = true;
            }
            parameter.defaultValueWasInferred = true;
          }
          FunctionParameter? tearOffParameter = bodyBuilderContext
              .getTearOffParameter(declaredParameterIndex);
          if (tearOffParameter != null) {
            Expression tearOffDefaultValue = _simpleCloner.cloneInContext(
              defaultValue!,
            );
            tearOffParameter.defaultValue = tearOffDefaultValue
              ..parent = tearOffParameter;
            tearOffParameter.hasErroneousDefaultValue =
                parameter.variable.hasErroneousDefaultValue;
          }
        }
        declaredParameterIndex++;
      }
    }

    late List<InternalVariable>? parameters = [
      for (FormalParameterBuilder formal in bodyBuilderContext.formals ?? [])
        formal.variable,
    ];
    ScopeProviderInfo? scopeProviderInfo;
    ContextAllocationStrategy contextAllocationStrategy =
        InferenceVisitorBase.createContextAllocationStrategy();
    if (libraryBuilder.loader.isClosureContextLoweringEnabled) {
      scopeProviderInfo = contextAllocationStrategy
          .beginClosureContextAllocation(
            [
              for (InternalVariable parameter in parameters)
                new VariableWithCaptureKind(
                  parameter.astVariable,
                  context.typeInferrer.captureKindForVariable(parameter),
                ),
            ],
            thisVariable: internalThisVariable == null
                ? null
                : new VariableWithCaptureKind(
                    internalThisVariable.astVariable,
                    context.typeInferrer.captureKindForVariable(
                      internalThisVariable,
                    ),
                  ),
          );
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
        constantContext: constantContext,
        initializers: initializers,
        forPrimaryConstructor: forPrimaryConstructor,
        parameters: parameters,
        internalThisVariable: internalThisVariable,
        contextAllocationStrategy: contextAllocationStrategy,
      );
    }

    DartType returnType = bodyBuilderContext.returnTypeContext;
    if (bodyBuilderContext.returnTypeBuilder is! OmittedTypeBuilder) {
      problemReporting.checkAsyncReturnType(
        libraryBuilder: libraryBuilder,
        typeEnvironment: context.typeInferrer.typeSchemaEnvironment,
        asyncModifier: asyncModifier,
        returnType: returnType,
        returnTypeBuilder: bodyBuilderContext.returnTypeBuilder,
        fileUri: fileUri,
      );
    }

    InferredFunctionBody? inferredFunctionBody;
    Statement? inferredBody;
    if (body != null) {
      inferredFunctionBody = context.typeInferrer.inferFunctionBody(
        fileUri: fileUri,
        fileOffset: bodyBuilderContext.memberNameOffset,
        returnType: returnType,
        asyncModifier: asyncModifier,
        body: body,
        contextAllocationStrategy: contextAllocationStrategy,
        constructorContext: bodyBuilderContext.constructorContext,
      );
      inferredBody = inferredFunctionBody.body;
    } else {
      // Normalize abstract members markers to sync.
      asyncModifier = AsyncModifier.implicitSync;
    }

    // No-such-method forwarders get their bodies injected during outline
    // building, so we should skip them here.
    bool isNoSuchMethodForwarder = bodyBuilderContext.isNoSuchMethodForwarder;
    if (inferredBody != null) {
      if (bodyBuilderContext.isExternalFunction || isNoSuchMethodForwarder) {
        inferredBody = new Block(<Statement>[
          new ExpressionStatement(
            extern.createInvalidExpressionFromErrorText(
              problemReporting.buildProblem(
                compilerContext: compilerContext,
                message: diag.externalMethodWithBody,
                fileUri: fileUri,
                fileOffset: inferredBody.fileOffset,
                length: noLength,
              ),
            ),
          )..fileOffset = inferredBody.fileOffset,
          inferredBody,
        ])..fileOffset = inferredBody.fileOffset;
      }
    }
    DartType? emittedValueType = inferredFunctionBody?.emittedValueType;
    assert(
      !(asyncModifier.kind == AsyncMarker.Sync && emittedValueType != null),
      "Unexpected emitted value type for sync function.",
    );
    assert(
      !(asyncModifier.kind != AsyncMarker.Sync && emittedValueType == null),
      "Missing emitted value type for non-sync function.",
    );
    if (scopeProviderInfo != null) {
      contextAllocationStrategy.endClosureContextAllocation(scopeProviderInfo);
    }
    bodyBuilderContext.registerFunctionBody(
      body: inferredBody,
      scopeProviderInfo: scopeProviderInfo,
      asyncModifier: asyncModifier,
      emittedValueType: emittedValueType,
    );
  }
}
