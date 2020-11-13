// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

part of 'type_inferrer.dart';

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

  factory ClosureContext(TypeInferrerImpl inferrer, AsyncMarker asyncMarker,
      DartType returnContext, bool needToInferReturnType) {
    assert(returnContext != null);
    DartType declaredReturnType =
        inferrer.computeGreatestClosure(returnContext);
    bool isAsync = asyncMarker == AsyncMarker.Async ||
        asyncMarker == AsyncMarker.AsyncStar;
    bool isGenerator = asyncMarker == AsyncMarker.SyncStar ||
        asyncMarker == AsyncMarker.AsyncStar;
    if (isGenerator) {
      if (isAsync) {
        DartType yieldContext = inferrer.getTypeArgumentOf(
            returnContext, inferrer.coreTypes.streamClass);
        return new _AsyncStarClosureContext(
            yieldContext, declaredReturnType, needToInferReturnType);
      } else {
        DartType yieldContext = inferrer.getTypeArgumentOf(
            returnContext, inferrer.coreTypes.iterableClass);
        return new _SyncStarClosureContext(
            yieldContext, declaredReturnType, needToInferReturnType);
      }
    } else if (isAsync) {
      if (inferrer.isNonNullableByDefault) {
        returnContext = inferrer.wrapFutureOrType(
            inferrer.computeFutureValueTypeSchema(returnContext));
      } else {
        returnContext = inferrer.wrapFutureOrType(
            inferrer.typeSchemaEnvironment.flatten(returnContext));
      }
      return new _AsyncClosureContext(
          returnContext, declaredReturnType, needToInferReturnType);
    } else {
      return new _SyncClosureContext(
          returnContext, declaredReturnType, needToInferReturnType);
    }
  }

  /// Handles an explicit return statement.
  ///
  /// If the return type is declared, the expression type is checked. If the
  /// return type is inferred the expression type registered for inference
  /// in [inferReturnType].
  void handleReturn(TypeInferrerImpl inferrer, ReturnStatement statement,
      DartType type, bool isArrow);

  /// Handles an explicit yield statement.
  ///
  /// If the return type is declared, the expression type is checked. If the
  /// return type is inferred the expression type registered for inference
  /// in [inferReturnType].
  void handleYield(TypeInferrerImpl inferrer, YieldStatement node,
      ExpressionInferenceResult expressionResult);

  /// Handles an implicit return statement.
  ///
  /// If the return type is declared, the expression type is checked. If the
  /// return type is inferred the expression type registered for inference
  /// in [inferReturnType].
  StatementInferenceResult handleImplicitReturn(TypeInferrerImpl inferrer,
      Statement body, StatementInferenceResult inferenceResult, int fileOffset);

  /// Infers the return type for the function.
  ///
  /// If the function is a non-generator function this is based on the explicit
  /// and implicit return statements registered in [handleReturn] and
  /// [handleImplicitReturn].
  ///
  /// If the function is a generator function this is based on the explicit
  /// yield statements registered in [handleYield].
  DartType inferReturnType(TypeInferrerImpl inferrer, {bool hasImplicitReturn});
}

class _SyncClosureContext implements ClosureContext {
  bool get isAsync => false;

  /// The typing expectation for the subexpression of a `return` statement
  /// inside the function.
  final DartType _returnContext;

  @override
  DartType get returnContext => _returnContext;

  @override
  DartType get yieldContext => const UnknownType();

  final DartType _declaredReturnType;

  final bool _needToInferReturnType;

  DartType _inferredReturnType;

  /// Whether the function is an arrow function.
  bool _isArrow;

  /// A list of return statements in functions whose return type is being
  /// inferred.
  ///
  /// The returns are checked for validity after the return type is inferred.
  List<ReturnStatement> _returnStatements;

  /// A list of return expression types in functions whose return type is
  /// being inferred.
  List<DartType> _returnExpressionTypes;

  _SyncClosureContext(this._returnContext, this._declaredReturnType,
      this._needToInferReturnType) {
    if (_needToInferReturnType) {
      _returnStatements = [];
      _returnExpressionTypes = [];
    }
  }

