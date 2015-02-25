// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.source_map_builder;

import '../util/util.dart';
import '../util/uri_extras.dart' show relativize;
import 'line_column_provider.dart';
import 'source_information.dart' show SourceLocation;

class SourceMapBuilder {
  static const int VLQ_BASE_SHIFT = 5;
  static const int VLQ_BASE_MASK = (1 << 5) - 1;
  static const int VLQ_CONTINUATION_BIT = 1 << 5;
  static const int VLQ_CONTINUATION_MASK = 1 << 5;
  static const String BASE64_DIGITS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmn'
                                      'opqrstuvwxyz0123456789+/';

  /// The URI of the source map file.
  final Uri sourceMapUri;
  /// The URI of the target language file.
  final Uri targetFileUri;

  LineColumnProvider lineColumnProvider;
  List<SourceMapEntry> entries;

  Map<Uri, int> sourceUriMap;
  List<Uri> sourceUriList;
  Map<String, int> sourceNameMap;
  List<String> sourceNameList;

  int previousTargetLine;
  int previousTargetColumn;
  int previousSourceUriIndex;
  int previousSourceLine;
  int previousSourceColumn;
  int previousSourceNameIndex;
  bool firstEntryInLine;

  SourceMapBuilder(this.sourceMapUri,
                   this.targetFileUri,
                   this.lineColumnProvider) {
    entries = new List<SourceMapEntry>();

    sourceUriMap = new Map<Uri, int>();
    sourceUriList = new List<Uri>();
    sourceNameMap = new Map<String, int>();
    sourceNameList = new List<String>();

    previousTargetLine = 0;
    previousTargetColumn = 0;
    previousSourceUriIndex = 0;
    previousSourceLine = 0;
    previousSourceColumn = 0;
    previousSourceNameIndex = 0;
    firstEntryInLine = true;
  }

  resetPreviousSourceLocation() {
    previousSourceUriIndex = 0;
    previousSourceLine = 0;
    previousSourceColumn = 0;
    previousSourceNameIndex = 0;
  }

  updatePreviousSourceLocation(SourceLocation sourceLocation) {
    previousSourceLine = sourceLocation.line;
    previousSourceColumn = sourceLocation.column;
    Uri sourceUri = sourceLocation.sourceUri;
    previousSourceUriIndex = indexOf(sourceUriList, sourceUri, sourceUriMap);
    String sourceName = sourceLocation.sourceName;
    if (sourceName != null) {
      previousSourceNameIndex =
          indexOf(sourceNameList, sourceName, sourceNameMap);
    }
  }

  bool sameAsPreviousLocation(SourceLocation sourceLocation) {
    if (sourceLocation == null) {
      return true;
    }
    int sourceUriIndex =
        indexOf(sourceUriList, sourceLocation.sourceUri, sourceUriMap);
    return
       sourceUriIndex == previousSourceUriIndex &&
       sourceLocation.line == previousSourceLine &&
       sourceLocation.column == previousSourceColumn;
  }

  void addMapping(int targetOffset, SourceLocation sourceLocation) {

    bool sameLine(int position, otherPosition) {
      return lineColumnProvider.getLine(position) ==
                 lineColumnProvider.getLine(otherPosition);
    }

    if (!entries.isEmpty && sameLine(targetOffset, entries.last.targetOffset)) {
      if (sameAsPreviousLocation(sourceLocation)) {
        // The entry points to the same source location as the previous entry in
        // the same line, hence it is not needed for the source map.
        //
        // TODO(zarah): Remove this check and make sure that [addMapping] is not
        // called for this position. Instead, when consecutive lines in the
        // generated code point to the same source location, record this and use
        // it to generate the entries of the source map.
        return;
      }
    }

    if (sourceLocation != null) {
      updatePreviousSourceLocation(sourceLocation);
    }
    entries.add(new SourceMapEntry(sourceLocation, targetOffset));
  }

  void printStringListOn(List<String> strings, StringBuffer buffer) {
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
    resetPreviousSourceLocation();
    StringBuffer mappingsBuffer = new StringBuffer();
    entries.forEach((SourceMapEntry entry) {
      writeEntry(entry, mappingsBuffer);
    });
    StringBuffer buffer = new StringBuffer();
    buffer.write('{\n');
    buffer.write('  "version": 3,\n');
    if (sourceMapUri != null && targetFileUri != null) {
      buffer.write(
          '  "file": "${relativize(sourceMapUri, targetFileUri, false)}",\n');
    }
    buffer.write('  "sourceRoot": "",\n');
    buffer.write('  "sources": ');
    List<String> relativeSourceUriList = <String>[];
    if (sourceMapUri != null) {
      relativeSourceUriList = sourceUriList
          .map((u) => relativize(sourceMapUri, u, false))
          .toList();
    }
    printStringListOn(relativeSourceUriList, buffer);
    buffer.write(',\n');
    buffer.write('  "names": ');
    printStringListOn(sourceNameList, buffer);
    buffer.write(',\n');
    buffer.write('  "mappings": "');
    buffer.write(mappingsBuffer);
    buffer.write('"\n}\n');
    return buffer.toString();
  }

  void writeEntry(SourceMapEntry entry, StringBuffer output) {
    int targetLine = lineColumnProvider.getLine(entry.targetOffset);
    int targetColumn =
        lineColumnProvider.getColumn(targetLine, entry.targetOffset);

    if (targetLine > previousTargetLine) {
      for (int i = previousTargetLine; i < targetLine; ++i) {
        output.write(';');
      }
      previousTargetLine = targetLine;
      previousTargetColumn = 0;
      firstEntryInLine = true;
    }

    if (!firstEntryInLine) {
      output.write(',');
    }
    firstEntryInLine = false;

    encodeVLQ(output, targetColumn - previousTargetColumn);
    previousTargetColumn = targetColumn;

    if (entry.sourceLocation == null) return;

    Uri sourceUri = entry.sourceLocation.sourceUri;
    int sourceLine = entry.sourceLocation.line;
    int sourceColumn = entry.sourceLocation.column;
    String sourceName = entry.sourceLocation.sourceName;

    int sourceUriIndex = indexOf(sourceUriList, sourceUri, sourceUriMap);
    encodeVLQ(output, sourceUriIndex - previousSourceUriIndex);
    encodeVLQ(output, sourceLine - previousSourceLine);
    encodeVLQ(output, sourceColumn - previousSourceColumn);

    if (sourceName != null) {
      int sourceNameIndex = indexOf(sourceNameList, sourceName, sourceNameMap);
      encodeVLQ(output, sourceNameIndex - previousSourceNameIndex);
    }

    // Update previous source location to ensure the next indices are relative
    // to those if [entry.sourceLocation].
    updatePreviousSourceLocation(entry.sourceLocation);
  }

  int indexOf(List list, value, Map<dynamic, int> map) {
    return map.putIfAbsent(value, () {
      int index = list.length;
      list.add(value);
      return index;
    });
  }

  static void encodeVLQ(StringBuffer output, int value) {
    int signBit = 0;
    if (value < 0) {
      signBit = 1;
      value = -value;
    }
    value = (value << 1) | signBit;
    do {
      int digit = value & VLQ_BASE_MASK;
      value >>= VLQ_BASE_SHIFT;
      if (value > 0) {
        digit |= VLQ_CONTINUATION_BIT;
      }
      output.write(BASE64_DIGITS[digit]);
    } while (value > 0);
  }
}

class SourceMapEntry {
  SourceLocation sourceLocation;
  int targetOffset;

  SourceMapEntry(this.sourceLocation, this.targetOffset);
}
