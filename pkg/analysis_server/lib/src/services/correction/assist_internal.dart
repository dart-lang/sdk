// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/plugin/edit/assist/assist_dart.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/flutter_util.dart';
import 'package:analysis_server/src/services/correction/name_suggestion.dart';
import 'package:analysis_server/src/services/correction/statement_analyzer.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;
import 'package:analyzer_plugin/utilities/assist/assist.dart'
    hide AssistContributor;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:path/path.dart';

typedef _SimpleIdentifierVisitor(SimpleIdentifier node);

/**
 * The computer for Dart assists.
 */
class AssistProcessor {
  /**
   * The analysis driver being used to perform analysis.
   */
  AnalysisDriver driver;

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

  Position exitPosition = null;

  CorrectionUtils utils;

  AstNode node;

  TypeProvider _typeProvider;

  AssistProcessor(DartAssistContext dartContext) {
    driver = dartContext.analysisDriver;
    // source
    source = dartContext.source;
    file = dartContext.source.fullName;
    fileStamp = _modificationStamp(file);
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

  TypeProvider get typeProvider {
    if (_typeProvider == null) {
      _typeProvider = unitElement.context.typeProvider;
    }
    return _typeProvider;
  }

  Future<List<Assist>> compute() async {
    // If the source was changed between the constructor and running
    // this asynchronous method, it is not safe to use the unit.
    if (_modificationStamp(file) != fileStamp) {
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

    await _addProposal_addTypeAnnotation_DeclaredIdentifier();
    await _addProposal_addTypeAnnotation_SimpleFormalParameter();
    await _addProposal_addTypeAnnotation_VariableDeclaration();
    await _addProposal_assignToLocalVariable();
    await _addProposal_convertIntoFinalField();
    await _addProposal_convertIntoGetter();
    await _addProposal_convertDocumentationIntoBlock();
    await _addProposal_convertDocumentationIntoLine();
    await _addProposal_convertToBlockFunctionBody();
    await _addProposal_convertToExpressionFunctionBody();
    await _addProposal_convertFlutterChild();
    await _addProposal_convertToForIndexLoop();
    await _addProposal_convertToIsNot_onIs();
    await _addProposal_convertToIsNot_onNot();
    await _addProposal_convertToIsNotEmpty();
    await _addProposal_convertToFieldParameter();
    await _addProposal_convertToNormalParameter();
    await _addProposal_encapsulateField();
    await _addProposal_exchangeOperands();
    await _addProposal_importAddShow();
    await _addProposal_introduceLocalTestedType();
    await _addProposal_invertIf();
    await _addProposal_joinIfStatementInner();
    await _addProposal_joinIfStatementOuter();
    await _addProposal_joinVariableDeclaration_onAssignment();
    await _addProposal_joinVariableDeclaration_onDeclaration();
    await _addProposal_moveFlutterWidgetDown();
    await _addProposal_moveFlutterWidgetUp();
    await _addProposal_removeTypeAnnotation();
    await _addProposal_reparentFlutterList();
    await _addProposal_reparentFlutterWidget();
    await _addProposal_replaceConditionalWithIfElse();
    await _addProposal_replaceIfElseWithConditional();
    await _addProposal_splitAndCondition();
    await _addProposal_splitVariableDeclaration();
    await _addProposal_surroundWith();

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

  void _addAssistFromBuilder(DartChangeBuilder builder, AssistKind kind,
      {List args: null}) {
    SourceChange change = builder.sourceChange;
    if (change.edits.isEmpty) {
      _coverageMarker();
      return;
    }
    change.message = formatList(kind.message, args);
    assists.add(new Assist(kind, change));
  }

  Future<Null> _addProposal_addTypeAnnotation_DeclaredIdentifier() async {
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
    // Ensure that there isn't already a type annotation.
    if (declaredIdentifier.type != null) {
      _coverageMarker();
      return;
    }
    DartType type = declaredIdentifier.identifier.bestType;
    if (type is! InterfaceType && type is! FunctionType) {
      _coverageMarker();
      return;
    }
    _configureTargetLocation(node);
    Set<Source> librariesToImport = new Set<Source>();
    String typeSource = utils.getTypeSource(type, librariesToImport);
    if (typeSource == null) {
      // The type source might be null if the type is private.
      _coverageMarker();
      return;
    }

    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      Token keyword = declaredIdentifier.keyword;
      if (keyword.keyword == Keyword.VAR) {
        builder.addSimpleReplacement(range.token(keyword), typeSource);
      } else {
        builder.addSimpleInsertion(
            declaredIdentifier.identifier.offset, '$typeSource ');
      }
      builder.importLibraries(librariesToImport);
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.ADD_TYPE_ANNOTATION);
  }

  Future<Null> _addProposal_addTypeAnnotation_SimpleFormalParameter() async {
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
    // prepare the type
    DartType type = parameter.element.type;
    // TODO(scheglov) If the parameter is in a method declaration, and if the
    // method overrides a method that has a type for the corresponding
    // parameter, it would be nice to copy down the type from the overridden
    // method.
    if (type is! InterfaceType) {
      _coverageMarker();
      return;
    }
    // prepare type source
    _configureTargetLocation(node);
    Set<Source> librariesToImport = new Set<Source>();
    String typeSource = utils.getTypeSource(type, librariesToImport);
    // type source might be null, if the type is private
    if (typeSource == null) {
      _coverageMarker();
      return;
    }

    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      builder.addSimpleInsertion(name.offset, '$typeSource ');
      builder.importLibraries(librariesToImport);
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.ADD_TYPE_ANNOTATION);
  }

  Future<Null> _addProposal_addTypeAnnotation_VariableDeclaration() async {
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
    if ((type is! InterfaceType || type.isDartCoreNull) &&
        type is! FunctionType) {
      _coverageMarker();
      return;
    }
    _configureTargetLocation(node);
    Set<Source> librariesToImport = new Set<Source>();
    String typeSource = utils.getTypeSource(type, librariesToImport);
    // type source might be null, if the type is private
    if (typeSource == null) {
      _coverageMarker();
      return;
    }

    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    if (unitLibraryFile == file) {
      // TODO(brianwilkerson) Make ChangeBuilder merge multiple edits to the
      // same file so that only the else block is necessary.
      await changeBuilder.addFileEdit(file, fileStamp,
          (DartFileEditBuilder builder) {
        Token keyword = declarationList.keyword;
        if (keyword?.keyword == Keyword.VAR) {
          builder.addSimpleReplacement(range.token(keyword), typeSource);
        } else {
          builder.addSimpleInsertion(variable.offset, '$typeSource ');
        }
        builder.importLibraries(librariesToImport);
      });
    } else {
      await changeBuilder.addFileEdit(file, fileStamp,
          (DartFileEditBuilder builder) {
        Token keyword = declarationList.keyword;
        if (keyword?.keyword == Keyword.VAR) {
          builder.addSimpleReplacement(range.token(keyword), typeSource);
        } else {
          builder.addSimpleInsertion(variable.offset, '$typeSource ');
        }
      });
      await changeBuilder
          .addFileEdit(unitLibraryFile, _modificationStamp(unitLibraryFile),
              (DartFileEditBuilder builder) {
        builder.importLibraries(librariesToImport);
      });
    }
    _addAssistFromBuilder(changeBuilder, DartAssistKind.ADD_TYPE_ANNOTATION);
  }

  Future<Null> _addProposal_assignToLocalVariable() async {
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
    // prepare excluded names
    Set<String> excluded = new Set<String>();
    ScopedNameFinder scopedNameFinder = new ScopedNameFinder(offset);
    expression.accept(scopedNameFinder);
    excluded.addAll(scopedNameFinder.locals.keys.toSet());
    List<String> suggestions =
        getVariableNameSuggestionsForExpression(type, expression, excluded);

    if (suggestions.isNotEmpty) {
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, fileStamp,
          (DartFileEditBuilder builder) {
        builder.addInsertion(offset, (DartEditBuilder builder) {
          builder.write('var ');
          builder.addSimpleLinkedEdit('NAME', suggestions[0],
              kind: LinkedEditSuggestionKind.VARIABLE,
              suggestions: suggestions);
          builder.write(' = ');
        });
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.ASSIGN_TO_LOCAL_VARIABLE);
    }
  }

  Future<Null> _addProposal_convertDocumentationIntoBlock() async {
    Comment comment = node.getAncestor((n) => n is Comment);
    if (comment == null || !comment.isDocumentation) {
      return;
    }
    var tokens = comment.tokens;
    if (tokens.isEmpty ||
        tokens.any((Token token) =>
            token is! DocumentationCommentToken ||
            token.type != TokenType.SINGLE_LINE_COMMENT)) {
      return;
    }
    String prefix = utils.getNodePrefix(comment);

    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(comment), (DartEditBuilder builder) {
        builder.writeln('/**');
        for (Token token in comment.tokens) {
          builder.write(prefix);
          builder.write(' *');
          builder.writeln(token.lexeme.substring('///'.length));
        }
        builder.write(prefix);
        builder.write(' */');
      });
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.CONVERT_DOCUMENTATION_INTO_BLOCK);
  }

  Future<Null> _addProposal_convertDocumentationIntoLine() async {
    Comment comment = node.getAncestor((n) => n is Comment);
    if (comment == null ||
        !comment.isDocumentation ||
        comment.tokens.length != 1) {
      _coverageMarker();
      return;
    }
    Token token = comment.tokens.first;
    if (token.type != TokenType.MULTI_LINE_COMMENT) {
      _coverageMarker();
      return;
    }
    String text = token.lexeme;
    List<String> lines = text.split('\n');
    String prefix = utils.getNodePrefix(comment);
    List<String> newLines = <String>[];
    bool firstLine = true;
    String linePrefix = '';
    for (String line in lines) {
      if (firstLine) {
        firstLine = false;
        String expectedPrefix = '/**';
        if (!line.startsWith(expectedPrefix)) {
          _coverageMarker();
          return;
        }
        line = line.substring(expectedPrefix.length).trim();
        if (line.isNotEmpty) {
          newLines.add('/// $line');
          linePrefix = eol + prefix;
        }
      } else {
        if (line.startsWith(prefix + ' */')) {
          break;
        }
        String expectedPrefix = prefix + ' * ';
        if (!line.startsWith(expectedPrefix)) {
          _coverageMarker();
          return;
        }
        line = line.substring(expectedPrefix.length).trim();
        newLines.add('$linePrefix/// $line');
        linePrefix = eol + prefix;
      }
    }

    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(comment), (DartEditBuilder builder) {
        for (String newLine in newLines) {
          builder.write(newLine);
        }
      });
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.CONVERT_DOCUMENTATION_INTO_LINE);
  }

  Future<Null> _addProposal_convertFlutterChild() async {
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
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      _convertFlutterChildToChildren(childArg, namedExp, eol, utils.getNodeText,
          utils.getLinePrefix, utils.getIndent, utils.getText, builder);
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.CONVERT_FLUTTER_CHILD);
  }

  Future<Null> _addProposal_convertIntoFinalField() async {
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
      SourceRange replacementRange = range.startEnd(beginNodeToReplace, getter);
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, fileStamp,
          (DartFileEditBuilder builder) {
        builder.addSimpleReplacement(replacementRange, code);
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.CONVERT_INTO_FINAL_FIELD);
    }
  }

  Future<Null> _addProposal_convertIntoGetter() async {
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
    SourceRange replacementRange =
        range.startEnd(fieldList.keyword, fieldDeclaration);
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(replacementRange, code);
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.CONVERT_INTO_GETTER);
  }

  Future<Null> _addProposal_convertToBlockFunctionBody() async {
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

    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(body), (DartEditBuilder builder) {
        if (body.isAsynchronous) {
          builder.write('async ');
        }
        builder.write('{$eol$prefix$indent');
        if (!returnValueType.isVoid) {
          builder.write('return ');
        }
        builder.write(returnValueCode);
        builder.write(';');
        builder.selectHere();
        builder.write('$eol$prefix}');
      });
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.CONVERT_INTO_BLOCK_BODY);
  }

  Future<Null> _addProposal_convertToExpressionFunctionBody() async {
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

    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(body), (DartEditBuilder builder) {
        if (body.isAsynchronous) {
          builder.write('async ');
        }
        builder.write('=> ');
        builder.write(_getNodeText(returnExpression));
        if (body.parent is! FunctionExpression ||
            body.parent.parent is FunctionDeclaration) {
          builder.write(';');
        }
      });
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.CONVERT_INTO_EXPRESSION_BODY);
  }

  Future<Null> _addProposal_convertToFieldParameter() async {
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

      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, fileStamp,
          (DartFileEditBuilder builder) {
        // replace parameter
        builder.addSimpleReplacement(range.node(parameter), 'this.$fieldName');
        // remove initializer
        int initializerIndex = initializers.indexOf(parameterInitializer);
        if (initializers.length == 1) {
          builder
              .addDeletion(range.endEnd(parameterList, parameterInitializer));
        } else {
          if (initializerIndex == 0) {
            ConstructorInitializer next = initializers[initializerIndex + 1];
            builder.addDeletion(range.startStart(parameterInitializer, next));
          } else {
            ConstructorInitializer prev = initializers[initializerIndex - 1];
            builder.addDeletion(range.endEnd(prev, parameterInitializer));
          }
        }
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.CONVERT_TO_FIELD_PARAMETER);
    }
  }

  Future<Null> _addProposal_convertToForIndexLoop() async {
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
      InterfaceType listType = typeProvider.listType;
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
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      // TODO(brianwilkerson) Create linked positions for the loop variable.
      builder.addSimpleReplacement(
          range.startEnd(forEachStatement, forEachStatement.rightParenthesis),
          'for (int $indexName = 0; $indexName < $listName.length; $indexName++)');
      builder.addSimpleInsertion(firstBlockLine,
          '$prefix$indent$loopVariable = $listName[$indexName];$eol');
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.CONVERT_INTO_FOR_INDEX);
  }

  Future<Null> _addProposal_convertToIsNot_onIs() async {
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

    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      if (getExpressionParentPrecedence(prefExpression) >=
          TokenClass.RELATIONAL_OPERATOR.precedence) {
        builder.addDeletion(range.token(prefExpression.operator));
      } else {
        builder.addDeletion(
            range.startEnd(prefExpression, parExpression.leftParenthesis));
        builder.addDeletion(
            range.startEnd(parExpression.rightParenthesis, prefExpression));
      }
      builder.addSimpleInsertion(isExpression.isOperator.end, '!');
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.CONVERT_INTO_IS_NOT);
  }

  Future<Null> _addProposal_convertToIsNot_onNot() async {
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

    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      if (getExpressionParentPrecedence(prefExpression) >=
          TokenClass.RELATIONAL_OPERATOR.precedence) {
        builder.addDeletion(range.token(prefExpression.operator));
      } else {
        builder.addDeletion(
            range.startEnd(prefExpression, parExpression.leftParenthesis));
        builder.addDeletion(
            range.startEnd(parExpression.rightParenthesis, prefExpression));
      }
      builder.addSimpleInsertion(isExpression.isOperator.end, '!');
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.CONVERT_INTO_IS_NOT);
  }

  /**
   * Converts "!isEmpty" -> "isNotEmpty" if possible.
   */
  Future<Null> _addProposal_convertToIsNotEmpty() async {
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

    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      builder.addDeletion(
          range.startStart(prefixExpression, prefixExpression.operand));
      builder.addSimpleReplacement(range.node(isEmptyIdentifier), 'isNotEmpty');
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.CONVERT_INTO_IS_NOT_EMPTY);
  }

  Future<Null> _addProposal_convertToNormalParameter() async {
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

      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, fileStamp,
          (DartFileEditBuilder builder) {
        // replace parameter
        if (type.isDynamic) {
          builder.addSimpleReplacement(range.node(parameter), name);
        } else {
          builder.addSimpleReplacement(
              range.node(parameter), '$typeCode $name');
        }
        // add field initializer
        List<ConstructorInitializer> initializers = constructor.initializers;
        if (initializers.isEmpty) {
          builder.addSimpleInsertion(parameterList.end, ' : $name = $name');
        } else {
          builder.addSimpleInsertion(initializers.last.end, ', $name = $name');
        }
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.CONVERT_TO_NORMAL_PARAMETER);
    }
  }

  Future<Null> _addProposal_encapsulateField() async {
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
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      // rename field
      builder.addSimpleReplacement(range.node(nameNode), '_$name');
      // update references in constructors
      ClassDeclaration classDeclaration = fieldDeclaration.parent;
      for (ClassMember member in classDeclaration.members) {
        if (member is ConstructorDeclaration) {
          for (FormalParameter parameter in member.parameters.parameters) {
            ParameterElement parameterElement = parameter.element;
            if (parameterElement is FieldFormalParameterElement &&
                parameterElement.field == fieldElement) {
              SimpleIdentifier identifier = parameter.identifier;
              builder.addSimpleReplacement(range.node(identifier), '_$name');
            }
          }
        }
      }
      // add accessors
      String eol2 = eol + eol;
      String typeNameCode = variableList.type != null
          ? _getNodeText(variableList.type) + ' '
          : '';
      String getterCode = '$eol2  ${typeNameCode}get $name => _$name;';
      String setterCode = '$eol2'
          '  void set $name($typeNameCode$name) {$eol'
          '    _$name = $name;$eol'
          '  }';
      builder.addSimpleInsertion(fieldDeclaration.end, getterCode + setterCode);
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.ENCAPSULATE_FIELD);
  }

  Future<Null> _addProposal_exchangeOperands() async {
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
    Expression leftOperand = binaryExpression.leftOperand;
    Expression rightOperand = binaryExpression.rightOperand;
    // find "wide" enclosing binary expression with same operator
    while (binaryExpression.parent is BinaryExpression) {
      BinaryExpression newBinaryExpression =
          binaryExpression.parent as BinaryExpression;
      if (newBinaryExpression.operator.type != binaryExpression.operator.type) {
        _coverageMarker();
        break;
      }
      binaryExpression = newBinaryExpression;
    }
    // exchange parts of "wide" expression parts
    SourceRange leftRange = range.startEnd(binaryExpression, leftOperand);
    SourceRange rightRange = range.startEnd(rightOperand, binaryExpression);
    // maybe replace the operator
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
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(leftRange, _getRangeText(rightRange));
      builder.addSimpleReplacement(rightRange, _getRangeText(leftRange));
      // Optionally replace the operator.
      if (newOperator != null) {
        builder.addSimpleReplacement(range.token(operator), newOperator);
      }
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.EXCHANGE_OPERANDS);
  }

  Future<Null> _addProposal_importAddShow() async {
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
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      String showCombinator = ' show ${referencedNames.join(', ')}';
      builder.addSimpleInsertion(importDirective.end - 1, showCombinator);
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.IMPORT_ADD_SHOW);
  }

  Future<Null> _addProposal_introduceLocalTestedType() async {
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
    // prepare excluded names
    Set<String> excluded = new Set<String>();
    ScopedNameFinder scopedNameFinder = new ScopedNameFinder(offset);
    isExpression.accept(scopedNameFinder);
    excluded.addAll(scopedNameFinder.locals.keys.toSet());
    // name(s)
    List<String> suggestions =
        getVariableNameSuggestionsForExpression(castType, null, excluded);

    if (suggestions.isNotEmpty) {
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, fileStamp,
          (DartFileEditBuilder builder) {
        builder.addInsertion(offset, (DartEditBuilder builder) {
          builder.write(eol + prefix + statementPrefix);
          builder.write(castTypeCode);
          builder.write(' ');
          builder.addSimpleLinkedEdit('NAME', suggestions[0],
              kind: LinkedEditSuggestionKind.VARIABLE,
              suggestions: suggestions);
          builder.write(' = ');
          builder.write(_getNodeText(isExpression.expression));
          builder.write(';');
          builder.selectHere();
        });
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.INTRODUCE_LOCAL_CAST_TYPE);
    }
  }

  Future<Null> _addProposal_invertIf() async {
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

    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(range.node(condition), invertedCondition);
      builder.addSimpleReplacement(range.node(thenStatement), elseSource);
      builder.addSimpleReplacement(range.node(elseStatement), thenSource);
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.INVERT_IF_STATEMENT);
  }

  Future<Null> _addProposal_joinIfStatementInner() async {
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
    Statement innerThenStatement = innerIfStatement.thenStatement;
    List<Statement> innerThenStatements = getStatements(innerThenStatement);
    SourceRange lineRanges = utils.getLinesRangeStatements(innerThenStatements);
    String oldSource = utils.getRangeText(lineRanges);
    String newSource = utils.indentSourceLeftRight(oldSource, false);

    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(range.node(targetIfStatement),
          'if ($condition) {$eol$newSource$prefix}');
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.JOIN_IF_WITH_INNER);
  }

  Future<Null> _addProposal_joinIfStatementOuter() async {
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
    String condition = '$outerConditionSource && $targetConditionSource';
    // replace outer "if" statement
    Statement targetThenStatement = targetIfStatement.thenStatement;
    List<Statement> targetThenStatements = getStatements(targetThenStatement);
    SourceRange lineRanges =
        utils.getLinesRangeStatements(targetThenStatements);
    String oldSource = utils.getRangeText(lineRanges);
    String newSource = utils.indentSourceLeftRight(oldSource, false);

    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(range.node(outerIfStatement),
          'if ($condition) {$eol$newSource$prefix}');
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.JOIN_IF_WITH_OUTER);
  }

  Future<Null> _addProposal_joinVariableDeclaration_onAssignment() async {
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

    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(
          range.endStart(declNode, assignExpression.operator), ' ');
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.JOIN_VARIABLE_DECLARATION);
  }

  Future<Null> _addProposal_joinVariableDeclaration_onDeclaration() async {
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

    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(
          range.endStart(decl.name, assignExpression.operator), ' ');
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.JOIN_VARIABLE_DECLARATION);
  }

  Future<Null> _addProposal_moveFlutterWidgetDown() async {
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
    await _swapFlutterWidgets(exprGoingDown, exprGoingUp, stableChild,
        DartAssistKind.MOVE_FLUTTER_WIDGET_DOWN);
  }

  Future<Null> _addProposal_moveFlutterWidgetUp() async {
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
    await _swapFlutterWidgets(exprGoingDown, exprGoingUp, stableChild,
        DartAssistKind.MOVE_FLUTTER_WIDGET_UP);
  }

  Future<Null> _addProposal_removeTypeAnnotation() async {
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
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      SourceRange typeRange = range.startStart(typeNode, firstVariable);
      if (keyword != null && keyword.lexeme != 'var') {
        builder.addSimpleReplacement(typeRange, '');
      } else {
        builder.addSimpleReplacement(typeRange, 'var ');
      }
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.REMOVE_TYPE_ANNOTATION);
  }

  Future<Null> _addProposal_reparentFlutterList() async {
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
    int newlineIdx = literalSrc.lastIndexOf(eol);
    if (newlineIdx < 0 || newlineIdx == literalSrc.length - 1) {
      _coverageMarker();
      return; // Lists need to be in multi-line format already.
    }
    String indentOld = utils.getLinePrefix(node.offset + 1 + newlineIdx);
    String indentArg = '$indentOld${utils.getIndent(1)}';
    String indentList = '$indentOld${utils.getIndent(2)}';

    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(node), (DartEditBuilder builder) {
        builder.write('[');
        builder.write(eol);
        builder.write(indentArg);
        builder.write('new ');
        builder.addSimpleLinkedEdit('WIDGET', 'widget');
        builder.write('(');
        builder.write(eol);
        builder.write(indentList);
        // Linked editing not needed since arg is always a list.
        builder.write('children: ');
        builder.write(literalSrc.replaceAll(
            new RegExp("^$indentOld", multiLine: true), "$indentList"));
        builder.write(',');
        builder.write(eol);
        builder.write(indentArg);
        builder.write('),');
        builder.write(eol);
        builder.write(indentOld);
        builder.write(']');
        builder.selectHere();
      });
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.REPARENT_FLUTTER_LIST);
  }

  Future<Null> _addProposal_reparentFlutterWidget() async {
    InstanceCreationExpression newExpr = identifyNewExpression(node);
    if (newExpr == null || !isFlutterInstanceCreationExpression(newExpr)) {
      _coverageMarker();
      return;
    }
    String newExprSrc = utils.getNodeText(newExpr);

    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(newExpr), (DartEditBuilder builder) {
        builder.write('new ');
        builder.addSimpleLinkedEdit('WIDGET', 'widget');
        builder.write('(');
        if (newExprSrc.contains(eol)) {
          int newlineIdx = newExprSrc.lastIndexOf(eol);
          int eolLen = eol.length;
          if (newlineIdx == newExprSrc.length - eolLen) {
            newlineIdx -= eolLen;
          }
          String indentOld =
              utils.getLinePrefix(newExpr.offset + eolLen + newlineIdx);
          String indentNew = '$indentOld${utils.getIndent(1)}';
          builder.write(eol);
          builder.write(indentNew);
          newExprSrc = newExprSrc.replaceAll(
              new RegExp("^$indentOld", multiLine: true), indentNew);
          newExprSrc += ",$eol$indentOld";
        }
        builder.addSimpleLinkedEdit('CHILD', 'child');
        builder.write(': ');
        builder.write(newExprSrc);
        builder.write(')');
        builder.selectHere();
      });
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.REPARENT_FLUTTER_WIDGET);
  }

  Future<Null> _addProposal_replaceConditionalWithIfElse() async {
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

    if (inVariable || inAssignment || inReturn) {
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, fileStamp,
          (DartFileEditBuilder builder) {
        // Type v = Conditional;
        if (inVariable) {
          VariableDeclaration variable =
              conditional.parent as VariableDeclaration;
          builder.addDeletion(range.endEnd(variable.name, conditional));
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
          builder.addSimpleReplacement(range.endLength(statement, 0), src);
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
          builder.addSimpleReplacement(range.node(statement), src);
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
          builder.addSimpleReplacement(range.node(statement), src);
        }
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.REPLACE_CONDITIONAL_WITH_IF_ELSE);
    }
  }

  Future<Null> _addProposal_replaceIfElseWithConditional() async {
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
    Expression thenExpression = null;
    Expression elseExpression = null;
    bool hasReturnStatements = false;
    if (thenStatement is ReturnStatement && elseStatement is ReturnStatement) {
      hasReturnStatements = true;
      thenExpression = thenStatement.expression;
      elseExpression = elseStatement.expression;
    }
    bool hasExpressionStatements = false;
    if (thenStatement is ExpressionStatement &&
        elseStatement is ExpressionStatement) {
      if (thenStatement.expression is AssignmentExpression &&
          elseStatement.expression is AssignmentExpression) {
        hasExpressionStatements = true;
        thenExpression = thenStatement.expression;
        elseExpression = elseStatement.expression;
      }
    }

    if (hasReturnStatements || hasExpressionStatements) {
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, fileStamp,
          (DartFileEditBuilder builder) {
        // returns
        if (hasReturnStatements) {
          String conditionSrc = _getNodeText(ifStatement.condition);
          String theSrc = _getNodeText(thenExpression);
          String elseSrc = _getNodeText(elseExpression);
          builder.addSimpleReplacement(range.node(ifStatement),
              'return $conditionSrc ? $theSrc : $elseSrc;');
        }
        // assignments -> v = Conditional;
        if (hasExpressionStatements) {
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
            builder.addSimpleReplacement(range.node(ifStatement),
                '$thenTarget = $conditionSrc ? $theSrc : $elseSrc;');
          }
        }
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.REPLACE_IF_ELSE_WITH_CONDITIONAL);
    }
  }

  Future<Null> _addProposal_splitAndCondition() async {
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
          range.startEnd(binaryExpression.rightOperand, condition);
      rightConditionSource = _getRangeText(rightConditionRange);
    }

    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      // remove "&& rightCondition"
      builder
          .addDeletion(range.endEnd(binaryExpression.leftOperand, condition));
      // update "then" statement
      Statement thenStatement = ifStatement.thenStatement;
      if (thenStatement is Block) {
        Block thenBlock = thenStatement;
        SourceRange thenBlockRange = range.node(thenBlock);
        // insert inner "if" with right part of "condition"
        int thenBlockInsideOffset = thenBlockRange.offset + 1;
        builder.addSimpleInsertion(thenBlockInsideOffset,
            '$eol$prefix${indent}if ($rightConditionSource) {');
        // insert closing "}" for inner "if"
        int thenBlockEnd = thenBlockRange.end;
        // insert before outer "then" block "}"
        builder.addSimpleInsertion(thenBlockEnd - 1, '$indent}$eol$prefix');
      } else {
        // insert inner "if" with right part of "condition"
        String source = '$eol$prefix${indent}if ($rightConditionSource)';
        builder.addSimpleInsertion(
            ifStatement.rightParenthesis.offset + 1, source);
      }
      // indent "then" statements to correspond inner "if"
      {
        List<Statement> thenStatements = getStatements(thenStatement);
        SourceRange linesRange = utils.getLinesRangeStatements(thenStatements);
        String thenIndentOld = '$prefix$indent';
        String thenIndentNew = '$thenIndentOld$indent';
        builder.addSimpleReplacement(
            linesRange,
            utils.replaceSourceRangeIndent(
                linesRange, thenIndentOld, thenIndentNew));
      }
    });
    _addAssistFromBuilder(changeBuilder, DartAssistKind.SPLIT_AND_CONDITION);
  }

  Future<Null> _addProposal_splitVariableDeclaration() async {
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
    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      // remove initializer value
      builder.addDeletion(range.endStart(variable.name, statement.semicolon));
      // add assignment statement
      String indent = utils.getNodePrefix(statement);
      String name = variable.name.name;
      String initSrc = _getNodeText(initializer);
      SourceRange assignRange = range.endLength(statement, 0);
      builder.addSimpleReplacement(
          assignRange, eol + indent + name + ' = ' + initSrc + ';');
    });
    _addAssistFromBuilder(
        changeBuilder, DartAssistKind.SPLIT_VARIABLE_DECLARATION);
  }

  Future<Null> _addProposal_surroundWith() async {
    // prepare selected statements
    List<Statement> selectedStatements;
    {
      StatementAnalyzer selectionAnalyzer = new StatementAnalyzer(
          unit, new SourceRange(selectionOffset, selectionLength));
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
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, fileStamp,
          (DartFileEditBuilder builder) {
        builder.addSimpleInsertion(statementsRange.offset, '$indentOld{$eol');
        builder.addSimpleReplacement(
            statementsRange,
            utils.replaceSourceRangeIndent(
                statementsRange, indentOld, indentNew));
        builder.addSimpleInsertion(statementsRange.end, '$indentOld}$eol');
        exitPosition = _newPosition(lastStatement.end);
      });
      _addAssistFromBuilder(changeBuilder, DartAssistKind.SURROUND_WITH_BLOCK);
    }
    // "if"
    {
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, fileStamp,
          (DartFileEditBuilder builder) {
        builder.addReplacement(statementsRange, (DartEditBuilder builder) {
          builder.write(indentOld);
          builder.write('if (');
          builder.addSimpleLinkedEdit('CONDITION', 'condition');
          builder.write(') {');
          builder.write(eol);
          builder.write(indentedCode);
          builder.write(indentOld);
          builder.write('}');
          builder.selectHere();
          builder.write(eol);
        });
      });
      _addAssistFromBuilder(changeBuilder, DartAssistKind.SURROUND_WITH_IF);
    }
    // "while"
    {
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, fileStamp,
          (DartFileEditBuilder builder) {
        builder.addReplacement(statementsRange, (DartEditBuilder builder) {
          builder.write(indentOld);
          builder.write('while (');
          builder.addSimpleLinkedEdit('CONDITION', 'condition');
          builder.write(') {');
          builder.write(eol);
          builder.write(indentedCode);
          builder.write(indentOld);
          builder.write('}');
          builder.selectHere();
          builder.write(eol);
        });
      });
      _addAssistFromBuilder(changeBuilder, DartAssistKind.SURROUND_WITH_WHILE);
    }
    // "for-in"
    {
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, fileStamp,
          (DartFileEditBuilder builder) {
        builder.addReplacement(statementsRange, (DartEditBuilder builder) {
          builder.write(indentOld);
          builder.write('for (var ');
          builder.addSimpleLinkedEdit('NAME', 'item');
          builder.write(' in ');
          builder.addSimpleLinkedEdit('ITERABLE', 'iterable');
          builder.write(') {');
          builder.write(eol);
          builder.write(indentedCode);
          builder.write(indentOld);
          builder.write('}');
          builder.selectHere();
          builder.write(eol);
        });
      });
      _addAssistFromBuilder(changeBuilder, DartAssistKind.SURROUND_WITH_FOR_IN);
    }
    // "for"
    {
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, fileStamp,
          (DartFileEditBuilder builder) {
        builder.addReplacement(statementsRange, (DartEditBuilder builder) {
          builder.write(indentOld);
          builder.write('for (var ');
          builder.addSimpleLinkedEdit('VAR', 'v');
          builder.write(' = ');
          builder.addSimpleLinkedEdit('INIT', 'init');
          builder.write('; ');
          builder.addSimpleLinkedEdit('CONDITION', 'condition');
          builder.write('; ');
          builder.addSimpleLinkedEdit('INCREMENT', 'increment');
          builder.write(') {');
          builder.write(eol);
          builder.write(indentedCode);
          builder.write(indentOld);
          builder.write('}');
          builder.selectHere();
          builder.write(eol);
        });
      });
      _addAssistFromBuilder(changeBuilder, DartAssistKind.SURROUND_WITH_FOR);
    }
    // "do-while"
    {
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, fileStamp,
          (DartFileEditBuilder builder) {
        builder.addReplacement(statementsRange, (DartEditBuilder builder) {
          builder.write(indentOld);
          builder.write('do {');
          builder.write(eol);
          builder.write(indentedCode);
          builder.write(indentOld);
          builder.write('} while (');
          builder.addSimpleLinkedEdit('CONDITION', 'condition');
          builder.write(');');
          builder.selectHere();
          builder.write(eol);
        });
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.SURROUND_WITH_DO_WHILE);
    }
    // "try-catch"
    {
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, fileStamp,
          (DartFileEditBuilder builder) {
        builder.addReplacement(statementsRange, (DartEditBuilder builder) {
          builder.write(indentOld);
          builder.write('try {');
          builder.write(eol);
          builder.write(indentedCode);
          builder.write(indentOld);
          builder.write('} on ');
          builder.addSimpleLinkedEdit('EXCEPTION_TYPE', 'Exception');
          builder.write(' catch (');
          builder.addSimpleLinkedEdit('EXCEPTION_VAR', 'e');
          builder.write(') {');
          builder.write(eol);
          //
          builder.write(indentNew);
          builder.addSimpleLinkedEdit('CATCH', '// TODO');
          builder.selectHere();
          builder.write(eol);
          //
          builder.write(indentOld);
          builder.write('}');
          builder.write(eol);
        });
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.SURROUND_WITH_TRY_CATCH);
    }
    // "try-finally"
    {
      DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
      await changeBuilder.addFileEdit(file, fileStamp,
          (DartFileEditBuilder builder) {
        builder.addReplacement(statementsRange, (DartEditBuilder builder) {
          builder.write(indentOld);
          builder.write('try {');
          builder.write(eol);
          //
          builder.write(indentedCode);
          //
          builder.write(indentOld);
          builder.write('} finally {');
          builder.write(eol);
          //
          builder.write(indentNew);
          builder.addSimpleLinkedEdit('FINALLY', '// TODO');
          builder.selectHere();
          builder.write(eol);
          //
          builder.write(indentOld);
          builder.write('}');
          builder.write(eol);
        });
      });
      _addAssistFromBuilder(
          changeBuilder, DartAssistKind.SURROUND_WITH_TRY_FINALLY);
    }
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

  void _convertFlutterChildToChildren(
      InstanceCreationExpression childArg,
      NamedExpression namedExp,
      String eol,
      Function getNodeText,
      Function getLinePrefix,
      Function getIndent,
      Function getText,
      DartFileEditBuilder builder) {
    int childLoc = namedExp.offset + 'child'.length;
    builder.addSimpleInsertion(childLoc, 'ren');
    int listLoc = childArg.offset;
    String childArgSrc = getNodeText(childArg);
    if (!childArgSrc.contains(eol)) {
      builder.addSimpleInsertion(listLoc, '<Widget>[');
      builder.addSimpleInsertion(listLoc + childArg.length, ']');
    } else {
      int newlineLoc = childArgSrc.lastIndexOf(eol);
      if (newlineLoc == childArgSrc.length) {
        newlineLoc -= 1;
      }
      String indentOld = getLinePrefix(childArg.offset + 1 + newlineLoc);
      String indentNew = '$indentOld${getIndent(1)}';
      // The separator includes 'child:' but that has no newlines.
      String separator =
          getText(namedExp.offset, childArg.offset - namedExp.offset);
      String prefix = separator.contains(eol) ? "" : "$eol$indentNew";
      if (prefix.isEmpty) {
        builder.addSimpleInsertion(
            namedExp.offset + 'child:'.length, ' <Widget>[');
        int argOffset = childArg.offset;
        builder
            .addDeletion(range.startOffsetEndOffset(argOffset - 2, argOffset));
      } else {
        builder.addSimpleInsertion(listLoc, '<Widget>[');
      }
      String newChildArgSrc = childArgSrc.replaceAll(
          new RegExp("^$indentOld", multiLine: true), "$indentNew");
      newChildArgSrc = "$prefix$newChildArgSrc,$eol$indentOld]";
      builder.addSimpleReplacement(range.node(childArg), newChildArgSrc);
    }
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

  int _modificationStamp(String filePath) {
    // TODO(brianwilkerson) We have lost the ability for clients to know whether
    // it is safe to apply an edit.
    return driver.fsState.getFileForPath(filePath).exists ? 0 : -1;
  }

  Position _newPosition(int offset) {
    return new Position(file, offset);
  }

  Future<Null> _swapFlutterWidgets(
      InstanceCreationExpression exprGoingDown,
      InstanceCreationExpression exprGoingUp,
      NamedExpression stableChild,
      AssistKind assistKind) async {
    String currentSource = unitElement.context.getContents(source).data;
    // TODO(messick) Find a better way to get LineInfo for the source.
    LineInfo lineInfo = new LineInfo.fromContent(currentSource);
    int currLn = lineInfo.getLocation(exprGoingUp.offset).lineNumber;
    int lnOffset = lineInfo.getOffsetOfLine(currLn);

    DartChangeBuilder changeBuilder = new DartChangeBuilder(driver);
    await changeBuilder.addFileEdit(file, fileStamp,
        (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(exprGoingDown),
          (DartEditBuilder builder) {
        String argSrc =
            utils.getText(exprGoingUp.offset, lnOffset - exprGoingUp.offset);
        builder.write(argSrc); // Append child new-expr plus rest of line.

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
            argSrc = utils.getText(
                lnOffset, stableChild.expression.offset - lnOffset);
            argSrc = argSrc.replaceAll(
                new RegExp("^$innerIndent", multiLine: true), "$outerIndent");
            builder.write(argSrc);
            int nextLn = lineInfo.getLocation(exprGoingDown.offset).lineNumber;
            lnOffset = lineInfo.getOffsetOfLine(nextLn);
            argSrc = utils.getText(
                exprGoingDown.offset, lnOffset - exprGoingDown.offset);
            builder.write(argSrc);

            exprGoingDown.argumentList.arguments.forEach((val) {
              if (val is NamedExpression && val.name.label.name == 'child') {
                // Insert stableChild here at same indent level.
                builder.write(utils.getNodePrefix(arg.name));
                argSrc = utils.getNodeText(stableChild);
                builder.write(argSrc);
                if (assistKind == DartAssistKind.MOVE_FLUTTER_WIDGET_UP) {
                  builder.write(',$eol');
                }
              } else {
                argSrc = getSrc(val);
                argSrc = argSrc.replaceAll(
                    new RegExp("^$outerIndent", multiLine: true),
                    "$innerIndent");
                builder.write(argSrc);
              }
            });
            if (assistKind == DartAssistKind.MOVE_FLUTTER_WIDGET_DOWN) {
              builder.write(',$eol');
            }
            builder.write(innerIndent);
            builder.write('),$eol');
          } else {
            argSrc = getSrc(arg);
            argSrc = argSrc.replaceAll(
                new RegExp("^$innerIndent", multiLine: true), "$outerIndent");
            builder.write(argSrc);
          }
        });
        builder.write(outerIndent);
        builder.write(')');
        builder.selectHere();
      });
    });
    _addAssistFromBuilder(changeBuilder, assistKind);
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
