// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'test_client.dart';
import 'test_scripts.dart';
import 'test_support.dart';

main() {
  late DapTestSession dap;
  setUp(() async {
    dap = await DapTestSession.setUp();
  });
  tearDown(() => dap.tearDown());

  group('debug mode breakpoints', () {
    testWithUriConfigurations(() => dap, 'stops at a line breakpoint',
        () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      await client.hitBreakpoint(testFile, breakpointLine);
    });

    testWithUriConfigurations(() => dap, 'resolves modified breakpoints',
        () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleMultiBreakpointProgram);
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
      final breakpointLinesToSend = <int>[];
      final addedBreakpoints = <int>{};
      for (var i = 1; i <= 4; i++) {
        breakpointLinesToSend.add(breakpointLine + i);
        final response =
            await client.setBreakpoints(testFile, breakpointLinesToSend);
        for (final breakpoint in response.breakpoints) {
          addedBreakpoints.add(breakpoint.id!);
        }
      }

      // Wait up to a few seconds for the resolved events to come through to
      // allow for slow CI bots, but exit early if they all arrived.
      final testUntil = DateTime.now().toUtc().add(const Duration(seconds: 5));
      while (DateTime.now().toUtc().isBefore(testUntil) &&
          resolvedBreakpoints.length < addedBreakpoints.length) {
        await pumpEventQueue(times: 5000);
      }
      await breakpointResolveSubscription.cancel();

      // Ensure every breakpoint that was added was also resolved.
      expect(resolvedBreakpoints, addedBreakpoints);
    });

    testWithUriConfigurations(() => dap,
        'does not re-resolve existing breakpoints when new ones are added',
        () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleMultiBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      // Start the app and hit the initial breakpoint.
      await client.hitBreakpoint(testFile, breakpointLine);

      // Collect any breakpoint events in a simple text format for verifying.
      final breakpointEvents = <String>[];
      final breakpointResolveSubscription =
          client.breakpointChangeEvents.listen((event) {
        var breakpoint = event.breakpoint;
        var id = breakpoint.id!;
        var verified = breakpoint.verified;
        var reason = breakpoint.reason;
        var description = verified ? 'verified' : 'not verified ($reason)';
        breakpointEvents.add('Breakpoint $id $description');
      });

      // Test adding breakpoints to the 4 lines after the first breakpoint, one
      // at a time. Each request contains the total set of breakpoints (so the
      // first request has one breakpoint and the last request has all 4). In
      // each response, we expect the previous breakpoints to be
      // already-verified and to not get events for them. For the last one
      // breakpoint, it will not be verified and we will then get an event.
      var breakpointLines = <int>[];
      var seenBreakpointIds = <int>{};
      for (var i = 1; i <= 4; i++) {
        breakpointEvents.clear(); // Clear any events from previous iterations.

        // Add an additional breakpoint on the next line.
        breakpointLines.add(breakpointLine + i);
        final response = await client.setBreakpoints(testFile, breakpointLines);
        expect(response.breakpoints, hasLength(i));

        // Wait up to a few seconds for a resolved events to come through.
        final testUntil =
            DateTime.now().toUtc().add(const Duration(seconds: 5));
        while (DateTime.now().toUtc().isBefore(testUntil) &&
            breakpointEvents.isEmpty) {
          await pumpEventQueue(times: 5000);
        }

        // Verify the results for this iteration.
        for (var j = 0; j < i; j++) {
          // j is zero-based but i is one-based
          final breakpoint = response.breakpoints[j];
          final id = breakpoint.id!;

          // All but the last should be verified already and have existing IDs.
          if (j == i - 1) {
            expect(seenBreakpointIds.contains(id), isFalse,
                reason:
                    'Last breakpoint (index $j) should have a new unseen ID');
            expect(breakpoint.verified, isFalse,
                reason:
                    'Last breakpoint (index $j) should not yet be verified');
            seenBreakpointIds.add(id);
          } else {
            expect(seenBreakpointIds.contains(id), isTrue,
                reason:
                    'Non-last breakpoint (index $j) should have an already-seen ID because it was reused');
            expect(breakpoint.verified, isTrue,
                reason:
                    'Non-last breakpoint (index $j) should already be verified');
          }
        }

        // We should have had one event for that last one to be verified (others
        // were already verified).
        expect(breakpointEvents,
            ['Breakpoint ${response.breakpoints.last.id} verified']);
      }

      await breakpointResolveSubscription.cancel();
    });

    testWithUriConfigurations(
        () => dap, 'provides reason for failed breakpoints', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(debuggerPauseProgram);
      final invalidBreakpointLine = 9999;

      // Start running the app.
      await Future.wait([
        client.initialize(),
        client.launch(testFile.path),
      ], eagerError: true);

      // Collect reasons from all breakpoint events.
      final breakpointReasons = <String?>[];
      final breakpointChangedSubscription =
          client.breakpointChangeEvents.listen((event) {
        breakpointReasons
            .add('${event.breakpoint.reason}: ${event.breakpoint.message}');
      });

      // Set the breakpoint and also collect the original reason.
      var bps = await client.setBreakpoint(testFile, invalidBreakpointLine);
      var bp = bps.breakpoints.single;
      breakpointReasons.add('${bp.reason}: ${bp.message}');

      // Wait up to a few seconds for the change events to come through to
      // allow for slow CI bots, but exit early if they all arrived.
      final testUntil = DateTime.now().toUtc().add(const Duration(seconds: 5));
      while (DateTime.now().toUtc().isBefore(testUntil) &&
          breakpointReasons.length < 2) {
        await pumpEventQueue(times: 5000);
      }

      expect(
          breakpointReasons,
          equals([
            'pending: Breakpoint has not yet been resolved',
            'failed: No debuggable code where breakpoint was requested'
          ]));

      await breakpointChangedSubscription.cancel();
    });

    testWithUriConfigurations(
        () => dap, 'provides reason for not-yet-resolved breakpoints',
        () async {
      final client = dap.client;
      final testFile = dap.createTestFile(debuggerPauseProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      // Start running the app.
      await Future.wait([
        client.initialize(),
        client.launch(testFile.path),
      ], eagerError: true);

      // Set a breakpoint and verify the result.
      var bps = await client.setBreakpoint(testFile, breakpointLine);
      expect(bps.breakpoints.single.reason, 'pending');
      expect(bps.breakpoints.single.message,
          'Breakpoint has not yet been resolved');
    });

    test('responds to setBreakpoints before any breakpoint events', () async {
      final client = dap.client;
      final testFile =
          dap.createTestFile(simpleBreakpointProgramWith50ExtraLines);
      final setBreakpointLine = lineWith(testFile, breakpointMarker);

      // Run the app and get to a breakpoint. This will allow us to add new
      // breakpoints in the same file that are _immediately_ resolved.
      await client.hitBreakpoint(testFile, setBreakpointLine);

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
            // Send 50 breakpoints for the next 50 lines to ensure we spend some
            // time sending requests to the VM to allow events to start coming
            // back from the VM before we complete. Without this, the test can
            // pass even without the fix.
            .setBreakpoints(testFile,
                List.generate(50, (index) => setBreakpointLine + index))
            .then((_) => setBreakpointsResponded = true),
      ]);
    });

    test('does not stop at a removed breakpoint', () async {
      final testFile = dap.createTestFile('''
void main(List<String> args) async {
  print('Hello!'); $breakpointMarker
  print('Hello!'); $breakpointMarker
}
    ''');

      final client = dap.client;
      final breakpoint1Line = lineWith(testFile, breakpointMarker);
      final breakpoint2Line = breakpoint1Line + 1;

      // Hit the first breakpoint.
      final stop = await client.hitBreakpoint(testFile, breakpoint1Line,
          additionalBreakpoints: [breakpoint2Line]);

      // Remove all breakpoints.
      await client.setBreakpoints(testFile, []);

      // Resume and expect termination (should not hit the second breakpoint).
      await Future.wait([
        client.event('terminated'),
        client.continue_(stop.threadId!),
      ], eagerError: true);
    });

    test('does not fail updating breakpoints after a removal', () async {
      // https://github.com/flutter/flutter/issues/106369 was caused by us not
      // tracking removals correctly, meaning we could try to remove a removed
      // breakpoint a second time.
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      await client.hitBreakpoint(testFile, breakpointLine);

      // Remove the breakpoint.
      await client.setBreakpoints(testFile, []);

      // Send another breakpoint update to ensure it doesn't try to re-remove
      // the previously removed breakpoint.
      await client.setBreakpoints(testFile, []);
    });

    test(
        'does not fail updating breakpoints after a removal '
        'if two breakpoints resolved to the same location', () async {
      final client = dap.client;
      final testFile =
          dap.createTestFile(simpleBreakpointWithLeadingBlankLineProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final beforeBreakpointLine = breakpointLine - 1;

      // Hit the breakpoint line first to ensure the function is compiled. This
      // is required to ensure the VM gives us back the same breakpoint ID for
      // the two locations.
      await client.hitBreakpoint(testFile, breakpointLine);

      // Add breakpoints to both lines.
      await client.setBreakpoints(
        testFile,
        [breakpointLine, beforeBreakpointLine],
      );

      // Remove all breakpoints (which in reality, is just one).
      await client.setBreakpoints(testFile, []);
    });

    test('stops at a line breakpoint in the SDK set via local sources',
        () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);

      // Add the breakpoint to the first line inside the SDK's print function.
      final sdkFile = File(path.join(sdkRoot, 'lib', 'core', 'print.dart'));
      final breakpointLine = lineWith(sdkFile, 'print(Object? object) {') + 1;

      await client.hitBreakpoint(sdkFile, breakpointLine, entryFile: testFile);
    });

    /// Tests hitting a simple breakpoint and resuming.
    Future<void> testHitBreakpointAndResume() async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      // Hit the initial breakpoint.
      final stop = await client.hitBreakpoint(testFile, breakpointLine);

      // Resume and expect termination (as the script will get to the end).
      await Future.wait([
        client.event('terminated'),
        client.continue_(stop.threadId!),
      ], eagerError: true);
    }

    test('stops at a line breakpoint and can be resumed', () async {
      await testHitBreakpointAndResume();
    });

    test('stops at a line breakpoint and can step over (next)', () async {
      final testFile = dap.createTestFile('''
void main(List<String> args) async {
  print('Hello!'); $breakpointMarker
  print('Hello!'); $stepMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final stepLine = lineWith(testFile, stepMarker);

      // Hit the initial breakpoint.
      final stop = await dap.client.hitBreakpoint(testFile, breakpointLine);

      // Step and expect stopping on the next line with a 'step' stop type.
      await Future.wait([
        dap.client.expectStop('step', file: testFile, line: stepLine),
        dap.client.next(stop.threadId!),
      ], eagerError: true);
    });

    test(
        'stops at a line breakpoint and can step over (next) '
        'when stepping granularity was included', () async {
      final testFile = dap.createTestFile('''
void main(List<String> args) async {
  print('Hello!'); $breakpointMarker
  print('Hello!'); $stepMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final stepLine = lineWith(testFile, stepMarker);

      // Hit the initial breakpoint.
      final stop = await dap.client.hitBreakpoint(testFile, breakpointLine);

      // Step and expect stopping on the next line with a 'step' stop type.
      await Future.wait([
        dap.client.expectStop('step', file: testFile, line: stepLine),
        dap.client.next(stop.threadId!, granularity: 'statement'),
      ], eagerError: true);
    });

    test('ignores resume request for an exited isolate', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(isolateSpawningProgram);

      // Run the script and wait for the isolate to exit.
      final threadExitFuture =
          client.threadEvents.where((event) => event.reason == 'exited').first;
      await Future.wait([
        threadExitFuture,
        client.initialize(),
        client.launch(testFile.path),
      ], eagerError: true);
      final exitedThreadId = (await threadExitFuture).threadId;

      // Try to resume the already-exited thread. It should not fail.
      await client.continue_(exitedThreadId);
    });

    test(
        'stops at a line breakpoint and can step over (next) an async boundary',
        () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
Future<void> main(List<String> args) async {
  await asyncPrint('Hello!'); $breakpointMarker
  await asyncPrint('Hello!'); $stepMarker
}

Future<void> asyncPrint(String message) async {
  await Future.delayed(const Duration(milliseconds: 1));
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final stepLine = lineWith(testFile, stepMarker);

      // Hit the initial breakpoint.
      final stop = await dap.client.hitBreakpoint(testFile, breakpointLine);

      // The first step will move from `asyncPrint` to the `await`.
      await Future.wait([
        client.expectStop('step', file: testFile, line: breakpointLine),
        client.next(stop.threadId!),
      ], eagerError: true);

      // The next step should go over the async boundary and to stepLine (if
      // we did not correctly send kOverAsyncSuspension we would end up in
      // the asyncPrint method).
      await Future.wait([
        client.expectStop('step', file: testFile, line: stepLine),
        client.next(stop.threadId!),
      ], eagerError: true);
    });

    test('stops at a line breakpoint and can step in', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) async {
  log('Hello!'); $breakpointMarker
}

void log(String message) { $stepMarker
  print(message);
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final stepLine = lineWith(testFile, stepMarker);

      // Hit the initial breakpoint.
      final stop = await client.hitBreakpoint(testFile, breakpointLine);

      // Step and expect stopping in the inner function with a 'step' stop type.
      await Future.wait([
        client.expectStop('step', file: testFile, line: stepLine),
        client.stepIn(stop.threadId!),
      ], eagerError: true);
    });

    test('stops at a line breakpoint and can step out', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) async {
  log('Hello!');
  log('Hello!'); $stepMarker
}

