// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A keyword in the Dart programming language.
 */
class Keyword implements SourceString {
  static const Keyword BREAK = const Keyword("break");
  static const Keyword CASE = const Keyword("case");
  static const Keyword CATCH = const Keyword("catch");
  static const Keyword CLASS = const Keyword("class");
  static const Keyword CONST = const Keyword("const");
  static const Keyword CONTINUE = const Keyword("continue");
  static const Keyword DEFAULT = const Keyword("default");
  static const Keyword DO = const Keyword("do");
  static const Keyword ELSE = const Keyword("else");
  static const Keyword EXTENDS = const Keyword("extends");
  static const Keyword FALSE = const Keyword("false");
  static const Keyword FINAL = const Keyword("final");
  static const Keyword FINALLY = const Keyword("finally");
  static const Keyword FOR = const Keyword("for");
  static const Keyword IF = const Keyword("if");
  static const Keyword IN = const Keyword("in");
  static const Keyword IS = const Keyword("is", info: IS_INFO);
  static const Keyword NEW = const Keyword("new");
  static const Keyword NULL = const Keyword("null");
  static const Keyword RETURN = const Keyword("return");
  static const Keyword SUPER = const Keyword("super");
  static const Keyword SWITCH = const Keyword("switch");
  static const Keyword THIS = const Keyword("this");
  static const Keyword THROW = const Keyword("throw");
  static const Keyword TRUE = const Keyword("true");
  static const Keyword TRY = const Keyword("try");
  static const Keyword VAR = const Keyword("var");
  static const Keyword VOID = const Keyword("void");
  static const Keyword WHILE = const Keyword("while");

  // Pseudo keywords:
  static const Keyword ABSTRACT = const Keyword("abstract", isPseudo: true);
  static const Keyword AS = const Keyword("as", info: AS_INFO, isPseudo: true);
  static const Keyword ASSERT = const Keyword("assert", isPseudo: true);
  static const Keyword EXTERNAL = const Keyword("external", isPseudo: true);
  static const Keyword FACTORY = const Keyword("factory", isPseudo: true);
  static const Keyword GET = const Keyword("get", isPseudo: true);
  static const Keyword IMPLEMENTS = const Keyword("implements", isPseudo: true);
  static const Keyword IMPORT = const Keyword("import", isPseudo: true);
  static const Keyword INTERFACE = const Keyword("interface", isPseudo: true);
  static const Keyword LIBRARY = const Keyword("library", isPseudo: true);
  static const Keyword NATIVE = const Keyword("native", isPseudo: true);
  static const Keyword OPERATOR = const Keyword("operator", isPseudo: true);
  static const Keyword ON = const Keyword("on", isPseudo: true);
  static const Keyword SET = const Keyword("set", isPseudo: true);
  static const Keyword SOURCE = const Keyword("source", isPseudo: true);
  static const Keyword STATIC = const Keyword("static", isPseudo: true);
  static const Keyword TYPEDEF = const Keyword("typedef", isPseudo: true);

  static const List<Keyword> values = const <Keyword> [
      AS,
      BREAK,
      CASE,
      CATCH,
      CONST,
      CONTINUE,
      DEFAULT,
      DO,
      ELSE,
      FALSE,
      FINAL,
      FINALLY,
      FOR,
      IF,
      IN,
      IS,
      NEW,
      NULL,
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
      ABSTRACT,
      ASSERT,
      CLASS,
      EXTENDS,
      EXTERNAL,
      FACTORY,
      GET,
      IMPLEMENTS,
      IMPORT,
      INTERFACE,
      LIBRARY,
      NATIVE,
      OPERATOR,
      ON,
      SET,
      SOURCE,
      STATIC,
      TYPEDEF ];

  final String syntax;
  final bool isPseudo;
  final PrecedenceInfo info;

  static Map<String, Keyword> _keywords;
  static Map<String, Keyword> get keywords {
    if (_keywords === null) {
      _keywords = computeKeywordMap();
    }
    return _keywords;
  }

  const Keyword(String this.syntax,
                [bool this.isPseudo = false,
                 PrecedenceInfo this.info = KEYWORD_INFO]);

