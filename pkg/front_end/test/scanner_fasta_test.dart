// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  final _keywordMap = {
    "assert": Keyword.ASSERT,
    "break": Keyword.BREAK,
    "case": Keyword.CASE,
    "catch": Keyword.CATCH,
    "class": Keyword.CLASS,
    "const": Keyword.CONST,
    "continue": Keyword.CONTINUE,
    "default": Keyword.DEFAULT,
    "do": Keyword.DO,
    "else": Keyword.ELSE,
    "enum": Keyword.ENUM,
    "extends": Keyword.EXTENDS,
    "false": Keyword.FALSE,
    "final": Keyword.FINAL,
    "finally": Keyword.FINALLY,
    "for": Keyword.FOR,
    "if": Keyword.IF,
    "in": Keyword.IN,
    "new": Keyword.NEW,
    "null": Keyword.NULL,
    "rethrow": Keyword.RETHROW,
    "return": Keyword.RETURN,
    "super": Keyword.SUPER,
    "switch": Keyword.SWITCH,
    "this": Keyword.THIS,
    "throw": Keyword.THROW,
    "true": Keyword.TRUE,
    "try": Keyword.TRY,
    "var": Keyword.VAR,
    "void": Keyword.VOID,
    "while": Keyword.WHILE,
    "with": Keyword.WITH,
    "is": Keyword.IS,
    "abstract": Keyword.ABSTRACT,
    "as": Keyword.AS,
    "covariant": Keyword.COVARIANT,
    "dynamic": Keyword.DYNAMIC,
    "export": Keyword.EXPORT,
    "external": Keyword.EXTERNAL,
    "factory": Keyword.FACTORY,
    "get": Keyword.GET,
    "implements": Keyword.IMPLEMENTS,
    "import": Keyword.IMPORT,
    "library": Keyword.LIBRARY,
    "operator": Keyword.OPERATOR,
    "part": Keyword.PART,
    "set": Keyword.SET,
    "static": Keyword.STATIC,
    "typedef": Keyword.TYPEDEF,
    "deferred": Keyword.DEFERRED,
  };

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
        var translatedToken = _translateToken(token, currentCommentHead);
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
    super.test_index();
  }

  @override
  @failingTest
  void test_index_eq() {
    // TODO(paulberry,ahe): "[]=" should be parsed as a single token.
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
      int errorLength = endOffset - charOffset;
      if (charOffset == inputLength) {
        // Analyzer never generates an error message past the end of the input,
        // since such an error would not be visible in an editor.
        // TODO(paulberry,ahe): would it make sense to replicate this behavior
        // in fasta, or move it elsewhere in analyzer?
        charOffset--;
      }
      if (errorLength == 0) {
        // Analyzer never generates an error message of length zero,
        // since such an error would not be visible in an editor.
        // TODO(paulberry,ahe): would it make sense to replicate this behavior
        // in fasta, or move it elsewhere in analyzer?
        errorLength = 1;
      }
      return new TestError(charOffset, errorLength, errorCode, arguments);
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

  Keyword _translateKeyword(String syntax) =>
      _keywordMap[syntax] ?? (throw new UnimplementedError('$syntax'));

  Token _translateToken(fasta.Token token, CommentToken comment) {
    var type = _translateTokenInfoKind(token.info.kind);
    int offset = token.charOffset;
    Token makeStringToken(String value) {
      if (comment == null) {
        return new StringToken(type, value, offset);
      } else {
        return new StringTokenWithComment(type, value, offset, comment);
      }
    }

    Token makeKeywordToken(Keyword keyword) {
      if (comment == null) {
        return new KeywordToken(keyword, offset);
      } else {
        return new KeywordTokenWithComment(keyword, offset, comment);
      }
    }

    Token makeBeginToken() {
      if (comment == null) {
        return new BeginToken(type, offset);
      } else {
        return new BeginTokenWithComment(type, offset, comment);
      }
    }

    if (token is fasta.StringToken) {
      return makeStringToken(token.value);
    } else if (token is fasta.KeywordToken) {
      return makeKeywordToken(_translateKeyword(token.keyword.syntax));
    } else if (token is fasta.SymbolToken) {
      if (token is fasta.BeginGroupToken) {
        if (type == TokenType.LT) {
          return makeStringToken(token.value);
        } else {
          return makeBeginToken();
        }
      } else {
        return makeStringToken(token.value);
      }
    }
    throw new UnimplementedError('${token.runtimeType}');
  }

  TokenType _translateTokenInfoKind(int kind) {
    switch (kind) {
      case fasta.EOF_TOKEN:
        return TokenType.EOF;
      case fasta.KEYWORD_TOKEN:
        return TokenType.KEYWORD;
      case fasta.IDENTIFIER_TOKEN:
        return TokenType.IDENTIFIER;
      case fasta.BAD_INPUT_TOKEN:
        return TokenType.STRING;
      case fasta.DOUBLE_TOKEN:
        return TokenType.DOUBLE;
      case fasta.INT_TOKEN:
        return TokenType.INT;
      case fasta.HEXADECIMAL_TOKEN:
        return TokenType.HEXADECIMAL;
      case fasta.STRING_TOKEN:
        return TokenType.STRING;
      case fasta.AMPERSAND_TOKEN:
        return TokenType.AMPERSAND;
      case fasta.BACKPING_TOKEN:
        return TokenType.BACKPING;
      case fasta.BACKSLASH_TOKEN:
        return TokenType.BACKSLASH;
      case fasta.BANG_TOKEN:
        return TokenType.BANG;
      case fasta.BAR_TOKEN:
        return TokenType.BAR;
      case fasta.COLON_TOKEN:
        return TokenType.COLON;
      case fasta.COMMA_TOKEN:
        return TokenType.COMMA;
      case fasta.EQ_TOKEN:
        return TokenType.EQ;
      case fasta.GT_TOKEN:
        return TokenType.GT;
      case fasta.HASH_TOKEN:
        return TokenType.HASH;
      case fasta.OPEN_CURLY_BRACKET_TOKEN:
        return TokenType.OPEN_CURLY_BRACKET;
      case fasta.OPEN_SQUARE_BRACKET_TOKEN:
        return TokenType.OPEN_SQUARE_BRACKET;
      case fasta.OPEN_PAREN_TOKEN:
        return TokenType.OPEN_PAREN;
      case fasta.LT_TOKEN:
        return TokenType.LT;
      case fasta.MINUS_TOKEN:
        return TokenType.MINUS;
      case fasta.PERIOD_TOKEN:
        return TokenType.PERIOD;
      case fasta.PLUS_TOKEN:
        return TokenType.PLUS;
      case fasta.QUESTION_TOKEN:
        return TokenType.QUESTION;
      case fasta.AT_TOKEN:
        return TokenType.AT;
      case fasta.CLOSE_CURLY_BRACKET_TOKEN:
        return TokenType.CLOSE_CURLY_BRACKET;
      case fasta.CLOSE_SQUARE_BRACKET_TOKEN:
        return TokenType.CLOSE_SQUARE_BRACKET;
      case fasta.CLOSE_PAREN_TOKEN:
        return TokenType.CLOSE_PAREN;
      case fasta.SEMICOLON_TOKEN:
        return TokenType.SEMICOLON;
      case fasta.SLASH_TOKEN:
        return TokenType.SLASH;
      case fasta.TILDE_TOKEN:
        return TokenType.TILDE;
      case fasta.STAR_TOKEN:
        return TokenType.STAR;
      case fasta.PERCENT_TOKEN:
        return TokenType.PERCENT;
      case fasta.CARET_TOKEN:
        return TokenType.CARET;
      case fasta.STRING_INTERPOLATION_TOKEN:
        return TokenType.STRING_INTERPOLATION_EXPRESSION;
      case fasta.LT_EQ_TOKEN:
        return TokenType.LT_EQ;
      case fasta.FUNCTION_TOKEN:
        return TokenType.FUNCTION;
      case fasta.SLASH_EQ_TOKEN:
        return TokenType.SLASH_EQ;
      case fasta.PERIOD_PERIOD_PERIOD_TOKEN:
        return TokenType.PERIOD_PERIOD_PERIOD;
      case fasta.PERIOD_PERIOD_TOKEN:
        return TokenType.PERIOD_PERIOD;
      case fasta.EQ_EQ_EQ_TOKEN:
        // TODO(paulberry,ahe): what is this?
        throw new UnimplementedError();
      case fasta.EQ_EQ_TOKEN:
        return TokenType.EQ_EQ;
      case fasta.LT_LT_EQ_TOKEN:
        return TokenType.LT_LT_EQ;
      case fasta.LT_LT_TOKEN:
        return TokenType.LT_LT;
      case fasta.GT_EQ_TOKEN:
        return TokenType.GT_EQ;
      case fasta.GT_GT_EQ_TOKEN:
        return TokenType.GT_GT_EQ;
      case fasta.INDEX_EQ_TOKEN:
        return TokenType.INDEX_EQ;
      case fasta.INDEX_TOKEN:
        return TokenType.INDEX;
      case fasta.BANG_EQ_EQ_TOKEN:
        // TODO(paulberry,ahe): what is this?
        throw new UnimplementedError();
      case fasta.BANG_EQ_TOKEN:
        return TokenType.BANG_EQ;
      case fasta.AMPERSAND_AMPERSAND_TOKEN:
        return TokenType.AMPERSAND_AMPERSAND;
      case fasta.AMPERSAND_EQ_TOKEN:
        return TokenType.AMPERSAND_EQ;
      case fasta.BAR_BAR_TOKEN:
        return TokenType.BAR_BAR;
      case fasta.BAR_EQ_TOKEN:
        return TokenType.BAR_EQ;
      case fasta.STAR_EQ_TOKEN:
        return TokenType.STAR_EQ;
      case fasta.PLUS_PLUS_TOKEN:
        return TokenType.PLUS_PLUS;
      case fasta.PLUS_EQ_TOKEN:
        return TokenType.PLUS_EQ;
      case fasta.MINUS_MINUS_TOKEN:
        return TokenType.MINUS_MINUS;
      case fasta.MINUS_EQ_TOKEN:
        return TokenType.MINUS_EQ;
      case fasta.TILDE_SLASH_EQ_TOKEN:
        return TokenType.TILDE_SLASH_EQ;
      case fasta.TILDE_SLASH_TOKEN:
        return TokenType.TILDE_SLASH;
      case fasta.PERCENT_EQ_TOKEN:
        return TokenType.PERCENT_EQ;
      case fasta.GT_GT_TOKEN:
        return TokenType.GT_GT;
      case fasta.CARET_EQ_TOKEN:
        return TokenType.CARET_EQ;
      case fasta.STRING_INTERPOLATION_IDENTIFIER_TOKEN:
        return TokenType.STRING_INTERPOLATION_IDENTIFIER;
      case fasta.QUESTION_PERIOD_TOKEN:
        return TokenType.QUESTION_PERIOD;
      case fasta.QUESTION_QUESTION_TOKEN:
        return TokenType.QUESTION_QUESTION;
      case fasta.QUESTION_QUESTION_EQ_TOKEN:
        return TokenType.QUESTION_QUESTION_EQ;
      default:
        throw new UnimplementedError('$kind');
    }
  }
}
