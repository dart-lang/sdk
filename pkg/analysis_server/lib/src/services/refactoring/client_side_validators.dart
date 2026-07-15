// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
/// @docImport 'package:analysis_server/src/services/refactoring/legacy/naming_conventions.dart';
library;

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analyzer/dart/ast/token.dart';

/// Validators for naming conventions that can be provided to clients for
/// real-time validation.
///
/// These validator are used by [ParameterizedRefactoringProducer]s as part
/// of Interactive Forms to provide immediate feedback for identifiers without
/// needing to wait until the form is posted back to the server.
///
/// These validator are not intended to be a comprehensive set of all
/// validation rules, only a simplified version for earlier reporting of obvious
/// invalid values. They may not reject all invalid inputs, but they should not
/// reject valid inputs.
class ClientSideValidators {
  final bool _clientSupportsEcmaScriptRegex;

  new(LspClientCapabilities? clientCapabilities)
    : _clientSupportsEcmaScriptRegex =
          clientCapabilities?.ecmaScriptRegex ?? false;

  /// Validators for constructor names.
  ///
  /// These are based approximately on the Dart version in
  /// [validateConstructorName].
  List<StringValidator> get constructorName {
    return _lowerCamelCase('Constructor name', allowBuiltIn: true);
  }

  /// Validators for import prefixes.
  ///
  /// These are based approximately on the Dart version in
  /// [validateImportPrefixName].
  List<StringValidator> get importPrefix {
    return _lowerCamelCase('Import prefix');
  }

  List<StringValidator> _lowerCamelCase(
    String desc, {
    bool allowBuiltIn = false,
  }) {
    // All of these validators are currently ECMAScript regexes.
    if (!_clientSupportsEcmaScriptRegex) return [];

    var keywords = Keyword.keywords.values
        .where((keyword) => !keyword.isBuiltInOrPseudo)
        .map((keyword) => keyword.lexeme);
    var keywordRegex = '^(?:${keywords.join("|")})\$';

    var builtins = Keyword.keywords.values
        .where((keyword) => keyword.isBuiltInOrPseudo)
        .map((keyword) => keyword.lexeme);
    var builtinRegex = '^(?:${builtins.join("|")})\$';

    return [
      RegexValidator(
        pattern: keywordRegex,
        message: '$desc must not be a keyword.',
        matchIsValid: false,
        severity: .Error,
      ),
      RegexValidator(
        pattern: r'^[a-zA-Z0-9_$]*$',
        message:
            '$desc must only include letters, digits, underscores and dollars.',
        matchIsValid: true,
        severity: .Error,
      ),
      RegexValidator(
        pattern: r'^[0-9]',
        message: '$desc must not begin with a number.',
        matchIsValid: false,
        severity: .Error,
      ),
      // For built-ins, they're either not allowed at all, or produce a warning.
      RegexValidator(
        pattern: builtinRegex,
        message: allowBuiltIn
            ? '$desc should not be a built-in identifier.'
            : '$desc must not be a built-in identifier.',
        matchIsValid: false,
        severity: allowBuiltIn ? .Warning : .Error,
      ),
      RegexValidator(
        pattern: r'^[a-z_]',
        message: '$desc should begin with a lowercase letter or underscore.',
        matchIsValid: true,
        severity: .Warning,
      ),
    ];
  }
}
