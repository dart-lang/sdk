// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Utilities for building JS ASTs at runtime.  Contains a builder class
// and a parser that parses part of the language.

part of js;

class JsBuilder {
  const JsBuilder();

  /**
   * Parses a bit of JavaScript, and returns an expression.
   *
   * See the MiniJsParser class.
   *
   * [expression] can be an [Expression] or a list of [Expression]s, which will
   * be interpolated into the source at the '#' signs.
   */
  Expression call(String source, [var expression]) {
    Expression result = new MiniJsParser(source).expression();
    if (expression == null) return result;

    List<Node> nodes;
    if (expression is List) {
      nodes = expression;
    } else {
      nodes = <Node>[expression];
    }
    if (nodes.length != result.interpolatedNodes.length) {
      throw 'Unmatched number of interpolated expressions given ${nodes.length}'
          ' expected ${result.interpolatedNodes.length}';
    }
    for (int i = 0; i < nodes.length; i++) {
      result.interpolatedNodes[i].assign(nodes[i]);
    }

    return result.value;
  }

  Statement statement(String source) {
    var result = new MiniJsParser(source).statement();
    // TODO(sra): Interpolation.
    return result;
  }

  // Parse JavaScript written in the JS foreign instruction.
  Expression parseForeignJS(String source, [var expression]) {
    // We can parse simple JS with the mini parser.  At the moment we can't
    // handle JSON literals and function literals, both of which contain "{".
    if (source.contains("{") || source.startsWith("throw ")) {
      assert(expression == null);
      return new LiteralExpression(source);
    }
    return call(source, expression);
  }

  /// Creates a litteral js string from [value].
  LiteralString escapedString(String value) {
    // Do not escape unicode characters and ' because they are allowed in the
    // string literal anyway.
    String escaped =
        value.replaceAllMapped(new RegExp('\n|"|\\|\0|\b|\t|\v'), (match) {
      switch (match.group(0)) {
        case "\n" : return r"\n";
        case "\\" : return r"\\";
        case "\"" : return r'\"';
        case "\0" : return r"\0";
        case "\b" : return r"\b";
        case "\t" : return r"\t";
        case "\f" : return r"\f";
        case "\v" : return r"\v";
      }
    });
    LiteralString result = string(escaped);
    // We don't escape ' under the assumption that the string is wrapped
    // into ". Verify that assumption.
    assert(result.value.codeUnitAt(0) == '"'.codeUnitAt(0));
    return result;
  }

  /// Creates a litteral js string from [value].
  ///
  /// Note that this function only puts quotes around [value]. It does not do
  /// any escaping, so use only when you can guarantee that [value] does not
  /// contain newlines or backslashes. For escaping the string use
  /// [escapedString].
  LiteralString string(String value) => new LiteralString('"$value"');

