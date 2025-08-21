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

import '../base/instrumentation.dart' show Instrumentation;
import '../base/scope.dart';
import '../kernel/benchmarker.dart' show BenchmarkSubdivides, Benchmarker;
import '../kernel/internal_ast.dart';
import '../source/source_constructor_builder.dart';
import '../source/source_library_builder.dart' show SourceLibraryBuilder;
import 'closure_context.dart';
import 'inference_helper.dart' show InferenceHelper;
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
  FlowAnalysis<TreeNode, Statement, Expression, VariableDeclaration,
      SharedTypeView> get flowAnalysis;

  AssignedVariables<TreeNode, VariableDeclaration> get assignedVariables;

  /// Performs top level type inference on the given field initializer and
  /// returns the computed field type.
  DartType inferImplicitFieldType(
      InferenceHelper helper, Expression initializer);

  /// Performs full type inference on the given field initializer.
  ExpressionInferenceResult inferFieldInitializer(
      InferenceHelper helper, DartType declaredType, Expression initializer);

  /// Performs type inference on the given function body.
  InferredFunctionBody inferFunctionBody(
      InferenceHelper helper,
      int fileOffset,
      DartType returnType,
      AsyncMarker asyncMarker,
      Statement body,
      ExpressionEvaluationHelper? expressionEvaluationHelper);

  /// Performs type inference on the given constructor initializer.
  InitializerInferenceResult inferInitializer(InferenceHelper helper,
      SourceConstructorBuilder constructorBuilder, Initializer initializer);

  /// Performs type inference on the given metadata annotations.
  void inferMetadata(
      InferenceHelper helper, TreeNode? parent, List<Expression>? annotations);

  /// Performs type inference on the given function parameter initializer
  /// expression.
  Expression inferParameterInitializer(
      InferenceHelper helper,
      Expression initializer,
      DartType declaredType,
      bool hasDeclaredInitializer);

  /// Infers the type arguments a redirecting factory target reference.
  List<DartType>? inferRedirectingFactoryTypeArguments(
      InferenceHelper helper,
      DartType typeContext,
      FunctionNode redirectingFactoryFunction,
      int fileOffset,
      Member target,
      FunctionType targetType);
}

/// Concrete implementation of [TypeInferrer] specialized to work with kernel
/// objects.
class TypeInferrerImpl implements TypeInferrer {
  final TypeInferenceEngine engine;

  final OperationsCfe operations;

  TypeAnalyzerOptions typeAnalyzerOptions;

