// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Utilities for building JS ASTs at runtime.  Contains a builder class
// and a parser that parses part of the language.

part of js;

class JsBuilder {
  const JsBuilder();

  Expression call(String source) {
    return new MiniJsParser(source).expression();
  }

  LiteralString string(String value) => new LiteralString('"$value"');

  If if_(condition, thenPart, [elsePart]) {
    condition = toExpression(condition);
    return (elsePart == null)
        ? new If.noElse(condition, toStatement(thenPart))
        : new If(condition, toStatement(thenPart), toStatement(elsePart));
  }

  Return return_([value]) {
    return new Return(value == null ? null : toExpression(value));
  }

  Block block(statement) {
    if (statement is Block) {
      return statement;
    } else if (statement is List) {
      return new Block(statement.map(toStatement).toList());
    } else {
      return new Block(<Statement>[toStatement(statement)]);
    }
  }

  Fun fun(parameters, body) {
    Parameter toParameter(parameter) {
      if (parameter is String) {
        return new Parameter(parameter);
      } else if (parameter is Parameter) {
        return parameter;
      } else {
        throw new ArgumentError('parameter should be a String or a Parameter');
      }
    }
    if (parameters is! List) {
      parameters = [parameters];
    }
    return new Fun(parameters.map(toParameter).toList(), block(body));
  }

  Assignment assign(Expression leftHandSide, Expression value) {
    return new Assignment(leftHandSide, value);
  }

  Expression undefined() => new Prefix('void', new LiteralNumber('0'));

  VariableDeclarationList defineVar(String name, [initializer]) {
    if (initializer != null) {
      initializer = toExpression(initializer);
    }
    var declaration = new VariableDeclaration(name);
    var initialization = [new VariableInitialization(declaration, initializer)];
    return new VariableDeclarationList(initialization);
  }

  Statement toStatement(statement) {
    if (statement is List) {
      return new Block(statement.map(toStatement).toList());
    } else if (statement is Node) {
      return statement.toStatement();
    } else {
      throw new ArgumentError('statement');
    }
  }

  Expression toExpression(expression) {
    if (expression is Expression) {
      return expression;
    } else if (expression is String) {
      return this(expression);
    } else if (expression is num) {
      return new LiteralNumber('$expression');
    } else if (expression is bool) {
      return new LiteralBool(expression);
    } else if (expression is Map) {
      if (!expression.isEmpty) {
        throw new ArgumentError('expression should be an empty Map');
      }
      return new ObjectInitializer([]);
    } else {
      throw new ArgumentError('expression should be an Expression, '
                              'a String, a num, a bool, or a Map');
    }
  }

  ForIn forIn(String name, object, statement) {
    return new ForIn(defineVar(name),
                     toExpression(object),
                     toStatement(statement));
  }

  For for_(init, condition, update, statement) {
    return new For(
        toExpression(init), toExpression(condition), toExpression(update),
        toStatement(statement));
  }

  While while_(condition, statement) {
    return new While(
        toExpression(condition), toStatement(statement));
  }

  Try try_(body, {catchPart, finallyPart}) {
    if (catchPart != null) catchPart = toStatement(catchPart);
    if (finallyPart != null) finallyPart = toStatement(finallyPart);
    return new Try(toStatement(body), catchPart, finallyPart);
  }

  Comment comment(String text) => new Comment(text);
}

const JsBuilder js = const JsBuilder();

LiteralString string(String value) => js.string(value);

class MiniJsParserError {
  MiniJsParserError(this.parser, this.message) { }

  MiniJsParser parser;
  String message;

  String toString() {
    var codes = new List.filled(parser.lastPosition, charCodes.$SPACE);
    var spaces = new String.fromCharCodes(codes);
    return "Error in MiniJsParser:\n${parser.src}\n$spaces^\n$spaces$message\n";
  }
}

