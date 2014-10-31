// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.correction.assist;

import 'dart:collection';

import 'package:analysis_server/src/protocol.dart' hide Element;
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/name_suggestion.dart';
import 'package:analysis_server/src/services/correction/source_buffer.dart';
import 'package:analysis_server/src/services/correction/source_range.dart';
import 'package:analysis_server/src/services/correction/statement_analyzer.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart';



typedef _SimpleIdentifierVisitor(SimpleIdentifier node);


/**
 * The computer for Dart assists.
 */
class AssistProcessor {
  final SearchEngine searchEngine;
  final Source source;
  final String file;
  int fileStamp;
  final CompilationUnit unit;
  final int selectionOffset;
  final int selectionLength;
  CompilationUnitElement unitElement;
  LibraryElement unitLibraryElement;
  String unitLibraryFile;
  String unitLibraryFolder;

  final List<SourceEdit> edits = <SourceEdit>[];
  final Map<String, LinkedEditGroup> linkedPositionGroups = <String,
      LinkedEditGroup>{};
  Position exitPosition = null;
  final List<Assist> assists = <Assist>[];

  int selectionEnd;
  CorrectionUtils utils;
  AstNode node;

  AssistProcessor(this.searchEngine, this.source, this.file, this.unit,
      this.selectionOffset, this.selectionLength) {
    unitElement = unit.element;
    unitLibraryElement = unitElement.library;
    unitLibraryFile = unitLibraryElement.source.fullName;
    unitLibraryFolder = dirname(unitLibraryFile);
    fileStamp = unitElement.context.getModificationStamp(source);
    selectionEnd = selectionOffset + selectionLength;
  }

  /**
   * Returns the EOL to use for this [CompilationUnit].
   */
  String get eol => utils.endOfLine;

  List<Assist> compute() {
    utils = new CorrectionUtils(unit);
    node =
        new NodeLocator.con2(selectionOffset, selectionEnd).searchWithin(unit);
    // try to add proposals
    _addProposal_addTypeAnnotation_DeclaredIdentifier();
    _addProposal_addTypeAnnotation_VariableDeclaration();
    _addProposal_assignToLocalVariable();
    _addProposal_convertToBlockFunctionBody();
    _addProposal_convertToExpressionFunctionBody();
    _addProposal_convertToIsNot_onIs();
    _addProposal_convertToIsNot_onNot();
    _addProposal_convertToIsNotEmpty();
    _addProposal_exchangeOperands();
    _addProposal_importAddShow();
    _addProposal_introduceLocalTestedType();
    _addProposal_invertIf();
    _addProposal_joinIfStatementInner();
    _addProposal_joinIfStatementOuter();
    _addProposal_joinVariableDeclaration_onAssignment();
    _addProposal_joinVariableDeclaration_onDeclaration();
    _addProposal_removeTypeAnnotation();
    _addProposal_replaceConditionalWithIfElse();
    _addProposal_replaceIfElseWithConditional();
    _addProposal_splitAndCondition();
    _addProposal_splitVariableDeclaration();
    _addProposal_surroundWith();
    // done
    return assists;
  }

  FunctionBody getEnclosingFunctionBody() {
    {
      FunctionExpression function =
          node.getAncestor((node) => node is FunctionExpression);
      if (function != null) {
        return function.body;
      }
    }
    {
      FunctionDeclaration function =
          node.getAncestor((node) => node is FunctionDeclaration);
      if (function != null) {
        return function.functionExpression.body;
      }
    }
    {
      ConstructorDeclaration constructor =
          node.getAncestor((node) => node is ConstructorDeclaration);
      if (constructor != null) {
        return constructor.body;
      }
    }
    {
      MethodDeclaration method =
          node.getAncestor((node) => node is MethodDeclaration);
      if (method != null) {
        return method.body;
      }
    }
    return null;
  }

  void _addAssist(AssistKind kind, List args, {String assistFile}) {
    if (assistFile == null) {
      assistFile = file;
    }
    // check is there are any edits
    if (edits.isEmpty) {
      _coverageMarker();
      return;
    }
    // prepare file edit
    SourceFileEdit fileEdit = new SourceFileEdit(file, fileStamp);
    fileEdit.addAll(edits);
    // prepare Change
    String message = formatList(kind.message, args);
    SourceChange change = new SourceChange(message);
    change.addFileEdit(fileEdit);
    linkedPositionGroups.values.forEach(
        (group) => change.addLinkedEditGroup(group));
    change.selection = exitPosition;
    // add Assist
    Assist assist = new Assist(kind, change);
    assists.add(assist);
    // clear
    edits.clear();
    linkedPositionGroups.clear();
    exitPosition = null;
  }

  /**
   * Adds a new [Edit] to [edits].
   */
  void _addInsertEdit(int offset, String text) {
    SourceEdit edit = new SourceEdit(offset, 0, text);
    edits.add(edit);
  }

  void _addProposal_addTypeAnnotation_DeclaredIdentifier() {
    DeclaredIdentifier declaredIdentifier =
        node.getAncestor((n) => n is DeclaredIdentifier);
    if (declaredIdentifier == null) {
      ForEachStatement forEach = node.getAncestor((n) => n is ForEachStatement);
      int offset = node.offset;
      if (forEach != null &&
          forEach.iterable != null &&
          offset < forEach.iterable.offset) {
        declaredIdentifier = forEach.loopVariable;
      }
    }
    if (declaredIdentifier == null) {
      _coverageMarker();
      return;
    }
    // may be has type annotation already
    if (declaredIdentifier.type != null) {
      _coverageMarker();
      return;
    }
    // prepare type source
    String typeSource;
    DartType type = declaredIdentifier.identifier.bestType;
    if (type is InterfaceType || type is FunctionType) {
      typeSource = utils.getTypeSource(type);
    } else {
      _coverageMarker();
      return;
    }
    // add edit
    Token keyword = declaredIdentifier.keyword;
    if (keyword is KeywordToken && keyword.keyword == Keyword.VAR) {
      SourceRange range = rangeToken(keyword);
      _addReplaceEdit(range, typeSource);
    } else {
      _addInsertEdit(declaredIdentifier.identifier.offset, '$typeSource ');
    }
    // add proposal
    _addAssist(AssistKind.ADD_TYPE_ANNOTATION, []);
  }

  void _addProposal_addTypeAnnotation_VariableDeclaration() {
    AstNode node = this.node;
    // check if "var v = 42;^"
    if (node is VariableDeclarationStatement) {
      node = (node as VariableDeclarationStatement).variables;
    }
    // prepare VariableDeclarationList
    VariableDeclarationList declarationList =
        node.getAncestor((node) => node is VariableDeclarationList);
    if (declarationList == null) {
      _coverageMarker();
      return;
    }
    // may be has type annotation already
    if (declarationList.type != null) {
      _coverageMarker();
      return;
    }
    // prepare single VariableDeclaration
    List<VariableDeclaration> variables = declarationList.variables;
    if (variables.length != 1) {
      _coverageMarker();
      return;
    }
    VariableDeclaration variable = variables[0];
    // we need an initializer to get the type from
    Expression initializer = variable.initializer;
    if (initializer == null) {
      _coverageMarker();
      return;
    }
    DartType type = initializer.bestType;
    // prepare type source
    String typeSource;
    if (type is InterfaceType || type is FunctionType) {
      typeSource = utils.getTypeSource(type);
    } else {
      _coverageMarker();
      return;
    }
    // add edit
    Token keyword = declarationList.keyword;
    if (keyword is KeywordToken && keyword.keyword == Keyword.VAR) {
      SourceRange range = rangeToken(keyword);
      _addReplaceEdit(range, typeSource);
    } else {
      _addInsertEdit(variable.offset, '$typeSource ');
    }
    // add proposal
    _addAssist(AssistKind.ADD_TYPE_ANNOTATION, []);
  }