  void _checkValidReturn(TypeInferrerImpl inferrer, DartType returnType,
      ReturnStatement statement, DartType expressionType) {
    if (inferrer.isNonNullableByDefault) {
      if (statement.expression == null) {
        // It is a compile-time error if s is `return;`, unless T is void,
        // dynamic, or Null.
        if (returnType is VoidType ||
            returnType is DynamicType ||
            returnType is NullType) {
          // Valid return;
        } else {
          statement.expression = inferrer.helper.wrapInProblem(
              new NullLiteral()..fileOffset = statement.fileOffset,
              messageReturnWithoutExpressionSync,
              statement.fileOffset,
              noLength)
            ..parent = statement;
        }
      } else {
        if (_isArrow && returnType is VoidType) {
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
          statement.expression = inferrer.helper.wrapInProblem(
              statement.expression,
              messageReturnFromVoidFunction,
              statement.expression.fileOffset,
              noLength)
            ..parent = statement;
        } else if (!(returnType is VoidType || returnType is DynamicType) &&
            expressionType is VoidType) {
          // It is a compile-time error if s is `return e;`, T is neither void
          // nor dynamic, and S is void.
          statement.expression = inferrer.helper.wrapInProblem(
              statement.expression,
              templateInvalidReturn.withArguments(expressionType,
                  _declaredReturnType, inferrer.isNonNullableByDefault),
              statement.expression.fileOffset,
              noLength)
            ..parent = statement;
        } else if (expressionType is! VoidType) {
          // It is a compile-time error if s is `return e;`, S is not void, and
          // S is not assignable to T.
          Expression expression = inferrer.ensureAssignable(
              _returnContext, expressionType, statement.expression,
              fileOffset: statement.expression.fileOffset,
              isVoidAllowed: true,
              errorTemplate: templateInvalidReturn,
              nullabilityErrorTemplate: templateInvalidReturnNullability,
              nullabilityPartErrorTemplate:
                  templateInvalidReturnPartNullability,
              nullabilityNullErrorTemplate:
                  templateInvalidReturnNullabilityNull,
              nullabilityNullTypeErrorTemplate:
                  templateInvalidReturnNullabilityNullType);
          statement.expression = expression..parent = statement;
        }
      }
    } else {
      // The rules for valid returns for functions with [returnType] `T` and
      // a return expression with static [expressionType] `S`.
      if (statement.expression == null) {
        // `return;` is a valid return if T is void, dynamic, or Null.
        if (returnType is VoidType ||
            returnType is DynamicType ||
            returnType is NullType) {
          // Valid return;
        } else {
          statement.expression = inferrer.helper.wrapInProblem(
              new NullLiteral()..fileOffset = statement.fileOffset,
              messageReturnWithoutExpression,
              statement.fileOffset,
              noLength)
            ..parent = statement;
        }
      } else {
        void ensureAssignability() {
          Expression expression = inferrer.ensureAssignable(
              _returnContext, expressionType, statement.expression,
              fileOffset: statement.fileOffset, isVoidAllowed: true);
          statement.expression = expression..parent = statement;
        }

        if (_isArrow && returnType is VoidType) {
          // Arrow functions are valid if: T is void or return exp; is a valid
          // for a block-bodied function.
          ensureAssignability();
        } else if (returnType is VoidType &&
            expressionType is! VoidType &&
            expressionType is! DynamicType &&
            expressionType is! NullType) {
          // Invalid if T is void and S is not void, dynamic, or Null
          statement.expression = inferrer.helper.wrapInProblem(
              statement.expression,
              messageReturnFromVoidFunction,
              statement.expression.fileOffset,
              noLength)
            ..parent = statement;
        } else if (expressionType is VoidType &&
            returnType is! VoidType &&
            returnType is! DynamicType &&
            returnType is! NullType) {
          // Invalid if S is void and T is not void, dynamic, or Null.
          statement.expression = inferrer.helper.wrapInProblem(
              statement.expression,
              messageVoidExpression,
              statement.expression.fileOffset,
              noLength)
            ..parent = statement;
        } else {
          ensureAssignability();
        }
      }
    }
  }

  /// Updates the inferred return type based on the presence of a return
  /// statement returning the given [type].
  @override
  void handleReturn(TypeInferrerImpl inferrer, ReturnStatement statement,
      DartType type, bool isArrow) {
    // The first return we see tells us if we have an arrow function.
    if (this._isArrow == null) {
      this._isArrow = isArrow;
    } else {
      assert(this._isArrow == isArrow);
    }

    if (_needToInferReturnType) {
      // Add the return to a list to be checked for validity after we've
      // inferred the return type.
      _returnStatements.add(statement);
      _returnExpressionTypes.add(type);
    } else {
      _checkValidReturn(inferrer, _declaredReturnType, statement, type);
    }
  }

