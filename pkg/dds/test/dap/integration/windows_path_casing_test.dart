// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';

import 'test_client.dart';
import 'test_scripts.dart';
import 'test_support.dart';

main() {
  group('windows path casing', () {
    DapTestSession? dap;
    tearDown(() => dap?.tearDown());

    for (final actualCwdCasing in [null, ...DriveLetterCasing.values]) {
      for (final programCasing in DriveLetterCasing.values) {
        for (final cwdCasing in [null, ...DriveLetterCasing.values]) {
          for (final breakpointCasing in DriveLetterCasing.values) {
            test(
                'stops at a breakpoint and can resume (casing: '
                'actualCwd: $actualCwdCasing, '
                'program: $programCasing, '
                'cwd: $cwdCasing, '
                'breakpoint requests: $breakpointCasing)', () async {
              // Set the correct casing of drive letters for this test.
              if (actualCwdCasing != null) {
                Directory.current = Directory(
                  setDriveLetterCasing(Directory.current.path, actualCwdCasing),
                );
              }

              dap = await DapTestSession.setUp();
              final client = dap!.client;

              client.forceProgramDriveLetterCasing = programCasing;
              client.forceCwdDriveLetterCasing = cwdCasing;
              client.forceBreakpointDriveLetterCasing = breakpointCasing;

              final testFile = dap!.createTestFile(simpleBreakpointProgram);
              final breakpointLine = lineWith(testFile, breakpointMarker);

              // Hit the initial breakpoint.
              final stop = await client.hitBreakpoint(
                testFile,
                breakpointLine,
                cwd: cwdCasing == null ? null : dap!.testAppDir.path,
              );

              // Resume and expect termination (as the script will get to the end).
              await Future.wait([
                client.event('terminated'),
                client.continue_(stop.threadId!),
              ], eagerError: true);
            });
          }
        }
      }
    }

    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none, skip: !Platform.isWindows);
}
