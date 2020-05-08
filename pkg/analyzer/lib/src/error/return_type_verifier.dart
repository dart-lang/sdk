// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:meta/meta.dart';

class ReturnTypeVerifier {
  final TypeProviderImpl _typeProvider;
  final TypeSystemImpl _typeSystem;
  final ErrorReporter _errorReporter;

  EnclosingExecutableContext enclosingExecutable;

  ReturnTypeVerifier({
    @required TypeProviderImpl typeProvider,
    @required TypeSystemImpl typeSystem,
    @required ErrorReporter errorReporter,
  })  : _typeProvider = typeProvider,
        _typeSystem = typeSystem,
        _errorReporter = errorReporter;

  /// Check that a type mis-match between the type of the [expression] and
  /// the [expectedReturnType] by the enclosing method or function.
  ///
  /// This method is called both by [_checkForAllReturnStatementErrorCodes]
  /// and [visitExpressionFunctionBody].
  void verifyReturnExpression(Expression expression, DartType expectedType,
      {bool isArrowFunction = false}) {
    if (enclosingExecutable == null) {
      return;
    }
    if (enclosingExecutable.isGenerator) {
      // "return expression;" is disallowed in generators, but this is checked
      // elsewhere.  Bare "return" is always allowed in generators regardless
      // of the return type.  So no need to do any further checking.
      return;
    }
    if (expression == null) {
      return; // Empty returns are handled elsewhere
    }

    DartType expressionType = getStaticType(expression);

    var toType = expectedType;
    var fromType = expressionType;
    if (enclosingExecutable.isAsynchronous) {
      toType = _typeSystem.flatten(toType);
      fromType = _typeSystem.flatten(fromType);
      if (!_isLegalReturnType(_typeProvider.futureElement)) {
        // ILLEGAL_ASYNC_RETURN_TYPE has already been reported, meaning the
        // _declared_ return type is illegal; don't confuse by also reporting
        // that the type being returned here does not match that illegal return
        // type.
        return;
      }
    }

    void reportTypeError() {
      String displayName = enclosingExecutable.element.displayName;

      if (displayName.isEmpty) {
        _errorReporter.reportErrorForNode(
            StaticTypeWarningCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE,
            expression,
            [fromType, toType]);
      } else if (enclosingExecutable.isMethod) {
        _errorReporter.reportErrorForNode(
            StaticTypeWarningCode.RETURN_OF_INVALID_TYPE_FROM_METHOD,
            expression,
            [fromType, toType, displayName]);
      } else {
        _errorReporter.reportErrorForNode(
            StaticTypeWarningCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION,
            expression,
            [fromType, toType, displayName]);
      }
    }

    // Anything can be returned to `void` in an arrow bodied function
    // or to `Future<void>` in an async arrow bodied function.
    if (isArrowFunction && toType.isVoid) {
      return;
    }

    if (toType.isVoid) {
      if (fromType.isVoid ||
          fromType.isDynamic ||
          fromType.isDartCoreNull ||
          fromType.isBottom) {
        return;
      }
    } else if (fromType.isVoid) {
      if (toType.isDynamic || toType.isDartCoreNull || toType.isBottom) {
        return;
      }
    }
    if (!expectedType.isVoid && !fromType.isVoid) {
      var checkWithType = !enclosingExecutable.isAsynchronous
          ? fromType
          : _typeProvider.futureType2(fromType);
      if (_typeSystem.isAssignableTo2(checkWithType, expectedType)) {
        return;
      }
    }

    reportTypeError();
  }

  void verifyReturnStatement(ReturnStatement statement) {
    FunctionType functionType = enclosingExecutable.element.type;
    DartType expectedReturnType = functionType == null
        ? DynamicTypeImpl.instance
        : functionType.returnType;
    Expression returnExpression = statement.expression;

    // RETURN_IN_GENERATIVE_CONSTRUCTOR
    bool isGenerativeConstructor(ExecutableElement element) =>
        element is ConstructorElement && !element.isFactory;
    if (isGenerativeConstructor(enclosingExecutable.element)) {
      if (returnExpression == null) {
        return;
      }
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR,
          returnExpression);
      return;
    }
    // RETURN_WITHOUT_VALUE
    if (returnExpression == null) {
      _checkForAllEmptyReturnStatementErrorCodes(statement, expectedReturnType);
      return;
    } else if (enclosingExecutable.isGenerator) {
      // RETURN_IN_GENERATOR
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.RETURN_IN_GENERATOR,
          statement,
          [enclosingExecutable.isAsynchronous ? "async*" : "sync*"]);
      return;
    }

    verifyReturnExpression(returnExpression, expectedReturnType);
  }

  void verifyReturnType(TypeAnnotation returnType) {
    // If no declared type, then the type is `dynamic`, which is valid.
    if (returnType == null) {
      return;
    }

    if (enclosingExecutable.isAsynchronous) {
      if (enclosingExecutable.isGenerator) {
        _checkForIllegalReturnTypeCode(
          returnType,
          _typeProvider.streamElement,
          StaticTypeWarningCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE,
        );
      } else {
        _checkForIllegalReturnTypeCode(
          returnType,
          _typeProvider.futureElement,
          StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE,
        );
      }
    } else if (enclosingExecutable.isGenerator) {
      _checkForIllegalReturnTypeCode(
        returnType,
        _typeProvider.iterableElement,
        StaticTypeWarningCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE,
      );
    }
  }

  /// Check that return statements without expressions are not in a generative
  /// constructor and the return type is not assignable to `null`; that is, we
  /// don't have `return;` if the enclosing method has a non-void containing
  /// return type.
  void _checkForAllEmptyReturnStatementErrorCodes(
      ReturnStatement statement, DartType expectedReturnType) {
    if (enclosingExecutable.isGenerator) {
      return;
    }
    var returnType = enclosingExecutable.isAsynchronous
        ? _typeSystem.flatten(expectedReturnType)
        : expectedReturnType;
    if (returnType.isDynamic ||
        returnType.isDartCoreNull ||
        returnType.isVoid) {
      return;
    }
    // If we reach here, this is an invalid return
    _errorReporter.reportErrorForToken(
        StaticWarningCode.RETURN_WITHOUT_VALUE, statement.returnKeyword);
    return;
  }

  /// If the current function is async, async*, or sync*, verify that its
  /// declared return type is assignable to Future, Stream, or Iterable,
  /// respectively. This is called by [_checkForIllegalReturnType] to check if
  /// a value with the type of the declared [returnTypeName] is assignable to
  /// [expectedElement] and if not report [errorCode].
  void _checkForIllegalReturnTypeCode(TypeAnnotation returnTypeName,
      ClassElement expectedElement, StaticTypeWarningCode errorCode) {
    if (!_isLegalReturnType(expectedElement)) {
      _errorReporter.reportErrorForNode(errorCode, returnTypeName);
    }
  }

  /// Returns whether a value with the type of the the enclosing function's
  /// declared return type is assignable to [expectedElement].
  bool _isLegalReturnType(ClassElement expectedElement) {
    DartType returnType = enclosingExecutable.element.returnType;
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
      nullabilitySuffix: NullabilitySuffix.star,
    );
    return _typeSystem.isSubtypeOf2(lowerBound, returnType);
  }

  /// Return the static type of the given [expression] that is to be used for
  /// type analysis.
  ///
  /// TODO(scheglov) this is duplicate
  static DartType getStaticType(Expression expression) {
    DartType type = expression.staticType;
    if (type == null) {
      // TODO(brianwilkerson) This should never happen.
      return DynamicTypeImpl.instance;
    }
    return type;
  }
}
