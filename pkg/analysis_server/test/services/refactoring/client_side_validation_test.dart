// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/services/refactoring/client_side_validators.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClientSideValidatorsTest);
  });
}

@reflectiveTest
class ClientSideValidatorsTest {
  /// Default validators where the client supports ECMAScript regex.
  final validators = ClientSideValidators(
    LspClientCapabilities(
      ClientCapabilities(
        general: GeneralClientCapabilities(
          regularExpressions: RegularExpressionsClientCapabilities(
            engine: 'ECMAScript',
          ),
        ),
      ),
    ),
  );

  /// Helper to expect an error validator to consider [input] invalid.
  void expectError(Validator validator, String input) {
    expect(validator.severity, ValidationSeverity.Error);
    expect(validate(validator, input), isFalse);
  }

  /// Helper to expect a validator to consider [input] to be valid.
  void expectValid(Validator validator, String input) {
    expect(validate(validator, input), isTrue);
  }

  /// Helper to expect a warning validator to consider [input] invalid.
  void expectWarning(Validator validator, String input) {
    expect(validator.severity, ValidationSeverity.Warning);
    expect(validate(validator, input), isFalse);
  }

  /// Helper to find the validator that would produce [message].
  Validator findValidator(List<Validator> validators, String message) {
    return validators.singleWhere((validator) => validator.message == message);
  }

  void test_constructorName_doesNotStartNumber() {
    var validator = findValidator(
      validators.constructorName,
      'Constructor name must not begin with a number.',
    );
    // Errors
    expectError(validator, '1foo');
    // Valid
    expectValid(validator, r'$foo');
    expectValid(validator, '_foo');
    expectValid(validator, 'foo');
  }

  void test_constructorName_keyword() {
    var validator = findValidator(
      validators.constructorName,
      'Constructor name must not be a keyword.',
    );
    // Errors
    expectError(validator, 'new');
    expectError(validator, 'catch');
    // Valid
    expectValid(validator, 'foo');
  }

  void test_constructorName_onlyAlphaNumericUnderscoreDollar() {
    var validator = findValidator(
      validators.constructorName,
      'Constructor name must only include letters, digits, underscores and dollars.',
    );
    // Errors
    expectError(validator, 'foo£');
    expectError(validator, 'catch!');
    // Valid
    expectValid(validator, r'foo123$_');
  }

  void test_constructorName_startsLowercaseOrUnderscore() {
    var validator = findValidator(
      validators.constructorName,
      'Constructor name should begin with a lowercase letter or underscore.',
    );
    // Warnings
    expectWarning(validator, 'Foo');
    expectWarning(validator, r'$Foo');
    expectWarning(validator, '1Foo');
    // Valid
    expectValid(validator, 'foo');
    expectValid(validator, '_foo');
  }

  void test_constructorName_unsupported_noRegexEngine() {
    var validators = ClientSideValidators(
      LspClientCapabilities(ClientCapabilities()),
    );
    expect(validators.constructorName, isEmpty);
  }

  void test_constructorName_unsupported_otherRegexEngine() {
    var validators = ClientSideValidators(
      LspClientCapabilities(
        ClientCapabilities(
          general: GeneralClientCapabilities(
            regularExpressions: RegularExpressionsClientCapabilities(
              engine: 'NOT ECMAScript', // Unsupported
            ),
          ),
        ),
      ),
    );
    expect(validators.constructorName, isEmpty);
  }

  /// Helper that executes [validator] and returns whether [input] was valid.
  bool validate(Validator validator, String input) {
    switch (validator) {
      case RegexValidator():
        return RegExp(validator.pattern).hasMatch(input) ==
            validator.matchIsValid;
      default:
        throw UnimplementedError('Validator $validator is not supported');
    }
  }
}
