// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Utilities for building JS ASTs at runtime.  Contains a builder class
// and a parser that parses part of the language.

part of js;

class JsBuilder {
  const JsBuilder();

  // Parse a bit of JavaScript, and return an expression.
  // See the MiniJsParser class.
  // You can provide an expression or a list of expressions, which will be
  // interpolated into the source at the '#' signs.
  Expression call(String source, [var expression]) {
    var result = new MiniJsParser(source).expression();
    if (expression == null) return result;

    List<Expression> expressions;
    if (expression is List) {
      expressions = expression;
    } else {
      expressions = <Expression>[expression];
    }
    if (expressions.length != result.interpolatedExpressions.length) {
      throw "Unmatched number of interpolated expressions";
    }
    for (int i = 0; i < expressions.length; i++) {
      result.interpolatedExpressions[i].value = expressions[i];
    }

    return result.value;
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
      var values = new List<ArrayElement>(expression.length);
      int index = 0;
      for (var entry in expression) {
        values[index] = new ArrayElement(index, toExpression(entry));
        index++;
      }
      return new ArrayInitializer(values.length, values);
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

  int lastCategory;
  String lastToken;
  int lastPosition;
  int position;
  String src;
  final List<InterpolatedExpression> interpolatedValues =
      <InterpolatedExpression>[];

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
  static const HASH = 15;
  static const WHITESPACE = 16;
  static const OTHER = 17;

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
      COLON, OTHER, SYMBOL, SYMBOL, SYMBOL, QUERY, OTHER,           // :;<=>?@
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
    while (position < src.length &&
           category(src.codeUnitAt(position)) == WHITESPACE) {
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
    }
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
        return receiver;
      }
    }
  }

  Expression parseCall() {
    bool constructor = acceptString("new");
    Expression receiver = parseMember();
    while (true) {
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
        return receiver;
      }
    }
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
    if (lastCategory == SYMBOL && (acceptString("++") || acceptString("--"))) {
      return new Postfix(operator, expression);
    }
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
        if (rhs == null) return lhs;
        return new Binary(lastSymbol, lhs, rhs);
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
      error("Unparsed junk: ${categoryToString(lastCategory)}");
    }
    if (!interpolatedValues.isEmpty) {
      return new JSExpression(expression, interpolatedValues);
    }
    return expression;
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
