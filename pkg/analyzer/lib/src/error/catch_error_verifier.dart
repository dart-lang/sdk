// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/return_type_verifier.dart';
import 'package:analyzer/src/generated/error_verifier.dart';

/// Reports on invalid functions passed to [Future.catchError].
class CatchErrorVerifier {
  final ErrorReporter _errorReporter;

  final TypeProvider _typeProvider;

  final TypeSystem _typeSystem;

  final ReturnTypeVerifier _returnTypeVerifier;

  CatchErrorVerifier(this._errorReporter, this._typeProvider, this._typeSystem)
      : _returnTypeVerifier = ReturnTypeVerifier(
          typeProvider: _typeProvider,
          typeSystem: _typeSystem,
          errorReporter: _errorReporter,
        );
  void verifyMethodInvocation(MethodInvocation node) {
    // TODO(https://github.com/dart-lang/sdk/issues/35825): Verify the
    // parameters of a function passed to `Future.catchError` as well.
    var target = node.realTarget;
    if (target == null) {
      return;
    }
    var methodName = node.methodName;
    if (!(methodName.name == 'catchError' &&
        target.staticType.isDartAsyncFuture)) {
      return;
    }
    if (node.argumentList.arguments.isEmpty) {
      return;
    }
    var callback = node.argumentList.arguments.first;
    if (callback is NamedExpression) {
      // This implies that no positional arguments are passed.
      return;
    }
    var targetType = target.staticType as InterfaceType;
    var targetFutureType = targetType.typeArguments.first;
    var expectedReturnType = _typeProvider.futureOrType2(targetFutureType);
    if (callback is FunctionExpression) {
      var catchErrorOnErrorExecutable = EnclosingExecutableContext(
          callback.declaredElement,
          isAsynchronous: true,
          catchErrorOnErrorReturnType: expectedReturnType);
      var returnStatementVerifier =
          _ReturnStatementVerifier(_returnTypeVerifier);
      _returnTypeVerifier.enclosingExecutable = catchErrorOnErrorExecutable;
      callback.body.accept(returnStatementVerifier);
    } else {
      var callbackType = callback.staticType;
      if (callbackType is FunctionType) {
        _checkReturnType(expectedReturnType, callbackType.returnType, callback);
      }
    }
  }

  void _checkReturnType(
      DartType expectedType, DartType functionReturnType, Expression callback) {
    if (!_typeSystem.isAssignableTo(functionReturnType, expectedType)) {
      _errorReporter.reportErrorForNode(
        HintCode.RETURN_TYPE_INVALID_FOR_CATCH_ERROR,
        callback,
        [functionReturnType, expectedType],
      );
    }
  }
}

/// Visits a function body, looking for return statements.
class _ReturnStatementVerifier extends RecursiveAstVisitor<void> {
  final ReturnTypeVerifier _returnTypeVerifier;
  _ReturnStatementVerifier(this._returnTypeVerifier);
  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _returnTypeVerifier.verifyExpressionFunctionBody(node);
    super.visitExpressionFunctionBody(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Do not visit within [node]. We have no interest in return statements
    // within.
  }
  @override
  void visitReturnStatement(ReturnStatement node) {
    _returnTypeVerifier.verifyReturnStatement(node);
    super.visitReturnStatement(node);
  }
}
