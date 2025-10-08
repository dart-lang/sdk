// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveAsync extends ResolvedCorrectionProducer {
  final _Type _type;

  RemoveAsync({required super.context}) : _type = _Type.other;

  RemoveAsync.unnecessary({required super.context}) : _type = _Type.unnecessary;

  @override
  CorrectionApplicability get applicability =>
      // Not predictably the correct action.
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => DartAssistKind.removeAsync;

  @override
  FixKind get fixKind => DartFixKind.removeAsync;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    bool updateReturnType = true;
    AstNode? node = this.node;
    FunctionBody body;
    DartType? returnType;
    if (_type == _Type.unnecessary) {
      if (node.thisOrAncestorOfType<FunctionBody>() case var ancestorBody?) {
        body = ancestorBody;
      } else {
        return;
      }
    } else {
      if (node is Block) {
        node = node.parent;
      }
      if (node is BlockFunctionBody) {
        node = node.parent;
      } else if (node is ExpressionFunctionBody) {
        node = node.parent;
      }
      if (node case FormalParameterList(:var parent?)) {
        node = parent;
      }
      if (node case NamedType(:var parent?)) {
        node = parent;
      }
      if (node case FunctionExpression(:FunctionDeclaration parent)) {
        node = parent;
      }
      switch (node) {
        case FunctionExpression():
          body = node.body;
        case FunctionDeclaration(
          :var functionExpression,
          :var declaredFragment,
        ):
          body = functionExpression.body;
          if (declaredFragment?.element case var declaredElement?) {
            returnType = declaredElement.returnType;
          } else if (declaredFragment case var declaredFragment?) {
            returnType = declaredFragment.element.returnType;
          }
        case MethodDeclaration():
          body = node.body;
          returnType = node.declaredFragment!.element.returnType;
        default:
          return;
      }
    }
    if (body.keyword?.lexeme != Keyword.ASYNC.lexeme || body.star != null) {
      return;
    }
    if (returnType is InterfaceType &&
        (returnType.isDartAsyncFuture || returnType.isDartAsyncFutureOr)) {
      var newReturn = returnType.typeArguments.first;
      var visitor = _VisitorTester(typeSystem, typeProvider, newReturn);
      if (!visitor.returnsWillBeAssignable(body)) {
        if (visitor.returnsAreAssignable(body)) {
          updateReturnType = false;
        } else {
          return;
        }
      }
      if (visitor.foundAwait) {
        return;
      }
    } else if (returnType != null &&
        !_VisitorTester(
          typeSystem,
          typeProvider,
          returnType,
        ).returnsAreAssignable(body)) {
      return;
    } else {
      updateReturnType = false;
    }
    if (updateReturnType) {
      return await builder.addDartFileEdit(file, (builder) {
        builder.convertFunctionFromAsyncToSync(
          body: body,
          typeSystem: typeSystem,
          typeProvider: typeProvider,
        );
      });
    } else {
      await builder.addDartFileEdit(file, (builder) {
        var keyword = body.keyword!;
        builder.addDeletion(
          range.startOffsetEndOffset(
            keyword.offset,
            keyword.end + (keyword.next!.offset == (keyword.end) ? 0 : 1),
          ),
        );
      });
    }
  }
}

enum _Type { unnecessary, other }

/// An AST visitor used to test if all return statements in a function body
/// are assignable to a given type.
class _VisitorTester extends RecursiveAstVisitor<void> {
  /// A flag indicating whether a return statement was visited.
  bool _foundOneReturn = false;

  /// A flag indicating whether an await expression was found.
  bool _foundAwait = false;

  /// A flag indicating whether the return type is assignable considering
  /// [_isAssignable].
  bool _returnsAreAssignable = true;

  final TypeProvider typeProvider;

  /// The type system used to check assignability.
  final TypeSystem typeSystem;

  /// The type that the return statements should be assignable to.
  final DartType argumentType;

  bool _processingFuture = false;

  /// Initialize a newly created visitor.
  _VisitorTester(this.typeSystem, this.typeProvider, this.argumentType);

  /// A flag indicating whether an await expression was found.
  bool get foundAwait => _foundAwait;

  /// Returns `true` if all return statements in the given [node] are
  /// assignable to the [argumentType] type.
  bool returnsAreAssignable(AstNode node) {
    _foundAwait = false;
    _returnsAreAssignable = true;
    _foundOneReturn = false;
    _processingFuture = true;
    node.accept(this);
    return _returnsAreAssignable && _foundOneReturn || !_foundOneReturn;
  }

  /// Returns `true` if all return statements in the given [node] are
  /// assignable to the [argumentType] type.
  bool returnsWillBeAssignable(AstNode node) {
    _foundAwait = false;
    _returnsAreAssignable = true;
    _foundOneReturn = false;
    node.accept(this);
    return _returnsAreAssignable && _foundOneReturn || !_foundOneReturn;
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _foundAwait = true;
    // No need to continue processing if we found an await expression.
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _foundOneReturn = true;
    if (node.expression.staticType case var type?) {
      _returnsAreAssignable &= _isAssignable(type);
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
      _returnsAreAssignable &= _isAssignable(type);
    } else {
      _returnsAreAssignable = false;
    }
  }

  /// Tests whether a type is assignable to the [argumentType] type.
  bool _isAssignable(DartType type) {
    if (_processingFuture) {
      return typeSystem.isAssignableTo(
        type,
        typeProvider.futureOrType(argumentType),
      );
    }
    return typeSystem.isAssignableTo(type, argumentType);
  }
}