  LiteralNumber number(num value) => new LiteralNumber('$value');

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
      List<Statement> statements = statement
          .map(toStatement)
          .where((s) => s is !EmptyStatement)
          .toList();
      return new Block(statements);
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
      return block(statement);
    } else if (statement is Node) {
      return statement.toStatement();
    } else {
      throw new ArgumentError('statement');
    }
  }

  Expression toExpression(expression) {
    if (expression == null) {
      return null;
    } else if (expression is Expression) {
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
    } else if (expression is List) {
      var values = new List<ArrayElement>.generate(expression.length,
          (index) => new ArrayElement(index, toExpression(expression[index])));
      return new ArrayInitializer(values.length, values);
    } else {
      throw new ArgumentError('expression should be an Expression, '
                              'a String, a num, a bool, a Map, or a List;');
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

  final MiniJsParser parser;
  final String message;

  String toString() {
    int pos = parser.lastPosition;

    // Discard lines following the line containing lastPosition.
    String src = parser.src;
    int newlinePos = src.indexOf('\n', pos);
    if (newlinePos >= pos) src = src.substring(0, newlinePos);

    // Extract the prefix of the error line before lastPosition.
    String line = src;
    int lastLineStart = line.lastIndexOf('\n');
    if (lastLineStart >= 0) line = line.substring(lastLineStart + 1);
    String prefix = line.substring(0, pos - (src.length - line.length));

    // Replace non-tabs with spaces, giving a print indent that matches the text
    // for tabbing.
    String spaces = prefix.replaceAll(new RegExp(r'[^\t]'), ' ');
    return 'Error in MiniJsParser:\n${src}\n$spaces^\n$spaces$message\n';
  }
}

/// Mini JavaScript parser for tiny snippets of code that we want to make into
/// AST nodes.  Handles:
/// * identifiers.
/// * dot access.
/// * method calls.
/// * [] access.
/// * array, string, regexp, boolean, null and numeric literals.
/// * most operators.
/// * brackets.
/// * var declarations.
/// * operator precedence.
/// Notable things it can't do yet include:
/// * non-empty object literals.
/// * throw, return.
/// * statements, including any flow control (if, while, for, etc.)
///
/// It's a fairly standard recursive descent parser.
///
/// Literal strings are passed through to the final JS source code unchanged,
/// including the choice of surrounding quotes, so if you parse
/// r'var x = "foo\n\"bar\""' you will end up with
///   var x = "foo\n\"bar\"" in the final program.  \x and \u escapes are not
/// allowed in string and regexp literals because the machinery for checking
/// their correctness is rather involved.
class MiniJsParser {
  MiniJsParser(this.src)
      : lastCategory = NONE,
        lastToken = null,
        lastPosition = 0,
        position = 0 {
    getToken();
  }

  int lastCategory = NONE;
  String lastToken = null;
  int lastPosition = 0;
  int position = 0;
  bool skippedNewline = false;  // skipped newline in last getToken?
  final String src;
  final List<InterpolatedNode> interpolatedValues = <InterpolatedNode>[];

  static const NONE = -1;
  static const ALPHA = 0;
  static const NUMERIC = 1;
  static const STRING = 2;
  static const SYMBOL = 3;
  static const ASSIGNMENT = 4;
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
  static const SEMICOLON = 15;
  static const HASH = 16;
  static const WHITESPACE = 17;
  static const OTHER = 18;

  // Make sure that ]] is two symbols.
  bool singleCharCategory(int category) => category >= DOT;

  static String categoryToString(int cat) {
    switch (cat) {
      case NONE: return "NONE";
      case ALPHA: return "ALPHA";
      case NUMERIC: return "NUMERIC";
      case SYMBOL: return "SYMBOL";
      case ASSIGNMENT: return "ASSIGNMENT";
      case DOT: return "DOT";
      case LPAREN: return "LPAREN";
      case RPAREN: return "RPAREN";
      case LBRACE: return "LBRACE";
      case RBRACE: return "RBRACE";
      case LSQUARE: return "LSQUARE";
      case RSQUARE: return "RSQUARE";
      case STRING: return "STRING";
      case COMMA: return "COMMA";
      case QUERY: return "QUERY";
      case COLON: return "COLON";
      case SEMICOLON: return "SEMICOLON";
      case HASH: return "HASH";
      case WHITESPACE: return "WHITESPACE";
      case OTHER: return "OTHER";
    }
    return "Unknown: $cat";
  }

  static const CATEGORIES = const <int>[
      OTHER, OTHER, OTHER, OTHER, OTHER, OTHER, OTHER, OTHER,       // 0-7
      OTHER, WHITESPACE, WHITESPACE, OTHER, OTHER, WHITESPACE,      // 8-13
      OTHER, OTHER, OTHER, OTHER, OTHER, OTHER, OTHER, OTHER,       // 14-21
      OTHER, OTHER, OTHER, OTHER, OTHER, OTHER, OTHER, OTHER,       // 22-29
      OTHER, OTHER, WHITESPACE,                                     // 30-32
      SYMBOL, OTHER, HASH, ALPHA, SYMBOL, SYMBOL, OTHER,            // !"#$%&´
      LPAREN, RPAREN, SYMBOL, SYMBOL, COMMA, SYMBOL, DOT, SYMBOL,   // ()*+,-./
      NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC,                  // 01234
      NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC,                  // 56789
      COLON, SEMICOLON, SYMBOL, SYMBOL, SYMBOL, QUERY, OTHER,       // :;<=>?@
      ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA,       // ABCDEFGH
      ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA,       // IJKLMNOP
      ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA,       // QRSTUVWX
      ALPHA, ALPHA, LSQUARE, OTHER, RSQUARE, SYMBOL, ALPHA, OTHER,  // YZ[\]^_'
      ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA,       // abcdefgh
      ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA,       // ijklmnop
      ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA,       // qrstuvwx
      ALPHA, ALPHA, LBRACE, SYMBOL, RBRACE, SYMBOL];                // yz{|}~

  // This must be a >= the highest precedence number handled by parseBinary.
  static var HIGHEST_PARSE_BINARY_PRECEDENCE = 16;
  static bool isAssignment(String symbol) => BINARY_PRECEDENCE[symbol] == 17;

  // From https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Operators/Operator_Precedence
  static final BINARY_PRECEDENCE = {
      '+=': 17, '-=': 17, '*=': 17, '/=': 17, '%=': 17, '^=': 17, '|=': 17,
      '&=': 17, '<<=': 17, '>>=': 17, '>>>=': 17, '=': 17,
      '||': 14,
      '&&': 13,
      '|': 12,
      '^': 11,
      '&': 10,
      '!=': 9, '==': 9, '!==': 9, '===': 9,
      '<': 8, '<=': 8, '>=': 8, '>': 8, 'in': 8, 'instanceof': 8,
      '<<': 7, '>>': 7, '>>>': 7,
      '+': 6, '-': 6,
      '*': 5, '/': 5, '%': 5
  };
  static final UNARY_OPERATORS =
      ['++', '--', '+', '-', '~', '!', 'typeof', 'void', 'delete'].toSet();

  static final OPERATORS_THAT_LOOK_LIKE_IDENTIFIERS =
      ['typeof', 'void', 'delete', 'in', 'instanceof'].toSet();

  static int category(int code) {
    if (code >= CATEGORIES.length) return OTHER;
    return CATEGORIES[code];
  }

  String getDelimited(int startPosition) {
    position = startPosition;
    int delimiter = src.codeUnitAt(startPosition);
    int currentCode;
    do {
      position++;
      if (position >= src.length) error("Unterminated literal");
      currentCode = src.codeUnitAt(position);
      if (currentCode == charCodes.$LF) error("Unterminated literal");
      if (currentCode == charCodes.$BACKSLASH) {
        if (++position >= src.length) error("Unterminated literal");
        int escaped = src.codeUnitAt(position);
        if (escaped == charCodes.$x || escaped == charCodes.$X ||
            escaped == charCodes.$u || escaped == charCodes.$U ||
            category(escaped) == NUMERIC) {
          error('Numeric and hex escapes are not allowed in literals');
        }
      }
    } while (currentCode != delimiter);
    position++;
    return src.substring(lastPosition, position);
  }

  void getToken() {
    skippedNewline = false;
    for (;;) {
      if (position >= src.length) break;
      int code = src.codeUnitAt(position);
      //  Skip '//' style comment.
      if (code == charCodes.$SLASH &&
          position + 1 < src.length &&
          src.codeUnitAt(position + 1) == charCodes.$SLASH) {
        int nextPosition = src.indexOf('\n', position);
        if (nextPosition == -1) nextPosition = src.length;
        position = nextPosition;
      } else {
        if (category(code) != WHITESPACE) break;
        if (code == charCodes.$LF) skippedNewline = true;
        ++position;
      }
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
      // String literal.
      lastCategory = STRING;
      lastToken = getDelimited(position);
    } else if (code == charCodes.$0 &&
               position + 2 < src.length &&
               src.codeUnitAt(position + 1) == charCodes.$x) {
      // Hex literal.
      for (position += 2; position < src.length; position++) {
        int cat = category(src.codeUnitAt(position));
        if (cat != NUMERIC && cat != ALPHA) break;
      }
      lastCategory = NUMERIC;
      lastToken = src.substring(lastPosition, position);
      int.parse(lastToken, onError: (_) {
        error("Unparseable number");
      });
    } else if (code == charCodes.$SLASH) {
      // Tokens that start with / are special due to regexp literals.
      lastCategory = SYMBOL;
      position++;
      if (position < src.length && src.codeUnitAt(position) == charCodes.$EQ) {
        position++;
      }
      lastToken = src.substring(lastPosition, position);
    } else {
      // All other tokens handled here.
      int cat = category(src.codeUnitAt(position));
      int newCat;
      do {
        position++;
        if (position == src.length) break;
        int code = src.codeUnitAt(position);
        // Special code to disallow ! and / in non-first position in token, so
        // that !! parses as two tokens and != parses as one, while =/ parses
        // as a an equals token followed by a regexp literal start.
        newCat = (code == charCodes.$BANG || code == charCodes.$SLASH)
            ?  NONE
            : category(code);
      } while (!singleCharCategory(cat) &&
               (cat == newCat ||
                (cat == ALPHA && newCat == NUMERIC) ||    // eg. level42.
                (cat == NUMERIC && newCat == DOT)));      // eg. 3.1415
      lastCategory = cat;
      lastToken = src.substring(lastPosition, position);
      if (cat == NUMERIC) {
        double.parse(lastToken, (_) {
          error("Unparseable number");
        });
      } else if (cat == SYMBOL) {
        int binaryPrecendence = BINARY_PRECEDENCE[lastToken];
        if (binaryPrecendence == null && !UNARY_OPERATORS.contains(lastToken)) {
          error("Unknown operator");
        }
        if (isAssignment(lastToken)) lastCategory = ASSIGNMENT;
      } else if (cat == ALPHA) {
        if (OPERATORS_THAT_LOOK_LIKE_IDENTIFIERS.contains(lastToken)) {
          lastCategory = SYMBOL;
        }
      }
    }
  }

  void expectCategory(int cat) {
    if (cat != lastCategory) error("Expected ${categoryToString(cat)}");
    getToken();
  }

  bool acceptCategory(int cat) {
    if (cat == lastCategory) {
      getToken();
      return true;
    }
    return false;
  }

  void expectSemicolon() {
    if (acceptSemicolon()) return;
    error('Expected SEMICOLON');
  }

  bool acceptSemicolon() {
    // Accept semicolon or automatically inserted semicolon before close brace.
    // Miniparser forbids other kinds of semicolon insertion.
    if (RBRACE == lastCategory) return true;
    if (skippedNewline) {
      error('No automatic semicolon insertion at preceding newline');
    }
    return acceptCategory(SEMICOLON);
  }

  bool acceptString(String string) {
    if (lastToken == string) {
      getToken();
      return true;
    }
    return false;
  }

  void error(message) {
    throw new MiniJsParserError(this, message);
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
      } else if (last == "function") {
        return parseFunctionExpression();
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
      return parseObjectInitializer();
    } else if (acceptCategory(LSQUARE)) {
      var values = <ArrayElement>[];
      if (!acceptCategory(RSQUARE)) {
        do {
          values.add(new ArrayElement(values.length, parseAssignment()));
        } while (acceptCategory(COMMA));
        expectCategory(RSQUARE);
      }
      return new ArrayInitializer(values.length, values);
    } else if (last.startsWith("/")) {
      String regexp = getDelimited(lastPosition);
      getToken();
      String flags = lastToken;
      if (!acceptCategory(ALPHA)) flags = "";
      Expression expression = new RegExpLiteral(regexp + flags);
      return expression;
    } else if (acceptCategory(HASH)) {
      InterpolatedExpression expression = new InterpolatedExpression(null);
      interpolatedValues.add(expression);
      return expression;
    } else {
      error("Expected primary expression");
      return null;
    }
  }

  Expression parseFunctionExpression() {
    String last = lastToken;
    if (acceptCategory(ALPHA)) {
      String functionName = last;
      return new NamedFunction(new VariableDeclaration(functionName),
          parseFun());
    }
    return parseFun();
  }

  Expression parseFun() {
    List<Parameter> params = <Parameter>[];
    expectCategory(LPAREN);
    String argumentName = lastToken;
    if (acceptCategory(ALPHA)) {
      params.add(new Parameter(argumentName));
      while (acceptCategory(COMMA)) {
        argumentName = lastToken;
        expectCategory(ALPHA);
        params.add(new Parameter(argumentName));
      }
    }
    expectCategory(RPAREN);
    expectCategory(LBRACE);
    Block block = parseBlock();
    return new Fun(params, block);
  }

  Expression parseObjectInitializer() {
    List<Property> properties = <Property>[];
    for (;;) {
      if (acceptCategory(RBRACE)) break;
      // Limited subset: keys are identifiers, no 'get' or 'set' properties.
      Literal propertyName;
      String identifier = lastToken;
      if (acceptCategory(ALPHA)) {
        propertyName = new LiteralString('"$identifier"');
      } else if (acceptCategory(STRING)) {
        propertyName = new LiteralString(identifier);
      } else {
        error('Expected property name');
      }
      expectCategory(COLON);
      Expression value = parseAssignment();
      properties.add(new Property(propertyName, value));
      if (acceptCategory(RBRACE)) break;
      expectCategory(COMMA);
    }
    return new ObjectInitializer(properties);
  }

  Expression parseMember() {
    Expression receiver = parsePrimary();
    while (true) {
      if (acceptCategory(DOT)) {
        receiver = getDotRhs(receiver);
      } else if (acceptCategory(LSQUARE)) {
        Expression inBraces = parseExpression();
        expectCategory(RSQUARE);
        receiver = new PropertyAccess(receiver, inBraces);
      } else {
        break;
      }
    }
    return receiver;
  }

  Expression parseCall() {
    bool constructor = acceptString("new");
    Expression receiver = parseMember();
    while (true) {
      if (acceptCategory(LPAREN)) {
        final arguments = <Expression>[];
        if (!acceptCategory(RPAREN)) {
          while (true) {
            Expression argument = parseAssignment();
            arguments.add(argument);
            if (acceptCategory(RPAREN)) break;
            expectCategory(COMMA);
          }
        }
        receiver = constructor ?
               new New(receiver, arguments) :
               new Call(receiver, arguments);
        constructor = false;
      } else if (!constructor && acceptCategory(LSQUARE)) {
        Expression inBraces = parseExpression();
        expectCategory(RSQUARE);
        receiver = new PropertyAccess(receiver, inBraces);
      } else if (!constructor && acceptCategory(DOT)) {
        receiver = getDotRhs(receiver);
      } else {
        // JS allows new without (), but we don't.
        if (constructor) error("Parentheses are required for new");
        break;
      }
    }
    return receiver;
  }

  Expression getDotRhs(Expression receiver) {
    String identifier = lastToken;
    // In ES5 keywords like delete and continue are allowed as property
    // names, and the IndexedDB API uses that, so we need to allow it here.
    if (acceptCategory(SYMBOL)) {
      if (!OPERATORS_THAT_LOOK_LIKE_IDENTIFIERS.contains(identifier)) {
        error("Expected alphanumeric identifier");
      }
    } else {
      expectCategory(ALPHA);
    }
    return new PropertyAccess.field(receiver, identifier);
  }

  Expression parsePostfix() {
    Expression expression = parseCall();
    String operator = lastToken;
    // JavaScript grammar is:
    //     LeftHandSideExpression [no LineTerminator here] ++
    if (lastCategory == SYMBOL &&
        !skippedNewline &&
        (acceptString("++") || acceptString("--"))) {
      return new Postfix(operator, expression);
    }
    // If we don't accept '++' or '--' due to skippedNewline a newline, no other
    // part of the parser will accept the token and we will get an error at the
    // whole expression level.
    return expression;
  }

  Expression parseUnaryHigh() {
    String operator = lastToken;
    if (lastCategory == SYMBOL && UNARY_OPERATORS.contains(operator) &&
        (acceptString("++") || acceptString("--"))) {
      return new Prefix(operator, parsePostfix());
    }
    return parsePostfix();
  }

  Expression parseUnaryLow() {
    String operator = lastToken;
    if (lastCategory == SYMBOL && UNARY_OPERATORS.contains(operator) &&
        operator != "++" && operator != "--") {
      expectCategory(SYMBOL);
      return new Prefix(operator, parseUnaryLow());
    }
    return parseUnaryHigh();
  }

  Expression parseBinary(int maxPrecedence) {
    Expression lhs = parseUnaryLow();
    int minPrecedence;
    String lastSymbol;
    Expression rhs;  // This is null first time around.
    while (true) {
      String symbol = lastToken;
      if (lastCategory != SYMBOL ||
          !BINARY_PRECEDENCE.containsKey(symbol) ||
          BINARY_PRECEDENCE[symbol] > maxPrecedence) {
        break;
      }
      expectCategory(SYMBOL);
      if (rhs == null || BINARY_PRECEDENCE[symbol] >= minPrecedence) {
        if (rhs != null) lhs = new Binary(lastSymbol, lhs, rhs);
        minPrecedence = BINARY_PRECEDENCE[symbol];
        rhs = parseUnaryLow();
        lastSymbol = symbol;
      } else {
        Expression higher = parseBinary(BINARY_PRECEDENCE[symbol]);
        rhs = new Binary(symbol, rhs, higher);
      }
    }
    if (rhs == null) return lhs;
    return new Binary(lastSymbol, lhs, rhs);
  }

  Expression parseConditional() {
    Expression lhs = parseBinary(HIGHEST_PARSE_BINARY_PRECEDENCE);
    if (!acceptCategory(QUERY)) return lhs;
    Expression ifTrue = parseAssignment();
    expectCategory(COLON);
    Expression ifFalse = parseAssignment();
    return new Conditional(lhs, ifTrue, ifFalse);
  }


  Expression parseAssignment() {
    Expression lhs = parseConditional();
    String assignmentOperator = lastToken;
    if (acceptCategory(ASSIGNMENT)) {
      Expression rhs = parseAssignment();
      if (assignmentOperator == "=") {
        return new Assignment(lhs, rhs);
      } else  {
        // Handle +=, -=, etc.
        String operator =
            assignmentOperator.substring(0, assignmentOperator.length - 1);
        return new Assignment.compound(lhs, operator, rhs);
      }
    }
    return lhs;
  }

  Expression parseExpression() {
    Expression expression = parseAssignment();
    while (acceptCategory(COMMA)) {
      Expression right = parseAssignment();
      expression = new Binary(',', expression, right);
    }
    return expression;
  }

  VariableDeclarationList parseVariableDeclarationList() {
    String firstVariable = lastToken;
    expectCategory(ALPHA);
    return finishVariableDeclarationList(firstVariable);
  }

  VariableDeclarationList finishVariableDeclarationList(String firstVariable) {
    var initialization = [];

    void declare(String variable) {
      Expression initializer = null;
      if (acceptString("=")) {
        initializer = parseAssignment();
      }
      var declaration = new VariableDeclaration(variable);
      initialization.add(new VariableInitialization(declaration, initializer));
    }

    declare(firstVariable);
    while (acceptCategory(COMMA)) {
      String variable = lastToken;
      expectCategory(ALPHA);
      declare(variable);
    }
    return new VariableDeclarationList(initialization);
  }

  Expression parseVarDeclarationOrExpression() {
    if (acceptString("var")) {
      return parseVariableDeclarationList();
    } else {
      return parseExpression();
    }
  }

  Expression expression() {
    Expression expression = parseVarDeclarationOrExpression();
    if (lastCategory != NONE || position != src.length) {
      error("Unparsed junk: ${categoryToString(lastCategory)}");
    }
    if (!interpolatedValues.isEmpty) {
      return new JSExpression(expression, interpolatedValues);
    }
    return expression;
  }

  Statement statement() {
    Statement statement = parseStatement();
    if (lastCategory != NONE || position != src.length) {
      error("Unparsed junk: ${categoryToString(lastCategory)}");
    }
    // TODO(sra): interpolated capture here?
    return statement;
  }

  Block parseBlock() {
    List<Statement> statements = <Statement>[];

    while (!acceptCategory(RBRACE)) {
      Statement statement = parseStatement();
      statements.add(statement);
    }
    return new Block(statements);
  }

  Statement parseStatement() {
    if (acceptCategory(LBRACE)) return parseBlock();

    if (lastCategory == ALPHA) {
      if (acceptString('return')) return parseReturn();

      if (acceptString('break')) {
        return parseBreakOrContinue((label) => new Break(label));
      }

      if (acceptString('continue')) {
        return parseBreakOrContinue((label) => new Continue(label));
      }

      if (acceptString('if')) return parseIfThenElse();

      if (acceptString('for')) return parseFor();

      if (acceptString('function')) return parseFunctionDeclaration();

      if (acceptString('var')) {
        Expression declarations = parseVariableDeclarationList();
        expectSemicolon();
        return new ExpressionStatement(declarations);
      }

      if (lastToken == 'case' ||
          lastToken == 'do' ||
          lastToken == 'while' ||
          lastToken == 'switch' ||
          lastToken == 'try' ||
          lastToken == 'throw' ||
          lastToken == 'with') {
        error('Not implemented in mini parser');
      }
    }

    if (acceptCategory(HASH)) {
      InterpolatedStatement statement = new InterpolatedStatement(null);
      interpolatedValues.add(statement);
      return statement;
    }

    // TODO:  label: statement

    Expression expression = parseExpression();
    expectSemicolon();
    return new ExpressionStatement(expression);
  }

  Statement parseReturn() {
    if (acceptSemicolon()) return new Return();
    Expression expression = parseExpression();
    expectSemicolon();
    return new Return(expression);
  }

  Statement parseBreakOrContinue(constructor) {
    var identifier = lastToken;
    if (!skippedNewline && acceptCategory(ALPHA)) {
      expectSemicolon();
      return constructor(identifier);
    }
    expectSemicolon();
    return constructor(null);
  }

  Statement parseIfThenElse() {
    expectCategory(LPAREN);
    Expression condition = parseExpression();
    expectCategory(RPAREN);
    Statement thenStatement = parseStatement();
    if (acceptString('else')) {
      // Resolves dangling else by binding 'else' to closest 'if'.
      Statement elseStatement = parseStatement();
      return new If(condition, thenStatement, elseStatement);
    } else {
      return new If.noElse(condition, thenStatement);
    }
  }

  Statement parseFor() {
    // For-init-condition-increment style loops are fully supported.
    //
    // Only one for-in variant is currently implemented:
    //
    //     for (var variable in Expression) Statement
    //
    Statement finishFor(Expression init) {
      Expression condition = null;
      if (!acceptCategory(SEMICOLON)) {
        condition = parseExpression();
        expectCategory(SEMICOLON);
      }
      Expression update = null;
      if (!acceptCategory(RPAREN)) {
        update = parseExpression();
        expectCategory(RPAREN);
      }
      Statement body = parseStatement();
      return new For(init, condition, update, body);
    }

    expectCategory(LPAREN);
    if (acceptCategory(SEMICOLON)) {
      return finishFor(null);
    }

    if (acceptString('var')) {
      String identifier = lastToken;
      expectCategory(ALPHA);
      if (acceptString('in')) {
        Expression objectExpression = parseExpression();
        expectCategory(RPAREN);
        Statement body = parseStatement();
        return new ForIn(js.defineVar(identifier), objectExpression, body);
      }
      Expression declarations = finishVariableDeclarationList(identifier);
      expectCategory(SEMICOLON);
      return finishFor(declarations);
    }

    Expression init = parseExpression();
    expectCategory(SEMICOLON);
    return finishFor(init);
  }

  Statement parseFunctionDeclaration() {
    String name = lastToken;
    expectCategory(ALPHA);
    Expression fun = parseFun();
    return new FunctionDeclaration(new VariableDeclaration(name), fun);
  }
}

