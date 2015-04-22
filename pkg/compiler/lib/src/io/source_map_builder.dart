// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.source_map_builder;

import '../util/util.dart';
import '../util/uri_extras.dart' show relativize;
import 'line_column_provider.dart';
import 'source_information.dart' show SourceLocation;

class SourceMapBuilder {

  /// The URI of the source map file.
  final Uri sourceMapUri;
  /// The URI of the target language file.
  final Uri targetFileUri;

  final LineColumnProvider lineColumnProvider;
  final List<SourceMapEntry> entries = new List<SourceMapEntry>();

  SourceMapBuilder(this.sourceMapUri,
                   this.targetFileUri,
                   this.lineColumnProvider);

  void addMapping(int targetOffset, SourceLocation sourceLocation) {
    entries.add(new SourceMapEntry(sourceLocation, targetOffset));
  }

  void printStringListOn(Iterable<String> strings, StringBuffer buffer) {
    bool first = true;
    buffer.write('[');
    for (String string in strings) {
      if (!first) buffer.write(',');
      buffer.write('"');
      writeJsonEscapedCharsOn(string, buffer);
      buffer.write('"');
      first = false;
    }
    buffer.write(']');
  }

  String build() {

    LineColumnMap<SourceMapEntry> lineColumnMap =
        new LineColumnMap<SourceMapEntry>();
    Map<Uri, LineColumnMap<SourceMapEntry>> sourceLocationMap =
        <Uri, LineColumnMap<SourceMapEntry>>{};
    entries.forEach((SourceMapEntry sourceMapEntry) {
      int line = lineColumnProvider.getLine(sourceMapEntry.targetOffset);
      int column =
          lineColumnProvider.getColumn(line, sourceMapEntry.targetOffset);
      lineColumnMap.add(line, column, sourceMapEntry);

      SourceLocation location = sourceMapEntry.sourceLocation;
      if (location != null) {
        LineColumnMap<SourceMapEntry> sourceLineColumnMap =
            sourceLocationMap.putIfAbsent(location.sourceUri,
                () => new LineColumnMap<SourceMapEntry>());
        sourceLineColumnMap.add(location.line, location.column, sourceMapEntry);
      }
    });

    return _build(lineColumnMap);
  }

  String _build(LineColumnMap<SourceMapEntry> lineColumnMap) {
    IndexMap<Uri> uriMap = new IndexMap<Uri>();
    IndexMap<String> nameMap = new IndexMap<String>();

    lineColumnMap.forEachElement((SourceMapEntry entry) {
      SourceLocation sourceLocation = entry.sourceLocation;
      if (sourceLocation != null) {
        uriMap.register(sourceLocation.sourceUri);
        if (sourceLocation.sourceName != null) {
          nameMap.register(sourceLocation.sourceName);
        }
      }
    });

    StringBuffer mappingsBuffer = new StringBuffer();
    writeEntries(lineColumnMap, uriMap, nameMap, mappingsBuffer);

    StringBuffer buffer = new StringBuffer();
    buffer.write('{\n');
    buffer.write('  "version": 3,\n');
    if (sourceMapUri != null && targetFileUri != null) {
      buffer.write(
          '  "file": "${relativize(sourceMapUri, targetFileUri, false)}",\n');
    }
    buffer.write('  "sourceRoot": "",\n');
    buffer.write('  "sources": ');
    Iterable<String> relativeSourceUriList = const <String>[];
    if (sourceMapUri != null) {
      relativeSourceUriList = uriMap.elements
          .map((u) => relativize(sourceMapUri, u, false));
    }
    printStringListOn(relativeSourceUriList, buffer);
    buffer.write(',\n');
    buffer.write('  "names": ');
    printStringListOn(nameMap.elements, buffer);
    buffer.write(',\n');
    buffer.write('  "mappings": "');
    buffer.write(mappingsBuffer);
    buffer.write('"\n}\n');
    return buffer.toString();
  }

  void writeEntries(LineColumnMap<SourceMapEntry> entries,
                    IndexMap<Uri> uriMap,
                    IndexMap<String> nameMap,
                    StringBuffer output) {
    SourceLocation previousSourceLocation;
    int previousTargetLine = 0;
    DeltaEncoder targetColumnEncoder = new DeltaEncoder();
    bool firstEntryInLine = true;
    DeltaEncoder sourceUriIndexEncoder = new DeltaEncoder();
    DeltaEncoder sourceLineEncoder = new DeltaEncoder();
    DeltaEncoder sourceColumnEncoder = new DeltaEncoder();
    DeltaEncoder sourceNameIndexEncoder = new DeltaEncoder();

    entries.forEach((int targetLine,
                     int targetColumn,
                     SourceMapEntry entry) {
      SourceLocation sourceLocation = entry.sourceLocation;
      if (sourceLocation == previousSourceLocation) {
        return;
      }

      if (targetLine > previousTargetLine) {
        for (int i = previousTargetLine; i < targetLine; ++i) {
          output.write(';');
        }
        previousTargetLine = targetLine;
        previousSourceLocation = null;
        targetColumnEncoder.reset();
        firstEntryInLine = true;
      }

      if (!firstEntryInLine) {
        output.write(',');
      }
      firstEntryInLine = false;

      targetColumnEncoder.encode(output, targetColumn);

      if (sourceLocation == null) {
        return;
      }

      Uri sourceUri = sourceLocation.sourceUri;
      sourceUriIndexEncoder.encode(output, uriMap[sourceUri]);
      sourceLineEncoder.encode(output, sourceLocation.line);
      sourceColumnEncoder.encode(output, sourceLocation.column);

      String sourceName = sourceLocation.sourceName;
      if (sourceName != null) {
        sourceNameIndexEncoder.encode(output, nameMap[sourceName]);
      }

      previousSourceLocation = sourceLocation;
    });
  }
}

