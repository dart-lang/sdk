// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library services.src.correction.assist;

import 'package:analysis_services/correction/assist.dart';
import 'package:analysis_services/correction/change.dart';
import 'package:analysis_services/search/search_engine.dart';
import 'package:analysis_services/src/correction/name_suggestion.dart';
import 'package:analysis_services/src/correction/source_buffer.dart';
import 'package:analysis_services/src/correction/source_range.dart';
import 'package:analysis_services/src/correction/util.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart';


/**
 * The computer for Dart assists.
 */
class AssistProcessor {
  final SearchEngine searchEngine;
  final Source source;
  final String file;
  final CompilationUnit unit;
  final int selectionOffset;
  final int selectionLength;
  CompilationUnitElement unitElement;
  LibraryElement unitLibraryElement;
  String unitLibraryFile;
  String unitLibraryFolder;

  final List<Edit> edits = <Edit>[];
  final Map<String, LinkedPositionGroup> linkedPositionGroups = <String,
      LinkedPositionGroup>{};
  Position endPosition = null;
  final List<Assist> assists = <Assist>[];

  int selectionEnd;
  CorrectionUtils utils;
  AstNode node;
  AstNode coveredNode;


  AssistProcessor(this.searchEngine, this.source, this.file, this.unit,
      this.selectionOffset, this.selectionLength) {
    unitElement = unit.element;
    unitLibraryElement = unitElement.library;
    unitLibraryFile = unitLibraryElement.source.fullName;
    unitLibraryFolder = dirname(unitLibraryFile);
    selectionEnd = selectionOffset + selectionLength;
  }

  /**
   * Returns the EOL to use for this [CompilationUnit].
   */
  String get eol => utils.endOfLine;