  @override
  void handleYield(TypeInferrerImpl inferrer, YieldStatement node,
      ExpressionInferenceResult expressionResult) {
    node.expression = expressionResult.expression..parent = node;
  }

  @override
  DartType inferReturnType(TypeInferrerImpl inferrer,
      {bool hasImplicitReturn}) {
    assert(_needToInferReturnType);
    assert(hasImplicitReturn != null);
    DartType actualReturnedType;
    DartType inferredReturnType;
    if (inferrer.isNonNullableByDefault) {
      if (hasImplicitReturn) {
        // No explicit returns we have an implicit `return null`.
        actualReturnedType = const NullType();
      } else {
        // No explicit return and the function doesn't complete normally; that
        // is, it throws.
        actualReturnedType = new NeverType(inferrer.library.nonNullable);
      }
      // Use the types seen from the explicit return statements.
      for (int i = 0; i < _returnStatements.length; i++) {
        ReturnStatement statement = _returnStatements[i];
        DartType type = _returnExpressionTypes[i];
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
              .getStandardUpperBound(
                  actualReturnedType, type, inferrer.library.library);
        }
      }

      // Let T be the actual returned type of a function literal as computed
      // above. Let R be the greatest closure of the typing context K as
      // computed above.
      DartType returnContext =
          inferrer.computeGreatestClosure2(_declaredReturnType);
      if (returnContext is VoidType) {
        // With null safety: if R is void, or the function literal is marked
        // async and R is FutureOr<void>, let S be void.
        inferredReturnType = const VoidType();
      } else if (inferrer.typeSchemaEnvironment.isSubtypeOf(actualReturnedType,
          returnContext, SubtypeCheckMode.withNullabilities)) {
        // Otherwise, if T <: R then let S be T.
        inferredReturnType = actualReturnedType;
      } else {
        // Otherwise, let S be R.
        inferredReturnType = returnContext;
      }
    } else {
      if (_returnStatements.isNotEmpty) {
        // Use the types seen from the explicit return statements.
        for (int i = 0; i < _returnStatements.length; i++) {
          ReturnStatement statement = _returnStatements[i];
          DartType type = _returnExpressionTypes[i];
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
                .getStandardUpperBound(
                    actualReturnedType, type, inferrer.library.library);
          }
        }
      } else if (hasImplicitReturn) {
        // No explicit returns we have an implicit `return null`.
        actualReturnedType = const NullType();
      } else {
        // No explicit return and the function doesn't complete normally; that
        // is, it throws.
        actualReturnedType = const NullType();
      }

      if (!inferrer.typeSchemaEnvironment.isSubtypeOf(actualReturnedType,
          _returnContext, SubtypeCheckMode.withNullabilities)) {
        // If the inferred return type isn't a subtype of the context, we use
        // the context.
        inferredReturnType =
            inferrer.computeGreatestClosure2(_declaredReturnType);
      } else {
        inferredReturnType = actualReturnedType;
      }
    }

    for (int i = 0; i < _returnStatements.length; ++i) {
      _checkValidReturn(inferrer, inferredReturnType, _returnStatements[i],
          _returnExpressionTypes[i]);
    }

    return _inferredReturnType =
        demoteTypeInLibrary(inferredReturnType, inferrer.library.library);
  }

  @override
  StatementInferenceResult handleImplicitReturn(
      TypeInferrerImpl inferrer,
      Statement body,
      StatementInferenceResult inferenceResult,
      int fileOffset) {
    DartType returnType;
    if (_needToInferReturnType) {
      assert(_inferredReturnType != null,
          "Return type has not yet been inferred.");
      returnType = _inferredReturnType;
    } else {
      returnType = _declaredReturnType;
    }
    if (inferrer.library.isNonNullableByDefault &&
        (containsInvalidType(returnType) ||
            returnType.isPotentiallyNonNullable) &&
        inferrer.flowAnalysis.isReachable) {
      Statement resultStatement =
          inferenceResult.hasChanged ? inferenceResult.statement : body;
      // Create a synthetic return statement with the error.
      Statement returnStatement = new ReturnStatement(inferrer.helper
          .wrapInProblem(
              new NullLiteral()..fileOffset = fileOffset,
              templateImplicitReturnNull.withArguments(
                  returnType, inferrer.library.isNonNullableByDefault),
              fileOffset,
              noLength))
        ..fileOffset = fileOffset;
      if (resultStatement is Block) {
        resultStatement.statements.add(returnStatement);
      } else {
        resultStatement =
            new Block(<Statement>[resultStatement, returnStatement])
              ..fileOffset = fileOffset;
      }
      return new StatementInferenceResult.single(resultStatement);
    }
    return inferenceResult;
  }
}

