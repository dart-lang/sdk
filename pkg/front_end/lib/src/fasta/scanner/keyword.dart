// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.scanner.keywords;

import '../../scanner/token.dart' as analyzer;

import 'characters.dart' show $a, $z, $A, $Z;

import 'precedence.dart' show PrecedenceInfo;

import 'precedence.dart' show AS_INFO, IS_INFO, KEYWORD_INFO;

/**
 * A keyword in the Dart programming language.
 */
class Keyword implements analyzer.Keyword {
  static const ASSERT = const Keyword("assert");
  static const BREAK = const Keyword("break");
  static const CASE = const Keyword("case");
  static const CATCH = const Keyword("catch");
  static const CLASS = const Keyword("class");
  static const CONST = const Keyword("const");
  static const CONTINUE = const Keyword("continue");
  static const DEFAULT = const Keyword("default");
  static const DO = const Keyword("do");
  static const ELSE = const Keyword("else");
  static const ENUM = const Keyword("enum");
  static const EXTENDS = const Keyword("extends");
  static const FALSE = const Keyword("false");
  static const FINAL = const Keyword("final");
  static const FINALLY = const Keyword("finally");
  static const FOR = const Keyword("for");
  static const IF = const Keyword("if");
  static const IN = const Keyword("in");
  static const NEW = const Keyword("new");
  static const NULL = const Keyword("null");
  static const RETHROW = const Keyword("rethrow");
  static const RETURN = const Keyword("return");
  static const SUPER = const Keyword("super");
  static const SWITCH = const Keyword("switch");
  static const THIS = const Keyword("this");
  static const THROW = const Keyword("throw");
  static const TRUE = const Keyword("true");
  static const TRY = const Keyword("try");
  static const VAR = const Keyword("var");
  static const VOID = const Keyword("void");
  static const WHILE = const Keyword("while");
  static const WITH = const Keyword("with");

  // TODO(ahe): Don't think this is a reserved word.
  // See: http://dartbug.com/5579
  static const IS = const Keyword("is", info: IS_INFO);

  static const ABSTRACT = const Keyword("abstract", isBuiltIn: true);
  static const AS = const Keyword("as", info: AS_INFO, isBuiltIn: true);
  static const COVARIANT = const Keyword("covariant", isBuiltIn: true);
  static const DYNAMIC = const Keyword("dynamic", isBuiltIn: true);
  static const EXPORT = const Keyword("export", isBuiltIn: true);
  static const EXTERNAL = const Keyword("external", isBuiltIn: true);
  static const FACTORY = const Keyword("factory", isBuiltIn: true);
  static const GET = const Keyword("get", isBuiltIn: true);
  static const IMPLEMENTS = const Keyword("implements", isBuiltIn: true);
  static const IMPORT = const Keyword("import", isBuiltIn: true);
  static const LIBRARY = const Keyword("library", isBuiltIn: true);
  static const OPERATOR = const Keyword("operator", isBuiltIn: true);
  static const PART = const Keyword("part", isBuiltIn: true);
  static const SET = const Keyword("set", isBuiltIn: true);
  static const STATIC = const Keyword("static", isBuiltIn: true);
  static const TYPEDEF = const Keyword("typedef", isBuiltIn: true);

  static const ASYNC = const Keyword("async", isPseudo: true);
  static const AWAIT = const Keyword("await", isPseudo: true);
  static const DEFERRED = const Keyword("deferred", isBuiltIn: true);
  static const FUNCTION = const Keyword("Function", isPseudo: true);
  static const HIDE = const Keyword("hide", isPseudo: true);
  static const NATIVE = const Keyword("native", isPseudo: true);
  static const OF = const Keyword("of", isPseudo: true);
  static const ON = const Keyword("on", isPseudo: true);
  static const PATCH = const Keyword("patch", isPseudo: true);
  static const SHOW = const Keyword("show", isPseudo: true);
  static const SOURCE = const Keyword("source", isPseudo: true);
  static const SYNC = const Keyword("sync", isPseudo: true);
  static const YIELD = const Keyword("yield", isPseudo: true);

  static const List<Keyword> values = const <Keyword>[
    ASSERT,
    BREAK,
    CASE,
    CATCH,
    CLASS,
    CONST,
    CONTINUE,
    DEFAULT,
    DO,
    ELSE,
    ENUM,
    EXTENDS,
    FALSE,
    FINAL,
    FINALLY,
    FOR,
    IF,
    IN,
    NEW,
    NULL,
    RETHROW,
    RETURN,
    SUPER,
    SWITCH,
    THIS,
    THROW,
    TRUE,
    TRY,
    VAR,
    VOID,
    WHILE,
    WITH,
    // ====
    IS,
    // ==== Built In
    ABSTRACT,
    AS,
    COVARIANT,
    DEFERRED,
    DYNAMIC,
    EXPORT,
    EXTERNAL,
    FACTORY,
    GET,
    IMPLEMENTS,
    IMPORT,
    LIBRARY,
    OPERATOR,
    PART,
    SET,
    STATIC,
    TYPEDEF,
    // ==== Pseudo
    ASYNC,
    AWAIT,
    FUNCTION,
    HIDE,
    NATIVE,
    OF,
    ON,
    PATCH,
    SHOW,
    SOURCE,
    SYNC,
    YIELD,
  ];

