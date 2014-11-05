// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of scanner;

/**
 * A keyword in the Dart programming language.
 */
class Keyword {
  static const List<Keyword> values = const <Keyword> [
      const Keyword("assert"),
      const Keyword("break"),
      const Keyword("case"),
      const Keyword("catch"),
      const Keyword("class"),
      const Keyword("const"),
      const Keyword("continue"),
      const Keyword("default"),
      const Keyword("do"),
      const Keyword("else"),
      const Keyword("extends"),
      const Keyword("false"),
      const Keyword("final"),
      const Keyword("finally"),
      const Keyword("for"),
      const Keyword("if"),
      const Keyword("in"),
      const Keyword("new"),
      const Keyword("null"),
      const Keyword("rethrow"),
      const Keyword("return"),
      const Keyword("super"),
      const Keyword("switch"),
      const Keyword("this"),
      const Keyword("throw"),
      const Keyword("true"),
      const Keyword("try"),
      const Keyword("var"),
      const Keyword("void"),
      const Keyword("while"),
      const Keyword("with"),

      // TODO(ahe): Don't think this is a reserved word.
      // See: http://dartbug.com/5579
      const Keyword("is", info: IS_INFO),

      const Keyword("abstract", isBuiltIn: true),
      const Keyword("as", info: AS_INFO, isBuiltIn: true),
      const Keyword("dynamic", isBuiltIn: true),
      const Keyword("export", isBuiltIn: true),
      const Keyword("external", isBuiltIn: true),
      const Keyword("factory", isBuiltIn: true),
      const Keyword("get", isBuiltIn: true),
      const Keyword("implements", isBuiltIn: true),
      const Keyword("import", isBuiltIn: true),
      const Keyword("library", isBuiltIn: true),
      const Keyword("operator", isBuiltIn: true),
      const Keyword("part", isBuiltIn: true),
      const Keyword("set", isBuiltIn: true),
      const Keyword("static", isBuiltIn: true),
      const Keyword("typedef", isBuiltIn: true),

      const Keyword("hide", isPseudo: true),
      const Keyword("native", isPseudo: true),
      const Keyword("of", isPseudo: true),
      const Keyword("on", isPseudo: true),
      const Keyword("show", isPseudo: true),
      const Keyword("source", isPseudo: true),
      const Keyword("deferred", isPseudo: true),
      const Keyword("async", isPseudo: true),
      const Keyword("sync", isPseudo: true),
      const Keyword("await", isPseudo: true),
      const Keyword("yield", isPseudo: true)];

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
                {this.isPseudo: false,
                 this.isBuiltIn: false,
                 this.info: KEYWORD_INFO});

  static Map<String, Keyword> computeKeywordMap() {
    Map<String, Keyword> result = new Map<String, Keyword>();
    for (Keyword keyword in values) {
      result[keyword.syntax] = keyword;
    }
    return result;
  }

  String toString() => syntax;
}

/**
 * Abstract state in a state machine for scanning keywords.
 */
abstract class KeywordState {
  KeywordState(this.keyword);

  KeywordState next(int c);
  final Keyword keyword;

  static KeywordState _KEYWORD_STATE;
  static KeywordState get KEYWORD_STATE {
    if (_KEYWORD_STATE == null) {
      List<String> strings =
          new List<String>(Keyword.values.length);
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
        int c = strings[i].codeUnitAt(start);
        if (chunk != c) {
          if (chunkStart != -1) {
            assert(result[chunk - $a] == null);
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
      assert(result[chunk - $a] == null);
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

  ArrayKeywordState(List<KeywordState> this.table, String syntax)
    : super((syntax == null) ? null : Keyword.keywords[syntax]);

  KeywordState next(int c) => table[c - $a];

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
        sb.write("${new String.fromCharCodes([i + $a])}: ${foo[i]}; ");
      }
    }
    sb.write("]");
    return sb.toString();
  }
}

/**
 * A state that has no outgoing transitions.
 */
class LeafKeywordState extends KeywordState {
  LeafKeywordState(String syntax) : super(Keyword.keywords[syntax]);

  KeywordState next(int c) => null;

  String toString() => keyword.syntax;
}
