// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertConditionalExpressionToIfElement
    extends ResolvedCorrectionProducer {
  ConvertConditionalExpressionToIfElement({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.convertToIfElement;

  @override
  FixKind get fixKind => DartFixKind.convertToIfElement;

  @override
  FixKind get multiFixKind => DartFixKind.convertToIfElementMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var conditional = node.thisOrAncestorOfType<ConditionalExpression>();
    if (conditional == null) {
      return;
    }

    AstNode nodeToReplace = conditional;
    var parent = conditional.parent;
    while (parent is ParenthesizedExpression) {
      nodeToReplace = parent;
      parent = parent.parent;
    }

    if (parent is ListLiteral || parent is SetOrMapLiteral && parent.isSet) {
      var condition = conditional.condition.unParenthesized;
      var thenExpression = conditional.thenExpression.unParenthesized;
      var elseExpression = conditional.elseExpression.unParenthesized;

      await builder.addDartFileEdit(file, (builder) {
        builder.addReplacement(range.node(nodeToReplace), (builder) {
          builder.write('if (');
          builder.write(utils.getNodeText(condition));
          builder.write(') ');
          builder.write(utils.getNodeText(thenExpression));
          builder.write(' else ');
          builder.write(utils.getNodeText(elseExpression));
        });
      });
    }
  }
}
