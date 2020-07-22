// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceCascadeWithDot extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.REPLACE_CASCADE_WITH_DOT;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is CascadeExpression) {
      var sections = node.cascadeSections;
      if (sections.length == 1) {
        var section = sections[0];
        Token cascadeOperator;
        if (section is MethodInvocation) {
          cascadeOperator = section.operator;
        } else if (section is PropertyAccess) {
          cascadeOperator = section.operator;
        } else if (section is IndexExpression) {
          await _handleIndexExpression(builder, section);
          return;
        } else if (section is AssignmentExpression) {
          var leftHandSide = section.leftHandSide;
          if (leftHandSide is PropertyAccess) {
            cascadeOperator = leftHandSide.operator;
          } else if (leftHandSide is IndexExpression) {
            await _handleIndexExpression(builder, leftHandSide);
            return;
          } else {
            return;
          }
        } else {
          return;
        }
        var type = cascadeOperator.type;
        if (type == TokenType.PERIOD_PERIOD ||
            type == TokenType.QUESTION_PERIOD_PERIOD) {
          await builder.addDartFileEdit(file, (builder) {
            var end = cascadeOperator.end;
            builder.addDeletion(range.startOffsetEndOffset(end - 1, end));
          });
        }
      }
    }
  }

  void _handleIndexExpression(
      ChangeBuilder builder, IndexExpression section) async {
    var cascadeOperator = section.period;
    var type = cascadeOperator.type;
    if (type == TokenType.PERIOD_PERIOD) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(
            range.startStart(cascadeOperator, section.leftBracket));
      });
    } else if (type == TokenType.QUESTION_PERIOD_PERIOD) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.token(cascadeOperator), '?');
      });
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ReplaceCascadeWithDot newInstance() => ReplaceCascadeWithDot();
}
