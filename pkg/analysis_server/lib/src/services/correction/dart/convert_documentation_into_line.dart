// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertDocumentationIntoLine extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_DOCUMENTATION_INTO_LINE;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_LINE_COMMENT;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var comment = node.thisOrAncestorOfType<Comment>();
    if (comment == null ||
        !comment.isDocumentation ||
        comment.tokens.length != 1) {
      return null;
    }
    var token = comment.tokens.first;
    if (token.type != TokenType.MULTI_LINE_COMMENT) {
      return null;
    }
    var text = token.lexeme;
    var lines = text.split(eol);
    var prefix = utils.getNodePrefix(comment);
    var newLines = <String>[];
    var firstLine = true;
    var linePrefix = '';
    for (var line in lines) {
      if (firstLine) {
        firstLine = false;
        var expectedPrefix = '/**';
        if (!line.startsWith(expectedPrefix)) {
          return null;
        }
        line = line.substring(expectedPrefix.length).trim();
        if (line.isNotEmpty) {
          newLines.add('/// $line');
          linePrefix = eol + prefix;
        }
      } else {
        if (line.startsWith(prefix + ' */')) {
          break;
        }
        var expectedPrefix = prefix + ' *';
        if (!line.startsWith(expectedPrefix)) {
          return null;
        }
        line = line.substring(expectedPrefix.length);
        if (line.isEmpty) {
          newLines.add('$linePrefix///');
        } else {
          newLines.add('$linePrefix///$line');
        }
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

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertDocumentationIntoLine newInstance() =>
      ConvertDocumentationIntoLine();
}
