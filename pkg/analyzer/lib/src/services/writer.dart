// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_writer;

import 'dart:math' as math;

class Line {

  final List<LineToken> tokens = <LineToken>[];
  final bool useTabs;
  final int spacesPerIndent;
  final int indentLevel;
  final LinePrinter printer;

  Line({this.indentLevel: 0, this.useTabs: false, this.spacesPerIndent: 2,
      this.printer: const SimpleLinePrinter()}) {
    if (indentLevel > 0) {
      indent(indentLevel);
    }
  }

  void addSpace() {
    addSpaces(1);
  }

  void addSpaces(int n, {breakWeight: DEFAULT_SPACE_WEIGHT}) {
    tokens.add(new SpaceToken(n, breakWeight: breakWeight));
  }

  void addToken(LineToken token) {
    tokens.add(token);
  }

  void clear() {
    tokens.clear();
  }

  bool isEmpty() => tokens.isEmpty;

  bool isWhitespace() => tokens.every(
      (tok) => tok is SpaceToken || tok is TabToken);

  void indent(int n) {
    tokens.insert(0,
        useTabs ? new TabToken(n) : new SpaceToken(n * spacesPerIndent));
  }

  String toString() => printer.printLine(this);

}


/// Base class for line printers
abstract class LinePrinter {

  const LinePrinter();

  /// Convert this [line] to a [String] representation.
  String printLine(Line line);
}


typedef String Indenter(int n);


/// A simple line breaking [LinePrinter]
class SimpleLineBreaker extends LinePrinter {

  static final NO_OP_INDENTER = (n) => '';

  final chunks = <Chunk>[];
  final int maxLength;
  Indenter indenter;

  SimpleLineBreaker(this.maxLength, [this.indenter]) {
    if (indenter == null) {
      indenter = NO_OP_INDENTER;
    }
  }

  String printLine(Line line) {
    var buf = new StringBuffer();
    var chunks = breakLine(line);
    for (var i = 0; i < chunks.length; ++i) {
      var chunk = chunks[i];
      if (i > 0) {
        buf.write(indent(chunk, chunk.indent));
      } else {
        buf.write(chunk);
      }
    }
    return buf.toString();
  }

  String indent(Chunk chunk, int level) {
    return '\n' + indenter(level) + chunk.toString();
  }

  List<Chunk> breakLine(Line line) {
    List<LineToken> tokens = preprocess(line.tokens);
    List<Chunk> chunks = <Chunk>[new Chunk(line.indentLevel, maxLength, tokens)];
    // try SINGLE_SPACE_WEIGHT
    {
      Chunk chunk = chunks[0];
      if (chunk.length > maxLength) {
        for (int i = 0; i < tokens.length; i++) {
          LineToken token = tokens[i];
          if (token is SpaceToken && token.breakWeight == SINGLE_SPACE_WEIGHT) {
            var beforeChunk = chunk.subChunk(chunk.indent, 0, i);
            var restChunk = chunk.subChunk(chunk.indent + 2, i + 1);
            // check if 'init' in 'var v = init;' fits a line
            if (restChunk.length < maxLength) {
              return [beforeChunk, restChunk];
            }
            // check if 'var v = method(' in 'var v = method(args)' does not fit
            int weight = chunk.findMinSpaceWeight();
            if (chunk.getLengthToSpaceWithWeight(weight) > maxLength) {
              chunks = [beforeChunk, restChunk];
            }
            // done anyway
            break;
          }
        }
      }
    }
    // other spaces
    while (true) {
      List<Chunk> newChunks = <Chunk>[];
      bool hasChanges = false;
      for (Chunk chunk in chunks) {
        tokens = chunk.tokens;
        if (chunk.length > maxLength) {
          if (chunk.hasAnySpace()) {
            int weight = chunk.findMinSpaceWeight();
            int newIndent = chunk.indent;
            if (weight == DEFAULT_SPACE_WEIGHT) {
              int start = 0;
              int length = 0;
              for (int i = 0; i < tokens.length; i++) {
                LineToken token = tokens[i];
                if (token is SpaceToken && token.breakWeight == weight &&
                    i < tokens.length - 1) {
                  LineToken nextToken = tokens[i + 1];
                  if (length + token.length + nextToken.length > maxLength) {
                    newChunks.add(chunk.subChunk(newIndent, start, i));
                    newIndent = chunk.indent + 2;
                    start = i + 1;
                    length = 0;
                    continue;
                  }
                }
                length += token.length;
              }
              if (start < tokens.length) {
                newChunks.add(chunk.subChunk(newIndent, start));
              }
            } else {
              List<LineToken> part = [];
              int start = 0;
              for (int i = 0; i < tokens.length; i++) {
                LineToken token = tokens[i];
                if (token is SpaceToken && token.breakWeight == weight) {
                  newChunks.add(chunk.subChunk(newIndent, start, i));
                  newIndent = chunk.indent + 2;
                  start = i + 1;
                }
              }
              if (start < tokens.length) {
                newChunks.add(chunk.subChunk(newIndent, start));
              }
            }
          } else {
            newChunks.add(chunk);
          }
        } else {
          newChunks.add(chunk);
        }
        if (newChunks.length > chunks.length) {
          hasChanges = true;
        }
      }
      if (!hasChanges) {
        break;
      }
      chunks = newChunks;
    }
    return chunks;
  }