  void _addProposal_assignToLocalVariable() {
    // prepare enclosing ExpressionStatement
    Statement statement = node.getAncestor((node) => node is Statement);
    if (statement is! ExpressionStatement) {
      _coverageMarker();
      return;
    }
    ExpressionStatement expressionStatement = statement as ExpressionStatement;
    // prepare expression
    Expression expression = expressionStatement.expression;
    int offset = expression.offset;
    // ignore if already assignment
    if (expression is AssignmentExpression) {
      _coverageMarker();
      return;
    }
    // ignore "throw"
    if (expression is ThrowExpression) {
      _coverageMarker();
      return;
    }
    // prepare expression type
    DartType type = expression.bestType;
    if (type.isVoid) {
      _coverageMarker();
      return;
    }
    // prepare source
    SourceBuilder builder = new SourceBuilder(file, offset);
    builder.append("var ");
    // prepare excluded names
    Set<String> excluded = new Set<String>();
    {
      ScopedNameFinder scopedNameFinder = new ScopedNameFinder(offset);
      expression.accept(scopedNameFinder);
      excluded.addAll(scopedNameFinder.locals.keys.toSet());
    }
    // name(s)
    {
      List<String> suggestions =
          getVariableNameSuggestionsForExpression(type, expression, excluded);
      builder.startPosition("NAME");
      for (int i = 0; i < suggestions.length; i++) {
        String name = suggestions[i];
        if (i == 0) {
          builder.append(name);
        }
        builder.addSuggestion(LinkedEditSuggestionKind.VARIABLE, name);
      }
      builder.endPosition();
    }
    builder.append(" = ");
    // add proposal
    _insertBuilder(builder);
    _addAssist(AssistKind.ASSIGN_TO_LOCAL_VARIABLE, []);
  }

  void _addProposal_convertToBlockFunctionBody() {
    FunctionBody body = getEnclosingFunctionBody();
    // prepare expression body
    if (body is! ExpressionFunctionBody) {
      _coverageMarker();
      return;
    }
    Expression returnValue = (body as ExpressionFunctionBody).expression;
    // prepare prefix
    String prefix = utils.getNodePrefix(body.parent);
    // add change
    String indent = utils.getIndent(1);
    String returnSource = 'return ' + _getNodeText(returnValue);
    String newBodySource = "{$eol$prefix${indent}$returnSource;$eol$prefix}";
    _addReplaceEdit(rangeNode(body), newBodySource);
    // add proposal
    _addAssist(AssistKind.CONVERT_INTO_BLOCK_BODY, []);
  }

  void _addProposal_convertToExpressionFunctionBody() {
    // prepare current body
    FunctionBody body = getEnclosingFunctionBody();
    if (body is! BlockFunctionBody) {
      _coverageMarker();
      return;
    }
    // prepare return statement
    List<Statement> statements = (body as BlockFunctionBody).block.statements;
    if (statements.length != 1) {
      _coverageMarker();
      return;
    }
    if (statements[0] is! ReturnStatement) {
      _coverageMarker();
      return;
    }
    ReturnStatement returnStatement = statements[0] as ReturnStatement;
    // prepare returned expression
    Expression returnExpression = returnStatement.expression;
    if (returnExpression == null) {
      _coverageMarker();
      return;
    }
    // add change
    String newBodySource = "=> ${_getNodeText(returnExpression)}";
    if (body.parent is! FunctionExpression ||
        body.parent.parent is FunctionDeclaration) {
      newBodySource += ";";
    }
    _addReplaceEdit(rangeNode(body), newBodySource);
    // add proposal
    _addAssist(AssistKind.CONVERT_INTO_EXPRESSION_BODY, []);
  }

  void _addProposal_convertToIsNot_onIs() {
    // may be child of "is"
    AstNode node = this.node;
    while (node != null && node is! IsExpression) {
      node = node.parent;
    }
    // prepare "is"
    if (node is! IsExpression) {
      _coverageMarker();
      return;
    }
    IsExpression isExpression = node as IsExpression;
    if (isExpression.notOperator != null) {
      _coverageMarker();
      return;
    }
    // prepare enclosing ()
    AstNode parent = isExpression.parent;
    if (parent is! ParenthesizedExpression) {
      _coverageMarker();
      return;
    }
    ParenthesizedExpression parExpression = parent as ParenthesizedExpression;
    // prepare enclosing !()
    AstNode parent2 = parent.parent;
    if (parent2 is! PrefixExpression) {
      _coverageMarker();
      return;
    }
    PrefixExpression prefExpression = parent2 as PrefixExpression;
    if (prefExpression.operator.type != TokenType.BANG) {
      _coverageMarker();
      return;
    }
    // strip !()
    if (getExpressionParentPrecedence(prefExpression) >=
        TokenType.IS.precedence) {
      _addRemoveEdit(rangeToken(prefExpression.operator));
    } else {
      _addRemoveEdit(
          rangeStartEnd(prefExpression, parExpression.leftParenthesis));
      _addRemoveEdit(
          rangeStartEnd(parExpression.rightParenthesis, prefExpression));
    }
    _addInsertEdit(isExpression.isOperator.end, "!");
    // add proposal
    _addAssist(AssistKind.CONVERT_INTO_IS_NOT, []);
  }

  void _addProposal_convertToIsNot_onNot() {
    // may be () in prefix expression
    if (node is ParenthesizedExpression && node.parent is PrefixExpression) {
      node = node.parent;
    }
    // prepare !()
    if (node is! PrefixExpression) {
      _coverageMarker();
      return;
    }
    PrefixExpression prefExpression = node as PrefixExpression;
    // should be ! operator
    if (prefExpression.operator.type != TokenType.BANG) {
      _coverageMarker();
      return;
    }
    // prepare !()
    Expression operand = prefExpression.operand;
    if (operand is! ParenthesizedExpression) {
      _coverageMarker();
      return;
    }
    ParenthesizedExpression parExpression = operand as ParenthesizedExpression;
    operand = parExpression.expression;
    // prepare "is"
    if (operand is! IsExpression) {
      _coverageMarker();
      return;
    }
    IsExpression isExpression = operand as IsExpression;
    if (isExpression.notOperator != null) {
      _coverageMarker();
      return;
    }
    // strip !()
    if (getExpressionParentPrecedence(prefExpression) >=
        TokenType.IS.precedence) {
      _addRemoveEdit(rangeToken(prefExpression.operator));
    } else {
      _addRemoveEdit(
          rangeStartEnd(prefExpression, parExpression.leftParenthesis));
      _addRemoveEdit(
          rangeStartEnd(parExpression.rightParenthesis, prefExpression));
    }
    _addInsertEdit(isExpression.isOperator.end, "!");
    // add proposal
    _addAssist(AssistKind.CONVERT_INTO_IS_NOT, []);
  }