  List<Assist> compute() {
    utils = new CorrectionUtils(unit);
    node = new NodeLocator.con1(selectionOffset).searchWithin(unit);
    coveredNode = new NodeLocator.con2(
        selectionOffset,
        selectionEnd).searchWithin(unit);
    // try to add proposals
    _addProposal_addTypeAnnotation();
    _addProposal_assignToLocalVariable();
    _addProposal_convertToBlockFunctionBody();
    _addProposal_convertToExpressionFunctionBody();
    _addProposal_convertToIsNot_onIs();
    _addProposal_convertToIsNot_onNot();
    _addProposal_convertToIsNotEmpty();
    _addProposal_exchangeOperands();
    _addProposal_extractClassIntoPart();
    _addProposal_importAddShow();
    _addProposal_invertIf();
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

  void _addAssist(AssistKind kind, List args, {String assistFile}) {
    if (assistFile == null) {
      assistFile = file;
    }
    FileEdit fileEdit = new FileEdit(file);
    edits.forEach((edit) => fileEdit.add(edit));
    // prepare Change
    String message = JavaString.format(kind.message, args);
    Change change = new Change(message);
    change.add(fileEdit);
    linkedPositionGroups.values.forEach(
        (group) => change.addLinkedPositionGroup(group));
    change.endPosition = endPosition;
    // add Assist
    Assist assist = new Assist(kind, change);
    assists.add(assist);
    // clear
    edits.clear();
    linkedPositionGroups.clear();
    endPosition = null;
  }

  /**
   * Adds a new [Edit] to [edits].
   */
  void _addInsertEdit(int offset, String text) {
    Edit edit = new Edit(offset, 0, text);
    edits.add(edit);
  }

  void _addProposal_addTypeAnnotation() {
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
        builder.addProposal(name);
      }
      builder.endPosition();
    }
    builder.append(" = ");
    // add proposal
    _insertBuilder(builder);
    _addAssist(AssistKind.ASSIGN_TO_LOCAL_VARIABLE, []);
  }

  void _addProposal_convertToBlockFunctionBody() {
    // TODO(scheglov) implement
//    FunctionBody body = enclosingFunctionBody;
//    // prepare expression body
//    if (body is! ExpressionFunctionBody) {
//      return;
//    }
//    Expression returnValue = (body as ExpressionFunctionBody).expression;
//    // prepare prefix
//    String prefix;
//    {
//      AstNode bodyParent = body.parent;
//      prefix = utils.getNodePrefix(bodyParent);
//    }
//    // add change
//    String eol = utils.endOfLine;
//    String indent = utils.getIndent(1);
//    String newBodySource =
//        "{${eol}${prefix}${indent}return ${_getSource(returnValue)};${eol}${prefix}}";
//    _addReplaceEdit(rangeNode(body), newBodySource);
//    // add proposal
//    _addAssist(AssistKind.CONVERT_INTO_BLOCK_BODY, []);
  }

  void _addProposal_convertToExpressionFunctionBody() {
    // TODO(scheglov) implement
//    // prepare current body
//    FunctionBody body = enclosingFunctionBody;
//    if (body is! BlockFunctionBody) {
//      return;
//    }
//    // prepare return statement
//    List<Statement> statements = (body as BlockFunctionBody).block.statements;
//    if (statements.length != 1) {
//      return;
//    }
//    if (statements[0] is! ReturnStatement) {
//      return;
//    }
//    ReturnStatement returnStatement = statements[0] as ReturnStatement;
//    // prepare returned expression
//    Expression returnExpression = returnStatement.expression;
//    if (returnExpression == null) {
//      return;
//    }
//    // add change
//    String newBodySource = "=> ${_getSource(returnExpression)}";
//    if (body.parent is! FunctionExpression ||
//        body.parent.parent is FunctionDeclaration) {
//      newBodySource += ";";
//    }
//    _addReplaceEdit(rangeNode(body), newBodySource);
//    // add proposal
//    _addAssist(
//        AssistKind.CONVERT_INTO_EXPRESSION_BODY,
//        []);
  }

  /**
   * Converts "!isEmpty" -> "isNotEmpty" if possible.
   */
  void _addProposal_convertToIsNotEmpty() {
    // TODO(scheglov) implement
//    // prepare "expr.isEmpty"
//    AstNode isEmptyAccess = null;
//    SimpleIdentifier isEmptyIdentifier = null;
//    if (node is SimpleIdentifier) {
//      SimpleIdentifier identifier = node as SimpleIdentifier;
//      AstNode parent = identifier.parent;
//      // normal case (but rare)
//      if (parent is PropertyAccess) {
//        PropertyAccess propertyAccess = parent;
//        isEmptyIdentifier = propertyAccess.propertyName;
//        isEmptyAccess = propertyAccess;
//      }
//      // usual case
//      if (parent is PrefixedIdentifier) {
//        PrefixedIdentifier prefixedIdentifier = parent;
//        isEmptyIdentifier = prefixedIdentifier.identifier;
//        isEmptyAccess = prefixedIdentifier;
//      }
//    }
//    if (isEmptyIdentifier == null) {
//      return;
//    }
//    // should be "isEmpty"
//    Element propertyElement = isEmptyIdentifier.bestElement;
//    if (propertyElement == null || "isEmpty" != propertyElement.name) {
//      return;
//    }
//    // should have "isNotEmpty"
//    Element propertyTarget = propertyElement.enclosingElement;
//    if (propertyTarget == null ||
//        CorrectionUtils.getChildren2(propertyTarget, "isNotEmpty").isEmpty) {
//      return;
//    }
//    // should be in PrefixExpression
//    if (isEmptyAccess.parent is! PrefixExpression) {
//      return;
//    }
//    PrefixExpression prefixExpression =
//        isEmptyAccess.parent as PrefixExpression;
//    // should be !
//    if (prefixExpression.operator.type != TokenType.BANG) {
//      return;
//    }
//    // do replace
//    _addRemoveEdit(
//        rangeStartStart(prefixExpression, prefixExpression.operand));
//    _addReplaceEdit(
//        rangeNode(isEmptyIdentifier),
//        "isNotEmpty");
//    // add proposal
//    _addAssist(AssistKind.CONVERT_INTO_IS_NOT_EMPTY, []);
  }

  void _addProposal_convertToIsNot_onIs() {
    // TODO(scheglov) implement
//    // may be child of "is"
//    AstNode node = this.node;
//    while (node != null && node is! IsExpression) {
//      node = node.parent;
//    }
//    // prepare "is"
//    if (node is! IsExpression) {
//      return;
//    }
//    IsExpression isExpression = node as IsExpression;
//    if (isExpression.notOperator != null) {
//      return;
//    }
//    // prepare enclosing ()
//    AstNode parent = isExpression.parent;
//    if (parent is! ParenthesizedExpression) {
//      return;
//    }
//    ParenthesizedExpression parExpression = parent as ParenthesizedExpression;
//    // prepare enclosing !()
//    AstNode parent2 = parent.parent;
//    if (parent2 is! PrefixExpression) {
//      return;
//    }
//    PrefixExpression prefExpression = parent2 as PrefixExpression;
//    if (prefExpression.operator.type != TokenType.BANG) {
//      return;
//    }
//    // strip !()
//    if (CorrectionUtils.getParentPrecedence(prefExpression) >=
//        TokenType.IS.precedence) {
//      _addRemoveEdit(rangeToken(prefExpression.operator));
//    } else {
//      _addRemoveEdit(
//          rangeStartEnd(
//              prefExpression,
//              parExpression.leftParenthesis));
//      _addRemoveEdit(
//          rangeStartEnd(
//              parExpression.rightParenthesis,
//              prefExpression));
//    }
//    _addInsertEdit(isExpression.isOperator.end, "!");
//    // add proposal
//    _addAssist(AssistKind.CONVERT_INTO_IS_NOT, []);
  }

  void _addProposal_convertToIsNot_onNot() {
    // TODO(scheglov) implement
//    // may be () in prefix expression
//    if (node is ParenthesizedExpression && node.parent is PrefixExpression) {
//      node = node.parent;
//    }
//    // prepare !()
//    if (node is! PrefixExpression) {
//      return;
//    }
//    PrefixExpression prefExpression = node as PrefixExpression;
//    // should be ! operator
//    if (prefExpression.operator.type != TokenType.BANG) {
//      return;
//    }
//    // prepare !()
//    Expression operand = prefExpression.operand;
//    if (operand is! ParenthesizedExpression) {
//      return;
//    }
//    ParenthesizedExpression parExpression = operand as ParenthesizedExpression;
//    operand = parExpression.expression;
//    // prepare "is"
//    if (operand is! IsExpression) {
//      return;
//    }
//    IsExpression isExpression = operand as IsExpression;
//    if (isExpression.notOperator != null) {
//      return;
//    }
//    // strip !()
//    if (getExpressionParentPrecedence(prefExpression) >=
//        TokenType.IS.precedence) {
//      _addRemoveEdit(rangeToken(prefExpression.operator));
//    } else {
//      _addRemoveEdit(
//          rangeStartEnd(
//              prefExpression,
//              parExpression.leftParenthesis));
//      _addRemoveEdit(
//          rangeStartEnd(
//              parExpression.rightParenthesis,
//              prefExpression));
//    }
//    _addInsertEdit(isExpression.isOperator.end, "!");
//    // add proposal
//    _addAssist(AssistKind.CONVERT_INTO_IS_NOT, []);
  }

  void _addProposal_exchangeOperands() {
    // TODO(scheglov) implement
//    // check that user invokes quick assist on binary expression
//    if (node is! BinaryExpression) {
//      return;
//    }
//    BinaryExpression binaryExpression = node as BinaryExpression;
//    // prepare operator position
//    int offset =
//        _isOperatorSelected(binaryExpression, _selectionOffset, _selectionLength);
//    if (offset == -1) {
//      return;
//    }
//    // add edits
//    {
//      Expression leftOperand = binaryExpression.leftOperand;
//      Expression rightOperand = binaryExpression.rightOperand;
//      // find "wide" enclosing binary expression with same operator
//      while (binaryExpression.parent is BinaryExpression) {
//        BinaryExpression newBinaryExpression =
//            binaryExpression.parent as BinaryExpression;
//        if (newBinaryExpression.operator.type !=
//            binaryExpression.operator.type) {
//          break;
//        }
//        binaryExpression = newBinaryExpression;
//      }
//      // exchange parts of "wide" expression parts
//      SourceRange leftRange =
//          rangeStartEnd(binaryExpression, leftOperand);
//      SourceRange rightRange =
//          rangeStartEnd(rightOperand, binaryExpression);
//      _addReplaceEdit(leftRange, _getSource2(rightRange));
//      _addReplaceEdit(rightRange, _getSource2(leftRange));
//    }
//    // add proposal
//    _addAssist(AssistKind.EXCHANGE_OPERANDS, []);
  }

  void _addProposal_extractClassIntoPart() {
    // TODO(scheglov) implement
//    // should be on the name
//    if (node is! SimpleIdentifier) {
//      return;
//    }
//    if (node.parent is! ClassDeclaration) {
//      return;
//    }
//    ClassDeclaration classDeclaration = node.parent as ClassDeclaration;
//    SourceRange linesRange =
//        utils.getLinesRange2(rangeNode(classDeclaration));
//    // prepare name
//    String className = classDeclaration.name.name;
//    String fileName = CorrectionUtils.getRecommentedFileNameForClass(className);
//    // prepare new file
//    JavaFile newFile = new JavaFile.relative(_unitLibraryFolder, fileName);
//    if (newFile.exists()) {
//      return;
//    }
//    // remove class from this unit
//    SourceChange unitChange = new SourceChange(_source.shortName, _source);
//    unitChange.addEdit(new Edit.range(linesRange, ""));
//    // create new unit
//    Change createFileChange;
//    {
//      String newContent = "part of ${_unitLibraryElement.displayName};";
//      newContent += utils.endOfLine;
//      newContent += utils.endOfLine;
//      newContent += _getSource2(linesRange);
//      createFileChange = new CreateFileChange(fileName, newFile, newContent);
//    }
//    // add 'part'
//    SourceChange libraryChange =
//        _getInsertPartDirectiveChange(_unitLibrarySource, fileName);
//    // add proposal
//    Change compositeChange =
//        new CompositeChange("", [unitChange, createFileChange, libraryChange]);
//    _proposals.add(
//        new ChangeCorrectionProposal(
//            compositeChange,
//            AssistKind.EXTRACT_CLASS,
//            [fileName]));
  }

  void _addProposal_importAddShow() {
    // TODO(scheglov) implement
//    // prepare ImportDirective
//    ImportDirective importDirective =
//        node.getAncestor((node) => node is ImportDirective);
//    if (importDirective == null) {
//      return;
//    }
//    // there should be no existing combinators
//    if (!importDirective.combinators.isEmpty) {
//      return;
//    }
//    // prepare whole import namespace
//    ImportElement importElement = importDirective.element;
//    Map<String, Element> namespace =
//        CorrectionUtils.getImportNamespace(importElement);
//    // prepare names of referenced elements (from this import)
//    Set<String> referencedNames = new Set();
//    // TODO(scheglov)
////    SearchEngine searchEngine = _assistContext.searchEngine;
////    for (Element element in namespace.values) {
////      List<SearchMatch> references =
////          searchEngine.searchReferences(element, null, null);
////      for (SearchMatch match in references) {
////        LibraryElement library = match.element.library;
////        if (_unitLibraryElement == library) {
////          referencedNames.add(element.displayName);
////          break;
////        }
////      }
////    }
//    // ignore if unused
//    if (referencedNames.isEmpty) {
//      return;
//    }
//    // prepare change
//    String sb = " show ${StringUtils.join(referencedNames, ", ")}";
//    _addInsertEdit(importDirective.end - 1, sb.toString());
//    // add proposal
//    _addAssist(AssistKind.IMPORT_ADD_SHOW, []);
  }

  void _addProposal_invertIf() {
    // TODO(scheglov) implement
//    if (node is! IfStatement) {
//      return;
//    }
//    IfStatement ifStatement = node as IfStatement;
//    Expression condition = ifStatement.condition;
//    // should have both "then" and "else"
//    Statement thenStatement = ifStatement.thenStatement;
//    Statement elseStatement = ifStatement.elseStatement;
//    if (thenStatement == null || elseStatement == null) {
//      return;
//    }
//    // prepare source
//    String invertedCondition = utils.invertCondition(condition);
//    String thenSource = _getSource(thenStatement);
//    String elseSource = _getSource(elseStatement);
//    // do replacements
//    _addReplaceEdit(rangeNode(condition), invertedCondition);
//    _addReplaceEdit(rangeNode(thenStatement), elseSource);
//    _addReplaceEdit(rangeNode(elseStatement), thenSource);
//    // add proposal
//    _addAssist(AssistKind.INVERT_IF_STATEMENT, []);
//  }
//
//  void _addProposal_joinIfStatementInner() {
//    // climb up condition to the (supposedly) "if" statement
//    AstNode node = this.node;
//    while (node is Expression) {
//      node = node.parent;
//    }
//    // prepare target "if" statement
//    if (node is! IfStatement) {
//      return;
//    }
//    IfStatement targetIfStatement = node as IfStatement;
//    if (targetIfStatement.elseStatement != null) {
//      return;
//    }
//    // prepare inner "if" statement
//    Statement targetThenStatement = targetIfStatement.thenStatement;
//    Statement innerStatement =
//        CorrectionUtils.getSingleStatement(targetThenStatement);
//    if (innerStatement is! IfStatement) {
//      return;
//    }
//    IfStatement innerIfStatement = innerStatement as IfStatement;
//    if (innerIfStatement.elseStatement != null) {
//      return;
//    }
//    // prepare environment
//    String prefix = utils.getNodePrefix(targetIfStatement);
//    String eol = utils.endOfLine;
//    // merge conditions
//    String condition;
//    {
//      Expression targetCondition = targetIfStatement.condition;
//      Expression innerCondition = innerIfStatement.condition;
//      String targetConditionSource = _getSource(targetCondition);
//      String innerConditionSource = _getSource(innerCondition);
//      if (_shouldWrapParenthesisBeforeAnd(targetCondition)) {
//        targetConditionSource = "(${targetConditionSource})";
//      }
//      if (_shouldWrapParenthesisBeforeAnd(innerCondition)) {
//        innerConditionSource = "(${innerConditionSource})";
//      }
//      condition = "${targetConditionSource} && ${innerConditionSource}";
//    }
//    // replace target "if" statement
//    {
//      Statement innerThenStatement = innerIfStatement.thenStatement;
//      List<Statement> innerThenStatements =
//          CorrectionUtils.getStatements(innerThenStatement);
//      SourceRange lineRanges = utils.getLinesRange(innerThenStatements);
//      String oldSource = utils.getText3(lineRanges);
//      String newSource = utils.getIndentSource2(oldSource, false);
//      // TODO(scheglov)
////      _addReplaceEdit(
////          rangeNode(targetIfStatement),
////          MessageFormat.format(
////              "if ({0}) '{'{1}{2}{3}'}'",
////              [condition, eol, newSource, prefix]));
//    }
//    // done
//    _addAssist(AssistKind.JOIN_IF_WITH_INNER, []);
  }

  void _addProposal_joinIfStatementOuter() {
    // TODO(scheglov) implement
//    // climb up condition to the (supposedly) "if" statement
//    AstNode node = this.node;
//    while (node is Expression) {
//      node = node.parent;
//    }
//    // prepare target "if" statement
//    if (node is! IfStatement) {
//      return;
//    }
//    IfStatement targetIfStatement = node as IfStatement;
//    if (targetIfStatement.elseStatement != null) {
//      return;
//    }
//    // prepare outer "if" statement
//    AstNode parent = targetIfStatement.parent;
//    if (parent is Block) {
//      parent = parent.parent;
//    }
//    if (parent is! IfStatement) {
//      return;
//    }
//    IfStatement outerIfStatement = parent as IfStatement;
//    if (outerIfStatement.elseStatement != null) {
//      return;
//    }
//    // prepare environment
//    String prefix = utils.getNodePrefix(outerIfStatement);
//    String eol = utils.endOfLine;
//    // merge conditions
//    String condition;
//    {
//      Expression targetCondition = targetIfStatement.condition;
//      Expression outerCondition = outerIfStatement.condition;
//      String targetConditionSource = _getSource(targetCondition);
//      String outerConditionSource = _getSource(outerCondition);
//      if (_shouldWrapParenthesisBeforeAnd(targetCondition)) {
//        targetConditionSource = "(${targetConditionSource})";
//      }
//      if (_shouldWrapParenthesisBeforeAnd(outerCondition)) {
//        outerConditionSource = "(${outerConditionSource})";
//      }
//      condition = "${outerConditionSource} && ${targetConditionSource}";
//    }
//    // replace outer "if" statement
//    {
//      Statement targetThenStatement = targetIfStatement.thenStatement;
//      List<Statement> targetThenStatements =
//          CorrectionUtils.getStatements(targetThenStatement);
//      SourceRange lineRanges = utils.getLinesRange(targetThenStatements);
//      String oldSource = utils.getText3(lineRanges);
//      String newSource = utils.getIndentSource2(oldSource, false);
//      // TODO(scheglov)
////      _addReplaceEdit(
////          rangeNode(outerIfStatement),
////          MessageFormat.format(
////              "if ({0}) '{'{1}{2}{3}'}'",
////              [condition, eol, newSource, prefix]));
//    }
//    // done
//    _addAssist(AssistKind.JOIN_IF_WITH_OUTER, []);
  }

  void _addProposal_joinVariableDeclaration_onAssignment() {
    // TODO(scheglov) implement
//    // check that node is LHS in assignment
//    if (node is SimpleIdentifier &&
//        node.parent is AssignmentExpression &&
//        identical((node.parent as AssignmentExpression).leftHandSide, node) &&
//        node.parent.parent is ExpressionStatement) {
//    } else {
//      return;
//    }
//    AssignmentExpression assignExpression =
//        node.parent as AssignmentExpression;
//    // check that binary expression is assignment
//    if (assignExpression.operator.type != TokenType.EQ) {
//      return;
//    }
//    // prepare "declaration" statement
//    Element element = (node as SimpleIdentifier).staticElement;
//    if (element == null) {
//      return;
//    }
//    int declOffset = element.nameOffset;
//    AstNode declNode = new NodeLocator.con1(declOffset).searchWithin(_unit);
//    if (declNode != null &&
//        declNode.parent is VariableDeclaration &&
//        identical((declNode.parent as VariableDeclaration).name, declNode) &&
//        declNode.parent.parent is VariableDeclarationList &&
//        declNode.parent.parent.parent is VariableDeclarationStatement) {
//    } else {
//      return;
//    }
//    VariableDeclaration decl = declNode.parent as VariableDeclaration;
//    VariableDeclarationStatement declStatement =
//        decl.parent.parent as VariableDeclarationStatement;
//    // may be has initializer
//    if (decl.initializer != null) {
//      return;
//    }
//    // check that "declaration" statement declared only one variable
//    if (declStatement.variables.variables.length != 1) {
//      return;
//    }
//
//        // check that "declaration" and "assignment" statements are part of same Block
//    ExpressionStatement assignStatement =
//        node.parent.parent as ExpressionStatement;
//    if (assignStatement.parent is Block &&
//        identical(assignStatement.parent, declStatement.parent)) {
//    } else {
//      return;
//    }
//    Block block = assignStatement.parent as Block;
//    // check that "declaration" and "assignment" statements are adjacent
//    List<Statement> statements = block.statements;
//    if (statements.indexOf(assignStatement) ==
//        statements.indexOf(declStatement) + 1) {
//    } else {
//      return;
//    }
//    // add edits
//    {
//      int assignOffset = assignExpression.operator.offset;
//      _addReplaceEdit(
//          rangeEndStart(declNode, assignOffset),
//          " ");
//    }
//    // add proposal
//    _addAssist(AssistKind.JOIN_VARIABLE_DECLARATION, []);
  }

  void _addProposal_joinVariableDeclaration_onDeclaration() {
    // TODO(scheglov) implement
//    // prepare enclosing VariableDeclarationList
//    VariableDeclarationList declList =
//        node.getAncestor((node) => node is VariableDeclarationList);
//    if (declList != null && declList.variables.length == 1) {
//    } else {
//      return;
//    }
//    VariableDeclaration decl = declList.variables[0];
//    // already initialized
//    if (decl.initializer != null) {
//      return;
//    }
//    // prepare VariableDeclarationStatement in Block
//    if (declList.parent is VariableDeclarationStatement &&
//        declList.parent.parent is Block) {
//    } else {
//      return;
//    }
//    VariableDeclarationStatement declStatement =
//        declList.parent as VariableDeclarationStatement;
//    Block block = declStatement.parent as Block;
//    List<Statement> statements = block.statements;
//    // prepare assignment
//    AssignmentExpression assignExpression;
//    {
//      // declaration should not be last Statement
//      int declIndex = statements.indexOf(declStatement);
//      if (declIndex < statements.length - 1) {
//      } else {
//        return;
//      }
//      // next Statement should be assignment
//      Statement assignStatement = statements[declIndex + 1];
//      if (assignStatement is ExpressionStatement) {
//      } else {
//        return;
//      }
//      ExpressionStatement expressionStatement =
//          assignStatement as ExpressionStatement;
//      // expression should be assignment
//      if (expressionStatement.expression is AssignmentExpression) {
//      } else {
//        return;
//      }
//      assignExpression = expressionStatement.expression as AssignmentExpression;
//    }
//    // check that pure assignment
//    if (assignExpression.operator.type != TokenType.EQ) {
//      return;
//    }
//    // add edits
//    {
//      int assignOffset = assignExpression.operator.offset;
//      _addReplaceEdit(
//          rangeEndStart(decl.name, assignOffset),
//          " ");
//    }
//    // add proposal
//    _addAssist(AssistKind.JOIN_VARIABLE_DECLARATION, []);
  }

  void _addProposal_removeTypeAnnotation() {
    // TODO(scheglov) implement
//    AstNode typeStart = null;
//    AstNode typeEnd = null;
//    // try top-level variable
//    {
//      TopLevelVariableDeclaration declaration =
//          node.getAncestor((node) => node is TopLevelVariableDeclaration);
//      if (declaration != null) {
//        TypeName typeNode = declaration.variables.type;
//        if (typeNode != null) {
//          VariableDeclaration field = declaration.variables.variables[0];
//          typeStart = declaration;
//          typeEnd = field;
//        }
//      }
//    }
//    // try class field
//    {
//      FieldDeclaration fieldDeclaration =
//          node.getAncestor((node) => node is FieldDeclaration);
//      if (fieldDeclaration != null) {
//        TypeName typeNode = fieldDeclaration.fields.type;
//        if (typeNode != null) {
//          VariableDeclaration field = fieldDeclaration.fields.variables[0];
//          typeStart = fieldDeclaration;
//          typeEnd = field;
//        }
//      }
//    }
//    // try local variable
//    {
//      VariableDeclarationStatement statement =
//          node.getAncestor((node) => node is VariableDeclarationStatement);
//      if (statement != null) {
//        TypeName typeNode = statement.variables.type;
//        if (typeNode != null) {
//          VariableDeclaration variable = statement.variables.variables[0];
//          typeStart = typeNode;
//          typeEnd = variable;
//        }
//      }
//    }
//    // add edit
//    if (typeStart != null && typeEnd != null) {
//      SourceRange typeRange =
//          rangeStartStart(typeStart, typeEnd);
//      _addReplaceEdit(typeRange, "var ");
//    }
//    // add proposal
//    _addAssist(AssistKind.REMOVE_TYPE_ANNOTATION, []);
  }

  void _addProposal_replaceConditionalWithIfElse() {
    // TODO(scheglov) implement
//    ConditionalExpression conditional = null;
//    // may be on Statement with Conditional
//    Statement statement = node.getAncestor((node) => node is Statement);
//    if (statement == null) {
//      return;
//    }
//    // variable declaration
//    bool inVariable = false;
//    if (statement is VariableDeclarationStatement) {
//      VariableDeclarationStatement variableStatement = statement;
//      for (VariableDeclaration variable in
//          variableStatement.variables.variables) {
//        if (variable.initializer is ConditionalExpression) {
//          conditional = variable.initializer as ConditionalExpression;
//          inVariable = true;
//          break;
//        }
//      }
//    }
//    // assignment
//    bool inAssignment = false;
//    if (statement is ExpressionStatement) {
//      ExpressionStatement exprStmt = statement;
//      if (exprStmt.expression is AssignmentExpression) {
//        AssignmentExpression assignment =
//            exprStmt.expression as AssignmentExpression;
//        if (assignment.operator.type == TokenType.EQ &&
//            assignment.rightHandSide is ConditionalExpression) {
//          conditional = assignment.rightHandSide as ConditionalExpression;
//          inAssignment = true;
//        }
//      }
//    }
//    // return
//    bool inReturn = false;
//    if (statement is ReturnStatement) {
//      ReturnStatement returnStatement = statement;
//      if (returnStatement.expression is ConditionalExpression) {
//        conditional = returnStatement.expression as ConditionalExpression;
//        inReturn = true;
//      }
//    }
//    // prepare environment
//    String eol = utils.endOfLine;
//    String indent = utils.getIndent(1);
//    String prefix = utils.getNodePrefix(statement);
//    // Type v = Conditional;
//    if (inVariable) {
//      VariableDeclaration variable = conditional.parent as VariableDeclaration;
//      _addRemoveEdit(
//          rangeEndEnd(variable.name, conditional));
//      // TODO(scheglov)
////      _addReplaceEdit(
////          rangeEndLength(statement, 0),
////          MessageFormat.format(
////              "{3}{4}if ({0}) '{'{3}{4}{5}{6} = {1};{3}{4}'} else {'{3}{4}{5}{6} = {2};{3}{4}'}'",
////              [
////                  _getSource(conditional.condition),
////                  _getSource(conditional.thenExpression),
////                  _getSource(conditional.elseExpression),
////                  eol,
////                  prefix,
////                  indent,
////                  variable.name]));
//    }
//    // v = Conditional;
//    if (inAssignment) {
//      AssignmentExpression assignment =
//          conditional.parent as AssignmentExpression;
//      Expression leftSide = assignment.leftHandSide;
//      // TODO(scheglov)
////      _addReplaceEdit(
////          rangeNode(statement),
////          MessageFormat.format(
////              "if ({0}) '{'{3}{4}{5}{6} = {1};{3}{4}'} else {'{3}{4}{5}{6} = {2};{3}{4}'}'",
////              [
////                  _getSource(conditional.condition),
////                  _getSource(conditional.thenExpression),
////                  _getSource(conditional.elseExpression),
////                  eol,
////                  prefix,
////                  indent,
////                  _getSource(leftSide)]));
//    }
//    // return Conditional;
//    if (inReturn) {
//      // TODO(scheglov)
////      _addReplaceEdit(
////          rangeNode(statement),
////          MessageFormat.format(
////              "if ({0}) '{'{3}{4}{5}return {1};{3}{4}'} else {'{3}{4}{5}return {2};{3}{4}'}'",
////              [
////                  _getSource(conditional.condition),
////                  _getSource(conditional.thenExpression),
////                  _getSource(conditional.elseExpression),
////                  eol,
////                  prefix,
////                  indent]));
//    }
//    // add proposal
//    _addAssist(
//        AssistKind.REPLACE_CONDITIONAL_WITH_IF_ELSE,
//        []);
  }

  void _addProposal_replaceIfElseWithConditional() {
    // TODO(scheglov) implement
//    // should be "if"
//    if (node is! IfStatement) {
//      return;
//    }
//    IfStatement ifStatement = node as IfStatement;
//    // single then/else statements
//    Statement thenStatement =
//        CorrectionUtils.getSingleStatement(ifStatement.thenStatement);
//    Statement elseStatement =
//        CorrectionUtils.getSingleStatement(ifStatement.elseStatement);
//    if (thenStatement == null || elseStatement == null) {
//      return;
//    }
//    // returns
//    if (thenStatement is ReturnStatement || elseStatement is ReturnStatement) {
//      ReturnStatement thenReturn = thenStatement as ReturnStatement;
//      ReturnStatement elseReturn = elseStatement as ReturnStatement;
//      // TODO(scheglov)
////      _addReplaceEdit(
////          rangeNode(ifStatement),
////          MessageFormat.format(
////              "return {0} ? {1} : {2};",
////              [
////                  _getSource(ifStatement.condition),
////                  _getSource(thenReturn.expression),
////                  _getSource(elseReturn.expression)]));
//    }
//    // assignments -> v = Conditional;
//    if (thenStatement is ExpressionStatement &&
//        elseStatement is ExpressionStatement) {
//      Expression thenExpression = thenStatement.expression;
//      Expression elseExpression = elseStatement.expression;
//      if (thenExpression is AssignmentExpression &&
//          elseExpression is AssignmentExpression) {
//        AssignmentExpression thenAssignment = thenExpression;
//        AssignmentExpression elseAssignment = elseExpression;
//        String thenTarget = _getSource(thenAssignment.leftHandSide);
//        String elseTarget = _getSource(elseAssignment.leftHandSide);
//        if (thenAssignment.operator.type == TokenType.EQ &&
//            elseAssignment.operator.type == TokenType.EQ &&
//            StringUtils.equals(thenTarget, elseTarget)) {
//          // TODO(scheglov)
////          _addReplaceEdit(
////              rangeNode(ifStatement),
////              MessageFormat.format(
////                  "{0} = {1} ? {2} : {3};",
////                  [
////                      thenTarget,
////                      _getSource(ifStatement.condition),
////                      _getSource(thenAssignment.rightHandSide),
////                      _getSource(elseAssignment.rightHandSide)]));
//        }
//      }
//    }
//    // add proposal
//    _addAssist(
//        AssistKind.REPLACE_IF_ELSE_WITH_CONDITIONAL,
//        []);
  }

  void _addProposal_splitAndCondition() {
    // TODO(scheglov) implement
//    // check that user invokes quick assist on binary expression
//    if (node is! BinaryExpression) {
//      return;
//    }
//    BinaryExpression binaryExpression = node as BinaryExpression;
//    // prepare operator position
//    int offset =
//        _isOperatorSelected(binaryExpression, _selectionOffset, _selectionLength);
//    if (offset == -1) {
//      return;
//    }
//    // should be &&
//    if (binaryExpression.operator.type != TokenType.AMPERSAND_AMPERSAND) {
//      return;
//    }
//    // prepare "if"
//    Statement statement = node.getAncestor((node) => node is Statement);
//    if (statement is! IfStatement) {
//      return;
//    }
//    IfStatement ifStatement = statement as IfStatement;
//    // check that binary expression is part of first level && condition of "if"
//    BinaryExpression condition = binaryExpression;
//    while (condition.parent is BinaryExpression &&
//        (condition.parent as BinaryExpression).operator.type ==
//            TokenType.AMPERSAND_AMPERSAND) {
//      condition = condition.parent as BinaryExpression;
//    }
//    if (!identical(ifStatement.condition, condition)) {
//      return;
//    }
//    // prepare environment
//    String prefix = utils.getNodePrefix(ifStatement);
//    String eol = utils.endOfLine;
//    String indent = utils.getIndent(1);
//    // prepare "rightCondition"
//    String rightConditionSource;
//    {
//      SourceRange rightConditionRange =
//          rangeStartEnd(binaryExpression.rightOperand, condition);
//      rightConditionSource = _getSource2(rightConditionRange);
//    }
//    // remove "&& rightCondition"
//    _addRemoveEdit(
//        rangeEndEnd(binaryExpression.leftOperand, condition));
//    // update "then" statement
//    Statement thenStatement = ifStatement.thenStatement;
//    Statement elseStatement = ifStatement.elseStatement;
//    if (thenStatement is Block) {
//      Block thenBlock = thenStatement;
//      SourceRange thenBlockRange = rangeNode(thenBlock);
//      // insert inner "if" with right part of "condition"
//      {
//        String source =
//            "${eol}${prefix}${indent}if (${rightConditionSource}) {";
//        int thenBlockInsideOffset = thenBlockRange.offset + 1;
//        _addInsertEdit(thenBlockInsideOffset, source);
//      }
//      // insert closing "}" for inner "if"
//      {
//        int thenBlockEnd = thenBlockRange.end;
//        String source = "${indent}}";
//        // may be move "else" statements
//        if (elseStatement != null) {
//          List<Statement> elseStatements =
//              CorrectionUtils.getStatements(elseStatement);
//          SourceRange elseLinesRange = utils.getLinesRange(elseStatements);
//          String elseIndentOld = "${prefix}${indent}";
//          String elseIndentNew = "${elseIndentOld}${indent}";
//          String newElseSource =
//              utils.getIndentSource(elseLinesRange, elseIndentOld, elseIndentNew);
//          // append "else" block
//          source += " else {${eol}";
//          source += newElseSource;
//          source += "${prefix}${indent}}";
//          // remove old "else" range
//          _addRemoveEdit(
//              rangeStartEnd(thenBlockEnd, elseStatement));
//        }
//        // insert before outer "then" block "}"
//        source += "${eol}${prefix}";
//        _addInsertEdit(thenBlockEnd - 1, source);
//      }
//    } else {
//      // insert inner "if" with right part of "condition"
//      {
//        String source = "${eol}${prefix}${indent}if (${rightConditionSource})";
//        _addInsertEdit(ifStatement.rightParenthesis.offset + 1, source);
//      }
//      // indent "else" statements to correspond inner "if"
//      if (elseStatement != null) {
//        SourceRange elseRange =
//            rangeStartEnd(ifStatement.elseKeyword.offset, elseStatement);
//        SourceRange elseLinesRange = utils.getLinesRange2(elseRange);
//        String elseIndentOld = prefix;
//        String elseIndentNew = "${elseIndentOld}${indent}";
//        edits.add(
//            utils.createIndentEdit(elseLinesRange, elseIndentOld, elseIndentNew));
//      }
//    }
//    // indent "then" statements to correspond inner "if"
//    {
//      List<Statement> thenStatements =
//          CorrectionUtils.getStatements(thenStatement);
//      SourceRange linesRange = utils.getLinesRange(thenStatements);
//      String thenIndentOld = "${prefix}${indent}";
//      String thenIndentNew = "${thenIndentOld}${indent}";
//      edits.add(
//          utils.createIndentEdit(linesRange, thenIndentOld, thenIndentNew));
//    }
//    // add proposal
//    _addAssist(AssistKind.SPLIT_AND_CONDITION, []);
  }

  void _addProposal_splitVariableDeclaration() {
    // TODO(scheglov) implement
//    // prepare DartVariableStatement, should be part of Block
//    VariableDeclarationStatement statement =
//        node.getAncestor((node) => node is VariableDeclarationStatement);
//    if (statement != null && statement.parent is Block) {
//    } else {
//      return;
//    }
//    // check that statement declares single variable
//    List<VariableDeclaration> variables = statement.variables.variables;
//    if (variables.length != 1) {
//      return;
//    }
//    VariableDeclaration variable = variables[0];
//    // remove initializer value
//    _addRemoveEdit(
//        rangeEndStart(variable.name, statement.semicolon));
//    // TODO(scheglov)
////    // add assignment statement
////    String eol = _utils.endOfLine;
////    String indent = _utils.getNodePrefix(statement);
////    String assignSource =
////        MessageFormat.format(
////            "{0} = {1};",
////            [variable.name.name, _getSource(variable.initializer)]);
////    SourceRange assignRange = rangeEndLength(statement, 0);
////    _addReplaceEdit(assignRange, "${eol}${indent}${assignSource}");
////    // add proposal
////    _addUnitCorrectionProposal(
////        AssistKind.SPLIT_VARIABLE_DECLARATION,
////        []);
  }

  void _addProposal_surroundWith() {
    // TODO(scheglov) implement
//    // prepare selected statements
//    List<Statement> selectedStatements;
//    {
//      SourceRange selection =
//          rangeStartLength(_selectionOffset, _selectionLength);
//      StatementAnalyzer selectionAnalyzer =
//          new StatementAnalyzer.con1(_unit, selection);
//      _unit.accept(selectionAnalyzer);
//      List<AstNode> selectedNodes = selectionAnalyzer.selectedNodes;
//      // convert nodes to statements
//      selectedStatements = [];
//      for (AstNode selectedNode in selectedNodes) {
//        if (selectedNode is Statement) {
//          selectedStatements.add(selectedNode);
//        }
//      }
//      // we want only statements
//      if (selectedStatements.isEmpty ||
//          selectedStatements.length != selectedNodes.length) {
//        return;
//      }
//    }
//    // prepare statement information
//    Statement firstStatement = selectedStatements[0];
//    Statement lastStatement = selectedStatements[selectedStatements.length - 1];
//    SourceRange statementsRange = utils.getLinesRange(selectedStatements);
//    // prepare environment
//    String eol = utils.endOfLine;
//    String indentOld = utils.getNodePrefix(firstStatement);
//    String indentNew = "${indentOld}${utils.getIndent(1)}";
//    // "block"
//    {
//      _addInsertEdit(statementsRange.offset, "${indentOld}{${eol}");
//      {
//        Edit edit =
//            utils.createIndentEdit(statementsRange, indentOld, indentNew);
//        edits.add(edit);
//      }
//      _addInsertEdit(statementsRange.end, "${indentOld}}${eol}");
//      _proposalEndRange = rangeEndLength(lastStatement, 0);
//      // add proposal
//      _addAssist(AssistKind.SURROUND_WITH_BLOCK, []);
//    }
//    // "if"
//    {
//      {
//        int offset = statementsRange.offset;
//        SourceBuilder sb = new SourceBuilder.con1(offset);
//        sb.append(indentOld);
//        sb.append("if (");
//        {
//          sb.startPosition("CONDITION");
//          sb.append("condition");
//          sb.endPosition();
//        }
//        sb.append(") {");
//        sb.append(eol);
//        _insertBuilder(sb);
//      }
//      {
//        Edit edit =
//            utils.createIndentEdit(statementsRange, indentOld, indentNew);
//        edits.add(edit);
//      }
//      _addInsertEdit(statementsRange.end, "${indentOld}}${eol}");
//      _proposalEndRange = rangeEndLength(lastStatement, 0);
//      // add proposal
//      _addAssist(AssistKind.SURROUND_WITH_IF, []);
//    }
//    // "while"
//    {
//      {
//        int offset = statementsRange.offset;
//        SourceBuilder sb = new SourceBuilder.con1(offset);
//        sb.append(indentOld);
//        sb.append("while (");
//        {
//          sb.startPosition("CONDITION");
//          sb.append("condition");
//          sb.endPosition();
//        }
//        sb.append(") {");
//        sb.append(eol);
//        _insertBuilder(sb);
//      }
//      {
//        Edit edit =
//            utils.createIndentEdit(statementsRange, indentOld, indentNew);
//        edits.add(edit);
//      }
//      _addInsertEdit(statementsRange.end, "${indentOld}}${eol}");
//      _proposalEndRange = rangeEndLength(lastStatement, 0);
//      // add proposal
//      _addAssist(AssistKind.SURROUND_WITH_WHILE, []);
//    }
//    // "for-in"
//    {
//      {
//        int offset = statementsRange.offset;
//        SourceBuilder sb = new SourceBuilder.con1(offset);
//        sb.append(indentOld);
//        sb.append("for (var ");
//        {
//          sb.startPosition("NAME");
//          sb.append("item");
//          sb.endPosition();
//        }
//        sb.append(" in ");
//        {
//          sb.startPosition("ITERABLE");
//          sb.append("iterable");
//          sb.endPosition();
//        }
//        sb.append(") {");
//        sb.append(eol);
//        _insertBuilder(sb);
//      }
//      {
//        Edit edit =
//            utils.createIndentEdit(statementsRange, indentOld, indentNew);
//        edits.add(edit);
//      }
//      _addInsertEdit(statementsRange.end, "${indentOld}}${eol}");
//      _proposalEndRange = rangeEndLength(lastStatement, 0);
//      // add proposal
//      _addAssist(AssistKind.SURROUND_WITH_FOR_IN, []);
//    }
//    // "for"
//    {
//      {
//        int offset = statementsRange.offset;
//        SourceBuilder sb = new SourceBuilder.con1(offset);
//        sb.append(indentOld);
//        sb.append("for (var ");
//        {
//          sb.startPosition("VAR");
//          sb.append("v");
//          sb.endPosition();
//        }
//        sb.append(" = ");
//        {
//          sb.startPosition("INIT");
//          sb.append("init");
//          sb.endPosition();
//        }
//        sb.append("; ");
//        {
//          sb.startPosition("CONDITION");
//          sb.append("condition");
//          sb.endPosition();
//        }
//        sb.append("; ");
//        {
//          sb.startPosition("INCREMENT");
//          sb.append("increment");
//          sb.endPosition();
//        }
//        sb.append(") {");
//        sb.append(eol);
//        _insertBuilder(sb);
//      }
//      {
//        Edit edit =
//            utils.createIndentEdit(statementsRange, indentOld, indentNew);
//        edits.add(edit);
//      }
//      _addInsertEdit(statementsRange.end, "${indentOld}}${eol}");
//      _proposalEndRange = rangeEndLength(lastStatement, 0);
//      // add proposal
//      _addAssist(AssistKind.SURROUND_WITH_FOR, []);
//    }
//    // "do-while"
//    {
//      _addInsertEdit(statementsRange.offset, "${indentOld}do {${eol}");
//      {
//        Edit edit =
//            utils.createIndentEdit(statementsRange, indentOld, indentNew);
//        edits.add(edit);
//      }
//      {
//        int offset = statementsRange.end;
//        SourceBuilder sb = new SourceBuilder.con1(offset);
//        sb.append(indentOld);
//        sb.append("} while (");
//        {
//          sb.startPosition("CONDITION");
//          sb.append("condition");
//          sb.endPosition();
//        }
//        sb.append(");");
//        sb.append(eol);
//        _insertBuilder(sb);
//      }
//      _proposalEndRange = rangeEndLength(lastStatement, 0);
//      // add proposal
//      _addAssist(AssistKind.SURROUND_WITH_DO_WHILE, []);
//    }
//    // "try-catch"
//    {
//      _addInsertEdit(statementsRange.offset, "${indentOld}try {${eol}");
//      {
//        Edit edit =
//            utils.createIndentEdit(statementsRange, indentOld, indentNew);
//        edits.add(edit);
//      }
//      {
//        int offset = statementsRange.end;
//        SourceBuilder sb = new SourceBuilder.con1(offset);
//        sb.append(indentOld);
//        sb.append("} on ");
//        {
//          sb.startPosition("EXCEPTION_TYPE");
//          sb.append("Exception");
//          sb.endPosition();
//        }
//        sb.append(" catch (");
//        {
//          sb.startPosition("EXCEPTION_VAR");
//          sb.append("e");
//          sb.endPosition();
//        }
//        sb.append(") {");
//        sb.append(eol);
//        //
//        sb.append(indentNew);
//        {
//          sb.startPosition("CATCH");
//          sb.append("// TODO");
//          sb.endPosition();
//          sb.setEndPosition();
//        }
//        sb.append(eol);
//        //
//        sb.append(indentOld);
//        sb.append("}");
//        sb.append(eol);
//        //
//        _insertBuilder(sb);
//      }
//      // add proposal
//      _addAssist(AssistKind.SURROUND_WITH_TRY_CATCH, []);
//    }
//    // "try-finally"
//    {
//      _addInsertEdit(statementsRange.offset, "${indentOld}try {${eol}");
//      {
//        Edit edit =
//            utils.createIndentEdit(statementsRange, indentOld, indentNew);
//        edits.add(edit);
//      }
//      {
//        int offset = statementsRange.end;
//        SourceBuilder sb = new SourceBuilder.con1(offset);
//        //
//        sb.append(indentOld);
//        sb.append("} finally {");
//        sb.append(eol);
//        //
//        sb.append(indentNew);
//        {
//          sb.startPosition("FINALLY");
//          sb.append("// TODO");
//          sb.endPosition();
//        }
//        sb.setEndPosition();
//        sb.append(eol);
//        //
//        sb.append(indentOld);
//        sb.append("}");
//        sb.append(eol);
//        //
//        _insertBuilder(sb);
//      }
//      // add proposal
//      _addAssist(
//          AssistKind.SURROUND_WITH_TRY_FINALLY,
//          []);
//    }
  }

  /**
   * Adds a new [Edit] to [edits].
   */
  void _addRemoveEdit(SourceRange range) {
    _addReplaceEdit(range, '');
  }

  /**
   * Adds a new [Edit] to [edits].
   */
  void _addReplaceEdit(SourceRange range, String text) {
    Edit edit = new Edit(range.offset, range.length, text);
    edits.add(edit);
  }

  /**
   * This method does nothing, but we invoke it in places where Dart VM
   * coverage agent fails to provide coverage information - such as almost
   * all "return" statements.
   *
   * https://code.google.com/p/dart/issues/detail?id=19912
   */
  void _coverageMarker() {
  }

  /**
   * Returns an existing or just added [LinkedPositionGroup] with [groupId].
   */
  LinkedPositionGroup _getLinkedPosition(String groupId) {
    LinkedPositionGroup group = linkedPositionGroups[groupId];
    if (group == null) {
      group = new LinkedPositionGroup(groupId);
      linkedPositionGroups[groupId] = group;
    }
    return group;
  }

  /**
   * Returns the text of the given range in the unit.
   */
  String _getSource(AstNode node) {
    // TODO(scheglov) rename
    return utils.getText(node);
  }

  /**
   * Returns the text of the given range in the unit.
   */
  String _getSource2(SourceRange range) {
    // TODO(scheglov) rename
    return utils.getText3(range);
  }

  /**
   * Inserts the given [SourceBuilder] at its offset.
   */
  void _insertBuilder(SourceBuilder builder) {
    String text = builder.toString();
    _addInsertEdit(builder.offset, text);
    // add linked positions
    builder.linkedPositionGroups.forEach((LinkedPositionGroup group) {
      LinkedPositionGroup fixGroup = _getLinkedPosition(group.id);
      group.positions.forEach((Position position) {
        fixGroup.addPosition(position);
      });
      group.proposals.forEach((String proposal) {
        fixGroup.addProposal(proposal);
      });
    });
  }
}
