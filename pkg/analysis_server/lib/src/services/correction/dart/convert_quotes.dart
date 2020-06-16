// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

abstract class ConvertQuotes extends CorrectionProducer {
  ConvertQuotes();

  /// Return `true` if this producer is converting from double quotes to single
  /// quotes, or `false` if it's converting from single quotes to double quotes.
  bool get _fromDouble;

  @override
  Future<void> compute(DartChangeBuilder builder) async {
    if (node is SimpleStringLiteral) {
      SimpleStringLiteral literal = node;
      if (_fromDouble ? !literal.isSingleQuoted : literal.isSingleQuoted) {
        var newQuote = literal.isMultiline
            ? (_fromDouble ? "'''" : '"""')
            : (_fromDouble ? "'" : '"');
        var quoteLength = literal.isMultiline ? 3 : 1;
        var lexeme = literal.literal.lexeme;
        if (!lexeme.contains(newQuote)) {
          await builder.addFileEdit(file, (DartFileEditBuilder builder) {
            builder.addSimpleReplacement(
                SourceRange(
                    literal.offset + (literal.isRaw ? 1 : 0), quoteLength),
                newQuote);
            builder.addSimpleReplacement(
                SourceRange(literal.end - quoteLength, quoteLength), newQuote);
          });
        }
      }
    } else if (node is InterpolationString) {
      StringInterpolation parent = node.parent;
      if (_fromDouble ? !parent.isSingleQuoted : parent.isSingleQuoted) {
        var newQuote = parent.isMultiline
            ? (_fromDouble ? "'''" : '"""')
            : (_fromDouble ? "'" : '"');
        var quoteLength = parent.isMultiline ? 3 : 1;
        var elements = parent.elements;
        for (var i = 0; i < elements.length; i++) {
          var element = elements[i];
          if (element is InterpolationString) {
            var lexeme = element.contents.lexeme;
            if (lexeme.contains(newQuote)) {
              return null;
            }
          }
        }
        await builder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addSimpleReplacement(
              SourceRange(parent.offset + (parent.isRaw ? 1 : 0), quoteLength),
              newQuote);
          builder.addSimpleReplacement(
              SourceRange(parent.end - quoteLength, quoteLength), newQuote);
        });
      }
    }
  }
}

class ConvertToDoubleQuotes extends ConvertQuotes {
  ConvertToDoubleQuotes();

  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_DOUBLE_QUOTED_STRING;

  @override
  bool get _fromDouble => false;

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertToDoubleQuotes newInstance() => ConvertToDoubleQuotes();
}

class ConvertToSingleQuotes extends ConvertQuotes {
  ConvertToSingleQuotes();

  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_SINGLE_QUOTED_STRING;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_SINGLE_QUOTED_STRING;

  @override
  bool get _fromDouble => true;

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertToSingleQuotes newInstance() => ConvertToSingleQuotes();
}
