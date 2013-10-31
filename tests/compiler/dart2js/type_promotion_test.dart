// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that dart2js produces the expected static type warnings for type
// promotion langauge tests. This ensures that the analyzer and dart2js agrees
// on these tests.

import 'dart:async';
import 'dart:io';
import 'package:expect/expect.dart';
import 'memory_compiler.dart';
import '../../../sdk/lib/_internal/compiler/implementation/filenames.dart';
import '../../../sdk/lib/_internal/compiler/implementation/source_file.dart';
import '../../../sdk/lib/_internal/compiler/implementation/source_file_provider.dart';
import '../../../sdk/lib/_internal/compiler/implementation/util/uri_extras.dart';
import 'dart:convert';

const List<String> TESTS = const [
    'language/type_promotion_assign_test.dart',
    'language/type_promotion_closure_test.dart',
    'language/type_promotion_functions_test.dart',
    'language/type_promotion_local_test.dart',
    'language/type_promotion_logical_and_test.dart',
    'language/type_promotion_more_specific_test.dart',
    'language/type_promotion_multiple_test.dart',
    'language/type_promotion_parameter_test.dart',
];

void main() {
  bool isWindows = Platform.isWindows;
  Uri script = currentDirectory.resolveUri(Platform.script);
  bool warningsMismatch = false;
  Future.forEach(TESTS, (String test) {
    Uri uri = script.resolve('../../$test');
    String source = UTF8.decode(readAll(uriPathToNative(uri.path)));
    SourceFile file = new StringSourceFile(
        relativize(currentDirectory, uri, isWindows), source);
    Map<int,String> expectedWarnings = {};
    int lineNo = 0;
    for (String line in source.split('\n')) {
      if (line.contains('///') && line.contains('static type warning')) {
        expectedWarnings[lineNo] = line;
      }
      lineNo++;
    }
    Set<int> unseenWarnings = new Set<int>.from(expectedWarnings.keys);
    DiagnosticCollector collector = new DiagnosticCollector();
    var compiler = compilerFor(const {},
         diagnosticHandler: collector,
         options: ['--analyze-only'],
         showDiagnostics: false);
    return compiler.run(uri).then((_) {
      for (DiagnosticMessage message in collector.warnings) {
        Expect.equals(uri, message.uri);
        int lineNo = file.getLine(message.begin);
        if (expectedWarnings.containsKey(lineNo)) {
          unseenWarnings.remove(lineNo);
        } else {
          warningsMismatch = true;
          print(file.getLocationMessage(
              'Unexpected warning: ${message.message}',
              message.begin, message.end, true, (x) => x));
        }
      }
      if (!unseenWarnings.isEmpty) {
        warningsMismatch = true;
        for (int lineNo in unseenWarnings) {
          String line = expectedWarnings[lineNo];
          print('$uri [${lineNo+1}]: Missing static type warning.');
          print(line);
        }
      }
    });
  }).then((_) {
    Expect.isFalse(warningsMismatch);
  });
}
