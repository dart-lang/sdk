// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.correction.assist;

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/plugin/edit/assist/assist_dart.dart';
import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/flutter_util.dart';
import 'package:analysis_server/src/services/correction/name_suggestion.dart';
import 'package:analysis_server/src/services/correction/source_buffer.dart';
import 'package:analysis_server/src/services/correction/source_range.dart';
import 'package:analysis_server/src/services/correction/statement_analyzer.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart';

typedef _SimpleIdentifierVisitor(SimpleIdentifier node);

/**
 * The computer for Dart assists.
 */
class AssistProcessor {
  AnalysisContext analysisContext;

  Source source;
  String file;
  int fileStamp;

  CompilationUnit unit;
  CompilationUnitElement unitElement;

  LibraryElement unitLibraryElement;
  String unitLibraryFile;
  String unitLibraryFolder;

  int selectionOffset;
  int selectionLength;
  int selectionEnd;

  final List<Assist> assists = <Assist>[];
  final Map<String, LinkedEditGroup> linkedPositionGroups =
      <String, LinkedEditGroup>{};
  Position exitPosition = null;

  CorrectionUtils utils;
  AstNode node;

  SourceChange change = new SourceChange('<message>');

  AssistProcessor(DartAssistContext dartContext) {
    analysisContext = dartContext.analysisContext;
    // source
    source = dartContext.source;
    file = dartContext.source.fullName;
    fileStamp = analysisContext.getModificationStamp(source);
    // unit
    unit = dartContext.unit;
    unitElement = dartContext.unit.element;
    // library
    unitLibraryElement = resolutionMap
        .elementDeclaredByCompilationUnit(dartContext.unit)
        .library;
    unitLibraryFile = unitLibraryElement.source.fullName;
    unitLibraryFolder = dirname(unitLibraryFile);
    // selection
    selectionOffset = dartContext.selectionOffset;
    selectionLength = dartContext.selectionLength;
    selectionEnd = selectionOffset + selectionLength;
  }

  /**
   * Returns the EOL to use for this [CompilationUnit].
   */
  String get eol => utils.endOfLine;

  Future<List<Assist>> compute() async {
    // If the source was changed between the constructor and running
    // this asynchronous method, it is not safe to use the unit.
    if (analysisContext.getModificationStamp(source) != fileStamp) {
      return const <Assist>[];
    }

    try {
      utils = new CorrectionUtils(unit);
    } catch (e) {
      throw new CancelCorrectionException(exception: e);
    }

    node = new NodeLocator(selectionOffset, selectionEnd).searchWithin(unit);
    if (node == null) {
      return assists;
    }
    // try to add proposals
    _addProposal_addTypeAnnotation_DeclaredIdentifier();
    _addProposal_addTypeAnnotation_SimpleFormalParameter();
    _addProposal_addTypeAnnotation_VariableDeclaration();
    _addProposal_assignToLocalVariable();
    _addProposal_convertIntoFinalField();
    _addProposal_convertIntoGetter();
    _addProposal_convertDocumentationIntoBlock();
    _addProposal_convertDocumentationIntoLine();
    _addProposal_convertToBlockFunctionBody();
    _addProposal_convertToExpressionFunctionBody();
    _addProposal_convertFlutterChild();
    _addProposal_convertToForIndexLoop();
    _addProposal_convertToIsNot_onIs();
    _addProposal_convertToIsNot_onNot();
    _addProposal_convertToIsNotEmpty();
    _addProposal_convertToFieldParameter();
    _addProposal_convertToNormalParameter();
    _addProposal_encapsulateField();
    _addProposal_exchangeOperands();
    _addProposal_importAddShow();
    _addProposal_introduceLocalTestedType();
    _addProposal_invertIf();
    _addProposal_joinIfStatementInner();
    _addProposal_joinIfStatementOuter();
    _addProposal_joinVariableDeclaration_onAssignment();
    _addProposal_joinVariableDeclaration_onDeclaration();
    _addProposal_moveFlutterWidgetDown();
    _addProposal_moveFlutterWidgetUp();
    _addProposal_removeTypeAnnotation();
    _addProposal_reparentFlutterList();
    _addProposal_reparentFlutterWidget();
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
    if (change.edits.isEmpty) {
      _coverageMarker();
      return;
    }
    // prepare Change
    change.message = formatList(kind.message, args);
    linkedPositionGroups.values
        .forEach((group) => change.addLinkedEditGroup(group));
    change.selection = exitPosition;
    // add Assist
    Assist assist = new Assist(kind, change);
    assists.add(assist);
    // clear
    change = new SourceChange('<message>');
    linkedPositionGroups.clear();
    exitPosition = null;
  }

  void _addIndentEdit(SourceRange range, String oldIndent, String newIndent) {
    SourceEdit edit = utils.createIndentEdit(range, oldIndent, newIndent);
    doSourceChange_addElementEdit(change, unitElement, edit);
  }

