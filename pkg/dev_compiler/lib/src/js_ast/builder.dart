// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Utilities for building JS ASTs at runtime.  Contains a builder class
// and a parser that parses part of the language.

part of js_ast;

/**
 * Global template manager.  We should aim to have a fixed number of
 * templates. This implies that we do not use js('xxx') to parse text that is
 * constructed from values that depend on names in the Dart program.
 *
 * TODO(sra): Find the remaining places where js('xxx') used to parse an
 * unbounded number of expression, or institute a cache policy.
 */
TemplateManager templateManager = TemplateManager();

/**

[js] is a singleton instance of JsBuilder.  JsBuilder is a set of conveniences
for constructing JavaScript ASTs.

[string] and [number] are used to create leaf AST nodes:

    var s = js.string('hello');    //  s = new LiteralString('"hello"')
    var n = js.number(123);        //  n = new LiteralNumber(123)

In the line above `a --> b` means Dart expression `a` evaluates to a JavaScript
AST that would pretty-print as `b`.

The [call] method constructs an Expression AST.

No argument

    js('window.alert("hello")')  -->  window.alert("hello")

The input text can contain placeholders `#` that are replaced with provided
arguments.  A single argument can be passed directly:

    js('window.alert(#)', s)   -->  window.alert("hello")

Multiple arguments are passed as a list:

    js('# + #', [s, s])  -->  "hello" + "hello"

The [statement] method constructs a Statement AST, but is otherwise like the
[call] method.  This constructs a Return AST:

    var ret = js.statement('return #;', n);  -->  return 123;

A placeholder in a Statement context must be followed by a semicolon ';'.  You
can think of a statement placeholder as being `#;` to explain why the output
still has one semicolon:

    js.statement('if (happy) #;', ret)
    -->
    if (happy)
      return 123;

If the placeholder is not followed by a semicolon, it is part of an expression.
Here the placeholder is in the position of the function in a function call:

    var vFoo = new Identifier('foo');
    js.statement('if (happy) #("Happy!")', vFoo)
    -->
    if (happy)
      foo("Happy!");

Generally, a placeholder in an expression position requires an Expression AST as
an argument and a placeholder in a statement position requires a Statement AST.
An expression will be converted to a Statement if needed by creating an
ExpressionStatement.  A String argument will be converted into a Identifier and
requires that the string is a JavaScript identifier.

    js('# + 1', vFoo)       -->  foo + 1
    js('# + 1', 'foo')      -->  foo + 1
    js('# + 1', 'foo.bar')  -->  assertion failure

Some placeholder positions are _splicing contexts_.  A function argument list is
a splicing expression context.  A placeholder in a splicing expression context
can take a single Expression (or String, converted to Identifier) or an
Iterable of Expressions (and/or Strings).

    // non-splicing argument:
    js('#(#)', ['say', s])        -->  say("hello")
    // splicing arguments:
    js('#(#)', ['say', []])       -->  say()
    js('#(#)', ['say', [s]])      -->  say("hello")
    js('#(#)', ['say', [s, n]])   -->  say("hello", 123)

A splicing context can be used to append 'lists' and add extra elements:

    js('foo(#, #, 1)', [ ['a', n], s])       -->  foo(a, 123, "hello", 1)
    js('foo(#, #, 1)', [ ['a', n], [s, n]])  -->  foo(a, 123, "hello", 123, 1)
    js('foo(#, #, 1)', [ [], [s, n]])        -->  foo("hello", 123, 1)
    js('foo(#, #, 1)', [ [], [] ])           -->  foo(1)

The generation of a compile-time optional argument expression can be chosen by
providing an empty or singleton list.

In addition to Expressions and Statements, there are Parameters, which occur
only in the parameter list of a function expression or declaration.
Placeholders in parameter positions behave like placeholders in Expression
positions, except only Parameter AST nodes are permitted.  String arguments for
parameter placeholders are converted to Parameter AST nodes.

    var pFoo = new Parameter('foo')
    js('function(#) { return #; }', [pFoo, vFoo])
    -->
    function(foo) { return foo; }

Expressions and Parameters are not compatible with each other's context:

    js('function(#) { return #; }', [vFoo, vFoo]) --> error
    js('function(#) { return #; }', [pFoo, pFoo]) --> error

The parameter context is a splicing context.  When combined with the
context-sensitive conversion of Strings, this simplifies the construction of
trampoline-like functions:

    var args = ['a', 'b'];
    js('function(#) { return f(this, #); }', [args, args])
    -->
    function(a, b) { return f(this, a, b); }

A statement placeholder in a Block is also in a splicing context.  In addition
to splicing Iterables, statement placeholders in a Block will also splice a
Block or an EmptyStatement.  This flattens nested blocks and allows blocks to be
appended.

    var b1 = js.statement('{ 1; 2; }');
    var sEmpty = new Emptystatement();
    js.statement('{ #; #; #; #; }', [sEmpty, b1, b1, sEmpty])
    -->
    { 1; 2; 1; 2; }

A placeholder in the context of an if-statement condition also accepts a Dart
bool argument, which selects the then-part or else-part of the if-statement:

    js.statement('if (#) return;', vFoo)   -->  if (foo) return;
    js.statement('if (#) return;', true)   -->  return;
    js.statement('if (#) return;', false)  -->  ;   // empty statement
    var eTrue = new LiteralBool(true);
    js.statement('if (#) return;', eTrue)  -->  if (true) return;

Combined with block splicing, if-statement condition context placeholders allows
the creation of templates that select code depending on variables.

    js.statement('{ 1; if (#) 2; else { 3; 4; } 5;}', true)
    --> { 1; 2; 5; }

    js.statement('{ 1; if (#) 2; else { 3; 4; } 5;}', false)
    --> { 1; 3; 4; 5; }

A placeholder following a period in a property access is in a property access
context.  This is just like an expression context, except String arguments are
converted to JavaScript property accesses.  In JavaScript, `a.b` is short-hand
for `a["b"]`:

    js('a[#]', vFoo)  -->  a[foo]
    js('a[#]', s)     -->  a.hello    (i.e. a["hello"]).
    js('a[#]', 'x')   -->  a[x]

    js('a.#', vFoo)   -->  a[foo]
    js('a.#', s)      -->  a.hello    (i.e. a["hello"])
    js('a.#', 'x')    -->  a.x        (i.e. a["x"])

(Question - should `.#` be restricted to permit only String arguments? The
template should probably be written with `[]` if non-strings are accepted.)


Object initializers allow placeholders in the key property name position:

    js('{#:1, #:2}',  [s, 'bye'])    -->  {hello: 1, bye: 2}


What is not implemented:

 -  Array initializers and object initializers could support splicing.  In the
    array case, we would need some way to know if an ArrayInitializer argument
    should be splice or is intended as a single value.

 -  There are no placeholders in definition contexts:

        function #(){}
        var # = 1;

*/
const JsBuilder js = JsBuilder();

