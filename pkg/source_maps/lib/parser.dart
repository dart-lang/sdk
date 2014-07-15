// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Contains the top-level function to parse source maps version 3.
library source_maps.parser;

import 'dart:collection';
import 'dart:convert';

import 'builder.dart' as builder;
import 'span.dart';
import 'src/utils.dart';
import 'src/vlq.dart';

/// Parses a source map directly from a json string.
// TODO(sigmund): evaluate whether other maps should have the json parsed, or
// the string represenation.
// TODO(tjblasi): Ignore the first line of [jsonMap] if the JSON safety string
// `)]}'` begins the string representation of the map.
Mapping parse(String jsonMap, {Map<String, Map> otherMaps}) =>
  parseJson(JSON.decode(jsonMap), otherMaps: otherMaps);

/// Parses a source map directly from a json map object.
Mapping parseJson(Map map, {Map<String, Map> otherMaps}) {
  if (map['version'] != 3) {
    throw new ArgumentError(
        'unexpected source map version: ${map["version"]}. '
        'Only version 3 is supported.');
  }

  if (!map.containsKey('file')) {
    print('warning: missing "file" entry in source map');
  }

  if (map.containsKey('sections')) {
    if (map.containsKey('mappings') || map.containsKey('sources') ||
        map.containsKey('names')) {
      throw new FormatException('map containing "sections" '
          'cannot contain "mappings", "sources", or "names".');
    }
    return new MultiSectionMapping.fromJson(map['sections'], otherMaps);
  }
  return new SingleMapping.fromJson(map);
}


/// A mapping parsed out of a source map.
abstract class Mapping {
  Span spanFor(int line, int column, {Map<String, SourceFile> files});

  Span spanForLocation(Location loc, {Map<String, SourceFile> files}) {
    return spanFor(loc.line, loc.column, files: files);
  }
}

/// A meta-level map containing sections.
class MultiSectionMapping extends Mapping {
  /// For each section, the start line offset.
  final List<int> _lineStart = <int>[];

  /// For each section, the start column offset.
  final List<int> _columnStart = <int>[];

  /// For each section, the actual source map information, which is not adjusted
  /// for offsets.
  final List<Mapping> _maps = <Mapping>[];

  /// Creates a section mapping from json.
  MultiSectionMapping.fromJson(List sections, Map<String, Map> otherMaps) {
    for (var section in sections) {
      var offset = section['offset'];
      if (offset == null) throw new FormatException('section missing offset');

      var line = section['offset']['line'];
      if (line == null) throw new FormatException('offset missing line');

      var column = section['offset']['column'];
      if (column == null) throw new FormatException('offset missing column');

      _lineStart.add(line);
      _columnStart.add(column);

      var url = section['url'];
      var map = section['map'];

      if (url != null && map != null) {
        throw new FormatException("section can't use both url and map entries");
      } else if (url != null) {
        if (otherMaps == null || otherMaps[url] == null) {
          throw new FormatException(
              'section contains refers to $url, but no map was '
              'given for it. Make sure a map is passed in "otherMaps"');
        }
        _maps.add(parseJson(otherMaps[url], otherMaps: otherMaps));
      } else if (map != null) {
        _maps.add(parseJson(map, otherMaps: otherMaps));
      } else {
        throw new FormatException('section missing url or map');
      }
    }
    if (_lineStart.length == 0) {
      throw new FormatException('expected at least one section');
    }
  }

  int _indexFor(line, column) {
    for(int i = 0; i < _lineStart.length; i++) {
      if (line < _lineStart[i]) return i - 1;
      if (line == _lineStart[i] && column < _columnStart[i]) return i - 1;
    }
    return _lineStart.length - 1;
  }

  Span spanFor(int line, int column, {Map<String, SourceFile> files}) {
    int index = _indexFor(line, column);
    return _maps[index].spanFor(
        line - _lineStart[index], column - _columnStart[index], files: files);
  }

  String toString() {
    var buff = new StringBuffer("$runtimeType : [");
    for (int i = 0; i < _lineStart.length; i++) {
      buff..write('(')
          ..write(_lineStart[i])
          ..write(',')
          ..write(_columnStart[i])
          ..write(':')
          ..write(_maps[i])
          ..write(')');
    }
    buff.write(']');
    return buff.toString();
  }
}

