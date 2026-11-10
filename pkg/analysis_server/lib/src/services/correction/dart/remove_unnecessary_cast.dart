// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveUnnecessaryCast extends ResolvedCorrectionProducer {
  new({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.removeUnnecessaryCast;

  @override
  FixKind get multiFixKind => DartFixKind.removeUnnecessaryCastMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var asExpression = coveringNode;
    if (asExpression is! AsExpression) {
      return;
    }

    // remove 'as T' from 'e as T'
    await builder.addDartFileEdit(file, (builder) {
      var expression = asExpression.expression;
      builder.addDeletion(range.endEnd(expression, asExpression));
      builder.removeEnclosingParentheses(
        asExpression,
        getExpressionPrecedence(asExpression.expression),
      );
    });
  }
}

extension on DartFileEditBuilder {
  /// Adds edits to this edit builder to remove any parentheses enclosing the
  /// [expression] that are safe to remove given that the remaining expression
  /// has the given [precedence].
  void removeEnclosingParentheses(
    Expression expression,
    Precedence precedence,
  ) {
    var parent = expression.parent;
    while (parent is ParenthesizedExpression) {
      if (getExpressionParentPrecedence(parent) > precedence) {
        break;
      }
      addDeletion(range.token(parent.leftParenthesis));
      addDeletion(range.token(parent.rightParenthesis));
      expression = parent;
      parent = expression.parent;
    }
  }
}