class JsBuilder {
  const JsBuilder();

  /**
   * Parses a bit of JavaScript, and returns an expression.
   *
   * See the MiniJsParser class.
   *
   * [arguments] can be a single [Node] (e.g. an [Expression] or [Statement]) or
   * a list of [Node]s, which will be interpolated into the source at the '#'
   * signs.
   */
  Expression call(String source, [arguments]) {
    Template template = _findExpressionTemplate(source);
    if (arguments == null) return template.instantiate([]) as Expression;
    // We allow a single argument to be given directly.
    if (arguments is! List && arguments is! Map) arguments = [arguments];
    return template.instantiate(arguments) as Expression;
  }

  /**
   * Parses a JavaScript Statement, otherwise just like [call].
   */
  Statement statement(String source, [arguments]) {
    Template template = _findStatementTemplate(source);
    if (arguments == null) return template.instantiate([]) as Statement;
    // We allow a single argument to be given directly.
    if (arguments is! List && arguments is! Map) arguments = [arguments];
    return template.instantiate(arguments) as Statement;
  }

  Block block(String source, [arguments]) =>
      statement(source, arguments) as Block;
  Fun fun(String source, [arguments]) => call(source, arguments) as Fun;

  /**
   * Parses JavaScript written in the `JS` foreign instruction.
   *
   * The [source] must be a JavaScript expression or a JavaScript throw
   * statement.
   */
  Template parseForeignJS(String source) {
    // TODO(sra): Parse with extra validation to forbid `#` interpolation in
    // functions, as this leads to unanticipated capture of temporaries that are
    // reused after capture.
    if (source.startsWith("throw ")) {
      return _findStatementTemplate(source);
    } else {
      return _findExpressionTemplate(source);
    }
  }

  Template _findExpressionTemplate(String source) {
    Template template = templateManager.lookupExpressionTemplate(source);
    if (template == null) {
      MiniJsParser parser = MiniJsParser(source);
      Expression expression = parser.expression();
      template = templateManager.defineExpressionTemplate(source, expression);
    }
    return template;
  }

  Template _findStatementTemplate(String source) {
    Template template = templateManager.lookupStatementTemplate(source);
    if (template == null) {
      MiniJsParser parser = MiniJsParser(source);
      Statement statement = parser.statement();
      template = templateManager.defineStatementTemplate(source, statement);
    }
    return template;
  }

  /**
   * Creates an Expression template without caching the result.
   */
  Template uncachedExpressionTemplate(String source) {
    MiniJsParser parser = MiniJsParser(source);
    Expression expression = parser.expression();
    return Template(source, expression, isExpression: true, forceCopy: false);
  }

  /**
   * Creates a Statement template without caching the result.
   */
  Template uncachedStatementTemplate(String source) {
    MiniJsParser parser = MiniJsParser(source);
    Statement statement = parser.statement();
    return Template(source, statement, isExpression: false, forceCopy: false);
  }

  /**
   * Create an Expression template which has [ast] as the result.  This is used
   * to wrap a generated AST in a zero-argument Template so it can be passed to
   * context that expects a template.
   */
  Template expressionTemplateYielding(Node ast) {
    return Template.withExpressionResult(ast);
  }

  Template statementTemplateYielding(Node ast) {
    return Template.withStatementResult(ast);
  }

  /// Creates a literal js string from [value].
  LiteralString escapedString(String value, [String quote = '"']) {
    // Start by escaping the backslashes.
    String escaped = value.replaceAll('\\', '\\\\');

    // Replace $ in template strings:
    // http://www.ecma-international.org/ecma-262/6.0/#sec-template-literal-lexical-components
    var quoteReplace = quote == '`' ? r'`$' : quote;

    // http://www.ecma-international.org/ecma-262/6.0/#sec-literals-string-literals
    // > All code points may appear literally in a string literal except for the
    // > closing quote code points, U+005C (REVERSE SOLIDUS),
    // > U+000D (CARRIAGE RETURN), U+2028 (LINE SEPARATOR),
    // > U+2029 (PARAGRAPH SEPARATOR), and U+000A (LINE FEED).
    var re = RegExp('[\n\r$quoteReplace\b\f\t\v\u2028\u2029]');
    escaped = escaped.replaceAllMapped(re, (m) {
      switch (m.group(0)) {
        case "\n":
          return r"\n";
        case "\r":
          return r"\r";
        case "\u2028":
          return r"\u2028";
        case "\u2029":
          return r"\u2029";
        // Quotes and $ are only replaced if they conflict with the containing
        // quote, see regex above.
        case '"':
          return r'\"';
        case "'":
          return r"\'";
        case "`":
          return r"\`";
        case r"$":
          return r"\$";
        // TODO(jmesserly): these don't need to be escaped for correctness,
        // but they are conventionally escaped.
        case "\b":
          return r"\b";
        case "\t":
          return r"\t";
        case "\f":
          return r"\f";
        case "\v":
          return r"\v";
      }
      throw 'unreachable';
    });
    LiteralString result = LiteralString('$quote$escaped$quote');
    // We don't escape quotes of a different style under the assumption that the
    // string is wrapped into quotes. Verify that assumption.
    assert(result.value.codeUnitAt(0) == quote.codeUnitAt(0));
    return result;
  }

