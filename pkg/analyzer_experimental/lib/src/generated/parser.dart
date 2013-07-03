// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.
library engine.parser;
import 'dart:collection';
import 'java_core.dart';
import 'java_engine.dart';
import 'instrumentation.dart';
import 'error.dart';
import 'source.dart';
import 'scanner.dart';
import 'ast.dart';
import 'utilities_dart.dart';
/**
 * Instances of the class `CommentAndMetadata` implement a simple data-holder for a method
 * that needs to return multiple values.
 *
 * @coverage dart.engine.parser
 */
class CommentAndMetadata {

  /**
   * The documentation comment that was parsed, or `null` if none was given.
   */
  Comment _comment;

  /**
   * The metadata that was parsed.
   */
  List<Annotation> _metadata;

  /**
   * Initialize a newly created holder with the given data.
   *
   * @param comment the documentation comment that was parsed
   * @param metadata the metadata that was parsed
   */
  CommentAndMetadata(Comment comment, List<Annotation> metadata) {
    this._comment = comment;
    this._metadata = metadata;
  }

  /**
   * Return the documentation comment that was parsed, or `null` if none was given.
   *
   * @return the documentation comment that was parsed
   */
  Comment get comment => _comment;

  /**
   * Return the metadata that was parsed. If there was no metadata, then the list will be empty.
   *
   * @return the metadata that was parsed
   */
  List<Annotation> get metadata => _metadata;
}
/**
 * Instances of the class `FinalConstVarOrType` implement a simple data-holder for a method
 * that needs to return multiple values.
 *
 * @coverage dart.engine.parser
 */
class FinalConstVarOrType {

  /**
   * The 'final', 'const' or 'var' keyword, or `null` if none was given.
   */
  Token _keyword;

  /**
   * The type, of `null` if no type was specified.
   */
  TypeName _type;

  /**
   * Initialize a newly created holder with the given data.
   *
   * @param keyword the 'final', 'const' or 'var' keyword
   * @param type the type
   */
  FinalConstVarOrType(Token keyword, TypeName type) {
    this._keyword = keyword;
    this._type = type;
  }

  /**
   * Return the 'final', 'const' or 'var' keyword, or `null` if none was given.
   *
   * @return the 'final', 'const' or 'var' keyword
   */
  Token get keyword => _keyword;

  /**
   * Return the type, of `null` if no type was specified.
   *
   * @return the type
   */
  TypeName get type => _type;
}
/**
 * Instances of the class `Modifiers` implement a simple data-holder for a method that needs
 * to return multiple values.
 *
 * @coverage dart.engine.parser
 */
class Modifiers {

  /**
   * The token representing the keyword 'abstract', or `null` if the keyword was not found.
   */
  Token _abstractKeyword;

  /**
   * The token representing the keyword 'const', or `null` if the keyword was not found.
   */
  Token _constKeyword;

  /**
   * The token representing the keyword 'external', or `null` if the keyword was not found.
   */
  Token _externalKeyword;

  /**
   * The token representing the keyword 'factory', or `null` if the keyword was not found.
   */
  Token _factoryKeyword;

  /**
   * The token representing the keyword 'final', or `null` if the keyword was not found.
   */
  Token _finalKeyword;

  /**
   * The token representing the keyword 'static', or `null` if the keyword was not found.
   */
  Token _staticKeyword;

  /**
   * The token representing the keyword 'var', or `null` if the keyword was not found.
   */
  Token _varKeyword;

  /**
   * Return the token representing the keyword 'abstract', or `null` if the keyword was not
   * found.
   *
   * @return the token representing the keyword 'abstract'
   */
  Token get abstractKeyword => _abstractKeyword;

  /**
   * Return the token representing the keyword 'const', or `null` if the keyword was not
   * found.
   *
   * @return the token representing the keyword 'const'
   */
  Token get constKeyword => _constKeyword;

  /**
   * Return the token representing the keyword 'external', or `null` if the keyword was not
   * found.
   *
   * @return the token representing the keyword 'external'
   */
  Token get externalKeyword => _externalKeyword;

  /**
   * Return the token representing the keyword 'factory', or `null` if the keyword was not
   * found.
   *
   * @return the token representing the keyword 'factory'
   */
  Token get factoryKeyword => _factoryKeyword;

  /**
   * Return the token representing the keyword 'final', or `null` if the keyword was not
   * found.
   *
   * @return the token representing the keyword 'final'
   */
  Token get finalKeyword => _finalKeyword;

  /**
   * Return the token representing the keyword 'static', or `null` if the keyword was not
   * found.
   *
   * @return the token representing the keyword 'static'
   */
  Token get staticKeyword => _staticKeyword;

  /**
   * Return the token representing the keyword 'var', or `null` if the keyword was not found.
   *
   * @return the token representing the keyword 'var'
   */
  Token get varKeyword => _varKeyword;

  /**
   * Set the token representing the keyword 'abstract' to the given token.
   *
   * @param abstractKeyword the token representing the keyword 'abstract'
   */
  void set abstractKeyword(Token abstractKeyword2) {
    this._abstractKeyword = abstractKeyword2;
  }

  /**
   * Set the token representing the keyword 'const' to the given token.
   *
   * @param constKeyword the token representing the keyword 'const'
   */
  void set constKeyword(Token constKeyword2) {
    this._constKeyword = constKeyword2;
  }

  /**
   * Set the token representing the keyword 'external' to the given token.
   *
   * @param externalKeyword the token representing the keyword 'external'
   */
  void set externalKeyword(Token externalKeyword2) {
    this._externalKeyword = externalKeyword2;
  }

  /**
   * Set the token representing the keyword 'factory' to the given token.
   *
   * @param factoryKeyword the token representing the keyword 'factory'
   */
  void set factoryKeyword(Token factoryKeyword2) {
    this._factoryKeyword = factoryKeyword2;
  }

  /**
   * Set the token representing the keyword 'final' to the given token.
   *
   * @param finalKeyword the token representing the keyword 'final'
   */
  void set finalKeyword(Token finalKeyword2) {
    this._finalKeyword = finalKeyword2;
  }

  /**
   * Set the token representing the keyword 'static' to the given token.
   *
   * @param staticKeyword the token representing the keyword 'static'
   */
  void set staticKeyword(Token staticKeyword2) {
    this._staticKeyword = staticKeyword2;
  }

  /**
   * Set the token representing the keyword 'var' to the given token.
   *
   * @param varKeyword the token representing the keyword 'var'
   */
  void set varKeyword(Token varKeyword2) {
    this._varKeyword = varKeyword2;
  }
  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    bool needsSpace = appendKeyword(builder, false, _abstractKeyword);
    needsSpace = appendKeyword(builder, needsSpace, _constKeyword);
    needsSpace = appendKeyword(builder, needsSpace, _externalKeyword);
    needsSpace = appendKeyword(builder, needsSpace, _factoryKeyword);
    needsSpace = appendKeyword(builder, needsSpace, _finalKeyword);
    needsSpace = appendKeyword(builder, needsSpace, _staticKeyword);
    appendKeyword(builder, needsSpace, _varKeyword);
    return builder.toString();
  }

  /**
   * If the given keyword is not `null`, append it to the given builder, prefixing it with a
   * space if needed.
   *
   * @param builder the builder to which the keyword will be appended
   * @param needsSpace `true` if the keyword needs to be prefixed with a space
   * @param keyword the keyword to be appended
   * @return `true` if subsequent keywords need to be prefixed with a space
   */
  bool appendKeyword(JavaStringBuilder builder, bool needsSpace, Token keyword) {
    if (keyword != null) {
      if (needsSpace) {
        builder.appendChar(0x20);
      }
      builder.append(keyword.lexeme);
      return true;
    }
    return needsSpace;
  }
}
/**
 * Instances of the class `Parser` are used to parse tokens into an AST structure.
 *
 * @coverage dart.engine.parser
 */
class Parser {

  /**
   * The source being parsed.
   */
  Source _source;

  /**
   * The error listener that will be informed of any errors that are found during the parse.
   */
  AnalysisErrorListener _errorListener;

  /**
   * The next token to be parsed.
   */
  Token _currentToken;

  /**
   * A flag indicating whether the parser is currently in the body of a loop.
   */
  bool _inLoop = false;

  /**
   * A flag indicating whether the parser is currently in a switch statement.
   */
  bool _inSwitch = false;
  static String _HIDE = "hide";
  static String _OF = "of";
  static String _ON = "on";
  static String _SHOW = "show";
  static String _NATIVE = "native";

  /**
   * Initialize a newly created parser.
   *
   * @param source the source being parsed
   * @param errorListener the error listener that will be informed of any errors that are found
   *          during the parse
   */
  Parser(Source source, AnalysisErrorListener errorListener) {
    this._source = source;
    this._errorListener = errorListener;
  }

