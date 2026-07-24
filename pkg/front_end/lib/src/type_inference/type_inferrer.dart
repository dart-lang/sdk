// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart'
    hide MapPatternEntry;
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/type_environment.dart';

import '../base/extension_scope.dart';
import '../builder/function_signature.dart';
import '../kernel/assigned_variables_impl.dart';
import '../kernel/benchmarker.dart' show BenchmarkSubdivides, Benchmarker;
import '../kernel/internal_ast.dart';
import '../kernel/internal_ast_helper.dart' as intern;
import '../source/source_library_builder.dart' show SourceLibraryBuilder;
import '../source/stack_listener_impl.dart' show AsyncModifier;
import '../util/expression_evaluation_helpers.dart';
import '../util/helpers.dart';
import 'body_inference_context.dart';
import 'context_allocation_strategy.dart';
import 'inference_results.dart';
import 'inference_visitor.dart';
import 'inference_visitor_base.dart';
import 'object_access_target.dart';
import 'type_inference_engine.dart';
import 'type_schema.dart' show UnknownType;
import 'type_schema_environment.dart' show TypeSchemaEnvironment;

/// Keeps track of the local state for the type inference that occurs during
/// compilation of a single method body or top level initializer.
///
/// This class describes the interface for use by clients of type inference
/// (e.g. BodyBuilder).  Derived classes should derive from [TypeInferrerImpl].
abstract class TypeInferrer {
  /// Gets the [TypeSchemaEnvironment] being used for type inference.
  TypeSchemaEnvironment get typeSchemaEnvironment;

  /// Gets the [ExtensionScope] being used for type inference.
  ExtensionScope get extensionScope;

  /// Returns the [FlowAnalysis] used during inference.
  FlowAnalysis<
    InternalNode,
    InternalStatement,
    InternalExpression,
    InternalVariable
  >
  get flowAnalysis;

  AssignedVariablesImpl get assignedVariables;

  /// Performs type inference on the given field [initializer] with the given
  /// [declaredType], if any.
  ///
  /// When [declaredType] is `null` and the [initializer] has type `Null`, the
  /// inferred field type is determined by [inferenceDefaultType].
  InferredFieldInitializer inferFieldInitializer({
    required Uri fileUri,
    DartType? declaredType,
    required InternalExpression initializer,
    required InferenceDefaultType inferenceDefaultType,
    required InternalThisVariable? internalThisVariable,
  });

  /// Performs type inference on the given function body.
  InferredFunctionBody inferFunctionBody({
    required Uri fileUri,
    required int fileOffset,
    required DartType returnType,
    required AsyncModifier asyncModifier,
    required InternalStatement body,
    required ContextAllocationStrategy contextAllocationStrategy,
    required ConstructorContext? constructorContext,
    ExpressionEvaluationHelper? expressionEvaluationHelper,
  });

  /// Performs type inference on the given constructor initializer.
  InferredConstructorInitializers inferInitializers({
    required Uri fileUri,
    required ConstructorContext constructorContext,
    required List<InternalInitializer> initializers,
    required ContextAllocationStrategy contextAllocationStrategy,
  });

  /// Performs type inference on the metadata annotations of the [annotatable].
  ///
  /// If [indices] is provided, only the annotations at the given indices are
  /// inferred. Otherwise all annotations are inferred.
  List<Expression> inferMetadata({
    required Uri fileUri,
    required Annotatable annotatable,
    required List<InternalExpression> annotations,
  });

  /// Performs type inference on the given function parameter default value
  /// expression.
  Expression inferParameterDefaultValue({
    required Uri fileUri,
    required InternalExpression defaultValue,
    required DartType declaredType,
    required bool hasDeclaredDefaultValue,
  });

  /// Infers the type arguments a redirecting factory target reference.
  List<DartType>? inferRedirectingFactoryTypeArguments({
    required DartType typeContext,
    required FunctionNode redirectingFactoryFunction,
    required Uri fileUri,
    required int fileOffset,
    required Member target,
    required FunctionType targetType,
  });