  /// Creates a literal js string from [value].
  ///
  /// Note that this function only puts quotes around [value]. It does not do
  /// any escaping, so use only when you can guarantee that [value] does not
  /// contain newlines or backslashes. For escaping the string use
  /// [escapedString].
  LiteralString string(String value, [String quote = '"']) =>
      LiteralString('$quote$value$quote');

  LiteralNumber number(num value) => LiteralNumber('$value');

  LiteralNumber uint64(int value) {
    BigInt uint64Value = new BigInt.from(value).toUnsigned(64);
    return LiteralNumber('$uint64Value');
  }

  LiteralBool boolean(bool value) => LiteralBool(value);

  ArrayInitializer numArray(Iterable<int> list) =>
      ArrayInitializer(list.map(number).toList());

  ArrayInitializer stringArray(Iterable<String> list) =>
      ArrayInitializer(list.map(string).toList());

  Comment comment(String text) => Comment(text);
  CommentExpression commentExpression(String text, Expression expression) =>
      CommentExpression(text, expression);

  Call propertyCall(
      Expression receiver, String fieldName, List<Expression> arguments) {
    return Call(PropertyAccess.field(receiver, fieldName), arguments);
  }
}

LiteralString string(String value) => js.string(value);
LiteralNumber number(num value) => js.number(value);
ArrayInitializer numArray(Iterable<int> list) => js.numArray(list);
ArrayInitializer stringArray(Iterable<String> list) => js.stringArray(list);
Call propertyCall(
    Expression receiver, String fieldName, List<Expression> arguments) {
  return js.propertyCall(receiver, fieldName, arguments);
}

class MiniJsParserError {
  MiniJsParserError(this.parser, this.message) {}

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
    String spaces = prefix.replaceAll(RegExp(r'[^\t]'), ' ');
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
/// * anonymous functions and named function expressions and declarations.
/// Notable things it can't do yet include:
/// * some statements are still missing (do-while, while, switch).
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
  bool skippedNewline = false; // skipped newline in last getToken?
  final String src;

  final List<InterpolatedNode> interpolatedValues = <InterpolatedNode>[];
  bool get hasNamedHoles =>
      interpolatedValues.isNotEmpty && interpolatedValues.first.isNamed;
  bool get hasPositionalHoles =>
      interpolatedValues.isNotEmpty && interpolatedValues.first.isPositional;

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
  static const ARROW = 16;
  static const ELLIPSIS = 17;
  static const HASH = 18;
  static const WHITESPACE = 19;
  static const OTHER = 20;

  // Make sure that ]] is two symbols.
  // TODO(jmesserly): => and ... are not single char tokens, should we change
  // their numbers? It shouldn't matter because this is only called on values
  // from the [CATEGORIES] table.
  bool singleCharCategory(int category) => category > DOT;

  static String categoryToString(int cat) {
    switch (cat) {
      case NONE:
        return "NONE";
      case ALPHA:
        return "ALPHA";
      case NUMERIC:
        return "NUMERIC";
      case SYMBOL:
        return "SYMBOL";
      case ASSIGNMENT:
        return "ASSIGNMENT";
      case DOT:
        return "DOT";
      case LPAREN:
        return "LPAREN";
      case RPAREN:
        return "RPAREN";
      case LBRACE:
        return "LBRACE";
      case RBRACE:
        return "RBRACE";
      case LSQUARE:
        return "LSQUARE";
      case RSQUARE:
        return "RSQUARE";
      case STRING:
        return "STRING";
      case COMMA:
        return "COMMA";
      case QUERY:
        return "QUERY";
      case COLON:
        return "COLON";
      case SEMICOLON:
        return "SEMICOLON";
      case ARROW:
        return "ARROW";
      case ELLIPSIS:
        return "ELLIPSIS";
      case HASH:
        return "HASH";
      case WHITESPACE:
        return "WHITESPACE";
      case OTHER:
        return "OTHER";
    }
    return "Unknown: $cat";
  }

  static const CATEGORIES = <int>[
    OTHER, OTHER, OTHER, OTHER, OTHER, OTHER, OTHER, OTHER, // 0-7
    OTHER, WHITESPACE, WHITESPACE, OTHER, OTHER, WHITESPACE, // 8-13
    OTHER, OTHER, OTHER, OTHER, OTHER, OTHER, OTHER, OTHER, // 14-21
    OTHER, OTHER, OTHER, OTHER, OTHER, OTHER, OTHER, OTHER, // 22-29
    OTHER, OTHER, WHITESPACE, // 30-32
    SYMBOL, OTHER, HASH, ALPHA, SYMBOL, SYMBOL, OTHER, // !"#$%&´
    LPAREN, RPAREN, SYMBOL, SYMBOL, COMMA, SYMBOL, DOT, SYMBOL, // ()*+,-./
    NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, // 01234
    NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, // 56789
    COLON, SEMICOLON, SYMBOL, SYMBOL, SYMBOL, QUERY, OTHER, // :;<=>?@
    ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, // ABCDEFGH
    ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, // IJKLMNOP
    ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, // QRSTUVWX
    ALPHA, ALPHA, LSQUARE, OTHER, RSQUARE, SYMBOL, ALPHA, OTHER, // YZ[\]^_'
    ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, // abcdefgh
    ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, // ijklmnop
    ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, ALPHA, // qrstuvwx
    ALPHA, ALPHA, LBRACE, SYMBOL, RBRACE, SYMBOL
  ]; // yz{|}~

