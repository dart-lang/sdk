// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/body_inference_context.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart';
import 'package:kernel/src/future_value_type.dart';

import '../codes/cfe_codes.dart';
import '../kernel/external_ast_helper.dart' as extern;
import '../kernel/internal_ast.dart';
import '../kernel/invalid_type.dart';
import '../source/check_helper.dart';
import 'inference_results.dart';
import 'inference_visitor_base.dart';
import 'type_demotion.dart';
import 'type_schema.dart' show UnknownType;

/// Keeps track of information about the innermost function body being inferred.
abstract class BodyInferenceContext implements SharedBodyInferenceContext {
  /// Returns `true` if this the root body context, i.e. the method or
  /// constructor itself and _not_ a nested local function.
  final bool isRoot;

  @override
  bool get isAsync;

  /// The typing expectation for the subexpression of a `return` statement
  /// inside the function.
  ///
  /// For an `async` function, this is a "FutureOr" type (since it is
  /// permissible for such a function to return either a direct value or a
  /// future).
  ///
  /// For generator functions (which do not allow return statements) this is the
  /// unknown type.
  DartType get returnContext;

  /// The typing expectation for the subexpression of a `yield` statement inside
  /// the function.
  ///
  /// For `sync*` and `async*` functions, the expected type is the element type
  /// of the generated `Iterable` or `Stream`, respectively.
  ///
  /// For non-generator functions (which do not allow yield statements) this is
  /// the unknown type.
  DartType get yieldContext;

  DartType? get emittedValueType;

  factory(
    InferenceVisitorBase inferrer,
    AsyncMarker asyncMarker,
    DartType returnContext, {
    required bool needToInferReturnType,
    required bool isRoot,
  }) {
    DartType declaredReturnType = inferrer.computeGreatestClosure(
      returnContext,
    );
    bool isAsync =
        asyncMarker == AsyncMarker.Async ||
        asyncMarker == AsyncMarker.AsyncStar;
    bool isGenerator =
        asyncMarker == AsyncMarker.SyncStar ||
        asyncMarker == AsyncMarker.AsyncStar;
    if (isGenerator) {
      if (isAsync) {
        DartType yieldContext = inferrer.getTypeArgumentOf(
          inferrer.typeSchemaEnvironment.getUnionFreeType(returnContext),
          inferrer.coreTypes.streamClass,
        );
        return new _AsyncStarContext(
          inferrer,
          yieldContext,
          declaredReturnType,
          needToInferReturnType,
          isRoot,
        );
      } else {
        DartType yieldContext = inferrer.getTypeArgumentOf(
          inferrer.typeSchemaEnvironment.getUnionFreeType(returnContext),
          inferrer.coreTypes.iterableClass,
        );
        return new _SyncStarContext(
          inferrer,
          yieldContext,
          declaredReturnType,
          needToInferReturnType,
          isRoot,
        );
      }
    } else if (isAsync) {
      DartType? futureValueType;
      returnContext = inferrer.wrapFutureOrType(
        inferrer.computeFutureValueTypeSchema(returnContext),
      );
      if (!needToInferReturnType) {
        futureValueType = computeFutureValueType(
          inferrer.coreTypes,
          declaredReturnType,
        );
      }
      return new _AsyncContext(
        inferrer,
        returnContext,
        declaredReturnType,
        needToInferReturnType,
        futureValueType,
        isRoot,
      );
    } else {
      return new _SyncContext(
        inferrer,
        returnContext,
        declaredReturnType,
        needToInferReturnType,
        isRoot,
      );
    }
  }

  new _(this.isRoot);

  @override
  SharedTypeSchemaView get sharedYieldContext =>
      yieldContext.wrapSharedTypeSchemaView();

  /// Handles an explicit return statement.
  ///
  /// If the return type is declared, the expression type is checked. If the
  /// return type is inferred the expression type registered for inference
  /// in [inferReturnType].
  void handleReturn(
    ReturnStatement statement,
    DartType type,
    bool isArrow, {
    required InternalNode expressionNode,
  });

  /// Handles an explicit yield statement.
  ///
  /// If the return type is declared, the expression type is checked. If the
  /// return type is inferred the expression type registered for inference
  /// in [inferReturnType].
  void handleYield(
    YieldStatement node,
    ExpressionInferenceResult expressionResult, {
    required InternalNode expressionNode,
  });