  @override
  late final FlowAnalysis<TreeNode, Statement, Expression, VariableDeclaration,
          SharedTypeView> flowAnalysis =
      new FlowAnalysis(operations, assignedVariables,
          typeAnalyzerOptions: typeAnalyzerOptions);

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
          libraryBuilder.library, typeSchemaEnvironment,
          thisType: thisType);

  TypeInferrerImpl(
      this.engine,
      this.uriForInstrumentation,
      this.isTopLevel,
      this.thisType,
      this.libraryBuilder,
      this.extensionScope,
      this.assignedVariables,
      this.dataForTesting)
      : instrumentation = isTopLevel ? null : engine.instrumentation,
        typeSchemaEnvironment = engine.typeSchemaEnvironment,
        operations = new OperationsCfe(engine.typeSchemaEnvironment,
            fieldNonPromotabilityInfo: libraryBuilder.fieldNonPromotabilityInfo,
            typeCacheNonNullable: engine.typeCacheNonNullable,
            typeCacheNullable: engine.typeCacheNullable,
            typeCacheLegacy: engine.typeCacheLegacy),
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
                libraryBuilder.libraryFeatures.soundFlowAnalysis.isEnabled);

  InferenceVisitorBase _createInferenceVisitor(InferenceHelper helper,
      {SourceConstructorBuilder? constructorBuilder,
      ExpressionEvaluationHelper? expressionEvaluationHelper}) {
    // For full (non-top level) inference, we need access to the
    // InferenceHelper so that we can perform error reporting.
    return new InferenceVisitorImpl(this, helper, constructorBuilder,
        operations, typeAnalyzerOptions, expressionEvaluationHelper);
  }

  @override
  DartType inferImplicitFieldType(
      InferenceHelper helper, Expression initializer) {
    InferenceVisitorBase visitor = _createInferenceVisitor(helper);
    ExpressionInferenceResult result = visitor
        .inferExpression(initializer, const UnknownType(), isVoidAllowed: true);
    DartType type = visitor.inferDeclarationType(result.inferredType);
    visitor.checkCleanState();
    return type;
  }

  @override
  ExpressionInferenceResult inferFieldInitializer(
      InferenceHelper helper, DartType declaredType, Expression initializer) {
    assert(!isTopLevel);
    InferenceVisitorBase visitor = _createInferenceVisitor(helper);
    ExpressionInferenceResult initializerResult =
        visitor.inferExpression(initializer, declaredType, isVoidAllowed: true);
    initializerResult = visitor.ensureAssignableResult(
        declaredType, initializerResult,
        isVoidAllowed: declaredType is VoidType);
    visitor.checkCleanState();
    return initializerResult;
  }

  @override
  InferredFunctionBody inferFunctionBody(
    InferenceHelper helper,
    int fileOffset,
    DartType returnType,
    AsyncMarker asyncMarker,
    Statement body,
    ExpressionEvaluationHelper? expressionEvaluationHelper,
  ) {
    InferenceVisitorBase visitor = _createInferenceVisitor(helper,
        expressionEvaluationHelper: expressionEvaluationHelper);
    ClosureContext closureContext =
        new ClosureContext(visitor, asyncMarker, returnType, false);
    StatementInferenceResult result =
        visitor.inferStatement(body, closureContext);
    if (dataForTesting != null) {
      // Coverage-ignore-block(suite): Not run.
      if (!flowAnalysis.isReachable) {
        dataForTesting!.flowAnalysisResult.functionBodiesThatDontComplete
            .add(body);
      }
    }
    result =
        closureContext.handleImplicitReturn(visitor, body, result, fileOffset);
    visitor.checkCleanState();
    DartType? emittedValueType = closureContext.emittedValueType;
    assert(asyncMarker == AsyncMarker.Sync || emittedValueType != null);
    flowAnalysis.finish();
    return new InferredFunctionBody(
        result.hasChanged ? result.statement : body, emittedValueType);
  }

  @override
  List<DartType>? inferRedirectingFactoryTypeArguments(
      InferenceHelper helper,
      DartType typeContext,
      FunctionNode redirectingFactoryFunction,
      int fileOffset,
      Member target,
      FunctionType targetType) {
    InferenceVisitorBase visitor = _createInferenceVisitor(helper);
    List<Expression> positionalArguments = <Expression>[];
    for (VariableDeclaration parameter
        in redirectingFactoryFunction.positionalParameters) {
      flowAnalysis.declare(parameter, new SharedTypeView(parameter.type),
          initialized: true);
      positionalArguments
          .add(new VariableGetImpl(parameter, forNullGuardedAccess: false));
    }
    List<NamedExpression> namedArguments = <NamedExpression>[];
    for (VariableDeclaration parameter
        in redirectingFactoryFunction.namedParameters) {
      flowAnalysis.declare(parameter, new SharedTypeView(parameter.type),
          initialized: true);
      namedArguments.add(new NamedExpression(parameter.name!,
          new VariableGetImpl(parameter, forNullGuardedAccess: false)));
    }
    // If arguments are created using [ArgumentsImpl], and the
    // type arguments are omitted, they are to be inferred.
    ArgumentsImpl targetInvocationArguments =
        new ArgumentsImpl(positionalArguments, named: namedArguments)
          ..fileOffset = fileOffset;

    InvocationInferenceResult result = visitor.inferInvocation(
        visitor,
        typeContext,
        fileOffset,
        new InvocationTargetFunctionType(targetType),
        targetInvocationArguments,
        staticTarget: target);
    visitor.checkCleanState();
    DartType resultType = result.inferredType;
    if (resultType is TypeDeclarationType) {
      return resultType.typeArguments;
    } else {
      return null;
    }
  }

  @override
  InitializerInferenceResult inferInitializer(InferenceHelper helper,
      SourceConstructorBuilder constructorBuilder, Initializer initializer) {
    // Use polymorphic dispatch on [KernelInitializer] to perform whatever
    // kind of type inference is correct for this kind of initializer.
    // TODO(paulberry): experiment to see if dynamic dispatch would be better,
    // so that the type hierarchy will be simpler (which may speed up "is"
    // checks).
    InferenceVisitorBase visitor =
        _createInferenceVisitor(helper, constructorBuilder: constructorBuilder);
    InitializerInferenceResult result = visitor.inferInitializer(initializer);
    visitor.checkCleanState();
    return result;
  }

  @override
  void inferMetadata(
      InferenceHelper helper, TreeNode? parent, List<Expression>? annotations) {
    if (annotations != null) {
      // We bypass the check for assignment of the helper during top-level
      // inference and use `_helper = helper` instead of `this.helper = helper`
      // because inference on metadata requires the helper.
      InferenceVisitorBase visitor = _createInferenceVisitor(helper);
      visitor.inferMetadata(visitor, parent, annotations);
      visitor.checkCleanState();
    }
  }

  @override
  Expression inferParameterInitializer(
      InferenceHelper helper,
      Expression initializer,
      DartType declaredType,
      bool hasDeclaredInitializer) {
    InferenceVisitorBase visitor = _createInferenceVisitor(helper);
    ExpressionInferenceResult result =
        visitor.inferExpression(initializer, declaredType);
    if (hasDeclaredInitializer) {
      initializer =
          visitor.ensureAssignableResult(declaredType, result).expression;
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
            dataForTesting);

  @override
  AssignedVariables<TreeNode, VariableDeclaration> get assignedVariables =>
      impl.assignedVariables;

  @override
  FlowAnalysis<TreeNode, Statement, Expression, VariableDeclaration,
      SharedTypeView> get flowAnalysis => impl.flowAnalysis;

  @override
  TypeSchemaEnvironment get typeSchemaEnvironment => impl.typeSchemaEnvironment;

  @override
  DartType inferImplicitFieldType(
      InferenceHelper helper, Expression initializer) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferImplicitFieldType);
    DartType result = impl.inferImplicitFieldType(helper, initializer);
    benchmarker.endSubdivide();
    return result;
  }

  @override
  ExpressionInferenceResult inferFieldInitializer(
      InferenceHelper helper, DartType declaredType, Expression initializer) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferFieldInitializer);
    ExpressionInferenceResult result =
        impl.inferFieldInitializer(helper, declaredType, initializer);
    benchmarker.endSubdivide();
    return result;
  }

  @override
  InferredFunctionBody inferFunctionBody(
    InferenceHelper helper,
    int fileOffset,
    DartType returnType,
    AsyncMarker asyncMarker,
    Statement body,
    ExpressionEvaluationHelper? expressionEvaluationHelper,
  ) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferFunctionBody);
    InferredFunctionBody result = impl.inferFunctionBody(helper, fileOffset,
        returnType, asyncMarker, body, expressionEvaluationHelper);
    benchmarker.endSubdivide();
    return result;
  }

  @override
  InitializerInferenceResult inferInitializer(InferenceHelper helper,
      SourceConstructorBuilder constructorBuilder, Initializer initializer) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferInitializer);
    InitializerInferenceResult result =
        impl.inferInitializer(helper, constructorBuilder, initializer);
    benchmarker.endSubdivide();
    return result;
  }

  @override
  void inferMetadata(
      InferenceHelper helper, TreeNode? parent, List<Expression>? annotations) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferMetadata);
    impl.inferMetadata(helper, parent, annotations);
    benchmarker.endSubdivide();
  }

  @override
  Expression inferParameterInitializer(
      InferenceHelper helper,
      Expression initializer,
      DartType declaredType,
      bool hasDeclaredInitializer) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferParameterInitializer);
    Expression result = impl.inferParameterInitializer(
        helper, initializer, declaredType, hasDeclaredInitializer);
    benchmarker.endSubdivide();
    return result;
  }

  @override
  List<DartType>? inferRedirectingFactoryTypeArguments(
      InferenceHelper helper,
      DartType typeContext,
      FunctionNode redirectingFactoryFunction,
      int fileOffset,
      Member target,
      FunctionType targetType) {
    benchmarker.beginSubdivide(
        BenchmarkSubdivides.inferRedirectingFactoryTypeArguments);
    List<DartType>? result = impl.inferRedirectingFactoryTypeArguments(
        helper,
        typeContext,
        redirectingFactoryFunction,
        fileOffset,
        target,
        targetType);
    benchmarker.endSubdivide();
    return result;
  }
}

class InferredFunctionBody {
  final Statement body;
  final DartType? emittedValueType;

  InferredFunctionBody(this.body, this.emittedValueType);
}
