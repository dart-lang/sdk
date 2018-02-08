// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/name_suggestion.dart';
import 'package:analysis_server/src/services/correction/selection_analyzer.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/strings.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

const String _TOKEN_SEPARATOR = "\uFFFF";

/**
 * [ExtractLocalRefactoring] implementation.
 */
class ExtractLocalRefactoringImpl extends RefactoringImpl
    implements ExtractLocalRefactoring {
  final CompilationUnit unit;
  final int selectionOffset;
  final int selectionLength;
  CompilationUnitElement unitElement;
  String file;
  SourceRange selectionRange;
  CorrectionUtils utils;

  String name;
  bool extractAll = true;
  final List<int> coveringExpressionOffsets = <int>[];
  final List<int> coveringExpressionLengths = <int>[];
  final List<String> names = <String>[];
  final List<int> offsets = <int>[];
  final List<int> lengths = <int>[];

  Expression rootExpression;
  Expression singleExpression;
  bool wholeStatementExpression = false;
  String stringLiteralPart;
  final List<SourceRange> occurrences = <SourceRange>[];
  final Map<Element, int> elementIds = <Element, int>{};
  Set<String> excludedVariableNames = new Set<String>();

  ExtractLocalRefactoringImpl(
      this.unit, this.selectionOffset, this.selectionLength) {
    unitElement = unit.element;
    selectionRange = new SourceRange(selectionOffset, selectionLength);
    utils = new CorrectionUtils(unit);
    file = unitElement.source.fullName;
  }

  @override
  String get refactoringName => 'Extract Local Variable';

  String get _declarationKeyword {
    if (_isPartOfConstantExpression(rootExpression)) {
      return "const";
    } else {
      return "var";
    }
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    RefactoringStatus result = new RefactoringStatus();
    result.addStatus(checkName());
    return new Future.value(result);
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() {
    RefactoringStatus result = new RefactoringStatus();
    // selection
    result.addStatus(_checkSelection());
    if (result.hasFatalError) {
      return new Future.value(result);
    }
    // occurrences
    _prepareOccurrences();
    _prepareOffsetsLengths();
    // names
    excludedVariableNames =
        utils.findPossibleLocalVariableConflicts(selectionOffset);
    _prepareNames();
    // done
    return new Future.value(result);
  }

  @override
  RefactoringStatus checkName() {
    RefactoringStatus result = new RefactoringStatus();
    result.addStatus(validateVariableName(name));
    if (excludedVariableNames.contains(name)) {
      result.addError(
          format("The name '{0}' is already used in the scope.", name));
    }
    return result;
  }

  @override
  Future<SourceChange> createChange() {
    SourceChange change = new SourceChange(refactoringName);
    // prepare occurrences
    List<SourceRange> occurrences;
    if (extractAll) {
      occurrences = this.occurrences;
    } else {
      occurrences = [selectionRange];
    }
    occurrences.sort((a, b) => a.offset - b.offset);
    // If the whole expression of a statement is selected, like '1 + 2',
    // then convert it into a variable declaration statement.
    if (wholeStatementExpression && occurrences.length == 1) {
      String keyword = _declarationKeyword;
      String declarationSource = '$keyword $name = ';
      SourceEdit edit =
          new SourceEdit(singleExpression.offset, 0, declarationSource);
      doSourceChange_addElementEdit(change, unitElement, edit);
      return new Future.value(change);
    }
    // prepare positions
    List<Position> positions = <Position>[];
    int occurrencesShift = 0;
    void addPosition(int offset) {
      positions.add(new Position(file, offset));
    }

    // add variable declaration
    {
      String declarationCode;
      int nameOffsetInDeclarationCode;
      if (stringLiteralPart != null) {
        declarationCode = 'var ';
        nameOffsetInDeclarationCode = declarationCode.length;
        declarationCode += "$name = '$stringLiteralPart';";
      } else {
        String keyword = _declarationKeyword;
        String initializerCode = utils.getRangeText(selectionRange);
        declarationCode = '$keyword ';
        nameOffsetInDeclarationCode = declarationCode.length;
        declarationCode += '$name = $initializerCode;';
      }
      // prepare location for declaration
      AstNode target = _findDeclarationTarget(occurrences);
      String eol = utils.endOfLine;
      // insert variable declaration
      if (target is Statement) {
        String prefix = utils.getNodePrefix(target);
        SourceEdit edit =
            new SourceEdit(target.offset, 0, declarationCode + eol + prefix);
        doSourceChange_addElementEdit(change, unitElement, edit);
        addPosition(edit.offset + nameOffsetInDeclarationCode);
        occurrencesShift = edit.replacement.length;
      } else if (target is ExpressionFunctionBody) {
        String prefix = utils.getNodePrefix(target.parent);
        String indent = utils.getIndent(1);
        Expression expr = target.expression;
        {
          String code = '{' + eol + prefix + indent;
          addPosition(
              target.offset + code.length + nameOffsetInDeclarationCode);
          code += declarationCode + eol;
          code += prefix + indent + 'return ';
          SourceEdit edit =
              new SourceEdit(target.offset, expr.offset - target.offset, code);
          occurrencesShift = target.offset + code.length - expr.offset;
          doSourceChange_addElementEdit(change, unitElement, edit);
        }
        doSourceChange_addElementEdit(
            change,
            unitElement,
            new SourceEdit(
                expr.end, target.end - expr.end, ';' + eol + prefix + '}'));
      }
    }
    // prepare replacement
    String occurrenceReplacement = name;
    if (stringLiteralPart != null) {
      occurrenceReplacement = "\${$name}";
      occurrencesShift += 2;
    }
    // replace occurrences with variable reference
    for (SourceRange range in occurrences) {
      SourceEdit edit = newSourceEdit_range(range, occurrenceReplacement);
      addPosition(range.offset + occurrencesShift);
      occurrencesShift += name.length - range.length;
      doSourceChange_addElementEdit(change, unitElement, edit);
    }
    // add the linked group
    change.addLinkedEditGroup(new LinkedEditGroup(
        positions,
        name.length,
        names
            .map((name) => new LinkedEditSuggestion(
                name, LinkedEditSuggestionKind.VARIABLE))
            .toList()));
    // done
    return new Future.value(change);
  }

  @override
  bool requiresPreview() => false;

  /**
   * Checks if [selectionRange] selects [Expression] which can be extracted, and
   * location of this [Expression] in AST allows extracting.
   */
  RefactoringStatus _checkSelection() {
    String selectionStr;
    // exclude whitespaces
    {
      selectionStr = utils.getRangeText(selectionRange);
      int numLeading = countLeadingWhitespaces(selectionStr);
      int numTrailing = countTrailingWhitespaces(selectionStr);
      int offset = selectionRange.offset + numLeading;
      int end = selectionRange.end - numTrailing;
      selectionRange = new SourceRange(offset, end - offset);
    }
    // get covering node
    AstNode coveringNode =
        new NodeLocator(selectionRange.offset, selectionRange.end)
            .searchWithin(unit);
    // compute covering expressions
    for (AstNode node = coveringNode; node != null; node = node.parent) {
      AstNode parent = node.parent;
      // skip some nodes
      if (node is ArgumentList ||
          node is AssignmentExpression ||
          node is NamedExpression ||
          node is TypeArgumentList) {
        continue;
      }
      if (node is ConstructorName || node is Label || node is TypeName) {
        rootExpression = null;
        coveringExpressionOffsets.clear();
        coveringExpressionLengths.clear();
        continue;
      }
      // cannot extract the name part of a property access
      if (parent is PrefixedIdentifier && parent.identifier == node ||
          parent is PropertyAccess && parent.propertyName == node) {
        continue;
      }
      // stop if not an Expression
      if (node is! Expression) {
        break;
      }
      // stop at void method invocations
      if (node is MethodInvocation) {
        MethodInvocation invocation = node;
        Element element = invocation.methodName.bestElement;
        if (element is ExecutableElement &&
            element.returnType != null &&
            element.returnType.isVoid) {
          if (rootExpression == null) {
            return new RefactoringStatus.fatal(
                'Cannot extract the void expression.',
                newLocation_fromNode(node));
          }
          break;
        }
      }
      // fatal selection problems
      if (coveringExpressionOffsets.isEmpty) {
        if (node is SimpleIdentifier) {
          if (node.inDeclarationContext()) {
            return new RefactoringStatus.fatal(
                'Cannot extract the name part of a declaration.',
                newLocation_fromNode(node));
          }
          Element element = node.bestElement;
          if (element is FunctionElement || element is MethodElement) {
            continue;
          }
        }
        if (parent is AssignmentExpression && parent.leftHandSide == node) {
          return new RefactoringStatus.fatal(
              'Cannot extract the left-hand side of an assignment.',
              newLocation_fromNode(node));
        }
      }
      // set selected expression
      if (coveringExpressionOffsets.isEmpty) {
        rootExpression = node;
      }
      // add the expression range
      coveringExpressionOffsets.add(node.offset);
      coveringExpressionLengths.add(node.length);
    }
    // We need an enclosing function.
    // If it has a block body, we can add a new variable declaration statement
    // into this block.  If it has an expression body, we can convert it into
    // the block body first.
    if (coveringNode == null ||
        coveringNode.getAncestor((node) => node is FunctionBody) == null) {
      return new RefactoringStatus.fatal(
          'An expression inside a function must be selected '
          'to activate this refactoring.');
    }
    // part of string literal
    if (coveringNode is StringLiteral) {
      if (selectionRange.length != 0 &&
          selectionRange.offset > coveringNode.offset &&
          selectionRange.end < coveringNode.end) {
        stringLiteralPart = selectionStr;
        return new RefactoringStatus();
      }
    }
    // single node selected
    if (rootExpression != null) {
      singleExpression = rootExpression;
      selectionRange = range.node(singleExpression);
      wholeStatementExpression = singleExpression.parent is ExpressionStatement;
      return new RefactoringStatus();
    }
    // invalid selection
    return new RefactoringStatus.fatal(
        'Expression must be selected to activate this refactoring.');
  }

  /**
   * Return an unique identifier for the given [Element], or `null` if [element]
   * is `null`.
   */
  int _encodeElement(Element element) {
    if (element == null) {
      return null;
    }
    int id = elementIds[element];
    if (id == null) {
      id = elementIds.length;
      elementIds[element] = id;
    }
    return id;
  }

  /**
   * Returns an [Element]-sensitive encoding of [tokens].
   * Each [Token] with a [LocalVariableElement] has a suffix of the element id.
   *
   * So, we can distinguish different local variables with the same name, if
   * there are multiple variables with the same name are declared in the
   * function we are searching occurrences in.
   */
  String _encodeExpressionTokens(Expression expr, List<Token> tokens) {
    // no expression, i.e. a part of a string
    if (expr == null) {
      return tokens.join(_TOKEN_SEPARATOR);
    }
    // prepare Token -> LocalElement map
    Map<Token, Element> map = new HashMap<Token, Element>(
        equals: (Token a, Token b) => a.lexeme == b.lexeme,
        hashCode: (Token t) => t.lexeme.hashCode);
    expr.accept(new _TokenLocalElementVisitor(map));
    // map and join tokens
    return tokens.map((Token token) {
      String tokenString = token.lexeme;
      // append token's Element id
      Element element = map[token];
      if (element != null) {
        int elementId = _encodeElement(element);
        if (elementId != null) {
          tokenString += '-$elementId';
        }
      }
      // done
      return tokenString;
    }).join(_TOKEN_SEPARATOR);
  }

  /**
   * Return the [AstNode] to defined the variable before.
   * It should be accessible by all the given [occurrences].
   */
  AstNode _findDeclarationTarget(List<SourceRange> occurrences) {
    List<AstNode> nodes = _findNodes(occurrences);
    AstNode commonParent = getNearestCommonAncestor(nodes);
    // Block
    if (commonParent is Block) {
      List<AstNode> firstParents = getParents(nodes[0]);
      int commonIndex = firstParents.indexOf(commonParent);
      return firstParents[commonIndex + 1];
    }
    // ExpressionFunctionBody
    AstNode expressionBody = _getEnclosingExpressionBody(commonParent);
    if (expressionBody != null) {
      return expressionBody;
    }
    // single Statement
    AstNode target = commonParent.getAncestor((node) => node is Statement);
    while (target.parent is! Block) {
      target = target.parent;
    }
    return target;
  }

  /**
   * Returns [AstNode]s at the offsets of the given [SourceRange]s.
   */
  List<AstNode> _findNodes(List<SourceRange> ranges) {
    List<AstNode> nodes = <AstNode>[];
    for (SourceRange range in ranges) {
      AstNode node = new NodeLocator(range.offset).searchWithin(unit);
      nodes.add(node);
    }
    return nodes;
  }

  /**
   * Returns the [ExpressionFunctionBody] that encloses [node], or `null`
   * if [node] is not enclosed with an [ExpressionFunctionBody].
   */
  ExpressionFunctionBody _getEnclosingExpressionBody(AstNode node) {
    while (node != null) {
      if (node is Statement) {
        return null;
      }
      if (node is ExpressionFunctionBody) {
        return node;
      }
      node = node.parent;
    }
    return null;
  }

  /**
   * Checks if it is OK to extract the node with the given [SourceRange].
   */
  bool _isExtractable(SourceRange range) {
    _ExtractExpressionAnalyzer analyzer = new _ExtractExpressionAnalyzer(range);
    utils.unit.accept(analyzer);
    return analyzer.status.isOK;
  }

  bool _isPartOfConstantExpression(AstNode node) {
    if (node is TypedLiteral) {
      return node.isConst;
    }
    if (node is InstanceCreationExpression) {
      return node.isConst;
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

  void _prepareNames() {
    names.clear();
    if (stringLiteralPart != null) {
      names.addAll(getVariableNameSuggestionsForText(
          stringLiteralPart, excludedVariableNames));
    } else if (singleExpression != null) {
      names.addAll(getVariableNameSuggestionsForExpression(
          singleExpression.staticType,
          singleExpression,
          excludedVariableNames));
    }
  }

  /**
   * Prepares all occurrences of the source which matches given selection,
   * sorted by offsets.
   */
  void _prepareOccurrences() {
    occurrences.clear();
    elementIds.clear();
    // prepare selection
    String selectionSource;
    {
      String rawSelectionSource = utils.getRangeText(selectionRange);
      List<Token> selectionTokens = TokenUtils.getTokens(rawSelectionSource);
      selectionSource =
          _encodeExpressionTokens(rootExpression, selectionTokens);
    }
    // prepare enclosing function
    AstNode enclosingFunction;
    {
      AstNode selectionNode =
          new NodeLocator(selectionOffset).searchWithin(unit);
      enclosingFunction = getEnclosingExecutableNode(selectionNode);
    }
    // visit function
    enclosingFunction
        .accept(new _OccurrencesVisitor(this, occurrences, selectionSource));
  }

  void _prepareOffsetsLengths() {
    offsets.clear();
    lengths.clear();
    for (SourceRange occurrence in occurrences) {
      offsets.add(occurrence.offset);
      lengths.add(occurrence.length);
    }
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
      _invalidSelection('Cannot extract the left-hand side of an assignment.',
          newLocation_fromNode(lhs));
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
   * Records fatal error with given [message] and [location].
   */
  void _invalidSelection(String message, Location location) {
    status.addFatalError(message, location);
    reset();
  }

  bool _isFirstSelectedNode(AstNode node) => node == firstSelectedNode;
}

class _HasStatementVisitor extends GeneralizingAstVisitor {
  bool result = false;

  _HasStatementVisitor();

  @override
  visitStatement(Statement node) {
    result = true;
  }
}

class _OccurrencesVisitor extends GeneralizingAstVisitor<Object> {
  final ExtractLocalRefactoringImpl ref;
  final List<SourceRange> occurrences;
  final String selectionSource;

  _OccurrencesVisitor(this.ref, this.occurrences, this.selectionSource);

  @override
  Object visitBinaryExpression(BinaryExpression node) {
    if (!_hasStatements(node)) {
      _tryToFindOccurrenceFragments(node);
      return null;
    }
    return super.visitBinaryExpression(node);
  }

  @override
  Object visitExpression(Expression node) {
    if (ref._isExtractable(range.node(node))) {
      _tryToFindOccurrence(node);
    }
    return super.visitExpression(node);
  }

  @override
  Object visitStringLiteral(StringLiteral node) {
    if (ref.stringLiteralPart != null) {
      int length = ref.stringLiteralPart.length;
      String value = ref.utils.getNodeText(node);
      int lastIndex = 0;
      while (true) {
        int index = value.indexOf(ref.stringLiteralPart, lastIndex);
        if (index == -1) {
          break;
        }
        lastIndex = index + length;
        int start = node.offset + index;
        SourceRange range = new SourceRange(start, length);
        occurrences.add(range);
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
    _HasStatementVisitor visitor = new _HasStatementVisitor();
    root.accept(visitor);
    return visitor.result;
  }

  void _tryToFindOccurrence(Expression node) {
    String nodeSource = ref.utils.getNodeText(node);
    List<Token> nodeTokens = TokenUtils.getTokens(nodeSource);
    nodeSource = ref._encodeExpressionTokens(node, nodeTokens);
    if (nodeSource == selectionSource) {
      _addOccurrence(range.node(node));
    }
  }

  void _tryToFindOccurrenceFragments(Expression node) {
    int nodeOffset = node.offset;
    String nodeSource = ref.utils.getNodeText(node);
    List<Token> nodeTokens = TokenUtils.getTokens(nodeSource);
    nodeSource = ref._encodeExpressionTokens(node, nodeTokens);
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
      int start = nodeOffset + startToken.offset;
      int end = nodeOffset + endToken.end;
      _addOccurrence(range.startOffsetEndOffset(start, end));
    }
  }
}

class _TokenLocalElementVisitor extends RecursiveAstVisitor {
  final Map<Token, Element> map;

  _TokenLocalElementVisitor(this.map);

  visitSimpleIdentifier(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is LocalVariableElement) {
      map[node.token] = element;
    }
  }
}
