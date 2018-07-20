// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/scanner/string_scanner.dart';
import 'package:front_end/src/scanner/token.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TokenTest);
  });
}

/// Assert that fasta PrecedenceInfo implements analyzer TokenType.
@reflectiveTest
class TokenTest {
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
    Token token = scanner.tokenize();

    Token nextComment() {
      while (!token.isEof) {
        Token comment = token.precedingComments;
        token = token.next;
        if (comment != null) return comment;
      }
      return null;
    }

    Token comment = nextComment();
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
    expect(token.matchesAny([Keyword.TRUE]), true);
    expect(token.matchesAny([TokenType.AMPERSAND, Keyword.TRUE]), true);
    expect(token.matchesAny([TokenType.AMPERSAND]), false);
  }

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
      Keyword.INTERFACE,
      Keyword.LIBRARY,
      Keyword.MIXIN,
      Keyword.OPERATOR,
      Keyword.PART,
      Keyword.SET,
      Keyword.STATIC,
      Keyword.TYPEDEF,
    ]);
    for (Keyword keyword in Keyword.values) {
      var isBuiltIn = builtInKeywords.contains(keyword);
      expect(keyword.isBuiltIn, isBuiltIn, reason: keyword.name);
    }
  }

  void test_isModifier() {
    var modifierKeywords = new Set<Keyword>.from([
      Keyword.ABSTRACT,
      Keyword.CONST,
      Keyword.COVARIANT,
      Keyword.EXTERNAL,
      Keyword.FINAL,
      Keyword.STATIC,
      Keyword.VAR,
    ]);
    for (Keyword keyword in Keyword.values) {
      var isModifier = modifierKeywords.contains(keyword);
      var scanner = new StringScanner(keyword.lexeme, includeComments: true);
      Token token = scanner.tokenize();
      expect(token.isModifier, isModifier, reason: keyword.name);
      if (isModifier) {
        expect(token.isTopLevelKeyword, isFalse, reason: keyword.name);
      }
    }
  }

  void test_isTopLevelKeyword() {
    var topLevelKeywords = new Set<Keyword>.from([
      Keyword.CLASS,
      Keyword.ENUM,
      Keyword.EXPORT,
      Keyword.IMPORT,
      Keyword.LIBRARY,
      Keyword.PART,
      Keyword.TYPEDEF,
    ]);
    for (Keyword keyword in Keyword.values) {
      var isTopLevelKeyword = topLevelKeywords.contains(keyword);
      var scanner = new StringScanner(keyword.lexeme, includeComments: true);
      Token token = scanner.tokenize();
      expect(token.isTopLevelKeyword, isTopLevelKeyword, reason: keyword.name);
      if (isTopLevelKeyword) {
        expect(token.isModifier, isFalse, reason: keyword.name);
      }
    }
  }

  void test_pseudo_keywords() {
    var pseudoKeywords = new Set<Keyword>.from([
      Keyword.ASYNC,
      Keyword.AWAIT,
      Keyword.FUNCTION,
      Keyword.HIDE,
      Keyword.NATIVE,
      Keyword.OF,
      Keyword.ON,
      Keyword.PATCH,
      Keyword.SHOW,
      Keyword.SOURCE,
      Keyword.SYNC,
      Keyword.YIELD,
    ]);
    for (Keyword keyword in Keyword.values) {
      var isPseudo = pseudoKeywords.contains(keyword);
      expect(keyword.isPseudo, isPseudo, reason: keyword.name);
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
