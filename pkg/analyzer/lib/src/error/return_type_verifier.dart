// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/analyzer_error_code.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/error_verifier.dart';

class ReturnTypeVerifier {
  final TypeProviderImpl _typeProvider;
  final TypeSystemImpl _typeSystem;
  final ErrorReporter _errorReporter;
  final bool _strictCasts;

  late EnclosingExecutableContext enclosingExecutable;

  ReturnTypeVerifier({
    required TypeProviderImpl typeProvider,
    required TypeSystemImpl typeSystem,
    required ErrorReporter errorReporter,
    required bool strictCasts,
  })  : _typeProvider = typeProvider,
        _typeSystem = typeSystem,
        _errorReporter = errorReporter,
        _strictCasts = strictCasts;

  DartType get _flattenedReturnType {
    var returnType = enclosingExecutable.returnType;
    if (enclosingExecutable.isSynchronous) {
      return returnType;
    } else {
      return _typeSystem.flatten(returnType);
    }
  }

  void verifyExpressionFunctionBody(ExpressionFunctionBody node) {
    // This enables concise declarations of void functions.
    if (_flattenedReturnType is VoidType) {
      return;
    }

    return _checkReturnExpression(node.expression);
  }

  void verifyReturnStatement(ReturnStatement statement) {
    var expression = statement.expression;

    if (enclosingExecutable.isGenerativeConstructor) {
      if (expression != null) {
        _errorReporter.atNode(
          expression,
          CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR,
        );
      }
      return;
    }

    if (enclosingExecutable.isGenerator) {
      return;
    }

    if (expression == null) {
      _checkReturnWithoutValue(statement);
      return;
    }

    _checkReturnExpression(expression);
  }

  void verifyReturnType(TypeAnnotation? returnType) {
    // If no declared type, then the type is `dynamic`, which is valid.
    if (returnType == null) {
      return;
    }

    void checkElement(
      ClassElement expectedElement,
      AnalyzerErrorCode errorCode,
    ) {
      void reportError() {
        enclosingExecutable.hasLegalReturnType = false;
        _errorReporter.atNode(
          returnType,
          errorCode,
        );
      }

      // It is a compile-time error if the declared return type of
      // a function marked `sync*` or `async*` is `void`.
      if (enclosingExecutable.isGenerator) {
        if (enclosingExecutable.returnType is VoidType) {
          return reportError();
        }
      }

      // It is a compile-time error if the declared return type of
      // a function marked `...` is not a supertype of `...`.
      if (!_isLegalReturnType(expectedElement)) {
        return reportError();
      }
    }

    if (enclosingExecutable.isAsynchronous) {
      if (enclosingExecutable.isGenerator) {
        checkElement(
          _typeProvider.streamElement,
          CompileTimeErrorCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE,
        );
      } else {
        checkElement(
          _typeProvider.futureElement,
          CompileTimeErrorCode.ILLEGAL_ASYNC_RETURN_TYPE,
        );
      }
    } else if (enclosingExecutable.isGenerator) {
      checkElement(
        _typeProvider.iterableElement,
        CompileTimeErrorCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE,
      );
    }
  }

