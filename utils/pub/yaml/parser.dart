// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Translates a string of characters into a YAML serialization tree.
 *
 * This parser is designed to closely follow the spec. All productions in the
 * spec are numbered, and the corresponding methods in the parser have the same
 * numbers. This is certainly not the most efficient way of parsing YAML, but it
 * is the easiest to write and read in the context of the spec.
 *
 * Methods corresponding to productions are also named as in the spec,
 * translating the name of the method (although not the annotation characters)
 * into camel-case for dart style.. For example, the spec has a production named
 * `nb-ns-plain-in-line`, and the method implementing it is named
 * `nb_ns_plainInLine`. The exception to that rule is methods that just
 * recognize character classes; these are named `is*`.
 */
class _Parser {
  static final TAB = 0x9;
  static final LF = 0xA;
  static final CR = 0xD;
  static final SP = 0x20;
  static final TILDE = 0x7E;
  static final NEL = 0x85;
  static final HYPHEN = 0x2D;
  static final QUESTION_MARK = 0x3F;
  static final COLON = 0x3A;
  static final COMMA = 0x2C;
  static final LEFT_BRACKET = 0x5B;
  static final RIGHT_BRACKET = 0x5D;
  static final LEFT_BRACE = 0x7B;
  static final RIGHT_BRACE = 0x7D;
  static final HASH = 0x23;
  static final AMPERSAND = 0x26;
  static final ASTERISK = 0x2A;
  static final EXCLAMATION = 0x21;
  static final VERTICAL_BAR = 0x7C;
  static final GREATER_THAN = 0x3E;
  static final SINGLE_QUOTE = 0x27;
  static final DOUBLE_QUOTE = 0x22;
  static final PERCENT = 0x25;
  static final AT = 0x40;
  static final GRAVE_ACCENT = 0x60;

  static final NULL = 0x0;
  static final BELL = 0x7;
  static final BACKSPACE = 0x8;
  static final VERTICAL_TAB = 0xB;
  static final FORM_FEED = 0xC;
  static final ESCAPE = 0x1B;
  static final BACKSLASH = 0x5C;
  static final NBSP = 0xA0;
  static final LINE_SEPARATOR = 0x2028;
  static final PARAGRAPH_SEPARATOR = 0x2029;

  static final C_SEQUENCE_ENTRY = 4;
  static final C_MAPPING_KEY = 5;
  static final C_MAPPING_VALUE = 6;
  static final C_COLLECT_ENTRY = 7;
  static final C_SEQUENCE_START = 8;
  static final C_SEQUENCE_END = 9;
  static final C_MAPPING_START = 10;
  static final C_MAPPING_END = 11;
  static final C_COMMENT = 12;
  static final C_ANCHOR = 13;
  static final C_ALIAS = 14;
  static final C_TAG = 15;
  static final C_LITERAL = 16;
  static final C_FOLDED = 17;
  static final C_SINGLE_QUOTE = 18;
  static final C_DOUBLE_QUOTE = 19;
  static final C_DIRECTIVE = 20;
  static final C_RESERVED = 21;

  static final BLOCK_OUT = 0;
  static final BLOCK_IN = 1;
  static final FLOW_OUT = 2;
  static final FLOW_IN = 3;
  static final BLOCK_KEY = 4;
  static final FLOW_KEY = 5;

  /** The source string being parsed. */
  final String s;

  /** The current position in the source string. */
  int pos = 0;

  /** The length of the string being parsed. */
  final int len;

  /** The current (0-based) line in the source string. */
  int line = 0;

  /** The current (0-based) column in the source string. */
  int column = 0;

  /**
   * Whether we're parsing a bare document (that is, one that doesn't begin with
   * `---`). Bare documents don't allow `%` immediately following newlines.
   */
  bool inBareDocument = false;

  /**
   * The line number of the farthest position that has been parsed successfully
   * before backtracking. Used for error reporting.
   */
  int farthestLine = 0;

  /**
   * The column number of the farthest position that has been parsed
   * successfully before backtracking. Used for error reporting.
   */
  int farthestColumn = 0;

  /**
   * The name of the context of the farthest position that has been parsed
   * successfully before backtracking. Used for error reporting.
   */
  String farthestContext = "document";

