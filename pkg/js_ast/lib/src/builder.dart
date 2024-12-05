// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utilities for building JS ASTs at runtime. Contains a builder class and a
/// parser that parses part of the language.
library;

import 'characters.dart' as char_codes;
import 'nodes.dart';
import 'template.dart';

/// Global template manager.
///
/// We should aim to have a fixed number of templates. This implies that we do
/// not use js('xxx') to parse text that is constructed from values that depend
/// on names in the Dart program.
// TODO(sra): Find the remaining places where js('xxx') used to parse an
// unbounded number of expression, or institute a cache policy.
TemplateManager templateManager = TemplateManager();

/// [js] is a singleton instance of JsBuilder.
///
/// JsBuilder is a set of conveniences for constructing JavaScript ASTs.
///
/// [string] and [number] are used to create leaf AST nodes:
///
///     var s = js.string('hello');    //  s = new LiteralString('"hello"')
///     var n = js.number(123);        //  n = new LiteralNumber(123)
///
/// In the line above `a --> b` means Dart expression `a` evaluates to a
/// JavaScript AST that would pretty-print as `b`.
///
/// The [call] method constructs an Expression AST.
///
/// No argument
///
///     js('window.alert("hello")')  -->  window.alert("hello")
///
/// The input text can contain placeholders `#` that are replaced with provided
/// arguments. A single argument can be passed directly:
///
///     js('window.alert(#)', s)   -->  window.alert("hello")
///
/// Multiple arguments are passed as a list:
///
///     js('# + #', [s, s])  -->  "hello" + "hello"
///
/// The [statement] method constructs a Statement AST, but is otherwise like the
/// [call] method. This constructs a Return AST:
///
///     var ret = js.statement('return #;', n);  -->  return 123;
///
/// A placeholder in a Statement context must be followed by a semicolon ';'.
/// One can think of a statement placeholder as being `#;` to explain why the
/// output still has one semicolon:
///
///     js.statement('if (happy) #;', ret)
///     -->
///     if (happy)
///       return 123;
///
/// If the placeholder is not followed by a semicolon, it is part of an
/// expression. Here the placeholder is in the position of the function in a
/// function call:
///
///     var vFoo = new VariableUse('foo');
///     js.statement('if (happy) #("Happy!")', vFoo)
///     -->
///     if (happy)
///       foo("Happy!");
///
/// Generally, a placeholder in an expression position requires an Expression
/// AST as an argument and a placeholder in a statement position requires a
/// Statement AST. An expression will be converted to a Statement if needed by
/// creating an ExpressionStatement. A String argument will be converted into a
/// VariableUse and requires that the string is a JavaScript identifier.
///
///     js('# + 1', vFoo)       -->  foo + 1
///     js('# + 1', 'foo')      -->  foo + 1
///     js('# + 1', 'foo.bar')  -->  assertion failure
///
/// Some placeholder positions are _splicing contexts_. A function argument list
/// is a splicing expression context. A placeholder in a splicing expression
/// context can take a single Expression (or String, converted to VariableUse)
/// or an Iterable of Expressions (and/or Strings).
///
///     // non-splicing argument:
///     js('#(#)', ['say', s])        -->  say("hello")
///     // splicing arguments:
///     js('#(#)', ['say', []])       -->  say()
///     js('#(#)', ['say', [s]])      -->  say("hello")
///     js('#(#)', ['say', [s, n]])   -->  say("hello", 123)
///
/// A splicing context can be used to append 'lists' and add extra elements:
///
///     js('foo(#, #, 1)', [ ['a', n], s])       -->  foo(a, 123, "hello", 1)
///     js('foo(#, #, 1)', [ ['a', n], [s, n]])  -->  foo(a, 123, "hello", 123, 1)
///     js('foo(#, #, 1)', [ [], [s, n]])        -->  foo("hello", 123, 1)
///     js('foo(#, #, 1)', [ [], [] ])           -->  foo(1)
///
/// The generation of a compile-time optional argument expression can be chosen
/// by providing an empty or singleton list.
///
/// In addition to Expressions and Statements, there are Parameters, which occur
/// only in the parameter list of a function expression or declaration.
/// Placeholders in parameter positions behave like placeholders in Expression
/// positions, except only Parameter AST nodes are permitted. String arguments
/// for parameter placeholders are converted to Parameter AST nodes.
///
///     var pFoo = new Parameter('foo')
///     js('function(#) { return #; }', [pFoo, vFoo])
///     -->
///     function(foo) { return foo; }
///
/// Expressions and Parameters are not compatible with each other's context:
///
///     js('function(#) { return #; }', [vFoo, vFoo]) --> error
///     js('function(#) { return #; }', [pFoo, pFoo]) --> error
///
/// The parameter context is a splicing context. When combined with the
/// context-sensitive conversion of Strings, this simplifies the construction of
/// trampoline-like functions:
///
///     var args = ['a', 'b'];
///     js('function(#) { return f(this, #); }', [args, args])
///     -->
///     function(a, b) { return f(this, a, b); }
///
/// A statement placeholder in a Block is also in a splicing context. In
/// addition to splicing Iterables, statement placeholders in a Block will also
/// splice a Block or an EmptyStatement. This flattens nested blocks and allows
/// blocks to be appended.
///
///     var b1 = js.statement('{ 1; 2; }');
///     var sEmpty = new EmptyStatement();
///     js.statement('{ #; #; #; #; }', [sEmpty, b1, b1, sEmpty])
///     -->
///     { 1; 2; 1; 2; }
///
/// A placeholder in the context of an if-statement condition also accepts a
/// Dart bool argument, which selects the then-part or else-part of the
/// if-statement:
///
///     js.statement('if (#) return;', vFoo)   -->  if (foo) return;
///     js.statement('if (#) return;', true)   -->  return;
///     js.statement('if (#) return;', false)  -->  ;   // empty statement
///     var eTrue = new LiteralBool(true);
///     js.statement('if (#) return;', eTrue)  -->  if (true) return;
///
/// Combined with block splicing, if-statement condition context placeholders
/// allows the creation of templates that select code depending on variables.
///
///     js.statement('{ 1; if (#) 2; else { 3; 4; } 5;}', true)
///     --> { 1; 2; 5; }
///
///     js.statement('{ 1; if (#) 2; else { 3; 4; } 5;}', false)
///     --> { 1; 3; 4; 5; }
///
/// A placeholder following a period in a property access is in a property
/// access context. This is just like an expression context, except String
/// arguments are converted to JavaScript property accesses. In JavaScript,
/// `a.b` is short-hand for `a["b"]`:
///
///     js('a[#]', vFoo)  -->  a[foo]
///     js('a[#]', s)     -->  a.hello    (i.e. a["hello"]).
///     js('a[#]', 'x')   -->  a[x]
///
///     js('a.#', vFoo)   -->  a[foo]
///     js('a.#', s)      -->  a.hello    (i.e. a["hello"])
///     js('a.#', 'x')    -->  a.x        (i.e. a["x"])
///
/// (Question - should `.#` be restricted to permit only String arguments? The
/// template should probably be written with `[]` if non-strings are accepted.)
///
///
/// Object initializers allow placeholders in the key property name position:
///
///     js('{#:1, #:2}',  [s, 'bye'])    -->  {hello: 1, bye: 2}
///
///
/// What is not implemented:
///
///  -  Array initializers and object initializers could support splicing. In
///     the array case, we would need some way to know if an ArrayInitializer
///     argument should be splice or is intended as a single value.
const JsBuilder js = JsBuilder();

