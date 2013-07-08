// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library formatter_impl;


import 'dart:io';

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
  final message;

  /// Creates a new FormatterException with an optional error [message].
  const FormatterException([this.message = '']);

  FormatterException.forError(List<AnalysisError> errors) :
    // TODO(pquitslund): add descriptive message based on errors
    message = 'an analysis error occured during format';

  String toString() => 'FormatterException: $message';

}

/// Specifies the kind of code snippet to format.
class CodeKind {

  final index;

  const CodeKind(this.index);

  /// A compilation unit snippet.
  static const COMPILATION_UNIT = const CodeKind(0);

  /// A statement snippet.
  static const STATEMENT = const CodeKind(1);

}

/// Dart source code formatter.
abstract class CodeFormatter {

  factory CodeFormatter([FormatterOptions options = const FormatterOptions()])
                        => new CodeFormatterImpl(options);

  /// Format the specified portion (from [offset] with [length]) of the given
  /// [source] string, optionally providing an [indentationLevel].
  String format(CodeKind kind, String source, {int offset, int end,
    int indentationLevel:0});

}

class CodeFormatterImpl implements CodeFormatter, AnalysisErrorListener {

  final FormatterOptions options;
  final errors = <AnalysisError>[];

  CodeFormatterImpl(this.options);

  String format(CodeKind kind, String source, {int offset, int end,
      int indentationLevel:0}) {

    var start = tokenize(source);
    checkForErrors();

    var node = parse(kind, start);
    checkForErrors();

    var formatter = new SourceVisitor(options);
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

  checkForErrors() {
    if (errors.length > 0) {
      throw new FormatterException.forError(errors);
    }
  }

  void onError(AnalysisError error) {
    errors.add(error);
  }

  Token tokenize(String source) {
    var scanner = new StringScanner(null, source, this);
    return scanner.tokenize();
  }

}



/// An AST visitor that drives formatting heuristics.
class SourceVisitor implements ASTVisitor {

  /// The writer to which the source is to be written.
  SourceWriter writer;

  /// Initialize a newly created visitor to write source code representing
  /// the visited nodes to the given [writer].
  SourceVisitor(FormatterOptions options) :
      writer = new SourceWriter(initialIndent: options.initialIndentationLevel,
                                lineSeparator: options.lineSeparator);

  visitAdjacentStrings(AdjacentStrings node) {
    visitList(node.strings, ' ');
  }

  visitAnnotation(Annotation node) {
    writer.print('@');
    visit(node.name);
    visitPrefixed('.', node.constructorName);
    visit(node.arguments);
  }

  visitArgumentDefinitionTest(ArgumentDefinitionTest node) {
    writer.print('?');
    visit(node.identifier);
  }

  visitArgumentList(ArgumentList node) {
    writer.print('(');
    visitList(node.arguments, ', ');
    writer.print(')');
  }

  visitAsExpression(AsExpression node) {
    visit(node.expression);
    writer.print(' as ');
    visit(node.type);
  }

  visitAssertStatement(AssertStatement node) {
    writer.print('assert (');
    visit(node.condition);
    writer.print(');');
  }

  visitAssignmentExpression(AssignmentExpression node) {
    visit(node.leftHandSide);
    writer.print(' ');
    writer.print(node.operator.lexeme);
    writer.print(' ');
    visit(node.rightHandSide);
  }

  visitBinaryExpression(BinaryExpression node) {
    visit(node.leftOperand);
    writer.print(' ');
    writer.print(node.operator.lexeme);
    writer.print(' ');
    visit(node.rightOperand);
  }

  visitBlock(Block node) {
    writer.print('{');
    writer.indent();

    for (var stmt in node.statements) {
      writer.newline();
      visit(stmt);
    }

    writer.unindent();
    writer.newline();
    writer.print('}');
  }

  visitBlockFunctionBody(BlockFunctionBody node) {
    visit(node.block);
  }

  visitBooleanLiteral(BooleanLiteral node) {
    writer.print(node.literal.lexeme);
  }

  visitBreakStatement(BreakStatement node) {
    writer.print('break');
    visitPrefixed(' ', node.label);
    writer.print(';');
  }

  visitCascadeExpression(CascadeExpression node) {
    visit(node.target);
    visitList(node.cascadeSections);
  }