  /** A stack of the names of parse contexts. Used for error reporting. */
  List<String> contextStack;

  _Parser(String s)
    : this.s = s,
      len = s.length,
      contextStack = <String>["document"];

  /**
   * Return the character at the current position, then move that position
   * forward one character. Also updates the current line and column numbers.
   */
  int next() {
    if (pos == len) return -1;
    var char = s.charCodeAt(pos++);
    if (isBreak(char)) {
      line++;
      column = 0;
    } else {
      column++;
    }

    if (farthestLine < line) {
      farthestLine = line;
      farthestColumn = column;
      farthestContext = contextStack.last();
    } else if (farthestLine == line && farthestColumn < column) {
      farthestColumn = column;
      farthestContext = contextStack.last();
    }

    return char;
  }

  /**
   * Returns the character at the current position, or the character [i]
   * characters after the current position.
   *
   * Returns -1 if this would return a character after the end or before the
   * beginning of the input string.
   */
  int peek([int i = 0]) {
    var peekPos = pos + i;
    return (peekPos >= len || peekPos < 0) ? -1 : s.charCodeAt(peekPos);
  }

  /**
   * The truthiness operator. Returns `false` if [obj] is `null` or `false`,
   * `true` otherwise.
   */
  bool truth(obj) => obj != null && obj != false;

  /**
   * Consumes the current character if it matches [matcher]. Returns the result
   * of [matcher].
   */
  bool consume(bool matcher(int)) {
    if (matcher(peek())) {
      next();
      return true;
    }
    return false;
  }

  /**
   * Calls [consumer] until it returns a falsey value. Returns a list of all
   * truthy return values of [consumer], or null if it didn't consume anything.
   *
   * Conceptually, repeats a production one or more times.
   */
  List oneOrMore(consumer()) {
    var first = consumer();
    if (!truth(first)) return null;
    var out = [first];
    while (true) {
      var el = consumer();
      if (!truth(el)) return out;
      out.add(el);
    }
  }

  /**
   * Calls [consumer] until it returns a falsey value. Returns a list of all
   * truthy return values of [consumer], or the empty list if it didn't consume
   * anything.
   *
   * Conceptually, repeats a production any number of times.
   */
  List zeroOrMore(consumer()) {
    var out = [];
    var oldPos = pos;
    while (true) {
      var el = consumer();
      if (!truth(el) || oldPos == pos) return out;
      oldPos = pos;
      out.add(el);
    }
  }

  /**
   * Just calls [consumer] and returns its result. Used to make it explicit that
   * a production is intended to be optional.
   */
  zeroOrOne(consumer()) => consumer();

  /**
   * Calls each function in [consumers] until one returns a truthy value, then
   * returns that.
   */
  or(List<Function> consumers) {
    for (var c in consumers) {
      var res = c();
      if (truth(res)) return res;
    }
    return null;
  }

  /**
   * Calls [consumer] and returns its result, but rolls back the parser state if
   * [consumer] returns a falsey value.
   */
  transaction(consumer()) {
    int oldPos = pos, oldLine = line, oldColumn = column;
    var res = consumer();
    if (truth(res)) return res;

    pos = oldPos;
    line = oldLine;
    column = oldColumn;
    return res;
  }

  /**
   * Consumes [n] characters matching [matcher], or none if there isn't a
   * complete match. The first argument to [matcher] is the character code, the
   * second is the index (from 0 to [n] - 1).
   *
   * Returns whether or not the characters were consumed.
   */
  bool nAtOnce(int n, bool matcher(int c, int i)) => transaction(() {
    for (int i = 0; i < n; i++) {
      if (!consume((c) => matcher(c, i))) return false;
    }
    return true;
  });

  /**
   * Consumes the exact characters in [str], or nothing.
   *
   * Returns whether or not the string was consumed.
   */
  bool rawString(String str) =>
    nAtOnce(str.length, (c, i) => str.charCodeAt(i) == c);

  /**
   * Consumes and returns a string of characters matching [matcher], or null if
   * there are no such characters.
   */
  String stringOf(bool matcher(int)) =>
    captureString(() => oneOrMore(() => consume(matcher)));

