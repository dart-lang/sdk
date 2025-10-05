// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class ConvertToIntLiteral extends ResolvedCorrectionProducer {
  ConvertToIntLiteral({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.convertToIntLiteral;

  @override
  FixKind get fixKind => DartFixKind.convertToIntLiteral;

  @override
  FixKind get multiFixKind => DartFixKind.convertToIntLiteralMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var literal = node;
    if (literal is! DoubleLiteral) {
      return;
    }

    int? intValue;
    try {
      intValue = literal.value.truncate();
    } catch (e) {
      // A double that cannot be converted to an int.
      return;
    }

    if (intValue != literal.value) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      if (!literal.literal.lexeme.toLowerCase().contains('e')) {
        var indexOfDecimal = literal.literal.lexeme.indexOf('.');
        if (indexOfDecimal > 0) {
          // Preserve digit separators by just truncating the existing lexeme.
          builder.addDeletion(
            SourceRange(
              literal.offset + indexOfDecimal,
              literal.length - indexOfDecimal,
            ),
          );
          return;
        }
      }

      builder.addReplacement(SourceRange(literal.offset, literal.length), (
        builder,
      ) {
        builder.write('$intValue');
      });
    });
  }
}
