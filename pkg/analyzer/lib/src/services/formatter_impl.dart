// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library formatter_impl;

import 'dart:math';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/services/writer.dart';

/// Formatter options.
class FormatterOptions {

  /// Create formatter options with defaults derived (where defined) from
  /// the style guide: <http://www.dartlang.org/articles/style-guide/>.
  const FormatterOptions({this.initialIndentationLevel: 0,
                 this.spacesPerIndent: 2,
                 this.lineSeparator: NEW_LINE,
                 this.pageWidth: 80,
                 this.tabsForIndent: false,
                 this.tabSize: 2,
                 this.codeTransforms: false});

  final String lineSeparator;
  final int initialIndentationLevel;
  final int spacesPerIndent;
  final int tabSize;
  final bool tabsForIndent;
  final int pageWidth;
  final bool codeTransforms;
}


/// Thrown when an error occurs in formatting.
class FormatterException implements Exception {

  /// A message describing the error.
  final String message;

  /// Creates a new FormatterException with an optional error [message].
  const FormatterException([this.message = 'FormatterException']);

  FormatterException.forError(List<AnalysisError> errors, [LineInfo line]) :
    message = _createMessage(errors);

  static String _createMessage(errors) {
    //TODO(pquitslund): consider a verbosity flag to add/suppress details
    var errorCode = errors[0].errorCode;
    var phase = errorCode is ParserErrorCode ? 'parsing' : 'scanning';
    return 'An error occured while ${phase} (${errorCode.name}).';
  }

  String toString() => '$message';
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
  FormattedSource format(CodeKind kind, String source, {int offset, int end,
    int indentationLevel: 0, Selection selection: null});

}

/// Source selection state information.
class Selection {

  /// The offset of the source selection.
  final int offset;

  /// The length of the selection.
  final int length;

  Selection(this.offset, this.length);

  String toString() => 'Selection (offset: $offset, length: $length)';
}

/// Formatted source.
class FormattedSource {

  /// Selection state or null if unspecified.
  Selection selection;

  /// Formatted source string.
  final String source;

  /// Create a formatted [source] result, with optional [selection] information.
  FormattedSource(this.source, [this.selection = null]);
}


class CodeFormatterImpl implements CodeFormatter, AnalysisErrorListener {

  final FormatterOptions options;
  final errors = <AnalysisError>[];
  final whitespace = new RegExp(r'[\s]+');

  LineInfo lineInfo;

  CodeFormatterImpl(this.options);

  FormattedSource format(CodeKind kind, String source, {int offset, int end,
      int indentationLevel: 0, Selection selection: null}) {

    var startToken = tokenize(source);
    checkForErrors();

    var node = parse(kind, startToken);
    checkForErrors();

    var formatter = new SourceVisitor(options, lineInfo, source, selection);
    node.accept(formatter);

    var formattedSource = formatter.writer.toString();

    checkTokenStreams(startToken, tokenize(formattedSource),
                      allowTransforms: options.codeTransforms);

    return new FormattedSource(formattedSource, formatter.selection);
  }

  checkTokenStreams(Token t1, Token t2, {allowTransforms: false}) =>
      new TokenStreamComparator(lineInfo, t1, t2, transforms: allowTransforms).
          verifyEquals();

  AstNode parse(CodeKind kind, Token start) {

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

  onError(AnalysisError error) {
    errors.add(error);
  }

  Token tokenize(String source) {
    var reader = new CharSequenceReader(source);
    var scanner = new Scanner(null, reader, this);
    var token = scanner.tokenize();
    lineInfo = new LineInfo(scanner.lineStarts);
    return token;
  }

}


// Compares two token streams.  Used for sanity checking formatted results.
class TokenStreamComparator {

  final LineInfo lineInfo;
  Token token1, token2;
  bool allowTransforms;

  TokenStreamComparator(this.lineInfo, this.token1, this.token2,
      {transforms: false}) : this.allowTransforms = transforms;

  /// Verify that these two token streams are equal.
  verifyEquals() {
    while (!isEOF(token1)) {
      checkPrecedingComments();
      if (!checkTokens()) {
        throwNotEqualException(token1, token2);
      }
      advance();

    }
    // TODO(pquitslund): consider a better way to notice trailing synthetics
    if (!isEOF(token2) &&
        !(isCLOSE_CURLY_BRACKET(token2) && isEOF(token2.next))) {
      throw new FormatterException(
          'Expected "EOF" but got "${token2}".');
    }
  }

  checkPrecedingComments() {
    var comment1 = token1.precedingComments;
    var comment2 = token2.precedingComments;
    while (comment1 != null) {
      if (comment2 == null) {
        throw new FormatterException(
            'Expected comment, "${comment1}", at ${describeLocation(token1)}, '
            'but got none.');
      }
      if (!equivalentComments(comment1, comment2)) {
        throwNotEqualException(comment1, comment2);
      }
      comment1 = comment1.next;
      comment2 = comment2.next;
    }
    if (comment2 != null) {
      throw new FormatterException(
          'Unexpected comment, "${comment2}", at ${describeLocation(token2)}.');
    }
  }

  bool equivalentComments(Token comment1, Token comment2) =>
      comment1.lexeme.trim() == comment2.lexeme.trim();

  throwNotEqualException(t1, t2) {
    throw new FormatterException(
        'Expected "${t1}" but got "${t2}", at ${describeLocation(t1)}.');
  }

