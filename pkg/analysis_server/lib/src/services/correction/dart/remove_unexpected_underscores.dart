// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class RemoveUnexpectedUnderscores extends ResolvedCorrectionProducer {
  RemoveUnexpectedUnderscores({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNEXPECTED_UNDERSCORES;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_UNEXPECTED_UNDERSCORES_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var offset = diagnostic?.problemMessage.offset;
    if (offset == null) {
      return;
    }
    var node = coveringNode;
    Token literal;
    if (node is IntegerLiteral) {
      literal = node.literal;
    } else if (node is DoubleLiteral) {
      literal = node.literal;
    } else {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      var lexeme = literal.lexeme;
      int? underscoresStart;
      var previousIsDigit = false;
      var isHexNumber =
          literal.type == TokenType.HEXADECIMAL ||
          literal.type == TokenType.HEXADECIMAL_WITH_SEPARATORS;
      for (var i = 0; i < lexeme.length; i++) {
        // Remove each sequence of '_' characters which is not surrounded by
        // '0-9' or 'a-f' or 'A-F' on both sides, or which are at the start or
        // end of the number.
        var ch = lexeme.codeUnitAt(i);
        var isHexDigit =
            isHexNumber &&
            ((ch >= 0x41 /* 'A' */ && ch <= 0x46 /* 'F' */ ) ||
                (ch >= 0x61 /* 'a' */ && ch <= 0x66 /* 'f' */ ));
        var isDigit =
            isHexDigit || (ch >= 0x30 /* '0' */ && ch <= 0x39 /* '9' */ );

        if (ch == 0x5F /* '_' */ ) {
          underscoresStart ??= i;
        } else if (isDigit) {
          if (underscoresStart != null && !previousIsDigit) {
            // Unexpected underscores follow a non-digit.
            var length = i - underscoresStart;
            builder.addDeletion(
              SourceRange(token.offset + underscoresStart, length),
            );
          }
          underscoresStart = null;
          previousIsDigit = true;
        } else {
          // Non-underscore and non-digit.
          if (underscoresStart != null) {
            // Unexpected underscores are followed by a non-digit.
            var length = i - underscoresStart;
            builder.addDeletion(
              SourceRange(token.offset + underscoresStart, length),
            );
          }
          underscoresStart = null;
          previousIsDigit = false;
        }
      }
      if (underscoresStart != null) {
        // Unexpected trailing underscores.
        var length = lexeme.length - underscoresStart;
        builder.addDeletion(
          SourceRange(token.offset + underscoresStart, length),
        );
      }
    });
  }
}