  /**
   * Parse a compilation unit, starting with the given token.
   *
   * @param token the first token of the compilation unit
   * @return the compilation unit that was parsed
   */
  CompilationUnit parseCompilationUnit(Token token) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("dart.engine.Parser.parseCompilationUnit");
    try {
      _currentToken = token;
      return parseCompilationUnit2();
    } finally {
      instrumentation.log();
    }
  }

  /**
   * Parse an expression, starting with the given token.
   *
   * @param token the first token of the expression
   * @return the expression that was parsed, or `null` if the tokens do not represent a
   *         recognizable expression
   */
  Expression parseExpression(Token token) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("dart.engine.Parser.parseExpression");
    try {
      _currentToken = token;
      return parseExpression2();
    } finally {
      instrumentation.log();
    }
  }

  /**
   * Parse a statement, starting with the given token.
   *
   * @param token the first token of the statement
   * @return the statement that was parsed, or `null` if the tokens do not represent a
   *         recognizable statement
   */
  Statement parseStatement(Token token) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("dart.engine.Parser.parseStatement");
    try {
      _currentToken = token;
      return parseStatement2();
    } finally {
      instrumentation.log();
    }
  }

  /**
   * Parse a sequence of statements, starting with the given token.
   *
   * @param token the first token of the sequence of statement
   * @return the statements that were parsed, or `null` if the tokens do not represent a
   *         recognizable sequence of statements
   */
  List<Statement> parseStatements(Token token) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("dart.engine.Parser.parseStatements");
    try {
      _currentToken = token;
      return parseStatements2();
    } finally {
      instrumentation.log();
    }
  }
  void set currentToken(Token currentToken2) {
    this._currentToken = currentToken2;
  }

  /**
   * Advance to the next token in the token stream.
   */
  void advance() {
    _currentToken = _currentToken.next;
  }

  /**
   * Append the character equivalent of the given scalar value to the given builder. Use the start
   * and end indices to report an error, and don't append anything to the builder, if the scalar
   * value is invalid.
   *
   * @param builder the builder to which the scalar value is to be appended
   * @param escapeSequence the escape sequence that was parsed to produce the scalar value
   * @param scalarValue the value to be appended
   * @param startIndex the index of the first character representing the scalar value
   * @param endIndex the index of the last character representing the scalar value
   */
  void appendScalarValue(JavaStringBuilder builder, String escapeSequence, int scalarValue, int startIndex, int endIndex) {
    if (scalarValue < 0 || scalarValue > Character.MAX_CODE_POINT || (scalarValue >= 0xD800 && scalarValue <= 0xDFFF)) {
      reportError7(ParserErrorCode.INVALID_CODE_POINT, [escapeSequence]);
      return;
    }
    if (scalarValue < Character.MAX_VALUE) {
      builder.appendChar((scalarValue as int));
    } else {
      builder.append(Character.toChars(scalarValue));
    }
  }

  /**
   * Compute the content of a string with the given literal representation.
   *
   * @param lexeme the literal representation of the string
   * @return the actual value of the string
   */
  String computeStringValue(String lexeme) {
    if (lexeme.startsWith("r\"\"\"") || lexeme.startsWith("r'''")) {
      if (lexeme.length > 4) {
        return lexeme.substring(4, lexeme.length - 3);
      }
    } else if (lexeme.startsWith("r\"") || lexeme.startsWith("r'")) {
      if (lexeme.length > 2) {
        return lexeme.substring(2, lexeme.length - 1);
      }
    }
    int start = 0;
    if (lexeme.startsWith("\"\"\"") || lexeme.startsWith("'''")) {
      start += 3;
    } else if (lexeme.startsWith("\"") || lexeme.startsWith("'")) {
      start += 1;
    }
    int end = lexeme.length;
    if (end > 3 && (lexeme.endsWith("\"\"\"") || lexeme.endsWith("'''"))) {
      end -= 3;
    } else if (end > 1 && (lexeme.endsWith("\"") || lexeme.endsWith("'"))) {
      end -= 1;
    }
    JavaStringBuilder builder = new JavaStringBuilder();
    int index = start;
    while (index < end) {
      index = translateCharacter(builder, lexeme, index);
    }
    return builder.toString();
  }

  /**
   * Convert the given method declaration into the nearest valid top-level function declaration.
   *
   * @param method the method to be converted
   * @return the function declaration that most closely captures the components of the given method
   *         declaration
   */
  FunctionDeclaration convertToFunctionDeclaration(MethodDeclaration method) => new FunctionDeclaration.full(method.documentationComment, method.metadata, method.externalKeyword, method.returnType, method.propertyKeyword, method.name, new FunctionExpression.full(method.parameters, method.body));

  /**
   * Return `true` if the current token could be the start of a compilation unit member. This
   * method is used for recovery purposes to decide when to stop skipping tokens after finding an
   * error while parsing a compilation unit member.
   *
   * @return `true` if the current token could be the start of a compilation unit member
   */
  bool couldBeStartOfCompilationUnitMember() {
    if ((matches(Keyword.IMPORT) || matches(Keyword.EXPORT) || matches(Keyword.LIBRARY) || matches(Keyword.PART)) && !matches4(peek(), TokenType.PERIOD) && !matches4(peek(), TokenType.LT)) {
      return true;
    } else if (matches(Keyword.CLASS)) {
      return true;
    } else if (matches(Keyword.TYPEDEF) && !matches4(peek(), TokenType.PERIOD) && !matches4(peek(), TokenType.LT)) {
      return true;
    } else if (matches(Keyword.VOID) || ((matches(Keyword.GET) || matches(Keyword.SET)) && matchesIdentifier2(peek())) || (matches(Keyword.OPERATOR) && isOperator(peek()))) {
      return true;
    } else if (matchesIdentifier()) {
      if (matches4(peek(), TokenType.OPEN_PAREN)) {
        return true;
      }
      Token token = skipReturnType(_currentToken);
      if (token == null) {
        return false;
      }
      if (matches(Keyword.GET) || matches(Keyword.SET) || (matches(Keyword.OPERATOR) && isOperator(peek())) || matchesIdentifier()) {
        return true;
      }
    }
    return false;
  }

  /**
   * Create a synthetic identifier.
   *
   * @return the synthetic identifier that was created
   */
  SimpleIdentifier createSyntheticIdentifier() => new SimpleIdentifier.full(createSyntheticToken2(TokenType.IDENTIFIER));

  /**
   * Create a synthetic string literal.
   *
   * @return the synthetic string literal that was created
   */
  SimpleStringLiteral createSyntheticStringLiteral() => new SimpleStringLiteral.full(createSyntheticToken2(TokenType.STRING), "");

  /**
   * Create a synthetic token representing the given keyword.
   *
   * @return the synthetic token that was created
   */
  Token createSyntheticToken(Keyword keyword) => new KeywordToken_11(keyword, _currentToken.offset);

  /**
   * Create a synthetic token with the given type.
   *
   * @return the synthetic token that was created
   */
  Token createSyntheticToken2(TokenType type) => new StringToken(type, "", _currentToken.offset);

  /**
   * Check that the given expression is assignable and report an error if it isn't.
   *
   * <pre>
   * assignableExpression ::=
   *     primary (arguments* assignableSelector)+
   *   | 'super' assignableSelector
   *   | identifier
   *
   * assignableSelector ::=
   *     '[' expression ']'
   *   | '.' identifier
   * </pre>
   *
   * @param expression the expression being checked
   */
  void ensureAssignable(Expression expression) {
    if (expression != null && !expression.isAssignable) {
      reportError7(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, []);
    }
  }

  /**
   * If the current token is a keyword matching the given string, return it after advancing to the
   * next token. Otherwise report an error and return the current token without advancing.
   *
   * @param keyword the keyword that is expected
   * @return the token that matched the given type
   */
  Token expect(Keyword keyword) {
    if (matches(keyword)) {
      return andAdvance;
    }
    reportError7(ParserErrorCode.EXPECTED_TOKEN, [keyword.syntax]);
    return _currentToken;
  }

  /**
   * If the current token has the expected type, return it after advancing to the next token.
   * Otherwise report an error and return the current token without advancing.
   *
   * @param type the type of token that is expected
   * @return the token that matched the given type
   */
  Token expect2(TokenType type) {
    if (matches5(type)) {
      return andAdvance;
    }
    if (identical(type, TokenType.SEMICOLON)) {
      reportError8(ParserErrorCode.EXPECTED_TOKEN, _currentToken.previous, [type.lexeme]);
    } else {
      reportError7(ParserErrorCode.EXPECTED_TOKEN, [type.lexeme]);
    }
    return _currentToken;
  }

  /**
   * Search the given list of ranges for a range that contains the given index. Return the range
   * that was found, or `null` if none of the ranges contain the index.
   *
   * @param ranges the ranges to be searched
   * @param index the index contained in the returned range
   * @return the range that was found
   */
  List<int> findRange(List<List<int>> ranges, int index) {
    for (List<int> range in ranges) {
      if (range[0] <= index && index <= range[1]) {
        return range;
      } else if (index < range[0]) {
        return null;
      }
    }
    return null;
  }

  /**
   * Advance to the next token in the token stream, making it the new current token.
   *
   * @return the token that was current before this method was invoked
   */
  Token get andAdvance {
    Token token = _currentToken;
    advance();
    return token;
  }

  /**
   * Return a list of the ranges of characters in the given comment string that should be treated as
   * code blocks.
   *
   * @param comment the comment being processed
   * @return the ranges of characters that should be treated as code blocks
   */
  List<List<int>> getCodeBlockRanges(String comment) {
    List<List<int>> ranges = new List<List<int>>();
    int length = comment.length;
    int index = 0;
    if (comment.startsWith("/**") || comment.startsWith("///")) {
      index = 3;
    }
    while (index < length) {
      int currentChar = comment.codeUnitAt(index);
      if (currentChar == 0xD || currentChar == 0xA) {
        index = index + 1;
        while (index < length && Character.isWhitespace(comment.codeUnitAt(index))) {
          index = index + 1;
        }
        if (JavaString.startsWithBefore(comment, "*     ", index)) {
          int end = index + 6;
          while (end < length && comment.codeUnitAt(end) != 0xD && comment.codeUnitAt(end) != 0xA) {
            end = end + 1;
          }
          ranges.add(<int> [index, end]);
          index = end;
        }
      } else if (JavaString.startsWithBefore(comment, "[:", index)) {
        int end = JavaString.indexOf(comment, ":]", index + 2);
        if (end < 0) {
          end = length;
        }
        ranges.add(<int> [index, end]);
        index = end + 1;
      } else {
        index = index + 1;
      }
    }
    return ranges;
  }

  /**
   * Return the end token associated with the given begin token, or `null` if either the given
   * token is not a begin token or it does not have an end token associated with it.
   *
   * @param beginToken the token that is expected to have an end token associated with it
   * @return the end token associated with the begin token
   */
  Token getEndToken(Token beginToken) {
    if (beginToken is BeginToken) {
      return ((beginToken as BeginToken)).endToken;
    }
    return null;
  }

  /**
   * Return `true` if the current token is the first token of a return type that is followed
   * by an identifier, possibly followed by a list of type parameters, followed by a
   * left-parenthesis. This is used by parseTypeAlias to determine whether or not to parse a return
   * type.
   *
   * @return `true` if we can successfully parse the rest of a type alias if we first parse a
   *         return type.
   */
  bool hasReturnTypeInTypeAlias() {
    Token next = skipReturnType(_currentToken);
    if (next == null) {
      return false;
    }
    return matchesIdentifier2(next);
  }

  /**
   * Return `true` if the current token appears to be the beginning of a function declaration.
   *
   * @return `true` if the current token appears to be the beginning of a function declaration
   */
  bool isFunctionDeclaration() {
    if (matches(Keyword.VOID)) {
      return true;
    }
    Token afterReturnType = skipTypeName(_currentToken);
    if (afterReturnType == null) {
      afterReturnType = _currentToken;
    }
    Token afterIdentifier = skipSimpleIdentifier(afterReturnType);
    if (afterIdentifier == null) {
      afterIdentifier = skipSimpleIdentifier(_currentToken);
    }
    if (afterIdentifier == null) {
      return false;
    }
    return isFunctionExpression(afterIdentifier);
  }

  /**
   * Return `true` if the given token appears to be the beginning of a function expression.
   *
   * @param startToken the token that might be the start of a function expression
   * @return `true` if the given token appears to be the beginning of a function expression
   */
  bool isFunctionExpression(Token startToken) {
    Token afterParameters = skipFormalParameterList(startToken);
    if (afterParameters == null) {
      return false;
    }
    return matchesAny(afterParameters, [TokenType.OPEN_CURLY_BRACKET, TokenType.FUNCTION]);
  }

  /**
   * Return `true` if the given character is a valid hexadecimal digit.
   *
   * @param character the character being tested
   * @return `true` if the character is a valid hexadecimal digit
   */
  bool isHexDigit(int character) => (0x30 <= character && character <= 0x39) || (0x41 <= character && character <= 0x46) || (0x61 <= character && character <= 0x66);

  /**
   * Return `true` if the current token is the first token in an initialized variable
   * declaration rather than an expression. This method assumes that we have already skipped past
   * any metadata that might be associated with the declaration.
   *
   * <pre>
   * initializedVariableDeclaration ::=
   *     declaredIdentifier ('=' expression)? (',' initializedIdentifier)*
   *
   * declaredIdentifier ::=
   *     metadata finalConstVarOrType identifier
   *
   * finalConstVarOrType ::=
   *     'final' type?
   *   | 'const' type?
   *   | 'var'
   *   | type
   *
   * type ::=
   *     qualified typeArguments?
   *
   * initializedIdentifier ::=
   *     identifier ('=' expression)?
   * </pre>
   *
   * @return `true` if the current token is the first token in an initialized variable
   *         declaration
   */
  bool isInitializedVariableDeclaration() {
    if (matches(Keyword.FINAL) || matches(Keyword.VAR)) {
      return true;
    }
    if (matches(Keyword.CONST)) {
      return !matchesAny(peek(), [TokenType.LT, TokenType.OPEN_CURLY_BRACKET, TokenType.OPEN_SQUARE_BRACKET, TokenType.INDEX]);
    }
    Token token = skipTypeName(_currentToken);
    if (token == null) {
      return false;
    }
    token = skipSimpleIdentifier(token);
    if (token == null) {
      return false;
    }
    TokenType type = token.type;
    return identical(type, TokenType.EQ) || identical(type, TokenType.COMMA) || identical(type, TokenType.SEMICOLON) || matches3(token, Keyword.IN);
  }

  /**
   * Given that we have just found bracketed text within a comment, look to see whether that text is
   * (a) followed by a parenthesized link address, (b) followed by a colon, or (c) followed by
   * optional whitespace and another square bracket.
   *
   * This method uses the syntax described by the <a
   * href="http://daringfireball.net/projects/markdown/syntax">markdown</a> project.
   *
   * @param comment the comment text in which the bracketed text was found
   * @param rightIndex the index of the right bracket
   * @return `true` if the bracketed text is followed by a link address
   */
  bool isLinkText(String comment, int rightIndex) {
    int length = comment.length;
    int index = rightIndex + 1;
    if (index >= length) {
      return false;
    }
    int nextChar = comment.codeUnitAt(index);
    if (nextChar == 0x28 || nextChar == 0x3A) {
      return true;
    }
    while (Character.isWhitespace(nextChar)) {
      index = index + 1;
      if (index >= length) {
        return false;
      }
      nextChar = comment.codeUnitAt(index);
    }
    return nextChar == 0x5B;
  }

  /**
   * Return `true` if the given token appears to be the beginning of an operator declaration.
   *
   * @param startToken the token that might be the start of an operator declaration
   * @return `true` if the given token appears to be the beginning of an operator declaration
   */
  bool isOperator(Token startToken) {
    if (startToken.isOperator) {
      Token token = startToken.next;
      while (token.isOperator) {
        token = token.next;
      }
      return matches4(token, TokenType.OPEN_PAREN);
    }
    return false;
  }

  /**
   * Return `true` if the current token appears to be the beginning of a switch member.
   *
   * @return `true` if the current token appears to be the beginning of a switch member
   */
  bool isSwitchMember() {
    Token token = _currentToken;
    while (matches4(token, TokenType.IDENTIFIER) && matches4(token.next, TokenType.COLON)) {
      token = token.next.next;
    }
    if (identical(token.type, TokenType.KEYWORD)) {
      Keyword keyword = ((token as KeywordToken)).keyword;
      return identical(keyword, Keyword.CASE) || identical(keyword, Keyword.DEFAULT);
    }
    return false;
  }

  /**
   * Compare the given tokens to find the token that appears first in the source being parsed. That
   * is, return the left-most of all of the tokens. The arguments are allowed to be `null`.
   * Return the token with the smallest offset, or `null` if there are no arguments or if all
   * of the arguments are `null`.
   *
   * @param tokens the tokens being compared
   * @return the token with the smallest offset
   */
  Token lexicallyFirst(List<Token> tokens) {
    Token first = null;
    int firstOffset = 2147483647;
    for (Token token in tokens) {
      if (token != null) {
        int offset = token.offset;
        if (offset < firstOffset) {
          first = token;
          firstOffset = offset;
        }
      }
    }
    return first;
  }

  /**
   * Return `true` if the current token matches the given keyword.
   *
   * @param keyword the keyword that can optionally appear in the current location
   * @return `true` if the current token matches the given keyword
   */
  bool matches(Keyword keyword) => matches3(_currentToken, keyword);

  /**
   * Return `true` if the current token matches the given identifier.
   *
   * @param identifier the identifier that can optionally appear in the current location
   * @return `true` if the current token matches the given identifier
   */
  bool matches2(String identifier) => identical(_currentToken.type, TokenType.IDENTIFIER) && _currentToken.lexeme == identifier;

  /**
   * Return `true` if the given token matches the given keyword.
   *
   * @param token the token being tested
   * @param keyword the keyword that is being tested for
   * @return `true` if the given token matches the given keyword
   */
  bool matches3(Token token, Keyword keyword2) => identical(token.type, TokenType.KEYWORD) && identical(((token as KeywordToken)).keyword, keyword2);

  /**
   * Return `true` if the given token has the given type.
   *
   * @param token the token being tested
   * @param type the type of token that is being tested for
   * @return `true` if the given token has the given type
   */
  bool matches4(Token token, TokenType type2) => identical(token.type, type2);

  /**
   * Return `true` if the current token has the given type. Note that this method, unlike
   * other variants, will modify the token stream if possible to match a wider range of tokens. In
   * particular, if we are attempting to match a '>' and the next token is either a '>>' or '>>>',
   * the token stream will be re-written and `true` will be returned.
   *
   * @param type the type of token that can optionally appear in the current location
   * @return `true` if the current token has the given type
   */
  bool matches5(TokenType type2) {
    TokenType currentType = _currentToken.type;
    if (currentType != type2) {
      if (identical(type2, TokenType.GT)) {
        if (identical(currentType, TokenType.GT_GT)) {
          int offset = _currentToken.offset;
          Token first = new Token(TokenType.GT, offset);
          Token second = new Token(TokenType.GT, offset + 1);
          second.setNext(_currentToken.next);
          first.setNext(second);
          _currentToken.previous.setNext(first);
          _currentToken = first;
          return true;
        } else if (identical(currentType, TokenType.GT_EQ)) {
          int offset = _currentToken.offset;
          Token first = new Token(TokenType.GT, offset);
          Token second = new Token(TokenType.EQ, offset + 1);
          second.setNext(_currentToken.next);
          first.setNext(second);
          _currentToken.previous.setNext(first);
          _currentToken = first;
          return true;
        } else if (identical(currentType, TokenType.GT_GT_EQ)) {
          int offset = _currentToken.offset;
          Token first = new Token(TokenType.GT, offset);
          Token second = new Token(TokenType.GT, offset + 1);
          Token third = new Token(TokenType.EQ, offset + 2);
          third.setNext(_currentToken.next);
          second.setNext(third);
          first.setNext(second);
          _currentToken.previous.setNext(first);
          _currentToken = first;
          return true;
        }
      }
      return false;
    }
    return true;
  }

  /**
   * Return `true` if the given token has any one of the given types.
   *
   * @param token the token being tested
   * @param types the types of token that are being tested for
   * @return `true` if the given token has any of the given types
   */
  bool matchesAny(Token token, List<TokenType> types) {
    TokenType actualType = token.type;
    for (TokenType type in types) {
      if (identical(actualType, type)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Return `true` if the current token is a valid identifier. Valid identifiers include
   * built-in identifiers (pseudo-keywords).
   *
   * @return `true` if the current token is a valid identifier
   */
  bool matchesIdentifier() => matchesIdentifier2(_currentToken);

  /**
   * Return `true` if the given token is a valid identifier. Valid identifiers include
   * built-in identifiers (pseudo-keywords).
   *
   * @return `true` if the given token is a valid identifier
   */
  bool matchesIdentifier2(Token token) => matches4(token, TokenType.IDENTIFIER) || (matches4(token, TokenType.KEYWORD) && ((token as KeywordToken)).keyword.isPseudoKeyword);

  /**
   * If the current token has the given type, then advance to the next token and return `true`
   * . Otherwise, return `false` without advancing.
   *
   * @param type the type of token that can optionally appear in the current location
   * @return `true` if the current token has the given type
   */
  bool optional(TokenType type) {
    if (matches5(type)) {
      advance();
      return true;
    }
    return false;
  }

  /**
   * Parse an additive expression.
   *
   * <pre>
   * additiveExpression ::=
   *     multiplicativeExpression (additiveOperator multiplicativeExpression)*
   *   | 'super' (additiveOperator multiplicativeExpression)+
   * </pre>
   *
   * @return the additive expression that was parsed
   */
  Expression parseAdditiveExpression() {
    Expression expression;
    if (matches(Keyword.SUPER) && _currentToken.next.type.isAdditiveOperator) {
      expression = new SuperExpression.full(andAdvance);
    } else {
      expression = parseMultiplicativeExpression();
    }
    while (_currentToken.type.isAdditiveOperator) {
      Token operator = andAdvance;
      expression = new BinaryExpression.full(expression, operator, parseMultiplicativeExpression());
    }
    return expression;
  }

  /**
   * Parse an annotation.
   *
   * <pre>
   * annotation ::=
   *     '@' qualified ('.' identifier)? arguments?
   * </pre>
   *
   * @return the annotation that was parsed
   */
  Annotation parseAnnotation() {
    Token atSign = expect2(TokenType.AT);
    Identifier name = parsePrefixedIdentifier();
    Token period = null;
    SimpleIdentifier constructorName = null;
    if (matches5(TokenType.PERIOD)) {
      period = andAdvance;
      constructorName = parseSimpleIdentifier();
    }
    ArgumentList arguments = null;
    if (matches5(TokenType.OPEN_PAREN)) {
      arguments = parseArgumentList();
    }
    return new Annotation.full(atSign, name, period, constructorName, arguments);
  }

  /**
   * Parse an argument.
   *
   * <pre>
   * argument ::=
   *     namedArgument
   *   | expression
   *
   * namedArgument ::=
   *     label expression
   * </pre>
   *
   * @return the argument that was parsed
   */
  Expression parseArgument() {
    if (matchesIdentifier() && matches4(peek(), TokenType.COLON)) {
      SimpleIdentifier label = new SimpleIdentifier.full(andAdvance);
      Label name = new Label.full(label, andAdvance);
      return new NamedExpression.full(name, parseExpression2());
    } else {
      return parseExpression2();
    }
  }

  /**
   * Parse an argument definition test.
   *
   * <pre>
   * argumentDefinitionTest ::=
   *     '?' identifier
   * </pre>
   *
   * @return the argument definition test that was parsed
   */
  ArgumentDefinitionTest parseArgumentDefinitionTest() {
    Token question = expect2(TokenType.QUESTION);
    SimpleIdentifier identifier = parseSimpleIdentifier();
    reportError8(ParserErrorCode.DEPRECATED_ARGUMENT_DEFINITION_TEST, question, []);
    return new ArgumentDefinitionTest.full(question, identifier);
  }

  /**
   * Parse a list of arguments.
   *
   * <pre>
   * arguments ::=
   *     '(' argumentList? ')'
   *
   * argumentList ::=
   *     namedArgument (',' namedArgument)*
   *   | expressionList (',' namedArgument)*
   * </pre>
   *
   * @return the argument list that was parsed
   */
  ArgumentList parseArgumentList() {
    Token leftParenthesis = expect2(TokenType.OPEN_PAREN);
    List<Expression> arguments = new List<Expression>();
    if (matches5(TokenType.CLOSE_PAREN)) {
      return new ArgumentList.full(leftParenthesis, arguments, andAdvance);
    }
    Expression argument = parseArgument();
    arguments.add(argument);
    bool foundNamedArgument = argument is NamedExpression;
    bool generatedError = false;
    while (optional(TokenType.COMMA)) {
      argument = parseArgument();
      arguments.add(argument);
      if (foundNamedArgument) {
        if (!generatedError && argument is! NamedExpression) {
          reportError7(ParserErrorCode.POSITIONAL_AFTER_NAMED_ARGUMENT, []);
          generatedError = true;
        }
      } else if (argument is NamedExpression) {
        foundNamedArgument = true;
      }
    }
    Token rightParenthesis = expect2(TokenType.CLOSE_PAREN);
    return new ArgumentList.full(leftParenthesis, arguments, rightParenthesis);
  }

  /**
   * Parse an assert statement.
   *
   * <pre>
   * assertStatement ::=
   *     'assert' '(' conditionalExpression ')' ';'
   * </pre>
   *
   * @return the assert statement
   */
  AssertStatement parseAssertStatement() {
    Token keyword = expect(Keyword.ASSERT);
    Token leftParen = expect2(TokenType.OPEN_PAREN);
    Expression expression = parseConditionalExpression();
    Token rightParen = expect2(TokenType.CLOSE_PAREN);
    Token semicolon = expect2(TokenType.SEMICOLON);
    return new AssertStatement.full(keyword, leftParen, expression, rightParen, semicolon);
  }

  /**
   * Parse an assignable expression.
   *
   * <pre>
   * assignableExpression ::=
   *     primary (arguments* assignableSelector)+
   *   | 'super' assignableSelector
   *   | identifier
   * </pre>
   *
   * @param primaryAllowed `true` if the expression is allowed to be a primary without any
   *          assignable selector
   * @return the assignable expression that was parsed
   */
  Expression parseAssignableExpression(bool primaryAllowed) {
    if (matches(Keyword.SUPER)) {
      return parseAssignableSelector(new SuperExpression.full(andAdvance), false);
    }
    Expression expression = parsePrimaryExpression();
    bool isOptional = primaryAllowed || expression is SimpleIdentifier;
    while (true) {
      while (matches5(TokenType.OPEN_PAREN)) {
        ArgumentList argumentList = parseArgumentList();
        if (expression is SimpleIdentifier) {
          expression = new MethodInvocation.full(null, null, (expression as SimpleIdentifier), argumentList);
        } else if (expression is PrefixedIdentifier) {
          PrefixedIdentifier identifier = expression as PrefixedIdentifier;
          expression = new MethodInvocation.full(identifier.prefix, identifier.period, identifier.identifier, argumentList);
        } else if (expression is PropertyAccess) {
          PropertyAccess access = expression as PropertyAccess;
          expression = new MethodInvocation.full(access.target, access.operator, access.propertyName, argumentList);
        } else {
          expression = new FunctionExpressionInvocation.full(expression, argumentList);
        }
        if (!primaryAllowed) {
          isOptional = false;
        }
      }
      Expression selectorExpression = parseAssignableSelector(expression, isOptional || (expression is PrefixedIdentifier));
      if (identical(selectorExpression, expression)) {
        if (!isOptional && (expression is PrefixedIdentifier)) {
          PrefixedIdentifier identifier = expression as PrefixedIdentifier;
          expression = new PropertyAccess.full(identifier.prefix, identifier.period, identifier.identifier);
        }
        return expression;
      }
      expression = selectorExpression;
      isOptional = true;
    }
  }

  /**
   * Parse an assignable selector.
   *
   * <pre>
   * assignableSelector ::=
   *     '[' expression ']'
   *   | '.' identifier
   * </pre>
   *
   * @param prefix the expression preceding the selector
   * @param optional `true` if the selector is optional
   * @return the assignable selector that was parsed
   */
  Expression parseAssignableSelector(Expression prefix, bool optional) {
    if (matches5(TokenType.OPEN_SQUARE_BRACKET)) {
      Token leftBracket = andAdvance;
      Expression index = parseExpression2();
      Token rightBracket = expect2(TokenType.CLOSE_SQUARE_BRACKET);
      return new IndexExpression.forTarget_full(prefix, leftBracket, index, rightBracket);
    } else if (matches5(TokenType.PERIOD)) {
      Token period = andAdvance;
      return new PropertyAccess.full(prefix, period, parseSimpleIdentifier());
    } else {
      if (!optional) {
        reportError7(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, []);
      }
      return prefix;
    }
  }

  /**
   * Parse a bitwise and expression.
   *
   * <pre>
   * bitwiseAndExpression ::=
   *     equalityExpression ('&' equalityExpression)*
   *   | 'super' ('&' equalityExpression)+
   * </pre>
   *
   * @return the bitwise and expression that was parsed
   */
  Expression parseBitwiseAndExpression() {
    Expression expression;
    if (matches(Keyword.SUPER) && matches4(peek(), TokenType.AMPERSAND)) {
      expression = new SuperExpression.full(andAdvance);
    } else {
      expression = parseEqualityExpression();
    }
    while (matches5(TokenType.AMPERSAND)) {
      Token operator = andAdvance;
      expression = new BinaryExpression.full(expression, operator, parseEqualityExpression());
    }
    return expression;
  }

  /**
   * Parse a bitwise or expression.
   *
   * <pre>
   * bitwiseOrExpression ::=
   *     bitwiseXorExpression ('|' bitwiseXorExpression)*
   *   | 'super' ('|' bitwiseXorExpression)+
   * </pre>
   *
   * @return the bitwise or expression that was parsed
   */
  Expression parseBitwiseOrExpression() {
    Expression expression;
    if (matches(Keyword.SUPER) && matches4(peek(), TokenType.BAR)) {
      expression = new SuperExpression.full(andAdvance);
    } else {
      expression = parseBitwiseXorExpression();
    }
    while (matches5(TokenType.BAR)) {
      Token operator = andAdvance;
      expression = new BinaryExpression.full(expression, operator, parseBitwiseXorExpression());
    }
    return expression;
  }

  /**
   * Parse a bitwise exclusive-or expression.
   *
   * <pre>
   * bitwiseXorExpression ::=
   *     bitwiseAndExpression ('^' bitwiseAndExpression)*
   *   | 'super' ('^' bitwiseAndExpression)+
   * </pre>
   *
   * @return the bitwise exclusive-or expression that was parsed
   */
  Expression parseBitwiseXorExpression() {
    Expression expression;
    if (matches(Keyword.SUPER) && matches4(peek(), TokenType.CARET)) {
      expression = new SuperExpression.full(andAdvance);
    } else {
      expression = parseBitwiseAndExpression();
    }
    while (matches5(TokenType.CARET)) {
      Token operator = andAdvance;
      expression = new BinaryExpression.full(expression, operator, parseBitwiseAndExpression());
    }
    return expression;
  }

  /**
   * Parse a block.
   *
   * <pre>
   * block ::=
   *     '{' statements '}'
   * </pre>
   *
   * @return the block that was parsed
   */
  Block parseBlock() {
    Token leftBracket = expect2(TokenType.OPEN_CURLY_BRACKET);
    List<Statement> statements = new List<Statement>();
    Token statementStart = _currentToken;
    while (!matches5(TokenType.EOF) && !matches5(TokenType.CLOSE_CURLY_BRACKET)) {
      Statement statement = parseStatement2();
      if (statement != null) {
        statements.add(statement);
      }
      if (identical(_currentToken, statementStart)) {
        reportError8(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken, [_currentToken.lexeme]);
        advance();
      }
      statementStart = _currentToken;
    }
    Token rightBracket = expect2(TokenType.CLOSE_CURLY_BRACKET);
    return new Block.full(leftBracket, statements, rightBracket);
  }

  /**
   * Parse a break statement.
   *
   * <pre>
   * breakStatement ::=
   *     'break' identifier? ';'
   * </pre>
   *
   * @return the break statement that was parsed
   */
  Statement parseBreakStatement() {
    Token breakKeyword = expect(Keyword.BREAK);
    SimpleIdentifier label = null;
    if (matchesIdentifier()) {
      label = parseSimpleIdentifier();
    }
    if (!_inLoop && !_inSwitch && label == null) {
      reportError8(ParserErrorCode.BREAK_OUTSIDE_OF_LOOP, breakKeyword, []);
    }
    Token semicolon = expect2(TokenType.SEMICOLON);
    return new BreakStatement.full(breakKeyword, label, semicolon);
  }

  /**
   * Parse a cascade section.
   *
   * <pre>
   * cascadeSection ::=
   *     '..' (cascadeSelector arguments*) (assignableSelector arguments*)* cascadeAssignment?
   *
   * cascadeSelector ::=
   *     '[' expression ']'
   *   | identifier
   *
   * cascadeAssignment ::=
   *     assignmentOperator expressionWithoutCascade
   * </pre>
   *
   * @return the expression representing the cascaded method invocation
   */
  Expression parseCascadeSection() {
    Token period = expect2(TokenType.PERIOD_PERIOD);
    Expression expression = null;
    SimpleIdentifier functionName = null;
    if (matchesIdentifier()) {
      functionName = parseSimpleIdentifier();
    } else if (identical(_currentToken.type, TokenType.OPEN_SQUARE_BRACKET)) {
      Token leftBracket = andAdvance;
      Expression index = parseExpression2();
      Token rightBracket = expect2(TokenType.CLOSE_SQUARE_BRACKET);
      expression = new IndexExpression.forCascade_full(period, leftBracket, index, rightBracket);
      period = null;
    } else {
      reportError8(ParserErrorCode.MISSING_IDENTIFIER, _currentToken, [_currentToken.lexeme]);
      functionName = createSyntheticIdentifier();
    }
    if (identical(_currentToken.type, TokenType.OPEN_PAREN)) {
      while (identical(_currentToken.type, TokenType.OPEN_PAREN)) {
        if (functionName != null) {
          expression = new MethodInvocation.full(expression, period, functionName, parseArgumentList());
          period = null;
          functionName = null;
        } else if (expression == null) {
          expression = new MethodInvocation.full(expression, period, createSyntheticIdentifier(), parseArgumentList());
        } else {
          expression = new FunctionExpressionInvocation.full(expression, parseArgumentList());
        }
      }
    } else if (functionName != null) {
      expression = new PropertyAccess.full(expression, period, functionName);
      period = null;
    }
    bool progress = true;
    while (progress) {
      progress = false;
      Expression selector = parseAssignableSelector(expression, true);
      if (selector != expression) {
        expression = selector;
        progress = true;
        while (identical(_currentToken.type, TokenType.OPEN_PAREN)) {
          expression = new FunctionExpressionInvocation.full(expression, parseArgumentList());
        }
      }
    }
    if (_currentToken.type.isAssignmentOperator) {
      Token operator = andAdvance;
      ensureAssignable(expression);
      expression = new AssignmentExpression.full(expression, operator, parseExpressionWithoutCascade());
    }
    return expression;
  }

  /**
   * Parse a class declaration.
   *
   * <pre>
   * classDeclaration ::=
   *     metadata 'abstract'? 'class' name typeParameterList? (extendsClause withClause?)? implementsClause? '{' classMembers '}'
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the member
   * @param abstractKeyword the token for the keyword 'abstract', or `null` if the keyword was
   *          not given
   * @return the class declaration that was parsed
   */
  ClassDeclaration parseClassDeclaration(CommentAndMetadata commentAndMetadata, Token abstractKeyword) {
    Token keyword = expect(Keyword.CLASS);
    SimpleIdentifier name = parseSimpleIdentifier();
    String className = name.name;
    TypeParameterList typeParameters = null;
    if (matches5(TokenType.LT)) {
      typeParameters = parseTypeParameterList();
    }
    ExtendsClause extendsClause = null;
    WithClause withClause = null;
    ImplementsClause implementsClause = null;
    bool foundClause = true;
    while (foundClause) {
      if (matches(Keyword.EXTENDS)) {
        if (extendsClause == null) {
          extendsClause = parseExtendsClause();
          if (withClause != null) {
            reportError8(ParserErrorCode.WITH_BEFORE_EXTENDS, withClause.withKeyword, []);
          } else if (implementsClause != null) {
            reportError8(ParserErrorCode.IMPLEMENTS_BEFORE_EXTENDS, implementsClause.keyword, []);
          }
        } else {
          reportError8(ParserErrorCode.MULTIPLE_EXTENDS_CLAUSES, extendsClause.keyword, []);
          parseExtendsClause();
        }
      } else if (matches(Keyword.WITH)) {
        if (withClause == null) {
          withClause = parseWithClause();
          if (implementsClause != null) {
            reportError8(ParserErrorCode.IMPLEMENTS_BEFORE_WITH, implementsClause.keyword, []);
          }
        } else {
          reportError8(ParserErrorCode.MULTIPLE_WITH_CLAUSES, withClause.withKeyword, []);
          parseWithClause();
        }
      } else if (matches(Keyword.IMPLEMENTS)) {
        if (implementsClause == null) {
          implementsClause = parseImplementsClause();
        } else {
          reportError8(ParserErrorCode.MULTIPLE_IMPLEMENTS_CLAUSES, implementsClause.keyword, []);
          parseImplementsClause();
        }
      } else {
        foundClause = false;
      }
    }
    if (withClause != null && extendsClause == null) {
      reportError8(ParserErrorCode.WITH_WITHOUT_EXTENDS, withClause.withKeyword, []);
    }
    if (matches2(_NATIVE) && matches4(peek(), TokenType.STRING)) {
      advance();
      advance();
    }
    Token leftBracket = null;
    List<ClassMember> members = null;
    Token rightBracket = null;
    if (matches5(TokenType.OPEN_CURLY_BRACKET)) {
      leftBracket = expect2(TokenType.OPEN_CURLY_BRACKET);
      members = parseClassMembers(className, getEndToken(leftBracket));
      rightBracket = expect2(TokenType.CLOSE_CURLY_BRACKET);
    } else {
      leftBracket = createSyntheticToken2(TokenType.OPEN_CURLY_BRACKET);
      rightBracket = createSyntheticToken2(TokenType.CLOSE_CURLY_BRACKET);
      reportError7(ParserErrorCode.MISSING_CLASS_BODY, []);
    }
    return new ClassDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, abstractKeyword, keyword, name, typeParameters, extendsClause, withClause, implementsClause, leftBracket, members, rightBracket);
  }

  /**
   * Parse a class member.
   *
   * <pre>
   * classMemberDefinition ::=
   *     declaration ';'
   *   | methodSignature functionBody
   * </pre>
   *
   * @param className the name of the class containing the member being parsed
   * @return the class member that was parsed, or `null` if what was found was not a valid
   *         class member
   */
  ClassMember parseClassMember(String className) {
    CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
    Modifiers modifiers = parseModifiers();
    if (matches(Keyword.VOID)) {
      TypeName returnType = parseReturnType();
      if (matches(Keyword.GET) && matchesIdentifier2(peek())) {
        validateModifiersForGetterOrSetterOrMethod(modifiers);
        return parseGetter(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, returnType);
      } else if (matches(Keyword.SET) && matchesIdentifier2(peek())) {
        validateModifiersForGetterOrSetterOrMethod(modifiers);
        return parseSetter(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, returnType);
      } else if (matches(Keyword.OPERATOR) && isOperator(peek())) {
        validateModifiersForOperator(modifiers);
        return parseOperator(commentAndMetadata, modifiers.externalKeyword, returnType);
      } else if (matchesIdentifier() && matchesAny(peek(), [TokenType.OPEN_PAREN, TokenType.OPEN_CURLY_BRACKET, TokenType.FUNCTION])) {
        validateModifiersForGetterOrSetterOrMethod(modifiers);
        return parseMethodDeclaration(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, returnType);
      } else {
        if (matchesIdentifier()) {
          if (matchesAny(peek(), [TokenType.EQ, TokenType.COMMA, TokenType.SEMICOLON])) {
            reportError(ParserErrorCode.VOID_VARIABLE, returnType, []);
            return parseInitializedIdentifierList(commentAndMetadata, modifiers.staticKeyword, validateModifiersForField(modifiers), returnType);
          }
        }
        if (isOperator(peek())) {
          validateModifiersForOperator(modifiers);
          return parseOperator(commentAndMetadata, modifiers.externalKeyword, returnType);
        }
        reportError8(ParserErrorCode.EXPECTED_EXECUTABLE, _currentToken, []);
        return null;
      }
    } else if (matches(Keyword.GET) && matchesIdentifier2(peek())) {
      validateModifiersForGetterOrSetterOrMethod(modifiers);
      return parseGetter(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, null);
    } else if (matches(Keyword.SET) && matchesIdentifier2(peek())) {
      validateModifiersForGetterOrSetterOrMethod(modifiers);
      return parseSetter(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, null);
    } else if (matches(Keyword.OPERATOR) && isOperator(peek())) {
      validateModifiersForOperator(modifiers);
      return parseOperator(commentAndMetadata, modifiers.externalKeyword, null);
    } else if (!matchesIdentifier()) {
      if (isOperator(peek())) {
        validateModifiersForOperator(modifiers);
        return parseOperator(commentAndMetadata, modifiers.externalKeyword, null);
      }
      reportError8(ParserErrorCode.EXPECTED_CLASS_MEMBER, _currentToken, []);
      return null;
    } else if (matches4(peek(), TokenType.PERIOD) && matchesIdentifier2(peek2(2)) && matches4(peek2(3), TokenType.OPEN_PAREN)) {
      return parseConstructor(commentAndMetadata, modifiers.externalKeyword, validateModifiersForConstructor(modifiers), modifiers.factoryKeyword, parseSimpleIdentifier(), andAdvance, parseSimpleIdentifier(), parseFormalParameterList());
    } else if (matches4(peek(), TokenType.OPEN_PAREN)) {
      SimpleIdentifier methodName = parseSimpleIdentifier();
      FormalParameterList parameters = parseFormalParameterList();
      if (matches5(TokenType.COLON) || modifiers.factoryKeyword != null || methodName.name == className) {
        return parseConstructor(commentAndMetadata, modifiers.externalKeyword, validateModifiersForConstructor(modifiers), modifiers.factoryKeyword, methodName, null, null, parameters);
      }
      validateModifiersForGetterOrSetterOrMethod(modifiers);
      validateFormalParameterList(parameters);
      return parseMethodDeclaration2(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, null, methodName, parameters);
    } else if (matchesAny(peek(), [TokenType.EQ, TokenType.COMMA, TokenType.SEMICOLON])) {
      if (modifiers.constKeyword == null && modifiers.finalKeyword == null && modifiers.varKeyword == null) {
        reportError7(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, []);
      }
      return parseInitializedIdentifierList(commentAndMetadata, modifiers.staticKeyword, validateModifiersForField(modifiers), null);
    }
    TypeName type = parseTypeName();
    if (matches(Keyword.GET) && matchesIdentifier2(peek())) {
      validateModifiersForGetterOrSetterOrMethod(modifiers);
      return parseGetter(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, type);
    } else if (matches(Keyword.SET) && matchesIdentifier2(peek())) {
      validateModifiersForGetterOrSetterOrMethod(modifiers);
      return parseSetter(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, type);
    } else if (matches(Keyword.OPERATOR) && isOperator(peek())) {
      validateModifiersForOperator(modifiers);
      return parseOperator(commentAndMetadata, modifiers.externalKeyword, type);
    } else if (!matchesIdentifier()) {
      if (matches5(TokenType.CLOSE_CURLY_BRACKET)) {
        return parseInitializedIdentifierList(commentAndMetadata, modifiers.staticKeyword, validateModifiersForField(modifiers), type);
      }
      if (isOperator(peek())) {
        validateModifiersForOperator(modifiers);
        return parseOperator(commentAndMetadata, modifiers.externalKeyword, type);
      }
      reportError8(ParserErrorCode.EXPECTED_CLASS_MEMBER, _currentToken, []);
      return null;
    } else if (matches4(peek(), TokenType.OPEN_PAREN)) {
      SimpleIdentifier methodName = parseSimpleIdentifier();
      FormalParameterList parameters = parseFormalParameterList();
      if (methodName.name == className) {
        reportError(ParserErrorCode.CONSTRUCTOR_WITH_RETURN_TYPE, type, []);
        return parseConstructor(commentAndMetadata, modifiers.externalKeyword, validateModifiersForConstructor(modifiers), modifiers.factoryKeyword, methodName, null, null, parameters);
      }
      validateModifiersForGetterOrSetterOrMethod(modifiers);
      validateFormalParameterList(parameters);
      return parseMethodDeclaration2(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, type, methodName, parameters);
    }
    return parseInitializedIdentifierList(commentAndMetadata, modifiers.staticKeyword, validateModifiersForField(modifiers), type);
  }

  /**
   * Parse a list of class members.
   *
   * <pre>
   * classMembers ::=
   *     (metadata memberDefinition)*
   * </pre>
   *
   * @param className the name of the class whose members are being parsed
   * @param closingBracket the closing bracket for the class, or `null` if the closing bracket
   *          is missing
   * @return the list of class members that were parsed
   */
  List<ClassMember> parseClassMembers(String className, Token closingBracket) {
    List<ClassMember> members = new List<ClassMember>();
    Token memberStart = _currentToken;
    while (!matches5(TokenType.EOF) && !matches5(TokenType.CLOSE_CURLY_BRACKET) && (closingBracket != null || (!matches(Keyword.CLASS) && !matches(Keyword.TYPEDEF)))) {
      if (matches5(TokenType.SEMICOLON)) {
        reportError8(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken, [_currentToken.lexeme]);
        advance();
      } else {
        ClassMember member = parseClassMember(className);
        if (member != null) {
          members.add(member);
        }
      }
      if (identical(_currentToken, memberStart)) {
        reportError8(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken, [_currentToken.lexeme]);
        advance();
      }
      memberStart = _currentToken;
    }
    return members;
  }

  /**
   * Parse a class type alias.
   *
   * <pre>
   * classTypeAlias ::=
   *     identifier typeParameters? '=' 'abstract'? mixinApplication
   *
   * mixinApplication ::=
   *     type withClause implementsClause? ';'
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the member
   * @param keyword the token representing the 'typedef' keyword
   * @return the class type alias that was parsed
   */
  ClassTypeAlias parseClassTypeAlias(CommentAndMetadata commentAndMetadata, Token keyword) {
    SimpleIdentifier className = parseSimpleIdentifier();
    TypeParameterList typeParameters = null;
    if (matches5(TokenType.LT)) {
      typeParameters = parseTypeParameterList();
    }
    Token equals = expect2(TokenType.EQ);
    Token abstractKeyword = null;
    if (matches(Keyword.ABSTRACT)) {
      abstractKeyword = andAdvance;
    }
    TypeName superclass = parseTypeName();
    WithClause withClause = null;
    if (matches(Keyword.WITH)) {
      withClause = parseWithClause();
    }
    ImplementsClause implementsClause = null;
    if (matches(Keyword.IMPLEMENTS)) {
      implementsClause = parseImplementsClause();
    }
    Token semicolon;
    if (matches5(TokenType.SEMICOLON)) {
      semicolon = andAdvance;
    } else {
      if (matches5(TokenType.OPEN_CURLY_BRACKET)) {
        reportError7(ParserErrorCode.EXPECTED_TOKEN, [TokenType.SEMICOLON.lexeme]);
        Token leftBracket = andAdvance;
        parseClassMembers(className.name, getEndToken(leftBracket));
        expect2(TokenType.CLOSE_CURLY_BRACKET);
      } else {
        reportError8(ParserErrorCode.EXPECTED_TOKEN, _currentToken.previous, [TokenType.SEMICOLON.lexeme]);
      }
      semicolon = createSyntheticToken2(TokenType.SEMICOLON);
    }
    return new ClassTypeAlias.full(commentAndMetadata.comment, commentAndMetadata.metadata, keyword, className, typeParameters, equals, abstractKeyword, superclass, withClause, implementsClause, semicolon);
  }

  /**
   * Parse a list of combinators in a directive.
   *
   * <pre>
   * combinator ::=
   *     'show' identifier (',' identifier)*
   *   | 'hide' identifier (',' identifier)*
   * </pre>
   *
   * @return the combinators that were parsed
   */
  List<Combinator> parseCombinators() {
    List<Combinator> combinators = new List<Combinator>();
    while (matches2(_SHOW) || matches2(_HIDE)) {
      Token keyword = expect2(TokenType.IDENTIFIER);
      if (keyword.lexeme == _SHOW) {
        List<SimpleIdentifier> shownNames = parseIdentifierList();
        combinators.add(new ShowCombinator.full(keyword, shownNames));
      } else {
        List<SimpleIdentifier> hiddenNames = parseIdentifierList();
        combinators.add(new HideCombinator.full(keyword, hiddenNames));
      }
    }
    return combinators;
  }

  /**
   * Parse the documentation comment and metadata preceeding a declaration. This method allows any
   * number of documentation comments to occur before, after or between the metadata, but only
   * returns the last (right-most) documentation comment that is found.
   *
   * <pre>
   * metadata ::=
   *     annotation*
   * </pre>
   *
   * @return the documentation comment and metadata that were parsed
   */
  CommentAndMetadata parseCommentAndMetadata() {
    Comment comment = parseDocumentationComment();
    List<Annotation> metadata = new List<Annotation>();
    while (matches5(TokenType.AT)) {
      metadata.add(parseAnnotation());
      Comment optionalComment = parseDocumentationComment();
      if (optionalComment != null) {
        comment = optionalComment;
      }
    }
    return new CommentAndMetadata(comment, metadata);
  }

  /**
   * Parse a comment reference from the source between square brackets.
   *
   * <pre>
   * commentReference ::=
   *     'new'? prefixedIdentifier
   * </pre>
   *
   * @param referenceSource the source occurring between the square brackets within a documentation
   *          comment
   * @param sourceOffset the offset of the first character of the reference source
   * @return the comment reference that was parsed, or `null` if no reference could be found
   */
  CommentReference parseCommentReference(String referenceSource, int sourceOffset) {
    if (referenceSource.length == 0) {
      return null;
    }
    try {
      List<bool> errorFound = [false];
      AnalysisErrorListener listener = new AnalysisErrorListener_12(errorFound);
      StringScanner scanner = new StringScanner(null, referenceSource, listener);
      scanner.setSourceStart(1, 1, sourceOffset);
      Token firstToken = scanner.tokenize();
      if (errorFound[0]) {
        return null;
      }
      Token newKeyword = null;
      if (matches3(firstToken, Keyword.NEW)) {
        newKeyword = firstToken;
        firstToken = firstToken.next;
      }
      if (matchesIdentifier2(firstToken)) {
        Token secondToken = firstToken.next;
        Token thirdToken = secondToken.next;
        Token nextToken;
        Identifier identifier;
        if (matches4(secondToken, TokenType.PERIOD) && matchesIdentifier2(thirdToken)) {
          identifier = new PrefixedIdentifier.full(new SimpleIdentifier.full(firstToken), secondToken, new SimpleIdentifier.full(thirdToken));
          nextToken = thirdToken.next;
        } else {
          identifier = new SimpleIdentifier.full(firstToken);
          nextToken = firstToken.next;
        }
        if (nextToken.type != TokenType.EOF) {
          return null;
        }
        return new CommentReference.full(newKeyword, identifier);
      } else if (matches3(firstToken, Keyword.THIS) || matches3(firstToken, Keyword.NULL) || matches3(firstToken, Keyword.TRUE) || matches3(firstToken, Keyword.FALSE)) {
        return null;
      }
    } catch (exception) {
    }
    return null;
  }

  /**
   * Parse all of the comment references occurring in the given array of documentation comments.
   *
   * <pre>
   * commentReference ::=
   *     '[' 'new'? qualified ']' libraryReference?
   *
   * libraryReference ::=
   *      '(' stringLiteral ')'
   * </pre>
   *
   * @param tokens the comment tokens representing the documentation comments to be parsed
   * @return the comment references that were parsed
   */
  List<CommentReference> parseCommentReferences(List<Token> tokens) {
    List<CommentReference> references = new List<CommentReference>();
    for (Token token in tokens) {
      String comment = token.lexeme;
      int length = comment.length;
      List<List<int>> codeBlockRanges = getCodeBlockRanges(comment);
      int leftIndex = comment.indexOf('[');
      while (leftIndex >= 0 && leftIndex + 1 < length) {
        List<int> range = findRange(codeBlockRanges, leftIndex);
        if (range == null) {
          int rightIndex = JavaString.indexOf(comment, ']', leftIndex);
          if (rightIndex >= 0) {
            int firstChar = comment.codeUnitAt(leftIndex + 1);
            if (firstChar != 0x27 && firstChar != 0x22) {
              if (isLinkText(comment, rightIndex)) {
              } else {
                CommentReference reference = parseCommentReference(comment.substring(leftIndex + 1, rightIndex), token.offset + leftIndex + 1);
                if (reference != null) {
                  references.add(reference);
                }
              }
            }
          } else {
            rightIndex = leftIndex + 1;
          }
          leftIndex = JavaString.indexOf(comment, '[', rightIndex);
        } else {
          leftIndex = JavaString.indexOf(comment, '[', range[1] + 1);
        }
      }
    }
    return references;
  }

  /**
   * Parse a compilation unit.
   *
   * Specified:
   *
   * <pre>
   * compilationUnit ::=
   *     scriptTag? directive* topLevelDeclaration*
   * </pre>
   * Actual:
   *
   * <pre>
   * compilationUnit ::=
   *     scriptTag? topLevelElement*
   *
   * topLevelElement ::=
   *     directive
   *   | topLevelDeclaration
   * </pre>
   *
   * @return the compilation unit that was parsed
   */
  CompilationUnit parseCompilationUnit2() {
    Token firstToken = _currentToken;
    ScriptTag scriptTag = null;
    if (matches5(TokenType.SCRIPT_TAG)) {
      scriptTag = new ScriptTag.full(andAdvance);
    }
    bool libraryDirectiveFound = false;
    bool partOfDirectiveFound = false;
    bool partDirectiveFound = false;
    bool directiveFoundAfterDeclaration = false;
    List<Directive> directives = new List<Directive>();
    List<CompilationUnitMember> declarations = new List<CompilationUnitMember>();
    Token memberStart = _currentToken;
    while (!matches5(TokenType.EOF)) {
      CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
      if ((matches(Keyword.IMPORT) || matches(Keyword.EXPORT) || matches(Keyword.LIBRARY) || matches(Keyword.PART)) && !matches4(peek(), TokenType.PERIOD) && !matches4(peek(), TokenType.LT)) {
        Directive directive = parseDirective(commentAndMetadata);
        if (declarations.length > 0 && !directiveFoundAfterDeclaration) {
          reportError7(ParserErrorCode.DIRECTIVE_AFTER_DECLARATION, []);
          directiveFoundAfterDeclaration = true;
        }
        if (directive is LibraryDirective) {
          if (libraryDirectiveFound) {
            reportError7(ParserErrorCode.MULTIPLE_LIBRARY_DIRECTIVES, []);
          } else {
            if (directives.length > 0) {
              reportError7(ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST, []);
            }
            libraryDirectiveFound = true;
          }
        } else if (directive is PartDirective) {
          partDirectiveFound = true;
        } else if (partDirectiveFound) {
          if (directive is ExportDirective) {
            reportError8(ParserErrorCode.EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE, ((directive as NamespaceDirective)).keyword, []);
          } else if (directive is ImportDirective) {
            reportError8(ParserErrorCode.IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE, ((directive as NamespaceDirective)).keyword, []);
          }
        }
        if (directive is PartOfDirective) {
          if (partOfDirectiveFound) {
            reportError7(ParserErrorCode.MULTIPLE_PART_OF_DIRECTIVES, []);
          } else {
            for (Directive preceedingDirective in directives) {
              reportError8(ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART, preceedingDirective.keyword, []);
            }
            partOfDirectiveFound = true;
          }
        } else {
          if (partOfDirectiveFound) {
            reportError8(ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART, directive.keyword, []);
          }
        }
        directives.add(directive);
      } else if (matches5(TokenType.SEMICOLON)) {
        reportError8(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken, [_currentToken.lexeme]);
        advance();
      } else {
        CompilationUnitMember member = parseCompilationUnitMember(commentAndMetadata);
        if (member != null) {
          declarations.add(member);
        }
      }
      if (identical(_currentToken, memberStart)) {
        reportError8(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken, [_currentToken.lexeme]);
        advance();
        while (!matches5(TokenType.EOF) && !couldBeStartOfCompilationUnitMember()) {
          advance();
        }
      }
      memberStart = _currentToken;
    }
    return new CompilationUnit.full(firstToken, scriptTag, directives, declarations, _currentToken);
  }

  /**
   * Parse a compilation unit member.
   *
   * <pre>
   * compilationUnitMember ::=
   *     classDefinition
   *   | functionTypeAlias
   *   | external functionSignature
   *   | external getterSignature
   *   | external setterSignature
   *   | functionSignature functionBody
   *   | returnType? getOrSet identifier formalParameterList functionBody
   *   | (final | const) type? staticFinalDeclarationList ';'
   *   | variableDeclaration ';'
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the member
   * @return the compilation unit member that was parsed, or `null` if what was parsed could
   *         not be represented as a compilation unit member
   */
  CompilationUnitMember parseCompilationUnitMember(CommentAndMetadata commentAndMetadata) {
    Modifiers modifiers = parseModifiers();
    if (matches(Keyword.CLASS)) {
      return parseClassDeclaration(commentAndMetadata, validateModifiersForClass(modifiers));
    } else if (matches(Keyword.TYPEDEF) && !matches4(peek(), TokenType.PERIOD) && !matches4(peek(), TokenType.LT)) {
      validateModifiersForTypedef(modifiers);
      return parseTypeAlias(commentAndMetadata);
    }
    if (matches(Keyword.VOID)) {
      TypeName returnType = parseReturnType();
      if ((matches(Keyword.GET) || matches(Keyword.SET)) && matchesIdentifier2(peek())) {
        validateModifiersForTopLevelFunction(modifiers);
        return parseFunctionDeclaration(commentAndMetadata, modifiers.externalKeyword, null);
      } else if (matches(Keyword.OPERATOR) && isOperator(peek())) {
        reportError8(ParserErrorCode.TOP_LEVEL_OPERATOR, _currentToken, []);
        return convertToFunctionDeclaration(parseOperator(commentAndMetadata, modifiers.externalKeyword, returnType));
      } else if (matchesIdentifier() && matchesAny(peek(), [TokenType.OPEN_PAREN, TokenType.OPEN_CURLY_BRACKET, TokenType.FUNCTION])) {
        validateModifiersForTopLevelFunction(modifiers);
        return parseFunctionDeclaration(commentAndMetadata, modifiers.externalKeyword, returnType);
      } else {
        if (matchesIdentifier()) {
          if (matchesAny(peek(), [TokenType.EQ, TokenType.COMMA, TokenType.SEMICOLON])) {
            reportError(ParserErrorCode.VOID_VARIABLE, returnType, []);
            return new TopLevelVariableDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, parseVariableDeclarationList2(null, validateModifiersForTopLevelVariable(modifiers), null), expect2(TokenType.SEMICOLON));
          }
        }
        reportError8(ParserErrorCode.EXPECTED_EXECUTABLE, _currentToken, []);
        return null;
      }
    } else if ((matches(Keyword.GET) || matches(Keyword.SET)) && matchesIdentifier2(peek())) {
      validateModifiersForTopLevelFunction(modifiers);
      return parseFunctionDeclaration(commentAndMetadata, modifiers.externalKeyword, null);
    } else if (matches(Keyword.OPERATOR) && isOperator(peek())) {
      reportError8(ParserErrorCode.TOP_LEVEL_OPERATOR, _currentToken, []);
      return convertToFunctionDeclaration(parseOperator(commentAndMetadata, modifiers.externalKeyword, null));
    } else if (!matchesIdentifier()) {
      reportError8(ParserErrorCode.EXPECTED_EXECUTABLE, _currentToken, []);
      return null;
    } else if (matches4(peek(), TokenType.OPEN_PAREN)) {
      validateModifiersForTopLevelFunction(modifiers);
      return parseFunctionDeclaration(commentAndMetadata, modifiers.externalKeyword, null);
    } else if (matchesAny(peek(), [TokenType.EQ, TokenType.COMMA, TokenType.SEMICOLON])) {
      if (modifiers.constKeyword == null && modifiers.finalKeyword == null && modifiers.varKeyword == null) {
        reportError7(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, []);
      }
      return new TopLevelVariableDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, parseVariableDeclarationList2(null, validateModifiersForTopLevelVariable(modifiers), null), expect2(TokenType.SEMICOLON));
    }
    TypeName returnType = parseReturnType();
    if (matches(Keyword.GET) || matches(Keyword.SET)) {
      validateModifiersForTopLevelFunction(modifiers);
      return parseFunctionDeclaration(commentAndMetadata, modifiers.externalKeyword, returnType);
    } else if (matches(Keyword.OPERATOR) && isOperator(peek())) {
      reportError8(ParserErrorCode.TOP_LEVEL_OPERATOR, _currentToken, []);
      return convertToFunctionDeclaration(parseOperator(commentAndMetadata, modifiers.externalKeyword, returnType));
    } else if (matches5(TokenType.AT)) {
      return new TopLevelVariableDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, parseVariableDeclarationList2(null, validateModifiersForTopLevelVariable(modifiers), returnType), expect2(TokenType.SEMICOLON));
    } else if (!matchesIdentifier()) {
      reportError8(ParserErrorCode.EXPECTED_EXECUTABLE, _currentToken, []);
      Token semicolon;
      if (matches5(TokenType.SEMICOLON)) {
        semicolon = andAdvance;
      } else {
        semicolon = createSyntheticToken2(TokenType.SEMICOLON);
      }
      List<VariableDeclaration> variables = new List<VariableDeclaration>();
      variables.add(new VariableDeclaration.full(null, null, createSyntheticIdentifier(), null, null));
      return new TopLevelVariableDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, new VariableDeclarationList.full(null, null, null, returnType, variables), semicolon);
    }
    if (matchesAny(peek(), [TokenType.OPEN_PAREN, TokenType.FUNCTION, TokenType.OPEN_CURLY_BRACKET])) {
      validateModifiersForTopLevelFunction(modifiers);
      return parseFunctionDeclaration(commentAndMetadata, modifiers.externalKeyword, returnType);
    }
    return new TopLevelVariableDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, parseVariableDeclarationList2(null, validateModifiersForTopLevelVariable(modifiers), returnType), expect2(TokenType.SEMICOLON));
  }

  /**
   * Parse a conditional expression.
   *
   * <pre>
   * conditionalExpression ::=
   *     logicalOrExpression ('?' expressionWithoutCascade ':' expressionWithoutCascade)?
   * </pre>
   *
   * @return the conditional expression that was parsed
   */
  Expression parseConditionalExpression() {
    Expression condition = parseLogicalOrExpression();
    if (!matches5(TokenType.QUESTION)) {
      return condition;
    }
    Token question = andAdvance;
    Expression thenExpression = parseExpressionWithoutCascade();
    Token colon = expect2(TokenType.COLON);
    Expression elseExpression = parseExpressionWithoutCascade();
    return new ConditionalExpression.full(condition, question, thenExpression, colon, elseExpression);
  }

  /**
   * Parse a const expression.
   *
   * <pre>
   * constExpression ::=
   *     instanceCreationExpression
   *   | listLiteral
   *   | mapLiteral
   * </pre>
   *
   * @return the const expression that was parsed
   */
  Expression parseConstExpression() {
    Token keyword = expect(Keyword.CONST);
    if (matches5(TokenType.OPEN_SQUARE_BRACKET) || matches5(TokenType.INDEX)) {
      return parseListLiteral(keyword, null);
    } else if (matches5(TokenType.OPEN_CURLY_BRACKET)) {
      return parseMapLiteral(keyword, null);
    } else if (matches5(TokenType.LT)) {
      return parseListOrMapLiteral(keyword);
    }
    return parseInstanceCreationExpression(keyword);
  }
  ConstructorDeclaration parseConstructor(CommentAndMetadata commentAndMetadata, Token externalKeyword, Token constKeyword, Token factoryKeyword, SimpleIdentifier returnType, Token period, SimpleIdentifier name, FormalParameterList parameters) {
    bool bodyAllowed = externalKeyword == null;
    Token separator = null;
    List<ConstructorInitializer> initializers = null;
    if (matches5(TokenType.COLON)) {
      separator = andAdvance;
      initializers = new List<ConstructorInitializer>();
      do {
        if (matches(Keyword.THIS)) {
          if (matches4(peek(), TokenType.OPEN_PAREN)) {
            bodyAllowed = false;
            initializers.add(parseRedirectingConstructorInvocation());
          } else if (matches4(peek(), TokenType.PERIOD) && matches4(peek2(3), TokenType.OPEN_PAREN)) {
            bodyAllowed = false;
            initializers.add(parseRedirectingConstructorInvocation());
          } else {
            initializers.add(parseConstructorFieldInitializer());
          }
        } else if (matches(Keyword.SUPER)) {
          initializers.add(parseSuperConstructorInvocation());
        } else {
          initializers.add(parseConstructorFieldInitializer());
        }
      } while (optional(TokenType.COMMA));
    }
    ConstructorName redirectedConstructor = null;
    FunctionBody body;
    if (matches5(TokenType.EQ)) {
      separator = andAdvance;
      redirectedConstructor = parseConstructorName();
      body = new EmptyFunctionBody.full(expect2(TokenType.SEMICOLON));
    } else {
      body = parseFunctionBody(true, ParserErrorCode.MISSING_FUNCTION_BODY, false);
      if (constKeyword != null && factoryKeyword != null) {
        reportError8(ParserErrorCode.CONST_FACTORY, factoryKeyword, []);
      } else if (body is EmptyFunctionBody) {
        if (factoryKeyword != null && externalKeyword == null) {
          reportError8(ParserErrorCode.FACTORY_WITHOUT_BODY, factoryKeyword, []);
        }
      } else {
        if (constKeyword != null) {
          reportError(ParserErrorCode.CONST_CONSTRUCTOR_WITH_BODY, body, []);
        } else if (!bodyAllowed) {
          reportError(ParserErrorCode.EXTERNAL_CONSTRUCTOR_WITH_BODY, body, []);
        }
      }
    }
    return new ConstructorDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, externalKeyword, constKeyword, factoryKeyword, returnType, period, name, parameters, separator, initializers, redirectedConstructor, body);
  }

  /**
   * Parse a field initializer within a constructor.
   *
   * <pre>
   * fieldInitializer:
   *     ('this' '.')? identifier '=' conditionalExpression cascadeSection*
   * </pre>
   *
   * @return the field initializer that was parsed
   */
  ConstructorFieldInitializer parseConstructorFieldInitializer() {
    Token keyword = null;
    Token period = null;
    if (matches(Keyword.THIS)) {
      keyword = andAdvance;
      period = expect2(TokenType.PERIOD);
    }
    SimpleIdentifier fieldName = parseSimpleIdentifier();
    Token equals = expect2(TokenType.EQ);
    Expression expression = parseConditionalExpression();
    TokenType tokenType = _currentToken.type;
    if (identical(tokenType, TokenType.PERIOD_PERIOD)) {
      List<Expression> cascadeSections = new List<Expression>();
      while (identical(tokenType, TokenType.PERIOD_PERIOD)) {
        Expression section = parseCascadeSection();
        if (section != null) {
          cascadeSections.add(section);
        }
        tokenType = _currentToken.type;
      }
      expression = new CascadeExpression.full(expression, cascadeSections);
    }
    return new ConstructorFieldInitializer.full(keyword, period, fieldName, equals, expression);
  }

  /**
   * Parse the name of a constructor.
   *
   * <pre>
   * constructorName:
   *     type ('.' identifier)?
   * </pre>
   *
   * @return the constructor name that was parsed
   */
  ConstructorName parseConstructorName() {
    TypeName type = parseTypeName();
    Token period = null;
    SimpleIdentifier name = null;
    if (matches5(TokenType.PERIOD)) {
      period = andAdvance;
      name = parseSimpleIdentifier();
    }
    return new ConstructorName.full(type, period, name);
  }

  /**
   * Parse a continue statement.
   *
   * <pre>
   * continueStatement ::=
   *     'continue' identifier? ';'
   * </pre>
   *
   * @return the continue statement that was parsed
   */
  Statement parseContinueStatement() {
    Token continueKeyword = expect(Keyword.CONTINUE);
    if (!_inLoop && !_inSwitch) {
      reportError8(ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP, continueKeyword, []);
    }
    SimpleIdentifier label = null;
    if (matchesIdentifier()) {
      label = parseSimpleIdentifier();
    }
    if (_inSwitch && !_inLoop && label == null) {
      reportError8(ParserErrorCode.CONTINUE_WITHOUT_LABEL_IN_CASE, continueKeyword, []);
    }
    Token semicolon = expect2(TokenType.SEMICOLON);
    return new ContinueStatement.full(continueKeyword, label, semicolon);
  }

  /**
   * Parse a directive.
   *
   * <pre>
   * directive ::=
   *     exportDirective
   *   | libraryDirective
   *   | importDirective
   *   | partDirective
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the directive
   * @return the directive that was parsed
   */
  Directive parseDirective(CommentAndMetadata commentAndMetadata) {
    if (matches(Keyword.IMPORT)) {
      return parseImportDirective(commentAndMetadata);
    } else if (matches(Keyword.EXPORT)) {
      return parseExportDirective(commentAndMetadata);
    } else if (matches(Keyword.LIBRARY)) {
      return parseLibraryDirective(commentAndMetadata);
    } else if (matches(Keyword.PART)) {
      return parsePartDirective(commentAndMetadata);
    } else {
      throw new IllegalStateException("parseDirective invoked in an invalid state; currentToken = ${_currentToken}");
    }
  }

  /**
   * Parse a documentation comment.
   *
   * <pre>
   * documentationComment ::=
   *     multiLineComment?
   *   | singleLineComment*
   * </pre>
   *
   * @return the documentation comment that was parsed, or `null` if there was no comment
   */
  Comment parseDocumentationComment() {
    List<Token> commentTokens = new List<Token>();
    Token commentToken = _currentToken.precedingComments;
    while (commentToken != null) {
      if (identical(commentToken.type, TokenType.SINGLE_LINE_COMMENT)) {
        if (commentToken.lexeme.startsWith("///")) {
          if (commentTokens.length == 1 && commentTokens[0].lexeme.startsWith("/**")) {
            commentTokens.clear();
          }
          commentTokens.add(commentToken);
        }
      } else {
        if (commentToken.lexeme.startsWith("/**")) {
          commentTokens.clear();
          commentTokens.add(commentToken);
        }
      }
      commentToken = commentToken.next;
    }
    if (commentTokens.isEmpty) {
      return null;
    }
    List<Token> tokens = new List.from(commentTokens);
    List<CommentReference> references = parseCommentReferences(tokens);
    return Comment.createDocumentationComment2(tokens, references);
  }

  /**
   * Parse a do statement.
   *
   * <pre>
   * doStatement ::=
   *     'do' statement 'while' '(' expression ')' ';'
   * </pre>
   *
   * @return the do statement that was parsed
   */
  Statement parseDoStatement() {
    bool wasInLoop = _inLoop;
    _inLoop = true;
    try {
      Token doKeyword = expect(Keyword.DO);
      Statement body = parseStatement2();
      Token whileKeyword = expect(Keyword.WHILE);
      Token leftParenthesis = expect2(TokenType.OPEN_PAREN);
      Expression condition = parseExpression2();
      Token rightParenthesis = expect2(TokenType.CLOSE_PAREN);
      Token semicolon = expect2(TokenType.SEMICOLON);
      return new DoStatement.full(doKeyword, body, whileKeyword, leftParenthesis, condition, rightParenthesis, semicolon);
    } finally {
      _inLoop = wasInLoop;
    }
  }

  /**
   * Parse an empty statement.
   *
   * <pre>
   * emptyStatement ::=
   *     ';'
   * </pre>
   *
   * @return the empty statement that was parsed
   */
  Statement parseEmptyStatement() => new EmptyStatement.full(andAdvance);

  /**
   * Parse an equality expression.
   *
   * <pre>
   * equalityExpression ::=
   *     relationalExpression (equalityOperator relationalExpression)?
   *   | 'super' equalityOperator relationalExpression
   * </pre>
   *
   * @return the equality expression that was parsed
   */
  Expression parseEqualityExpression() {
    Expression expression;
    if (matches(Keyword.SUPER) && _currentToken.next.type.isEqualityOperator) {
      expression = new SuperExpression.full(andAdvance);
    } else {
      expression = parseRelationalExpression();
    }
    bool leftEqualityExpression = false;
    while (_currentToken.type.isEqualityOperator) {
      Token operator = andAdvance;
      if (leftEqualityExpression) {
        reportError(ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND, expression, []);
      }
      expression = new BinaryExpression.full(expression, operator, parseRelationalExpression());
      leftEqualityExpression = true;
    }
    return expression;
  }

  /**
   * Parse an export directive.
   *
   * <pre>
   * exportDirective ::=
   *     metadata 'export' stringLiteral combinator*';'
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the directive
   * @return the export directive that was parsed
   */
  ExportDirective parseExportDirective(CommentAndMetadata commentAndMetadata) {
    Token exportKeyword = expect(Keyword.EXPORT);
    StringLiteral libraryUri = parseStringLiteral();
    List<Combinator> combinators = parseCombinators();
    Token semicolon = expect2(TokenType.SEMICOLON);
    return new ExportDirective.full(commentAndMetadata.comment, commentAndMetadata.metadata, exportKeyword, libraryUri, combinators, semicolon);
  }

  /**
   * Parse an expression that does not contain any cascades.
   *
   * <pre>
   * expression ::=
   *     assignableExpression assignmentOperator expression
   *   | conditionalExpression cascadeSection*
   *   | throwExpression
   * </pre>
   *
   * @return the expression that was parsed
   */
  Expression parseExpression2() {
    if (matches(Keyword.THROW)) {
      return parseThrowExpression();
    } else if (matches(Keyword.RETHROW)) {
      return parseRethrowExpression();
    }
    Expression expression = parseConditionalExpression();
    TokenType tokenType = _currentToken.type;
    if (identical(tokenType, TokenType.PERIOD_PERIOD)) {
      List<Expression> cascadeSections = new List<Expression>();
      while (identical(tokenType, TokenType.PERIOD_PERIOD)) {
        Expression section = parseCascadeSection();
        if (section != null) {
          cascadeSections.add(section);
        }
        tokenType = _currentToken.type;
      }
      return new CascadeExpression.full(expression, cascadeSections);
    } else if (tokenType.isAssignmentOperator) {
      Token operator = andAdvance;
      ensureAssignable(expression);
      return new AssignmentExpression.full(expression, operator, parseExpression2());
    }
    return expression;
  }

  /**
   * Parse a list of expressions.
   *
   * <pre>
   * expressionList ::=
   *     expression (',' expression)*
   * </pre>
   *
   * @return the expression that was parsed
   */
  List<Expression> parseExpressionList() {
    List<Expression> expressions = new List<Expression>();
    expressions.add(parseExpression2());
    while (optional(TokenType.COMMA)) {
      expressions.add(parseExpression2());
    }
    return expressions;
  }

  /**
   * Parse an expression that does not contain any cascades.
   *
   * <pre>
   * expressionWithoutCascade ::=
   *     assignableExpression assignmentOperator expressionWithoutCascade
   *   | conditionalExpression
   *   | throwExpressionWithoutCascade
   * </pre>
   *
   * @return the expression that was parsed
   */
  Expression parseExpressionWithoutCascade() {
    if (matches(Keyword.THROW)) {
      return parseThrowExpressionWithoutCascade();
    } else if (matches(Keyword.RETHROW)) {
      return parseRethrowExpression();
    }
    Expression expression = parseConditionalExpression();
    if (_currentToken.type.isAssignmentOperator) {
      Token operator = andAdvance;
      ensureAssignable(expression);
      expression = new AssignmentExpression.full(expression, operator, parseExpressionWithoutCascade());
    }
    return expression;
  }

  /**
   * Parse a class extends clause.
   *
   * <pre>
   * classExtendsClause ::=
   *     'extends' type
   * </pre>
   *
   * @return the class extends clause that was parsed
   */
  ExtendsClause parseExtendsClause() {
    Token keyword = expect(Keyword.EXTENDS);
    TypeName superclass = parseTypeName();
    return new ExtendsClause.full(keyword, superclass);
  }

  /**
   * Parse the 'final', 'const', 'var' or type preceding a variable declaration.
   *
   * <pre>
   * finalConstVarOrType ::=
   *   | 'final' type?
   *   | 'const' type?
   *   | 'var'
   *   | type
   * </pre>
   *
   * @param optional `true` if the keyword and type are optional
   * @return the 'final', 'const', 'var' or type that was parsed
   */
  FinalConstVarOrType parseFinalConstVarOrType(bool optional) {
    Token keyword = null;
    TypeName type = null;
    if (matches(Keyword.FINAL) || matches(Keyword.CONST)) {
      keyword = andAdvance;
      if (matchesIdentifier2(peek()) || matches4(peek(), TokenType.LT) || matches3(peek(), Keyword.THIS) || (matches4(peek(), TokenType.PERIOD) && matchesIdentifier2(peek2(2)) && (matchesIdentifier2(peek2(3)) || matches4(peek2(3), TokenType.LT) || matches3(peek2(3), Keyword.THIS)))) {
        type = parseTypeName();
      }
    } else if (matches(Keyword.VAR)) {
      keyword = andAdvance;
    } else {
      if (matchesIdentifier2(peek()) || matches4(peek(), TokenType.LT) || matches3(peek(), Keyword.THIS) || (matches4(peek(), TokenType.PERIOD) && matchesIdentifier2(peek2(2)) && (matchesIdentifier2(peek2(3)) || matches4(peek2(3), TokenType.LT) || matches3(peek2(3), Keyword.THIS)))) {
        type = parseReturnType();
      } else if (!optional) {
        reportError7(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, []);
      }
    }
    return new FinalConstVarOrType(keyword, type);
  }

  /**
   * Parse a formal parameter. At most one of `isOptional` and `isNamed` can be
   * `true`.
   *
   * <pre>
   * defaultFormalParameter ::=
   *     normalFormalParameter ('=' expression)?
   *
   * defaultNamedParameter ::=
   *     normalFormalParameter (':' expression)?
   * </pre>
   *
   * @param kind the kind of parameter being expected based on the presence or absence of group
   *          delimiters
   * @return the formal parameter that was parsed
   */
  FormalParameter parseFormalParameter(ParameterKind kind) {
    NormalFormalParameter parameter = parseNormalFormalParameter();
    if (matches5(TokenType.EQ)) {
      Token seperator = andAdvance;
      Expression defaultValue = parseExpression2();
      if (identical(kind, ParameterKind.NAMED)) {
        reportError8(ParserErrorCode.WRONG_SEPARATOR_FOR_NAMED_PARAMETER, seperator, []);
      } else if (identical(kind, ParameterKind.REQUIRED)) {
        reportError(ParserErrorCode.POSITIONAL_PARAMETER_OUTSIDE_GROUP, parameter, []);
      }
      return new DefaultFormalParameter.full(parameter, kind, seperator, defaultValue);
    } else if (matches5(TokenType.COLON)) {
      Token seperator = andAdvance;
      Expression defaultValue = parseExpression2();
      if (identical(kind, ParameterKind.POSITIONAL)) {
        reportError8(ParserErrorCode.WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER, seperator, []);
      } else if (identical(kind, ParameterKind.REQUIRED)) {
        reportError(ParserErrorCode.NAMED_PARAMETER_OUTSIDE_GROUP, parameter, []);
      }
      return new DefaultFormalParameter.full(parameter, kind, seperator, defaultValue);
    } else if (kind != ParameterKind.REQUIRED) {
      return new DefaultFormalParameter.full(parameter, kind, null, null);
    }
    return parameter;
  }

  /**
   * Parse a list of formal parameters.
   *
   * <pre>
   * formalParameterList ::=
   *     '(' ')'
   *   | '(' normalFormalParameters (',' optionalFormalParameters)? ')'
   *   | '(' optionalFormalParameters ')'
   *
   * normalFormalParameters ::=
   *     normalFormalParameter (',' normalFormalParameter)*
   *
   * optionalFormalParameters ::=
   *     optionalPositionalFormalParameters
   *   | namedFormalParameters
   *
   * optionalPositionalFormalParameters ::=
   *     '[' defaultFormalParameter (',' defaultFormalParameter)* ']'
   *
   * namedFormalParameters ::=
   *     '{' defaultNamedParameter (',' defaultNamedParameter)* '}'
   * </pre>
   *
   * @return the formal parameters that were parsed
   */
  FormalParameterList parseFormalParameterList() {
    Token leftParenthesis = expect2(TokenType.OPEN_PAREN);
    if (matches5(TokenType.CLOSE_PAREN)) {
      return new FormalParameterList.full(leftParenthesis, null, null, null, andAdvance);
    }
    List<FormalParameter> parameters = new List<FormalParameter>();
    List<FormalParameter> normalParameters = new List<FormalParameter>();
    List<FormalParameter> positionalParameters = new List<FormalParameter>();
    List<FormalParameter> namedParameters = new List<FormalParameter>();
    List<FormalParameter> currentParameters = normalParameters;
    Token leftSquareBracket = null;
    Token rightSquareBracket = null;
    Token leftCurlyBracket = null;
    Token rightCurlyBracket = null;
    ParameterKind kind = ParameterKind.REQUIRED;
    bool firstParameter = true;
    bool reportedMuliplePositionalGroups = false;
    bool reportedMulipleNamedGroups = false;
    bool reportedMixedGroups = false;
    bool wasOptionalParameter = false;
    Token initialToken = null;
    do {
      if (firstParameter) {
        firstParameter = false;
      } else if (!optional(TokenType.COMMA)) {
        if (getEndToken(leftParenthesis) != null) {
          reportError7(ParserErrorCode.EXPECTED_TOKEN, [TokenType.COMMA.lexeme]);
        } else {
          reportError8(ParserErrorCode.MISSING_CLOSING_PARENTHESIS, _currentToken.previous, []);
          break;
        }
      }
      initialToken = _currentToken;
      if (matches5(TokenType.OPEN_SQUARE_BRACKET)) {
        wasOptionalParameter = true;
        if (leftSquareBracket != null && !reportedMuliplePositionalGroups) {
          reportError7(ParserErrorCode.MULTIPLE_POSITIONAL_PARAMETER_GROUPS, []);
          reportedMuliplePositionalGroups = true;
        }
        if (leftCurlyBracket != null && !reportedMixedGroups) {
          reportError7(ParserErrorCode.MIXED_PARAMETER_GROUPS, []);
          reportedMixedGroups = true;
        }
        leftSquareBracket = andAdvance;
        currentParameters = positionalParameters;
        kind = ParameterKind.POSITIONAL;
      } else if (matches5(TokenType.OPEN_CURLY_BRACKET)) {
        wasOptionalParameter = true;
        if (leftCurlyBracket != null && !reportedMulipleNamedGroups) {
          reportError7(ParserErrorCode.MULTIPLE_NAMED_PARAMETER_GROUPS, []);
          reportedMulipleNamedGroups = true;
        }
        if (leftSquareBracket != null && !reportedMixedGroups) {
          reportError7(ParserErrorCode.MIXED_PARAMETER_GROUPS, []);
          reportedMixedGroups = true;
        }
        leftCurlyBracket = andAdvance;
        currentParameters = namedParameters;
        kind = ParameterKind.NAMED;
      }
      FormalParameter parameter = parseFormalParameter(kind);
      parameters.add(parameter);
      currentParameters.add(parameter);
      if (identical(kind, ParameterKind.REQUIRED) && wasOptionalParameter) {
        reportError(ParserErrorCode.NORMAL_BEFORE_OPTIONAL_PARAMETERS, parameter, []);
      }
      if (matches5(TokenType.CLOSE_SQUARE_BRACKET)) {
        rightSquareBracket = andAdvance;
        currentParameters = normalParameters;
        if (leftSquareBracket == null) {
          if (leftCurlyBracket != null) {
            reportError7(ParserErrorCode.WRONG_TERMINATOR_FOR_PARAMETER_GROUP, ["}"]);
            rightCurlyBracket = rightSquareBracket;
            rightSquareBracket = null;
          } else {
            reportError7(ParserErrorCode.UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP, ["["]);
          }
        }
        kind = ParameterKind.REQUIRED;
      } else if (matches5(TokenType.CLOSE_CURLY_BRACKET)) {
        rightCurlyBracket = andAdvance;
        currentParameters = normalParameters;
        if (leftCurlyBracket == null) {
          if (leftSquareBracket != null) {
            reportError7(ParserErrorCode.WRONG_TERMINATOR_FOR_PARAMETER_GROUP, ["]"]);
            rightSquareBracket = rightCurlyBracket;
            rightCurlyBracket = null;
          } else {
            reportError7(ParserErrorCode.UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP, ["{"]);
          }
        }
        kind = ParameterKind.REQUIRED;
      }
    } while (!matches5(TokenType.CLOSE_PAREN) && initialToken != _currentToken);
    Token rightParenthesis = expect2(TokenType.CLOSE_PAREN);
    if (leftSquareBracket != null && rightSquareBracket == null) {
      reportError7(ParserErrorCode.MISSING_TERMINATOR_FOR_PARAMETER_GROUP, ["]"]);
    }
    if (leftCurlyBracket != null && rightCurlyBracket == null) {
      reportError7(ParserErrorCode.MISSING_TERMINATOR_FOR_PARAMETER_GROUP, ["}"]);
    }
    if (leftSquareBracket == null) {
      leftSquareBracket = leftCurlyBracket;
    }
    if (rightSquareBracket == null) {
      rightSquareBracket = rightCurlyBracket;
    }
    return new FormalParameterList.full(leftParenthesis, parameters, leftSquareBracket, rightSquareBracket, rightParenthesis);
  }

  /**
   * Parse a for statement.
   *
   * <pre>
   * forStatement ::=
   *     'for' '(' forLoopParts ')' statement
   *
   * forLoopParts ::=
   *     forInitializerStatement expression? ';' expressionList?
   *   | declaredIdentifier 'in' expression
   *   | identifier 'in' expression
   *
   * forInitializerStatement ::=
   *     localVariableDeclaration ';'
   *   | expression? ';'
   * </pre>
   *
   * @return the for statement that was parsed
   */
  Statement parseForStatement() {
    bool wasInLoop = _inLoop;
    _inLoop = true;
    try {
      Token forKeyword = expect(Keyword.FOR);
      Token leftParenthesis = expect2(TokenType.OPEN_PAREN);
      VariableDeclarationList variableList = null;
      Expression initialization = null;
      if (!matches5(TokenType.SEMICOLON)) {
        CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
        if (matchesIdentifier() && matches3(peek(), Keyword.IN)) {
          List<VariableDeclaration> variables = new List<VariableDeclaration>();
          SimpleIdentifier variableName = parseSimpleIdentifier();
          variables.add(new VariableDeclaration.full(null, null, variableName, null, null));
          variableList = new VariableDeclarationList.full(commentAndMetadata.comment, commentAndMetadata.metadata, null, null, variables);
        } else if (isInitializedVariableDeclaration()) {
          variableList = parseVariableDeclarationList(commentAndMetadata);
        } else {
          initialization = parseExpression2();
        }
        if (matches(Keyword.IN)) {
          DeclaredIdentifier loopVariable = null;
          if (variableList == null) {
            reportError7(ParserErrorCode.MISSING_VARIABLE_IN_FOR_EACH, []);
          } else {
            NodeList<VariableDeclaration> variables = variableList.variables;
            if (variables.length > 1) {
              reportError7(ParserErrorCode.MULTIPLE_VARIABLES_IN_FOR_EACH, [variables.length.toString()]);
            }
            VariableDeclaration variable = variables[0];
            if (variable.initializer != null) {
              reportError7(ParserErrorCode.INITIALIZED_VARIABLE_IN_FOR_EACH, []);
            }
            loopVariable = new DeclaredIdentifier.full(commentAndMetadata.comment, commentAndMetadata.metadata, variableList.keyword, variableList.type, variable.name);
          }
          Token inKeyword = expect(Keyword.IN);
          Expression iterator = parseExpression2();
          Token rightParenthesis = expect2(TokenType.CLOSE_PAREN);
          Statement body = parseStatement2();
          return new ForEachStatement.full(forKeyword, leftParenthesis, loopVariable, inKeyword, iterator, rightParenthesis, body);
        }
      }
      Token leftSeparator = expect2(TokenType.SEMICOLON);
      Expression condition = null;
      if (!matches5(TokenType.SEMICOLON)) {
        condition = parseExpression2();
      }
      Token rightSeparator = expect2(TokenType.SEMICOLON);
      List<Expression> updaters = null;
      if (!matches5(TokenType.CLOSE_PAREN)) {
        updaters = parseExpressionList();
      }
      Token rightParenthesis = expect2(TokenType.CLOSE_PAREN);
      Statement body = parseStatement2();
      return new ForStatement.full(forKeyword, leftParenthesis, variableList, initialization, leftSeparator, condition, rightSeparator, updaters, rightParenthesis, body);
    } finally {
      _inLoop = wasInLoop;
    }
  }

  /**
   * Parse a function body.
   *
   * <pre>
   * functionBody ::=
   *     '=>' expression ';'
   *   | block
   *
   * functionExpressionBody ::=
   *     '=>' expression
   *   | block
   * </pre>
   *
   * @param mayBeEmpty `true` if the function body is allowed to be empty
   * @param emptyErrorCode the error code to report if function body expecte, but not found
   * @param inExpression `true` if the function body is being parsed as part of an expression
   *          and therefore does not have a terminating semicolon
   * @return the function body that was parsed
   */
  FunctionBody parseFunctionBody(bool mayBeEmpty, ParserErrorCode emptyErrorCode, bool inExpression) {
    bool wasInLoop = _inLoop;
    bool wasInSwitch = _inSwitch;
    _inLoop = false;
    _inSwitch = false;
    try {
      if (matches5(TokenType.SEMICOLON)) {
        if (!mayBeEmpty) {
          reportError7(emptyErrorCode, []);
        }
        return new EmptyFunctionBody.full(andAdvance);
      } else if (matches5(TokenType.FUNCTION)) {
        Token functionDefinition = andAdvance;
        Expression expression = parseExpression2();
        Token semicolon = null;
        if (!inExpression) {
          semicolon = expect2(TokenType.SEMICOLON);
        }
        return new ExpressionFunctionBody.full(functionDefinition, expression, semicolon);
      } else if (matches5(TokenType.OPEN_CURLY_BRACKET)) {
        return new BlockFunctionBody.full(parseBlock());
      } else if (matches2(_NATIVE)) {
        Token nativeToken = andAdvance;
        StringLiteral stringLiteral = null;
        if (matches5(TokenType.STRING)) {
          stringLiteral = parseStringLiteral();
        }
        return new NativeFunctionBody.full(nativeToken, stringLiteral, expect2(TokenType.SEMICOLON));
      } else {
        reportError7(emptyErrorCode, []);
        return new EmptyFunctionBody.full(createSyntheticToken2(TokenType.SEMICOLON));
      }
    } finally {
      _inLoop = wasInLoop;
      _inSwitch = wasInSwitch;
    }
  }

  /**
   * Parse a function declaration.
   *
   * <pre>
   * functionDeclaration ::=
   *     functionSignature functionBody
   *   | returnType? getOrSet identifier formalParameterList functionBody
   * </pre>
   *
   * @param commentAndMetadata the documentation comment and metadata to be associated with the
   *          declaration
   * @param externalKeyword the 'external' keyword, or `null` if the function is not external
   * @param returnType the return type, or `null` if there is no return type
   * @param isStatement `true` if the function declaration is being parsed as a statement
   * @return the function declaration that was parsed
   */
  FunctionDeclaration parseFunctionDeclaration(CommentAndMetadata commentAndMetadata, Token externalKeyword, TypeName returnType) {
    Token keyword = null;
    bool isGetter = false;
    if (matches(Keyword.GET) && !matches4(peek(), TokenType.OPEN_PAREN)) {
      keyword = andAdvance;
      isGetter = true;
    } else if (matches(Keyword.SET) && !matches4(peek(), TokenType.OPEN_PAREN)) {
      keyword = andAdvance;
    }
    SimpleIdentifier name = parseSimpleIdentifier();
    FormalParameterList parameters = null;
    if (!isGetter) {
      if (matches5(TokenType.OPEN_PAREN)) {
        parameters = parseFormalParameterList();
        validateFormalParameterList(parameters);
      } else {
        reportError7(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, []);
      }
    } else if (matches5(TokenType.OPEN_PAREN)) {
      reportError7(ParserErrorCode.GETTER_WITH_PARAMETERS, []);
      parseFormalParameterList();
    }
    FunctionBody body;
    if (externalKeyword == null) {
      body = parseFunctionBody(false, ParserErrorCode.MISSING_FUNCTION_BODY, false);
    } else {
      body = new EmptyFunctionBody.full(expect2(TokenType.SEMICOLON));
    }
    return new FunctionDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, externalKeyword, returnType, keyword, name, new FunctionExpression.full(parameters, body));
  }

  /**
   * Parse a function declaration statement.
   *
   * <pre>
   * functionDeclarationStatement ::=
   *     functionSignature functionBody
   * </pre>
   *
   * @return the function declaration statement that was parsed
   */
  Statement parseFunctionDeclarationStatement() {
    Modifiers modifiers = parseModifiers();
    validateModifiersForFunctionDeclarationStatement(modifiers);
    return parseFunctionDeclarationStatement2(parseCommentAndMetadata(), parseOptionalReturnType());
  }

  /**
   * Parse a function declaration statement.
   *
   * <pre>
   * functionDeclarationStatement ::=
   *     functionSignature functionBody
   * </pre>
   *
   * @param commentAndMetadata the documentation comment and metadata to be associated with the
   *          declaration
   * @param returnType the return type, or `null` if there is no return type
   * @return the function declaration statement that was parsed
   */
  Statement parseFunctionDeclarationStatement2(CommentAndMetadata commentAndMetadata, TypeName returnType) => new FunctionDeclarationStatement.full(parseFunctionDeclaration(commentAndMetadata, null, returnType));

  /**
   * Parse a function expression.
   *
   * <pre>
   * functionExpression ::=
   *     formalParameterList functionExpressionBody
   * </pre>
   *
   * @return the function expression that was parsed
   */
  FunctionExpression parseFunctionExpression() {
    FormalParameterList parameters = parseFormalParameterList();
    validateFormalParameterList(parameters);
    FunctionBody body = parseFunctionBody(false, ParserErrorCode.MISSING_FUNCTION_BODY, true);
    return new FunctionExpression.full(parameters, body);
  }

  /**
   * Parse a function type alias.
   *
   * <pre>
   * functionTypeAlias ::=
   *     functionPrefix typeParameterList? formalParameterList ';'
   *
   * functionPrefix ::=
   *     returnType? name
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the member
   * @param keyword the token representing the 'typedef' keyword
   * @return the function type alias that was parsed
   */
  FunctionTypeAlias parseFunctionTypeAlias(CommentAndMetadata commentAndMetadata, Token keyword) {
    TypeName returnType = null;
    if (hasReturnTypeInTypeAlias()) {
      returnType = parseReturnType();
    }
    SimpleIdentifier name = parseSimpleIdentifier();
    TypeParameterList typeParameters = null;
    if (matches5(TokenType.LT)) {
      typeParameters = parseTypeParameterList();
    }
    if (matches5(TokenType.SEMICOLON) || matches5(TokenType.EOF)) {
      reportError7(ParserErrorCode.MISSING_TYPEDEF_PARAMETERS, []);
      FormalParameterList parameters = new FormalParameterList.full(createSyntheticToken2(TokenType.OPEN_PAREN), null, null, null, createSyntheticToken2(TokenType.CLOSE_PAREN));
      Token semicolon = expect2(TokenType.SEMICOLON);
      return new FunctionTypeAlias.full(commentAndMetadata.comment, commentAndMetadata.metadata, keyword, returnType, name, typeParameters, parameters, semicolon);
    } else if (!matches5(TokenType.OPEN_PAREN)) {
      reportError7(ParserErrorCode.MISSING_TYPEDEF_PARAMETERS, []);
      return new FunctionTypeAlias.full(commentAndMetadata.comment, commentAndMetadata.metadata, keyword, returnType, name, typeParameters, new FormalParameterList.full(createSyntheticToken2(TokenType.OPEN_PAREN), null, null, null, createSyntheticToken2(TokenType.CLOSE_PAREN)), createSyntheticToken2(TokenType.SEMICOLON));
    }
    FormalParameterList parameters = parseFormalParameterList();
    validateFormalParameterList(parameters);
    Token semicolon = expect2(TokenType.SEMICOLON);
    return new FunctionTypeAlias.full(commentAndMetadata.comment, commentAndMetadata.metadata, keyword, returnType, name, typeParameters, parameters, semicolon);
  }

  /**
   * Parse a getter.
   *
   * <pre>
   * getter ::=
   *     getterSignature functionBody?
   *
   * getterSignature ::=
   *     'external'? 'static'? returnType? 'get' identifier
   * </pre>
   *
   * @param commentAndMetadata the documentation comment and metadata to be associated with the
   *          declaration
   * @param externalKeyword the 'external' token
   * @param staticKeyword the static keyword, or `null` if the getter is not static
   * @param the return type that has already been parsed, or `null` if there was no return
   *          type
   * @return the getter that was parsed
   */
  MethodDeclaration parseGetter(CommentAndMetadata commentAndMetadata, Token externalKeyword, Token staticKeyword, TypeName returnType) {
    Token propertyKeyword = expect(Keyword.GET);
    SimpleIdentifier name = parseSimpleIdentifier();
    if (matches5(TokenType.OPEN_PAREN) && matches4(peek(), TokenType.CLOSE_PAREN)) {
      reportError7(ParserErrorCode.GETTER_WITH_PARAMETERS, []);
      advance();
      advance();
    }
    FunctionBody body = parseFunctionBody(externalKeyword != null || staticKeyword == null, ParserErrorCode.STATIC_GETTER_WITHOUT_BODY, false);
    if (externalKeyword != null && body is! EmptyFunctionBody) {
      reportError7(ParserErrorCode.EXTERNAL_GETTER_WITH_BODY, []);
    }
    return new MethodDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, externalKeyword, staticKeyword, returnType, propertyKeyword, null, name, null, body);
  }

  /**
   * Parse a list of identifiers.
   *
   * <pre>
   * identifierList ::=
   *     identifier (',' identifier)*
   * </pre>
   *
   * @return the list of identifiers that were parsed
   */
  List<SimpleIdentifier> parseIdentifierList() {
    List<SimpleIdentifier> identifiers = new List<SimpleIdentifier>();
    identifiers.add(parseSimpleIdentifier());
    while (matches5(TokenType.COMMA)) {
      advance();
      identifiers.add(parseSimpleIdentifier());
    }
    return identifiers;
  }

  /**
   * Parse an if statement.
   *
   * <pre>
   * ifStatement ::=
   *     'if' '(' expression ')' statement ('else' statement)?
   * </pre>
   *
   * @return the if statement that was parsed
   */
  Statement parseIfStatement() {
    Token ifKeyword = expect(Keyword.IF);
    Token leftParenthesis = expect2(TokenType.OPEN_PAREN);
    Expression condition = parseExpression2();
    Token rightParenthesis = expect2(TokenType.CLOSE_PAREN);
    Statement thenStatement = parseStatement2();
    Token elseKeyword = null;
    Statement elseStatement = null;
    if (matches(Keyword.ELSE)) {
      elseKeyword = andAdvance;
      elseStatement = parseStatement2();
    }
    return new IfStatement.full(ifKeyword, leftParenthesis, condition, rightParenthesis, thenStatement, elseKeyword, elseStatement);
  }

  /**
   * Parse an implements clause.
   *
   * <pre>
   * implementsClause ::=
   *     'implements' type (',' type)*
   * </pre>
   *
   * @return the implements clause that was parsed
   */
  ImplementsClause parseImplementsClause() {
    Token keyword = expect(Keyword.IMPLEMENTS);
    List<TypeName> interfaces = new List<TypeName>();
    interfaces.add(parseTypeName());
    while (optional(TokenType.COMMA)) {
      interfaces.add(parseTypeName());
    }
    return new ImplementsClause.full(keyword, interfaces);
  }

  /**
   * Parse an import directive.
   *
   * <pre>
   * importDirective ::=
   *     metadata 'import' stringLiteral ('as' identifier)? combinator*';'
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the directive
   * @return the import directive that was parsed
   */
  ImportDirective parseImportDirective(CommentAndMetadata commentAndMetadata) {
    Token importKeyword = expect(Keyword.IMPORT);
    StringLiteral libraryUri = parseStringLiteral();
    Token asToken = null;
    SimpleIdentifier prefix = null;
    if (matches(Keyword.AS)) {
      asToken = andAdvance;
      prefix = parseSimpleIdentifier();
    }
    List<Combinator> combinators = parseCombinators();
    Token semicolon = expect2(TokenType.SEMICOLON);
    return new ImportDirective.full(commentAndMetadata.comment, commentAndMetadata.metadata, importKeyword, libraryUri, asToken, prefix, combinators, semicolon);
  }

  /**
   * Parse a list of initialized identifiers.
   *
   * <pre>
   * ?? ::=
   *     'static'? ('var' | type) initializedIdentifierList ';'
   *   | 'final' type? initializedIdentifierList ';'
   *
   * initializedIdentifierList ::=
   *     initializedIdentifier (',' initializedIdentifier)*
   *
   * initializedIdentifier ::=
   *     identifier ('=' expression)?
   * </pre>
   *
   * @param commentAndMetadata the documentation comment and metadata to be associated with the
   *          declaration
   * @param staticKeyword the static keyword, or `null` if the getter is not static
   * @param keyword the token representing the 'final', 'const' or 'var' keyword, or `null` if
   *          there is no keyword
   * @param type the type that has already been parsed, or `null` if 'var' was provided
   * @return the getter that was parsed
   */
  FieldDeclaration parseInitializedIdentifierList(CommentAndMetadata commentAndMetadata, Token staticKeyword, Token keyword, TypeName type) {
    VariableDeclarationList fieldList = parseVariableDeclarationList2(null, keyword, type);
    return new FieldDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, staticKeyword, fieldList, expect2(TokenType.SEMICOLON));
  }

  /**
   * Parse an instance creation expression.
   *
   * <pre>
   * instanceCreationExpression ::=
   *     ('new' | 'const') type ('.' identifier)? argumentList
   * </pre>
   *
   * @param keyword the 'new' or 'const' keyword that introduces the expression
   * @return the instance creation expression that was parsed
   */
  InstanceCreationExpression parseInstanceCreationExpression(Token keyword) {
    ConstructorName constructorName = parseConstructorName();
    ArgumentList argumentList = parseArgumentList();
    return new InstanceCreationExpression.full(keyword, constructorName, argumentList);
  }

  /**
   * Parse a library directive.
   *
   * <pre>
   * libraryDirective ::=
   *     metadata 'library' identifier ';'
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the directive
   * @return the library directive that was parsed
   */
  LibraryDirective parseLibraryDirective(CommentAndMetadata commentAndMetadata) {
    Token keyword = expect(Keyword.LIBRARY);
    LibraryIdentifier libraryName = parseLibraryName(ParserErrorCode.MISSING_NAME_IN_LIBRARY_DIRECTIVE, keyword);
    Token semicolon = expect2(TokenType.SEMICOLON);
    return new LibraryDirective.full(commentAndMetadata.comment, commentAndMetadata.metadata, keyword, libraryName, semicolon);
  }

  /**
   * Parse a library identifier.
   *
   * <pre>
   * libraryIdentifier ::=
   *     identifier ('.' identifier)*
   * </pre>
   *
   * @return the library identifier that was parsed
   */
  LibraryIdentifier parseLibraryIdentifier() {
    List<SimpleIdentifier> components = new List<SimpleIdentifier>();
    components.add(parseSimpleIdentifier());
    while (matches5(TokenType.PERIOD)) {
      advance();
      components.add(parseSimpleIdentifier());
    }
    return new LibraryIdentifier.full(components);
  }

  /**
   * Parse a library name.
   *
   * <pre>
   * libraryName ::=
   *     libraryIdentifier
   * </pre>
   *
   * @param missingNameError the error code to be used if the library name is missing
   * @param missingNameToken the token associated with the error produced if the library name is
   *          missing
   * @return the library name that was parsed
   */
  LibraryIdentifier parseLibraryName(ParserErrorCode missingNameError, Token missingNameToken) {
    if (matchesIdentifier()) {
      return parseLibraryIdentifier();
    } else if (matches5(TokenType.STRING)) {
      StringLiteral string = parseStringLiteral();
      reportError(ParserErrorCode.NON_IDENTIFIER_LIBRARY_NAME, string, []);
    } else {
      reportError8(missingNameError, missingNameToken, []);
    }
    List<SimpleIdentifier> components = new List<SimpleIdentifier>();
    components.add(createSyntheticIdentifier());
    return new LibraryIdentifier.full(components);
  }

  /**
   * Parse a list literal.
   *
   * <pre>
   * listLiteral ::=
   *     'const'? typeArguments? '[' (expressionList ','?)? ']'
   * </pre>
   *
   * @param modifier the 'const' modifier appearing before the literal, or `null` if there is
   *          no modifier
   * @param typeArguments the type arguments appearing before the literal, or `null` if there
   *          are no type arguments
   * @return the list literal that was parsed
   */
  ListLiteral parseListLiteral(Token modifier, TypeArgumentList typeArguments) {
    if (matches5(TokenType.INDEX)) {
      BeginToken leftBracket = new BeginToken(TokenType.OPEN_SQUARE_BRACKET, _currentToken.offset);
      Token rightBracket = new Token(TokenType.CLOSE_SQUARE_BRACKET, _currentToken.offset + 1);
      leftBracket.endToken = rightBracket;
      rightBracket.setNext(_currentToken.next);
      leftBracket.setNext(rightBracket);
      _currentToken.previous.setNext(leftBracket);
      _currentToken = _currentToken.next;
      return new ListLiteral.full(modifier, typeArguments, leftBracket, null, rightBracket);
    }
    Token leftBracket = expect2(TokenType.OPEN_SQUARE_BRACKET);
    if (matches5(TokenType.CLOSE_SQUARE_BRACKET)) {
      return new ListLiteral.full(modifier, typeArguments, leftBracket, null, andAdvance);
    }
    List<Expression> elements = new List<Expression>();
    elements.add(parseExpression2());
    while (optional(TokenType.COMMA)) {
      if (matches5(TokenType.CLOSE_SQUARE_BRACKET)) {
        return new ListLiteral.full(modifier, typeArguments, leftBracket, elements, andAdvance);
      }
      elements.add(parseExpression2());
    }
    Token rightBracket = expect2(TokenType.CLOSE_SQUARE_BRACKET);
    return new ListLiteral.full(modifier, typeArguments, leftBracket, elements, rightBracket);
  }

  /**
   * Parse a list or map literal.
   *
   * <pre>
   * listOrMapLiteral ::=
   *     listLiteral
   *   | mapLiteral
   * </pre>
   *
   * @param modifier the 'const' modifier appearing before the literal, or `null` if there is
   *          no modifier
   * @return the list or map literal that was parsed
   */
  TypedLiteral parseListOrMapLiteral(Token modifier) {
    TypeArgumentList typeArguments = null;
    if (matches5(TokenType.LT)) {
      typeArguments = parseTypeArgumentList();
    }
    if (matches5(TokenType.OPEN_CURLY_BRACKET)) {
      return parseMapLiteral(modifier, typeArguments);
    } else if (matches5(TokenType.OPEN_SQUARE_BRACKET) || matches5(TokenType.INDEX)) {
      return parseListLiteral(modifier, typeArguments);
    }
    reportError7(ParserErrorCode.EXPECTED_LIST_OR_MAP_LITERAL, []);
    return new ListLiteral.full(modifier, typeArguments, createSyntheticToken2(TokenType.OPEN_SQUARE_BRACKET), null, createSyntheticToken2(TokenType.CLOSE_SQUARE_BRACKET));
  }

  /**
   * Parse a logical and expression.
   *
   * <pre>
   * logicalAndExpression ::=
   *     bitwiseOrExpression ('&&' bitwiseOrExpression)*
   * </pre>
   *
   * @return the logical and expression that was parsed
   */
  Expression parseLogicalAndExpression() {
    Expression expression = parseBitwiseOrExpression();
    while (matches5(TokenType.AMPERSAND_AMPERSAND)) {
      Token operator = andAdvance;
      expression = new BinaryExpression.full(expression, operator, parseBitwiseOrExpression());
    }
    return expression;
  }

  /**
   * Parse a logical or expression.
   *
   * <pre>
   * logicalOrExpression ::=
   *     logicalAndExpression ('||' logicalAndExpression)*
   * </pre>
   *
   * @return the logical or expression that was parsed
   */
  Expression parseLogicalOrExpression() {
    Expression expression = parseLogicalAndExpression();
    while (matches5(TokenType.BAR_BAR)) {
      Token operator = andAdvance;
      expression = new BinaryExpression.full(expression, operator, parseLogicalAndExpression());
    }
    return expression;
  }

  /**
   * Parse a map literal.
   *
   * <pre>
   * mapLiteral ::=
   *     'const'? typeArguments? '{' (mapLiteralEntry (',' mapLiteralEntry)* ','?)? '}'
   * </pre>
   *
   * @param modifier the 'const' modifier appearing before the literal, or `null` if there is
   *          no modifier
   * @param typeArguments the type arguments that were declared, or `null` if there are no
   *          type arguments
   * @return the map literal that was parsed
   */
  MapLiteral parseMapLiteral(Token modifier, TypeArgumentList typeArguments) {
    if (typeArguments != null) {
      int num = typeArguments.arguments.length;
      if (num != 2) {
        reportError(ParserErrorCode.EXPECTED_TWO_MAP_TYPE_ARGUMENTS, typeArguments, [num]);
      }
    }
    Token leftBracket = expect2(TokenType.OPEN_CURLY_BRACKET);
    List<MapLiteralEntry> entries = new List<MapLiteralEntry>();
    if (matches5(TokenType.CLOSE_CURLY_BRACKET)) {
      return new MapLiteral.full(modifier, typeArguments, leftBracket, entries, andAdvance);
    }
    entries.add(parseMapLiteralEntry());
    while (optional(TokenType.COMMA)) {
      if (matches5(TokenType.CLOSE_CURLY_BRACKET)) {
        return new MapLiteral.full(modifier, typeArguments, leftBracket, entries, andAdvance);
      }
      entries.add(parseMapLiteralEntry());
    }
    Token rightBracket = expect2(TokenType.CLOSE_CURLY_BRACKET);
    return new MapLiteral.full(modifier, typeArguments, leftBracket, entries, rightBracket);
  }

  /**
   * Parse a map literal entry.
   *
   * <pre>
   * mapLiteralEntry ::=
   *     expression ':' expression
   * </pre>
   *
   * @return the map literal entry that was parsed
   */
  MapLiteralEntry parseMapLiteralEntry() {
    Expression key = parseExpression2();
    Token separator = expect2(TokenType.COLON);
    Expression value = parseExpression2();
    return new MapLiteralEntry.full(key, separator, value);
  }

  /**
   * Parse a method declaration.
   *
   * <pre>
   * functionDeclaration ::=
   *     'external'? 'static'? functionSignature functionBody
   *   | 'external'? functionSignature ';'
   * </pre>
   *
   * @param commentAndMetadata the documentation comment and metadata to be associated with the
   *          declaration
   * @param externalKeyword the 'external' token
   * @param staticKeyword the static keyword, or `null` if the getter is not static
   * @param returnType the return type of the method
   * @return the method declaration that was parsed
   */
  MethodDeclaration parseMethodDeclaration(CommentAndMetadata commentAndMetadata, Token externalKeyword, Token staticKeyword, TypeName returnType) {
    SimpleIdentifier methodName = parseSimpleIdentifier();
    FormalParameterList parameters = parseFormalParameterList();
    validateFormalParameterList(parameters);
    return parseMethodDeclaration2(commentAndMetadata, externalKeyword, staticKeyword, returnType, methodName, parameters);
  }

  /**
   * Parse a method declaration.
   *
   * <pre>
   * functionDeclaration ::=
   *     ('external' 'static'?)? functionSignature functionBody
   *   | 'external'? functionSignature ';'
   * </pre>
   *
   * @param commentAndMetadata the documentation comment and metadata to be associated with the
   *          declaration
   * @param externalKeyword the 'external' token
   * @param staticKeyword the static keyword, or `null` if the getter is not static
   * @param returnType the return type of the method
   * @param name the name of the method
   * @param parameters the parameters to the method
   * @return the method declaration that was parsed
   */
  MethodDeclaration parseMethodDeclaration2(CommentAndMetadata commentAndMetadata, Token externalKeyword, Token staticKeyword, TypeName returnType, SimpleIdentifier name, FormalParameterList parameters) {
    FunctionBody body = parseFunctionBody(externalKeyword != null || staticKeyword == null, ParserErrorCode.MISSING_FUNCTION_BODY, false);
    if (externalKeyword != null) {
      if (body is! EmptyFunctionBody) {
        reportError(ParserErrorCode.EXTERNAL_METHOD_WITH_BODY, body, []);
      }
    } else if (staticKeyword != null) {
      if (body is EmptyFunctionBody) {
        reportError(ParserErrorCode.ABSTRACT_STATIC_METHOD, body, []);
      }
    }
    return new MethodDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, externalKeyword, staticKeyword, returnType, null, null, name, parameters, body);
  }

  /**
   * Parse the modifiers preceding a declaration. This method allows the modifiers to appear in any
   * order but does generate errors for duplicated modifiers. Checks for other problems, such as
   * having the modifiers appear in the wrong order or specifying both 'const' and 'final', are
   * reported in one of the methods whose name is prefixed with `validateModifiersFor`.
   *
   * <pre>
   * modifiers ::=
   *     ('abstract' | 'const' | 'external' | 'factory' | 'final' | 'static' | 'var')*
   * </pre>
   *
   * @return the modifiers that were parsed
   */
  Modifiers parseModifiers() {
    Modifiers modifiers = new Modifiers();
    bool progress = true;
    while (progress) {
      if (matches(Keyword.ABSTRACT) && !matches4(peek(), TokenType.PERIOD) && !matches4(peek(), TokenType.LT)) {
        if (modifiers.abstractKeyword != null) {
          reportError7(ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          advance();
        } else {
          modifiers.abstractKeyword = andAdvance;
        }
      } else if (matches(Keyword.CONST)) {
        if (modifiers.constKeyword != null) {
          reportError7(ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          advance();
        } else {
          modifiers.constKeyword = andAdvance;
        }
      } else if (matches(Keyword.EXTERNAL) && !matches4(peek(), TokenType.PERIOD) && !matches4(peek(), TokenType.LT)) {
        if (modifiers.externalKeyword != null) {
          reportError7(ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          advance();
        } else {
          modifiers.externalKeyword = andAdvance;
        }
      } else if (matches(Keyword.FACTORY) && !matches4(peek(), TokenType.PERIOD) && !matches4(peek(), TokenType.LT)) {
        if (modifiers.factoryKeyword != null) {
          reportError7(ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          advance();
        } else {
          modifiers.factoryKeyword = andAdvance;
        }
      } else if (matches(Keyword.FINAL)) {
        if (modifiers.finalKeyword != null) {
          reportError7(ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          advance();
        } else {
          modifiers.finalKeyword = andAdvance;
        }
      } else if (matches(Keyword.STATIC) && !matches4(peek(), TokenType.PERIOD) && !matches4(peek(), TokenType.LT)) {
        if (modifiers.staticKeyword != null) {
          reportError7(ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          advance();
        } else {
          modifiers.staticKeyword = andAdvance;
        }
      } else if (matches(Keyword.VAR)) {
        if (modifiers.varKeyword != null) {
          reportError7(ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          advance();
        } else {
          modifiers.varKeyword = andAdvance;
        }
      } else {
        progress = false;
      }
    }
    return modifiers;
  }

  /**
   * Parse a multiplicative expression.
   *
   * <pre>
   * multiplicativeExpression ::=
   *     unaryExpression (multiplicativeOperator unaryExpression)*
   *   | 'super' (multiplicativeOperator unaryExpression)+
   * </pre>
   *
   * @return the multiplicative expression that was parsed
   */
  Expression parseMultiplicativeExpression() {
    Expression expression;
    if (matches(Keyword.SUPER) && _currentToken.next.type.isMultiplicativeOperator) {
      expression = new SuperExpression.full(andAdvance);
    } else {
      expression = parseUnaryExpression();
    }
    while (_currentToken.type.isMultiplicativeOperator) {
      Token operator = andAdvance;
      expression = new BinaryExpression.full(expression, operator, parseUnaryExpression());
    }
    return expression;
  }

  /**
   * Parse a new expression.
   *
   * <pre>
   * newExpression ::=
   *     instanceCreationExpression
   * </pre>
   *
   * @return the new expression that was parsed
   */
  InstanceCreationExpression parseNewExpression() => parseInstanceCreationExpression(expect(Keyword.NEW));

  /**
   * Parse a non-labeled statement.
   *
   * <pre>
   * nonLabeledStatement ::=
   *     block
   *   | assertStatement
   *   | breakStatement
   *   | continueStatement
   *   | doStatement
   *   | forStatement
   *   | ifStatement
   *   | returnStatement
   *   | switchStatement
   *   | tryStatement
   *   | whileStatement
   *   | variableDeclarationList ';'
   *   | expressionStatement
   *   | functionSignature functionBody
   * </pre>
   *
   * @return the non-labeled statement that was parsed
   */
  Statement parseNonLabeledStatement() {
    CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
    if (matches5(TokenType.OPEN_CURLY_BRACKET)) {
      if (matches4(peek(), TokenType.STRING)) {
        Token afterString = skipStringLiteral(_currentToken.next);
        if (afterString != null && identical(afterString.type, TokenType.COLON)) {
          return new ExpressionStatement.full(parseExpression2(), expect2(TokenType.SEMICOLON));
        }
      }
      return parseBlock();
    } else if (matches5(TokenType.KEYWORD) && !((_currentToken as KeywordToken)).keyword.isPseudoKeyword) {
      Keyword keyword = ((_currentToken as KeywordToken)).keyword;
      if (identical(keyword, Keyword.ASSERT)) {
        return parseAssertStatement();
      } else if (identical(keyword, Keyword.BREAK)) {
        return parseBreakStatement();
      } else if (identical(keyword, Keyword.CONTINUE)) {
        return parseContinueStatement();
      } else if (identical(keyword, Keyword.DO)) {
        return parseDoStatement();
      } else if (identical(keyword, Keyword.FOR)) {
        return parseForStatement();
      } else if (identical(keyword, Keyword.IF)) {
        return parseIfStatement();
      } else if (identical(keyword, Keyword.RETHROW)) {
        return new ExpressionStatement.full(parseRethrowExpression(), expect2(TokenType.SEMICOLON));
      } else if (identical(keyword, Keyword.RETURN)) {
        return parseReturnStatement();
      } else if (identical(keyword, Keyword.SWITCH)) {
        return parseSwitchStatement();
      } else if (identical(keyword, Keyword.THROW)) {
        return new ExpressionStatement.full(parseThrowExpression(), expect2(TokenType.SEMICOLON));
      } else if (identical(keyword, Keyword.TRY)) {
        return parseTryStatement();
      } else if (identical(keyword, Keyword.WHILE)) {
        return parseWhileStatement();
      } else if (identical(keyword, Keyword.VAR) || identical(keyword, Keyword.FINAL)) {
        return parseVariableDeclarationStatement(commentAndMetadata);
      } else if (identical(keyword, Keyword.VOID)) {
        TypeName returnType = parseReturnType();
        if (matchesIdentifier() && matchesAny(peek(), [TokenType.OPEN_PAREN, TokenType.OPEN_CURLY_BRACKET, TokenType.FUNCTION])) {
          return parseFunctionDeclarationStatement2(commentAndMetadata, returnType);
        } else {
          if (matchesIdentifier()) {
            if (matchesAny(peek(), [TokenType.EQ, TokenType.COMMA, TokenType.SEMICOLON])) {
              reportError(ParserErrorCode.VOID_VARIABLE, returnType, []);
              return parseVariableDeclarationStatement(commentAndMetadata);
            }
          } else if (matches5(TokenType.CLOSE_CURLY_BRACKET)) {
            return parseVariableDeclarationStatement2(commentAndMetadata, null, returnType);
          }
          reportError7(ParserErrorCode.MISSING_STATEMENT, []);
          return new EmptyStatement.full(createSyntheticToken2(TokenType.SEMICOLON));
        }
      } else if (identical(keyword, Keyword.CONST)) {
        if (matchesAny(peek(), [TokenType.LT, TokenType.OPEN_CURLY_BRACKET, TokenType.OPEN_SQUARE_BRACKET, TokenType.INDEX])) {
          return new ExpressionStatement.full(parseExpression2(), expect2(TokenType.SEMICOLON));
        } else if (matches4(peek(), TokenType.IDENTIFIER)) {
          Token afterType = skipTypeName(peek());
          if (afterType != null) {
            if (matches4(afterType, TokenType.OPEN_PAREN) || (matches4(afterType, TokenType.PERIOD) && matches4(afterType.next, TokenType.IDENTIFIER) && matches4(afterType.next.next, TokenType.OPEN_PAREN))) {
              return new ExpressionStatement.full(parseExpression2(), expect2(TokenType.SEMICOLON));
            }
          }
        }
        return parseVariableDeclarationStatement(commentAndMetadata);
      } else if (identical(keyword, Keyword.NEW) || identical(keyword, Keyword.TRUE) || identical(keyword, Keyword.FALSE) || identical(keyword, Keyword.NULL) || identical(keyword, Keyword.SUPER) || identical(keyword, Keyword.THIS)) {
        return new ExpressionStatement.full(parseExpression2(), expect2(TokenType.SEMICOLON));
      } else {
        reportError7(ParserErrorCode.MISSING_STATEMENT, []);
        return new EmptyStatement.full(createSyntheticToken2(TokenType.SEMICOLON));
      }
    } else if (matches5(TokenType.SEMICOLON)) {
      return parseEmptyStatement();
    } else if (isInitializedVariableDeclaration()) {
      return parseVariableDeclarationStatement(commentAndMetadata);
    } else if (isFunctionDeclaration()) {
      return parseFunctionDeclarationStatement();
    } else if (matches5(TokenType.CLOSE_CURLY_BRACKET)) {
      reportError7(ParserErrorCode.MISSING_STATEMENT, []);
      return new EmptyStatement.full(createSyntheticToken2(TokenType.SEMICOLON));
    } else {
      return new ExpressionStatement.full(parseExpression2(), expect2(TokenType.SEMICOLON));
    }
  }

  /**
   * Parse a normal formal parameter.
   *
   * <pre>
   * normalFormalParameter ::=
   *     functionSignature
   *   | fieldFormalParameter
   *   | simpleFormalParameter
   *
   * functionSignature:
   *     metadata returnType? identifier formalParameterList
   *
   * fieldFormalParameter ::=
   *     metadata finalConstVarOrType? 'this' '.' identifier
   *
   * simpleFormalParameter ::=
   *     declaredIdentifier
   *   | metadata identifier
   * </pre>
   *
   * @return the normal formal parameter that was parsed
   */
  NormalFormalParameter parseNormalFormalParameter() {
    CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
    FinalConstVarOrType holder = parseFinalConstVarOrType(true);
    Token thisKeyword = null;
    Token period = null;
    if (matches(Keyword.THIS)) {
      thisKeyword = andAdvance;
      period = expect2(TokenType.PERIOD);
    }
    SimpleIdentifier identifier = parseSimpleIdentifier();
    if (matches5(TokenType.OPEN_PAREN)) {
      FormalParameterList parameters = parseFormalParameterList();
      if (thisKeyword == null) {
        if (holder.keyword != null) {
          reportError8(ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR, holder.keyword, []);
        }
        return new FunctionTypedFormalParameter.full(commentAndMetadata.comment, commentAndMetadata.metadata, holder.type, identifier, parameters);
      } else {
        return new FieldFormalParameter.full(commentAndMetadata.comment, commentAndMetadata.metadata, holder.keyword, holder.type, thisKeyword, period, identifier, parameters);
      }
    }
    TypeName type = holder.type;
    if (type != null && matches3(type.name.beginToken, Keyword.VOID)) {
      reportError8(ParserErrorCode.VOID_PARAMETER, type.name.beginToken, []);
    }
    if (thisKeyword != null) {
      return new FieldFormalParameter.full(commentAndMetadata.comment, commentAndMetadata.metadata, holder.keyword, holder.type, thisKeyword, period, identifier, null);
    }
    return new SimpleFormalParameter.full(commentAndMetadata.comment, commentAndMetadata.metadata, holder.keyword, holder.type, identifier);
  }

  /**
   * Parse an operator declaration.
   *
   * <pre>
   * operatorDeclaration ::=
   *     operatorSignature (';' | functionBody)
   *
   * operatorSignature ::=
   *     'external'? returnType? 'operator' operator formalParameterList
   * </pre>
   *
   * @param commentAndMetadata the documentation comment and metadata to be associated with the
   *          declaration
   * @param externalKeyword the 'external' token
   * @param the return type that has already been parsed, or `null` if there was no return
   *          type
   * @return the operator declaration that was parsed
   */
  MethodDeclaration parseOperator(CommentAndMetadata commentAndMetadata, Token externalKeyword, TypeName returnType) {
    Token operatorKeyword;
    if (matches(Keyword.OPERATOR)) {
      operatorKeyword = andAdvance;
    } else {
      reportError8(ParserErrorCode.MISSING_KEYWORD_OPERATOR, _currentToken, []);
      operatorKeyword = createSyntheticToken(Keyword.OPERATOR);
    }
    if (!_currentToken.isUserDefinableOperator) {
      reportError7(ParserErrorCode.NON_USER_DEFINABLE_OPERATOR, [_currentToken.lexeme]);
    }
    SimpleIdentifier name = new SimpleIdentifier.full(andAdvance);
    if (matches5(TokenType.EQ)) {
      Token previous = _currentToken.previous;
      if ((matches4(previous, TokenType.EQ_EQ) || matches4(previous, TokenType.BANG_EQ)) && _currentToken.offset == previous.offset + 2) {
        reportError7(ParserErrorCode.INVALID_OPERATOR, ["${previous.lexeme}${_currentToken.lexeme}"]);
        advance();
      }
    }
    FormalParameterList parameters = parseFormalParameterList();
    validateFormalParameterList(parameters);
    FunctionBody body = parseFunctionBody(true, ParserErrorCode.MISSING_FUNCTION_BODY, false);
    if (externalKeyword != null && body is! EmptyFunctionBody) {
      reportError7(ParserErrorCode.EXTERNAL_OPERATOR_WITH_BODY, []);
    }
    return new MethodDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, externalKeyword, null, returnType, null, operatorKeyword, name, parameters, body);
  }

  /**
   * Parse a return type if one is given, otherwise return `null` without advancing.
   *
   * @return the return type that was parsed
   */
  TypeName parseOptionalReturnType() {
    if (matches(Keyword.VOID)) {
      return parseReturnType();
    } else if (matchesIdentifier() && !matches(Keyword.GET) && !matches(Keyword.SET) && !matches(Keyword.OPERATOR) && (matchesIdentifier2(peek()) || matches4(peek(), TokenType.LT))) {
      return parseReturnType();
    } else if (matchesIdentifier() && matches4(peek(), TokenType.PERIOD) && matchesIdentifier2(peek2(2)) && (matchesIdentifier2(peek2(3)) || matches4(peek2(3), TokenType.LT))) {
      return parseReturnType();
    }
    return null;
  }

  /**
   * Parse a part or part-of directive.
   *
   * <pre>
   * partDirective ::=
   *     metadata 'part' stringLiteral ';'
   *
   * partOfDirective ::=
   *     metadata 'part' 'of' identifier ';'
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the directive
   * @return the part or part-of directive that was parsed
   */
  Directive parsePartDirective(CommentAndMetadata commentAndMetadata) {
    Token partKeyword = expect(Keyword.PART);
    if (matches2(_OF)) {
      Token ofKeyword = andAdvance;
      LibraryIdentifier libraryName = parseLibraryName(ParserErrorCode.MISSING_NAME_IN_PART_OF_DIRECTIVE, ofKeyword);
      Token semicolon = expect2(TokenType.SEMICOLON);
      return new PartOfDirective.full(commentAndMetadata.comment, commentAndMetadata.metadata, partKeyword, ofKeyword, libraryName, semicolon);
    }
    StringLiteral partUri = parseStringLiteral();
    Token semicolon = expect2(TokenType.SEMICOLON);
    return new PartDirective.full(commentAndMetadata.comment, commentAndMetadata.metadata, partKeyword, partUri, semicolon);
  }

  /**
   * Parse a postfix expression.
   *
   * <pre>
   * postfixExpression ::=
   *     assignableExpression postfixOperator
   *   | primary selector*
   *
   * selector ::=
   *     assignableSelector
   *   | argumentList
   * </pre>
   *
   * @return the postfix expression that was parsed
   */
  Expression parsePostfixExpression() {
    Expression operand = parseAssignableExpression(true);
    if (matches5(TokenType.OPEN_SQUARE_BRACKET) || matches5(TokenType.PERIOD) || matches5(TokenType.OPEN_PAREN)) {
      do {
        if (matches5(TokenType.OPEN_PAREN)) {
          ArgumentList argumentList = parseArgumentList();
          if (operand is PropertyAccess) {
            PropertyAccess access = operand as PropertyAccess;
            operand = new MethodInvocation.full(access.target, access.operator, access.propertyName, argumentList);
          } else {
            operand = new FunctionExpressionInvocation.full(operand, argumentList);
          }
        } else {
          operand = parseAssignableSelector(operand, true);
        }
      } while (matches5(TokenType.OPEN_SQUARE_BRACKET) || matches5(TokenType.PERIOD) || matches5(TokenType.OPEN_PAREN));
      return operand;
    }
    if (!_currentToken.type.isIncrementOperator) {
      return operand;
    }
    if (operand is Literal || operand is FunctionExpressionInvocation) {
      reportError7(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, []);
    }
    Token operator = andAdvance;
    return new PostfixExpression.full(operand, operator);
  }

  /**
   * Parse a prefixed identifier.
   *
   * <pre>
   * prefixedIdentifier ::=
   *     identifier ('.' identifier)?
   * </pre>
   *
   * @return the prefixed identifier that was parsed
   */
  Identifier parsePrefixedIdentifier() {
    SimpleIdentifier qualifier = parseSimpleIdentifier();
    if (!matches5(TokenType.PERIOD)) {
      return qualifier;
    }
    Token period = andAdvance;
    SimpleIdentifier qualified = parseSimpleIdentifier();
    return new PrefixedIdentifier.full(qualifier, period, qualified);
  }

  /**
   * Parse a primary expression.
   *
   * <pre>
   * primary ::=
   *     thisExpression
   *   | 'super' assignableSelector
   *   | functionExpression
   *   | literal
   *   | identifier
   *   | newExpression
   *   | constObjectExpression
   *   | '(' expression ')'
   *   | argumentDefinitionTest
   *
   * literal ::=
   *     nullLiteral
   *   | booleanLiteral
   *   | numericLiteral
   *   | stringLiteral
   *   | symbolLiteral
   *   | mapLiteral
   *   | listLiteral
   * </pre>
   *
   * @return the primary expression that was parsed
   */
  Expression parsePrimaryExpression() {
    if (matches(Keyword.THIS)) {
      return new ThisExpression.full(andAdvance);
    } else if (matches(Keyword.SUPER)) {
      return parseAssignableSelector(new SuperExpression.full(andAdvance), false);
    } else if (matches(Keyword.NULL)) {
      return new NullLiteral.full(andAdvance);
    } else if (matches(Keyword.FALSE)) {
      return new BooleanLiteral.full(andAdvance, false);
    } else if (matches(Keyword.TRUE)) {
      return new BooleanLiteral.full(andAdvance, true);
    } else if (matches5(TokenType.DOUBLE)) {
      Token token = andAdvance;
      double value = 0.0;
      try {
        value = double.parse(token.lexeme);
      } on FormatException catch (exception) {
      }
      return new DoubleLiteral.full(token, value);
    } else if (matches5(TokenType.HEXADECIMAL)) {
      Token token = andAdvance;
      int value = null;
      try {
        value = int.parse(token.lexeme.substring(2), radix: 16);
      } on FormatException catch (exception) {
      }
      return new IntegerLiteral.full(token, value);
    } else if (matches5(TokenType.INT)) {
      Token token = andAdvance;
      int value = null;
      try {
        value = int.parse(token.lexeme);
      } on FormatException catch (exception) {
      }
      return new IntegerLiteral.full(token, value);
    } else if (matches5(TokenType.STRING)) {
      return parseStringLiteral();
    } else if (matches5(TokenType.OPEN_CURLY_BRACKET)) {
      return parseMapLiteral(null, null);
    } else if (matches5(TokenType.OPEN_SQUARE_BRACKET) || matches5(TokenType.INDEX)) {
      return parseListLiteral(null, null);
    } else if (matchesIdentifier()) {
      return parsePrefixedIdentifier();
    } else if (matches(Keyword.NEW)) {
      return parseNewExpression();
    } else if (matches(Keyword.CONST)) {
      return parseConstExpression();
    } else if (matches5(TokenType.OPEN_PAREN)) {
      if (isFunctionExpression(_currentToken)) {
        return parseFunctionExpression();
      }
      Token leftParenthesis = andAdvance;
      Expression expression = parseExpression2();
      Token rightParenthesis = expect2(TokenType.CLOSE_PAREN);
      return new ParenthesizedExpression.full(leftParenthesis, expression, rightParenthesis);
    } else if (matches5(TokenType.LT)) {
      return parseListOrMapLiteral(null);
    } else if (matches5(TokenType.QUESTION)) {
      return parseArgumentDefinitionTest();
    } else if (matches(Keyword.VOID)) {
      reportError7(ParserErrorCode.UNEXPECTED_TOKEN, [_currentToken.lexeme]);
      advance();
      return parsePrimaryExpression();
    } else if (matches5(TokenType.HASH)) {
      return parseSymbolLiteral();
    } else {
      reportError7(ParserErrorCode.MISSING_IDENTIFIER, []);
      return createSyntheticIdentifier();
    }
  }

  /**
   * Parse a redirecting constructor invocation.
   *
   * <pre>
   * redirectingConstructorInvocation ::=
   *     'this' ('.' identifier)? arguments
   * </pre>
   *
   * @return the redirecting constructor invocation that was parsed
   */
  RedirectingConstructorInvocation parseRedirectingConstructorInvocation() {
    Token keyword = expect(Keyword.THIS);
    Token period = null;
    SimpleIdentifier constructorName = null;
    if (matches5(TokenType.PERIOD)) {
      period = andAdvance;
      constructorName = parseSimpleIdentifier();
    }
    ArgumentList argumentList = parseArgumentList();
    return new RedirectingConstructorInvocation.full(keyword, period, constructorName, argumentList);
  }

  /**
   * Parse a relational expression.
   *
   * <pre>
   * relationalExpression ::=
   *     shiftExpression ('is' '!'? type | 'as' type | relationalOperator shiftExpression)?
   *   | 'super' relationalOperator shiftExpression
   * </pre>
   *
   * @return the relational expression that was parsed
   */
  Expression parseRelationalExpression() {
    if (matches(Keyword.SUPER) && _currentToken.next.type.isRelationalOperator) {
      Expression expression = new SuperExpression.full(andAdvance);
      Token operator = andAdvance;
      expression = new BinaryExpression.full(expression, operator, parseShiftExpression());
      return expression;
    }
    Expression expression = parseShiftExpression();
    if (matches(Keyword.AS)) {
      Token asOperator = andAdvance;
      expression = new AsExpression.full(expression, asOperator, parseTypeName());
    } else if (matches(Keyword.IS)) {
      Token isOperator = andAdvance;
      Token notOperator = null;
      if (matches5(TokenType.BANG)) {
        notOperator = andAdvance;
      }
      expression = new IsExpression.full(expression, isOperator, notOperator, parseTypeName());
    } else if (_currentToken.type.isRelationalOperator) {
      Token operator = andAdvance;
      expression = new BinaryExpression.full(expression, operator, parseShiftExpression());
    }
    return expression;
  }

  /**
   * Parse a rethrow expression.
   *
   * <pre>
   * rethrowExpression ::=
   *     'rethrow'
   * </pre>
   *
   * @return the rethrow expression that was parsed
   */
  Expression parseRethrowExpression() => new RethrowExpression.full(expect(Keyword.RETHROW));

  /**
   * Parse a return statement.
   *
   * <pre>
   * returnStatement ::=
   *     'return' expression? ';'
   * </pre>
   *
   * @return the return statement that was parsed
   */
  Statement parseReturnStatement() {
    Token returnKeyword = expect(Keyword.RETURN);
    if (matches5(TokenType.SEMICOLON)) {
      return new ReturnStatement.full(returnKeyword, null, andAdvance);
    }
    Expression expression = parseExpression2();
    Token semicolon = expect2(TokenType.SEMICOLON);
    return new ReturnStatement.full(returnKeyword, expression, semicolon);
  }

  /**
   * Parse a return type.
   *
   * <pre>
   * returnType ::=
   *     'void'
   *   | type
   * </pre>
   *
   * @return the return type that was parsed
   */
  TypeName parseReturnType() {
    if (matches(Keyword.VOID)) {
      return new TypeName.full(new SimpleIdentifier.full(andAdvance), null);
    } else {
      return parseTypeName();
    }
  }

  /**
   * Parse a setter.
   *
   * <pre>
   * setter ::=
   *     setterSignature functionBody?
   *
   * setterSignature ::=
   *     'external'? 'static'? returnType? 'set' identifier formalParameterList
   * </pre>
   *
   * @param commentAndMetadata the documentation comment and metadata to be associated with the
   *          declaration
   * @param externalKeyword the 'external' token
   * @param staticKeyword the static keyword, or `null` if the setter is not static
   * @param the return type that has already been parsed, or `null` if there was no return
   *          type
   * @return the setter that was parsed
   */
  MethodDeclaration parseSetter(CommentAndMetadata commentAndMetadata, Token externalKeyword, Token staticKeyword, TypeName returnType) {
    Token propertyKeyword = expect(Keyword.SET);
    SimpleIdentifier name = parseSimpleIdentifier();
    FormalParameterList parameters = parseFormalParameterList();
    validateFormalParameterList(parameters);
    FunctionBody body = parseFunctionBody(externalKeyword != null || staticKeyword == null, ParserErrorCode.STATIC_SETTER_WITHOUT_BODY, false);
    if (externalKeyword != null && body is! EmptyFunctionBody) {
      reportError7(ParserErrorCode.EXTERNAL_SETTER_WITH_BODY, []);
    }
    return new MethodDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, externalKeyword, staticKeyword, returnType, propertyKeyword, null, name, parameters, body);
  }

  /**
   * Parse a shift expression.
   *
   * <pre>
   * shiftExpression ::=
   *     additiveExpression (shiftOperator additiveExpression)*
   *   | 'super' (shiftOperator additiveExpression)+
   * </pre>
   *
   * @return the shift expression that was parsed
   */
  Expression parseShiftExpression() {
    Expression expression;
    if (matches(Keyword.SUPER) && _currentToken.next.type.isShiftOperator) {
      expression = new SuperExpression.full(andAdvance);
    } else {
      expression = parseAdditiveExpression();
    }
    while (_currentToken.type.isShiftOperator) {
      Token operator = andAdvance;
      expression = new BinaryExpression.full(expression, operator, parseAdditiveExpression());
    }
    return expression;
  }

  /**
   * Parse a simple identifier.
   *
   * <pre>
   * identifier ::=
   *     IDENTIFIER
   * </pre>
   *
   * @return the simple identifier that was parsed
   */
  SimpleIdentifier parseSimpleIdentifier() {
    if (matchesIdentifier()) {
      return new SimpleIdentifier.full(andAdvance);
    }
    reportError7(ParserErrorCode.MISSING_IDENTIFIER, []);
    return createSyntheticIdentifier();
  }

  /**
   * Parse a statement.
   *
   * <pre>
   * statement ::=
   *     label* nonLabeledStatement
   * </pre>
   *
   * @return the statement that was parsed
   */
  Statement parseStatement2() {
    List<Label> labels = new List<Label>();
    while (matchesIdentifier() && matches4(peek(), TokenType.COLON)) {
      SimpleIdentifier label = parseSimpleIdentifier();
      Token colon = expect2(TokenType.COLON);
      labels.add(new Label.full(label, colon));
    }
    Statement statement = parseNonLabeledStatement();
    if (labels.isEmpty) {
      return statement;
    }
    return new LabeledStatement.full(labels, statement);
  }

  /**
   * Parse a list of statements within a switch statement.
   *
   * <pre>
   * statements ::=
   *     statement*
   * </pre>
   *
   * @return the statements that were parsed
   */
  List<Statement> parseStatements2() {
    List<Statement> statements = new List<Statement>();
    Token statementStart = _currentToken;
    while (!matches5(TokenType.EOF) && !matches5(TokenType.CLOSE_CURLY_BRACKET) && !isSwitchMember()) {
      statements.add(parseStatement2());
      if (identical(_currentToken, statementStart)) {
        reportError8(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken, [_currentToken.lexeme]);
        advance();
      }
      statementStart = _currentToken;
    }
    return statements;
  }

  /**
   * Parse a string literal that contains interpolations.
   *
   * @return the string literal that was parsed
   */
  StringInterpolation parseStringInterpolation(Token string) {
    List<InterpolationElement> elements = new List<InterpolationElement>();
    elements.add(new InterpolationString.full(string, computeStringValue(string.lexeme)));
    while (matches5(TokenType.STRING_INTERPOLATION_EXPRESSION) || matches5(TokenType.STRING_INTERPOLATION_IDENTIFIER)) {
      if (matches5(TokenType.STRING_INTERPOLATION_EXPRESSION)) {
        Token openToken = andAdvance;
        Expression expression = parseExpression2();
        Token rightBracket = expect2(TokenType.CLOSE_CURLY_BRACKET);
        elements.add(new InterpolationExpression.full(openToken, expression, rightBracket));
      } else {
        Token openToken = andAdvance;
        Expression expression = null;
        if (matches(Keyword.THIS)) {
          expression = new ThisExpression.full(andAdvance);
        } else {
          expression = parseSimpleIdentifier();
        }
        elements.add(new InterpolationExpression.full(openToken, expression, null));
      }
      if (matches5(TokenType.STRING)) {
        string = andAdvance;
        elements.add(new InterpolationString.full(string, computeStringValue(string.lexeme)));
      }
    }
    return new StringInterpolation.full(elements);
  }

  /**
   * Parse a string literal.
   *
   * <pre>
   * stringLiteral ::=
   *     MULTI_LINE_STRING+
   *   | SINGLE_LINE_STRING+
   * </pre>
   *
   * @return the string literal that was parsed
   */
  StringLiteral parseStringLiteral() {
    List<StringLiteral> strings = new List<StringLiteral>();
    while (matches5(TokenType.STRING)) {
      Token string = andAdvance;
      if (matches5(TokenType.STRING_INTERPOLATION_EXPRESSION) || matches5(TokenType.STRING_INTERPOLATION_IDENTIFIER)) {
        strings.add(parseStringInterpolation(string));
      } else {
        strings.add(new SimpleStringLiteral.full(string, computeStringValue(string.lexeme)));
      }
    }
    if (strings.length < 1) {
      reportError7(ParserErrorCode.EXPECTED_STRING_LITERAL, []);
      return createSyntheticStringLiteral();
    } else if (strings.length == 1) {
      return strings[0];
    } else {
      return new AdjacentStrings.full(strings);
    }
  }

  /**
   * Parse a super constructor invocation.
   *
   * <pre>
   * superConstructorInvocation ::=
   *     'super' ('.' identifier)? arguments
   * </pre>
   *
   * @return the super constructor invocation that was parsed
   */
  SuperConstructorInvocation parseSuperConstructorInvocation() {
    Token keyword = expect(Keyword.SUPER);
    Token period = null;
    SimpleIdentifier constructorName = null;
    if (matches5(TokenType.PERIOD)) {
      period = andAdvance;
      constructorName = parseSimpleIdentifier();
    }
    ArgumentList argumentList = parseArgumentList();
    return new SuperConstructorInvocation.full(keyword, period, constructorName, argumentList);
  }

  /**
   * Parse a switch statement.
   *
   * <pre>
   * switchStatement ::=
   *     'switch' '(' expression ')' '{' switchCase* defaultCase? '}'
   *
   * switchCase ::=
   *     label* ('case' expression ':') statements
   *
   * defaultCase ::=
   *     label* 'default' ':' statements
   * </pre>
   *
   * @return the switch statement that was parsed
   */
  SwitchStatement parseSwitchStatement() {
    bool wasInSwitch = _inSwitch;
    _inSwitch = true;
    try {
      Set<String> definedLabels = new Set<String>();
      Token keyword = expect(Keyword.SWITCH);
      Token leftParenthesis = expect2(TokenType.OPEN_PAREN);
      Expression expression = parseExpression2();
      Token rightParenthesis = expect2(TokenType.CLOSE_PAREN);
      Token leftBracket = expect2(TokenType.OPEN_CURLY_BRACKET);
      Token defaultKeyword = null;
      List<SwitchMember> members = new List<SwitchMember>();
      while (!matches5(TokenType.EOF) && !matches5(TokenType.CLOSE_CURLY_BRACKET)) {
        List<Label> labels = new List<Label>();
        while (matchesIdentifier() && matches4(peek(), TokenType.COLON)) {
          SimpleIdentifier identifier = parseSimpleIdentifier();
          String label = identifier.token.lexeme;
          if (definedLabels.contains(label)) {
            reportError8(ParserErrorCode.DUPLICATE_LABEL_IN_SWITCH_STATEMENT, identifier.token, [label]);
          } else {
            javaSetAdd(definedLabels, label);
          }
          Token colon = expect2(TokenType.COLON);
          labels.add(new Label.full(identifier, colon));
        }
        if (matches(Keyword.CASE)) {
          Token caseKeyword = andAdvance;
          Expression caseExpression = parseExpression2();
          Token colon = expect2(TokenType.COLON);
          members.add(new SwitchCase.full(labels, caseKeyword, caseExpression, colon, parseStatements2()));
          if (defaultKeyword != null) {
            reportError8(ParserErrorCode.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE, caseKeyword, []);
          }
        } else if (matches(Keyword.DEFAULT)) {
          if (defaultKeyword != null) {
            reportError8(ParserErrorCode.SWITCH_HAS_MULTIPLE_DEFAULT_CASES, peek(), []);
          }
          defaultKeyword = andAdvance;
          Token colon = expect2(TokenType.COLON);
          members.add(new SwitchDefault.full(labels, defaultKeyword, colon, parseStatements2()));
        } else {
          reportError7(ParserErrorCode.EXPECTED_CASE_OR_DEFAULT, []);
          while (!matches5(TokenType.EOF) && !matches5(TokenType.CLOSE_CURLY_BRACKET) && !matches(Keyword.CASE) && !matches(Keyword.DEFAULT)) {
            advance();
          }
        }
      }
      Token rightBracket = expect2(TokenType.CLOSE_CURLY_BRACKET);
      return new SwitchStatement.full(keyword, leftParenthesis, expression, rightParenthesis, leftBracket, members, rightBracket);
    } finally {
      _inSwitch = wasInSwitch;
    }
  }

  /**
   * Parse a symbol literal.
   *
   * <pre>
   * symbolLiteral ::=
   *     '#' identifier ('.' identifier)*
   * </pre>
   *
   * @return the symbol literal that was parsed
   */
  SymbolLiteral parseSymbolLiteral() {
    Token poundSign = andAdvance;
    List<SimpleIdentifier> components = new List<SimpleIdentifier>();
    if (matches5(TokenType.IDENTIFIER)) {
      components.add(parseSimpleIdentifier());
      while (matches5(TokenType.PERIOD)) {
        advance();
        if (matches5(TokenType.IDENTIFIER)) {
          components.add(parseSimpleIdentifier());
        } else {
          reportError7(ParserErrorCode.MISSING_IDENTIFIER, []);
          components.add(createSyntheticIdentifier());
          break;
        }
      }
    } else {
      reportError7(ParserErrorCode.MISSING_IDENTIFIER, []);
      components.add(createSyntheticIdentifier());
    }
    return new SymbolLiteral.full(poundSign, components);
  }

  /**
   * Parse a throw expression.
   *
   * <pre>
   * throwExpression ::=
   *     'throw' expression
   * </pre>
   *
   * @return the throw expression that was parsed
   */
  Expression parseThrowExpression() {
    Token keyword = expect(Keyword.THROW);
    if (matches5(TokenType.SEMICOLON) || matches5(TokenType.CLOSE_PAREN)) {
      reportError8(ParserErrorCode.MISSING_EXPRESSION_IN_THROW, _currentToken, []);
      return new ThrowExpression.full(keyword, createSyntheticIdentifier());
    }
    Expression expression = parseExpression2();
    return new ThrowExpression.full(keyword, expression);
  }

  /**
   * Parse a throw expression.
   *
   * <pre>
   * throwExpressionWithoutCascade ::=
   *     'throw' expressionWithoutCascade
   * </pre>
   *
   * @return the throw expression that was parsed
   */
  Expression parseThrowExpressionWithoutCascade() {
    Token keyword = expect(Keyword.THROW);
    if (matches5(TokenType.SEMICOLON) || matches5(TokenType.CLOSE_PAREN)) {
      reportError8(ParserErrorCode.MISSING_EXPRESSION_IN_THROW, _currentToken, []);
      return new ThrowExpression.full(keyword, createSyntheticIdentifier());
    }
    Expression expression = parseExpressionWithoutCascade();
    return new ThrowExpression.full(keyword, expression);
  }

  /**
   * Parse a try statement.
   *
   * <pre>
   * tryStatement ::=
   *     'try' block (onPart+ finallyPart? | finallyPart)
   *
   * onPart ::=
   *     catchPart block
   *   | 'on' type catchPart? block
   *
   * catchPart ::=
   *     'catch' '(' identifier (',' identifier)? ')'
   *
   * finallyPart ::=
   *     'finally' block
   * </pre>
   *
   * @return the try statement that was parsed
   */
  Statement parseTryStatement() {
    Token tryKeyword = expect(Keyword.TRY);
    Block body = parseBlock();
    List<CatchClause> catchClauses = new List<CatchClause>();
    Block finallyClause = null;
    while (matches2(_ON) || matches(Keyword.CATCH)) {
      Token onKeyword = null;
      TypeName exceptionType = null;
      if (matches2(_ON)) {
        onKeyword = andAdvance;
        exceptionType = parseTypeName();
      }
      Token catchKeyword = null;
      Token leftParenthesis = null;
      SimpleIdentifier exceptionParameter = null;
      Token comma = null;
      SimpleIdentifier stackTraceParameter = null;
      Token rightParenthesis = null;
      if (matches(Keyword.CATCH)) {
        catchKeyword = andAdvance;
        leftParenthesis = expect2(TokenType.OPEN_PAREN);
        exceptionParameter = parseSimpleIdentifier();
        if (matches5(TokenType.COMMA)) {
          comma = andAdvance;
          stackTraceParameter = parseSimpleIdentifier();
        }
        rightParenthesis = expect2(TokenType.CLOSE_PAREN);
      }
      Block catchBody = parseBlock();
      catchClauses.add(new CatchClause.full(onKeyword, exceptionType, catchKeyword, leftParenthesis, exceptionParameter, comma, stackTraceParameter, rightParenthesis, catchBody));
    }
    Token finallyKeyword = null;
    if (matches(Keyword.FINALLY)) {
      finallyKeyword = andAdvance;
      finallyClause = parseBlock();
    } else {
      if (catchClauses.isEmpty) {
        reportError7(ParserErrorCode.MISSING_CATCH_OR_FINALLY, []);
      }
    }
    return new TryStatement.full(tryKeyword, body, catchClauses, finallyKeyword, finallyClause);
  }

  /**
   * Parse a type alias.
   *
   * <pre>
   * typeAlias ::=
   *     'typedef' typeAliasBody
   *
   * typeAliasBody ::=
   *     classTypeAlias
   *   | functionTypeAlias
   *
   * classTypeAlias ::=
   *     identifier typeParameters? '=' 'abstract'? mixinApplication
   *
   * mixinApplication ::=
   *     qualified withClause implementsClause? ';'
   *
   * functionTypeAlias ::=
   *     functionPrefix typeParameterList? formalParameterList ';'
   *
   * functionPrefix ::=
   *     returnType? name
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the member
   * @return the type alias that was parsed
   */
  TypeAlias parseTypeAlias(CommentAndMetadata commentAndMetadata) {
    Token keyword = expect(Keyword.TYPEDEF);
    if (matchesIdentifier()) {
      Token next = peek();
      if (matches4(next, TokenType.LT)) {
        next = skipTypeParameterList(next);
        if (next != null && matches4(next, TokenType.EQ)) {
          return parseClassTypeAlias(commentAndMetadata, keyword);
        }
      } else if (matches4(next, TokenType.EQ)) {
        return parseClassTypeAlias(commentAndMetadata, keyword);
      }
    }
    return parseFunctionTypeAlias(commentAndMetadata, keyword);
  }

  /**
   * Parse a list of type arguments.
   *
   * <pre>
   * typeArguments ::=
   *     '<' typeList '>'
   *
   * typeList ::=
   *     type (',' type)*
   * </pre>
   *
   * @return the type argument list that was parsed
   */
  TypeArgumentList parseTypeArgumentList() {
    Token leftBracket = expect2(TokenType.LT);
    List<TypeName> arguments = new List<TypeName>();
    arguments.add(parseTypeName());
    while (optional(TokenType.COMMA)) {
      arguments.add(parseTypeName());
    }
    Token rightBracket = expect2(TokenType.GT);
    return new TypeArgumentList.full(leftBracket, arguments, rightBracket);
  }

  /**
   * Parse a type name.
   *
   * <pre>
   * type ::=
   *     qualified typeArguments?
   * </pre>
   *
   * @return the type name that was parsed
   */
  TypeName parseTypeName() {
    Identifier typeName;
    if (matches(Keyword.VAR)) {
      reportError7(ParserErrorCode.VAR_AS_TYPE_NAME, []);
      typeName = new SimpleIdentifier.full(andAdvance);
    } else if (matchesIdentifier()) {
      typeName = parsePrefixedIdentifier();
    } else {
      typeName = createSyntheticIdentifier();
      reportError7(ParserErrorCode.EXPECTED_TYPE_NAME, []);
    }
    TypeArgumentList typeArguments = null;
    if (matches5(TokenType.LT)) {
      typeArguments = parseTypeArgumentList();
    }
    return new TypeName.full(typeName, typeArguments);
  }

  /**
   * Parse a type parameter.
   *
   * <pre>
   * typeParameter ::=
   *     metadata name ('extends' bound)?
   * </pre>
   *
   * @return the type parameter that was parsed
   */
  TypeParameter parseTypeParameter() {
    CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
    SimpleIdentifier name = parseSimpleIdentifier();
    if (matches(Keyword.EXTENDS)) {
      Token keyword = andAdvance;
      TypeName bound = parseTypeName();
      return new TypeParameter.full(commentAndMetadata.comment, commentAndMetadata.metadata, name, keyword, bound);
    }
    return new TypeParameter.full(commentAndMetadata.comment, commentAndMetadata.metadata, name, null, null);
  }

  /**
   * Parse a list of type parameters.
   *
   * <pre>
   * typeParameterList ::=
   *     '<' typeParameter (',' typeParameter)* '>'
   * </pre>
   *
   * @return the list of type parameters that were parsed
   */
  TypeParameterList parseTypeParameterList() {
    Token leftBracket = expect2(TokenType.LT);
    List<TypeParameter> typeParameters = new List<TypeParameter>();
    typeParameters.add(parseTypeParameter());
    while (optional(TokenType.COMMA)) {
      typeParameters.add(parseTypeParameter());
    }
    Token rightBracket = expect2(TokenType.GT);
    return new TypeParameterList.full(leftBracket, typeParameters, rightBracket);
  }

  /**
   * Parse a unary expression.
   *
   * <pre>
   * unaryExpression ::=
   *     prefixOperator unaryExpression
   *   | postfixExpression
   *   | unaryOperator 'super'
   *   | '-' 'super'
   *   | incrementOperator assignableExpression
   * </pre>
   *
   * @return the unary expression that was parsed
   */
  Expression parseUnaryExpression() {
    if (matches5(TokenType.MINUS) || matches5(TokenType.BANG) || matches5(TokenType.TILDE)) {
      Token operator = andAdvance;
      if (matches(Keyword.SUPER)) {
        if (matches4(peek(), TokenType.OPEN_SQUARE_BRACKET) || matches4(peek(), TokenType.PERIOD)) {
          return new PrefixExpression.full(operator, parseUnaryExpression());
        }
        return new PrefixExpression.full(operator, new SuperExpression.full(andAdvance));
      }
      return new PrefixExpression.full(operator, parseUnaryExpression());
    } else if (_currentToken.type.isIncrementOperator) {
      Token operator = andAdvance;
      if (matches(Keyword.SUPER)) {
        if (matches4(peek(), TokenType.OPEN_SQUARE_BRACKET) || matches4(peek(), TokenType.PERIOD)) {
          return new PrefixExpression.full(operator, parseUnaryExpression());
        }
        if (identical(operator.type, TokenType.MINUS_MINUS)) {
          int offset = operator.offset;
          Token firstOperator = new Token(TokenType.MINUS, offset);
          Token secondOperator = new Token(TokenType.MINUS, offset + 1);
          secondOperator.setNext(_currentToken);
          firstOperator.setNext(secondOperator);
          operator.previous.setNext(firstOperator);
          return new PrefixExpression.full(firstOperator, new PrefixExpression.full(secondOperator, new SuperExpression.full(andAdvance)));
        } else {
          reportError7(ParserErrorCode.INVALID_OPERATOR_FOR_SUPER, [operator.lexeme]);
          return new PrefixExpression.full(operator, new SuperExpression.full(andAdvance));
        }
      }
      return new PrefixExpression.full(operator, parseAssignableExpression(false));
    } else if (matches5(TokenType.PLUS)) {
      reportError7(ParserErrorCode.MISSING_IDENTIFIER, []);
      return createSyntheticIdentifier();
    }
    return parsePostfixExpression();
  }

  /**
   * Parse a variable declaration.
   *
   * <pre>
   * variableDeclaration ::=
   *     identifier ('=' expression)?
   * </pre>
   *
   * @return the variable declaration that was parsed
   */
  VariableDeclaration parseVariableDeclaration() {
    CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
    SimpleIdentifier name = parseSimpleIdentifier();
    Token equals = null;
    Expression initializer = null;
    if (matches5(TokenType.EQ)) {
      equals = andAdvance;
      initializer = parseExpression2();
    }
    return new VariableDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, name, equals, initializer);
  }

  /**
   * Parse a variable declaration list.
   *
   * <pre>
   * variableDeclarationList ::=
   *     finalConstVarOrType variableDeclaration (',' variableDeclaration)*
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the variable declaration list
   * @return the variable declaration list that was parsed
   */
  VariableDeclarationList parseVariableDeclarationList(CommentAndMetadata commentAndMetadata) {
    FinalConstVarOrType holder = parseFinalConstVarOrType(false);
    return parseVariableDeclarationList2(commentAndMetadata, holder.keyword, holder.type);
  }

  /**
   * Parse a variable declaration list.
   *
   * <pre>
   * variableDeclarationList ::=
   *     finalConstVarOrType variableDeclaration (',' variableDeclaration)*
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the variable declaration list, or
   *          `null` if there is no attempt at parsing the comment and metadata
   * @param keyword the token representing the 'final', 'const' or 'var' keyword, or `null` if
   *          there is no keyword
   * @param type the type of the variables in the list
   * @return the variable declaration list that was parsed
   */
  VariableDeclarationList parseVariableDeclarationList2(CommentAndMetadata commentAndMetadata, Token keyword, TypeName type) {
    List<VariableDeclaration> variables = new List<VariableDeclaration>();
    variables.add(parseVariableDeclaration());
    while (matches5(TokenType.COMMA)) {
      advance();
      variables.add(parseVariableDeclaration());
    }
    return new VariableDeclarationList.full(commentAndMetadata != null ? commentAndMetadata.comment : null, commentAndMetadata != null ? commentAndMetadata.metadata : null, keyword, type, variables);
  }

  /**
   * Parse a variable declaration statement.
   *
   * <pre>
   * variableDeclarationStatement ::=
   *     variableDeclarationList ';'
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the variable declaration
   *          statement, or `null` if there is no attempt at parsing the comment and metadata
   * @return the variable declaration statement that was parsed
   */
  VariableDeclarationStatement parseVariableDeclarationStatement(CommentAndMetadata commentAndMetadata) {
    VariableDeclarationList variableList = parseVariableDeclarationList(commentAndMetadata);
    Token semicolon = expect2(TokenType.SEMICOLON);
    return new VariableDeclarationStatement.full(variableList, semicolon);
  }

  /**
   * Parse a variable declaration statement.
   *
   * <pre>
   * variableDeclarationStatement ::=
   *     variableDeclarationList ';'
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the variable declaration
   *          statement, or `null` if there is no attempt at parsing the comment and metadata
   * @param keyword the token representing the 'final', 'const' or 'var' keyword, or `null` if
   *          there is no keyword
   * @param type the type of the variables in the list
   * @return the variable declaration statement that was parsed
   */
  VariableDeclarationStatement parseVariableDeclarationStatement2(CommentAndMetadata commentAndMetadata, Token keyword, TypeName type) {
    VariableDeclarationList variableList = parseVariableDeclarationList2(commentAndMetadata, keyword, type);
    Token semicolon = expect2(TokenType.SEMICOLON);
    return new VariableDeclarationStatement.full(variableList, semicolon);
  }

  /**
   * Parse a while statement.
   *
   * <pre>
   * whileStatement ::=
   *     'while' '(' expression ')' statement
   * </pre>
   *
   * @return the while statement that was parsed
   */
  Statement parseWhileStatement() {
    bool wasInLoop = _inLoop;
    _inLoop = true;
    try {
      Token keyword = expect(Keyword.WHILE);
      Token leftParenthesis = expect2(TokenType.OPEN_PAREN);
      Expression condition = parseExpression2();
      Token rightParenthesis = expect2(TokenType.CLOSE_PAREN);
      Statement body = parseStatement2();
      return new WhileStatement.full(keyword, leftParenthesis, condition, rightParenthesis, body);
    } finally {
      _inLoop = wasInLoop;
    }
  }

  /**
   * Parse a with clause.
   *
   * <pre>
   * withClause ::=
   *     'with' typeName (',' typeName)*
   * </pre>
   *
   * @return the with clause that was parsed
   */
  WithClause parseWithClause() {
    Token with2 = expect(Keyword.WITH);
    List<TypeName> types = new List<TypeName>();
    types.add(parseTypeName());
    while (optional(TokenType.COMMA)) {
      types.add(parseTypeName());
    }
    return new WithClause.full(with2, types);
  }

  /**
   * Return the token that is immediately after the current token. This is equivalent to
   * [peek].
   *
   * @return the token that is immediately after the current token
   */
  Token peek() => _currentToken.next;

  /**
   * Return the token that is the given distance after the current token.
   *
   * @param distance the number of tokens to look ahead, where `0` is the current token,
   *          `1` is the next token, etc.
   * @return the token that is the given distance after the current token
   */
  Token peek2(int distance) {
    Token token = _currentToken;
    for (int i = 0; i < distance; i++) {
      token = token.next;
    }
    return token;
  }

  /**
   * Report an error with the given error code and arguments.
   *
   * @param errorCode the error code of the error to be reported
   * @param node the node specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportError(ParserErrorCode errorCode, ASTNode node, List<Object> arguments) {
    _errorListener.onError(new AnalysisError.con2(_source, node.offset, node.length, errorCode, arguments));
  }

  /**
   * Report an error with the given error code and arguments.
   *
   * @param errorCode the error code of the error to be reported
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportError7(ParserErrorCode errorCode, List<Object> arguments) {
    reportError8(errorCode, _currentToken, arguments);
  }

  /**
   * Report an error with the given error code and arguments.
   *
   * @param errorCode the error code of the error to be reported
   * @param token the token specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportError8(ParserErrorCode errorCode, Token token, List<Object> arguments) {
    _errorListener.onError(new AnalysisError.con2(_source, token.offset, token.length, errorCode, arguments));
  }

  /**
   * Parse the 'final', 'const', 'var' or type preceding a variable declaration, starting at the
   * given token, without actually creating a type or changing the current token. Return the token
   * following the type that was parsed, or `null` if the given token is not the first token
   * in a valid type.
   *
   * <pre>
   * finalConstVarOrType ::=
   *   | 'final' type?
   *   | 'const' type?
   *   | 'var'
   *   | type
   * </pre>
   *
   * @param startToken the token at which parsing is to begin
   * @return the token following the type that was parsed
   */
  Token skipFinalConstVarOrType(Token startToken) {
    if (matches3(startToken, Keyword.FINAL) || matches3(startToken, Keyword.CONST)) {
      Token next = startToken.next;
      if (matchesIdentifier2(next.next) || matches4(next.next, TokenType.LT) || matches3(next.next, Keyword.THIS)) {
        return skipTypeName(next);
      }
    } else if (matches3(startToken, Keyword.VAR)) {
      return startToken.next;
    } else if (matchesIdentifier2(startToken)) {
      Token next = startToken.next;
      if (matchesIdentifier2(next) || matches4(next, TokenType.LT) || matches3(next, Keyword.THIS) || (matches4(next, TokenType.PERIOD) && matchesIdentifier2(next.next) && (matchesIdentifier2(next.next.next) || matches4(next.next.next, TokenType.LT) || matches3(next.next.next, Keyword.THIS)))) {
        return skipReturnType(startToken);
      }
    }
    return null;
  }

  /**
   * Parse a list of formal parameters, starting at the given token, without actually creating a
   * formal parameter list or changing the current token. Return the token following the formal
   * parameter list that was parsed, or `null` if the given token is not the first token in a
   * valid list of formal parameter.
   *
   * Note that unlike other skip methods, this method uses a heuristic. In the worst case, the
   * parameters could be prefixed by metadata, which would require us to be able to skip arbitrary
   * expressions. Rather than duplicate the logic of most of the parse methods we simply look for
   * something that is likely to be a list of parameters and then skip to returning the token after
   * the closing parenthesis.
   *
   * This method must be kept in sync with [parseFormalParameterList].
   *
   * <pre>
   * formalParameterList ::=
   *     '(' ')'
   *   | '(' normalFormalParameters (',' optionalFormalParameters)? ')'
   *   | '(' optionalFormalParameters ')'
   *
   * normalFormalParameters ::=
   *     normalFormalParameter (',' normalFormalParameter)*
   *
   * optionalFormalParameters ::=
   *     optionalPositionalFormalParameters
   *   | namedFormalParameters
   *
   * optionalPositionalFormalParameters ::=
   *     '[' defaultFormalParameter (',' defaultFormalParameter)* ']'
   *
   * namedFormalParameters ::=
   *     '{' defaultNamedParameter (',' defaultNamedParameter)* '}'
   * </pre>
   *
   * @param startToken the token at which parsing is to begin
   * @return the token following the formal parameter list that was parsed
   */
  Token skipFormalParameterList(Token startToken) {
    if (!matches4(startToken, TokenType.OPEN_PAREN)) {
      return null;
    }
    Token next = startToken.next;
    if (matches4(next, TokenType.CLOSE_PAREN)) {
      return next.next;
    }
    if (matchesAny(next, [TokenType.AT, TokenType.OPEN_SQUARE_BRACKET, TokenType.OPEN_CURLY_BRACKET]) || matches3(next, Keyword.VOID) || (matchesIdentifier2(next) && (matchesAny(next.next, [TokenType.COMMA, TokenType.CLOSE_PAREN])))) {
      return skipPastMatchingToken(startToken);
    }
    if (matchesIdentifier2(next) && matches4(next.next, TokenType.OPEN_PAREN)) {
      Token afterParameters = skipFormalParameterList(next.next);
      if (afterParameters != null && (matchesAny(afterParameters, [TokenType.COMMA, TokenType.CLOSE_PAREN]))) {
        return skipPastMatchingToken(startToken);
      }
    }
    Token afterType = skipFinalConstVarOrType(next);
    if (afterType == null) {
      return null;
    }
    if (skipSimpleIdentifier(afterType) == null) {
      return null;
    }
    return skipPastMatchingToken(startToken);
  }

  /**
   * If the given token is a begin token with an associated end token, then return the token
   * following the end token. Otherwise, return `null`.
   *
   * @param startToken the token that is assumed to be a being token
   * @return the token following the matching end token
   */
  Token skipPastMatchingToken(Token startToken) {
    if (startToken is! BeginToken) {
      return null;
    }
    Token closeParen = ((startToken as BeginToken)).endToken;
    if (closeParen == null) {
      return null;
    }
    return closeParen.next;
  }

  /**
   * Parse a prefixed identifier, starting at the given token, without actually creating a prefixed
   * identifier or changing the current token. Return the token following the prefixed identifier
   * that was parsed, or `null` if the given token is not the first token in a valid prefixed
   * identifier.
   *
   * This method must be kept in sync with [parsePrefixedIdentifier].
   *
   * <pre>
   * prefixedIdentifier ::=
   *     identifier ('.' identifier)?
   * </pre>
   *
   * @param startToken the token at which parsing is to begin
   * @return the token following the prefixed identifier that was parsed
   */
  Token skipPrefixedIdentifier(Token startToken) {
    Token token = skipSimpleIdentifier(startToken);
    if (token == null) {
      return null;
    } else if (!matches4(token, TokenType.PERIOD)) {
      return token;
    }
    return skipSimpleIdentifier(token.next);
  }

  /**
   * Parse a return type, starting at the given token, without actually creating a return type or
   * changing the current token. Return the token following the return type that was parsed, or
   * `null` if the given token is not the first token in a valid return type.
   *
   * This method must be kept in sync with [parseReturnType].
   *
   * <pre>
   * returnType ::=
   *     'void'
   *   | type
   * </pre>
   *
   * @param startToken the token at which parsing is to begin
   * @return the token following the return type that was parsed
   */
  Token skipReturnType(Token startToken) {
    if (matches3(startToken, Keyword.VOID)) {
      return startToken.next;
    } else {
      return skipTypeName(startToken);
    }
  }

  /**
   * Parse a simple identifier, starting at the given token, without actually creating a simple
   * identifier or changing the current token. Return the token following the simple identifier that
   * was parsed, or `null` if the given token is not the first token in a valid simple
   * identifier.
   *
   * This method must be kept in sync with [parseSimpleIdentifier].
   *
   * <pre>
   * identifier ::=
   *     IDENTIFIER
   * </pre>
   *
   * @param startToken the token at which parsing is to begin
   * @return the token following the simple identifier that was parsed
   */
  Token skipSimpleIdentifier(Token startToken) {
    if (matches4(startToken, TokenType.IDENTIFIER) || (matches4(startToken, TokenType.KEYWORD) && ((startToken as KeywordToken)).keyword.isPseudoKeyword)) {
      return startToken.next;
    }
    return null;
  }

  /**
   * Parse a string literal that contains interpolations, starting at the given token, without
   * actually creating a string literal or changing the current token. Return the token following
   * the string literal that was parsed, or `null` if the given token is not the first token
   * in a valid string literal.
   *
   * This method must be kept in sync with [parseStringInterpolation].
   *
   * @param startToken the token at which parsing is to begin
   * @return the string literal that was parsed
   */
  Token skipStringInterpolation(Token startToken) {
    Token token = startToken;
    TokenType type = token.type;
    while (identical(type, TokenType.STRING_INTERPOLATION_EXPRESSION) || identical(type, TokenType.STRING_INTERPOLATION_IDENTIFIER)) {
      if (identical(type, TokenType.STRING_INTERPOLATION_EXPRESSION)) {
        token = token.next;
        type = token.type;
        int bracketNestingLevel = 1;
        while (bracketNestingLevel > 0) {
          if (identical(type, TokenType.EOF)) {
            return null;
          } else if (identical(type, TokenType.OPEN_CURLY_BRACKET)) {
            bracketNestingLevel++;
          } else if (identical(type, TokenType.CLOSE_CURLY_BRACKET)) {
            bracketNestingLevel--;
          } else if (identical(type, TokenType.STRING)) {
            token = skipStringLiteral(token);
            if (token == null) {
              return null;
            }
          } else {
            token = token.next;
          }
          type = token.type;
        }
        token = token.next;
        type = token.type;
      } else {
        token = token.next;
        if (token.type != TokenType.IDENTIFIER) {
          return null;
        }
        token = token.next;
      }
      type = token.type;
      if (identical(type, TokenType.STRING)) {
        token = token.next;
        type = token.type;
      }
    }
    return token;
  }

  /**
   * Parse a string literal, starting at the given token, without actually creating a string literal
   * or changing the current token. Return the token following the string literal that was parsed,
   * or `null` if the given token is not the first token in a valid string literal.
   *
   * This method must be kept in sync with [parseStringLiteral].
   *
   * <pre>
   * stringLiteral ::=
   *     MULTI_LINE_STRING+
   *   | SINGLE_LINE_STRING+
   * </pre>
   *
   * @param startToken the token at which parsing is to begin
   * @return the token following the string literal that was parsed
   */
  Token skipStringLiteral(Token startToken) {
    Token token = startToken;
    while (token != null && matches4(token, TokenType.STRING)) {
      token = token.next;
      TokenType type = token.type;
      if (identical(type, TokenType.STRING_INTERPOLATION_EXPRESSION) || identical(type, TokenType.STRING_INTERPOLATION_IDENTIFIER)) {
        token = skipStringInterpolation(token);
      }
    }
    if (identical(token, startToken)) {
      return null;
    }
    return token;
  }

  /**
   * Parse a list of type arguments, starting at the given token, without actually creating a type argument list
   * or changing the current token. Return the token following the type argument list that was parsed,
   * or `null` if the given token is not the first token in a valid type argument list.
   *
   * This method must be kept in sync with [parseTypeArgumentList].
   *
   * <pre>
   * typeArguments ::=
   *     '<' typeList '>'
   *
   * typeList ::=
   *     type (',' type)*
   * </pre>
   *
   * @param startToken the token at which parsing is to begin
   * @return the token following the type argument list that was parsed
   */
  Token skipTypeArgumentList(Token startToken) {
    Token token = startToken;
    if (!matches4(token, TokenType.LT)) {
      return null;
    }
    token = skipTypeName(token.next);
    if (token == null) {
      return null;
    }
    while (matches4(token, TokenType.COMMA)) {
      token = skipTypeName(token.next);
      if (token == null) {
        return null;
      }
    }
    if (identical(token.type, TokenType.GT)) {
      return token.next;
    } else if (identical(token.type, TokenType.GT_GT)) {
      Token second = new Token(TokenType.GT, token.offset + 1);
      second.setNextWithoutSettingPrevious(token.next);
      return second;
    }
    return null;
  }

  /**
   * Parse a type name, starting at the given token, without actually creating a type name or
   * changing the current token. Return the token following the type name that was parsed, or
   * `null` if the given token is not the first token in a valid type name.
   *
   * This method must be kept in sync with [parseTypeName].
   *
   * <pre>
   * type ::=
   *     qualified typeArguments?
   * </pre>
   *
   * @param startToken the token at which parsing is to begin
   * @return the token following the type name that was parsed
   */
  Token skipTypeName(Token startToken) {
    Token token = skipPrefixedIdentifier(startToken);
    if (token == null) {
      return null;
    }
    if (matches4(token, TokenType.LT)) {
      token = skipTypeArgumentList(token);
    }
    return token;
  }

  /**
   * Parse a list of type parameters, starting at the given token, without actually creating a type
   * parameter list or changing the current token. Return the token following the type parameter
   * list that was parsed, or `null` if the given token is not the first token in a valid type
   * parameter list.
   *
   * This method must be kept in sync with [parseTypeParameterList].
   *
   * <pre>
   * typeParameterList ::=
   *     '<' typeParameter (',' typeParameter)* '>'
   * </pre>
   *
   * @param startToken the token at which parsing is to begin
   * @return the token following the type parameter list that was parsed
   */
  Token skipTypeParameterList(Token startToken) {
    if (!matches4(startToken, TokenType.LT)) {
      return null;
    }
    int depth = 1;
    Token next = startToken.next;
    while (depth > 0) {
      if (matches4(next, TokenType.EOF)) {
        return null;
      } else if (matches4(next, TokenType.LT)) {
        depth++;
      } else if (matches4(next, TokenType.GT)) {
        depth--;
      } else if (matches4(next, TokenType.GT_EQ)) {
        if (depth == 1) {
          Token fakeEquals = new Token(TokenType.EQ, next.offset + 2);
          fakeEquals.setNextWithoutSettingPrevious(next.next);
          return fakeEquals;
        }
        depth--;
      } else if (matches4(next, TokenType.GT_GT)) {
        depth -= 2;
      } else if (matches4(next, TokenType.GT_GT_EQ)) {
        if (depth < 2) {
          return null;
        } else if (depth == 2) {
          Token fakeEquals = new Token(TokenType.EQ, next.offset + 2);
          fakeEquals.setNextWithoutSettingPrevious(next.next);
          return fakeEquals;
        }
        depth -= 2;
      }
      next = next.next;
    }
    return next;
  }

  /**
   * Translate the characters at the given index in the given string, appending the translated
   * character to the given builder. The index is assumed to be valid.
   *
   * @param builder the builder to which the translated character is to be appended
   * @param lexeme the string containing the character(s) to be translated
   * @param index the index of the character to be translated
   * @return the index of the next character to be translated
   */
  int translateCharacter(JavaStringBuilder builder, String lexeme, int index) {
    int currentChar = lexeme.codeUnitAt(index);
    if (currentChar != 0x5C) {
      builder.appendChar(currentChar);
      return index + 1;
    }
    int length = lexeme.length;
    int currentIndex = index + 1;
    if (currentIndex >= length) {
      return length;
    }
    currentChar = lexeme.codeUnitAt(currentIndex);
    if (currentChar == 0x6E) {
      builder.appendChar(0xA);
    } else if (currentChar == 0x72) {
      builder.appendChar(0xD);
    } else if (currentChar == 0x66) {
      builder.appendChar(0xC);
    } else if (currentChar == 0x62) {
      builder.appendChar(0x8);
    } else if (currentChar == 0x74) {
      builder.appendChar(0x9);
    } else if (currentChar == 0x76) {
      builder.appendChar(0xB);
    } else if (currentChar == 0x78) {
      if (currentIndex + 2 >= length) {
        reportError7(ParserErrorCode.INVALID_HEX_ESCAPE, []);
        return length;
      }
      int firstDigit = lexeme.codeUnitAt(currentIndex + 1);
      int secondDigit = lexeme.codeUnitAt(currentIndex + 2);
      if (!isHexDigit(firstDigit) || !isHexDigit(secondDigit)) {
        reportError7(ParserErrorCode.INVALID_HEX_ESCAPE, []);
      } else {
        builder.appendChar((((Character.digit(firstDigit, 16) << 4) + Character.digit(secondDigit, 16)) as int));
      }
      return currentIndex + 3;
    } else if (currentChar == 0x75) {
      currentIndex++;
      if (currentIndex >= length) {
        reportError7(ParserErrorCode.INVALID_UNICODE_ESCAPE, []);
        return length;
      }
      currentChar = lexeme.codeUnitAt(currentIndex);
      if (currentChar == 0x7B) {
        currentIndex++;
        if (currentIndex >= length) {
          reportError7(ParserErrorCode.INVALID_UNICODE_ESCAPE, []);
          return length;
        }
        currentChar = lexeme.codeUnitAt(currentIndex);
        int digitCount = 0;
        int value = 0;
        while (currentChar != 0x7D) {
          if (!isHexDigit(currentChar)) {
            reportError7(ParserErrorCode.INVALID_UNICODE_ESCAPE, []);
            currentIndex++;
            while (currentIndex < length && lexeme.codeUnitAt(currentIndex) != 0x7D) {
              currentIndex++;
            }
            return currentIndex + 1;
          }
          digitCount++;
          value = (value << 4) + Character.digit(currentChar, 16);
          currentIndex++;
          if (currentIndex >= length) {
            reportError7(ParserErrorCode.INVALID_UNICODE_ESCAPE, []);
            return length;
          }
          currentChar = lexeme.codeUnitAt(currentIndex);
        }
        if (digitCount < 1 || digitCount > 6) {
          reportError7(ParserErrorCode.INVALID_UNICODE_ESCAPE, []);
        }
        appendScalarValue(builder, lexeme.substring(index, currentIndex + 1), value, index, currentIndex);
        return currentIndex + 1;
      } else {
        if (currentIndex + 3 >= length) {
          reportError7(ParserErrorCode.INVALID_UNICODE_ESCAPE, []);
          return length;
        }
        int firstDigit = currentChar;
        int secondDigit = lexeme.codeUnitAt(currentIndex + 1);
        int thirdDigit = lexeme.codeUnitAt(currentIndex + 2);
        int fourthDigit = lexeme.codeUnitAt(currentIndex + 3);
        if (!isHexDigit(firstDigit) || !isHexDigit(secondDigit) || !isHexDigit(thirdDigit) || !isHexDigit(fourthDigit)) {
          reportError7(ParserErrorCode.INVALID_UNICODE_ESCAPE, []);
        } else {
          appendScalarValue(builder, lexeme.substring(index, currentIndex + 1), ((((((Character.digit(firstDigit, 16) << 4) + Character.digit(secondDigit, 16)) << 4) + Character.digit(thirdDigit, 16)) << 4) + Character.digit(fourthDigit, 16)), index, currentIndex + 3);
        }
        return currentIndex + 4;
      }
    } else {
      builder.appendChar(currentChar);
    }
    return currentIndex + 1;
  }

  /**
   * Validate that the given parameter list does not contain any field initializers.
   *
   * @param parameterList the parameter list to be validated
   */
  void validateFormalParameterList(FormalParameterList parameterList) {
    for (FormalParameter parameter in parameterList.parameters) {
      if (parameter is FieldFormalParameter) {
        reportError(ParserErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, ((parameter as FieldFormalParameter)).identifier, []);
      }
    }
  }

  /**
   * Validate that the given set of modifiers is appropriate for a class and return the 'abstract'
   * keyword if there is one.
   *
   * @param modifiers the modifiers being validated
   */
  Token validateModifiersForClass(Modifiers modifiers) {
    validateModifiersForTopLevelDeclaration(modifiers);
    if (modifiers.constKeyword != null) {
      reportError8(ParserErrorCode.CONST_CLASS, modifiers.constKeyword, []);
    }
    if (modifiers.externalKeyword != null) {
      reportError8(ParserErrorCode.EXTERNAL_CLASS, modifiers.externalKeyword, []);
    }
    if (modifiers.finalKeyword != null) {
      reportError8(ParserErrorCode.FINAL_CLASS, modifiers.finalKeyword, []);
    }
    if (modifiers.varKeyword != null) {
      reportError8(ParserErrorCode.VAR_CLASS, modifiers.varKeyword, []);
    }
    return modifiers.abstractKeyword;
  }

  /**
   * Validate that the given set of modifiers is appropriate for a constructor and return the
   * 'const' keyword if there is one.
   *
   * @param modifiers the modifiers being validated
   * @return the 'const' or 'final' keyword associated with the constructor
   */
  Token validateModifiersForConstructor(Modifiers modifiers) {
    if (modifiers.abstractKeyword != null) {
      reportError7(ParserErrorCode.ABSTRACT_CLASS_MEMBER, []);
    }
    if (modifiers.finalKeyword != null) {
      reportError8(ParserErrorCode.FINAL_CONSTRUCTOR, modifiers.finalKeyword, []);
    }
    if (modifiers.staticKeyword != null) {
      reportError8(ParserErrorCode.STATIC_CONSTRUCTOR, modifiers.staticKeyword, []);
    }
    if (modifiers.varKeyword != null) {
      reportError8(ParserErrorCode.CONSTRUCTOR_WITH_RETURN_TYPE, modifiers.varKeyword, []);
    }
    Token externalKeyword = modifiers.externalKeyword;
    Token constKeyword = modifiers.constKeyword;
    Token factoryKeyword = modifiers.factoryKeyword;
    if (externalKeyword != null && constKeyword != null && constKeyword.offset < externalKeyword.offset) {
      reportError8(ParserErrorCode.EXTERNAL_AFTER_CONST, externalKeyword, []);
    }
    if (externalKeyword != null && factoryKeyword != null && factoryKeyword.offset < externalKeyword.offset) {
      reportError8(ParserErrorCode.EXTERNAL_AFTER_FACTORY, externalKeyword, []);
    }
    return constKeyword;
  }

  /**
   * Validate that the given set of modifiers is appropriate for a field and return the 'final',
   * 'const' or 'var' keyword if there is one.
   *
   * @param modifiers the modifiers being validated
   * @return the 'final', 'const' or 'var' keyword associated with the field
   */
  Token validateModifiersForField(Modifiers modifiers) {
    if (modifiers.abstractKeyword != null) {
      reportError7(ParserErrorCode.ABSTRACT_CLASS_MEMBER, []);
    }
    if (modifiers.externalKeyword != null) {
      reportError8(ParserErrorCode.EXTERNAL_FIELD, modifiers.externalKeyword, []);
    }
    if (modifiers.factoryKeyword != null) {
      reportError8(ParserErrorCode.NON_CONSTRUCTOR_FACTORY, modifiers.factoryKeyword, []);
    }
    Token staticKeyword = modifiers.staticKeyword;
    Token constKeyword = modifiers.constKeyword;
    Token finalKeyword = modifiers.finalKeyword;
    Token varKeyword = modifiers.varKeyword;
    if (constKeyword != null) {
      if (finalKeyword != null) {
        reportError8(ParserErrorCode.CONST_AND_FINAL, finalKeyword, []);
      }
      if (varKeyword != null) {
        reportError8(ParserErrorCode.CONST_AND_VAR, varKeyword, []);
      }
      if (staticKeyword != null && constKeyword.offset < staticKeyword.offset) {
        reportError8(ParserErrorCode.STATIC_AFTER_CONST, staticKeyword, []);
      }
    } else if (finalKeyword != null) {
      if (varKeyword != null) {
        reportError8(ParserErrorCode.FINAL_AND_VAR, varKeyword, []);
      }
      if (staticKeyword != null && finalKeyword.offset < staticKeyword.offset) {
        reportError8(ParserErrorCode.STATIC_AFTER_FINAL, staticKeyword, []);
      }
    } else if (varKeyword != null && staticKeyword != null && varKeyword.offset < staticKeyword.offset) {
      reportError8(ParserErrorCode.STATIC_AFTER_VAR, staticKeyword, []);
    }
    return lexicallyFirst([constKeyword, finalKeyword, varKeyword]);
  }

  /**
   * Validate that the given set of modifiers is appropriate for a local function.
   *
   * @param modifiers the modifiers being validated
   */
  void validateModifiersForFunctionDeclarationStatement(Modifiers modifiers) {
    if (modifiers.abstractKeyword != null || modifiers.constKeyword != null || modifiers.externalKeyword != null || modifiers.factoryKeyword != null || modifiers.finalKeyword != null || modifiers.staticKeyword != null || modifiers.varKeyword != null) {
      reportError7(ParserErrorCode.LOCAL_FUNCTION_DECLARATION_MODIFIER, []);
    }
  }

  /**
   * Validate that the given set of modifiers is appropriate for a getter, setter, or method.
   *
   * @param modifiers the modifiers being validated
   */
  void validateModifiersForGetterOrSetterOrMethod(Modifiers modifiers) {
    if (modifiers.abstractKeyword != null) {
      reportError7(ParserErrorCode.ABSTRACT_CLASS_MEMBER, []);
    }
    if (modifiers.constKeyword != null) {
      reportError8(ParserErrorCode.CONST_METHOD, modifiers.constKeyword, []);
    }
    if (modifiers.factoryKeyword != null) {
      reportError8(ParserErrorCode.NON_CONSTRUCTOR_FACTORY, modifiers.factoryKeyword, []);
    }
    if (modifiers.finalKeyword != null) {
      reportError8(ParserErrorCode.FINAL_METHOD, modifiers.finalKeyword, []);
    }
    if (modifiers.varKeyword != null) {
      reportError8(ParserErrorCode.VAR_RETURN_TYPE, modifiers.varKeyword, []);
    }
    Token externalKeyword = modifiers.externalKeyword;
    Token staticKeyword = modifiers.staticKeyword;
    if (externalKeyword != null && staticKeyword != null && staticKeyword.offset < externalKeyword.offset) {
      reportError8(ParserErrorCode.EXTERNAL_AFTER_STATIC, externalKeyword, []);
    }
  }

  /**
   * Validate that the given set of modifiers is appropriate for a getter, setter, or method.
   *
   * @param modifiers the modifiers being validated
   */
  void validateModifiersForOperator(Modifiers modifiers) {
    if (modifiers.abstractKeyword != null) {
      reportError7(ParserErrorCode.ABSTRACT_CLASS_MEMBER, []);
    }
    if (modifiers.constKeyword != null) {
      reportError8(ParserErrorCode.CONST_METHOD, modifiers.constKeyword, []);
    }
    if (modifiers.factoryKeyword != null) {
      reportError8(ParserErrorCode.NON_CONSTRUCTOR_FACTORY, modifiers.factoryKeyword, []);
    }
    if (modifiers.finalKeyword != null) {
      reportError8(ParserErrorCode.FINAL_METHOD, modifiers.finalKeyword, []);
    }
    if (modifiers.staticKeyword != null) {
      reportError8(ParserErrorCode.STATIC_OPERATOR, modifiers.staticKeyword, []);
    }
    if (modifiers.varKeyword != null) {
      reportError8(ParserErrorCode.VAR_RETURN_TYPE, modifiers.varKeyword, []);
    }
  }

  /**
   * Validate that the given set of modifiers is appropriate for a top-level declaration.
   *
   * @param modifiers the modifiers being validated
   */
  void validateModifiersForTopLevelDeclaration(Modifiers modifiers) {
    if (modifiers.factoryKeyword != null) {
      reportError8(ParserErrorCode.FACTORY_TOP_LEVEL_DECLARATION, modifiers.factoryKeyword, []);
    }
    if (modifiers.staticKeyword != null) {
      reportError8(ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION, modifiers.staticKeyword, []);
    }
  }

  /**
   * Validate that the given set of modifiers is appropriate for a top-level function.
   *
   * @param modifiers the modifiers being validated
   */
  void validateModifiersForTopLevelFunction(Modifiers modifiers) {
    validateModifiersForTopLevelDeclaration(modifiers);
    if (modifiers.abstractKeyword != null) {
      reportError7(ParserErrorCode.ABSTRACT_TOP_LEVEL_FUNCTION, []);
    }
    if (modifiers.constKeyword != null) {
      reportError8(ParserErrorCode.CONST_CLASS, modifiers.constKeyword, []);
    }
    if (modifiers.finalKeyword != null) {
      reportError8(ParserErrorCode.FINAL_CLASS, modifiers.finalKeyword, []);
    }
    if (modifiers.varKeyword != null) {
      reportError8(ParserErrorCode.VAR_RETURN_TYPE, modifiers.varKeyword, []);
    }
  }

  /**
   * Validate that the given set of modifiers is appropriate for a field and return the 'final',
   * 'const' or 'var' keyword if there is one.
   *
   * @param modifiers the modifiers being validated
   * @return the 'final', 'const' or 'var' keyword associated with the field
   */
  Token validateModifiersForTopLevelVariable(Modifiers modifiers) {
    validateModifiersForTopLevelDeclaration(modifiers);
    if (modifiers.abstractKeyword != null) {
      reportError7(ParserErrorCode.ABSTRACT_TOP_LEVEL_VARIABLE, []);
    }
    if (modifiers.externalKeyword != null) {
      reportError8(ParserErrorCode.EXTERNAL_FIELD, modifiers.externalKeyword, []);
    }
    Token constKeyword = modifiers.constKeyword;
    Token finalKeyword = modifiers.finalKeyword;
    Token varKeyword = modifiers.varKeyword;
    if (constKeyword != null) {
      if (finalKeyword != null) {
        reportError8(ParserErrorCode.CONST_AND_FINAL, finalKeyword, []);
      }
      if (varKeyword != null) {
        reportError8(ParserErrorCode.CONST_AND_VAR, varKeyword, []);
      }
    } else if (finalKeyword != null) {
      if (varKeyword != null) {
        reportError8(ParserErrorCode.FINAL_AND_VAR, varKeyword, []);
      }
    }
    return lexicallyFirst([constKeyword, finalKeyword, varKeyword]);
  }

  /**
   * Validate that the given set of modifiers is appropriate for a class and return the 'abstract'
   * keyword if there is one.
   *
   * @param modifiers the modifiers being validated
   */
  void validateModifiersForTypedef(Modifiers modifiers) {
    validateModifiersForTopLevelDeclaration(modifiers);
    if (modifiers.abstractKeyword != null) {
      reportError8(ParserErrorCode.ABSTRACT_TYPEDEF, modifiers.abstractKeyword, []);
    }
    if (modifiers.constKeyword != null) {
      reportError8(ParserErrorCode.CONST_TYPEDEF, modifiers.constKeyword, []);
    }
    if (modifiers.externalKeyword != null) {
      reportError8(ParserErrorCode.EXTERNAL_TYPEDEF, modifiers.externalKeyword, []);
    }
    if (modifiers.finalKeyword != null) {
      reportError8(ParserErrorCode.FINAL_TYPEDEF, modifiers.finalKeyword, []);
    }
    if (modifiers.varKeyword != null) {
      reportError8(ParserErrorCode.VAR_TYPEDEF, modifiers.varKeyword, []);
    }
  }
}
class KeywordToken_11 extends KeywordToken {
  KeywordToken_11(Keyword arg0, int arg1) : super(arg0, arg1);
  int get length => 0;
}
class AnalysisErrorListener_12 implements AnalysisErrorListener {
  List<bool> errorFound;
  AnalysisErrorListener_12(this.errorFound);
  void onError(AnalysisError error) {
    errorFound[0] = true;
  }
}
/**
 * The enumeration `ParserErrorCode` defines the error codes used for errors detected by the
 * parser. The convention for this class is for the name of the error code to indicate the problem
 * that caused the error to be generated and for the error message to explain what is wrong and,
 * when appropriate, how the problem can be corrected.
 *
 * @coverage dart.engine.parser
 */
class ParserErrorCode implements Comparable<ParserErrorCode>, ErrorCode {
  static final ParserErrorCode ABSTRACT_CLASS_MEMBER = new ParserErrorCode.con2('ABSTRACT_CLASS_MEMBER', 0, "Members of classes cannot be declared to be 'abstract'");
  static final ParserErrorCode ABSTRACT_STATIC_METHOD = new ParserErrorCode.con2('ABSTRACT_STATIC_METHOD', 1, "Static methods cannot be declared to be 'abstract'");
  static final ParserErrorCode ABSTRACT_TOP_LEVEL_FUNCTION = new ParserErrorCode.con2('ABSTRACT_TOP_LEVEL_FUNCTION', 2, "Top-level functions cannot be declared to be 'abstract'");
  static final ParserErrorCode ABSTRACT_TOP_LEVEL_VARIABLE = new ParserErrorCode.con2('ABSTRACT_TOP_LEVEL_VARIABLE', 3, "Top-level variables cannot be declared to be 'abstract'");
  static final ParserErrorCode ABSTRACT_TYPEDEF = new ParserErrorCode.con2('ABSTRACT_TYPEDEF', 4, "Type aliases cannot be declared to be 'abstract'");
  static final ParserErrorCode BREAK_OUTSIDE_OF_LOOP = new ParserErrorCode.con2('BREAK_OUTSIDE_OF_LOOP', 5, "A break statement cannot be used outside of a loop or switch statement");
  static final ParserErrorCode CONST_AND_FINAL = new ParserErrorCode.con2('CONST_AND_FINAL', 6, "Members cannot be declared to be both 'const' and 'final'");
  static final ParserErrorCode CONST_AND_VAR = new ParserErrorCode.con2('CONST_AND_VAR', 7, "Members cannot be declared to be both 'const' and 'var'");
  static final ParserErrorCode CONST_CLASS = new ParserErrorCode.con2('CONST_CLASS', 8, "Classes cannot be declared to be 'const'");
  static final ParserErrorCode CONST_CONSTRUCTOR_WITH_BODY = new ParserErrorCode.con2('CONST_CONSTRUCTOR_WITH_BODY', 9, "'const' constructors cannot have a body");
  static final ParserErrorCode CONST_FACTORY = new ParserErrorCode.con2('CONST_FACTORY', 10, "Only redirecting factory constructors can be declared to be 'const'");
  static final ParserErrorCode CONST_METHOD = new ParserErrorCode.con2('CONST_METHOD', 11, "Getters, setters and methods cannot be declared to be 'const'");
  static final ParserErrorCode CONST_TYPEDEF = new ParserErrorCode.con2('CONST_TYPEDEF', 12, "Type aliases cannot be declared to be 'const'");
  static final ParserErrorCode CONSTRUCTOR_WITH_RETURN_TYPE = new ParserErrorCode.con2('CONSTRUCTOR_WITH_RETURN_TYPE', 13, "Constructors cannot have a return type");
  static final ParserErrorCode CONTINUE_OUTSIDE_OF_LOOP = new ParserErrorCode.con2('CONTINUE_OUTSIDE_OF_LOOP', 14, "A continue statement cannot be used outside of a loop or switch statement");
  static final ParserErrorCode CONTINUE_WITHOUT_LABEL_IN_CASE = new ParserErrorCode.con2('CONTINUE_WITHOUT_LABEL_IN_CASE', 15, "A continue statement in a switch statement must have a label as a target");
  static final ParserErrorCode DEPRECATED_ARGUMENT_DEFINITION_TEST = new ParserErrorCode.con2('DEPRECATED_ARGUMENT_DEFINITION_TEST', 16, "The argument definition test ('?' operator) has been deprecated");
  static final ParserErrorCode DIRECTIVE_AFTER_DECLARATION = new ParserErrorCode.con2('DIRECTIVE_AFTER_DECLARATION', 17, "Directives must appear before any declarations");
  static final ParserErrorCode DUPLICATE_LABEL_IN_SWITCH_STATEMENT = new ParserErrorCode.con2('DUPLICATE_LABEL_IN_SWITCH_STATEMENT', 18, "The label %s was already used in this switch statement");
  static final ParserErrorCode DUPLICATED_MODIFIER = new ParserErrorCode.con2('DUPLICATED_MODIFIER', 19, "The modifier '%s' was already specified.");
  static final ParserErrorCode EQUALITY_CANNOT_BE_EQUALITY_OPERAND = new ParserErrorCode.con2('EQUALITY_CANNOT_BE_EQUALITY_OPERAND', 20, "Equality expression cannot be operand of another equality expression.");
  static final ParserErrorCode EXPECTED_CASE_OR_DEFAULT = new ParserErrorCode.con2('EXPECTED_CASE_OR_DEFAULT', 21, "Expected 'case' or 'default'");
  static final ParserErrorCode EXPECTED_CLASS_MEMBER = new ParserErrorCode.con2('EXPECTED_CLASS_MEMBER', 22, "Expected a class member");
  static final ParserErrorCode EXPECTED_EXECUTABLE = new ParserErrorCode.con2('EXPECTED_EXECUTABLE', 23, "Expected a method, getter, setter or operator declaration");
  static final ParserErrorCode EXPECTED_LIST_OR_MAP_LITERAL = new ParserErrorCode.con2('EXPECTED_LIST_OR_MAP_LITERAL', 24, "Expected a list or map literal");
  static final ParserErrorCode EXPECTED_STRING_LITERAL = new ParserErrorCode.con2('EXPECTED_STRING_LITERAL', 25, "Expected a string literal");
  static final ParserErrorCode EXPECTED_TOKEN = new ParserErrorCode.con2('EXPECTED_TOKEN', 26, "Expected to find '%s'");
  static final ParserErrorCode EXPECTED_TWO_MAP_TYPE_ARGUMENTS = new ParserErrorCode.con2('EXPECTED_TWO_MAP_TYPE_ARGUMENTS', 27, "Map literal requires exactly two type arguments or none, but %d found");
  static final ParserErrorCode EXPECTED_TYPE_NAME = new ParserErrorCode.con2('EXPECTED_TYPE_NAME', 28, "Expected a type name");
  static final ParserErrorCode EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE = new ParserErrorCode.con2('EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE', 29, "Export directives must preceed part directives");
  static final ParserErrorCode EXTERNAL_AFTER_CONST = new ParserErrorCode.con2('EXTERNAL_AFTER_CONST', 30, "The modifier 'external' should be before the modifier 'const'");
  static final ParserErrorCode EXTERNAL_AFTER_FACTORY = new ParserErrorCode.con2('EXTERNAL_AFTER_FACTORY', 31, "The modifier 'external' should be before the modifier 'factory'");
  static final ParserErrorCode EXTERNAL_AFTER_STATIC = new ParserErrorCode.con2('EXTERNAL_AFTER_STATIC', 32, "The modifier 'external' should be before the modifier 'static'");
  static final ParserErrorCode EXTERNAL_CLASS = new ParserErrorCode.con2('EXTERNAL_CLASS', 33, "Classes cannot be declared to be 'external'");
  static final ParserErrorCode EXTERNAL_CONSTRUCTOR_WITH_BODY = new ParserErrorCode.con2('EXTERNAL_CONSTRUCTOR_WITH_BODY', 34, "External constructors cannot have a body");
  static final ParserErrorCode EXTERNAL_FIELD = new ParserErrorCode.con2('EXTERNAL_FIELD', 35, "Fields cannot be declared to be 'external'");
  static final ParserErrorCode EXTERNAL_GETTER_WITH_BODY = new ParserErrorCode.con2('EXTERNAL_GETTER_WITH_BODY', 36, "External getters cannot have a body");
  static final ParserErrorCode EXTERNAL_METHOD_WITH_BODY = new ParserErrorCode.con2('EXTERNAL_METHOD_WITH_BODY', 37, "External methods cannot have a body");
  static final ParserErrorCode EXTERNAL_OPERATOR_WITH_BODY = new ParserErrorCode.con2('EXTERNAL_OPERATOR_WITH_BODY', 38, "External operators cannot have a body");
  static final ParserErrorCode EXTERNAL_SETTER_WITH_BODY = new ParserErrorCode.con2('EXTERNAL_SETTER_WITH_BODY', 39, "External setters cannot have a body");
  static final ParserErrorCode EXTERNAL_TYPEDEF = new ParserErrorCode.con2('EXTERNAL_TYPEDEF', 40, "Type aliases cannot be declared to be 'external'");
  static final ParserErrorCode FACTORY_TOP_LEVEL_DECLARATION = new ParserErrorCode.con2('FACTORY_TOP_LEVEL_DECLARATION', 41, "Top-level declarations cannot be declared to be 'factory'");
  static final ParserErrorCode FACTORY_WITHOUT_BODY = new ParserErrorCode.con2('FACTORY_WITHOUT_BODY', 42, "A non-redirecting 'factory' constructor must have a body");
  static final ParserErrorCode FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR = new ParserErrorCode.con2('FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR', 43, "Field initializers can only be used in a constructor");
  static final ParserErrorCode FINAL_AND_VAR = new ParserErrorCode.con2('FINAL_AND_VAR', 44, "Members cannot be declared to be both 'final' and 'var'");
  static final ParserErrorCode FINAL_CLASS = new ParserErrorCode.con2('FINAL_CLASS', 45, "Classes cannot be declared to be 'final'");
  static final ParserErrorCode FINAL_CONSTRUCTOR = new ParserErrorCode.con2('FINAL_CONSTRUCTOR', 46, "A constructor cannot be declared to be 'final'");
  static final ParserErrorCode FINAL_METHOD = new ParserErrorCode.con2('FINAL_METHOD', 47, "Getters, setters and methods cannot be declared to be 'final'");
  static final ParserErrorCode FINAL_TYPEDEF = new ParserErrorCode.con2('FINAL_TYPEDEF', 48, "Type aliases cannot be declared to be 'final'");
  static final ParserErrorCode FUNCTION_TYPED_PARAMETER_VAR = new ParserErrorCode.con2('FUNCTION_TYPED_PARAMETER_VAR', 49, "Function typed parameters cannot specify 'const', 'final' or 'var' instead of return type");
  static final ParserErrorCode GETTER_WITH_PARAMETERS = new ParserErrorCode.con2('GETTER_WITH_PARAMETERS', 50, "Getter should be declared without a parameter list");
  static final ParserErrorCode ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE = new ParserErrorCode.con2('ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE', 51, "Illegal assignment to non-assignable expression");
  static final ParserErrorCode IMPLEMENTS_BEFORE_EXTENDS = new ParserErrorCode.con2('IMPLEMENTS_BEFORE_EXTENDS', 52, "The extends clause must be before the implements clause");
  static final ParserErrorCode IMPLEMENTS_BEFORE_WITH = new ParserErrorCode.con2('IMPLEMENTS_BEFORE_WITH', 53, "The with clause must be before the implements clause");
  static final ParserErrorCode IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE = new ParserErrorCode.con2('IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE', 54, "Import directives must preceed part directives");
  static final ParserErrorCode INITIALIZED_VARIABLE_IN_FOR_EACH = new ParserErrorCode.con2('INITIALIZED_VARIABLE_IN_FOR_EACH', 55, "The loop variable in a for-each loop cannot be initialized");
  static final ParserErrorCode INVALID_CODE_POINT = new ParserErrorCode.con2('INVALID_CODE_POINT', 56, "The escape sequence '%s' is not a valid code point");
  static final ParserErrorCode INVALID_COMMENT_REFERENCE = new ParserErrorCode.con2('INVALID_COMMENT_REFERENCE', 57, "Comment references should contain a possibly prefixed identifier and can start with 'new', but should not contain anything else");
  static final ParserErrorCode INVALID_HEX_ESCAPE = new ParserErrorCode.con2('INVALID_HEX_ESCAPE', 58, "An escape sequence starting with '\\x' must be followed by 2 hexidecimal digits");
  static final ParserErrorCode INVALID_OPERATOR = new ParserErrorCode.con2('INVALID_OPERATOR', 59, "The string '%s' is not a valid operator");
  static final ParserErrorCode INVALID_OPERATOR_FOR_SUPER = new ParserErrorCode.con2('INVALID_OPERATOR_FOR_SUPER', 60, "The operator '%s' cannot be used with 'super'");
  static final ParserErrorCode INVALID_UNICODE_ESCAPE = new ParserErrorCode.con2('INVALID_UNICODE_ESCAPE', 61, "An escape sequence starting with '\\u' must be followed by 4 hexidecimal digits or from 1 to 6 digits between '{' and '}'");
  static final ParserErrorCode LIBRARY_DIRECTIVE_NOT_FIRST = new ParserErrorCode.con2('LIBRARY_DIRECTIVE_NOT_FIRST', 62, "The library directive must appear before all other directives");
  static final ParserErrorCode LOCAL_FUNCTION_DECLARATION_MODIFIER = new ParserErrorCode.con2('LOCAL_FUNCTION_DECLARATION_MODIFIER', 63, "Local function declarations cannot specify any modifier");
  static final ParserErrorCode MISSING_ASSIGNABLE_SELECTOR = new ParserErrorCode.con2('MISSING_ASSIGNABLE_SELECTOR', 64, "Missing selector such as \".<identifier>\" or \"[0]\"");
  static final ParserErrorCode MISSING_CATCH_OR_FINALLY = new ParserErrorCode.con2('MISSING_CATCH_OR_FINALLY', 65, "A try statement must have either a catch or finally clause");
  static final ParserErrorCode MISSING_CLASS_BODY = new ParserErrorCode.con2('MISSING_CLASS_BODY', 66, "A class definition must have a body, even if it is empty");
  static final ParserErrorCode MISSING_CLOSING_PARENTHESIS = new ParserErrorCode.con2('MISSING_CLOSING_PARENTHESIS', 67, "The closing parenthesis is missing");
  static final ParserErrorCode MISSING_CONST_FINAL_VAR_OR_TYPE = new ParserErrorCode.con2('MISSING_CONST_FINAL_VAR_OR_TYPE', 68, "Variables must be declared using the keywords 'const', 'final', 'var' or a type name");
  static final ParserErrorCode MISSING_EXPRESSION_IN_THROW = new ParserErrorCode.con2('MISSING_EXPRESSION_IN_THROW', 69, "Throw expressions must compute the object to be thrown");
  static final ParserErrorCode MISSING_FUNCTION_BODY = new ParserErrorCode.con2('MISSING_FUNCTION_BODY', 70, "A function body must be provided");
  static final ParserErrorCode MISSING_FUNCTION_PARAMETERS = new ParserErrorCode.con2('MISSING_FUNCTION_PARAMETERS', 71, "Functions must have an explicit list of parameters");
  static final ParserErrorCode MISSING_IDENTIFIER = new ParserErrorCode.con2('MISSING_IDENTIFIER', 72, "Expected an identifier");
  static final ParserErrorCode MISSING_KEYWORD_OPERATOR = new ParserErrorCode.con2('MISSING_KEYWORD_OPERATOR', 73, "Operator declarations must be preceeded by the keyword 'operator'");
  static final ParserErrorCode MISSING_NAME_IN_LIBRARY_DIRECTIVE = new ParserErrorCode.con2('MISSING_NAME_IN_LIBRARY_DIRECTIVE', 74, "Library directives must include a library name");
  static final ParserErrorCode MISSING_NAME_IN_PART_OF_DIRECTIVE = new ParserErrorCode.con2('MISSING_NAME_IN_PART_OF_DIRECTIVE', 75, "Library directives must include a library name");
  static final ParserErrorCode MISSING_STATEMENT = new ParserErrorCode.con2('MISSING_STATEMENT', 76, "Expected a statement");
  static final ParserErrorCode MISSING_TERMINATOR_FOR_PARAMETER_GROUP = new ParserErrorCode.con2('MISSING_TERMINATOR_FOR_PARAMETER_GROUP', 77, "There is no '%s' to close the parameter group");
  static final ParserErrorCode MISSING_TYPEDEF_PARAMETERS = new ParserErrorCode.con2('MISSING_TYPEDEF_PARAMETERS', 78, "Type aliases for functions must have an explicit list of parameters");
  static final ParserErrorCode MISSING_VARIABLE_IN_FOR_EACH = new ParserErrorCode.con2('MISSING_VARIABLE_IN_FOR_EACH', 79, "A loop variable must be declared in a for-each loop before the 'in', but none were found");
  static final ParserErrorCode MIXED_PARAMETER_GROUPS = new ParserErrorCode.con2('MIXED_PARAMETER_GROUPS', 80, "Cannot have both positional and named parameters in a single parameter list");
  static final ParserErrorCode MULTIPLE_EXTENDS_CLAUSES = new ParserErrorCode.con2('MULTIPLE_EXTENDS_CLAUSES', 81, "Each class definition can have at most one extends clause");
  static final ParserErrorCode MULTIPLE_IMPLEMENTS_CLAUSES = new ParserErrorCode.con2('MULTIPLE_IMPLEMENTS_CLAUSES', 82, "Each class definition can have at most one implements clause");
  static final ParserErrorCode MULTIPLE_LIBRARY_DIRECTIVES = new ParserErrorCode.con2('MULTIPLE_LIBRARY_DIRECTIVES', 83, "Only one library directive may be declared in a file");
  static final ParserErrorCode MULTIPLE_NAMED_PARAMETER_GROUPS = new ParserErrorCode.con2('MULTIPLE_NAMED_PARAMETER_GROUPS', 84, "Cannot have multiple groups of named parameters in a single parameter list");
  static final ParserErrorCode MULTIPLE_PART_OF_DIRECTIVES = new ParserErrorCode.con2('MULTIPLE_PART_OF_DIRECTIVES', 85, "Only one part-of directive may be declared in a file");
  static final ParserErrorCode MULTIPLE_POSITIONAL_PARAMETER_GROUPS = new ParserErrorCode.con2('MULTIPLE_POSITIONAL_PARAMETER_GROUPS', 86, "Cannot have multiple groups of positional parameters in a single parameter list");
  static final ParserErrorCode MULTIPLE_VARIABLES_IN_FOR_EACH = new ParserErrorCode.con2('MULTIPLE_VARIABLES_IN_FOR_EACH', 87, "A single loop variable must be declared in a for-each loop before the 'in', but %s were found");
  static final ParserErrorCode MULTIPLE_WITH_CLAUSES = new ParserErrorCode.con2('MULTIPLE_WITH_CLAUSES', 88, "Each class definition can have at most one with clause");
  static final ParserErrorCode NAMED_FUNCTION_EXPRESSION = new ParserErrorCode.con2('NAMED_FUNCTION_EXPRESSION', 89, "Function expressions cannot be named");
  static final ParserErrorCode NAMED_PARAMETER_OUTSIDE_GROUP = new ParserErrorCode.con2('NAMED_PARAMETER_OUTSIDE_GROUP', 90, "Named parameters must be enclosed in curly braces ('{' and '}')");
  static final ParserErrorCode NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE = new ParserErrorCode.con2('NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE', 91, "Native functions can only be declared in the SDK and code that is loaded through native extensions");
  static final ParserErrorCode NON_CONSTRUCTOR_FACTORY = new ParserErrorCode.con2('NON_CONSTRUCTOR_FACTORY', 92, "Only constructors can be declared to be a 'factory'");
  static final ParserErrorCode NON_IDENTIFIER_LIBRARY_NAME = new ParserErrorCode.con2('NON_IDENTIFIER_LIBRARY_NAME', 93, "The name of a library must be an identifier");
  static final ParserErrorCode NON_PART_OF_DIRECTIVE_IN_PART = new ParserErrorCode.con2('NON_PART_OF_DIRECTIVE_IN_PART', 94, "The part-of directive must be the only directive in a part");
  static final ParserErrorCode NON_USER_DEFINABLE_OPERATOR = new ParserErrorCode.con2('NON_USER_DEFINABLE_OPERATOR', 95, "The operator '%s' is not user definable");
  static final ParserErrorCode NORMAL_BEFORE_OPTIONAL_PARAMETERS = new ParserErrorCode.con2('NORMAL_BEFORE_OPTIONAL_PARAMETERS', 96, "Normal parameters must occur before optional parameters");
  static final ParserErrorCode POSITIONAL_AFTER_NAMED_ARGUMENT = new ParserErrorCode.con2('POSITIONAL_AFTER_NAMED_ARGUMENT', 97, "Positional arguments must occur before named arguments");
  static final ParserErrorCode POSITIONAL_PARAMETER_OUTSIDE_GROUP = new ParserErrorCode.con2('POSITIONAL_PARAMETER_OUTSIDE_GROUP', 98, "Positional parameters must be enclosed in square brackets ('[' and ']')");
  static final ParserErrorCode STATIC_AFTER_CONST = new ParserErrorCode.con2('STATIC_AFTER_CONST', 99, "The modifier 'static' should be before the modifier 'const'");
  static final ParserErrorCode STATIC_AFTER_FINAL = new ParserErrorCode.con2('STATIC_AFTER_FINAL', 100, "The modifier 'static' should be before the modifier 'final'");
  static final ParserErrorCode STATIC_AFTER_VAR = new ParserErrorCode.con2('STATIC_AFTER_VAR', 101, "The modifier 'static' should be before the modifier 'var'");
  static final ParserErrorCode STATIC_CONSTRUCTOR = new ParserErrorCode.con2('STATIC_CONSTRUCTOR', 102, "Constructors cannot be static");
  static final ParserErrorCode STATIC_GETTER_WITHOUT_BODY = new ParserErrorCode.con2('STATIC_GETTER_WITHOUT_BODY', 103, "A 'static' getter must have a body");
  static final ParserErrorCode STATIC_OPERATOR = new ParserErrorCode.con2('STATIC_OPERATOR', 104, "Operators cannot be static");
  static final ParserErrorCode STATIC_SETTER_WITHOUT_BODY = new ParserErrorCode.con2('STATIC_SETTER_WITHOUT_BODY', 105, "A 'static' setter must have a body");
  static final ParserErrorCode STATIC_TOP_LEVEL_DECLARATION = new ParserErrorCode.con2('STATIC_TOP_LEVEL_DECLARATION', 106, "Top-level declarations cannot be declared to be 'static'");
  static final ParserErrorCode SWITCH_HAS_CASE_AFTER_DEFAULT_CASE = new ParserErrorCode.con2('SWITCH_HAS_CASE_AFTER_DEFAULT_CASE', 107, "The 'default' case should be the last case in a switch statement");
  static final ParserErrorCode SWITCH_HAS_MULTIPLE_DEFAULT_CASES = new ParserErrorCode.con2('SWITCH_HAS_MULTIPLE_DEFAULT_CASES', 108, "The 'default' case can only be declared once");
  static final ParserErrorCode TOP_LEVEL_OPERATOR = new ParserErrorCode.con2('TOP_LEVEL_OPERATOR', 109, "Operators must be declared within a class");
  static final ParserErrorCode UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP = new ParserErrorCode.con2('UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP', 110, "There is no '%s' to open a parameter group");
  static final ParserErrorCode UNEXPECTED_TOKEN = new ParserErrorCode.con2('UNEXPECTED_TOKEN', 111, "Unexpected token '%s'");
  static final ParserErrorCode WITH_BEFORE_EXTENDS = new ParserErrorCode.con2('WITH_BEFORE_EXTENDS', 112, "The extends clause must be before the with clause");
  static final ParserErrorCode WITH_WITHOUT_EXTENDS = new ParserErrorCode.con2('WITH_WITHOUT_EXTENDS', 113, "The with clause cannot be used without an extends clause");
  static final ParserErrorCode WRONG_SEPARATOR_FOR_NAMED_PARAMETER = new ParserErrorCode.con2('WRONG_SEPARATOR_FOR_NAMED_PARAMETER', 114, "The default value of a named parameter should be preceeded by ':'");
  static final ParserErrorCode WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER = new ParserErrorCode.con2('WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER', 115, "The default value of a positional parameter should be preceeded by '='");
  static final ParserErrorCode WRONG_TERMINATOR_FOR_PARAMETER_GROUP = new ParserErrorCode.con2('WRONG_TERMINATOR_FOR_PARAMETER_GROUP', 116, "Expected '%s' to close parameter group");
  static final ParserErrorCode VAR_AS_TYPE_NAME = new ParserErrorCode.con2('VAR_AS_TYPE_NAME', 117, "The keyword 'var' cannot be used as a type name");
  static final ParserErrorCode VAR_CLASS = new ParserErrorCode.con2('VAR_CLASS', 118, "Classes cannot be declared to be 'var'");
  static final ParserErrorCode VAR_RETURN_TYPE = new ParserErrorCode.con2('VAR_RETURN_TYPE', 119, "The return type cannot be 'var'");
  static final ParserErrorCode VAR_TYPEDEF = new ParserErrorCode.con2('VAR_TYPEDEF', 120, "Type aliases cannot be declared to be 'var'");
  static final ParserErrorCode VOID_PARAMETER = new ParserErrorCode.con2('VOID_PARAMETER', 121, "Parameters cannot have a type of 'void'");
  static final ParserErrorCode VOID_VARIABLE = new ParserErrorCode.con2('VOID_VARIABLE', 122, "Variables cannot have a type of 'void'");
  static final List<ParserErrorCode> values = [ABSTRACT_CLASS_MEMBER, ABSTRACT_STATIC_METHOD, ABSTRACT_TOP_LEVEL_FUNCTION, ABSTRACT_TOP_LEVEL_VARIABLE, ABSTRACT_TYPEDEF, BREAK_OUTSIDE_OF_LOOP, CONST_AND_FINAL, CONST_AND_VAR, CONST_CLASS, CONST_CONSTRUCTOR_WITH_BODY, CONST_FACTORY, CONST_METHOD, CONST_TYPEDEF, CONSTRUCTOR_WITH_RETURN_TYPE, CONTINUE_OUTSIDE_OF_LOOP, CONTINUE_WITHOUT_LABEL_IN_CASE, DEPRECATED_ARGUMENT_DEFINITION_TEST, DIRECTIVE_AFTER_DECLARATION, DUPLICATE_LABEL_IN_SWITCH_STATEMENT, DUPLICATED_MODIFIER, EQUALITY_CANNOT_BE_EQUALITY_OPERAND, EXPECTED_CASE_OR_DEFAULT, EXPECTED_CLASS_MEMBER, EXPECTED_EXECUTABLE, EXPECTED_LIST_OR_MAP_LITERAL, EXPECTED_STRING_LITERAL, EXPECTED_TOKEN, EXPECTED_TWO_MAP_TYPE_ARGUMENTS, EXPECTED_TYPE_NAME, EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE, EXTERNAL_AFTER_CONST, EXTERNAL_AFTER_FACTORY, EXTERNAL_AFTER_STATIC, EXTERNAL_CLASS, EXTERNAL_CONSTRUCTOR_WITH_BODY, EXTERNAL_FIELD, EXTERNAL_GETTER_WITH_BODY, EXTERNAL_METHOD_WITH_BODY, EXTERNAL_OPERATOR_WITH_BODY, EXTERNAL_SETTER_WITH_BODY, EXTERNAL_TYPEDEF, FACTORY_TOP_LEVEL_DECLARATION, FACTORY_WITHOUT_BODY, FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, FINAL_AND_VAR, FINAL_CLASS, FINAL_CONSTRUCTOR, FINAL_METHOD, FINAL_TYPEDEF, FUNCTION_TYPED_PARAMETER_VAR, GETTER_WITH_PARAMETERS, ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, IMPLEMENTS_BEFORE_EXTENDS, IMPLEMENTS_BEFORE_WITH, IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE, INITIALIZED_VARIABLE_IN_FOR_EACH, INVALID_CODE_POINT, INVALID_COMMENT_REFERENCE, INVALID_HEX_ESCAPE, INVALID_OPERATOR, INVALID_OPERATOR_FOR_SUPER, INVALID_UNICODE_ESCAPE, LIBRARY_DIRECTIVE_NOT_FIRST, LOCAL_FUNCTION_DECLARATION_MODIFIER, MISSING_ASSIGNABLE_SELECTOR, MISSING_CATCH_OR_FINALLY, MISSING_CLASS_BODY, MISSING_CLOSING_PARENTHESIS, MISSING_CONST_FINAL_VAR_OR_TYPE, MISSING_EXPRESSION_IN_THROW, MISSING_FUNCTION_BODY, MISSING_FUNCTION_PARAMETERS, MISSING_IDENTIFIER, MISSING_KEYWORD_OPERATOR, MISSING_NAME_IN_LIBRARY_DIRECTIVE, MISSING_NAME_IN_PART_OF_DIRECTIVE, MISSING_STATEMENT, MISSING_TERMINATOR_FOR_PARAMETER_GROUP, MISSING_TYPEDEF_PARAMETERS, MISSING_VARIABLE_IN_FOR_EACH, MIXED_PARAMETER_GROUPS, MULTIPLE_EXTENDS_CLAUSES, MULTIPLE_IMPLEMENTS_CLAUSES, MULTIPLE_LIBRARY_DIRECTIVES, MULTIPLE_NAMED_PARAMETER_GROUPS, MULTIPLE_PART_OF_DIRECTIVES, MULTIPLE_POSITIONAL_PARAMETER_GROUPS, MULTIPLE_VARIABLES_IN_FOR_EACH, MULTIPLE_WITH_CLAUSES, NAMED_FUNCTION_EXPRESSION, NAMED_PARAMETER_OUTSIDE_GROUP, NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE, NON_CONSTRUCTOR_FACTORY, NON_IDENTIFIER_LIBRARY_NAME, NON_PART_OF_DIRECTIVE_IN_PART, NON_USER_DEFINABLE_OPERATOR, NORMAL_BEFORE_OPTIONAL_PARAMETERS, POSITIONAL_AFTER_NAMED_ARGUMENT, POSITIONAL_PARAMETER_OUTSIDE_GROUP, STATIC_AFTER_CONST, STATIC_AFTER_FINAL, STATIC_AFTER_VAR, STATIC_CONSTRUCTOR, STATIC_GETTER_WITHOUT_BODY, STATIC_OPERATOR, STATIC_SETTER_WITHOUT_BODY, STATIC_TOP_LEVEL_DECLARATION, SWITCH_HAS_CASE_AFTER_DEFAULT_CASE, SWITCH_HAS_MULTIPLE_DEFAULT_CASES, TOP_LEVEL_OPERATOR, UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP, UNEXPECTED_TOKEN, WITH_BEFORE_EXTENDS, WITH_WITHOUT_EXTENDS, WRONG_SEPARATOR_FOR_NAMED_PARAMETER, WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER, WRONG_TERMINATOR_FOR_PARAMETER_GROUP, VAR_AS_TYPE_NAME, VAR_CLASS, VAR_RETURN_TYPE, VAR_TYPEDEF, VOID_PARAMETER, VOID_VARIABLE];

  /// The name of this enum constant, as declared in the enum declaration.
  final String name;

  /// The position in the enum declaration.
  final int ordinal;

  /**
   * The severity of this error.
   */
  ErrorSeverity _severity;

  /**
   * The message template used to create the message to be displayed for this error.
   */
  String _message;

  /**
   * Initialize a newly created error code to have the given severity and message.
   *
   * @param severity the severity of the error
   * @param message the message template used to create the message to be displayed for the error
   */
  ParserErrorCode.con1(this.name, this.ordinal, ErrorSeverity severity, String message) {
    this._severity = severity;
    this._message = message;
  }

  /**
   * Initialize a newly created error code to have the given message and a severity of ERROR.
   *
   * @param message the message template used to create the message to be displayed for the error
   */
  ParserErrorCode.con2(String name, int ordinal, String message) : this.con1(name, ordinal, ErrorSeverity.ERROR, message);
  ErrorSeverity get errorSeverity => _severity;
  String get message => _message;
  ErrorType get type => ErrorType.SYNTACTIC_ERROR;
  int compareTo(ParserErrorCode other) => ordinal - other.ordinal;
  int get hashCode => ordinal;
  String toString() => name;
}
/**
 * Instances of the class {link ToFormattedSourceVisitor} write a source representation of a visited
 * AST node (and all of it's children) to a writer.
 */
class ToFormattedSourceVisitor implements ASTVisitor<Object> {

  /**
   * The writer to which the source is to be written.
   */
  PrintWriter _writer;
  int _indentLevel = 0;
  String _indentString = "";

  /**
   * Initialize a newly created visitor to write source code representing the visited nodes to the
   * given writer.
   *
   * @param writer the writer to which the source is to be written
   */
  ToFormattedSourceVisitor(PrintWriter writer) {
    this._writer = writer;
  }
  Object visitAdjacentStrings(AdjacentStrings node) {
    visitList5(node.strings, " ");
    return null;
  }
  Object visitAnnotation(Annotation node) {
    _writer.print('@');
    visit(node.name);
    visit7(".", node.constructorName);
    visit(node.arguments);
    return null;
  }
  Object visitArgumentDefinitionTest(ArgumentDefinitionTest node) {
    _writer.print('?');
    visit(node.identifier);
    return null;
  }
  Object visitArgumentList(ArgumentList node) {
    _writer.print('(');
    visitList5(node.arguments, ", ");
    _writer.print(')');
    return null;
  }
  Object visitAsExpression(AsExpression node) {
    visit(node.expression);
    _writer.print(" as ");
    visit(node.type);
    return null;
  }
  Object visitAssertStatement(AssertStatement node) {
    _writer.print("assert(");
    visit(node.condition);
    _writer.print(");");
    return null;
  }
  Object visitAssignmentExpression(AssignmentExpression node) {
    visit(node.leftHandSide);
    _writer.print(' ');
    _writer.print(node.operator.lexeme);
    _writer.print(' ');
    visit(node.rightHandSide);
    return null;
  }
  Object visitBinaryExpression(BinaryExpression node) {
    visit(node.leftOperand);
    _writer.print(' ');
    _writer.print(node.operator.lexeme);
    _writer.print(' ');
    visit(node.rightOperand);
    return null;
  }
  Object visitBlock(Block node) {
    _writer.print('{');
    {
      indentInc();
      visitList5(node.statements, "\n");
      indentDec();
    }
    nl2();
    _writer.print('}');
    return null;
  }
  Object visitBlockFunctionBody(BlockFunctionBody node) {
    visit(node.block);
    return null;
  }
  Object visitBooleanLiteral(BooleanLiteral node) {
    _writer.print(node.literal.lexeme);
    return null;
  }
  Object visitBreakStatement(BreakStatement node) {
    _writer.print("break");
    visit7(" ", node.label);
    _writer.print(";");
    return null;
  }
  Object visitCascadeExpression(CascadeExpression node) {
    visit(node.target);
    visitList(node.cascadeSections);
    return null;
  }
  Object visitCatchClause(CatchClause node) {
    visit7("on ", node.exceptionType);
    if (node.catchKeyword != null) {
      if (node.exceptionType != null) {
        _writer.print(' ');
      }
      _writer.print("catch (");
      visit(node.exceptionParameter);
      visit7(", ", node.stackTraceParameter);
      _writer.print(") ");
    } else {
      _writer.print(" ");
    }
    visit(node.body);
    return null;
  }
  Object visitClassDeclaration(ClassDeclaration node) {
    visit(node.documentationComment);
    visit8(node.abstractKeyword, " ");
    _writer.print("class ");
    visit(node.name);
    visit(node.typeParameters);
    visit7(" ", node.extendsClause);
    visit7(" ", node.withClause);
    visit7(" ", node.implementsClause);
    _writer.print(" {");
    {
      indentInc();
      visitList5(node.members, "\n");
      indentDec();
    }
    nl2();
    _writer.print("}");
    return null;
  }
  Object visitClassTypeAlias(ClassTypeAlias node) {
    _writer.print("typedef ");
    visit(node.name);
    visit(node.typeParameters);
    _writer.print(" = ");
    if (node.abstractKeyword != null) {
      _writer.print("abstract ");
    }
    visit(node.superclass);
    visit7(" ", node.withClause);
    visit7(" ", node.implementsClause);
    _writer.print(";");
    return null;
  }
  Object visitComment(Comment node) {
    Token token = node.beginToken;
    while (token != null) {
      bool firstLine = true;
      for (String line in StringUtils.split(token.lexeme, "\n")) {
        if (firstLine) {
          firstLine = false;
          if (node.isDocumentation) {
            nl2();
          }
        } else {
          line = " ${line.trim()}";
          line = StringUtils.replace(line, "/*", "/ *");
        }
        _writer.print(line);
        nl2();
      }
      if (identical(token, node.endToken)) {
        break;
      }
    }
    return null;
  }
  Object visitCommentReference(CommentReference node) => null;
  Object visitCompilationUnit(CompilationUnit node) {
    ScriptTag scriptTag = node.scriptTag;
    NodeList<Directive> directives = node.directives;
    visit(scriptTag);
    String prefix = scriptTag == null ? "" : " ";
    visitList7(prefix, directives, "\n");
    prefix = scriptTag == null && directives.isEmpty ? "" : "\n\n";
    visitList7(prefix, node.declarations, "\n");
    return null;
  }
  Object visitConditionalExpression(ConditionalExpression node) {
    visit(node.condition);
    _writer.print(" ? ");
    visit(node.thenExpression);
    _writer.print(" : ");
    visit(node.elseExpression);
    return null;
  }
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    visit(node.documentationComment);
    visit8(node.externalKeyword, " ");
    visit8(node.constKeyword, " ");
    visit8(node.factoryKeyword, " ");
    visit(node.returnType);
    visit7(".", node.name);
    visit(node.parameters);
    visitList7(" : ", node.initializers, ", ");
    visit7(" = ", node.redirectedConstructor);
    if (node.body is! EmptyFunctionBody) {
      _writer.print(' ');
    }
    visit(node.body);
    return null;
  }
  Object visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    visit8(node.keyword, ".");
    visit(node.fieldName);
    _writer.print(" = ");
    visit(node.expression);
    return null;
  }
  Object visitConstructorName(ConstructorName node) {
    visit(node.type);
    visit7(".", node.name);
    return null;
  }
  Object visitContinueStatement(ContinueStatement node) {
    _writer.print("continue");
    visit7(" ", node.label);
    _writer.print(";");
    return null;
  }
  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    visit8(node.keyword, " ");
    visit6(node.type, " ");
    visit(node.identifier);
    return null;
  }
  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    visit(node.parameter);
    if (node.separator != null) {
      _writer.print(" ");
      _writer.print(node.separator.lexeme);
      visit7(" ", node.defaultValue);
    }
    return null;
  }
  Object visitDoStatement(DoStatement node) {
    _writer.print("do ");
    visit(node.body);
    _writer.print(" while (");
    visit(node.condition);
    _writer.print(");");
    return null;
  }
  Object visitDoubleLiteral(DoubleLiteral node) {
    _writer.print(node.literal.lexeme);
    return null;
  }
  Object visitEmptyFunctionBody(EmptyFunctionBody node) {
    _writer.print(';');
    return null;
  }
  Object visitEmptyStatement(EmptyStatement node) {
    _writer.print(';');
    return null;
  }
  Object visitExportDirective(ExportDirective node) {
    _writer.print("export ");
    visit(node.uri);
    visitList7(" ", node.combinators, " ");
    _writer.print(';');
    return null;
  }
  Object visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _writer.print("=> ");
    visit(node.expression);
    if (node.semicolon != null) {
      _writer.print(';');
    }
    return null;
  }
  Object visitExpressionStatement(ExpressionStatement node) {
    visit(node.expression);
    _writer.print(';');
    return null;
  }
  Object visitExtendsClause(ExtendsClause node) {
    _writer.print("extends ");
    visit(node.superclass);
    return null;
  }
  Object visitFieldDeclaration(FieldDeclaration node) {
    visit(node.documentationComment);
    visit8(node.keyword, " ");
    visit(node.fields);
    _writer.print(";");
    return null;
  }
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    visit8(node.keyword, " ");
    visit6(node.type, " ");
    _writer.print("this.");
    visit(node.identifier);
    visit(node.parameters);
    return null;
  }
  Object visitForEachStatement(ForEachStatement node) {
    _writer.print("for (");
    visit(node.loopVariable);
    _writer.print(" in ");
    visit(node.iterator);
    _writer.print(") ");
    visit(node.body);
    return null;
  }
  Object visitFormalParameterList(FormalParameterList node) {
    String groupEnd = null;
    _writer.print('(');
    NodeList<FormalParameter> parameters = node.parameters;
    int size = parameters.length;
    for (int i = 0; i < size; i++) {
      FormalParameter parameter = parameters[i];
      if (i > 0) {
        _writer.print(", ");
      }
      if (groupEnd == null && parameter is DefaultFormalParameter) {
        if (identical(parameter.kind, ParameterKind.NAMED)) {
          groupEnd = "}";
          _writer.print('{');
        } else {
          groupEnd = "]";
          _writer.print('[');
        }
      }
      parameter.accept(this);
    }
    if (groupEnd != null) {
      _writer.print(groupEnd);
    }
    _writer.print(')');
    return null;
  }
  Object visitForStatement(ForStatement node) {
    Expression initialization = node.initialization;
    _writer.print("for (");
    if (initialization != null) {
      visit(initialization);
    } else {
      visit(node.variables);
    }
    _writer.print(";");
    visit7(" ", node.condition);
    _writer.print(";");
    visitList7(" ", node.updaters, ", ");
    _writer.print(") ");
    visit(node.body);
    return null;
  }
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    visit6(node.returnType, " ");
    visit8(node.propertyKeyword, " ");
    visit(node.name);
    visit(node.functionExpression);
    return null;
  }
  Object visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    visit(node.functionDeclaration);
    _writer.print(';');
    return null;
  }
  Object visitFunctionExpression(FunctionExpression node) {
    visit(node.parameters);
    _writer.print(' ');
    visit(node.body);
    return null;
  }
  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    visit(node.function);
    visit(node.argumentList);
    return null;
  }
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    _writer.print("typedef ");
    visit6(node.returnType, " ");
    visit(node.name);
    visit(node.typeParameters);
    visit(node.parameters);
    _writer.print(";");
    return null;
  }
  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    visit6(node.returnType, " ");
    visit(node.identifier);
    visit(node.parameters);
    return null;
  }
  Object visitHideCombinator(HideCombinator node) {
    _writer.print("hide ");
    visitList5(node.hiddenNames, ", ");
    return null;
  }
  Object visitIfStatement(IfStatement node) {
    _writer.print("if (");
    visit(node.condition);
    _writer.print(") ");
    visit(node.thenStatement);
    visit7(" else ", node.elseStatement);
    return null;
  }
  Object visitImplementsClause(ImplementsClause node) {
    _writer.print("implements ");
    visitList5(node.interfaces, ", ");
    return null;
  }
  Object visitImportDirective(ImportDirective node) {
    _writer.print("import ");
    visit(node.uri);
    visit7(" as ", node.prefix);
    visitList7(" ", node.combinators, " ");
    _writer.print(';');
    return null;
  }
  Object visitIndexExpression(IndexExpression node) {
    if (node.isCascaded) {
      _writer.print("..");
    } else {
      visit(node.array);
    }
    _writer.print('[');
    visit(node.index);
    _writer.print(']');
    return null;
  }
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    visit8(node.keyword, " ");
    visit(node.constructorName);
    visit(node.argumentList);
    return null;
  }
  Object visitIntegerLiteral(IntegerLiteral node) {
    _writer.print(node.literal.lexeme);
    return null;
  }
  Object visitInterpolationExpression(InterpolationExpression node) {
    if (node.rightBracket != null) {
      _writer.print("\${");
      visit(node.expression);
      _writer.print("}");
    } else {
      _writer.print("\$");
      visit(node.expression);
    }
    return null;
  }
  Object visitInterpolationString(InterpolationString node) {
    _writer.print(node.contents.lexeme);
    return null;
  }
  Object visitIsExpression(IsExpression node) {
    visit(node.expression);
    if (node.notOperator == null) {
      _writer.print(" is ");
    } else {
      _writer.print(" is! ");
    }
    visit(node.type);
    return null;
  }
  Object visitLabel(Label node) {
    visit(node.label);
    _writer.print(":");
    return null;
  }
  Object visitLabeledStatement(LabeledStatement node) {
    visitList6(node.labels, " ", " ");
    visit(node.statement);
    return null;
  }
  Object visitLibraryDirective(LibraryDirective node) {
    _writer.print("library ");
    visit(node.name);
    _writer.print(';');
    nl();
    return null;
  }
  Object visitLibraryIdentifier(LibraryIdentifier node) {
    _writer.print(node.name);
    return null;
  }
  Object visitListLiteral(ListLiteral node) {
    if (node.modifier != null) {
      _writer.print(node.modifier.lexeme);
      _writer.print(' ');
    }
    visit6(node.typeArguments, " ");
    _writer.print("[");
    visitList5(node.elements, ", ");
    _writer.print("]");
    return null;
  }
  Object visitMapLiteral(MapLiteral node) {
    if (node.modifier != null) {
      _writer.print(node.modifier.lexeme);
      _writer.print(' ');
    }
    visit6(node.typeArguments, " ");
    _writer.print("{");
    visitList5(node.entries, ", ");
    _writer.print("}");
    return null;
  }
  Object visitMapLiteralEntry(MapLiteralEntry node) {
    visit(node.key);
    _writer.print(" : ");
    visit(node.value);
    return null;
  }
  Object visitMethodDeclaration(MethodDeclaration node) {
    visit(node.documentationComment);
    visit8(node.externalKeyword, " ");
    visit8(node.modifierKeyword, " ");
    visit6(node.returnType, " ");
    visit8(node.propertyKeyword, " ");
    visit8(node.operatorKeyword, " ");
    visit(node.name);
    if (!node.isGetter) {
      visit(node.parameters);
    }
    if (node.body is! EmptyFunctionBody) {
      _writer.print(' ');
    }
    visit(node.body);
    return null;
  }
  Object visitMethodInvocation(MethodInvocation node) {
    if (node.isCascaded) {
      _writer.print("..");
    } else {
      visit6(node.target, ".");
    }
    visit(node.methodName);
    visit(node.argumentList);
    return null;
  }
  Object visitNamedExpression(NamedExpression node) {
    visit(node.name);
    visit7(" ", node.expression);
    return null;
  }
  Object visitNativeFunctionBody(NativeFunctionBody node) {
    _writer.print("native ");
    visit(node.stringLiteral);
    _writer.print(';');
    return null;
  }
  Object visitNullLiteral(NullLiteral node) {
    _writer.print("null");
    return null;
  }
  Object visitParenthesizedExpression(ParenthesizedExpression node) {
    _writer.print('(');
    visit(node.expression);
    _writer.print(')');
    return null;
  }
  Object visitPartDirective(PartDirective node) {
    _writer.print("part ");
    visit(node.uri);
    _writer.print(';');
    return null;
  }
  Object visitPartOfDirective(PartOfDirective node) {
    _writer.print("part of ");
    visit(node.libraryName);
    _writer.print(';');
    return null;
  }
  Object visitPostfixExpression(PostfixExpression node) {
    visit(node.operand);
    _writer.print(node.operator.lexeme);
    return null;
  }
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    visit(node.prefix);
    _writer.print('.');
    visit(node.identifier);
    return null;
  }
  Object visitPrefixExpression(PrefixExpression node) {
    _writer.print(node.operator.lexeme);
    visit(node.operand);
    return null;
  }
  Object visitPropertyAccess(PropertyAccess node) {
    if (node.isCascaded) {
      _writer.print("..");
    } else {
      visit6(node.target, ".");
    }
    visit(node.propertyName);
    return null;
  }
  Object visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    _writer.print("this");
    visit7(".", node.constructorName);
    visit(node.argumentList);
    return null;
  }
  Object visitRethrowExpression(RethrowExpression node) {
    _writer.print("rethrow");
    return null;
  }
  Object visitReturnStatement(ReturnStatement node) {
    Expression expression = node.expression;
    if (expression == null) {
      _writer.print("return;");
    } else {
      _writer.print("return ");
      expression.accept(this);
      _writer.print(";");
    }
    return null;
  }
  Object visitScriptTag(ScriptTag node) {
    _writer.print(node.scriptTag.lexeme);
    return null;
  }
  Object visitShowCombinator(ShowCombinator node) {
    _writer.print("show ");
    visitList5(node.shownNames, ", ");
    return null;
  }
  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    visit8(node.keyword, " ");
    visit6(node.type, " ");
    visit(node.identifier);
    return null;
  }
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    _writer.print(node.token.lexeme);
    return null;
  }
  Object visitSimpleStringLiteral(SimpleStringLiteral node) {
    _writer.print(node.literal.lexeme);
    return null;
  }
  Object visitStringInterpolation(StringInterpolation node) {
    visitList(node.elements);
    return null;
  }
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _writer.print("super");
    visit7(".", node.constructorName);
    visit(node.argumentList);
    return null;
  }
  Object visitSuperExpression(SuperExpression node) {
    _writer.print("super");
    return null;
  }
  Object visitSwitchCase(SwitchCase node) {
    visitList6(node.labels, " ", " ");
    _writer.print("case ");
    visit(node.expression);
    _writer.print(": ");
    {
      indentInc();
      visitList5(node.statements, "\n");
      indentDec();
    }
    return null;
  }
  Object visitSwitchDefault(SwitchDefault node) {
    visitList6(node.labels, " ", " ");
    _writer.print("default: ");
    {
      indentInc();
      visitList5(node.statements, "\n");
      indentDec();
    }
    return null;
  }
  Object visitSwitchStatement(SwitchStatement node) {
    _writer.print("switch (");
    visit(node.expression);
    _writer.print(") {");
    {
      indentInc();
      visitList5(node.members, "\n");
      indentDec();
    }
    nl2();
    _writer.print('}');
    return null;
  }
  Object visitSymbolLiteral(SymbolLiteral node) {
    _writer.print("#");
    visitList5(node.components, ".");
    return null;
  }
  Object visitThisExpression(ThisExpression node) {
    _writer.print("this");
    return null;
  }
  Object visitThrowExpression(ThrowExpression node) {
    _writer.print("throw ");
    visit(node.expression);
    return null;
  }
  Object visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    visit6(node.variables, ";");
    return null;
  }
  Object visitTryStatement(TryStatement node) {
    _writer.print("try ");
    visit(node.body);
    visitList7(" ", node.catchClauses, " ");
    visit7(" finally ", node.finallyClause);
    return null;
  }
  Object visitTypeArgumentList(TypeArgumentList node) {
    _writer.print('<');
    visitList5(node.arguments, ", ");
    _writer.print('>');
    return null;
  }
  Object visitTypeName(TypeName node) {
    visit(node.name);
    visit(node.typeArguments);
    return null;
  }
  Object visitTypeParameter(TypeParameter node) {
    visit(node.name);
    visit7(" extends ", node.bound);
    return null;
  }
  Object visitTypeParameterList(TypeParameterList node) {
    _writer.print('<');
    visitList5(node.typeParameters, ", ");
    _writer.print('>');
    return null;
  }
  Object visitVariableDeclaration(VariableDeclaration node) {
    visit(node.name);
    visit7(" = ", node.initializer);
    return null;
  }
  Object visitVariableDeclarationList(VariableDeclarationList node) {
    visit8(node.keyword, " ");
    visit6(node.type, " ");
    visitList5(node.variables, ", ");
    return null;
  }
  Object visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    visit(node.variables);
    _writer.print(";");
    return null;
  }
  Object visitWhileStatement(WhileStatement node) {
    _writer.print("while (");
    visit(node.condition);
    _writer.print(") ");
    visit(node.body);
    return null;
  }
  Object visitWithClause(WithClause node) {
    _writer.print("with ");
    visitList5(node.mixinTypes, ", ");
    return null;
  }
  void indent() {
    _writer.print(_indentString);
  }
  void indentDec() {
    _indentLevel -= 2;
    _indentString = StringUtils.repeat(" ", _indentLevel);
  }
  void indentInc() {
    _indentLevel += 2;
    _indentString = StringUtils.repeat(" ", _indentLevel);
  }
  void nl() {
    _writer.print("\n");
  }
  void nl2() {
    nl();
    indent();
  }

  /**
   * Safely visit the given node.
   *
   * @param node the node to be visited
   */
  void visit(ASTNode node) {
    if (node != null) {
      node.accept(this);
    }
  }

  /**
   * Safely visit the given node, printing the suffix after the node if it is non-<code>null</code>.
   *
   * @param suffix the suffix to be printed if there is a node to visit
   * @param node the node to be visited
   */
  void visit6(ASTNode node, String suffix) {
    if (node != null) {
      node.accept(this);
      _writer.print(suffix);
    }
  }

  /**
   * Safely visit the given node, printing the prefix before the node if it is non-<code>null</code>
   * .
   *
   * @param prefix the prefix to be printed if there is a node to visit
   * @param node the node to be visited
   */
  void visit7(String prefix, ASTNode node) {
    if (node != null) {
      _writer.print(prefix);
      node.accept(this);
    }
  }

  /**
   * Safely visit the given node, printing the suffix after the node if it is non-<code>null</code>.
   *
   * @param suffix the suffix to be printed if there is a node to visit
   * @param node the node to be visited
   */
  void visit8(Token token, String suffix) {
    if (token != null) {
      _writer.print(token.lexeme);
      _writer.print(suffix);
    }
  }

  /**
   * Print a list of nodes without any separation.
   *
   * @param nodes the nodes to be printed
   * @param separator the separator to be printed between adjacent nodes
   */
  void visitList(NodeList<ASTNode> nodes) {
    visitList5(nodes, "");
  }

  /**
   * Print a list of nodes, separated by the given separator.
   *
   * @param nodes the nodes to be printed
   * @param separator the separator to be printed between adjacent nodes
   */
  void visitList5(NodeList<ASTNode> nodes, String separator) {
    if (nodes != null) {
      int size = nodes.length;
      for (int i = 0; i < size; i++) {
        if ("\n" == separator) {
          _writer.print("\n");
          indent();
        } else if (i > 0) {
          _writer.print(separator);
        }
        nodes[i].accept(this);
      }
    }
  }

  /**
   * Print a list of nodes, separated by the given separator.
   *
   * @param nodes the nodes to be printed
   * @param separator the separator to be printed between adjacent nodes
   * @param suffix the suffix to be printed if the list is not empty
   */
  void visitList6(NodeList<ASTNode> nodes, String separator, String suffix) {
    if (nodes != null) {
      int size = nodes.length;
      if (size > 0) {
        for (int i = 0; i < size; i++) {
          if (i > 0) {
            _writer.print(separator);
          }
          nodes[i].accept(this);
        }
        _writer.print(suffix);
      }
    }
  }

  /**
   * Print a list of nodes, separated by the given separator.
   *
   * @param prefix the prefix to be printed if the list is not empty
   * @param nodes the nodes to be printed
   * @param separator the separator to be printed between adjacent nodes
   */
  void visitList7(String prefix, NodeList<ASTNode> nodes, String separator) {
    if (nodes != null) {
      int size = nodes.length;
      if (size > 0) {
        _writer.print(prefix);
        for (int i = 0; i < size; i++) {
          if (i > 0) {
            _writer.print(separator);
          }
          nodes[i].accept(this);
        }
      }
    }
  }
}