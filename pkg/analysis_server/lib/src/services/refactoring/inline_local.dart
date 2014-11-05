// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.refactoring.inline_local;

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/source_range.dart';
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


/**
 * [InlineLocalRefactoring] implementation.
 */
class InlineLocalRefactoringImpl extends RefactoringImpl implements
    InlineLocalRefactoring {
  final SearchEngine searchEngine;
  final CompilationUnit unit;
  final int offset;
  CompilationUnitElement unitElement;
  CorrectionUtils utils;

  Element _variableElement;
  VariableDeclaration _variableNode;
  List<SearchMatch> _references;

  InlineLocalRefactoringImpl(this.searchEngine, this.unit, this.offset) {
    unitElement = unit.element;
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
          new RefactoringStatus.fatal(message, newLocation_fromNode(_variableNode));
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
              newLocation_fromMatch(reference));
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
      doSourceChange_addElementEdit(
          change,
          unitElement,
          newSourceEdit_range(range, ''));
    }
    // prepare initializer
    Expression initializer = _variableNode.initializer;
    String initializerCode = utils.getNodeText(initializer);
    // replace references
    for (SearchMatch reference in _references) {
      SourceRange range = reference.sourceRange;
      // prepare context
      int offset = range.offset;
      AstNode node = utils.findNode(offset);
      AstNode parent = node.parent;
      // prepare code
      String codeForReference;
      if (parent is InterpolationExpression) {
        StringInterpolation target = parent.parent;
        if (initializer is SingleStringLiteral &&
            !initializer.isRaw &&
            initializer.isSingleQuoted == target.isSingleQuoted &&
            (!initializer.isMultiline || target.isMultiline)) {
          range = rangeNode(parent);
          // unwrap the literal being inlined
          int initOffset = initializer.contentsOffset;
          int initLength = initializer.contentsEnd - initOffset;
          codeForReference = utils.getText(initOffset, initLength);
          // drop leading multiline EOL
          if (initializer.isMultiline) {
            if (codeForReference.startsWith('\n')) {
              codeForReference = codeForReference.substring(1);
            } else if (codeForReference.startsWith('\r\n')) {
              codeForReference = codeForReference.substring(2);
            }
          }
        } else if (_shouldBeExpressionInterpolation(parent, initializer)) {
          codeForReference = '{$initializerCode}';
        } else {
          codeForReference = initializerCode;
        }
      } else if (_shouldUseParenthesis(initializer, node)) {
        codeForReference = '($initializerCode)';
      } else {
        codeForReference = initializerCode;
      }
      // do replace
      doSourceChange_addElementEdit(
          change,
          unitElement,
          newSourceEdit_range(range, codeForReference));
    }
    // done
    return new Future.value(change);
  }

  @override
  bool requiresPreview() => false;

  static bool _shouldBeExpressionInterpolation(InterpolationExpression target,
      Expression expression) {
    TokenType targetType = target.beginToken.type;
    return targetType == TokenType.STRING_INTERPOLATION_IDENTIFIER &&
        expression is! SimpleIdentifier;
  }

  static bool _shouldUseParenthesis(Expression init, AstNode node) {
    // check precedence
    int initPrecedence = getExpressionPrecedence(init);
    if (initPrecedence < getExpressionParentPrecedence(node)) {
      return true;
    }
    // special case for '-'
    AstNode parent = node.parent;
    if (init is PrefixExpression && parent is PrefixExpression) {
      if (parent.operator.type == TokenType.MINUS) {
        TokenType initializerOperator = init.operator.type;
        if (initializerOperator == TokenType.MINUS ||
            initializerOperator == TokenType.MINUS_MINUS) {
          return true;
        }
      }
    }
    // no () is needed
    return false;
  }
}