/// Encoder for value deltas in VLQ format.
class DeltaEncoder {
  /// The last emitted value of the encoder.
  int _value = 0;

  /// Reset the encoder to its initial state.
  void reset() {
    _value = 0;
  }

  /// Writes the VLQ of delta between [value] and the last emitted value into
  /// [output] and updates the last emitted value of the encoder.
  void encode(StringBuffer output, int value) {
    _value = encodeVLQ(output, value, _value);
  }

  static const int VLQ_BASE_SHIFT = 5;
  static const int VLQ_BASE_MASK = (1 << 5) - 1;
  static const int VLQ_CONTINUATION_BIT = 1 << 5;
  static const int VLQ_CONTINUATION_MASK = 1 << 5;
  static const String BASE64_DIGITS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmn'
                                      'opqrstuvwxyz0123456789+/';

  /// Writes the VLQ of delta between [value] and [offset] into [output] and
  /// return [value].
  static int encodeVLQ(StringBuffer output, int value, int offset) {
    int delta = value - offset;
    int signBit = 0;
    if (delta < 0) {
      signBit = 1;
      delta = -delta;
    }
    delta = (delta << 1) | signBit;
    do {
      int digit = delta & VLQ_BASE_MASK;
      delta >>= VLQ_BASE_SHIFT;
      if (delta > 0) {
        digit |= VLQ_CONTINUATION_BIT;
      }
      output.write(BASE64_DIGITS[digit]);
    } while (delta > 0);
    return value;
  }
}

class SourceMapEntry {
  SourceLocation sourceLocation;
  int targetOffset;

  SourceMapEntry(this.sourceLocation, this.targetOffset);
}

/// Map from line/column pairs to lists of [T] elements.
class LineColumnMap<T> {
  Map<int, Map<int, List<T>>> _map = <int, Map<int, List<T>>>{};

  /// Returns the list of elements associated with ([line],[column]).
  List<T> _getList(int line, int column) {
    Map<int, List<T>> lineMap = _map.putIfAbsent(line, () => <int, List<T>>{});
    return lineMap.putIfAbsent(column, () => <T>[]);
  }

  /// Adds [element] to the end of the list of elements associated with
  /// ([line],[column]).
  void add(int line, int column, T element) {
    _getList(line, column).add(element);
  }

  /// Adds [element] to the beginning of the list of elements associated with
  /// ([line],[column]).
  void addFirst(int line, int column, T element) {
    _getList(line, column).insert(0, element);
  }

  /// Calls [f] with the line number for each line with associated elements.
  ///
  /// [f] is called in increasing line order.
  void forEachLine(f(int line)) {
    List<int> lines = _map.keys.toList()..sort();
    lines.forEach(f);
  }

  /// Returns the elements for the first the column in [line] that has
  /// associated elements.
  List<T> getFirstElementsInLine(int line) {
    Map<int, List<T>> lineMap = _map[line];
    if (lineMap == null) return null;
    List<int> columns = lineMap.keys.toList()..sort();
    return lineMap[columns.first];
  }

  /// Calls [f] for each column with associated elements in [line].
  ///
  /// [f] is called in increasing column order.
  void forEachColumn(int line, f(int column, List<T> elements)) {
    Map<int, List<T>> lineMap = _map[line];
    if (lineMap != null) {
      List<int> columns = lineMap.keys.toList()..sort();
      columns.forEach((int column) {
        f(column, lineMap[column]);
      });
    }
  }

  /// Calls [f] for each line/column/element triplet in the map.
  ///
  /// [f] is called in increasing line, column, element order.
  void forEach(f(int line, int column, T element)) {
    List<int> lines = _map.keys.toList()..sort();
    for (int line in lines) {
      Map<int, List<T>> lineMap = _map[line];
      List<int> columns = lineMap.keys.toList()..sort();
      for (int column in columns) {
        lineMap[column].forEach((e) => f(line, column, e));
      }
    }
  }

  /// Calls [f] for each element associated in the map.
  ///
  /// [f] is called in increasing line, column, element order.
  void forEachElement(f(T element)) {
    forEach((line, column, element) => f(element));
  }
}

/// Map from [T] elements to assigned indices.
class IndexMap<T> {
  Map<T, int> map = <T, int>{};

  /// Register [element] and returns its index.
  int register(T element) {
    return map.putIfAbsent(element, () => map.length);
  }

  /// Returns the index of [element].
  int operator [](T element) => map[element];

  /// Returns the indexed elements.
  Iterable<T> get elements => map.keys;
}
