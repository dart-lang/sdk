// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/src/utilities/extensions/string_extension.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertDocumentationIntoLine extends ParsedCorrectionProducer {
  ConvertDocumentationIntoLine({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.convertDocumentationIntoLine;

  @override
  FixKind get fixKind => DartFixKind.convertToLineComment;

  @override
  FixKind get multiFixKind => DartFixKind.convertToLineCommentMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var comment = node.thisOrAncestorOfType<Comment>();
    if (comment == null || comment.tokens.length != 1) {
      return;
    }
    var token = comment.tokens.first;
    if (token.type != TokenType.MULTI_LINE_COMMENT) {
      return;
    }
    var text = token.lexeme;
    var eol = text.endOfLine;
    var lines = eol != null ? text.split(eol) : [text];
    // To simplify the code below which builds prefixes with eols in the loop,
    // ensure we have a value. In the case of a single line (eol=null) these
    // eols are only assigned to variables and not used.
    eol ??= builder.defaultEol;
    var prefix = utils.getNodePrefix(comment);
    var newLines = <String>[];
    var firstLine = true;
    var linePrefix = '';
    for (var line in lines) {
      if (firstLine) {
        firstLine = false;
        var expectedPrefix = '/**';
        if (!line.startsWith(expectedPrefix)) {
          return;
        }
        line = line.substring(expectedPrefix.length).trim();
        if (line.endsWith('*/')) {
          line = line.substring(0, line.length - 2).trim();
        }
        if (line.isNotEmpty) {
          newLines.add('/// $line');
          linePrefix = eol + prefix;
        }
      } else {
        line = line.trimLeft();
        if (line.startsWith('*/')) {
          break;
        }
        if (!line.startsWith('*')) {
          return;
        }
        line = line.substring(1);
        if (line.endsWith('*/')) {
          line = line.substring(0, line.length - 2).trimRight();
        }
        newLines.add('$linePrefix///$line');
        linePrefix = eol + prefix;
      }
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(comment), (builder) {
        for (var newLine in newLines) {
          builder.write(newLine);
        }
      });
    });
  }
}