  /**
   * Calls [consumer] and returns the string that was consumed while doing so,
   * or null if [consumer] returned a falsey value. Automatically wraps
   * [consumer] in `transaction`.
   */
  String captureString(consumer()) {
    int start = pos;
    var res = transaction(consumer);
    if (!truth(res)) return null;
    return s.substring(start, pos);
  }

  /**
   * Adds a tag and an anchor to [node], if they're defined.
   */
  _Node addProps(_Node node, _Pair<_Tag, String> props) {
    if (truth(props.first)) node.tag = props.first;
    if (truth(props.last)) node.anchor = props.last;
    return node;
  }

  /** Creates a MappingNode from [pairs]. */
  _MappingNode map(List<_Pair<_Node, _Node>> pairs) {
    var content = new Map<_Node, _Node>();
    pairs.forEach((pair) => content[pair.first] = pair.last);
    return new _MappingNode("?", content);
  }

  /** Runs [fn] in a context named [name]. Used for error reporting. */
  context(String name, fn()) {
    try {
      contextStack.add(name);
      return fn();
    } finally {
      var popped = contextStack.removeLast();
      assert(popped == name);
    }
  }

  /** Throws an error with additional context information. */
  error(String message) {
    // Line and column should be one-based.
    throw new SyntaxError(line + 1, column + 1,
        "$message (in $farthestContext)");
  }

  /**
   * If [result] is falsey, throws an error saying that [expected] was
   * expected.
   */
  expect(result, String expected) {
    if (truth(result)) return result;
    error("expected $expected");
  }

  /**
   * Throws an error saying that the parse failed. Uses [farthestLine],
   * [farthestColumn], and [farthestContext] to provide additional information.
   */
  parseFailed() {
    throw new SyntaxError(farthestLine + 1, farthestColumn + 1,
        "invalid YAML in $farthestContext");
  }

  /** Returns the number of spaces after the current position. */ 
  int countIndentation() {
    var i = 0;
    while (peek(i) == SP) i++;
    return i;
  }

  /** Returns whether the current position is at the beginning of a line. */
  bool get atStartOfLine() => column == 0;

  /** Returns whether the current position is at the end of the input. */
  bool get atEndOfFile() => pos == len;

  /**
   * Given an indicator character, returns the type of that indicator (or null
   * if the indicator isn't found.
   */
  int indicatorType(int char) {
    switch (char) {
    case HYPHEN: return C_SEQUENCE_ENTRY;
    case QUESTION_MARK: return C_MAPPING_KEY;
    case COLON: return C_MAPPING_VALUE;
    case COMMA: return C_COLLECT_ENTRY;
    case LEFT_BRACKET: return C_SEQUENCE_START;
    case RIGHT_BRACKET: return C_SEQUENCE_END;
    case LEFT_BRACE: return C_MAPPING_START;
    case RIGHT_BRACE: return C_MAPPING_END;
    case HASH: return C_COMMENT;
    case AMPERSAND: return C_ANCHOR;
    case ASTERISK: return C_ALIAS;
    case EXCLAMATION: return C_TAG;
    case VERTICAL_BAR: return C_LITERAL;
    case GREATER_THAN: return C_FOLDED;
    case SINGLE_QUOTE: return C_SINGLE_QUOTE;
    case DOUBLE_QUOTE: return C_DOUBLE_QUOTE;
    case PERCENT: return C_DIRECTIVE;
    case AT:
    case GRAVE_ACCENT:
      return C_RESERVED;
    default: return null;
    }
  }

  // 1
  bool isPrintable(int char) {
    return char == TAB ||
      char == LF ||
      char == CR ||
      (char >= SP && char <= TILDE) ||
      char == NEL ||
      (char >= 0xA0 && char <= 0xD7FF) ||
      (char >= 0xE000 && char <= 0xFFFD) ||
      (char >= 0x10000 && char <= 0x10FFFF);
  }

  // 22
  bool c_indicator(int type) => consume((c) => indicatorType(c) == type);

  // 23
  bool isFlowIndicator(int char) {
    var indicator = indicatorType(char);
    return indicator == C_COLLECT_ENTRY ||
      indicator == C_SEQUENCE_START ||
      indicator == C_SEQUENCE_END ||
      indicator == C_MAPPING_START ||
      indicator == C_MAPPING_END;
  }

  // 26
  bool isBreak(int char) => char == LF || char == CR;

