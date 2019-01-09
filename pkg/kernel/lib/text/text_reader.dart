// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.text_reader;

// S-expressions
//
// An S-expression is an atom or an S-list, an atom is a string that does not
// contain the delimiters '(', ')', or ' ', and an S-list is a space delimited
// sequence of S-expressions enclosed in parentheses:
//
// <S-expression> ::= <Atom>
//                  | <S-list>
// <S-list>       ::= '(' ')'
//                  | '(' <S-expression> {' ' <S-expression>}* ')'
//
// We use an iterator to read S-expressions.  The iterator produces a stream
// of atoms (strings) and nested iterators (S-lists).
class TextIterator implements Iterator<Object /* String | TextIterator */ > {
  static int space = ' '.codeUnitAt(0);
  static int lparen = '('.codeUnitAt(0);
  static int rparen = ')'.codeUnitAt(0);
  static int dquote = '"'.codeUnitAt(0);
  static int bslash = '\\'.codeUnitAt(0);

  final String input;
  int index;

  TextIterator(this.input, this.index);

  // Consume spaces.
  void skipWhitespace() {
    while (index < input.length && input.codeUnitAt(index) == space) {
      ++index;
    }
  }

  // Consume the rest of a nested S-expression and the closing delimiter.
  void skipToEndOfNested() {
    if (current is TextIterator) {
      TextIterator it = current;
      while (it.moveNext());
      index = it.index + 1;
    }
  }

  void skipToEndOfAtom() {
    bool isQuoted = false;
    if (index < input.length && input.codeUnitAt(index) == dquote) {
      ++index;
      isQuoted = true;
    }
    do {
      if (index >= input.length) return;
      int codeUnit = input.codeUnitAt(index);
      if (isQuoted) {
        // Terminator.
        if (codeUnit == dquote) {
          ++index;
          return;
        }
        // Escaped double quote.
        if (codeUnit == bslash &&
            index < input.length + 1 &&
            input.codeUnitAt(index + 1) == dquote) {
          index += 2;
        } else {
          ++index;
        }
      } else {
        // Terminator.
        if (codeUnit == space || codeUnit == rparen) return;
        ++index;
      }
    } while (true);
  }

  @override
  Object current = null;

  @override
  bool moveNext() {
    skipToEndOfNested();
    skipWhitespace();
    if (index >= input.length || input.codeUnitAt(index) == rparen) {
      current = null;
      return false;
    }
    if (input.codeUnitAt(index) == lparen) {
      current = new TextIterator(input, index + 1);
      return true;
    }
    int start = index;
    skipToEndOfAtom();
    current = input.substring(start, index);
    return true;
  }
}
