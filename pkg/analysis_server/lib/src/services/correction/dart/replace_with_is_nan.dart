// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceWithIsNan extends ResolvedCorrectionProducer {
  ReplaceWithIsNan({required super.context});

  @override
  CorrectionApplicability get applicability =>
          // TODO(applicability): comment on why.
          CorrectionApplicability
          .singleLocation;

  @override
  FixKind get fixKind => DartFixKind.REPLACE_WITH_IS_NAN;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is! BinaryExpression) return;

    var needsBang = node.operator.type == TokenType.BANG_EQ;
    var rightOperand = node.rightOperand;
    var leftOperand = node.leftOperand;
    var isRightNan =
        rightOperand is PrefixedIdentifier &&
        (rightOperand.staticType?.isDartCoreDouble ?? false) &&
        rightOperand.identifier.name == 'nan';

    var expression = isRightNan ? leftOperand : rightOperand;
    var needsParentheses =
        expression is PostfixExpression ||
        expression.precedence < Precedence.postfix;

    var prefix = '${needsBang ? '!' : ''}${needsParentheses ? '(' : ''}';
    var suffix = '${needsParentheses ? ')' : ''}.isNaN';

    await builder.addDartFileEdit(file, (builder) {
      if (isRightNan) {
        if (prefix.isNotEmpty) {
          builder.addSimpleInsertion(leftOperand.offset, prefix);
        }
        builder.addSimpleReplacement(
          range.endStart(leftOperand, rightOperand.endToken.next!),
          suffix,
        );
      } else {
        builder.addSimpleReplacement(
          range.startStart(leftOperand, rightOperand),
          prefix,
        );
        builder.addSimpleInsertion(rightOperand.end, suffix);
      }
    });
  }
}
