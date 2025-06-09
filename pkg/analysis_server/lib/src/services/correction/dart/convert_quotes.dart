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

class ConvertQuotes extends _ConvertQuotes {
  @override
  late bool _fromSingle;

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
      _fromSingle = node.isSingleQuoted;
    } else if (node is StringInterpolation) {
      _fromSingle = node.isSingleQuoted;
    } else if (node case InterpolationString(:StringInterpolation parent)) {
      _fromSingle = parent.isSingleQuoted;
    }
    await super.compute(builder);
  }
}

class ConvertToDoubleQuotes extends _ConvertQuotes {
  ConvertToDoubleQuotes({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.convertToDoubleQuotedString;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_DOUBLE_QUOTED_STRING;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_TO_DOUBLE_QUOTED_STRING_MULTI;

  @override
  bool get _fromSingle => true;
}

class ConvertToSingleQuotes extends _ConvertQuotes {
  ConvertToSingleQuotes({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.convertToSingleQuotedString;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_SINGLE_QUOTED_STRING;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_TO_SINGLE_QUOTED_STRING_MULTI;

  @override
  bool get _fromSingle => false;
}

abstract class _ConvertQuotes extends ResolvedCorrectionProducer {
  static const _backslash = 0x5C;
  static const _dollar = 0x24;

  _ConvertQuotes({required super.context});

  /// Return `true` if this producer is converting from single quotes to double
  /// quotes, or `false` if it's converting from double quotes to single quotes.
  bool get _fromSingle;

  _QuotePair get _quotes =>
      _fromSingle ? _QuotePair.toDouble : _QuotePair.toSingle;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    StringInterpolation? interpolation;
    if (node is SimpleStringLiteral) {
      await _simpleStringLiteral(builder, node);
    } else if (node is StringInterpolation) {
      interpolation = node;
    } else if (node case InterpolationString(:StringInterpolation parent)) {
      interpolation = parent;
    }
    await _stringInterpolation(builder, interpolation);
  }

  bool _canKeepAsRaw(String text) {
    var newQuoteChar = _quotes.newQuoteString;

    // If the string ends with the new quote, we would have four consecutive
    // equal quotes, which would close the string and open a new one.
    if (text.endsWith(newQuoteChar)) {
      return false;
    }

    // If the string contains three consecutive new quotes (or more) we would
    // close the string at that position so this would be invalid.
    return !text.contains(newQuoteChar * 3);
  }

  Future<void> _deleteAtOffset(ChangeBuilder builder, int offset) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(SourceRange(offset, 1));
    });
  }

  Future<void> _escapeBackslashesAndDollars(
    ChangeBuilder builder,
    String text,
    int offset,
  ) async {
    for (var i = 0; i < text.length; i++) {
      var char = text.codeUnitAt(i);
      if (char == _backslash) {
        await _insertBackslashAt(builder, offset + i);
      } else if (char == _dollar) {
        await _insertBackslashAt(builder, offset + i);
      }
    }
  }

  Future<void> _fixBackslashesForQuotes(
    ChangeBuilder builder,
    String text,
    int offset, {
    required bool isMultiline,
    required bool containsStringEnd,
  }) async {
    var _QuotePair(:newQuote, :oppositeQuote) = _quotes;
    var isEscaping = false;
    var quoteCount = 0;

    for (var i = 0; i < text.length; i++) {
      var char = text.codeUnitAt(i);
      if (char == newQuote) {
        // If we're not escaping, add a backslash before the quote.
        if (!isEscaping) {
          if (isMultiline) {
            quoteCount++;
            // If we have a triple quote equal to the new quote, we need to
            // escape the third so it doesn't close the string.
            if (quoteCount == 3) {
              await _insertBackslashAt(builder, offset + i);
              // This quote counts as the first of a new triple quote.
              quoteCount = 0;
            } else if (containsStringEnd && (i + 1) == text.length) {
              // At the end of the multiline string we must always escape the
              // quote so that our multiline closing works as expected.
              await _insertBackslashAt(builder, offset + i);
            }
          } else {
            await _insertBackslashAt(builder, offset + i);
          }
        } else {
          // Here we say that we're not escaping anymore, because this is a
          // quote, not a backslash.
          isEscaping = false;
        }
      } else {
        quoteCount = 0;
        if (char == oppositeQuote) {
          // If we're escaping, remove the backslash before the opposite quote.
          if (isEscaping) {
            await _deleteAtOffset(builder, offset + i - 1);
            // Here we say that we're not escaping anymore, because this is a
            // quote, not a backslash.
            isEscaping = false;
          }
        }
        // Swap the escaping state because we found a backslash.
        isEscaping = (char == _backslash) && !isEscaping;
      }
    }
  }

