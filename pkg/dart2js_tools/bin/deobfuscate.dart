// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math' show max;
import 'package:stack_trace/stack_trace.dart';
import 'package:dart2js_tools/src/trace.dart';
import 'package:dart2js_tools/src/name_decoder.dart';
import 'package:dart2js_tools/src/util.dart';
import 'package:dart2js_tools/src/trace_decoder.dart';

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
    String obfuscatedTrace = new File(args[0]).readAsStringSync();
    String error = extractErrorMessage(obfuscatedTrace);
    var provider = new CachingFileProvider(logger: Logger());
    StackDeobfuscationResult result =
        deobfuscateStack(obfuscatedTrace, provider);
    Frame firstFrame = result.original.frames.first;
    String translatedError =
        translate(error, provider.mappingFor(firstFrame.uri));
    if (translatedError == null) translatedError = '<no error message found>';
    printPadded(translatedError, error, sb);
    int longest =
        result.deobfuscated.frames.fold(0, (m, f) => max(f.member.length, m));
    for (var originalFrame in result.original.frames) {
      var deobfuscatedFrames = result.frameMap[originalFrame];
      if (deobfuscatedFrames == null) {
        printPadded('no mapping', '${originalFrame.location}', sb);
      } else {
        for (var frame in deobfuscatedFrames) {
          printPadded('${frame.member.padRight(longest)} ${frame.location}',
              '${originalFrame.location}', sb);
        }
      }
    }
  } finally {
    print('$sb');
  }
}

final green = stdout.hasTerminal ? '\x1b[32m' : '';
final none = stdout.hasTerminal ? '\x1b[0m' : '';

printPadded(String mapping, String original, sb) {
  var len = mapping.length;
  var s = mapping.indexOf('\n');
  if (s >= 0) len -= s + 1;
  var pad = ' ' * (50 - len);
  sb.writeln('$green$mapping$none$pad ... $original');
}
