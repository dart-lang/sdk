// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show stdout;

import 'package:_fe_analyzer_shared/src/scanner/characters.dart';
import 'package:_fe_analyzer_shared/src/scanner/keyword_state.dart' as new_impl;
import 'package:_fe_analyzer_shared/src/scanner/token.dart';

void main() {
  new_impl.KeywordState initialAlternative = new_impl.KeywordStateHelper.table;
  final KeywordState initialState = KeywordState.KEYWORD_STATE;
  for (int i = 0; i < Keyword.values.length; i++) {
    Keyword keyword = Keyword.values[i];
    String lexeme = keyword.lexeme;
    KeywordState? state = initialState;
    new_impl.KeywordState alternative = initialAlternative;
    for (int j = 0; j < lexeme.length; j++) {
      int char = lexeme.codeUnitAt(j);
      stdout.write("--> $char ");
      if (char <= $Z) {
        state = state?.nextCapital(char);
      } else {
        state = state?.next(char);
      }
      if (state?.keyword != null) {
        stdout.write(" => ${state?.keyword} (KeywordState)");
      }

      alternative = alternative.next(char);
      if (alternative.keyword != null) {
        stdout.write(" => ${alternative.keyword} (bar)");
      }

      if (state?.keyword != alternative.keyword) {
        throw "Unexpected keyword. Expected ${state?.keyword}, "
            "but found ${alternative.keyword}";
      }

      // What if we we're to take any (other) character?
      for (int k = $A; k < $z; k++) {
        KeywordState? statePrime = state;
        new_impl.KeywordState alternativePrime = alternative;
        // Doing it the other way around here to avoid a crash when giving
        // next something that's not between a and z.
        if (k >= $a) {
          statePrime = statePrime?.next(k);
        } else {
          statePrime = statePrime?.nextCapital(k);
        }
        alternativePrime = alternativePrime.next(k);
        if ((statePrime == null) != (alternativePrime.isNull)) {
          throw "Unexpected null-ness: "
              "Expected ${statePrime == null ? "null" : "non-null"},"
              "but found ${alternativePrime.isNull ? "null" : "non-null"}";
        }
        if (statePrime?.keyword != alternativePrime.keyword) {
          throw "Unexpected keyword. Expected ${statePrime?.keyword}, "
              "but found ${alternativePrime.keyword}";
        }
      }
    }

    stdout.write("\n");
  }

  print("All done.");
}

// The below is the original implementation of the KeywordState stuff that the
// new implementation is tested against.
// As of 2025-02-03 the retained size of the single UpperCaseArrayKeywordState
// existing is 68.4KB (~70,041 bytes).
// There are additionally:
// 70 LeafKeywordState and 225 LowerCaseArrayKeywordState.
// The new implementation (above) has a 35,046 bytes table, and even with some
// possible overhead it's ~half the memory. It seems quite a lot faster.

/**
 * Abstract state in a state machine for scanning keywords.
 */
abstract class KeywordState {
  KeywordState? next(int c);
  KeywordState? nextCapital(int c);

  Keyword? get keyword;

  static KeywordState? _KEYWORD_STATE;
  static KeywordState get KEYWORD_STATE {
    if (_KEYWORD_STATE == null) {
      List<String> strings = Keyword.values
          .map((keyword) => keyword.lexeme)
          .toList(growable: false);
      strings.sort((a, b) => a.compareTo(b));
      _KEYWORD_STATE = computeKeywordStateTable(
        /* start = */ 0,
        strings,
        /* offset = */ 0,
        strings.length,
      );
    }
    return _KEYWORD_STATE!;
  }

  static KeywordState computeKeywordStateTable(
    int start,
    List<String> strings,
    int offset,
    int length,
  ) {
    bool isLowercase = true;

    List<KeywordState?> table = new List<KeywordState?>.filled(
      $z - $A + 1,
      /* fill = */ null,
    );
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
              start + 1,
              strings,
              chunkStart,
              i - chunkStart,
            );
          }
          chunkStart = i;
          chunk = c;
        }
      }
    }
    if (chunkStart != -1) {
      assert(table[chunk - $A] == null);
      table[chunk - $A] = computeKeywordStateTable(
        start + 1,
        strings,
        chunkStart,
        offset + length - chunkStart,
      );
    } else {
      assert(length == 1);
      return new LeafKeywordState(strings[offset]);
    }
    String? syntax = isLeaf ? strings[offset] : null;
    if (isLowercase) {
      // This creates a growable list.
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
  final List<KeywordState?> table;
  @override
  final Keyword? keyword;

  ArrayKeywordState(this.table, String? syntax)
    : keyword = ((syntax == null) ? null : Keyword.keywords[syntax]);

  @override
  KeywordState? next(int c);

  @override
  KeywordState? nextCapital(int c);

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("[");
    if (keyword != null) {
      sb.write("*");
      sb.write(keyword);
      sb.write(" ");
    }
    List<KeywordState?> foo = table;
    for (int i = 0; i < foo.length; i++) {
      if (foo[i] != null) {
        sb.write(
          "${new String.fromCharCodes([i + $a])}: "
          "${foo[i]}; ",
        );
      }
    }
    sb.write("]");
    return sb.toString();
  }
}

class LowerCaseArrayKeywordState extends ArrayKeywordState {
  LowerCaseArrayKeywordState(List<KeywordState?> table, String? syntax)
    : super(table, syntax) {
    assert(table.length == $z - $a + 1);
  }

  @override
  KeywordState? next(int c) => table[c - $a];

  @override
  KeywordState? nextCapital(int c) => null;
}

class UpperCaseArrayKeywordState extends ArrayKeywordState {
  UpperCaseArrayKeywordState(List<KeywordState?> table, String? syntax)
    : super(table, syntax) {
    assert(table.length == $z - $A + 1);
  }

  @override
  KeywordState? next(int c) => table[c - $A];

  @override
  KeywordState? nextCapital(int c) => table[c - $A];
}

/**
 * A state that has no outgoing transitions.
 */
class LeafKeywordState implements KeywordState {
  @override
  final Keyword keyword;

  LeafKeywordState(String syntax) : keyword = Keyword.keywords[syntax]!;

  @override
  KeywordState? next(int c) => null;
  @override
  KeywordState? nextCapital(int c) => null;

  @override
  String toString() => keyword.lexeme;
}
