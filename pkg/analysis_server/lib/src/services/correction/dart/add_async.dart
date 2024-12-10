// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddAsync extends ResolvedCorrectionProducer {
  // TODO(pq): consider adding a variation that adds an `await` as well.

  final _Type _type;

  /// Initialize a newly created producer.
  AddAsync({required super.context}) : _type = _Type.others;

  AddAsync.missingReturn({required super.context})
    : _type = _Type.missingReturn;

  AddAsync.wrongReturnType({required super.context})
    : _type = _Type.wrongReturnType;

  @override
  CorrectionApplicability get applicability =>
          // Not predictably the correct action.
          CorrectionApplicability
          .singleLocation;

  @override
  FixKind get fixKind => DartFixKind.ADD_ASYNC;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    switch (_type) {
      case _Type.missingReturn:
        var node = this.node;
        FunctionBody? body;
        DartType? returnType;
        switch (node) {
          case FunctionDeclaration():
            body = node.functionExpression.body;
            if (node.declaredFragment?.element case var declaredElement?) {
              returnType = declaredElement.returnType;
            } else if (node.declaredFragment case var declaredFragment?) {
              returnType = declaredFragment.element.returnType;
            }
          case MethodDeclaration():
            body = node.body;
            returnType = node.declaredFragment!.element.returnType;
        }
        if (body == null || returnType == null) {
          return;
        }
        if (_isFutureVoid(returnType) && _hasNoReturns(body)) {
          var final_body = body;
          await builder.addDartFileEdit(file, (builder) {
            builder.addSimpleInsertion(final_body.offset, 'async ');
          });
        }
      case _Type.wrongReturnType:
        var body = node.thisOrAncestorOfType<FunctionBody>();
        if (body == null) {
          return;
        }
        if (body.keyword != null) {
          return;
        }
        var expectedReturnType = _getStaticFunctionType(body);
        if (expectedReturnType == null) {
          return;
        }

        if (expectedReturnType is! InterfaceType ||
            !expectedReturnType.isDartAsyncFuture) {
          return;
        }

        var visitor = _ReturnTypeTester(
          typeSystem,
          expectedReturnType.typeArguments.first,
        );
        if (visitor.returnsAreAssignable(body)) {
          await builder.addDartFileEdit(file, (builder) {
            builder.convertFunctionFromSyncToAsync(
              body: body,
              typeSystem: typeSystem,
              typeProvider: typeProvider,
            );
          });
        }
      case _Type.others:
        var body = node.thisOrAncestorOfType<FunctionBody>();
        if (body != null && body.keyword == null) {
          await builder.addDartFileEdit(file, (builder) {
            builder.convertFunctionFromSyncToAsync(
              body: body,
              typeSystem: typeSystem,
              typeProvider: typeProvider,
            );
          });
        }
    }
  }

  DartType? _getStaticFunctionType(FunctionBody body) {
    // Gets return type for expression functions.
    if (body case ExpressionFunctionBody(:FunctionExpression parent)) {
      return parent.declaredFragment?.element.returnType;
    }

    if (body is! BlockFunctionBody) {
      return null;
    }

    // Gets return type for methods.
    if (node.thisOrAncestorOfType<MethodDeclaration>() case var method?
        when method.body == body) {
      return method.declaredFragment?.element.returnType;
    }

    // Gets return type for functions.
    if (node.thisOrAncestorOfType<FunctionDeclaration>() case var function?
        when function.functionExpression.body == body) {
      return function.declaredFragment?.element.returnType;
    }

    return null;
  }

  /// Return `true` if there are no return statements in the given function
  /// [body].
  bool _hasNoReturns(FunctionBody body) {
    var finder = _ReturnFinder();
    body.accept(finder);
    return !finder.foundReturn;
  }

  /// Return `true` if the [type] is `Future<void>`.
  bool _isFutureVoid(DartType type) {
    if (type is InterfaceType && type.isDartAsyncFuture) {
      return type.typeArguments[0] is VoidType;
    }
    return false;
  }
}

/// An AST visitor used to find return statements in function bodies.
class _ReturnFinder extends RecursiveAstVisitor<void> {
  /// A flag indicating whether a return statement was visited.
  bool foundReturn = false;

  /// Initialize a newly created visitor.
  _ReturnFinder();

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Return statements within closures aren't counted.
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    foundReturn = true;
  }
}

/// An AST visitor used to test if all return statements in a function body
/// are assignable to a given type.
class _ReturnTypeTester extends RecursiveAstVisitor<void> {
  /// A flag indicating whether a return statement was visited.
  bool _foundOneReturn = false;

  /// A flag indicating whether the return type is assignable considering
  /// [isAssignable].
  bool _returnsAreAssignable = true;

  /// The type system used to check assignability.
  final TypeSystem typeSystem;

  /// The type that the return statements should be assignable to.
  final DartType futureOf;

  /// Initialize a newly created visitor.
  _ReturnTypeTester(this.typeSystem, this.futureOf);

  /// Tests whether a type is assignable to the [futureOf] type.
  bool isAssignable(DartType type) {
    if (typeSystem.isAssignableTo(type, futureOf)) {
      return true;
    }
    if (type is InterfaceType && type.isDartAsyncFuture) {
      return typeSystem.isAssignableTo(type.typeArguments.first, futureOf);
    }
    return false;
  }

  /// Returns `true` if all return statements in the given [node] are
  /// assignable to the [futureOf] type.
  bool returnsAreAssignable(AstNode node) {
    _returnsAreAssignable = true;
    _foundOneReturn = false;
    node.accept(this);
    return _returnsAreAssignable && _foundOneReturn;
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _foundOneReturn = true;
    if (node.expression.staticType case var type?) {
      _returnsAreAssignable &= isAssignable(type);
    } else {
      _returnsAreAssignable = false;
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Return statements within closures aren't counted.
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _foundOneReturn = true;
    if (node.expression?.staticType case var type?) {
      _returnsAreAssignable &= isAssignable(type);
    } else {
      _returnsAreAssignable = false;
    }
  }
}

enum _Type {
  /// Indicates whether the producer is producing a fix in the case
  /// where a function has a return statement with the wrong return type.
  wrongReturnType,

  /// Indicates whether the producer is producing a fix in the case
  /// where a function is missing a return at the end.
  missingReturn,

  /// Indicates whether the producer is producing a fix that adds `async`
  /// to a function that is missing it. In cases where the error/lint is
  /// good enough to suggest adding `async` to a function, this is valid.
  others,
}
