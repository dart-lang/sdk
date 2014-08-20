// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.refactoring.extract_local;

import 'dart:async';

import 'package:analysis_server/src/protocol2.dart' show SourceEdit;
import 'package:analysis_server/src/services/correction/change.dart';
import 'package:analysis_server/src/services/correction/selection_analyzer.dart';
import 'package:analysis_server/src/services/correction/source_range.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/strings.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analysis_server/src/services/search/element_visitors.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';


const String _TOKEN_SEPARATOR = "\uFFFF";


/**
 * [ExtractLocalRefactoring] implementation.
 */
class ExtractLocalRefactoringImpl extends RefactoringImpl implements
    ExtractLocalRefactoring {
  final CompilationUnit unit;
  final int selectionOffset;
  final int selectionLength;
  String file;
  SourceRange selectionRange;
  CorrectionUtils utils;

  String name;
  bool extractAll = true;
  final List<String> names = <String>[];
  final List<int> offsets = <int>[];
  final List<int> lengths = <int>[];

  Expression rootExpression;
  Expression singleExpression;
  bool wholeStatementExpression = false;
  String stringLiteralPart;
  final List<SourceRange> occurrences = <SourceRange>[];
  final Set<String> excludedVariableNames = new Set<String>();

  ExtractLocalRefactoringImpl(this.unit, this.selectionOffset,
      this.selectionLength) {
    file = unit.element.source.fullName;
    selectionRange = new SourceRange(selectionOffset, selectionLength);
    utils = new CorrectionUtils(unit);
  }

  String get declarationKeyword {
    if (_isPartOfConstantExpression(rootExpression)) {
      return "const";
    } else {
      return "var";
    }
  }

  @override
  String get refactoringName => 'Extract Local Variable';

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    RefactoringStatus result = new RefactoringStatus();
    if (excludedVariableNames.contains(name)) {
      result.addWarning(
          format(
              "A variable with name '{0}' is already defined in the visible scope.",
              name));
    }
    return new Future.value(result);
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() {
    RefactoringStatus result = new RefactoringStatus();
    // selection
    result.addStatus(_checkSelection());
    // occurrences
    if (!result.hasFatalError) {
      _prepareOccurrences();
      _prepareExcludedNames();
    }
    // suggested names
    _prepareNames();
    // done
    return new Future.value(result);
  }

  @override
  RefactoringStatus checkName() {
    return validateVariableName(name);
  }

  @override
  Future<Change> createChange() {
    Change change = new Change(refactoringName);
    // prepare occurrences
    List<SourceRange> occurrences;
    if (extractAll) {
      occurrences = this.occurrences;
    } else {
      occurrences = [selectionRange];
    }
    // If the whole expression of a statement is selected, like '1 + 2',
    // then convert it into a variable declaration statement.
    if (wholeStatementExpression && occurrences.length == 1) {
      String keyword = declarationKeyword;
      String declarationSource = '$keyword $name = ';
      SourceEdit edit =
          new SourceEdit(singleExpression.offset, 0, declarationSource);
      change.addEdit(file, edit);
      return new Future.value(change);
    }
    // add variable declaration
    {
      String declarationSource;
      if (stringLiteralPart != null) {
        declarationSource = "var ${name} = '${stringLiteralPart}';";
      } else {
        String keyword = declarationKeyword;
        String initializerSource = utils.getRangeText(selectionRange);
        declarationSource = "${keyword} ${name} = ${initializerSource};";
      }
      // prepare location for declaration
      Statement targetStatement = _findTargetStatement(occurrences);
      String prefix = utils.getNodePrefix(targetStatement);
      // insert variable declaration
      String eol = utils.endOfLine;
      SourceEdit edit = new SourceEdit(
          targetStatement.offset,
          0,
          '${declarationSource}${eol}${prefix}');
      change.addEdit(file, edit);
    }
    // prepare replacement
    String occurrenceReplacement = name;
    if (stringLiteralPart != null) {
      occurrenceReplacement = "\${$name}";
    }
    // replace occurrences with variable reference
    for (SourceRange range in occurrences) {
      SourceEdit edit = editFromRange(range, occurrenceReplacement);
      change.addEdit(file, edit);
    }
    // done
    return new Future.value(change);
  }

  @override
  bool requiresPreview() => false;

  /**
   * Checks if [selectionRange] selects [Expression] which can be extracted, and
   * location of this [DartExpression] in AST allows extracting.
   */
  RefactoringStatus _checkSelection() {
    _ExtractExpressionAnalyzer _selectionAnalyzer =
        new _ExtractExpressionAnalyzer(selectionRange);
    unit.accept(_selectionAnalyzer);
    AstNode coveringNode = _selectionAnalyzer.coveringNode;
    // may be fatal error
    {
      RefactoringStatus status = _selectionAnalyzer.status;
      if (status.hasFatalError) {
        return status;
      }
    }
    // we need enclosing block to add variable declaration statement
    if (coveringNode == null ||
        coveringNode.getAncestor((node) => node is Block) == null) {
      return new RefactoringStatus.fatal(
          'Expression inside of function must be selected '
              'to activate this refactoring.');
    }
    // part of string literal
    if (coveringNode is StringLiteral) {
      stringLiteralPart = utils.getRangeText(selectionRange);
      if (stringLiteralPart.startsWith("'") ||
          stringLiteralPart.startsWith('"') ||
          stringLiteralPart.endsWith("'") ||
          stringLiteralPart.endsWith('"')) {
        return new RefactoringStatus.fatal(
            'Cannot extract only leading or trailing quote of string literal.');
      }
      return new RefactoringStatus();
    }
    // single node selected
    if (_selectionAnalyzer.selectedNodes.length == 1 &&
        !utils.selectionIncludesNonWhitespaceOutsideNode(
            selectionRange,
            _selectionAnalyzer.firstSelectedNode)) {
      AstNode selectedNode = _selectionAnalyzer.firstSelectedNode;
      if (selectedNode is Expression) {
        rootExpression = selectedNode;
        singleExpression = rootExpression;
        wholeStatementExpression =
            singleExpression.parent is ExpressionStatement;
        return new RefactoringStatus();
      }
    }
    // fragment of binary expression selected
    if (coveringNode is BinaryExpression) {
      BinaryExpression binaryExpression = coveringNode;
      if (utils.validateBinaryExpressionRange(
          binaryExpression,
          selectionRange)) {
        rootExpression = binaryExpression;
        singleExpression = null;
        return new RefactoringStatus();
      }
    }
    // invalid selection
    return new RefactoringStatus.fatal(
        'Expression must be selected to activate this refactoring.');
  }

  /**
   * Returns [AstNode]s at the offsets of the given [SourceRange]s.
   */
  List<AstNode> _findNodes(List<SourceRange> ranges) {
    List<AstNode> nodes = <AstNode>[];
    for (SourceRange range in ranges) {
      AstNode node = new NodeLocator.con1(range.offset).searchWithin(unit);
      nodes.add(node);
    }
    return nodes;
  }

  /**
   * @return the [Statement] such that variable declaration added before it will be visible in
   *         all given occurrences.
   */
  Statement _findTargetStatement(List<SourceRange> occurrences) {
    List<AstNode> nodes = _findNodes(occurrences);
    List<AstNode> firstParents = getParents(nodes[0]);
    AstNode commonParent = getNearestCommonAncestor(nodes);
    if (commonParent is Block) {
      int commonIndex = firstParents.indexOf(commonParent);
      return firstParents[commonIndex + 1] as Statement;
    } else {
      return commonParent.getAncestor((node) => node is Statement);
    }
  }

  /**
   * @return `true` if it is OK to extract the node with the given [SourceRange].
   */
  bool _isExtractable(SourceRange range) {
    _ExtractExpressionAnalyzer analyzer = new _ExtractExpressionAnalyzer(range);
    utils.unit.accept(analyzer);
    return analyzer.status.isOK;
  }

  bool _isPartOfConstantExpression(AstNode node) {
    if (node is TypedLiteral) {
      return node.constKeyword != null;
    }
    if (node is InstanceCreationExpression) {
      InstanceCreationExpression creation = node;
      return creation.isConst;
    }
    if (node is ArgumentList ||
        node is ConditionalExpression ||
        node is BinaryExpression ||
        node is ParenthesizedExpression ||
        node is PrefixExpression ||
        node is Literal ||
        node is MapLiteralEntry) {
      return _isPartOfConstantExpression(node.parent);
    }
    return false;
  }

  void _prepareExcludedNames() {
    excludedVariableNames.clear();
    // TODO(scheglov) clean up?
    AstNode enclosingNode =
        new NodeLocator.con1(selectionOffset).searchWithin(unit);
    Block enclosingBlock = enclosingNode.getAncestor((node) => node is Block);
    if (enclosingBlock != null) {
      SourceRange newVariableVisibleRange =
          rangeStartEnd(selectionRange, enclosingBlock.end);
      ExecutableElement enclosingExecutable =
          getEnclosingExecutableElement(enclosingNode);
      if (enclosingExecutable != null) {
        visitChildren(enclosingExecutable, (Element element) {
          if (element is LocalElement) {
            SourceRange elementRange = element.visibleRange;
            if (elementRange != null &&
                elementRange.intersects(newVariableVisibleRange)) {
              excludedVariableNames.add(element.displayName);
            }
          }
          return true;
        });
      }
    }
  }

  void _prepareNames() {
    names.clear();
    // TODO(scheglov) implement
//    Set<String> excluded = excludedVariableNames;
//    if (_stringLiteralPart != null) {
//      return getVariableNameSuggestions(_stringLiteralPart, excluded);
//    } else if (_singleExpression != null) {
//      _guessedNames = CorrectionUtils.getVariableNameSuggestions2(_singleExpression.staticType, _singleExpression, excluded);
//    } else {
//      _guessedNames = ArrayUtils.EMPTY_STRING_ARRAY;
//    }
  }

  /**
   * @return all occurrences of the source which matches given selection, sorted by offset. First
   *         [SourceRange] is same as the given selection. May be empty, but not
   *         <code>null</code>.
   */
  List<SourceRange> _prepareOccurrences() {
    // prepare selection
    String selectionSource;
    {
      String rawSelectionSource = utils.getRangeText(selectionRange);
      List<Token> selectionTokens = TokenUtils.getTokens(rawSelectionSource);
      selectionSource = selectionTokens.join(_TOKEN_SEPARATOR);
    }
    // prepare enclosing function
    AstNode enclosingFunction;
    {
      AstNode selectionNode =
          new NodeLocator.con1(selectionOffset).searchWithin(unit);
      enclosingFunction = getEnclosingExecutableNode(selectionNode);
    }
    // visit function
    enclosingFunction.accept(
        new _OccurrencesVisitor(this, occurrences, selectionSource));
    // done
    return occurrences;
  }
}


