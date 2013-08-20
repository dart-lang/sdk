// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library formatter_impl;

import 'dart:math';

import 'package:analyzer_experimental/analyzer.dart';
import 'package:analyzer_experimental/src/generated/parser.dart';
import 'package:analyzer_experimental/src/generated/scanner.dart';
import 'package:analyzer_experimental/src/generated/source.dart';
import 'package:analyzer_experimental/src/services/writer.dart';

/// OS line separator. --- TODO(pquitslund): may not be necessary
const NEW_LINE = '\n' ; //Platform.pathSeparator;

/// Formatter options.
class FormatterOptions {

  /// Create formatter options with defaults derived (where defined) from
  /// the style guide: <http://www.dartlang.org/articles/style-guide/>.
  const FormatterOptions({this.initialIndentationLevel: 0,
                 this.spacesPerIndent: 2,
                 this.lineSeparator: NEW_LINE,
                 this.pageWidth: 80,
                 this.tabsForIndent: false,
                 this.tabSize: 2});

  final String lineSeparator;
  final int initialIndentationLevel;
  final int spacesPerIndent;
  final int tabSize;
  final bool tabsForIndent;
  final int pageWidth;
}


/// Thrown when an error occurs in formatting.
class FormatterException implements Exception {

  /// A message describing the error.
  final String message;

  /// Creates a new FormatterException with an optional error [message].
  const FormatterException([this.message = '']);

  FormatterException.forError(List<AnalysisError> errors) :
    // TODO(pquitslund): add descriptive message based on errors
    message = 'an analysis error occured during format';

  String toString() => 'FormatterException: $message';
}

/// Specifies the kind of code snippet to format.
class CodeKind {

  final int _index;

  const CodeKind._(this._index);

  /// A compilation unit snippet.
  static const COMPILATION_UNIT = const CodeKind._(0);

  /// A statement snippet.
  static const STATEMENT = const CodeKind._(1);

}

/// Dart source code formatter.
abstract class CodeFormatter {

  factory CodeFormatter([FormatterOptions options = const FormatterOptions()])
                        => new CodeFormatterImpl(options);

  /// Format the specified portion (from [offset] with [length]) of the given
  /// [source] string, optionally providing an [indentationLevel].
  String format(CodeKind kind, String source, {int offset, int end,
    int indentationLevel: 0});

}

class CodeFormatterImpl implements CodeFormatter, AnalysisErrorListener {

  final FormatterOptions options;
  final errors = <AnalysisError>[];

  LineInfo lineInfo;

  CodeFormatterImpl(this.options);

  String format(CodeKind kind, String source, {int offset, int end,
      int indentationLevel: 0}) {

    var start = tokenize(source);
    checkForErrors();

    var node = parse(kind, start);
    checkForErrors();

    var formatter = new SourceVisitor(options, lineInfo);
    node.accept(formatter);

    return formatter.writer.toString();
  }

  ASTNode parse(CodeKind kind, Token start) {

    var parser = new Parser(null, this);

    switch (kind) {
      case CodeKind.COMPILATION_UNIT:
        return parser.parseCompilationUnit(start);
      case CodeKind.STATEMENT:
        return parser.parseStatement(start);
    }

    throw new FormatterException('Unsupported format kind: $kind');
  }

  void checkForErrors() {
    if (errors.length > 0) {
      throw new FormatterException.forError(errors);
    }
  }

  void onError(AnalysisError error) {
    errors.add(error);
  }

  Token tokenize(String source) {
    var scanner = new StringScanner(null, source, this);
    var token = scanner.tokenize();
    lineInfo = new LineInfo(scanner.lineStarts);
    return token;
  }

}


/// An AST visitor that drives formatting heuristics.
class SourceVisitor implements ASTVisitor {

  /// The writer to which the source is to be written.
  final SourceWriter writer;

  /// Cached line info for calculating blank lines.
  LineInfo lineInfo;

  /// Cached previous token for calculating preceding whitespace.
  Token previousToken;

  /// A flag to indicate that a newline should be emitted before the next token.
  bool needsNewline = false;
  
  /// A flag to indicate that user introduced newlines should be emitted before
  /// the next token.
  bool preservePrecedingNewlines = false;
  
