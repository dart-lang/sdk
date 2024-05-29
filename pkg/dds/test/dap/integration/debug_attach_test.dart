// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'test_client.dart';
import 'test_scripts.dart';
import 'test_support.dart';

main() {
  group('debug mode', () {
    late DapTestSession dap;
    setUp(() async {
      dap = await DapTestSession.setUp();
    });
    tearDown(() => dap.tearDown());

    test('can attach to a simple script using vmServiceUri', () async {
      final testFile = dap.createTestFile(simpleArgPrintingProgram);

      final args = ['one', 'two'];
      final proc = await startDartProcessPaused(
        testFile.path,
        args,
        cwd: dap.testAppDir.path,
        pauseOnExit: true, // To ensure we capture all output
      );
      final vmServiceUri = await waitForStdoutVmServiceBanner(proc);

      final outputEvents = await dap.client.collectOutput(
        launch: () => dap.client.attach(
          vmServiceUri: vmServiceUri.toString(),
          autoResumeOnEntry: true,
          autoResumeOnExit: true,
          cwd: dap.testAppDir.path,
        ),
      );

      expectLines(outputEvents.map((output) => output.output).join(), [
        startsWith('Connecting to VM Service at ws://127.0.0.1:'),
        'Connected to the VM Service.',
        startsWith('The Dart VM service is listening on'),
        startsWith('The Dart DevTools debugger and profiler is available at'),
        'Hello!',
        'World!',
        'args: [one, two]',
        '',
        'Exited.',
      ]);

      // Ensure the categories were set correctly.
      for (final output in outputEvents) {
        if (output.output.contains('VM Service') ||
            output.output.contains('Exited')) {
          expect(output.category, anyOf('console', isNull));
        } else {
          // User output.
          expect(output.category, 'stdout');
        }
      }
    });

    test('can attach to a simple script using vmServiceInfoFile', () async {
      final testFile = dap.createTestFile(simpleArgPrintingProgram);

      // Spawn the program using --write-service-info which we'll pass the path
      // of directly to the DAP to read.
      final vmServiceInfoFilePath = path.join(
        dap.testAppDir.path,
        'vmServiceInfo.json',
      );
      await startDartProcessPaused(
        testFile.path,
        ['one', 'two'],
        cwd: dap.testAppDir.path,
        vmArgs: ['--write-service-info=${Uri.file(vmServiceInfoFilePath)}'],
        pauseOnExit: true, // To ensure we capture all output
      );
      final outputEvents = await dap.client.collectOutput(
        launch: () => dap.client.attach(
          vmServiceInfoFile: vmServiceInfoFilePath,
          autoResumeOnEntry: true,
          autoResumeOnExit: true,
          cwd: dap.testAppDir.path,
        ),
      );

      expectLines(outputEvents.map((output) => output.output).join(), [
        startsWith('Connecting to VM Service at ws://127.0.0.1:'),
        'Connected to the VM Service.',
        startsWith('The Dart VM service is listening on'),
        startsWith('The Dart DevTools debugger and profiler is available at'),
        'Hello!',
        'World!',
        'args: [one, two]',
        '',
        'Exited.',
      ]);

      // Ensure the categories were set correctly.
      for (final output in outputEvents) {
        if (output.output.contains('VM Service') ||
            output.output.contains('Exited')) {
          expect(output.category, anyOf('console', isNull));
        } else {
          // User output.
          expect(output.category, 'stdout');
        }
      }
    });

    test('reports initialization failures if can\'t connect to the VM Service',
        () async {
      final outputEvents = await dap.client.collectOutput(
        launch: () => dap.client.attach(
          vmServiceUri: 'ws://bogus.local/',
          autoResumeOnEntry: false,
          autoResumeOnExit: false,
        ),
      );

      expect(
        outputEvents.map((e) => e.output).join(),
        allOf(
          contains('Failed to start DDS for ws://bogus.local/'),
          contains('Failed host lookup'),
        ),
      );
    });

    test('removes breakpoints/pause and resumes on detach', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointAndThrowProgram);

      final proc = await startDartProcessPaused(
        testFile.path,
        [],
        cwd: dap.testAppDir.path,
        // Disable user-pause-on-exit because we're checking DAP resumes and
        // if the VM waits for user-resume, we won't complete. We don't want to
        // send an explicit user-resume because that would force resume,
        // invalidating this test that we did a DAP resume.
        pauseOnExit: false,
      );
      final vmServiceUri = await waitForStdoutVmServiceBanner(proc);

      // Attach to the paused script without resuming and wait for the startup
      // pause event.
      await Future.wait([
        client.expectStop('entry'),
        client.start(
          launch: () => client.attach(
            vmServiceUri: vmServiceUri.toString(),
            autoResumeOnEntry: false,
            autoResumeOnExit: false,
            cwd: dap.testAppDir.path,
          ),
        ),
      ]);

      // Set a breakpoint that we expect not to be hit, as detach should disable
      // it and resume.
      final breakpointLine = lineWith(testFile, breakpointMarker);
      await client.setBreakpoint(testFile, breakpointLine);

      // Expect that termination is reported as 'Detached' when we explicitly
      // requested a detach.
      expect(
        client.outputEvents.map((output) => output.output.trim()),
        // emitsThrough because we might still get "Hello" in the output
        // because we resume as part of detach.
        emitsThrough('Detached.'),
      );

      // Detach using terminateRequest. Despite the name, terminateRequest is
      // the request for a graceful detach (and disconnectRequest is the
      // forceful shutdown).
      await client.terminate();

      // Expect the process terminates (and hasn't got stuck on the breakpoint
      // or exception).
      await proc.exitCode;
    });

    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);
}
