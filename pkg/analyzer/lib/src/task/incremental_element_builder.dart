// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.incremental_element_builder;

import 'dart:collection';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * Incrementally updates the existing [oldUnitElement] and builds elements for
 * the [newUnit].
 */
class IncrementalCompilationUnitElementBuilder {
  final Source source;
  final CompilationUnit oldUnit;
  final CompilationUnitElement oldUnitElement;
  final CompilationUnit newUnit;

  IncrementalCompilationUnitElementBuilder(
      CompilationUnit oldUnit, this.newUnit)
      : oldUnit = oldUnit,
        oldUnitElement = oldUnit.element,
        source = oldUnit.element.source;

  void build() {
    new CompilationUnitBuilder().buildCompilationUnit(source, newUnit);
    _processDirectives();
  }

  void _processDirectives() {
    Map<String, Directive> oldDirectiveMap = <String, Directive>{};
    // Fill the old directives map.
    for (Directive oldDirective in oldUnit.directives) {
      String code = TokenUtils.getFullCode(oldDirective);
      oldDirectiveMap[code] = oldDirective;
    }
    // Replace new nodes with the identical old nodes.
    for (Directive newDirective in newUnit.directives) {
      String code = TokenUtils.getFullCode(newDirective);
      // Prepare an old directive.
      Directive oldDirective = oldDirectiveMap[code];
      if (oldDirective == null) {
        continue;
      }
      // URI's must be resolved to the same sources.
      if (newDirective is UriBasedDirective &&
          oldDirective is UriBasedDirective) {
        if (oldDirective.source != newDirective.source) {
          continue;
        }
      }
      // Do replacement.
      _replaceNode(newDirective, oldDirective, oldDirective.element);
    }
  }

  /**
   * Replaces [newNode] with [oldNode], updates tokens and elements.
   * The nodes must have the same tokens, but offsets may be different.
   */
  void _replaceNode(AstNode newNode, AstNode oldNode, Element oldElement) {
    // Replace node.
    NodeReplacer.replace(newNode, oldNode);
    // Replace tokens.
    {
      Token oldBeginToken = TokenUtils.getBeginTokenNotComment(newNode);
      Token newBeginToken = TokenUtils.getBeginTokenNotComment(oldNode);
      oldBeginToken.previous.setNext(newBeginToken);
      oldNode.endToken.setNext(newNode.endToken.next);
    }
    // Change tokens offsets.
    Map<int, int> offsetMap = new HashMap<int, int>();
    TokenUtils.copyTokenOffsets(offsetMap, oldNode.beginToken,
        newNode.beginToken, oldNode.endToken, newNode.endToken, true);
    // Change elements offsets.
    oldElement.accept(new _UpdateElementOffsetsVisitor(offsetMap));
  }
}

/**
 * Utilities for [Token] manipulations.
 */
class TokenUtils {
  static const String _SEPARATOR = "\uFFFF";

  /**
   * Copy offsets from [newToken]s to [oldToken]s.
   */
  static void copyTokenOffsets(Map<int, int> offsetMap, Token oldToken,
      Token newToken, Token oldEndToken, Token newEndToken,
      [bool goUpComment = false]) {
    if (oldToken is CommentToken && newToken is CommentToken) {
      if (goUpComment) {
        copyTokenOffsets(offsetMap, (oldToken as CommentToken).parent,
            (newToken as CommentToken).parent, oldEndToken, newEndToken);
      }
      while (oldToken.type != TokenType.EOF) {
        offsetMap[oldToken.offset] = newToken.offset;
        oldToken.offset = newToken.offset;
        oldToken = oldToken.next;
        newToken = newToken.next;
      }
    }
    while (true) {
      if (oldToken.precedingComments != null) {
        assert(newToken.precedingComments == null);
        copyTokenOffsets(offsetMap, oldToken.precedingComments,
            newToken.precedingComments, oldEndToken, newEndToken);
      }
      offsetMap[oldToken.offset] = newToken.offset;
      oldToken.offset = newToken.offset;
      if (oldToken == oldEndToken) {
        assert(newToken == newEndToken);
        break;
      }
      oldToken = oldToken.next;
      newToken = newToken.next;
    }
  }

  static Token getBeginTokenNotComment(AstNode node) {
    Token oldBeginToken = node.beginToken;
    if (oldBeginToken is CommentToken) {
      oldBeginToken = (oldBeginToken as CommentToken).parent;
    }
    return oldBeginToken;
  }

  /**
   * Return the token string of all the [node] tokens.
   */
  static String getFullCode(AstNode node) {
    List<Token> tokens = getTokens(node);
    return joinTokens(tokens);
  }

  static List<Token> getTokens(AstNode node) {
    List<Token> tokens = <Token>[];
    Token token = node.beginToken;
    Token endToken = node.endToken;
    while (true) {
      // append comment tokens
      for (Token commentToken = token.precedingComments;
          commentToken != null;
          commentToken = commentToken.next) {
        tokens.add(commentToken);
      }
      // append token
      tokens.add(token);
      // next token
      if (token == endToken) {
        break;
      }
      token = token.next;
    }
    return tokens;
  }

  static String joinTokens(List<Token> tokens) {
    return tokens.map((token) => token.lexeme).join(_SEPARATOR);
  }
}

/**
 * Updates name offsets of [Element]s according to the [map].
 */
class _UpdateElementOffsetsVisitor extends GeneralizingElementVisitor {
  final Map<int, int> map;

  _UpdateElementOffsetsVisitor(this.map);

  visitElement(Element element) {
    int oldOffset = element.nameOffset;
    int newOffset = map[oldOffset];
    assert(newOffset != null);
    (element as ElementImpl).nameOffset = newOffset;
    if (element is! LibraryElement) {
      super.visitElement(element);
    }
  }
}