  String describeLocation(Token token) => lineInfo == null ? '<unknown>' :
      'Line: ${lineInfo.getLocation(token.offset).lineNumber}, '
      'Column: ${lineInfo.getLocation(token.offset).columnNumber}';

  advance() {
    token1 = token1.next;
    token2 = token2.next;
  }

  bool checkTokens() {
    if (token1 == null || token2 == null) {
      return false;
    }
    if (token1 == token2 || token1.lexeme == token2.lexeme) {
      return true;
    }

    // '[' ']' => '[]'
    if (isOPEN_SQ_BRACKET(token1) && isCLOSE_SQUARE_BRACKET(token1.next)) {
      if (isINDEX(token2)) {
        token1 = token1.next;
        return true;
      }
    }
    // '>' '>' => '>>'
    if (isGT(token1) && isGT(token1.next)) {
      if (isGT_GT(token2)) {
        token1 = token1.next;
        return true;
      }
    }
    // Cons(){} => Cons();
    if (isOPEN_CURLY_BRACKET(token1) && isCLOSE_CURLY_BRACKET(token1.next)) {
      if (isSEMICOLON(token2)) {
        token1 = token1.next;
        advance();
        return true;
      }
    }

    // Transform-related special casing
    if (allowTransforms) {

      // Advance past empty statements
      if (isSEMICOLON(token1)) {
        // TODO whitelist
        token1 = token1.next;
        return checkTokens();
      }

      // Advance past synthetic { } tokens
      if (isOPEN_CURLY_BRACKET(token2) || isCLOSE_CURLY_BRACKET(token2)) {
        token2 = token2.next;
        return checkTokens();
      }

    }

    return false;
  }

}

/// Test for token type.
bool tokenIs(Token token, TokenType type) =>
    token != null && token.type == type;

/// Test if this token is an EOF token.
bool isEOF(Token token) => tokenIs(token, TokenType.EOF);

/// Test if this token is a GT token.
bool isGT(Token token) => tokenIs(token, TokenType.GT);

/// Test if this token is a GT_GT token.
bool isGT_GT(Token token) => tokenIs(token, TokenType.GT_GT);

/// Test if this token is an INDEX token.
bool isINDEX(Token token) => tokenIs(token, TokenType.INDEX);

/// Test if this token is a OPEN_CURLY_BRACKET token.
bool isOPEN_CURLY_BRACKET(Token token) =>
    tokenIs(token, TokenType.OPEN_CURLY_BRACKET);

/// Test if this token is a CLOSE_CURLY_BRACKET token.
bool isCLOSE_CURLY_BRACKET(Token token) =>
    tokenIs(token, TokenType.CLOSE_CURLY_BRACKET);

/// Test if this token is a OPEN_SQUARE_BRACKET token.
bool isOPEN_SQ_BRACKET(Token token) =>
    tokenIs(token, TokenType.OPEN_SQUARE_BRACKET);

/// Test if this token is a CLOSE_SQUARE_BRACKET token.
bool isCLOSE_SQUARE_BRACKET(Token token) =>
    tokenIs(token, TokenType.CLOSE_SQUARE_BRACKET);

/// Test if this token is a SEMICOLON token.
bool isSEMICOLON(Token token) =>
    tokenIs(token, TokenType.SEMICOLON);


/// An AST visitor that drives formatting heuristics.
class SourceVisitor implements AstVisitor {

  static final OPEN_CURLY = syntheticToken(TokenType.OPEN_CURLY_BRACKET, '{');
  static final CLOSE_CURLY = syntheticToken(TokenType.CLOSE_CURLY_BRACKET, '}');
  static final SEMI_COLON = syntheticToken(TokenType.SEMICOLON, ';');

  static const SYNTH_OFFSET = -13;

  static StringToken syntheticToken(TokenType type, String value) =>
      new StringToken(type, value, SYNTH_OFFSET);

  static bool isSynthetic(Token token) => token.offset == SYNTH_OFFSET;

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
  bool preserveNewlines = false;

  /// A counter for spaces that should be emitted preceding the next token.
  int leadingSpaces = 0;

  /// A flag to specify whether line-leading spaces should be preserved (and
  /// addded to the indent level).
  bool allowLineLeadingSpaces;

  /// A flag to specify whether zero-length spaces should be emmitted.
  bool emitEmptySpaces = false;

  /// Used for matching EOL comments
  final twoSlashes = new RegExp(r'//[^/]');

  /// A weight for potential breakpoints.
  int currentBreakWeight = DEFAULT_SPACE_WEIGHT;

  /// The last issued space weight.
  int lastSpaceWeight = 0;

  /// Original pre-format selection information (may be null).
  final Selection preSelection;

  final bool codeTransforms;


  /// The source being formatted (used in interpolation handling)
  final String source;

  /// Post format selection information.
  Selection selection;


  /// Initialize a newly created visitor to write source code representing
  /// the visited nodes to the given [writer].
  SourceVisitor(FormatterOptions options, this.lineInfo, this.source,
    this.preSelection)
      : writer = new SourceWriter(indentCount: options.initialIndentationLevel,
                                lineSeparator: options.lineSeparator,
                                maxLineLength: options.pageWidth,
                                useTabs: options.tabsForIndent,
                                spacesPerIndent: options.spacesPerIndent),
       codeTransforms = options.codeTransforms;

  visitAdjacentStrings(AdjacentStrings node) {
    visitNodes(node.strings, separatedBy: space);
  }

