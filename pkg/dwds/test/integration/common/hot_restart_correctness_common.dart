// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['daily'])
@TestOn('vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:async';

import 'package:dwds/dwds.dart';
import 'package:dwds/expression_compiler.dart';
import 'package:dwds_test_common/logging.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import '../fixtures/context.dart';
import '../fixtures/project.dart';
import '../fixtures/utilities.dart';

const originalString = 'variableToModifyToForceRecompile = 23';
const newString = 'variableToModifyToForceRecompile = 45';

const constantSuccessString = 'ConstantEqualitySuccess';
const constantFailureString = 'ConstantEqualityFailure';

void runTests({
  required TestSdkConfigurationProvider provider,
  required ModuleFormat moduleFormat,
  required CompilationMode compilationMode,
  required bool canaryFeatures,
}) {
  tearDownAll(provider.dispose);

  final testHotRestart2 = TestProject.testHotRestart2;
  final context = TestContext(testHotRestart2, provider);

  Future<void> makeEditAndRecompile() async {
    await context.makeEdits([
      (
        file: 'library2.dart',
        originalString: originalString,
        newString: newString,
      ),
    ]);
    if (compilationMode == CompilationMode.frontendServer) {
      await context.recompile(fullRestart: true);
    } else {
      assert(compilationMode == CompilationMode.buildDaemon);
      await context.waitForSuccessfulBuild(propagateToBrowser: true);
    }
  }

  // Wait for `expectedString` to be printed to the console.
  Future<void> waitForLog(String expectedString) async {
    final completer = Completer<void>();
    final subscription = context.webkitDebugger.onConsoleAPICalled.listen((e) {
      if (e.args.first.value == expectedString) {
        completer.complete();
      }
    });
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

  group('Injected client', () {
    VmService? fakeClient;

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

      fakeClient = await context.connectFakeClient();
    });

    tearDown(() async {
      await context.tearDown();
    });

    test('initial state prints the right log', () async {
      final client = context.debugConnection.vmService;

      final logFuture = waitForLog(
        'ConstObject(reloadVariable: 23, ConstantEqualitySuccess)',
      );
      final vm = await client.getVM();
      final isolate = await client.getIsolate(vm.isolates!.first.id!);
      final rootLib = isolate.rootLib;
      await client.evaluate(isolate.id!, rootLib!.id!, 'printConst()');
      await logFuture;
    });

    test(
      'properly compares constants after hot restart via the service extension',
      () async {
        final client = context.debugConnection.vmService;
        await client.streamListen('Isolate');

        await makeEditAndRecompile();

        final eventsDone = expectLater(
          client.onIsolateEvent,
          emitsThrough(
            emitsInOrder([
              _hasKind(EventKind.kIsolateExit),
              _hasKind(EventKind.kIsolateStart),
              _hasKind(EventKind.kIsolateRunnable),
            ]),
          ),
        );

        final logFuture = waitForLog(
          'ConstObject(reloadVariable: 45, ConstantEqualitySuccess)',
        );
        final hotRestart = context.getRegisteredServiceExtension('hotRestart');
        expect(
          await fakeClient!.callServiceExtension(hotRestart!),
          const TypeMatcher<Success>(),
        );

        await eventsDone;
        await logFuture;
      },
    );
  }, timeout: const Timeout.factor(2));

  group(
    'Injected client with hot restart',
    () {
      group('and with debugging', () {
        setUp(() async {
          setCurrentLogWriter(debug: provider.verbose);
          await context.setUp(
            testSettings: TestSettings(
              reloadConfiguration: ReloadConfiguration.hotRestart,
              compilationMode: compilationMode,
              moduleFormat: provider.ddcModuleFormat,
              canaryFeatures: provider.canaryFeatures,
            ),
          );
        });

        tearDown(() async {
          await context.tearDown();
        });

        test('properly compares constants after hot restart', () async {
          final logFuture = waitForLog(
            'ConstObject(reloadVariable: 45, ConstantEqualitySuccess)',
          );
          await makeEditAndRecompile();
          await logFuture;
        });
      });

      group('and without debugging', () {
        setUp(() async {
          setCurrentLogWriter(debug: provider.verbose);
          await context.setUp(
            testSettings: TestSettings(
              reloadConfiguration: ReloadConfiguration.hotRestart,
              compilationMode: compilationMode,
              moduleFormat: provider.ddcModuleFormat,
              canaryFeatures: provider.canaryFeatures,
            ),
            debugSettings: const TestDebugSettings.noDevToolsLaunch().copyWith(
              enableDebugging: false,
            ),
          );
        });

        tearDown(() async {
          await context.tearDown();
        });

        test('properly compares constants after hot restart', () async {
          final logFuture = waitForLog(
            'ConstObject(reloadVariable: 45, ConstantEqualitySuccess)',
          );
          await makeEditAndRecompile();
          await logFuture;
        });
      });
    },
    // `BuildResult`s are only ever emitted when using the build daemon.
    skip: compilationMode == CompilationMode.buildDaemon ? null : true,
    timeout: const Timeout.factor(2),
  );
}

TypeMatcher<Event> _hasKind(String kind) =>
    isA<Event>().having((e) => e.kind, 'kind', kind);
