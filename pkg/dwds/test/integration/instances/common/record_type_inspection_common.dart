// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  final context = TestContext(TestProject.testExperiment, provider);
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

  Future<InstanceRef> getInstanceRef(int frame, String expression) =>
      testInspector.getInstanceRef(isolateId, frame, expression);

  Future<Map<Object?, String?>> getDisplayedFields(InstanceRef ref) =>
      testInspector.getDisplayedFields(isolateId, ref);

  Future<Map<Object?, String?>> getDisplayedGetters(InstanceRef ref) =>
      testInspector.getDisplayedGetters(isolateId, ref);

  Future<List<Instance>> getElements(String instanceId) =>
      testInspector.getElements(isolateId, instanceId);

  final matchDisplayedTypeObjectGetters = {
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

    test('simple record type', () async {
      await onBreakPoint('printSimpleLocalRecord', (event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, 'record.runtimeType');
        final instanceId = instanceRef.id!;

        expect(instanceRef, matchRecordTypeInstanceRef(length: 2));
        expect(await getObject(instanceId), matchRecordTypeInstance(length: 2));

        final classId = instanceRef.classRef!.id!;
        expect(await getObject(classId), matchRecordTypeClass);
      });
    });

    test('simple record type elements', () async {
      await onBreakPoint('printSimpleLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, 'record.runtimeType');
        final instanceId = instanceRef.id!;

        expect(await getElements(instanceId), [
          matchTypeInstance('bool'),
          matchTypeInstance('int'),
        ]);
        expect(await getDisplayedFields(instanceRef), {1: 'bool', 2: 'int'});
      });
    });

    test('simple record type getters', () async {
      await onBreakPoint('printSimpleLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, 'record.runtimeType');

        expect(
          await getDisplayedGetters(instanceRef),
          matchDisplayedTypeObjectGetters,
        );
      });
    });

    test('simple record type display', () async {
      await onBreakPoint('printSimpleLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final typeStringRef = await getInstanceRef(
          frame,
          'record.runtimeType.toString()',
        );
        final typeStringId = typeStringRef.id!;

        expect(
          await getObject(typeStringId),
          matchPrimitiveInstance(
            kind: InstanceKind.kString,
            value: '(bool, int)',
          ),
        );
      });
    });

    test('complex record type', () async {
      await onBreakPoint('printComplexLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, 'record.runtimeType');
        final instanceId = instanceRef.id!;

        expect(instanceRef, matchRecordTypeInstanceRef(length: 3));
        expect(await getObject(instanceId), matchRecordTypeInstance(length: 3));

        final classId = instanceRef.classRef!.id!;
        expect(await getObject(classId), matchRecordTypeClass);
      });
    });

    test('complex record type elements', () async {
      await onBreakPoint('printComplexLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, 'record.runtimeType');
        final instanceId = instanceRef.id!;

        expect(await getElements(instanceId), [
          matchTypeInstance('bool'),
          matchTypeInstance('int'),
          matchTypeInstance('IdentityMap<String, int>'),
        ]);
        expect(await getDisplayedFields(instanceRef), {
          1: 'bool',
          2: 'int',
          3: 'IdentityMap<String, int>',
        });
      });
    });

    test('complex record type getters', () async {
      await onBreakPoint('printComplexLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, 'record.runtimeType');

        expect(
          await getDisplayedGetters(instanceRef),
          matchDisplayedTypeObjectGetters,
        );
      });
    });

    test('complex record type display', () async {
      await onBreakPoint('printComplexLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final typeStringRef = await getInstanceRef(
          frame,
          'record.runtimeType.toString()',
        );
        final typeStringId = typeStringRef.id!;

        expect(
          await getObject(typeStringId),
          matchPrimitiveInstance(
            kind: InstanceKind.kString,
            value: '(bool, int, IdentityMap<String, int>)',
          ),
        );
      });
    });

    test('complex record type with named fields ', () async {
      await onBreakPoint('printComplexNamedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, 'record.runtimeType');
        final instanceId = instanceRef.id!;

        expect(instanceRef, matchRecordTypeInstanceRef(length: 3));
        expect(await getObject(instanceId), matchRecordTypeInstance(length: 3));

        final classId = instanceRef.classRef!.id!;
        expect(await getObject(classId), matchRecordTypeClass);
      });
    });

    test('complex record type with named fields elements', () async {
      await onBreakPoint('printComplexNamedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, 'record.runtimeType');
        final instanceId = instanceRef.id!;

        expect(await getElements(instanceId), [
          matchTypeInstance('bool'),
          matchTypeInstance('int'),
          matchTypeInstance('IdentityMap<String, int>'),
        ]);

        expect(await getDisplayedFields(instanceRef), {
          1: 'bool',
          2: 'int',
          'array': 'IdentityMap<String, int>',
        });
      });
    });

    test('complex record type with named fields getters', () async {
      await onBreakPoint('printComplexNamedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, 'record.runtimeType');

        expect(
          await getDisplayedGetters(instanceRef),
          matchDisplayedTypeObjectGetters,
        );
      });
    });

    test('complex record type with named fields display', () async {
      await onBreakPoint('printComplexNamedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final typeStringRef = await getInstanceRef(
          frame,
          'record.runtimeType.toString()',
        );
        final typeStringId = typeStringRef.id!;

        expect(
          await getObject(typeStringId),
          matchPrimitiveInstance(
            kind: InstanceKind.kString,
            value: '(bool, int, {IdentityMap<String, int> array})',
          ),
        );
      });
    });

    test('nested record type', () async {
      await onBreakPoint('printNestedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, 'record.runtimeType');
        final instanceId = instanceRef.id!;

        expect(instanceRef, matchRecordTypeInstanceRef(length: 2));
        expect(await getObject(instanceId), matchRecordTypeInstance(length: 2));

        final classId = instanceRef.classRef!.id!;
        expect(await getObject(classId), matchRecordTypeClass);
      });
    });

    test('nested record type elements', () async {
      await onBreakPoint('printNestedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, 'record.runtimeType');
        final instanceId = instanceRef.id!;

        final elements = await getElements(instanceId);
        expect(elements, [
          matchTypeInstance('bool'),
          matchRecordTypeInstance(length: 2),
        ]);
        expect(await getElements(elements[1].id!), [
          matchTypeInstance('bool'),
          matchTypeInstance('int'),
        ]);
        expect(await getDisplayedFields(instanceRef), {
          1: 'bool',
          2: '(bool, int)',
        });
        expect(await getDisplayedFields(elements[1]), {1: 'bool', 2: 'int'});
      });
    });

    test('nested record type getters', () async {
      await onBreakPoint('printNestedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, 'record.runtimeType');
        final elements = await getElements(instanceRef.id!);

        expect(
          await getDisplayedGetters(instanceRef),
          matchDisplayedTypeObjectGetters,
        );
        expect(
          await getDisplayedGetters(elements[1]),
          matchDisplayedTypeObjectGetters,
        );
      });
    });

    test('nested record type display', () async {
      await onBreakPoint('printNestedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final typeStringRef = await getInstanceRef(
          frame,
          'record.runtimeType.toString()',
        );
        final typeStringId = typeStringRef.id!;

        expect(
          await getObject(typeStringId),
          matchPrimitiveInstance(
            kind: InstanceKind.kString,
            value: '(bool, (bool, int))',
          ),
        );
      });
    });

    test('nested record type with named fields', () async {
      await onBreakPoint('printNestedNamedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, 'record.runtimeType');
        final instanceId = instanceRef.id!;
        final instance = await getObject(instanceId);

        expect(instanceRef, matchRecordTypeInstanceRef(length: 2));
        expect(instance, matchRecordTypeInstance(length: 2));

        final classId = instanceRef.classRef!.id!;
        expect(await getObject(classId), matchRecordTypeClass);
      });
    });

    test('nested record type with named fields elements', () async {
      await onBreakPoint('printNestedNamedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, 'record.runtimeType');
        final instanceId = instanceRef.id!;

        final elements = await getElements(instanceId);
        expect(elements, [
          matchTypeInstance('bool'),
          matchRecordTypeInstance(length: 2),
        ]);
        expect(await getElements(elements[1].id!), [
          matchTypeInstance('bool'),
          matchTypeInstance('int'),
        ]);
        expect(await getDisplayedFields(instanceRef), {
          1: 'bool',
          'inner': '(bool, int)',
        });

        expect(await getDisplayedFields(elements[1]), {1: 'bool', 2: 'int'});
      });
    });

    test('nested record type with named fields getters', () async {
      await onBreakPoint('printNestedNamedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, 'record.runtimeType');
        final elements = await getElements(instanceRef.id!);

        expect(
          await getDisplayedGetters(instanceRef),
          matchDisplayedTypeObjectGetters,
        );
        expect(
          await getDisplayedGetters(elements[1]),
          matchDisplayedTypeObjectGetters,
        );
      });
    });

    test('nested record type with named fields display', () async {
      await onBreakPoint('printNestedNamedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, 'record.runtimeType');
        final instance = await getObject(instanceRef.id!);
        final typeClassId = instance.classRef!.id!;

        expect(await getObject(typeClassId), matchRecordTypeClass);

        final typeStringRef = await getInstanceRef(
          frame,
          'record.runtimeType.toString()',
        );
        final typeStringId = typeStringRef.id!;

        expect(
          await getObject(typeStringId),
          matchPrimitiveInstance(
            kind: InstanceKind.kString,
            value: '(bool, {(bool, int) inner})',
          ),
        );
      });
    });
  });
}
