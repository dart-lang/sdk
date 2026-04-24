// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds/expression_compiler.dart';
import 'package:dwds_test_common/logging.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import '../../fixtures/context.dart';
import '../../fixtures/project.dart';
import '../../fixtures/utilities.dart';
import 'test_inspector.dart';

void runTests({
  required TestSdkConfigurationProvider provider,
  required CompilationMode compilationMode,
  required bool canaryFeatures,
}) {
  final project = TestProject.testExperiment;
  final context = TestContext(project, provider);
  final testInspector = TestInspector(context);

  late VmService service;
  late Stream<Event> stream;
  late String isolateId;
  late ScriptRef mainScript;

  Future<void> onBreakPoint(
    String breakPointId,
    Future<void> Function(Event) body,
  ) => testInspector.onBreakPoint(
    stream,
    isolateId,
    mainScript,
    breakPointId,
    body,
  );

  Future<Obj> getObject(String instanceId) =>
      service.getObject(isolateId, instanceId);

  Future<Map<Object?, String?>> getDisplayedFields(InstanceRef instanceRef) =>
      testInspector.getDisplayedFields(isolateId, instanceRef);

  Future<Map<Object?, String?>> getDisplayedGetters(InstanceRef instanceRef) =>
      testInspector.getDisplayedGetters(isolateId, instanceRef);

  Future<InstanceRef> getInstanceRef(int frame, String expression) =>
      testInspector.getInstanceRef(isolateId, frame, expression);

  Future<Map<Object?, Object?>> getFields(
    InstanceRef instanceRef, {
    int? offset,
    int? count,
    int depth = -1,
  }) => testInspector.getFields(
    isolateId,
    instanceRef,
    offset: offset,
    count: count,
    depth: depth,
  );

  Future<List<Instance>> getElements(String instanceId) =>
      testInspector.getElements(isolateId, instanceId);

  final matchTypeObjectFields = <String, dynamic>{
    if (provider.ddcModuleFormat == ModuleFormat.ddc) '_rti': anything,
  };

  final matchDisplayedTypeObjectFields = <String, dynamic>{
    if (provider.ddcModuleFormat == ModuleFormat.ddc) '_rti': anything,
  };

  final matchDisplayedTypeObjectGetters = <String, dynamic>{
    'hashCode': matches('[0-9]*'),
    'runtimeType': matchTypeClassName,
  };

  group('$compilationMode |', () {
    setUpAll(() async {
      setCurrentLogWriter(debug: provider.verbose);
      await context.setUp(
        testSettings: TestSettings(
          compilationMode: compilationMode,
          enableExpressionEvaluation: true,
          verboseCompiler: provider.verbose,
          experiments: ['dot-shorthands'],
          canaryFeatures: canaryFeatures,
          moduleFormat: provider.ddcModuleFormat,
        ),
      );
      service = context.debugConnection.vmService;

      final vm = await service.getVM();
      isolateId = vm.isolates!.first.id!;
      final scripts = await service.getScripts(isolateId);

      await service.streamListen('Debug');
      stream = service.onEvent('Debug');

      mainScript = scripts.scripts!.firstWhere(
        (each) => each.uri!.contains('main.dart'),
      );
    });

    tearDownAll(() async {
      await context.tearDown();
    });

    setUp(() => setCurrentLogWriter(debug: provider.verbose));
    tearDown(() => service.resume(isolateId));

    test('String type', () async {
      await onBreakPoint('printSimpleLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, "'1'.runtimeType");
        expect(instanceRef, matchTypeInstanceRef('String'));

        final instanceId = instanceRef.id!;
        final instance = await getObject(instanceId);
        expect(instance, matchTypeInstance('String'));

        final classId = instanceRef.classRef!.id!;
        expect(await getObject(classId), matchTypeClass);
        expect(await getFields(instanceRef, depth: 1), matchTypeObjectFields);
        expect(
          await getDisplayedFields(instanceRef),
          matchDisplayedTypeObjectFields,
        );
      });
    });

    test('String type getters', () async {
      await onBreakPoint('printSimpleLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, "'1'.runtimeType");

        expect(
          await getDisplayedGetters(instanceRef),
          matchDisplayedTypeObjectGetters,
        );
      });
    });

    test('int type', () async {
      await onBreakPoint('printSimpleLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, '1.runtimeType');
        expect(instanceRef, matchTypeInstanceRef('int'));

        final instanceId = instanceRef.id!;
        final instance = await getObject(instanceId);
        expect(instance, matchTypeInstance('int'));

        final classId = instanceRef.classRef!.id!;
        expect(await getObject(classId), matchTypeClass);
        expect(await getFields(instanceRef, depth: 1), matchTypeObjectFields);
        expect(
          await getDisplayedFields(instanceRef),
          matchDisplayedTypeObjectFields,
        );
      });
    });

    test('int type getters', () async {
      await onBreakPoint('printSimpleLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, '1.runtimeType');

        expect(
          await getDisplayedGetters(instanceRef),
          matchDisplayedTypeObjectGetters,
        );
      });
    });

    test('list type', () async {
      await onBreakPoint('printSimpleLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, '<int>[].runtimeType');
        expect(instanceRef, matchTypeInstanceRef('List<int>'));

        final instanceId = instanceRef.id!;
        final instance = await getObject(instanceId);
        expect(instance, matchTypeInstance('List<int>'));

        final classId = instanceRef.classRef!.id!;
        expect(await getObject(classId), matchTypeClass);
        expect(await getFields(instanceRef, depth: 1), matchTypeObjectFields);
        expect(
          await getDisplayedFields(instanceRef),
          matchDisplayedTypeObjectFields,
        );
        expect(
          await getDisplayedGetters(instanceRef),
          matchDisplayedTypeObjectGetters,
        );
      });
    });

    test('map type', () async {
      await onBreakPoint('printSimpleLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(
          frame,
          '<int, String>{}.runtimeType',
        );
        expect(instanceRef, matchTypeInstanceRef('IdentityMap<int, String>'));

        final instanceId = instanceRef.id!;
        final instance = await getObject(instanceId);
        expect(instance, matchTypeInstance('IdentityMap<int, String>'));

        final classId = instanceRef.classRef!.id!;
        expect(await getObject(classId), matchTypeClass);
        expect(await getFields(instanceRef, depth: 1), matchTypeObjectFields);
        expect(
          await getDisplayedFields(instanceRef),
          matchDisplayedTypeObjectFields,
        );
      });
    });

    test('map type getters', () async {
      await onBreakPoint('printSimpleLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(
          frame,
          '<int, String>{}.runtimeType',
        );

        expect(
          await getDisplayedGetters(instanceRef),
          matchDisplayedTypeObjectGetters,
        );
      });
    });

    test('set type', () async {
      await onBreakPoint('printSimpleLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, '<int>{}.runtimeType');
        expect(instanceRef, matchTypeInstanceRef('IdentitySet<int>'));

        final instanceId = instanceRef.id!;
        final instance = await getObject(instanceId);
        expect(instance, matchTypeInstance('IdentitySet<int>'));

        final classId = instanceRef.classRef!.id!;
        expect(await getObject(classId), matchTypeClass);
        expect(await getFields(instanceRef, depth: 1), matchTypeObjectFields);
        expect(
          await getDisplayedFields(instanceRef),
          matchDisplayedTypeObjectFields,
        );
      });
    });

    test('set type getters', () async {
      await onBreakPoint('printSimpleLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, '<int>{}.runtimeType');

        expect(
          await getDisplayedGetters(instanceRef),
          matchDisplayedTypeObjectGetters,
        );
      });
    });

    test('record type', () async {
      await onBreakPoint('printSimpleLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, "(0,'a').runtimeType");
        expect(instanceRef, matchRecordTypeInstanceRef(length: 2));

        final instanceId = instanceRef.id!;
        final instance = await getObject(instanceId);
        expect(instance, matchRecordTypeInstance(length: 2));
        expect(await getElements(instanceId), [
          matchTypeInstance('int'),
          matchTypeInstance('String'),
        ]);

        final classId = instanceRef.classRef!.id!;
        expect(await getObject(classId), matchRecordTypeClass);
        expect(await getFields(instanceRef, depth: 2), {
          1: matchTypeObjectFields,
          2: matchTypeObjectFields,
        });
        expect(await getDisplayedFields(instanceRef), {1: 'int', 2: 'String'});
      });
    });

    test('record type getters', () async {
      await onBreakPoint('printSimpleLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, "(0,'a').runtimeType");

        expect(
          await getDisplayedGetters(instanceRef),
          matchDisplayedTypeObjectGetters,
        );
      });
    });

    test('class type', () async {
      await onBreakPoint('printSimpleLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(
          frame,
          "Uri.file('').runtimeType",
        );
        expect(instanceRef, matchTypeInstanceRef('_Uri'));

        final instanceId = instanceRef.id!;
        final instance = await getObject(instanceId);
        expect(instance, matchTypeInstance('_Uri'));
        final classId = instanceRef.classRef!.id!;
        expect(await getObject(classId), matchTypeClass);
        expect(await getFields(instanceRef, depth: 1), matchTypeObjectFields);
        expect(
          await getDisplayedFields(instanceRef),
          matchDisplayedTypeObjectFields,
        );
      });
    });

    test('class type getters', () async {
      await onBreakPoint('printSimpleLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(
          frame,
          "Uri.file('').runtimeType",
        );

        expect(
          await getDisplayedGetters(instanceRef),
          matchDisplayedTypeObjectGetters,
        );
      });
    });
  });
}