  /// Initialize a newly created visitor to write source code representing
  /// the visited nodes to the given [writer].
  SourceVisitor(FormatterOptions options, this.lineInfo) :
      writer = new SourceWriter(indentCount: options.initialIndentationLevel,
                                lineSeparator: options.lineSeparator);

  visitAdjacentStrings(AdjacentStrings node) {
    visitList(node.strings, ' ');
  }

  visitAnnotation(Annotation node) {
    token(node.atSign);
    visit(node.name);
    visitPrefixed('.', node.constructorName);
    visit(node.arguments);
  }

  visitArgumentDefinitionTest(ArgumentDefinitionTest node) {
    token(node.question);
    visit(node.identifier);
  }

  visitArgumentList(ArgumentList node) {
    token(node.leftParenthesis);
    visitList(node.arguments, ', ');
    token(node.rightParenthesis);
  }

  visitAsExpression(AsExpression node) {
    visit(node.expression);
    space();
    token(node.asOperator);
    space();
    visit(node.type);
  }

  visitAssertStatement(AssertStatement node) {
    token(node.keyword);
    space();
    token(node.leftParenthesis);
    visit(node.condition);
    token(node.rightParenthesis);
    token(node.semicolon);
  }

  visitAssignmentExpression(AssignmentExpression node) {
    visit(node.leftHandSide);
    space();
    token(node.operator);
    space();
    visit(node.rightHandSide);
  }

  visitBinaryExpression(BinaryExpression node) {
    visit(node.leftOperand);
    space();
    token(node.operator);
    space();
    visit(node.rightOperand);
  }

  visitBlock(Block node) {
    token(node.leftBracket);
    needsNewline = true;
    indent();

    for (var stmt in node.statements) {
      visit(stmt);
    }

    unindent();
    preservePrecedingNewlines = true;
    needsNewline = true;
    token(node.rightBracket);
  }

  visitBlockFunctionBody(BlockFunctionBody node) {
    visit(node.block);
  }

  visitBooleanLiteral(BooleanLiteral node) {
    token(node.literal);
  }

  visitBreakStatement(BreakStatement node) {
    preservePrecedingNewlines = true;
    token(node.keyword);
    visitPrefixed(' ', node.label);
    token(node.semicolon);
    needsNewline = true;
  }

  visitCascadeExpression(CascadeExpression node) {
    visit(node.target);
    visitList(node.cascadeSections);
  }

  visitCatchClause(CatchClause node) {
    visitPrefixed('on ', node.exceptionType);
    if (node.catchKeyword != null) {
      if (node.exceptionType != null) {
        space();
      }
      token(node.catchKeyword);
      space();
      token(node.leftParenthesis);
      visit(node.exceptionParameter);
      visitPrefixed(', ', node.stackTraceParameter);
      token(node.rightParenthesis);
      space();
    } else {
      space();
    }
    visit(node.body);
    needsNewline = true;
  }

  visitClassDeclaration(ClassDeclaration node) {
    preservePrecedingNewlines = true;
    modifier(node.abstractKeyword);
    token(node.classKeyword);
    space();
    visit(node.name);
    visit(node.typeParameters);
    visitPrefixed(' ', node.extendsClause);
    visitPrefixed(' ', node.withClause);
    visitPrefixed(' ', node.implementsClause);
    space();
    token(node.leftBracket);
    indent();

    for (var i = 0; i < node.members.length; i++) {
      visit(node.members[i]);
    }

    unindent();

    emitPrecedingNewlines(node.rightBracket, min: 1);
    token(node.rightBracket);
  }

  visitClassTypeAlias(ClassTypeAlias node) {
    token(node.keyword);
    space();
    visit(node.name);
    visit(node.typeParameters);
    space();
    token(node.equals);
    space();
    if (node.abstractKeyword != null) {
      token(node.abstractKeyword);
      space();
    }
    visit(node.superclass);
    visitPrefixed(' ', node.withClause);
    visitPrefixed(' ', node.implementsClause);
    token(node.semicolon);
  }

  visitComment(Comment node) => null;

  visitCommentReference(CommentReference node) => null;

