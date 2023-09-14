// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.source_map_builder;

import 'package:front_end/src/api_unstable/dart2js.dart' as fe;
import 'package:kernel/ast.dart' show Location;
import '../../compiler_api.dart' as api
    show CompilerOutput, OutputSink, OutputType;
import '../util/output_util.dart';
import '../util/util.dart';
import 'location_provider.dart';
import 'code_output.dart' show SourceLocationsProvider, SourceLocations;
import 'source_information.dart' show SourceLocation, FrameEntry;

class SourceMapBuilder {
  final String version;
  final StringSink outputSink;

  /// The URI of the source map file.
  final Uri? sourceMapUri;

  /// The URI of the target language file.
  final Uri? targetFileUri;

  final LocationProvider locationProvider;
  final List<SourceMapEntry> entries = [];

  /// Extension used to deobfuscate minified names in error messages.
  final Map<String, String> minifiedGlobalNames;
  final Map<String, String> minifiedInstanceNames;

  /// Contains mapped source locations including inlined frame mappings.
  final SourceLocations sourceLocations;

  SourceMapBuilder(
      this.version,
      this.sourceMapUri,
      this.targetFileUri,
      this.locationProvider,
      this.minifiedGlobalNames,
      this.minifiedInstanceNames,
      this.sourceLocations,
      this.outputSink);

  void addMapping(int targetOffset, SourceLocation sourceLocation) {
    entries.add(SourceMapEntry(sourceLocation, targetOffset));
  }

  void printStringListOn(Iterable<String> strings) {
    bool first = true;
    outputSink.write('[');
    for (String string in strings) {
      if (!first) outputSink.write(',');
      outputSink.write('"');
      writeJsonEscapedCharsOn(string, outputSink);
      outputSink.write('"');
      first = false;
    }
    outputSink.write(']');
  }

  void build() {
    LineColumnMap<SourceMapEntry> lineColumnMap = LineColumnMap();
    Map<Uri, LineColumnMap<SourceMapEntry>> sourceLocationMap = {};
    entries.forEach((SourceMapEntry sourceMapEntry) {
      Location kernelLocation =
          locationProvider.getLocation(sourceMapEntry.targetOffset);
      int line = kernelLocation.line - 1;
      int column = kernelLocation.column - 1;
      lineColumnMap.add(line, column, sourceMapEntry);

      SourceLocation? location = sourceMapEntry.sourceLocation;
      if (location != null) {
        if (location.sourceUri != null) {
          LineColumnMap<SourceMapEntry> sourceLineColumnMap =
              sourceLocationMap.putIfAbsent(
                  location.sourceUri!, () => LineColumnMap<SourceMapEntry>());
          sourceLineColumnMap.add(
              location.line - 1, location.column - 1, sourceMapEntry);
        }
      }
    });

    _build(lineColumnMap);
  }

  void _build(LineColumnMap<SourceMapEntry> lineColumnMap) {
    IndexMap<Uri> uriMap = IndexMap<Uri>();
    IndexMap<String> nameMap = IndexMap<String>();

    void registerLocation(SourceLocation? sourceLocation) {
      if (sourceLocation != null) {
        if (sourceLocation.sourceUri != null) {
          uriMap.register(sourceLocation.sourceUri!);
          if (sourceLocation.sourceName != null) {
            nameMap.register(sourceLocation.sourceName!);
          }
        }
      }
    }

    lineColumnMap.forEachElement((SourceMapEntry entry) {
      registerLocation(entry.sourceLocation);
    });

    minifiedGlobalNames.values.forEach(nameMap.register);
    minifiedInstanceNames.values.forEach(nameMap.register);
    sourceLocations.forEachFrameMarker((_, frame) {
      registerLocation(frame.pushLocation);
      if (frame.inlinedMethodName != null) {
        nameMap.register(frame.inlinedMethodName!);
      }
    });

    outputSink.write('{\n');
    outputSink.write('  "version": 3,\n');
    outputSink.write('  "engine": "$version",\n');
    if (sourceMapUri != null && targetFileUri != null) {
      outputSink.write('  "file": '
          '"${fe.relativizeUri(sourceMapUri!, targetFileUri!, false)}",\n');
    }
    outputSink.write('  "sourceRoot": "",\n');
    outputSink.write('  "sources": ');
    Iterable<String> relativeSourceUriList = const <String>[];
    if (sourceMapUri != null) {
      relativeSourceUriList =
          uriMap.elements.map((u) => fe.relativizeUri(sourceMapUri!, u, false));
    }
    printStringListOn(relativeSourceUriList);
    outputSink.write(',\n');
    outputSink.write('  "names": ');
    printStringListOn(nameMap.elements);
    outputSink.write(',\n');
    outputSink.write('  "mappings": "');
    writeEntries(lineColumnMap, uriMap, nameMap);
    outputSink.write('",\n');
    outputSink.write('  "x_org_dartlang_dart2js": {\n');
    outputSink.write('    "minified_names": {\n');
    outputSink.write('      "global": ');
    writeMinifiedNames(minifiedGlobalNames, nameMap);
    outputSink.write(',\n');
    outputSink.write('      "instance": ');
    writeMinifiedNames(minifiedInstanceNames, nameMap);
    outputSink.write('\n    },\n');
    outputSink.write('    "frames": ');
    writeFrames(uriMap, nameMap);
    outputSink.write('\n  }\n}\n');
  }

