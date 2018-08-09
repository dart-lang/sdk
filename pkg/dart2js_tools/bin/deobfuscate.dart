// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:source_maps/source_maps.dart';
import 'package:source_maps/src/utils.dart';
import 'package:dart2js_tools/src/trace.dart';
import 'package:dart2js_tools/src/sourcemap_helper.dart';
import 'package:dart2js_tools/src/name_decoder.dart';
import 'package:dart2js_tools/src/dart2js_mapping.dart';
import 'package:dart2js_tools/src/util.dart';

/// Script that deobuscates a stack-trace given in a text file.
///
/// To run this script you need 3 or more files:
///
///  * A stacktrace file
///  * The deployed .js file
///  * The corresponding .map file
///
/// There might be more than one .js/.map file if your app is divided in
/// deferred chunks.
///
/// The stack trace file contains a copy/paste of a JavaScript stack trace, of
/// this form:
///
///     at aB.a20 (main.dart.js:71969:32)
///     at aNk.goV (main.dart.js:72040:52)
///     at aNk.gfK (main.dart.js:72038:27)
///     at FE.gtn (main.dart.js:72640:24)
///     at aBZ.ghN (main.dart.js:72642:24)
///     at inheritance (main.dart.js:105334:0)
///     at FE (main.dart.js:5037:18)
///
/// If you download the stacktrace from a production service, you can keep the
/// full URL (including http://....) and this script will simply try to match
/// the name of the file at the end with a file in the current working
/// directory.
///
/// The .js file must contain a `//# sourceMappingURL=` line at the end, which
/// tells this script how to determine the name of the source-map file.
main(List<String> args) {
  if (args.length != 1) {
    print('usage: deobfuscate.dart <stack-trace-file>');
    exit(1);
  }
  var sb = new StringBuffer();
  try {
    deobfuscate(new File(args[0]).readAsStringSync(), sb);
  } finally {
    print('$sb');
  }
}

void deobfuscate(trace, StringBuffer sb) {
  String error = extractErrorMessage(trace);
  String translatedError;
  var provider = new CachingFileProvider();

  List<StackTraceLine> jsStackTrace = parseStackTrace(trace);

  for (StackTraceLine line in jsStackTrace) {
    var uri = resolveUri(line.fileName);
    var mapping = provider.mappingFor(uri);
    if (mapping == null) {
      printPadded('no mapping', line.inlineString, sb);
      continue;
    }

    TargetEntry targetEntry = findColumn(line.lineNo - 1, line.columnNo - 1,
        findLine(mapping.sourceMap, line.lineNo - 1));
    if (targetEntry == null) {
      printPadded('no entry', line.inlineString, sb);
      continue;
    }

    if (translatedError == null) {
      translatedError = translate(error, mapping, line, targetEntry);
      if (translatedError == null) translatedError = '<no error message found>';
      printPadded(translatedError, error, sb);
    }

    int offset =
        provider.fileFor(uri).getOffset(line.lineNo - 1, line.columnNo - 1);

    String nameOf(id) => id != 0 ? mapping.sourceMap.names[id] : null;
    String urlOf(id) => id != 0 ? mapping.sourceMap.urls[id] : null;

    String fileName = urlOf(targetEntry.sourceUrlId ?? 0);
    int targetLine = (targetEntry.sourceLine ?? 0) + 1;
    int targetColumn = (targetEntry.sourceColumn ?? 0) + 1;

    // Expand inlined frames.
    Map<int, List<FrameEntry>> frames = mapping.frames;
    List<int> index = mapping.frameIndex;
    int key = binarySearch(index, (i) => i > offset) - 1;
    int depth = 0;
    outer:
    while (key >= 0) {
      for (var frame in frames[index[key]].reversed) {
        if (frame.isEmpty) break outer;
        if (frame.isPush) {
          if (depth <= 0) {
            var mappedLine = new StackTraceLine(
                frame.inlinedMethodName + "(inlined)",
                fileName,
                targetLine,
                targetColumn);
            printPadded(mappedLine.inlineString, "", sb);
            fileName = frame.callUri;
            targetLine = (frame.callLine ?? 0) + 1;
            targetColumn = (frame.callColumn ?? 0) + 1;
          } else {
            depth--;
          }
        }
        if (frame.isPop) {
          depth++;
        }
      }
      key--;
    }

    var functionEntry = findEnclosingFunction(provider, uri, offset);
    String methodName = nameOf(functionEntry.sourceNameId ?? 0);
    var mappedLine =
        new StackTraceLine(methodName, fileName, targetLine, targetColumn);
    printPadded(mappedLine.inlineString, line.inlineString, sb);
  }
}

final green = stdout.hasTerminal ? '[32m' : '';
final none = stdout.hasTerminal ? '[0m' : '';

printPadded(String mapping, String original, sb) {
  var len = mapping.length;
  var s = mapping.indexOf('\n');
  if (s >= 0) len -= s + 1;
  var pad = ' ' * (50 - len);
  sb.writeln('$green$mapping$none$pad ... $original');
}

Uri resolveUri(String filename) {
  var uri = Uri.base.resolve(filename);
  if (uri.scheme == 'http' || uri.scheme == 'https') {
    filename = uri.path.substring(uri.path.lastIndexOf('/') + 1);
    uri = Uri.base.resolve(filename);
  }
  return uri;
}
