// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/type_inference/assigned_variables.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart'
    hide MapPatternEntry;
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/type_environment.dart';

import '../base/constant_context.dart';
import '../base/instrumentation.dart' show Instrumentation;
import '../base/scope.dart';
import '../kernel/benchmarker.dart' show BenchmarkSubdivides, Benchmarker;
import '../kernel/internal_ast.dart';
import '../source/source_constructor_builder.dart';
import '../source/source_library_builder.dart' show SourceLibraryBuilder;
import 'closure_context.dart';
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

  /// Returns the [FlowAnalysis] used during inference.
  FlowAnalysis<
    TreeNode,
    Statement,
    Expression,
    VariableDeclaration,
    SharedTypeView
  >
  get flowAnalysis;

  AssignedVariables<TreeNode, VariableDeclaration> get assignedVariables;

  /// Performs top level type inference on the given field initializer and
  /// returns the computed field type.
  DartType inferImplicitFieldType({
    required Uri fileUri,
    required ConstantContext constantContext,
    required Expression initializer,
  });

  /// Performs full type inference on the given field initializer.
  ExpressionInferenceResult inferFieldInitializer({
    required Uri fileUri,
    required ConstantContext constantContext,
    required DartType declaredType,
    required Expression initializer,
  });

  /// Performs type inference on the given function body.
  InferredFunctionBody inferFunctionBody({
    required Uri fileUri,
    required int fileOffset,
    required DartType returnType,
    required ConstantContext constantContext,
    required AsyncMarker asyncMarker,
    required Statement body,
    ExpressionEvaluationHelper? expressionEvaluationHelper,
  });

  /// Performs type inference on the given constructor initializer.
  InitializerInferenceResult inferInitializer({
    required Uri fileUri,
    required ConstantContext constantContext,
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
    required ConstantContext constantContext,
  });

  /// Performs type inference on the given function parameter initializer
  /// expression.
  Expression inferParameterInitializer({
    required Uri fileUri,
    required Expression initializer,
    required DartType declaredType,
    required bool hasDeclaredInitializer,
    required ConstantContext constantContext,
  });

  /// Infers the type arguments a redirecting factory target reference.
  List<DartType>? inferRedirectingFactoryTypeArguments({
    required DartType typeContext,
    required FunctionNode redirectingFactoryFunction,
    required Uri fileUri,
    required int fileOffset,
    required Member target,
    required FunctionType targetType,
    required ConstantContext constantContext,
  });
}

/// Concrete implementation of [TypeInferrer] specialized to work with kernel
/// objects.
class TypeInferrerImpl implements TypeInferrer {
  final TypeInferenceEngine engine;

  final OperationsCfe operations;

  TypeAnalyzerOptions typeAnalyzerOptions;

  @override
  late final FlowAnalysis<
    TreeNode,
    Statement,
    Expression,
    VariableDeclaration,
    SharedTypeView
  >
  flowAnalysis = new FlowAnalysis(
    operations,
    assignedVariables,
    typeAnalyzerOptions: typeAnalyzerOptions,
  );

  @override
  final AssignedVariables<TreeNode, VariableDeclaration> assignedVariables;

  final InferenceDataForTesting? dataForTesting;

  /// The URI of the code for which type inference is currently being
  /// performed--this is used for testing.
  final Uri uriForInstrumentation;

  /// Indicates whether the construct we are currently performing inference for
  /// is outside of a method body, and hence top level type inference rules
  /// should apply.
  final bool isTopLevel;

  final Instrumentation? instrumentation;

  @override
  final TypeSchemaEnvironment typeSchemaEnvironment;

  final InterfaceType? thisType;

  final SourceLibraryBuilder libraryBuilder;

  final LookupScope extensionScope;

  late final StaticTypeContext staticTypeContext =
      new StaticTypeContextImpl.direct(
        libraryBuilder.library,
        typeSchemaEnvironment,
        thisType: thisType,
      );

  TypeInferrerImpl(
    this.engine,
    this.uriForInstrumentation,
    this.isTopLevel,
    this.thisType,
    this.libraryBuilder,
    this.extensionScope,
    this.assignedVariables,
    this.dataForTesting,
  ) : instrumentation = isTopLevel ? null : engine.instrumentation,
      typeSchemaEnvironment = engine.typeSchemaEnvironment,
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

