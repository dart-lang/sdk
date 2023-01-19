// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/utilities/legacy.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/cli.dart' as cli;
import 'package:test/test.dart';

import '../mocks.dart';
import '../test_constants.dart';

void main() {
  group('use_build_context_synchronously', () {
    var currentOut = outSink;
    var collectingOut = CollectingSink();
    setUp(() {
      noSoundNullSafety = false;
      return outSink = collectingOut;
    });
    tearDown(() {
      noSoundNullSafety = true;
      collectingOut.buffer.clear();
      outSink = currentOut;
    });
    //https://github.com/dart-lang/linter/issues/2572
    test('mixed_mode', () async {
      await cli.runLinter([
        '$integrationTestDir/use_build_context_synchronously/lib/unmigrated.dart',
        '--rules=use_build_context_synchronously',
      ], LinterOptions());
      var out = collectingOut.trim();
      expect(out, contains('1 file analyzed, 1 issue found'));
      expect(out, contains('22:3'));
    });
  });
}
