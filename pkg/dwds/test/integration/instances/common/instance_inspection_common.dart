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
  final project = TestProject.testPackage();
  final context = TestContext(project, provider);

  late VmService service;
  late Stream<Event> stream;
  late String isolateId;
  late ScriptRef mainScript;

  final testInspector = TestInspector(context);

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
  }) => testInspector.getFields(
    isolateId,
    instanceRef,
    offset: offset,
    count: count,
  );

  group('$compilationMode |', () {
    setUpAll(() async {
      setCurrentLogWriter(debug: provider.verbose);
      await context.setUp(
        testSettings: TestSettings(
          compilationMode: compilationMode,
          enableExpressionEvaluation: true,
          verboseCompiler: provider.verbose,
          canaryFeatures: canaryFeatures,
          experiments: ['records'],
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

    tearDownAll(context.tearDown);

    setUp(() => setCurrentLogWriter(debug: provider.verbose));
    tearDown(() async {
      // We must resume execution in case a test left the isolate paused, but
      // error 106 is expected if the isolate is already running.
      try {
        await service.resume(isolateId);
      } on RPCError catch (e) {
        if (e.code != 106) rethrow;
      }
    });

    group('Library |', () {
      test('classes', () async {
        const libraryId = 'org-dartlang-app:///web/main.dart';
        final library = await getObject(libraryId);

        expect(
          library,
          isA<Library>().having((l) => l.classes, 'classes', [
            matchClassRef(name: 'MainClass', libraryId: libraryId),
            matchClassRef(name: 'EnclosedClass', libraryId: libraryId),
            matchClassRef(name: 'ClassWithMethod', libraryId: libraryId),
            matchClassRef(name: 'EnclosingClass', libraryId: libraryId),
          ]),
        );
      });
    });

    group('Class |', () {
      test('name and library', () async {
        const libraryId = 'org-dartlang-app:///web/main.dart';
        const className = 'MainClass';
        final cls = await getObject('classes|$libraryId|$className');

        expect(cls, matchClass(name: className, libraryId: libraryId));
      });
    });

    group('Object |', () {
      test('type and fields', () async {
        await onBreakPoint('printFieldMain', (Event event) async {
          final frame = event.topFrame!.index!;
          final instanceRef = await getInstanceRef(frame, 'instance');

          final instanceId = instanceRef.id!;
          expect(
            await getObject(instanceId),
            matchPlainInstance(
              libraryId: 'org-dartlang-app:///web/main.dart',
              type: 'MainClass',
            ),
          );

          expect(await getFields(instanceRef), {'_field': 1, 'field': 2});

          // Offsets and counts are ignored for plain object fields.

          // DevTools calls [VmServiceInterface.getObject] with offset=0
          // and count=0 and expects all fields to be returned.
          expect(await getFields(instanceRef, offset: 0, count: 0), {
            '_field': 1,
            'field': 2,
          });
          expect(await getFields(instanceRef, offset: 0), {
            '_field': 1,
            'field': 2,
          });
          expect(await getFields(instanceRef, offset: 0, count: 1), {
            '_field': 1,
            'field': 2,
          });
          expect(await getFields(instanceRef, offset: 1), {
            '_field': 1,
            'field': 2,
          });
          expect(await getFields(instanceRef, offset: 1, count: 0), {
            '_field': 1,
            'field': 2,
          });
          expect(await getFields(instanceRef, offset: 1, count: 3), {
            '_field': 1,
            'field': 2,
          });
        });
      });

      test('field access', () async {
        await onBreakPoint('printFieldMain', (Event event) async {
          final frame = event.topFrame!.index!;
          expect(
            await getInstance(frame, r'instance.field'),
            matchPrimitiveInstance(kind: InstanceKind.kDouble, value: 2),
          );

          expect(
            await getInstance(frame, r'instance._field'),
            matchPrimitiveInstance(kind: InstanceKind.kDouble, value: 1),
          );
        });
      });
    });

    group('List |', () {
      test('type and fields', () async {
        await onBreakPoint('printList', (Event event) async {
          final frame = event.topFrame!.index!;
          final instanceRef = await getInstanceRef(frame, 'list');

          final instanceId = instanceRef.id!;
          expect(await getObject(instanceId), matchListInstance(type: 'int'));

          expect(await getFields(instanceRef), {0: 0.0, 1: 1.0, 2: 2.0});
          expect(
            await getFields(instanceRef, offset: 1, count: 0),
            <Object?, Object?>{},
          );
          expect(await getFields(instanceRef, offset: 0), {
            0: 0.0,
            1: 1.0,
            2: 2.0,
          });
          expect(await getFields(instanceRef, offset: 0, count: 1), {0: 0.0});
          expect(await getFields(instanceRef, offset: 1), {0: 1.0, 1: 2.0});
          expect(await getFields(instanceRef, offset: 1, count: 1), {0: 1.0});
          expect(await getFields(instanceRef, offset: 1, count: 3), {
            0: 1.0,
            1: 2.0,
          });
          expect(
            await getFields(instanceRef, offset: 3, count: 3),
            <Object?, Object?>{},
          );
        });
      });

      test('Element access', () async {
        await onBreakPoint('printList', (Event event) async {
          final frame = event.topFrame!.index!;
          expect(
            await getInstance(frame, r'list[0]'),
            matchPrimitiveInstance(kind: InstanceKind.kDouble, value: 0),
          );

          expect(
            await getInstance(frame, r'list[1]'),
            matchPrimitiveInstance(kind: InstanceKind.kDouble, value: 1),
          );

          expect(
            await getInstance(frame, r'list[2]'),
            matchPrimitiveInstance(kind: InstanceKind.kDouble, value: 2),
          );
        });
      });
    });

    group('Map |', () {
      test('type and fields', () async {
        await onBreakPoint('printMap', (Event event) async {
          final frame = event.topFrame!.index!;
          final instanceRef = await getInstanceRef(frame, 'map');

          final instanceId = instanceRef.id!;
          expect(
            await getObject(instanceId),
            matchMapInstance(type: 'IdentityMap<String, int>'),
          );

          expect(await getFields(instanceRef), {'a': 1, 'b': 2, 'c': 3});

          expect(
            await getFields(instanceRef, offset: 1, count: 0),
            <Object?, Object?>{},
          );
          expect(await getFields(instanceRef, offset: 0), {
            'a': 1,
            'b': 2,
            'c': 3,
          });
          expect(await getFields(instanceRef, offset: 0, count: 1), {'a': 1});
          expect(await getFields(instanceRef, offset: 1), {'b': 2, 'c': 3});
          expect(await getFields(instanceRef, offset: 1, count: 1), {'b': 2});
          expect(await getFields(instanceRef, offset: 1, count: 3), {
            'b': 2,
            'c': 3,
          });
          expect(
            await getFields(instanceRef, offset: 3, count: 3),
            <Object?, Object?>{},
          );
        });
      });

      test('Element access', () async {
        await onBreakPoint('printMap', (Event event) async {
          final frame = event.topFrame!.index!;
          expect(
            await getInstance(frame, r"map['a']"),
            matchPrimitiveInstance(kind: InstanceKind.kDouble, value: 1),
          );

          expect(
            await getInstance(frame, r"map['b']"),
            matchPrimitiveInstance(kind: InstanceKind.kDouble, value: 2),
          );

          expect(
            await getInstance(frame, r"map['c']"),
            matchPrimitiveInstance(kind: InstanceKind.kDouble, value: 3),
          );
        });
      });
    });

    group('Set |', () {
      test('type and fields', () async {
        await onBreakPoint('printSet', (Event event) async {
          final frame = event.topFrame!.index!;
          final instanceRef = await getInstanceRef(frame, 'mySet');

          final instanceId = instanceRef.id!;
          expect(
            await getObject(instanceId),
            matchSetInstance(type: 'LinkedSet<int>'),
          );

          expect(await getFields(instanceRef), {
            0: 1.0,
            1: 4.0,
            2: 5.0,
            3: 7.0,
          });
          expect(await getFields(instanceRef, offset: 0), {
            0: 1.0,
            1: 4.0,
            2: 5.0,
            3: 7.0,
          });
          expect(await getFields(instanceRef, offset: 1, count: 2), {
            0: 4.0,
            1: 5.0,
          });
          expect(await getFields(instanceRef, offset: 2), {0: 5.0, 1: 7.0});
          expect(await getFields(instanceRef, offset: 2, count: 10), {
            0: 5.0,
            1: 7.0,
          });
          expect(
            await getFields(instanceRef, offset: 1, count: 0),
            <Object?, Object?>{},
          );
          expect(
            await getFields(instanceRef, offset: 10, count: 2),
            <Object?, Object?>{},
          );
        });
      });

      test('Element access', () async {
        await onBreakPoint('printSet', (Event event) async {
          final frame = event.topFrame!.index!;
          expect(
            await getInstance(frame, r'mySet.first'),
            matchPrimitiveInstance(kind: InstanceKind.kDouble, value: 1),
          );
          expect(
            await getInstance(frame, r'mySet.last'),
            matchPrimitiveInstance(kind: InstanceKind.kDouble, value: 7),
          );
        });
      });
    });
  });
}
