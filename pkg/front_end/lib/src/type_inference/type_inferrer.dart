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
import '../kernel/assigned_variables_impl.dart';
import '../kernel/benchmarker.dart' show BenchmarkSubdivides, Benchmarker;
import '../kernel/internal_ast.dart';
import '../source/source_constructor_builder.dart';
import '../source/source_library_builder.dart' show SourceLibraryBuilder;
import '../util/helpers.dart';
import 'closure_context.dart';
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
  FlowAnalysis<TreeNode, Statement, Expression, ExpressionVariable>
  get flowAnalysis;

  AssignedVariablesImpl get assignedVariables;

  /// Performs type inference on the given field [initializer] with the given
  /// [declaredType], if any.
  ///
  /// When [declaredType] is `null` and the [initializer] has type `Null`, the
  /// inferred field type is determined by [inferenceDefaultType].
  ExpressionInferenceResult inferFieldInitializer({
    required Uri fileUri,
    DartType? declaredType,
    required Expression initializer,
    required InferenceDefaultType inferenceDefaultType,
  });

  /// Performs type inference on the given function body.
  InferredFunctionBody inferFunctionBody({
    required Uri fileUri,
    required int fileOffset,
    required DartType returnType,
    required AsyncMarker asyncMarker,
    required Statement body,
    required List<VariableDeclaration> parameters,
    required ThisVariable? internalThisVariable,
    ExpressionEvaluationHelper? expressionEvaluationHelper,
  });

  /// Performs type inference on the given constructor initializer.
  InitializerInferenceResult inferInitializer({
    required Uri fileUri,
    required SourceConstructorBuilder constructorBuilder,
    required Initializer initializer,
  });

  /// Performs type inference on the given metadata [annotations].
  ///
  /// If [indices] is provided, only the annotations at the given indices are
  /// inferred. Otherwise all annotations are inferred.
  void inferMetadata({
    required Uri fileUri,
    required Annotatable annotatable,
    required List<int>? indices,
  });

  /// Performs type inference on the given function parameter initializer
  /// expression.
  Expression inferParameterInitializer({
    required Uri fileUri,
    required Expression initializer,
    required DartType declaredType,
    required bool hasDeclaredInitializer,
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
}

/// Concrete implementation of [TypeInferrer] specialized to work with kernel
/// objects.
class TypeInferrerImpl implements TypeInferrer {
  final TypeInferenceEngine engine;

  final OperationsCfe operations;

  TypeAnalyzerOptions typeAnalyzerOptions;

  @override
  late final FlowAnalysis<TreeNode, Statement, Expression, ExpressionVariable>
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

  TypeInferrerImpl(
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
        soundFlowAnalysisEnabled:
            libraryBuilder.libraryFeatures.soundFlowAnalysis.isEnabled,
      );

  bool get isClosureContextLoweringEnabled => libraryBuilder
      .loader
      .target
      .backendTarget
      .flags
      .isClosureContextLoweringEnabled;

  InferenceVisitorBase _createInferenceVisitor({
    required Uri fileUri,
    SourceConstructorBuilder? constructorBuilder,
    ExpressionEvaluationHelper? expressionEvaluationHelper,
  }) {
    // For full (non-top level) inference, we need access to the
    // InferenceHelper so that we can perform error reporting.
    return new InferenceVisitorImpl(
      this,
      fileUri,
      constructorBuilder,
      operations,
      typeAnalyzerOptions,
      expressionEvaluationHelper,
    );
  }

  @override
  ExpressionInferenceResult inferFieldInitializer({
    required Uri fileUri,
    DartType? declaredType,
    required Expression initializer,
    required InferenceDefaultType inferenceDefaultType,
  }) {
    InferenceVisitorBase visitor = _createInferenceVisitor(fileUri: fileUri);
    ExpressionInferenceResult initializerResult = visitor.inferExpression(
      initializer,
      declaredType ?? const UnknownType(),
      isVoidAllowed: true,
    );
    if (declaredType != null) {
      // If the field has a declared type, check for assignability.
      initializerResult = visitor.ensureAssignableResult(
        declaredType,
        initializerResult,
        isVoidAllowed: declaredType is VoidType,
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
    return initializerResult;
  }

  @override
  InferredFunctionBody inferFunctionBody({
    required Uri fileUri,
    required int fileOffset,
    required DartType returnType,
    required AsyncMarker asyncMarker,
    required Statement body,
    required List<VariableDeclaration> parameters,
    required ThisVariable? internalThisVariable,
    ExpressionEvaluationHelper? expressionEvaluationHelper,
  }) {
    InferenceVisitorBase visitor = _createInferenceVisitor(
      fileUri: fileUri,
      expressionEvaluationHelper: expressionEvaluationHelper,
    );
    ClosureContext closureContext = new ClosureContext(
      visitor,
      asyncMarker,
      returnType,
      false,
    );
    ScopeProviderInfo? scopeProviderInfo;
    if (isClosureContextLoweringEnabled) {
      scopeProviderInfo = visitor.beginFunctionBodyInference(
        parameters,
        internalThisVariable: internalThisVariable,
      );
    }
    StatementInferenceResult result = visitor.inferStatement(
      body,
      closureContext,
    );
    if (scopeProviderInfo != null) {
      visitor.endFunctionBodyInference(scopeProviderInfo);
    }
    if (dataForTesting != null) {
      // Coverage-ignore-block(suite): Not run.
      if (!flowAnalysis.isReachable) {
        dataForTesting!.flowAnalysisResult.functionBodiesThatDontComplete.add(
          body,
        );
      }
    }
    result = closureContext.handleImplicitReturn(
      visitor,
      body,
      result,
      fileOffset,
    );
    visitor.checkCleanState();
    DartType? emittedValueType = closureContext.emittedValueType;
    assert(asyncMarker == AsyncMarker.Sync || emittedValueType != null);
    flowAnalysis.finish();
    return new InferredFunctionBody(
      result.hasChanged ? result.statement : body,
      emittedValueType,
      scopeProviderInfo,
    );
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
    InferenceVisitorBase visitor = _createInferenceVisitor(fileUri: fileUri);
    List<Argument> arguments = [];
    int positionalCount = 0;
    for (VariableDeclaration parameter
        in redirectingFactoryFunction.positionalParameters) {
      flowAnalysis.declare(
        parameter,
        new SharedTypeView(parameter.type),
        initialized: true,
      );
      Expression variableGet = new VariableGet(parameter);
      arguments.add(new PositionalArgument(variableGet));
      positionalCount++;
    }
    for (VariableDeclaration parameter
        in redirectingFactoryFunction.namedParameters) {
      flowAnalysis.declare(
        parameter,
        new SharedTypeView(parameter.type),
        initialized: true,
      );
      NamedExpression namedExpression = new NamedExpression(
        parameter.name!,
        new VariableGet(parameter),
      );
      arguments.add(new NamedArgument(namedExpression));
    }
    // If arguments are created using [ArgumentsImpl], and the
    // type arguments are omitted, they are to be inferred.
    ActualArguments targetInvocationArguments = new ActualArguments(
      argumentList: arguments,
      hasNamedBeforePositional: false,
      positionalCount: positionalCount,
    )..fileOffset = fileOffset;

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
    DartType resultType = result.inferredType;
    if (resultType is TypeDeclarationType) {
      return resultType.typeArguments;
    } else {
      return null;
    }
  }

  @override
  InitializerInferenceResult inferInitializer({
    required Uri fileUri,
    required SourceConstructorBuilder constructorBuilder,
    required Initializer initializer,
  }) {
    // Use polymorphic dispatch on [KernelInitializer] to perform whatever
    // kind of type inference is correct for this kind of initializer.
    // TODO(paulberry): experiment to see if dynamic dispatch would be better,
    // so that the type hierarchy will be simpler (which may speed up "is"
    // checks).
    InferenceVisitorBase visitor = _createInferenceVisitor(
      fileUri: fileUri,
      constructorBuilder: constructorBuilder,
    );
    InitializerInferenceResult result = visitor.inferInitializer(initializer);
    visitor.checkCleanState();
    return result;
  }

  @override
  void inferMetadata({
    required Uri fileUri,
    required Annotatable annotatable,
    required List<int>? indices,
  }) {
    InferenceVisitorBase visitor = _createInferenceVisitor(fileUri: fileUri);
    visitor.inferMetadata(visitor, annotatable, indices: indices);
    visitor.checkCleanState();
  }

  @override
  Expression inferParameterInitializer({
    required Uri fileUri,
    required Expression initializer,
    required DartType declaredType,
    required bool hasDeclaredInitializer,
  }) {
    InferenceVisitorBase visitor = _createInferenceVisitor(fileUri: fileUri);
    ExpressionInferenceResult result = visitor.inferExpression(
      initializer,
      declaredType,
    );
    if (hasDeclaredInitializer) {
      initializer = visitor
          .ensureAssignableResult(declaredType, result)
          .expression;
    }
    visitor.checkCleanState();
    return initializer;
  }
}

// Coverage-ignore(suite): Not run.
class TypeInferrerImplBenchmarked implements TypeInferrer {
  final TypeInferrerImpl impl;
  final Benchmarker benchmarker;

  @override
  final ExtensionScope extensionScope;

  TypeInferrerImplBenchmarked(
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
  FlowAnalysis<TreeNode, Statement, Expression, ExpressionVariable>
  get flowAnalysis => impl.flowAnalysis;

  @override
  TypeSchemaEnvironment get typeSchemaEnvironment => impl.typeSchemaEnvironment;

  @override
  ExpressionInferenceResult inferFieldInitializer({
    required Uri fileUri,
    DartType? declaredType,
    required Expression initializer,
    required InferenceDefaultType inferenceDefaultType,
  }) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferFieldInitializer);
    ExpressionInferenceResult result = impl.inferFieldInitializer(
      fileUri: fileUri,
      declaredType: declaredType,
      initializer: initializer,
      inferenceDefaultType: inferenceDefaultType,
    );
    benchmarker.endSubdivide();
    return result;
  }

  @override
  InferredFunctionBody inferFunctionBody({
    required Uri fileUri,
    required int fileOffset,
    required DartType returnType,
    required AsyncMarker asyncMarker,
    required Statement body,
    required List<VariableDeclaration> parameters,
    required ThisVariable? internalThisVariable,
    ExpressionEvaluationHelper? expressionEvaluationHelper,
  }) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferFunctionBody);
    InferredFunctionBody result = impl.inferFunctionBody(
      fileUri: fileUri,
      fileOffset: fileOffset,
      returnType: returnType,
      asyncMarker: asyncMarker,
      body: body,
      expressionEvaluationHelper: expressionEvaluationHelper,
      parameters: parameters,
      internalThisVariable: internalThisVariable,
    );
    benchmarker.endSubdivide();
    return result;
  }

  @override
  InitializerInferenceResult inferInitializer({
    required Uri fileUri,
    required SourceConstructorBuilder constructorBuilder,
    required Initializer initializer,
  }) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferInitializer);
    InitializerInferenceResult result = impl.inferInitializer(
      fileUri: fileUri,
      constructorBuilder: constructorBuilder,
      initializer: initializer,
    );
    benchmarker.endSubdivide();
    return result;
  }

  @override
  void inferMetadata({
    required Uri fileUri,
    required Annotatable annotatable,
    required List<int>? indices,
  }) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferMetadata);
    impl.inferMetadata(
      fileUri: fileUri,
      annotatable: annotatable,
      indices: indices,
    );
    benchmarker.endSubdivide();
  }

  @override
  Expression inferParameterInitializer({
    required Uri fileUri,
    required Expression initializer,
    required DartType declaredType,
    required bool hasDeclaredInitializer,
  }) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferParameterInitializer);
    Expression result = impl.inferParameterInitializer(
      fileUri: fileUri,
      initializer: initializer,
      declaredType: declaredType,
      hasDeclaredInitializer: hasDeclaredInitializer,
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
}

class InferredFunctionBody {
  final Statement body;
  final DartType? emittedValueType;
  final ScopeProviderInfo? scopeProviderInfo;

  InferredFunctionBody(
    this.body,
    this.emittedValueType,
    this.scopeProviderInfo,
  );
}
