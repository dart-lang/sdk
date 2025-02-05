// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceWithEightDigitHex extends ResolvedCorrectionProducer {
  static final _underscoresPattern = RegExp('_+');

  static final _tripletWithUnderscoresPattern = RegExp(
    r'^[0-9a-fA-F]{2}_[0-9a-fA-F]{2}_[0-9a-fA-F]{2}$',
  );

  /// The replacement text, used as an argument to the fix message.
  String _replacement = '';

  ReplaceWithEightDigitHex({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  List<String> get fixArguments => [_replacement];

  @override
  FixKind get fixKind => DartFixKind.REPLACE_WITH_EIGHT_DIGIT_HEX;

  @override
  FixKind get multiFixKind => DartFixKind.REPLACE_WITH_EIGHT_DIGIT_HEX_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (node case (IntegerLiteral(:var value?, :var literal))) {
      var replacementDigits = value.toRadixString(16).padLeft(8, '0');
      if (literal.type == TokenType.HEXADECIMAL_WITH_SEPARATORS) {
        // The original string should be a substring of the replacement
        // (ignoring the '0x'). If there are existing separators, preserve them.
        var originalDigits = literal.lexeme.substring('0x'.length);
        if (_tripletWithUnderscoresPattern.hasMatch(originalDigits)) {
          replacementDigits = '00_$originalDigits';
        } else {
          var originalWithoutSeparators = originalDigits.replaceAll(
            _underscoresPattern,
            '',
          );
          var numberOfDigitsToAdd =
              replacementDigits.length - originalWithoutSeparators.length;
          var newLeadingDigits = '0' * numberOfDigitsToAdd;
          replacementDigits = '$newLeadingDigits$originalDigits';
        }
      }
      var hexIndicator = switch (literal.type) {
        TokenType.HEXADECIMAL || TokenType.HEXADECIMAL_WITH_SEPARATORS =>
          literal.lexeme.substring(0, '0x'.length),
        // Defalt to lower-case.
        _ => '0x',
      };
      _replacement = '$hexIndicator$replacementDigits';
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.node(node), _replacement);
      });
    }
  }
}