  /// Returns [CaptureKind] for the given [variable].
  CaptureKind captureKindForVariable(InternalVariable variable);
}

/// Concrete implementation of [TypeInferrer] specialized to work with kernel
/// objects.
class TypeInferrerImpl implements TypeInferrer {
  final TypeInferenceEngine engine;

  final OperationsCfe operations;

  TypeAnalyzerOptions typeAnalyzerOptions;

  @override
  late final FlowAnalysis<
    InternalNode,
    InternalStatement,
    InternalExpression,
    InternalVariable
  >
  flowAnalysis = new FlowAnalysis(
    operations,
    assignedVariables,
    typeAnalyzerOptions: typeAnalyzerOptions,
  );

  @override
  final AssignedVariablesImpl assignedVariables;

  final InferenceDataForTesting? dataForTesting;

  @override
  final TypeSchemaEnvironment typeSchemaEnvironment;

  final InterfaceType? thisType;

  final SourceLibraryBuilder libraryBuilder;

  @override
  final ExtensionScope extensionScope;

  late final StaticTypeContext staticTypeContext =
      new StaticTypeContextImpl.direct(
        libraryBuilder.library,
        typeSchemaEnvironment,
        thisType: thisType,
      );

  new(
    this.engine,
    this.thisType,
    this.libraryBuilder,
    this.extensionScope,
    this.assignedVariables,
    this.dataForTesting,
  ) : typeSchemaEnvironment = engine.typeSchemaEnvironment,
      operations = new OperationsCfe(
        engine.typeSchemaEnvironment,
        fieldNonPromotabilityInfo: libraryBuilder.fieldNonPromotabilityInfo,
        typeCacheNonNullable: engine.typeCacheNonNullable,
        typeCacheNullable: engine.typeCacheNullable,
        typeCacheLegacy: engine.typeCacheLegacy,
      ),
      typeAnalyzerOptions = new TypeAnalyzerOptions(
        patternsEnabled: libraryBuilder.libraryFeatures.patterns.isEnabled,
        inferenceUpdate3Enabled:
            libraryBuilder.libraryFeatures.inferenceUpdate3.isEnabled,
        respectImplicitlyTypedVarInitializers:
            libraryBuilder.libraryFeatures.constructorTearoffs.isEnabled,
        fieldPromotionEnabled:
            libraryBuilder.libraryFeatures.inferenceUpdate2.isEnabled,
        inferenceUpdate4Enabled:
            libraryBuilder.libraryFeatures.inferenceUpdate4.isEnabled,
        thisPromotionEnabled:
            libraryBuilder.libraryFeatures.thisPromotion.isEnabled,
        soundFlowAnalysisEnabled:
            libraryBuilder.libraryFeatures.soundFlowAnalysis.isEnabled,
      );

  bool get isClosureContextLoweringEnabled =>
      libraryBuilder.loader.isClosureContextLoweringEnabled;

  InferenceVisitorBase _createInferenceVisitor({
    required Uri fileUri,
    ConstructorContext? constructorContext,
    ExpressionEvaluationHelper? expressionEvaluationHelper,
    required ContextAllocationStrategy contextAllocationStrategy,
  }) {
    // For full (non-top level) inference, we need access to the
    // InferenceHelper so that we can perform error reporting.
    return new InferenceVisitorImpl(
      this,
      fileUri,
      constructorContext,
      operations,
      typeAnalyzerOptions,
      expressionEvaluationHelper,
      contextAllocationStrategy: contextAllocationStrategy,
    );
  }

