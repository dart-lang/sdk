// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('windows')

import 'dart:io';

import 'package:dartdev/src/processes.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('process listing', () {
    test('windows', () {
      var results = ProcessInfo.getProcessInfo();

      expect(results, isNotNull);
      expect(results, isNotEmpty);

      for (var process in results!) {
        expect(process.memoryMb, greaterThan(0));
        expect(process.cpuPercent, null);
        expect(process.elapsedTime, null);
        expect(process.commandLine, startsWith('dart.exe'));
      }
    });

    test('ProcessInfo.parseWindows', () {
      final testLine = '"dart.exe","12068","Console","1","233,384 K"';

      var result = ProcessInfo.parseWindows(testLine);

      expect(result, isNotNull);
      expect(result!.command, 'dart.exe');
      // 233384kb == 227MB
      expect(result.memoryMb, 227);
    });
  }, skip: !Platform.isWindows);

  group('info windows', () {
    late TestProject p;

    test('shows process info', () async {
      p = project(mainSrc: 'void main() {}');
      final runResult = await p.run(['info']);

      expect(runResult.stderr, isEmpty);
      expect(runResult.exitCode, 0);

      var output = runResult.stdout as String;

      expect(output, contains('providing this information'));
      expect(output, contains('## Process info'));
      expect(output, contains(RegExp(r'\|\s+Memory')));
      expect(output, contains(RegExp(r'\|\s+dart.exe ')));
    });
  }, timeout: longTimeout, skip: !Platform.isWindows);
}
