// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dwds/expression_compiler.dart';
import 'package:dwds_test_common/logging.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service_interface/vm_service_interface.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'fixtures/context.dart';
import 'fixtures/project.dart';
import 'fixtures/utilities.dart';

void main() {
  // Enable verbose logging for debugging.
  const debug = false;
  final provider = TestSdkConfigurationProvider(
    verbose: debug,
    canaryFeatures: true,
    ddcModuleFormat: ModuleFormat.ddc,
  );

  tearDownAll(provider.dispose);

  group('Frontend Server', () {
    runTests(
      provider: provider,
      compilationMode: CompilationMode.frontendServer,
    );
  });

  group('Build Daemon', () {
    runTests(provider: provider, compilationMode: CompilationMode.buildDaemon);
  });
}

void runTests({
  required TestSdkConfigurationProvider provider,
  required CompilationMode compilationMode,
}) {
  final project = TestProject.testHotRestartBreakpoints;
  final context = TestContext(project, provider);
  final mainFile = project.dartEntryFileName;
  final callLogMarker = 'callLog';

  Future<void> makeEditsAndRecompile(List<Edit> edits) async {
    await context.makeEdits(edits);
    if (compilationMode == CompilationMode.frontendServer) {
      await context.recompile(fullRestart: true);
    } else {
      await context.waitForSuccessfulBuild();
    }
  }

  group('when pause_isolates_on_start is true', () {
    late VmService client;
    late VmServiceInterface service;
    late Stream<Event> stream;
    // Fetch the log statements that are sent to console.
    final consoleLogs = <String>[];
    StreamSubscription<ConsoleAPIEvent>? consoleSubscription;

    setUp(() async {
      setCurrentLogWriter(debug: provider.verbose);
      await context.setUp(
        testSettings: TestSettings(
          enableExpressionEvaluation: true,
          compilationMode: compilationMode,
          moduleFormat: provider.ddcModuleFormat,
          canaryFeatures: provider.canaryFeatures,
        ),
      );
      client = await context.connectFakeClient();
      service = context.service;
      await client.setFlag('pause_isolates_on_start', 'true');
      await client.streamListen(EventStreams.kIsolate);
      await client.streamListen(EventStreams.kDebug);
      stream = client.onDebugEvent;
      consoleSubscription = context.webkitDebugger.onConsoleAPICalled.listen(
        (e) => consoleLogs.add(e.args.first.value as String),
      );
    });

    tearDown(() async {
      await consoleSubscription?.cancel();
      consoleLogs.clear();
      await context.tearDown();
    });

    Future<Breakpoint> addBreakpoint({
      required String file,
      required String breakpointMarker,
    }) async {
      final vm = await client.getVM();
      final isolateId = vm.isolates!.first.id!;
      final scriptList = await client.getScripts(isolateId);
      final scriptRef = scriptList.scripts!.firstWhere(
        (script) => script.uri!.contains(file),
      );
      final bpLine = await context.findBreakpointLine(
        breakpointMarker,
        isolateId,
        scriptRef,
      );
      final breakpointAdded = expectLater(
        stream,
        emits(_hasKind(EventKind.kBreakpointAdded)),
      );
      final breakpoint = await client.addBreakpointWithScriptUri(
        isolateId,
        scriptRef.uri!,
        bpLine,
      );
      await breakpointAdded;
      return breakpoint;
    }

    Future<void> resume() async {
      final vm = await client.getVM();
      final isolate = await client.getIsolate(vm.isolates!.first.id!);
      await client.resume(isolate.id!);
    }

    // Resume the program, and check that at some point it will execute code
    // that will print `expectedString` to the console.
    Future<void> resumeAndWaitForLog(String expectedString) async {
      final completer = Completer<void>();
      final subscription = context.webkitDebugger.onConsoleAPICalled.listen((
        e,
      ) {
        if (e.args.first.value == expectedString) {
          completer.complete();
        }
      });
      await resume();
      await completer.future.timeout(
        const Duration(minutes: 1),
        onTimeout: () {
          throw TimeoutException(
            "Failed to find log: '$expectedString' in console.",
          );
        },
      );
      await subscription.cancel();
    }

    Future<void> hotRestartAndHandlePausePost(
      List<({String file, String breakpointMarker, bool exists})> breakpoints,
    ) async {
      final isolateEvents = expectLater(
        client.onIsolateEvent,
        emitsInOrder([
          _hasKind(EventKind.kIsolateExit),
          _hasKind(EventKind.kIsolateStart),
          _hasKind(EventKind.kIsolateRunnable),
        ]),
      );
      final breakpointEvents = expectLater(
        stream,
        emitsInOrder([
          for (final (:exists, breakpointMarker: _, file: _)
              in breakpoints) ...[
            if (exists) _hasKind(EventKind.kBreakpointRemoved),
          ],
          _hasKind(EventKind.kResume),
          _hasKind(EventKind.kPausePostRequest),
          for (final _ in breakpoints) ...[
            _hasKind(EventKind.kBreakpointAdded),
          ],
        ]),
      );

      final waitForPausePost = expectLater(
        stream,
        emitsThrough(_hasKind(EventKind.kPausePostRequest)),
      );

      final hotRestart = context.getRegisteredServiceExtension('hotRestart');
      expect(
        await client.callServiceExtension(hotRestart!),
        const TypeMatcher<Success>(),
      );

      await isolateEvents;

      // DWDS defers running main after a hot restart until the client (e.g.
      // DAP) resumes. Client should listen for this event, remove breakpoints
      // (we don't remove them here as DWDS already removes them), and
      // reregister breakpoints (which will be registered in the new files), and
      // resume.
      await waitForPausePost;
      // Verify DWDS has already removed the breakpoints at this point.
      final vm = await client.getVM();
      final isolate = await service.getIsolate(vm.isolates!.first.id!);
      expect(isolate.breakpoints, isEmpty);
      for (final (exists: _, :breakpointMarker, :file) in breakpoints) {
        await addBreakpoint(file: file, breakpointMarker: breakpointMarker);
      }
      await resume();
      await breakpointEvents;
    }

    Future<Event> waitForBreakpoint() =>
        stream.firstWhere((event) => event.kind == EventKind.kPauseBreakpoint);

    test('empty hot restart keeps breakpoints', () async {
      final genString = 'main gen0';

      await addBreakpoint(file: mainFile, breakpointMarker: callLogMarker);

      final breakpointFuture = waitForBreakpoint();

      if (compilationMode == CompilationMode.frontendServer) {
        await context.recompile(fullRestart: false);
      }

      await hotRestartAndHandlePausePost([
        (exists: true, file: mainFile, breakpointMarker: callLogMarker),
      ]);

      // Should break at `callLog`.
      await breakpointFuture;
      await resumeAndWaitForLog(genString);
    });

    test('after edit and hot restart, breakpoint is in new file', () async {
      final oldLog = 'main gen0';
      final newLog = 'main gen1';

      await addBreakpoint(file: mainFile, breakpointMarker: callLogMarker);

      await makeEditsAndRecompile([
        (file: mainFile, originalString: oldLog, newString: newLog),
      ]);

      final breakpointFuture = waitForBreakpoint();

      await hotRestartAndHandlePausePost([
        (exists: true, file: mainFile, breakpointMarker: callLogMarker),
      ]);

      // Should break at `callLog`.
      await breakpointFuture;
      expect(consoleLogs.contains(newLog), false);
      await resumeAndWaitForLog(newLog);
    });

    test('after adding line, hot restart, removing line, and hot restart, '
        'breakpoint is correct across both hot restarts', () async {
      final genLog = 'main gen0';

      await addBreakpoint(file: mainFile, breakpointMarker: callLogMarker);

      // Add an extra log before the existing log.
      final extraLog = 'hot reload';
      final oldString = "log('";
      final newString = "log('$extraLog');\n$oldString";
      await makeEditsAndRecompile([
        (file: mainFile, originalString: oldString, newString: newString),
      ]);

      var breakpointFuture = waitForBreakpoint();

      await hotRestartAndHandlePausePost([
        (exists: true, file: mainFile, breakpointMarker: callLogMarker),
      ]);

      // Should break at `callLog`.
      await breakpointFuture;
      expect(consoleLogs.contains(extraLog), true);
      expect(consoleLogs.contains(genLog), false);
      await resumeAndWaitForLog(genLog);

      consoleLogs.clear();

      // Remove the line we just added.
      await makeEditsAndRecompile([
        (file: mainFile, originalString: newString, newString: oldString),
      ]);

      breakpointFuture = waitForBreakpoint();

      await hotRestartAndHandlePausePost([
        (exists: true, file: mainFile, breakpointMarker: callLogMarker),
      ]);

      // Should break at `callLog`.
      await breakpointFuture;
      expect(consoleLogs.contains(extraLog), false);
      expect(consoleLogs.contains(genLog), false);
      await resumeAndWaitForLog(genLog);
    });

    test(
      'after adding file and putting breakpoint in it, breakpoint is correctly '
      'registered',
      () async {
        final genLog = 'main gen0';

        await addBreakpoint(file: mainFile, breakpointMarker: callLogMarker);

        // Add a library file, import it, and then refer to it in the log.
        final libFile = 'library.dart';
        final libGenLog = 'library gen0';
        final libValueMarker = 'libValue';
        context.addLibraryFile(
          libFileName: libFile,
          contents:
              '''String get libraryValue {
            return '$libGenLog'; // Breakpoint: $libValueMarker
          }''',
        );
        final oldImports = "import 'dart:js_interop';";
        final newImports =
            '$oldImports\n'
            "import 'package:_test_hot_restart_breakpoints/library.dart';";
        final edits = [
          (file: mainFile, originalString: oldImports, newString: newImports),
        ];
        final oldLog = "log('$genLog');";
        final newLog = "log('\$libraryValue');";
        edits.add((file: mainFile, originalString: oldLog, newString: newLog));

        // Include library file in edits to ensure it's added to
        // reloaded_sources.json
        edits.add((
          file: libFile,
          originalString: 'String get libraryValue',
          newString: 'String get libraryValue',
        ));

        await makeEditsAndRecompile(edits);

        var breakpointFuture = waitForBreakpoint();

        await hotRestartAndHandlePausePost([
          (exists: true, file: mainFile, breakpointMarker: callLogMarker),
          (exists: false, file: libFile, breakpointMarker: libValueMarker),
        ]);

        // Should break at `callLog`.
        await breakpointFuture;
        expect(consoleLogs.contains(libGenLog), false);

        breakpointFuture = waitForBreakpoint();

        await resume();
        // Should break at `libValue`.
        await breakpointFuture;
        expect(consoleLogs.contains(libGenLog), false);
        await resumeAndWaitForLog(libGenLog);
      },
    );

    // Test that we wait for all scripts to be parsed first before computing
    // location metadata.
    test('after adding many files and putting breakpoint in the last one,'
        'breakpoint is correctly registered', () async {
      final genLog = 'main gen0';

      await addBreakpoint(file: mainFile, breakpointMarker: callLogMarker);

      // Add library files, import them, but only refer to the last one in main.
      final numFiles = 50;
      final edits = <Edit>[];
      for (var i = 1; i <= numFiles; i++) {
        final libFile = 'library$i.dart';
        context.addLibraryFile(
          libFileName: libFile,
          contents:
              '''String get libraryValue$i {
            return 'library$i gen1'; // Breakpoint: libValue$i
          }''',
        );
        final oldImports = "import 'dart:js_interop';";
        final newImports =
            '$oldImports\n'
            "import 'package:_test_hot_restart_breakpoints/$libFile';";
        edits.add((
          file: mainFile,
          originalString: oldImports,
          newString: newImports,
        ));
      }
      final oldLog = "log('$genLog');";
      final newLog = "log('\$libraryValue$numFiles');";
      edits.add((file: mainFile, originalString: oldLog, newString: newLog));

      // Include library files in edits to ensure they are added to
      // reloaded_sources.json
      for (var i = 1; i <= numFiles; i++) {
        edits.add((
          file: 'library$i.dart',
          originalString: 'String get libraryValue$i',
          newString: 'String get libraryValue$i',
        ));
      }

      await makeEditsAndRecompile(edits);

      var breakpointFuture = waitForBreakpoint();

      await hotRestartAndHandlePausePost([
        (exists: true, file: mainFile, breakpointMarker: callLogMarker),
        (
          exists: false,
          file: 'library$numFiles.dart',
          breakpointMarker: 'libValue$numFiles',
        ),
      ]);

      final newGenLog = 'library$numFiles gen1';

      // Should break at `callLog`.
      await breakpointFuture;
      expect(consoleLogs.contains(newGenLog), false);

      breakpointFuture = waitForBreakpoint();

      await resume();
      // Should break at the breakpoint in the last file.
      await breakpointFuture;
      expect(consoleLogs.contains(newGenLog), false);
      await resumeAndWaitForLog(newGenLog);
    });
  });
}

TypeMatcher<Event> _hasKind(String kind) =>
    isA<Event>().having((e) => e.kind, 'kind', kind);