/// Keeps track of information about the innermost function or closure being
/// inferred.
class _AsyncClosureContext implements ClosureContext {
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
  DartType get yieldContext => const UnknownType();

  final DartType _declaredReturnType;

  final bool _needToInferReturnType;

  DartType _inferredReturnType;

  /// Whether the function is an arrow function.
  bool _isArrow;

  /// A list of return statements in functions whose return type is being
  /// inferred.
  ///
  /// The returns are checked for validity after the return type is inferred.
  List<ReturnStatement> _returnStatements;

  /// A list of return expression types in functions whose return type is
  /// being inferred.
  List<DartType> _returnExpressionTypes;

  _AsyncClosureContext(this._returnContext, this._declaredReturnType,
      this._needToInferReturnType) {
    if (_needToInferReturnType) {
      _returnStatements = [];
      _returnExpressionTypes = [];
    }
  }

  void _checkValidReturn(TypeInferrerImpl inferrer, DartType returnType,
      ReturnStatement statement, DartType expressionType) {
    if (inferrer.isNonNullableByDefault) {
      DartType futureValueType =
          computeFutureValueType(inferrer.coreTypes, returnType);

      if (statement.expression == null) {
        // It is a compile-time error if s is `return;`, unless T_v is void,
        // dynamic, or Null.
        if (futureValueType is VoidType ||
            futureValueType is DynamicType ||
            futureValueType is NullType) {
          // Valid return;
        } else {
          statement.expression = inferrer.helper.wrapInProblem(
              new NullLiteral()..fileOffset = statement.fileOffset,
              messageReturnWithoutExpressionAsync,
              statement.fileOffset,
              noLength)
            ..parent = statement;
        }
      } else {
        if (_isArrow &&
            inferrer.typeSchemaEnvironment.flatten(returnType) is VoidType) {
          // For `async => e` it is a compile-time error if flatten(T) is not
          // void, and it would have been a compile-time error to declare the
          // function with the body `async { return e; }` rather than
          // `async => e`.
          return;
        }

        DartType flattenedExpressionType =
            inferrer.typeSchemaEnvironment.flatten(expressionType);
        if (futureValueType is VoidType &&
            !(flattenedExpressionType is VoidType ||
                flattenedExpressionType is DynamicType ||
                flattenedExpressionType is NullType)) {
          // It is a compile-time error if s is `return e;`, T_v is void, and
          // flatten(S) is neither void, dynamic, Null.
          statement.expression = inferrer.helper.wrapInProblem(
              new NullLiteral()..fileOffset = statement.fileOffset,
              templateInvalidReturnAsync.withArguments(
                  expressionType, returnType, inferrer.isNonNullableByDefault),
              statement.expression.fileOffset,
              noLength)
            ..parent = statement;
        } else if (!(futureValueType is VoidType ||
                futureValueType is DynamicType) &&
            flattenedExpressionType is VoidType) {
          // It is a compile-time error if s is `return e;`, T_v is neither void
          // nor dynamic, and flatten(S) is void.
          statement.expression = inferrer.helper.wrapInProblem(
              new NullLiteral()..fileOffset = statement.fileOffset,
              templateInvalidReturnAsync.withArguments(
                  expressionType, returnType, inferrer.isNonNullableByDefault),
              statement.expression.fileOffset,
              noLength)
            ..parent = statement;
        } else if (flattenedExpressionType is! VoidType &&
            !inferrer.typeSchemaEnvironment
                .performNullabilityAwareSubtypeCheck(
                    flattenedExpressionType, futureValueType)
                .isSubtypeWhenUsingNullabilities()) {
          // It is a compile-time error if s is `return e;`, flatten(S) is not
          // void, S is not assignable to T_v, and flatten(S) is not a subtype
          // of T_v.
          statement.expression = inferrer.ensureAssignable(
              futureValueType, expressionType, statement.expression,
              fileOffset: statement.expression.fileOffset,
              runtimeCheckedType:
                  inferrer.computeGreatestClosure2(_returnContext),
              declaredContextType: returnType,
              isVoidAllowed: false,
              errorTemplate: templateInvalidReturnAsync,
              nullabilityErrorTemplate: templateInvalidReturnAsyncNullability,
              nullabilityPartErrorTemplate:
                  templateInvalidReturnAsyncPartNullability,
              nullabilityNullErrorTemplate:
                  templateInvalidReturnAsyncNullabilityNull,
              nullabilityNullTypeErrorTemplate:
                  templateInvalidReturnAsyncNullabilityNullType)
            ..parent = statement;
        }
      }
    } else {
      // The rules for valid returns for async functions with [returnType] `T`
      // and a return expression with static [expressionType] `S`.
      DartType flattenedReturnType =
          inferrer.typeSchemaEnvironment.flatten(returnType);
      if (statement.expression == null) {
        // `return;` is a valid return if flatten(T) is void, dynamic, or Null.
        if (flattenedReturnType is VoidType ||
            flattenedReturnType is DynamicType ||
            flattenedReturnType is NullType) {
          // Valid return;
        } else {
          statement.expression = inferrer.helper.wrapInProblem(
              new NullLiteral()..fileOffset = statement.fileOffset,
              messageReturnWithoutExpression,
              statement.fileOffset,
              noLength)
            ..parent = statement;
        }
      } else {
        DartType flattenedExpressionType =
            inferrer.typeSchemaEnvironment.flatten(expressionType);

        void ensureAssignability() {
          DartType wrappedType = inferrer.typeSchemaEnvironment
              .futureType(flattenedExpressionType, Nullability.nonNullable);
          Expression expression = inferrer.ensureAssignable(
              computeAssignableType(inferrer, _returnContext, wrappedType),
              wrappedType,
              statement.expression,
              fileOffset: statement.fileOffset,
              isVoidAllowed: true,
              runtimeCheckedType:
                  inferrer.computeGreatestClosure(_returnContext));
          statement.expression = expression..parent = statement;
        }

        if (_isArrow && flattenedReturnType is VoidType) {
          // Arrow functions are valid if: flatten(T) is void or return exp; is
          // valid for a block-bodied function.
          ensureAssignability();
        } else if (returnType is VoidType &&
            flattenedExpressionType is! VoidType &&
            flattenedExpressionType is! DynamicType &&
            flattenedExpressionType is! NullType) {
          // Invalid if T is void and flatten(S) is not void, dynamic, or Null.
          statement.expression = inferrer.helper.wrapInProblem(
              statement.expression,
              messageReturnFromVoidFunction,
              statement.expression.fileOffset,
              noLength)
            ..parent = statement;
        } else if (flattenedExpressionType is VoidType &&
            flattenedReturnType is! VoidType &&
            flattenedReturnType is! DynamicType &&
            flattenedReturnType is! NullType) {
          // Invalid if flatten(S) is void and flatten(T) is not void, dynamic,
          // or Null.
          statement.expression = inferrer.helper.wrapInProblem(
              statement.expression,
              messageVoidExpression,
              statement.expression.fileOffset,
              noLength)
            ..parent = statement;
        } else {
          // The caller will check that the return expression is assignable to
          // the return type.
          ensureAssignability();
        }
      }
    }
  }