  // This must be a >= the highest precedence number handled by parseBinary.
  static var HIGHEST_PARSE_BINARY_PRECEDENCE = 16;
  static bool isAssignment(String symbol) => BINARY_PRECEDENCE[symbol] == 17;

  // From https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Operators/Operator_Precedence
  static final BINARY_PRECEDENCE = {
    '+=': 17,
    '-=': 17,
    '*=': 17,
    '/=': 17,
    '%=': 17,
    '^=': 17,
    '|=': 17,
    '&=': 17,
    '<<=': 17,
    '>>=': 17,
    '>>>=': 17,
    '=': 17,
    '||': 14,
    '&&': 13,
    '|': 12,
    '^': 11,
    '&': 10,
    '!=': 9,
    '==': 9,
    '!==': 9,
    '===': 9,
    '<': 8,
    '<=': 8,
    '>=': 8,
    '>': 8,
    'in': 8,
    'instanceof': 8,
    '<<': 7,
    '>>': 7,
    '>>>': 7,
    '+': 6,
    '-': 6,
    '*': 5,
    '/': 5,
    '%': 5
  };
  static final UNARY_OPERATORS = [
    '++',
    '--',
    '+',
    '-',
    '~',
    '!',
    'typeof',
    'void',
    'delete',
    'await'
  ].toSet();

  static final ARROW_TOKEN = '=>';
  static final ELLIPSIS_TOKEN = '...';