  final String syntax;
  final bool isPseudo;
  final bool isBuiltIn;
  final PrecedenceInfo info;

  static Map<String, Keyword> _keywords;
  static Map<String, Keyword> get keywords {
    if (_keywords == null) {
      _keywords = computeKeywordMap();
    }
    return _keywords;
  }

  const Keyword(this.syntax,
      {this.isPseudo: false, this.isBuiltIn: false, this.info: KEYWORD_INFO});

  static Map<String, Keyword> computeKeywordMap() {
    Map<String, Keyword> result = new Map<String, Keyword>();
    for (Keyword keyword in values) {
      result[keyword.syntax] = keyword;
    }
    return result;
  }

  String toString() => syntax;

  /// The term "pseudo-keyword" doesn't exist in the spec, and
  /// Analyzer and Fasta have different notions of what it means.
  /// Analyzer's notion of "pseudo-keyword" corresponds with Fasta's
  /// notion of "built-in keyword".
  /// Use [isBuiltIn] instead.
  @override
  bool get isPseudoKeyword => isBuiltIn;

  @override
  String get name => syntax.toUpperCase();
}

/**
 * Abstract state in a state machine for scanning keywords.
 */
abstract class KeywordState {
  KeywordState next(int c);
  KeywordState nextCapital(int c);

  Keyword get keyword;

  static KeywordState _KEYWORD_STATE;
  static KeywordState get KEYWORD_STATE {
    if (_KEYWORD_STATE == null) {
      List<String> strings = new List<String>(Keyword.values.length);
      for (int i = 0; i < Keyword.values.length; i++) {
        strings[i] = Keyword.values[i].syntax;
      }
      strings.sort((a, b) => a.compareTo(b));
      _KEYWORD_STATE = computeKeywordStateTable(0, strings, 0, strings.length);
    }
    return _KEYWORD_STATE;
  }

  static KeywordState computeKeywordStateTable(
      int start, List<String> strings, int offset, int length) {
    bool isLowercase = true;

    List<KeywordState> table = new List<KeywordState>($z - $A + 1);
    assert(length != 0);
    int chunk = 0;
    int chunkStart = -1;
    bool isLeaf = false;
    for (int i = offset; i < offset + length; i++) {
      if (strings[i].length == start) {
        isLeaf = true;
      }
      if (strings[i].length > start) {
        int c = strings[i].codeUnitAt(start);
        if ($A <= c && c <= $Z) {
          isLowercase = false;
        }
        if (chunk != c) {
          if (chunkStart != -1) {
            assert(table[chunk - $A] == null);
            table[chunk - $A] = computeKeywordStateTable(
                start + 1, strings, chunkStart, i - chunkStart);
          }
          chunkStart = i;
          chunk = c;
        }
      }
    }
    if (chunkStart != -1) {
      assert(table[chunk - $A] == null);
      table[chunk - $A] = computeKeywordStateTable(
          start + 1, strings, chunkStart, offset + length - chunkStart);
    } else {
      assert(length == 1);
      return new LeafKeywordState(strings[offset]);
    }
    String syntax = isLeaf ? strings[offset] : null;
    if (isLowercase) {
      table = table.sublist($a - $A);
      return new LowerCaseArrayKeywordState(table, syntax);
    } else {
      return new UpperCaseArrayKeywordState(table, syntax);
    }
  }
}

/**
 * A state with multiple outgoing transitions.
 */
abstract class ArrayKeywordState implements KeywordState {
  final List<KeywordState> table;
  final Keyword keyword;

  ArrayKeywordState(this.table, String syntax)
      : keyword = ((syntax == null) ? null : Keyword.keywords[syntax]);

  KeywordState next(int c);

  KeywordState nextCapital(int c);

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("[");
    if (keyword != null) {
      sb.write("*");
      sb.write(keyword);
      sb.write(" ");
    }
    List<KeywordState> foo = table;
    for (int i = 0; i < foo.length; i++) {
      if (foo[i] != null) {
        sb.write("${new String.fromCharCodes([i + $a])}: "
            "${foo[i]}; ");
      }
    }
    sb.write("]");
    return sb.toString();
  }
}

class LowerCaseArrayKeywordState extends ArrayKeywordState {
  LowerCaseArrayKeywordState(List<KeywordState> table, String syntax)
      : super(table, syntax) {
    assert(table.length == $z - $a + 1);
  }

  KeywordState next(int c) => table[c - $a];

  KeywordState nextCapital(int c) => null;
}

class UpperCaseArrayKeywordState extends ArrayKeywordState {
  UpperCaseArrayKeywordState(List<KeywordState> table, String syntax)
      : super(table, syntax) {
    assert(table.length == $z - $A + 1);
  }

  KeywordState next(int c) => table[c - $A];

  KeywordState nextCapital(int c) => table[c - $A];
}

/**
 * A state that has no outgoing transitions.
 */
class LeafKeywordState implements KeywordState {
  final Keyword keyword;

  LeafKeywordState(String syntax) : keyword = Keyword.keywords[syntax];

  KeywordState next(int c) => null;
  KeywordState nextCapital(int c) => null;

  String toString() => keyword.syntax;
}
