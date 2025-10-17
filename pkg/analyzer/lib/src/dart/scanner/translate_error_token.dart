// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/codes.dart';
import 'package:_fe_analyzer_shared/src/scanner/error_token.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show Token, TokenType;
import 'package:_fe_analyzer_shared/src/scanner/token_constants.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';

/// Translates the given error [token] into an analyzer error and reports it
/// using [reportError].
void translateErrorToken(ErrorToken token, ReportError reportError) {
  int charOffset = token.charOffset;
  // TODO(paulberry): why is endOffset sometimes null?
  int endOffset = token.endOffset ?? charOffset;
  void makeError(DiagnosticCode errorCode, List<Object>? arguments) {
    if (_isAtEnd(token, charOffset)) {
      // Analyzer never generates an error message past the end of the input,
      // since such an error would not be visible in an editor.
      // TODO(paulberry): would it make sense to replicate this behavior
      // in cfe, or move it elsewhere in analyzer?
      charOffset--;
    }
    reportError(errorCode, charOffset, arguments);
  }

  Code errorCode = token.errorCode;
  switch (errorCode.pseudoSharedCode) {
    case PseudoSharedCode.encoding:
      reportError(ScannerErrorCode.encoding, charOffset, null);
      return;

    case PseudoSharedCode.unterminatedStringLiteral:
      // TODO(paulberry): Fasta reports the error location as the entire
      // string; analyzer expects the end of the string.
      reportError(
        ScannerErrorCode.unterminatedStringLiteral,
        endOffset - 1,
        null,
      );
      return;

    case PseudoSharedCode.unterminatedMultiLineComment:
      // TODO(paulberry): Fasta reports the error location as the entire
      // comment; analyzer expects the end of the comment.
      reportError(
        ScannerErrorCode.unterminatedMultiLineComment,
        endOffset - 1,
        null,
      );
      return;

    case PseudoSharedCode.missingDigit:
      // TODO(paulberry): Fasta reports the error location as the entire
      // number; analyzer expects the end of the number.
      charOffset = endOffset - 1;
      return makeError(ScannerErrorCode.missingDigit, null);

    case PseudoSharedCode.missingHexDigit:
      // TODO(paulberry): Fasta reports the error location as the entire
      // number; analyzer expects the end of the number.
      charOffset = endOffset - 1;
      return makeError(ScannerErrorCode.missingHexDigit, null);

    case PseudoSharedCode.illegalCharacter:
      // We can safely assume `token.character` is non-`null` because this error
      // is only reported when there is a character associated with the token.
      return makeError(ScannerErrorCode.illegalCharacter, [token.character!]);

    case PseudoSharedCode.unexpectedSeparatorInNumber:
      return makeError(ScannerErrorCode.unexpectedSeparatorInNumber, null);

    case PseudoSharedCode.unsupportedOperator:
      return makeError(ScannerErrorCode.unsupportedOperator, [
        (token as UnsupportedOperator).token.lexeme,
      ]);

    default:
      if (errorCode == codeUnmatchedToken) {
        charOffset = token.begin!.endToken!.charOffset;
        TokenType type = token.begin!.type;
        if (type == TokenType.OPEN_CURLY_BRACKET ||
            type == TokenType.STRING_INTERPOLATION_EXPRESSION) {
          return makeError(ParserErrorCode.expectedToken, ['}']);
        }
        if (type == TokenType.OPEN_SQUARE_BRACKET) {
          return makeError(ParserErrorCode.expectedToken, [']']);
        }
        if (type == TokenType.OPEN_PAREN) {
          return makeError(ParserErrorCode.expectedToken, [')']);
        }
        if (type == TokenType.LT) {
          return makeError(ParserErrorCode.expectedToken, ['>']);
        }
      } else if (errorCode == codeUnexpectedDollarInString) {
        return makeError(ParserErrorCode.missingIdentifier, null);
      }
      throw UnimplementedError('$errorCode "${errorCode.pseudoSharedCode}"');
  }
}

/// Determines whether the given [charOffset], which came from the non-EOF token
/// [token], represents the end of the input.
bool _isAtEnd(Token token, int charOffset) {
  while (true) {
    // Skip to the next token.
    token = token.next!;
    // If we've found an EOF token, its charOffset indicates where the end of
    // the input is.
    if (token.isEof) return token.charOffset == charOffset;
    // If we've found a non-error token, then we know there is additional input
    // text after [charOffset].
    if (token.type.kind != BAD_INPUT_TOKEN) return false;
    // Otherwise keep looking.
  }
}

/// Used to report a scan error at the given offset.
/// The [errorCode] is the error code indicating the nature of the error.
/// The [arguments] are any arguments needed to complete the error message.
typedef ReportError =
    void Function(
      DiagnosticCode errorCode,
      int offset,
      List<Object>? arguments,
    );