  void writeEntries(LineColumnMap<SourceMapEntry> entries, IndexMap<Uri> uriMap,
      IndexMap<String> nameMap) {
    SourceLocation? previousSourceLocation;
    int previousTargetLine = 0;
    DeltaEncoder targetColumnEncoder = DeltaEncoder();
    bool firstEntryInLine = true;
    DeltaEncoder sourceUriIndexEncoder = DeltaEncoder();
    DeltaEncoder sourceLineEncoder = DeltaEncoder();
    DeltaEncoder sourceColumnEncoder = DeltaEncoder();
    DeltaEncoder sourceNameIndexEncoder = DeltaEncoder();

    entries.forEach((int targetLine, int targetColumn, SourceMapEntry entry) {
      SourceLocation? sourceLocation = entry.sourceLocation;
      if (sourceLocation == previousSourceLocation) {
        return;
      }

      if (targetLine > previousTargetLine) {
        for (int i = previousTargetLine; i < targetLine; ++i) {
          outputSink.write(';');
        }
        previousTargetLine = targetLine;
        previousSourceLocation = null;
        targetColumnEncoder.reset();
        firstEntryInLine = true;
      }

      if (!firstEntryInLine) {
        outputSink.write(',');
      }
      firstEntryInLine = false;

      targetColumnEncoder.encode(outputSink, targetColumn);

      if (sourceLocation == null) {
        return;
      }

      Uri? sourceUri = sourceLocation.sourceUri;
      if (sourceUri != null) {
        sourceUriIndexEncoder.encode(outputSink, uriMap[sourceUri]!);
        sourceLineEncoder.encode(outputSink, sourceLocation.line - 1);
        sourceColumnEncoder.encode(outputSink, sourceLocation.column - 1);
      }

      String? sourceName = sourceLocation.sourceName;
      if (sourceName != null) {
        sourceNameIndexEncoder.encode(outputSink, nameMap[sourceName]!);
      }

      previousSourceLocation = sourceLocation;
    });
  }

  void writeMinifiedNames(
      Map<String, String> minifiedNames, IndexMap<String> nameMap) {
    bool first = true;
    outputSink.write('"');
    minifiedNames.forEach((String minifiedName, String name) {
      if (!first) outputSink.write(',');
      // minifiedNames are valid JS identifiers so they don't need to be escaped
      outputSink.write(minifiedName);
      outputSink.write(',');
      outputSink.write(nameMap[name]);
      first = false;
    });
    outputSink.write('"');
  }

  void writeFrames(IndexMap<Uri> uriMap, IndexMap<String> nameMap) {
    var offsetEncoder = DeltaEncoder();
    var uriEncoder = DeltaEncoder();
    var lineEncoder = DeltaEncoder();
    var columnEncoder = DeltaEncoder();
    var nameEncoder = DeltaEncoder();
    outputSink.write('"');
    sourceLocations.forEachFrameMarker((int offset, FrameEntry entry) {
      offsetEncoder.encode(outputSink, offset);
      if (entry.isPush) {
        SourceLocation location = entry.pushLocation!;
        uriEncoder.encode(outputSink, uriMap[location.sourceUri!]!);
        lineEncoder.encode(outputSink, location.line - 1);
        columnEncoder.encode(outputSink, location.column - 1);
        nameEncoder.encode(outputSink, nameMap[entry.inlinedMethodName!]!);
      } else {
        // ; and , are not used by VLQ so we can distinguish them in the
        // encoding, this is the same reason they are used in the mappings
        // field.
        outputSink.write(entry.isEmptyPop ? ";" : ",");
      }
    });
    outputSink.write('"');
  }