  visitAnnotation(Annotation node) {
    token(node.atSign);
    visit(node.name);
    token(node.period);
    visit(node.constructorName);
    visit(node.arguments);
  }

  visitArgumentList(ArgumentList node) {
    token(node.leftParenthesis);
    if (node.arguments.isNotEmpty) {
      int weight = lastSpaceWeight++;
      levelSpace(weight, 0);
      visitCommaSeparatedNodes(
          node.arguments,
          followedBy: () => levelSpace(weight));
    }
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
    token(node.leftParenthesis);
    visit(node.condition);
    token(node.rightParenthesis);
    token(node.semicolon);
  }

  visitAssignmentExpression(AssignmentExpression node) {
    visit(node.leftHandSide);
    space();
    token(node.operator);
    allowContinuedLines((){
      space();
      visit(node.rightHandSide);
    });
  }

  @override
  visitAwaitExpression(AwaitExpression node) {
    token(node.awaitKeyword);
    space();
    visit(node.expression);
    // TODO(scheglov) a bug in the spec, there sould not be a ';'
    token(node.semicolon);
  }

  visitBinaryExpression(BinaryExpression node) {
    Token operator = node.operator;
    TokenType operatorType = operator.type;
    int addOperands(List<Expression> operands, Expression e, int i) {
      if (e is BinaryExpression && e.operator.type == operatorType) {
        i = addOperands(operands, e.leftOperand, i);
        i = addOperands(operands, e.rightOperand, i);
      } else {
        operands.insert(i++, e);
      }
      return i;
    }
    List<Expression> operands = [];
    addOperands(operands, node.leftOperand, 0);
    addOperands(operands, node.rightOperand, operands.length);
    int weight = lastSpaceWeight++;
    for (int i = 0; i < operands.length; i++) {
      if (i != 0) {
        space();
        token(operator);
        levelSpace(weight);
      }
      visit(operands[i]);
    }
  }

  visitBlock(Block node) {
    token(node.leftBracket);
    indent();
    if (!node.statements.isEmpty) {
      visitNodes(node.statements, precededBy: newlines, separatedBy: newlines);
      newlines();
    } else {
      preserveLeadingNewlines();
    }
    token(node.rightBracket, precededBy: unindent);
  }

  visitBlockFunctionBody(BlockFunctionBody node) {
    visit(node.block);
  }

  visitBooleanLiteral(BooleanLiteral node) {
    token(node.literal);
  }

  visitBreakStatement(BreakStatement node) {
    token(node.keyword);
    visitNode(node.label, precededBy: space);
    token(node.semicolon);
  }

  visitCascadeExpression(CascadeExpression node) {
    visit(node.target);
    indent(2);
    // Single cascades do not force a linebreak (dartbug.com/16384)
    if (node.cascadeSections.length > 1) {
      newlines();
    }
    visitNodes(node.cascadeSections, separatedBy: newlines);
    unindent(2);
  }

  visitCatchClause(CatchClause node) {

    token(node.onKeyword, followedBy: space);
    visit(node.exceptionType);

    if (node.catchKeyword != null) {
      if (node.exceptionType != null) {
        space();
      }
      token(node.catchKeyword);
      space();
      token(node.leftParenthesis);
      visit(node.exceptionParameter);
      token(node.comma, followedBy: space);
      visit(node.stackTraceParameter);
      token(node.rightParenthesis);
      space();
    } else {
      space();
    }
    visit(node.body);
  }

  visitClassDeclaration(ClassDeclaration node) {
    preserveLeadingNewlines();
    visitMemberMetadata(node.metadata);
    modifier(node.abstractKeyword);
    token(node.classKeyword);
    space();
    visit(node.name);
    allowContinuedLines((){
      visit(node.typeParameters);
      visitNode(node.extendsClause, precededBy: space);
      visitNode(node.withClause, precededBy: space);
      visitNode(node.implementsClause, precededBy: space);
      visitNode(node.nativeClause, precededBy: space);
      space();
    });
    token(node.leftBracket);
    indent();
    if (!node.members.isEmpty) {
      visitNodes(node.members, precededBy: newlines, separatedBy: newlines);
      newlines();
    } else {
      preserveLeadingNewlines();
    }
    token(node.rightBracket, precededBy: unindent);
  }

  visitClassTypeAlias(ClassTypeAlias node) {
    preserveLeadingNewlines();
    visitMemberMetadata(node.metadata);
    modifier(node.abstractKeyword);
    token(node.keyword);
    space();
    visit(node.name);
    visit(node.typeParameters);
    space();
    token(node.equals);
    space();
    visit(node.superclass);
    visitNode(node.withClause, precededBy: space);
    visitNode(node.implementsClause, precededBy: space);
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

    visitNodes(directives, separatedBy: newlines, followedBy: newlines);

    visitNodes(node.declarations, separatedBy: newlines);

    preserveLeadingNewlines();

    // Handle trailing whitespace
    token(node.endToken /* EOF */);

    // Be a good citizen, end with a NL
    ensureTrailingNewline();
  }

  visitConditionalExpression(ConditionalExpression node) {
    int weight = lastSpaceWeight++;
    visit(node.condition);
    space();
    token(node.question);
    allowContinuedLines((){
      levelSpace(weight);
      visit(node.thenExpression);
      space();
      token(node.colon);
      levelSpace(weight);
      visit(node.elseExpression);
    });
  }

