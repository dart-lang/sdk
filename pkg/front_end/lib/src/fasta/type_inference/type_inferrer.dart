// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/type_inference/assigned_variables.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/type_environment.dart';

import '../../base/instrumentation.dart' show Instrumentation;
import '../kernel/benchmarker.dart' show BenchmarkSubdivides, Benchmarker;
import '../kernel/internal_ast.dart';
import '../source/constructor_declaration.dart';
import '../source/source_library_builder.dart' show SourceLibraryBuilder;
import 'closure_context.dart';
import 'inference_helper.dart' show InferenceHelper;
import 'inference_results.dart';
import 'inference_visitor.dart';
import 'inference_visitor_base.dart';
import 'type_inference_engine.dart';
import 'type_schema.dart' show UnknownType;
import 'type_schema_environment.dart' show TypeSchemaEnvironment;

/// Keeps track of the local state for the type inference that occurs during
/// compilation of a single method body or top level initializer.
///
/// This class describes the interface for use by clients of type inference
/// (e.g. BodyBuilder).  Derived classes should derive from [TypeInferrerImpl].
abstract class TypeInferrer {
  SourceLibraryBuilder get libraryBuilder;

  /// Gets the [TypeSchemaEnvironment] being used for type inference.
  TypeSchemaEnvironment get typeSchemaEnvironment;

  /// Returns the [FlowAnalysis] used during inference.
  FlowAnalysis<TreeNode, Statement, Expression, VariableDeclaration, DartType>
      get flowAnalysis;

  /// The URI of the code for which type inference is currently being
  /// performed--this is used for testing.
  Uri get uriForInstrumentation;

  AssignedVariables<TreeNode, VariableDeclaration> get assignedVariables;

  /// Indicates whether the construct we are currently performing inference for
  /// is outside of a method body, and hence top level type inference rules
  /// should apply.
  bool get isTopLevel;

  /// Performs top level type inference on the given field initializer and
  /// returns the computed field type.
  DartType inferImplicitFieldType(
      InferenceHelper helper, Expression initializer);

  /// Performs full type inference on the given field initializer.
  ExpressionInferenceResult inferFieldInitializer(
      InferenceHelper helper, DartType declaredType, Expression initializer);

  /// Performs type inference on the given function body.
  InferredFunctionBody inferFunctionBody(InferenceHelper helper, int fileOffset,
      DartType returnType, AsyncMarker asyncMarker, Statement body);

  /// Performs type inference on the given constructor initializer.
  InitializerInferenceResult inferInitializer(InferenceHelper helper,
      ConstructorDeclaration constructorDeclaration, Initializer initializer);

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
  /// Marker object to indicate that a function takes an unknown number
  /// of arguments.
  final FunctionType unknownFunction;

  final TypeInferenceEngine engine;

  final OperationsCfe operations;

  @override
  late final FlowAnalysis<TreeNode, Statement, Expression, VariableDeclaration,
          DartType> flowAnalysis =
      libraryBuilder.isNonNullableByDefault
          ? new FlowAnalysis(operations, assignedVariables,
              respectImplicitlyTypedVarInitializers:
                  libraryBuilder.libraryFeatures.constructorTearoffs.isEnabled)
          : new FlowAnalysis.legacy(operations, assignedVariables);

  @override
  final AssignedVariables<TreeNode, VariableDeclaration> assignedVariables;

  final InferenceDataForTesting? dataForTesting;

  @override
  final Uri uriForInstrumentation;

  @override
  final bool isTopLevel;

  final Instrumentation? instrumentation;

  @override
  final TypeSchemaEnvironment typeSchemaEnvironment;

  final InterfaceType? thisType;