  // 27
  bool isNonBreak(int char) => isPrintable(char) && !isBreak(char);

  // 30
  bool b_non_content() => consume(isBreak);

  // 33
  bool isSpace(int char) => char == SP || char == TAB;

  // 34
  bool isNonSpace(int char) => isNonBreak(char) && !isSpace(char);

  // 63
  bool s_indent(int indent) => nAtOnce(indent, (c, i) => c == SP);

  // 66
  bool s_separateInLine() => transaction(() =>
    truth(oneOrMore(() => consume(isSpace))) || atStartOfLine);

  // 69
  bool s_flowLinePrefix(int indent) {
    if (!s_indent(indent)) return false;
    zeroOrOne(s_separateInLine);
    return true;
  }

  // 74
  bool s_flowFolded(int indent) => false; // TODO(nweiz): implement

  // 75
  bool c_nb_commentText() {
    if (!c_indicator(C_COMMENT)) return false;
    zeroOrMore(() => consume(isNonBreak));
    return true;
  }

  // 76
  bool b_comment() => atEndOfFile || b_non_content();

  // 77
  bool s_b_comment() {
    if (s_separateInLine()) {
      zeroOrOne(c_nb_commentText);
    }
    return b_comment();
  }

  // 78
  bool l_comment() => transaction(() {
    if (!s_separateInLine()) return false;
    zeroOrOne(c_nb_commentText);
    return b_comment();
  });

  // 79
  bool s_l_comments() {
    if (!s_b_comment() && !atStartOfLine) return false;
    zeroOrMore(l_comment);
    return true;
  }

  // 80
  bool s_separate(int indent, int ctx) {
    switch (ctx) {
    case BLOCK_OUT:
    case BLOCK_IN:
    case FLOW_OUT:
    case FLOW_IN:
      return s_separateLines(indent);
    case BLOCK_KEY:
    case FLOW_KEY:
      return s_separateInLine();
    default: throw 'invalid context "$ctx"';
    }
  }

  // 81
  bool s_separateLines(int indent) {
    return transaction(() => s_l_comments() && s_flowLinePrefix(indent)) ||
      s_separateInLine();
  }

  // 82
  bool l_directive() => false; // TODO(nweiz): implement

  // 96
  _Pair<_Tag, String> c_ns_properties(int indent, int ctx) {
    var tag, anchor;
    tag = c_ns_tagProperty();
    if (truth(tag)) {
      anchor = transaction(() {
        if (!s_separate(indent, ctx)) return null;
        return c_ns_anchorProperty();
      });
      return new _Pair<_Tag, String>(tag, anchor);
    }

    anchor = c_ns_anchorProperty();
    if (truth(anchor)) {
      tag = transaction(() {
        if (!s_separate(indent, ctx)) return null;
        return c_ns_tagProperty();
      });
      return new _Pair<_Tag, String>(tag, anchor);
    }

    return null;
  }

  // 97
  _Tag c_ns_tagProperty() => null; // TODO(nweiz): implement

  // 101
  String c_ns_anchorProperty() => null; // TODO(nweiz): implement

  // 102
  bool isAnchorChar(int char) => isNonSpace(char) && !isFlowIndicator(char);

  // 103
  String ns_anchorName() =>
    captureString(() => oneOrMore(() => consume(isAnchorChar)));

  // 104
  _Node c_ns_aliasNode() {
    if (!c_indicator(C_ALIAS)) return null;
    var name = expect(ns_anchorName(), 'anchor name');
    return new _AliasNode(name);
  }

  // 105
  _ScalarNode e_scalar() => new _ScalarNode("?", content: "");

  // 106
  _ScalarNode e_node() => e_scalar();

  // 126
  bool ns_plainFirst(int ctx) {
    var char = peek();
    var indicator = indicatorType(char);
    if (indicator == C_RESERVED) {
      error("reserved indicators can't start a plain scalar");
    }
    var match = (isNonSpace(char) && indicator == null) ||
      ((indicator == C_MAPPING_KEY ||
        indicator == C_MAPPING_VALUE ||
        indicator == C_SEQUENCE_ENTRY) &&
       isPlainSafe(ctx, peek(1)));

    if (match) next();
    return match;
  }

