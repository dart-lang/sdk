// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class UseEffectiveIntegerDivision extends ResolvedCorrectionProducer {
  UseEffectiveIntegerDivision({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.useEffectiveIntegerDivision;

  @override
  FixKind get multiFixKind => DartFixKind.useEffectiveIntegerDivisionMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    for (var n in node.withAncestors) {
      if (n is! MethodInvocation) continue;
      if (n.offset != diagnosticOffset && n.length != diagnosticLength) {
        continue;
      }

      var target = n.target;
      if (target != null) {
        target = target.unParenthesized;
        await builder.addDartFileEdit(file, (builder) {
          // Replace `/` with `~/`.
          var binary = target as BinaryExpression;
          builder.addSimpleReplacement(range.token(binary.operator), '~/');
          var parentOfToIntInvocation = n.parent;
          if (parentOfToIntInvocation is Expression &&
              parentOfToIntInvocation.precedence >= binary.precedence) {
            // Wrap the new `~/` binary expression in parentheses if needed.
            builder.addSimpleReplacement(
              range.startStart(n, binary.leftOperand),
              '(',
            );
            builder.addSimpleReplacement(
              range.endEnd(binary.rightOperand, n),
              ')',
            );
          } else {
            // Remove everything before and after.
            builder.addDeletion(range.startStart(n, binary.leftOperand));
            builder.addDeletion(range.endEnd(binary.rightOperand, n));
          }
        });
      }
      // Done.
      break;
    }
  }
}
