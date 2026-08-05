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

  Future<Instance> getInstance(int frame, String expression) =>
      testInspector.getInstance(isolateId, frame, expression);

  Future<Obj> getObject(String instanceId) =>
      service.getObject(isolateId, instanceId);

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

    test('simple record display', () async {
      await onBreakPoint('printSimpleLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;

        final instanceRef = await getInstanceRef(frame, 'record');
        final classId = instanceRef.classRef!.id!;

        expect(await getObject(classId), matchRecordClass);

        final stringRef = await getInstanceRef(frame, 'record.toString()');
        final stringRefId = stringRef.id!;

        expect(
          await getObject(stringRefId),
          matchPrimitiveInstance(
            kind: InstanceKind.kString,
            value: '(true, 3)',
          ),
        );
      });
    });

    test('simple records', () async {
      await onBreakPoint('printSimpleLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, 'record');
        final instanceId = instanceRef.id!;

        expect(instanceRef, matchRecordInstanceRef(length: 2));
        expect(await getObject(instanceId), matchRecordInstance(length: 2));

        expect(await getFields(instanceRef), {1: true, 2: 3});
        expect(await getFields(instanceRef, offset: 0), {1: true, 2: 3});
        expect(await getFields(instanceRef, offset: 1), {2: 3});
        expect(await getFields(instanceRef, offset: 2), <Object?, Object?>{});
        expect(
          await getFields(instanceRef, offset: 0, count: 0),
          <Object?, Object?>{},
        );
        expect(await getFields(instanceRef, offset: 0, count: 1), {1: true});
        expect(await getFields(instanceRef, offset: 0, count: 2), {
          1: true,
          2: 3,
        });
        expect(await getFields(instanceRef, offset: 0, count: 5), {
          1: true,
          2: 3,
        });
        expect(
          await getFields(instanceRef, offset: 2, count: 5),
          <Object?, Object?>{},
        );
      });
    });

    test('simple records, field access', () async {
      await onBreakPoint('printSimpleLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        expect(
          await getInstance(frame, r'record.$1'),
          matchPrimitiveInstance(kind: InstanceKind.kBool, value: true),
        );

        expect(
          await getInstance(frame, r'record.$2'),
          matchPrimitiveInstance(kind: InstanceKind.kDouble, value: 3),
        );
      });
    });

    test('simple records with named fields display', () async {
      await onBreakPoint('printSimpleNamedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;

        final instanceRef = await getInstanceRef(frame, 'record');
        final classId = instanceRef.classRef!.id!;

        expect(await getObject(classId), matchRecordClass);

        final stringRef = await getInstanceRef(frame, 'record.toString()');
        final stringId = stringRef.id!;

        expect(
          await getObject(stringId),
          matchPrimitiveInstance(
            kind: InstanceKind.kString,
            value: '(true, cat: Vasya)',
          ),
        );
      });
    });

    test('simple records with named fields', () async {
      await onBreakPoint('printSimpleNamedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, 'record');

        final instanceId = instanceRef.id!;
        expect(instanceRef, matchRecordInstanceRef(length: 2));
        expect(await getObject(instanceId), matchRecordInstance(length: 2));

        expect(await getFields(instanceRef), {1: true, 'cat': 'Vasya'});
        expect(await getFields(instanceRef, offset: 0), {
          1: true,
          'cat': 'Vasya',
        });
        expect(await getFields(instanceRef, offset: 1), {'cat': 'Vasya'});
        expect(await getFields(instanceRef, offset: 2), <Object?, Object?>{});
        expect(
          await getFields(instanceRef, offset: 0, count: 0),
          <Object?, Object?>{},
        );
        expect(await getFields(instanceRef, offset: 0, count: 1), {1: true});
        expect(await getFields(instanceRef, offset: 0, count: 2), {
          1: true,
          'cat': 'Vasya',
        });
        expect(await getFields(instanceRef, offset: 0, count: 5), {
          1: true,
          'cat': 'Vasya',
        });
        expect(
          await getFields(instanceRef, offset: 2, count: 5),
          <Object?, Object?>{},
        );
      });
    });

    test('simple records with named fields, field access', () async {
      await onBreakPoint('printSimpleNamedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        expect(
          await getInstance(frame, r'record.$1'),
          matchPrimitiveInstance(kind: InstanceKind.kBool, value: true),
        );

        expect(
          await getInstance(frame, r'record.cat'),
          matchPrimitiveInstance(kind: InstanceKind.kString, value: 'Vasya'),
        );
      });
    });

    test('complex records display', () async {
      await onBreakPoint('printComplexLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;

        final instanceRef = await getInstanceRef(frame, 'record');
        final classId = instanceRef.classRef!.id!;

        expect(await getObject(classId), matchRecordClass);

        final stringRef = await getInstanceRef(frame, 'record.toString()');
        final stringId = stringRef.id!;

        expect(
          await getObject(stringId),
          matchPrimitiveInstance(
            kind: InstanceKind.kString,
            value: '(true, 3, {a: 1, b: 5})',
          ),
        );
      });
    });

    test('complex records', () async {
      await onBreakPoint('printComplexLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, 'record');

        final instanceId = instanceRef.id!;
        expect(instanceRef, matchRecordInstanceRef(length: 3));
        expect(await getObject(instanceId), matchRecordInstance(length: 3));

        expect(await getFields(instanceRef), {
          1: true,
          2: 3,
          3: {'a': 1, 'b': 5},
        });
        expect(await getFields(instanceRef, offset: 0), {
          1: true,
          2: 3,
          3: {'a': 1, 'b': 5},
        });
        expect(await getFields(instanceRef, offset: 1), {
          2: 3,
          3: {'a': 1, 'b': 5},
        });
        expect(await getFields(instanceRef, offset: 1, count: 1), {2: 3});
        expect(await getFields(instanceRef, offset: 1, count: 2), {
          2: 3,
          3: {'a': 1, 'b': 5},
        });
        expect(await getFields(instanceRef, offset: 2), {
          3: {'a': 1, 'b': 5},
        });
        expect(await getFields(instanceRef, offset: 3), <Object?, Object?>{});
        expect(
          await getFields(instanceRef, offset: 0, count: 0),
          <Object?, Object?>{},
        );
        expect(await getFields(instanceRef, offset: 0, count: 1), {1: true});
        expect(await getFields(instanceRef, offset: 0, count: 2), {
          1: true,
          2: 3,
        });
        expect(await getFields(instanceRef, offset: 0, count: 5), {
          1: true,
          2: 3,
          3: {'a': 1, 'b': 5},
        });
        expect(
          await getFields(instanceRef, offset: 3, count: 5),
          <Object?, Object?>{},
        );
      });
    });

    test('complex records, field access', () async {
      await onBreakPoint('printComplexLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        expect(
          await getInstance(frame, r'record.$1'),
          matchPrimitiveInstance(kind: InstanceKind.kBool, value: true),
        );

        expect(
          await getInstance(frame, r'record.$2'),
          matchPrimitiveInstance(kind: InstanceKind.kDouble, value: 3),
        );

        final third = await getInstanceRef(frame, r'record.$3');
        expect(third.kind, InstanceKind.kMap);
        expect(await getFields(third), {'a': 1, 'b': 5});
      });
    });

    test('complex records with named fields display', () async {
      await onBreakPoint('printComplexNamedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;

        final instanceRef = await getInstanceRef(frame, 'record');
        final classId = instanceRef.classRef!.id!;

        expect(await getObject(classId), matchRecordClass);

        final stringRef = await getInstanceRef(frame, 'record.toString()');
        final stringId = stringRef.id!;

        expect(
          await getObject(stringId),
          matchPrimitiveInstance(
            kind: InstanceKind.kString,
            value: '(true, 3, array: {a: 1, b: 5})',
          ),
        );
      });
    });

    test('complex records with named fields', () async {
      await onBreakPoint('printComplexNamedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, 'record');

        final instanceId = instanceRef.id!;
        expect(instanceRef, matchRecordInstanceRef(length: 3));
        expect(await getObject(instanceId), matchRecordInstance(length: 3));

        expect(await getFields(instanceRef), {
          1: true,
          2: 3,
          'array': {'a': 1, 'b': 5},
        });
        expect(await getFields(instanceRef, offset: 0), {
          1: true,
          2: 3,
          'array': {'a': 1, 'b': 5},
        });
        expect(await getFields(instanceRef, offset: 1), {
          2: 3,
          'array': {'a': 1, 'b': 5},
        });
        expect(await getFields(instanceRef, offset: 1, count: 1), {2: 3});
        expect(await getFields(instanceRef, offset: 1, count: 2), {
          2: 3,
          'array': {'a': 1, 'b': 5},
        });
        expect(await getFields(instanceRef, offset: 2), {
          'array': {'a': 1, 'b': 5},
        });
        expect(await getFields(instanceRef, offset: 3), <Object?, Object?>{});
        expect(
          await getFields(instanceRef, offset: 0, count: 0),
          <Object?, Object?>{},
        );
        expect(await getFields(instanceRef, offset: 0, count: 1), {1: true});
        expect(await getFields(instanceRef, offset: 0, count: 2), {
          1: true,
          2: 3,
        });
        expect(await getFields(instanceRef, offset: 0, count: 5), {
          1: true,
          2: 3,
          'array': {'a': 1, 'b': 5},
        });
        expect(
          await getFields(instanceRef, offset: 3, count: 5),
          <Object?, Object?>{},
        );
      });
    });

    test('complex records with named fields, field access', () async {
      await onBreakPoint('printComplexNamedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        expect(
          await getInstance(frame, r'record.$1'),
          matchPrimitiveInstance(kind: InstanceKind.kBool, value: true),
        );

        expect(
          await getInstance(frame, r'record.$2'),
          matchPrimitiveInstance(kind: InstanceKind.kDouble, value: 3),
        );

        final third = await getInstanceRef(frame, r'record.array');
        expect(third.kind, InstanceKind.kMap);
        expect(await getFields(third), {'a': 1, 'b': 5});
      });
    });

    test('nested records display', () async {
      await onBreakPoint('printNestedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;

        final instanceRef = await getInstanceRef(frame, 'record');
        final classId = instanceRef.classRef!.id!;

        expect(await getObject(classId), matchRecordClass);

        final stringRef = await getInstanceRef(frame, 'record.toString()');
        final stringId = stringRef.id!;

        expect(
          await getObject(stringId),
          matchPrimitiveInstance(
            kind: InstanceKind.kString,
            value: '(true, (false, 5))',
          ),
        );
      });
    });

    test('nested records', () async {
      await onBreakPoint('printNestedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, 'record');

        final instanceId = instanceRef.id!;
        expect(instanceRef, matchRecordInstanceRef(length: 2));
        expect(await getObject(instanceId), matchRecordInstance(length: 2));

        expect(await getFields(instanceRef), {
          1: true,
          2: {1: false, 2: 5},
        });
        expect(await getFields(instanceRef, offset: 0), {
          1: true,
          2: {1: false, 2: 5},
        });
        expect(await getFields(instanceRef, offset: 1), {
          2: {1: false, 2: 5},
        });
        expect(await getFields(instanceRef, offset: 2), <Object?, Object?>{});
        expect(
          await getFields(instanceRef, offset: 0, count: 0),
          <Object?, Object?>{},
        );
        expect(await getFields(instanceRef, offset: 0, count: 1), {1: true});
        expect(await getFields(instanceRef, offset: 0, count: 2), {
          1: true,
          2: {1: false, 2: 5},
        });
        expect(await getFields(instanceRef, offset: 0, count: 5), {
          1: true,
          2: {1: false, 2: 5},
        });
        expect(
          await getFields(instanceRef, offset: 2, count: 5),
          <Object?, Object?>{},
        );
      });
    });

    test('nested records, field access', () async {
      await onBreakPoint('printNestedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, r'record.$2');

        final instanceId = instanceRef.id!;
        expect(instanceRef, matchRecordInstanceRef(length: 2));
        expect(await getObject(instanceId), matchRecordInstance(length: 2));

        expect(await getFields(instanceRef), {1: false, 2: 5});
        expect(await getFields(instanceRef, offset: 0), {1: false, 2: 5});
      });
    });

    test('nested records with named fields display', () async {
      await onBreakPoint('printNestedNamedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;

        final instanceRef = await getInstanceRef(frame, 'record');
        final classId = instanceRef.classRef!.id!;

        expect(await getObject(classId), matchRecordClass);

        final stringRef = await getInstanceRef(frame, 'record.toString()');
        final stringId = stringRef.id!;

        expect(
          await getObject(stringId),
          matchPrimitiveInstance(
            kind: InstanceKind.kString,
            value: '(true, inner: (false, 5))',
          ),
        );
      });
    });

    test('nested records with named fields', () async {
      await onBreakPoint('printNestedNamedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, 'record');

        final instanceId = instanceRef.id!;
        expect(instanceRef, matchRecordInstanceRef(length: 2));
        expect(await getObject(instanceId), matchRecordInstance(length: 2));

        expect(await getFields(instanceRef), {
          1: true,
          'inner': {1: false, 2: 5},
        });
        expect(await getFields(instanceRef, offset: 0), {
          1: true,
          'inner': {1: false, 2: 5},
        });
        expect(await getFields(instanceRef, offset: 1), {
          'inner': {1: false, 2: 5},
        });
        expect(await getFields(instanceRef, offset: 1, count: 1), {
          'inner': {1: false, 2: 5},
        });
        expect(await getFields(instanceRef, offset: 1, count: 2), {
          'inner': {1: false, 2: 5},
        });
        expect(await getFields(instanceRef, offset: 2), <Object?, Object?>{});
        expect(
          await getFields(instanceRef, offset: 0, count: 0),
          <Object?, Object?>{},
        );
        expect(await getFields(instanceRef, offset: 0, count: 1), {1: true});
        expect(await getFields(instanceRef, offset: 0, count: 2), {
          1: true,
          'inner': {1: false, 2: 5},
        });
        expect(await getFields(instanceRef, offset: 0, count: 5), {
          1: true,
          'inner': {1: false, 2: 5},
        });
        expect(
          await getFields(instanceRef, offset: 2, count: 5),
          <Object?, Object?>{},
        );
      });
    });

    test('nested records with named fields, field access', () async {
      await onBreakPoint('printNestedNamedLocalRecord', (Event event) async {
        final frame = event.topFrame!.index!;
        final instanceRef = await getInstanceRef(frame, r'record.inner');

        final instanceId = instanceRef.id!;
        expect(instanceRef, matchRecordInstanceRef(length: 2));
        expect(await getObject(instanceId), matchRecordInstance(length: 2));

        expect(await getFields(instanceRef), {1: false, 2: 5});
        expect(await getFields(instanceRef, offset: 0), {1: false, 2: 5});
      });
    });
  });
}