  Future<void> _insertBackslashAt(ChangeBuilder builder, int offset) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(offset, r'\');
    });
  }

  String _newQuote(SingleStringLiteral node) {
    return node.isMultiline
        ? _quotes.newQuoteMultilineString
        : _quotes.newQuoteString;
  }

  Future<void> _replaceQuotes(
    ChangeBuilder builder,
    int offset,
    int end,
    String newQuote, {
    required bool wasRaw,
    required bool isRaw,
  }) async {
    var endQuoteLength = newQuote.length;
    var startQuoteLength = endQuoteLength;
    var startQuoteOffset = offset;
    if (wasRaw) {
      if (isRaw) {
        startQuoteOffset += 1;
      } else {
        startQuoteLength += 1;
      }
    }
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        SourceRange(startQuoteOffset, startQuoteLength),
        newQuote,
      );
      builder.addSimpleReplacement(
        SourceRange(end - endQuoteLength, endQuoteLength),
        newQuote,
      );
    });
  }

  Future<void> _simpleStringLiteral(
    ChangeBuilder builder,
    SimpleStringLiteral node,
  ) async {
    if (_fromSingle != node.isSingleQuoted) {
      return;
    }
    var token = node.literal;
    if (token.isSynthetic) {
      return;
    }

    var isRaw = node.isRaw;
    var endQuoteLength = node.isMultiline ? 3 : 1;
    var startQuoteLength = endQuoteLength;
    var offset = token.offset + startQuoteLength;
    var text = utils.getText(
      offset,
      token.length - (startQuoteLength + endQuoteLength),
    );
    if (isRaw) {
      offset++;
      text = text.substring(1);
      isRaw = _canKeepAsRaw(text);
      // Removes obsolete escape for opposite quotes.
      if (!isRaw) {
        await _escapeBackslashesAndDollars(builder, text, offset);
      }
    }

    await _fixBackslashesForQuotes(
      builder,
      text,
      offset,
      isMultiline: node.isMultiline,
      containsStringEnd: true,
    );

    await _replaceQuotes(
      builder,
      node.offset,
      node.end,
      _newQuote(node),
      isRaw: isRaw,
      wasRaw: node.isRaw,
    );
  }

  Future<void> _stringInterpolation(
    ChangeBuilder builder,
    StringInterpolation? node,
  ) async {
    if (node == null) {
      return;
    }
    if (_fromSingle != node.isSingleQuoted) {
      return;
    }

    if (node.lastString.endToken.isSynthetic ||
        node.firstString.beginToken.isSynthetic) {
      return;
    }

    var newQuote = _newQuote(node);

    for (var element in node.elements) {
      if (element is InterpolationString) {
        var offset = element.offset;
        var length = element.length;
        var containsStringEnd = false;
        if (element == node.firstString) {
          offset += newQuote.length;
        } else if (element == node.lastString) {
          length -= newQuote.length;
          containsStringEnd = true;
        }
        var text = utils.getText(offset, length);
        await _fixBackslashesForQuotes(
          builder,
          text,
          offset,
          isMultiline: node.isMultiline,
          containsStringEnd: containsStringEnd,
        );
      }
    }

    await _replaceQuotes(
      builder,
      node.offset,
      node.end,
      newQuote,
      wasRaw: false,
      isRaw: false,
    );
  }
}

enum _QuotePair {
  toDouble(_doubleQuote, '"', '"""', _singleQuote),
  toSingle(_singleQuote, "'", "'''", _doubleQuote);

  static const _doubleQuote = 0x22;
  static const _singleQuote = 0x27;

  final int newQuote;
  final String newQuoteString;
  final String newQuoteMultilineString;
  final int oppositeQuote;

  const _QuotePair(
    this.newQuote,
    this.newQuoteString,
    this.newQuoteMultilineString,
    this.oppositeQuote,
  );
}