  /// Updates the inferred return type based on the presence of a return
  /// statement returning the given [type].
  @override
  void handleReturn(TypeInferrerImpl inferrer, ReturnStatement statement,
      DartType type, bool isArrow) {
    // The first return we see tells us if we have an arrow function.
    if (this._isArrow == null) {
      this._isArrow = isArrow;
    } else {
      assert(this._isArrow == isArrow);
    }

    if (_needToInferReturnType) {
      // Add the return to a list to be checked for validity after we've
      // inferred the return type.
      _returnStatements.add(statement);
      _returnExpressionTypes.add(type);
    } else {
      _checkValidReturn(inferrer, _declaredReturnType, statement, type);
    }
  }

  @override
  void handleYield(TypeInferrerImpl inferrer, YieldStatement node,
      ExpressionInferenceResult expressionResult) {
    node.expression = expressionResult.expression..parent = node;
  }

  DartType computeAssignableType(TypeInferrerImpl inferrer,
      DartType contextType, DartType expressionType) {
    contextType = inferrer.computeGreatestClosure(contextType);

    DartType initialContextType = contextType;
    if (!inferrer.isAssignable(initialContextType, expressionType)) {
      // If the body of the function is async, the expected return type has the
      // shape FutureOr<T>.  We check both branches for FutureOr here: both T
      // and Future<T>.
      DartType unfuturedExpectedType =
          inferrer.typeSchemaEnvironment.flatten(contextType);
      DartType futuredExpectedType = inferrer.wrapFutureType(
          unfuturedExpectedType, inferrer.library.nonNullable);
      if (inferrer.isAssignable(unfuturedExpectedType, expressionType)) {
        contextType = unfuturedExpectedType;
      } else if (inferrer.isAssignable(futuredExpectedType, expressionType)) {
        contextType = futuredExpectedType;
      }
    }
    return contextType;
  }

