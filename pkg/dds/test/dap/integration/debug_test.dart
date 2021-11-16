// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dds/src/dap/protocol_generated.dart';
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
      expect(vmConnection.category, equals('console'));

      // Expect the normal applications output.
      final output = outputEvents.skip(1).map((e) => e.output).join();
      expectLines(output, [
        'Hello!',
        'World!',
        'args: [one, two]',
        '',
        'Exited.',
      ]);
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
        containsAllInOrder([Platform.resolvedExecutable, testFile.path]),
      );
      expect(proc!.pid, isPositive);
      expect(proc!.exitCode, completes);
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

    test('can download source code from the VM', () async {
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

      // SDK sources should have a sourceReference and no path.
      expect(topFrame.source!.path, isNull);
      expect(topFrame.source!.sourceReference, isPositive);

      // Source code should contain the implementation/signature of print().
      final source = await client.getValidSource(topFrame.source!);
      expect(source.content, contains('void print(Object? object) {'));
    });

    test('can shutdown during startup', () async {
      final testFile = dap.createTestFile(simpleArgPrintingProgram);

      // Terminate the app immediately upon recieving the first Thread event.
      // The DAP is also responding to this event to configure the isolate (eg.
      // set breakpoints and exception pause behaviour) and will cause it to
      // receive "Service has disappeared" responses if these are in-flight as
      // the process terminates. These should not go unhandled since they are
      // normal during shutdown.
      unawaited(dap.client.event('thread').then((_) => dap.client.terminate()));
      await dap.client.start(file: testFile);
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
      testFile.writeAsStringSync(stringPrintingProgram(newText));
      await dap.client.hotReload();

      // Expect the new text.
      await dap.client.outputEvents
          .firstWhere((event) => event.output.trim() == newText);

      await dap.client.terminate();
    });
    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);

  group('debug mode', () {
    test('can run without DDS', () async {
      final dap = await DapTestSession.setUp(additionalArgs: ['--no-dds']);
      addTearDown(dap.tearDown);

      final client = dap.client;
      final testFile = dap.createTestFile(simpleBreakpointProgram);
      final breakpointLine = lineWith(testFile, breakpointMarker);

      await client.hitBreakpoint(testFile, breakpointLine);

      expect(await client.ddsAvailable, isFalse);
    });

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
  //   if implemented (whch VS Code also needs).
  final match = dapVmServiceBannerPattern.firstMatch(vmConnectionBanner.output);
  return Uri.parse(match!.group(1)!);
}