/// A map containing direct source mappings.
class SingleMapping extends Mapping {
  /// Url of the target file.
  final String targetUrl;

  /// Source urls used in the mapping, indexed by id.
  final List<String> urls;

  /// Source names used in the mapping, indexed by id.
  final List<String> names;

  /// Entries indicating the beginning of each span.
  final List<TargetLineEntry> lines;

  /// Source root appended to the start of all entries in [urls].
  String sourceRoot = null;

  SingleMapping._internal(this.targetUrl, this.urls, this.names, this.lines);

  factory SingleMapping.fromEntries(
      Iterable<builder.Entry> entries, [String fileUrl]) {
    // The entries needs to be sorted by the target offsets.
    var sourceEntries = new List.from(entries)..sort();
    var lines = <TargetLineEntry>[];

    // Indices associated with file urls that will be part of the source map. We
    // use a linked hash-map so that `_urls.keys[_urls[u]] == u`
    var urls = new LinkedHashMap<String, int>();

    // Indices associated with identifiers that will be part of the source map.
    // We use a linked hash-map so that `_names.keys[_names[n]] == n`
    var names = new LinkedHashMap<String, int>();

    var lineNum;
    var targetEntries;
    for (var sourceEntry in sourceEntries) {
      if (lineNum == null || sourceEntry.target.line > lineNum) {
        lineNum = sourceEntry.target.line;
        targetEntries = <TargetEntry>[];
        lines.add(new TargetLineEntry(lineNum, targetEntries));
      }

      if (sourceEntry.source == null) {
        targetEntries.add(new TargetEntry(sourceEntry.target.column));
      } else {
        var urlId = urls.putIfAbsent(
            sourceEntry.source.sourceUrl, () => urls.length);
        var srcNameId = sourceEntry.identifierName == null ? null :
            names.putIfAbsent(sourceEntry.identifierName, () => names.length);
        targetEntries.add(new TargetEntry(
            sourceEntry.target.column,
            urlId,
            sourceEntry.source.line,
            sourceEntry.source.column,
            srcNameId));
      }
    }
    return new SingleMapping._internal(
        fileUrl, urls.keys.toList(), names.keys.toList(), lines);
  }

  SingleMapping.fromJson(Map map)
      : targetUrl = map['file'],
        urls = map['sources'],
        names = map['names'],
        sourceRoot = map['sourceRoot'],
        lines = <TargetLineEntry>[] {
    int line = 0;
    int column = 0;
    int srcUrlId = 0;
    int srcLine = 0;
    int srcColumn = 0;
    int srcNameId = 0;
    var tokenizer = new _MappingTokenizer(map['mappings']);
    var entries = <TargetEntry>[];

    while (tokenizer.hasTokens) {
      if (tokenizer.nextKind.isNewLine) {
        if (!entries.isEmpty) {
          lines.add(new TargetLineEntry(line, entries));
          entries = <TargetEntry>[];
        }
        line++;
        column = 0;
        tokenizer._consumeNewLine();
        continue;
      }

      // Decode the next entry, using the previous encountered values to
      // decode the relative values.
      //
      // We expect 1, 4, or 5 values. If present, values are expected in the
      // following order:
      //   0: the starting column in the current line of the generated file
      //   1: the id of the original source file
      //   2: the starting line in the original source
      //   3: the starting column in the original source
      //   4: the id of the original symbol name
      // The values are relative to the previous encountered values.
      if (tokenizer.nextKind.isNewSegment) throw _segmentError(0, line);
      column += tokenizer._consumeValue();
      if (!tokenizer.nextKind.isValue) {
        entries.add(new TargetEntry(column));
      } else {
        srcUrlId += tokenizer._consumeValue();
        if (srcUrlId >= urls.length) {
          throw new StateError(
              'Invalid source url id. $targetUrl, $line, $srcUrlId');
        }
        if (!tokenizer.nextKind.isValue) throw _segmentError(2, line);
        srcLine += tokenizer._consumeValue();
        if (!tokenizer.nextKind.isValue) throw _segmentError(3, line);
        srcColumn += tokenizer._consumeValue();
        if (!tokenizer.nextKind.isValue) {
          entries.add(new TargetEntry(column, srcUrlId, srcLine, srcColumn));
        } else {
          srcNameId += tokenizer._consumeValue();
          if (srcNameId >= names.length) {
            throw new StateError(
                'Invalid name id: $targetUrl, $line, $srcNameId');
          }
          entries.add(new TargetEntry(column, srcUrlId, srcLine, srcColumn,
              srcNameId));
        }
      }
      if (tokenizer.nextKind.isNewSegment) tokenizer._consumeNewSegment();
    }
    if (!entries.isEmpty) {
      lines.add(new TargetLineEntry(line, entries));
    }
  }