  @override
  DartType inferReturnType(TypeInferrerImpl inferrer,
      {bool hasImplicitReturn}) {
    assert(_needToInferReturnType);
    assert(hasImplicitReturn != null);
    DartType inferredType;

    if (inferrer.isNonNullableByDefault) {
      if (hasImplicitReturn) {
        // No explicit returns we have an implicit `return null`.
        inferredType = const NullType();
      } else {
        // No explicit return and the function doesn't complete normally; that
        // is, it throws.
        inferredType = new NeverType(inferrer.library.nonNullable);
      }
      // Use the types seen from the explicit return statements.
      for (int i = 0; i < _returnStatements.length; i++) {
        DartType type = _returnExpressionTypes[i];

        DartType unwrappedType = inferrer.typeSchemaEnvironment.flatten(type);
        if (inferredType == null) {
          inferredType = unwrappedType;
        } else {
          inferredType = inferrer.typeSchemaEnvironment.getStandardUpperBound(
              inferredType, unwrappedType, inferrer.library.library);
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
          inferredType, returnContext, SubtypeCheckMode.withNullabilities)) {
        // If the inferred return type isn't a subtype of the context, we use
        // the context.
        inferredType = returnContext;
      }
      inferredType = inferrer.wrapFutureType(
          inferrer.typeSchemaEnvironment.flatten(inferredType),
          inferrer.library.nonNullable);
    } else {
      if (_returnStatements.isNotEmpty) {
        // Use the types seen from the explicit return statements.
        for (int i = 0; i < _returnStatements.length; i++) {
          ReturnStatement statement = _returnStatements[i];
          DartType type = _returnExpressionTypes[i];

          // The return expression has to be assignable to the return type
          // expectation from the downwards inference context.
          if (statement.expression != null) {
            if (!inferrer.isAssignable(
                computeAssignableType(inferrer, _returnContext, type), type)) {
              // Not assignable, use the expectation.
              type = inferrer.computeGreatestClosure(_returnContext);
            }
          }
          DartType unwrappedType = inferrer.typeSchemaEnvironment.flatten(type);
          if (inferredType == null) {
            inferredType = unwrappedType;
          } else {
            inferredType = inferrer.typeSchemaEnvironment.getStandardUpperBound(
                inferredType, unwrappedType, inferrer.library.library);
          }
        }
      } else if (hasImplicitReturn) {
        // No explicit returns we have an implicit `return null`.
        inferredType = const NullType();
      } else {
        // No explicit return and the function doesn't complete normally;
        // that is, it throws.
        inferredType = const NullType();
      }
      inferredType =
          inferrer.wrapFutureType(inferredType, inferrer.library.nonNullable);

      if (!inferrer.typeSchemaEnvironment.isSubtypeOf(
          inferredType, _returnContext, SubtypeCheckMode.withNullabilities)) {
        // If the inferred return type isn't a subtype of the context, we use
        // the context.
        inferredType = inferrer.computeGreatestClosure2(_declaredReturnType);
      }
    }

    for (int i = 0; i < _returnStatements.length; ++i) {
      _checkValidReturn(inferrer, inferredType, _returnStatements[i],
          _returnExpressionTypes[i]);
    }

    return _inferredReturnType =
        demoteTypeInLibrary(inferredType, inferrer.library.library);
  }