  /**
   * Converts "!isEmpty" -> "isNotEmpty" if possible.
   */
  void _addProposal_convertToIsNotEmpty() {
    // prepare "expr.isEmpty"
    AstNode isEmptyAccess = null;
    SimpleIdentifier isEmptyIdentifier = null;
    if (node is SimpleIdentifier) {
      SimpleIdentifier identifier = node as SimpleIdentifier;
      AstNode parent = identifier.parent;
      // normal case (but rare)
      if (parent is PropertyAccess) {
        isEmptyIdentifier = parent.propertyName;
        isEmptyAccess = parent;
      }
      // usual case
      if (parent is PrefixedIdentifier) {
        isEmptyIdentifier = parent.identifier;
        isEmptyAccess = parent;
      }
    }
    if (isEmptyIdentifier == null) {
      _coverageMarker();
      return;
    }
    // should be "isEmpty"
    Element propertyElement = isEmptyIdentifier.bestElement;
    if (propertyElement == null || "isEmpty" != propertyElement.name) {
      _coverageMarker();
      return;
    }
    // should have "isNotEmpty"
    Element propertyTarget = propertyElement.enclosingElement;
    if (propertyTarget == null ||
        getChildren(propertyTarget, "isNotEmpty").isEmpty) {
      _coverageMarker();
      return;
    }
    // should be in PrefixExpression
    if (isEmptyAccess.parent is! PrefixExpression) {
      _coverageMarker();
      return;
    }
    PrefixExpression prefixExpression =
        isEmptyAccess.parent as PrefixExpression;
    // should be !
    if (prefixExpression.operator.type != TokenType.BANG) {
      return;
    }
    // do replace
    _addRemoveEdit(rangeStartStart(prefixExpression, prefixExpression.operand));
    _addReplaceEdit(rangeNode(isEmptyIdentifier), "isNotEmpty");
    // add proposal
    _addAssist(AssistKind.CONVERT_INTO_IS_NOT_EMPTY, []);
  }

  void _addProposal_exchangeOperands() {
    // check that user invokes quick assist on binary expression
    if (node is! BinaryExpression) {
      _coverageMarker();
      return;
    }
    BinaryExpression binaryExpression = node as BinaryExpression;
    // prepare operator position
    if (!_isOperatorSelected(
        binaryExpression,
        selectionOffset,
        selectionLength)) {
      _coverageMarker();
      return;
    }
    // add edits
    {
      Expression leftOperand = binaryExpression.leftOperand;
      Expression rightOperand = binaryExpression.rightOperand;
      // find "wide" enclosing binary expression with same operator
      while (binaryExpression.parent is BinaryExpression) {
        BinaryExpression newBinaryExpression =
            binaryExpression.parent as BinaryExpression;
        if (newBinaryExpression.operator.type !=
            binaryExpression.operator.type) {
          _coverageMarker();
          break;
        }
        binaryExpression = newBinaryExpression;
      }
      // exchange parts of "wide" expression parts
      SourceRange leftRange = rangeStartEnd(binaryExpression, leftOperand);
      SourceRange rightRange = rangeStartEnd(rightOperand, binaryExpression);
      _addReplaceEdit(leftRange, _getRangeText(rightRange));
      _addReplaceEdit(rightRange, _getRangeText(leftRange));
    }
    // add proposal
    _addAssist(AssistKind.EXCHANGE_OPERANDS, []);
  }

  void _addProposal_importAddShow() {
    // prepare ImportDirective
    ImportDirective importDirective =
        node.getAncestor((node) => node is ImportDirective);
    if (importDirective == null) {
      _coverageMarker();
      return;
    }
    // there should be no existing combinators
    if (importDirective.combinators.isNotEmpty) {
      _coverageMarker();
      return;
    }
    // prepare whole import namespace
    ImportElement importElement = importDirective.element;
    if (importElement == null) {
      _coverageMarker();
      return;
    }
    Map<String, Element> namespace = getImportNamespace(importElement);
    // prepare names of referenced elements (from this import)
    SplayTreeSet<String> referencedNames = new SplayTreeSet<String>();
    _SimpleIdentifierRecursiveAstVisitor visitor =
        new _SimpleIdentifierRecursiveAstVisitor((SimpleIdentifier node) {
      Element element = node.staticElement;
      if (element != null && namespace[node.name] == element) {
        referencedNames.add(element.displayName);
      }
    });
    unit.accept(visitor);
    // ignore if unused
    if (referencedNames.isEmpty) {
      _coverageMarker();
      return;
    }
    // prepare change
    String showCombinator = " show ${StringUtils.join(referencedNames, ", ")}";
    _addInsertEdit(importDirective.end - 1, showCombinator);
    // add proposal
    _addAssist(AssistKind.IMPORT_ADD_SHOW, []);
  }

  void _addProposal_introduceLocalTestedType() {
    AstNode node = this.node;
    if (node is IfStatement) {
      node = (node as IfStatement).condition;
    } else if (node is WhileStatement) {
      node = (node as WhileStatement).condition;
    }
    // prepare IsExpression
    if (node is! IsExpression) {
      _coverageMarker();
      return;
    }
    IsExpression isExpression = node;
    DartType castType = isExpression.type.type;
    String castTypeCode = _getNodeText(isExpression.type);
    // prepare environment
    String indent = utils.getIndent(1);
    String prefix;
    Block targetBlock;
    {
      Statement statement = node.getAncestor((n) => n is Statement);
      prefix = utils.getNodePrefix(statement);
      if (statement is IfStatement && statement.thenStatement is Block) {
        targetBlock = statement.thenStatement;
      }
      if (statement is WhileStatement && statement.body is Block) {
        targetBlock = statement.body;
      }
    }
    if (targetBlock == null) {
      _coverageMarker();
      return;
    }
    // prepare source
    int offset = targetBlock.leftBracket.end;
    SourceBuilder builder = new SourceBuilder(file, offset);
    builder.append(eol + prefix + indent);
    builder.append(castTypeCode);
    // prepare excluded names
    Set<String> excluded = new Set<String>();
    {
      ScopedNameFinder scopedNameFinder = new ScopedNameFinder(offset);
      isExpression.accept(scopedNameFinder);
      excluded.addAll(scopedNameFinder.locals.keys.toSet());
    }
    // name(s)
    {
      List<String> suggestions =
          getVariableNameSuggestionsForExpression(castType, null, excluded);
      builder.append(' ');
      builder.startPosition('NAME');
      for (int i = 0; i < suggestions.length; i++) {
        String name = suggestions[i];
        if (i == 0) {
          builder.append(name);
        }
        builder.addSuggestion(LinkedEditSuggestionKind.VARIABLE, name);
      }
      builder.endPosition();
    }
    builder.append(' = ');
    builder.append(_getNodeText(isExpression.expression));
    builder.append(';');
    builder.setExitOffset();
    // add proposal
    _insertBuilder(builder);
    _addAssist(AssistKind.INTRODUCE_LOCAL_CAST_TYPE, []);
  }