/// Mini JavaScript parser for tiny snippets of code that we want to make into
/// AST nodes.  Handles:
/// * identifiers.
/// * dot access.
/// * method calls.
/// * [] access.
/// * array, string, boolean, null and numeric literals (no hex).
/// * most operators.
/// * brackets.
/// * var declarations.
/// Notable things it can't do yet include:
/// * operator precedence.
/// * non-empty object literals.
/// * throw, return.
/// * statements, including any flow control (if, while, for, etc.)
/// * the 'in' keyword.
///
/// It's a fairly standard recursive descent parser.
///
/// Literal strings are passed through to the final JS source code unchanged,
/// including the choice of surrounding quotes, so if you parse
/// r'var x = "foo\n\"bar\""' you will end up with
///   var x = "foo\n\"bar\"" in the final program.  String literals are
/// restricted to a small subset of the full set of allowed JS escapes in order
/// to get early errors for unintentional escape sequences without complicating
/// this parser unneccessarily.
class MiniJsParser {
  MiniJsParser(this.src)
      : lastCategory = NONE,
        lastToken = null,
        lastPosition = 0,
        position = 0 {
    getSymbol();
  }

  int lastCategory;
  String lastToken;
  int lastPosition;
  int position;
  String src;

  static const NONE = -1;
  static const ALPHA = 0;
  static const NUMERIC = 1;
  static const STRING = 2;
  static const SYMBOL = 3;
  static const RELATION = 4;
  static const DOT = 5;
  static const LPAREN = 6;
  static const RPAREN = 7;
  static const LBRACE = 8;
  static const RBRACE = 9;
  static const LSQUARE = 10;
  static const RSQUARE = 11;
  static const COMMA = 12;
  static const QUERY = 13;
  static const COLON = 14;
  static const OTHER = 15;

  // Make sure that ]] is two symbols.
  bool singleCharCategory(int category) => category >= DOT;

  static String categoryToString(int cat) {
    switch (cat) {
      case NONE: return "NONE";
      case ALPHA: return "ALPHA";
      case NUMERIC: return "NUMERIC";
      case SYMBOL: return "SYMBOL";
      case RELATION: return "RELATION";
      case DOT: return "DOT";
      case LPAREN: return "LPAREN";
      case RPAREN: return "RPAREN";
      case LBRACE: return "LBRACE";
      case RBRACE: return "RBRACE";
      case RSQUARE: return "RSQUARE";
      case STRING: return "STRING";
      case COMMA: return "COMMA";
      case QUERY: return "QUERY";
      case COLON: return "COLON";
      case OTHER: return "OTHER";
    }
    return "Unknown: $cat";
  }

  static const CATEGORIES = const <int>[
      OTHER, OTHER, OTHER, OTHER, OTHER, OTHER, OTHER, OTHER,       // 0-7
      OTHER, OTHER, OTHER, OTHER, OTHER, OTHER, OTHER, OTHER,       // 8-15
      OTHER, OTHER, OTHER, OTHER, OTHER, OTHER, OTHER, OTHER,       // 16-23
      OTHER, OTHER, OTHER, OTHER, OTHER, OTHER, OTHER, OTHER,       // 24-31
      OTHER, RELATION, OTHER, OTHER, ALPHA, SYMBOL, SYMBOL, OTHER,  //  !"#$%&´
      LPAREN, RPAREN, SYMBOL, SYMBOL, COMMA, SYMBOL, DOT, SYMBOL,   // ()*+,-./
      NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC,                  // 01234
      NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC,                  // 56789
      COLON, OTHER, RELATION, RELATION, RELATION, QUERY, OTHER,     // :;<=>?@
      ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA,       // ABCDEFGH
      ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA,       // IJKLMNOP
      ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA,       // QRSTUVWX
      ALPHA, ALPHA, LSQUARE, OTHER, RSQUARE, SYMBOL, ALPHA, OTHER,  // YZ[\]^_'
      ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA,       // abcdefgh
      ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA,       // ijklmnop
      ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA,       // qrstuvwx
      ALPHA, ALPHA, LBRACE, SYMBOL, RBRACE, SYMBOL];                // yz{|}~

  static final BINARY_OPERATORS = [
      '+', '-', '*', '/', '%', '^', '|', '&', '||', '&&', '<<', '>>', '>>>',
      '+=', '-=', '*=', '/=', '%=', '^=', '|=', '&=', '<<=', '>>=', '>>>=',
      '=', '!=', '==', '!==', '===', '<', '<=', '>=', '>'].toSet();
  static final UNARY_OPERATORS = ['++', '--', '+', '-', '~', '!'].toSet();

  static int category(int code) {
    if (code >= CATEGORIES.length) return OTHER;
    return CATEGORIES[code];
  }

