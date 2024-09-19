// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class ConvertQuotes extends _ConvertQuotes {
  @override
  late bool _fromDouble;

  ConvertQuotes({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_QUOTES;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_QUOTES_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is SimpleStringLiteral) {
      _fromDouble = !node.isSingleQuoted;
      await _simpleStringLiteral(builder, node, addBackslash: false);
      await _removeBackslash(builder, node.literal);
    } else if (node is StringInterpolation) {
      _fromDouble = !node.isSingleQuoted;
      await _stringInterpolation(builder, node);

      for (var child in node.childEntities.whereType<InterpolationString>()) {
        await _removeBackslash(builder, child.contents);
      }
    }
  }
}

class ConvertToDoubleQuotes extends _ConvertQuotes {
  ConvertToDoubleQuotes({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_DOUBLE_QUOTED_STRING;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_DOUBLE_QUOTED_STRING;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_TO_DOUBLE_QUOTED_STRING_MULTI;

  @override
  bool get _fromDouble => false;
}

class ConvertToSingleQuotes extends _ConvertQuotes {
  ConvertToSingleQuotes({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_SINGLE_QUOTED_STRING;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_SINGLE_QUOTED_STRING;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_TO_SINGLE_QUOTED_STRING_MULTI;

  @override
  bool get _fromDouble => true;
}

abstract class _ConvertQuotes extends ResolvedCorrectionProducer {
  _ConvertQuotes({required super.context});

  /// Return `true` if this producer is converting from double quotes to single
  /// quotes, or `false` if it's converting from single quotes to double quotes.
  bool get _fromDouble;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is SimpleStringLiteral) {
      await _simpleStringLiteral(builder, node);
    } else if (node is StringInterpolation) {
      await _stringInterpolation(builder, node);
    } else if (node is InterpolationString) {
      await _stringInterpolation(builder, node.parent as StringInterpolation);
    }
    await _removeBackslash(builder, token);
  }

  Future<void> _addBackslash(ChangeBuilder builder, Token token) async {
    var quote = _fromDouble ? "'" : '"';
    var text = utils.getText(token.offset, token.length);
    for (var i = 1; i + 1 < text.length; i++) {
      if ((text[i + 1] == quote) && (text[i] != r'\')) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleInsertion(token.offset + 1 + i, r'\');
        });
      }
    }
  }

  Future<void> _removeBackslash(ChangeBuilder builder, Token token) async {
    var quote = _fromDouble ? '"' : "'";
    var text = utils.getText(token.offset, token.length);
    for (var i = 0; i + 1 < text.length; i++) {
      if (text[i] == r'\' && text[i + 1] == quote) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(SourceRange(token.offset + i, 1));
        });
        i++;
      }
    }
  }

  Future<void> _simpleStringLiteral(
      ChangeBuilder builder, SimpleStringLiteral node,
      {bool addBackslash = true}) async {
    if (_fromDouble ? !node.isSingleQuoted : node.isSingleQuoted) {
      var newQuote = node.isMultiline
          ? (_fromDouble ? "'''" : '"""')
          : (_fromDouble ? "'" : '"');
      var quoteLength = node.isMultiline ? 3 : 1;
      var token = node.literal;

      if (addBackslash) {
        await _addBackslash(builder, token);
      }

      if (!token.isSynthetic) {
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
      ChangeBuilder builder, StringInterpolation node) async {
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
