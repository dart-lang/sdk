// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';

class _FunctionData {
  final List<AwaitExpression> awaits = [];
  final Set<ReturnStatement> returnStatements = {};
  // If we find certain control flow statements in this function, we choose to
  // not lower it.
  bool shouldLower = true;

  _FunctionData();

  /// Returns true if all [AwaitExpression]s are children of [ReturnStatement]s.
  bool allAwaitsDirectReturn() {
    return awaits.every(
        (awaitExpression) => returnStatements.contains(awaitExpression.parent));
  }
}

/// Handles simplification of basic 'async' functions into [Future]s.
///
/// The JS expansion of an async/await function is a complex state machine.
/// In many cases 'async' functions either do not use 'await' or have very
/// simple 'await' logic which is easily captured by [Future]. By making this
/// transformation we avoid substantial over head from the state machine.
class AsyncLowering {
  final List<_FunctionData> _functions = [];
  final CoreTypes _coreTypes;

  AsyncLowering(this._coreTypes);

  bool _shouldTryAsyncLowering(FunctionNode node) =>
      node.asyncMarker == AsyncMarker.Async &&
      node.futureValueType != null &&
      _functions.last.shouldLower;

  void enterFunction(FunctionNode node) {
    _functions.add(_FunctionData());
  }

  void _exitFunction() {
    _functions.removeLast();
  }

  void _updateFunctionBody(FunctionNode node, Statement? newBody) {
    node.body = newBody;
    newBody?.parent = node;
  }

  void _wrapBodySync(FunctionNode node) {
    node.asyncMarker = AsyncMarker.Sync;
    final futureValueType = node.futureValueType!;
    _updateFunctionBody(
        node,
        ReturnStatement(StaticInvocation(
            _coreTypes.futureSyncFactory,
            Arguments([
              FunctionExpression(FunctionNode(node.body,
                  returnType: FutureOrType(
                      futureValueType, futureValueType.nullability)))
            ], types: [
              futureValueType
            ]))));
  }

  void _wrapReturns(_FunctionData functionData, FunctionNode node) {
    final futureValueType = node.futureValueType!;
    for (final returnStatement in functionData.returnStatements) {
      final expression = returnStatement.expression;
      // Ensure the returned future has a runtime type (T) matching the
      // function's return type by wrapping with Future.value<T>.
      if (expression == null) continue;
      final futureValueCall = StaticInvocation(_coreTypes.futureValueFactory,
          Arguments([expression], types: [futureValueType]));
      returnStatement.expression = futureValueCall;
      futureValueCall.parent = returnStatement;
    }
  }

  void _transformDirectReturnAwaits(
      FunctionNode node, _FunctionData functionData) {
    // If every await is the direct child of a return statement then we can
    // do the following transformation:
    // return await e; --> return e;
    final updatedReturns = <ReturnStatement>{};
    for (final awaitExpression in functionData.awaits) {
      final returnStatement = awaitExpression.parent as ReturnStatement;
      updatedReturns.add(returnStatement);
      awaitExpression.replaceWith(awaitExpression.operand);
    }
  }

  void _transformAsyncFunctionNode(FunctionNode node) {
    assert(_functions.isNotEmpty, 'Must be within a function scope.');
    final functionData = _functions.last;
    var isLowered = false;
    if (functionData.awaits.isEmpty) {
      // There are no awaits within this function so convert to a simple
      // Future.sync call with the function's returned expressions. We use
      // this over Future.value because the expression can throw and async
      // functions defer exceptions as errors on returned Future. Future.sync
      // has the same deferred behavior.
      //
      // Before:
      // Future<int> foo() async {
      //   doSomething();
      //   return 3;
      // }
      //
      // After:
      // Future<int> foo() {
      //   return Future.sync(() {
      //     doSomething();
      //     return 3;
      //   });
      // }
      //
      // Edge cases to consider:
      // 1) Function doesn't include a return expression. (e.g. Future<void>)
      //    In this case we call Future.value(null).
      // 2) The returned expression might itself be a future. Future.sync will
      //    handle the unpacking of the returned future in that case.
      // 3) The return type of the function is not specified. In this case we
      //    instantiate Future.value with 'dynamic'.
      isLowered = true;
    } else if (functionData.allAwaitsDirectReturn()) {
      _transformDirectReturnAwaits(node, functionData);
      isLowered = true;
    }
    if (isLowered) {
      _wrapReturns(functionData, node);
      _wrapBodySync(node);
    }
  }

  void transformFunctionNodeAndExit(FunctionNode node) {
    if (_shouldTryAsyncLowering(node)) _transformAsyncFunctionNode(node);
    _exitFunction();
  }

  void visitAwaitExpression(AwaitExpression expression) {
    assert(_functions.isNotEmpty,
        'Awaits must be within the scope of a function.');
    _functions.last.awaits.add(expression);
  }

  void visitReturnStatement(ReturnStatement statement) {
    _functions.last.returnStatements.add(statement);
  }

  void visitForInStatement(ForInStatement statement) {
    if (statement.isAsync && _functions.isNotEmpty) {
      _functions.last.shouldLower = false;
    }
  }

  void visitTry() {
    _functions.last.shouldLower = false;
  }
}