  @override
  InferredFieldInitializer inferFieldInitializer({
    required Uri fileUri,
    DartType? declaredType,
    required InternalExpression initializer,
    required InferenceDefaultType inferenceDefaultType,
    required InternalThisVariable? internalThisVariable,
  }) {
    InferenceVisitorBase visitor = _createInferenceVisitor(
      fileUri: fileUri,
      contextAllocationStrategy:
          InferenceVisitorBase.createContextAllocationStrategy(),
    );
    ScopeProviderInfo? scopeProviderInfo;
    if (isClosureContextLoweringEnabled) {
      scopeProviderInfo = visitor.beginFieldInference(
        internalThisVariable: internalThisVariable,
      );
    }
    ExpressionInferenceResult initializerResult = visitor.inferExpression(
      initializer,
      declaredType ?? const UnknownType(),
      isVoidAllowed: true,
    );
    if (scopeProviderInfo != null) {
      visitor.endFieldInference(scopeProviderInfo);
    }
    if (declaredType != null) {
      // If the field has a declared type, check for assignability.
      initializerResult = visitor.ensureAssignableResult(
        declaredType,
        initializerResult,
        isVoidAllowed: declaredType is VoidType,
        assignedNode: initializer,
      );
    } else {
      // If the field has no declared type, compute the field type from the
      // inferred type.
      initializerResult = new ExpressionInferenceResult(
        visitor.inferDeclarationType(
          initializerResult.inferredType,
          inferenceDefaultType: inferenceDefaultType,
        ),
        initializerResult.expression,
      );
    }
    visitor.checkCleanState();
    return new InferredFieldInitializer(initializerResult, scopeProviderInfo);
  }

  @override
  InferredFunctionBody inferFunctionBody({
    required Uri fileUri,
    required int fileOffset,
    required DartType returnType,
    required AsyncModifier asyncModifier,
    required InternalStatement body,
    required ContextAllocationStrategy contextAllocationStrategy,
    required ConstructorContext? constructorContext,
    ExpressionEvaluationHelper? expressionEvaluationHelper,
  }) {
    InferenceVisitorBase visitor = _createInferenceVisitor(
      fileUri: fileUri,
      constructorContext: constructorContext,
      expressionEvaluationHelper: expressionEvaluationHelper,
      contextAllocationStrategy: contextAllocationStrategy,
    );
    BodyInferenceContext bodyContext = new BodyInferenceContext(
      visitor,
      asyncModifier.kind,
      returnType,
      needToInferReturnType: false,
      isRoot: true,
    );
    StatementInferenceResult result = visitor.inferStatement(body, bodyContext);
    if (dataForTesting != null) {
      // Coverage-ignore-block(suite): Not run.
      if (!flowAnalysis.isReachable) {
        dataForTesting!.flowAnalysisResult.functionBodiesThatDontComplete.add(
          body,
        );
      }
    }
    result = bodyContext.handleImplicitReturn(
      visitor,
      body,
      result,
      fileOffset,
    );
    visitor.checkCleanState();
    DartType? emittedValueType = bodyContext.emittedValueType;
    assert(asyncModifier.kind == AsyncMarker.Sync || emittedValueType != null);
    flowAnalysis.finish();
    Statement inferredBody = result.statement;
    libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(body, inferredBody);
    return new InferredFunctionBody(inferredBody, emittedValueType);
  }

