// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.correction.statement_analyzer;

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/correction/selection_analyzer.dart';
import 'package:analysis_server/src/services/correction/source_range.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * Returns [Token]s of the given Dart source, not `null`, may be empty if no
 * tokens or some exception happens.
 */
List<Token> _getTokens(String text) {
  try {
    List<Token> tokens = <Token>[];
    Scanner scanner = new Scanner(null, new CharSequenceReader(text), null);
    Token token = scanner.tokenize();
    while (token.type != TokenType.EOF) {
      tokens.add(token);
      token = token.next;
    }
    return tokens;
  } catch (e) {
    return new List<Token>(0);
  }
}


/**
 * Analyzer to check if a selection covers a valid set of statements of AST.
 */
class StatementAnalyzer extends SelectionAnalyzer {
  final CompilationUnit unit;

  RefactoringStatus _status = new RefactoringStatus();

  StatementAnalyzer(this.unit, SourceRange selection) : super(selection);

  /**
   * Returns the [RefactoringStatus] result of selection checking.
   */
  RefactoringStatus get status => _status;

  /**
   * Records fatal error with given message and [Location].
   */
  void invalidSelection(String message, [Location context]) {
    _status.addFatalError(message, context);
    reset();
  }

  @override
  Object visitCompilationUnit(CompilationUnit node) {
    super.visitCompilationUnit(node);
    if (!hasSelectedNodes) {
      return null;
    }
    // check that selection does not begin/end in comment
    {
      int selectionStart = selection.offset;
      int selectionEnd = selection.end;
      List<SourceRange> commentRanges = getCommentRanges(unit);
      for (SourceRange commentRange in commentRanges) {
        if (commentRange.contains(selectionStart)) {
          invalidSelection("Selection begins inside a comment.");
        }
        if (commentRange.containsExclusive(selectionEnd)) {
          invalidSelection("Selection ends inside a comment.");
        }
      }
    }
    // more checks
    if (!_status.hasFatalError) {
      _checkSelectedNodes(node);
    }
    return null;
  }

  @override
  Object visitDoStatement(DoStatement node) {
    super.visitDoStatement(node);
    List<AstNode> selectedNodes = this.selectedNodes;
    if (_contains(selectedNodes, node.body)) {
      invalidSelection(
          "Operation not applicable to a 'do' statement's body and expression.");
    }
    return null;
  }

  @override
  Object visitForStatement(ForStatement node) {
    super.visitForStatement(node);
    List<AstNode> selectedNodes = this.selectedNodes;
    bool containsInit =
        _contains(selectedNodes, node.initialization) ||
        _contains(selectedNodes, node.variables);
    bool containsCondition = _contains(selectedNodes, node.condition);
    bool containsUpdaters = _containsAny(selectedNodes, node.updaters);
    bool containsBody = _contains(selectedNodes, node.body);
    if (containsInit && containsCondition) {
      invalidSelection(
          "Operation not applicable to a 'for' statement's initializer and condition.");
    } else if (containsCondition && containsUpdaters) {
      invalidSelection(
          "Operation not applicable to a 'for' statement's condition and updaters.");
    } else if (containsUpdaters && containsBody) {
      invalidSelection(
          "Operation not applicable to a 'for' statement's updaters and body.");
    }
    return null;
  }

  @override
  Object visitSwitchStatement(SwitchStatement node) {
    super.visitSwitchStatement(node);
    List<AstNode> selectedNodes = this.selectedNodes;
    List<SwitchMember> switchMembers = node.members;
    for (AstNode selectedNode in selectedNodes) {
      if (switchMembers.contains(selectedNode)) {
        invalidSelection(
            "Selection must either cover whole switch statement or parts of a single case block.");
        break;
      }
    }
    return null;
  }

  @override
  Object visitTryStatement(TryStatement node) {
    super.visitTryStatement(node);
    AstNode firstSelectedNode = this.firstSelectedNode;
    if (firstSelectedNode != null) {
      if (firstSelectedNode == node.body ||
          firstSelectedNode == node.finallyBlock) {
        invalidSelection(
            "Selection must either cover whole try statement or parts of try, catch, or finally block.");
      } else {
        List<CatchClause> catchClauses = node.catchClauses;
        for (CatchClause catchClause in catchClauses) {
          if (firstSelectedNode == catchClause ||
              firstSelectedNode == catchClause.body ||
              firstSelectedNode == catchClause.exceptionParameter) {
            invalidSelection(
                "Selection must either cover whole try statement or parts of try, catch, or finally block.");
          }
        }
      }
    }
    return null;
  }

  @override
  Object visitWhileStatement(WhileStatement node) {
    super.visitWhileStatement(node);
    List<AstNode> selectedNodes = this.selectedNodes;
    if (_contains(selectedNodes, node.condition) &&
        _contains(selectedNodes, node.body)) {
      invalidSelection(
          "Operation not applicable to a while statement's expression and body.");
    }
    return null;
  }

  /**
   * Checks final selected [AstNode]s after processing [CompilationUnit].
   */
  void _checkSelectedNodes(CompilationUnit unit) {
    List<AstNode> nodes = selectedNodes;
    // some tokens before first selected node
    {
      AstNode firstNode = nodes[0];
      SourceRange rangeBeforeFirstNode = rangeStartStart(selection, firstNode);
      if (_hasTokens(rangeBeforeFirstNode)) {
        invalidSelection(
            "The beginning of the selection contains characters that "
                "do not belong to a statement.",
            newLocation_fromUnit(unit, rangeBeforeFirstNode));
      }
    }
    // some tokens after last selected node
    {
      AstNode lastNode = nodes.last;
      SourceRange rangeAfterLastNode = rangeEndEnd(lastNode, selection);
      if (_hasTokens(rangeAfterLastNode)) {
        invalidSelection(
            "The end of the selection contains characters that "
                "do not belong to a statement.",
            newLocation_fromUnit(unit, rangeAfterLastNode));
      }
    }
  }

  /**
   * Returns `true` if there are [Token]s in the given [SourceRange].
   */
  bool _hasTokens(SourceRange range) {
    CompilationUnitElement unitElement = unit.element;
    String fullText = unitElement.context.getContents(unitElement.source).data;
    String rangeText = fullText.substring(range.offset, range.end);
    return _getTokens(rangeText).isNotEmpty;
  }

  /**
   * Returns `true` if [nodes] contains [node].
   */
  static bool _contains(List<AstNode> nodes, AstNode node) =>
      nodes.contains(node);

  /**
   * Returns `true` if [nodes] contains one of the [otherNodes].
   */
  static bool _containsAny(List<AstNode> nodes, List<AstNode> otherNodes) {
    for (AstNode otherNode in otherNodes) {
      if (nodes.contains(otherNode)) {
        return true;
      }
    }
    return false;
  }
}
