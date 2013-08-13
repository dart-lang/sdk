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

  /// Initialize a newly created visitor to write source code representing
  /// the visited nodes to the given [writer].
  SourceVisitor(FormatterOptions options, this.lineInfo) :
      writer = new SourceWriter(indentCount: options.initialIndentationLevel,
                                lineSeparator: options.lineSeparator);

  visitAdjacentStrings(AdjacentStrings node) {
    visitList(node.strings, ' ');
  }

  visitAnnotation(Annotation node) {
    emitToken(node.atSign);
    visit(node.name);
    visitPrefixed('.', node.constructorName);
    visit(node.arguments);
  }

  visitArgumentDefinitionTest(ArgumentDefinitionTest node) {
    emitToken(node.question);
    visit(node.identifier);
  }

  visitArgumentList(ArgumentList node) {
    emitToken(node.leftParenthesis);
    visitList(node.arguments, ', ');
    emitToken(node.rightParenthesis);
  }

  visitAsExpression(AsExpression node) {
    visit(node.expression);
    emitToken(node.asOperator, prefix: ' ', suffix: ' ');
    visit(node.type);
  }

  visitAssertStatement(AssertStatement node) {
    emitToken(node.keyword, suffix: ' (');
    visit(node.condition);
    emitToken(node.semicolon, prefix: ')');
  }

  visitAssignmentExpression(AssignmentExpression node) {
    visit(node.leftHandSide);
    emitToken(node.operator, prefix: ' ', suffix: ' ');
    visit(node.rightHandSide);
  }

  visitBinaryExpression(BinaryExpression node) {
    visit(node.leftOperand);
    emitToken(node.operator, prefix: ' ', suffix: ' ');
    visit(node.rightOperand);
  }

  visitBlock(Block node) {
    emitToken(node.leftBracket);
    indent();

    for (var stmt in node.statements) {
      visit(stmt);
    }

    unindent();
    newline();
    print('}');
//TODO(pquitslund): make this work    
//    emitToken(node.rightBracket);
    previousToken = node.rightBracket;
  }

  visitBlockFunctionBody(BlockFunctionBody node) {
    visit(node.block);
  }

  visitBooleanLiteral(BooleanLiteral node) {
    emitToken(node.literal);
  }

  visitBreakStatement(BreakStatement node) {
    emitToken(node.keyword);
    visitPrefixed(' ', node.label);
    emitToken(node.semicolon);
  }

  visitCascadeExpression(CascadeExpression node) {
    visit(node.target);
    visitList(node.cascadeSections);
  }

  visitCatchClause(CatchClause node) {
    visitPrefixed('on ', node.exceptionType);
    if (node.catchKeyword != null) {
      if (node.exceptionType != null) {
        print(' ');
      }
      print('catch (');
      visit(node.exceptionParameter);
      visitPrefixed(', ', node.stackTraceParameter);
      print(') ');
    } else {
      print(' ');
    }
    visit(node.body);
    newline();
  }

  visitClassDeclaration(ClassDeclaration node) {
    emitToken(node.abstractKeyword, suffix: ' ');
    emitToken(node.classKeyword, suffix: ' ');
    visit(node.name);
    visit(node.typeParameters);
    visitPrefixed(' ', node.extendsClause);
    visitPrefixed(' ', node.withClause);
    visitPrefixed(' ', node.implementsClause);
    emitToken(node.leftBracket, prefix: ' ');
    indent();

    for (var i = 0; i < node.members.length; i++) {
      visit(node.members[i]);
    }

    unindent();

    emitToken(node.rightBracket, minNewlines: 1);
  }

  visitClassTypeAlias(ClassTypeAlias node) {
    emitToken(node.keyword, suffix: ' ');
    visit(node.name);
    visit(node.typeParameters);
    print(' = ');
    if (node.abstractKeyword != null) {
      print('abstract ');
    }
    visit(node.superclass);
    visitPrefixed(' ', node.withClause);
    visitPrefixed(' ', node.implementsClause);
    emitToken(node.semicolon);
  }

  visitComment(Comment node) => null;

  visitCommentReference(CommentReference node) => null;

  visitCompilationUnit(CompilationUnit node) {
    var scriptTag = node.scriptTag;
    var directives = node.directives;
    visit(scriptTag);
    var prefix = scriptTag == null ? '' : ' ';
    visitPrefixedList(prefix, directives, ' ');
    //prefix = scriptTag == null && directives.isEmpty ? '' : ' ';
    prefix = '';
    visitPrefixedList(prefix, node.declarations);

    //TODO(pquitslund): move this?
    newline();
  }

  visitConditionalExpression(ConditionalExpression node) {
    visit(node.condition);
    print(' ? ');
    visit(node.thenExpression);
    print(' : ');
    visit(node.elseExpression);
  }

  visitConstructorDeclaration(ConstructorDeclaration node) {
    emitToken(node.externalKeyword, suffix: ' ');
    emitToken(node.constKeyword, suffix: ' ');
    emitToken(node.factoryKeyword, suffix: ' ');
    visit(node.returnType);
    visitPrefixed('.', node.name);
    visit(node.parameters);
    visitPrefixedList(' : ', node.initializers, ', ');
    visitPrefixed(' = ', node.redirectedConstructor);
    visitPrefixedBody(' ', node.body);
  }

  visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    emitToken(node.keyword, suffix: '.');
    visit(node.fieldName);
    print(' = ');
    visit(node.expression);
  }

  visitConstructorName(ConstructorName node) {
    visit(node.type);
    visitPrefixed('.', node.name);
  }

  visitContinueStatement(ContinueStatement node) {
    emitToken(node.keyword);
    visitPrefixed(' ', node.label);
    emitToken(node.semicolon);
  }

  visitDeclaredIdentifier(DeclaredIdentifier node) {
    emitToken(node.keyword, suffix: ' ');
    visitSuffixed(node.type, ' ');
    visit(node.identifier);
  }

  visitDefaultFormalParameter(DefaultFormalParameter node) {
    visit(node.parameter);
    if (node.separator != null) {
      print(' ');
      print(node.separator.lexeme);
      visitPrefixed(' ', node.defaultValue);
    }
  }

  visitDoStatement(DoStatement node) {
    emitToken(node.doKeyword, suffix: ' ');
    visit(node.body);
    emitToken(node.whileKeyword, prefix: ' ', suffix: ' (');
    visit(node.condition);
    emitToken(node.semicolon, prefix: ')');
  }

  visitDoubleLiteral(DoubleLiteral node) {
    print(node.literal.lexeme);
  }

  visitEmptyFunctionBody(EmptyFunctionBody node) {
    emitToken(node.semicolon);
  }

  visitEmptyStatement(EmptyStatement node) {
    emitToken(node.semicolon);
  }

  visitExportDirective(ExportDirective node) {
    emitToken(node.keyword, suffix: ' ');
    visit(node.uri);
    visitPrefixedList(' ', node.combinators, ' ');
    emitToken(node.semicolon);
  }

  visitExpressionFunctionBody(ExpressionFunctionBody node) {
    emitToken(node.functionDefinition, suffix: ' ');
    visit(node.expression);
    emitToken(node.semicolon);
  }

  visitExpressionStatement(ExpressionStatement node) {
    visit(node.expression);
    emitToken(node.semicolon);
  }

  visitExtendsClause(ExtendsClause node) {
    emitToken(node.keyword, suffix: ' ');
    visit(node.superclass);
  }

  visitFieldDeclaration(FieldDeclaration node) {
    emitToken(node.keyword, suffix: ' ');
    visit(node.fields);
    emitToken(node.semicolon);
  }

  visitFieldFormalParameter(FieldFormalParameter node) {
    emitToken(node.keyword, suffix: ' ');
    visitSuffixed(node.type, ' ');
    print('this.');
    visit(node.identifier);
    visit(node.parameters);
  }

  visitForEachStatement(ForEachStatement node) {
    print('for (');
    visit(node.loopVariable);
    print(' in ');
    visit(node.iterator);
    print(') ');
    visit(node.body);
  }

  visitFormalParameterList(FormalParameterList node) {
    var groupEnd = null;
    print('(');
    var parameters = node.parameters;
    var size = parameters.length;
    for (var i = 0; i < size; i++) {
      var parameter = parameters[i];
      if (i > 0) {
        print(', ');
      }
      if (groupEnd == null && parameter is DefaultFormalParameter) {
        if (identical(parameter.kind, ParameterKind.NAMED)) {
          groupEnd = '}';
          print('{');
        } else {
          groupEnd = ']';
          print('[');
        }
      }
      parameter.accept(this);
    }
    if (groupEnd != null) {
      print(groupEnd);
    }
    print(')');
  }

  visitForStatement(ForStatement node) {
    var initialization = node.initialization;
    print('for (');
    if (initialization != null) {
      visit(initialization);
    } else {
      visit(node.variables);
    }
    print(';');
    visitPrefixed(' ', node.condition);
    print(';');
    visitPrefixedList(' ', node.updaters, ', ');
    print(') ');
    visit(node.body);
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    visitSuffixed(node.returnType, ' ');
    emitToken(node.propertyKeyword, suffix: ' ');
    visit(node.name);
    visit(node.functionExpression);
  }

  visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    visit(node.functionDeclaration);
    print(';');
  }

  visitFunctionExpression(FunctionExpression node) {
    visit(node.parameters);
    print(' ');
    visit(node.body);
  }

  visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    visit(node.function);
    visit(node.argumentList);
  }

  visitFunctionTypeAlias(FunctionTypeAlias node) {
    emitToken(node.keyword, suffix: ' ');
    visitSuffixed(node.returnType, ' ');
    visit(node.name);
    visit(node.typeParameters);
    visit(node.parameters);
    emitToken(node.semicolon);
  }

  visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    visitSuffixed(node.returnType, ' ');
    visit(node.identifier);
    visit(node.parameters);
  }

  visitHideCombinator(HideCombinator node) {
    emitToken(node.keyword, suffix: ' ');
    visitList(node.hiddenNames, ', ');
  }

  visitIfStatement(IfStatement node) {
    emitToken(node.ifKeyword);
    print(' (');
    visit(node.condition);
    print(') ');
    visit(node.thenStatement);
    visitPrefixed(' else ', node.elseStatement);
  }

  visitImplementsClause(ImplementsClause node) {
    emitToken(node.keyword, suffix: ' ');
    visitList(node.interfaces, ', ');
  }

  visitImportDirective(ImportDirective node) {
    emitToken(node.keyword, suffix: ' ');
    visit(node.uri);
    visitPrefixed(' as ', node.prefix);
    visitPrefixedList(' ', node.combinators, ' ');
    emitToken(node.semicolon);
  }

  visitIndexExpression(IndexExpression node) {
    if (node.isCascaded) {
      print('..');
    } else {
      visit(node.target);
    }
    print('[');
    visit(node.index);
    print(']');
  }

  visitInstanceCreationExpression(InstanceCreationExpression node) {
    emitToken(node.keyword, suffix: ' ');
    visit(node.constructorName);
    visit(node.argumentList);
  }

  visitIntegerLiteral(IntegerLiteral node) {
    print(node.literal.lexeme);
  }

  visitInterpolationExpression(InterpolationExpression node) {
    if (node.rightBracket != null) {
      print('\${');
      visit(node.expression);
      print('}');
    } else {
      print('\$');
      visit(node.expression);
    }
  }

  visitInterpolationString(InterpolationString node) {
    print(node.contents.lexeme);
  }

  visitIsExpression(IsExpression node) {
    visit(node.expression);
    if (node.notOperator == null) {
      print(' is ');
    } else {
      print(' is! ');
    }
    visit(node.type);
  }

  visitLabel(Label node) {
    visit(node.label);
    print(':');
  }

  visitLabeledStatement(LabeledStatement node) {
    visitSuffixedList(node.labels, ' ', ' ');
    visit(node.statement);
  }

  visitLibraryDirective(LibraryDirective node) {
    emitToken(node.keyword, suffix: ' ');
    visit(node.name);
    emitToken(node.semicolon);
  }

  visitLibraryIdentifier(LibraryIdentifier node) {
    print(node.name);
  }

  visitListLiteral(ListLiteral node) {
    if (node.modifier != null) {
      print(node.modifier.lexeme);
      print(' ');
    }
    visit(node.typeArguments);
    print('[');
    visitList(node.elements, ', ');
    print(']');
  }

  visitMapLiteral(MapLiteral node) {
    if (node.modifier != null) {
      print(node.modifier.lexeme);
      print(' ');
    }
    visitSuffixed(node.typeArguments, ' ');
    print('{');
    visitList(node.entries, ', ');
    print('}');
  }

  visitMapLiteralEntry(MapLiteralEntry node) {
    visit(node.key);
    print(' : ');
    visit(node.value);
  }

  visitMethodDeclaration(MethodDeclaration node) {
    emitToken(node.externalKeyword, suffix: ' ');
    emitToken(node.modifierKeyword, suffix: ' ');
    visitSuffixed(node.returnType, ' ');
    emitToken(node.propertyKeyword, suffix: ' ');
    emitToken(node.operatorKeyword, suffix: ' ');
    visit(node.name);
    if (!node.isGetter) {
      visit(node.parameters);
    }
    visitPrefixedBody(' ', node.body);
  }

  visitMethodInvocation(MethodInvocation node) {
    if (node.isCascaded) {
      print('..');
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
    emitToken(node.keyword, suffix: ' ');
    visit(node.name);
  }

  visitNativeFunctionBody(NativeFunctionBody node) {
    emitToken(node.nativeToken, suffix: ' ');
    visit(node.stringLiteral);
    emitToken(node.semicolon);
  }

  visitNullLiteral(NullLiteral node) {
    emitToken(node.literal);
  }

  visitParenthesizedExpression(ParenthesizedExpression node) {
    emitToken(node.leftParenthesis);
    visit(node.expression);
    emitToken(node.rightParenthesis);
  }

  visitPartDirective(PartDirective node) {
    emitToken(node.keyword, suffix: ' ');
    visit(node.uri);
    emitToken(node.semicolon);
  }

  visitPartOfDirective(PartOfDirective node) {
    emitToken(node.keyword, suffix: ' ');
    visit(node.libraryName);
    emitToken(node.semicolon);
  }

  visitPostfixExpression(PostfixExpression node) {
    visit(node.operand);
    print(node.operator.lexeme);
  }

  visitPrefixedIdentifier(PrefixedIdentifier node) {
    visit(node.prefix);
    print('.');
    visit(node.identifier);
  }

  visitPrefixExpression(PrefixExpression node) {
    emitToken(node.operator);
    visit(node.operand);
  }

  visitPropertyAccess(PropertyAccess node) {
    if (node.isCascaded) {
      print('..');
    } else {
      visit(node.target);
      print('.');
    }
    visit(node.propertyName);
  }

  visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    emitToken(node.keyword);
    visitPrefixed('.', node.constructorName);
    visit(node.argumentList);
  }

  visitRethrowExpression(RethrowExpression node) {
    emitToken(node.keyword);
  }

  visitReturnStatement(ReturnStatement node) {
    var expression = node.expression;
    if (expression == null) {
      emitToken(node.keyword, minNewlines: 1);
      emitToken(node.semicolon);
    } else {
      emitToken(node.keyword, suffix: ' ', minNewlines: 1);
      expression.accept(this);
      emitToken(node.semicolon);
    }
  }

  visitScriptTag(ScriptTag node) {
    print(node.scriptTag.lexeme);
  }

  visitShowCombinator(ShowCombinator node) {
    emitToken(node.keyword, suffix: ' ');
    visitList(node.shownNames, ', ');
  }

  visitSimpleFormalParameter(SimpleFormalParameter node) {
    emitToken(node.keyword, suffix: ' ');
    visitSuffixed(node.type, ' ');
    visit(node.identifier);
  }

  visitSimpleIdentifier(SimpleIdentifier node) {
    emitToken(node.token);
  }

  visitSimpleStringLiteral(SimpleStringLiteral node) {
    emitToken(node.literal);
  }

  visitStringInterpolation(StringInterpolation node) {
    visitList(node.elements);
  }

  visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    emitToken(node.keyword);
    visitPrefixed('.', node.constructorName);
    visit(node.argumentList);
  }

  visitSuperExpression(SuperExpression node) {
    emitToken(node.keyword);
  }

  visitSwitchCase(SwitchCase node) {
    visitSuffixedList(node.labels, ' ', ' ');
    emitToken(node.keyword, suffix: ' ');
    visit(node.expression);
    print(':');
    indent();
    visitList(node.statements);
    unindent();
  }

  visitSwitchDefault(SwitchDefault node) {
    visitSuffixedList(node.labels, ' ', ' ');
    emitToken(node.keyword, suffix: ': ');
    visitList(node.statements, ' ');
  }

  visitSwitchStatement(SwitchStatement node) {
    emitToken(node.keyword);
    print(' (');
    visit(node.expression);
    print(') ');
    emitToken(node.leftBracket);
    indent();
    visitList(node.members);
    unindent();
    emitToken(node.rightBracket);
    newline();
  }

  visitSymbolLiteral(SymbolLiteral node) {
     // No-op ?
  }

  visitThisExpression(ThisExpression node) {
    emitToken(node.keyword);
  }

  visitThrowExpression(ThrowExpression node) {
    emitToken(node.keyword, suffix: ' ');
    visit(node.expression);
  }

  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    visitSuffixed(node.variables, ';');
  }

  visitTryStatement(TryStatement node) {
    emitToken(node.tryKeyword, suffix: ' ');
    visit(node.body);
    visitPrefixedList(' ', node.catchClauses, ' ');
    visitPrefixed(' finally ', node.finallyClause);
  }

  visitTypeArgumentList(TypeArgumentList node) {
    emitToken(node.leftBracket);
    visitList(node.arguments, ', ');
    emitToken(node.rightBracket);
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
    emitToken(node.leftBracket);
    visitList(node.typeParameters, ', ');
    emitToken(node.rightBracket);
  }

  visitVariableDeclaration(VariableDeclaration node) {
    visit(node.name);
    visitPrefixed(' = ', node.initializer);
  }

  visitVariableDeclarationList(VariableDeclarationList node) {
    emitToken(node.keyword, suffix: ' ');
    visitSuffixed(node.type, ' ');
    visitList(node.variables, ', ');
  }

  visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    visit(node.variables);
    emitToken(node.semicolon);
  }

  visitWhileStatement(WhileStatement node) {
    emitToken(node.keyword, suffix: ' (');
    visit(node.condition);
    print(') ');
    visit(node.body);
  }

  visitWithClause(WithClause node) {
    emitToken(node.withKeyword, suffix: ' ');
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
      print(suffix);
    }
  }

  /// Safely visit the given [node], printing the [prefix] before the node if
  /// it is non-null.
  visitPrefixed(String prefix, ASTNode node) {
    if (node != null) {
      print(prefix);
      node.accept(this);
    }
  }

  /// Visit the given function [body], printing the [prefix] before if given
  /// body is not empty.
  visitPrefixedBody(String prefix, FunctionBody body) {
    if (body is! EmptyFunctionBody) {
      print(prefix);
    }
    visit(body);
  }

  /// Print a list of [nodes], optionally separated by the given [separator].
  visitList(NodeList<ASTNode> nodes, [String separator = '']) {
    if (nodes != null) {
      var size = nodes.length;
      for (var i = 0; i < size; i++) {
        if (i > 0) {
          print(separator);
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
            print(separator);
          }
          nodes[i].accept(this);
        }
        print(suffix);
      }
    }
  }

  /// Print a list of [nodes], separated by the given [separator].
  visitPrefixedList(String prefix, NodeList<ASTNode> nodes,
      [String separator = null]) {
    if (nodes != null) {
      var size = nodes.length;
      if (size > 0) {
        print(prefix);
        for (var i = 0; i < size; i++) {
          if (i > 0 && separator != null) {
            print(separator);
          }
          nodes[i].accept(this);
        }
      }
    }
  }


  /// Emit the given [token], if it's non-null, preceded by any detected 
  /// newlines or a minimum as specified by [minNewlines], printing a [prefix] 
  /// before and a [suffix] after.
  emitToken(Token token, {String prefix, String suffix, 
      int minNewlines: 0}) {
    if (token != null) {
      print(prefix);
      emitPrecedingNewlines(token, min: minNewlines);
      print(token.lexeme);
      print(suffix);
    }
  }
  
  /// Print the given [string] to the source writer if it's non-null.
  print(String string) {
    if (string != null) {
      writer.print(string);
    }
  }
  
  /// Emit a newline.
  newline() {
   writer.newline();
  }
  
  /// Emit [n] newlines.
  newlines(n) {
   writer.newlines(n);
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
  emitPrecedingNewlines(Token token, {min: 0}) {
    var comment = token.precedingComments;
    var currentToken = comment != null ? comment : token;
    var lines = max(min, countNewlinesBetween(previousToken, currentToken));
    newlines(lines);
    while (comment != null) {
      print(comment.toString().trim());
      newline();
      comment = comment.next;
    }

    previousToken = token;
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