  /// Handles an implicit return statement.
  ///
  /// If the return type is declared, the expression type is checked. If the
  /// return type is inferred the expression type registered for inference
  /// in [inferReturnType].
  StatementInferenceResult handleImplicitReturn(
    InferenceVisitorBase inferrer,
    InternalStatement body,
    StatementInferenceResult inferenceResult,
    int fileOffset,
  );

  /// Infers the return type for the function.
  ///
  /// If the function is a non-generator function this is based on the explicit
  /// and implicit return statements registered in [handleReturn] and
  /// [handleImplicitReturn].
  ///
  /// If the function is a generator function this is based on the explicit
  /// yield statements registered in [handleYield].
  DartType inferReturnType(
    InferenceVisitorBase inferrer, {
    required bool hasImplicitReturn,
  });
}

class _SyncContext extends BodyInferenceContext {
  final InferenceVisitorBase inferrer;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAsync => false;

  /// The typing expectation for the subexpression of a `return` statement
  /// inside the function.
  final DartType _returnContext;

  @override
  DartType get returnContext => _returnContext;

  @override
  // Coverage-ignore(suite): Not run.
  DartType get yieldContext => const UnknownType();

  @override
  DartType? get emittedValueType => null;

  final DartType _declaredReturnType;

  final bool _needToInferReturnType;

  DartType? _inferredReturnType;

  /// Whether the function is an arrow function.
  bool? _isArrow;

  /// A list of information for the return statements in functions whose return
  /// type is being inferred.
  ///
  /// The returns are checked for validity after the return type is inferred.
  List<_ReturnInfo>? _returnStatementInfos;

  new(
    this.inferrer,
    this._returnContext,
    this._declaredReturnType,
    this._needToInferReturnType,
    super.isRoot,
  ) : super._() {
    if (_needToInferReturnType) {
      _returnStatementInfos = [];
    }
  }

  void _checkValidReturn(
    DartType returnType,
    ReturnStatement statement,
    DartType expressionType, {
    required InternalNode expressionNode,
  }) {
    if (statement.expression == null) {
      // It is a compile-time error if s is `return;`, unless T is void,
      // dynamic, or Null.
      if (returnType is VoidType ||
          returnType is DynamicType ||
          returnType is NullType) {
        // Valid return;
      } else {
        statement.expression = extern.createInvalidExpressionFromErrorText(
          inferrer.problemReporting.buildProblem(
            compilerContext: inferrer.compilerContext,
            message: diag.returnWithoutExpressionSync,
            fileUri: inferrer.fileUri,
            fileOffset: statement.fileOffset,
            length: noLength,
          ),
          expression: extern.createNullLiteral(
            fileOffset: statement.fileOffset,
          ),
        )..parent = statement;
      }
    } else {
      if (_isArrow! && returnType is VoidType) {
        // For `=> e` it is a compile-time error if T is not void, and it
        // would have been a compile-time error to declare the function with
        // the body `{ return e; }` rather than `=> e`.
        return;
      }

      if (returnType is VoidType &&
          !(expressionType is VoidType ||
              expressionType is DynamicType ||
              expressionType is NullType)) {
        // It is a compile-time error if s is `return e;`, T is void, and S is
        // neither void, dynamic, nor Null.
        statement.expression = extern.createInvalidExpressionFromErrorText(
          inferrer.problemReporting.buildProblem(
            compilerContext: inferrer.compilerContext,
            message: diag.returnFromVoidFunction,
            fileUri: inferrer.fileUri,
            fileOffset: statement.expression!.fileOffset,
            length: noLength,
          ),
          expression: statement.expression!,
        )..parent = statement;
      } else if (!(returnType is VoidType || returnType is DynamicType) &&
          expressionType is VoidType) {
        // Coverage-ignore-block(suite): Not run.
        // It is a compile-time error if s is `return e;`, T is neither void
        // nor dynamic, and S is void.
        statement.expression = extern.createInvalidExpressionFromErrorText(
          inferrer.problemReporting.buildProblem(
            compilerContext: inferrer.compilerContext,
            message: diag.invalidReturn.withArguments(
              actualType: expressionType,
              expectedType: _declaredReturnType,
            ),
            fileUri: inferrer.fileUri,
            fileOffset: statement.expression!.fileOffset,
            length: noLength,
          ),
          expression: statement.expression!,
        )..parent = statement;
      } else if (expressionType is! VoidType) {
        // It is a compile-time error if s is `return e;`, S is not void, and
        // S is not assignable to T.
        Expression expression = inferrer.ensureAssignable(
          _returnContext,
          expressionType,
          statement.expression!,
          fileOffset: statement.expression!.fileOffset,
          errorTemplate: diag.invalidReturn,
          assignedNode: expressionNode,
        );
        statement.expression = expression..parent = statement;
      }
    }
  }