  /// Returns the source map tag to put at the end a .js file in [fileUri] to
  /// make it point to the source map file in [sourceMapUri].
  static String generateSourceMapTag(Uri? sourceMapUri, Uri? fileUri) {
    if (sourceMapUri != null && fileUri != null) {
      String sourceMapFileName = fe.relativizeUri(fileUri, sourceMapUri, false);
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
  /// create the [api.OutputSink] for the source map text.
  static void outputSourceMap(
      SourceLocationsProvider sourceLocationsProvider,
      LocationProvider locationProvider,
      Map<String, String> minifiedGlobalNames,
      Map<String, String> minifiedInstanceNames,
      String name,
      Uri? sourceMapUri,
      Uri? fileUri,
      api.CompilerOutput compilerOutput) {
    // Create a source file for the compilation output. This allows using
    // [:getLine:] to transform offsets to line numbers in [SourceMapBuilder].
    int index = 0;
    sourceLocationsProvider.sourceLocations
        .forEach((SourceLocations sourceLocations) {
      String extension = 'js.map';
      if (index > 0) {
        if (name == '') {
          name = fileUri != null ? fileUri.pathSegments.last : 'out.js';
          extension = 'map.${sourceLocations.name}';
        } else {
          extension = 'js.map.${sourceLocations.name}';
        }
      }
      final outputSink = BufferedStringOutputSink(compilerOutput
          .createOutputSink(name, extension, api.OutputType.sourceMap));
      SourceMapBuilder sourceMapBuilder = SourceMapBuilder(
          sourceLocations.name,
          sourceMapUri,
          fileUri,
          locationProvider,
          minifiedGlobalNames,
          minifiedInstanceNames,
          sourceLocations,
          outputSink);
      sourceLocations.forEachSourceLocation(sourceMapBuilder.addMapping);
      sourceMapBuilder.build();
      sourceLocations.close();
      outputSink.close();
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
  void encode(StringSink output, int value) {
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
  static int encodeVLQ(StringSink output, int value, int offset) {
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
  SourceLocation? sourceLocation;
  int targetOffset;

  SourceMapEntry(this.sourceLocation, this.targetOffset);
}

/// Map from line/column pairs to lists of [T] elements.
class LineColumnMap<T> {
  final Map<int, Map<int, List<T>>> _map = {};

  /// Returns the list of elements associated with ([line],[column]).
  List<T> _getList(int line, int column) {
    Map<int, List<T>> lineMap = _map[line] ??= {};
    return lineMap[column] ??= [];
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
  List<T>? getFirstElementsInLine(int line) {
    Map<int, List<T>>? lineMap = _map[line];
    if (lineMap == null) return null;
    List<int> columns = lineMap.keys.toList()..sort();
    return lineMap[columns.first];
  }

  /// Calls [f] for each column with associated elements in [line].
  ///
  /// [f] is called in increasing column order.
  void forEachColumn(int line, f(int column, List<T> elements)) {
    Map<int, List<T>>? lineMap = _map[line];
    if (lineMap != null) {
      List<int> columns = lineMap.keys.toList()..sort();
      columns.forEach((int column) {
        f(column, lineMap[column]!);
      });
    }
  }

  /// Calls [f] for each line/column/element triplet in the map.
  ///
  /// [f] is called in increasing line, column, element order.
  void forEach(f(int line, int column, T element)) {
    List<int> lines = _map.keys.toList()..sort();
    for (int line in lines) {
      Map<int, List<T>> lineMap = _map[line]!;
      List<int> columns = lineMap.keys.toList()..sort();
      for (int column in columns) {
        lineMap[column]!.forEach((e) => f(line, column, e));
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
  Map<T, int> map = {};

  /// Register [element] and returns its index.
  int register(T element) {
    return map.putIfAbsent(element, () => map.length);
  }

  /// Returns the index of [element].
  int? operator [](T element) => map[element];

  /// Returns the indexed elements.
  Iterable<T> get elements => map.keys;
}