  void getSymbol() {
    while (position < src.length &&
           src.codeUnitAt(position) == charCodes.$SPACE) {
      position++;
    }
    if (position == src.length) {
      lastCategory = NONE;
      lastToken = null;
      lastPosition = position;
      return;
    }
    int code = src.codeUnitAt(position);
    lastPosition = position;
    if (code == charCodes.$SQ || code == charCodes.$DQ) {
      int currentCode;
      do {
        position++;
        if (position >= src.length) {
          throw new MiniJsParserError(this, "Unterminated string");
        }
        currentCode = src.codeUnitAt(position);
        if (currentCode == charCodes.$BACKSLASH) {
          if (++position >= src.length) {
            throw new MiniJsParserError(this, "Unterminated string");
          }
          int escapedCode = src.codeUnitAt(position);
          if (!(escapedCode == charCodes.$BACKSLASH ||
                escapedCode == charCodes.$SQ ||
                escapedCode == charCodes.$DQ ||
                escapedCode == charCodes.$n)) {
            throw new MiniJsParserError(
                this,
                'Only escapes allowed in string literals are '
                r'''\\, \', \" and \n''');
          }
        }
      } while (currentCode != code);
      lastCategory = STRING;
      position++;
      lastToken = src.substring(lastPosition, position);
    } else {
      int cat = category(src.codeUnitAt(position));
      int newCat;
      do {
        position++;
        if (position == src.length) break;
        newCat = category(src.codeUnitAt(position));
      } while (!singleCharCategory(cat) &&
               (cat == newCat ||
                (cat == ALPHA && newCat == NUMERIC) ||    // eg. level42.
                (cat == NUMERIC && newCat == DOT) ||      // eg. 3.1415
                (cat == SYMBOL && newCat == RELATION)));  // eg. +=.
      lastCategory = cat;
      lastToken = src.substring(lastPosition, position);
      if (cat == NUMERIC) {
        double.parse(lastToken, (_) {
          throw new MiniJsParserError(this, "Unparseable number");
        });
      } else if (cat == SYMBOL || cat == RELATION) {
        if (!BINARY_OPERATORS.contains(lastToken) &&
            !UNARY_OPERATORS.contains(lastToken)) {
          throw new MiniJsParserError(this, "Unknown operator");
        }
      }
    }
  }

  void expectCategory(int cat) {
    if (cat != lastCategory) {
      throw new MiniJsParserError(this, "Expected ${categoryToString(cat)}");
    }
    getSymbol();
  }

  bool acceptCategory(int cat) {
    if (cat == lastCategory) {
      getSymbol();
      return true;
    }
    return false;
  }

  bool acceptString(String string) {
    if (lastToken == string) {
      getSymbol();
      return true;
    }
    return false;
  }

  Expression parsePrimary() {
    String last = lastToken;
    if (acceptCategory(ALPHA)) {
      if (last == "true") {
        return new LiteralBool(true);
      } else if (last == "false") {
        return new LiteralBool(false);
      } else if (last == "null") {
        return new LiteralNull();
      } else {
        return new VariableUse(last);
      }
    } else if (acceptCategory(LPAREN)) {
      Expression expression = parseExpression();
      expectCategory(RPAREN);
      return expression;
    } else if (acceptCategory(STRING)) {
      return new LiteralString(last);
    } else if (acceptCategory(NUMERIC)) {
      return new LiteralNumber(last);
    } else if (acceptCategory(LBRACE)) {
      expectCategory(RBRACE);
      return new ObjectInitializer([]);
    } else if (acceptCategory(LSQUARE)) {
      var values = <ArrayElement>[];
      if (!acceptCategory(RSQUARE)) {
        do {
          values.add(new ArrayElement(values.length, parseExpression()));
        } while (acceptCategory(COMMA));
        expectCategory(RSQUARE);
      }
      return new ArrayInitializer(values.length, values);
    } else {
      throw new MiniJsParserError(this, "Expected primary expression");
    }
  }

  Expression parseMember() {
    Expression receiver = parsePrimary();
    while (true) {
      if (acceptCategory(DOT)) {
        String identifier = lastToken;
        expectCategory(ALPHA);
        receiver = new PropertyAccess.field(receiver, identifier);
      } else if (acceptCategory(LSQUARE)) {
        Expression inBraces = parseExpression();
        expectCategory(RSQUARE);
        receiver = new PropertyAccess(receiver, inBraces);
      } else {
        return receiver;
      }
    }
  }