  static List<LineToken> preprocess(List<LineToken> tok) {

    var tokens = <LineToken>[];
    var curr;

    tok.forEach((token) {
      if (token is! SpaceToken) {
        if (curr == null) {
          curr = token;
        } else {
          curr = merge(curr, token);
        }
      } else {
        if (isNonbreaking(token)) {
          curr = merge(curr, token);
        } else {
          if (curr != null) {
            tokens.add(curr);
            curr = null;
          }
          tokens.add(token);
        }
      }
    });

    if (curr != null) {
      tokens.add(curr);
    }

    return tokens;
  }

  static bool isNonbreaking(SpaceToken token) =>
      token.breakWeight == UNBREAKABLE_SPACE_WEIGHT;

  static LineToken merge(LineToken first, LineToken second) =>
      new LineToken(first.value + second.value);
}

/// Test if this [string] contains only whitespace characters
bool isWhitespace(String string) => string.codeUnits.every(
      (c) => c == 0x09 || c == 0x20 || c == 0x0A || c == 0x0D);

/// Special token indicating a line start
final LINE_START = new SpaceToken(0);

const DEFAULT_SPACE_WEIGHT = UNBREAKABLE_SPACE_WEIGHT - 1;
/// The weight of a space after '=' in variable declaration or assignment
const SINGLE_SPACE_WEIGHT = UNBREAKABLE_SPACE_WEIGHT - 2;
const UNBREAKABLE_SPACE_WEIGHT = 100000000;

/// Simple non-breaking printer
class SimpleLinePrinter extends LinePrinter {

  const SimpleLinePrinter();

  String printLine(Line line) {
    var buffer = new StringBuffer();
    line.tokens.forEach((tok) => buffer.write(tok.toString()));
    return buffer.toString();
  }

}


/// Describes a piece of text in a [Line].
abstract class LineText {
  int get length;
}


/// A working piece of text used in calculating line breaks
class Chunk {
  final int indent;
  final int maxLength;
  final List<LineToken> tokens = <LineToken>[];

  Chunk(this.indent, this.maxLength, [List<LineToken> tokens]) {
    this.tokens.addAll(tokens);
  }

  int get length {
    return tokens.fold(0, (len, token) => len + token.length);
  }

  int getLengthToSpaceWithWeight(int weight) {
    int length = 0;
    for (LineToken token in tokens) {
      if (token is SpaceToken && token.breakWeight == weight) {
        break;
      }
      length += token.length;
    }
    return length;
  }

  bool fits(LineToken a, LineToken b) {
    return length + a.length + a.length <= maxLength;
  }

  void add(LineToken token) {
    tokens.add(token);
  }

