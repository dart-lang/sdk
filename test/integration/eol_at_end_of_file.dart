// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/cli.dart' as cli;
import 'package:test/test.dart';

import '../mocks.dart';
import '../test_constants.dart';

void main() {
  group('eol_at_end_of_file', () {
    var currentOut = outSink;
    var collectingOut = CollectingSink();
    setUp(() => outSink = collectingOut);
    tearDown(() {
      collectingOut.buffer.clear();
      outSink = currentOut;
    });
    test('eol at end of file', () async {
      await cli.runLinter([
        '$integrationTestDir/eol_at_end_of_file',
        '--rules=eol_at_end_of_file',
      ], LinterOptions());
      expect(
          collectingOut.trim(), contains('5 files analyzed, 3 issues found'));
      expect(collectingOut.trim(),
          contains('Put a single newline at end of file'));
    });
  });
}