/**
 * [SelectionAnalyzer] for [ExtractLocalRefactoringImpl].
 */
class _ExtractExpressionAnalyzer extends SelectionAnalyzer {
  final RefactoringStatus status = new RefactoringStatus();

  _ExtractExpressionAnalyzer(SourceRange selection) : super(selection);

  /**
   * Records fatal error with given message.
   */
  void invalidSelection(String message) {
    _invalidSelection(message, null);
  }

  @override
  Object visitAssignmentExpression(AssignmentExpression node) {
    super.visitAssignmentExpression(node);
    Expression lhs = node.leftHandSide;
    if (_isFirstSelectedNode(lhs)) {
      _invalidSelection(
          'Cannot extract the left-hand side of an assignment.',
          new RefactoringStatusContext.forNode(lhs));
    }
    return null;
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    super.visitSimpleIdentifier(node);
    if (_isFirstSelectedNode(node)) {
      // name of declaration
      if (node.inDeclarationContext()) {
        invalidSelection('Cannot extract the name part of a declaration.');
      }
      // method name
      Element element = node.bestElement;
      if (element is FunctionElement || element is MethodElement) {
        invalidSelection('Cannot extract a single method name.');
      }
      // name in property access
      AstNode parent = node.parent;
      if (parent is PrefixedIdentifier && identical(parent.identifier, node)) {
        invalidSelection('Cannot extract name part of a property access.');
      }
      if (parent is PropertyAccess && identical(parent.propertyName, node)) {
        invalidSelection('Cannot extract name part of a property access.');
      }
    }
    return null;
  }

