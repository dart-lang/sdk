// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_map_builder;


import 'util/util.dart';
import 'scanner/scannerlib.dart' show Token;
import 'source_file.dart';
import 'util/uri_extras.dart' show relativize;

class SourceMapBuilder {
  static const int VLQ_BASE_SHIFT = 5;
  static const int VLQ_BASE_MASK = (1 << 5) - 1;
  static const int VLQ_CONTINUATION_BIT = 1 << 5;
  static const int VLQ_CONTINUATION_MASK = 1 << 5;
  static const String BASE64_DIGITS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmn'
                                      'opqrstuvwxyz0123456789+/';

  final Uri uri;
  final Uri fileUri;

  List<SourceMapEntry> entries;

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

  SourceMapBuilder(this.uri, this.fileUri) {
    entries = new List<SourceMapEntry>();

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

  void addMapping(int targetOffset, SourceFileLocation sourceLocation) {
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

  String build(SourceFile targetFile) {
    StringBuffer mappingsBuffer = new StringBuffer();
    entries.forEach((SourceMapEntry entry) => writeEntry(entry, targetFile,
                                                         mappingsBuffer));
    StringBuffer buffer = new StringBuffer();
    buffer.write('{\n');
    buffer.write('  "version": 3,\n');
    if (uri != null && fileUri != null) {
      buffer.write('  "file": "${relativize(uri, fileUri, false)}",\n');
    }
    buffer.write('  "sourceRoot": "",\n');
    buffer.write('  "sources": ');
    if (uri != null) {
      sourceUrlList =
          sourceUrlList.map((url) => relativize(uri, Uri.parse(url), false))
              .toList();
    }
    printStringListOn(sourceUrlList, buffer);
    buffer.write(',\n');
    buffer.write('  "names": ');
    printStringListOn(sourceNameList, buffer);
    buffer.write(',\n');
    buffer.write('  "mappings": "');
    buffer.write(mappingsBuffer);
    buffer.write('"\n}\n');
    return buffer.toString();
  }

  void writeEntry(SourceMapEntry entry, SourceFile targetFile, StringBuffer output) {
    int targetLine = targetFile.getLine(entry.targetOffset);
    int targetColumn = targetFile.getColumn(targetLine, entry.targetOffset);

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

    String sourceUrl = entry.sourceLocation.getSourceUrl();
    int sourceLine = entry.sourceLocation.getLine();
    int sourceColumn = entry.sourceLocation.getColumn();
    String sourceName = entry.sourceLocation.getSourceName();

    int sourceUrlIndex = indexOf(sourceUrlList, sourceUrl, sourceUrlMap);
    encodeVLQ(output, sourceUrlIndex - previousSourceUrlIndex);
    previousSourceUrlIndex = sourceUrlIndex;

    encodeVLQ(output, sourceLine - previousSourceLine);
    previousSourceLine = sourceLine;
    encodeVLQ(output, sourceColumn - previousSourceColumn);
    previousSourceColumn = sourceColumn;

    if (sourceName == null) {
      return;
    }

    int sourceNameIndex = indexOf(sourceNameList, sourceName, sourceNameMap);
    encodeVLQ(output, sourceNameIndex - previousSourceNameIndex);
    previousSourceNameIndex = sourceNameIndex;
  }

  int indexOf(List<String> list, String value, Map<String, int> map) {
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
  SourceFileLocation sourceLocation;
  int targetOffset;

  SourceMapEntry(this.sourceLocation, this.targetOffset);
}

abstract class SourceFileLocation {
  SourceFile sourceFile;

  SourceFileLocation(this.sourceFile) {
    assert(isValid());
  }

  int line;

  int get offset;

  String getSourceUrl() => sourceFile.filename;

  int getLine() {
    if (line == null) line = sourceFile.getLine(offset);
    return line;
  }

  int getColumn() => sourceFile.getColumn(getLine(), offset);

  String getSourceName();

  bool isValid() => offset < sourceFile.length;
}

class TokenSourceFileLocation extends SourceFileLocation {
  final Token token;

  TokenSourceFileLocation(SourceFile sourceFile, this.token)
    : super(sourceFile);

  int get offset => token.charOffset;

  String getSourceName() {
    if (token.isIdentifier()) return token.value;
    return null;
  }
}

class OffsetSourceFileLocation extends SourceFileLocation {
  final int offset;
  final String sourceName;
  OffsetSourceFileLocation(SourceFile sourceFile, this.offset,
      [this.sourceName]) : super(sourceFile);

  String getSourceName() => sourceName;
}
