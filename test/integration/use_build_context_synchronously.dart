// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/cli.dart' as cli;
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('use_build_context_synchronously', () {
    var currentOut = outSink;
    var collectingOut = CollectingSink();
    setUp(() => outSink = collectingOut);
    tearDown(() {
      collectingOut.buffer.clear();
      outSink = currentOut;
    });
    //https://github.com/dart-lang/linter/issues/2572
    test('mixed_mode', () async {
      await cli.runLinter([
        'test_data/integration/use_build_context_synchronously/lib/unmigrated.dart',
        '--packages',
        'test/rules/.mock_packages',
        '--rules=use_build_context_synchronously',
      ], LinterOptions());
      var out = collectingOut.trim();
      expect(out, contains('1 file analyzed, 1 issue found'));
      expect(out,
          contains('21:3 [lint] Do not use BuildContexts across async gaps.'));
    });
  });
}
