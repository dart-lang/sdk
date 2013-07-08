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

  addSpace() {
    addSpaces(1);
  }

  addSpaces(int n) {
    if (n > 0) {
      tokens.add(new SpaceToken(n));
    }
  }

  addToken(LineToken token) {
    tokens.add(token);
  }

  _indent(int n) {
    tokens.add(useTabs ? new TabToken(n) : new SpaceToken(n * spacesPerIndent));
  }

  String toString() {
    var buffer = new StringBuffer();
    for (var tok in tokens) {
      buffer.write(tok.toString());
    }
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
  Line currentLine = new Line();

  final String lineSeparator;
  int indentCount = 0;

  SourceWriter({int initialIndent: 0, this.lineSeparator: '\n'}) :
    indentCount = initialIndent;

  indent() {
    ++indentCount;
  }

  unindent() {
    --indentCount;
  }

  print(x) {
    currentLine.addToken(new LineToken(x));
  }

  newline() {
    currentLine.addToken(new NewlineToken(this.lineSeparator));
    buffer.write(currentLine.toString());
    currentLine = new Line(indent: indentCount);
  }

  space() {
    spaces(1);
  }

  spaces(n) {
    currentLine.addSpaces(n);
  }

  println(String s) {
    print(s);
    newline();
  }

  String toString() {
    var source = new StringBuffer(buffer.toString());
    source.write(currentLine);
    return source.toString();
  }
}


const SPACE = ' ';
final SPACES = [
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
final TABS = [
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
