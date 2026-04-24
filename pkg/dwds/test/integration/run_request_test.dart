// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Timeout(Duration(minutes: 2))
library;

import 'dart:async';

import 'package:dwds_test_common/logging.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service_interface/vm_service_interface.dart';

import 'fixtures/context.dart';
import 'fixtures/project.dart';
import 'fixtures/utilities.dart';

void main() {
  // Enable verbose logging for debugging.
  const debug = false;

  final provider = TestSdkConfigurationProvider(verbose: debug);
  tearDownAll(provider.dispose);

  final context = TestContext(TestProject.test, provider);

  group('while debugger is attached', () {
    late VmServiceInterface service;
    setUp(() async {
      setCurrentLogWriter(debug: provider.verbose);
      await context.setUp(
        testSettings: TestSettings(
          autoRun: false,
          verboseCompiler: provider.verbose,
        ),
      );
      service = context.service;
    });

    tearDown(() async {
      await context.tearDown();
    });

    test('can resume while paused at the start', () async {
      final vm = await service.getVM();
      final isolate = await service.getIsolate(vm.isolates!.first.id!);
      expect(isolate.pauseEvent!.kind, EventKind.kPauseStart);
      final stream = service.onEvent('Debug');
      final resumeCompleter = Completer<void>();
      // The underlying stream is a broadcast stream so we need to add a
      // listener before calling resume so that we don't miss events.
      unawaited(
        stream.firstWhere((event) => event.kind == EventKind.kResume).then((_) {
          resumeCompleter.complete();
        }),
      );
      await service.resume(isolate.id!);
      await resumeCompleter.future;
      expect(isolate.pauseEvent!.kind, EventKind.kResume);
    });

    test('correctly sets the isolate pauseEvent', () async {
      final vm = await service.getVM();
      final isolate = await service.getIsolate(vm.isolates!.first.id!);
      expect(isolate.pauseEvent!.kind, EventKind.kPauseStart);
      final stream = service.onEvent('Debug');
      context.appConnection.runMain();
      await stream.firstWhere((event) => event.kind == EventKind.kResume);
      expect(isolate.pauseEvent!.kind, EventKind.kResume);
    });
  }, timeout: const Timeout.factor(2));

  group('while debugger is not attached', () {
    setUp(() async {
      setCurrentLogWriter(debug: provider.verbose);
      await context.setUp(
        testSettings: const TestSettings(autoRun: false, waitToDebug: true),
      );
    });

    tearDown(() async {
      await context.tearDown();
    });
    test('correctly sets the isolate pauseEvent if already running', () async {
      context.appConnection.runMain();
      await context.startDebugging();
      final service = context.vmService;
      final vm = await service.getVM();
      final isolate = await service.getIsolate(vm.isolates!.first.id!);
      expect(isolate.pauseEvent!.kind, EventKind.kResume);
    });
  });
}