/**
 * Clone a JSExpression node into an expression where all children
 * have been cloned, and [InterpolatedExpression]s have been replaced
 * with real [Expression].
 */
class UninterpolateJSExpression extends BaseVisitor<Node> {
  final List<Expression> arguments;
  int argumentIndex = 0;

  UninterpolateJSExpression(this.arguments);

  void error(message) {
    throw message;
  }

  Node visitNode(Node node) {
    error('Cannot handle $node');
    return null;
  }

  Node copyPosition(Node oldNode, Node newNode) {
    newNode.sourcePosition = oldNode.sourcePosition;
    newNode.endSourcePosition = oldNode.endSourcePosition;
    return newNode;
  }

  Node visit(Node node) {
    return node == null ? null : node.accept(this);
  }

  List<Node> visitList(List<Node> list) {
    return list.map((e) => visit(e)).toList();
  }

  Node visitLiteralString(LiteralString node) {
    return node;
  }

  Node visitVariableUse(VariableUse node) {
    return node;
  }

  Node visitAccess(PropertyAccess node) {
    return copyPosition(node,
        new PropertyAccess(visit(node.receiver), visit(node.selector)));
  }

  Node visitCall(Call node) {
    return copyPosition(node,
        new Call(visit(node.target), visitList(node.arguments)));
  }