  InferenceVisitorBase _createInferenceVisitor({
    required Uri fileUri,
    required ConstantContext constantContext,
    SourceConstructorBuilder? constructorBuilder,
    ExpressionEvaluationHelper? expressionEvaluationHelper,
  }) {
    // For full (non-top level) inference, we need access to the
    // InferenceHelper so that we can perform error reporting.
    return new InferenceVisitorImpl(
      this,
      fileUri,
      constantContext,
      constructorBuilder,
      operations,
      typeAnalyzerOptions,
      expressionEvaluationHelper,
    );
  }

  @override
  DartType inferImplicitFieldType({
    required Uri fileUri,
    required ConstantContext constantContext,
    required Expression initializer,
  }) {
    InferenceVisitorBase visitor = _createInferenceVisitor(
      fileUri: fileUri,
      constantContext: constantContext,
    );
    ExpressionInferenceResult result = visitor.inferExpression(
      initializer,
      const UnknownType(),
      isVoidAllowed: true,
    );
    DartType type = visitor.inferDeclarationType(result.inferredType);
    visitor.checkCleanState();
    return type;
  }

  @override
  ExpressionInferenceResult inferFieldInitializer({
    required Uri fileUri,
    required ConstantContext constantContext,
    required DartType declaredType,
    required Expression initializer,
  }) {
    assert(!isTopLevel);
    InferenceVisitorBase visitor = _createInferenceVisitor(
      fileUri: fileUri,
      constantContext: constantContext,
    );
    ExpressionInferenceResult initializerResult = visitor.inferExpression(
      initializer,
      declaredType,
      isVoidAllowed: true,
    );
    initializerResult = visitor.ensureAssignableResult(
      declaredType,
      initializerResult,
      isVoidAllowed: declaredType is VoidType,
    );
    visitor.checkCleanState();
    return initializerResult;
  }