  static Map<String, Keyword> computeKeywordMap() {
    Map<String, Keyword> result = new LinkedHashMap<String, Keyword>();
    for (Keyword keyword in values) {
      result[keyword.syntax] = keyword;
    }
    return result;
  }

  int hashCode() => syntax.hashCode();

  bool operator ==(other) {
    return other is SourceString && toString() == other.slowToString();
  }

  Iterator<int> iterator() => new StringCodeIterator(syntax);

  void printOn(StringBuffer sb) {
    sb.add(syntax);
  }

  String toString() => syntax;
  String slowToString() => syntax;
  String get stringValue => syntax;

  SourceString copyWithoutQuotes(int initial, int terminal) {
    // TODO(lrn): consider remodelling to avoid having this method in keywords.
    return this;
  }

  bool isEmpty() => false;
  bool isPrivate() => false;
}

/**
 * Abstract state in a state machine for scanning keywords.
 */
class KeywordState {
  abstract bool isLeaf();
  abstract KeywordState next(int c);
  abstract Keyword get keyword;

  static KeywordState _KEYWORD_STATE;
  static KeywordState get KEYWORD_STATE {
    if (_KEYWORD_STATE === null) {
      List<String> strings = new List<String>(Keyword.values.length);
      for (int i = 0; i < Keyword.values.length; i++) {
        strings[i] = Keyword.values[i].syntax;
      }
      strings.sort((a,b) => a.compareTo(b));
      _KEYWORD_STATE = computeKeywordStateTable(0, strings, 0, strings.length);
    }
    return _KEYWORD_STATE;
  }

  static KeywordState computeKeywordStateTable(int start, List<String> strings,
                                               int offset, int length) {
    List<KeywordState> result = new List<KeywordState>(26);
    assert(length != 0);
    int chunk = 0;
    int chunkStart = -1;
    bool isLeaf = false;
    for (int i = offset; i < offset + length; i++) {
      if (strings[i].length == start) {
        isLeaf = true;
      }
      if (strings[i].length > start) {
        int c = strings[i].charCodeAt(start);
        if (chunk != c) {
          if (chunkStart != -1) {
            assert(result[chunk - $a] === null);
            result[chunk - $a] = computeKeywordStateTable(start + 1, strings,
                                                          chunkStart,
                                                          i - chunkStart);
          }
          chunkStart = i;
          chunk = c;
        }
      }
    }
    if (chunkStart != -1) {
      assert(result[chunk - $a] === null);
      result[chunk - $a] =
        computeKeywordStateTable(start + 1, strings, chunkStart,
                                 offset + length - chunkStart);
    } else {
      assert(length == 1);
      return new LeafKeywordState(strings[offset]);
    }
    if (isLeaf) {
      return new ArrayKeywordState(result, strings[offset]);
    } else {
      return new ArrayKeywordState(result, null);
    }
  }
}

/**
 * A state with multiple outgoing transitions.
 */
class ArrayKeywordState extends KeywordState {
  final List<KeywordState> table;
  final Keyword keyword;

  ArrayKeywordState(List<KeywordState> this.table, String syntax)
    : keyword = (syntax === null) ? null : Keyword.keywords[syntax];

  bool isLeaf() => false;

  KeywordState next(int c) => table[c - $a];

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.add("[");
    if (keyword !== null) {
      sb.add("*");
      sb.add(keyword);
      sb.add(" ");
    }
    List<KeywordState> foo = table;
    for (int i = 0; i < foo.length; i++) {
      if (foo[i] != null) {
        sb.add("${new String.fromCharCodes([i + $a])}: ${foo[i]}; ");
      }
    }
    sb.add("]");
    return sb.toString();
  }
}

/**
 * A state that has no outgoing transitions.
 */
class LeafKeywordState extends KeywordState {
  final Keyword keyword;

  LeafKeywordState(String syntax) : keyword = Keyword.keywords[syntax];

  bool isLeaf() => true;

  KeywordState next(int c) => null;

  String toString() => keyword.syntax;
}
