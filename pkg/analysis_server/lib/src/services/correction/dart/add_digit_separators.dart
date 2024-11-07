// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/util.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class AddDigitSeparatorEveryThreeDigits extends _AddDigitSeparators {
  AddDigitSeparatorEveryThreeDigits({required super.context});

  @override
  int get _digitsPerGroup => 3;

  @override
  int get _minimumDigitCount => 5;

  @override
  Set<TokenType> get _tokenTypes => const {
    TokenType.INT,
    TokenType.INT_WITH_SEPARATORS,
    TokenType.DOUBLE,
    TokenType.DOUBLE_WITH_SEPARATORS,
  };
}

class AddDigitSeparatorEveryTwoDigits extends _AddDigitSeparators {
  AddDigitSeparatorEveryTwoDigits({required super.context});

  @override
  int get _digitsPerGroup => 2;

  @override
  int get _minimumDigitCount => 4;

  @override
  Set<TokenType> get _tokenTypes => const {
    TokenType.HEXADECIMAL,
    TokenType.HEXADECIMAL_WITH_SEPARATORS,
  };
}

abstract class _AddDigitSeparators extends ResolvedCorrectionProducer {
  _AddDigitSeparators({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.ADD_DIGIT_SEPARATORS;

  /// The number of digits in each group, to be separated by a separator.
  int get _digitsPerGroup;

  /// The minimum number of digits in order to offer the correction.
  int get _minimumDigitCount;

  /// The token types for which this correction is applicable.
  Set<TokenType> get _tokenTypes;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is IntegerLiteral) {
      if (!_tokenTypes.contains(node.literal.type)) {
        return;
      }
      // We scrap whatever separators are in place.
      var source = stripSeparators(node.literal.lexeme);
      var isHex =
          node.literal.type == TokenType.HEXADECIMAL ||
          node.literal.type == TokenType.HEXADECIMAL_WITH_SEPARATORS;
      if (isHex) {
        const hexPrefixLength = '0x'.length;
        var replacement = _addSeparators(source.substring(hexPrefixLength));
        if (replacement == null) return;
        // Prefix the '0x' text.
        replacement = '${source.substring(0, hexPrefixLength)}$replacement';
        // Don't offer the correction if the result is unchanged.
        if (replacement == node.literal.lexeme) return;
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleReplacement(range.node(node), replacement!);
        });
      } else {
        var replacement = _addSeparators(source);
        if (replacement == null) return;
        // Don't offer the correction if the result is unchanged.
        if (replacement == node.literal.lexeme) return;
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleReplacement(range.node(node), replacement);
        });
      }
    } else if (node is DoubleLiteral) {
      if (!_tokenTypes.contains(node.literal.type)) {
        return;
      }
      // We scrap whatever separators are in place.
      var source = stripSeparators(node.literal.lexeme);

      String wholePart;
      String? fractionalPart;
      String? exponentialPart;
      var exponentialPartIsNegative = false;

      var eIndex = source.indexOf('e');
      if (eIndex == -1) eIndex = source.indexOf('E');
      if (eIndex > -1) {
        if (source.codeUnitAt(eIndex + 1) == 0x2D /* '-' */ ) {
          exponentialPartIsNegative = true;
          exponentialPart = source.substring(eIndex + 2);
        } else {
          exponentialPart = source.substring(eIndex + 1);
        }
      }

      var decimalIndex = source.indexOf('.');
      if (decimalIndex > -1) {
        wholePart = source.substring(0, decimalIndex);
        fractionalPart =
            eIndex > -1
                ? source.substring(decimalIndex + 1, eIndex)
                : source.substring(decimalIndex + 1);
      } else {
        assert(
          eIndex > -1,
          "There is neither a decimal point, nor an 'e', nor an 'E', in this "
          "double literal: '${node.literal.lexeme}'",
        );
        wholePart = source.substring(0, eIndex);
        fractionalPart = null;
      }

      var buffer = StringBuffer();
      var replacement = _addSeparators(wholePart);
      buffer.write(replacement ?? wholePart);

      if (fractionalPart != null) {
        buffer.write('.');

        // Reverse the fractional part, so that separators are aligned to the
        // left instead of the right.
        var fractionalPartReversed = fractionalPart.split('').reversed.join();
        replacement = _addSeparators(fractionalPartReversed);

        // Reverse back the replacement.
        replacement = replacement?.split('').reversed.join();
        buffer.write(replacement ?? fractionalPart);
      }

      if (exponentialPart != null) {
        buffer.write(source.substring(eIndex, eIndex + 1));
        if (exponentialPartIsNegative) buffer.write('-');
        replacement = _addSeparators(exponentialPart);
        buffer.write(replacement ?? exponentialPart);
      }

      replacement = buffer.toString();
      // Don't offer the correction if the result is unchanged.
      if (replacement == node.literal.lexeme) return;

      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.node(node), buffer.toString());
      });
    }
  }

  /// Adds separators to [digits], returning the result.
  String? _addSeparators(String digits) {
    // Only offer to add separators when the number has some minimum number of
    // digits.
    var digitCount = digits.length;
    if (digitCount < _minimumDigitCount) return null;

    var buffer = StringBuffer();
    var offset = digitCount % _digitsPerGroup;
    if (offset == 0) offset = _digitsPerGroup;
    buffer.write(digits.substring(0, offset));
    offset += _digitsPerGroup;
    for (; offset <= digits.length; offset += _digitsPerGroup) {
      buffer.write('_');
      buffer.write(digits.substring(offset - _digitsPerGroup, offset));
    }
    return buffer.toString();
  }
}
