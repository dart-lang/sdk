// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddAsync extends ResolvedCorrectionProducer {
  // todo(pq): consider adding a variation that adds an `await` as well

  /// A flag indicating whether this producer is producing a fix in the case
  /// where a function is missing a return at the end.
  final bool isForMissingReturn;

  /// Initialize a newly created producer.
  AddAsync() : isForMissingReturn = false;

  AddAsync.missingReturn() : isForMissingReturn = true;

  @override
  // Not predictably the correct action.
  bool get canBeAppliedInBulk => false;

  @override
  // Not predictably the correct action.
  bool get canBeAppliedToFile => false;

  @override
  FixKind get fixKind => DartFixKind.ADD_ASYNC;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (isForMissingReturn) {
      final node = this.node;
      FunctionBody? body;
      DartType? returnType;
      if (node is FunctionDeclaration) {
        body = node.functionExpression.body;
        returnType = node.declaredElement!.returnType;
      } else if (node is MethodDeclaration) {
        body = node.body;
        returnType = node.declaredElement!.returnType;
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
    } else {
      var body = node.thisOrAncestorOfType<FunctionBody>();
      if (body != null && body.keyword == null) {
        final typeProvider = this.typeProvider;
        await builder.addDartFileEdit(file, (builder) {
          builder.convertFunctionFromSyncToAsync(body, typeProvider);
        });
      }
    }
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
