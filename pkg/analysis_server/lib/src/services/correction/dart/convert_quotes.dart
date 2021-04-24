// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

abstract class ConvertQuotes extends CorrectionProducer {
  ConvertQuotes();

  /// Return `true` if this producer is converting from double quotes to single
  /// quotes, or `false` if it's converting from single quotes to double quotes.
  bool get _fromDouble;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;
    if (node is SimpleStringLiteral) {
      await _simpleStringLiteral(builder, node);
    } else if (node is StringInterpolation) {
      await _stringInterpolation(builder, node);
    } else if (node is InterpolationString) {
      await _stringInterpolation(builder, node.parent as StringInterpolation);
    }
  }

  Future<void> _simpleStringLiteral(
    ChangeBuilder builder,
    SimpleStringLiteral node,
  ) async {
    if (_fromDouble ? !node.isSingleQuoted : node.isSingleQuoted) {
      var newQuote = node.isMultiline
          ? (_fromDouble ? "'''" : '"""')
          : (_fromDouble ? "'" : '"');
      var quoteLength = node.isMultiline ? 3 : 1;
      var token = node.literal;
      if (!token.isSynthetic && !token.lexeme.contains(newQuote)) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleReplacement(
            SourceRange(node.offset + (node.isRaw ? 1 : 0), quoteLength),
            newQuote,
          );
          builder.addSimpleReplacement(
            SourceRange(node.end - quoteLength, quoteLength),
            newQuote,
          );
        });
      }
    }
  }

  Future<void> _stringInterpolation(
    ChangeBuilder builder,
    StringInterpolation node,
  ) async {
    if (_fromDouble ? !node.isSingleQuoted : node.isSingleQuoted) {
      var newQuote = node.isMultiline
          ? (_fromDouble ? "'''" : '"""')
          : (_fromDouble ? "'" : '"');
      var quoteLength = node.isMultiline ? 3 : 1;
      var elements = node.elements;
      for (var i = 0; i < elements.length; i++) {
        var element = elements[i];
        if (element is InterpolationString) {
          var token = element.contents;
          if (token.isSynthetic || token.lexeme.contains(newQuote)) {
            return;
          }
        }
      }
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(
          SourceRange(node.offset + (node.isRaw ? 1 : 0), quoteLength),
          newQuote,
        );
        builder.addSimpleReplacement(
          SourceRange(node.end - quoteLength, quoteLength),
          newQuote,
        );
      });
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
  FixKind get multiFixKind => DartFixKind.CONVERT_TO_SINGLE_QUOTED_STRING_MULTI;

  @override
  bool get _fromDouble => true;

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertToSingleQuotes newInstance() => ConvertToSingleQuotes();
}