  void _addProposal_invertIf() {
    if (node is! IfStatement) {
      return;
    }
    IfStatement ifStatement = node as IfStatement;
    Expression condition = ifStatement.condition;
    // should have both "then" and "else"
    Statement thenStatement = ifStatement.thenStatement;
    Statement elseStatement = ifStatement.elseStatement;
    if (thenStatement == null || elseStatement == null) {
      return;
    }
    // prepare source
    String invertedCondition = utils.invertCondition(condition);
    String thenSource = _getNodeText(thenStatement);
    String elseSource = _getNodeText(elseStatement);
    // do replacements
    _addReplaceEdit(rangeNode(condition), invertedCondition);
    _addReplaceEdit(rangeNode(thenStatement), elseSource);
    _addReplaceEdit(rangeNode(elseStatement), thenSource);
    // add proposal
    _addAssist(AssistKind.INVERT_IF_STATEMENT, []);
  }

  void _addProposal_joinIfStatementInner() {
    // climb up condition to the (supposedly) "if" statement
    AstNode node = this.node;
    while (node is Expression) {
      node = node.parent;
    }
    // prepare target "if" statement
    if (node is! IfStatement) {
      _coverageMarker();
      return;
    }
    IfStatement targetIfStatement = node as IfStatement;
    if (targetIfStatement.elseStatement != null) {
      _coverageMarker();
      return;
    }
    // prepare inner "if" statement
    Statement targetThenStatement = targetIfStatement.thenStatement;
    Statement innerStatement = getSingleStatement(targetThenStatement);
    if (innerStatement is! IfStatement) {
      _coverageMarker();
      return;
    }
    IfStatement innerIfStatement = innerStatement as IfStatement;
    if (innerIfStatement.elseStatement != null) {
      _coverageMarker();
      return;
    }
    // prepare environment
    String prefix = utils.getNodePrefix(targetIfStatement);
    // merge conditions
    String condition;
    {
      Expression targetCondition = targetIfStatement.condition;
      Expression innerCondition = innerIfStatement.condition;
      String targetConditionSource = _getNodeText(targetCondition);
      String innerConditionSource = _getNodeText(innerCondition);
      if (_shouldWrapParenthesisBeforeAnd(targetCondition)) {
        targetConditionSource = "(${targetConditionSource})";
      }
      if (_shouldWrapParenthesisBeforeAnd(innerCondition)) {
        innerConditionSource = "(${innerConditionSource})";
      }
      condition = "${targetConditionSource} && ${innerConditionSource}";
    }
    // replace target "if" statement
    {
      Statement innerThenStatement = innerIfStatement.thenStatement;
      List<Statement> innerThenStatements = getStatements(innerThenStatement);
      SourceRange lineRanges =
          utils.getLinesRangeStatements(innerThenStatements);
      String oldSource = utils.getRangeText(lineRanges);
      String newSource = utils.indentSourceLeftRight(oldSource, false);
      _addReplaceEdit(
          rangeNode(targetIfStatement),
          "if ($condition) {${eol}${newSource}${prefix}}");
    }
    // done
    _addAssist(AssistKind.JOIN_IF_WITH_INNER, []);
  }

  void _addProposal_joinIfStatementOuter() {
    // climb up condition to the (supposedly) "if" statement
    AstNode node = this.node;
    while (node is Expression) {
      node = node.parent;
    }
    // prepare target "if" statement
    if (node is! IfStatement) {
      _coverageMarker();
      return;
    }
    IfStatement targetIfStatement = node as IfStatement;
    if (targetIfStatement.elseStatement != null) {
      _coverageMarker();
      return;
    }
    // prepare outer "if" statement
    AstNode parent = targetIfStatement.parent;
    if (parent is Block) {
      parent = parent.parent;
    }
    if (parent is! IfStatement) {
      _coverageMarker();
      return;
    }
    IfStatement outerIfStatement = parent as IfStatement;
    if (outerIfStatement.elseStatement != null) {
      _coverageMarker();
      return;
    }
    // prepare environment
    String prefix = utils.getNodePrefix(outerIfStatement);
    // merge conditions
    String condition;
    {
      Expression targetCondition = targetIfStatement.condition;
      Expression outerCondition = outerIfStatement.condition;
      String targetConditionSource = _getNodeText(targetCondition);
      String outerConditionSource = _getNodeText(outerCondition);
      if (_shouldWrapParenthesisBeforeAnd(targetCondition)) {
        targetConditionSource = "(${targetConditionSource})";
      }
      if (_shouldWrapParenthesisBeforeAnd(outerCondition)) {
        outerConditionSource = "(${outerConditionSource})";
      }
      condition = "${outerConditionSource} && ${targetConditionSource}";
    }
    // replace outer "if" statement
    {
      Statement targetThenStatement = targetIfStatement.thenStatement;
      List<Statement> targetThenStatements = getStatements(targetThenStatement);
      SourceRange lineRanges =
          utils.getLinesRangeStatements(targetThenStatements);
      String oldSource = utils.getRangeText(lineRanges);
      String newSource = utils.indentSourceLeftRight(oldSource, false);
      _addReplaceEdit(
          rangeNode(outerIfStatement),
          "if ($condition) {${eol}${newSource}${prefix}}");
    }
    // done
    _addAssist(AssistKind.JOIN_IF_WITH_OUTER, []);
  }

  void _addProposal_joinVariableDeclaration_onAssignment() {
    // check that node is LHS in assignment
    if (node is SimpleIdentifier &&
        node.parent is AssignmentExpression &&
        (node.parent as AssignmentExpression).leftHandSide == node &&
        node.parent.parent is ExpressionStatement) {
    } else {
      _coverageMarker();
      return;
    }
    AssignmentExpression assignExpression = node.parent as AssignmentExpression;
    // check that binary expression is assignment
    if (assignExpression.operator.type != TokenType.EQ) {
      _coverageMarker();
      return;
    }
    // prepare "declaration" statement
    Element element = (node as SimpleIdentifier).staticElement;
    if (element == null) {
      _coverageMarker();
      return;
    }
    int declOffset = element.nameOffset;
    AstNode declNode = new NodeLocator.con1(declOffset).searchWithin(unit);
    if (declNode != null &&
        declNode.parent is VariableDeclaration &&
        (declNode.parent as VariableDeclaration).name == declNode &&
        declNode.parent.parent is VariableDeclarationList &&
        declNode.parent.parent.parent is VariableDeclarationStatement) {
    } else {
      _coverageMarker();
      return;
    }
    VariableDeclaration decl = declNode.parent as VariableDeclaration;
    VariableDeclarationStatement declStatement =
        decl.parent.parent as VariableDeclarationStatement;
    // may be has initializer
    if (decl.initializer != null) {
      _coverageMarker();
      return;
    }
    // check that "declaration" statement declared only one variable
    if (declStatement.variables.variables.length != 1) {
      _coverageMarker();
      return;
    }
    // check that the "declaration" and "assignment" statements are
    // parts of the same Block
    ExpressionStatement assignStatement =
        node.parent.parent as ExpressionStatement;
    if (assignStatement.parent is Block &&
        assignStatement.parent == declStatement.parent) {
    } else {
      _coverageMarker();
      return;
    }
    Block block = assignStatement.parent as Block;
    // check that "declaration" and "assignment" statements are adjacent
    List<Statement> statements = block.statements;
    if (statements.indexOf(assignStatement) ==
        statements.indexOf(declStatement) + 1) {
    } else {
      _coverageMarker();
      return;
    }
    // add edits
    {
      int assignOffset = assignExpression.operator.offset;
      _addReplaceEdit(rangeEndStart(declNode, assignOffset), " ");
    }
    // add proposal
    _addAssist(AssistKind.JOIN_VARIABLE_DECLARATION, []);
  }