  // 127
  bool isPlainSafe(int ctx, int char) {
    switch (ctx) {
    case FLOW_OUT:
    case BLOCK_KEY:
      // 128
      return isNonSpace(char);
    case FLOW_IN:
    case FLOW_KEY:
      // 129
      return isNonSpace(char) && !isFlowIndicator(char);
    default: throw 'invalid context "$ctx"';
    }
  }

  // 130
  bool ns_plainChar(int ctx) {
    var char = peek();
    var indicator = indicatorType(char);
    var safeChar = isPlainSafe(ctx, char) && indicator != C_MAPPING_VALUE &&
      indicator != C_COMMENT;
    var nonCommentHash = isNonSpace(peek(-1)) && indicator == C_COMMENT;
    var nonMappingColon = indicator == C_MAPPING_VALUE &&
      isPlainSafe(ctx, peek(1));
    var match = safeChar || nonCommentHash || nonMappingColon;

    if (match) next();
    return match;
  }

  // 131
  String ns_plain(int indent, int ctx) => context('plain scalar', () {
    switch (ctx) {
    case FLOW_OUT:
    case FLOW_IN:
      return ns_plainMultiLine(indent, ctx);
    case BLOCK_KEY:
    case FLOW_KEY:
      return ns_plainOneLine(ctx);
    default: throw 'invalid context "$ctx"';
    }
  });

  // 132
  void nb_ns_plainInLine(int ctx) {
    zeroOrMore(() => transaction(() {
      zeroOrMore(() => consume(isSpace));
      return ns_plainChar(ctx);
    }));
  }

  // 133
  String ns_plainOneLine(int ctx) => captureString(() {
    if (c_forbidden()) return false;
    if (!ns_plainFirst(ctx)) return false;
    nb_ns_plainInLine(ctx);
    return true;
  });

  // 134
  bool s_ns_plainNextLine(int indent, int ctx) => transaction(() {
    if (c_forbidden()) return false;
    if (!s_flowFolded(indent)) return false;
    if (!ns_plainChar(ctx)) return false;
    nb_ns_plainInLine(ctx);
    return true;
  });

  // 135
  String ns_plainMultiLine(int indent, int ctx) => captureString(() {
    if (!truth(ns_plainOneLine(ctx))) return false;
    zeroOrMore(() => s_ns_plainNextLine(indent, ctx));
    return true;
  });

  // 154
  _Node c_s_implicitYamlKey(int ctx) => transaction(() {
    // The indentation parameter is "null" since it's unused in this path
    var node = ns_flowYamlNode(null, ctx);
    if (!truth(node)) return null;
    zeroOrOne(s_separateInLine);
    return node;
  });

  // 155
  _Node c_s_implicitJsonKey(int ctx) => null; // TODO(nweiz): implement

  // 156
  _Node ns_flowYamlContent(int indent, int ctx) {
    var str = ns_plain(indent, ctx);
    if (!truth(str)) return null;
    return new _ScalarNode("?", content: str);
  }

  // 157
  // TODO(nweiz): implement
  _Node ns_flowJsonContent(int indent, int ctx) => null;

  // 158
  _Node ns_flowContent(int indent, int ctx) => or([
    () => ns_flowYamlContent(indent, ctx),
    () => ns_flowJsonContent(indent, ctx)
  ]);

  // 159
  _Node ns_flowYamlNode(int indent, int ctx) => or([
    c_ns_aliasNode,
    () => ns_flowYamlContent(indent, ctx),
    () {
      var props = c_ns_properties(indent, ctx);
      if (!truth(props)) return null;
      var node = or([
        () => transaction(() {
          if (!s_separate(indent, ctx)) return null;
          return ns_flowYamlContent(indent, ctx);
        }),
        e_scalar
      ]);
      return addProps(node, props);
    }
  ]);

  // 161
  _Node ns_flowNode(int indent, int ctx) => or([
    c_ns_aliasNode,
    () => ns_flowContent(indent, ctx),
    () => transaction(() {
      var props = c_ns_properties(indent, ctx);
      if (!truth(props)) return null;
      var node = or([
        () => transaction(() => s_separate(indent, ctx) ?
            ns_flowContent(indent, ctx) : null),
        e_scalar]);
      return addProps(node, props);
    })
  ]);