  @override
  List<DartType>? inferRedirectingFactoryTypeArguments({
    required DartType typeContext,
    required FunctionNode redirectingFactoryFunction,
    required Uri fileUri,
    required int fileOffset,
    required Member target,
    required FunctionType targetType,
  }) {
    ContextAllocationStrategy contextAllocationStrategy =
        InferenceVisitorBase.createContextAllocationStrategy();
    InferenceVisitorBase visitor = _createInferenceVisitor(
      fileUri: fileUri,
      contextAllocationStrategy: contextAllocationStrategy,
    );

    List<InternalVariable> positionalParameters = [
      for (PositionalParameter positionalParameter
          in redirectingFactoryFunction.positionalParameters)
        new InternalPositionalParameter(
          defaultValue: null,
          astVariable: positionalParameter,
          isImplicitlyTyped: false,
          fileOffset: positionalParameter.fileOffset,
        ),
    ];
    List<InternalVariable> namedParameters = [
      for (NamedParameter namedParameter
          in redirectingFactoryFunction.namedParameters)
        new InternalNamedParameter(
          defaultValue: null,
          astVariable: namedParameter,
          isImplicitlyTyped: false,
          fileOffset: namedParameter.fileOffset,
        ),
    ];

    ScopeProviderInfo? scopeProviderInfo;
    if (isClosureContextLoweringEnabled) {
      scopeProviderInfo = contextAllocationStrategy
          .beginClosureContextAllocation([
            for (InternalVariable positionalParameter in positionalParameters)
              new VariableWithCaptureKind(
                positionalParameter.astVariable,
                captureKindForVariable(positionalParameter),
              ),
            for (InternalVariable namedParameter in namedParameters)
              new VariableWithCaptureKind(
                namedParameter.astVariable,
                captureKindForVariable(namedParameter),
              ),
          ], thisVariable: null);
    }

    List<Argument> arguments = [];
    int positionalCount = 0;
    for (InternalVariable parameter in positionalParameters) {
      flowAnalysis.declare(
        parameter,
        new SharedTypeView(parameter.type),
        initialized: true,
      );
      InternalExpression variableGet = intern.createVariableGet(
        parameter,
        fileOffset: parameter.fileOffset,
      );
      arguments.add(new PositionalArgument(variableGet));
      positionalCount++;
    }
    for (InternalVariable parameter in namedParameters) {
      flowAnalysis.declare(
        parameter,
        new SharedTypeView(parameter.type),
        initialized: true,
      );
      InternalNamedExpression namedExpression = intern.createNamedExpression(
        parameter.cosmeticName!,
        intern.createVariableGet(parameter, fileOffset: parameter.fileOffset),
        fileOffset: parameter.fileOffset,
      );

      arguments.add(new NamedArgument(namedExpression));
    }
    // If arguments are created using [ArgumentsImpl], and the
    // type arguments are omitted, they are to be inferred.
    ActualArguments targetInvocationArguments = new ActualArguments(
      argumentList: arguments,
      hasNamedBeforePositional: false,
      positionalCount: positionalCount,
      fileOffset: fileOffset,
    );

    InvocationInferenceResult result = visitor.inferInvocation(
      visitor,
      typeContext,
      fileOffset,
      new InvocationTargetFunctionType(targetType),
      null,
      targetInvocationArguments,
      staticTarget: target,
    );
    visitor.checkCleanState();

    if (scopeProviderInfo != null) {
      contextAllocationStrategy.endClosureContextAllocation(scopeProviderInfo);
      redirectingFactoryFunction.scope = scopeProviderInfo.scope;
    }

    DartType resultType = result.inferredType;
    if (resultType is TypeDeclarationType) {
      return resultType.typeArguments;
    } else {
      return null;
    }
  }

  @override
  InferredConstructorInitializers inferInitializers({
    required Uri fileUri,
    required ConstructorContext constructorContext,
    required List<InternalInitializer> initializers,
    required ContextAllocationStrategy contextAllocationStrategy,
  }) {
    // Use polymorphic dispatch on [KernelInitializer] to perform whatever
    // kind of type inference is correct for this kind of initializer.
    // TODO(paulberry): experiment to see if dynamic dispatch would be better,
    // so that the type hierarchy will be simpler (which may speed up "is"
    // checks).
    InferenceVisitorBase visitor = _createInferenceVisitor(
      fileUri: fileUri,
      constructorContext: constructorContext,
      contextAllocationStrategy: contextAllocationStrategy,
    );
    List<InitializerInferenceResult> results = [];
    for (InternalInitializer initializer in initializers) {
      results.add(visitor.inferInitializer(initializer));
    }
    visitor.checkCleanState();
    return new InferredConstructorInitializers(results);
  }