  @override
  InferredFunctionBody inferFunctionBody({
    required Uri fileUri,
    required int fileOffset,
    required DartType returnType,
    required ConstantContext constantContext,
    required AsyncMarker asyncMarker,
    required Statement body,
    ExpressionEvaluationHelper? expressionEvaluationHelper,
  }) {
    InferenceVisitorBase visitor = _createInferenceVisitor(
      fileUri: fileUri,
      constantContext: constantContext,
      expressionEvaluationHelper: expressionEvaluationHelper,
    );
    ClosureContext closureContext = new ClosureContext(
      visitor,
      asyncMarker,
      returnType,
      false,
    );
    StatementInferenceResult result = visitor.inferStatement(
      body,
      closureContext,
    );
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
    required ConstantContext constantContext,
  }) {
    InferenceVisitorBase visitor = _createInferenceVisitor(
      fileUri: fileUri,
      constantContext: constantContext,
    );
    List<Expression> positionalArguments = <Expression>[];
    for (VariableDeclaration parameter
        in redirectingFactoryFunction.positionalParameters) {
      flowAnalysis.declare(
        parameter,
        new SharedTypeView(parameter.type),
        initialized: true,
      );
      positionalArguments.add(new VariableGet(parameter));
    }
    List<NamedExpression> namedArguments = <NamedExpression>[];
    for (VariableDeclaration parameter
        in redirectingFactoryFunction.namedParameters) {
      flowAnalysis.declare(
        parameter,
        new SharedTypeView(parameter.type),
        initialized: true,
      );
      namedArguments.add(
        new NamedExpression(parameter.name!, new VariableGet(parameter)),
      );
    }
    // If arguments are created using [ArgumentsImpl], and the
    // type arguments are omitted, they are to be inferred.
    ArgumentsImpl targetInvocationArguments = new ArgumentsImpl(
      positionalArguments,
      named: namedArguments,
    )..fileOffset = fileOffset;

    InvocationInferenceResult result = visitor.inferInvocation(
      visitor,
      typeContext,
      fileOffset,
      new InvocationTargetFunctionType(targetType),
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
    required ConstantContext constantContext,
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
      constantContext: constantContext,
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
    required ConstantContext constantContext,
  }) {
    InferenceVisitorBase visitor = _createInferenceVisitor(
      fileUri: fileUri,
      constantContext: constantContext,
    );
    visitor.inferMetadata(visitor, annotatable, indices: indices);
    visitor.checkCleanState();
  }

  @override
  Expression inferParameterInitializer({
    required Uri fileUri,
    required Expression initializer,
    required DartType declaredType,
    required bool hasDeclaredInitializer,
    required ConstantContext constantContext,
  }) {
    InferenceVisitorBase visitor = _createInferenceVisitor(
      fileUri: fileUri,
      constantContext: constantContext,
    );
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

  TypeInferrerImplBenchmarked(
    TypeInferenceEngine engine,
    Uri uriForInstrumentation,
    bool topLevel,
    InterfaceType? thisType,
    SourceLibraryBuilder libraryBuilder,
    LookupScope extensionScope,
    AssignedVariables<TreeNode, VariableDeclaration> assignedVariables,
    InferenceDataForTesting? dataForTesting,
    this.benchmarker,
  ) : impl = new TypeInferrerImpl(
        engine,
        uriForInstrumentation,
        topLevel,
        thisType,
        libraryBuilder,
        extensionScope,
        assignedVariables,
        dataForTesting,
      );

  @override
  AssignedVariables<TreeNode, VariableDeclaration> get assignedVariables =>
      impl.assignedVariables;

  @override
  FlowAnalysis<
    TreeNode,
    Statement,
    Expression,
    VariableDeclaration,
    SharedTypeView
  >
  get flowAnalysis => impl.flowAnalysis;

  @override
  TypeSchemaEnvironment get typeSchemaEnvironment => impl.typeSchemaEnvironment;

  @override
  DartType inferImplicitFieldType({
    required Uri fileUri,
    required ConstantContext constantContext,
    required Expression initializer,
  }) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferImplicitFieldType);
    DartType result = impl.inferImplicitFieldType(
      fileUri: fileUri,
      constantContext: constantContext,
      initializer: initializer,
    );
    benchmarker.endSubdivide();
    return result;
  }

  @override
  ExpressionInferenceResult inferFieldInitializer({
    required Uri fileUri,
    required ConstantContext constantContext,
    required DartType declaredType,
    required Expression initializer,
  }) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferFieldInitializer);
    ExpressionInferenceResult result = impl.inferFieldInitializer(
      fileUri: fileUri,
      constantContext: constantContext,
      declaredType: declaredType,
      initializer: initializer,
    );
    benchmarker.endSubdivide();
    return result;
  }

  @override
  InferredFunctionBody inferFunctionBody({
    required Uri fileUri,
    required int fileOffset,
    required DartType returnType,
    required ConstantContext constantContext,
    required AsyncMarker asyncMarker,
    required Statement body,
    ExpressionEvaluationHelper? expressionEvaluationHelper,
  }) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferFunctionBody);
    InferredFunctionBody result = impl.inferFunctionBody(
      fileUri: fileUri,
      fileOffset: fileOffset,
      returnType: returnType,
      constantContext: constantContext,
      asyncMarker: asyncMarker,
      body: body,
      expressionEvaluationHelper: expressionEvaluationHelper,
    );
    benchmarker.endSubdivide();
    return result;
  }

  @override
  InitializerInferenceResult inferInitializer({
    required Uri fileUri,
    required ConstantContext constantContext,
    required SourceConstructorBuilder constructorBuilder,
    required Initializer initializer,
  }) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferInitializer);
    InitializerInferenceResult result = impl.inferInitializer(
      fileUri: fileUri,
      constantContext: constantContext,
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
    required ConstantContext constantContext,
  }) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferMetadata);
    impl.inferMetadata(
      fileUri: fileUri,
      annotatable: annotatable,
      indices: indices,
      constantContext: constantContext,
    );
    benchmarker.endSubdivide();
  }

  @override
  Expression inferParameterInitializer({
    required Uri fileUri,
    required Expression initializer,
    required DartType declaredType,
    required bool hasDeclaredInitializer,
    required ConstantContext constantContext,
  }) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferParameterInitializer);
    Expression result = impl.inferParameterInitializer(
      fileUri: fileUri,
      initializer: initializer,
      declaredType: declaredType,
      hasDeclaredInitializer: hasDeclaredInitializer,
      constantContext: constantContext,
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
    required ConstantContext constantContext,
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
      constantContext: constantContext,
    );
    benchmarker.endSubdivide();
    return result;
  }
}

class InferredFunctionBody {
  final Statement body;
  final DartType? emittedValueType;

  InferredFunctionBody(this.body, this.emittedValueType);
}