  // 170
  _Node c_l_literal(int indent) => null; // TODO(nweiz); implement

  // 174
  _Node c_l_folded(int indent) => null; // TODO(nweiz); implement

  // 183
  _SequenceNode l_blockSequence(int indent) => context('sequence', () {
    var additionalIndent = countIndentation() - indent;
    if (additionalIndent <= 0) return null;

    var content = oneOrMore(() => transaction(() {
      if (!s_indent(indent + additionalIndent)) return null;
      return c_l_blockSeqEntry(indent + additionalIndent);
    }));
    if (!truth(content)) return null;

    return new _SequenceNode("?", content);
  });

  // 184
  _Node c_l_blockSeqEntry(int indent) => transaction(() {
    if (!c_indicator(C_SEQUENCE_ENTRY)) return null;
    if (isNonSpace(peek())) return null;

    return s_l_blockIndented(indent, BLOCK_IN);
  });

  // 185
  _Node s_l_blockIndented(int indent, int ctx) {
    var additionalIndent = countIndentation();
    return or([
      () => transaction(() {
        if (!s_indent(additionalIndent)) return null;
        return or([
          () => ns_l_compactSequence(indent + 1 + additionalIndent),
          () => ns_l_compactMapping(indent + 1 + additionalIndent)]);
      }),
      () => s_l_blockNode(indent, ctx),
      () => s_l_comments() ? e_node() : null]);
  }

  // 186
  _Node ns_l_compactSequence(int indent) => context('sequence', () {
    var first = c_l_blockSeqEntry(indent);
    if (!truth(first)) return null;

    var content = zeroOrMore(() => transaction(() {
        if (!s_indent(indent)) return null;
        return c_l_blockSeqEntry(indent);
      }));
    content.insertRange(0, 1, first);

    return new _SequenceNode("?", content);
  });

  // 187
  _Node l_blockMapping(int indent) => context('mapping', () {
    var additionalIndent = countIndentation() - indent;
    if (additionalIndent <= 0) return null;

    var pairs = oneOrMore(() => transaction(() {
      if (!s_indent(indent + additionalIndent)) return null;
      return ns_l_blockMapEntry(indent + additionalIndent);
    }));
    if (!truth(pairs)) return null;

    return map(pairs);
  });

  // 188
  _Pair<_Node, _Node> ns_l_blockMapEntry(int indent) => or([
    () => c_l_blockMapExplicitEntry(indent),
    () => ns_l_blockMapImplicitEntry(indent)
  ]);

  // 189
  // TODO(nweiz): implement
  _Pair<_Node, _Node> c_l_blockMapExplicitEntry(int indent) => null;

  // 192
  _Pair<_Node, _Node> ns_l_blockMapImplicitEntry(int indent) => transaction(() {
    var key = or([ns_s_blockMapImplicitKey, e_node]);
    var value = c_l_blockMapImplicitValue(indent);
    return truth(value) ? new _Pair<_Node, _Node>(key, value) : null;
  });

  // 193
  _Node ns_s_blockMapImplicitKey() => context('mapping key', () => or([
    () => c_s_implicitJsonKey(BLOCK_KEY),
    () => c_s_implicitYamlKey(BLOCK_KEY)
  ]));

  // 194
  _Node c_l_blockMapImplicitValue(int indent) => context('mapping value', () =>
    transaction(() {
      if (!c_indicator(C_MAPPING_VALUE)) return null;
      return or([
        () => s_l_blockNode(indent, BLOCK_OUT),
        () => s_l_comments() ? e_node() : null
      ]);
    }));

  // 195
  _Node ns_l_compactMapping(int indent) => context('mapping', () {
    var first = ns_l_blockMapEntry(indent);
    if (!truth(first)) return null;

    var pairs = zeroOrMore(() => transaction(() {
        if (!s_indent(indent)) return null;
        return ns_l_blockMapEntry(indent);
      }));
    pairs.insertRange(0, 1, first);

    return map(pairs);
  });

  // 196
  _Node s_l_blockNode(int indent, int ctx) => or([
    () => s_l_blockInBlock(indent, ctx),
    () => s_l_flowInBlock(indent)
  ]);