  /// Updates the inferred return type based on the presence of a return
  /// statement returning the given [type].
  @override
  void handleReturn(
    ReturnStatement statement,
    DartType type,
    bool isArrow, {
    required InternalNode expressionNode,
  }) {
    // The first return we see tells us if we have an arrow function.
    if (this._isArrow == null) {
      this._isArrow = isArrow;
    } else {
      assert(this._isArrow == isArrow);
    }

    if (_needToInferReturnType) {
      // Add the return to a list to be checked for validity after we've
      // inferred the return type.
      _returnStatementInfos!.add(
        new _ReturnInfo(
          statement: statement,
          expressionType: type,
          expressionNode: expressionNode,
        ),
      );
    } else {
      _checkValidReturn(
        _declaredReturnType,
        statement,
        type,
        expressionNode: expressionNode,
      );
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  void handleYield(
    YieldStatement node,
    ExpressionInferenceResult expressionResult, {
    required InternalNode expressionNode,
  }) {
    node.expression = expressionResult.expression..parent = node;
  }

  @override
  DartType inferReturnType(
    InferenceVisitorBase inferrer, {
    required bool hasImplicitReturn,
  }) {
    assert(_needToInferReturnType);
    DartType? actualReturnedType;
    DartType inferredReturnType;
    if (hasImplicitReturn) {
      // No explicit returns we have an implicit `return null`.
      actualReturnedType = const NullType();
    } else {
      // No explicit return and the function doesn't complete normally; that
      // is, it throws.
      actualReturnedType = NeverType.fromNullability(Nullability.nonNullable);
    }
    // Use the types seen from the explicit return statements.
    for (int i = 0; i < _returnStatementInfos!.length; i++) {
      _ReturnInfo info = _returnStatementInfos![i];
      ReturnStatement statement = info.statement;
      DartType type = info.expressionType;
      // The return expression has to be assignable to the return type
      // expectation from the downwards inference context.
      if (statement.expression != null) {
        if (!inferrer.isAssignable(_returnContext, type)) {
          type = inferrer.computeGreatestClosure(_returnContext);
        }
      }
      if (actualReturnedType == null) {
        actualReturnedType = type;
      } else {
        actualReturnedType = inferrer.typeSchemaEnvironment
            .getStandardUpperBound(actualReturnedType, type);
      }
    }

    // Let T be the actual returned type of a function literal as computed
    // above. Let R be the greatest closure of the typing context K as
    // computed above.
    DartType returnContext = inferrer.computeGreatestClosure2(
      _declaredReturnType,
    );
    if (returnContext is VoidType) {
      // With null safety: if R is void, or the function literal is marked
      // async and R is FutureOr<void>, let S be void.
      inferredReturnType = const VoidType();
    } else if (inferrer.typeSchemaEnvironment.isSubtypeOf(
      actualReturnedType!,
      returnContext,
    )) {
      // Otherwise, if T <: R then let S be T.
      inferredReturnType = actualReturnedType;
    } else {
      // Otherwise, let S be R.
      inferredReturnType = returnContext;
    }

    for (int i = 0; i < _returnStatementInfos!.length; i++) {
      _ReturnInfo info = _returnStatementInfos![i];
      _checkValidReturn(
        inferredReturnType,
        info.statement,
        info.expressionType,
        expressionNode: info.expressionNode,
      );
    }

    return _inferredReturnType = demoteTypeInLibrary(inferredReturnType);
  }

  @override
  StatementInferenceResult handleImplicitReturn(
    InferenceVisitorBase inferrer,
    InternalStatement body,
    StatementInferenceResult inferenceResult,
    int fileOffset,
  ) {
    DartType returnType;
    if (_needToInferReturnType) {
      assert(
        _inferredReturnType != null,
        "Return type has not yet been inferred.",
      );
      returnType = _inferredReturnType!;
    } else {
      returnType = _declaredReturnType;
    }
    if (!containsInvalidType(returnType) &&
        returnType.isPotentiallyNonNullable &&
        inferrer.flowAnalysis.isReachable) {
      Statement resultStatement = inferenceResult.statement;
      // Create a synthetic return statement with the error.
      Statement returnStatement = new ReturnStatement(
        extern.createInvalidExpressionFromErrorText(
          inferrer.problemReporting.buildProblem(
            compilerContext: inferrer.compilerContext,
            message: diag.implicitReturnNull.withArguments(
              returnType: returnType,
            ),
            fileUri: inferrer.fileUri,
            fileOffset: fileOffset,
            length: noLength,
          ),
          expression: extern.createNullLiteral(fileOffset: fileOffset),
        ),
      )..fileOffset = fileOffset;
      if (resultStatement is Block) {
        resultStatement.addStatement(returnStatement);
      } else {
        // Coverage-ignore-block(suite): Not run.
        resultStatement = new Block(<Statement>[
          resultStatement,
          returnStatement,
        ])..fileOffset = fileOffset;
      }
      return new StatementInferenceResult.single(resultStatement);
    }
    return inferenceResult;
  }
}

/// Keeps track of information about the innermost function or closure being
/// inferred.
class _AsyncContext extends BodyInferenceContext {
  final InferenceVisitorBase inferrer;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAsync => true;

  /// The typing expectation for the subexpression of a `return` statement
  /// inside the function.
  ///
  /// This will be a "FutureOr" type (since it is permissible for such a
  /// function to return either a direct value or a future).
  final DartType _returnContext;

  @override
  DartType get returnContext => _returnContext;

  @override
  // Coverage-ignore(suite): Not run.
  DartType get yieldContext => const UnknownType();

  @override
  DartType? emittedValueType;

  final DartType _declaredReturnType;

  final bool _needToInferReturnType;

  DartType? _inferredReturnType;

  /// Whether the function is an arrow function.
  bool? _isArrow;

  /// A list of information for the return statements in functions whose return
  /// type is being inferred.
  ///
  /// The returns are checked for validity after the return type is inferred.
  List<_ReturnInfo>? _returnStatementInfos;

  new(
    this.inferrer,
    this._returnContext,
    this._declaredReturnType,
    this._needToInferReturnType,
    this.emittedValueType,
    super.isRoot,
  ) : super._() {
    if (_needToInferReturnType) {
      _returnStatementInfos = [];
    }
  }

  void _checkValidReturn(
    DartType returnType,
    ReturnStatement statement,
    DartType expressionType, {
    required InternalNode expressionNode,
  }) {
    assert(
      emittedValueType != null,
      "Future value type has not been computed.",
    );

    if (statement.expression == null) {
      // It is a compile-time error if s is `return;`, unless T_v is void,
      // dynamic, or Null.
      if (emittedValueType is VoidType ||
          emittedValueType is DynamicType ||
          emittedValueType is NullType) {
        // Valid return;
      } else {
        statement.expression = extern.createInvalidExpressionFromErrorText(
          inferrer.problemReporting.buildProblem(
            compilerContext: inferrer.compilerContext,
            message: diag.returnWithoutExpressionAsync,
            fileUri: inferrer.fileUri,
            fileOffset: statement.fileOffset,
            length: noLength,
          ),
          expression: extern.createNullLiteral(
            fileOffset: statement.fileOffset,
          ),
        )..parent = statement;
      }
    } else {
      if (_isArrow! &&
          inferrer.typeSchemaEnvironment.flatten(returnType) is VoidType) {
        // For `async => e` it is a compile-time error if flatten(T) is not
        // void, and it would have been a compile-time error to declare the
        // function with the body `async { return e; }` rather than
        // `async => e`.
        return;
      }

      DartType flattenedExpressionType = inferrer.typeSchemaEnvironment.flatten(
        expressionType,
      );
      if (emittedValueType is VoidType &&
          !(flattenedExpressionType is VoidType ||
              // Coverage-ignore(suite): Not run.
              flattenedExpressionType is DynamicType ||
              // Coverage-ignore(suite): Not run.
              flattenedExpressionType is NullType)) {
        // Coverage-ignore-block(suite): Not run.
        // It is a compile-time error if s is `return e;`, T_v is void, and
        // flatten(S) is neither void, dynamic, Null.
        statement.expression = extern.createInvalidExpressionFromErrorText(
          inferrer.problemReporting.buildProblem(
            compilerContext: inferrer.compilerContext,
            message: diag.invalidReturnAsync.withArguments(
              actualType: expressionType,
              expectedType: returnType,
            ),
            fileUri: inferrer.fileUri,
            fileOffset: statement.expression!.fileOffset,
            length: noLength,
          ),
          expression: extern.createNullLiteral(
            fileOffset: statement.fileOffset,
          ),
        )..parent = statement;
      } else if (!(emittedValueType is VoidType ||
              emittedValueType is DynamicType) &&
          flattenedExpressionType is VoidType) {
        // Coverage-ignore-block(suite): Not run.
        // It is a compile-time error if s is `return e;`, T_v is neither void
        // nor dynamic, and flatten(S) is void.
        statement.expression = extern.createInvalidExpressionFromErrorText(
          inferrer.problemReporting.buildProblem(
            compilerContext: inferrer.compilerContext,
            message: diag.invalidReturnAsync.withArguments(
              actualType: expressionType,
              expectedType: returnType,
            ),
            fileUri: inferrer.fileUri,
            fileOffset: statement.expression!.fileOffset,
            length: noLength,
          ),
          expression: extern.createNullLiteral(
            fileOffset: statement.fileOffset,
          ),
        )..parent = statement;
      } else if (flattenedExpressionType is! VoidType &&
          !inferrer.typeSchemaEnvironment
              .performSubtypeCheck(flattenedExpressionType, emittedValueType!)
              .isSuccess()) {
        // It is a compile-time error if s is `return e;`, flatten(S) is not
        // void, S is not assignable to T_v, and flatten(S) is not a subtype
        // of T_v.
        statement.expression = inferrer.ensureAssignable(
          emittedValueType!,
          expressionType,
          statement.expression!,
          fileOffset: statement.expression!.fileOffset,
          runtimeCheckedType: inferrer.computeGreatestClosure2(_returnContext),
          declaredContextType: returnType,
          isVoidAllowed: false,
          errorTemplate: diag.invalidReturnAsync,
          assignedNode: expressionNode,
        )..parent = statement;
      }
    }
  }

  /// Updates the inferred return type based on the presence of a return
  /// statement returning the given [type].
  @override
  void handleReturn(
    ReturnStatement statement,
    DartType type,
    bool isArrow, {
    required InternalNode expressionNode,
  }) {
    // The first return we see tells us if we have an arrow function.
    if (this._isArrow == null) {
      this._isArrow = isArrow;
    } else {
      assert(this._isArrow == isArrow);
    }

    if (_needToInferReturnType) {
      // Add the return to a list to be checked for validity after we've
      // inferred the return type.
      _returnStatementInfos!.add(
        new _ReturnInfo(
          statement: statement,
          expressionType: type,
          expressionNode: expressionNode,
        ),
      );
    } else {
      _checkValidReturn(
        _declaredReturnType,
        statement,
        type,
        expressionNode: expressionNode,
      );
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  void handleYield(
    YieldStatement node,
    ExpressionInferenceResult expressionResult, {
    required InternalNode expressionNode,
  }) {
    node.expression = expressionResult.expression..parent = node;
  }

  @override
  DartType inferReturnType(
    InferenceVisitorBase inferrer, {
    required bool hasImplicitReturn,
  }) {
    assert(_needToInferReturnType);
    DartType? inferredType;

    if (hasImplicitReturn) {
      // No explicit returns we have an implicit `return null`.
      inferredType = const NullType();
    } else {
      // No explicit return and the function doesn't complete normally; that
      // is, it throws.
      inferredType = NeverType.fromNullability(Nullability.nonNullable);
    }
    // Use the types seen from the explicit return statements.
    for (int i = 0; i < _returnStatementInfos!.length; i++) {
      _ReturnInfo info = _returnStatementInfos![i];
      DartType type = info.expressionType;

      DartType unwrappedType = inferrer.typeSchemaEnvironment.flatten(type);
      if (inferredType == null) {
        inferredType = unwrappedType;
      } else {
        inferredType = inferrer.typeSchemaEnvironment.getStandardUpperBound(
          inferredType,
          unwrappedType,
        );
      }
    }

    // Let `T` be the **actual returned type** of a function literal as
    // computed above.

    // Let `R` be the greatest closure of the typing context `K` as computed
    // above. If `R` is `void`, or the function literal is marked `async` and
    // `R` is `FutureOr<void>`, let `S` be `void`. Otherwise, if `T <: R` then
    // let `S` be `T`.  Otherwise, let `S` be `R`.
    DartType returnContext = inferrer.computeGreatestClosure2(_returnContext);
    if (returnContext is VoidType ||
        returnContext is FutureOrType &&
            returnContext.typeArgument is VoidType) {
      inferredType = const VoidType();
    } else if (!inferrer.typeSchemaEnvironment.isSubtypeOf(
      inferredType!,
      returnContext,
    )) {
      // If the inferred return type isn't a subtype of the context, we use
      // the context.
      inferredType = returnContext;
    }
    inferredType = inferrer.wrapFutureType(
      inferrer.typeSchemaEnvironment.flatten(inferredType),
      Nullability.nonNullable,
    );

    emittedValueType = computeFutureValueType(inferrer.coreTypes, inferredType);

    for (int i = 0; i < _returnStatementInfos!.length; i++) {
      _ReturnInfo info = _returnStatementInfos![i];
      _checkValidReturn(
        inferredType,
        info.statement,
        info.expressionType,
        expressionNode: info.expressionNode,
      );
    }

    return _inferredReturnType = demoteTypeInLibrary(inferredType);
  }

  @override
  StatementInferenceResult handleImplicitReturn(
    InferenceVisitorBase inferrer,
    InternalStatement body,
    StatementInferenceResult inferenceResult,
    int fileOffset,
  ) {
    DartType returnType;
    if (_needToInferReturnType) {
      assert(
        _inferredReturnType != null,
        "Return type has not yet been inferred.",
      );
      returnType = _inferredReturnType!;
    } else {
      returnType = _declaredReturnType;
    }
    returnType = inferrer.typeSchemaEnvironment.flatten(returnType);
    if (!containsInvalidType(returnType) &&
        returnType.isPotentiallyNonNullable &&
        inferrer.flowAnalysis.isReachable) {
      Statement resultStatement = inferenceResult.statement;
      // Create a synthetic return statement with the error.
      Statement returnStatement = new ReturnStatement(
        extern.createInvalidExpressionFromErrorText(
          inferrer.problemReporting.buildProblem(
            compilerContext: inferrer.compilerContext,
            message: diag.implicitReturnNull.withArguments(
              returnType: returnType,
            ),
            fileUri: inferrer.fileUri,
            fileOffset: fileOffset,
            length: noLength,
          ),
          expression: extern.createNullLiteral(fileOffset: fileOffset),
        ),
      )..fileOffset = fileOffset;
      if (resultStatement is Block) {
        resultStatement.addStatement(returnStatement);
      } else {
        // Coverage-ignore-block(suite): Not run.
        resultStatement = new Block(<Statement>[
          resultStatement,
          returnStatement,
        ])..fileOffset = fileOffset;
      }
      return new StatementInferenceResult.single(resultStatement);
    }
    return inferenceResult;
  }
}

/// Keeps track of information about the innermost function or closure being
/// inferred.
class _SyncStarContext extends BodyInferenceContext {
  final InferenceVisitorBase inferrer;

  @override
  bool get isAsync => false;

  /// The typing expectation for the subexpression of a `return` or `yield`
  /// statement inside the function.
  ///
  /// For non-generator async functions, this will be a "FutureOr" type (since
  /// it is permissible for such a function to return either a direct value or
  /// a future).
  ///
  /// For generator functions containing a `yield*` statement, the expected type
  /// for the subexpression of the `yield*` statement is the result of wrapping
  /// this typing expectation in `Stream` or `Iterator`, as appropriate.
  final DartType _yieldElementContext;

  @override
  // Coverage-ignore(suite): Not run.
  DartType get returnContext => const UnknownType();

  @override
  DartType get yieldContext => _yieldElementContext;

  @override
  DartType? get emittedValueType => _emittedValueType;

  final DartType _declaredReturnType;

  DartType? _emittedValueType;

  final bool _needToInferReturnType;

  /// A list of return expression types in functions whose return type is
  /// being inferred.
  List<DartType>? _yieldElementTypes;

  new(
    this.inferrer,
    this._yieldElementContext,
    this._declaredReturnType,
    this._needToInferReturnType,
    super.isRoot,
  ) : super._() {
    if (_needToInferReturnType) {
      _yieldElementTypes = [];
    } else {
      _emittedValueType = inferrer.computeGreatestClosure(_yieldElementContext);
    }
  }

  /// Updates the inferred return type based on the presence of a return
  /// statement returning the given [type].
  @override
  // Coverage-ignore(suite): Not run.
  void handleReturn(
    ReturnStatement statement,
    DartType type,
    bool isArrow, {
    required InternalNode expressionNode,
  }) {}

  @override
  void handleYield(
    YieldStatement node,
    ExpressionInferenceResult expressionResult, {
    required InternalNode expressionNode,
  }) {
    DartType expectedType = node.isYieldStar
        ? inferrer.wrapType(
            _yieldElementContext,
            inferrer.coreTypes.iterableClass,
            Nullability.nonNullable,
          )
        : _yieldElementContext;
    Expression expression = inferrer
        .ensureAssignableResult(
          expectedType,
          expressionResult,
          fileOffset: node.fileOffset,
          assignedNode: expressionNode,
        )
        .expression;
    node.expression = expression..parent = node;
    DartType type =
        expressionResult.postCoercionType ?? expressionResult.inferredType;
    if (_needToInferReturnType) {
      DartType elementType = type;
      if (node.isYieldStar) {
        elementType =
            inferrer.getDerivedTypeArgumentOf(
              type,
              inferrer.coreTypes.iterableClass,
            ) ??
            elementType;
      }
      _yieldElementTypes!.add(elementType);
    }
  }

  @override
  DartType inferReturnType(
    InferenceVisitorBase inferrer, {
    required bool hasImplicitReturn,
  }) {
    assert(_needToInferReturnType);
    DartType? inferredElementType;
    if (_yieldElementTypes!.isNotEmpty) {
      // Use the types seen from the explicit return statements.
      for (int i = 0; i < _yieldElementTypes!.length; i++) {
        DartType type = _yieldElementTypes![i];
        if (inferredElementType == null) {
          inferredElementType = type;
        } else {
          inferredElementType = inferrer.typeSchemaEnvironment
              .getStandardUpperBound(inferredElementType, type);
        }
      }
    }
    // Coverage-ignore(suite): Not run.
    else if (hasImplicitReturn) {
      // No explicit returns we have an implicit `return null`.
      inferredElementType = const NullType();
    } else {
      // No explicit return and the function doesn't complete normally; that is,
      // it throws.
      inferredElementType = NeverType.fromNullability(Nullability.nonNullable);
    }

    DartType inferredType = inferrer.wrapType(
      inferredElementType!,
      inferrer.coreTypes.iterableClass,
      Nullability.nonNullable,
    );

    if (!inferrer.typeSchemaEnvironment.isSubtypeOf(
      inferredType,
      _yieldElementContext,
    )) {
      // Coverage-ignore-block(suite): Not run.
      // If the inferred return type isn't a subtype of the context, we use the
      // context.
      inferredType = inferrer.computeGreatestClosure2(_declaredReturnType);
    }

    DartType demotedType = demoteTypeInLibrary(inferredType);
    _emittedValueType = inferrer.getTypeArgumentOf(
      inferrer.typeSchemaEnvironment.getUnionFreeType(demotedType),
      inferrer.coreTypes.iterableClass,
    );
    return demotedType;
  }

  @override
  StatementInferenceResult handleImplicitReturn(
    InferenceVisitorBase inferrer,
    InternalStatement body,
    StatementInferenceResult inferenceResult,
    int fileOffset,
  ) {
    // There is no implicit return.
    return inferenceResult;
  }
}

/// Keeps track of information about the innermost function or closure being
/// inferred.
class _AsyncStarContext extends BodyInferenceContext {
  final InferenceVisitorBase inferrer;

  @override
  bool get isAsync => true;

  /// The typing expectation for the subexpression of a `return` or `yield`
  /// statement inside the function.
  ///
  /// For non-generator async functions, this will be a "FutureOr" type (since
  /// it is permissible for such a function to return either a direct value or
  /// a future).
  ///
  /// For generator functions containing a `yield*` statement, the expected type
  /// for the subexpression of the `yield*` statement is the result of wrapping
  /// this typing expectation in `Stream` or `Iterator`, as appropriate.
  final DartType _yieldElementContext;

  @override
  // Coverage-ignore(suite): Not run.
  DartType get returnContext => const UnknownType();

  @override
  DartType get yieldContext => _yieldElementContext;

  @override
  DartType? get emittedValueType => _emittedValueType;

  final DartType _declaredReturnType;

  DartType? _emittedValueType;

  final bool _needToInferReturnType;

  /// A list of return expression types in functions whose return type is
  /// being inferred.
  List<DartType>? _yieldElementTypes;

  new(
    this.inferrer,
    this._yieldElementContext,
    this._declaredReturnType,
    this._needToInferReturnType,
    super.isRoot,
  ) : super._() {
    if (_needToInferReturnType) {
      _yieldElementTypes = [];
    } else {
      _emittedValueType = inferrer.computeGreatestClosure(_yieldElementContext);
    }
  }

  /// Updates the inferred return type based on the presence of a return
  /// statement returning the given [type].
  @override
  // Coverage-ignore(suite): Not run.
  void handleReturn(
    ReturnStatement statement,
    DartType type,
    bool isArrow, {
    required InternalNode expressionNode,
  }) {}

  @override
  void handleYield(
    YieldStatement node,
    ExpressionInferenceResult expressionResult, {
    required InternalNode expressionNode,
  }) {
    DartType expectedType = node.isYieldStar
        ? inferrer.wrapType(
            _yieldElementContext,
            inferrer.coreTypes.streamClass,
            Nullability.nonNullable,
          )
        : _yieldElementContext;

    Expression expression = inferrer
        .ensureAssignableResult(
          expectedType,
          expressionResult,
          fileOffset: node.fileOffset,
          assignedNode: expressionNode,
        )
        .expression;
    node.expression = expression..parent = node;
    DartType type =
        expressionResult.postCoercionType ?? expressionResult.inferredType;
    if (_needToInferReturnType) {
      DartType elementType = type;
      if (node.isYieldStar) {
        elementType =
            inferrer.getDerivedTypeArgumentOf(
              type,
              inferrer.coreTypes.streamClass,
            ) ??
            type;
      }
      _yieldElementTypes!.add(elementType);
    }
  }

  @override
  DartType inferReturnType(
    InferenceVisitorBase inferrer, {
    required bool hasImplicitReturn,
  }) {
    assert(_needToInferReturnType);
    DartType? inferredElementType;
    if (_yieldElementTypes!.isNotEmpty) {
      // Use the types seen from the explicit return statements.
      for (DartType elementType in _yieldElementTypes!) {
        if (inferredElementType == null) {
          inferredElementType = elementType;
        } else {
          inferredElementType = inferrer.typeSchemaEnvironment
              .getStandardUpperBound(inferredElementType, elementType);
        }
      }
    }
    // Coverage-ignore(suite): Not run.
    else if (hasImplicitReturn) {
      // No explicit returns we have an implicit `return null`.
      inferredElementType = const NullType();
    } else {
      // No explicit return and the function doesn't complete normally; that is,
      // it throws.
      inferredElementType = NeverType.fromNullability(Nullability.nonNullable);
    }

    DartType inferredType = inferrer.wrapType(
      inferredElementType!,
      inferrer.coreTypes.streamClass,
      Nullability.nonNullable,
    );

    if (!inferrer.typeSchemaEnvironment.isSubtypeOf(
      inferredType,
      _yieldElementContext,
    )) {
      // If the inferred return type isn't a subtype of the context, we use the
      // context.
      inferredType = inferrer.computeGreatestClosure2(_declaredReturnType);
    }

    DartType demotedType = demoteTypeInLibrary(inferredType);
    _emittedValueType = inferrer.getTypeArgumentOf(
      inferrer.typeSchemaEnvironment.getUnionFreeType(demotedType),
      inferrer.coreTypes.streamClass,
    );
    return demotedType;
  }

  @override
  StatementInferenceResult handleImplicitReturn(
    InferenceVisitorBase inferrer,
    InternalStatement body,
    StatementInferenceResult inferenceResult,
    int fileOffset,
  ) {
    // There is no implicit return.
    return inferenceResult;
  }
}

class _ReturnInfo({
  /// The inferred return statement.
  required final ReturnStatement statement,

  /// The static type of the returned expression.
  required final DartType expressionType,

  /// The internal node corresponding to the expression.
  required final InternalNode expressionNode,
});
