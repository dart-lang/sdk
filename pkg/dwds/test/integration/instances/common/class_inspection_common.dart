// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['daily'])
@TestOn('vm')
@Timeout(Duration(minutes: 2))
library;

import 'package:dwds_test_common/logging.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import '../../fixtures/context.dart';
import '../../fixtures/project.dart';
import '../../fixtures/utilities.dart';
import '../common/test_inspector.dart';

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

    group('calling getObject for an existent class', () {
      test('returns the correct class representation', () async {
        await onBreakPoint('testClass1Case1', (Event event) async {
          // classes|dart:core|Object_Diagnosticable
          final result = await getObject(
            'classes|org-dartlang-app:///web/main.dart|GreeterClass',
          );
          final clazz = result as Class?;
          expect(clazz!.name, equals('GreeterClass'));
          expect(
            clazz.fields!.map((field) => field.name),
            unorderedEquals(['greeteeName', 'useFrench']),
          );
          expect(
            clazz.functions!.map((fn) => fn.name),
            containsAll(['sayHello', 'greetInEnglish', 'greetInFrench']),
          );
        });
      });
    });

    group('calling getObject for a non-existent class', () {
      // TODO(https://github.com/dart-lang/webdev/issues/2297): Ideally we
      // should throw an error in this case for the client to catch instead
      // of returning an empty class.
      test('returns an empty class representation', () async {
        await onBreakPoint('testClass1Case1', (Event event) async {
          final result = await getObject(
            'classes|dart:core|Object_Diagnosticable',
          );
          final clazz = result as Class?;
          expect(clazz!.name, equals('Object_Diagnosticable'));
          expect(clazz.fields, isEmpty);
          expect(clazz.functions, isEmpty);
        });
      });
    });
  });
}
