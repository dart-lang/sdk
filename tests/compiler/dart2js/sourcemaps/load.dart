// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Loads a source map file and outputs a human-readable version of it.

library load;

import 'dart:convert';
import 'dart:io';
import 'package:source_maps/source_maps.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('''
Usage: load <dir-containing 'out.js.map'>
   or: load <source-map-file> [<human-readable-source-map-file>]''');
    exit(1);
  }

  File humanReadableSourceMapFile;
  File sourceMapFile;
  if (args.length == 1 && new Directory(args[0]).existsSync()) {
    humanReadableSourceMapFile = new File('${args[0]}/out.js.map2');
    sourceMapFile = new File('${args[0]}/out.js.map');
  } else {
    sourceMapFile = new File(args[0]);
    if (args.length > 1) {
      humanReadableSourceMapFile = new File(args[1]);
    }
  }
  mainInternal(sourceMapFile, humanReadableSourceMapFile);
}

void mainInternal(File sourceMapFile, File humanReadableSourceMapFile) {
  SingleMapping sourceMap =
      new SingleMapping.fromJson(JSON.decode(sourceMapFile.readAsStringSync()));
  String humanReadableSourceMap = convertToHumanReadableSourceMap(sourceMap);
  if (humanReadableSourceMapFile != null) {
    humanReadableSourceMapFile.writeAsStringSync(humanReadableSourceMap);
  } else {
    print(humanReadableSourceMap);
  }
}

String convertToHumanReadableSourceMap(SingleMapping sourceMap) {
  StringBuffer sb = new StringBuffer();
  sb.write('{\n');
  sb.write('  "file": "${sourceMap.targetUrl}",\n');
  sb.write('  "sourceRoot": "${sourceMap.sourceRoot}",\n');
  sb.write('  "sources": {\n');
  for (int index = 0; index < sourceMap.urls.length; index++) {
    if (index > 0) {
      sb.write(',\n');
    }
    sb.write('    "$index": "${sourceMap.urls[index]}"');
  }
  sb.write('\n  },\n');
  sb.write('  "lines": [\n');
  bool needsComma = false;
  for (int lineIndex = 0; lineIndex < sourceMap.lines.length; lineIndex++) {
    TargetLineEntry lineEntry = sourceMap.lines[lineIndex];
    int line = lineEntry.line + 1;
    for (int entryIndex = 0;
        entryIndex < lineEntry.entries.length;
        entryIndex++) {
      TargetEntry entry = lineEntry.entries[entryIndex];
      int columnStart = entry.column + 1;
      int columnEnd;
      String position;
      if (entryIndex + 1 < lineEntry.entries.length) {
        columnEnd = lineEntry.entries[entryIndex + 1].column + 1;
        position = '$line,$columnStart-$columnEnd';
      } else {
        position = '$line,$columnStart-';
      }
      if (entry.sourceUrlId != null || columnEnd == null) {
        if (needsComma) {
          sb.write(',\n');
        }
        sb.write('    {"target": "$position"');
        if (entry.sourceUrlId != null) {
          int sourceUrlId = entry.sourceUrlId;
          int sourceLine = entry.sourceLine + 1;
          int sourceColumn = entry.sourceColumn + 1;
          sb.write(', "source": "$sourceUrlId:$sourceLine,$sourceColumn"');
          if (entry.sourceNameId != null) {
            sb.write(', "name": "${sourceMap.names[entry.sourceNameId]}"');
          }
        }
        sb.write('}');
        needsComma = true;
      }
    }
  }
  sb.write('\n  ]\n');
  sb.write('}');
  return sb.toString();
}
