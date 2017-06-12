// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of layout;

/**
 * Base class for simple recursive descent parsers.
 * Handles the lower level stuff, i.e. what a scanner/tokenizer would do.
 */
class _Parser {
  static const WHITESPACE = ' \r\n\t';

  // TODO(jmesserly): shouldn't need this optimization, but dart_json parser
  // found that they needed this.
  static const A_BIG = 65; // 'A'.codeUnitAt(0)
  static const Z_BIG = 90; // 'Z'.codeUnitAt(0)
  static const A_SMALL = 97; // 'a'.codeUnitAt(0)
  static const Z_SMALL = 122; // 'z'.codeUnitAt(0)
  static const TAB = 9; // '\t'.codeUnitAt(0)
  static const NEW_LINE = 10; // '\n'.codeUnitAt(0)
  static const LINE_FEED = 13; // '\r'.codeUnitAt(0)
  static const SPACE = 32; // ' '.codeUnitAt(0)
  static const ZERO = 48; // '0'.codeUnitAt(0)
  static const NINE = 57; // '9'.codeUnitAt(0)
  static const DOT = 46; // '.'.codeUnitAt(0)
  static const R_PAREN = 41; // ')'.codeUnitAt(0)

  final String _src;
  int _offset;

  // TODO(jmesserly): should be this._offset = 0, see bug 5332175.
  _Parser(this._src) : _offset = 0;

  // TODO(jmesserly): these should exist in the standard lib.
  // I took this from dart_json.dart
  static bool _isWhitespace(int c) {
    switch (c) {
      case SPACE:
      case TAB:
      case NEW_LINE:
      case LINE_FEED:
        return true;
    }
    return false;
  }

  static bool _isDigit(int c) {
    return (ZERO <= c) && (c <= NINE);
  }

  static bool _isLetter(int c) {
    return (A_SMALL <= c) && (c <= Z_SMALL) || (A_BIG <= c) && (c <= Z_BIG);
  }

  void _error(String msg) {
    throw new SyntaxErrorException(msg, _src, _offset);
  }

  int get length => _src.length;

  int get remaining => _src.length - _offset;

  int _peekChar() => _src.codeUnitAt(_offset);

  bool get endOfInput => _offset >= _src.length;

  bool _maybeEatWhitespace() {
    int start = _offset;
    while (_offset < length && _isWhitespace(_peekChar())) {
      _offset++;
    }
    return _offset != start;
  }

  bool _maybeEatMultiLineComment() {
    if (_maybeEat('/*', /*eatWhitespace:*/ false)) {
      while (!_maybeEat('*/', /*eatWhitespace:*/ false)) {
        if (_offset >= length) {
          _error('expected */');
        }
        _offset++;
      }
      return true;
    }
    return false;
  }

  void _maybeEatWhitespaceOrComments() {
    while (_maybeEatWhitespace() || _maybeEatMultiLineComment()) {}
  }

  void _eatEnd() {
    _maybeEatWhitespaceOrComments();
    if (!endOfInput) {
      _error('expected end of input');
    }
  }

  bool _maybeEat(String value, [bool eatWhitespace = true]) {
    if (eatWhitespace) {
      _maybeEatWhitespaceOrComments();
    }
    if (remaining < value.length) {
      return false;
    }
    for (int i = 0; i < value.length; i++) {
      if (_src[_offset + i] != value[i]) {
        return false;
      }
    }

    // If we're eating something that's like a word, make sure
    // it's not followed by more characters.
    // This is ugly. Proper tokenization would make this cleaner.
    if (_isLetter(value.codeUnitAt(value.length - 1))) {
      int i = _offset + value.length;
      if (i < _src.length && _isLetter(_src.codeUnitAt(i))) {
        return false;
      }
    }

    _offset += value.length;
    return true;
  }

  void _eat(String value, [bool eatWhitespace = true]) {
    if (!_maybeEat(value)) {
      _error('expected "$value"');
    }
  }

  String _maybeEatString() {
    // TODO(jmesserly): make this match CSS string parsing
    String quote = "'";
    if (!_maybeEat(quote)) {
      quote = '"';
      if (!_maybeEat(quote)) {
        return null;
      }
    }

    bool hasEscape = false;
    int start = _offset;
    while (!_maybeEat(quote)) {
      if (endOfInput) {
        _error('expected "$quote"');
      }
      if (_maybeEat('\\')) {
        hasEscape = true;
      }
      _offset++;
    }
    String result = _src.substring(start, _offset - 1);
    if (hasEscape) {
      // TODO(jmesserly): more escape sequences
      result = result.replaceFirst('\\', '');
    }
    return result;
  }