  void _addProposal_joinVariableDeclaration_onDeclaration() {
    // prepare enclosing VariableDeclarationList
    VariableDeclarationList declList =
        node.getAncestor((node) => node is VariableDeclarationList);
    if (declList != null && declList.variables.length == 1) {
    } else {
      _coverageMarker();
      return;
    }
    VariableDeclaration decl = declList.variables[0];
    // already initialized
    if (decl.initializer != null) {
      _coverageMarker();
      return;
    }
    // prepare VariableDeclarationStatement in Block
    if (declList.parent is VariableDeclarationStatement &&
        declList.parent.parent is Block) {
    } else {
      _coverageMarker();
      return;
    }
    VariableDeclarationStatement declStatement =
        declList.parent as VariableDeclarationStatement;
    Block block = declStatement.parent as Block;
    List<Statement> statements = block.statements;
    // prepare assignment
    AssignmentExpression assignExpression;
    {
      // declaration should not be last Statement
      int declIndex = statements.indexOf(declStatement);
      if (declIndex < statements.length - 1) {
      } else {
        _coverageMarker();
        return;
      }
      // next Statement should be assignment
      Statement assignStatement = statements[declIndex + 1];
      if (assignStatement is ExpressionStatement) {
      } else {
        _coverageMarker();
        return;
      }
      ExpressionStatement expressionStatement =
          assignStatement as ExpressionStatement;
      // expression should be assignment
      if (expressionStatement.expression is AssignmentExpression) {
      } else {
        _coverageMarker();
        return;
      }
      assignExpression = expressionStatement.expression as AssignmentExpression;
    }
    // check that pure assignment
    if (assignExpression.operator.type != TokenType.EQ) {
      _coverageMarker();
      return;
    }
    // add edits
    {
      int assignOffset = assignExpression.operator.offset;
      _addReplaceEdit(rangeEndStart(decl.name, assignOffset), " ");
    }
    // add proposal
    _addAssist(AssistKind.JOIN_VARIABLE_DECLARATION, []);
  }

  void _addProposal_removeTypeAnnotation() {
    AstNode typeStart = null;
    AstNode typeEnd = null;
    // try top-level variable
    {
      TopLevelVariableDeclaration declaration =
          node.getAncestor((node) => node is TopLevelVariableDeclaration);
      if (declaration != null) {
        TypeName typeNode = declaration.variables.type;
        if (typeNode != null) {
          VariableDeclaration field = declaration.variables.variables[0];
          typeStart = declaration;
          typeEnd = field;
        }
      }
    }
    // try class field
    {
      FieldDeclaration fieldDeclaration =
          node.getAncestor((node) => node is FieldDeclaration);
      if (fieldDeclaration != null) {
        TypeName typeNode = fieldDeclaration.fields.type;
        if (typeNode != null) {
          VariableDeclaration field = fieldDeclaration.fields.variables[0];
          typeStart = fieldDeclaration;
          typeEnd = field;
        }
      }
    }
    // try local variable
    {
      VariableDeclarationStatement statement =
          node.getAncestor((node) => node is VariableDeclarationStatement);
      if (statement != null) {
        TypeName typeNode = statement.variables.type;
        if (typeNode != null) {
          VariableDeclaration variable = statement.variables.variables[0];
          typeStart = typeNode;
          typeEnd = variable;
        }
      }
    }
    // add edit
    if (typeStart != null && typeEnd != null) {
      SourceRange typeRange = rangeStartStart(typeStart, typeEnd);
      _addReplaceEdit(typeRange, "var ");
    }
    // add proposal
    _addAssist(AssistKind.REMOVE_TYPE_ANNOTATION, []);
  }

  void _addProposal_replaceConditionalWithIfElse() {
    ConditionalExpression conditional = null;
    // may be on Statement with Conditional
    Statement statement = node.getAncestor((node) => node is Statement);
    if (statement == null) {
      _coverageMarker();
      return;
    }
    // variable declaration
    bool inVariable = false;
    if (statement is VariableDeclarationStatement) {
      VariableDeclarationStatement variableStatement = statement;
      for (VariableDeclaration variable in
          variableStatement.variables.variables) {
        if (variable.initializer is ConditionalExpression) {
          conditional = variable.initializer as ConditionalExpression;
          inVariable = true;
          break;
        }
      }
    }
    // assignment
    bool inAssignment = false;
    if (statement is ExpressionStatement) {
      ExpressionStatement exprStmt = statement;
      if (exprStmt.expression is AssignmentExpression) {
        AssignmentExpression assignment =
            exprStmt.expression as AssignmentExpression;
        if (assignment.operator.type == TokenType.EQ &&
            assignment.rightHandSide is ConditionalExpression) {
          conditional = assignment.rightHandSide as ConditionalExpression;
          inAssignment = true;
        }
      }
    }
    // return
    bool inReturn = false;
    if (statement is ReturnStatement) {
      ReturnStatement returnStatement = statement;
      if (returnStatement.expression is ConditionalExpression) {
        conditional = returnStatement.expression as ConditionalExpression;
        inReturn = true;
      }
    }
    // prepare environment
    String indent = utils.getIndent(1);
    String prefix = utils.getNodePrefix(statement);
    // Type v = Conditional;
    if (inVariable) {
      VariableDeclaration variable = conditional.parent as VariableDeclaration;
      _addRemoveEdit(rangeEndEnd(variable.name, conditional));
      String conditionSrc = _getNodeText(conditional.condition);
      String thenSrc = _getNodeText(conditional.thenExpression);
      String elseSrc = _getNodeText(conditional.elseExpression);
      String name = variable.name.name;
      String src = eol;
      src += prefix + 'if ($conditionSrc) {' + eol;
      src += prefix + indent + '$name = $thenSrc;' + eol;
      src += prefix + '} else {' + eol;
      src += prefix + indent + '$name = $elseSrc;' + eol;
      src += prefix + '}';
      _addReplaceEdit(rangeEndLength(statement, 0), src);
    }
    // v = Conditional;
    if (inAssignment) {
      AssignmentExpression assignment =
          conditional.parent as AssignmentExpression;
      Expression leftSide = assignment.leftHandSide;
      String conditionSrc = _getNodeText(conditional.condition);
      String thenSrc = _getNodeText(conditional.thenExpression);
      String elseSrc = _getNodeText(conditional.elseExpression);
      String name = _getNodeText(leftSide);
      String src = '';
      src += 'if ($conditionSrc) {' + eol;
      src += prefix + indent + '$name = $thenSrc;' + eol;
      src += prefix + '} else {' + eol;
      src += prefix + indent + '$name = $elseSrc;' + eol;
      src += prefix + '}';
      _addReplaceEdit(rangeNode(statement), src);
    }
    // return Conditional;
    if (inReturn) {
      String conditionSrc = _getNodeText(conditional.condition);
      String thenSrc = _getNodeText(conditional.thenExpression);
      String elseSrc = _getNodeText(conditional.elseExpression);
      String src = '';
      src += 'if ($conditionSrc) {' + eol;
      src += prefix + indent + 'return $thenSrc;' + eol;
      src += prefix + '} else {' + eol;
      src += prefix + indent + 'return $elseSrc;' + eol;
      src += prefix + '}';
      _addReplaceEdit(rangeNode(statement), src);
    }
    // add proposal
    _addAssist(AssistKind.REPLACE_CONDITIONAL_WITH_IF_ELSE, []);
  }

