// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/analyzer/token_utils.dart';
import 'package:front_end/src/fasta/scanner/error_token.dart' as fasta;
import 'package:front_end/src/fasta/scanner/keyword.dart' as fasta;
import 'package:front_end/src/fasta/scanner/string_scanner.dart' as fasta;
import 'package:front_end/src/fasta/scanner/token.dart' as fasta;
import 'package:front_end/src/fasta/scanner/token_constants.dart' as fasta;
import 'package:front_end/src/scanner/errors.dart';
import 'package:front_end/src/scanner/token.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'scanner_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ScannerTest_Fasta);
  });
}

@reflectiveTest
class ScannerTest_Fasta extends ScannerTestBase {
  @override
  Token scanWithListener(String source, ErrorListener listener,
      {bool genericMethodComments: false,
      bool lazyAssignmentOperators: false}) {
    if (genericMethodComments) {
      // Fasta doesn't support generic method comments.
      // TODO(paulberry): once the analyzer toolchain no longer needs generic
      // method comments, remove tests that exercise them.
      fail('No generic method comment support in Fasta');
    }
    // Note: Fasta always supports lazy assignment operators (`&&=` and `||=`),
    // so we can ignore the `lazyAssignmentOperators` flag.
    // TODO(paulberry): once lazyAssignmentOperators are fully supported by
    // Dart, remove this flag.
    var scanner = new fasta.StringScanner(source, includeComments: true);
    var token = scanner.tokenize();
    var analyzerTokenHead = new Token(null, 0);
    analyzerTokenHead.previous = analyzerTokenHead;
    var analyzerTokenTail = analyzerTokenHead;
    // TODO(paulberry,ahe): Fasta includes comments directly in the token
    // stream, rather than pointing to them via a "precedingComment" pointer, as
    // analyzer does.  This seems like it will complicate parsing and other
    // operations.
    CommentToken currentCommentHead;
    CommentToken currentCommentTail;
    while (true) {
      if (scanner.hasErrors && token is fasta.ErrorToken) {
        var error = _translateErrorToken(token, source.length);
        if (error != null) {
          listener.errors.add(error);
        }
      } else if (token is fasta.StringToken &&
          token.info.kind == fasta.COMMENT_TOKEN) {
        // TODO(paulberry,ahe): It would be nice if the scanner gave us an
        // easier way to distinguish between the two types of comment.
        var type = token.value.startsWith('/*')
            ? TokenType.MULTI_LINE_COMMENT
            : TokenType.SINGLE_LINE_COMMENT;
        var translatedToken =
            new CommentToken(type, token.value, token.charOffset);
        if (currentCommentHead == null) {
          currentCommentHead = currentCommentTail = translatedToken;
        } else {
          currentCommentTail.setNext(translatedToken);
          currentCommentTail = translatedToken;
        }
      } else {
        var translatedToken = toAnalyzerToken(token, currentCommentHead);
        translatedToken.setNext(translatedToken);
        currentCommentHead = currentCommentTail = null;
        analyzerTokenTail.setNext(translatedToken);
        translatedToken.previous = analyzerTokenTail;
        analyzerTokenTail = translatedToken;
      }
      if (token.isEof) {
        return analyzerTokenHead.next;
      }
      token = token.next;
    }
  }

  @override
  @failingTest
  void test_ampersand_ampersand_eq() {
    // TODO(paulberry,ahe): Fasta doesn't support `&&=` yet
    super.test_ampersand_ampersand_eq();
  }

  @override
  @failingTest
  void test_bar_bar_eq() {
    // TODO(paulberry,ahe): Fasta doesn't support `||=` yet
    super.test_bar_bar_eq();
  }

  @override
  @failingTest
  void test_comment_generic_method_type_assign() {
    // TODO(paulberry,ahe): Fasta doesn't support generic method comment syntax.
    super.test_comment_generic_method_type_assign();
  }

  @override
  @failingTest
  void test_comment_generic_method_type_list() {
    // TODO(paulberry,ahe): Fasta doesn't support generic method comment syntax.
    super.test_comment_generic_method_type_list();
  }

  @override
  @failingTest
  void test_index() {
    // TODO(paulberry,ahe): "[]" should be parsed as a single token.
    // See dartbug.com/28665.
    super.test_index();
  }

