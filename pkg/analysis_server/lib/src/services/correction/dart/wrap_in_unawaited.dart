// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class WrapInUnawaited extends ResolvedCorrectionProducer {
  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.WRAP_IN_UNAWAITED;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    AstNode? node = this.node;
    if (node.parent is CascadeExpression) {
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
}