class JsBuilder {
  const JsBuilder();

  /// Parses a bit of JavaScript, and returns an expression.
  ///
  /// See the MiniJsParser class.
  ///
  /// [arguments] can be a single [Node] (e.g. an [Expression] or [Statement])
  /// or a list of [Node]s, which will be interpolated into the source at the
  /// '#' signs.
  Expression call(String source, [var arguments]) {
    Template template = _findExpressionTemplate(source);
    arguments ??= [];
    // We allow a single argument to be given directly.
    if (arguments is! List && arguments is! Map) arguments = [arguments];
    return template.instantiate(arguments) as Expression;
  }

  /// Parses a JavaScript Statement, otherwise just like [call].
  Statement statement(String source, [var arguments]) {
    Template template = _findStatementTemplate(source);
    arguments ??= [];
    // We allow a single argument to be given directly.
    if (arguments is! List && arguments is! Map) arguments = [arguments];
    return template.instantiate(arguments) as Statement;
  }

  /// Parses JavaScript written in the `JS` foreign instruction.
  ///
  /// The [source] must be a JavaScript expression or a JavaScript throw
  /// statement.
  Template parseForeignJS(String source) {
    // TODO(sra): Parse with extra validation to forbid `#` interpolation in
    // functions, as this leads to unanticipated capture of temporaries that are
    // reused after capture.
    if (source.startsWith('throw ')) {
      return _findStatementTemplate(source);
    } else {
      return _findExpressionTemplate(source);
    }
  }

  Template _findExpressionTemplate(String source) {
    Template? template = templateManager.lookupExpressionTemplate(source);
    if (template == null) {
      MiniJsParser parser = MiniJsParser(source);
      Expression expression = parser.expression();
      template = templateManager.defineExpressionTemplate(source, expression);
    }
    return template;
  }

  Template _findStatementTemplate(String source) {
    Template? template = templateManager.lookupStatementTemplate(source);
    if (template == null) {
      MiniJsParser parser = MiniJsParser(source);
      Statement statement = parser.statement();
      template = templateManager.defineStatementTemplate(source, statement);
    }
    return template;
  }

  /// Creates an Expression template for the given [source].
  ///
  /// The returned template is cached.
  Template expressionTemplateFor(String source) {
    return _findExpressionTemplate(source);
  }

  /// Creates an Expression template without caching the result.
  Template uncachedExpressionTemplate(String source) {
    MiniJsParser parser = MiniJsParser(source);
    Expression expression = parser.expression();
    return Template(source, expression, isExpression: true, forceCopy: false);
  }

  /// Creates a Statement template without caching the result.
  Template uncachedStatementTemplate(String source) {
    MiniJsParser parser = MiniJsParser(source);
    Statement statement = parser.statement();
    return Template(source, statement, isExpression: false, forceCopy: false);
  }

  /// Create an Expression template which has [ast] as the result. This is used
  /// to wrap a generated AST in a zero-argument Template so it can be passed to
  /// context that expects a template.
  Template expressionTemplateYielding(Expression ast) {
    return Template.withExpressionResult(ast);
  }

