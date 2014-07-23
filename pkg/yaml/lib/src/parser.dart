// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library yaml.parser;

import 'dart:collection';

import 'package:source_span/source_span.dart';
import 'package:string_scanner/string_scanner.dart';

import 'equality.dart';
import 'model.dart';
import 'utils.dart';

/// Translates a string of characters into a YAML serialization tree.
///
/// This parser is designed to closely follow the spec. All productions in the
/// spec are numbered, and the corresponding methods in the parser have the same
/// numbers. This is certainly not the most efficient way of parsing YAML, but
/// it is the easiest to write and read in the context of the spec.
///
/// Methods corresponding to productions are also named as in the spec,
/// translating the name of the method (although not the annotation characters)
/// into camel-case for dart style.. For example, the spec has a production
/// named `nb-ns-plain-in-line`, and the method implementing it is named
/// `nb_ns_plainInLine`. The exception to that rule is methods that just
/// recognize character classes; these are named `is*`.
class Parser {
  static const TAB = 0x9;
  static const LF = 0xA;
  static const CR = 0xD;
  static const SP = 0x20;
  static const TILDE = 0x7E;
  static const NEL = 0x85;
  static const PLUS = 0x2B;
  static const HYPHEN = 0x2D;
  static const QUESTION_MARK = 0x3F;
  static const COLON = 0x3A;
  static const COMMA = 0x2C;
  static const LEFT_BRACKET = 0x5B;
  static const RIGHT_BRACKET = 0x5D;
  static const LEFT_BRACE = 0x7B;
  static const RIGHT_BRACE = 0x7D;
  static const HASH = 0x23;
  static const AMPERSAND = 0x26;
  static const ASTERISK = 0x2A;
  static const EXCLAMATION = 0x21;
  static const VERTICAL_BAR = 0x7C;
  static const GREATER_THAN = 0x3E;
  static const SINGLE_QUOTE = 0x27;
  static const DOUBLE_QUOTE = 0x22;
  static const PERCENT = 0x25;
  static const AT = 0x40;
  static const GRAVE_ACCENT = 0x60;

  static const NULL = 0x0;
  static const BELL = 0x7;
  static const BACKSPACE = 0x8;
  static const VERTICAL_TAB = 0xB;
  static const FORM_FEED = 0xC;
  static const ESCAPE = 0x1B;
  static const SLASH = 0x2F;
  static const BACKSLASH = 0x5C;
  static const UNDERSCORE = 0x5F;
  static const NBSP = 0xA0;
  static const LINE_SEPARATOR = 0x2028;
  static const PARAGRAPH_SEPARATOR = 0x2029;

  static const NUMBER_0 = 0x30;
  static const NUMBER_9 = 0x39;

  static const LETTER_A = 0x61;
  static const LETTER_B = 0x62;
  static const LETTER_E = 0x65;
  static const LETTER_F = 0x66;
  static const LETTER_N = 0x6E;
  static const LETTER_R = 0x72;
  static const LETTER_T = 0x74;
  static const LETTER_U = 0x75;
  static const LETTER_V = 0x76;
  static const LETTER_X = 0x78;

  static const LETTER_CAP_A = 0x41;
  static const LETTER_CAP_F = 0x46;
  static const LETTER_CAP_L = 0x4C;
  static const LETTER_CAP_N = 0x4E;
  static const LETTER_CAP_P = 0x50;
  static const LETTER_CAP_U = 0x55;
  static const LETTER_CAP_X = 0x58;

  static const C_SEQUENCE_ENTRY = 4;
  static const C_MAPPING_KEY = 5;
  static const C_MAPPING_VALUE = 6;
  static const C_COLLECT_ENTRY = 7;
  static const C_SEQUENCE_START = 8;
  static const C_SEQUENCE_END = 9;
  static const C_MAPPING_START = 10;
  static const C_MAPPING_END = 11;
  static const C_COMMENT = 12;
  static const C_ANCHOR = 13;
  static const C_ALIAS = 14;
  static const C_TAG = 15;
  static const C_LITERAL = 16;
  static const C_FOLDED = 17;
  static const C_SINGLE_QUOTE = 18;
  static const C_DOUBLE_QUOTE = 19;
  static const C_DIRECTIVE = 20;
  static const C_RESERVED = 21;

  static const BLOCK_OUT = 0;
  static const BLOCK_IN = 1;
  static const FLOW_OUT = 2;
  static const FLOW_IN = 3;
  static const BLOCK_KEY = 4;
  static const FLOW_KEY = 5;

  static const CHOMPING_STRIP = 0;
  static const CHOMPING_KEEP = 1;
  static const CHOMPING_CLIP = 2;

  /// The scanner that's used to scan through the document.
  final SpanScanner _scanner;

  /// Whether we're parsing a bare document (that is, one that doesn't begin
  /// with `---`). Bare documents don't allow `%` immediately following
  /// newlines.
  bool _inBareDocument = false;

  /// The state of the scanner when it was the farthest in the document it's
  /// been.
  LineScannerState _farthestState;

  /// The name of the context of the farthest position that has been parsed
  /// successfully before backtracking. Used for error reporting.
  String _farthestContext = "document";

  /// A stack of the names of parse contexts. Used for error reporting.
  final _contextStack = <String>["document"];

  /// Annotations attached to ranges of the source string that add extra
  /// information to any errors that occur in the annotated range.
  final _errorAnnotations = new _RangeMap<String>();

  /// The buffer containing the string currently being captured.
  StringBuffer _capturedString;

  /// The beginning of the current section of the captured string.
  int _captureStart;

  /// Whether the current string capture is being overridden.
  bool _capturingAs = false;

  Parser(String yaml, sourceUrl)
      : _scanner = new SpanScanner(yaml, sourceUrl: sourceUrl) {
    _farthestState = _scanner.state;
  }

  /// Returns the character at the current position, then moves that position
  /// forward one character.
  int next() => _scanner.readChar();

  /// Returns the code unit at the current position, or the character [i]
  /// characters after the current position.
  int peek([int i = 0]) => _scanner.peekChar(i);

  /// The truthiness operator. Returns `false` if [obj] is `null` or `false`,
  /// `true` otherwise.
  bool truth(obj) => obj != null && obj != false;

  /// Consumes the current character if it matches [matcher]. Returns the result
  /// of [matcher].
  bool consume(bool matcher(int)) {
    if (matcher(peek())) {
      next();
      return true;
    }
    return false;
  }

  /// Consumes the current character if it equals [char].
  bool consumeChar(int char) => consume((c) => c == char);

  /// Calls [consumer] until it returns a falsey value. Returns a list of all
  /// truthy return values of [consumer], or null if it didn't consume anything.
  ///
  /// Conceptually, repeats a production one or more times.
  List oneOrMore(consumer()) {
    var first = consumer();
    if (!truth(first)) return null;
    var out = [first];
    while (true) {
      var el = consumer();
      if (!truth(el)) return out;
      out.add(el);
    }
    return null; // Unreachable.
  }