  visitCompilationUnit(CompilationUnit node) {
    
    // Cache EOF for leading whitespace calculation
    var start = node.beginToken.previous;
    if (start != null && start.type is TokenType_EOF) {
      previousToken = start;
    }
    
    var scriptTag = node.scriptTag;
    var directives = node.directives;
    visit(scriptTag);
    visitList(directives);
    visitList(node.declarations);

    // Handle trailing whitespace
    preservePrecedingNewlines = true;
    token(node.endToken /* EOF */);
  }

  visitConditionalExpression(ConditionalExpression node) {
    visit(node.condition);
    space();
    token(node.question);
    space();
    visit(node.thenExpression);
    space();
    token(node.colon);
    space();
    visit(node.elseExpression);
  }

  visitConstructorDeclaration(ConstructorDeclaration node) {
    modifier(node.externalKeyword);
    modifier(node.constKeyword);
    modifier(node.factoryKeyword);
    visit(node.returnType);
    visitPrefixed('.', node.name);
    visit(node.parameters);
    visitPrefixedList(' : ', node.initializers, ', ');
    visitPrefixed(' = ', node.redirectedConstructor);
    visitPrefixedBody(' ', node.body);
  }

  visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    token(node.keyword);
    token(node.period);
    visit(node.fieldName);
    space();
    token(node.equals);
    space();
    visit(node.expression);
  }

  visitConstructorName(ConstructorName node) {
    visit(node.type);
    visitPrefixed('.', node.name);
  }

  visitContinueStatement(ContinueStatement node) {
    token(node.keyword);
    visitPrefixed(' ', node.label);
    token(node.semicolon);
  }

  visitDeclaredIdentifier(DeclaredIdentifier node) {
    token(node.keyword);
    space();
    visitSuffixed(node.type, ' ');
    visit(node.identifier);
  }

  visitDefaultFormalParameter(DefaultFormalParameter node) {
    visit(node.parameter);
    if (node.separator != null) {
      space();
      token(node.separator);
      visitPrefixed(' ', node.defaultValue);
    }
  }

  visitDoStatement(DoStatement node) {
    token(node.doKeyword);
    space();
    visit(node.body);
    space();
    token(node.whileKeyword);
    space();
    token(node.leftParenthesis);
    visit(node.condition);
    token(node.rightParenthesis);
    token(node.semicolon);
  }

  visitDoubleLiteral(DoubleLiteral node) {
    token(node.literal);
  }

  visitEmptyFunctionBody(EmptyFunctionBody node) {
    token(node.semicolon);
  }

  visitEmptyStatement(EmptyStatement node) {
    token(node.semicolon);
  }

  visitExportDirective(ExportDirective node) {
    token(node.keyword);
    space();
    visit(node.uri);
    visitPrefixedList(' ', node.combinators, ' ');
    token(node.semicolon);
  }

  visitExpressionFunctionBody(ExpressionFunctionBody node) {
    token(node.functionDefinition);
    space();
    visit(node.expression);
    token(node.semicolon);
  }

  visitExpressionStatement(ExpressionStatement node) {
    visit(node.expression);
    token(node.semicolon);
  }

  visitExtendsClause(ExtendsClause node) {
    token(node.keyword);
    space();
    visit(node.superclass);
  }

  visitFieldDeclaration(FieldDeclaration node) {
    token(node.keyword);
    space();
    visit(node.fields);
    token(node.semicolon);
  }

  visitFieldFormalParameter(FieldFormalParameter node) {
    token(node.keyword);
    space();
    visitSuffixed(node.type, ' ');
    token(node.thisToken);
    token(node.period);
    visit(node.identifier);
    visit(node.parameters);
  }

  visitForEachStatement(ForEachStatement node) {
    token(node.forKeyword);
    space();
    token(node.leftParenthesis);
    visit(node.loopVariable);
    space();
    token(node.inKeyword);
    space();
    visit(node.iterator);
    token(node.leftParenthesis);
    space();
    visit(node.body);
  }

  visitFormalParameterList(FormalParameterList node) {
    var groupEnd = null;
    token(node.leftParenthesis);
    var parameters = node.parameters;
    var size = parameters.length;
    for (var i = 0; i < size; i++) {
      var parameter = parameters[i];
      if (i > 0) {
        append(', ');
      }
      if (groupEnd == null && parameter is DefaultFormalParameter) {
        if (identical(parameter.kind, ParameterKind.NAMED)) {
          groupEnd = '}';
          append('{');
        } else {
          groupEnd = ']';
          append('[');
        }
      }
      parameter.accept(this);
    }
    if (groupEnd != null) {
      append(groupEnd);
    }
    token(node.rightParenthesis);
  }

  visitForStatement(ForStatement node) {
    token(node.forKeyword);
    space();
    token(node.leftParenthesis);
    var initialization = node.initialization;
    if (initialization != null) {
      visit(initialization);
    } else {
      visit(node.variables);
    }
    token(node.leftSeparator);
    visitPrefixed(' ', node.condition);
    token(node.rightSeparator);
    visitPrefixedList(' ', node.updaters, ', ');
    token(node.leftParenthesis);
    space();
    visit(node.body);
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    needsNewline = true;
    preservePrecedingNewlines = true;
    visitSuffixed(node.returnType, ' ');
    token(node.propertyKeyword, followedBy: space);
    visit(node.name);
    visit(node.functionExpression);
  }

  visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    visit(node.functionDeclaration);
    // TODO(pquitslund): fix and handle in function body
    append(';');
  }

  visitFunctionExpression(FunctionExpression node) {
    visit(node.parameters);
    space();
    visit(node.body);
  }

  visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    visit(node.function);
    visit(node.argumentList);
  }

  visitFunctionTypeAlias(FunctionTypeAlias node) {
    token(node.keyword);
    space();
    visitSuffixed(node.returnType, ' ');
    visit(node.name);
    visit(node.typeParameters);
    visit(node.parameters);
    token(node.semicolon);
  }

  visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    visitSuffixed(node.returnType, ' ');
    visit(node.identifier);
    visit(node.parameters);
  }

  visitHideCombinator(HideCombinator node) {
    token(node.keyword);
    space();
    visitList(node.hiddenNames, ', ');
  }

  visitIfStatement(IfStatement node) {
    preservePrecedingNewlines = true;
    token(node.ifKeyword);
    space();
    token(node.leftParenthesis);
    visit(node.condition);
    token(node.rightParenthesis);
    space();
    visit(node.thenStatement);
    //visitPrefixed(' else ', node.elseStatement);
    if (node.elseStatement != null) {
      space();
      token(node.elseKeyword);
      space();
      visit(node.elseStatement);
    }
    needsNewline = true;
  }
  
  visitImplementsClause(ImplementsClause node) {
    token(node.keyword);
    space();
    visitList(node.interfaces, ', ');
  }

  visitImportDirective(ImportDirective node) {
    preservePrecedingNewlines = true;
    token(node.keyword);
    space();
    visit(node.uri);
    visitPrefixed(' as ', node.prefix);
    visitPrefixedList(' ', node.combinators, ' ');
    token(node.semicolon);
    needsNewline = true;
  }

  visitIndexExpression(IndexExpression node) {
    if (node.isCascaded) {
      token(node.period);
    } else {
      visit(node.target);
    }
    token(node.leftBracket);
    visit(node.index);
    token(node.rightBracket);
  }

  visitInstanceCreationExpression(InstanceCreationExpression node) {
    token(node.keyword);
    space();
    visit(node.constructorName);
    visit(node.argumentList);
  }

  visitIntegerLiteral(IntegerLiteral node) {
    token(node.literal);
  }

  visitInterpolationExpression(InterpolationExpression node) {
    if (node.rightBracket != null) {
      token(node.leftBracket);
      visit(node.expression);
      token(node.rightBracket);
    } else {
      token(node.leftBracket);
      visit(node.expression);
    }
  }

  visitInterpolationString(InterpolationString node) {
    token(node.contents);
  }

  visitIsExpression(IsExpression node) {
    visit(node.expression);
    space();
    token(node.isOperator);
    token(node.notOperator);
    space();
    visit(node.type);
  }

  visitLabel(Label node) {
    visit(node.label);
    token(node.colon);
  }

  visitLabeledStatement(LabeledStatement node) {
    visitSuffixedList(node.labels, ' ', ' ');
    visit(node.statement);
  }

  visitLibraryDirective(LibraryDirective node) {
    token(node.keyword);
    space();
    visit(node.name);
    token(node.semicolon);
  }

  visitLibraryIdentifier(LibraryIdentifier node) {
    append(node.name);
  }

  visitListLiteral(ListLiteral node) {
    if (node.modifier != null) {
      token(node.modifier);
      space();
    }
    visit(node.typeArguments);
    token(node.leftBracket);
    visitList(node.elements, ', ');
    token(node.rightBracket);
  }

  visitMapLiteral(MapLiteral node) {
    modifier(node.modifier);
    visitSuffixed(node.typeArguments, ' ');
    token(node.leftBracket);
    visitList(node.entries, ', ');
    token(node.rightBracket);
  }

  visitMapLiteralEntry(MapLiteralEntry node) {
    visit(node.key);
    space();
    token(node.separator);
    space();
    visit(node.value);
  }

  visitMethodDeclaration(MethodDeclaration node) {
    needsNewline = true;
    preservePrecedingNewlines = true;
    modifier(node.externalKeyword);
    modifier(node.modifierKeyword);
    visitSuffixed(node.returnType, ' ');
    modifier(node.propertyKeyword);
    modifier(node.operatorKeyword);
    visit(node.name);
    if (!node.isGetter) {
      visit(node.parameters);
    }
    visitPrefixedBody(' ', node.body);
  }

  visitMethodInvocation(MethodInvocation node) {
    if (node.isCascaded) {
      token(node.period);
    } else {
      visitSuffixed(node.target, '.');
    }
    visit(node.methodName);
    visit(node.argumentList);
  }

  visitNamedExpression(NamedExpression node) {
    visit(node.name);
    visitPrefixed(' ', node.expression);
  }

  visitNativeClause(NativeClause node) {
    token(node.keyword);
    space();
    visit(node.name);
  }

  visitNativeFunctionBody(NativeFunctionBody node) {
    token(node.nativeToken);
    space();
    visit(node.stringLiteral);
    token(node.semicolon);
  }

  visitNullLiteral(NullLiteral node) {
    token(node.literal);
  }

  visitParenthesizedExpression(ParenthesizedExpression node) {
    token(node.leftParenthesis);
    visit(node.expression);
    token(node.rightParenthesis);
  }

  visitPartDirective(PartDirective node) {
    token(node.keyword);
    space();
    visit(node.uri);
    token(node.semicolon);
  }

  visitPartOfDirective(PartOfDirective node) {
    token(node.keyword);
    space();
    visit(node.libraryName);
    token(node.semicolon);
  }

  visitPostfixExpression(PostfixExpression node) {
    visit(node.operand);
    token(node.operator);
  }

  visitPrefixedIdentifier(PrefixedIdentifier node) {
    visit(node.prefix);
    token(node.period);
    visit(node.identifier);
  }

  visitPrefixExpression(PrefixExpression node) {
    token(node.operator);
    visit(node.operand);
  }

  visitPropertyAccess(PropertyAccess node) {
    if (node.isCascaded) {
      token(node.operator);
    } else {
      visit(node.target);
      token(node.operator);
    }
    visit(node.propertyName);
  }

  visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    token(node.keyword);
    visitPrefixed('.', node.constructorName);
    visit(node.argumentList);
  }

  visitRethrowExpression(RethrowExpression node) {
    token(node.keyword);
  }

  visitReturnStatement(ReturnStatement node) {
    preservePrecedingNewlines = true;
    var expression = node.expression;
    if (expression == null) {
      token(node.keyword);
      token(node.semicolon);
    } else {
      token(node.keyword);
      space();
      expression.accept(this);
      token(node.semicolon);
    }
  }

  visitScriptTag(ScriptTag node) {
    token(node.scriptTag);
  }

  visitShowCombinator(ShowCombinator node) {
    token(node.keyword);
    space();
    visitList(node.shownNames, ', ');
  }

  visitSimpleFormalParameter(SimpleFormalParameter node) {
    token(node.keyword);
    space();
    visitSuffixed(node.type, ' ');
    visit(node.identifier);
  }

  visitSimpleIdentifier(SimpleIdentifier node) {
    token(node.token);
  }

  visitSimpleStringLiteral(SimpleStringLiteral node) {
    token(node.literal);
  }

  visitStringInterpolation(StringInterpolation node) {
    visitList(node.elements);
  }

  visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    token(node.keyword);
    visitPrefixed('.', node.constructorName);
    visit(node.argumentList);
  }

  visitSuperExpression(SuperExpression node) {
    token(node.keyword);
  }

  visitSwitchCase(SwitchCase node) {
    preservePrecedingNewlines = true;
    visitSuffixedList(node.labels, ' ', ' ');
    token(node.keyword);
    space();
    visit(node.expression);
    token(node.colon);
    indent();
    needsNewline = true;
    visitList(node.statements);
    unindent();
  }

  visitSwitchDefault(SwitchDefault node) {
    preservePrecedingNewlines = true;
    visitSuffixedList(node.labels, ' ', ' ');
    token(node.keyword);
    token(node.colon);
    space();
    visitList(node.statements, ' ');
  }

  visitSwitchStatement(SwitchStatement node) {
    token(node.keyword);
    space();
    token(node.leftParenthesis);
    visit(node.expression);
    token(node.rightParenthesis);
    space();
    token(node.leftBracket);
    indent();
    visitList(node.members);
    unindent();
    token(node.rightBracket);
    needsNewline = true;
  }

  visitSymbolLiteral(SymbolLiteral node) {
     // No-op ?
  }

  visitThisExpression(ThisExpression node) {
    token(node.keyword);
  }

  visitThrowExpression(ThrowExpression node) {
    token(node.keyword);
    space();
    visit(node.expression);
  }

  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    visitSuffixed(node.variables, ';');
  }

  visitTryStatement(TryStatement node) {
    preservePrecedingNewlines = true;
    token(node.tryKeyword);
    space();
    visit(node.body);
    visitPrefixedList(' ', node.catchClauses, ' ');
    visitPrefixed(' finally ', node.finallyClause);
  }

  visitTypeArgumentList(TypeArgumentList node) {
    token(node.leftBracket);
    visitList(node.arguments, ', ');
    token(node.rightBracket);
  }

  visitTypeName(TypeName node) {
    visit(node.name);
    visit(node.typeArguments);
  }

  visitTypeParameter(TypeParameter node) {
    visit(node.name);
    visitPrefixed(' extends ', node.bound);
  }

  visitTypeParameterList(TypeParameterList node) {
    token(node.leftBracket);
    visitList(node.typeParameters, ', ');
    token(node.rightBracket);
  }

  visitVariableDeclaration(VariableDeclaration node) {
    visit(node.name);
    visitPrefixed(' = ', node.initializer);
  }

  visitVariableDeclarationList(VariableDeclarationList node) {
    token(node.keyword);
    space();
    visitSuffixed(node.type, ' ');
    visitList(node.variables, ', ');
  }

  visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    visit(node.variables);
    token(node.semicolon);
  }

  visitWhileStatement(WhileStatement node) {
    token(node.keyword);
    space();
    token(node.leftParenthesis);
    visit(node.condition);
    token(node.rightParenthesis);
    space();
    visit(node.body);
  }

  visitWithClause(WithClause node) {
    token(node.withKeyword);
    space();
    visitList(node.mixinTypes, ', ');
  }

  /// Safely visit the given [node].
  visit(ASTNode node) {
    if (node != null) {
      node.accept(this);
    }
  }

  /// Safely visit the given [node], printing the [suffix] after the node if it
  /// is non-null.
  visitSuffixed(ASTNode node, String suffix) {
    if (node != null) {
      node.accept(this);
      append(suffix);
    }
  }

  /// Safely visit the given [node], printing the [prefix] before the node if
  /// it is non-null.
  visitPrefixed(String prefix, ASTNode node) {
    if (node != null) {
      append(prefix);
      node.accept(this);
    }
  }

  /// Visit the given function [body], printing the [prefix] before if given
  /// body is not empty.
  visitPrefixedBody(String prefix, FunctionBody body) {
    if (body is! EmptyFunctionBody) {
      append(prefix);
    }
    visit(body);
  }

  /// Print a list of [nodes], optionally separated by the given [separator].
  visitList(NodeList<ASTNode> nodes, [String separator = '']) {
    if (nodes != null) {
      var size = nodes.length;
      for (var i = 0; i < size; i++) {
        if (i > 0) {
          append(separator);
        }
        nodes[i].accept(this);
      }
    }
  }

  /// Print a list of [nodes], separated by the given [separator].
  visitSuffixedList(NodeList<ASTNode> nodes, String separator, String suffix) {
    if (nodes != null) {
      var size = nodes.length;
      if (size > 0) {
        for (var i = 0; i < size; i++) {
          if (i > 0) {
            append(separator);
          }
          nodes[i].accept(this);
        }
        append(suffix);
      }
    }
  }

  /// Print a list of [nodes], separated by the given [separator].
  visitPrefixedList(String prefix, NodeList<ASTNode> nodes,
      [String separator = null]) {
    if (nodes != null) {
      var size = nodes.length;
      if (size > 0) {
        append(prefix);
        for (var i = 0; i < size; i++) {
          if (i > 0 && separator != null) {
            append(separator);
          }
          nodes[i].accept(this);
        }
      }
    }
  }

  /// Emit the given [modifier] if it's non null, followed by non-breaking 
  /// whitespace.
  modifier(Token modifier) {
    token(modifier, followedBy: space);
  }
    
  token(Token token, {followedBy(), int minNewlines: 0}) {
    if (token != null) {
      if (needsNewline) {
        minNewlines = max(1, minNewlines);
      }
      if (preservePrecedingNewlines || minNewlines > 0) {
        var emitted = emitPrecedingNewlines(token, min: minNewlines);
        preservePrecedingNewlines = false;
        if (emitted > 0) {
          needsNewline = false;
        }
      }
      append(token.lexeme);
      if (followedBy != null) { 
        followedBy();
      }
      previousToken = token;
    }    
  }
    
  /// Emit a non-breakable space.
  space() {
    //TODO(pquitslund): replace with a proper space token
    append(' ');
  }
  
  /// Emit a breakable space
  breakableSpace() {
    //Implement
  }
  
  /// Append the given [string] to the source writer if it's non-null.
  append(String string) {
    if (string != null) {
      writer.print(string);
    }
  }
    
  /// Indent.
  indent() {
    writer.indent();
  }
  
  /// Unindent
  unindent() {
    writer.unindent();
  }
  
  /// Emit any detected newlines or a minimum as specified by [minNewlines].
  int emitPrecedingNewlines(Token token, {min: 0}) {
    var comment = token.precedingComments;
    var currentToken = comment != null ? comment : token;
    var lines = max(min, countNewlinesBetween(previousToken, currentToken));
    writer.newlines(lines);
    while (comment != null) {
      append(comment.toString().trim());
      writer.newline();
      comment = comment.next;
    }

    previousToken = token;
    return lines;
  }

  /// Count the blanks between these two nodes.
  int countBlankLinesBetween(ASTNode lastNode, ASTNode currentNode) =>
      countNewlinesBetween(lastNode.endToken, currentNode.beginToken);

  /// Count newlines preceeding this [node].
  int countPrecedingNewlines(ASTNode node) =>
      countNewlinesBetween(node.beginToken.previous, node.beginToken);

  /// Count newlines succeeding this [node].
  int countSucceedingNewlines(ASTNode node) => node == null ? 0 :
      countNewlinesBetween(node.endToken, node.endToken.next);

  /// Count the blanks between these two nodes.
  int countNewlinesBetween(Token last, Token current) {
    if (last == null || current == null) {
      return 0;
    }
    var lastLine =
        lineInfo.getLocation(last.offset).lineNumber;
    var currentLine =
        lineInfo.getLocation(current.offset).lineNumber;
    return  currentLine - lastLine;
  }

  String toString() => writer.toString();
  
}