  @override
  List<Expression> inferMetadata({
    required Uri fileUri,
    required Annotatable annotatable,
    required List<InternalExpression> annotations,
  }) {
    InferenceVisitorBase visitor = _createInferenceVisitor(
      fileUri: fileUri,
      contextAllocationStrategy:
          InferenceVisitorBase.createContextAllocationStrategy(),
    );
    List<Expression> result = visitor.inferMetadata(
      visitor,
      annotatable,
      annotations,
    );
    visitor.checkCleanState();
    return result;
  }

  @override
  Expression inferParameterDefaultValue({
    required Uri fileUri,
    required InternalExpression defaultValue,
    required DartType declaredType,
    required bool hasDeclaredDefaultValue,
  }) {
    InferenceVisitorBase visitor = _createInferenceVisitor(
      fileUri: fileUri,
      contextAllocationStrategy:
          InferenceVisitorBase.createContextAllocationStrategy(),
    );
    ExpressionInferenceResult result = visitor.inferExpression(
      defaultValue,
      declaredType,
    );
    Expression inferredDefaultValue;
    if (hasDeclaredDefaultValue) {
      inferredDefaultValue = visitor
          .ensureAssignableResult(
            declaredType,
            result,
            assignedNode: defaultValue,
          )
          .expression;
    } else {
      inferredDefaultValue = result.expression;
    }
    visitor.checkCleanState();
    return inferredDefaultValue;
  }

  @override
  CaptureKind captureKindForVariable(InternalVariable variable) {
    int variableKey = assignedVariables.promotionKeyStore.keyForVariable(
      variable,
    );

    if (assignedVariables.outsideAsserts.captured.contains(variableKey) ||
        assignedVariables.outsideAsserts.readCaptured.contains(variableKey)) {
      return CaptureKind.directCaptured;
    } else if (assignedVariables.insideAsserts.captured.contains(variableKey) ||
        assignedVariables.insideAsserts.readCaptured.contains(variableKey)) {
      return CaptureKind.assertCaptured;
    } else {
      return CaptureKind.notCaptured;
    }
  }
}

// Coverage-ignore(suite): Not run.
class TypeInferrerImplBenchmarked implements TypeInferrer {
  final TypeInferrerImpl impl;
  final Benchmarker benchmarker;

  @override
  final ExtensionScope extensionScope;

  new(
    TypeInferenceEngine engine,
    InterfaceType? thisType,
    SourceLibraryBuilder libraryBuilder,
    this.extensionScope,
    AssignedVariablesImpl assignedVariables,
    InferenceDataForTesting? dataForTesting,
    this.benchmarker,
  ) : impl = new TypeInferrerImpl(
        engine,
        thisType,
        libraryBuilder,
        extensionScope,
        assignedVariables,
        dataForTesting,
      );

  @override
  AssignedVariablesImpl get assignedVariables => impl.assignedVariables;

  @override
  FlowAnalysis<
    InternalNode,
    InternalStatement,
    InternalExpression,
    InternalVariable
  >
  get flowAnalysis => impl.flowAnalysis;

  @override
  TypeSchemaEnvironment get typeSchemaEnvironment => impl.typeSchemaEnvironment;