  Node visitInterpolatedExpression(InterpolatedExpression expression) {
    return arguments[argumentIndex++];
  }

  Node visitInterpolatedStatement(InterpolatedStatement statement) {
    return arguments[argumentIndex++];
  }

  Node visitJSExpression(JSExpression expression) {
    assert(argumentIndex == 0);
    Node result = visit(expression.value);
    if (argumentIndex != arguments.length) {
      error("Invalid number of arguments");
    }
    assert(result is! JSExpression);
    return result;
  }

  Node visitLiteralExpression(LiteralExpression node) {
    assert(argumentIndex == 0);
    return copyPosition(node,
        new LiteralExpression.withData(node.template, arguments));
  }

  Node visitAssignment(Assignment node) {
    return copyPosition(node,
        new Assignment._internal(visit(node.leftHandSide),
                                 visit(node.compoundTarget),
                                 visit(node.value)));
  }

  Node visitRegExpLiteral(RegExpLiteral node) {
    return node;
  }

  Node visitLiteralNumber(LiteralNumber node) {
    return node;
  }

  Node visitBinary(Binary node) {
    return copyPosition(node,
        new Binary(node.op, visit(node.left), visit(node.right)));
  }

  Node visitPrefix(Prefix node) {
    return copyPosition(node,
        new Prefix(node.op, visit(node.argument)));
  }

  Node visitPostfix(Postfix node) {
    return copyPosition(node,
        new Postfix(node.op, visit(node.argument)));
  }

  Node visitNew(New node) {
    return copyPosition(node,
        new New(visit(node.target), visitList(node.arguments)));
  }

  Node visitArrayInitializer(ArrayInitializer node) {
    return copyPosition(node,
        new ArrayInitializer(node.length, visitList(node.elements)));
  }

  Node visitArrayElement(ArrayElement node) {
    return copyPosition(node,
        new ArrayElement(node.index, visit(node.value)));
  }

  Node visitConditional(Conditional node) {
    return copyPosition(node,
        new Conditional(visit(node.condition),
                        visit(node.then),
                        visit(node.otherwise)));
  }

  Node visitLiteralNull(LiteralNull node) {
    return node;
  }

  Node visitLiteralBool(LiteralBool node) {
    return node;
  }
}