  /// Calls [consumer] until it returns a falsey value. Returns a list of all
  /// truthy return values of [consumer], or the empty list if it didn't consume
  /// anything.
  ///
  /// Conceptually, repeats a production any number of times.
  List zeroOrMore(consumer()) {
    var out = [];
    var oldPos = _scanner.position;
    while (true) {
      var el = consumer();
      if (!truth(el) || oldPos == _scanner.position) return out;
      oldPos = _scanner.position;
      out.add(el);
    }
    return null; // Unreachable.
  }

  /// Just calls [consumer] and returns its result. Used to make it explicit
  /// that a production is intended to be optional.
  zeroOrOne(consumer()) => consumer();

  /// Calls each function in [consumers] until one returns a truthy value, then
  /// returns that.
  or(List<Function> consumers) {
    for (var c in consumers) {
      var res = c();
      if (truth(res)) return res;
    }
    return null;
  }

  /// Calls [consumer] and returns its result, but rolls back the parser state
  /// if [consumer] returns a falsey value.
  transaction(consumer()) {
    var oldState = _scanner.state;
    var oldCaptureStart = _captureStart;
    String capturedSoFar = _capturedString == null ? null :
      _capturedString.toString();
    var res = consumer();
    _refreshFarthestState();
    if (truth(res)) return res;

    _scanner.state = oldState;
    _captureStart = oldCaptureStart;
    _capturedString = capturedSoFar == null ? null :
      new StringBuffer(capturedSoFar);
    return res;
  }

  /// Consumes [n] characters matching [matcher], or none if there isn't a
  /// complete match. The first argument to [matcher] is the character code, the
  /// second is the index (from 0 to [n] - 1).
  ///
  /// Returns whether or not the characters were consumed.
  bool nAtOnce(int n, bool matcher(int c, int i)) => transaction(() {
    for (int i = 0; i < n; i++) {
      if (!consume((c) => matcher(c, i))) return false;
    }
    return true;
  });

  /// Consumes the exact characters in [str], or nothing.
  ///
  /// Returns whether or not the string was consumed.
  bool rawString(String str) =>
    nAtOnce(str.length, (c, i) => str.codeUnitAt(i) == c);

  /// Consumes and returns a string of characters matching [matcher], or null if
  /// there are no such characters.
  String stringOf(bool matcher(int)) =>
    captureString(() => oneOrMore(() => consume(matcher)));

  /// Calls [consumer] and returns the string that was consumed while doing so,
  /// or null if [consumer] returned a falsey value. Automatically wraps
  /// [consumer] in `transaction`.
  String captureString(consumer()) {
    // captureString calls may not be nested
    assert(_capturedString == null);

    _captureStart = _scanner.position;
    _capturedString = new StringBuffer();
    var res = transaction(consumer);
    if (!truth(res)) {
      _captureStart = null;
      _capturedString = null;
      return null;
    }

    flushCapture();
    var result = _capturedString.toString();
    _captureStart = null;
    _capturedString = null;
    return result;
  }

  captureAs(String replacement, consumer()) =>
      captureAndTransform(consumer, (_) => replacement);

  captureAndTransform(consumer(), String transformation(String captured)) {
    if (_capturedString == null) return consumer();
    if (_capturingAs) return consumer();

    flushCapture();
    _capturingAs = true;
    var res = consumer();
    _capturingAs = false;
    if (!truth(res)) return res;

    _capturedString.write(transformation(
        _scanner.string.substring(_captureStart, _scanner.position)));
    _captureStart = _scanner.position;
    return res;
  }

  void flushCapture() {
    _capturedString.write(_scanner.string.substring(
        _captureStart, _scanner.position));
    _captureStart = _scanner.position;
  }

  /// Adds a tag and an anchor to [node], if they're defined.
  Node addProps(Node node, Pair<Tag, String> props) {
    if (props == null || node == null) return node;
    if (truth(props.first)) node.tag = props.first;
    if (truth(props.last)) node.anchor = props.last;
    return node;
  }

  /// Creates a MappingNode from [pairs].
  MappingNode map(List<Pair<Node, Node>> pairs, SourceSpan span) {
    var content = new Map<Node, Node>();
    pairs.forEach((pair) => content[pair.first] = pair.last);
    return new MappingNode("?", content, span);
  }

  /// Runs [fn] in a context named [name]. Used for error reporting.
  context(String name, fn()) {
    try {
      _contextStack.add(name);
      return fn();
    } finally {
      var popped = _contextStack.removeLast();
      assert(popped == name);
    }
  }

  /// Adds [message] as extra information to any errors that occur between the
  /// current position and the position of the cursor after running [fn]. The
  /// cursor is reset after [fn] is run.
  annotateError(String message, fn()) {
    var start = _scanner.position;
    var end;
    transaction(() {
      fn();
      end = _scanner.position;
      return false;
    });
    _errorAnnotations[new _Range(start, end)] = message;
  }

  /// Throws an error with additional context information.
  void error(String message) =>
      _scanner.error("$message (in $_farthestContext).");

  /// If [result] is falsey, throws an error saying that [expected] was
  /// expected.
  expect(result, String expected) {
    if (truth(result)) return result;
    error("Expected $expected");
  }

  /// Throws an error saying that the parse failed.
  ///
  /// Uses [_farthestState] and [_farthestContext] to provide additional
  /// information.
  parseFailed() {
    var message = "Invalid YAML in $_farthestContext";
    _refreshFarthestState();
    _scanner.state = _farthestState;

    var extraError = _errorAnnotations[_scanner.position];
    if (extraError != null) message = "$message ($extraError)";
    _scanner.error("$message.");
  }

  /// Update [_farthestState] if the scanner is farther than it's been before.
  void _refreshFarthestState() {
    if (_scanner.position <= _farthestState.position) return;
    _farthestState = _scanner.state;
  }

  /// Returns the number of spaces after the current position.
  int countIndentation() {
    var i = 0;
    while (peek(i) == SP) i++;
    return i;
  }

  /// Returns the indentation for a block scalar.
  int blockScalarAdditionalIndentation(_BlockHeader header, int indent) {
    if (!header.autoDetectIndent) return header.additionalIndent;

    var maxSpaces = 0;
    var spaces = 0;
    transaction(() {
      do {
        spaces = captureString(() => zeroOrMore(() => consumeChar(SP))).length;
        if (spaces > maxSpaces) maxSpaces = spaces;
      } while (b_break());
      return false;
    });

    // If the next non-empty line isn't indented further than the start of the
    // block scalar, that means the scalar is going to be empty. Returning any
    // value > 0 will cause the parser not to consume any text.
    if (spaces <= indent) return 1;

    // It's an error for a leading empty line to be indented more than the first
    // non-empty line.
    if (maxSpaces > spaces) {
      _scanner.error("Leading empty lines may not be indented more than the "
          "first non-empty line.");
    }

    return spaces - indent;
  }

