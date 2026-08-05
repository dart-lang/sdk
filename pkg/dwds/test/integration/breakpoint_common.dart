// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds_test_common/logging.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service_interface/vm_service_interface.dart';

import 'fixtures/context.dart';
import 'fixtures/project.dart';
import 'fixtures/utilities.dart';

void testBreakpoint({
  required TestSdkConfigurationProvider provider,
  required CompilationMode compilationMode,
  bool verboseCompiler = false,
}) {
  final context = TestContext(TestProject.testPackage(), provider);

  group('shared context', () {
    setUpAll(() async {
      setCurrentLogWriter(debug: provider.verbose);
      await context.setUp(
        testSettings: TestSettings(
          compilationMode: compilationMode,
          verboseCompiler: verboseCompiler,
          canaryFeatures: provider.canaryFeatures,
          moduleFormat: provider.ddcModuleFormat,
        ),
      );
    });

    tearDownAll(() async {
      await context.tearDown();
    });

    group('breakpoint', () {
      VM vm;
      late Isolate isolate;
      late String isolateId;
      ScriptList scripts;
      late ScriptRef mainScript;
      late String mainScriptUri;
      late Stream<Event> stream;
      late VmServiceInterface service;

      setUp(() async {
        service = context.service;
        setCurrentLogWriter(debug: provider.verbose);
        vm = await service.getVM();
        isolate = await service.getIsolate(vm.isolates!.first.id!);
        isolateId = isolate.id!;
        scripts = await service.getScripts(isolateId);

        await service.streamListen('Debug');
        stream = service.onEvent('Debug');

        mainScript = scripts.scripts!.firstWhere(
          (each) => each.uri!.contains('main.dart'),
        );
        mainScriptUri = mainScript.uri!;
      });

      tearDown(() async {
        // We must resume execution in case a test left the isolate paused, but
        // error 106 is expected if the isolate is already running.
        try {
          await service.resume(isolateId);
        } on RPCError catch (e) {
          if (e.code != 106) rethrow;
        }
      });

      test('set breakpoint', () async {
        final line = await context.findBreakpointLine(
          'printLocal',
          isolateId,
          mainScript,
        );
        final bp = await service.addBreakpointWithScriptUri(
          isolateId,
          mainScriptUri,
          line,
        );

        await stream.firstWhere(
          (Event event) => event.kind == EventKind.kPauseBreakpoint,
        );

        expect(bp, isNotNull);

        // Remove breakpoint so it doesn't impact other tests.
        await service.removeBreakpoint(isolateId, bp.id!);
      });

      test('set breakpoint again', () async {
        final line = await context.findBreakpointLine(
          'printLocal',
          isolateId,
          mainScript,
        );
        final bp = await service.addBreakpointWithScriptUri(
          isolateId,
          mainScriptUri,
          line,
        );

        await stream.firstWhere(
          (Event event) => event.kind == EventKind.kPauseBreakpoint,
        );

        expect(bp, isNotNull);

        // Remove breakpoint so it doesn't impact other tests.
        await service.removeBreakpoint(isolateId, bp.id!);
      });

      test('set existing breakpoint succeeds', () async {
        final line = await context.findBreakpointLine(
          'printLocal',
          isolateId,
          mainScript,
        );
        final bp1 = await service.addBreakpointWithScriptUri(
          isolateId,
          mainScriptUri,
          line,
        );
        final bp2 = await service.addBreakpointWithScriptUri(
          isolateId,
          mainScriptUri,
          line,
        );

        expect(bp1, equals(bp2));
        expect(bp1, isNotNull);

        await stream.firstWhere(
          (Event event) => event.kind == EventKind.kPauseBreakpoint,
        );

        var currentIsolate = await service.getIsolate(isolateId);
        expect(currentIsolate.breakpoints, containsAll([bp1]));

        // Remove breakpoint so it doesn't impact other tests.
        await service.removeBreakpoint(isolateId, bp1.id!);

        currentIsolate = await service.getIsolate(isolateId);
        expect(currentIsolate.breakpoints, isEmpty);
      });

      test(
        'set breakpoints at the same line simultaneously succeeds',
        () async {
          final line = await context.findBreakpointLine(
            'printLocal',
            isolateId,
            mainScript,
          );
          final futures = [
            service.addBreakpointWithScriptUri(isolateId, mainScriptUri, line),
            service.addBreakpointWithScriptUri(isolateId, mainScriptUri, line),
          ];

          final breakpoints = await Future.wait(futures);
          expect(breakpoints[0], equals(breakpoints[1]));
          expect(breakpoints[0], isNotNull);

          await stream.firstWhere(
            (Event event) => event.kind == EventKind.kPauseBreakpoint,
          );

          var currentIsolate = await service.getIsolate(isolateId);
          expect(currentIsolate.breakpoints, containsAll([breakpoints[0]]));

          // Remove breakpoint so it doesn't impact other tests.
          await service.removeBreakpoint(isolateId, breakpoints[0].id!);

          currentIsolate = await service.getIsolate(isolateId);
          expect(currentIsolate.breakpoints, isEmpty);
        },
      );

      test('remove non-existing breakpoint fails', () async {
        final line = await context.findBreakpointLine(
          'printLocal',
          isolateId,
          mainScript,
        );
        final bp = await service.addBreakpointWithScriptUri(
          isolateId,
          mainScriptUri,
          line,
        );

        await stream.firstWhere(
          (Event event) => event.kind == EventKind.kPauseBreakpoint,
        );

        var currentIsolate = await service.getIsolate(isolateId);
        expect(currentIsolate.breakpoints, containsAll([bp]));

        // Remove breakpoint so it doesn't impact other tests.
        await service.removeBreakpoint(isolateId, bp.id!);
        await expectLater(
          service.removeBreakpoint(isolateId, bp.id!),
          throwsRPCError,
        );

        currentIsolate = await service.getIsolate(isolateId);
        expect(currentIsolate.breakpoints, isEmpty);
      });

      test('set breakpoint inside a JavaScript line succeeds', () async {
        final line = await context.findBreakpointLine(
          'printNestedObjectMultiLine',
          isolateId,
          mainScript,
        );
        final column = 0;
        final bp = await service.addBreakpointWithScriptUri(
          isolateId,
          mainScriptUri,
          line,
          column: column,
        );

        await stream.firstWhere(
          (Event event) => event.kind == EventKind.kPauseBreakpoint,
        );

        expect(bp, isNotNull);
        expect(
          bp.location,
          isA<SourceLocation>()
              .having((loc) => loc.script, 'script', equals(mainScript))
              .having((loc) => loc.line, 'line', equals(line))
              .having((loc) => loc.column, 'column', greaterThan(column)),
        );

        // Remove breakpoint so it doesn't impact other tests.
        await service.removeBreakpoint(isolateId, bp.id!);
      });
    });
  });
}
