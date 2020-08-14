// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertConditionalExpressionToIfElement extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_IF_ELEMENT;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_IF_ELEMENT;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    AstNode node = this.node.thisOrAncestorOfType<ConditionalExpression>();
    if (node == null) {
      return null;
    }
    var nodeToReplace = node;
    var parent = node.parent;
    while (parent is ParenthesizedExpression) {
      nodeToReplace = parent;
      parent = parent.parent;
    }
    if (parent is ListLiteral || (parent is SetOrMapLiteral && parent.isSet)) {
      ConditionalExpression conditional = node;
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

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertConditionalExpressionToIfElement newInstance() =>
      ConvertConditionalExpressionToIfElement();
}
