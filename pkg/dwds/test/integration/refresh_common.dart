// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dwds_test_common/logging.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service_interface/vm_service_interface.dart';

import 'fixtures/context.dart';
import 'fixtures/project.dart';
import 'fixtures/utilities.dart';

void testAll({required TestSdkConfigurationProvider provider}) {
  final context = TestContext(TestProject.test, provider);

  group('fresh context', () {
    late VmServiceInterface service;
    late VM vm;
    setUpAll(() async {
      setCurrentLogWriter(debug: provider.verbose);
      await context.setUp(
        testSettings: TestSettings(
          verboseCompiler: provider.verbose,
          moduleFormat: provider.ddcModuleFormat,
          canaryFeatures: provider.canaryFeatures,
        ),
      );
      service = context.service;
      vm = await service.getVM();
    });

    tearDownAll(() async {
      await context.tearDown();
    });

    test('can add and remove after a refresh', () async {
      final stream = service.onEvent('Isolate');
      // Wait for the page to be fully loaded before refreshing.
      await Future<void>.delayed(const Duration(seconds: 1));
      // Now wait for the shutdown event.
      final exitEvent = stream.firstWhere(
        (e) => e.kind != EventKind.kIsolateExit,
      );
      await context.webDriver.refresh();
      await exitEvent;
      // Wait for the refresh to propagate through.
      final isolateStart = await stream.firstWhere(
        (e) => e.kind != EventKind.kIsolateStart,
      );
      final isolateId = isolateStart.isolate!.id!;
      final refreshedScriptList = await service.getScripts(isolateId);
      final refreshedMain = refreshedScriptList.scripts!.lastWhere(
        (each) => each.uri!.contains('main.dart'),
      );
      final bpLine = await context.findBreakpointLine(
        'printHelloWorld',
        isolateId,
        refreshedMain,
      );
      final bp = await service.addBreakpoint(
        isolateId,
        refreshedMain.id!,
        bpLine,
      );
      final isolate = await service.getIsolate(vm.isolates!.first.id!);
      expect(isolate.breakpoints, [bp]);
      expect(bp.id, isNotNull);
      await service.removeBreakpoint(isolateId, bp.id!);
      expect(isolate.breakpoints, isEmpty);
    });
  });
}