  static final OPERATORS_THAT_LOOK_LIKE_IDENTIFIERS = [
    'typeof',
    'void',
    'delete',
    'in',
    'instanceof',
    'await',
    'extends'
  ].toSet();

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
        if (escaped == charCodes.$x ||
            escaped == charCodes.$X ||
            escaped == charCodes.$u ||
            escaped == charCodes.$U ||
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
      //  Skip '//' and '/*' style comments.
      if (code == charCodes.$SLASH && position + 1 < src.length) {
        if (src.codeUnitAt(position + 1) == charCodes.$SLASH) {
          int nextPosition = src.indexOf('\n', position);
          if (nextPosition == -1) nextPosition = src.length;
          position = nextPosition;
          continue;
        } else if (src.codeUnitAt(position + 1) == charCodes.$STAR) {
          int nextPosition = src.indexOf('*/', position + 2);
          if (nextPosition == -1) error('Unterminated comment');
          position = nextPosition + 2;
          continue;
        }
      }
      if (category(code) != WHITESPACE) break;
      if (code == charCodes.$LF) skippedNewline = true;
      ++position;
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
      if (int.tryParse(lastToken) == null) {
        error("Unparseable number");
      }
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
            ? NONE
            : category(code);
      } while (!singleCharCategory(cat) &&
          (cat == newCat ||
              (cat == ALPHA && newCat == NUMERIC) || // eg. level42.
              (cat == NUMERIC && newCat == DOT))); // eg. 3.1415
      lastCategory = cat;
      lastToken = src.substring(lastPosition, position);
      if (cat == NUMERIC) {
        if (double.tryParse(lastToken) == null) {
          error("Unparseable number");
        }
      } else if (cat == DOT && lastToken.length > 1) {
        if (lastToken == ELLIPSIS_TOKEN) {
          lastCategory = ELLIPSIS;
        } else {
          error("Unknown operator");
        }
      } else if (cat == SYMBOL) {
        if (lastToken == ARROW_TOKEN) {
          lastCategory = ARROW;
        } else {
          int binaryPrecendence = BINARY_PRECEDENCE[lastToken];
          if (binaryPrecendence == null &&
              !UNARY_OPERATORS.contains(lastToken)) {
            error("Unknown operator");
          }
          if (isAssignment(lastToken)) lastCategory = ASSIGNMENT;
        }
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
    if (NONE == lastCategory) return true; // end of input
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

  void error(String message) {
    throw MiniJsParserError(this, message);
  }

  /// Returns either the name for the hole, or its integer position.
  parseHash() {
    String holeName = lastToken;
    if (acceptCategory(ALPHA)) {
      // Named hole. Example: 'function #funName() { ... }'
      if (hasPositionalHoles) {
        error('Holes must all be positional or named. $holeName');
      }
      return holeName;
    } else {
      if (hasNamedHoles) {
        error('Holes must all be positional or named. $holeName');
      }
      int position = interpolatedValues.length;
      return position;
    }
  }

  Expression parsePrimary() {
    String last = lastToken;
    if (acceptCategory(ALPHA)) {
      if (last == "true") {
        return LiteralBool(true);
      } else if (last == "false") {
        return LiteralBool(false);
      } else if (last == "null") {
        return LiteralNull();
      } else if (last == "function") {
        return parseFunctionExpression();
      } else if (last == "this") {
        return This();
      } else if (last == "super") {
        return Super();
      } else if (last == "class") {
        return parseClass();
      } else {
        return Identifier(last);
      }
    } else if (acceptCategory(LPAREN)) {
      return parseExpressionOrArrowFunction();
    } else if (acceptCategory(STRING)) {
      return LiteralString(last);
    } else if (acceptCategory(NUMERIC)) {
      return LiteralNumber(last);
    } else if (acceptCategory(LBRACE)) {
      return parseObjectInitializer();
    } else if (acceptCategory(LSQUARE)) {
      var values = <Expression>[];

      while (true) {
        if (acceptCategory(COMMA)) {
          values.add(ArrayHole());
          continue;
        }
        if (acceptCategory(RSQUARE)) break;
        values.add(parseAssignment());
        if (acceptCategory(RSQUARE)) break;
        expectCategory(COMMA);
      }
      return ArrayInitializer(values);
    } else if (last != null && last.startsWith("/")) {
      String regexp = getDelimited(lastPosition);
      getToken();
      String flags = lastToken;
      if (!acceptCategory(ALPHA)) flags = "";
      Expression expression = RegExpLiteral(regexp + flags);
      return expression;
    } else if (acceptCategory(HASH)) {
      return parseInterpolatedExpression();
    } else {
      error("Expected primary expression");
      return null;
    }
  }

  InterpolatedExpression parseInterpolatedExpression() {
    var expression = InterpolatedExpression(parseHash());
    interpolatedValues.add(expression);
    return expression;
  }

  InterpolatedIdentifier parseInterpolatedIdentifier() {
    var id = InterpolatedIdentifier(parseHash());
    interpolatedValues.add(id);
    return id;
  }

  Identifier parseIdentifier() {
    if (acceptCategory(HASH)) {
      return parseInterpolatedIdentifier();
    } else {
      var id = Identifier(lastToken);
      expectCategory(ALPHA);
      return id;
    }
  }

  /**
   * CoverParenthesizedExpressionAndArrowParameterList[Yield] :
   *     ( Expression )
   *     ( )
   *     ( ... BindingIdentifier )
   *     ( Expression , ... BindingIdentifier )
   */
  Expression parseExpressionOrArrowFunction() {
    if (acceptCategory(RPAREN)) {
      expectCategory(ARROW);
      return parseArrowFunctionBody(<Parameter>[]);
    }
    if (acceptCategory(ELLIPSIS)) {
      var params = <Parameter>[RestParameter(parseParameter())];
      expectCategory(RPAREN);
      expectCategory(ARROW);
      return parseArrowFunctionBody(params);
    }
    Expression expression = parseAssignment();
    while (acceptCategory(COMMA)) {
      if (acceptCategory(ELLIPSIS)) {
        var params = <Parameter>[];
        _expressionToParameterList(expression, params);
        params.add(RestParameter(parseParameter()));
        expectCategory(RPAREN);
        expectCategory(ARROW);
        return parseArrowFunctionBody(params);
      }
      Expression right = parseAssignment();
      expression = Binary(',', expression, right);
    }
    expectCategory(RPAREN);
    if (acceptCategory(ARROW)) {
      var params = <Parameter>[];
      _expressionToParameterList(expression, params);
      return parseArrowFunctionBody(params);
    }
    return expression;
  }

  /**
   * Converts a parenthesized expression into a list of parameters, issuing an
   * error if the conversion fails.
   */
  void _expressionToParameterList(Expression node, List<Parameter> params) {
    if (node is Identifier) {
      params.add(node);
    } else if (node is Binary && node.op == ',') {
      // TODO(jmesserly): this will allow illegal parens, such as
      // `((a, b), (c, d))`. Fixing it on the left side needs an explicit
      // ParenthesizedExpression node, so we can distinguish
      // `((a, b), c)` from `(a, b, c)`.
      _expressionToParameterList(node.left, params);
      _expressionToParameterList(node.right, params);
    } else if (node is InterpolatedExpression) {
      params.add(InterpolatedParameter(node.nameOrPosition));
    } else {
      error("Expected arrow function parameter list");
    }
  }

  Expression parseArrowFunctionBody(List<Parameter> params) {
    Node body;
    if (acceptCategory(LBRACE)) {
      body = parseBlock();
    } else {
      body = parseAssignment();
    }
    return ArrowFun(params, body);
  }

  Expression parseFunctionExpression() {
    String last = lastToken;
    if (acceptCategory(ALPHA)) {
      String functionName = last;
      return NamedFunction(Identifier(functionName), parseFun());
    }
    return parseFun();
  }

  Fun parseFun() {
    List<Parameter> params = <Parameter>[];

    expectCategory(LPAREN);
    if (!acceptCategory(RPAREN)) {
      for (;;) {
        if (acceptCategory(ELLIPSIS)) {
          params.add(RestParameter(parseParameter()));
          expectCategory(RPAREN);
          break;
        }

        params.add(parseParameter());
        if (!acceptCategory(COMMA)) {
          expectCategory(RPAREN);
          break;
        }
      }
    }
    AsyncModifier asyncModifier;
    if (acceptString('async')) {
      if (acceptString('*')) {
        asyncModifier = const AsyncModifier.asyncStar();
      } else {
        asyncModifier = const AsyncModifier.async();
      }
    } else if (acceptString('sync')) {
      if (!acceptString('*')) error("Only sync* is valid - sync is implied");
      asyncModifier = const AsyncModifier.syncStar();
    } else {
      asyncModifier = const AsyncModifier.sync();
    }
    expectCategory(LBRACE);
    Block block = parseBlock();
    return Fun(params, block, asyncModifier: asyncModifier);
  }

  /** Parse parameter name or interpolated parameter. */
  Identifier parseParameter() {
    if (acceptCategory(HASH)) {
      var nameOrPosition = parseHash();
      var parameter = InterpolatedParameter(nameOrPosition);
      interpolatedValues.add(parameter);
      return parameter;
    } else {
      // TODO(jmesserly): validate this is not a keyword
      String argumentName = lastToken;
      expectCategory(ALPHA);
      return Identifier(argumentName);
    }
  }

  Expression parseObjectInitializer() {
    List<Property> properties = <Property>[];
    for (;;) {
      if (acceptCategory(RBRACE)) break;
      // Limited subset of ES6 object initializers.
      //
      // PropertyDefinition :
      //     PropertyName : AssignmentExpression
      //     MethodDefinition
      properties.add(parseMethodOrProperty());

      if (acceptCategory(RBRACE)) break;
      expectCategory(COMMA);
    }
    return ObjectInitializer(properties);
  }

  Expression parseMember() {
    Expression receiver = parsePrimary();
    while (true) {
      if (acceptCategory(DOT)) {
        receiver = getDotRhs(receiver);
      } else if (acceptCategory(LSQUARE)) {
        Expression inBraces = parseExpression();
        expectCategory(RSQUARE);
        receiver = PropertyAccess(receiver, inBraces);
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
            if (acceptCategory(ELLIPSIS)) {
              arguments.add(Spread(parseAssignment()));
              expectCategory(RPAREN);
              break;
            }
            arguments.add(parseAssignment());
            if (acceptCategory(RPAREN)) break;
            expectCategory(COMMA);
          }
        }
        receiver =
            constructor ? New(receiver, arguments) : Call(receiver, arguments);
        constructor = false;
      } else if (!constructor && acceptCategory(LSQUARE)) {
        Expression inBraces = parseExpression();
        expectCategory(RSQUARE);
        receiver = PropertyAccess(receiver, inBraces);
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
    if (acceptCategory(HASH)) {
      var nameOrPosition = parseHash();
      InterpolatedSelector property = InterpolatedSelector(nameOrPosition);
      interpolatedValues.add(property);
      return PropertyAccess(receiver, property);
    }
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
    return PropertyAccess.field(receiver, identifier);
  }

  Expression parsePostfix() {
    Expression expression = parseCall();
    String operator = lastToken;
    // JavaScript grammar is:
    //     LeftHandSideExpression [no LineTerminator here] ++
    if (lastCategory == SYMBOL &&
        !skippedNewline &&
        (acceptString("++") || acceptString("--"))) {
      return Postfix(operator, expression);
    }
    // If we don't accept '++' or '--' due to skippedNewline a newline, no other
    // part of the parser will accept the token and we will get an error at the
    // whole expression level.
    return expression;
  }

  Expression parseUnaryHigh() {
    String operator = lastToken;
    if (lastCategory == SYMBOL &&
        UNARY_OPERATORS.contains(operator) &&
        (acceptString("++") || acceptString("--") || acceptString('await'))) {
      if (operator == "await") return Await(parsePostfix());
      return Prefix(operator, parsePostfix());
    }
    return parsePostfix();
  }

  Expression parseUnaryLow() {
    String operator = lastToken;
    if (lastCategory == SYMBOL &&
        UNARY_OPERATORS.contains(operator) &&
        operator != "++" &&
        operator != "--") {
      expectCategory(SYMBOL);
      if (operator == "await") return Await(parsePostfix());
      return Prefix(operator, parseUnaryLow());
    }
    return parseUnaryHigh();
  }

  Expression parseBinary(int maxPrecedence) {
    Expression lhs = parseUnaryLow();
    int minPrecedence;
    String lastSymbol;
    Expression rhs; // This is null first time around.
    while (true) {
      String symbol = lastToken;
      if (lastCategory != SYMBOL ||
          !BINARY_PRECEDENCE.containsKey(symbol) ||
          BINARY_PRECEDENCE[symbol] > maxPrecedence) {
        break;
      }
      expectCategory(SYMBOL);
      if (rhs == null || BINARY_PRECEDENCE[symbol] >= minPrecedence) {
        if (rhs != null) lhs = Binary(lastSymbol, lhs, rhs);
        minPrecedence = BINARY_PRECEDENCE[symbol];
        rhs = parseUnaryLow();
        lastSymbol = symbol;
      } else {
        Expression higher = parseBinary(BINARY_PRECEDENCE[symbol]);
        rhs = Binary(symbol, rhs, higher);
      }
    }
    if (rhs == null) return lhs;
    return Binary(lastSymbol, lhs, rhs);
  }

  Expression parseConditional() {
    Expression lhs = parseBinary(HIGHEST_PARSE_BINARY_PRECEDENCE);
    if (!acceptCategory(QUERY)) return lhs;
    Expression ifTrue = parseAssignment();
    expectCategory(COLON);
    Expression ifFalse = parseAssignment();
    return Conditional(lhs, ifTrue, ifFalse);
  }

  Expression parseLeftHandSide() => parseConditional();

  Expression parseAssignment() {
    Expression lhs = parseLeftHandSide();
    String assignmentOperator = lastToken;
    if (acceptCategory(ASSIGNMENT)) {
      Expression rhs = parseAssignment();
      if (assignmentOperator == "=") {
        return Assignment(lhs, rhs);
      } else {
        // Handle +=, -=, etc.
        String operator =
            assignmentOperator.substring(0, assignmentOperator.length - 1);
        return Assignment.compound(lhs, operator, rhs);
      }
    }
    return lhs;
  }

  Expression parseExpression() {
    Expression expression = parseAssignment();
    while (acceptCategory(COMMA)) {
      Expression right = parseAssignment();
      expression = Binary(',', expression, right);
    }
    return expression;
  }

  /** Parse a variable declaration list, with `var` or `let` [keyword] */
  VariableDeclarationList parseVariableDeclarationList(String keyword,
      [String firstIdentifier]) {
    var initialization = <VariableInitialization>[];

    do {
      VariableBinding declarator;
      if (firstIdentifier != null) {
        declarator = Identifier(firstIdentifier);
        firstIdentifier = null;
      } else {
        declarator = parseVariableBinding();
      }

      var initializer = acceptString("=") ? parseAssignment() : null;
      initialization.add(VariableInitialization(declarator, initializer));
    } while (acceptCategory(COMMA));

    return VariableDeclarationList(keyword, initialization);
  }

  VariableBinding parseVariableBinding() {
    switch (lastCategory) {
      case ALPHA:
      case HASH:
        return parseIdentifier();
      case LBRACE:
      case LSQUARE:
        return parseBindingPattern();
      default:
        error('Unexpected token $lastToken: ${categoryToString(lastCategory)}');
        return null;
    }
  }

  /// Note: this doesn't deal with general-case destructuring yet, it just
  /// supports it in variable initialization.
  /// See ES6 spec:
  /// http://www.ecma-international.org/ecma-262/6.0/#sec-destructuring-binding-patterns
  /// http://www.ecma-international.org/ecma-262/6.0/#sec-destructuring-assignment
  /// TODO(ochafik): Support destructuring in LeftHandSideExpression.
  BindingPattern parseBindingPattern() {
    if (acceptCategory(LBRACE)) {
      return parseObjectBindingPattern();
    } else {
      expectCategory(LSQUARE);
      return parseArrayBindingPattern();
    }
  }

  ArrayBindingPattern parseArrayBindingPattern() {
    var variables = <DestructuredVariable>[];
    do {
      Identifier name;
      BindingPattern structure;
      Expression defaultValue;

      var declarator = parseVariableBinding();
      if (declarator is Identifier) {
        name = declarator;
      } else if (declarator is BindingPattern) {
        structure = declarator;
      } else {
        error("Unexpected LHS: $declarator");
      }

      if (acceptString("=")) {
        defaultValue = parseExpression();
      }
      variables.add(DestructuredVariable(
          name: name, structure: structure, defaultValue: defaultValue));
    } while (acceptCategory(COMMA));

    expectCategory(RSQUARE);
    return ArrayBindingPattern(variables);
  }

  ObjectBindingPattern parseObjectBindingPattern() {
    var variables = <DestructuredVariable>[];
    do {
      var name = parseIdentifier();
      BindingPattern structure;
      Expression defaultValue;

      if (acceptCategory(COLON)) {
        structure = parseBindingPattern();
      } else if (acceptString("=")) {
        defaultValue = parseExpression();
      }
      variables.add(DestructuredVariable(
          name: name, structure: structure, defaultValue: defaultValue));
    } while (acceptCategory(COMMA));

    expectCategory(RBRACE);
    return ObjectBindingPattern(variables);
  }

  Expression parseVarDeclarationOrExpression() {
    var keyword = acceptVarLetOrConst();
    if (keyword != null) {
      return parseVariableDeclarationList(keyword);
    } else {
      return parseExpression();
    }
  }

  /** Accepts a `var` or `let` keyword. If neither is found, returns null. */
  String acceptVarLetOrConst() {
    if (acceptString('var')) return 'var';
    if (acceptString('let')) return 'let';
    if (acceptString('const')) return 'const';
    return null;
  }

  Expression expression() {
    Expression expression = parseVarDeclarationOrExpression();
    if (lastCategory != NONE || position != src.length) {
      error("Unparsed junk: ${categoryToString(lastCategory)}");
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
    return Block(statements);
  }

  Statement parseStatement() {
    if (acceptCategory(LBRACE)) return parseBlock();

    if (acceptCategory(SEMICOLON)) return EmptyStatement();

    if (lastCategory == ALPHA) {
      if (acceptString('return')) return parseReturn();

      if (acceptString('throw')) return parseThrow();

      if (acceptString('break')) {
        return parseBreakOrContinue((label) => Break(label));
      }

      if (acceptString('continue')) {
        return parseBreakOrContinue((label) => Continue(label));
      }

      if (acceptString('debugger')) {
        expectSemicolon();
        return DebuggerStatement();
      }

      if (acceptString('if')) return parseIfThenElse();

      if (acceptString('for')) return parseFor();

      if (acceptString('function')) return parseFunctionDeclaration();

      if (acceptString('class')) return ClassDeclaration(parseClass());

      if (acceptString('try')) return parseTry();

      var keyword = acceptVarLetOrConst();
      if (keyword != null) {
        Expression declarations = parseVariableDeclarationList(keyword);
        expectSemicolon();
        return ExpressionStatement(declarations);
      }

      if (acceptString('while')) return parseWhile();

      if (acceptString('do')) return parseDo();

      if (acceptString('switch')) return parseSwitch();

      if (lastToken == 'case') error("Case outside switch.");

      if (lastToken == 'default') error("Default outside switch.");

      if (lastToken == 'yield') return parseYield();

      if (lastToken == 'with') {
        error('Not implemented in mini parser');
      }
    }

    bool checkForInterpolatedStatement = lastCategory == HASH;

    Expression expression = parseExpression();

    if (expression is Identifier && acceptCategory(COLON)) {
      return LabeledStatement(expression.name, parseStatement());
    }

    expectSemicolon();

    if (checkForInterpolatedStatement) {
      // 'Promote' the interpolated expression `#;` to an interpolated
      // statement.
      if (expression is InterpolatedExpression) {
        assert(identical(interpolatedValues.last, expression));
        InterpolatedStatement statement =
            InterpolatedStatement(expression.nameOrPosition);
        interpolatedValues[interpolatedValues.length - 1] = statement;
        return statement;
      }
    }

    return ExpressionStatement(expression);
  }

  Statement parseReturn() {
    if (acceptSemicolon()) return Return();
    Expression expression = parseExpression();
    expectSemicolon();
    return Return(expression);
  }

  Statement parseYield() {
    bool hasStar = acceptString('*');
    Expression expression = parseExpression();
    expectSemicolon();
    return DartYield(expression, hasStar);
  }

  Statement parseThrow() {
    if (skippedNewline) error('throw expression must be on same line');
    Expression expression = parseExpression();
    expectSemicolon();
    return Throw(expression);
  }

  Statement parseBreakOrContinue(Statement Function(String) constructor) {
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
      return If(condition, thenStatement, elseStatement);
    } else {
      return If.noElse(condition, thenStatement);
    }
  }

  Statement parseFor() {
    // For-init-condition-increment style loops are fully supported.
    //
    // Only one for-in variant is currently implemented:
    //
    //     for (var variable in Expression) Statement
    //
    // One variant of ES6 for-of is also implemented:
    //
    //     for (let variable of Expression) Statement
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
      return For(init, condition, update, body);
    }

    expectCategory(LPAREN);
    if (acceptCategory(SEMICOLON)) {
      return finishFor(null);
    }

    var keyword = acceptVarLetOrConst();
    if (keyword != null) {
      String identifier = lastToken;
      expectCategory(ALPHA);

      if (acceptString('in')) {
        Expression objectExpression = parseExpression();
        expectCategory(RPAREN);
        Statement body = parseStatement();
        return ForIn(_createVariableDeclarationList(keyword, identifier),
            objectExpression, body);
      } else if (acceptString('of')) {
        Expression iterableExpression = parseAssignment();
        expectCategory(RPAREN);
        Statement body = parseStatement();
        return ForOf(_createVariableDeclarationList(keyword, identifier),
            iterableExpression, body);
      }
      var declarations = parseVariableDeclarationList(keyword, identifier);
      expectCategory(SEMICOLON);
      return finishFor(declarations);
    }

    Expression init = parseExpression();
    expectCategory(SEMICOLON);
    return finishFor(init);
  }