  @override
  final SourceLibraryBuilder libraryBuilder;

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
      this.assignedVariables,
      this.dataForTesting,
      FunctionType unknownFunctionNonNullable,
      FunctionType unknownFunctionLegacy)
      : unknownFunction = libraryBuilder.isNonNullableByDefault
            ? unknownFunctionNonNullable
            : unknownFunctionLegacy,
        instrumentation = isTopLevel ? null : engine.instrumentation,
        typeSchemaEnvironment = engine.typeSchemaEnvironment,
        operations = new OperationsCfe(engine.typeSchemaEnvironment,
            nullability: libraryBuilder.nonNullable,
            fieldNonPromotabilityInfo: libraryBuilder.fieldNonPromotabilityInfo,
            typeCacheNonNullable: engine.typeCacheNonNullable,
            typeCacheNullable: engine.typeCacheNullable,
            typeCacheLegacy: engine.typeCacheLegacy);

  InferenceVisitorBase _createInferenceVisitor(InferenceHelper helper,
      [ConstructorDeclaration? constructorDeclaration]) {
    // For full (non-top level) inference, we need access to the
    // InferenceHelper so that we can perform error reporting.
    return new InferenceVisitorImpl(
        this, helper, constructorDeclaration, operations);
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
  InferredFunctionBody inferFunctionBody(InferenceHelper helper, int fileOffset,
      DartType returnType, AsyncMarker asyncMarker, Statement body) {
    InferenceVisitorBase visitor = _createInferenceVisitor(helper);
    ClosureContext closureContext =
        new ClosureContext(visitor, asyncMarker, returnType, false);
    StatementInferenceResult result =
        visitor.inferStatement(body, closureContext);
    if (dataForTesting != null) {
      if (!flowAnalysis.isReachable) {
        dataForTesting!.flowAnalysisResult.functionBodiesThatDontComplete
            .add(body);
      }
    }
    result =
        closureContext.handleImplicitReturn(visitor, body, result, fileOffset);
    visitor.checkCleanState();
    DartType? futureValueType = closureContext.futureValueType;
    assert(!(asyncMarker == AsyncMarker.Async && futureValueType == null),
        "No future value type computed.");
    flowAnalysis.finish();
    return new InferredFunctionBody(
        result.hasChanged ? result.statement : body, futureValueType);
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
      flowAnalysis.declare(parameter, parameter.type, initialized: true);
      positionalArguments
          .add(new VariableGetImpl(parameter, forNullGuardedAccess: false));
    }
    List<NamedExpression> namedArguments = <NamedExpression>[];
    for (VariableDeclaration parameter
        in redirectingFactoryFunction.namedParameters) {
      flowAnalysis.declare(parameter, parameter.type, initialized: true);
      namedArguments.add(new NamedExpression(parameter.name!,
          new VariableGetImpl(parameter, forNullGuardedAccess: false)));
    }
    // If arguments are created using [ArgumentsImpl], and the
    // type arguments are omitted, they are to be inferred.
    ArgumentsImpl targetInvocationArguments =
        new ArgumentsImpl(positionalArguments, named: namedArguments)
          ..fileOffset = fileOffset;

    InvocationInferenceResult result = visitor.inferInvocation(
        visitor, typeContext, fileOffset, targetType, targetInvocationArguments,
        staticTarget: target);
    visitor.checkCleanState();
    DartType resultType = result.inferredType;
    if (resultType is InterfaceType) {
      return resultType.typeArguments;
    } else {
      return null;
    }
  }

  @override
  InitializerInferenceResult inferInitializer(InferenceHelper helper,
      ConstructorDeclaration constructorDeclaration, Initializer initializer) {
    // Use polymorphic dispatch on [KernelInitializer] to perform whatever
    // kind of type inference is correct for this kind of initializer.
    // TODO(paulberry): experiment to see if dynamic dispatch would be better,
    // so that the type hierarchy will be simpler (which may speed up "is"
    // checks).
    InferenceVisitorBase visitor =
        _createInferenceVisitor(helper, constructorDeclaration);
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

class TypeInferrerImplBenchmarked implements TypeInferrer {
  final TypeInferrerImpl impl;
  final Benchmarker benchmarker;

  TypeInferrerImplBenchmarked(
    TypeInferenceEngine engine,
    Uri uriForInstrumentation,
    bool topLevel,
    InterfaceType? thisType,
    SourceLibraryBuilder library,
    AssignedVariables<TreeNode, VariableDeclaration> assignedVariables,
    InferenceDataForTesting? dataForTesting,
    this.benchmarker,
    FunctionType unknownFunctionNonNullable,
    FunctionType unknownFunctionLegacy,
  ) : impl = new TypeInferrerImpl(
          engine,
          uriForInstrumentation,
          topLevel,
          thisType,
          library,
          assignedVariables,
          dataForTesting,
          unknownFunctionNonNullable,
          unknownFunctionLegacy,
        );

  @override
  bool get isTopLevel => impl.isTopLevel;

  @override
  AssignedVariables<TreeNode, VariableDeclaration> get assignedVariables =>
      impl.assignedVariables;

  @override
  FlowAnalysis<TreeNode, Statement, Expression, VariableDeclaration, DartType>
      get flowAnalysis => impl.flowAnalysis;

  @override
  SourceLibraryBuilder get libraryBuilder => impl.libraryBuilder;

  @override
  TypeSchemaEnvironment get typeSchemaEnvironment => impl.typeSchemaEnvironment;

  @override
  Uri get uriForInstrumentation => impl.uriForInstrumentation;

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
  InferredFunctionBody inferFunctionBody(InferenceHelper helper, int fileOffset,
      DartType returnType, AsyncMarker asyncMarker, Statement body) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferFunctionBody);
    InferredFunctionBody result = impl.inferFunctionBody(
        helper, fileOffset, returnType, asyncMarker, body);
    benchmarker.endSubdivide();
    return result;
  }

  @override
  InitializerInferenceResult inferInitializer(InferenceHelper helper,
      ConstructorDeclaration constructorDeclaration, Initializer initializer) {
    benchmarker.beginSubdivide(BenchmarkSubdivides.inferInitializer);
    InitializerInferenceResult result =
        impl.inferInitializer(helper, constructorDeclaration, initializer);
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
  final DartType? futureValueType;

  InferredFunctionBody(this.body, this.futureValueType);
}
