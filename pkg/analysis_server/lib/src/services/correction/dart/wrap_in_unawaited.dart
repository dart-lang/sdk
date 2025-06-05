// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class WrapInUnawaited extends ResolvedCorrectionProducer {
  WrapInUnawaited({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // We only wrap a single expression in unawaited.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.WRAP_IN_UNAWAITED;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    AstNode? node = this.node;
    // The reported node may be the `identifier` in a PrefixedIdentifier,
    // the `propertyName` in a PropertyAccess, or the `methodName` in a
    // MethodInvocation. Check whether the grandparent is a
    // CascadeExpression. If it is, we cannot simply add an await
    // expression; we must also change the cascade(s) into a regular
    // property access or method call.
    if (node.parent?.parent is CascadeExpression) {
      return;
    }
    if (node is SimpleIdentifier) {
      node = node.parent;
    }
    Expression? expression;
    if (node is Expression) {
      expression = node;
      // more than or equal the Precedence of AwaitExpression
      if (expression.precedence >= Precedence.prefix) {
        while (true) {
          var parent = expression!.parent;
          if (parent is Expression && parent.precedence >= Precedence.prefix) {
            expression = parent;
          } else {
            break;
          }
        }
      }
    } else if (node is ExpressionStatement) {
      expression = node.expression;
    }
    if (expression == null) return;

    var isFuture = _isAssignableToFuture(expression.staticType);
    if (!isFuture) return;

    var value = utils.getNodeText(expression);

    await builder.addDartFileEdit(file, (builder) {
      var libraryPrefix =
          builder.importLibraryElement(Uri.parse('dart:async')).prefix;
      var prefix = libraryPrefix != null ? '$libraryPrefix.' : '';
      builder.addSimpleReplacement(
        range.node(expression!),
        '${prefix}unawaited($value)',
      );
    });
  }

  bool _isAssignableToFuture(DartType? type) {
    if (type == null) {
      return false;
    }
    if (type.isDartAsyncFutureOr) {
      return true;
    }
    return typeSystem.isAssignableTo(type, typeProvider.futureDynamicType);
  }
}
