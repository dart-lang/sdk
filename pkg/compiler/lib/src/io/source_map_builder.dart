// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.source_map_builder;

import 'package:kernel/ast.dart' show Location;
import '../../compiler_new.dart' show OutputSink, OutputType;
import '../util/uri_extras.dart' show relativize;
import '../util/util.dart';
import 'location_provider.dart';
import 'code_output.dart' show SourceLocationsProvider, SourceLocations;
import 'source_information.dart' show SourceLocation;

class SourceMapBuilder {
  final String version;

  /// The URI of the source map file.
  final Uri sourceMapUri;

  /// The URI of the target language file.
  final Uri targetFileUri;

  final LocationProvider locationProvider;
  final List<SourceMapEntry> entries = new List<SourceMapEntry>();

  SourceMapBuilder(this.version, this.sourceMapUri, this.targetFileUri,
      this.locationProvider);

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
      Location kernelLocation =
          locationProvider.getLocation(sourceMapEntry.targetOffset);
      int line = kernelLocation.line - 1;
      int column = kernelLocation.column - 1;
      lineColumnMap.add(line, column, sourceMapEntry);

      SourceLocation location = sourceMapEntry.sourceLocation;
      if (location != null) {
        if (location.sourceUri != null) {
          LineColumnMap<SourceMapEntry> sourceLineColumnMap =
              sourceLocationMap.putIfAbsent(location.sourceUri,
                  () => new LineColumnMap<SourceMapEntry>());
          sourceLineColumnMap.add(
              location.line - 1, location.column - 1, sourceMapEntry);
        }
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
        if (sourceLocation.sourceUri != null) {
          uriMap.register(sourceLocation.sourceUri);
          if (sourceLocation.sourceName != null) {
            nameMap.register(sourceLocation.sourceName);
          }
        }
      }
    });

    StringBuffer mappingsBuffer = new StringBuffer();
    writeEntries(lineColumnMap, uriMap, nameMap, mappingsBuffer);

    StringBuffer buffer = new StringBuffer();
    buffer.write('{\n');
    buffer.write('  "version": 3,\n');
    buffer.write('  "engine": "$version",\n');
    if (sourceMapUri != null && targetFileUri != null) {
      buffer.write(
          '  "file": "${relativize(sourceMapUri, targetFileUri, false)}",\n');
    }
    buffer.write('  "sourceRoot": "",\n');
    buffer.write('  "sources": ');
    Iterable<String> relativeSourceUriList = const <String>[];
    if (sourceMapUri != null) {
      relativeSourceUriList =
          uriMap.elements.map((u) => relativize(sourceMapUri, u, false));
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

  void writeEntries(LineColumnMap<SourceMapEntry> entries, IndexMap<Uri> uriMap,
      IndexMap<String> nameMap, StringBuffer output) {
    SourceLocation previousSourceLocation;
    int previousTargetLine = 0;
    DeltaEncoder targetColumnEncoder = new DeltaEncoder();
    bool firstEntryInLine = true;
    DeltaEncoder sourceUriIndexEncoder = new DeltaEncoder();
    DeltaEncoder sourceLineEncoder = new DeltaEncoder();
    DeltaEncoder sourceColumnEncoder = new DeltaEncoder();
    DeltaEncoder sourceNameIndexEncoder = new DeltaEncoder();

    entries.forEach((int targetLine, int targetColumn, SourceMapEntry entry) {
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
      if (sourceUri != null) {
        sourceUriIndexEncoder.encode(output, uriMap[sourceUri]);
        sourceLineEncoder.encode(output, sourceLocation.line - 1);
        sourceColumnEncoder.encode(output, sourceLocation.column - 1);
      }

      String sourceName = sourceLocation.sourceName;
      if (sourceName != null) {
        sourceNameIndexEncoder.encode(output, nameMap[sourceName]);
      }

      previousSourceLocation = sourceLocation;
    });
  }

  /// Returns the source map tag to put at the end a .js file in [fileUri] to
  /// make it point to the source map file in [sourceMapUri].
  static String generateSourceMapTag(Uri sourceMapUri, Uri fileUri) {
    if (sourceMapUri != null && fileUri != null) {
      String sourceMapFileName = relativize(fileUri, sourceMapUri, false);
      return '''

//# sourceMappingURL=$sourceMapFileName
''';
    }
    return '';
  }

  /// Generates source map files for all [SourceLocations] in
  /// [sourceLocationsProvider] for the .js code in [locationProvider]
  /// [sourceMapUri] is used to relativizes the URIs of the referenced source
  /// files and the target [fileUri]. [name] and [outputProvider] are used to
  /// create the [OutputSink] for the source map text.
  static void outputSourceMap(
      SourceLocationsProvider sourceLocationsProvider,
      LocationProvider locationProvider,
      String name,
      Uri sourceMapUri,
      Uri fileUri,
      OutputSink outputProvider(
          String name, String extension, OutputType type)) {
    // Create a source file for the compilation output. This allows using
    // [:getLine:] to transform offsets to line numbers in [SourceMapBuilder].
    int index = 0;
    sourceLocationsProvider.sourceLocations
        .forEach((SourceLocations sourceLocations) {
      SourceMapBuilder sourceMapBuilder = new SourceMapBuilder(
          sourceLocations.name, sourceMapUri, fileUri, locationProvider);
      sourceLocations.forEachSourceLocation(sourceMapBuilder.addMapping);
      String sourceMap = sourceMapBuilder.build();
      String extension = 'js.map';
      if (index > 0) {
        if (name == '') {
          name = fileUri != null ? fileUri.pathSegments.last : 'out.js';
          extension = 'map.${sourceLocations.name}';
        } else {
          extension = 'js.map.${sourceLocations.name}';
        }
      }
      outputProvider(name, extension, OutputType.sourceMap)
        ..add(sourceMap)
        ..close();
      index++;
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
  var _makeLineMap = () => <int, List<T>>{};
  var _makeList = () => <T>[];

  /// Returns the list of elements associated with ([line],[column]).
  List<T> _getList(int line, int column) {
    Map<int, List<T>> lineMap = _map.putIfAbsent(line, _makeLineMap);
    return lineMap.putIfAbsent(column, _makeList);
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
