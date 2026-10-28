// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/type_environment.dart';

/// A transformation that simplifies basic 'async' functions into [Future]s.
///
/// The JS expansion of an async/await function is a complex state machine.
/// In many cases 'async' functions do not use 'await' and return known
/// non-[Future] values, which is easily captured by [Future.sync]. By making
/// this transformation we avoid substantial overhead from the state machine.
class AsyncLowering {
  /// Stack tracking whether each currently visited [FunctionNode] should be
  /// lowered.
  ///
  /// The top of the stack corresponds to the innermost [FunctionNode] being
  /// visited. It starts as `true` for lowerable `async` functions and is set to
  /// `false` if an `await`, `await for`, or return of a potential [Future] is
  /// encountered inside that function.
  final List<bool> _shouldLower = [];
  final CoreTypes _coreTypes;
  final TypeEnvironment _typeEnvironment;
  late final StatefulStaticTypeContext _typeContext =
      StatefulStaticTypeContext.flat(_typeEnvironment);

  AsyncLowering(this._coreTypes, ClassHierarchy hierarchy)
    : _typeEnvironment = TypeEnvironment(_coreTypes, hierarchy);

  void enterMember(Member node) {
    _typeContext.enterMember(node);
  }

  void exitMember(Member node) {
    _typeContext.leaveMember(node);
  }

  void enterFunction(FunctionNode node) {
    _shouldLower.add(
      node.asyncMarker == AsyncMarker.Async && node.emittedValueType != null,
    );
  }

  void _updateFunctionBody(FunctionNode node, Statement? newBody) {
    node.body = newBody;
    newBody?.parent = node;
  }

  /// Rewrites [node] from an `async` function into a synchronous function
  /// returning a [Future] via [Future.sync] (or [Future.syncValue] for a
  /// simple non-throwing return).
  ///
  /// Precondition: [node] contains no `await` expressions or `await for` loops,
  /// and every returned expression is guaranteed not to evaluate to a [Future]
  /// at runtime.
  ///
  /// Wrapping the body in [Future.sync] avoids the async state machine and
  /// scheduling a microtask on synchronous completion while still catching
  /// synchronous throws and turning them into error futures:
  /// ```dart
  /// // Before:
  /// Future<int> foo() async {
  ///   doSomething();
  ///   return 3;
  /// }
  ///
  /// // After:
  /// Future<int> foo() {
  ///   return Future<int>.sync(() {
  ///     doSomething();
  ///     return 3;
  ///   });
  /// }
  /// ```
  void _wrapBodySync(FunctionNode node) {
    node.asyncMarker = AsyncMarker.Sync;
    final futureValueType = node.emittedValueType!;
    final simpleReturn = _simpleNonThrowingReturn(node.body);
    _updateFunctionBody(
      node,
      ReturnStatement(
        simpleReturn != null
            ? StaticInvocation(
                _coreTypes.futureSyncValueFactory,
                Arguments(
                  ExpressionList(simpleReturn),
                  types: DartTypeList(futureValueType),
                ),
              )
            : StaticInvocation(
                _coreTypes.futureSyncFactory,
                Arguments(
                  ExpressionList(
                    FunctionExpression(
                      FunctionNode(
                        node.body,
                        returnType: FutureOrType(
                          futureValueType,
                          futureValueType.nullability,
                        ),
                      ),
                    ),
                  ),
                  types: DartTypeList(futureValueType),
                ),
              ),
      ),
    );
  }

  /// The returned expression if [body] consists solely of returning an
  /// expression whose evaluation cannot possibly throw at runtime, or `null`
  /// otherwise.
  Expression? _simpleNonThrowingReturn(Statement? body) {
    if (body is Block) {
      if (body.statements.isEmpty) return NullLiteral();
      if (body.statements.length != 1) return null;
      body = body.statements.first;
    }
    if (body is ReturnStatement) {
      final expression = body.expression;
      if (expression == null) return NullLiteral();
      if (expression is BasicLiteral || expression is ConstantExpression) {
        return expression;
      }
    }
    return null;
  }

  /// Whether [expression] is guaranteed to evaluate to a non-[Future] value at
  /// runtime.
  ///
  /// `Future<T>.sync` returns a `Future<T>` result directly instead of chaining
  /// it into a fresh `_Future<T>`, so we only lower when no returned expression
  /// can be a [Future] at runtime.
  bool _isDefinitelyNonFutureValue(Expression expression) {
    // 1. Literals of known non-`Future` classes (even when non-const or when
    //    their static interface type, such as `List`, could be implemented by a
    //    custom `Future` class).
    if (expression is BasicLiteral ||
        expression is SymbolLiteral ||
        expression is TypeLiteral ||
        expression is ListLiteral ||
        expression is SetLiteral ||
        expression is MapLiteral ||
        expression is RecordLiteral) {
      return true;
    }
    // 2. Evaluated constants, whose actual runtime class can be inspected
    //    regardless of static type (e.g. `const Object x = 42;`).
    if (expression is ConstantExpression) {
      return _isNonFutureConstant(expression.constant);
    }
    // 3. General expressions whose static type cannot be inhabited by a
    //    `Future` instance.
    final type = expression.getStaticType(_typeContext).extensionTypeErasure;
    if (type is NullType ||
        type is NeverType ||
        type is RecordType ||
        type is FunctionType) {
      return true;
    }
    if (type is InterfaceType) {
      final cls = type.classNode;
      return cls == _coreTypes.intClass ||
          cls == _coreTypes.doubleClass ||
          cls == _coreTypes.numClass ||
          cls == _coreTypes.boolClass ||
          cls == _coreTypes.stringClass ||
          cls == _coreTypes.recordClass ||
          cls == _coreTypes.functionClass ||
          (cls.isEnum &&
              !_typeEnvironment.hierarchy.isSubInterfaceOf(
                cls,
                _coreTypes.futureClass,
              ));
    }
    return false;
  }

  bool _isNonFutureConstant(Constant constant) =>
      constant is! UnevaluatedConstant &&
      (constant is! InstanceConstant ||
          !_typeEnvironment.hierarchy.isSubInterfaceOf(
            constant.classNode,
            _coreTypes.futureClass,
          ));

  void transformFunctionNodeAndExit(FunctionNode node) {
    if (_shouldLower.removeLast()) {
      _wrapBodySync(node);
    }
  }

  void visitAwaitExpression(AwaitExpression expression) {
    assert(
      _shouldLower.isNotEmpty,
      'Awaits must be within the scope of a function.',
    );
    _shouldLower.last = false;
  }

  void visitReturnStatement(ReturnStatement statement) {
    assert(_shouldLower.isNotEmpty);
    if (_shouldLower.last) {
      final expression = statement.expression;
      if (expression != null && !_isDefinitelyNonFutureValue(expression)) {
        _shouldLower.last = false;
      }
    }
  }

  void visitForInStatement(ForInStatement statement) {
    if (statement.isAsync) {
      assert(_shouldLower.isNotEmpty);
      _shouldLower.last = false;
    }
  }
}
