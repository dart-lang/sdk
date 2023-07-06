// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:dap/dap.dart';
import 'package:test/test.dart';

import 'test_client.dart';
import 'test_scripts.dart';
import 'test_support.dart';

main() {
  late DapTestSession dap;
  setUp(() async {
    dap = await DapTestSession.setUp(additionalArgs: ['--test']);
    await dap.addPackageDependency(dap.testAppDir, 'test');
  });
  tearDown(() => dap.tearDown());

  group('dart test', () {
    /// A helper that verifies a full set of expected test results for the
    /// [simpleTestProgram] script.
    void expectStandardSimpleTestResults(TestEvents events) {
      // Check we received all expected test events passed through from
      // package:test.
      final eventNames =
          events.testNotifications.map((e) => e['type']).toList();

      // start/done should always be first/last.
      expect(eventNames.first, equals('start'));
      expect(eventNames.last, equals('done'));

      // allSuites should have occurred after start.
      expect(
        eventNames,
        containsAllInOrder(['start', 'allSuites']),
      );

      // Expect two tests, with the failing one emitting an error.
      expect(
        eventNames,
        containsAllInOrder([
          'testStart',
          'testDone',
          'testStart',
          'error',
          'testDone',
        ]),
      );
    }

    test('can run without debugging', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleTestProgram);

      // Collect output and test events while running the script.
      final outputEvents = await client.collectTestOutput(
        launch: () => client.launch(
          testFile.path,
          noDebug: true,
          cwd: dap.testAppDir.path,
          args: ['--chain-stack-traces'], // to suppress warnings in the output
        ),
      );

      // Check the printed output shows that the run finished, and it's exit
      // code (which is 1 due to the failing test).
      final output = outputEvents.output.map((e) => e.output).join();
      expectLines(output, simpleTestProgramExpectedOutput);

      expectStandardSimpleTestResults(outputEvents);
    });

    test('can run a single test', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleTestProgram);

      // Collect output and test events while running the script.
      final outputEvents = await client.collectTestOutput(
        launch: () => client.launch(
          testFile.path,
          noDebug: true,
          cwd: dap.testAppDir.path,
          // It's up to the calling IDE to pass the correct args for 'dart test'
          // if it wants to run a subset of tests.
          args: [
            '--plain-name',
            'passing test',
          ],
        ),
      );

      final testsNames = outputEvents.testNotifications
          .where((e) => e['type'] == 'testStart')
          .map((e) => (e['test'] as Map<String, Object?>)['name'])
          .toList();

      expect(testsNames, contains('group 1 passing test'));
      expect(testsNames, isNot(contains('group 1 failing test')));
    });

    test('includes absolute paths in OutputEvent metadata', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleFailingTestProgram);

      // Collect output and test events while running the script.
      final outputEvents = await client.collectTestOutput(
        launch: () => client.launch(
          testFile.path,
          cwd: dap.testAppDir.path,
        ),
      );

      // Collect paths from any OutputEvents that had them.
      final stackFramePaths = outputEvents.output
          .map((event) => event.source?.path)
          .whereNotNull()
          .toList();
      // Ensure we had a frame with the absolute path of the test script.
      expect(stackFramePaths, contains(testFile.path));
    });

    test('can hit and resume from a breakpoint', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleTestProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      // Collect output and test events while running the script.
      final outputEvents = await client.collectTestOutput(
        // When launching, hit a breakpoint and resume.
        start: () => client.hitBreakpoint(
          testFile,
          breakpointLine,
          cwd: dap.testAppDir.path,
          args: ['--chain-stack-traces'], // to suppress warnings in the output
        ).then((stop) => client.continue_(stop.threadId!)),
      );

      // Check the usual output and test events to ensure breaking/resuming did
      // not affect the results.
      final output = outputEvents.output
          .map((e) => e.output)
          .skipWhile(dapVmServiceBannerPattern.hasMatch)
          .join();
      expectLines(output, simpleTestProgramExpectedOutput);
      expectStandardSimpleTestResults(outputEvents);
    });

    test('can cleanly terminate from a breakpoint', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleTestProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      // Hit the breakpoint inside the test.
      await client.hitBreakpoint(
        testFile,
        breakpointLine,
        cwd: dap.testAppDir.path,
      );

      // Send a single terminate, and expect a clean exit (with a `terminated`
      // event).
      await Future.wait([
        dap.client.event('terminated'),
        dap.client.terminate(),
      ], eagerError: true);
    });

    test('resolves and updates breakpoints', () async {
      final client = dap.client;
      final testFile =
          dap.createTestFile(simpleTestBreakpointResolutionProgram);
      final setBreakpointLine = lineWith(testFile, breakpointMarker);
      final expectedResolvedBreakpointLine = setBreakpointLine + 1;

      // Collect any breakpoint changes during the run.
      final breakpointChangesFuture = client.breakpointChangeEvents.toList();

      Future<SetBreakpointsResponseBody> setBreakpointFuture;
      await Future.wait([
        client
            .expectStop('breakpoint',
                file: testFile, line: expectedResolvedBreakpointLine)
            .then((_) => client.terminate()),
        client.initialize(),
        setBreakpointFuture = client.setBreakpoint(testFile, setBreakpointLine),
        client.launch(testFile.path),
      ], eagerError: true);

      // The initial setBreakpointResponse should always return unverified
      // because we verify using the BreakpointAdded/BreakpointResolved events.
      final setBreakpointResponse = await setBreakpointFuture;
      expect(setBreakpointResponse.breakpoints, hasLength(1));
      final setBreakpoint = setBreakpointResponse.breakpoints.single;
      expect(setBreakpoint.verified, isFalse);

      // The last breakpoint change we had should be verified and also update
      // the line to [expectedResolvedBreakpointLine] since the breakpoint was
      // on a blank line.
      final breakpointChanges = await breakpointChangesFuture;
      final updatedBreakpoint = breakpointChanges.last.breakpoint;
      expect(updatedBreakpoint.verified, isTrue);
      expect(updatedBreakpoint.line, expectedResolvedBreakpointLine);
    });

    test('resolves modified breakpoints', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleTestMultiBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      // Start the app and hit the initial breakpoint.
      await client.hitBreakpoint(testFile, breakpointLine);

      // Collect IDs of all breakpoints that get resolved.
      final resolvedBreakpoints = <int>{};
      final breakpointResolveSubscription =
          client.breakpointChangeEvents.listen((event) {
        if (event.breakpoint.verified) {
          resolvedBreakpoints.add(event.breakpoint.id!);
        } else {
          resolvedBreakpoints.remove(event.breakpoint.id!);
        }
      });

      // Add breakpoints to the 4 lines after the current one, one at a time.
      // Capture the IDs of all breakpoints added.
      final breakpointLinesToSend = <int>[breakpointLine];
      final addedBreakpoints = <int>{};
      for (var i = 1; i <= 4; i++) {
        breakpointLinesToSend.add(breakpointLine + i);
        final response =
            await client.setBreakpoints(testFile, breakpointLinesToSend);
        for (final breakpoint in response.breakpoints) {
          addedBreakpoints.add(breakpoint.id!);
        }
      }

      await pumpEventQueue(times: 5000);
      await breakpointResolveSubscription.cancel();

      // Ensure every breakpoint that was added was also resolved.
      expect(resolvedBreakpoints, addedBreakpoints);
    });

    test('responds to setBreakpoints before any breakpoint events', () async {
      final client = dap.client;
      final testFile =
          dap.createTestFile(simpleTestBreakpointResolutionProgram);
      final setBreakpointLine = lineWith(testFile, breakpointMarker);

      // Run the app and get to a breakpoint. This will allow us to add new
      // breakpoints in the same file that are _immediately_ resolved.
      await Future.wait([
        client.initialize(),
        client.expectStop('breakpoint'),
        client.setBreakpoint(testFile, setBreakpointLine),
        client.launch(testFile.path),
      ], eagerError: true);

      // Call setBreakpoint again, and ensure it response before we get any
      // breakpoint change events because we require their IDs before the change
      // events are sent.
      var setBreakpointsResponded = false;
      await Future.wait([
        client.breakpointChangeEvents.first.then((_) {
          if (!setBreakpointsResponded) {
            throw 'breakpoint change event arrived before '
                'setBreakpoints completed';
          }
        }),
        client
            // Send 50 breakpoints for lines 1-50 to ensure we spend some time
            // sending requests to the VM to allow events to start coming back
            // from the VM before we complete. Without this, the test can pass
            // even without the fix.
            .setBreakpoints(testFile, List.generate(50, (index) => index))
            .then((_) => setBreakpointsResponded = true),
      ]);
    });

    test('rejects attaching', () async {
      final client = dap.client;

      final outputEvents = await client.collectTestOutput(
        launch: () => client.attach(
          vmServiceUri: 'ws://bogus.local/',
          autoResume: false,
        ),
      );

      final output = outputEvents.output.map((e) => e.output).join();
      expectLines(output, [
        'Attach is not supported for test runs',
        '',
        'Exited.',
      ]);
    });

    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);
}