  Template statementTemplateYielding(Statement ast) {
    return Template.withStatementResult(ast);
  }

  /// Creates a literal js string from [value].
  LiteralString string(String value) => LiteralString(value);

  StringConcatenation concatenateStrings(Iterable<Literal> parts) {
    return StringConcatenation(List.of(parts, growable: false));
  }

  Iterable<Literal> joinLiterals(
      Iterable<Literal> items, Literal separator) sync* {
    bool first = true;
    for (final item in items) {
      if (!first) yield separator;
      yield item;
      first = false;
    }
  }

  LiteralString quoteName(Name name) {
    return LiteralStringFromName(name);
  }

  LiteralNumber number(num value) => LiteralNumber('$value');

  LiteralBool boolean(bool value) => LiteralBool(value);

  ArrayInitializer numArray(Iterable<int> list) =>
      ArrayInitializer(list.map(number).toList());

  ArrayInitializer stringArray(Iterable<String> list) =>
      ArrayInitializer(list.map(string).toList());

  Comment comment(String text) => Comment(text);

  Call propertyCall(
      Expression receiver, Expression fieldName, List<Expression> arguments) {
    return Call(PropertyAccess(receiver, fieldName), arguments);
  }

  ObjectInitializer objectLiteral(Map<String, Expression> map) {
    List<Property> properties = [];
    map.forEach((name, value) {
      properties.add(Property(string(name), value));
    });
    return ObjectInitializer(properties);
  }
}

LiteralString string(String value) => js.string(value);

/// Returns a LiteralString which has contents determined by [Name].
///
/// This is used to force a Name to be a string literal regardless of
/// context. It is not necessary for properties.
LiteralString quoteName(Name name) => js.quoteName(name);

Iterable<Literal> joinLiterals(Iterable<Literal> list, Literal separator) {
  return js.joinLiterals(list, separator);
}

StringConcatenation concatenateStrings(Iterable<Literal> parts) {
  return js.concatenateStrings(parts);
}

LiteralNumber number(num value) => js.number(value);
ArrayInitializer numArray(Iterable<int> list) => js.numArray(list);
ArrayInitializer stringArray(Iterable<String> list) => js.stringArray(list);
Call propertyCall(
    Expression receiver, Expression fieldName, List<Expression> arguments) {
  return js.propertyCall(receiver, fieldName, arguments);
}

ObjectInitializer objectLiteral(Map<String, Expression> map) {
  return js.objectLiteral(map);
}

class MiniJsParserError {
  MiniJsParserError(this.parser, this.message);

  final MiniJsParser parser;
  final String message;

  @override
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
    return 'Error in MiniJsParser:\n$src\n$spaces^\n$spaces$message\n';
  }
}

enum _Category {
  none,
  alpha,
  numeric,
  string,
  symbol,
  assignment,
  dot,
  lparen,
  rparen,
  lbrace,
  rbrace,
  lsquare,
  rsquare,
  comma,
  query,
  colon,
  semicolon,
  arrow,
  hash,
  whitespace,
  other,
  ;

  static const _asciiTable = <_Category>[
    other, other, other, other, other, other, other, other, // 0-7
    other, whitespace, whitespace, other, other, whitespace, // 8-13
    other, other, other, other, other, other, other, other, // 14-21
    other, other, other, other, other, other, other, other, // 22-29
    other, other, whitespace, // 30-32
    symbol, other, hash, alpha, symbol, symbol, other, // !"#$%&`
    lparen, rparen, symbol, symbol, comma, symbol, dot, symbol, // ()*+,-./
    numeric, numeric, numeric, numeric, numeric, // 01234
    numeric, numeric, numeric, numeric, numeric, // 56789
    colon, semicolon, symbol, symbol, symbol, query, other, // :;<=>?@
    alpha, alpha, alpha, alpha, alpha, alpha, alpha, alpha, // ABCDEFGH
    alpha, alpha, alpha, alpha, alpha, alpha, alpha, alpha, // IJKLMNOP
    alpha, alpha, alpha, alpha, alpha, alpha, alpha, alpha, // QRSTUVWX
    alpha, alpha, lsquare, other, rsquare, symbol, alpha, other, // YZ[\]^_'
    alpha, alpha, alpha, alpha, alpha, alpha, alpha, alpha, // abcdefgh
    alpha, alpha, alpha, alpha, alpha, alpha, alpha, alpha, // ijklmnop
    alpha, alpha, alpha, alpha, alpha, alpha, alpha, alpha, // qrstuvwx
    alpha, alpha, lbrace, symbol, rbrace, symbol, // yx{|}~
  ];
}

/// Mini JavaScript parser for tiny snippets of code that we want to make into
/// AST nodes. Handles:
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
///   var x = "foo\n\"bar\"" in the final program. \x and \u escapes are not
/// allowed in string and regexp literals because the machinery for checking
/// their correctness is rather involved.
class MiniJsParser {
  MiniJsParser(this.src) {
    getToken();
  }

  _Category _lastCategory = _Category.none;
  String lastToken = '';
  int lastPosition = 0;
  int position = 0;
  bool skippedNewline = false; // skipped newline in last getToken?
  final String src;

  final List<InterpolatedNode> interpolatedValues = [];
  bool get hasNamedHoles =>
      interpolatedValues.isNotEmpty && interpolatedValues.first.isNamed;
  bool get hasPositionalHoles =>
      interpolatedValues.isNotEmpty && interpolatedValues.first.isPositional;