  visitCatchClause(CatchClause node) {
    visitPrefixed('on ', node.exceptionType);
    if (node.catchKeyword != null) {
      if (node.exceptionType != null) {
        writer.print(' ');
      }
      writer.print('catch (');
      visit(node.exceptionParameter);
      visitPrefixed(', ', node.stackTraceParameter);
      writer.print(') ');
    } else {
      writer.print(' ');
    }
    visit(node.body);
  }

  visitClassDeclaration(ClassDeclaration node) {
    visitToken(node.abstractKeyword, ' ');
    writer.print('class ');
    visit(node.name);
    visit(node.typeParameters);
    visitPrefixed(' ', node.extendsClause);
    visitPrefixed(' ', node.withClause);
    visitPrefixed(' ', node.implementsClause);
    writer.print(' {');
    writer.indent();
    for (var member in node.members) {
      writer.newline();
      visit(member);
    }

    writer.unindent();
    writer.newline();
    writer.print('}');
  }

  visitClassTypeAlias(ClassTypeAlias node) {
    writer.print('typedef ');
    visit(node.name);
    visit(node.typeParameters);
    writer.print(' = ');
    if (node.abstractKeyword != null) {
      writer.print('abstract ');
    }
    visit(node.superclass);
    visitPrefixed(' ', node.withClause);
    visitPrefixed(' ', node.implementsClause);
    writer.print(';');
  }

  visitComment(Comment node) => null;

  visitCommentReference(CommentReference node) => null;

  visitCompilationUnit(CompilationUnit node) {
    var scriptTag = node.scriptTag;
    var directives = node.directives;
    visit(scriptTag);
    var prefix = scriptTag == null ? '' : ' ';
    visitPrefixedList(prefix, directives, ' ');
    prefix = scriptTag == null && directives.isEmpty ? '' : ' ';
    visitPrefixedList(prefix, node.declarations, ' ');
  }

  visitConditionalExpression(ConditionalExpression node) {
    visit(node.condition);
    writer.print(' ? ');
    visit(node.thenExpression);
    writer.print(' : ');
    visit(node.elseExpression);
  }

  visitConstructorDeclaration(ConstructorDeclaration node) {
    visitToken(node.externalKeyword, ' ');
    visitToken(node.constKeyword, ' ');
    visitToken(node.factoryKeyword, ' ');
    visit(node.returnType);
    visitPrefixed('.', node.name);
    visit(node.parameters);
    visitPrefixedList(' : ', node.initializers, ', ');
    visitPrefixed(' = ', node.redirectedConstructor);
    visitPrefixedBody(' ', node.body);
  }

  visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    visitToken(node.keyword, '.');
    visit(node.fieldName);
    writer.print(' = ');
    visit(node.expression);
  }

  visitConstructorName(ConstructorName node) {
    visit(node.type);
    visitPrefixed('.', node.name);
  }

  visitContinueStatement(ContinueStatement node) {
    writer.print('continue');
    visitPrefixed(' ', node.label);
    writer.print(';');
  }

  visitDeclaredIdentifier(DeclaredIdentifier node) {
    visitToken(node.keyword, ' ');
    visitSuffixed(node.type, ' ');
    visit(node.identifier);
  }

  visitDefaultFormalParameter(DefaultFormalParameter node) {
    visit(node.parameter);
    if (node.separator != null) {
      writer.print(' ');
      writer.print(node.separator.lexeme);
      visitPrefixed(' ', node.defaultValue);
    }
  }

  visitDoStatement(DoStatement node) {
    writer.print('do ');
    visit(node.body);
    writer.print(' while (');
    visit(node.condition);
    writer.print(');');
  }

  visitDoubleLiteral(DoubleLiteral node) {
    writer.print(node.literal.lexeme);
  }

  visitEmptyFunctionBody(EmptyFunctionBody node) {
    writer.print(';');
  }

  visitEmptyStatement(EmptyStatement node) {
    writer.print(';');
  }

  visitExportDirective(ExportDirective node) {
    writer.print('export ');
    visit(node.uri);
    visitPrefixedList(' ', node.combinators, ' ');
    writer.print(';');
  }

  visitExpressionFunctionBody(ExpressionFunctionBody node) {
    writer.print('=> ');
    visit(node.expression);
    if (node.semicolon != null) {
      writer.print(';');
    }
  }