  /**
   * Records fatal error with given message and [RefactoringStatusContext].
   */
  void _invalidSelection(String message, RefactoringStatusContext context) {
    status.addFatalError(message, context);
    reset();
  }

  bool _isFirstSelectedNode(AstNode node) => identical(firstSelectedNode, node);
}


class _HasStatementVisitor extends GeneralizingAstVisitor {
  final List<bool> result;

  _HasStatementVisitor(this.result);

  @override
  visitStatement(Statement node) {
    result[0] = true;
  }
}


class _OccurrencesVisitor extends GeneralizingAstVisitor<Object> {
  final ExtractLocalRefactoringImpl ref;

  List<SourceRange> occurrences;

  String selectionSource;

  _OccurrencesVisitor(this.ref, this.occurrences, this.selectionSource);

  @override
  Object visitBinaryExpression(BinaryExpression node) {
    if (!_hasStatements(node)) {
      _tryToFindOccurrenceFragment(node);
      return null;
    }
    return super.visitBinaryExpression(node);
  }

  @override
  Object visitExpression(Expression node) {
    if (ref._isExtractable(rangeNode(node))) {
      _tryToFindOccurrence(node);
    }
    return super.visitExpression(node);
  }

  @override
  Object visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (ref.stringLiteralPart != null) {
      int occuLength = ref.stringLiteralPart.length;
      String value = node.value;
      int valueOffset = node.offset + (node.isMultiline ? 3 : 1);
      int lastIndex = 0;
      while (true) {
        int index = value.indexOf(ref.stringLiteralPart, lastIndex);
        if (index == -1) {
          break;
        }
        lastIndex = index + occuLength;
        int occuStart = valueOffset + index;
        SourceRange occuRange = rangeStartLength(occuStart, occuLength);
        occurrences.add(occuRange);
      }
      return null;
    }
    return visitExpression(node);
  }

  void _addOccurrence(SourceRange range) {
    if (range.intersects(ref.selectionRange)) {
      occurrences.add(ref.selectionRange);
    } else {
      occurrences.add(range);
    }
  }

  bool _hasStatements(AstNode root) {
    List<bool> result = [false];
    root.accept(new _HasStatementVisitor(result));
    return result[0];
  }

  void _tryToFindOccurrence(Expression node) {
    String nodeSource = ref.utils.getNodeText(node);
    List<Token> nodeTokens = TokenUtils.getTokens(nodeSource);
    nodeSource = nodeTokens.join(_TOKEN_SEPARATOR);
    if (nodeSource == selectionSource) {
      SourceRange occuRange = rangeNode(node);
      _addOccurrence(occuRange);
    }
  }

  void _tryToFindOccurrenceFragment(Expression node) {
    int nodeOffset = node.offset;
    String nodeSource = ref.utils.getNodeText(node);
    List<Token> nodeTokens = TokenUtils.getTokens(nodeSource);
    nodeSource = nodeTokens.join(_TOKEN_SEPARATOR);
    // find "selection" in "node" tokens
    int lastIndex = 0;
    while (true) {
      // find next occurrence
      int index = nodeSource.indexOf(selectionSource, lastIndex);
      if (index == -1) {
        break;
      }
      lastIndex = index + selectionSource.length;
      // find start/end tokens
      int startTokenIndex =
          countMatches(nodeSource.substring(0, index), _TOKEN_SEPARATOR);
      int endTokenIndex =
          countMatches(nodeSource.substring(0, lastIndex), _TOKEN_SEPARATOR);
      Token startToken = nodeTokens[startTokenIndex];
      Token endToken = nodeTokens[endTokenIndex];
      // add occurrence range
      int occuStart = nodeOffset + startToken.offset;
      int occuEnd = nodeOffset + endToken.end;
      SourceRange occuRange = rangeStartEnd(occuStart, occuEnd);
      _addOccurrence(occuRange);
    }
  }
}