  void _addProposal_replaceIfElseWithConditional() {
    // should be "if"
    if (node is! IfStatement) {
      _coverageMarker();
      return;
    }
    IfStatement ifStatement = node as IfStatement;
    // single then/else statements
    Statement thenStatement = getSingleStatement(ifStatement.thenStatement);
    Statement elseStatement = getSingleStatement(ifStatement.elseStatement);
    if (thenStatement == null || elseStatement == null) {
      _coverageMarker();
      return;
    }
    // returns
    if (thenStatement is ReturnStatement || elseStatement is ReturnStatement) {
      ReturnStatement thenReturn = thenStatement as ReturnStatement;
      ReturnStatement elseReturn = elseStatement as ReturnStatement;
      String conditionSrc = _getNodeText(ifStatement.condition);
      String theSrc = _getNodeText(thenReturn.expression);
      String elseSrc = _getNodeText(elseReturn.expression);
      _addReplaceEdit(
          rangeNode(ifStatement),
          'return $conditionSrc ? $theSrc : $elseSrc;');
    }
    // assignments -> v = Conditional;
    if (thenStatement is ExpressionStatement &&
        elseStatement is ExpressionStatement) {
      Expression thenExpression = thenStatement.expression;
      Expression elseExpression = elseStatement.expression;
      if (thenExpression is AssignmentExpression &&
          elseExpression is AssignmentExpression) {
        AssignmentExpression thenAssignment = thenExpression;
        AssignmentExpression elseAssignment = elseExpression;
        String thenTarget = _getNodeText(thenAssignment.leftHandSide);
        String elseTarget = _getNodeText(elseAssignment.leftHandSide);
        if (thenAssignment.operator.type == TokenType.EQ &&
            elseAssignment.operator.type == TokenType.EQ &&
            StringUtils.equals(thenTarget, elseTarget)) {
          String conditionSrc = _getNodeText(ifStatement.condition);
          String theSrc = _getNodeText(thenAssignment.rightHandSide);
          String elseSrc = _getNodeText(elseAssignment.rightHandSide);
          _addReplaceEdit(
              rangeNode(ifStatement),
              '$thenTarget = $conditionSrc ? $theSrc : $elseSrc;');
        }
      }
    }
    // add proposal
    _addAssist(AssistKind.REPLACE_IF_ELSE_WITH_CONDITIONAL, []);
  }

  void _addProposal_splitAndCondition() {
    // check that user invokes quick assist on binary expression
    if (node is! BinaryExpression) {
      _coverageMarker();
      return;
    }
    BinaryExpression binaryExpression = node as BinaryExpression;
    // prepare operator position
    if (!_isOperatorSelected(
        binaryExpression,
        selectionOffset,
        selectionLength)) {
      _coverageMarker();
      return;
    }
    // should be &&
    if (binaryExpression.operator.type != TokenType.AMPERSAND_AMPERSAND) {
      _coverageMarker();
      return;
    }
    // prepare "if"
    Statement statement = node.getAncestor((node) => node is Statement);
    if (statement is! IfStatement) {
      _coverageMarker();
      return;
    }
    IfStatement ifStatement = statement as IfStatement;
    // check that binary expression is part of first level && condition of "if"
    BinaryExpression condition = binaryExpression;
    while (condition.parent is BinaryExpression &&
        (condition.parent as BinaryExpression).operator.type ==
            TokenType.AMPERSAND_AMPERSAND) {
      condition = condition.parent as BinaryExpression;
    }
    if (ifStatement.condition != condition) {
      _coverageMarker();
      return;
    }
    // prepare environment
    String prefix = utils.getNodePrefix(ifStatement);
    String indent = utils.getIndent(1);
    // prepare "rightCondition"
    String rightConditionSource;
    {
      SourceRange rightConditionRange =
          rangeStartEnd(binaryExpression.rightOperand, condition);
      rightConditionSource = _getRangeText(rightConditionRange);
    }
    // remove "&& rightCondition"
    _addRemoveEdit(rangeEndEnd(binaryExpression.leftOperand, condition));
    // update "then" statement
    Statement thenStatement = ifStatement.thenStatement;
    Statement elseStatement = ifStatement.elseStatement;
    if (thenStatement is Block) {
      Block thenBlock = thenStatement;
      SourceRange thenBlockRange = rangeNode(thenBlock);
      // insert inner "if" with right part of "condition"
      {
        String source =
            "${eol}${prefix}${indent}if (${rightConditionSource}) {";
        int thenBlockInsideOffset = thenBlockRange.offset + 1;
        _addInsertEdit(thenBlockInsideOffset, source);
      }
      // insert closing "}" for inner "if"
      {
        int thenBlockEnd = thenBlockRange.end;
        String source = "${indent}}";
        // may be move "else" statements
        if (elseStatement != null) {
          List<Statement> elseStatements = getStatements(elseStatement);
          SourceRange elseLinesRange =
              utils.getLinesRangeStatements(elseStatements);
          String elseIndentOld = "${prefix}${indent}";
          String elseIndentNew = "${elseIndentOld}${indent}";
          String newElseSource =
              utils.replaceSourceRangeIndent(elseLinesRange, elseIndentOld, elseIndentNew);
          // append "else" block
          source += " else {${eol}";
          source += newElseSource;
          source += "${prefix}${indent}}";
          // remove old "else" range
          _addRemoveEdit(rangeStartEnd(thenBlockEnd, elseStatement));
        }
        // insert before outer "then" block "}"
        source += "${eol}${prefix}";
        _addInsertEdit(thenBlockEnd - 1, source);
      }
    } else {
      // insert inner "if" with right part of "condition"
      {
        String source = "${eol}${prefix}${indent}if (${rightConditionSource})";
        _addInsertEdit(ifStatement.rightParenthesis.offset + 1, source);
      }
      // indent "else" statements to correspond inner "if"
      if (elseStatement != null) {
        SourceRange elseRange =
            rangeStartEnd(ifStatement.elseKeyword.offset, elseStatement);
        SourceRange elseLinesRange = utils.getLinesRange(elseRange);
        String elseIndentOld = prefix;
        String elseIndentNew = "${elseIndentOld}${indent}";
        edits.add(
            utils.createIndentEdit(elseLinesRange, elseIndentOld, elseIndentNew));
      }
    }
    // indent "then" statements to correspond inner "if"
    {
      List<Statement> thenStatements = getStatements(thenStatement);
      SourceRange linesRange = utils.getLinesRangeStatements(thenStatements);
      String thenIndentOld = "${prefix}${indent}";
      String thenIndentNew = "${thenIndentOld}${indent}";
      edits.add(
          utils.createIndentEdit(linesRange, thenIndentOld, thenIndentNew));
    }
    // add proposal
    _addAssist(AssistKind.SPLIT_AND_CONDITION, []);
  }