  /**
   * Adds a new [Edit] to [edits].
   */
  void _addInsertEdit(int offset, String text) {
    SourceEdit edit = new SourceEdit(offset, 0, text);
    doSourceChange_addElementEdit(change, unitElement, edit);
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
      _configureTargetLocation(node);
      Set<Source> librariesToImport = new Set<Source>();
      typeSource = utils.getTypeSource(type, librariesToImport);
      addLibraryImports(change, unitLibraryElement, librariesToImport);
    } else {
      _coverageMarker();
      return;
    }
    // type source might be null, if the type is private
    if (typeSource == null) {
      _coverageMarker();
      return;
    }
    // add edit
    Token keyword = declaredIdentifier.keyword;
    if (keyword.keyword == Keyword.VAR) {
      SourceRange range = rangeToken(keyword);
      _addReplaceEdit(range, typeSource);
    } else {
      _addInsertEdit(declaredIdentifier.identifier.offset, '$typeSource ');
    }
    // add proposal
    _addAssist(DartAssistKind.ADD_TYPE_ANNOTATION, []);
  }

  void _addProposal_addTypeAnnotation_SimpleFormalParameter() {
    AstNode node = this.node;
    // should be the name of a simple parameter
    if (node is! SimpleIdentifier || node.parent is! SimpleFormalParameter) {
      _coverageMarker();
      return;
    }
    SimpleIdentifier name = node;
    SimpleFormalParameter parameter = node.parent;
    // the parameter should not have a type
    if (parameter.type != null) {
      _coverageMarker();
      return;
    }
    // prepare propagated type
    DartType type = name.propagatedType;
    // TODO(scheglov) If the parameter is in a method declaration, and if the
    // method overrides a method that has a type for the corresponding
    // parameter, it would be nice to copy down the type from the overridden
    // method.
    if (type is! InterfaceType) {
      _coverageMarker();
      return;
    }
    // prepare type source
    String typeSource;
    {
      _configureTargetLocation(node);
      Set<Source> librariesToImport = new Set<Source>();
      typeSource = utils.getTypeSource(type, librariesToImport);
      addLibraryImports(change, unitLibraryElement, librariesToImport);
    }
    // type source might be null, if the type is private
    if (typeSource == null) {
      _coverageMarker();
      return;
    }
    // add edit
    _addInsertEdit(name.offset, '$typeSource ');
    // add proposal
    _addAssist(DartAssistKind.ADD_TYPE_ANNOTATION, []);
  }

  void _addProposal_addTypeAnnotation_VariableDeclaration() {
    AstNode node = this.node;
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
    // must be not after the name of the variable
    if (selectionOffset > variable.name.end) {
      _coverageMarker();
      return;
    }
    // we need an initializer to get the type from
    Expression initializer = variable.initializer;
    if (initializer == null) {
      _coverageMarker();
      return;
    }
    DartType type = initializer.bestType;
    // prepare type source
    String typeSource;
    if (type is InterfaceType && !type.isDartCoreNull || type is FunctionType) {
      _configureTargetLocation(node);
      Set<Source> librariesToImport = new Set<Source>();
      typeSource = utils.getTypeSource(type, librariesToImport);
      addLibraryImports(change, unitLibraryElement, librariesToImport);
    } else {
      _coverageMarker();
      return;
    }
    // type source might be null, if the type is private
    if (typeSource == null) {
      _coverageMarker();
      return;
    }
    // add edit
    Token keyword = declarationList.keyword;
    if (keyword?.keyword == Keyword.VAR) {
      SourceRange range = rangeToken(keyword);
      _addReplaceEdit(range, typeSource);
    } else {
      _addInsertEdit(variable.offset, '$typeSource ');
    }
    // add proposal
    _addAssist(DartAssistKind.ADD_TYPE_ANNOTATION, []);
  }

  void _addProposal_assignToLocalVariable() {
    // prepare enclosing ExpressionStatement
    ExpressionStatement expressionStatement;
    for (AstNode node = this.node; node != null; node = node.parent) {
      if (node is ExpressionStatement) {
        expressionStatement = node;
        break;
      }
      if (node is ArgumentList ||
          node is AssignmentExpression ||
          node is Statement ||
          node is ThrowExpression) {
        _coverageMarker();
        return;
      }
    }
    if (expressionStatement == null) {
      _coverageMarker();
      return;
    }
    // prepare expression
    Expression expression = expressionStatement.expression;
    int offset = expression.offset;
    // prepare expression type
    DartType type = expression.bestType;
    if (type.isVoid) {
      _coverageMarker();
      return;
    }
    // prepare source
    SourceBuilder builder = new SourceBuilder(file, offset);
    builder.append('var ');
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
    // add proposal
    _insertBuilder(builder);
    _addAssist(DartAssistKind.ASSIGN_TO_LOCAL_VARIABLE, []);
  }

  void _addProposal_convertDocumentationIntoBlock() {
    Comment comment = node.getAncestor((n) => n is Comment);
    if (comment != null && comment.isDocumentation) {
      String prefix = utils.getNodePrefix(comment);
      SourceBuilder sb = new SourceBuilder(file, comment.offset);
      sb.append('/**');
      sb.append(eol);
      for (Token token in comment.tokens) {
        if (token is DocumentationCommentToken &&
            token.type == TokenType.SINGLE_LINE_COMMENT) {
          sb.append(prefix);
          sb.append(' *');
          sb.append(token.lexeme.substring('///'.length));
          sb.append(eol);
        } else {
          return;
        }
      }
      sb.append(prefix);
      sb.append(' */');
      _insertBuilder(sb, comment.length);
    }
    // add proposal
    _addAssist(DartAssistKind.CONVERT_DOCUMENTATION_INTO_BLOCK, []);
  }

  void _addProposal_convertDocumentationIntoLine() {
    Comment comment = node.getAncestor((n) => n is Comment);
    if (comment != null && comment.isDocumentation) {
      if (comment.tokens.length == 1) {
        Token token = comment.tokens.first;
        if (token.type == TokenType.MULTI_LINE_COMMENT) {
          String text = token.lexeme;
          List<String> lines = text.split('\n');
          String prefix = utils.getNodePrefix(comment);
          SourceBuilder sb = new SourceBuilder(file, comment.offset);
          bool firstLine = true;
          String linePrefix = '';
          for (String line in lines) {
            if (firstLine) {
              firstLine = false;
              String expectedPrefix = '/**';
              if (!line.startsWith(expectedPrefix)) {
                return;
              }
              line = line.substring(expectedPrefix.length).trim();
              if (line.isNotEmpty) {
                sb.append('/// ');
                sb.append(line);
                linePrefix = eol + prefix;
              }
            } else {
              if (line.startsWith(prefix + ' */')) {
                break;
              }
              String expectedPrefix = prefix + ' * ';
              if (!line.startsWith(expectedPrefix)) {
                return;
              }
              line = line.substring(expectedPrefix.length).trim();
              sb.append(linePrefix);
              sb.append('/// ');
              sb.append(line);
              linePrefix = eol + prefix;
            }
          }
          _insertBuilder(sb, comment.length);
        }
      }
    }
    // add proposal
    _addAssist(DartAssistKind.CONVERT_DOCUMENTATION_INTO_LINE, []);
  }

  void _addProposal_convertFlutterChild() {
    NamedExpression namedExp;
    // Allow assist to activate from either the new-expr or the child: arg.
    if (node is SimpleIdentifier &&
        node.parent is Label &&
        node.parent.parent is NamedExpression) {
      namedExp = node.parent.parent as NamedExpression;
      if ((node as SimpleIdentifier).name != 'child' ||
          namedExp.expression == null) {
        return;
      }
      if (namedExp.parent?.parent is! InstanceCreationExpression) {
        return;
      }
      InstanceCreationExpression newExpr = namedExp.parent.parent;
      if (newExpr == null || !isFlutterInstanceCreationExpression(newExpr)) {
        return;
      }
    } else {
      InstanceCreationExpression newExpr = identifyNewExpression(node);
      if (newExpr == null || !isFlutterInstanceCreationExpression(newExpr)) {
        _coverageMarker();
        return;
      }
      namedExp = findChildArgument(newExpr);
      if (namedExp == null || namedExp.expression == null) {
        _coverageMarker();
        return;
      }
    }
    InstanceCreationExpression childArg = getChildWidget(namedExp, false);
    if (childArg == null) {
      _coverageMarker();
      return;
    }
    convertFlutterChildToChildren(
        childArg,
        namedExp,
        eol,
        utils.getNodeText,
        utils.getLinePrefix,
        utils.getIndent,
        utils.getText,
        _addInsertEdit,
        _addRemoveEdit,
        _addReplaceEdit,
        rangeStartLength,
        rangeNode);
    _addAssist(DartAssistKind.CONVERT_FLUTTER_CHILD, []);
  }

  void _addProposal_convertIntoFinalField() {
    // Find the enclosing getter.
    MethodDeclaration getter;
    for (AstNode n = node; n != null; n = n.parent) {
      if (n is MethodDeclaration) {
        getter = n;
        break;
      }
      if (n is SimpleIdentifier ||
          n is TypeAnnotation ||
          n is TypeArgumentList) {
        continue;
      }
      break;
    }
    if (getter == null || !getter.isGetter) {
      return;
    }
    // Check that there is no corresponding setter.
    {
      ExecutableElement element = getter.element;
      if (element == null) {
        return;
      }
      Element enclosing = element.enclosingElement;
      if (enclosing is ClassElement) {
        if (enclosing.getSetter(element.name) != null) {
          return;
        }
      }
    }
    // Try to find the returned expression.
    Expression expression;
    {
      FunctionBody body = getter.body;
      if (body is ExpressionFunctionBody) {
        expression = body.expression;
      } else if (body is BlockFunctionBody) {
        List<Statement> statements = body.block.statements;
        if (statements.length == 1) {
          Statement statement = statements.first;
          if (statement is ReturnStatement) {
            expression = statement.expression;
          }
        }
      }
    }
    // Use the returned expression as the field initializer.
    if (expression != null) {
      AstNode beginNodeToReplace = getter.name;
      String code = 'final';
      if (getter.returnType != null) {
        beginNodeToReplace = getter.returnType;
        code += ' ' + _getNodeText(getter.returnType);
      }
      code += ' ' + _getNodeText(getter.name);
      if (expression is! NullLiteral) {
        code += ' = ' + _getNodeText(expression);
      }
      code += ';';
      _addReplaceEdit(rangeStartEnd(beginNodeToReplace, getter), code);
      _addAssist(DartAssistKind.CONVERT_INTO_FINAL_FIELD, []);
    }
  }

  void _addProposal_convertIntoGetter() {
    // Find the enclosing field declaration.
    FieldDeclaration fieldDeclaration;
    for (AstNode n = node; n != null; n = n.parent) {
      if (n is FieldDeclaration) {
        fieldDeclaration = n;
        break;
      }
      if (n is SimpleIdentifier ||
          n is VariableDeclaration ||
          n is VariableDeclarationList ||
          n is TypeAnnotation ||
          n is TypeArgumentList) {
        continue;
      }
      break;
    }
    if (fieldDeclaration == null) {
      return;
    }
    // The field must be final and has only one variable.
    VariableDeclarationList fieldList = fieldDeclaration.fields;
    if (!fieldList.isFinal || fieldList.variables.length != 1) {
      return;
    }
    VariableDeclaration field = fieldList.variables.first;
    // Prepare the initializer.
    Expression initializer = field.initializer;
    if (initializer == null) {
      return;
    }
    // Add proposal.
    String code = '';
    if (fieldList.type != null) {
      code += _getNodeText(fieldList.type) + ' ';
    }
    code += 'get';
    code += ' ' + _getNodeText(field.name);
    code += ' => ' + _getNodeText(initializer);
    code += ';';
    _addReplaceEdit(rangeStartEnd(fieldList.keyword, fieldDeclaration), code);
    _addAssist(DartAssistKind.CONVERT_INTO_GETTER, []);
  }

  void _addProposal_convertToBlockFunctionBody() {
    FunctionBody body = getEnclosingFunctionBody();
    // prepare expression body
    if (body is! ExpressionFunctionBody || body.isGenerator) {
      _coverageMarker();
      return;
    }
    Expression returnValue = (body as ExpressionFunctionBody).expression;
    DartType returnValueType = returnValue.staticType;
    String returnValueCode = _getNodeText(returnValue);
    // prepare prefix
    String prefix = utils.getNodePrefix(body.parent);
    String indent = utils.getIndent(1);
    // add change
    SourceBuilder sb = new SourceBuilder(file, body.offset);
    if (body.isAsynchronous) {
      sb.append('async ');
    }
    sb.append('{$eol$prefix$indent');
    if (!returnValueType.isVoid) {
      sb.append('return ');
    }
    sb.append(returnValueCode);
    sb.append(';');
    sb.setExitOffset();
    sb.append('$eol$prefix}');
    _insertBuilder(sb, body.length);
    // add proposal
    _addAssist(DartAssistKind.CONVERT_INTO_BLOCK_BODY, []);
  }

  void _addProposal_convertToExpressionFunctionBody() {
    // prepare current body
    FunctionBody body = getEnclosingFunctionBody();
    if (body is! BlockFunctionBody || body.isGenerator) {
      _coverageMarker();
      return;
    }
    // prepare return statement
    List<Statement> statements = (body as BlockFunctionBody).block.statements;
    if (statements.length != 1) {
      _coverageMarker();
      return;
    }
    Statement onlyStatement = statements.first;
    // prepare returned expression
    Expression returnExpression;
    if (onlyStatement is ReturnStatement) {
      returnExpression = onlyStatement.expression;
    } else if (onlyStatement is ExpressionStatement) {
      returnExpression = onlyStatement.expression;
    }
    if (returnExpression == null) {
      _coverageMarker();
      return;
    }
    // add change
    SourceBuilder sb = new SourceBuilder(file, body.offset);
    if (body.isAsynchronous) {
      sb.append('async ');
    }
    sb.append('=> ');
    sb.append(_getNodeText(returnExpression));
    if (body.parent is! FunctionExpression ||
        body.parent.parent is FunctionDeclaration) {
      sb.append(';');
    }
    _insertBuilder(sb, body.length);
    // add proposal
    _addAssist(DartAssistKind.CONVERT_INTO_EXPRESSION_BODY, []);
  }

  void _addProposal_convertToFieldParameter() {
    if (node == null) {
      return;
    }
    // prepare ConstructorDeclaration
    ConstructorDeclaration constructor =
        node.getAncestor((node) => node is ConstructorDeclaration);
    if (constructor == null) {
      return;
    }
    FormalParameterList parameterList = constructor.parameters;
    List<ConstructorInitializer> initializers = constructor.initializers;
    // prepare parameter
    SimpleFormalParameter parameter;
    if (node.parent is SimpleFormalParameter &&
        node.parent.parent is FormalParameterList &&
        node.parent.parent.parent is ConstructorDeclaration) {
      parameter = node.parent;
    }
    if (node is SimpleIdentifier &&
        node.parent is ConstructorFieldInitializer) {
      String name = (node as SimpleIdentifier).name;
      ConstructorFieldInitializer initializer = node.parent;
      if (initializer.expression == node) {
        for (FormalParameter formalParameter in parameterList.parameters) {
          if (formalParameter is SimpleFormalParameter &&
              formalParameter.identifier.name == name) {
            parameter = formalParameter;
          }
        }
      }
    }
    // analyze parameter
    if (parameter != null) {
      String parameterName = parameter.identifier.name;
      ParameterElement parameterElement = parameter.element;
      // check number of references
      {
        int numOfReferences = 0;
        AstVisitor visitor =
            new _SimpleIdentifierRecursiveAstVisitor((SimpleIdentifier node) {
          if (node.staticElement == parameterElement) {
            numOfReferences++;
          }
        });
        for (ConstructorInitializer initializer in initializers) {
          initializer.accept(visitor);
        }
        if (numOfReferences != 1) {
          return;
        }
      }
      // find the field initializer
      ConstructorFieldInitializer parameterInitializer;
      for (ConstructorInitializer initializer in initializers) {
        if (initializer is ConstructorFieldInitializer) {
          Expression expression = initializer.expression;
          if (expression is SimpleIdentifier &&
              expression.name == parameterName) {
            parameterInitializer = initializer;
          }
        }
      }
      if (parameterInitializer == null) {
        return;
      }
      String fieldName = parameterInitializer.fieldName.name;
      // replace parameter
      _addReplaceEdit(rangeNode(parameter), 'this.$fieldName');
      // remove initializer
      int initializerIndex = initializers.indexOf(parameterInitializer);
      if (initializers.length == 1) {
        _addRemoveEdit(rangeEndEnd(parameterList, parameterInitializer));
      } else {
        if (initializerIndex == 0) {
          ConstructorInitializer next = initializers[initializerIndex + 1];
          _addRemoveEdit(rangeStartStart(parameterInitializer, next));
        } else {
          ConstructorInitializer prev = initializers[initializerIndex - 1];
          _addRemoveEdit(rangeEndEnd(prev, parameterInitializer));
        }
      }
      // add proposal
      _addAssist(DartAssistKind.CONVERT_TO_FIELD_PARAMETER, []);
    }
  }

  void _addProposal_convertToForIndexLoop() {
    // find enclosing ForEachStatement
    ForEachStatement forEachStatement =
        node.getAncestor((n) => n is ForEachStatement);
    if (forEachStatement == null) {
      _coverageMarker();
      return;
    }
    if (selectionOffset < forEachStatement.offset ||
        forEachStatement.rightParenthesis.end < selectionOffset) {
      _coverageMarker();
      return;
    }
    // loop should declare variable
    DeclaredIdentifier loopVariable = forEachStatement.loopVariable;
    if (loopVariable == null) {
      _coverageMarker();
      return;
    }
    // iterable should be VariableElement
    String listName;
    Expression iterable = forEachStatement.iterable;
    if (iterable is SimpleIdentifier &&
        iterable.staticElement is VariableElement) {
      listName = iterable.name;
    } else {
      _coverageMarker();
      return;
    }
    // iterable should be List
    {
      DartType iterableType = iterable.bestType;
      InterfaceType listType = analysisContext.typeProvider.listType;
      if (iterableType is! InterfaceType ||
          iterableType.element != listType.element) {
        _coverageMarker();
        return;
      }
    }
    // body should be Block
    if (forEachStatement.body is! Block) {
      _coverageMarker();
      return;
    }
    Block body = forEachStatement.body;
    // prepare a name for the index variable
    String indexName;
    {
      Set<String> conflicts =
          utils.findPossibleLocalVariableConflicts(forEachStatement.offset);
      if (!conflicts.contains('i')) {
        indexName = 'i';
      } else if (!conflicts.contains('j')) {
        indexName = 'j';
      } else if (!conflicts.contains('k')) {
        indexName = 'k';
      } else {
        _coverageMarker();
        return;
      }
    }
    // prepare environment
    String prefix = utils.getNodePrefix(forEachStatement);
    String indent = utils.getIndent(1);
    int firstBlockLine = utils.getLineContentEnd(body.leftBracket.end);
    // add change
    _addReplaceEdit(
        rangeStartEnd(forEachStatement, forEachStatement.rightParenthesis),
        'for (int $indexName = 0; $indexName < $listName.length; $indexName++)');
    _addInsertEdit(firstBlockLine,
        '$prefix$indent$loopVariable = $listName[$indexName];$eol');
    // add proposal
    _addAssist(DartAssistKind.CONVERT_INTO_FOR_INDEX, []);
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
        TokenClass.RELATIONAL_OPERATOR.precedence) {
      _addRemoveEdit(rangeToken(prefExpression.operator));
    } else {
      _addRemoveEdit(
          rangeStartEnd(prefExpression, parExpression.leftParenthesis));
      _addRemoveEdit(
          rangeStartEnd(parExpression.rightParenthesis, prefExpression));
    }
    _addInsertEdit(isExpression.isOperator.end, '!');
    // add proposal
    _addAssist(DartAssistKind.CONVERT_INTO_IS_NOT, []);
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
        TokenClass.RELATIONAL_OPERATOR.precedence) {
      _addRemoveEdit(rangeToken(prefExpression.operator));
    } else {
      _addRemoveEdit(
          rangeStartEnd(prefExpression, parExpression.leftParenthesis));
      _addRemoveEdit(
          rangeStartEnd(parExpression.rightParenthesis, prefExpression));
    }
    _addInsertEdit(isExpression.isOperator.end, '!');
    // add proposal
    _addAssist(DartAssistKind.CONVERT_INTO_IS_NOT, []);
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
    if (propertyElement == null || 'isEmpty' != propertyElement.name) {
      _coverageMarker();
      return;
    }
    // should have "isNotEmpty"
    Element propertyTarget = propertyElement.enclosingElement;
    if (propertyTarget == null ||
        getChildren(propertyTarget, 'isNotEmpty').isEmpty) {
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
      _coverageMarker();
      return;
    }
    // do replace
    _addRemoveEdit(rangeStartStart(prefixExpression, prefixExpression.operand));
    _addReplaceEdit(rangeNode(isEmptyIdentifier), 'isNotEmpty');
    // add proposal
    _addAssist(DartAssistKind.CONVERT_INTO_IS_NOT_EMPTY, []);
  }

  void _addProposal_convertToNormalParameter() {
    if (node is SimpleIdentifier &&
        node.parent is FieldFormalParameter &&
        node.parent.parent is FormalParameterList &&
        node.parent.parent.parent is ConstructorDeclaration) {
      ConstructorDeclaration constructor = node.parent.parent.parent;
      FormalParameterList parameterList = node.parent.parent;
      FieldFormalParameter parameter = node.parent;
      ParameterElement parameterElement = parameter.element;
      String name = (node as SimpleIdentifier).name;
      // prepare type
      DartType type = parameterElement.type;
      Set<Source> librariesToImport = new Set<Source>();
      String typeCode = utils.getTypeSource(type, librariesToImport);
      // replace parameter
      if (type.isDynamic) {
        _addReplaceEdit(rangeNode(parameter), name);
      } else {
        _addReplaceEdit(rangeNode(parameter), '$typeCode $name');
      }
      // add field initializer
      List<ConstructorInitializer> initializers = constructor.initializers;
      if (initializers.isEmpty) {
        _addInsertEdit(parameterList.end, ' : $name = $name');
      } else {
        _addInsertEdit(initializers.last.end, ', $name = $name');
      }
      // add proposal
      _addAssist(DartAssistKind.CONVERT_TO_NORMAL_PARAMETER, []);
    }
  }

  void _addProposal_encapsulateField() {
    // find FieldDeclaration
    FieldDeclaration fieldDeclaration =
        node.getAncestor((x) => x is FieldDeclaration);
    if (fieldDeclaration == null) {
      _coverageMarker();
      return;
    }
    // not interesting for static
    if (fieldDeclaration.isStatic) {
      _coverageMarker();
      return;
    }
    // has a parse error
    VariableDeclarationList variableList = fieldDeclaration.fields;
    if (variableList.keyword == null && variableList.type == null) {
      _coverageMarker();
      return;
    }
    // not interesting for final
    if (variableList.isFinal) {
      _coverageMarker();
      return;
    }
    // should have exactly one field
    List<VariableDeclaration> fields = variableList.variables;
    if (fields.length != 1) {
      _coverageMarker();
      return;
    }
    VariableDeclaration field = fields.first;
    SimpleIdentifier nameNode = field.name;
    FieldElement fieldElement = nameNode.staticElement;
    // should have a public name
    String name = nameNode.name;
    if (Identifier.isPrivateName(name)) {
      _coverageMarker();
      return;
    }
    // should be on the name
    if (nameNode != node) {
      _coverageMarker();
      return;
    }
    // rename field
    _addReplaceEdit(rangeNode(nameNode), '_$name');
    // update references in constructors
    ClassDeclaration classDeclaration = fieldDeclaration.parent;
    for (ClassMember member in classDeclaration.members) {
      if (member is ConstructorDeclaration) {
        for (FormalParameter parameter in member.parameters.parameters) {
          ParameterElement parameterElement = parameter.element;
          if (parameterElement is FieldFormalParameterElement &&
              parameterElement.field == fieldElement) {
            _addReplaceEdit(rangeNode(parameter.identifier), '_$name');
          }
        }
      }
    }
    // add accessors
    String eol2 = eol + eol;
    String typeNameCode =
        variableList.type != null ? _getNodeText(variableList.type) + ' ' : '';
    String getterCode = '$eol2  ${typeNameCode}get $name => _$name;';
    String setterCode = '$eol2'
        '  void set $name($typeNameCode$name) {$eol'
        '    _$name = $name;$eol'
        '  }';
    _addInsertEdit(fieldDeclaration.end, getterCode + setterCode);
    // add proposal
    _addAssist(DartAssistKind.ENCAPSULATE_FIELD, []);
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
        binaryExpression, selectionOffset, selectionLength)) {
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
      // maybe replace the operator
      {
        Token operator = binaryExpression.operator;
        // prepare a new operator
        String newOperator = null;
        TokenType operatorType = operator.type;
        if (operatorType == TokenType.LT) {
          newOperator = '>';
        } else if (operatorType == TokenType.LT_EQ) {
          newOperator = '>=';
        } else if (operatorType == TokenType.GT) {
          newOperator = '<';
        } else if (operatorType == TokenType.GT_EQ) {
          newOperator = '<=';
        }
        // replace the operator
        if (newOperator != null) {
          _addReplaceEdit(rangeToken(operator), newOperator);
        }
      }
    }
    // add proposal
    _addAssist(DartAssistKind.EXCHANGE_OPERANDS, []);
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
    String showCombinator = ' show ${referencedNames.join(', ')}';
    _addInsertEdit(importDirective.end - 1, showCombinator);
    // add proposal
    _addAssist(DartAssistKind.IMPORT_ADD_SHOW, []);
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
      if (statement is IfStatement && statement.thenStatement is Block) {
        targetBlock = statement.thenStatement;
      } else if (statement is WhileStatement && statement.body is Block) {
        targetBlock = statement.body;
      } else {
        _coverageMarker();
        return;
      }
      prefix = utils.getNodePrefix(statement);
    }
    // prepare location
    int offset;
    String statementPrefix;
    if (isExpression.notOperator == null) {
      offset = targetBlock.leftBracket.end;
      statementPrefix = indent;
    } else {
      offset = targetBlock.rightBracket.end;
      statementPrefix = '';
    }
    // prepare source
    SourceBuilder builder = new SourceBuilder(file, offset);
    builder.append(eol + prefix + statementPrefix);
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
    _addAssist(DartAssistKind.INTRODUCE_LOCAL_CAST_TYPE, []);
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
    _addAssist(DartAssistKind.INVERT_IF_STATEMENT, []);
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
        targetConditionSource = '($targetConditionSource)';
      }
      if (_shouldWrapParenthesisBeforeAnd(innerCondition)) {
        innerConditionSource = '($innerConditionSource)';
      }
      condition = '$targetConditionSource && $innerConditionSource';
    }
    // replace target "if" statement
    {
      Statement innerThenStatement = innerIfStatement.thenStatement;
      List<Statement> innerThenStatements = getStatements(innerThenStatement);
      SourceRange lineRanges =
          utils.getLinesRangeStatements(innerThenStatements);
      String oldSource = utils.getRangeText(lineRanges);
      String newSource = utils.indentSourceLeftRight(oldSource, false);
      _addReplaceEdit(rangeNode(targetIfStatement),
          'if ($condition) {$eol$newSource$prefix}');
    }
    // done
    _addAssist(DartAssistKind.JOIN_IF_WITH_INNER, []);
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
      if ((parent as Block).statements.length != 1) {
        _coverageMarker();
        return;
      }
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
        targetConditionSource = '($targetConditionSource)';
      }
      if (_shouldWrapParenthesisBeforeAnd(outerCondition)) {
        outerConditionSource = '($outerConditionSource)';
      }
      condition = '$outerConditionSource && $targetConditionSource';
    }
    // replace outer "if" statement
    {
      Statement targetThenStatement = targetIfStatement.thenStatement;
      List<Statement> targetThenStatements = getStatements(targetThenStatement);
      SourceRange lineRanges =
          utils.getLinesRangeStatements(targetThenStatements);
      String oldSource = utils.getRangeText(lineRanges);
      String newSource = utils.indentSourceLeftRight(oldSource, false);
      _addReplaceEdit(rangeNode(outerIfStatement),
          'if ($condition) {$eol$newSource$prefix}');
    }
    // done
    _addAssist(DartAssistKind.JOIN_IF_WITH_OUTER, []);
  }

  void _addProposal_joinVariableDeclaration_onAssignment() {
    // check that node is LHS in assignment
    if (node is SimpleIdentifier &&
        node.parent is AssignmentExpression &&
        (node.parent as AssignmentExpression).leftHandSide == node &&
        node.parent.parent is ExpressionStatement) {} else {
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
    AstNode declNode = new NodeLocator(declOffset).searchWithin(unit);
    if (declNode != null &&
        declNode.parent is VariableDeclaration &&
        (declNode.parent as VariableDeclaration).name == declNode &&
        declNode.parent.parent is VariableDeclarationList &&
        declNode.parent.parent.parent is VariableDeclarationStatement) {} else {
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
        assignStatement.parent == declStatement.parent) {} else {
      _coverageMarker();
      return;
    }
    Block block = assignStatement.parent as Block;
    // check that "declaration" and "assignment" statements are adjacent
    List<Statement> statements = block.statements;
    if (statements.indexOf(assignStatement) ==
        statements.indexOf(declStatement) + 1) {} else {
      _coverageMarker();
      return;
    }
    // add edits
    {
      int assignOffset = assignExpression.operator.offset;
      _addReplaceEdit(rangeEndStart(declNode, assignOffset), ' ');
    }
    // add proposal
    _addAssist(DartAssistKind.JOIN_VARIABLE_DECLARATION, []);
  }

  void _addProposal_joinVariableDeclaration_onDeclaration() {
    // prepare enclosing VariableDeclarationList
    VariableDeclarationList declList =
        node.getAncestor((node) => node is VariableDeclarationList);
    if (declList != null && declList.variables.length == 1) {} else {
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
        declList.parent.parent is Block) {} else {
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
      if (declIndex < statements.length - 1) {} else {
        _coverageMarker();
        return;
      }
      // next Statement should be assignment
      Statement assignStatement = statements[declIndex + 1];
      if (assignStatement is ExpressionStatement) {} else {
        _coverageMarker();
        return;
      }
      ExpressionStatement expressionStatement =
          assignStatement as ExpressionStatement;
      // expression should be assignment
      if (expressionStatement.expression is AssignmentExpression) {} else {
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
      _addReplaceEdit(rangeEndStart(decl.name, assignOffset), ' ');
    }
    // add proposal
    _addAssist(DartAssistKind.JOIN_VARIABLE_DECLARATION, []);
  }

  void _addProposal_moveFlutterWidgetDown() {
    InstanceCreationExpression exprGoingDown = identifyNewExpression(node);
    if (exprGoingDown == null ||
        !isFlutterInstanceCreationExpression(exprGoingDown)) {
      _coverageMarker();
      return;
    }
    InstanceCreationExpression exprGoingUp = findChildWidget(exprGoingDown);
    if (exprGoingUp == null) {
      _coverageMarker();
      return;
    }
    NamedExpression stableChild = findChildArgument(exprGoingUp);
    if (stableChild == null || stableChild.expression == null) {
      _coverageMarker();
      return;
    }
    String exprGoingDownSrc = utils.getNodeText(exprGoingDown);
    int dnNewlineIdx = exprGoingDownSrc.lastIndexOf(eol);
    if (dnNewlineIdx < 0 || dnNewlineIdx == exprGoingDownSrc.length - 1) {
      _coverageMarker();
      return; // Outer new-expr needs to be in multi-line format already.
    }
    String exprGoingUpSrc = utils.getNodeText(exprGoingUp);
    int upNewlineIdx = exprGoingUpSrc.lastIndexOf(eol);
    if (upNewlineIdx < 0 || upNewlineIdx == exprGoingUpSrc.length - 1) {
      _coverageMarker();
      return; // Inner new-expr needs to be in multi-line format already.
    }
    _swapFlutterWidgets(exprGoingDown, exprGoingUp, stableChild,
        DartAssistKind.MOVE_FLUTTER_WIDGET_DOWN);
  }

  void _addProposal_moveFlutterWidgetUp() {
    InstanceCreationExpression exprGoingUp = identifyNewExpression(node);
    if (exprGoingUp == null ||
        !isFlutterInstanceCreationExpression(exprGoingUp)) {
      _coverageMarker();
      return;
    }
    AstNode expr = exprGoingUp.parent?.parent?.parent;
    if (expr == null || expr is! InstanceCreationExpression) {
      _coverageMarker();
      return;
    }
    InstanceCreationExpression exprGoingDown = expr;
    NamedExpression stableChild = findChildArgument(exprGoingUp);
    if (stableChild == null || stableChild.expression == null) {
      _coverageMarker();
      return;
    }
    String exprGoingUpSrc = utils.getNodeText(exprGoingUp);
    int upNewlineIdx = exprGoingUpSrc.lastIndexOf(eol);
    if (upNewlineIdx < 0 || upNewlineIdx == exprGoingUpSrc.length - 1) {
      _coverageMarker();
      return; // Inner new-expr needs to be in multi-line format already.
    }
    String exprGoingDownSrc = utils.getNodeText(exprGoingDown);
    int dnNewlineIdx = exprGoingDownSrc.lastIndexOf(eol);
    if (dnNewlineIdx < 0 || dnNewlineIdx == exprGoingDownSrc.length - 1) {
      _coverageMarker();
      return; // Outer new-expr needs to be in multi-line format already.
    }
    _swapFlutterWidgets(exprGoingDown, exprGoingUp, stableChild,
        DartAssistKind.MOVE_FLUTTER_WIDGET_UP);
  }

  void _addProposal_removeTypeAnnotation() {
    VariableDeclarationList declarationList =
        node.getAncestor((n) => n is VariableDeclarationList);
    if (declarationList == null) {
      _coverageMarker();
      return;
    }
    // we need a type
    TypeAnnotation typeNode = declarationList.type;
    if (typeNode == null) {
      _coverageMarker();
      return;
    }
    // ignore if an incomplete variable declaration
    if (declarationList.variables.length == 1 &&
        declarationList.variables[0].name.isSynthetic) {
      _coverageMarker();
      return;
    }
    // must be not after the name of the variable
    VariableDeclaration firstVariable = declarationList.variables[0];
    if (selectionOffset > firstVariable.name.end) {
      _coverageMarker();
      return;
    }
    // add edit
    Token keyword = declarationList.keyword;
    SourceRange typeRange = rangeStartStart(typeNode, firstVariable);
    if (keyword != null && keyword.lexeme != 'var') {
      _addReplaceEdit(typeRange, '');
    } else {
      _addReplaceEdit(typeRange, 'var ');
    }
    // add proposal
    _addAssist(DartAssistKind.REMOVE_TYPE_ANNOTATION, []);
  }

  void _addProposal_reparentFlutterList() {
    if (node is! ListLiteral) {
      return;
    }
    if ((node as ListLiteral).elements.any((Expression exp) =>
        !(exp is InstanceCreationExpression &&
            isFlutterInstanceCreationExpression(exp)))) {
      _coverageMarker();
      return;
    }
    String literalSrc = utils.getNodeText(node);
    SourceBuilder sb = new SourceBuilder(file, node.offset);
    int newlineIdx = literalSrc.lastIndexOf(eol);
    if (newlineIdx < 0 || newlineIdx == literalSrc.length - 1) {
      _coverageMarker();
      return; // Lists need to be in multi-line format already.
    }
    String indentOld = utils.getLinePrefix(node.offset + 1 + newlineIdx);
    String indentArg = '$indentOld${utils.getIndent(1)}';
    String indentList = '$indentOld${utils.getIndent(2)}';
    sb.append('[');
    sb.append(eol);
    sb.append(indentArg);
    sb.append('new ');
    sb.startPosition('WIDGET');
    sb.append('widget');
    sb.endPosition();
    sb.append('(');
    sb.append(eol);
    sb.append(indentList);
    // Linked editing not needed since arg is always a list.
    sb.append('children: ');
    sb.append(literalSrc.replaceAll(
        new RegExp("^$indentOld", multiLine: true), "$indentList"));
    sb.append(',');
    sb.append(eol);
    sb.append(indentArg);
    sb.append('),');
    sb.append(eol);
    sb.append(indentOld);
    sb.append(']');
    exitPosition = _newPosition(sb.offset + sb.length);
    _insertBuilder(sb, literalSrc.length);
    _addAssist(DartAssistKind.REPARENT_FLUTTER_LIST, []);
  }

  void _addProposal_reparentFlutterWidget() {
    InstanceCreationExpression newExpr = identifyNewExpression(node);
    if (newExpr == null || !isFlutterInstanceCreationExpression(newExpr)) {
      _coverageMarker();
      return;
    }
    String newExprSrc = utils.getNodeText(newExpr);
    SourceBuilder sb = new SourceBuilder(file, newExpr.offset);
    sb.append('new ');
    sb.startPosition('WIDGET');
    sb.append('widget');
    sb.endPosition();
    sb.append('(');
    if (newExprSrc.contains(eol)) {
      int newlineIdx = newExprSrc.lastIndexOf(eol);
      if (newlineIdx == newExprSrc.length - 1) {
        newlineIdx -= 1;
      }
      String indentOld = utils.getLinePrefix(newExpr.offset + 1 + newlineIdx);
      String indentNew = '$indentOld${utils.getIndent(1)}';
      sb.append(eol);
      sb.append(indentNew);
      newExprSrc = newExprSrc.replaceAll(
          new RegExp("^$indentOld", multiLine: true), "$indentNew");
      newExprSrc += ",$eol$indentOld";
    }
    sb.startPosition('CHILD');
    sb.append('child');
    sb.endPosition();
    sb.append(': ');
    sb.append(newExprSrc);
    sb.append(')');
    exitPosition = _newPosition(sb.offset + sb.length);
    _insertBuilder(sb, newExpr.length);
    _addAssist(DartAssistKind.REPARENT_FLUTTER_WIDGET, []);
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
      for (VariableDeclaration variable
          in variableStatement.variables.variables) {
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
    _addAssist(DartAssistKind.REPLACE_CONDITIONAL_WITH_IF_ELSE, []);
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
    if (thenStatement is ReturnStatement && elseStatement is ReturnStatement) {
      String conditionSrc = _getNodeText(ifStatement.condition);
      String theSrc = _getNodeText(thenStatement.expression);
      String elseSrc = _getNodeText(elseStatement.expression);
      _addReplaceEdit(
          rangeNode(ifStatement), 'return $conditionSrc ? $theSrc : $elseSrc;');
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
            thenTarget == elseTarget) {
          String conditionSrc = _getNodeText(ifStatement.condition);
          String theSrc = _getNodeText(thenAssignment.rightHandSide);
          String elseSrc = _getNodeText(elseAssignment.rightHandSide);
          _addReplaceEdit(rangeNode(ifStatement),
              '$thenTarget = $conditionSrc ? $theSrc : $elseSrc;');
        }
      }
    }
    // add proposal
    _addAssist(DartAssistKind.REPLACE_IF_ELSE_WITH_CONDITIONAL, []);
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
        binaryExpression, selectionOffset, selectionLength)) {
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
    // no support "else"
    if (ifStatement.elseStatement != null) {
      _coverageMarker();
      return;
    }
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
    if (thenStatement is Block) {
      Block thenBlock = thenStatement;
      SourceRange thenBlockRange = rangeNode(thenBlock);
      // insert inner "if" with right part of "condition"
      {
        String source = '$eol$prefix${indent}if ($rightConditionSource) {';
        int thenBlockInsideOffset = thenBlockRange.offset + 1;
        _addInsertEdit(thenBlockInsideOffset, source);
      }
      // insert closing "}" for inner "if"
      {
        int thenBlockEnd = thenBlockRange.end;
        String source = "$indent}";
        // insert before outer "then" block "}"
        source += '$eol$prefix';
        _addInsertEdit(thenBlockEnd - 1, source);
      }
    } else {
      // insert inner "if" with right part of "condition"
      String source = '$eol$prefix${indent}if ($rightConditionSource)';
      _addInsertEdit(ifStatement.rightParenthesis.offset + 1, source);
    }
    // indent "then" statements to correspond inner "if"
    {
      List<Statement> thenStatements = getStatements(thenStatement);
      SourceRange linesRange = utils.getLinesRangeStatements(thenStatements);
      String thenIndentOld = '$prefix$indent';
      String thenIndentNew = '$thenIndentOld$indent';
      _addIndentEdit(linesRange, thenIndentOld, thenIndentNew);
    }
    // add proposal
    _addAssist(DartAssistKind.SPLIT_AND_CONDITION, []);
  }

  void _addProposal_splitVariableDeclaration() {
    // prepare DartVariableStatement, should be part of Block
    VariableDeclarationStatement statement =
        node.getAncestor((node) => node is VariableDeclarationStatement);
    if (statement != null && statement.parent is Block) {} else {
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
    _addAssist(DartAssistKind.SPLIT_VARIABLE_DECLARATION, []);
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
    String indentNew = '$indentOld${utils.getIndent(1)}';
    String indentedCode =
        utils.replaceSourceRangeIndent(statementsRange, indentOld, indentNew);
    // "block"
    {
      _addInsertEdit(statementsRange.offset, '$indentOld{$eol');
      _addIndentEdit(statementsRange, indentOld, indentNew);
      _addInsertEdit(statementsRange.end, '$indentOld}$eol');
      exitPosition = _newPosition(lastStatement.end);
      // add proposal
      _addAssist(DartAssistKind.SURROUND_WITH_BLOCK, []);
    }
    // "if"
    {
      int offset = statementsRange.offset;
      SourceBuilder sb = new SourceBuilder(file, offset);
      sb.append(indentOld);
      sb.append('if (');
      {
        sb.startPosition('CONDITION');
        sb.append('condition');
        sb.endPosition();
      }
      sb.append(') {');
      sb.append(eol);
      sb.append(indentedCode);
      sb.append(indentOld);
      sb.append('}');
      exitPosition = _newPosition(sb.offset + sb.length);
      sb.append(eol);
      _insertBuilder(sb, statementsRange.length);
      // add proposal
      _addAssist(DartAssistKind.SURROUND_WITH_IF, []);
    }
    // "while"
    {
      int offset = statementsRange.offset;
      SourceBuilder sb = new SourceBuilder(file, offset);
      sb.append(indentOld);
      sb.append('while (');
      {
        sb.startPosition('CONDITION');
        sb.append('condition');
        sb.endPosition();
      }
      sb.append(') {');
      sb.append(eol);
      sb.append(indentedCode);
      sb.append(indentOld);
      sb.append('}');
      exitPosition = _newPosition(sb.offset + sb.length);
      sb.append(eol);
      _insertBuilder(sb, statementsRange.length);
      // add proposal
      _addAssist(DartAssistKind.SURROUND_WITH_WHILE, []);
    }
    // "for-in"
    {
      int offset = statementsRange.offset;
      SourceBuilder sb = new SourceBuilder(file, offset);
      sb.append(indentOld);
      sb.append('for (var ');
      {
        sb.startPosition('NAME');
        sb.append('item');
        sb.endPosition();
      }
      sb.append(' in ');
      {
        sb.startPosition('ITERABLE');
        sb.append('iterable');
        sb.endPosition();
      }
      sb.append(') {');
      sb.append(eol);
      sb.append(indentedCode);
      sb.append(indentOld);
      sb.append('}');
      exitPosition = _newPosition(sb.offset + sb.length);
      sb.append(eol);
      _insertBuilder(sb, statementsRange.length);
      // add proposal
      _addAssist(DartAssistKind.SURROUND_WITH_FOR_IN, []);
    }
    // "for"
    {
      int offset = statementsRange.offset;
      SourceBuilder sb = new SourceBuilder(file, offset);
      sb.append(indentOld);
      sb.append('for (var ');
      {
        sb.startPosition('VAR');
        sb.append('v');
        sb.endPosition();
      }
      sb.append(' = ');
      {
        sb.startPosition('INIT');
        sb.append('init');
        sb.endPosition();
      }
      sb.append('; ');
      {
        sb.startPosition('CONDITION');
        sb.append('condition');
        sb.endPosition();
      }
      sb.append('; ');
      {
        sb.startPosition('INCREMENT');
        sb.append('increment');
        sb.endPosition();
      }
      sb.append(') {');
      sb.append(eol);
      sb.append(indentedCode);
      sb.append(indentOld);
      sb.append('}');
      exitPosition = _newPosition(sb.offset + sb.length);
      sb.append(eol);
      _insertBuilder(sb, statementsRange.length);
      // add proposal
      _addAssist(DartAssistKind.SURROUND_WITH_FOR, []);
    }
    // "do-while"
    {
      int offset = statementsRange.offset;
      SourceBuilder sb = new SourceBuilder(file, offset);
      sb.append(indentOld);
      sb.append('do {');
      sb.append(eol);
      sb.append(indentedCode);
      sb.append(indentOld);
      sb.append('} while (');
      {
        sb.startPosition('CONDITION');
        sb.append('condition');
        sb.endPosition();
      }
      sb.append(');');
      exitPosition = _newPosition(sb.offset + sb.length);
      sb.append(eol);
      _insertBuilder(sb, statementsRange.length);
      // add proposal
      _addAssist(DartAssistKind.SURROUND_WITH_DO_WHILE, []);
    }
    // "try-catch"
    {
      int offset = statementsRange.offset;
      SourceBuilder sb = new SourceBuilder(file, offset);
      sb.append(indentOld);
      sb.append('try {');
      sb.append(eol);
      sb.append(indentedCode);
      sb.append(indentOld);
      sb.append('} on ');
      {
        sb.startPosition('EXCEPTION_TYPE');
        sb.append('Exception');
        sb.endPosition();
      }
      sb.append(' catch (');
      {
        sb.startPosition('EXCEPTION_VAR');
        sb.append('e');
        sb.endPosition();
      }
      sb.append(') {');
      sb.append(eol);
      //
      sb.append(indentNew);
      {
        sb.startPosition('CATCH');
        sb.append('// TODO');
        sb.endPosition();
        sb.setExitOffset();
      }
      sb.append(eol);
      //
      sb.append(indentOld);
      sb.append('}');
      sb.append(eol);
      _insertBuilder(sb, statementsRange.length);
      // add proposal
      _addAssist(DartAssistKind.SURROUND_WITH_TRY_CATCH, []);
    }
    // "try-finally"
    {
      int offset = statementsRange.offset;
      SourceBuilder sb = new SourceBuilder(file, offset);
      //
      sb.append(indentOld);
      sb.append('try {');
      sb.append(eol);
      //
      sb.append(indentedCode);
      //
      sb.append(indentOld);
      sb.append('} finally {');
      sb.append(eol);
      //
      sb.append(indentNew);
      {
        sb.startPosition('FINALLY');
        sb.append('// TODO');
        sb.endPosition();
        sb.setExitOffset();
      }
      sb.setExitOffset();
      sb.append(eol);
      //
      sb.append(indentOld);
      sb.append('}');
      sb.append(eol);
      //
      _insertBuilder(sb, statementsRange.length);
      // add proposal
      _addAssist(DartAssistKind.SURROUND_WITH_TRY_FINALLY, []);
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
    doSourceChange_addElementEdit(change, unitElement, edit);
  }

  /**
   * Configures [utils] using given [target].
   */
  void _configureTargetLocation(Object target) {
    utils.targetClassElement = null;
    if (target is AstNode) {
      ClassDeclaration targetClassDeclaration =
          target.getAncestor((node) => node is ClassDeclaration);
      if (targetClassDeclaration != null) {
        utils.targetClassElement = targetClassDeclaration.element;
      }
    }
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
  void _insertBuilder(SourceBuilder builder, [int length = 0]) {
    {
      SourceRange range = rangeStartLength(builder.offset, length);
      String text = builder.toString();
      _addReplaceEdit(range, text);
    }
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

  void _swapFlutterWidgets(
      InstanceCreationExpression exprGoingDown,
      InstanceCreationExpression exprGoingUp,
      NamedExpression stableChild,
      AssistKind assistKind) {
    String currentSource = analysisContext.getContents(source).data;
    // TODO(messick) Find a better way to get LineInfo for the source.
    LineInfo lineInfo = new LineInfo.fromContent(currentSource);
    int currLn = lineInfo.getLocation(exprGoingUp.offset).lineNumber;
    int lnOffset = lineInfo.getOffsetOfLine(currLn);
    SourceBuilder sb = new SourceBuilder(file, exprGoingDown.offset);
    String argSrc =
        utils.getText(exprGoingUp.offset, lnOffset - exprGoingUp.offset);
    sb.append(argSrc); // Append child new-expr plus rest of line.

    String getSrc(Expression expr) {
      int startLn = lineInfo.getLocation(expr.offset).lineNumber;
      int startOffset = lineInfo.getOffsetOfLine(startLn - 1);
      int endLn =
          lineInfo.getLocation(expr.offset + expr.length).lineNumber + 1;
      int curOffset = lineInfo.getOffsetOfLine(endLn - 1);
      return utils.getText(startOffset, curOffset - startOffset);
    }

    String outerIndent = utils.getNodePrefix(exprGoingDown.parent);
    String innerIndent = utils.getNodePrefix(exprGoingUp.parent);
    exprGoingUp.argumentList.arguments.forEach((arg) {
      if (arg is NamedExpression && arg.name.label.name == 'child') {
        if (stableChild != arg) {
          _coverageMarker();
          return;
        }
        // Insert exprGoingDown here.
        // Copy from start of line to offset of exprGoingDown.
        currLn = lineInfo.getLocation(stableChild.offset).lineNumber;
        lnOffset = lineInfo.getOffsetOfLine(currLn - 1);
        argSrc =
            utils.getText(lnOffset, stableChild.expression.offset - lnOffset);
        argSrc = argSrc.replaceAll(
            new RegExp("^$innerIndent", multiLine: true), "$outerIndent");
        sb.append(argSrc);
        int nextLn = lineInfo.getLocation(exprGoingDown.offset).lineNumber;
        lnOffset = lineInfo.getOffsetOfLine(nextLn);
        argSrc = utils.getText(
            exprGoingDown.offset, lnOffset - exprGoingDown.offset);
        sb.append(argSrc);

        exprGoingDown.argumentList.arguments.forEach((val) {
          if (val is NamedExpression && val.name.label.name == 'child') {
            // Insert stableChild here at same indent level.
            sb.append(utils.getNodePrefix(arg.name));
            argSrc = utils.getNodeText(stableChild);
            sb.append(argSrc);
            if (assistKind == DartAssistKind.MOVE_FLUTTER_WIDGET_UP) {
              sb.append(',$eol');
            }
          } else {
            argSrc = getSrc(val);
            argSrc = argSrc.replaceAll(
                new RegExp("^$outerIndent", multiLine: true), "$innerIndent");
            sb.append(argSrc);
          }
        });
        if (assistKind == DartAssistKind.MOVE_FLUTTER_WIDGET_DOWN) {
          sb.append(',$eol');
        }
        sb.append(innerIndent);
        sb.append('),$eol');
      } else {
        argSrc = getSrc(arg);
        argSrc = argSrc.replaceAll(
            new RegExp("^$innerIndent", multiLine: true), "$outerIndent");
        sb.append(argSrc);
      }
    });
    sb.append(outerIndent);
    sb.append(')');

    exitPosition = _newPosition(sb.offset + sb.length);
    _insertBuilder(sb, exprGoingDown.length);
    _addAssist(assistKind, []);
  }

  /**
   * This method does nothing, but we invoke it in places where Dart VM
   * coverage agent fails to provide coverage information - such as almost
   * all "return" statements.
   *
   * https://code.google.com/p/dart/issues/detail?id=19912
   */
  static void _coverageMarker() {}

  /**
   * Returns `true` if the selection covers an operator of the given
   * [BinaryExpression].
   */
  static bool _isOperatorSelected(
      BinaryExpression binaryExpression, int offset, int length) {
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

/**
 * An [AssistContributor] that provides the default set of assists.
 */
class DefaultAssistContributor extends DartAssistContributor {
  @override
  Future<List<Assist>> internalComputeAssists(DartAssistContext context) async {
    try {
      AssistProcessor processor = new AssistProcessor(context);
      return processor.compute();
    } on CancelCorrectionException {
      return Assist.EMPTY_LIST;
    }
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