  Expression parseCall() {
    bool constructor = acceptString("new");
    Expression receiver = parseMember();
    if (acceptCategory(LPAREN)) {
      final arguments = <Expression>[];
      if (!acceptCategory(RPAREN)) {
        while (true) {
          Expression argument = parseExpression();
          arguments.add(argument);
          if (acceptCategory(RPAREN)) break;
          expectCategory(COMMA);
        }
      }
      return constructor ?
             new New(receiver, arguments) :
             new Call(receiver, arguments);
    } else {
      if (constructor) {
        // JS allows new without (), but we don't.
        throw new MiniJsParserError(this, "Parentheses are required for new");
      }
      return receiver;
    }
  }

  Expression parsePostfix() {
    Expression expression = parseCall();
    String operator = lastToken;
    if (lastCategory == SYMBOL && (acceptString("++") || acceptString("--"))) {
      return new Postfix(operator, expression);
    }
    return expression;
  }

  Expression parseUnary() {
    String operator = lastToken;
    if (lastCategory == ALPHA) {
     if (acceptString("typeof") || acceptString("void") ||
         acceptString("delete")) {
        return new Prefix(operator, parsePostfix());
     }
    } else if (lastCategory == SYMBOL) {
      if (acceptString("~") || acceptString("-") || acceptString("++") ||
          acceptString("--") || acceptString("+")) {
        return new Prefix(operator, parsePostfix());
      }
    } else if (acceptString("!")) {
      return new Prefix(operator, parsePostfix());
    }
    return parsePostfix();
  }

  Expression parseBinary() {
    // Since we don't handle precedence we don't allow two different symbols
    // without parentheses.
    Expression lhs = parseUnary();
    String firstSymbol = lastToken;
    while (true) {
      String symbol = lastToken;
      if (!acceptCategory(SYMBOL)) return lhs;
      if (!BINARY_OPERATORS.contains(symbol)) {
        throw new MiniJsParserError(this, "Unknown binary operator");
      }
      if (symbol != firstSymbol) {
        throw new MiniJsParserError(
            this, "Mixed $firstSymbol and $symbol operators without ()");
      }
      Expression rhs = parseUnary();
      if (symbol.endsWith("=")) {
        // +=, -=, *= etc.
        lhs = new Assignment.compound(lhs,
                                      symbol.substring(0, symbol.length - 1),
                                      rhs);
      } else {
        lhs = new Binary(symbol, lhs, rhs);
      }
    }
  }

  Expression parseRelation() {
    Expression lhs = parseBinary();
    String relation = lastToken;
    // The lexer returns "=" as a relational operator because it looks a bit
    // like ==, <=, etc.  But we don't want to handle it here (that would give
    // it the wrong prescedence), so we just return if we see it.
    if (relation == "=" || !acceptCategory(RELATION)) return lhs;
    Expression rhs = parseBinary();
    if (relation == "<<=" || relation == ">>=" || relation == ">>>=") {
      return new Assignment.compound(lhs,
                                     relation.substring(0, relation.length - 1),
                                     rhs);
    } else {
      // Regular binary operation.
      return new Binary(relation, lhs, rhs);
    }
  }

  Expression parseConditional() {
    Expression lhs = parseRelation();
    if (!acceptCategory(QUERY)) return lhs;
    Expression ifTrue = parseAssignment();
    expectCategory(COLON);
    Expression ifFalse = parseAssignment();
    return new Conditional(lhs, ifTrue, ifFalse);
  }


  Expression parseAssignment() {
    Expression lhs = parseConditional();
    if (acceptString("=")) {
      return new Assignment(lhs, parseAssignment());
    }
    return lhs;
  }

  Expression parseExpression() => parseAssignment();

  Expression parseVarDeclarationOrExpression() {
    if (acceptString("var")) {
      var initialization = [];
      do {
        String variable = lastToken;
        expectCategory(ALPHA);
        Expression initializer = null;
        if (acceptString("=")) {
          initializer = parseExpression();
        }
        var declaration = new VariableDeclaration(variable);
        initialization.add(
            new VariableInitialization(declaration, initializer));
      } while (acceptCategory(COMMA));
      return new VariableDeclarationList(initialization);
    } else {
      return parseExpression();
    }
  }

  Expression expression() {
    Expression expression = parseVarDeclarationOrExpression();
    if (lastCategory != NONE || position != src.length) {
      throw new MiniJsParserError(
          this, "Unparsed junk: ${categoryToString(lastCategory)}");
    }
    return expression;
  }
}
