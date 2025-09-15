// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/src/future_value_type.dart';

import '../codes/cfe_codes.dart';
import '../kernel/invalid_type.dart';
import '../source/check_helper.dart';
import 'inference_results.dart';
import 'inference_visitor_base.dart';
import 'type_demotion.dart';
import 'type_schema.dart' show UnknownType;

/// Keeps track of information about the innermost function or closure being
/// inferred.
abstract class ClosureContext {
  /// Returns `true` if this is an `async` or an `async*` function.
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

  factory ClosureContext(
    InferenceVisitorBase inferrer,
    AsyncMarker asyncMarker,
    DartType returnContext,
    bool needToInferReturnType,
  ) {
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
        return new _AsyncStarClosureContext(
          inferrer,
          yieldContext,
          declaredReturnType,
          needToInferReturnType,
        );
      } else {
        DartType yieldContext = inferrer.getTypeArgumentOf(
          inferrer.typeSchemaEnvironment.getUnionFreeType(returnContext),
          inferrer.coreTypes.iterableClass,
        );
        return new _SyncStarClosureContext(
          inferrer,
          yieldContext,
          declaredReturnType,
          needToInferReturnType,
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
      return new _AsyncClosureContext(
        inferrer,
        returnContext,
        declaredReturnType,
        needToInferReturnType,
        futureValueType,
      );
    } else {
      return new _SyncClosureContext(
        inferrer,
        returnContext,
        declaredReturnType,
        needToInferReturnType,
      );
    }
  }

  /// Handles an explicit return statement.
  ///
  /// If the return type is declared, the expression type is checked. If the
  /// return type is inferred the expression type registered for inference
  /// in [inferReturnType].
  void handleReturn(ReturnStatement statement, DartType type, bool isArrow);

  /// Handles an explicit yield statement.
  ///
  /// If the return type is declared, the expression type is checked. If the
  /// return type is inferred the expression type registered for inference
  /// in [inferReturnType].
  void handleYield(
    YieldStatement node,
    ExpressionInferenceResult expressionResult,
  );