  /** Eats something like a keyword. */
  String _eatWord() {
    int start = _offset;
    while (_offset < length && _isLetter(_peekChar())) {
      _offset++;
    }
    return _src.substring(start, _offset);
  }

  /** Eats an integer. */
  int _maybeEatInt() {
    int start = _offset;
    bool dot = false;
    while (_offset < length && _isDigit(_peekChar())) {
      _offset++;
    }

    if (start == _offset) {
      return null;
    }

    return int.parse(_src.substring(start, _offset));
  }

  /** Eats an integer. */
  int _eatInt() {
    int result = _maybeEatInt();
    if (result == null) {
      _error('expected positive integer');
    }
    return result;
  }

  /** Eats something like a positive decimal: 12.345. */
  num _eatDouble() {
    int start = _offset;
    bool dot = false;
    while (_offset < length) {
      int c = _peekChar();
      if (!_isDigit(c)) {
        if (c == DOT && !dot) {
          dot = true;
        } else {
          // Not a digit or decimal seperator
          break;
        }
      }
      _offset++;
    }

    if (start == _offset) {
      _error('expected positive decimal number');
    }

    return double.parse(_src.substring(start, _offset));
  }
}

/** Parses a grid template. */
class _GridTemplateParser extends _Parser {
  _GridTemplateParser._internal(String src) : super(src);

  /** Parses the grid-rows and grid-columns CSS properties into object form. */
  static GridTemplate parse(String str) {
    if (str == null) return null;
    final p = new _GridTemplateParser._internal(str);
    final result = p._parseTemplate();
    p._eatEnd();
    return result;
  }

  /** Parses a grid-cell value. */
  static String parseCell(String str) {
    if (str == null) return null;
    final p = new _GridTemplateParser._internal(str);
    final result = p._maybeEatString();
    p._eatEnd();
    return result;
  }

  // => <string>+ | 'none'
  GridTemplate _parseTemplate() {
    if (_maybeEat('none')) {
      return null;
    }
    final rows = new List<String>();
    String row;
    while ((row = _maybeEatString()) != null) {
      rows.add(row);
    }
    if (rows.length == 0) {
      _error('expected at least one cell, or "none"');
    }
    return new GridTemplate(rows);
  }
}

/** Parses a grid-row or grid-column */
class _GridItemParser extends _Parser {
  _GridItemParser._internal(String src) : super(src);

  /** Parses the grid-rows and grid-columns CSS properties into object form. */
  static _GridLocation parse(String cell, GridTrackList list) {
    if (cell == null) return null;
    final p = new _GridItemParser._internal(cell);
    final result = p._parseTrack(list);
    p._eatEnd();
    return result;
  }

  // [ [ <integer> | <string> | 'start' | 'end' ]
  //   [ <integer> | <string> | 'start' | 'end' ]? ]
  // | 'auto'
  _GridLocation _parseTrack(GridTrackList list) {
    if (_maybeEat('auto')) {
      return null;
    }
    int start = _maybeParseLine(list);
    if (start == null) {
      _error('expected row/column number or name');
    }
    int end = _maybeParseLine(list);
    int span = null;
    if (end != null) {
      span = end - start;
      if (span <= 0) {
        _error('expected row/column span to be a positive integer');
      }
    }
    return new _GridLocation(start, span);
  }

  // [ <integer> | <string> | 'start' | 'end' ]
  int _maybeParseLine(GridTrackList list) {
    if (_maybeEat('start')) {
      return 1;
    } else if (_maybeEat('end')) {
      // The end is exclusive and 1-based, so return one past the size of the
      // track list.
      // TODO(jmesserly): this won't interact properly with implicit
      // rows/columns. Instead it will snap to the number of tracks at the point
      // where it is evaluated.
      return list.tracks.length + 1;
    }

    String name = _maybeEatString();
    if (name == null) {
      return _maybeEatInt();
    } else {
      int edge = list.lineNames[name];
      if (edge == null) {
        _error('row/column name "$name" not found in the parent\'s '
            ' grid-row/grid-columns properties');
      }
      return edge;
    }
  }
}

/**
 * Parses grid-rows and grid-column properties, see:
 * [http://dev.w3.org/csswg/css3-grid-align/#grid-columns-and-rows-properties]
 * This is kept as a recursive descent parser for simplicity.
 */
// TODO(jmesserly): implement missing features from the spec. Mainly around
// CSS units, support for all escape sequences, etc.
class _GridTrackParser extends _Parser {
  final List<GridTrack> _tracks;
  final Map<String, int> _lineNames;

