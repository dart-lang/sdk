// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/base/errors.dart';
import 'package:_fe_analyzer_shared/src/messages/codes.dart';
import 'package:_fe_analyzer_shared/src/messages/diagnostic.dart' as fe_diag;
import 'package:_fe_analyzer_shared/src/messages/diagnostic.dart';
import 'package:_fe_analyzer_shared/src/scanner/error_token.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show Token, TokenType;
import 'package:_fe_analyzer_shared/src/scanner/token_constants.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;

/// Translates the given error [token] into an analyzer error and reports it
/// using [reportError].
void translateErrorToken(ErrorToken token, ReportError reportError) {
  int charOffset = token.charOffset;
  // TODO(paulberry): why is endOffset sometimes null?
  int endOffset = token.endOffset ?? charOffset;
  void makeError(LocatableDiagnostic locatableDiagnostic) {
    if (_isAtEnd(token, charOffset)) {
      // Analyzer never generates an error message past the end of the input,
      // since such an error would not be visible in an editor.
      // TODO(paulberry): would it make sense to replicate this behavior
      // in cfe, or move it elsewhere in analyzer?
      charOffset--;
    }
    reportError(locatableDiagnostic.atOffset(offset: charOffset, length: 1));
  }

  Code errorCode = token.errorCode;
  switch (errorCode.pseudoSharedCode) {
    case PseudoSharedCode.encoding:
      reportError(diag.encoding.atOffset(offset: charOffset, length: 1));
      return;

    case PseudoSharedCode.unterminatedStringLiteral:
      // TODO(paulberry): Fasta reports the error location as the entire
      // string; analyzer expects the end of the string.
      reportError(
        diag.unterminatedStringLiteral.atOffset(
          offset: endOffset - 1,
          length: 1,
        ),
      );
      return;

    case PseudoSharedCode.unterminatedMultiLineComment:
      // TODO(paulberry): Fasta reports the error location as the entire
      // comment; analyzer expects the end of the comment.
      reportError(
        diag.unterminatedMultiLineComment.atOffset(
          offset: endOffset - 1,
          length: 1,
        ),
      );
      return;

    case PseudoSharedCode.missingDigit:
      // TODO(paulberry): Fasta reports the error location as the entire
      // number; analyzer expects the end of the number.
      charOffset = endOffset - 1;
      return makeError(diag.missingDigit);

    case PseudoSharedCode.missingHexDigit:
      // TODO(paulberry): Fasta reports the error location as the entire
      // number; analyzer expects the end of the number.
      charOffset = endOffset - 1;
      return makeError(diag.missingHexDigit);

    case PseudoSharedCode.illegalCharacter:
      // We can safely assume `token.character` is non-`null` because this error
      // is only reported when there is a character associated with the token.
      return makeError(
        diag.illegalCharacter.withArguments(codePoint: token.character!),
      );

    case PseudoSharedCode.unexpectedSeparatorInNumber:
      return makeError(diag.unexpectedSeparatorInNumber);

    case PseudoSharedCode.unsupportedOperator:
      return makeError(
        diag.unsupportedOperator.withArguments(
          lexeme: (token as UnsupportedOperator).token.lexeme,
        ),
      );

    default:
      if (errorCode == fe_diag.unmatchedToken) {
        charOffset = token.begin!.endToken!.charOffset;
        TokenType type = token.begin!.type;
        if (type == TokenType.OPEN_CURLY_BRACKET ||
            type == TokenType.STRING_INTERPOLATION_EXPRESSION) {
          return makeError(diag.expectedToken.withArguments(token: '}'));
        }
        if (type == TokenType.OPEN_SQUARE_BRACKET) {
          return makeError(diag.expectedToken.withArguments(token: ']'));
        }
        if (type == TokenType.OPEN_PAREN) {
          return makeError(diag.expectedToken.withArguments(token: ')'));
        }
        if (type == TokenType.LT) {
          return makeError(diag.expectedToken.withArguments(token: '>'));
        }
      } else if (errorCode == fe_diag.unexpectedDollarInString) {
        return makeError(diag.missingIdentifier);
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

/// Used to report a scan error.
/// The [locatedDiagnostic] contains the error code, arguments, and the location
/// of the error.
typedef ReportError = void Function(LocatedDiagnostic locatedDiagnostic);
