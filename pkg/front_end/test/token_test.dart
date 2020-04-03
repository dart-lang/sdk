// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show ScannerConfiguration, scanString;
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
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
    Token token = scanString(source, includeComments: true).tokens;

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
    expect(comment, const TypeMatcher<DocumentationCommentToken>());

    comment = nextComment();
    expect(comment.lexeme, contains('Multi-line dartdoc comment'));
    expect(comment.type, TokenType.MULTI_LINE_COMMENT);
    expect(comment, const TypeMatcher<DocumentationCommentToken>());

    comment = nextComment();
    expect(comment.lexeme, contains('Single line comment'));
    expect(comment.type, TokenType.SINGLE_LINE_COMMENT);
    expect(comment, const TypeMatcher<CommentToken>());

    comment = nextComment();
    expect(comment.lexeme, contains('Multi-line comment'));
    expect(comment.type, TokenType.MULTI_LINE_COMMENT);
    expect(comment, const TypeMatcher<CommentToken>());
  }

  void test_isSynthetic() {
    var token = scanString('/* 1 */ foo', includeComments: true).tokens;
    expect(token.isSynthetic, false);
    expect(token.precedingComments.isSynthetic, false);
    expect(token.previous.isSynthetic, true);
    expect(token.next.isEof, true);
    expect(token.next.isSynthetic, true);
  }

  void test_matchesAny() {
    var token = scanString('true', includeComments: true).tokens;
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
      Keyword.EXTENSION,
      Keyword.EXTERNAL,
      Keyword.FACTORY,
      Keyword.GET,
      Keyword.IMPLEMENTS,
      Keyword.IMPORT,
      Keyword.INTERFACE,
      Keyword.LATE,
      Keyword.LIBRARY,
      Keyword.MIXIN,
      Keyword.OPERATOR,
      Keyword.PART,
      Keyword.REQUIRED,
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
      Keyword.LATE,
      Keyword.REQUIRED,
      Keyword.STATIC,
      Keyword.VAR,
    ]);
    for (Keyword keyword in Keyword.values) {
      var isModifier = modifierKeywords.contains(keyword);
      Token token = scanString(keyword.lexeme,
              configuration: ScannerConfiguration.nonNullable,
              includeComments: true)
          .tokens;
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
      //Keyword.EXTENSION, <-- when "extension methods" is enabled by default
      Keyword.IMPORT,
      Keyword.LIBRARY,
      Keyword.MIXIN,
      Keyword.PART,
      Keyword.TYPEDEF,
    ]);
    for (Keyword keyword in Keyword.values) {
      var isTopLevelKeyword = topLevelKeywords.contains(keyword);
      Token token = scanString(keyword.lexeme, includeComments: true).tokens;
      expect(token.isTopLevelKeyword, isTopLevelKeyword, reason: keyword.name);
      if (isTopLevelKeyword) {
        expect(token.isModifier, isFalse, reason: keyword.name);
      }
    }
  }

  void test_noPseudoModifiers() {
    for (Keyword keyword in Keyword.values) {
      if (keyword.isModifier) {
        expect(keyword.isPseudo, isFalse, reason: keyword.lexeme);
      }
    }
  }

  void test_pseudo_keywords() {
    var pseudoKeywords = new Set<Keyword>.from([
      Keyword.ASYNC,
      Keyword.AWAIT,
      Keyword.FUNCTION,
      Keyword.HIDE,
      Keyword.INOUT,
      Keyword.NATIVE,
      Keyword.OF,
      Keyword.ON,
      Keyword.OUT,
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
    var token = scanString('true & "home"', includeComments: true).tokens;
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
