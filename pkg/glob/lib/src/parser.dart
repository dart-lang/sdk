// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library glob.single_component;

import 'package:path/path.dart' as p;
import 'package:string_scanner/string_scanner.dart';

import 'ast.dart';
import 'utils.dart';

const _HYPHEN = 0x2D;
const _SLASH = 0x2F;

/// A parser for globs.
class Parser {
  /// The scanner used to scan the source.
  final StringScanner _scanner;

  /// The path context for the glob.
  final p.Context _context;

  Parser(String component, this._context)
      : _scanner = new StringScanner(component);

  /// Parses an entire glob.
  SequenceNode parse() => _parseSequence();

  /// Parses a [SequenceNode].
  ///
  /// If [inOptions] is true, this is parsing within an [OptionsNode].
  SequenceNode _parseSequence({bool inOptions: false}) {
    var nodes = [];

    if (_scanner.isDone) {
      _scanner.error('expected a glob.', position: 0, length: 0);
    }

    while (!_scanner.isDone) {
      if (inOptions && (_scanner.matches(',') || _scanner.matches('}'))) break;
      nodes.add(_parseNode(inOptions: inOptions));
    }

    return new SequenceNode(nodes);
  }

  /// Parses an [AstNode].
  ///
  /// If [inOptions] is true, this is parsing within an [OptionsNode].
  AstNode _parseNode({bool inOptions: false}) {
    var star = _parseStar();
    if (star != null) return star;

    var anyChar = _parseAnyChar();
    if (anyChar != null) return anyChar;

    var range = _parseRange();
    if (range != null) return range;

    var options = _parseOptions();
    if (options != null) return options;

    return _parseLiteral(inOptions: inOptions);
  }

  /// Tries to parse a [StarNode] or a [DoubleStarNode].
  ///
  /// Returns `null` if there's not one to parse.
  AstNode _parseStar() {
    if (!_scanner.scan('*')) return null;
    return _scanner.scan('*') ? new DoubleStarNode(_context) : new StarNode();
  }

  /// Tries to parse an [AnyCharNode].
  ///
  /// Returns `null` if there's not one to parse.
  AstNode _parseAnyChar() {
    if (!_scanner.scan('?')) return null;
    return new AnyCharNode();
  }

  /// Tries to parse an [RangeNode].
  ///
  /// Returns `null` if there's not one to parse.
  AstNode _parseRange() {
    if (!_scanner.scan('[')) return null;
    if (_scanner.matches(']')) _scanner.error('unexpected "]".');
    var negated = _scanner.scan('!') || _scanner.scan('^');

    readRangeChar() {
      var char = _scanner.readChar();
      if (negated || char != _SLASH) return char;
      _scanner.error('"/" may not be used in a range.',
          position: _scanner.position - 1);
    }

    var ranges = [];
    while (!_scanner.scan(']')) {
      var start = _scanner.position;
      // Allow a backslash to escape a character.
      _scanner.scan('\\');
      var char = readRangeChar();

      if (_scanner.scan('-')) {
        if (_scanner.matches(']')) {
          ranges.add(new Range.singleton(char));
          ranges.add(new Range.singleton(_HYPHEN));
          continue;
        }

        // Allow a backslash to escape a character.
        _scanner.scan('\\');

        var end = readRangeChar();

        if (end < char) {
          _scanner.error("Range out of order.",
              position: start,
              length: _scanner.position - start);
        }
        ranges.add(new Range(char, end));
      } else {
        ranges.add(new Range.singleton(char));
      }
    }

    return new RangeNode(ranges, negated: negated);
  }

  /// Tries to parse an [OptionsNode].
  ///
  /// Returns `null` if there's not one to parse.
  AstNode _parseOptions() {
    if (!_scanner.scan('{')) return null;
    if (_scanner.matches('}')) _scanner.error('unexpected "}".');

    var options = [];
    do {
      options.add(_parseSequence(inOptions: true));
    } while (_scanner.scan(','));

    // Don't allow single-option blocks.
    if (options.length == 1) _scanner.expect(',');
    _scanner.expect('}');

    return new OptionsNode(options);
  }

  /// Parses a [LiteralNode].
  AstNode _parseLiteral({bool inOptions: false}) {
    // If we're in an options block, we want to stop parsing as soon as we hit a
    // comma. Otherwise, commas are fair game for literals.
    var regExp = new RegExp(
        inOptions ? r'[^*{[?\\}\],()]*' : r'[^*{[?\\}\]()]*');

    _scanner.scan(regExp);
    var buffer = new StringBuffer()..write(_scanner.lastMatch[0]);

    while (_scanner.scan('\\')) {
      buffer.writeCharCode(_scanner.readChar());
      _scanner.scan(regExp);
      buffer.write(_scanner.lastMatch[0]);
    }

    for (var char in const [']', '(', ')']) {
      if (_scanner.matches(char)) _scanner.error('unexpected "$char"');
    }
    if (!inOptions && _scanner.matches('}')) _scanner.error('unexpected "}"');

    return new LiteralNode(buffer.toString(), _context);
  }
}
