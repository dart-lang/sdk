// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('linux')
library;

import 'package:dartdev/src/processes.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('process listing', () {
    test('linux', () {
      var results = ProcessInfo.getProcessInfo();

      expect(results, isNotNull);
      expect(results, isNotEmpty);

      for (var process in results!) {
        expect(process.memoryMb, greaterThan(0));
        expect(process.cpuPercent, greaterThanOrEqualTo(0.0));
        expect(process.elapsedTime, isNotEmpty);
        if (!(process.commandLine.startsWith('dart') ||
            process.commandLine.contains('snapshot'))) {
          print("Expected ${process.commandLine} to start with 'dart' or"
              " contain 'snapshot'.");
          expect(true, false);
        }
      }
    });
  });

  group('info linux', () {
    late TestProject p;

    test('shows process info', () async {
      p = project(mainSrc: 'void main() {}');
      final runResult = await p.run(['info']);

      expect(runResult.stderr, isEmpty);
      expect(runResult.exitCode, 0);

      var output = runResult.stdout as String;

      expect(output, contains('providing this information'));
      expect(output, contains('## Process info'));
      expect(output, contains('Memory |'));
      expect(output, contains('| dart '));
    });
  }, timeout: longTimeout);
}