  /// Handles an implicit return statement.
  ///
  /// If the return type is declared, the expression type is checked. If the
  /// return type is inferred the expression type registered for inference
  /// in [inferReturnType].
  StatementInferenceResult handleImplicitReturn(
    InferenceVisitorBase inferrer,
    Statement body,
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

class _SyncClosureContext implements ClosureContext {
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

  /// A list of return statements in functions whose return type is being
  /// inferred.
  ///
  /// The returns are checked for validity after the return type is inferred.
  List<ReturnStatement>? _returnStatements;

  /// A list of return expression types in functions whose return type is
  /// being inferred.
  List<DartType>? _returnExpressionTypes;

  _SyncClosureContext(
    this.inferrer,
    this._returnContext,
    this._declaredReturnType,
    this._needToInferReturnType,
  ) {
    if (_needToInferReturnType) {
      _returnStatements = [];
      _returnExpressionTypes = [];
    }
  }

  void _checkValidReturn(
    DartType returnType,
    ReturnStatement statement,
    DartType expressionType,
  ) {
    if (statement.expression == null) {
      // It is a compile-time error if s is `return;`, unless T is void,
      // dynamic, or Null.
      if (returnType is VoidType ||
          returnType is DynamicType ||
          returnType is NullType) {
        // Valid return;
      } else {
        statement.expression = inferrer.problemReporting.wrapInProblem(
          compilerContext: inferrer.compilerContext,
          expression: new NullLiteral()..fileOffset = statement.fileOffset,
          message: codeReturnWithoutExpressionSync,
          fileUri: inferrer.fileUri,
          fileOffset: statement.fileOffset,
          length: noLength,
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
        statement.expression = inferrer.problemReporting.wrapInProblem(
          compilerContext: inferrer.compilerContext,
          expression: statement.expression!,
          message: codeReturnFromVoidFunction,
          fileUri: inferrer.fileUri,
          fileOffset: statement.expression!.fileOffset,
          length: noLength,
        )..parent = statement;
      } else if (!(returnType is VoidType || returnType is DynamicType) &&
          expressionType is VoidType) {
        // Coverage-ignore-block(suite): Not run.
        // It is a compile-time error if s is `return e;`, T is neither void
        // nor dynamic, and S is void.
        statement.expression = inferrer.problemReporting.wrapInProblem(
          compilerContext: inferrer.compilerContext,
          expression: statement.expression!,
          message: codeInvalidReturn.withArgumentsOld(
            expressionType,
            _declaredReturnType,
          ),
          fileUri: inferrer.fileUri,
          fileOffset: statement.expression!.fileOffset,
          length: noLength,
        )..parent = statement;
      } else if (expressionType is! VoidType) {
        // It is a compile-time error if s is `return e;`, S is not void, and
        // S is not assignable to T.
        Expression expression = inferrer.ensureAssignable(
          _returnContext,
          expressionType,
          statement.expression!,
          fileOffset: statement.expression!.fileOffset,
          isVoidAllowed: true,
          errorTemplate: codeInvalidReturn,
        );
        statement.expression = expression..parent = statement;
      }
    }
  }

  /// Updates the inferred return type based on the presence of a return
  /// statement returning the given [type].
  @override
  void handleReturn(ReturnStatement statement, DartType type, bool isArrow) {
    // The first return we see tells us if we have an arrow function.
    if (this._isArrow == null) {
      this._isArrow = isArrow;
    } else {
      assert(this._isArrow == isArrow);
    }

    if (_needToInferReturnType) {
      // Add the return to a list to be checked for validity after we've
      // inferred the return type.
      _returnStatements!.add(statement);
      _returnExpressionTypes!.add(type);
    } else {
      _checkValidReturn(_declaredReturnType, statement, type);
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  void handleYield(
    YieldStatement node,
    ExpressionInferenceResult expressionResult,
  ) {
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
    for (int i = 0; i < _returnStatements!.length; i++) {
      ReturnStatement statement = _returnStatements![i];
      DartType type = _returnExpressionTypes![i];
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

    for (int i = 0; i < _returnStatements!.length; ++i) {
      _checkValidReturn(
        inferredReturnType,
        _returnStatements![i],
        _returnExpressionTypes![i],
      );
    }

    return _inferredReturnType = demoteTypeInLibrary(inferredReturnType);
  }

  @override
  StatementInferenceResult handleImplicitReturn(
    InferenceVisitorBase inferrer,
    Statement body,
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
      Statement resultStatement = inferenceResult.hasChanged
          ? inferenceResult.statement
          : body;
      // Create a synthetic return statement with the error.
      Statement returnStatement = new ReturnStatement(
        inferrer.problemReporting.wrapInProblem(
          compilerContext: inferrer.compilerContext,
          expression: new NullLiteral()..fileOffset = fileOffset,
          message: codeImplicitReturnNull.withArgumentsOld(returnType),
          fileUri: inferrer.fileUri,
          fileOffset: fileOffset,
          length: noLength,
        ),
      )..fileOffset = fileOffset;
      if (resultStatement is Block) {
        resultStatement.statements.add(returnStatement);
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
class _AsyncClosureContext implements ClosureContext {
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

  /// A list of return statements in functions whose return type is being
  /// inferred.
  ///
  /// The returns are checked for validity after the return type is inferred.
  List<ReturnStatement>? _returnStatements;

  /// A list of return expression types in functions whose return type is
  /// being inferred.
  List<DartType>? _returnExpressionTypes;

  _AsyncClosureContext(
    this.inferrer,
    this._returnContext,
    this._declaredReturnType,
    this._needToInferReturnType,
    this.emittedValueType,
  ) {
    if (_needToInferReturnType) {
      _returnStatements = [];
      _returnExpressionTypes = [];
    }
  }

  void _checkValidReturn(
    DartType returnType,
    ReturnStatement statement,
    DartType expressionType,
  ) {
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
        statement.expression = inferrer.problemReporting.wrapInProblem(
          compilerContext: inferrer.compilerContext,
          expression: new NullLiteral()..fileOffset = statement.fileOffset,
          message: codeReturnWithoutExpressionAsync,
          fileUri: inferrer.fileUri,
          fileOffset: statement.fileOffset,
          length: noLength,
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
        statement.expression = inferrer.problemReporting.wrapInProblem(
          compilerContext: inferrer.compilerContext,
          expression: new NullLiteral()..fileOffset = statement.fileOffset,
          message: codeInvalidReturnAsync.withArgumentsOld(
            expressionType,
            returnType,
          ),
          fileUri: inferrer.fileUri,
          fileOffset: statement.expression!.fileOffset,
          length: noLength,
        )..parent = statement;
      } else if (!(emittedValueType is VoidType ||
              emittedValueType is DynamicType) &&
          flattenedExpressionType is VoidType) {
        // Coverage-ignore-block(suite): Not run.
        // It is a compile-time error if s is `return e;`, T_v is neither void
        // nor dynamic, and flatten(S) is void.
        statement.expression = inferrer.problemReporting.wrapInProblem(
          compilerContext: inferrer.compilerContext,
          expression: new NullLiteral()..fileOffset = statement.fileOffset,
          message: codeInvalidReturnAsync.withArgumentsOld(
            expressionType,
            returnType,
          ),
          fileUri: inferrer.fileUri,
          fileOffset: statement.expression!.fileOffset,
          length: noLength,
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
          errorTemplate: codeInvalidReturnAsync,
        )..parent = statement;
      }
    }
  }

  /// Updates the inferred return type based on the presence of a return
  /// statement returning the given [type].
  @override
  void handleReturn(ReturnStatement statement, DartType type, bool isArrow) {
    // The first return we see tells us if we have an arrow function.
    if (this._isArrow == null) {
      this._isArrow = isArrow;
    } else {
      assert(this._isArrow == isArrow);
    }

    if (_needToInferReturnType) {
      // Add the return to a list to be checked for validity after we've
      // inferred the return type.
      _returnStatements!.add(statement);
      _returnExpressionTypes!.add(type);
    } else {
      _checkValidReturn(_declaredReturnType, statement, type);
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  void handleYield(
    YieldStatement node,
    ExpressionInferenceResult expressionResult,
  ) {
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
    for (int i = 0; i < _returnStatements!.length; i++) {
      DartType type = _returnExpressionTypes![i];

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

    for (int i = 0; i < _returnStatements!.length; ++i) {
      _checkValidReturn(
        inferredType,
        _returnStatements![i],
        _returnExpressionTypes![i],
      );
    }

    return _inferredReturnType = demoteTypeInLibrary(inferredType);
  }

  @override
  StatementInferenceResult handleImplicitReturn(
    InferenceVisitorBase inferrer,
    Statement body,
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
      Statement resultStatement = inferenceResult.hasChanged
          ? inferenceResult.statement
          : body;
      // Create a synthetic return statement with the error.
      Statement returnStatement = new ReturnStatement(
        inferrer.problemReporting.wrapInProblem(
          compilerContext: inferrer.compilerContext,
          expression: new NullLiteral()..fileOffset = fileOffset,
          message: codeImplicitReturnNull.withArgumentsOld(returnType),
          fileUri: inferrer.fileUri,
          fileOffset: fileOffset,
          length: noLength,
        ),
      )..fileOffset = fileOffset;
      if (resultStatement is Block) {
        resultStatement.statements.add(returnStatement);
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
class _SyncStarClosureContext implements ClosureContext {
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

  _SyncStarClosureContext(
    this.inferrer,
    this._yieldElementContext,
    this._declaredReturnType,
    this._needToInferReturnType,
  ) {
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
  void handleReturn(ReturnStatement statement, DartType type, bool isArrow) {}

  @override
  void handleYield(
    YieldStatement node,
    ExpressionInferenceResult expressionResult,
  ) {
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
        )
        .expression;
    node.expression = expression..parent = node;
    DartType type = expressionResult.inferredType;
    if (!identical(expressionResult.expression, expression)) {
      type = inferrer.computeGreatestClosure(expectedType);
    }
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
    Statement body,
    StatementInferenceResult inferenceResult,
    int fileOffset,
  ) {
    // There is no implicit return.
    return inferenceResult;
  }
}

/// Keeps track of information about the innermost function or closure being
/// inferred.
class _AsyncStarClosureContext implements ClosureContext {
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

  _AsyncStarClosureContext(
    this.inferrer,
    this._yieldElementContext,
    this._declaredReturnType,
    this._needToInferReturnType,
  ) {
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
  void handleReturn(ReturnStatement statement, DartType type, bool isArrow) {}

  @override
  void handleYield(
    YieldStatement node,
    ExpressionInferenceResult expressionResult,
  ) {
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
        )
        .expression;
    node.expression = expression..parent = node;
    DartType type = expressionResult.inferredType;
    if (!identical(expressionResult.expression, expression)) {
      type = inferrer.computeGreatestClosure(expectedType);
    }
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
    Statement body,
    StatementInferenceResult inferenceResult,
    int fileOffset,
  ) {
    // There is no implicit return.
    return inferenceResult;
  }
}