  void _addProposal_splitVariableDeclaration() {
    // prepare DartVariableStatement, should be part of Block
    VariableDeclarationStatement statement =
        node.getAncestor((node) => node is VariableDeclarationStatement);
    if (statement != null && statement.parent is Block) {
    } else {
      _coverageMarker();
      return;
    }
    // check that statement declares single variable
    List<VariableDeclaration> variables = statement.variables.variables;
    if (variables.length != 1) {
      _coverageMarker();
      return;
    }
    VariableDeclaration variable = variables[0];
    // prepare initializer
    Expression initializer = variable.initializer;
    if (initializer == null) {
      _coverageMarker();
      return;
    }
    // remove initializer value
    _addRemoveEdit(rangeEndStart(variable.name, statement.semicolon));
    // add assignment statement
    String indent = utils.getNodePrefix(statement);
    String name = variable.name.name;
    String initSrc = _getNodeText(initializer);
    SourceRange assignRange = rangeEndLength(statement, 0);
    _addReplaceEdit(assignRange, eol + indent + name + ' = ' + initSrc + ';');
    // add proposal
    _addAssist(AssistKind.SPLIT_VARIABLE_DECLARATION, []);
  }

  void _addProposal_surroundWith() {
    // prepare selected statements
    List<Statement> selectedStatements;
    {
      SourceRange selection =
          rangeStartLength(selectionOffset, selectionLength);
      StatementAnalyzer selectionAnalyzer =
          new StatementAnalyzer(unit, selection);
      unit.accept(selectionAnalyzer);
      List<AstNode> selectedNodes = selectionAnalyzer.selectedNodes;
      // convert nodes to statements
      selectedStatements = [];
      for (AstNode selectedNode in selectedNodes) {
        if (selectedNode is Statement) {
          selectedStatements.add(selectedNode);
        }
      }
      // we want only statements
      if (selectedStatements.isEmpty ||
          selectedStatements.length != selectedNodes.length) {
        return;
      }
    }
    // prepare statement information
    Statement firstStatement = selectedStatements[0];
    Statement lastStatement = selectedStatements[selectedStatements.length - 1];
    SourceRange statementsRange =
        utils.getLinesRangeStatements(selectedStatements);
    // prepare environment
    String indentOld = utils.getNodePrefix(firstStatement);
    String indentNew = "${indentOld}${utils.getIndent(1)}";
    // "block"
    {
      _addInsertEdit(statementsRange.offset, "${indentOld}{${eol}");
      {
        SourceEdit edit =
            utils.createIndentEdit(statementsRange, indentOld, indentNew);
        edits.add(edit);
      }
      _addInsertEdit(statementsRange.end, "${indentOld}}${eol}");
      exitPosition = _newPosition(lastStatement.end);
      // add proposal
      _addAssist(AssistKind.SURROUND_WITH_BLOCK, []);
    }
    // "if"
    {
      {
        int offset = statementsRange.offset;
        SourceBuilder sb = new SourceBuilder(file, offset);
        sb.append(indentOld);
        sb.append("if (");
        {
          sb.startPosition("CONDITION");
          sb.append("condition");
          sb.endPosition();
        }
        sb.append(") {");
        sb.append(eol);
        _insertBuilder(sb);
      }
      {
        SourceEdit edit =
            utils.createIndentEdit(statementsRange, indentOld, indentNew);
        edits.add(edit);
      }
      _addInsertEdit(statementsRange.end, "${indentOld}}${eol}");
      exitPosition = _newPosition(lastStatement.end);
      // add proposal
      _addAssist(AssistKind.SURROUND_WITH_IF, []);
    }
    // "while"
    {
      {
        int offset = statementsRange.offset;
        SourceBuilder sb = new SourceBuilder(file, offset);
        sb.append(indentOld);
        sb.append("while (");
        {
          sb.startPosition("CONDITION");
          sb.append("condition");
          sb.endPosition();
        }
        sb.append(") {");
        sb.append(eol);
        _insertBuilder(sb);
      }
      {
        SourceEdit edit =
            utils.createIndentEdit(statementsRange, indentOld, indentNew);
        edits.add(edit);
      }
      _addInsertEdit(statementsRange.end, "${indentOld}}${eol}");
      exitPosition = _newPosition(lastStatement.end);
      // add proposal
      _addAssist(AssistKind.SURROUND_WITH_WHILE, []);
    }
    // "for-in"
    {
      {
        int offset = statementsRange.offset;
        SourceBuilder sb = new SourceBuilder(file, offset);
        sb.append(indentOld);
        sb.append("for (var ");
        {
          sb.startPosition("NAME");
          sb.append("item");
          sb.endPosition();
        }
        sb.append(" in ");
        {
          sb.startPosition("ITERABLE");
          sb.append("iterable");
          sb.endPosition();
        }
        sb.append(") {");
        sb.append(eol);
        _insertBuilder(sb);
      }
      {
        SourceEdit edit =
            utils.createIndentEdit(statementsRange, indentOld, indentNew);
        edits.add(edit);
      }
      _addInsertEdit(statementsRange.end, "${indentOld}}${eol}");
      exitPosition = _newPosition(lastStatement.end);
      // add proposal
      _addAssist(AssistKind.SURROUND_WITH_FOR_IN, []);
    }
    // "for"
    {
      {
        int offset = statementsRange.offset;
        SourceBuilder sb = new SourceBuilder(file, offset);
        sb.append(indentOld);
        sb.append("for (var ");
        {
          sb.startPosition("VAR");
          sb.append("v");
          sb.endPosition();
        }
        sb.append(" = ");
        {
          sb.startPosition("INIT");
          sb.append("init");
          sb.endPosition();
        }
        sb.append("; ");
        {
          sb.startPosition("CONDITION");
          sb.append("condition");
          sb.endPosition();
        }
        sb.append("; ");
        {
          sb.startPosition("INCREMENT");
          sb.append("increment");
          sb.endPosition();
        }
        sb.append(") {");
        sb.append(eol);
        _insertBuilder(sb);
      }
      {
        SourceEdit edit =
            utils.createIndentEdit(statementsRange, indentOld, indentNew);
        edits.add(edit);
      }
      _addInsertEdit(statementsRange.end, "${indentOld}}${eol}");
      exitPosition = _newPosition(lastStatement.end);
      // add proposal
      _addAssist(AssistKind.SURROUND_WITH_FOR, []);
    }
    // "do-while"
    {
      _addInsertEdit(statementsRange.offset, "${indentOld}do {${eol}");
      {
        SourceEdit edit =
            utils.createIndentEdit(statementsRange, indentOld, indentNew);
        edits.add(edit);
      }
      {
        int offset = statementsRange.end;
        SourceBuilder sb = new SourceBuilder(file, offset);
        sb.append(indentOld);
        sb.append("} while (");
        {
          sb.startPosition("CONDITION");
          sb.append("condition");
          sb.endPosition();
        }
        sb.append(");");
        sb.append(eol);
        _insertBuilder(sb);
      }
      exitPosition = _newPosition(lastStatement.end);
      // add proposal
      _addAssist(AssistKind.SURROUND_WITH_DO_WHILE, []);
    }
    // "try-catch"
    {
      _addInsertEdit(statementsRange.offset, "${indentOld}try {${eol}");
      {
        SourceEdit edit =
            utils.createIndentEdit(statementsRange, indentOld, indentNew);
        edits.add(edit);
      }
      {
        int offset = statementsRange.end;
        SourceBuilder sb = new SourceBuilder(file, offset);
        sb.append(indentOld);
        sb.append("} on ");
        {
          sb.startPosition("EXCEPTION_TYPE");
          sb.append("Exception");
          sb.endPosition();
        }
        sb.append(" catch (");
        {
          sb.startPosition("EXCEPTION_VAR");
          sb.append("e");
          sb.endPosition();
        }
        sb.append(") {");
        sb.append(eol);
        //
        sb.append(indentNew);
        {
          sb.startPosition("CATCH");
          sb.append("// TODO");
          sb.endPosition();
          sb.setExitOffset();
        }
        sb.append(eol);
        //
        sb.append(indentOld);
        sb.append("}");
        sb.append(eol);
        //
        _insertBuilder(sb);
        exitPosition = _newPosition(sb.exitOffset);
      }
      // add proposal
      _addAssist(AssistKind.SURROUND_WITH_TRY_CATCH, []);
    }
    // "try-finally"
    {
      _addInsertEdit(statementsRange.offset, "${indentOld}try {${eol}");
      {
        SourceEdit edit =
            utils.createIndentEdit(statementsRange, indentOld, indentNew);
        edits.add(edit);
      }
      {
        int offset = statementsRange.end;
        SourceBuilder sb = new SourceBuilder(file, offset);
        //
        sb.append(indentOld);
        sb.append("} finally {");
        sb.append(eol);
        //
        sb.append(indentNew);
        {
          sb.startPosition("FINALLY");
          sb.append("// TODO");
          sb.endPosition();
        }
        sb.setExitOffset();
        sb.append(eol);
        //
        sb.append(indentOld);
        sb.append("}");
        sb.append(eol);
        //
        _insertBuilder(sb);
        exitPosition = _newPosition(sb.exitOffset);
      }
      // add proposal
      _addAssist(AssistKind.SURROUND_WITH_TRY_FINALLY, []);
    }
  }