  /// Encodes the Mapping mappings as a json map.
  Map toJson() {
    var buff = new StringBuffer();
    var line = 0;
    var column = 0;
    var srcLine = 0;
    var srcColumn = 0;
    var srcUrlId = 0;
    var srcNameId = 0;
    var first = true;

    for (var entry in lines) {
      int nextLine = entry.line;
      if (nextLine > line) {
        for (int i = line; i < nextLine; ++i) {
          buff.write(';');
        }
        line = nextLine;
        column = 0;
        first = true;
      }

      for (var segment in entry.entries) {
        if (!first) buff.write(',');
        first = false;
        column = _append(buff, column, segment.column);

        // Encoding can be just the column offset if there is no source
        // information.
        var newUrlId = segment.sourceUrlId;
        if (newUrlId == null) continue;
        srcUrlId = _append(buff, srcUrlId, newUrlId);
        srcLine = _append(buff, srcLine, segment.sourceLine);
        srcColumn = _append(buff, srcColumn, segment.sourceColumn);

        if (segment.sourceNameId == null) continue;
        srcNameId = _append(buff, srcNameId, segment.sourceNameId);
      }
    }

    var result = {
      'version': 3,
      'sourceRoot': sourceRoot == null ? '' : sourceRoot,
      'sources': urls,
      'names' : names,
      'mappings' : buff.toString()
    };
    if (targetUrl != null) {
      result['file'] = targetUrl;
    }
    return result;
  }

  /// Appends to [buff] a VLQ encoding of [newValue] using the difference
  /// between [oldValue] and [newValue]
  static int _append(StringBuffer buff, int oldValue, int newValue) {
    buff.writeAll(encodeVlq(newValue - oldValue));
    return newValue;
  }

  _segmentError(int seen, int line) => new StateError(
      'Invalid entry in sourcemap, expected 1, 4, or 5'
      ' values, but got $seen.\ntargeturl: $targetUrl, line: $line');

  /// Returns [TargetLineEntry] which includes the location in the target [line]
  /// number. In particular, the resulting entry is the last entry whose line
  /// number is lower or equal to [line].
  TargetLineEntry _findLine(int line) {
    int index = binarySearch(lines, (e) => e.line > line);
    return (index <= 0) ? null : lines[index - 1];
  }

  /// Returns [TargetEntry] which includes the location denoted by
  /// [line], [column]. If [lineEntry] corresponds to [line], then this will be
  /// the last entry whose column is lower or equal than [column]. If
  /// [lineEntry] corresponds to a line prior to [line], then the result will be
  /// the very last entry on that line.
  TargetEntry _findColumn(int line, int column, TargetLineEntry lineEntry) {
    if (lineEntry == null || lineEntry.entries.length == 0) return null;
    if (lineEntry.line != line) return lineEntry.entries.last;
    var entries = lineEntry.entries;
    int index = binarySearch(entries, (e) => e.column > column);
    return (index <= 0) ? null : entries[index - 1];
  }

  Span spanFor(int line, int column, {Map<String, SourceFile> files}) {
    var entry = _findColumn(line, column, _findLine(line));
    if (entry == null || entry.sourceUrlId == null) return null;
    var url = urls[entry.sourceUrlId];
    if (sourceRoot != null) {
      url = '${sourceRoot}${url}';
    }
    if (files != null && files[url] != null) {
      var file = files[url];
      var start = file.getOffset(entry.sourceLine, entry.sourceColumn);
      if (entry.sourceNameId != null) {
        var text = names[entry.sourceNameId];
        return new FileSpan(files[url], start, start + text.length, true);
      } else {
        return new FileSpan(files[url], start);
      }
    } else {
      // Offset and other context is not available.
      if (entry.sourceNameId != null) {
        return new FixedSpan(url, 0, entry.sourceLine, entry.sourceColumn,
            text: names[entry.sourceNameId], isIdentifier: true);
      } else {
        return new FixedSpan(url, 0, entry.sourceLine, entry.sourceColumn);
      }
    }
  }