void log(String message) {
  print(message); $breakpointMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final stepLine = lineWith(testFile, stepMarker);

      // Hit the initial breakpoint.
      final stop = await client.hitBreakpoint(testFile, breakpointLine);

      // Step and expect stopping in the inner function with a 'step' stop type.
      await Future.wait([
        client.expectStop('step', file: testFile, line: stepLine),
        client.stepOut(stop.threadId!),
      ], eagerError: true);
    });

    test('does not step into SDK code with debugSdkLibraries=false', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) async {
  print('Hello!'); $breakpointMarker
  print('Hello!'); $stepMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final stepLine = lineWith(testFile, stepMarker);

      // Hit the initial breakpoint.
      final stop = await client.hitBreakpoint(
        testFile,
        breakpointLine,
        launch: () => client.launch(
          testFile.path,
          debugSdkLibraries: false,
        ),
      );

      // Step in and expect stopping on the next line (don't go into print).
      await Future.wait([
        client.expectStop('step', file: testFile, line: stepLine),
        client.stepIn(stop.threadId!),
      ], eagerError: true);
    });

    test('steps into SDK code with debugSdkLibraries=true', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) async {
  print('Hello!'); $breakpointMarker
  print('Hello!');
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      // Hit the initial breakpoint.
      final stop = await dap.client.hitBreakpoint(
        testFile,
        breakpointLine,
        launch: () => client.launch(
          testFile.path,
          debugSdkLibraries: true,
        ),
      );

      // Step in and expect to go into print.
      await Future.wait([
        client.expectStop('step', sourceName: 'dart:core/print.dart'),
        client.stepIn(stop.threadId!),
      ], eagerError: true);
    });

    test(
        'does not step into external package code with debugExternalPackageLibraries=false',
        () async {
      final client = dap.client;
      final (otherPackageUri, _) = await dap.createFooPackage();
      final testFile = dap.createTestFile('''
import '$otherPackageUri';

void main(List<String> args) async {
  foo(); $breakpointMarker
  foo(); $stepMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final stepLine = lineWith(testFile, stepMarker);

      // Hit the initial breakpoint.
      final stop = await client.hitBreakpoint(
        testFile,
        breakpointLine,
        launch: () => client.launch(
          testFile.path,
          debugExternalPackageLibraries: false,
        ),
      );

      // Step in and expect stopping on the next line (don't go into the package).
      await Future.wait([
        client.expectStop('step', file: testFile, line: stepLine),
        client.stepIn(stop.threadId!),
      ], eagerError: true);
    });

    test(
        'steps into external package code with debugExternalPackageLibraries=true',
        () async {
      final client = dap.client;
      final (otherPackageUri, _) = await dap.createFooPackage();
      final testFile = dap.createTestFile('''
import '$otherPackageUri';

void main(List<String> args) async {
  foo(); $breakpointMarker
  foo();
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      // Hit the initial breakpoint.
      final stop = await dap.client.hitBreakpoint(
        testFile,
        breakpointLine,
        launch: () => client.launch(
          testFile.path,
          debugExternalPackageLibraries: true,
        ),
      );

      // Step in and expect to go into the package.
      await Future.wait([
        client.expectStop('step', sourceName: '$otherPackageUri'),
        client.stepIn(stop.threadId!),
      ], eagerError: true);
    });

    test(
        'steps into other-project package code with debugExternalPackageLibraries=false',
        () async {
      final client = dap.client;
      final (otherPackageUri, _) = await dap.createFooPackage();
      final testFile = dap.createTestFile('''
import '$otherPackageUri';

void main(List<String> args) async {
  foo(); $breakpointMarker
  foo();
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);

      // Hit the initial breakpoint.
      final stop = await client.hitBreakpoint(
        testFile,
        breakpointLine,
        launch: () => client.launch(
          testFile.path,
          debugExternalPackageLibraries: false,
          // Include the packages folder as an additional project path so that
          // it will be treated as local code.
          additionalProjectPaths: [dap.testPackagesDir.path],
        ),
      );

      // Step in and expect stopping in the other package.
      await Future.wait([
        client.expectStop('step', sourceName: '$otherPackageUri'),
        client.stepIn(stop.threadId!),
      ], eagerError: true);
    });

    test('allows changing debug settings during session', () async {
      final client = dap.client;
      final testFile = dap.createTestFile('''
void main(List<String> args) async {
  print('Hello!'); $breakpointMarker
  print('Hello!'); $stepMarker
}
    ''');
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final stepLine = lineWith(testFile, stepMarker);

      // Start with debugSdkLibraries _enabled_ and hit the breakpoint.
      final stop = await client.hitBreakpoint(
        testFile,
        breakpointLine,
        launch: () => client.launch(
          testFile.path,
          debugSdkLibraries: true,
        ),
      );

      // Turn off debugSdkLibraries.
      await client.custom('updateDebugOptions', {
        'debugSdkLibraries': false,
      });

      // Step in and expect stopping on the next line (don't go into print
      // because we turned off SDK debugging).
      await Future.wait([
        client.expectStop('step', file: testFile, line: stepLine),
        client.stepIn(stop.threadId!),
      ], eagerError: true);
    });

    test('handles breakpoints correctly in newly spawned isolates', () async {
      // When calling debugger(), the stop reason is "step" because we can't
      // tell the difference between a pause from debugger() and one from
      // stepping.
      const debuggerStopReason = 'step';

      final client = dap.client;
      final testFile =
          dap.createTestFile(multiIsolateBreakpointResolutionProgram);
      final breakpoint1Line = lineWith(testFile, '$breakpointMarker 1');
      final breakpoint2Line = lineWith(testFile, '$breakpointMarker 2');

      // Start the app and wait for it to pause.
      unawaited(client.start(file: testFile));
      final mainIsolateStop = await client.expectStop(debuggerStopReason);

      // Add and remove a breakpoint to consume "breakpoints/1" in the main
      // isolate.
      await client.setBreakpoints(testFile, [breakpoint1Line]);
      await client.setBreakpoints(testFile, []);

      // Resume so that the new isolate spawns.
      client.continue_(mainIsolateStop.threadId!);
      final otherIsolateStop = await client.expectStop(debuggerStopReason);

      // Make sure the stop we got was a new isolate.
      expect(otherIsolateStop.threadId!, isNot(mainIsolateStop.threadId!));

      // Send the other breakpoint and verify it resolves to the expected line.
      client.setBreakpoints(testFile, [breakpoint2Line]);
      final bpResolved = await client.breakpointChangeEvents
          .firstWhere((e) => e.reason == 'changed');
      expect(bpResolved.breakpoint.line, breakpoint2Line);
    });

    test('does not fail if two debug clients resume the same thread', () async {
      final testFile = dap.createTestFile(infiniteRunningProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      // Start a program and hit a breakpoint.
      final client1 = dap.client;
      final stop1 = await client1.hitBreakpoint(testFile, breakpointLine);
      final vmServiceUri = (await client1.vmServiceUri)!;
      final thread1 = stop1.threadId!;

      // Attach a second debug adapter to it.
      final dap2 = await DapTestSession.setUp(logPrefix: '(CLIENT2) ');
      final client2 = dap2.client;
      await Future.wait([
        // We'll still get event for existing pause.
        client2.expectStop('breakpoint'),
        client2.start(
          launch: () => client2.attach(
            vmServiceUri: vmServiceUri.toString(),
            autoResumeOnEntry: false,
            autoResumeOnExit: false,
            cwd: dap.testAppDir.path,
          ),
        ),
      ]);
      final thread2 = (await client2.getValidThreads()).threads.single.id;

      // Send resumes to both and ensure they complete without errors.
      await Future.wait([
        client1.continue_(thread1),
        client2.continue_(thread2),
      ], eagerError: true);

      await dap2.tearDown();
    });
  }, timeout: Timeout.none);

  group('debug mode conditional breakpoints', () {
    test('stops with condition evaluating to true', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      await client.hitBreakpoint(
        testFile,
        breakpointLine,
        condition: '1 == 1',
      );
    });

    test('does not stop with condition evaluating to false', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      await client.doNotHitBreakpoint(
        testFile,
        breakpointLine,
        condition: '1 == 2',
      );
    });

    test('stops with condition evaluating to non-zero', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      await client.hitBreakpoint(
        testFile,
        breakpointLine,
        condition: '1 + 1',
      );
    });

    test('does not stop with condition evaluating to zero', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      await client.doNotHitBreakpoint(
        testFile,
        breakpointLine,
        condition: '1 - 1',
      );
    });

    test('reports evaluation errors for conditions', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final outputEventsFuture = client.outputEvents.toList();

      await client.doNotHitBreakpoint(
        testFile,
        breakpointLine,
        condition: "1 + 'a'",
      );

      final outputEvents = await outputEventsFuture;
      final outputMessages = outputEvents.map((e) => e.output);

      final hasPrefix = startsWith(
          'Debugger failed to evaluate breakpoint condition "1 + \'a\'": '
          'evaluateInFrame: (113) Expression compilation error');
      final hasDescriptiveMessage = contains(
          "A value of type 'String' can't be assigned to a variable of type 'num'");

      expect(
        outputMessages,
        containsAll([allOf(hasPrefix, hasDescriptiveMessage)]),
      );
    });
    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);

  group('debug mode logpoints', () {
    /// A helper that tests a LogPoint using [logMessage] and expecting the
    /// script not to pause and [expectedMessage] to show up in the output.
    Future<void> testLogPoint(
      DapTestSession dap,
      String logMessage,
      String expectedMessage,
    ) async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      final outputEventsFuture = client.outputEvents.toList();

      await client.doNotHitBreakpoint(
        testFile,
        breakpointLine,
        logMessage: logMessage,
      );

      final outputEvents = await outputEventsFuture;
      final outputMessages = outputEvents.map((e) => e.output.trim());

      expect(
        outputMessages,
        contains(expectedMessage),
      );
    }

    test('print simple messages', () async {
      await testLogPoint(
        dap,
        r'This is a test message',
        'This is a test message',
      );
    });

    test('print messages with Dart interpolation', () async {
      await testLogPoint(
        dap,
        r'This is a test message in ${DateTime(2000, 1, 1).year}',
        'This is a test message in ${DateTime(2000, 1, 1).year}',
      );
    });

    test('print messages with just {braces}', () async {
      await testLogPoint(
        dap,
        // The DAP spec says "Expressions within {} are interpolated" so in the DA
        // we just prefix them with $ and treat them like other Dart interpolation
        // expressions.
        r'This is a test message in {DateTime(2000, 1, 1).year}',
        'This is a test message in ${DateTime(2000, 1, 1).year}',
      );
    });

    test('allows \\{escaped braces}', () async {
      await testLogPoint(
        dap,
        // Since we treat things in {braces} as expressions, we need to support
        // escaping them.
        r'This is a test message with \{escaped braces}',
        r'This is a test message with {escaped braces}',
      );
    });

    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);
}
