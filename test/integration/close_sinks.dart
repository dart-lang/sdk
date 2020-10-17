// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/io.dart';
import 'package:linter/src/cli.dart' as cli;
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('close_sinks', () {
    final currentOut = outSink;
    final collectingOut = CollectingSink();
    setUp(() {
      exitCode = 0;
      outSink = collectingOut;
    });
    tearDown(() {
      collectingOut.buffer.clear();
      outSink = currentOut;
      exitCode = 0;
    });

    test('close sinks', () async {
      var packagesFilePath = File('.packages').absolute.path;
      await cli.run([
        '--packages',
        packagesFilePath,
        'test/_data/close_sinks',
        '--rules=close_sinks'
      ]);
      expect(
          collectingOut.trim(),
          stringContainsInOrder([
            'IOSink _sinkA; // LINT',
            'IOSink _sinkSomeFunction; // LINT',
            '1 file analyzed, 2 issues found, in'
          ]));
      expect(exitCode, 1);
    });
  });
}