  @override
  InferredFieldInitializer inferFieldInitializer({
    required Uri fileUri,
    DartType? declaredType,
    required InternalExpression initializer,
    required InferenceDefaultType inferenceDefaultType,
    required InternalThisVariable? internalThisVariable,
  }) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferFieldInitializer);
    InferredFieldInitializer result = impl.inferFieldInitializer(
      fileUri: fileUri,
      declaredType: declaredType,
      initializer: initializer,
      inferenceDefaultType: inferenceDefaultType,
      internalThisVariable: internalThisVariable,
    );
    benchmarker.endSubdivide();
    return result;
  }

  @override
  InferredFunctionBody inferFunctionBody({
    required Uri fileUri,
    required int fileOffset,
    required DartType returnType,
    required AsyncModifier asyncModifier,
    required InternalStatement body,
    required ContextAllocationStrategy contextAllocationStrategy,
    required ConstructorContext? constructorContext,
    ExpressionEvaluationHelper? expressionEvaluationHelper,
  }) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferFunctionBody);
    InferredFunctionBody result = impl.inferFunctionBody(
      fileUri: fileUri,
      fileOffset: fileOffset,
      returnType: returnType,
      asyncModifier: asyncModifier,
      body: body,
      expressionEvaluationHelper: expressionEvaluationHelper,
      contextAllocationStrategy: contextAllocationStrategy,
      constructorContext: constructorContext,
    );
    benchmarker.endSubdivide();
    return result;
  }

  @override
  InferredConstructorInitializers inferInitializers({
    required Uri fileUri,
    required ConstructorContext constructorContext,
    required List<InternalInitializer> initializers,
    required ContextAllocationStrategy<ScopeProviderInfo>
    contextAllocationStrategy,
  }) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferInitializers);
    InferredConstructorInitializers result = impl.inferInitializers(
      fileUri: fileUri,
      constructorContext: constructorContext,
      initializers: initializers,
      contextAllocationStrategy: contextAllocationStrategy,
    );
    benchmarker.endSubdivide();
    return result;
  }

  @override
  List<Expression> inferMetadata({
    required Uri fileUri,
    required Annotatable annotatable,
    required List<InternalExpression> annotations,
  }) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferMetadata);
    List<Expression> result = impl.inferMetadata(
      fileUri: fileUri,
      annotatable: annotatable,
      annotations: annotations,
    );
    benchmarker.endSubdivide();
    return result;
  }

  @override
  Expression inferParameterDefaultValue({
    required Uri fileUri,
    required InternalExpression defaultValue,
    required DartType declaredType,
    required bool hasDeclaredDefaultValue,
  }) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferParameterInitializer);
    Expression result = impl.inferParameterDefaultValue(
      fileUri: fileUri,
      defaultValue: defaultValue,
      declaredType: declaredType,
      hasDeclaredDefaultValue: hasDeclaredDefaultValue,
    );
    benchmarker.endSubdivide();
    return result;
  }

  @override
  List<DartType>? inferRedirectingFactoryTypeArguments({
    required DartType typeContext,
    required FunctionNode redirectingFactoryFunction,
    required Uri fileUri,
    required int fileOffset,
    required Member target,
    required FunctionType targetType,
  }) {
    benchmarker.beginSubdivide(
      BenchmarkSubdivides.inferRedirectingFactoryTypeArguments,
    );
    List<DartType>? result = impl.inferRedirectingFactoryTypeArguments(
      typeContext: typeContext,
      redirectingFactoryFunction: redirectingFactoryFunction,
      fileUri: fileUri,
      fileOffset: fileOffset,
      target: target,
      targetType: targetType,
    );
    benchmarker.endSubdivide();
    return result;
  }

  @override
  CaptureKind captureKindForVariable(InternalVariable variable) {
    return impl.captureKindForVariable(variable);
  }
}

class InferredFunctionBody(this.body, this.emittedValueType) {
  final Statement body;
  final DartType? emittedValueType;
}

class InferredFieldInitializer(
  this.expressionInferenceResult,
  this.scopeProviderInfo,
) {
  final ExpressionInferenceResult expressionInferenceResult;
  final ScopeProviderInfo? scopeProviderInfo;
}

class InferredConstructorInitializers(this.initializersInferenceResult) {
  final List<InitializerInferenceResult> initializersInferenceResult;
}

/// Contextual information used to infer constructor initializers and body.
abstract class ConstructorContext {
  /// Computes the type of a field with the declared [fieldType] as used in
  /// the context of this constructor.
  ///
  /// This is used for lowered constructors where the declared field type uses
  /// type parameters declared in the declaration which must be replace with the
  /// type parameters on the lowered procedure.
  DartType substituteFieldType(DartType fieldType);

  /// The signature of the constructor.
  FunctionSignature get signature;

  /// The variable used for `this`, if any.
  Variable? get thisVariable;
}
