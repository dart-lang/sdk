// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show
        Code,
        Message,
        codeAssertAsExpression,
        codeSetOrMapLiteralTooManyTypeArguments,
        AnalyzerCode;
import 'package:analyzer/dart/ast/token.dart' show Token;
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';

/// An error reporter that knows how to convert a Fasta error into an analyzer
/// error.
class FastaErrorReporter {
  /// The underlying diagnostic reporter to which diagnostics are reported.
  final DiagnosticReporter? diagnosticReporter;

  /// Initialize a newly created error reporter to report diagnostics to the
  /// given [diagnosticReporter].
  FastaErrorReporter(this.diagnosticReporter);

  void reportByCode(
    AnalyzerCode? analyzerCode,
    int offset,
    int length,
    Message message,
  ) {
    Map<String, dynamic> arguments = message.arguments;

    String lexeme() => (arguments['lexeme'] as Token).lexeme;

    switch (analyzerCode) {
      case AnalyzerCode.asyncForInWrongContext:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.asyncForInWrongContext,
        );
        return;
      case AnalyzerCode.asyncKeywordUsedAsIdentifier:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.asyncKeywordUsedAsIdentifier,
        );
        return;
      case AnalyzerCode.awaitInWrongContext:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.awaitInWrongContext,
        );
        return;
      case AnalyzerCode.builtInIdentifierAsType:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.builtInIdentifierAsType,
          arguments: [lexeme()],
        );
        return;
      case AnalyzerCode.constConstructorWithBody:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.constConstructorWithBody,
        );
        return;
      case AnalyzerCode.constNotInitialized:
        var name = arguments['name'] as String;
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.constNotInitialized,
          arguments: [name],
        );
        return;
      case AnalyzerCode.defaultValueInFunctionType:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.defaultValueInFunctionType,
        );
        return;
      case AnalyzerCode.expectedClassMember:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.expectedClassMember,
        );
        return;
      case AnalyzerCode.expectedExecutable:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.expectedExecutable,
        );
        return;
      case AnalyzerCode.expectedStringLiteral:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.expectedStringLiteral,
        );
        return;
      case AnalyzerCode.expectedToken:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.expectedToken,
          arguments: [arguments['string'] as Object],
        );
        return;
      case AnalyzerCode.expectedTypeName:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.expectedTypeName,
        );
        return;
      case AnalyzerCode.extensionDeclaresInstanceField:
        // Reported by
        // [ErrorVerifier._checkForExtensionDeclaresInstanceField]
        return;
      case AnalyzerCode.finalNotInitialized:
        var name = arguments['name'] as String;
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.finalNotInitialized,
          arguments: [name],
        );
        return;
      case AnalyzerCode.getterWithParameters:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.getterWithParameters,
        );
        return;
      case AnalyzerCode.illegalCharacter:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ScannerErrorCode.illegalCharacter,
        );
        return;
      case AnalyzerCode.invalidInlineFunctionType:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.invalidInlineFunctionType,
        );
        return;
      case AnalyzerCode.invalidLiteralInConfiguration:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.invalidLiteralInConfiguration,
        );
        return;
      case AnalyzerCode.invalidCodePoint:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.invalidCodePoint,
          arguments: ['\\u{...}'],
        );
        return;
      case AnalyzerCode.invalidModifierOnSetter:
        _reportByCode(
          offset: offset,
          length: length,
          code: CompileTimeErrorCode.invalidModifierOnSetter,
          message: message,
        );
        return;
      case AnalyzerCode.missingDigit:
        diagnosticReporter?.atOffset(
          diagnosticCode: ScannerErrorCode.missingDigit,
          offset: offset,
          length: length,
        );
        return;
      case AnalyzerCode.missingEnumBody:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.missingEnumBody,
        );
        return;
      case AnalyzerCode.missingFunctionBody:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.missingFunctionBody,
        );
        return;
      case AnalyzerCode.missingFunctionParameters:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.missingFunctionParameters,
        );
        return;
      case AnalyzerCode.missingHexDigit:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ScannerErrorCode.missingHexDigit,
        );
        return;
      case AnalyzerCode.missingIdentifier:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.missingIdentifier,
        );
        return;
      case AnalyzerCode.missingMethodParameters:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.missingMethodParameters,
        );
        return;
      case AnalyzerCode.missingStarAfterSync:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.missingStarAfterSync,
        );
        return;
      case AnalyzerCode.missingTypedefParameters:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.missingTypedefParameters,
        );
        return;
      case AnalyzerCode.multipleImplementsClauses:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.multipleImplementsClauses,
        );
        return;
      case AnalyzerCode.namedFunctionExpression:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.namedFunctionExpression,
        );
        return;
      case AnalyzerCode.namedParameterOutsideGroup:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.namedParameterOutsideGroup,
        );
        return;
      case AnalyzerCode.nonPartOfDirectiveInPart:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.nonPartOfDirectiveInPart,
        );
        return;
      case AnalyzerCode.nonSyncFactory:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.nonSyncFactory,
        );
        return;
      case AnalyzerCode.positionalAfterNamedArgument:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.positionalAfterNamedArgument,
        );
        return;
      case AnalyzerCode.returnInGenerator:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.returnInGenerator,
        );
        return;
      case AnalyzerCode.unexpectedDollarInString:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ScannerErrorCode.unexpectedDollarInString,
        );
        return;
      case AnalyzerCode.unexpectedToken:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.unexpectedToken,
          arguments: [lexeme()],
        );
        return;
      case AnalyzerCode.unterminatedMultiLineComment:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ScannerErrorCode.unterminatedMultiLineComment,
        );
        return;
      case AnalyzerCode.unterminatedStringLiteral:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ScannerErrorCode.unterminatedStringLiteral,
        );
        return;
      case AnalyzerCode.wrongSeparatorForPositionalParameter:
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.wrongSeparatorForPositionalParameter,
        );
        return;
      case AnalyzerCode.yieldInNonGenerator:
        // Reported by [YieldStatementResolver._resolve_notGenerator]
        return;
      case AnalyzerCode.builtInIdentifierInDeclaration:
        // Reported by [ErrorVerifier._checkForBuiltInIdentifierAsName].
        return;
      case AnalyzerCode.privateOptionalParameter:
        // Reported by [ErrorVerifier._checkForPrivateOptionalParameter].
        return;
      case AnalyzerCode.nonSyncAbstractMethod:
        // Not reported but followed by a MISSING_FUNCTION_BODY error.
        return;
      case AnalyzerCode.abstractExtensionField:
        // Not reported but followed by a
        // CompileTimeErrorCode.EXTENSION_DECLARES_INSTANCE_FIELD.
        return;
      case AnalyzerCode.extensionTypeWithAbstractMember:
        // Reported by [ErrorVerifier._checkForExtensionTypeWithAbstractMember].
        return;
      case AnalyzerCode.extensionTypeDeclaresInstanceField:
        // Reported by
        // [ErrorVerifier._checkForExtensionTypeDeclaresInstanceField]
        return;
      case AnalyzerCode.unexpectedSeparatorInNumber:
      case AnalyzerCode.unsupportedOperator:
        // This is handled by `translateErrorToken` in
        // `package:_fe_analyzer_shared/src/scanner/errors.dart`.
        assert(false, 'Should be handled by translateErrorToken');
        return;
      case null:
        switch (message.code) {
          case codeAssertAsExpression:
            // Reported as UNDEFINED_IDENTIFIER in
            // [SimpleIdentifierResolver._resolve1],
            // followed by an EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD error,
            // or followed by an EXPECTED_TOKEN error as seen in
            // `language/constructor/explicit_instantiation_syntax_test`
            // TODO(srawlins): See below
            // TODO(johnniwinther): How can we be sure that no other
            // cases exists?
            return;
          case codeSetOrMapLiteralTooManyTypeArguments:
            // Reported as EXPECTED_TWO_MAP_TYPE_ARGUMENTS in
            // [TypeArgumentsVerifier.checkMapLiteral].
            return;
          default:
        }
    }
    assert(false, "Unreported message $analyzerCode.");
  }

  /// Report an error based on the given [message] whose range is described by
  /// the given [offset] and [length].
  void reportMessage(Message message, int offset, int length) {
    Code code = message.code;
    int index = code.index;
    if (index > 0 && index < fastaAnalyzerErrorCodes.length) {
      var errorCode = fastaAnalyzerErrorCodes[index];
      if (errorCode != null) {
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
    }
    reportByCode(code.analyzerCodes?.first, offset, length, message);
  }

  void reportScannerError(
    ScannerErrorCode errorCode,
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
