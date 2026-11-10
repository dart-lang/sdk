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

      // A concurrent Dart process on the machine may be starting up or exiting
      // with under 1024 KB RSS, which integer-divides to 0 MB. At least the
      // current test process should report non-zero memory.
      expect(results!.map((p) => p.memoryMb), contains(greaterThan(0)));
      for (var process in results) {
        expect(process.memoryMb, greaterThanOrEqualTo(0));
        expect(process.cpuPercent, greaterThanOrEqualTo(0.0));
        expect(process.elapsedTime, isNotEmpty);
        if (!(process.commandLine.startsWith('dart') ||
            process.commandLine.contains('snapshot'))) {
          print(
            "Expected ${process.commandLine} to start with 'dart' or"
            " contain 'snapshot'.",
          );
          expect(true, false);
        }
      }
    });

    test('parseLinux', () {
      const line =
          '35472   0.0    20:41:58 /path/to/dart --disable-dart-dev '
          '/home/foo/flutter_tools.snapshot daemon';

      var result = ProcessInfo.parseLinux(line);
      expect(result, isNotNull);
      expect(result!.command, 'dart');
      expect(result.cpuPercent, 0.0);
      expect(result.memoryMb, 34);

      const smallRssLine = '512   0.0    00:00:00 /path/to/dart run';
      var smallRssResult = ProcessInfo.parseLinux(smallRssLine);
      expect(smallRssResult, isNotNull);
      expect(smallRssResult!.command, 'dart');
      expect(smallRssResult.memoryMb, 0);
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
      expect(output, contains(RegExp('| dart(vm)? ')));
    });
  }, timeout: longTimeout);
}
