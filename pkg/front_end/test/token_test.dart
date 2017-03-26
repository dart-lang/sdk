// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/scanner/string_scanner.dart';
import 'package:front_end/src/fasta/scanner/keyword.dart' as fasta;
import 'package:front_end/src/fasta/scanner/token.dart' as fasta;
import 'package:front_end/src/scanner/token.dart';
import 'package:front_end/src/scanner/reader.dart' as analyzer;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'scanner_roundtrip_test.dart' show TestScanner;

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TokenTest);
  });
}

/// Assert that fasta PrecedenceInfo implements analyzer TokenType.
@reflectiveTest
class TokenTest {
  void test_applyDelta() {
    var scanner = new StringScanner('/* 1 */ foo', includeComments: true);
    var token = scanner.tokenize();
    expect(token.offset, 8);
    expect(token.precedingComments.offset, 0);
    token.applyDelta(12);
    expect(token.offset, 20);
    expect(token.precedingComments.offset, 12);
  }

  void test_comments() {
    var source = '''
/// Single line dartdoc comment
class Foo {
  /**
   * Multi-line dartdoc comment
   */
  void bar() {
    // Single line comment
    int x = 0;
    /* Multi-line comment */
    x = x + 1;
  }
}
''';
    var scanner = new StringScanner(source, includeComments: true);
    fasta.Token token = scanner.tokenize();

    Token nextComment() {
      while (!token.isEof) {
        Token comment = token.precedingComments;
        token = token.next;
        if (comment != null) return comment;
      }
      return null;
    }

    fasta.Token comment = nextComment();
    expect(comment.lexeme, contains('Single line dartdoc comment'));
    expect(comment.type, TokenType.SINGLE_LINE_COMMENT);
    expect(comment, new isInstanceOf<DocumentationCommentToken>());

    comment = nextComment();
    expect(comment.lexeme, contains('Multi-line dartdoc comment'));
    expect(comment.type, TokenType.MULTI_LINE_COMMENT);
    expect(comment, new isInstanceOf<DocumentationCommentToken>());

    comment = nextComment();
    expect(comment.lexeme, contains('Single line comment'));
    expect(comment.type, TokenType.SINGLE_LINE_COMMENT);
    expect(comment, new isInstanceOf<CommentToken>());

    comment = nextComment();
    expect(comment.lexeme, contains('Multi-line comment'));
    expect(comment.type, TokenType.MULTI_LINE_COMMENT);
    expect(comment, new isInstanceOf<CommentToken>());
  }

  void test_copy() {
    String source = '/* 1 */ /* 2 */ main() {print("hello"); return;}';
    int commentCount = 0;

    void assertCopiedToken(Token token1, Token token2) {
      if (token1 == null) {
        expect(token2, isNull);
        return;
      }
      expect(token1.lexeme, token2.lexeme);
      expect(token1.offset, token2.offset, reason: token1.lexeme);
      var comment1 = token1.precedingComments;
      var comment2 = token2.precedingComments;
      while (comment1 != null) {
        ++commentCount;
        assertCopiedToken(comment1, comment2);
        comment1 = comment1.next;
        comment2 = comment2.next;
      }
      expect(comment2, isNull, reason: comment2?.lexeme);
    }

    var token1 = new StringScanner(source, includeComments: true).tokenize();
    var analyzerScanner =
        new TestScanner(new analyzer.CharSequenceReader(source));
    analyzerScanner.preserveComments = true;
    var token2 = analyzerScanner.tokenize();

    bool stringTokenFound = false;
    bool keywordTokenFound = false;
    bool symbolTokenFound = false;
    bool beginGroupTokenFound = false;

    while (!token1.isEof) {
      if (token1 is fasta.StringToken) stringTokenFound = true;
      if (token1 is fasta.KeywordToken) keywordTokenFound = true;
      if (token1 is fasta.SymbolToken) symbolTokenFound = true;
      if (token1 is fasta.BeginGroupToken) beginGroupTokenFound = true;

      var copy1 = token1.copy();
      expect(copy1, isNotNull);

      var copy2 = token2.copy();
      expect(copy2, isNotNull);

      assertCopiedToken(copy1, copy2);

      token1 = token1.next;
      token2 = token2.next;
    }
    expect(token2.type, TokenType.EOF);

    expect(commentCount, 2);
    expect(stringTokenFound, isTrue);
    expect(keywordTokenFound, isTrue);
    expect(symbolTokenFound, isTrue);
    expect(beginGroupTokenFound, isTrue);
  }