  @override
  StatementInferenceResult handleImplicitReturn(
      TypeInferrerImpl inferrer,
      Statement body,
      StatementInferenceResult inferenceResult,
      int fileOffset) {
    DartType returnType;
    if (_needToInferReturnType) {
      assert(_inferredReturnType != null,
          "Return type has not yet been inferred.");
      returnType = _inferredReturnType;
    } else {
      returnType = _declaredReturnType;
    }
    returnType = inferrer.typeSchemaEnvironment.flatten(returnType);
    if (inferrer.library.isNonNullableByDefault &&
        (containsInvalidType(returnType) ||
            returnType.isPotentiallyNonNullable) &&
        inferrer.flowAnalysis.isReachable) {
      Statement resultStatement =
          inferenceResult.hasChanged ? inferenceResult.statement : body;
      // Create a synthetic return statement with the error.
      Statement returnStatement = new ReturnStatement(inferrer.helper
          .wrapInProblem(
              new NullLiteral()..fileOffset = fileOffset,
              templateImplicitReturnNull.withArguments(
                  returnType, inferrer.library.isNonNullableByDefault),
              fileOffset,
              noLength))
        ..fileOffset = fileOffset;
      if (resultStatement is Block) {
        resultStatement.statements.add(returnStatement);
      } else {
        resultStatement =
            new Block(<Statement>[resultStatement, returnStatement])
              ..fileOffset = fileOffset;
      }
      return new StatementInferenceResult.single(resultStatement);
    }
    return inferenceResult;
  }
}

/// Keeps track of information about the innermost function or closure being
/// inferred.
class _SyncStarClosureContext implements ClosureContext {
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
  DartType get returnContext => const UnknownType();

  @override
  DartType get yieldContext => _yieldElementContext;

  final DartType _declaredReturnType;

  final bool _needToInferReturnType;

  /// A list of return expression types in functions whose return type is
  /// being inferred.
  List<DartType> _yieldElementTypes;

  _SyncStarClosureContext(this._yieldElementContext, this._declaredReturnType,
      this._needToInferReturnType) {
    if (_needToInferReturnType) {
      _yieldElementTypes = [];
    }
  }

  /// Updates the inferred return type based on the presence of a return
  /// statement returning the given [type].
  @override
  void handleReturn(TypeInferrerImpl inferrer, ReturnStatement statement,
      DartType type, bool isArrow) {}

  @override
  void handleYield(TypeInferrerImpl inferrer, YieldStatement node,
      ExpressionInferenceResult expressionResult) {
    DartType expectedType = node.isYieldStar
        ? inferrer.wrapType(_yieldElementContext,
            inferrer.coreTypes.iterableClass, inferrer.library.nonNullable)
        : _yieldElementContext;
    Expression expression = inferrer.ensureAssignableResult(
        expectedType, expressionResult,
        fileOffset: node.fileOffset);
    node.expression = expression..parent = node;
    DartType type = expressionResult.inferredType;
    if (!identical(expressionResult.expression, expression)) {
      type = inferrer.computeGreatestClosure(expectedType);
    }
    if (_needToInferReturnType) {
      DartType elementType = type;
      if (node.isYieldStar) {
        elementType = inferrer.getDerivedTypeArgumentOf(
                type, inferrer.coreTypes.iterableClass) ??
            elementType;
      }
      _yieldElementTypes.add(elementType);
    }
  }

  @override
  DartType inferReturnType(TypeInferrerImpl inferrer,
      {bool hasImplicitReturn}) {
    assert(_needToInferReturnType);
    assert(hasImplicitReturn != null);
    DartType inferredElementType;
    if (_yieldElementTypes.isNotEmpty) {
      // Use the types seen from the explicit return statements.
      for (int i = 0; i < _yieldElementTypes.length; i++) {
        DartType type = _yieldElementTypes[i];
        if (inferredElementType == null) {
          inferredElementType = type;
        } else {
          inferredElementType = inferrer.typeSchemaEnvironment
              .getStandardUpperBound(
                  inferredElementType, type, inferrer.library.library);
        }
      }
    } else if (hasImplicitReturn) {
      // No explicit returns we have an implicit `return null`.
      inferredElementType = const NullType();
    } else {
      // No explicit return and the function doesn't complete normally; that is,
      // it throws.
      if (inferrer.isNonNullableByDefault) {
        inferredElementType = new NeverType(inferrer.library.nonNullable);
      } else {
        inferredElementType = const NullType();
      }
    }

    DartType inferredType = inferrer.wrapType(inferredElementType,
        inferrer.coreTypes.iterableClass, inferrer.library.nonNullable);

    if (!inferrer.typeSchemaEnvironment.isSubtypeOf(inferredType,
        _yieldElementContext, SubtypeCheckMode.withNullabilities)) {
      // If the inferred return type isn't a subtype of the context, we use the
      // context.
      inferredType = inferrer.computeGreatestClosure2(_declaredReturnType);
    }

    return demoteTypeInLibrary(inferredType, inferrer.library.library);
  }