  bool hasInitializerSpace() {
    return tokens.any((token) {
      return token is SpaceToken && token.breakWeight == SINGLE_SPACE_WEIGHT;
    });
  }

  bool hasAnySpace() {
    return tokens.any((token) => token is SpaceToken);
  }

  int findMinSpaceWeight() {
    int minWeight = UNBREAKABLE_SPACE_WEIGHT;
    for (var token in tokens) {
      if (token is SpaceToken) {
        minWeight = math.min(minWeight, token.breakWeight);
      }
    }
    return minWeight;
  }

  Chunk subChunk(int indentLevel, int start, [int end]) {
    List<LineToken> subTokens = tokens.sublist(start, end);
    return new Chunk(indentLevel, maxLength, subTokens);
  }

  String toString() => tokens.join();
}


class LineToken implements LineText {

  final String value;

  LineToken(this.value);

  String toString() => value;

  int get length => lengthLessNewlines(value);

  int lengthLessNewlines(String str) =>
      str.endsWith('\n') ? str.length - 1 : str.length;

}


class SpaceToken extends LineToken {

  final int breakWeight;

  SpaceToken(int n, {this.breakWeight: DEFAULT_SPACE_WEIGHT}) :
      super(getSpaces(n));
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
  final int spacesPerIndent;
  final bool useTabs;

  LinePrinter linePrinter;
  LineToken _lastToken;

  SourceWriter({this.indentCount: 0, this.lineSeparator: NEW_LINE,
      this.useTabs: false, this.spacesPerIndent: 2, int maxLineLength: 80}) {
    if (maxLineLength > 0) {
      linePrinter = new SimpleLineBreaker(maxLineLength, (n) =>
          getIndentString(n, useTabs: useTabs, spacesPerIndent: spacesPerIndent));
    } else {
      linePrinter = new SimpleLinePrinter();
    }
    currentLine = newLine();
  }

  LineToken get lastToken => _lastToken;

  _addToken(LineToken token) {
    _lastToken = token;
    currentLine.addToken(token);
  }

  void indent() {
    ++indentCount;
    // Rather than fiddle with deletions/insertions just start fresh
    if (currentLine.isWhitespace()) {
      currentLine = newLine();
    }
  }

  void newline() {
    if (currentLine.isWhitespace()) {
      currentLine.tokens.clear();
    }
    _addToken(new NewlineToken(this.lineSeparator));
    buffer.write(currentLine.toString());
    currentLine = newLine();
  }

  void newlines(int num) {
    while (num-- > 0) {
      newline();
    }
  }

  void write(String string) {
    var lines = string.split(lineSeparator);
    var length = lines.length;
    for (int i = 0; i < length; i++) {
      var line = lines[i];
      _addToken(new LineToken(line));
      if (i != length - 1) {
        newline();
        // no indentation for multi-line strings
        currentLine.clear();
      }
    }
  }

  void writeln(String s) {
    write(s);
    newline();
  }

  void space() {
    spaces(1);
  }

  void spaces(n, {breakWeight: DEFAULT_SPACE_WEIGHT}) {
    currentLine.addSpaces(n, breakWeight: breakWeight);
  }

  void unindent() {
    --indentCount;
    // Rather than fiddle with deletions/insertions just start fresh
    if (currentLine.isWhitespace()) {
      currentLine = newLine();
    }
  }

  Line newLine() => new Line(indentLevel: indentCount, useTabs: useTabs,
      spacesPerIndent: spacesPerIndent, printer: linePrinter);

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


String getIndentString(int indentWidth, {bool useTabs: false,
  int spacesPerIndent: 2}) => useTabs ? getTabs(indentWidth) :
    getSpaces(indentWidth * spacesPerIndent);

String getSpaces(int n) => n < SPACES.length ? SPACES[n] : repeat(' ', n);

String getTabs(int n) => n < TABS.length ? TABS[n] : repeat('\t', n);

String repeat(String ch, int times) {
  var sb = new StringBuffer();
  for (var i = 0; i < times; ++i) {
    sb.write(ch);
  }
  return sb.toString();
}