  visitExpressionStatement(ExpressionStatement node) {
    visit(node.expression);
    writer.print(';');
  }

  visitExtendsClause(ExtendsClause node) {
    writer.print('extends ');
    visit(node.superclass);
  }

  visitFieldDeclaration(FieldDeclaration node) {
    visitToken(node.keyword, ' ');
    visit(node.fields);
    writer.print(';');
  }

  visitFieldFormalParameter(FieldFormalParameter node) {
    visitToken(node.keyword, ' ');
    visitSuffixed(node.type, ' ');
    writer.print('this.');
    visit(node.identifier);
    visit(node.parameters);
  }

  visitForEachStatement(ForEachStatement node) {
    writer.print('for (');
    visit(node.loopVariable);
    writer.print(' in ');
    visit(node.iterator);
    writer.print(') ');
    visit(node.body);
  }

  visitFormalParameterList(FormalParameterList node) {
    var groupEnd = null;
    writer.print('(');
    var parameters = node.parameters;
    var size = parameters.length;
    for (var i = 0; i < size; i++) {
      var parameter = parameters[i];
      if (i > 0) {
        writer.print(', ');
      }
      if (groupEnd == null && parameter is DefaultFormalParameter) {
        if (identical(parameter.kind, ParameterKind.NAMED)) {
          groupEnd = '}';
          writer.print('{');
        } else {
          groupEnd = ']';
          writer.print('[');
        }
      }
      parameter.accept(this);
    }
    if (groupEnd != null) {
      writer.print(groupEnd);
    }
    writer.print(')');
  }

  visitForStatement(ForStatement node) {
    var initialization = node.initialization;
    writer.print('for (');
    if (initialization != null) {
      visit(initialization);
    } else {
      visit(node.variables);
    }
    writer.print(';');
    visitPrefixed(' ', node.condition);
    writer.print(';');
    visitPrefixedList(' ', node.updaters, ', ');
    writer.print(') ');
    visit(node.body);
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    visitSuffixed(node.returnType, ' ');
    visitToken(node.propertyKeyword, ' ');
    visit(node.name);
    visit(node.functionExpression);
  }

  visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    visit(node.functionDeclaration);
    writer.print(';');
  }

  visitFunctionExpression(FunctionExpression node) {
    visit(node.parameters);
    writer.print(' ');
    visit(node.body);
  }

  visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    visit(node.function);
    visit(node.argumentList);
  }

  visitFunctionTypeAlias(FunctionTypeAlias node) {
    writer.print('typedef ');
    visitSuffixed(node.returnType, ' ');
    visit(node.name);
    visit(node.typeParameters);
    visit(node.parameters);
    writer.print(';');
  }

  visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    visitSuffixed(node.returnType, ' ');
    visit(node.identifier);
    visit(node.parameters);
  }

  visitHideCombinator(HideCombinator node) {
    writer.print('hide ');
    visitList(node.hiddenNames, ', ');
  }

  visitIfStatement(IfStatement node) {
    writer.print('if (');
    visit(node.condition);
    writer.print(') ');
    visit(node.thenStatement);
    visitPrefixed(' else ', node.elseStatement);
  }

  visitImplementsClause(ImplementsClause node) {
    writer.print('implements ');
    visitList(node.interfaces, ', ');
  }

  visitImportDirective(ImportDirective node) {
    writer.print('import ');
    visit(node.uri);
    visitPrefixed(' as ', node.prefix);
    visitPrefixedList(' ', node.combinators, ' ');
    writer.print(';');
  }

  visitIndexExpression(IndexExpression node) {
    if (node.isCascaded) {
      writer.print('..');
    } else {
      visit(node.array);
    }
    writer.print('[');
    visit(node.index);
    writer.print(']');
  }

  visitInstanceCreationExpression(InstanceCreationExpression node) {
    visitToken(node.keyword, ' ');
    visit(node.constructorName);
    visit(node.argumentList);
  }

  visitIntegerLiteral(IntegerLiteral node) {
    writer.print(node.literal.lexeme);
  }

  visitInterpolationExpression(InterpolationExpression node) {
    if (node.rightBracket != null) {
      writer.print('\${');
      visit(node.expression);
      writer.print('}');
    } else {
      writer.print('\$');
      visit(node.expression);
    }
  }

  visitInterpolationString(InterpolationString node) {
    writer.print(node.contents.lexeme);
  }

  visitIsExpression(IsExpression node) {
    visit(node.expression);
    if (node.notOperator == null) {
      writer.print(' is ');
    } else {
      writer.print(' is! ');
    }
    visit(node.type);
  }

  visitLabel(Label node) {
    visit(node.label);
    writer.print(':');
  }

  visitLabeledStatement(LabeledStatement node) {
    visitSuffixedList(node.labels, ' ', ' ');
    visit(node.statement);
  }

  visitLibraryDirective(LibraryDirective node) {
    writer.print('library ');
    visit(node.name);
    writer.print(';');
  }

  visitLibraryIdentifier(LibraryIdentifier node) {
    writer.print(node.name);
  }

  visitListLiteral(ListLiteral node) {
    if (node.modifier != null) {
      writer.print(node.modifier.lexeme);
      writer.print(' ');
    }
    visitSuffixed(node.typeArguments, ' ');
    writer.print('[');
    visitList(node.elements, ', ');
    writer.print(']');
  }

  visitMapLiteral(MapLiteral node) {
    if (node.modifier != null) {
      writer.print(node.modifier.lexeme);
      writer.print(' ');
    }
    visitSuffixed(node.typeArguments, ' ');
    writer.print('{');
    visitList(node.entries, ', ');
    writer.print('}');
  }

  visitMapLiteralEntry(MapLiteralEntry node) {
    visit(node.key);
    writer.print(' : ');
    visit(node.value);
  }

  visitMethodDeclaration(MethodDeclaration node) {
    visitToken(node.externalKeyword, ' ');
    visitToken(node.modifierKeyword, ' ');
    visitSuffixed(node.returnType, ' ');
    visitToken(node.propertyKeyword, ' ');
    visitToken(node.operatorKeyword, ' ');
    visit(node.name);
    if (!node.isGetter) {
      visit(node.parameters);
    }
    visitPrefixedBody(' ', node.body);
  }

  visitMethodInvocation(MethodInvocation node) {
    if (node.isCascaded) {
      writer.print('..');
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

  visitNativeFunctionBody(NativeFunctionBody node) {
    writer.print('native ');
    visit(node.stringLiteral);
    writer.print(';');
  }

  visitNullLiteral(NullLiteral node) {
    writer.print('null');
  }

  visitParenthesizedExpression(ParenthesizedExpression node) {
    writer.print('(');
    visit(node.expression);
    writer.print(')');
  }

  visitPartDirective(PartDirective node) {
    writer.print('part ');
    visit(node.uri);
    writer.print(';');
  }

  visitPartOfDirective(PartOfDirective node) {
    writer.print('part of ');
    visit(node.libraryName);
    writer.print(';');
  }

  visitPostfixExpression(PostfixExpression node) {
    visit(node.operand);
    writer.print(node.operator.lexeme);
  }

  visitPrefixedIdentifier(PrefixedIdentifier node) {
    visit(node.prefix);
    writer.print('.');
    visit(node.identifier);
  }

  visitPrefixExpression(PrefixExpression node) {
    writer.print(node.operator.lexeme);
    visit(node.operand);
  }

  visitPropertyAccess(PropertyAccess node) {
    if (node.isCascaded) {
      writer.print('..');
    } else {
      visit(node.target);
      writer.print('.');
    }
    visit(node.propertyName);
  }

  visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    writer.print('this');
    visitPrefixed('.', node.constructorName);
    visit(node.argumentList);
  }

  visitRethrowExpression(RethrowExpression node) {
    writer.print('rethrow');
  }

  visitReturnStatement(ReturnStatement node) {
    var expression = node.expression;
    if (expression == null) {
      writer.print('return;');
    } else {
      writer.print('return ');
      expression.accept(this);
      writer.print(';');
    }
  }

  visitScriptTag(ScriptTag node) {
    writer.print(node.scriptTag.lexeme);
  }

  visitShowCombinator(ShowCombinator node) {
    writer.print('show ');
    visitList(node.shownNames, ', ');
  }

  visitSimpleFormalParameter(SimpleFormalParameter node) {
    visitToken(node.keyword, ' ');
    visitSuffixed(node.type, ' ');
    visit(node.identifier);
  }

  visitSimpleIdentifier(SimpleIdentifier node) {
    writer.print(node.token.lexeme);
  }

  visitSimpleStringLiteral(SimpleStringLiteral node) {
    writer.print(node.literal.lexeme);
  }

  visitStringInterpolation(StringInterpolation node) {
    visitList(node.elements);
  }

  visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    writer.print('super');
    visitPrefixed('.', node.constructorName);
    visit(node.argumentList);
  }

  visitSuperExpression(SuperExpression node) {
    writer.print('super');
  }

  visitSwitchCase(SwitchCase node) {
    visitSuffixedList(node.labels, ' ', ' ');
    writer.print('case ');
    visit(node.expression);
    writer.print(': ');
    visitList(node.statements, ' ');
  }

  visitSwitchDefault(SwitchDefault node) {
    visitSuffixedList(node.labels, ' ', ' ');
    writer.print('default: ');
    visitList(node.statements, ' ');
  }

  visitSwitchStatement(SwitchStatement node) {
    writer.print('switch (');
    visit(node.expression);
    writer.print(') {');
    visitList(node.members, ' ');
    writer.print('}');
  }

  visitSymbolLiteral(SymbolLiteral node) {
     // No-op ?
  }

  visitThisExpression(ThisExpression node) {
    writer.print('this');
  }

  visitThrowExpression(ThrowExpression node) {
    writer.print('throw ');
    visit(node.expression);
  }

  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    visitSuffixed(node.variables, ';');
  }

  visitTryStatement(TryStatement node) {
    writer.print('try ');
    visit(node.body);
    visitPrefixedList(' ', node.catchClauses, ' ');
    visitPrefixed(' finally ', node.finallyClause);
  }

  visitTypeArgumentList(TypeArgumentList node) {
    writer.print('<');
    visitList(node.arguments, ', ');
    writer.print('>');
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
    writer.print('<');
    visitList(node.typeParameters, ', ');
    writer.print('>');
  }

  visitVariableDeclaration(VariableDeclaration node) {
    visit(node.name);
    visitPrefixed(' = ', node.initializer);
  }

  visitVariableDeclarationList(VariableDeclarationList node) {
    visitToken(node.keyword, ' ');
    visitSuffixed(node.type, ' ');
    visitList(node.variables, ', ');
  }

  visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    visit(node.variables);
    writer.print(';');
  }

  visitWhileStatement(WhileStatement node) {
    writer.print('while (');
    visit(node.condition);
    writer.print(') ');
    visit(node.body);
  }

  visitWithClause(WithClause node) {
    writer.print('with ');
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
      writer.print(suffix);
    }
  }

  /// Safely visit the given [node], printing the [prefix] before the node if
  /// it is non-null.
  visitPrefixed(String prefix, ASTNode node) {
    if (node != null) {
      writer.print(prefix);
      node.accept(this);
    }
  }

  /// Visit the given function [body], printing the [prefix] before if given
  /// body is not empty.
  visitPrefixedBody(String prefix, FunctionBody body) {
    if (body is! EmptyFunctionBody) {
      writer.print(prefix);
    }
    visit(body);
  }

  /// Safely visit the given [token], printing the suffix after the [token]
  /// node if it is non-null.
  visitToken(Token token, String suffix) {
    if (token != null) {
      writer.print(token.lexeme);
      writer.print(suffix);
    }
  }

  /// Print a list of [nodes], separated by the given [separator].
  visitList(NodeList<ASTNode> nodes, [String separator = '']) {
    if (nodes != null) {
      var size = nodes.length;
      for (var i = 0; i < size; i++) {
        if (i > 0) {
          writer.print(separator);
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
            writer.print(separator);
          }
          nodes[i].accept(this);
        }
        writer.print(suffix);
      }
    }
  }

  /// Print a list of [nodes], separated by the given [separator].
  visitPrefixedList(String prefix, NodeList<ASTNode> nodes, String separator) {
    if (nodes != null) {
      var size = nodes.length;
      if (size > 0) {
        writer.print(prefix);
        for (var i = 0; i < size; i++) {
          if (i > 0) {
            writer.print(separator);
          }
          nodes[i].accept(this);
        }
      }
    }
  }

}