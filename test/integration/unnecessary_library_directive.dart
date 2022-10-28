// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
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
  group('unnecessary_library_directive', () {
    var currentOut = outSink;
    var collectingOut = CollectingSink();
    setUp(() => outSink = collectingOut);
    tearDown(() {
      collectingOut.buffer.clear();
      outSink = currentOut;
    });
    test('unnecessary_library_directive', () async {
      await cli.runLinter([
        '$integrationTestDir/unnecessary_library_directive',
        '--rules=unnecessary_library_directive',
      ], LinterOptions());
      expect(
        collectingOut.trim(),
        startsWith('5 files analyzed, 0 issues found'),
      );
    });
  });
}