  /**
   * Adds a new [Edit] to [edits].
   */
  void _addRemoveEdit(SourceRange range) {
    _addReplaceEdit(range, '');
  }

  /**
   * Adds a new [SourceEdit] to [edits].
   */
  void _addReplaceEdit(SourceRange range, String text) {
    SourceEdit edit = new SourceEdit(range.offset, range.length, text);
    edits.add(edit);
  }

  /**
   * Returns an existing or just added [LinkedEditGroup] with [groupId].
   */
  LinkedEditGroup _getLinkedPosition(String groupId) {
    LinkedEditGroup group = linkedPositionGroups[groupId];
    if (group == null) {
      group = new LinkedEditGroup.empty();
      linkedPositionGroups[groupId] = group;
    }
    return group;
  }

  /**
   * Returns the text of the given node in the unit.
   */
  String _getNodeText(AstNode node) {
    return utils.getNodeText(node);
  }

  /**
   * Returns the text of the given range in the unit.
   */
  String _getRangeText(SourceRange range) {
    return utils.getRangeText(range);
  }

  /**
   * Inserts the given [SourceBuilder] at its offset.
   */
  void _insertBuilder(SourceBuilder builder) {
    String text = builder.toString();
    _addInsertEdit(builder.offset, text);
    // add linked positions
    builder.linkedPositionGroups.forEach((String id, LinkedEditGroup group) {
      LinkedEditGroup fixGroup = _getLinkedPosition(id);
      group.positions.forEach((Position position) {
        fixGroup.addPosition(position, group.length);
      });
      group.suggestions.forEach((LinkedEditSuggestion suggestion) {
        fixGroup.addSuggestion(suggestion);
      });
    });
    // add exit position
    {
      int exitOffset = builder.exitOffset;
      if (exitOffset != null) {
        exitPosition = _newPosition(exitOffset);
      }
    }
  }

  Position _newPosition(int offset) {
    return new Position(file, offset);
  }

  /**
   * This method does nothing, but we invoke it in places where Dart VM
   * coverage agent fails to provide coverage information - such as almost
   * all "return" statements.
   *
   * https://code.google.com/p/dart/issues/detail?id=19912
   */
  static void _coverageMarker() {
  }

  /**
   * Returns `true` if the selection covers an operator of the given
   * [BinaryExpression].
   */
  static bool _isOperatorSelected(BinaryExpression binaryExpression, int offset,
      int length) {
    AstNode left = binaryExpression.leftOperand;
    AstNode right = binaryExpression.rightOperand;
    // between the nodes
    if (offset >= left.endToken.end && offset + length <= right.offset) {
      _coverageMarker();
      return true;
    }
    // or exactly select the node (but not with infix expressions)
    if (offset == left.offset && offset + length == right.endToken.end) {
      if (left is BinaryExpression || right is BinaryExpression) {
        _coverageMarker();
        return false;
      }
      _coverageMarker();
      return true;
    }
    // invalid selection (part of node, etc)
    _coverageMarker();
    return false;
  }

  /**
   * Checks if the given [Expression] should be wrapped with parenthesis when we
   * want to use it as operand of a logical `and` expression.
   */
  static bool _shouldWrapParenthesisBeforeAnd(Expression expr) {
    if (expr is BinaryExpression) {
      BinaryExpression binary = expr;
      int precedence = binary.operator.type.precedence;
      return precedence < TokenClass.LOGICAL_AND_OPERATOR.precedence;
    }
    return false;
  }
}


class _SimpleIdentifierRecursiveAstVisitor extends RecursiveAstVisitor {
  final _SimpleIdentifierVisitor visitor;

  _SimpleIdentifierRecursiveAstVisitor(this.visitor);

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    visitor(node);
  }
}
