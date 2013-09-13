// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_writer;


class Line {

  final int lineLength;
  final tokens = <LineToken>[];
  final bool useTabs;
  final int spacesPerIndent;

  Line({indent: 0, this.lineLength: 80, this.useTabs: false,
        this.spacesPerIndent: 2}) {
    if (indent > 0) {
      _indent(indent);
    }
  }

  void addSpace() {
    addSpaces(1);
  }

  void addSpaces(int n) {
    if (n > 0) {
      tokens.add(new SpaceToken(n));
    }
  }

  void addToken(LineToken token) {
    tokens.add(token);
  }

  bool isWhitespace() => tokens.every((tok) => tok is SpaceToken);

  void _indent(int n) {
    tokens.add(useTabs ? new TabToken(n) : new SpaceToken(n * spacesPerIndent));
  }

  String toString() {
    var buffer = new StringBuffer();
    tokens.forEach((tok) => buffer.write(tok.toString()));
    return buffer.toString();
  }

}


class LineToken {

  final String value;

  LineToken(this.value);

  String toString() => value;
}

class SpaceToken extends LineToken {

  SpaceToken(int n) : super(getSpaces(n));
}

class TabToken extends LineToken {

  TabToken(int n) : super(getTabs(n));
}


class NewlineToken extends LineToken {

  NewlineToken(String value) : super(value);
}



class SourceWriter {

  final StringBuffer buffer = new StringBuffer();
  Line currentLine;

  final String lineSeparator;
  int indentCount = 0;
  
  LineToken _lastToken;
  
  SourceWriter({this.indentCount: 0, this.lineSeparator: NEW_LINE}) {
    currentLine = new Line(indent: indentCount);
  }

  LineToken get lastToken => _lastToken;
  
  _addToken(LineToken token) {
    _lastToken = token;
    currentLine.addToken(token);
  }
  
  void indent() {
    ++indentCount;
  }

  void newline() {
    if (currentLine.isWhitespace()) {
      currentLine.tokens.clear();
    }
    _addToken(new NewlineToken(this.lineSeparator));
    buffer.write(currentLine.toString());
    currentLine = new Line(indent: indentCount);
  }

  void newlines(int num) {
    while (num-- > 0) {
      newline();
    }
  }

  void print(x) {
    _addToken(new LineToken(x));
  }
  
  void println(String s) {
    print(s);
    newline();
  }
  
  void space() {
    spaces(1);
  }

  void spaces(n) {
    currentLine.addSpaces(n);
  }
  
  void unindent() {
    --indentCount;
  }
  
  String toString() {
    var source = new StringBuffer(buffer.toString());
    if (!currentLine.isWhitespace()) {
      source.write(currentLine);
    }
    return source.toString();
  }

}

const NEW_LINE = '\n';
const SPACE = ' ';
const SPACES = const [
          '',
          ' ',
          '  ',
          '   ',
          '    ',
          '     ',
          '      ',
          '       ',
          '        ',
          '         ',
          '          ',
          '           ',
          '            ',
          '             ',
          '              ',
          '               ',
          '                ',
];
const TABS = const [
          '',
          '\t',
          '\t\t',
          '\t\t\t',
          '\t\t\t\t',
          '\t\t\t\t\t',
          '\t\t\t\t\t\t',
          '\t\t\t\t\t\t\t',
          '\t\t\t\t\t\t\t\t',
          '\t\t\t\t\t\t\t\t\t',
          '\t\t\t\t\t\t\t\t\t\t',
          '\t\t\t\t\t\t\t\t\t\t\t',
          '\t\t\t\t\t\t\t\t\t\t\t\t',
          '\t\t\t\t\t\t\t\t\t\t\t\t\t',
          '\t\t\t\t\t\t\t\t\t\t\t\t\t\t',
];


String getIndentString(int indentWidth, {bool useTabs: false}) =>
    useTabs ? getTabs(indentWidth) : getSpaces(indentWidth);

String getSpaces(int n) => n < SPACES.length ? SPACES[n] : repeat(' ', n);

String getTabs(int n) => n < TABS.length ? TABS[n] : repeat('\t', n);

String repeat(String ch, int times) {
  var sb = new StringBuffer();
  for (var i = 0; i < times; ++i) {
    sb.write(ch);
  }
  return sb.toString();
}