  static VariableDeclarationList _createVariableDeclarationList(
      String keyword, String identifier) {
    return VariableDeclarationList(
        keyword, [VariableInitialization(Identifier(identifier), null)]);
  }

  Statement parseFunctionDeclaration() {
    String name = lastToken;
    expectCategory(ALPHA);
    var fun = parseFun();
    return FunctionDeclaration(Identifier(name), fun);
  }

  Statement parseTry() {
    expectCategory(LBRACE);
    Block body = parseBlock();
    Catch catchPart = null;
    if (acceptString('catch')) catchPart = parseCatch();
    Block finallyPart = null;
    if (acceptString('finally')) {
      expectCategory(LBRACE);
      finallyPart = parseBlock();
    } else {
      if (catchPart == null) error("expected 'finally'");
    }
    return Try(body, catchPart, finallyPart);
  }

  SwitchCase parseSwitchClause() {
    Expression expression = null;
    if (acceptString('case')) {
      expression = parseExpression();
      expectCategory(COLON);
    } else {
      if (!acceptString('default')) {
        error('expected case or default');
      }
      expectCategory(COLON);
    }
    var statements = <Statement>[];
    while (lastCategory != RBRACE &&
        lastToken != 'case' &&
        lastToken != 'default') {
      statements.add(parseStatement());
    }
    return SwitchCase(expression, Block(statements));
  }

