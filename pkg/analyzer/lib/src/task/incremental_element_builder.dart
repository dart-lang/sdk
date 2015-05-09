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
 * Incrementally updates the existing [unitElement] and builds elements for
 * the [newUnit].
 */
class IncrementalCompilationUnitElementBuilder {
  final Source source;
  final Source librarySource;
  final CompilationUnit oldUnit;
  final CompilationUnitElementImpl unitElement;
  final CompilationUnit newUnit;
  final ElementHolder holder = new ElementHolder();

  IncrementalCompilationUnitElementBuilder(
      CompilationUnit oldUnit, this.newUnit)
      : oldUnit = oldUnit,
        unitElement = oldUnit.element,
        source = oldUnit.element.source,
        librarySource = (oldUnit.element as CompilationUnitElementImpl).librarySource;

  void build() {
    new CompilationUnitBuilder().buildCompilationUnit(
        source, newUnit, librarySource);
    _processDirectives();
    _processUnitMembers();
    newUnit.element = unitElement;
  }

  void _addElementsToHolder(CompilationUnitMember node) {
    List<Element> elements = _getElements(node);
    elements.forEach(_addElementToHolder);
  }

  void _addElementToHolder(Element element) {
    if (element is PropertyAccessorElement) {
      holder.addAccessor(element);
    } else if (element is ClassElement) {
      if (element.isEnum) {
        holder.addEnum(element);
      } else {
        holder.addType(element);
      }
    } else if (element is FunctionElement) {
      holder.addFunction(element);
    } else if (element is FunctionTypeAliasElement) {
      holder.addTypeAlias(element);
    } else if (element is TopLevelVariableElement) {
      holder.addTopLevelVariable(element);
    }
  }

  void _processDirectives() {
    Map<String, Directive> oldDirectiveMap = new HashMap<String, Directive>();
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
      _replaceNode(newDirective, oldDirective);
    }
  }

  void _processUnitMembers() {
    Map<String, CompilationUnitMember> oldNodeMap =
        new HashMap<String, CompilationUnitMember>();
    for (CompilationUnitMember oldNode in oldUnit.declarations) {
      String code = TokenUtils.getFullCode(oldNode);
      oldNodeMap[code] = oldNode;
    }
    // Replace new nodes with the identical old nodes.
    for (CompilationUnitMember newNode in newUnit.declarations) {
      String code = TokenUtils.getFullCode(newNode);
      // Prepare an old node.
      CompilationUnitMember oldNode = oldNodeMap[code];
      if (oldNode == null) {
        _addElementsToHolder(newNode);
        continue;
      }
      // Do replacement.
      _replaceNode(newNode, oldNode);
      _addElementsToHolder(oldNode);
    }
    // Update CompilationUnitElement.
    unitElement.accessors = holder.accessors;
    unitElement.enums = holder.enums;
    unitElement.functions = holder.functions;
    unitElement.typeAliases = holder.typeAliases;
    unitElement.types = holder.types;
    unitElement.topLevelVariables = holder.topLevelVariables;
    holder.validate();
  }

  /**
   * Replaces [newNode] with [oldNode], updates tokens and elements.
   * The nodes must have the same tokens, but offsets may be different.
   */
  void _replaceNode(AstNode newNode, AstNode oldNode) {
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
    {
      var visitor = new _UpdateElementOffsetsVisitor(offsetMap);
      List<Element> elements = _getElements(oldNode);
      for (Element element in elements) {
        element.accept(visitor);
      }
    }
  }

  /**
   * Returns [Element]s that are declared directly by the given [node].
   * This does not include any child elements - parameters, local variables.
   *
   * Usually just one [Element] is returned, but [VariableDeclarationList]
   * nodes may declare more than one.
   */
  static List<Element> _getElements(AstNode node) {
    List<Element> elements = <Element>[];
    if (node is TopLevelVariableDeclaration) {
      VariableDeclarationList variableList = node.variables;
      if (variableList != null) {
        for (VariableDeclaration variable in variableList.variables) {
          TopLevelVariableElement element = variable.element;
          elements.add(element);
          elements.add(element.getter);
          elements.add(element.setter);
        }
      }
    } else if (node is PartDirective || node is PartOfDirective) {
    } else if (node is Directive && node.element != null) {
      elements.add(node.element);
    } else if (node is Declaration && node.element != null) {
      Element element = node.element;
      elements.add(element);
      if (element is PropertyAccessorElement) {
        elements.add(element.variable);
      }
    }
    return elements;
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
      while (oldToken != null) {
        offsetMap[oldToken.offset] = newToken.offset;
        oldToken.offset = newToken.offset;
        oldToken = oldToken.next;
        newToken = newToken.next;
      }
      assert(oldToken == null);
      assert(newToken == null);
      return;
    }
    while (true) {
      if (oldToken.precedingComments != null) {
        assert(newToken.precedingComments != null);
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

  /**
   * Returns all tokends (including comments) of the given [node].
   */
  static List<Token> getTokens(AstNode node) {
    List<Token> tokens = <Token>[];
    Token token = getBeginTokenNotComment(node);
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

  void visitElement(Element element) {
    if (element is CompilationUnitElement) {
      return;
    }
    if (element.isSynthetic) {
      return;
    }
    int oldOffset = element.nameOffset;
    int newOffset = map[oldOffset];
    assert(newOffset != null);
    (element as ElementImpl).nameOffset = newOffset;
    if (element is! LibraryElement) {
      super.visitElement(element);
    }
  }
}