  visitConstructorDeclaration(ConstructorDeclaration node) {
    visitMemberMetadata(node.metadata);
    modifier(node.externalKeyword);
    modifier(node.constKeyword);
    modifier(node.factoryKeyword);
    visit(node.returnType);
    token(node.period);
    visit(node.name);
    visit(node.parameters);

    // Check for redirects or initializer lists
    if (node.separator != null) {
      if (node.redirectedConstructor != null) {
        visitConstructorRedirects(node);
      } else {
        visitConstructorInitializers(node);
      }
    }

    var body = node.body;
    if (codeTransforms && body is BlockFunctionBody) {
      if (body.block.statements.isEmpty) {
        token(SEMI_COLON);
        newlines();
        return;
      }
    }

    visitPrefixedBody(space, body);
  }

  visitConstructorInitializers(ConstructorDeclaration node) {
    if (node.initializers.length > 1) {
      newlines();
    } else {
      preserveLeadingNewlines();
      space();
    }
    indent(2);
    token(node.separator /* : */);
    space();
    for (var i = 0; i < node.initializers.length; i++) {
      if (i > 0) {
        // preceding comma
        token(node.initializers[i].beginToken.previous);
        newlines();
        space(n: 2, allowLineLeading: true);
      }
      node.initializers[i].accept(this);
    }
    unindent(2);
  }

  visitConstructorRedirects(ConstructorDeclaration node) {
    token(node.separator /* = */, precededBy: space, followedBy: space);
    visitCommaSeparatedNodes(node.initializers);
    visit(node.redirectedConstructor);
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
    token(node.period);
    visit(node.name);
  }

  visitContinueStatement(ContinueStatement node) {
    token(node.keyword);
    visitNode(node.label, precededBy: space);
    token(node.semicolon);
  }

  visitDeclaredIdentifier(DeclaredIdentifier node) {
    modifier(node.keyword);
    visitNode(node.type, followedBy: space);
    visit(node.identifier);
  }

  visitDefaultFormalParameter(DefaultFormalParameter node) {
    visit(node.parameter);
    if (node.separator != null) {
      // The '=' separator is preceded by a space
      if (node.separator.type == TokenType.EQ) {
        space();
      }
      token(node.separator);
      visitNode(node.defaultValue, precededBy: space);
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
    allowContinuedLines((){
      visit(node.condition);
      token(node.rightParenthesis);
    });
    token(node.semicolon);
  }

  visitDoubleLiteral(DoubleLiteral node) {
    token(node.literal);
  }

  visitEmptyFunctionBody(EmptyFunctionBody node) {
    token(node.semicolon);
  }

  visitEmptyStatement(EmptyStatement node) {
    if (!codeTransforms || node.parent is! Block) {
      token(node.semicolon);
    }
  }

  visitExportDirective(ExportDirective node) {
    visitDirectiveMetadata(node.metadata);
    token(node.keyword);
    space();
    visit(node.uri);
    allowContinuedLines((){
      visitNodes(node.combinators, precededBy: space, separatedBy: space);
    });
    token(node.semicolon);
  }

  visitExpressionFunctionBody(ExpressionFunctionBody node) {
    int weight = lastSpaceWeight++;
    token(node.functionDefinition);
    levelSpace(weight);
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
    visitMemberMetadata(node.metadata);
    modifier(node.staticKeyword);
    visit(node.fields);
    token(node.semicolon);
  }

  visitFieldFormalParameter(FieldFormalParameter node) {
    token(node.keyword, followedBy: space);
    visitNode(node.type, followedBy: space);
    token(node.thisToken);
    token(node.period);
    visit(node.identifier);
    visit(node.parameters);
  }

  visitForEachStatement(ForEachStatement node) {
    token(node.forKeyword);
    space();
    token(node.leftParenthesis);
    if (node.loopVariable != null) {
      visit(node.loopVariable);
    } else {
      visit(node.identifier);
    }
    space();
    token(node.inKeyword);
    space();
    visit(node.iterator);
    token(node.rightParenthesis);
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
        append(',');
        space();
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
    if (node.initialization != null) {
      visit(node.initialization);
    } else {
      if (node.variables == null) {
        space();
      } else {
        visit(node.variables);
      }
    }
    token(node.leftSeparator);
    space();
    visit(node.condition);
    token(node.rightSeparator);
    if (node.updaters != null) {
      space();
      visitCommaSeparatedNodes(node.updaters);
    }
    token(node.rightParenthesis);
    if (node.body is! EmptyStatement) {
      space();
    }
    visit(node.body);
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    preserveLeadingNewlines();
    visitMemberMetadata(node.metadata);
    modifier(node.externalKeyword);
    visitNode(node.returnType, followedBy: space);
    modifier(node.propertyKeyword);
    visit(node.name);
    visit(node.functionExpression);
  }

  visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    visit(node.functionDeclaration);
  }

  visitFunctionExpression(FunctionExpression node) {
    visit(node.parameters);
    if (node.body is! EmptyFunctionBody) {
      space();
    }
    visit(node.body);
  }

  visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    visit(node.function);
    visit(node.argumentList);
  }

  visitFunctionTypeAlias(FunctionTypeAlias node) {
    visitMemberMetadata(node.metadata);
    token(node.keyword);
    space();
    visitNode(node.returnType, followedBy: space);
    visit(node.name);
    visit(node.typeParameters);
    visit(node.parameters);
    token(node.semicolon);
  }

  visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    visitNode(node.returnType, followedBy: space);
    visit(node.identifier);
    visit(node.parameters);
  }

  visitHideCombinator(HideCombinator node) {
    token(node.keyword);
    space();
    visitCommaSeparatedNodes(node.hiddenNames);
  }

  visitIfStatement(IfStatement node) {
    var hasElse = node.elseStatement != null;
    token(node.ifKeyword);
    allowContinuedLines((){
      space();
      token(node.leftParenthesis);
      visit(node.condition);
      token(node.rightParenthesis);
    });
    space();
    if (hasElse) {
      printAsBlock(node.thenStatement);
      space();
      token(node.elseKeyword);
      space();
      if (node.elseStatement is IfStatement) {
        visit(node.elseStatement);
      } else {
        printAsBlock(node.elseStatement);
      }
    } else {
      visit(node.thenStatement);
    }
  }

  visitImplementsClause(ImplementsClause node) {
    token(node.keyword);
    space();
    visitCommaSeparatedNodes(node.interfaces);
  }

  visitImportDirective(ImportDirective node) {
    visitDirectiveMetadata(node.metadata);
    token(node.keyword);
    nonBreakingSpace();
    visit(node.uri);
    token(node.deferredToken, precededBy: space);
    token(node.asToken, precededBy: space, followedBy: space);
    allowContinuedLines((){
      visit(node.prefix);
      visitNodes(node.combinators, precededBy: space, separatedBy: space);
    });
    token(node.semicolon);
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
    nonBreakingSpace();
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
    visitNodes(node.labels, separatedBy: space, followedBy: space);
    visit(node.statement);
  }

  visitLibraryDirective(LibraryDirective node) {
    visitDirectiveMetadata(node.metadata);
    token(node.keyword);
    space();
    visit(node.name);
    token(node.semicolon);
  }

  visitLibraryIdentifier(LibraryIdentifier node) {
    append(node.name);
  }

  visitListLiteral(ListLiteral node) {
    int weight = lastSpaceWeight++;
    modifier(node.constKeyword);
    visit(node.typeArguments);
    token(node.leftBracket);
    indent();
    levelSpace(weight, 0);
    visitCommaSeparatedNodes(
        node.elements,
        followedBy: () => levelSpace(weight));
    optionalTrailingComma(node.rightBracket);
    token(node.rightBracket, precededBy: unindent);
  }

  visitMapLiteral(MapLiteral node) {
    modifier(node.constKeyword);
    visitNode(node.typeArguments);
    token(node.leftBracket);
    if (!node.entries.isEmpty) {
      newlines();
      indent();
      visitCommaSeparatedNodes(node.entries, followedBy: newlines);
      optionalTrailingComma(node.rightBracket);
      unindent();
      newlines();
    }
    token(node.rightBracket);
  }

  visitMapLiteralEntry(MapLiteralEntry node) {
    visit(node.key);
    token(node.separator);
    space();
    visit(node.value);
  }

  visitMethodDeclaration(MethodDeclaration node) {
    visitMemberMetadata(node.metadata);
    modifier(node.externalKeyword);
    modifier(node.modifierKeyword);
    visitNode(node.returnType, followedBy: space);
    modifier(node.propertyKeyword);
    modifier(node.operatorKeyword);
    visit(node.name);
    if (!node.isGetter) {
      visit(node.parameters);
    }
    visitPrefixedBody(nonBreakingSpace, node.body);
  }

  visitMethodInvocation(MethodInvocation node) {
    visit(node.target);
    token(node.period);
    visit(node.methodName);
    visit(node.argumentList);
  }

  visitNamedExpression(NamedExpression node) {
    visit(node.name);
    visitNode(node.expression, precededBy: space);
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
    token(node.ofToken);
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
    token(node.period);
    visit(node.constructorName);
    visit(node.argumentList);
  }

  visitRethrowExpression(RethrowExpression node) {
    token(node.keyword);
  }

  visitReturnStatement(ReturnStatement node) {
    var expression = node.expression;
    if (expression == null) {
      token(node.keyword);
      token(node.semicolon);
    } else {
      token(node.keyword);
      allowContinuedLines((){
        space();
        expression.accept(this);
        token(node.semicolon);
      });
    }
  }

  visitScriptTag(ScriptTag node) {
    token(node.scriptTag);
  }

  visitShowCombinator(ShowCombinator node) {
    token(node.keyword);
    space();
    visitCommaSeparatedNodes(node.shownNames);
  }

  visitSimpleFormalParameter(SimpleFormalParameter node) {
    visitMemberMetadata(node.metadata);
    modifier(node.keyword);
    visitNode(node.type, followedBy: nonBreakingSpace);
    visit(node.identifier);
  }

  visitSimpleIdentifier(SimpleIdentifier node) {
    token(node.token);
  }

  visitSimpleStringLiteral(SimpleStringLiteral node) {
    token(node.literal);
  }

  visitStringInterpolation(StringInterpolation node) {
    // Ensure that interpolated strings don't get broken up by treating them as
    // a single String token
    // Process token (for comments etc. but don't print the lexeme)
    token(node.beginToken, printToken: (tok) => null);
    var start = node.beginToken.offset;
    var end = node.endToken.end;
    String string = source.substring(start, end);
    append(string);
    //visitNodes(node.elements);
  }

  visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    token(node.keyword);
    token(node.period);
    visit(node.constructorName);
    visit(node.argumentList);
  }

  visitSuperExpression(SuperExpression node) {
    token(node.keyword);
  }

  visitSwitchCase(SwitchCase node) {
    visitNodes(node.labels, separatedBy: space, followedBy: space);
    token(node.keyword);
    space();
    visit(node.expression);
    token(node.colon);
    newlines();
    indent();
    visitNodes(node.statements, separatedBy: newlines);
    unindent();
  }

  visitSwitchDefault(SwitchDefault node) {
    visitNodes(node.labels, separatedBy: space, followedBy: space);
    token(node.keyword);
    token(node.colon);
    newlines();
    indent();
    visitNodes(node.statements, separatedBy: newlines);
    unindent();
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
    newlines();
    visitNodes(node.members, separatedBy: newlines, followedBy: newlines);
    token(node.rightBracket, precededBy: unindent);

  }

  visitSymbolLiteral(SymbolLiteral node) {
    token(node.poundSign);
    var components = node.components;
    var size = components.length;
    for (var component in components) {
      // The '.' separator
      if (component.previous.lexeme == '.') {
        token(component.previous);
      }
      token(component);
    }
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
    visit(node.variables);
    token(node.semicolon);
  }

  visitTryStatement(TryStatement node) {
    token(node.tryKeyword);
    space();
    visit(node.body);
    visitNodes(node.catchClauses, precededBy: space, separatedBy: space);
    token(node.finallyKeyword, precededBy: space, followedBy: space);
    visit(node.finallyBlock);
  }

  visitTypeArgumentList(TypeArgumentList node) {
    token(node.leftBracket);
    visitCommaSeparatedNodes(node.arguments);
    token(node.rightBracket);
  }

  visitTypeName(TypeName node) {
    visit(node.name);
    visit(node.typeArguments);
  }

  visitTypeParameter(TypeParameter node) {
    visitMemberMetadata(node.metadata);
    visit(node.name);
    token(node.keyword /* extends */, precededBy: space, followedBy: space);
    visit(node.bound);
  }

  visitTypeParameterList(TypeParameterList node) {
    token(node.leftBracket);
    visitCommaSeparatedNodes(node.typeParameters);
    token(node.rightBracket);
  }

  visitVariableDeclaration(VariableDeclaration node) {
    visit(node.name);
    if (node.initializer != null) {
      space();
      token(node.equals);
      var initializer = node.initializer;
      if (initializer is ListLiteral || initializer is MapLiteral) {
        space();
        visit(initializer);
      } else if (initializer is BinaryExpression) {
        allowContinuedLines(() {
          levelSpace(lastSpaceWeight);
          visit(initializer);
        });
      } else if (initializer is ConditionalExpression) {
        allowContinuedLines(() {
          space();
          visit(initializer);
        });
      } else {
        allowContinuedLines(() {
          levelSpace(lastSpaceWeight++);
          visit(initializer);
        });
      }
    }
  }

  visitVariableDeclarationList(VariableDeclarationList node) {
    visitMemberMetadata(node.metadata);
    modifier(node.keyword);
    visitNode(node.type, followedBy: space);

    var variables = node.variables;
    // Decls with initializers get their own lines (dartbug.com/16849)
    if (variables.any((v) => (v.initializer != null))) {
      var size = variables.length;
      if (size > 0) {
        var variable;
        for (var i = 0; i < size; i++) {
          variable = variables[i];
          if (i > 0) {
            var comma = variable.beginToken.previous;
            token(comma);
            newlines();
          }
          if (i == 1) {
            indent(2);
          }
          variable.accept(this);
        }
        if (size > 1) {
          unindent(2);
        }
      }
    } else {
      visitCommaSeparatedNodes(node.variables);
    }
  }

  visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    visit(node.variables);
    token(node.semicolon);
  }

  visitWhileStatement(WhileStatement node) {
    token(node.keyword);
    space();
    token(node.leftParenthesis);
    allowContinuedLines((){
      visit(node.condition);
      token(node.rightParenthesis);
    });
    if (node.body is! EmptyStatement) {
      space();
    }
    visit(node.body);
  }

  visitWithClause(WithClause node) {
    token(node.withKeyword);
    space();
    visitCommaSeparatedNodes(node.mixinTypes);
  }

  @override
  visitYieldStatement(YieldStatement node) {
    token(node.yieldKeyword);
    token(node.star);
    space();
    visit(node.expression);
    token(node.semicolon);
  }

  /// Safely visit the given [node].
  visit(AstNode node) {
    if (node != null) {
      node.accept(this);
    }
  }

  /// Visit member metadata
  visitMemberMetadata(NodeList<Annotation> metadata) {
    visitNodes(metadata,
      separatedBy: () {
        space();
        preserveLeadingNewlines();
      },
      followedBy: space);
    if (metadata != null && metadata.length > 0) {
      preserveLeadingNewlines();
    }
  }

  /// Visit member metadata
  visitDirectiveMetadata(NodeList<Annotation> metadata) {
    visitNodes(metadata, separatedBy: newlines, followedBy: newlines);
  }

  /// Visit the given function [body], printing the [prefix] before if given
  /// body is not empty.
  visitPrefixedBody(prefix(), FunctionBody body) {
    if (body is! EmptyFunctionBody) {
      prefix();
    }
    visit(body);
  }

  /// Visit a list of [nodes] if not null, optionally separated and/or preceded
  /// and followed by the given functions.
  visitNodes(NodeList<AstNode> nodes, {precededBy(): null,
      separatedBy() : null, followedBy(): null}) {
    if (nodes != null) {
      var size = nodes.length;
      if (size > 0) {
        if (precededBy != null) {
          precededBy();
        }
        for (var i = 0; i < size; i++) {
          if (i > 0 && separatedBy != null) {
            separatedBy();
          }
          nodes[i].accept(this);
        }
        if (followedBy != null) {
          followedBy();
        }
      }
    }
  }

  /// Visit a comma-separated list of [nodes] if not null.
  visitCommaSeparatedNodes(NodeList<AstNode> nodes, {followedBy(): null}) {
    //TODO(pquitslund): handle this more neatly
    if (followedBy == null) {
      followedBy = space;
    }
    if (nodes != null) {
      var size = nodes.length;
      if (size > 0) {
        var node;
        for (var i = 0; i < size; i++) {
          node = nodes[i];
          if (i > 0) {
            var comma = node.beginToken.previous;
            token(comma);
            followedBy();
          }
          node.accept(this);
        }
      }
    }
  }


  /// Visit a [node], and if not null, optionally preceded or followed by the
  /// specified functions.
  visitNode(AstNode node, {precededBy(): null, followedBy(): null}) {
    if (node != null) {
      if (precededBy != null) {
        precededBy();
      }
      node.accept(this);
      if (followedBy != null) {
        followedBy();
      }
    }
  }

  /// Allow [code] to be continued across lines.
  allowContinuedLines(code()) {
    //TODO(pquitslund): add before
    code();
    //TODO(pquitslund): add after
  }

  /// Emit the given [modifier] if it's non null, followed by non-breaking
  /// whitespace.
  modifier(Token modifier) {
    token(modifier, followedBy: space);
  }

  /// Indicate that at least one newline should be emitted and possibly more
  /// if the source has them.
  newlines() {
    needsNewline = true;
  }

  /// Optionally emit a trailing comma.
  optionalTrailingComma(Token rightBracket) {
    if (rightBracket.previous.lexeme == ',') {
      token(rightBracket.previous);
    }
  }

  /// Indicate that user introduced newlines should be emitted before the next
  /// token.
  preserveLeadingNewlines() {
    preserveNewlines = true;
  }

  token(Token token, {precededBy(), followedBy(), printToken(tok),
      int minNewlines: 0}) {
    if (token != null) {
      if (needsNewline) {
        minNewlines = max(1, minNewlines);
      }
      var emitted = emitPrecedingCommentsAndNewlines(token, min: minNewlines);
      if (emitted > 0) {
        needsNewline = false;
      }
      if (precededBy != null) {
        precededBy();
      }
      checkForSelectionUpdate(token);
      if (printToken == null) {
        append(token.lexeme);
      } else {
        printToken(token);
      }
      if (followedBy != null) {
        followedBy();
      }
      previousToken = token;
    }
  }

  emitSpaces() {
    if (leadingSpaces > 0 || emitEmptySpaces) {
      if (allowLineLeadingSpaces || !writer.currentLine.isWhitespace()) {
        writer.spaces(leadingSpaces, breakWeight: currentBreakWeight);
      }
      leadingSpaces = 0;
      allowLineLeadingSpaces = false;
      emitEmptySpaces = false;
      currentBreakWeight = DEFAULT_SPACE_WEIGHT;
    }
  }

  checkForSelectionUpdate(Token token) {
    // Cache the first token on or AFTER the selection offset
    if (preSelection != null && selection == null) {
      // Check for overshots
      var overshot = token.offset - preSelection.offset;
      if (overshot >= 0) {
        //TODO(pquitslund): update length (may need truncating)
        selection = new Selection(
            writer.toString().length + leadingSpaces - overshot,
            preSelection.length);
      }
    }
  }

  /// Emit a breakable 'non' (zero-length) space
  breakableNonSpace() {
    space(n: 0);
    emitEmptySpaces = true;
  }

  /// Emit level spaces, even if empty (works as a break point).
  levelSpace(int weight, [int n = 1]) {
    space(n: n, breakWeight: weight);
    emitEmptySpaces = true;
  }

  /// Emit a non-breakable space.
  nonBreakingSpace() {
    space(breakWeight: UNBREAKABLE_SPACE_WEIGHT);
  }

  /// Emit a space. If [allowLineLeading] is specified, spaces
  /// will be preserved at the start of a line (in addition to the
  /// indent-level), otherwise line-leading spaces will be ignored.
  space({n: 1, allowLineLeading: false, breakWeight: DEFAULT_SPACE_WEIGHT}) {
    //TODO(pquitslund): replace with a proper space token
    leadingSpaces += n;
    allowLineLeadingSpaces = allowLineLeading;
    currentBreakWeight = breakWeight;
  }

  /// Append the given [string] to the source writer if it's non-null.
  append(String string) {
    if (string != null && !string.isEmpty) {
      emitSpaces();
      writer.write(string);
    }
  }

  /// Indent.
  indent([n = 1]) {
    while (n-- > 0) {
      writer.indent();
    }
  }

  /// Unindent
  unindent([n = 1]) {
    while (n-- > 0) {
      writer.unindent();
    }
  }

  /// Print this statement as if it were a block (e.g., surrounded by braces).
  printAsBlock(Statement statement) {
    if (codeTransforms && statement is! Block) {
      token(OPEN_CURLY);
      indent();
      newlines();
      visit(statement);
      newlines();
      token(CLOSE_CURLY, precededBy: unindent);
    } else {
      visit(statement);
    }
  }

  /// Emit any detected comments and newlines or a minimum as specified
  /// by [min].
  int emitPrecedingCommentsAndNewlines(Token token, {min: 0}) {

    var comment = token.precedingComments;
    var currentToken = comment != null ? comment : token;

    //Handle EOLs before newlines
    if (isAtEOL(comment)) {
      emitComment(comment, previousToken);
      comment = comment.next;
      currentToken = comment != null ? comment : token;
      // Ensure EOL comments force a linebreak
      needsNewline = true;
    }

    var lines = 0;
    if (needsNewline || preserveNewlines) {
      lines = max(min, countNewlinesBetween(previousToken, currentToken));
      preserveNewlines = false;
    }

    emitNewlines(lines);

    previousToken =
        currentToken.previous != null ? currentToken.previous : token.previous;

    while (comment != null) {

      emitComment(comment, previousToken);

      var nextToken = comment.next != null ? comment.next : token;
      var newlines = calculateNewlinesBetweenComments(comment, nextToken);
      if (newlines > 0) {
        emitNewlines(newlines);
        lines += newlines;
      } else {
        var spaces = countSpacesBetween(comment, nextToken);
        if (spaces > 0) {
          space();
        }
      }

      previousToken = comment;
      comment = comment.next;
    }

    previousToken = token;
    return lines;
  }

  void emitNewlines(lines) {
    writer.newlines(lines);
  }

  ensureTrailingNewline() {
    if (writer.lastToken is! NewlineToken) {
      writer.newline();
    }
  }


  /// Test if this EOL [comment] is at the beginning of a line.
  bool isAtBOL(Token comment) =>
      lineInfo.getLocation(comment.offset).columnNumber == 1;

  /// Test if this [comment] is at the end of a line.
  bool isAtEOL(Token comment) =>
      comment != null && comment.toString().trim().startsWith(twoSlashes) &&
      sameLine(comment, previousToken);

  /// Emit this [comment], inserting leading whitespace if appropriate.
  emitComment(Token comment, Token previousToken) {
    if (!writer.currentLine.isWhitespace() && previousToken != null) {
      var ws = countSpacesBetween(previousToken, comment);
      // Preserve one space but no more
      if (ws > 0 && leadingSpaces == 0) {
        space();
      }
    }

    // Don't indent commented-out lines
    if (isAtBOL(comment)) {
      writer.currentLine.clear();
    }

    append(comment.toString().trim());
  }

  /// Count spaces between these tokens.  Tokens on different lines return 0.
  int countSpacesBetween(Token last, Token current) => isEOF(last) ||
      countNewlinesBetween(last, current) > 0 ? 0 : current.offset - last.end;

  /// Count the blanks between these two nodes.
  int countBlankLinesBetween(AstNode lastNode, AstNode currentNode) =>
      countNewlinesBetween(lastNode.endToken, currentNode.beginToken);

  /// Count newlines preceeding this [node].
  int countPrecedingNewlines(AstNode node) =>
      countNewlinesBetween(node.beginToken.previous, node.beginToken);

  /// Count newlines succeeding this [node].
  int countSucceedingNewlines(AstNode node) => node == null ? 0 :
      countNewlinesBetween(node.endToken, node.endToken.next);

  /// Count the blanks between these two tokens.
  int countNewlinesBetween(Token last, Token current) {
    if (last == null || current == null || isSynthetic(last)) {
      return 0;
    }

    return linesBetween(last.end - 1, current.offset);
  }

  /// Calculate the newlines that should separate these comments.
  int calculateNewlinesBetweenComments(Token last, Token current) {
    // Insist on a newline after doc comments or single line comments
    // (NOTE that EOL comments have already been processed).
    if (isOldSingleLineDocComment(last) || isSingleLineComment(last)) {
      return max(1, countNewlinesBetween(last, current));
    } else {
      return countNewlinesBetween(last, current);
    }
  }

  /// Single line multi-line comments (e.g., '/** like this */').
  bool isOldSingleLineDocComment(Token comment) =>
      comment.lexeme.startsWith(r'/**') && singleLine(comment);

  /// Test if this [token] spans just one line.
  bool singleLine(Token token) => linesBetween(token.offset, token.end) < 1;

  /// Test if token [first] is on the same line as [second].
  bool sameLine(Token first, Token second) =>
      countNewlinesBetween(first, second) == 0;

  /// Test if this is a multi-line [comment] (e.g., '/* ...' or '/** ...')
  bool isMultiLineComment(Token comment) =>
      comment.type == TokenType.MULTI_LINE_COMMENT;

  /// Test if this is a single-line [comment] (e.g., '// ...')
  bool isSingleLineComment(Token comment) =>
      comment.type == TokenType.SINGLE_LINE_COMMENT;

  /// Test if this [comment] is a block comment (e.g., '/* like this */')..
  bool isBlock(Token comment) =>
      isMultiLineComment(comment) && singleLine(comment);

  /// Count the lines between two offsets.
  int linesBetween(int lastOffset, int currentOffset) {
    var lastLine =
        lineInfo.getLocation(lastOffset).lineNumber;
    var currentLine =
        lineInfo.getLocation(currentOffset).lineNumber;
    return currentLine - lastLine;
  }

  String toString() => writer.toString();

  @override
  visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    // TODO: implement visitEnumConstantDeclaration
  }

  @override
  visitEnumDeclaration(EnumDeclaration node) {
    // TODO: implement visitEnumDeclaration
  }
}
