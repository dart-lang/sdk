// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('source_map_builder');

#import('dart:json');

#import('source_file.dart');

class SourceMappingEntry {
  SourceFile sourceFile;
  int sourceOffset;
  int targetOffset;
  String sourceName;

  SourceMappingEntry(this.sourceFile,
                     this.sourceOffset,
                     this.targetOffset,
                     [this.sourceName]);
}

class SourceMapBuilder {
  static final int VLQ_BASE_SHIFT = 5;
  static final int VLQ_BASE_MASK = (1 << 5) - 1;
  static final int VLQ_CONTINUATION_BIT = 1 << 5;
  static final int VLQ_CONTINUATION_MASK = 1 << 5;
  static final String BASE64_DIGITS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmn'
                                      'opqrstuvwxyz0123456789+/';

  Map<String, int> sourceUrlMap;
  List<String> sourceUrlList;
  Map<String, int> sourceNameMap;
  List<String> sourceNameList;

  int previousTargetLine;
  int previousTargetColumn;
  int previousSourceUrlIndex;
  int previousSourceLine;
  int previousSourceColumn;
  int previousSourceNameIndex;
  bool firstEntryInLine;

  SourceMapBuilder() {
    sourceUrlMap = new Map<String, int>();
    sourceUrlList = new List<String>();
    sourceNameMap = new Map<String, int>();
    sourceNameList = new List<String>();

    previousTargetLine = 0;
    previousTargetColumn = 0;
    previousSourceUrlIndex = 0;
    previousSourceLine = 0;
    previousSourceColumn = 0;
    previousSourceNameIndex = 0;
    firstEntryInLine = true;
  }

  String build(List<SourceMappingEntry> mappingEntries, SourceFile targetFile) {
    StringBuffer buffer = new StringBuffer();
    buffer.add('{\n');
    buffer.add('  "version": 3,\n');
    buffer.add('  "mappings": "');
    mappingEntries.forEach((SourceMappingEntry entry) {
      writeEntry(entry, targetFile, buffer);
    });
    buffer.add('",\n');
    buffer.add('  "sources": ');
    JSON.printOn(sourceUrlList, buffer);
    buffer.add(',\n');
    buffer.add('  "names": ');
    JSON.printOn(sourceNameList, buffer);
    buffer.add('\n}\n');
    return buffer.toString();
  }

  void writeEntry(SourceMappingEntry entry,
                  SourceFile targetFile,
                  StringBuffer output) {
    if (entry.sourceFile === null) {
      return;
    }
    int targetLine = targetFile.getLine(entry.targetOffset);
    int targetColumn = targetFile.getColumn(targetLine, entry.targetOffset);
    String sourceUrl = entry.sourceFile.filename;
    int sourceLine = entry.sourceFile.getLine(entry.sourceOffset);
    int sourceColumn = entry.sourceFile.getColumn(sourceLine,
                                                  entry.sourceOffset);
    String sourceName = entry.sourceName;

    if (targetLine > previousTargetLine) {
      for (int i = previousTargetLine; i < targetLine; ++i) {
        output.add(';');
      }
      previousTargetLine = targetLine;
      previousTargetColumn = 0;
      firstEntryInLine = true;
    }

    if (!firstEntryInLine) {
      output.add(',');
    }
    firstEntryInLine = false;

    encodeVLQ(output, targetColumn - previousTargetColumn);
    previousTargetColumn = targetColumn;

    if (sourceUrl === null) {
      return;
    }

    int sourceUrlIndex = indexOf(sourceUrlList, sourceUrl, sourceUrlMap);
    encodeVLQ(output, sourceUrlIndex - previousSourceUrlIndex);
    previousSourceUrlIndex = sourceUrlIndex;

    encodeVLQ(output, sourceLine - previousSourceLine);
    previousSourceLine = sourceLine;
    encodeVLQ(output, sourceColumn - previousSourceColumn);
    previousSourceColumn = sourceColumn;

    if (sourceName === null) {
      return;
    }

    int sourceNameIndex = indexOf(sourceNameList, sourceName, sourceNameMap);
    encodeVLQ(output, sourceNameIndex - previousSourceNameIndex);
    previousSourceNameIndex = sourceNameIndex;
  }

  int indexOf(List<String> list, String value, Map<String, int> map) {
    return map.putIfAbsent(value, () {
      int index = list.length;
      map[value] = index;
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
      output.add(BASE64_DIGITS[digit]);
    } while (value > 0);
  }
}