  // Make sure that ]] is two symbols.
  bool _singleCharCategory(_Category category) =>
      category.index >= _Category.dot.index;

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
    '**=': 17,
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
    '%': 5,
    '**': 4,
  };
  static final UNARY_OPERATORS = {
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
  };

  static final OPERATORS_THAT_LOOK_LIKE_IDENTIFIERS = {
    'typeof',
    'void',
    'delete',
    'in',
    'instanceof',
    'await'
  };

  static _Category _category(int code) {
    if (code >= _Category._asciiTable.length) return _Category.other;
    return _Category._asciiTable[code];
  }

  String getRegExp(int startPosition) {
    position = startPosition;
    int delimiter = src.codeUnitAt(startPosition);
    int currentCode;
    do {
      position++;
      if (position >= src.length) error('Unterminated literal');
      currentCode = src.codeUnitAt(position);
      if (currentCode == char_codes.$LF) error('Unterminated literal');
      if (currentCode == char_codes.$BACKSLASH) {
        if (++position >= src.length) error('Unterminated literal');
        int escaped = src.codeUnitAt(position);
        if (escaped == char_codes.$x ||
            escaped == char_codes.$X ||
            escaped == char_codes.$u ||
            escaped == char_codes.$U ||
            _category(escaped) == _Category.numeric) {
          error('Numeric and hex escapes are not supported in RegExp literals');
        }
      }
    } while (currentCode != delimiter);
    position++;
    return src.substring(lastPosition, position);
  }

  String getString(int startPosition, int quote) {
    assert(src.codeUnitAt(startPosition) == quote);
    position = startPosition + 1;
    final value = StringBuffer();
    while (true) {
      if (position >= src.length) error('Unterminated literal');
      int code = src.codeUnitAt(position++);
      if (code == quote) break;
      if (code == char_codes.$LF) error('Unterminated literal');
      if (code == char_codes.$BACKSLASH) {
        if (position >= src.length) error('Unterminated literal');
        code = src.codeUnitAt(position++);
        if (code == char_codes.$f) {
          value.writeCharCode(12);
        } else if (code == char_codes.$n) {
          value.writeCharCode(10);
        } else if (code == char_codes.$r) {
          value.writeCharCode(13);
        } else if (code == char_codes.$t) {
          value.writeCharCode(8);
        } else if (code == char_codes.$BACKSLASH ||
            code == char_codes.$SQ ||
            code == char_codes.$DQ) {
          value.writeCharCode(code);
        } else if (code == char_codes.$x || code == char_codes.$X) {
          error('Hex escapes not supported in string literals');
        } else if (code == char_codes.$u || code == char_codes.$U) {
          error('Unicode escapes not supported in string literals');
        } else if (char_codes.$0 <= code && code <= char_codes.$9) {
          error('Numeric escapes not supported in string literals');
        } else {
          error('Unknown escape U+${code.toRadixString(16).padLeft(4, '0')}');
        }
        continue;
      }
      value.writeCharCode(code);
    }
    return value.toString();
  }

  void getToken() {
    skippedNewline = false;
    for (;;) {
      if (position >= src.length) break;
      int code = src.codeUnitAt(position);
      //  Skip '//' and '/*' style comments.
      if (code == char_codes.$SLASH && position + 1 < src.length) {
        if (src.codeUnitAt(position + 1) == char_codes.$SLASH) {
          int nextPosition = src.indexOf('\n', position);
          if (nextPosition == -1) nextPosition = src.length;
          position = nextPosition;
          continue;
        } else if (src.codeUnitAt(position + 1) == char_codes.$STAR) {
          int nextPosition = src.indexOf('*/', position + 2);
          if (nextPosition == -1) error('Unterminated comment');
          position = nextPosition + 2;
          continue;
        }
      }
      if (_category(code) != _Category.whitespace) break;
      if (code == char_codes.$LF) skippedNewline = true;
      ++position;
    }

    if (position == src.length) {
      _lastCategory = _Category.none;
      lastToken = '';
      lastPosition = position;
      return;
    }
    int code = src.codeUnitAt(position);
    lastPosition = position;
    if (code == char_codes.$SQ || code == char_codes.$DQ) {
      // String literal.
      _lastCategory = _Category.string;
      lastToken = getString(position, code);
    } else if (code == char_codes.$0 &&
        position + 2 < src.length &&
        src.codeUnitAt(position + 1) == char_codes.$x) {
      // Hex literal.
      for (position += 2; position < src.length; position++) {
        final cat = _category(src.codeUnitAt(position));
        if (cat != _Category.numeric && cat != _Category.alpha) break;
      }
      _lastCategory = _Category.numeric;
      lastToken = src.substring(lastPosition, position);
      if (int.tryParse(lastToken) == null) {
        error('Unparseable number');
      }
    } else if (code == char_codes.$SLASH) {
      // Tokens that start with / are special due to regexp literals.
      _lastCategory = _Category.symbol;
      position++;
      if (position < src.length && src.codeUnitAt(position) == char_codes.$EQ) {
        position++;
      }
      lastToken = src.substring(lastPosition, position);
    } else {
      // All other tokens handled here.
      final cat = _category(src.codeUnitAt(position));
      _Category newCat;
      do {
        position++;
        if (position == src.length) break;
        int code = src.codeUnitAt(position);
        // Special code to disallow !, ~ and / in non-first position in token,
        // so that !! and ~~ parse as two tokens and != parses as one, while =/
        // parses as a an equals token followed by a regexp literal start.
        newCat = (code == char_codes.$BANG ||
                code == char_codes.$SLASH ||
                code == char_codes.$TILDE)
            ? _Category.none
            : _category(code);
      } while (!_singleCharCategory(cat) &&
          (cat == newCat ||
              (cat == _Category.alpha &&
                  newCat == _Category.numeric) || // eg. level42.
              (cat == _Category.numeric &&
                  newCat == _Category.dot))); // eg. 3.1415
      _lastCategory = cat;
      lastToken = src.substring(lastPosition, position);
      if (cat == _Category.numeric) {
        if (double.tryParse(lastToken) == null) {
          error('Unparseable number');
        }
      } else if (cat == _Category.symbol) {
        if (lastToken == '=>') {
          _lastCategory = _Category.arrow;
        } else {
          int? binaryPrecedence = BINARY_PRECEDENCE[lastToken];
          if (binaryPrecedence == null &&
              !UNARY_OPERATORS.contains(lastToken)) {
            error('Unknown operator');
          }
          if (isAssignment(lastToken)) _lastCategory = _Category.assignment;
        }
      } else if (cat == _Category.alpha) {
        if (OPERATORS_THAT_LOOK_LIKE_IDENTIFIERS.contains(lastToken)) {
          _lastCategory = _Category.symbol;
        }
      }
    }
  }

  void _expectCategory(_Category cat) {
    if (cat != _lastCategory) error('Expected $cat');
    getToken();
  }

  bool _acceptCategory(_Category cat) {
    if (cat == _lastCategory) {
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
    if (_Category.rbrace == _lastCategory) return true;
    if (_Category.none == _lastCategory) return true; // end of input
    if (skippedNewline) {
      error('No automatic semicolon insertion at preceding newline');
    }
    return _acceptCategory(_Category.semicolon);
  }

  bool acceptString(String string) {
    if (lastToken == string) {
      getToken();
      return true;
    }
    return false;
  }

  Never error(String message) {
    throw MiniJsParserError(this, message);
  }

  /// Returns either the name for the hole, or its integer position.
  Object parseHash() {
    String holeName = lastToken;
    if (_acceptCategory(_Category.alpha)) {
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
    if (_acceptCategory(_Category.alpha)) {
      if (last == 'true') {
        return LiteralBool(true);
      } else if (last == 'false') {
        return LiteralBool(false);
      } else if (last == 'null') {
        return LiteralNull();
      } else if (last == 'function') {
        return parseFunctionExpression();
      } else if (last == 'this') {
        return This();
      } else {
        return VariableUse(last);
      }
    } else if (_acceptCategory(_Category.lparen)) {
      return parseExpressionOrArrowFunction();
    } else if (_acceptCategory(_Category.string)) {
      return LiteralString(last);
    } else if (_acceptCategory(_Category.numeric)) {
      return LiteralNumber(last);
    } else if (_acceptCategory(_Category.lbrace)) {
      return parseObjectInitializer();
    } else if (_acceptCategory(_Category.lsquare)) {
      var values = <Expression>[];
      while (true) {
        if (_acceptCategory(_Category.comma)) {
          values.add(ArrayHole());
          continue;
        }
        if (_acceptCategory(_Category.rsquare)) break;
        values.add(parseAssignment());
        if (_acceptCategory(_Category.rsquare)) break;
        _expectCategory(_Category.comma);
      }
      return ArrayInitializer(values);
    } else if (last.startsWith('/')) {
      String regexp = getRegExp(lastPosition);
      getToken();
      String flags = lastToken;
      if (!_acceptCategory(_Category.alpha)) flags = '';
      Expression expression = RegExpLiteral(regexp + flags);
      return expression;
    } else if (_acceptCategory(_Category.hash)) {
      var nameOrPosition = parseHash();
      InterpolatedExpression expression =
          InterpolatedExpression(nameOrPosition);
      interpolatedValues.add(expression);
      return expression;
    } else {
      error('Expected primary expression');
    }
  }

  Expression parseFunctionExpression() {
    if (_lastCategory == _Category.alpha || _lastCategory == _Category.hash) {
      Declaration name = parseVariableDeclaration();
      return NamedFunction(name, parseFun());
    }
    return parseFun();
  }

  Fun parseFun() {
    List<Parameter> params = [];
    _expectCategory(_Category.lparen);
    if (!_acceptCategory(_Category.rparen)) {
      for (;;) {
        if (_acceptCategory(_Category.hash)) {
          var nameOrPosition = parseHash();
          InterpolatedParameter parameter =
              InterpolatedParameter(nameOrPosition);
          interpolatedValues.add(parameter);
          params.add(parameter);
        } else {
          String argumentName = lastToken;
          _expectCategory(_Category.alpha);
          params.add(Parameter(argumentName));
        }
        if (_acceptCategory(_Category.comma)) continue;
        _expectCategory(_Category.rparen);
        break;
      }
    }
    AsyncModifier asyncModifier;
    if (acceptString('async')) {
      if (acceptString('*')) {
        asyncModifier = AsyncModifier.asyncStar;
      } else {
        asyncModifier = AsyncModifier.async;
      }
    } else if (acceptString('sync')) {
      if (!acceptString('*')) error('Only sync* is valid - sync is implied');
      asyncModifier = AsyncModifier.syncStar;
    } else {
      asyncModifier = AsyncModifier.sync;
    }
    _expectCategory(_Category.lbrace);
    Block block = parseBlock();
    return Fun(params, block, asyncModifier: asyncModifier);
  }

  Expression parseObjectInitializer() {
    List<Property> properties = [];
    for (;;) {
      if (_acceptCategory(_Category.rbrace)) break;
      properties.add(parseMethodDefinitionOrProperty());
      if (_acceptCategory(_Category.rbrace)) break;
      _expectCategory(_Category.comma);
    }
    return ObjectInitializer(properties);
  }

  Property parseMethodDefinitionOrProperty() {
    // Limited subset: keys are identifiers, no 'get' or 'set' properties.
    Literal propertyName;
    String identifier = lastToken;
    if (_acceptCategory(_Category.alpha)) {
      propertyName = LiteralString(identifier);
    } else if (_acceptCategory(_Category.string)) {
      propertyName = LiteralString(identifier);
    } else if (_acceptCategory(_Category.symbol)) {
      // e.g. void
      propertyName = LiteralString(identifier);
    } else if (_acceptCategory(_Category.hash)) {
      var nameOrPosition = parseHash();
      InterpolatedLiteral interpolatedLiteral =
          InterpolatedLiteral(nameOrPosition);
      interpolatedValues.add(interpolatedLiteral);
      propertyName = interpolatedLiteral;
    } else {
      error('Expected property name');
    }
    if (_acceptCategory(_Category.colon)) {
      Expression value = parseAssignment();
      return Property(propertyName, value);
    } else {
      final fun = parseFun();
      return MethodDefinition(propertyName, fun);
    }
  }

  Expression parseMember() {
    Expression receiver = parsePrimary();
    while (true) {
      if (_acceptCategory(_Category.dot)) {
        receiver = getDotRhs(receiver);
      } else if (_acceptCategory(_Category.lsquare)) {
        Expression inBraces = parseExpression();
        _expectCategory(_Category.rsquare);
        receiver = PropertyAccess(receiver, inBraces);
      } else {
        break;
      }
    }
    return receiver;
  }

  Expression parseCall() {
    bool constructor = acceptString('new');
    Expression receiver = parseMember();
    while (true) {
      if (_acceptCategory(_Category.lparen)) {
        final arguments = <Expression>[];
        if (!_acceptCategory(_Category.rparen)) {
          while (true) {
            Expression argument = parseAssignment();
            arguments.add(argument);
            if (_acceptCategory(_Category.rparen)) break;
            _expectCategory(_Category.comma);
          }
        }
        receiver =
            constructor ? New(receiver, arguments) : Call(receiver, arguments);
        constructor = false;
      } else if (!constructor && _acceptCategory(_Category.lsquare)) {
        Expression inBraces = parseExpression();
        _expectCategory(_Category.rsquare);
        receiver = PropertyAccess(receiver, inBraces);
      } else if (!constructor && _acceptCategory(_Category.dot)) {
        receiver = getDotRhs(receiver);
      } else {
        // JS allows new without (), but we don't.
        if (constructor) error('Parentheses are required for new');
        break;
      }
    }
    return receiver;
  }

  Expression getDotRhs(Expression receiver) {
    if (_acceptCategory(_Category.hash)) {
      var nameOrPosition = parseHash();
      InterpolatedSelector property = InterpolatedSelector(nameOrPosition);
      interpolatedValues.add(property);
      return PropertyAccess(receiver, property);
    }
    String identifier = lastToken;
    // In ES5 keywords like delete and continue are allowed as property
    // names, and the IndexedDB API uses that, so we need to allow it here.
    if (_acceptCategory(_Category.symbol)) {
      if (!OPERATORS_THAT_LOOK_LIKE_IDENTIFIERS.contains(identifier)) {
        error('Expected alphanumeric identifier');
      }
    } else {
      _expectCategory(_Category.alpha);
    }
    return PropertyAccess.field(receiver, identifier);
  }

  Expression parsePostfix() {
    Expression expression = parseCall();
    String operator = lastToken;
    // JavaScript grammar is:
    //     LeftHandSideExpression [no LineTerminator here] ++
    if (_lastCategory == _Category.symbol &&
        !skippedNewline &&
        (acceptString('++') || acceptString('--'))) {
      return Postfix(operator, expression);
    }
    // If we don't accept '++' or '--' due to skippedNewline a newline, no other
    // part of the parser will accept the token and we will get an error at the
    // whole expression level.
    return expression;
  }

  Expression parseUnaryHigh() {
    String operator = lastToken;
    if (_lastCategory == _Category.symbol &&
        UNARY_OPERATORS.contains(operator) &&
        (acceptString('++') || acceptString('--') || acceptString('await'))) {
      if (operator == 'await') return Await(parsePostfix());
      return Prefix(operator, parsePostfix());
    }
    return parsePostfix();
  }

  Expression parseUnaryLow() {
    String operator = lastToken;
    if (_lastCategory == _Category.symbol &&
        UNARY_OPERATORS.contains(operator) &&
        operator != '++' &&
        operator != '--') {
      _expectCategory(_Category.symbol);
      if (operator == 'await') return Await(parsePostfix());
      return Prefix(operator, parseUnaryLow());
    }
    return parseUnaryHigh();
  }

  Expression parseBinary(int maxPrecedence) {
    Expression lhs = parseUnaryLow();
    Expression? rhs; // This is null first time around.
    late int minPrecedence;
    late String lastSymbol;

    while (true) {
      final symbol = lastToken;
      if (_lastCategory != _Category.symbol) break;
      final symbolPrecedence = BINARY_PRECEDENCE[symbol];
      if (symbolPrecedence == null) break;
      if (symbolPrecedence > maxPrecedence) break;

      _expectCategory(_Category.symbol);
      if (rhs == null || symbolPrecedence >= minPrecedence) {
        if (rhs != null) lhs = Binary(lastSymbol, lhs, rhs);
        minPrecedence = symbolPrecedence;
        rhs = parseUnaryLow();
        lastSymbol = symbol;
      } else {
        Expression higher = parseBinary(symbolPrecedence);
        rhs = Binary(symbol, rhs, higher);
      }
    }

    if (rhs == null) return lhs;
    return Binary(lastSymbol, lhs, rhs);
  }

  Expression parseConditional() {
    Expression lhs = parseBinary(HIGHEST_PARSE_BINARY_PRECEDENCE);
    if (!_acceptCategory(_Category.query)) return lhs;
    Expression ifTrue = parseAssignment();
    _expectCategory(_Category.colon);
    Expression ifFalse = parseAssignment();
    return Conditional(lhs, ifTrue, ifFalse);
  }

  Expression parseAssignment() {
    Expression lhs = parseConditional();
    String assignmentOperator = lastToken;
    if (_acceptCategory(_Category.assignment)) {
      Expression rhs = parseAssignment();
      if (assignmentOperator == '=') {
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
    while (_acceptCategory(_Category.comma)) {
      Expression right = parseAssignment();
      expression = Binary(',', expression, right);
    }
    return expression;
  }

  Expression parseExpressionOrArrowFunction() {
    if (_acceptCategory(_Category.rparen)) {
      _expectCategory(_Category.arrow);
      return parseArrowFunctionBody([]);
    }
    List<Expression> expressions = [parseAssignment()];
    while (_acceptCategory(_Category.comma)) {
      expressions.add(parseAssignment());
    }
    _expectCategory(_Category.rparen);
    if (_acceptCategory(_Category.arrow)) {
      var params = <Parameter>[];
      for (Expression e in expressions) {
        if (e is VariableUse) {
          params.add(Parameter(e.name));
        } else if (e is InterpolatedExpression) {
          params.add(InterpolatedParameter(e.nameOrPosition));
        } else {
          error('Expected arrow function parameter list');
        }
      }
      return parseArrowFunctionBody(params);
    }
    return expressions.reduce(
        (Expression value, Expression element) => Binary(',', value, element));
  }

  Expression parseArrowFunctionBody(List<Parameter> params) {
    Node body;
    if (_acceptCategory(_Category.lbrace)) {
      body = parseBlock();
    } else {
      body = parseAssignment();
    }
    return ArrowFunction(params, body);
  }

  VariableDeclarationList parseVariableDeclarationList() {
    Declaration firstVariable = parseVariableDeclaration();
    return finishVariableDeclarationList(firstVariable);
  }

  VariableDeclarationList finishVariableDeclarationList(
      Declaration firstVariable) {
    var initialization = <VariableInitialization>[];

    void declare(Declaration declaration) {
      Expression? initializer;
      if (acceptString('=')) {
        initializer = parseAssignment();
      }
      initialization.add(VariableInitialization(declaration, initializer));
    }

    declare(firstVariable);
    while (_acceptCategory(_Category.comma)) {
      Declaration variable = parseVariableDeclaration();
      declare(variable);
    }
    return VariableDeclarationList(initialization);
  }

  Expression parseVarDeclarationOrExpression() {
    if (acceptString('var')) {
      return parseVariableDeclarationList();
    } else {
      return parseExpression();
    }
  }

  Expression expression() {
    Expression expression = parseVarDeclarationOrExpression();
    if (_lastCategory != _Category.none || position != src.length) {
      error('Unparsed junk: $_lastCategory');
    }
    return expression;
  }

  Statement statement() {
    Statement statement = parseStatement();
    if (_lastCategory != _Category.none || position != src.length) {
      error('Unparsed junk: $_lastCategory');
    }
    // TODO(sra): interpolated capture here?
    return statement;
  }

  Block parseBlock() {
    List<Statement> statements = [];

    while (!_acceptCategory(_Category.rbrace)) {
      Statement statement = parseStatement();
      statements.add(statement);
    }
    return Block(statements);
  }

  Statement parseStatement() {
    if (_acceptCategory(_Category.lbrace)) return parseBlock();

    if (_acceptCategory(_Category.semicolon)) return EmptyStatement();

    if (_lastCategory == _Category.alpha) {
      if (acceptString('return')) return parseReturn();

      if (acceptString('throw')) return parseThrow();

      if (acceptString('break')) {
        return parseBreakOrContinue((label) => Break(label));
      }

      if (acceptString('continue')) {
        return parseBreakOrContinue((label) => Continue(label));
      }

      if (acceptString('if')) return parseIfThenElse();

      if (acceptString('for')) return parseFor();

      if (acceptString('function')) return parseFunctionDeclaration();

      if (acceptString('try')) return parseTry();

      if (acceptString('var')) {
        Expression declarations = parseVariableDeclarationList();
        expectSemicolon();
        return ExpressionStatement(declarations);
      }

      if (acceptString('while')) return parseWhile();

      if (acceptString('do')) return parseDo();

      if (acceptString('switch')) return parseSwitch();

      if (lastToken == 'case') error('Case outside switch.');

      if (lastToken == 'default') error('Default outside switch.');

      if (lastToken == 'yield') return parseYield();

      if (lastToken == 'with') {
        error('Not implemented in mini parser');
      }
    }

    bool checkForInterpolatedStatement = _lastCategory == _Category.hash;

    Expression expression = parseExpression();

    if (expression is VariableUse && _acceptCategory(_Category.colon)) {
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

  Statement parseBreakOrContinue(Statement Function(String?) constructor) {
    var identifier = lastToken;
    if (!skippedNewline && _acceptCategory(_Category.alpha)) {
      expectSemicolon();
      return constructor(identifier);
    }
    expectSemicolon();
    return constructor(null);
  }

  Statement parseIfThenElse() {
    _expectCategory(_Category.lparen);
    Expression condition = parseExpression();
    _expectCategory(_Category.rparen);
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
    Statement finishFor(Expression? init) {
      Expression? condition;
      if (!_acceptCategory(_Category.semicolon)) {
        condition = parseExpression();
        _expectCategory(_Category.semicolon);
      }
      Expression? update;
      if (!_acceptCategory(_Category.rparen)) {
        update = parseExpression();
        _expectCategory(_Category.rparen);
      }
      Statement body = parseStatement();
      return For(init, condition, update, body);
    }

    _expectCategory(_Category.lparen);
    if (_acceptCategory(_Category.semicolon)) {
      return finishFor(null);
    }

    if (acceptString('var')) {
      Declaration declaration = parseVariableDeclaration();
      if (acceptString('in')) {
        Expression objectExpression = parseExpression();
        _expectCategory(_Category.rparen);
        Statement body = parseStatement();
        return ForIn(
            VariableDeclarationList(
                [VariableInitialization(declaration, null)]),
            objectExpression,
            body);
      }
      Expression declarations = finishVariableDeclarationList(declaration);
      _expectCategory(_Category.semicolon);
      return finishFor(declarations);
    }

    Expression init = parseExpression();
    _expectCategory(_Category.semicolon);
    return finishFor(init);
  }

  Declaration parseVariableDeclaration() {
    if (_acceptCategory(_Category.hash)) {
      var nameOrPosition = parseHash();
      InterpolatedDeclaration declaration =
          InterpolatedDeclaration(nameOrPosition);
      interpolatedValues.add(declaration);
      return declaration;
    } else {
      String token = lastToken;
      _expectCategory(_Category.alpha);
      return VariableDeclaration(token);
    }
  }

  Statement parseFunctionDeclaration() {
    Declaration name = parseVariableDeclaration();
    Fun fun = parseFun();
    return FunctionDeclaration(name, fun);
  }

  Statement parseTry() {
    _expectCategory(_Category.lbrace);
    Block body = parseBlock();
    Catch? catchPart;
    if (acceptString('catch')) catchPart = parseCatch();
    Block? finallyPart;
    if (acceptString('finally')) {
      _expectCategory(_Category.lbrace);
      finallyPart = parseBlock();
    } else {
      if (catchPart == null) error("expected 'finally'");
    }
    return Try(body, catchPart, finallyPart);
  }

  SwitchClause parseSwitchClause() {
    Expression? expression;
    if (acceptString('case')) {
      expression = parseExpression();
      _expectCategory(_Category.colon);
    } else {
      if (!acceptString('default')) {
        error('expected case or default');
      }
      _expectCategory(_Category.colon);
    }
    List<Statement> statements = [];
    while (_lastCategory != _Category.rbrace &&
        lastToken != 'case' &&
        lastToken != 'default') {
      statements.add(parseStatement());
    }
    return expression == null
        ? Default(Block(statements))
        : Case(expression, Block(statements));
  }

  Statement parseWhile() {
    _expectCategory(_Category.lparen);
    Expression condition = parseExpression();
    _expectCategory(_Category.rparen);
    Statement body = parseStatement();
    return While(condition, body);
  }

  Statement parseDo() {
    Statement body = parseStatement();
    if (lastToken != 'while') error('Missing while after do body.');
    getToken();
    _expectCategory(_Category.lparen);
    Expression condition = parseExpression();
    _expectCategory(_Category.rparen);
    expectSemicolon();
    return Do(body, condition);
  }

  Statement parseSwitch() {
    _expectCategory(_Category.lparen);
    Expression key = parseExpression();
    _expectCategory(_Category.rparen);
    _expectCategory(_Category.lbrace);
    List<SwitchClause> clauses = [];
    while (_lastCategory != _Category.rbrace) {
      clauses.add(parseSwitchClause());
    }
    _expectCategory(_Category.rbrace);
    return Switch(key, clauses);
  }

  Catch parseCatch() {
    _expectCategory(_Category.lparen);
    Declaration errorName = parseVariableDeclaration();
    _expectCategory(_Category.rparen);
    _expectCategory(_Category.lbrace);
    Block body = parseBlock();
    return Catch(errorName, body);
  }
}
