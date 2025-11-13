// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show Code, Message, PseudoSharedCode;
import 'package:analyzer/dart/ast/token.dart' show Token;
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/diagnostic/diagnostic_code_values.dart';

/// An error reporter that knows how to convert a Fasta error into an analyzer
/// error.
class FastaErrorReporter {
  /// The underlying diagnostic reporter to which diagnostics are reported.
  final DiagnosticReporter? diagnosticReporter;

  /// Initialize a newly created error reporter to report diagnostics to the
  /// given [diagnosticReporter].
  FastaErrorReporter(this.diagnosticReporter);

  void reportByCode(
    PseudoSharedCode? pseudoSharedCode,
    int offset,
    int length,
    Message message,
  ) {
    Map<String, dynamic> arguments = message.arguments;

    String lexeme() => (arguments['lexeme'] as Token).lexeme;

    switch (pseudoSharedCode) {
      case PseudoSharedCode.asyncForInWrongContext:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.asyncForInWrongContext,
        );
        return;
      case PseudoSharedCode.asyncKeywordUsedAsIdentifier:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.asyncKeywordUsedAsIdentifier,
        );
        return;
      case PseudoSharedCode.awaitInWrongContext:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.awaitInWrongContext,
        );
        return;
      case PseudoSharedCode.builtInIdentifierAsType:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.builtInIdentifierAsType,
          arguments: [lexeme()],
        );
        return;
      case PseudoSharedCode.constConstructorWithBody:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.constConstructorWithBody,
        );
        return;
      case PseudoSharedCode.constNotInitialized:
        var name = arguments['name'] as String;
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.constNotInitialized,
          arguments: [name],
        );
        return;
      case PseudoSharedCode.defaultValueInFunctionType:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.defaultValueInFunctionType,
        );
        return;
      case PseudoSharedCode.expectedClassMember:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.expectedClassMember,
        );
        return;
      case PseudoSharedCode.expectedExecutable:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.expectedExecutable,
        );
        return;
      case PseudoSharedCode.expectedStringLiteral:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.expectedStringLiteral,
        );
        return;
      case PseudoSharedCode.expectedToken:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.expectedToken,
          arguments: [arguments['string'] as Object],
        );
        return;
      case PseudoSharedCode.expectedTypeName:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.expectedTypeName,
        );
        return;
      case PseudoSharedCode.extensionDeclaresInstanceField:
        // Reported by
        // [ErrorVerifier._checkForExtensionDeclaresInstanceField]
        return;
      case PseudoSharedCode.finalNotInitialized:
        var name = arguments['name'] as String;
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.finalNotInitialized,
          arguments: [name],
        );
        return;
      case PseudoSharedCode.getterWithParameters:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.getterWithParameters,
        );
        return;
      case PseudoSharedCode.illegalCharacter:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.illegalCharacter,
        );
        return;
      case PseudoSharedCode.invalidInlineFunctionType:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.invalidInlineFunctionType,
        );
        return;
      case PseudoSharedCode.invalidLiteralInConfiguration:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.invalidLiteralInConfiguration,
        );
        return;
      case PseudoSharedCode.invalidCodePoint:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.invalidCodePoint,
          arguments: ['\\u{...}'],
        );
        return;
      case PseudoSharedCode.invalidModifierOnSetter:
        _reportByCode(
          offset: offset,
          length: length,
          code: diag.invalidModifierOnSetter,
          message: message,
        );
        return;
      case PseudoSharedCode.missingDigit:
        diagnosticReporter?.atOffset(
          diagnosticCode: diag.missingDigit,
          offset: offset,
          length: length,
        );
        return;
      case PseudoSharedCode.missingEnumBody:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.missingEnumBody,
        );
        return;
      case PseudoSharedCode.missingFunctionBody:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.missingFunctionBody,
        );
        return;
      case PseudoSharedCode.missingFunctionParameters:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.missingFunctionParameters,
        );
        return;
      case PseudoSharedCode.missingHexDigit:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.missingHexDigit,
        );
        return;
      case PseudoSharedCode.missingIdentifier:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.missingIdentifier,
        );
        return;
      case PseudoSharedCode.missingMethodParameters:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.missingMethodParameters,
        );
        return;
      case PseudoSharedCode.missingStarAfterSync:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.missingStarAfterSync,
        );
        return;
      case PseudoSharedCode.missingTypedefParameters:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.missingTypedefParameters,
        );
        return;
      case PseudoSharedCode.multipleImplementsClauses:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.multipleImplementsClauses,
        );
        return;
      case PseudoSharedCode.namedFunctionExpression:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.namedFunctionExpression,
        );
        return;
      case PseudoSharedCode.namedParameterOutsideGroup:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.namedParameterOutsideGroup,
        );
        return;
      case PseudoSharedCode.nonPartOfDirectiveInPart:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.nonPartOfDirectiveInPart,
        );
        return;
      case PseudoSharedCode.nonSyncFactory:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.nonSyncFactory,
        );
        return;
      case PseudoSharedCode.positionalAfterNamedArgument:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.positionalAfterNamedArgument,
        );
        return;
      case PseudoSharedCode.returnInGenerator:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.returnInGenerator,
        );
        return;
      case PseudoSharedCode.unexpectedDollarInString:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.unexpectedDollarInString,
        );
        return;
      case PseudoSharedCode.unexpectedToken:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.unexpectedToken,
          arguments: [lexeme()],
        );
        return;
      case PseudoSharedCode.unterminatedMultiLineComment:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.unterminatedMultiLineComment,
        );
        return;
      case PseudoSharedCode.unterminatedStringLiteral:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.unterminatedStringLiteral,
        );
        return;
      case PseudoSharedCode.wrongSeparatorForPositionalParameter:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.wrongSeparatorForPositionalParameter,
        );
        return;
      case PseudoSharedCode.yieldInNonGenerator:
        // Reported by [YieldStatementResolver._resolve_notGenerator]
        return;
      case PseudoSharedCode.builtInIdentifierInDeclaration:
        // Reported by [ErrorVerifier._checkForBuiltInIdentifierAsName].
        return;
      case PseudoSharedCode.privateOptionalParameter:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.privateOptionalParameter,
        );
        return;
      case PseudoSharedCode.privateNamedNonFieldParameter:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: diag.privateNamedNonFieldParameter,
        );
        return;
      case PseudoSharedCode.nonSyncAbstractMethod:
        // Not reported but followed by a MISSING_FUNCTION_BODY error.
        return;
      case PseudoSharedCode.abstractExtensionField:
        // Not reported but followed by a
        // CompileTimeErrorCode.EXTENSION_DECLARES_INSTANCE_FIELD.
        return;
      case PseudoSharedCode.extensionTypeWithAbstractMember:
        // Reported by [ErrorVerifier._checkForExtensionTypeWithAbstractMember].
        return;
      case PseudoSharedCode.extensionTypeDeclaresInstanceField:
        // Reported by
        // [ErrorVerifier._checkForExtensionTypeDeclaresInstanceField]
        return;
      case PseudoSharedCode.encoding:
      case PseudoSharedCode.unexpectedSeparatorInNumber:
      case PseudoSharedCode.unsupportedOperator:
        // This is handled by `translateErrorToken` in
        // `package:analyzer/src/dart/error/syntactic_errors.dart`.
        assert(false, 'Should be handled by translateErrorToken');
        return;
      case PseudoSharedCode.setOrMapLiteralTooManyTypeArguments:
        // Reported as EXPECTED_TWO_MAP_TYPE_ARGUMENTS in
        // [TypeArgumentsVerifier.checkMapLiteral].
        return;
      case PseudoSharedCode.assertAsExpression:
        // Reported as UNDEFINED_IDENTIFIER in
        // [SimpleIdentifierResolver._resolve1],
        // followed by an EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD error,
        // or followed by an EXPECTED_TOKEN error as seen in
        // `language/constructor/explicit_instantiation_syntax_test`
        // TODO(srawlins): See below
        // TODO(johnniwinther): How can we be sure that no other
        // cases exists?
        return;
      case PseudoSharedCode.fastaCliArgumentRequired:
      case PseudoSharedCode.internalProblemStackNotEmpty:
      case PseudoSharedCode.internalProblemUnhandled:
      case PseudoSharedCode.internalProblemUnsupported:
      case PseudoSharedCode.unspecified:
      case null:
        break;
    }
    assert(false, "Unreported message $pseudoSharedCode (${message.code}).");
  }

  /// Report an error based on the given [message] whose range is described by
  /// the given [offset] and [length].
  void reportMessage(Message message, int offset, int length) {
    Code code = message.code;
    if (code.sharedCode case var sharedCode?) {
      var errorCode = sharedAnalyzerCodes[sharedCode.index];
      diagnosticReporter!.reportError(
        Diagnostic.tmp(
          source: diagnosticReporter!.source,
          offset: offset,
          length: length,
          diagnosticCode: errorCode,
          arguments: message.arguments.values.toList(),
        ),
      );
      return;
    }
    reportByCode(code.pseudoSharedCode, offset, length, message);
  }

  void reportScannerError(
    DiagnosticCode errorCode,
    int offset,
    List<Object>? arguments,
  ) {
    // TODO(danrubel): update client to pass length in addition to offset.
    int length = 1;
    diagnosticReporter?.atOffset(
      diagnosticCode: errorCode,
      offset: offset,
      length: length,
      arguments: arguments ?? const [],
    );
  }

  void _reportByCode({
    required int offset,
    required int length,
    required DiagnosticCode code,
    required Message message,
  }) {
    if (diagnosticReporter != null) {
      diagnosticReporter!.reportError(
        Diagnostic.tmp(
          source: diagnosticReporter!.source,
          offset: offset,
          length: length,
          diagnosticCode: code,
          arguments: message.arguments.values.toList(),
        ),
      );
    }
  }
}