  @override
  StatementInferenceResult handleImplicitReturn(
      TypeInferrerImpl inferrer,
      Statement body,
      StatementInferenceResult inferenceResult,
      int fileOffset) {
    // There is no implicit return.
    return inferenceResult;
  }
}

/// Keeps track of information about the innermost function or closure being
/// inferred.
class _AsyncStarClosureContext implements ClosureContext {
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
  DartType get returnContext => const UnknownType();

  @override
  DartType get yieldContext => _yieldElementContext;

  final DartType _declaredReturnType;

  final bool _needToInferReturnType;

  /// A list of return expression types in functions whose return type is
  /// being inferred.
  List<DartType> _yieldElementTypes;

  _AsyncStarClosureContext(this._yieldElementContext, this._declaredReturnType,
      this._needToInferReturnType) {
    if (_needToInferReturnType) {
      _yieldElementTypes = [];
    }
  }

  /// Updates the inferred return type based on the presence of a return
  /// statement returning the given [type].
  @override
  void handleReturn(TypeInferrerImpl inferrer, ReturnStatement statement,
      DartType type, bool isArrow) {}

  @override
  void handleYield(TypeInferrerImpl inferrer, YieldStatement node,
      ExpressionInferenceResult expressionResult) {
    DartType expectedType = node.isYieldStar
        ? inferrer.wrapType(_yieldElementContext,
            inferrer.coreTypes.streamClass, inferrer.library.nonNullable)
        : _yieldElementContext;

    Expression expression = inferrer.ensureAssignableResult(
        expectedType, expressionResult,
        fileOffset: node.fileOffset);
    node.expression = expression..parent = node;
    DartType type = expressionResult.inferredType;
    if (!identical(expressionResult.expression, expression)) {
      type = inferrer.computeGreatestClosure(expectedType);
    }
    if (_needToInferReturnType) {
      DartType elementType = type;
      if (node.isYieldStar) {
        elementType = inferrer.getDerivedTypeArgumentOf(
                type, inferrer.coreTypes.streamClass) ??
            type;
      }
      _yieldElementTypes.add(elementType);
    }
  }

  @override
  DartType inferReturnType(TypeInferrerImpl inferrer,
      {bool hasImplicitReturn}) {
    assert(_needToInferReturnType);
    assert(hasImplicitReturn != null);
    DartType inferredElementType;
    if (_yieldElementTypes.isNotEmpty) {
      // Use the types seen from the explicit return statements.
      for (DartType elementType in _yieldElementTypes) {
        if (inferredElementType == null) {
          inferredElementType = elementType;
        } else {
          inferredElementType = inferrer.typeSchemaEnvironment
              .getStandardUpperBound(
                  inferredElementType, elementType, inferrer.library.library);
        }
      }
    } else if (hasImplicitReturn) {
      // No explicit returns we have an implicit `return null`.
      inferredElementType = const NullType();
    } else {
      // No explicit return and the function doesn't complete normally; that is,
      // it throws.
      if (inferrer.isNonNullableByDefault) {
        inferredElementType = new NeverType(inferrer.library.nonNullable);
      } else {
        inferredElementType = const NullType();
      }
    }

    DartType inferredType = inferrer.wrapType(inferredElementType,
        inferrer.coreTypes.streamClass, inferrer.library.nonNullable);

    if (!inferrer.typeSchemaEnvironment.isSubtypeOf(inferredType,
        _yieldElementContext, SubtypeCheckMode.withNullabilities)) {
      // If the inferred return type isn't a subtype of the context, we use the
      // context.
      inferredType = inferrer.computeGreatestClosure2(_declaredReturnType);
    }

    return demoteTypeInLibrary(inferredType, inferrer.library.library);
  }

  @override
  StatementInferenceResult handleImplicitReturn(
      TypeInferrerImpl inferrer,
      Statement body,
      StatementInferenceResult inferenceResult,
      int fileOffset) {
    // There is no implicit return.
    return inferenceResult;
  }
}
