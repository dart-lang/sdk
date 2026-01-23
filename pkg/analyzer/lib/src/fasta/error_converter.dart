// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/base/errors.dart';
import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show Code, Message, PseudoSharedCode;
import 'package:analyzer/dart/ast/token.dart' show Token;
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/diagnostic/diagnostic_code_values.dart';
import 'package:analyzer/src/error/listener.dart';

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
        diagnosticReporter?.report(
          diag.asyncForInWrongContext.atOffset(offset: offset, length: length),
        );
        return;
      case PseudoSharedCode.asyncKeywordUsedAsIdentifier:
        diagnosticReporter?.report(
          diag.asyncKeywordUsedAsIdentifier.atOffset(
            offset: offset,
            length: length,
          ),
        );
        return;
      case PseudoSharedCode.awaitInWrongContext:
        diagnosticReporter?.report(
          diag.awaitInWrongContext.atOffset(offset: offset, length: length),
        );
        return;
      case PseudoSharedCode.builtInIdentifierAsType:
        diagnosticReporter?.report(
          diag.builtInIdentifierAsType
              .withArguments(token: lexeme())
              .atOffset(offset: offset, length: length),
        );
        return;
      case PseudoSharedCode.constConstructorWithBody:
        diagnosticReporter?.report(
          diag.constConstructorWithBody.atOffset(
            offset: offset,
            length: length,
          ),
        );
        return;
      case PseudoSharedCode.constNotInitialized:
        var name = arguments['name'] as String;
        diagnosticReporter?.report(
          diag.constNotInitialized
              .withArguments(name: name)
              .atOffset(offset: offset, length: length),
        );
        return;
      case PseudoSharedCode.defaultValueInFunctionType:
        diagnosticReporter?.report(
          diag.defaultValueInFunctionType.atOffset(
            offset: offset,
            length: length,
          ),
        );
        return;
      case PseudoSharedCode.expectedClassMember:
        diagnosticReporter?.report(
          diag.expectedClassMember.atOffset(offset: offset, length: length),
        );
        return;
      case PseudoSharedCode.expectedExecutable:
        diagnosticReporter?.report(
          diag.expectedExecutable.atOffset(offset: offset, length: length),
        );
        return;
      case PseudoSharedCode.expectedStringLiteral:
        diagnosticReporter?.report(
          diag.expectedStringLiteral.atOffset(offset: offset, length: length),
        );
        return;
      case PseudoSharedCode.expectedToken:
        diagnosticReporter?.report(
          diag.expectedToken
              .withArguments(token: arguments['string'] as String)
              .atOffset(offset: offset, length: length),
        );
        return;
      case PseudoSharedCode.expectedTypeName:
        diagnosticReporter?.report(
          diag.expectedTypeName.atOffset(offset: offset, length: length),
        );
        return;
      case PseudoSharedCode.extensionDeclaresInstanceField:
        // Reported by
        // [ErrorVerifier._checkForExtensionDeclaresInstanceField]
        return;
      case PseudoSharedCode.finalNotInitialized:
        var name = arguments['name'] as String;
        diagnosticReporter?.report(
          diag.finalNotInitialized
              .withArguments(name: name)
              .atOffset(offset: offset, length: length),
        );
        return;
      case PseudoSharedCode.getterWithParameters:
        diagnosticReporter?.report(
          diag.getterWithParameters.atOffset(offset: offset, length: length),
        );
        return;
      case PseudoSharedCode.illegalCharacter:
        var codePoint = (arguments['unicode'] ?? arguments['character']) as int;
        diagnosticReporter?.report(
          diag.illegalCharacter
              .withArguments(codePoint: codePoint)
              .atOffset(offset: offset, length: length),
        );
        return;
      case PseudoSharedCode.invalidInlineFunctionType:
        diagnosticReporter?.report(
          diag.invalidInlineFunctionType.atOffset(
            offset: offset,
            length: length,
          ),
        );
        return;
      case PseudoSharedCode.invalidLiteralInConfiguration:
        diagnosticReporter?.report(
          diag.invalidLiteralInConfiguration.atOffset(
            offset: offset,
            length: length,
          ),
        );
        return;
      case PseudoSharedCode.invalidCodePoint:
        diagnosticReporter?.report(
          diag.invalidCodePoint
              .withArguments(escapeSequence: '\\u{...}')
              .atOffset(offset: offset, length: length),
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
        diagnosticReporter?.report(
          diag.missingDigit.atOffset(offset: offset, length: length),
        );
        return;
      case PseudoSharedCode.missingEnumBody:
        diagnosticReporter?.report(
          diag.missingEnumBody.atOffset(offset: offset, length: length),
        );
        return;
      case PseudoSharedCode.missingFunctionBody:
        diagnosticReporter?.report(
          diag.missingFunctionBody.atOffset(offset: offset, length: length),
        );
        return;
      case PseudoSharedCode.missingFunctionParameters:
        diagnosticReporter?.report(
          diag.missingFunctionParameters.atOffset(
            offset: offset,
            length: length,
          ),
        );
        return;
      case PseudoSharedCode.missingHexDigit:
        diagnosticReporter?.report(
          diag.missingHexDigit.atOffset(offset: offset, length: length),
        );
        return;
      case PseudoSharedCode.missingIdentifier:
        diagnosticReporter?.report(
          diag.missingIdentifier.atOffset(offset: offset, length: length),
        );
        return;
      case PseudoSharedCode.missingMethodParameters:
        diagnosticReporter?.report(
          diag.missingMethodParameters.atOffset(offset: offset, length: length),
        );
        return;
      case PseudoSharedCode.missingStarAfterSync:
        diagnosticReporter?.report(
          diag.missingStarAfterSync.atOffset(offset: offset, length: length),
        );
        return;
      case PseudoSharedCode.missingTypedefParameters:
        diagnosticReporter?.report(
          diag.missingTypedefParameters.atOffset(
            offset: offset,
            length: length,
          ),
        );
        return;
      case PseudoSharedCode.multipleImplementsClauses:
        diagnosticReporter?.report(
          diag.multipleImplementsClauses.atOffset(
            offset: offset,
            length: length,
          ),
        );
        return;
      case PseudoSharedCode.namedFunctionExpression:
        diagnosticReporter?.report(
          diag.namedFunctionExpression.atOffset(offset: offset, length: length),
        );
        return;
      case PseudoSharedCode.namedParameterOutsideGroup:
        diagnosticReporter?.report(
          diag.namedParameterOutsideGroup.atOffset(
            offset: offset,
            length: length,
          ),
        );
        return;
      case PseudoSharedCode.nonPartOfDirectiveInPart:
        diagnosticReporter?.report(
          diag.nonPartOfDirectiveInPart.atOffset(
            offset: offset,
            length: length,
          ),
        );
        return;
      case PseudoSharedCode.nonSyncFactory:
        diagnosticReporter?.report(
          diag.nonSyncFactory.atOffset(offset: offset, length: length),
        );
        return;
      case PseudoSharedCode.positionalAfterNamedArgument:
        diagnosticReporter?.report(
          diag.positionalAfterNamedArgument.atOffset(
            offset: offset,
            length: length,
          ),
        );
        return;
      case PseudoSharedCode.returnInGenerator:
        diagnosticReporter?.report(
          diag.returnInGenerator.atOffset(offset: offset, length: length),
        );
        return;
      case PseudoSharedCode.unexpectedDollarInString:
        diagnosticReporter?.report(
          diag.unexpectedDollarInString.atOffset(
            offset: offset,
            length: length,
          ),
        );
        return;
      case PseudoSharedCode.unexpectedToken:
        diagnosticReporter?.report(
          diag.unexpectedToken
              .withArguments(text: lexeme())
              .atOffset(offset: offset, length: length),
        );
        return;
      case PseudoSharedCode.unterminatedMultiLineComment:
        diagnosticReporter?.report(
          diag.unterminatedMultiLineComment.atOffset(
            offset: offset,
            length: length,
          ),
        );
        return;
      case PseudoSharedCode.unterminatedStringLiteral:
        diagnosticReporter?.report(
          diag.unterminatedStringLiteral.atOffset(
            offset: offset,
            length: length,
          ),
        );
        return;
      case PseudoSharedCode.wrongSeparatorForPositionalParameter:
        diagnosticReporter?.report(
          diag.wrongSeparatorForPositionalParameter.atOffset(
            offset: offset,
            length: length,
          ),
        );
        return;
      case PseudoSharedCode.yieldInNonGenerator:
        // Reported by [YieldStatementResolver._resolve_notGenerator]
        return;
      case PseudoSharedCode.builtInIdentifierInDeclaration:
        // Reported by [ErrorVerifier._checkForBuiltInIdentifierAsName].
        return;
      case PseudoSharedCode.privateOptionalParameter:
        diagnosticReporter?.report(
          diag.privateOptionalParameter.atOffset(
            offset: offset,
            length: length,
          ),
        );
        return;
      case PseudoSharedCode.privateNamedNonFieldParameter:
        diagnosticReporter?.report(
          diag.privateNamedNonFieldParameter.atOffset(
            offset: offset,
            length: length,
          ),
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
      var diagnosticCode = sharedAnalyzerCodes[sharedCode.index];
      diagnosticReporter!.reportError(
        Diagnostic.tmp(
          source: diagnosticReporter!.source,
          offset: offset,
          length: length,
          diagnosticCode: diagnosticCode,
          arguments: message.arguments.values.toList(),
        ),
      );
      return;
    }
    reportByCode(code.pseudoSharedCode, offset, length, message);
  }

  void reportScannerError(LocatedDiagnostic locatedDiagnostic) {
    diagnosticReporter?.report(locatedDiagnostic);
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
