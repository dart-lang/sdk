// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
@Timeout(Duration(minutes: 2))
library;

import 'package:dwds_test_common/logging.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service_interface/vm_service_interface.dart';

import 'fixtures/context.dart';
import 'fixtures/project.dart';
import 'fixtures/utilities.dart';

void testAll({
  required TestSdkConfigurationProvider provider,
  CompilationMode compilationMode = CompilationMode.buildDaemon,
  IndexBaseMode indexBaseMode = IndexBaseMode.noBase,
  bool useDebuggerModuleNames = false,
}) {
  if (compilationMode == CompilationMode.buildDaemon &&
      indexBaseMode == IndexBaseMode.base) {
    throw StateError(
      'build daemon scenario does not support non-empty base in index file',
    );
  }

  final testCircular1 = TestProject.testCircular1;
  final testCircular2 = TestProject.testCircular2(baseMode: indexBaseMode);

  final context = TestContext(testCircular2, provider);

  Future<void> onBreakPoint(
    String isolate,
    ScriptRef script,
    String breakPointId,
    Future<void> Function() body,
  ) async {
    Breakpoint? bp;
    try {
      final line = await context.findBreakpointLine(
        breakPointId,
        isolate,
        script,
      );
      bp = await context.service.addBreakpointWithScriptUri(
        isolate,
        script.uri!,
        line,
      );
      await body();
    } finally {
      // Remove breakpoint so it doesn't impact other tests or retries.
      if (bp != null) {
        await context.service.removeBreakpoint(isolate, bp.id!);
      }
    }
  }

  group('shared context with evaluation', () {
    setUpAll(() async {
      setCurrentLogWriter(debug: provider.verbose);
      await context.setUp(
        testSettings: TestSettings(
          compilationMode: compilationMode,
          enableExpressionEvaluation: true,
          useDebuggerModuleNames: useDebuggerModuleNames,
          verboseCompiler: provider.verbose,
          canaryFeatures: provider.canaryFeatures,
          moduleFormat: provider.ddcModuleFormat,
        ),
      );
    });

    tearDownAll(() async {
      await context.tearDown();
    });

    setUp(() => setCurrentLogWriter(debug: provider.verbose));

    group('evaluateInFrame', () {
      late VmServiceInterface service;
      VM vm;
      late Isolate isolate;
      late String isolateId;
      ScriptList scripts;
      late ScriptRef test1LibraryScript;
      late ScriptRef test2LibraryScript;
      late Stream<Event> stream;

      setUp(() async {
        setCurrentLogWriter(debug: provider.verbose);
        service = context.service;
        vm = await service.getVM();
        isolate = await service.getIsolate(vm.isolates!.first.id!);
        isolateId = isolate.id!;
        scripts = await service.getScripts(isolateId);

        await service.streamListen('Debug');
        stream = service.onEvent('Debug');

        final test1 = testCircular1.packageName;
        final test2 = testCircular2.packageName;

        test1LibraryScript = scripts.scripts!.firstWhere(
          (each) => each.uri!.contains('package:$test1/library1.dart'),
        );
        test2LibraryScript = scripts.scripts!.firstWhere(
          (each) => each.uri!.contains('package:$test2/library2.dart'),
        );
      });

      tearDown(() async {
        await service.resume(isolateId);
      });

      test('evaluate expression in _test_circular1/library', () async {
        await onBreakPoint(
          isolateId,
          test1LibraryScript,
          'Concatenate',
          () async {
            final event = await stream.firstWhere(
              (event) => event.kind == EventKind.kPauseBreakpoint,
            );

            final result = await context.service.evaluateInFrame(
              isolateId,
              event.topFrame!.index!,
              'a',
            );

            expect(
              result,
              isA<InstanceRef>().having(
                (instance) => instance.valueAsString,
                'valueAsString',
                'a',
              ),
            );
          },
        );
      });

      test('evaluate expression in _test_circular2/library', () async {
        await onBreakPoint(
          isolateId,
          test2LibraryScript,
          'testCircularDependencies',
          () async {
            final event = await stream.firstWhere(
              (event) => event.kind == EventKind.kPauseBreakpoint,
            );

            final result = await context.service.evaluateInFrame(
              isolateId,
              event.topFrame!.index!,
              'true',
            );

            expect(
              result,
              isA<InstanceRef>().having(
                (instance) => instance.valueAsString,
                'valueAsString',
                'true',
              ),
            );
          },
        );
      });
    });
  });
}