  @override
  @failingTest
  void test_index_eq() {
    // TODO(paulberry,ahe): "[]=" should be parsed as a single token.
    // See dartbug.com/28665.
    super.test_index_eq();
  }

  @override
  @failingTest
  void test_scriptTag_withArgs() {
    // TODO(paulberry,ahe): script tags are needed by analyzer.
    super.test_scriptTag_withArgs();
  }

  @override
  @failingTest
  void test_scriptTag_withoutSpace() {
    // TODO(paulberry,ahe): script tags are needed by analyzer.
    super.test_scriptTag_withoutSpace();
  }

  @override
  @failingTest
  void test_scriptTag_withSpace() {
    // TODO(paulberry,ahe): script tags are needed by analyzer.
    super.test_scriptTag_withSpace();
  }

  @override
  @failingTest
  void test_string_multi_unterminated() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_multi_unterminated();
  }

  @override
  @failingTest
  void test_string_multi_unterminated_interpolation_block() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_multi_unterminated_interpolation_block();
  }

  @override
  @failingTest
  void test_string_multi_unterminated_interpolation_identifier() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_multi_unterminated_interpolation_identifier();
  }

  @override
  @failingTest
  void test_string_raw_multi_unterminated() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_raw_multi_unterminated();
  }

  @override
  @failingTest
  void test_string_raw_simple_unterminated_eof() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_raw_simple_unterminated_eof();
  }

  @override
  @failingTest
  void test_string_raw_simple_unterminated_eol() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_raw_simple_unterminated_eol();
  }

  @override
  @failingTest
  void test_string_simple_unterminated_eof() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_simple_unterminated_eof();
  }

  @override
  @failingTest
  void test_string_simple_unterminated_eol() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_simple_unterminated_eol();
  }

  @override
  @failingTest
  void test_string_simple_unterminated_interpolation_block() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_simple_unterminated_interpolation_block();
  }

  @override
  @failingTest
  void test_string_simple_unterminated_interpolation_identifier() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_simple_unterminated_interpolation_identifier();
  }

  TestError _translateErrorToken(fasta.ErrorToken token, int inputLength) {
    int charOffset = token.charOffset;
    // TODO(paulberry,ahe): why is endOffset sometimes null?
    int endOffset = token.endOffset ?? charOffset;
    TestError _makeError(ScannerErrorCode errorCode, List<Object> arguments) {
      if (charOffset == inputLength) {
        // Analyzer never generates an error message past the end of the input,
        // since such an error would not be visible in an editor.
        // TODO(paulberry,ahe): would it make sense to replicate this behavior
        // in fasta, or move it elsewhere in analyzer?
        charOffset--;
      }
      return new TestError(charOffset, errorCode, arguments);
    }

    var errorCode = token.errorCode;
    switch (errorCode) {
      case fasta.ErrorKind.UnterminatedString:
        // TODO(paulberry,ahe): Fasta reports the error location as the entire
        // string; analyzer expects the end of the string.
        charOffset = endOffset;
        return _makeError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, null);
      case fasta.ErrorKind.UnmatchedToken:
        return null;
      case fasta.ErrorKind.UnterminatedComment:
        // TODO(paulberry,ahe): Fasta reports the error location as the entire
        // comment; analyzer expects the end of the comment.
        charOffset = endOffset;
        return _makeError(
            ScannerErrorCode.UNTERMINATED_MULTI_LINE_COMMENT, null);
      case fasta.ErrorKind.MissingExponent:
        // TODO(paulberry,ahe): Fasta reports the error location as the entire
        // number; analyzer expects the end of the number.
        charOffset = endOffset;
        return _makeError(ScannerErrorCode.MISSING_DIGIT, null);
      case fasta.ErrorKind.ExpectedHexDigit:
        // TODO(paulberry,ahe): Fasta reports the error location as the entire
        // number; analyzer expects the end of the number.
        charOffset = endOffset;
        return _makeError(ScannerErrorCode.MISSING_HEX_DIGIT, null);
      case fasta.ErrorKind.NonAsciiIdentifier:
      case fasta.ErrorKind.NonAsciiWhitespace:
        return _makeError(
            ScannerErrorCode.ILLEGAL_CHARACTER, [token.character]);
      case fasta.ErrorKind.UnexpectedDollarInString:
        return null;
      default:
        throw new UnimplementedError('$errorCode');
    }
  }
}