  Statement parseWhile() {
    expectCategory(LPAREN);
    Expression condition = parseExpression();
    expectCategory(RPAREN);
    Statement body = parseStatement();
    return While(condition, body);
  }

  Statement parseDo() {
    Statement body = parseStatement();
    if (lastToken != "while") error("Missing while after do body.");
    getToken();
    expectCategory(LPAREN);
    Expression condition = parseExpression();
    expectCategory(RPAREN);
    expectSemicolon();
    return Do(body, condition);
  }

  Statement parseSwitch() {
    expectCategory(LPAREN);
    Expression key = parseExpression();
    expectCategory(RPAREN);
    expectCategory(LBRACE);
    var clauses = List<SwitchCase>();
    while (lastCategory != RBRACE) {
      clauses.add(parseSwitchClause());
    }
    expectCategory(RBRACE);
    return Switch(key, clauses);
  }

  Catch parseCatch() {
    expectCategory(LPAREN);
    String identifier = lastToken;
    expectCategory(ALPHA);
    expectCategory(RPAREN);
    expectCategory(LBRACE);
    Block body = parseBlock();
    return Catch(Identifier(identifier), body);
  }

  ClassExpression parseClass() {
    Identifier name = parseIdentifier();
    Expression heritage = null;
    if (acceptString('extends')) {
      heritage = parseConditional();
    }
    expectCategory(LBRACE);
    var methods = List<Method>();
    while (lastCategory != RBRACE) {
      methods.add(parseMethodOrProperty(onlyMethods: true) as Method);
    }
    expectCategory(RBRACE);
    return ClassExpression(name, heritage, methods);
  }