  String toString() {
    return (new StringBuffer("$runtimeType : [")
        ..write('targetUrl: ')
        ..write(targetUrl)
        ..write(', sourceRoot: ')
        ..write(sourceRoot)
        ..write(', urls: ')
        ..write(urls)
        ..write(', names: ')
        ..write(names)
        ..write(', lines: ')
        ..write(lines)
        ..write(']')).toString();
  }

  String get debugString {
    var buff = new StringBuffer();
    for (var lineEntry in lines) {
      var line = lineEntry.line;
      for (var entry in lineEntry.entries) {
        buff..write(targetUrl)
            ..write(': ')
            ..write(line)
            ..write(':')
            ..write(entry.column);
        if (entry.sourceUrlId != null) {
          buff..write('   -->   ')
              ..write(sourceRoot)
              ..write(urls[entry.sourceUrlId])
              ..write(': ')
              ..write(entry.sourceLine)
              ..write(':')
              ..write(entry.sourceColumn);
        }
        if (entry.sourceNameId != null) {
          buff..write(' (')
              ..write(names[entry.sourceNameId])
              ..write(')');
        }
        buff.write('\n');
      }
    }
    return buff.toString();
  }
}

/// A line entry read from a source map.
class TargetLineEntry {
  final int line;
  List<TargetEntry> entries;
  TargetLineEntry(this.line, this.entries);

  String toString() => '$runtimeType: $line $entries';
}

/// A target segment entry read from a source map
class TargetEntry {
  final int column;
  final int sourceUrlId;
  final int sourceLine;
  final int sourceColumn;
  final int sourceNameId;

  TargetEntry(this.column, [this.sourceUrlId, this.sourceLine,
      this.sourceColumn, this.sourceNameId]);

  String toString() => '$runtimeType: '
      '($column, $sourceUrlId, $sourceLine, $sourceColumn, $sourceNameId)';
}

/** A character iterator over a string that can peek one character ahead. */
class _MappingTokenizer implements Iterator<String> {
  final String _internal;
  final int _length;
  int index = -1;
  _MappingTokenizer(String internal)
      : _internal = internal,
        _length = internal.length;

  // Iterator API is used by decodeVlq to consume VLQ entries.
  bool moveNext() => ++index < _length;
  String get current =>
      (index >= 0 && index < _length) ?  _internal[index] : null;

  bool get hasTokens => index < _length - 1 && _length > 0;

  _TokenKind get nextKind {
    if (!hasTokens) return _TokenKind.EOF;
    var next = _internal[index + 1];
    if (next == ';') return _TokenKind.LINE;
    if (next == ',') return _TokenKind.SEGMENT;
    return _TokenKind.VALUE;
  }

  int _consumeValue() => decodeVlq(this);
  void _consumeNewLine() { ++index; }
  void _consumeNewSegment() { ++index; }

  // Print the state of the iterator, with colors indicating the current
  // position.
  String toString() {
    var buff = new StringBuffer();
    for (int i = 0; i < index; i++) {
      buff.write(_internal[i]);
    }
    buff.write('[31m');
    buff.write(current == null ? '' : current);
    buff.write('[0m');
    for (int i = index + 1; i < _internal.length; i++) {
      buff.write(_internal[i]);
    }
    buff.write(' ($index)');
    return buff.toString();
  }
}

class _TokenKind {
  static const _TokenKind LINE = const _TokenKind(isNewLine: true);
  static const _TokenKind SEGMENT = const _TokenKind(isNewSegment: true);
  static const _TokenKind EOF = const _TokenKind(isEof: true);
  static const _TokenKind VALUE = const _TokenKind();
  final bool isNewLine;
  final bool isNewSegment;
  final bool isEof;
  bool get isValue => !isNewLine && !isNewSegment && !isEof;

  const _TokenKind(
      {this.isNewLine: false, this.isNewSegment: false, this.isEof: false});
}