  /// Returns whether the current position is at the beginning of a line.
  bool get atStartOfLine => _scanner.column == 0;

  /// Given an indicator character, returns the type of that indicator (or null
  /// if the indicator isn't found.
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
    if (char == null) return false;
    return char == TAB ||
      char == LF ||
      char == CR ||
      (char >= SP && char <= TILDE) ||
      char == NEL ||
      (char >= 0xA0 && char <= 0xD7FF) ||
      (char >= 0xE000 && char <= 0xFFFD) ||
      (char >= 0x10000 && char <= 0x10FFFF);
  }

  // 2
  bool isJson(int char) => char != null &&
      (char == TAB || (char >= SP && char <= 0x10FFFF));

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

  // 28
  bool b_break() {
    if (consumeChar(CR)) {
      zeroOrOne(() => consumeChar(LF));
      return true;
    }
    return consumeChar(LF);
  }

  // 29
  bool b_asLineFeed() => captureAs("\n", () => b_break());

  // 30
  bool b_nonContent() => captureAs("", () => b_break());

  // 33
  bool isSpace(int char) => char == SP || char == TAB;

  // 34
  bool isNonSpace(int char) => isNonBreak(char) && !isSpace(char);

  // 35
  bool isDecDigit(int char) => char != null && char >= NUMBER_0 &&
      char <= NUMBER_9;

  // 36
  bool isHexDigit(int char) {
    if (char == null) return false;
    return isDecDigit(char) ||
      (char >= LETTER_A && char <= LETTER_F) ||
      (char >= LETTER_CAP_A && char <= LETTER_CAP_F);
  }

  // 41
  bool c_escape() => captureAs("", () => consumeChar(BACKSLASH));

  // 42
  bool ns_escNull() => captureAs("\x00", () => consumeChar(NUMBER_0));

  // 43
  bool ns_escBell() => captureAs("\x07", () => consumeChar(LETTER_A));

  // 44
  bool ns_escBackspace() => captureAs("\b", () => consumeChar(LETTER_B));

  // 45
  bool ns_escHorizontalTab() => captureAs("\t", () {
    return consume((c) => c == LETTER_T || c == TAB);
  });

  // 46
  bool ns_escLineFeed() => captureAs("\n", () => consumeChar(LETTER_N));

  // 47
  bool ns_escVerticalTab() => captureAs("\v", () => consumeChar(LETTER_V));

  // 48
  bool ns_escFormFeed() => captureAs("\f", () => consumeChar(LETTER_F));

  // 49
  bool ns_escCarriageReturn() => captureAs("\r", () => consumeChar(LETTER_R));

  // 50
  bool ns_escEscape() => captureAs("\x1B", () => consumeChar(LETTER_E));

  // 51
  bool ns_escSpace() => consumeChar(SP);

  // 52
  bool ns_escDoubleQuote() => consumeChar(DOUBLE_QUOTE);

  // 53
  bool ns_escSlash() => consumeChar(SLASH);

  // 54
  bool ns_escBackslash() => consumeChar(BACKSLASH);

  // 55
  bool ns_escNextLine() => captureAs("\x85", () => consumeChar(LETTER_CAP_N));

  // 56
  bool ns_escNonBreakingSpace() =>
    captureAs("\xA0", () => consumeChar(UNDERSCORE));

  // 57
  bool ns_escLineSeparator() =>
    captureAs("\u2028", () => consumeChar(LETTER_CAP_L));

  // 58
  bool ns_escParagraphSeparator() =>
    captureAs("\u2029", () => consumeChar(LETTER_CAP_P));

  // 59
  bool ns_esc8Bit() => ns_escNBit(LETTER_X, 2);

  // 60
  bool ns_esc16Bit() => ns_escNBit(LETTER_U, 4);

  // 61
  bool ns_esc32Bit() => ns_escNBit(LETTER_CAP_U, 8);

  // Helper method for 59 - 61
  bool ns_escNBit(int char, int digits) {
    if (!captureAs('', () => consumeChar(char))) return false;
    var captured = captureAndTransform(
        () => nAtOnce(digits, (c, _) => isHexDigit(c)),
        (hex) => new String.fromCharCodes([int.parse("0x$hex")]));
    return expect(captured, "$digits hexidecimal digits");
  }

  // 62
  bool c_ns_escChar() => context('escape sequence', () => transaction(() {
      if (!truth(c_escape())) return false;
      return truth(or([
        ns_escNull, ns_escBell, ns_escBackspace, ns_escHorizontalTab,
        ns_escLineFeed, ns_escVerticalTab, ns_escFormFeed, ns_escCarriageReturn,
        ns_escEscape, ns_escSpace, ns_escDoubleQuote, ns_escSlash,
        ns_escBackslash, ns_escNextLine, ns_escNonBreakingSpace,
        ns_escLineSeparator, ns_escParagraphSeparator, ns_esc8Bit, ns_esc16Bit,
        ns_esc32Bit
      ]));
    }));

  // 63
  bool s_indent(int indent) {
    var result = nAtOnce(indent, (c, i) => c == SP);
    if (peek() == TAB) {
      annotateError("tab characters are not allowed as indentation in YAML",
          () => zeroOrMore(() => consume(isSpace)));
    }
    return result;
  }

  // 64
  bool s_indentLessThan(int indent) {
    for (int i = 0; i < indent - 1; i++) {
      if (!consumeChar(SP)) {
        if (peek() == TAB) {
          annotateError("tab characters are not allowed as indentation in YAML",
              () {
            for (; i < indent - 1; i++) {
              if (!consume(isSpace)) break;
            }
          });
        }
        break;
      }
    }
    return true;
  }

  // 65
  bool s_indentLessThanOrEqualTo(int indent) => s_indentLessThan(indent + 1);

  // 66
  bool s_separateInLine() => transaction(() {
    return captureAs('', () =>
        truth(oneOrMore(() => consume(isSpace))) || atStartOfLine);
  });

  // 67
  bool s_linePrefix(int indent, int ctx) => captureAs("", () {
    switch (ctx) {
    case BLOCK_OUT:
    case BLOCK_IN:
      return s_blockLinePrefix(indent);
    case FLOW_OUT:
    case FLOW_IN:
      return s_flowLinePrefix(indent);
    }
  });

  // 68
  bool s_blockLinePrefix(int indent) => s_indent(indent);

  // 69
  bool s_flowLinePrefix(int indent) => captureAs('', () {
    if (!truth(s_indent(indent))) return false;
    zeroOrOne(s_separateInLine);
    return true;
  });

  // 70
  bool l_empty(int indent, int ctx) => transaction(() {
    var start = or([
      () => s_linePrefix(indent, ctx),
      () => s_indentLessThan(indent)
    ]);
    if (!truth(start)) return false;
    return b_asLineFeed();
  });

  // 71
  bool b_asSpace() => captureAs(" ", () => consume(isBreak));

  // 72
  bool b_l_trimmed(int indent, int ctx) => transaction(() {
    if (!truth(b_nonContent())) return false;
    return truth(oneOrMore(() => captureAs("\n", () => l_empty(indent, ctx))));
  });

  // 73
  bool b_l_folded(int indent, int ctx) =>
    or([() => b_l_trimmed(indent, ctx), b_asSpace]);

  // 74
  bool s_flowFolded(int indent) => transaction(() {
    zeroOrOne(s_separateInLine);
    if (!truth(b_l_folded(indent, FLOW_IN))) return false;
    return s_flowLinePrefix(indent);
  });

  // 75
  bool c_nb_commentText() {
    if (!truth(c_indicator(C_COMMENT))) return false;
    zeroOrMore(() => consume(isNonBreak));
    return true;
  }

  // 76
  bool b_comment() => _scanner.isDone || b_nonContent();

  // 77
  bool s_b_comment() {
    if (truth(s_separateInLine())) {
      zeroOrOne(c_nb_commentText);
    }
    return b_comment();
  }

  // 78
  bool l_comment() => transaction(() {
    if (!truth(s_separateInLine())) return false;
    zeroOrOne(c_nb_commentText);
    return b_comment();
  });

  // 79
  bool s_l_comments() {
    if (!truth(s_b_comment()) && !atStartOfLine) return false;
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
    default: throw 'Invalid context "$ctx".';
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
  Pair<Tag, String> c_ns_properties(int indent, int ctx) {
    var tag, anchor;
    tag = c_ns_tagProperty();
    if (truth(tag)) {
      anchor = transaction(() {
        if (!truth(s_separate(indent, ctx))) return null;
        return c_ns_anchorProperty();
      });
      return new Pair<Tag, String>(tag, anchor);
    }

    anchor = c_ns_anchorProperty();
    if (truth(anchor)) {
      tag = transaction(() {
        if (!truth(s_separate(indent, ctx))) return null;
        return c_ns_tagProperty();
      });
      return new Pair<Tag, String>(tag, anchor);
    }

    return null;
  }

  // 97
  Tag c_ns_tagProperty() => null; // TODO(nweiz): implement

  // 101
  String c_ns_anchorProperty() => null; // TODO(nweiz): implement

  // 102
  bool isAnchorChar(int char) => isNonSpace(char) && !isFlowIndicator(char);

  // 103
  String ns_anchorName() =>
    captureString(() => oneOrMore(() => consume(isAnchorChar)));

  // 104
  Node c_ns_aliasNode() {
    var start = _scanner.state;
    if (!truth(c_indicator(C_ALIAS))) return null;
    var name = expect(ns_anchorName(), 'anchor name');
    return new AliasNode(name, _scanner.spanFrom(start));
  }

  // 105
  ScalarNode e_scalar() => new ScalarNode("?", _scanner.emptySpan, content: "");

  // 106
  ScalarNode e_node() => e_scalar();

  // 107
  bool nb_doubleChar() => or([
    c_ns_escChar,
    () => consume((c) => isJson(c) && c != BACKSLASH && c != DOUBLE_QUOTE)
  ]);

  // 108
  bool ns_doubleChar() => !isSpace(peek()) && truth(nb_doubleChar());

  // 109
  Node c_doubleQuoted(int indent, int ctx) => context('string', () {
    return transaction(() {
      var start = _scanner.state;
      if (!truth(c_indicator(C_DOUBLE_QUOTE))) return null;
      var contents = nb_doubleText(indent, ctx);
      if (!truth(c_indicator(C_DOUBLE_QUOTE))) return null;
      return new ScalarNode("!", _scanner.spanFrom(start), content: contents);
    });
  });

  // 110
  String nb_doubleText(int indent, int ctx) => captureString(() {
    switch (ctx) {
    case FLOW_OUT:
    case FLOW_IN:
      nb_doubleMultiLine(indent);
      break;
    case BLOCK_KEY:
    case FLOW_KEY:
      nb_doubleOneLine();
      break;
    }
    return true;
  });

  // 111
  void nb_doubleOneLine() {
    zeroOrMore(nb_doubleChar);
  }

  // 112
  bool s_doubleEscaped(int indent) => transaction(() {
    zeroOrMore(() => consume(isSpace));
    if (!captureAs("", () => consumeChar(BACKSLASH))) return false;
    if (!truth(b_nonContent())) return false;
    zeroOrMore(() => captureAs("\n", () => l_empty(indent, FLOW_IN)));
    return s_flowLinePrefix(indent);
  });

  // 113
  bool s_doubleBreak(int indent) => or([
    () => s_doubleEscaped(indent),
    () => s_flowFolded(indent)
  ]);

  // 114
  void nb_ns_doubleInLine() {
    zeroOrMore(() => transaction(() {
        zeroOrMore(() => consume(isSpace));
        return ns_doubleChar();
      }));
  }

  // 115
  bool s_doubleNextLine(int indent) {
    if (!truth(s_doubleBreak(indent))) return false;
    zeroOrOne(() {
      if (!truth(ns_doubleChar())) return;
      nb_ns_doubleInLine();
      or([
        () => s_doubleNextLine(indent),
        () => zeroOrMore(() => consume(isSpace))
      ]);
    });
    return true;
  }

  // 116
  void nb_doubleMultiLine(int indent) {
    nb_ns_doubleInLine();
    or([
      () => s_doubleNextLine(indent),
      () => zeroOrMore(() => consume(isSpace))
    ]);
  }

  // 117
  bool c_quotedQuote() => captureAs("'", () => rawString("''"));

  // 118
  bool nb_singleChar() => or([
    c_quotedQuote,
    () => consume((c) => isJson(c) && c != SINGLE_QUOTE)
  ]);

  // 119
  bool ns_singleChar() => !isSpace(peek()) && truth(nb_singleChar());

  // 120
  Node c_singleQuoted(int indent, int ctx) => context('string', () {
    return transaction(() {
      var start = _scanner.state;
      if (!truth(c_indicator(C_SINGLE_QUOTE))) return null;
      var contents = nb_singleText(indent, ctx);
      if (!truth(c_indicator(C_SINGLE_QUOTE))) return null;
      return new ScalarNode("!", _scanner.spanFrom(start), content: contents);
    });
  });

  // 121
  String nb_singleText(int indent, int ctx) => captureString(() {
    switch (ctx) {
    case FLOW_OUT:
    case FLOW_IN:
      nb_singleMultiLine(indent);
      break;
    case BLOCK_KEY:
    case FLOW_KEY:
      nb_singleOneLine(indent);
      break;
    }
    return true;
  });

  // 122
  void nb_singleOneLine(int indent) {
    zeroOrMore(nb_singleChar);
  }

  // 123
  void nb_ns_singleInLine() {
    zeroOrMore(() => transaction(() {
      zeroOrMore(() => consume(isSpace));
      return ns_singleChar();
    }));
  }

  // 124
  bool s_singleNextLine(int indent) {
    if (!truth(s_flowFolded(indent))) return false;
    zeroOrOne(() {
      if (!truth(ns_singleChar())) return;
      nb_ns_singleInLine();
      or([
        () => s_singleNextLine(indent),
        () => zeroOrMore(() => consume(isSpace))
      ]);
    });
    return true;
  }

  // 125
  void nb_singleMultiLine(int indent) {
    nb_ns_singleInLine();
    or([
      () => s_singleNextLine(indent),
      () => zeroOrMore(() => consume(isSpace))
    ]);
  }

  // 126
  bool ns_plainFirst(int ctx) {
    var char = peek();
    var indicator = indicatorType(char);
    if (indicator == C_RESERVED) {
      error("Reserved indicators can't start a plain scalar");
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
    default: throw 'Invalid context "$ctx".';
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
    return captureString(() {
      switch (ctx) {
      case FLOW_OUT:
      case FLOW_IN:
        return ns_plainMultiLine(indent, ctx);
      case BLOCK_KEY:
      case FLOW_KEY:
        return ns_plainOneLine(ctx);
      default: throw 'Invalid context "$ctx".';
      }
    });
  });

  // 132
  void nb_ns_plainInLine(int ctx) {
    zeroOrMore(() => transaction(() {
      zeroOrMore(() => consume(isSpace));
      return ns_plainChar(ctx);
    }));
  }

  // 133
  bool ns_plainOneLine(int ctx) {
    if (truth(c_forbidden())) return false;
    if (!truth(ns_plainFirst(ctx))) return false;
    nb_ns_plainInLine(ctx);
    return true;
  }

  // 134
  bool s_ns_plainNextLine(int indent, int ctx) => transaction(() {
    if (!truth(s_flowFolded(indent))) return false;
    if (truth(c_forbidden())) return false;
    if (!truth(ns_plainChar(ctx))) return false;
    nb_ns_plainInLine(ctx);
    return true;
  });

  // 135
  bool ns_plainMultiLine(int indent, int ctx) {
    if (!truth(ns_plainOneLine(ctx))) return false;
    zeroOrMore(() => s_ns_plainNextLine(indent, ctx));
    return true;
  }

  // 136
  int inFlow(int ctx) {
    switch (ctx) {
      case FLOW_OUT:
      case FLOW_IN:
        return FLOW_IN;
      case BLOCK_KEY:
      case FLOW_KEY:
        return FLOW_KEY;
    }
    throw "unreachable";
  }

  // 137
  SequenceNode c_flowSequence(int indent, int ctx) => transaction(() {
    var start = _scanner.state;
    if (!truth(c_indicator(C_SEQUENCE_START))) return null;
    zeroOrOne(() => s_separate(indent, ctx));
    var content = zeroOrOne(() => ns_s_flowSeqEntries(indent, inFlow(ctx)));
    if (!truth(c_indicator(C_SEQUENCE_END))) return null;
    return new SequenceNode("?", new List<Node>.from(content),
        _scanner.spanFrom(start));
  });

  // 138
  Iterable<Node> ns_s_flowSeqEntries(int indent, int ctx) {
    var first = ns_flowSeqEntry(indent, ctx);
    if (!truth(first)) return new Queue<Node>();
    zeroOrOne(() => s_separate(indent, ctx));

    var rest;
    if (truth(c_indicator(C_COLLECT_ENTRY))) {
      zeroOrOne(() => s_separate(indent, ctx));
      rest = zeroOrOne(() => ns_s_flowSeqEntries(indent, ctx));
    }

    if (rest == null) rest = new Queue<Node>();
    rest.addFirst(first);

    return rest;
  }

  // 139
  Node ns_flowSeqEntry(int indent, int ctx) => or([
    () => ns_flowPair(indent, ctx),
    () => ns_flowNode(indent, ctx)
  ]);

  // 140
  Node c_flowMapping(int indent, int ctx) {
    var start = _scanner.state;
    if (!truth(c_indicator(C_MAPPING_START))) return null;
    zeroOrOne(() => s_separate(indent, ctx));
    var content = zeroOrOne(() => ns_s_flowMapEntries(indent, inFlow(ctx)));
    if (!truth(c_indicator(C_MAPPING_END))) return null;
    return new MappingNode("?", content, _scanner.spanFrom(start));
  }

  // 141
  Map ns_s_flowMapEntries(int indent, int ctx) {
    var first = ns_flowMapEntry(indent, ctx);
    if (!truth(first)) return deepEqualsMap();
    zeroOrOne(() => s_separate(indent, ctx));

    var rest;
    if (truth(c_indicator(C_COLLECT_ENTRY))) {
      zeroOrOne(() => s_separate(indent, ctx));
      rest = ns_s_flowMapEntries(indent, ctx);
    }

    if (rest == null) rest = deepEqualsMap();

    // TODO(nweiz): Duplicate keys should be an error. This includes keys with
    // different representations but the same value (e.g. 10 vs 0xa). To make
    // this user-friendly we'll probably also want to associate nodes with a
    // source range.
    if (!rest.containsKey(first.first)) rest[first.first] = first.last;

    return rest;
  }

  // 142
  Pair<Node, Node> ns_flowMapEntry(int indent, int ctx) => or([
    () => transaction(() {
      if (!truth(c_indicator(C_MAPPING_KEY))) return false;
      if (!truth(s_separate(indent, ctx))) return false;
      return ns_flowMapExplicitEntry(indent, ctx);
    }),
    () => ns_flowMapImplicitEntry(indent, ctx)
  ]);

  // 143
  Pair<Node, Node> ns_flowMapExplicitEntry(int indent, int ctx) => or([
    () => ns_flowMapImplicitEntry(indent, ctx),
    () => new Pair<Node, Node>(e_node(), e_node())
  ]);

  // 144
  Pair<Node, Node> ns_flowMapImplicitEntry(int indent, int ctx) => or([
    () => ns_flowMapYamlKeyEntry(indent, ctx),
    () => c_ns_flowMapEmptyKeyEntry(indent, ctx),
    () => c_ns_flowMapJsonKeyEntry(indent, ctx)
  ]);

  // 145
  Pair<Node, Node> ns_flowMapYamlKeyEntry(int indent, int ctx) {
    var key = ns_flowYamlNode(indent, ctx);
    if (!truth(key)) return null;
    var value = or([
      () => transaction(() {
        zeroOrOne(() => s_separate(indent, ctx));
        return c_ns_flowMapSeparateValue(indent, ctx);
      }),
      e_node
    ]);
    return new Pair<Node, Node>(key, value);
  }

  // 146
  Pair<Node, Node> c_ns_flowMapEmptyKeyEntry(int indent, int ctx) {
    var value = c_ns_flowMapSeparateValue(indent, ctx);
    if (!truth(value)) return null;
    return new Pair<Node, Node>(e_node(), value);
  }

  // 147
  Node c_ns_flowMapSeparateValue(int indent, int ctx) => transaction(() {
    if (!truth(c_indicator(C_MAPPING_VALUE))) return null;
    if (isPlainSafe(ctx, peek())) return null;

    return or([
      () => transaction(() {
        if (!s_separate(indent, ctx)) return null;
        return ns_flowNode(indent, ctx);
      }),
      e_node
    ]);
  });

  // 148
  Pair<Node, Node> c_ns_flowMapJsonKeyEntry(int indent, int ctx) {
    var key = c_flowJsonNode(indent, ctx);
    if (!truth(key)) return null;
    var value = or([
      () => transaction(() {
        zeroOrOne(() => s_separate(indent, ctx));
        return c_ns_flowMapAdjacentValue(indent, ctx);
      }),
      e_node
    ]);
    return new Pair<Node, Node>(key, value);
  }

  // 149
  Node c_ns_flowMapAdjacentValue(int indent, int ctx) {
    if (!truth(c_indicator(C_MAPPING_VALUE))) return null;
    return or([
      () => transaction(() {
        zeroOrOne(() => s_separate(indent, ctx));
        return ns_flowNode(indent, ctx);
      }),
      e_node
    ]);
  }

  // 150
  Node ns_flowPair(int indent, int ctx) {
    var start = _scanner.state;
    var pair = or([
      () => transaction(() {
        if (!truth(c_indicator(C_MAPPING_KEY))) return null;
        if (!truth(s_separate(indent, ctx))) return null;
        return ns_flowMapExplicitEntry(indent, ctx);
      }),
      () => ns_flowPairEntry(indent, ctx)
    ]);
    if (!truth(pair)) return null;

    return map([pair], _scanner.spanFrom(start));
  }

  // 151
  Pair<Node, Node> ns_flowPairEntry(int indent, int ctx) => or([
    () => ns_flowPairYamlKeyEntry(indent, ctx),
    () => c_ns_flowMapEmptyKeyEntry(indent, ctx),
    () => c_ns_flowPairJsonKeyEntry(indent, ctx)
  ]);

  // 152
  Pair<Node, Node> ns_flowPairYamlKeyEntry(int indent, int ctx) =>
    transaction(() {
      var key = ns_s_implicitYamlKey(FLOW_KEY);
      if (!truth(key)) return null;
      var value = c_ns_flowMapSeparateValue(indent, ctx);
      if (!truth(value)) return null;
      return new Pair<Node, Node>(key, value);
    });

  // 153
  Pair<Node, Node> c_ns_flowPairJsonKeyEntry(int indent, int ctx) =>
    transaction(() {
      var key = c_s_implicitJsonKey(FLOW_KEY);
      if (!truth(key)) return null;
      var value = c_ns_flowMapAdjacentValue(indent, ctx);
      if (!truth(value)) return null;
      return new Pair<Node, Node>(key, value);
    });

  // 154
  Node ns_s_implicitYamlKey(int ctx) => transaction(() {
    // TODO(nweiz): this is supposed to be limited to 1024 characters.

    // The indentation parameter is "null" since it's unused in this path
    var node = ns_flowYamlNode(null, ctx);
    if (!truth(node)) return null;
    zeroOrOne(s_separateInLine);
    return node;
  });

  // 155
  Node c_s_implicitJsonKey(int ctx) => transaction(() {
    // TODO(nweiz): this is supposed to be limited to 1024 characters.

    // The indentation parameter is "null" since it's unused in this path
    var node = c_flowJsonNode(null, ctx);
    if (!truth(node)) return null;
    zeroOrOne(s_separateInLine);
    return node;
  });

  // 156
  Node ns_flowYamlContent(int indent, int ctx) {
    var start = _scanner.state;
    var str = ns_plain(indent, ctx);
    if (!truth(str)) return null;
    return new ScalarNode("?", _scanner.spanFrom(start), content: str);
  }

  // 157
  Node c_flowJsonContent(int indent, int ctx) => or([
    () => c_flowSequence(indent, ctx),
    () => c_flowMapping(indent, ctx),
    () => c_singleQuoted(indent, ctx),
    () => c_doubleQuoted(indent, ctx)
  ]);

  // 158
  Node ns_flowContent(int indent, int ctx) => or([
    () => ns_flowYamlContent(indent, ctx),
    () => c_flowJsonContent(indent, ctx)
  ]);

  // 159
  Node ns_flowYamlNode(int indent, int ctx) => or([
    c_ns_aliasNode,
    () => ns_flowYamlContent(indent, ctx),
    () {
      var props = c_ns_properties(indent, ctx);
      if (!truth(props)) return null;
      var node = or([
        () => transaction(() {
          if (!truth(s_separate(indent, ctx))) return null;
          return ns_flowYamlContent(indent, ctx);
        }),
        e_scalar
      ]);
      return addProps(node, props);
    }
  ]);

  // 160
  Node c_flowJsonNode(int indent, int ctx) => transaction(() {
    var props;
    zeroOrOne(() => transaction(() {
        props = c_ns_properties(indent, ctx);
        if (!truth(props)) return null;
        return s_separate(indent, ctx);
      }));

    return addProps(c_flowJsonContent(indent, ctx), props);
  });

  // 161
  Node ns_flowNode(int indent, int ctx) => or([
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

  // 162
  _BlockHeader c_b_blockHeader() => transaction(() {
    var indentation = c_indentationIndicator();
    var chomping = c_chompingIndicator();
    if (!truth(indentation)) indentation = c_indentationIndicator();
    if (!truth(s_b_comment())) return null;

    return new _BlockHeader(indentation, chomping);
  });

  // 163
  int c_indentationIndicator() {
    if (!isDecDigit(peek())) return null;
    return next() - NUMBER_0;
  }

  // 164
  int c_chompingIndicator() {
    switch (peek()) {
    case HYPHEN:
      next();
      return CHOMPING_STRIP;
    case PLUS:
      next();
      return CHOMPING_KEEP;
    default:
      return CHOMPING_CLIP;
    }
  }

  // 165
  bool b_chompedLast(int chomping) {
    if (_scanner.isDone) return true;
    switch (chomping) {
    case CHOMPING_STRIP:
      return b_nonContent();
    case CHOMPING_CLIP:
    case CHOMPING_KEEP:
      return b_asLineFeed();
    }
    throw "unreachable";
  }

  // 166
  void l_chompedEmpty(int indent, int chomping) {
    switch (chomping) {
    case CHOMPING_STRIP:
    case CHOMPING_CLIP:
      l_stripEmpty(indent);
      break;
    case CHOMPING_KEEP:
      l_keepEmpty(indent);
      break;
    }
  }

  // 167
  void l_stripEmpty(int indent) {
    captureAs('', () {
      zeroOrMore(() => transaction(() {
          if (!truth(s_indentLessThanOrEqualTo(indent))) return false;
          return b_nonContent();
        }));
      zeroOrOne(() => l_trailComments(indent));
      return true;
    });
  }

  // 168
  void l_keepEmpty(int indent) {
    zeroOrMore(() => captureAs('\n', () => l_empty(indent, BLOCK_IN)));
    zeroOrOne(() => captureAs('', () => l_trailComments(indent)));
  }

  // 169
  bool l_trailComments(int indent) => transaction(() {
    if (!truth(s_indentLessThanOrEqualTo(indent))) return false;
    if (!truth(c_nb_commentText())) return false;
    if (!truth(b_comment())) return false;
    zeroOrMore(l_comment);
    return true;
  });

  // 170
  Node c_l_literal(int indent) => transaction(() {
    var start = _scanner.state;
    if (!truth(c_indicator(C_LITERAL))) return null;
    var header = c_b_blockHeader();
    if (!truth(header)) return null;

    var additionalIndent = blockScalarAdditionalIndentation(header, indent);
    var content = l_literalContent(indent + additionalIndent, header.chomping);
    if (!truth(content)) return null;

    return new ScalarNode("!", _scanner.spanFrom(start), content: content);
  });

  // 171
  bool l_nb_literalText(int indent) => transaction(() {
    zeroOrMore(() => captureAs("\n", () => l_empty(indent, BLOCK_IN)));
    if (!truth(captureAs("", () => s_indent(indent)))) return false;
    return truth(oneOrMore(() => consume(isNonBreak)));
  });

  // 172
  bool b_nb_literalNext(int indent) => transaction(() {
    if (!truth(b_asLineFeed())) return false;
    return l_nb_literalText(indent);
  });

  // 173
  String l_literalContent(int indent, int chomping) => captureString(() {
    transaction(() {
      if (!truth(l_nb_literalText(indent))) return false;
      zeroOrMore(() => b_nb_literalNext(indent));
      return b_chompedLast(chomping);
    });
    l_chompedEmpty(indent, chomping);
    return true;
  });

  // 174
  Node c_l_folded(int indent) => transaction(() {
    var start = _scanner.state;
    if (!truth(c_indicator(C_FOLDED))) return null;
    var header = c_b_blockHeader();
    if (!truth(header)) return null;

    var additionalIndent = blockScalarAdditionalIndentation(header, indent);
    var content = l_foldedContent(indent + additionalIndent, header.chomping);
    if (!truth(content)) return null;

    return new ScalarNode("!", _scanner.spanFrom(start), content: content);
  });

  // 175
  bool s_nb_foldedText(int indent) => transaction(() {
    if (!truth(captureAs('', () => s_indent(indent)))) return false;
    if (!truth(consume(isNonSpace))) return false;
    zeroOrMore(() => consume(isNonBreak));
    return true;
  });

  // 176
  bool l_nb_foldedLines(int indent) {
    if (!truth(s_nb_foldedText(indent))) return false;
    zeroOrMore(() => transaction(() {
        if (!truth(b_l_folded(indent, BLOCK_IN))) return false;
        return s_nb_foldedText(indent);
      }));
    return true;
  }

  // 177
  bool s_nb_spacedText(int indent) => transaction(() {
    if (!truth(captureAs('', () => s_indent(indent)))) return false;
    if (!truth(consume(isSpace))) return false;
    zeroOrMore(() => consume(isNonBreak));
    return true;
  });

  // 178
  bool b_l_spaced(int indent) {
    if (!truth(b_asLineFeed())) return false;
    zeroOrMore(() => captureAs("\n", () => l_empty(indent, BLOCK_IN)));
    return true;
  }

  // 179
  bool l_nb_spacedLines(int indent) {
    if (!truth(s_nb_spacedText(indent))) return false;
    zeroOrMore(() => transaction(() {
        if (!truth(b_l_spaced(indent))) return false;
        return s_nb_spacedText(indent);
      }));
    return true;
  }

  // 180
  bool l_nb_sameLines(int indent) => transaction(() {
    zeroOrMore(() => captureAs('\n', () => l_empty(indent, BLOCK_IN)));
    return or([
      () => l_nb_foldedLines(indent),
      () => l_nb_spacedLines(indent)
    ]);
  });

  // 181
  bool l_nb_diffLines(int indent) {
    if (!truth(l_nb_sameLines(indent))) return false;
    zeroOrMore(() => transaction(() {
        if (!truth(b_asLineFeed())) return false;
        return l_nb_sameLines(indent);
      }));
    return true;
  }

  // 182
  String l_foldedContent(int indent, int chomping) => captureString(() {
    transaction(() {
      if (!truth(l_nb_diffLines(indent))) return false;
      return b_chompedLast(chomping);
    });
    l_chompedEmpty(indent, chomping);
    return true;
  });

  // 183
  SequenceNode l_blockSequence(int indent) => context('sequence', () {
    var additionalIndent = countIndentation() - indent;
    if (additionalIndent <= 0) return null;

    var start = _scanner.state;
    var content = oneOrMore(() => transaction(() {
      if (!truth(s_indent(indent + additionalIndent))) return null;
      return c_l_blockSeqEntry(indent + additionalIndent);
    }));
    if (!truth(content)) return null;

    return new SequenceNode("?", content, _scanner.spanFrom(start));
  });

  // 184
  Node c_l_blockSeqEntry(int indent) => transaction(() {
    if (!truth(c_indicator(C_SEQUENCE_ENTRY))) return null;
    if (isNonSpace(peek())) return null;

    return s_l_blockIndented(indent, BLOCK_IN);
  });

  // 185
  Node s_l_blockIndented(int indent, int ctx) {
    var additionalIndent = countIndentation();
    return or([
      () => transaction(() {
        if (!truth(s_indent(additionalIndent))) return null;
        return or([
          () => ns_l_compactSequence(indent + 1 + additionalIndent),
          () => ns_l_compactMapping(indent + 1 + additionalIndent)]);
      }),
      () => s_l_blockNode(indent, ctx),
      () => s_l_comments() ? e_node() : null]);
  }

  // 186
  Node ns_l_compactSequence(int indent) => context('sequence', () {
    var start = _scanner.state;
    var first = c_l_blockSeqEntry(indent);
    if (!truth(first)) return null;

    var content = zeroOrMore(() => transaction(() {
        if (!truth(s_indent(indent))) return null;
        return c_l_blockSeqEntry(indent);
      }));
    content.insert(0, first);

    return new SequenceNode("?", content, _scanner.spanFrom(start));
  });

  // 187
  Node l_blockMapping(int indent) => context('mapping', () {
    var additionalIndent = countIndentation() - indent;
    if (additionalIndent <= 0) return null;

    var start = _scanner.state;
    var pairs = oneOrMore(() => transaction(() {
      if (!truth(s_indent(indent + additionalIndent))) return null;
      return ns_l_blockMapEntry(indent + additionalIndent);
    }));
    if (!truth(pairs)) return null;

    return map(pairs, _scanner.spanFrom(start));
  });

  // 188
  Pair<Node, Node> ns_l_blockMapEntry(int indent) => or([
    () => c_l_blockMapExplicitEntry(indent),
    () => ns_l_blockMapImplicitEntry(indent)
  ]);

  // 189
  Pair<Node, Node> c_l_blockMapExplicitEntry(int indent) {
    var key = c_l_blockMapExplicitKey(indent);
    if (!truth(key)) return null;

    var value = or([
      () => l_blockMapExplicitValue(indent),
      e_node
    ]);

    return new Pair<Node, Node>(key, value);
  }

  // 190
  Node c_l_blockMapExplicitKey(int indent) => transaction(() {
    if (!truth(c_indicator(C_MAPPING_KEY))) return null;
    return s_l_blockIndented(indent, BLOCK_OUT);
  });

  // 191
  Node l_blockMapExplicitValue(int indent) => transaction(() {
    if (!truth(s_indent(indent))) return null;
    if (!truth(c_indicator(C_MAPPING_VALUE))) return null;
    return s_l_blockIndented(indent, BLOCK_OUT);
  });

  // 192
  Pair<Node, Node> ns_l_blockMapImplicitEntry(int indent) => transaction(() {
    var key = or([ns_s_blockMapImplicitKey, e_node]);
    var value = c_l_blockMapImplicitValue(indent);
    return truth(value) ? new Pair<Node, Node>(key, value) : null;
  });

  // 193
  Node ns_s_blockMapImplicitKey() => context('mapping key', () => or([
    () => c_s_implicitJsonKey(BLOCK_KEY),
    () => ns_s_implicitYamlKey(BLOCK_KEY)
  ]));

  // 194
  Node c_l_blockMapImplicitValue(int indent) => context('mapping value', () =>
    transaction(() {
      if (!truth(c_indicator(C_MAPPING_VALUE))) return null;
      return or([
        () => s_l_blockNode(indent, BLOCK_OUT),
        () => s_l_comments() ? e_node() : null
      ]);
    }));

  // 195
  Node ns_l_compactMapping(int indent) => context('mapping', () {
    var start = _scanner.state;
    var first = ns_l_blockMapEntry(indent);
    if (!truth(first)) return null;

    var pairs = zeroOrMore(() => transaction(() {
        if (!truth(s_indent(indent))) return null;
        return ns_l_blockMapEntry(indent);
      }));
    pairs.insert(0, first);

    return map(pairs, _scanner.spanFrom(start));
  });

  // 196
  Node s_l_blockNode(int indent, int ctx) => or([
    () => s_l_blockInBlock(indent, ctx),
    () => s_l_flowInBlock(indent)
  ]);

  // 197
  Node s_l_flowInBlock(int indent) => transaction(() {
    if (!truth(s_separate(indent + 1, FLOW_OUT))) return null;
    var node = ns_flowNode(indent + 1, FLOW_OUT);
    if (!truth(node)) return null;
    if (!truth(s_l_comments())) return null;
    return node;
  });

  // 198
  Node s_l_blockInBlock(int indent, int ctx) => or([
    () => s_l_blockScalar(indent, ctx),
    () => s_l_blockCollection(indent, ctx)
  ]);

  // 199
  Node s_l_blockScalar(int indent, int ctx) => transaction(() {
    if (!truth(s_separate(indent + 1, ctx))) return null;
    var props = transaction(() {
      var innerProps = c_ns_properties(indent + 1, ctx);
      if (!truth(innerProps)) return null;
      if (!truth(s_separate(indent + 1, ctx))) return null;
      return innerProps;
    });

    var node = or([() => c_l_literal(indent), () => c_l_folded(indent)]);
    if (!truth(node)) return null;
    return addProps(node, props);
  });

  // 200
  Node s_l_blockCollection(int indent, int ctx) => transaction(() {
    var props = transaction(() {
      if (!truth(s_separate(indent + 1, ctx))) return null;
      return c_ns_properties(indent + 1, ctx);
    });

    if (!truth(s_l_comments())) return null;
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
    if (!truth(c_documentEnd())) return false;
    return s_l_comments();
  });

  // 206
  bool c_forbidden() {
    if (!_inBareDocument || !atStartOfLine) return false;
    var forbidden = false;
    transaction(() {
      if (!truth(or([c_directivesEnd, c_documentEnd]))) return;
      var char = peek();
      forbidden = isBreak(char) || isSpace(char) || _scanner.isDone;
      return;
    });
    return forbidden;
  }

  // 207
  Node l_bareDocument() {
    try {
      _inBareDocument = true;
      return s_l_blockNode(-1, BLOCK_IN);
    } finally {
      _inBareDocument = false;
    }
  }

  // 208
  Node l_explicitDocument() {
    if (!truth(c_directivesEnd())) return null;
    var doc = l_bareDocument();
    if (truth(doc)) return doc;

    doc = e_node();
    s_l_comments();
    return doc;
  }

  // 209
  Node l_directiveDocument() {
    if (!truth(oneOrMore(l_directive))) return null;
    var doc = l_explicitDocument();
    if (doc != null) return doc;
    parseFailed();
    return null; // Unreachable.
  }

  // 210
  Node l_anyDocument() =>
    or([l_directiveDocument, l_explicitDocument, l_bareDocument]);

  // 211
  Pair<List<Node>, SourceSpan> l_yamlStream() {
    var start = _scanner.state;
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

    if (!_scanner.isDone) parseFailed();
    return new Pair(docs, _scanner.spanFrom(start));
  }
}

/// The information in the header for a block scalar.
class _BlockHeader {
  final int additionalIndent;
  final int chomping;

  _BlockHeader(this.additionalIndent, this.chomping);

  bool get autoDetectIndent => additionalIndent == null;
}

/// A range of characters in the YAML document, from [start] to [end]
/// (inclusive).
class _Range {
  /// The first character in the range.
  final int start;

  /// The last character in the range.
  final int end;

  _Range(this.start, this.end);

  /// Returns whether or not [pos] lies within this range.
  bool contains(int pos) => pos >= start && pos <= end;
}

/// A map that associates [E] values with [_Range]s. It's efficient to create
/// new associations, but finding the value associated with a position is more
/// expensive.
class _RangeMap<E> {
  /// The ranges and their associated elements.
  final List<Pair<_Range, E>> _contents = <Pair<_Range, E>>[];

  _RangeMap();

  /// Returns the value associated with the range in which [pos] lies, or null
  /// if there is no such range. If there's more than one such range, the most
  /// recently set one is used.
  E operator[](int pos) {
    // Iterate backwards through contents so the more recent range takes
    // precedence.
    for (var pair in _contents.reversed) {
      if (pair.first.contains(pos)) return pair.last;
    }
    return null;
  }

  /// Associates [value] with [range].
  operator[]=(_Range range, E value) =>
    _contents.add(new Pair<_Range, E>(range, value));
}