  /**
   * Parses a [Method] or a [Property].
   *
   * Most of the complexity is from supporting interpolation. Several forms
   * are supported:
   *
   * - getter/setter names: `get #() { ... }`
   * - method names: `#() { ... }`
   * - property names: `#: ...`
   * - entire methods: `#`
   */
  Property parseMethodOrProperty({bool onlyMethods = false}) {
    bool isStatic = acceptString('static');

    bool isGetter = lastToken == 'get';
    bool isSetter = lastToken == 'set';
    Expression name = null;
    if (isGetter || isSetter) {
      var token = lastToken;
      getToken();
      if (lastCategory == COLON) {
        // That wasn't a accessor but the 'get' or 'set' property: retropedal.
        isGetter = isSetter = false;
        name = LiteralString('"$token"');
      }
    }
    if (acceptCategory(HASH)) {
      if (lastCategory != LPAREN && (onlyMethods || lastCategory != COLON)) {
        // Interpolated method
        var member = InterpolatedMethod(parseHash());
        interpolatedValues.add(member);
        return member;
      }
      name = parseInterpolatedExpression();
    } else {
      name ??= parsePropertyName();
    }

    if (!onlyMethods && acceptCategory(COLON)) {
      Expression value = parseAssignment();
      return Property(name, value);
    } else {
      var fun = parseFun();
      return Method(name, fun,
          isGetter: isGetter, isSetter: isSetter, isStatic: isStatic);
    }
  }

  Expression parsePropertyName() {
    String identifier = lastToken;
    if (acceptCategory(STRING)) {
      return LiteralString(identifier);
    } else if (acceptCategory(ALPHA) || acceptCategory(SYMBOL)) {
      // ALPHA or a SYMBOL, e.g. void
      return LiteralString('"$identifier"');
    } else if (acceptCategory(LSQUARE)) {
      var expr = parseAssignment();
      expectCategory(RSQUARE);
      return expr;
    } else if (acceptCategory(HASH)) {
      return parseInterpolatedExpression();
    } else {
      error('Expected property name');
      return null;
    }
  }
}
