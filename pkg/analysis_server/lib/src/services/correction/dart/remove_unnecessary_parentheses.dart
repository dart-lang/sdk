// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveUnnecessaryParentheses extends ResolvedCorrectionProducer {
  RemoveUnnecessaryParentheses({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNNECESSARY_PARENTHESES;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_UNNECESSARY_PARENTHESES_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var outer = coveringNode;
    if (outer is ParenthesizedExpression) {
      if (outer.parent is! ParenthesizedExpression) {
        var left = outer.leftParenthesis;

        await builder.addDartFileEdit(file, (builder) {
          builder.addReplacement(range.token(left), (builder) {
            if ((left.previous?.isKeywordOrIdentifier ?? false) &&
                left.previous?.end == left.offset) {
              builder.write(' ');
            }
          });
          builder.addDeletion(range.token(outer.rightParenthesis));
        });
      } else if (outer.parent?.parent case Expression expression) {
        if (expression is! BinaryExpression &&
            expression is! ConditionalExpression &&
            expression is! AsExpression &&
            expression is! IsExpression) return;

        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(range.token(outer.leftParenthesis));
          builder.addDeletion(range.token(outer.rightParenthesis));
        });
      }
    }
  }
}