  /// Check that a type mismatch between the type of the [expression] and
  /// the expected return type of the enclosing executable.
  void _checkReturnExpression(Expression expression) {
    if (!enclosingExecutable.hasLegalReturnType) {
      // ILLEGAL_ASYNC_RETURN_TYPE has already been reported, meaning the
      // _declared_ return type is illegal; don't confuse by also reporting
      // that the type being returned here does not match that illegal return
      // type.
      return;
    }

    if (enclosingExecutable.isGenerator) {
      // [CompileTimeErrorCode.RETURN_IN_GENERATOR] has already been reported;
      // do not report a duplicate error.
      return;
    }

    // `T` is the declared return type.
    // `S` is the static type of the expression.
    var T = enclosingExecutable.returnType;
    var S = expression.typeOrThrow;

    void reportTypeError() {
      if (enclosingExecutable.catchErrorOnErrorReturnType != null) {
        _errorReporter.atNode(
          expression,
          WarningCode.RETURN_OF_INVALID_TYPE_FROM_CATCH_ERROR,
          arguments: [S, T],
        );
      } else if (enclosingExecutable.isClosure) {
        _errorReporter.atNode(
          expression,
          CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE,
          arguments: [S, T],
        );
      } else if (enclosingExecutable.isConstructor) {
        // [EnclosingExecutableContext.displayName] will only return `null` if
        // there is no enclosing element, in which case the `if` test above
        // would have failed.  So it's safe to assume that
        // `enclosingExecutable.displayName` is non-`null`.
        _errorReporter.atNode(
          expression,
          CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CONSTRUCTOR,
          arguments: [S, T, enclosingExecutable.displayName!],
        );
      } else if (enclosingExecutable.isFunction) {
        // [EnclosingExecutableContext.displayName] will only return `null` if
        // there is no enclosing element, in which case the `if` test above
        // would have failed.  So it's safe to assume that
        // `enclosingExecutable.displayName` is non-`null`.
        _errorReporter.atNode(
          expression,
          CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION,
          arguments: [S, T, enclosingExecutable.displayName!],
        );
      } else if (enclosingExecutable.isMethod) {
        // [EnclosingExecutableContext.displayName] will only return `null` if
        // there is no enclosing element, in which case the `if` test above
        // would have failed.  So it's safe to assume that
        // `enclosingExecutable.displayName` is non-`null`.
        _errorReporter.atNode(
          expression,
          CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_METHOD,
          arguments: [S, T, enclosingExecutable.displayName!],
        );
      }
    }

    if (enclosingExecutable.isSynchronous) {
      // It is a compile-time error if `T` is `void`,
      // and `S` is neither `void`, `dynamic`, nor `Null`.
      if (T is VoidType) {
        if (!_isVoidDynamicOrNull(S)) {
          reportTypeError();
          return;
        }
      }
      // It is a compile-time error if `S` is `void`,
      // and `T` is neither `void` nor `dynamic`.
      if (S is VoidType) {
        if (!_isVoidDynamic(T)) {
          reportTypeError();
          return;
        }
      }
      // It is a compile-time error if `S` is not `void`,
      // and `S` is not assignable to `T`.
      if (S is! VoidType) {
        if (T is RecordType &&
            T.positionalFields.length == 1 &&
            S is! RecordType &&
            expression is ParenthesizedExpression) {
          var field = T.positionalFields.first;
          if (_typeSystem.isAssignableTo(field.type, S,
              strictCasts: _strictCasts)) {
            _errorReporter.atNode(
              expression,
              CompileTimeErrorCode
                  .RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA,
            );
            return;
          }
        }

        if (!_typeSystem.isAssignableTo(S, T, strictCasts: _strictCasts)) {
          reportTypeError();
          return;
        }
      }
      // OK
      return;
    }

    if (enclosingExecutable.isAsynchronous) {
      var T_v = _typeSystem.futureValueType(T);
      var flatten_S = _typeSystem.flatten(S);
      // It is a compile-time error if `flatten(T)` is `void`,
      // and `flatten(S)` is neither `void`, `dynamic`, nor `Null`.
      if (T_v is VoidType) {
        if (!_isVoidDynamicOrNull(flatten_S)) {
          reportTypeError();
          return;
        }
      }
      // It is a compile-time error if `flatten(S)` is `void`,
      // and `flatten(T)` is neither `void`, `dynamic`.
      if (flatten_S is VoidType) {
        if (!_isVoidDynamic(T_v)) {
          reportTypeError();
          return;
        }
      }
      // It is a compile-time error if `flatten(S)` is not `void`,
      // and `Future<flatten(S)>` is not assignable to `T`.
      if (flatten_S is! VoidType) {
        if (!_typeSystem.isAssignableTo(S, T_v, strictCasts: _strictCasts) &&
            !_typeSystem.isSubtypeOf(flatten_S, T_v)) {
          reportTypeError();
          return;
        }
        // OK
        return;
      }
    }
  }

  void _checkReturnWithoutValue(ReturnStatement statement) {
    var T = enclosingExecutable.returnType;
    if (enclosingExecutable.isSynchronous) {
      if (_isVoidDynamicOrNull(T)) {
        return;
      }
    } else {
      var T_v = _typeSystem.futureValueType(T);
      if (_isVoidDynamicOrNull(T_v)) {
        return;
      }
    }

    _errorReporter.atToken(
      statement.returnKeyword,
      CompileTimeErrorCode.RETURN_WITHOUT_VALUE,
    );
  }

  bool _isLegalReturnType(ClassElement expectedElement) {
    DartType returnType = enclosingExecutable.returnType;
    //
    // When checking an async/sync*/async* method, we know the exact type
    // that will be returned (e.g. Future, Iterable, or Stream).
    //
    // For example an `async` function body will return a `Future<T>` for
    // some `T` (possibly `dynamic`).
    //
    // We allow the declared return type to be a supertype of that
    // (e.g. `dynamic`, `Object`), or Future<S> for some S.
    // (We assume the T <: S relation is checked elsewhere.)
    //
    // We do not allow user-defined subtypes of Future, because an `async`
    // method will never return those.
    //
    // To check for this, we ensure that `Future<bottom> <: returnType`.
    //
    // Similar logic applies for sync* and async*.
    //
    var lowerBound = expectedElement.instantiate(
      typeArguments: [NeverTypeImpl.instance],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    return _typeSystem.isSubtypeOf(lowerBound, returnType);
  }

  static bool _isVoidDynamic(DartType type) {
    return type is VoidType || type is DynamicType || type is InvalidType;
  }

  static bool _isVoidDynamicOrNull(DartType type) {
    return type is VoidType ||
        type is DynamicType ||
        type is InvalidType ||
        type.isDartCoreNull;
  }
}