  void test_isSynthetic() {
    var scanner = new StringScanner('/* 1 */ foo', includeComments: true);
    var token = scanner.tokenize();
    expect(token.isSynthetic, false);
    expect(token.precedingComments.isSynthetic, false);
    expect(token.previous.isSynthetic, true);
    expect(token.next.isEof, true);
    expect(token.next.isSynthetic, true);
  }

  void test_matchesAny() {
    var scanner = new StringScanner('true', includeComments: true);
    var token = scanner.tokenize();
    expect(token.matchesAny([TokenType.KEYWORD]), true);
    expect(token.matchesAny([TokenType.AMPERSAND, TokenType.KEYWORD]), true);
    expect(token.matchesAny([TokenType.AMPERSAND]), false);
  }

  /// Return all fasta and all analyzer keywords
  List<Keyword> get _allKeywords =>
      new List.from(Keyword.values)..addAll(fasta.Keyword.values);

  void test_built_in_keywords() {
    var builtInKeywords = new Set<Keyword>.from([
      Keyword.ABSTRACT,
      Keyword.AS,
      Keyword.COVARIANT,
      Keyword.DEFERRED,
      Keyword.DYNAMIC,
      Keyword.EXPORT,
      Keyword.EXTERNAL,
      Keyword.FACTORY,
      Keyword.GET,
      Keyword.IMPLEMENTS,
      Keyword.IMPORT,
      Keyword.LIBRARY,
      Keyword.OPERATOR,
      Keyword.PART,
      Keyword.SET,
      Keyword.STATIC,
      Keyword.TYPEDEF,
    ]);
    for (Keyword keyword in _allKeywords) {
      var isBuiltIn = builtInKeywords.contains(keyword);
      expect(keyword.isPseudoKeyword, isBuiltIn, reason: keyword.name);
      expect((keyword as fasta.Keyword).isBuiltIn, isBuiltIn,
          reason: keyword.name);
    }
  }

  void test_pseudo_keywords() {
    var pseudoKeywords = new Set<Keyword>.from([
      fasta.Keyword.ASYNC,
      fasta.Keyword.AWAIT,
      fasta.Keyword.FUNCTION,
      fasta.Keyword.HIDE,
      fasta.Keyword.NATIVE,
      fasta.Keyword.OF,
      fasta.Keyword.ON,
      fasta.Keyword.PATCH,
      fasta.Keyword.SHOW,
      fasta.Keyword.SOURCE,
      fasta.Keyword.SYNC,
      fasta.Keyword.YIELD,
    ]);
    for (Keyword keyword in _allKeywords) {
      var isPseudo = pseudoKeywords.contains(keyword);
      expect((keyword as fasta.Keyword).isPseudo, isPseudo,
          reason: keyword.name);
    }
  }

  void test_value() {
    var scanner = new StringScanner('true & "home"', includeComments: true);
    var token = scanner.tokenize();
    // Keywords
    expect(token.lexeme, 'true');
    expect(token.value(), Keyword.TRUE);
    // General tokens
    token = token.next;
    expect(token.lexeme, '&');
    expect(token.value(), '&');
    // String tokens
    token = token.next;
    expect(token.lexeme, '"home"');
    expect(token.value(), '"home"');
  }
}
