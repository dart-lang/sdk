// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.refactoring.inline_local;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';


const String _TOKEN_SEPARATOR = "\uFFFF";


/**
 * [InlineLocalRefactoring] implementation.
 */
class InlineLocalRefactoringImpl extends RefactoringImpl implements
    InlineLocalRefactoring {
  final SearchEngine searchEngine;
  final CompilationUnit unit;
  final int offset;
  String file;
  CorrectionUtils utils;

  Element _variableElement;
  VariableDeclaration _variableNode;
  List<SearchMatch> _references;

  InlineLocalRefactoringImpl(this.searchEngine, this.unit, this.offset) {
    file = unit.element.source.fullName;
    utils = new CorrectionUtils(unit);
  }

  @override
  String get refactoringName => 'Inline Local Variable';

  @override
  int get referenceCount {
    if (_references == null) {
      return 0;
    }
    return _references.length;
  }

  @override
  String get variableName {
    if (_variableElement == null) {
      return null;
    }
    return _variableElement.name;
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    RefactoringStatus result = new RefactoringStatus();
    return new Future.value(result);
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() {
    RefactoringStatus result = new RefactoringStatus();
    // prepare variable
    {
      AstNode offsetNode = new NodeLocator.con1(offset).searchWithin(unit);
      if (offsetNode is SimpleIdentifier) {
        Element element = offsetNode.staticElement;
        if (element is LocalVariableElement) {
          _variableElement = element;
          _variableNode = element.node;
        }
      }
    }
    if (_variableNode == null) {
      result = new RefactoringStatus.fatal(
          'Local variable declaration or reference must be selected to activate this refactoring.');
      return new Future.value(result);
    }
    // should be normal variable declaration statement
    if (_variableNode.parent is! VariableDeclarationList ||
        _variableNode.parent.parent is! VariableDeclarationStatement ||
        _variableNode.parent.parent.parent is! Block) {
      result = new RefactoringStatus.fatal(
          'Local variable declared in '
              'statement should be selected to activate this refactoring.');
      return new Future.value(result);
    }
    // should have initializer at declaration
    if (_variableNode.initializer == null) {
      String message = format(
          "Local variable '{0}' is not initialized at declaration.",
          _variableElement.displayName);
      result =
          new RefactoringStatus.fatal(message, new Location.fromNode(_variableNode));
      return new Future.value(result);
    }
    // prepare references
    return searchEngine.searchReferences(_variableElement).then((references) {
      this._references = references;
      // should not have assignments
      for (SearchMatch reference in _references) {
        if (reference.kind != MatchKind.READ) {
          String message = format(
              "Local variable '{0}' is assigned more than once.",
              [_variableElement.displayName]);
          return new RefactoringStatus.fatal(
              message,
              new Location.fromMatch(reference));
        }
      }
      // done
      return result;
    });
  }

  @override
  Future<SourceChange> createChange() {
    SourceChange change = new SourceChange(refactoringName);
    // remove declaration
    {
      Statement declarationStatement =
          _variableNode.getAncestor((node) => node is VariableDeclarationStatement);
      SourceRange range = utils.getLinesRangeStatements([declarationStatement]);
      change.addEdit(file, new SourceEdit.range(range, ''));
    }
    // prepare initializer
    Expression initializer = _variableNode.initializer;
    String initializerSource = utils.getNodeText(initializer);
    int initializerPrecedence = getExpressionPrecedence(initializer);
    // replace references
    for (SearchMatch reference in _references) {
      SourceRange range = reference.sourceRange;
      String sourceForReference =
          _getSourceForReference(range, initializerSource, initializerPrecedence);
      change.addEdit(file, new SourceEdit.range(range, sourceForReference));
    }
    // done
    return new Future.value(change);
  }

  @override
  bool requiresPreview() => false;

  /**
   * Returns the source which should be used to replace the reference with the
   * given [SourceRange].
   *
   * [range] - the [SourceRange] of the reference.
   * [source] - the source of the initializer, to be inserted at [range].
   * [precedence] - the precedence of the initializer [source].
   */
  String _getSourceForReference(SourceRange range, String source,
      int precedence) {
    int offset = range.offset;
    AstNode node = utils.findNode(offset);
    AstNode parent = node.parent;
    if (_isIdentifierStringInterpolation(parent)) {
      return '{${source}}';
    }
    if (precedence < getExpressionParentPrecedence(node)) {
      return '(${source})';
    }
    return source;
  }

  /**
   * Checks if the given node is a string interpolation in form `$name`.
   */
  bool _isIdentifierStringInterpolation(AstNode parent) {
    if (parent is InterpolationExpression) {
      InterpolationExpression element = parent;
      return element.beginToken.type ==
          TokenType.STRING_INTERPOLATION_IDENTIFIER;
    }
    return false;
  }
}
