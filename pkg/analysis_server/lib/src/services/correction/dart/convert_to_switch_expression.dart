// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToSwitchExpression extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_SWITCH_EXPRESSION;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is! SwitchStatement) return;

    var expression = node.expression;
    if (!expression.staticType.isExhaustive) return;

    if (isReturnSwitch(node)) {
      await convertReturnSwitchExpression(builder, node);
    }
  }

  Future<void> convertReturnSwitchExpression(
      ChangeBuilder builder, SwitchStatement node) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(node.offset, 'return ');
      builder.addSimpleInsertion(node.end, ';');

      var memberCount = node.members.length;
      for (var i = 0; i < memberCount; ++i) {
        // Sure to be a SwitchPatternCase
        var patternCase = node.members[i] as SwitchPatternCase;
        builder.addDeletion(
            range.startStart(patternCase.keyword, patternCase.guardedPattern));
        var colonRange = range.entity(patternCase.colon);
        builder.addSimpleReplacement(colonRange, ' =>');

        var statement = patternCase.statements.first;
        var hasComment = statement.beginToken.precedingComments != null;

        if (statement is ReturnStatement) {
          // Return expression is sure to be non-null
          var deletion = !hasComment
              ? range.startOffsetEndOffset(range.offsetBy(colonRange, 1).offset,
                  statement.expression!.offset - 1)
              : range.startStart(
                  statement.returnKeyword, statement.expression!);
          builder.addDeletion(deletion);
        }

        if (!hasComment && statement is ExpressionStatement) {
          var expression = statement.expression;
          if (expression is ThrowExpression) {
            var deletionRange = range.startOffsetEndOffset(
                range.offsetBy(colonRange, 1).offset, statement.offset - 1);
            builder.addDeletion(deletionRange);
          }
        }

        var endToken = i < memberCount - 1 ? ',' : '';
        builder.addSimpleReplacement(
            range.entity(statement.endToken), endToken);
      }
    });
  }

  bool isReturnSwitch(SwitchStatement node) {
    for (var member in node.members) {
      if (member is! SwitchPatternCase) return false;
      if (member.labels.isNotEmpty) return false;
      var statements = member.statements;
      if (statements.length != 1) return false;
      var s = statements.first;
      if (s is ReturnStatement && s.expression != null) continue;
      if (s is! ExpressionStatement || s.expression is! ThrowExpression) {
        return false;
      }
    }
    return true;
  }
}

extension on DartType? {
  bool get isExhaustive {
    var element = this?.element;
    if (element is EnumElement) return true;
    if (element is ClassElement) return element.isExhaustive;
    if (element is MixinElement) return element.isExhaustive;
    return false;
  }
}
