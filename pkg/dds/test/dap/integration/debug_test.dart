// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dap/dap.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'test_client.dart';
import 'test_scripts.dart';
import 'test_server.dart';
import 'test_support.dart';

main() {
  group('debug mode', () {
    late DapTestSession dap;
    setUp(() async {
      dap = await DapTestSession.setUp();
    });
    tearDown(() => dap.tearDown());

    test('runs a simple script', () async {
      final testFile = dap.createTestFile(simpleArgPrintingProgram);

      final outputEvents = await dap.client.collectOutput(
        launch: () => dap.client.launch(
          testFile.path,
          args: ['one', 'two'],
        ),
      );

      // Expect a "console" output event that prints the URI of the VM Service
      // the debugger connects to.
      final vmConnection = outputEvents.first;
      expect(vmConnection.output,
          startsWith('Connecting to VM Service at ws://127.0.0.1:'));
      expect(vmConnection.category, anyOf('console', isNull));

      // Expect the normal applications output.
      final output = outputEvents.skip(2).map((e) => e.output).join();
      expectLines(output, [
        'Hello!',
        'World!',
        'args: [one, two]',
        '',
        'Exited.',
      ]);
    });

    test('does not include empty output events when output ends with a newline',
        () async {
      final testFile = dap.createTestFile(simpleArgPrintingProgram);

      final outputEvents = await dap.client.collectOutput(
        launch: () => dap.client.launch(
          testFile.path,
          args: ['one', 'two'],
        ),
      );

      // The sample application uses `print()` which includes newlines on
      // each output. Output is split by `\n` when scanning for stack frames
      // and previously would include empty output events at the end if the
      // content ended with a newline.
      // https://github.com/flutter/flutter/pull/147250#issuecomment-2075128834
      for (var output in outputEvents) {
        expect(output.output, isNotEmpty);
      }
    });

    test('runs a simple script using runInTerminal request', () async {
      final testFile = dap.createTestFile(emptyProgram);

      // Set up a handler to handle the server calling the clients runInTerminal
      // request and capture the args.
      RunInTerminalRequestArguments? runInTerminalArgs;
      Process? proc;
      dap.client.handleRequest(
        'runInTerminal',
        (args) async {
          runInTerminalArgs = RunInTerminalRequestArguments.fromJson(
            args as Map<String, Object?>,
          );

          // Run the requested process (emulating what the editor would do) so
          // that the DA will pick up the service info file, connect to the VM,
          // resume, and then detect its termination.
          final runArgs = runInTerminalArgs!;
          proc = await Process.start(
            runArgs.args.first,
            runArgs.args.skip(1).toList(),
            workingDirectory: runArgs.cwd,
          );

          return RunInTerminalResponseBody(processId: proc!.pid);
        },
      );

      // Run the script until we get a TerminatedEvent.
      await Future.wait([
        dap.client.event('terminated'),
        dap.client.initialize(supportsRunInTerminalRequest: true),
        dap.client.launch(testFile.path, console: "terminal"),
      ], eagerError: true);

      expect(runInTerminalArgs, isNotNull);
      expect(proc, isNotNull);
      expect(
        runInTerminalArgs!.args,
        containsAllInOrder([
          Platform.resolvedExecutable,
          dap.client.uppercaseDriveLetter(testFile.path),
        ]),
      );
      expect(proc!.pid, isPositive);
      expect(proc!.exitCode, completes);
    });

    test('runs a simple script with commas in the filename', () async {
      final (packageUri, _) = await dap.createFooPackage('foo,foo.dart');
      final testFile = dap.createTestFile(
        '''
          import '$packageUri';
          void main() {
            foo();
          }
        ''',
      );

      final outputEvents = await dap.client.collectOutput(
        launch: () => dap.client.launch(
          testFile.path,
          args: ['one', 'two'],
        ),
      );

      // Expect the normal applications output. This means we set up the
      // debugger without crashing, even though we imported files with commas
      // in the name.
      final output = outputEvents.skip(2).map((e) => e.output).join();
      expectLines(output, [
        'Hello!',
        'World!',
        'args: [one, two]',
        '',
        'Exited.',
      ]);
    }, skip: 'Fails because of https://github.com/dart-lang/sdk/issues/52632');

    test('does not resume isolates if user passes --pause-isolates-on-exit',
        () async {
      // Internally we always pass --pause-isolates-on-exit and resume the
      // isolates after waiting for any output events to complete (in case they
      // need to resolve URIs that involve API calls on an Isolate).
      //
      // However if a user passes this flag explicitly, we should not
      // auto-resume because they might be trying to debug something.
      final testFile = dap.createTestFile(simpleArgPrintingProgram);

      // Run the script, expecting a Stopped event.
      final stop = dap.client.expectStop('exit');
      await Future.wait([
        stop,
        dap.client.initialize(),
        dap.client
            .launch(testFile.path, toolArgs: ["--pause-isolates-on-exit"]),
      ], eagerError: true);

      // Resume and expect termination.
      await Future.wait([
        dap.client.event('terminated'),
        dap.client.continue_((await stop).threadId!),
      ], eagerError: true);
    });

    test('does not resume isolates if user passes --pause-isolates-on-start',
        () async {
      // Internally we always pass --pause-isolates-on-start and resume the
      // isolates after setting any breakpoints.
      //
      // However if a user passes this flag explicitly, we should not
      // auto-resume because they might be trying to debug something.
      final testFile = dap.createTestFile(simpleArgPrintingProgram);

      // Run the script, expecting a Stopped event.
      final stop = dap.client.expectStop('entry');
      await Future.wait([
        stop,
        dap.client.initialize(),
        dap.client.launch(
          testFile.path,
          toolArgs: ["--pause-isolates-on-start"],
        ),
      ], eagerError: true);

      // Resume and expect termination.
      await Future.wait([
        dap.client.event('terminated'),
        dap.client.continue_((await stop).threadId!),
      ], eagerError: true);
    });

    test('receives thread, stopped, continued events during pause/resume',
        () async {
      final client = dap.client;
      final testFile = dap.createTestFile(debuggerPauseAndPrintManyProgram);

      // Collect interesting events that we want to verify exist and in the
      // right order.
      final interestingEvents = const {
        'thread',
        'stopped',
        'continued',
        'terminated'
      };
      final eventsFuture = client.allEvents
          .where((e) => interestingEvents.contains(e.event))
          .map((e) {
        // Map onto a descriptive string for verifying later.
        final reason = (e.body as Map<String, Object?>)['reason'] as String?;
        return reason != null ? '${e.event} ($reason)' : e.event;
      }).toList();

      // Start the program and wait to pause on `debugger()`.
      final stoppedFuture = client.expectStop('step');
      await client.start(file: testFile);
      final threadId = (await stoppedFuture).threadId!;

      // Step 3 times and wait for the corresponding stop.
      for (var i = 0; i < 3; i++) {
        client.next(threadId);
        await client.stoppedEvents.first;
      }

      // Resume to run to end.
      client.continue_(threadId);

      // Verify we had the expected events.
      expect(
        await eventsFuture,
        [
          'thread (started)',
          'stopped (entry)',
          'continued',
          // stop on debugger()
          'stopped (step)',
          // step 1
          'continued',
          'stopped (step)',
          // step 2
          'continued',
          'stopped (step)',
          // step 3
          'continued',
          'stopped (step)',
          // continue
          'continued',
          // pause-on-exit to drain stdout and handle looking up URIs
          'stopped (exit)',
          // finished
          'thread (exited)',
          'terminated',
        ],
      );
    });

    for (final outputKind in ['stdout', 'stderr']) {
      test('sends $outputKind output events in the correct order', () async {
        // Output events that have their URIs mapped will be processed slowly due
        // the async requests for resolving the package URI. This should not cause
        // them to appear out-of-order with other lines that do not require this
        // work.
        //
        // Use a sample program that prints output to stderr that includes:
        // - non stack frame lines
        // - stack frames with file:// URIs
        // - stack frames with package URIs (that need asynchronously resolving)
        // - stack frames with dart URIs (that need asynchronously resolving)
        final fileUri = Uri.file(dap.createTestFile('').path);
        final (packageUri, _) = await dap.createFooPackage();
        final dartUri = Uri.parse('dart:isolate-patch/isolate_patch.dart');
        final testFile = dap.createTestFile(
          stackPrintingProgram(outputKind, fileUri, packageUri, dartUri),
        );

        var outputEvents = await dap.client.collectOutput(
          launch: () => dap.client.launch(testFile.path),
        );
        outputEvents =
            outputEvents.where((e) => e.category == outputKind).toList();

        // Verify the order of the stderr output events.
        final output = outputEvents
            .map((e) => e.output.trim())
            .where((output) => output.isNotEmpty)
            .join('\n');
        expectLines(output, [
          'Start',
          '#0      main ($fileUri:1:2)',
          '#1      main2 ($packageUri:3:4)',
          '#2      main3 ($dartUri:5:6)',
          'End',
        ]);

        // As a sanity check, verify we did actually do the async path mapping and
        // got both frames with paths in our test folder.
        final stackFramesWithPaths = outputEvents.where((e) =>
            e.source?.path != null &&
            path.isWithin(dap.testDir.path, e.source!.path!));
        expect(
          stackFramesWithPaths,
          hasLength(2),
          reason: 'Expected two frames within path ${dap.testDir.path}',
        );
      });

      test(
          'fades $outputKind stack frames that are not part of our project when allowAnsiColorOutput=true',
          () async {
        // Use a sample program that prints output to stderr that includes:
        // - non stack frame lines
        // - stack frames with file:// URIs
        // - stack frames with package URIs (that need asynchronously resolving)
        // - stack frames with dart URIs (that need asynchronously resolving)
        final fileUri = Uri.file(dap.createTestFile('').path);
        final (packageUri, _) = await dap.createFooPackage();
        final dartUri = Uri.parse('dart:isolate-patch/isolate_patch.dart');
        final testFile = dap.createTestFile(
          stackPrintingProgram(outputKind, fileUri, packageUri, dartUri),
        );

        var outputEvents = await dap.client.collectOutput(
          launch: () => dap.client.launch(testFile.path,
              allowAnsiColorOutput: true,
              // Include package:foo as being user-code, to ensure it's not faded.
              additionalProjectPaths: [
                path.join(dap.testPackagesDir.path, 'foo'),
              ]),
        );
        outputEvents =
            outputEvents.where((e) => e.category == outputKind).toList();

        // Verify the order of the stderr output events.
        final output = outputEvents
            .map((e) => e.output.trim())
            .where((output) => output.isNotEmpty)
            .join('\n');
        expectLines(output, [
          'Start',
          '#0      main ($fileUri:1:2)',
          '#1      main2 ($packageUri:3:4)',
          '\u001B[2m#2      main3 ($dartUri:5:6)\u001B[0m',
          'End',
        ]);
      });

      test(
          'includes correct Source.name for SDK and package sources in $outputKind output',
          () async {
        // Use a sample program that prints output to stderr that includes:
        // - non stack frame lines
        // - stack frames with file:// URIs
        // - stack frames with package URIs (that need asynchronously resolving)
        // - stack frames with dart URIs (that need asynchronously resolving)
        final fileUri = Uri.file(dap.createTestFile('').path);
        final (packageUri, _) = await dap.createFooPackage();
        final dartUri = Uri.parse('dart:isolate-patch/isolate_patch.dart');
        final testFile = dap.createTestFile(
          stackPrintingProgram(outputKind, fileUri, packageUri, dartUri),
        );

        final outputEvents = await dap.client.collectOutput(file: testFile);
        final outputSourceNames = outputEvents
            .where((e) => e.category == outputKind)
            .map((output) => output.source?.name)
            .where((sourceName) => (sourceName?.isNotEmpty ?? false))
            .toList();

        expect(
          outputSourceNames,
          [
            fileUri.toFilePath(),
            packageUri.toString(),
            dartUri.toString(),
          ],
        );
      });
    }

    group('progress notifications', () {
      /// Helper to verify [events] are the expected start/update/end events
      /// in-order for a debug session starting.
      void verifyLaunchProgressEvents(List<Event> events) {
        final bodies =
            events.map((e) => e.body as Map<String, Object?>).toList();
        final start = ProgressStartEventBody.fromMap(bodies[0]);
        final update = ProgressUpdateEventBody.fromMap(bodies[1]);
        final end = ProgressEndEventBody.fromMap(bodies[2]);

        expect(start.progressId, isNotNull);
        expect(start.title, 'Debugger');
        expect(start.message, 'Starting…');
        expect(update.progressId, start.progressId);
        expect(update.message, 'Connecting…');
        expect(end.progressId, start.progressId);
        expect(end.message, isNull);
      }

      test('sends no events by default', () async {
        final testFile = dap.createTestFile(simpleArgPrintingProgram);

        final standardEvents = dap.client.standardProgressEvents().toList();
        final customEvents = dap.client.customProgressEvents().toList();

        // Run the script to completion.
        await Future.wait([
          dap.client.event('terminated'),
          dap.client.initialize(),
          dap.client.launch(testFile.path),
        ], eagerError: true);

        expect(await standardEvents, isEmpty);
        expect(await customEvents, isEmpty);
      });

      test('sends standard events when supported', () async {
        final testFile = dap.createTestFile(simpleArgPrintingProgram);

        final standardEventsFuture =
            dap.client.standardProgressEvents().toList();
        final customEventsFuture = dap.client.customProgressEvents().toList();

        // Run the script to completion.
        await Future.wait([
          dap.client.event('terminated'),
          dap.client.initialize(
            supportsProgressReporting: true,
          ),
          dap.client.launch(testFile.path),
        ], eagerError: true);

        final standardEvents = await standardEventsFuture;
        final customEvents = await customEventsFuture;

        // Verify the standard launch events.
        expect(
          standardEvents.map((e) => e.event),
          ['progressStart', 'progressUpdate', 'progressEnd'],
        );
        verifyLaunchProgressEvents(standardEvents);
        // And no custom events.
        expect(customEvents, isEmpty);
      });

      test('sends custom events when requested', () async {
        final testFile = dap.createTestFile(simpleArgPrintingProgram);

        final standardEventsFuture =
            dap.client.standardProgressEvents().toList();
        final customEventsFuture = dap.client.customProgressEvents().toList();

        // Run the script to completion.
        await Future.wait([
          dap.client.event('terminated'),
          dap.client.initialize(),
          dap.client.launch(
            testFile.path,
            sendCustomProgressEvents: true,
          ),
        ], eagerError: true);

        final standardEvents = await standardEventsFuture;
        final customEvents = await customEventsFuture;

        // Verify no standard events.
        expect(standardEvents, isEmpty);
        // But custom events are sent.
        expect(
          customEvents.map((e) => e.event),
          ['dart.progressStart', 'dart.progressUpdate', 'dart.progressEnd'],
        );
        verifyLaunchProgressEvents(customEvents);
      });
    });

    test('provides a list of threads', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      await client.hitBreakpoint(testFile, breakpointLine);
      final response = await client.getValidThreads();

      expect(response.threads, hasLength(1));
      expect(response.threads.first.name, equals('main'));
    });

    test('runs with DDS by default', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      await client.hitBreakpoint(testFile, breakpointLine);
      expect(await client.ddsAvailable, isTrue);
    });

    test('runs with auth codes enabled by default', () async {
      final testFile = dap.createTestFile(emptyProgram);

      final outputEvents = await dap.client.collectOutput(file: testFile);
      final vmServiceUri = _extractVmServiceUri(outputEvents.first);
      expect(vmServiceUri.path, matches(vmServiceAuthCodePathPattern));
    });

    for (final folderName in ['bin', 'lib']) {
      /// Gets the expected name and URI for a macro-generated source.
      ({String name, Uri fileLikeUri}) getExpectedMacroSource(File testFile) {
        // Drive letters are always normalized to uppercase so expect
        // uppercase in the path part of the macro URI.
        final fileLikeUri =
            Uri.file(dap.client.uppercaseDriveLetter(testFile.path))
                .replace(scheme: 'dart-macro+file');
        // The expected source name will differ for inside/outside the lib
        // folder.
        final name = folderName == 'lib'
            ? 'dart-macro+package:my_test_project/main.dart'
            : fileLikeUri.toString();

        return (name: name, fileLikeUri: fileLikeUri);
      }

      test(
          'can download source code from the VM for macro-generated files '
          'in "$folderName" when the client does not support Dart URIs',
          () async {
        final client = dap.client;

        // Create the macro impl, the script that uses it and set up macro
        // support.
        dap.createTestFile(
          filename: '$folderName/with_hello.dart',
          withHelloMacroImplementation,
        );
        final testFile = dap.createTestFile(
          filename: '$folderName/main.dart',
          withHelloMacroProgram,
        );
        dap.createPubspec(dap.testAppDir, 'my_test_project');
        await dap.enableMacroSupport();
        final macroSource = getExpectedMacroSource(testFile);

        // Hit the initial breakpoint.
        final breakpointLine = lineWith(testFile, breakpointMarker);
        final stop = await dap.client.hitBreakpoint(
          testFile,
          breakpointLine,
          toolArgs: ['--enable-experiment=macros'],
        );

        // Step in to the hello() method provided by the macro.
        final responses = await Future.wait([
          client.expectStop('step', sourceName: macroSource.name),
          client.stepIn(stop.threadId!),
        ], eagerError: true);
        final stopResponse = responses.first as StoppedEventBody;

        // Fetch the top stack frame (which should be inside print).
        final stack = await client.getValidStack(
          stopResponse.threadId!,
          startFrame: 0,
          numFrames: 1,
        );
        final topFrame = stack.stackFrames.first;

        // Downloaded macro sources should have a sourceReference and no path.
        expect(topFrame.source!.path, isNull);
        expect(topFrame.source!.sourceReference, isPositive);

        // Source code should contain the augmentation for class A.
        final source = await client.getValidSource(topFrame.source!);
        expect(source.content, contains('augment class A'));
      });

      test(
          'can use local source code for macro-generated files '
          'in "$folderName" when the client supports Dart URIs', () async {
        final client = dap.client;

        // Create the macro impl, the script that uses it and set up macro
        // support.
        dap.createTestFile(
          filename: '$folderName/with_hello.dart',
          withHelloMacroImplementation,
        );
        final testFile = dap.createTestFile(
          filename: '$folderName/main.dart',
          withHelloMacroProgram,
        );
        dap.createPubspec(dap.testAppDir, 'my_test_project');
        await dap.enableMacroSupport();
        final macroSource = getExpectedMacroSource(testFile);
        // Tell the DA we can handle the special URIs.
        client.supportUris = true;

        // Hit the initial breakpoint.
        final breakpointLine = lineWith(testFile, breakpointMarker);
        final stop = await dap.client.hitBreakpoint(
          testFile,
          breakpointLine,
          toolArgs: ['--enable-experiment=macros'],
        );

        // Step in to the hello() method provided by the macro.
        final responses = await Future.wait([
          client.expectStop('step', sourceName: macroSource.name),
          client.stepIn(stop.threadId!),
        ], eagerError: true);
        final stopResponse = responses.first as StoppedEventBody;

        // Fetch the top stack frame (which should be inside print).
        final stack = await client.getValidStack(
          stopResponse.threadId!,
          startFrame: 0,
          numFrames: 1,
        );
        final topFrame = stack.stackFrames.first;

        // When we use local editor-provided sources, there should be a URI in
        // pathand no sourceReference.
        expect(topFrame.source!.sourceReference, isNull);
        expect(topFrame.source!.path, macroSource.fileLikeUri.toString());
      });
    }

    test('can map SDK source code to a local path', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
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

      // Step in to go into print.
      final responses = await Future.wait([
        client.expectStop('step', sourceName: 'dart:core/print.dart'),
        client.stepIn(stop.threadId!),
      ], eagerError: true);
      final stopResponse = responses.first as StoppedEventBody;

      // Fetch the top stack frame (which should be inside print).
      final stack = await client.getValidStack(
        stopResponse.threadId!,
        startFrame: 0,
        numFrames: 1,
      );
      final topFrame = stack.stackFrames.first;

      // SDK sources that have been mapped have no sourceReference but a path.
      expect(
        topFrame.source!.path,
        equals(path.join(sdkRoot, 'lib', 'core', 'print.dart')),
      );
      expect(topFrame.source!.sourceReference, isNull);
    });

    test('can shutdown during startup', () async {
      final testFile = dap.createTestFile(simpleArgPrintingProgram);

      // Request termination immediately upon receiving the first Thread event.
      // The DAP is also responding to this event to configure the isolate (eg.
      // set breakpoints and exception pause behaviour) and will cause it to
      // receive "Service has disappeared" responses if these are in-flight as
      // the process terminates. These should be silently discarded since they
      // are normal during shutdown.
      unawaited(dap.client.event('thread').then((_) => dap.client.terminate()));

      // Start the program and expect termination.
      await Future.wait([
        dap.client.event('terminated'),
        dap.client.start(file: testFile),
      ], eagerError: true);
    });

    test('can hot reload', () async {
      const originalText = 'ORIGINAL TEXT';
      const newText = 'NEW TEXT';

      // Create a script that prints 'ORIGINAL TEXT'.
      final testFile = dap.createTestFile(stringPrintingProgram(originalText));

      // Start the program and wait for 'ORIGINAL TEXT' to be printed.
      await Future.wait([
        dap.client.initialize(),
        dap.client.launch(testFile.path),
      ], eagerError: true);

      // Expect the original text.
      await dap.client.outputEvents
          .firstWhere((event) => event.output.trim() == originalText);

      // Update the file and hot reload.
      testFile.writeAsStringSync(stringPrintingProgram(newText), flush: true);
      // Set a future date to ensure hot reload detects it as being modified.
      testFile.setLastModifiedSync(
        DateTime.now().add(const Duration(seconds: 2)),
      );
      await dap.client.hotReload();

      // Expect the new text.
      await dap.client.outputEvents
          .firstWhere((event) => event.output.trim() == newText);

      await dap.client.terminate();

      // If we're running out of process, ensure the server process terminates.
      final server = dap.server;
      if (server is OutOfProcessDapTestServer) {
        await server.exitCode;
      }
    });

    test('can pause', () async {
      final testFile = dap.createTestFile(infiniteRunningProgram);

      // Start a program and hit a breakpoint.
      final client = dap.client;
      final threadFuture = client.threadEvents.first;

      // Start the app and wait for it to start printing output.
      await Future.wait([
        client.initialize(),
        client.launch(testFile.path),
        dap.client.outputEvents
            .firstWhere((event) => event.output.contains('Looping'))
      ]);

      // Ensure we can pause.
      final thread = await threadFuture;
      await Future.wait([
        client.expectStop('pause'),
        client.pause(thread.threadId),
      ], eagerError: true);
    });

    test('can restart frame', () async {
      final client = dap.client;
      final testFile = dap.createTestFile(restartFrameProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);
      final outputEventsFuture = dap.client.outputEvents.toList();

      // Stop at the breakpoint in the printMessage function.
      final stop = await client.hitBreakpoint(testFile, breakpointLine);
      final threadId = stop.threadId!;

      // Restart back to the main function and expect a new stop event.
      final stack =
          await client.getValidStack(threadId, startFrame: 0, numFrames: 2);
      final mainFunctionFrame = stack.stackFrames[1];
      await Future.wait([
        client.expectStop('step'),
        client.restartFrame(mainFunctionFrame.id),
      ], eagerError: true);

      // Resume, hit breakpoint again, resume to end.
      await Future.wait([
        client.expectStop('breakpoint'),
        client.continue_(threadId),
      ], eagerError: true);
      await Future.wait([
        client.event('terminated'),
        client.continue_(threadId),
      ], eagerError: true);

      // Finally, verify we got output that shows we restarted and re-ran the
      // code before the breakpoint.
      final outputEvents = await outputEventsFuture;
      final outputMessages = outputEvents.map((e) => e.output.trim());

      expect(
        outputMessages,
        containsAll(['Hello', 'Hello', 'World']),
      );
    });

    test('forwards tool events to client', () async {
      final testFile = dap.createTestFile(simpleToolEventProgram);

      // Capture any `dart.toolEvent` events.
      final toolEventsFuture = dap.client.events('dart.toolEvent').toList();

      // Run the script to completion.
      await Future.wait([
        dap.client.event('terminated'),
        dap.client.initialize(),
        dap.client.launch(testFile.path),
      ], eagerError: true);

      // Verify we got exactly the event in the sample program.
      final toolEvents = await toolEventsFuture;
      expect(toolEvents, hasLength(1));
      final toolEvent = toolEvents.single;
      expect(toolEvent.body, {
        'kind': 'navigate',
        'data': {
          'uri': 'file:///file.dart',
        },
      });
    });

    test('resolves URIs in tool events to file:///', () async {
      final client = dap.client;
      final testFile =
          dap.createTestFile(simpleToolEventWithDartCoreUriProgram);

      // Capture the `dart.toolEvent` event.
      final toolEventsFuture = client.events('dart.toolEvent').first;

      // Run the script until we get the event (which means mapping has
      // completed).
      await Future.wait([
        toolEventsFuture,
        client.initialize(),
        client.launch(testFile.path),
      ], eagerError: true);

      // Terminate the app (since the test script has a delay to ensure it
      // doesn't terminate before the async mapping code completes).
      await client.terminate();

      // Verify we got the right fileUri.
      final toolEvent = await toolEventsFuture;
      final body = toolEvent.body as Map<String, Object?>;
      final data = body['data'] as Map<String, Object?>;
      final uri = data['uri'] as String;
      final resolvedUri = data['resolvedUri'] as String;
      expect(uri, 'dart:core');
      expect(resolvedUri, startsWith('file:///'));
      expect(resolvedUri, endsWith('lib/core/core.dart'));
    });
    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);

  group('debug mode', () {
    test(
      'can run without DDS',
      () async {
        final dap = await DapTestSession.setUp(additionalArgs: ['--no-dds']);
        addTearDown(dap.tearDown);

        final client = dap.client;
        final testFile = dap.createTestFile(simpleBreakpointProgram);
        final breakpointLine = lineWith(testFile, breakpointMarker);

        await client.hitBreakpoint(testFile, breakpointLine);

        expect(await client.ddsAvailable, isFalse);
      },
    );

    test('can run without auth codes', () async {
      final dap =
          await DapTestSession.setUp(additionalArgs: ['--no-auth-codes']);
      addTearDown(dap.tearDown);

      final testFile = dap.createTestFile(emptyProgram);
      final outputEvents = await dap.client.collectOutput(file: testFile);
      final vmServiceUri = _extractVmServiceUri(outputEvents.first);
      expect(vmServiceUri.path, isNot(matches(vmServiceAuthCodePathPattern)));
    });

    test('can run with ipv6', () async {
      final dap = await DapTestSession.setUp(additionalArgs: ['--ipv6']);
      addTearDown(dap.tearDown);

      final testFile = dap.createTestFile(emptyProgram);
      final outputEvents = await dap.client.collectOutput(file: testFile);
      final vmServiceUri = _extractVmServiceUri(outputEvents.first);

      expect(vmServiceUri.host, equals('::1'));
    });
    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);
}

/// Extracts the VM Service URI from the "Connecting to ..." banner output by
/// the DAP server upon connection.
Uri _extractVmServiceUri(OutputEventBody vmConnectionBanner) {
  // TODO(dantup): Change this to use the dart.debuggerUris custom event
  //   if implemented (which VS Code also needs).
  final match = dapVmServiceBannerPattern.firstMatch(vmConnectionBanner.output);
  return Uri.parse(match!.group(1)!);
}