  _GridTrackParser._internal(String src)
      : super(src),
        _tracks = new List<GridTrack>(),
        _lineNames = new Map<String, int>();

  /** Parses the grid-rows and grid-columns CSS properties into object form. */
  static GridTrackList parse(String str) {
    if (str == null) return null;
    final p = new _GridTrackParser._internal(str);
    final result = p._parseTrackList();
    p._eatEnd();
    return result;
  }

  /**
   * Parses the grid-row-sizing and grid-column-sizing CSS properties into
   * object form.
   */
  static TrackSizing parseTrackSizing(String str) {
    if (str == null) str = 'auto';
    final p = new _GridTrackParser._internal(str);
    final result = p._parseTrackMinmax();
    p._eatEnd();
    return result;
  }

  // <track-list> => [ [ <string> ]* <track-group> [ <string> ]* ]+ | 'none'
  GridTrackList _parseTrackList() {
    if (_maybeEat('none')) {
      return null;
    }
    _parseTrackListHelper();
    return new GridTrackList(_tracks, _lineNames);
  }

  /** Code shared by _parseTrackList and _parseTrackGroup */
  void _parseTrackListHelper([List<GridTrack> resultTracks = null]) {
    _maybeEatWhitespace();
    while (!endOfInput) {
      String name;
      while ((name = _maybeEatString()) != null) {
        _lineNames[name] = _tracks.length + 1; // should be 1-based
      }

      _maybeEatWhitespace();
      if (endOfInput) {
        return;
      }

      if (resultTracks != null) {
        if (_peekChar() == _Parser.R_PAREN) {
          return;
        }
        resultTracks.add(new GridTrack(_parseTrackMinmax()));
      } else {
        _parseTrackGroup();
      }

      _maybeEatWhitespace();
    }
  }

  // <track-group> => [ '(' [ [ <string> ]* <track-minmax> [ <string> ]* ]+ ')'
  //                     [ '[' <positive-number> ']' ]? ]
  //                  | <track-minmax>
  void _parseTrackGroup() {
    if (_maybeEat('(')) {
      final tracks = new List<GridTrack>();
      _parseTrackListHelper(tracks);
      _eat(')');
      if (_maybeEat('[')) {
        num expand = _eatInt();
        _eat(']');

        if (expand <= 0) {
          _error('expected positive number');
        }

        // Repeat the track definition (but not the names) the specified number
        // of times. See:
        // http://dev.w3.org/csswg/css3-grid-align/#grid-repeating-columns-and-rows
        for (int i = 0; i < expand; i++) {
          for (GridTrack t in tracks) {
            _tracks.add(t.clone());
          }
        }
      }
    } else {
      _tracks.add(new GridTrack(_parseTrackMinmax()));
    }
  }

  // <track-minmax> => 'minmax(' <track-breadth> ',' <track-breadth> ')'
  //                   | 'auto' | <track-breadth>
  TrackSizing _parseTrackMinmax() {
    if (_maybeEat('auto') || _maybeEat('fit-content')) {
      return const TrackSizing.auto();
    }
    if (_maybeEat('minmax(')) {
      final min = _parseTrackBreadth();
      _eat(',');
      final max = _parseTrackBreadth();
      _eat(')');
      return new TrackSizing(min, max);
    } else {
      final breadth = _parseTrackBreadth();
      return new TrackSizing(breadth, breadth);
    }
  }

  // <track-breadth> => <length> | <percentage> | <fraction>
  //                    | 'min-content' | 'max-content'
  SizingFunction _parseTrackBreadth() {
    if (_maybeEat('min-content')) {
      return const MinContentSizing();
    } else if (_maybeEat('max-content')) {
      return const MaxContentSizing();
    }

    num value = _eatDouble();

    String units;
    if (_maybeEat('%')) {
      units = '%';
    } else {
      units = _eatWord();
    }

    if (units == 'fr') {
      return new FractionSizing(value);
    } else {
      return new FixedSizing(value, units);
    }
  }
}

/**
 * Exception thrown because the grid style properties had incorrect values.
 */
class SyntaxErrorException implements Exception {
  final String _message;
  final int _offset;
  final String _source;

  const SyntaxErrorException(this._message, this._source, this._offset);

  String toString() {
    String location;
    if (_offset < _source.length) {
      location = 'location: ${_source.substring(_offset)}';
    } else {
      location = 'end of input';
    }
    return 'SyntaxErrorException: $_message at $location';
  }
}