  // 197
  _Node s_l_flowInBlock(int indent) => transaction(() {
    if (!s_separate(indent + 1, FLOW_OUT)) return null;
    var node = ns_flowNode(indent + 1, FLOW_OUT);
    if (!truth(node)) return null;
    if (!s_l_comments()) return null;
    return node;
  });

  // 198
  _Node s_l_blockInBlock(int indent, int ctx) => or([
    () => s_l_blockScalar(indent, ctx),
    () => s_l_blockCollection(indent, ctx)
  ]);

  // 199
  _Node s_l_blockScalar(int indent, int ctx) => transaction(() {
    if (!s_separate(indent + 1, ctx)) return null;
    var props = transaction(() {
      var props = c_ns_properties(indent + 1, ctx);
      if (!truth(props)) return null;
      if (!s_separate(indent + 1, ctx)) return null;
      return props;
    });
    if (!truth(props)) props = new _Pair<_Tag, String>(null, null);

    var node = or([() => c_l_literal(indent), () => c_l_folded(indent)]);
    if (!truth(node)) return null;
    return addProps(node, props);
  });

  // 200
  _Node s_l_blockCollection(int indent, int ctx) => transaction(() {
    var props = transaction(() {
      if (!s_separate(indent + 1, ctx)) return null;
      return c_ns_properties(indent + 1, ctx);
    });
    if (!truth(props)) props = new _Pair<_Tag, String>(null, null);

    if (!s_l_comments()) return null;
    return or([
      () => l_blockSequence(seqSpaces(indent, ctx)),
      () => l_blockMapping(indent)]);
  });

  // 201
  int seqSpaces(int indent, int ctx) => ctx == BLOCK_OUT ? indent - 1 : indent;

  // 202
  void l_documentPrefix() {
    zeroOrMore(l_comment);
  }

  // 203
  bool c_directivesEnd() => rawString("---");

  // 204
  bool c_documentEnd() => rawString("...");

  // 205
  bool l_documentSuffix() => transaction(() {
    if (!c_documentEnd()) return false;
    return s_l_comments();
  });

  // 206
  bool c_forbidden() {
    if (!inBareDocument || !atStartOfLine) return false;
    var forbidden = false;
    transaction(() {
      if (!truth(or([c_directivesEnd, c_documentEnd]))) return;
      var char = peek();
      forbidden = isBreak(char) || isSpace(char) || atEndOfFile;
      return;
    });
    return forbidden;
  }

  // 207
  _Node l_bareDocument() {
    try {
      inBareDocument = true;
      return s_l_blockNode(-1, BLOCK_IN);
    } finally {
      inBareDocument = false;
    }
  }

  // 208
  _Node l_explicitDocument() {
    if (!c_directivesEnd()) return null;
    var doc = l_bareDocument();
    if (truth(doc)) return doc;

    doc = e_node();
    s_l_comments();
    return doc;
  }

  // 209
  _Node l_directiveDocument() {
    if (!truth(oneOrMore(l_directive))) return null;
    var doc = l_explicitDocument();
    if (doc != null) return doc;
    parseFailed();
  }

  // 210
  _Node l_anyDocument() =>
    or([l_directiveDocument, l_explicitDocument, l_bareDocument]);

  // 211
  List<_Node> l_yamlStream() {
    var docs = [];
    zeroOrMore(l_documentPrefix);
    var first = zeroOrOne(l_anyDocument);
    if (!truth(first)) first = e_node();
    docs.add(first);

    zeroOrMore(() {
      var doc;
      if (truth(oneOrMore(l_documentSuffix))) {
        zeroOrMore(l_documentPrefix);
        doc = zeroOrOne(l_anyDocument);
      } else {
        zeroOrMore(l_documentPrefix);
        doc = zeroOrOne(l_explicitDocument);
      }
      if (truth(doc)) docs.add(doc);
      return doc;
    });

    if (!atEndOfFile) parseFailed();
    return docs;
  }
}

class SyntaxError extends YamlException {
  final int line;
  final int column;

  SyntaxError(this.line, this.column, String msg) : super(msg);

  String toString() => "Syntax error on line $line, column $column: $msg";
}

/** A pair of values. */
class _Pair<E, F> {
  E first;
  F last;

  _Pair(this.first, this.last);

  String toString() => '($first, $last)';
}
