// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that dart2js produces the expected static type warnings to ensures that
// the analyzer and dart2js agrees on the tests.

import 'dart:async';
import 'dart:io';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'memory_compiler.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/io/source_file.dart';
import 'package:compiler/src/source_file_provider.dart';
import 'package:compiler/src/util/uri_extras.dart';
import 'dart:convert';

final _multiTestRegExpSeperator = new RegExp(r"//[#/]");

void checkWarnings(Map<String, dynamic> tests, [List<String> arguments]) {
  bool isWindows = Platform.isWindows;
  Uri script = currentDirectory.resolveUri(Platform.script);
  bool warningsMismatch = false;
  bool verbose = arguments != null && arguments.contains('-v');
  asyncTest(() => Future.forEach(tests.keys, (String test) async {
        Uri uri = script.resolve('../../$test');
        String source = utf8.decode(readAll(uriPathToNative(uri.path)));
        SourceFile file = new StringSourceFile(
            uri, relativize(currentDirectory, uri, isWindows), source);
        Map<int, String> expectedWarnings = {};
        int lineNo = 0;
        for (String line in source.split('\n')) {
          if (line.contains(_multiTestRegExpSeperator) &&
              (line.contains('static type warning') ||
                  line.contains('static warning'))) {
            expectedWarnings[lineNo] = line;
          }
          lineNo++;
        }
        Set<int> unseenWarnings = new Set<int>.from(expectedWarnings.keys);
        DiagnosticCollector collector = new DiagnosticCollector();
        await runCompiler(
            entryPoint: uri,
            diagnosticHandler: collector,
            options: [Flags.analyzeOnly],
            showDiagnostics: verbose);
        Map<String, List<int>> statusMap = tests[test];
        // Line numbers with known unexpected warnings.
        List<int> unexpectedStatus = [];
        if (statusMap != null && statusMap.containsKey('unexpected')) {
          unexpectedStatus = statusMap['unexpected'];
        }
        // Line numbers with known missing warnings.
        List<int> missingStatus = [];
        if (statusMap != null && statusMap.containsKey('missing')) {
          missingStatus = statusMap['missing'];
        }
        for (CollectedMessage message in collector.warnings) {
          Expect.equals(uri, message.uri);
          int lineNo = file.getLocation(message.begin).line - 1;
          if (expectedWarnings.containsKey(lineNo)) {
            unseenWarnings.remove(lineNo);
          } else if (!unexpectedStatus.contains(lineNo + 1)) {
            warningsMismatch = true;
            print(file.getLocationMessage(
                'Unexpected warning: ${message.message}',
                message.begin,
                message.end));
          }
        }
        if (!unseenWarnings.isEmpty) {
          for (int lineNo in unseenWarnings) {
            if (!missingStatus.contains(lineNo + 1)) {
              warningsMismatch = true;
              String line = expectedWarnings[lineNo];
              print('$uri [${lineNo+1}]: Missing static type warning.');
              print(line);
            }
          }
        }
      }).then((_) {
        Expect.isFalse(warningsMismatch);
      }));
}
