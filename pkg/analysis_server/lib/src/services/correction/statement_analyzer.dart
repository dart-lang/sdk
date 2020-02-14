// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/correction/selection_analyzer.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Returns [Token]s of the given Dart source, not `null`, may be empty if no
/// tokens or some exception happens.
List<Token> _getTokens(String text, FeatureSet featureSet) {
  try {
    List<Token> tokens = <Token>[];
    Scanner scanner = Scanner(null, CharSequenceReader(text), null)
      ..configureFeatures(featureSet);
    Token token = scanner.tokenize();
    while (token.type != TokenType.EOF) {
      tokens.add(token);
      token = token.next;
    }
    return tokens;
  } catch (e) {
    return List<Token>(0);
  }
}

/// Analyzer to check if a selection covers a valid set of statements of AST.
class StatementAnalyzer extends SelectionAnalyzer {
  final ResolvedUnitResult resolveResult;

  final RefactoringStatus _status = RefactoringStatus();

  StatementAnalyzer(this.resolveResult, SourceRange selection)
      : super(selection);

  /// Returns the [RefactoringStatus] result of selection checking.
  RefactoringStatus get status => _status;

  /// Analyze the selection, compute [status] and nodes.
  void analyze() {
    resolveResult.unit.accept(this);
  }

  /// Records fatal error with given message and [Location].
  void invalidSelection(String message, [Location context]) {
    if (!_status.hasFatalError) {
      _status.addFatalError(message, context);
    }
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
      List<SourceRange> commentRanges = getCommentRanges(resolveResult.unit);
      for (SourceRange commentRange in commentRanges) {
        if (commentRange.contains(selectionStart)) {
          invalidSelection('Selection begins inside a comment.');
        }
        if (commentRange.containsExclusive(selectionEnd)) {
          invalidSelection('Selection ends inside a comment.');
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
    var forLoopParts = node.forLoopParts;
    if (forLoopParts is ForParts) {
      List<AstNode> selectedNodes = this.selectedNodes;
      bool containsInit;
      if (forLoopParts is ForPartsWithExpression) {
        containsInit = _contains(selectedNodes, forLoopParts.initialization);
      } else if (forLoopParts is ForPartsWithDeclarations) {
        containsInit = _contains(selectedNodes, forLoopParts.variables);
      } else {
        throw StateError('Unrecognized for loop parts');
      }
      bool containsCondition = _contains(selectedNodes, forLoopParts.condition);
      bool containsUpdaters =
          _containsAny(selectedNodes, forLoopParts.updaters);
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
            'Selection must either cover whole switch statement or parts of a single case block.');
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
            'Selection must either cover whole try statement or parts of try, catch, or finally block.');
      } else {
        List<CatchClause> catchClauses = node.catchClauses;
        for (CatchClause catchClause in catchClauses) {
          if (firstSelectedNode == catchClause ||
              firstSelectedNode == catchClause.body ||
              firstSelectedNode == catchClause.exceptionParameter) {
            invalidSelection(
                'Selection must either cover whole try statement or parts of try, catch, or finally block.');
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

  /// Checks final selected [AstNode]s after processing [CompilationUnit].
  void _checkSelectedNodes(CompilationUnit unit) {
    List<AstNode> nodes = selectedNodes;
    // some tokens before first selected node
    {
      AstNode firstNode = nodes[0];
      SourceRange rangeBeforeFirstNode =
          range.startOffsetEndOffset(selection.offset, firstNode.offset);
      if (_hasTokens(rangeBeforeFirstNode)) {
        invalidSelection(
            'The beginning of the selection contains characters that '
            'do not belong to a statement.',
            newLocation_fromUnit(unit, rangeBeforeFirstNode));
      }
    }
    // some tokens after last selected node
    {
      AstNode lastNode = nodes.last;
      SourceRange rangeAfterLastNode =
          range.startOffsetEndOffset(lastNode.end, selection.end);
      if (_hasTokens(rangeAfterLastNode)) {
        invalidSelection(
            'The end of the selection contains characters that '
            'do not belong to a statement.',
            newLocation_fromUnit(unit, rangeAfterLastNode));
      }
    }
  }

  /// Returns `true` if there are [Token]s in the given [SourceRange].
  bool _hasTokens(SourceRange range) {
    String fullText = resolveResult.content;
    String rangeText = fullText.substring(range.offset, range.end);
    return _getTokens(rangeText, resolveResult.unit.featureSet).isNotEmpty;
  }

  /// Returns `true` if [nodes] contains [node].
  static bool _contains(List<AstNode> nodes, AstNode node) =>
      nodes.contains(node);

  /// Returns `true` if [nodes] contains one of the [otherNodes].
  static bool _containsAny(List<AstNode> nodes, List<AstNode> otherNodes) {
    for (AstNode otherNode in otherNodes) {
      if (nodes.contains(otherNode)) {
        return true;
      }
    }
    return false;
  }
}
