// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dwds/src/events.dart';
import 'package:dwds_test_common/logging.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service_interface/vm_service_interface.dart';
import 'package:webdriver/async_core.dart';

import 'fixtures/context.dart';
import 'fixtures/project.dart';
import 'fixtures/utilities.dart';

void testWithDwds({required TestSdkConfigurationProvider provider}) {
  final context = TestContext(TestProject.test, provider);

  group(
    'with dwds',
    () {
      Future? initialEvents;
      late Keyboard keyboard;
      late Stream<DwdsEvent> events;
      late VmService fakeClient;

      /// Runs [action] and waits for an event matching [eventMatcher].
      Future<T> expectEventDuring<T>(
        Matcher eventMatcher,
        Future<T> Function() action, {
        Timeout? timeout,
      }) async {
        // The events stream is a broadcast stream so start listening
        // before the action.
        final events = expectLater(
          pipe(context.testServer.dwds.events, timeout: timeout),
          emitsThrough(eventMatcher),
        );
        final result = await action();
        await events;
        return result;
      }

      /// Runs [action] and waits for an event matching [eventMatcher].
      Future<T> expectEventsDuring<T>(
        List<Matcher> eventMatchers,
        Future<T> Function() action, {
        Timeout? timeout,
      }) async {
        // The events stream is a broadcast stream so start listening
        // before the action.
        final events = eventMatchers.map(
          (matcher) => expectLater(
            pipe(context.testServer.dwds.events, timeout: timeout),
            emitsThrough(matcher),
          ),
        );
        final result = await action();
        await Future.wait(events);
        return result;
      }

      setUpAll(() async {
        setCurrentLogWriter(debug: provider.verbose);
        initialEvents = expectLater(
          pipe(eventStream, timeout: const Timeout.factor(5)),
          emitsThrough(
            matchesEvent(DwdsEventKind.compilerUpdateDependencies, {
              'entrypoint': 'hello_world/main.dart.bootstrap.js',
              'elapsedMilliseconds': isNotNull,
            }),
          ),
        );
        await context.setUp(
          testSettings: TestSettings(
            enableExpressionEvaluation: true,
            moduleFormat: provider.ddcModuleFormat,
            verboseCompiler: provider.verbose,
            canaryFeatures: provider.canaryFeatures,
          ),
          debugSettings: TestDebugSettings.withDevToolsLaunch(context),
        );
        keyboard = context.webDriver.driver.keyboard;
        events = context.testServer.dwds.events;
        fakeClient = await context.connectFakeClient();
      });

      tearDownAll(() async {
        await context.tearDown();
      });

      test(
        'emits DEBUGGER_READY and DEVTOOLS_LOAD events',
        () async {
          await expectEventsDuring([
            matchesEvent(DwdsEventKind.debuggerReady, {
              'elapsedMilliseconds': isNotNull,
              'screen': equals('debugger'),
            }),
            matchesEvent(DwdsEventKind.devToolsLoad, {
              'elapsedMilliseconds': isNotNull,
              'screen': equals('debugger'),
            }),
          ], () => keyboard.sendChord([Keyboard.alt, 'd']));
        },
        skip: 'https://github.com/dart-lang/webdev/issues/2394',
      );

      test('emits DEVTOOLS_LAUNCH event', () async {
        await expectEventDuring(
          matchesEvent(DwdsEventKind.devtoolsLaunch, {}),
          () => keyboard.sendChord([Keyboard.alt, 'd']),
        );
      });

      test('events can be listened to multiple times', () async {
        events.listen((_) {});
        events.listen((_) {});
      });

      test('can emit event through service extension', () async {
        final response = await expectEventDuring(
          matchesEvent('foo-event', {'data': 1234}),
          () => fakeClient.callServiceExtension(
            'ext.dwds.emitEvent',
            args: {
              'type': 'foo-event',
              'payload': {'data': 1234},
            },
          ),
        );
        expect(response.type, 'Success');
      });

      group('evaluate', () {
        late VmServiceInterface service;
        late String isolateId;
        late String bootstrapId;

        setUpAll(() async {
          setCurrentLogWriter(debug: provider.verbose);
          service = context.service;
          final vm = await service.getVM();
          final isolate = await service.getIsolate(vm.isolates!.first.id!);
          isolateId = isolate.id!;
          bootstrapId = isolate.rootLib!.id!;
        });

        setUp(() async {
          setCurrentLogWriter(debug: provider.verbose);
        });

        test('emits EVALUATE events on evaluation success', () async {
          final expression = "helloString('world')";
          await expectEventDuring(
            matchesEvent(DwdsEventKind.evaluate, {
              'expression': expression,
              'success': isTrue,
              'elapsedMilliseconds': isNotNull,
            }),
            () => service.evaluate(isolateId, bootstrapId, expression),
          );
        });

        test('emits COMPILER_UPDATE_DEPENDENCIES event', () async {
          await initialEvents;
        });

        test('emits EVALUATE events on evaluation failure', () async {
          final expression = 'some-bad-expression';
          await expectEventDuring(
            matchesEvent(DwdsEventKind.evaluate, {
              'expression': expression,
              'success': isFalse,
              'error': isA<ErrorRef>(),
              'elapsedMilliseconds': isNotNull,
            }),
            () => service.evaluate(isolateId, bootstrapId, expression),
          );
        });
      });

      group('evaluateInFrame', () {
        late VmServiceInterface service;
        late String isolateId;
        late Stream<Event> stream;
        late ScriptRef mainScript;

        setUpAll(() async {
          setCurrentLogWriter(debug: provider.verbose);
          service = context.service;
          final vm = await service.getVM();

          isolateId = vm.isolates!.first.id!;
          await service.streamListen('Debug');
          stream = service.onEvent('Debug');
          final scriptList = await service.getScripts(isolateId);
          mainScript = scriptList.scripts!.firstWhere(
            (script) => script.uri!.contains('main.dart'),
          );
        });

        setUp(() async {
          setCurrentLogWriter(debug: provider.verbose);
        });

        test('emits EVALUATE_IN_FRAME events on RPC error', () async {
          final expression = 'some-bad-expression';
          await expectEventDuring(
            matchesEvent(DwdsEventKind.evaluateInFrame, {
              'expression': expression,
              'success': isFalse,
              'exception': isA<RPCError>().having(
                (e) => e.message,
                'message',
                contains('program is not paused'),
              ),
              'elapsedMilliseconds': isNotNull,
            }),
            () => service
                .evaluateInFrame(isolateId, 0, expression)
                .catchError((_) => Future.value(Response())),
          );
        });

        test('emits EVALUATE_IN_FRAME events on evaluation error', () async {
          final line = await context.findBreakpointLine(
            'callPrintCount',
            isolateId,
            mainScript,
          );
          final bp = await service.addBreakpoint(
            isolateId,
            mainScript.id!,
            line,
          );
          // Wait for breakpoint to trigger.
          await stream.firstWhere(
            (event) => event.kind == EventKind.kPauseBreakpoint,
          );

          // Evaluation succeeds and return ErrorRef containing compilation
          // error, so event is marked as success.
          final expression = 'some-bad-expression';
          await expectEventDuring(
            matchesEvent(DwdsEventKind.evaluateInFrame, {
              'expression': expression,
              'success': isFalse,
              'error': isA<ErrorRef>(),
              'elapsedMilliseconds': isNotNull,
            }),
            () => service
                .evaluateInFrame(isolateId, 0, expression)
                .catchError((_) => Future.value(Response())),
          );

          await service.removeBreakpoint(isolateId, bp.id!);
          await service.resume(isolateId);
        });

        test('emits EVALUATE_IN_FRAME events on evaluation success', () async {
          final line = await context.findBreakpointLine(
            'callPrintCount',
            isolateId,
            mainScript,
          );
          final bp = await service.addBreakpoint(
            isolateId,
            mainScript.id!,
            line,
          );
          // Wait for breakpoint to trigger.
          await stream.firstWhere(
            (event) => event.kind == EventKind.kPauseBreakpoint,
          );

          // Evaluation succeeds and return InstanceRef,
          // so event is marked as success.
          final expression = 'true';
          await expectEventDuring(
            matchesEvent(DwdsEventKind.evaluateInFrame, {
              'expression': expression,
              'success': isTrue,
              'elapsedMilliseconds': isNotNull,
            }),
            () => service
                .evaluateInFrame(isolateId, 0, expression)
                .catchError((_) => Future.value(Response())),
          );

          await service.removeBreakpoint(isolateId, bp.id!);
          await service.resume(isolateId);
        });
      });

      group('getSourceReport', () {
        late VmServiceInterface service;
        late String isolateId;
        late ScriptRef mainScript;

        setUp(() async {
          setCurrentLogWriter(debug: provider.verbose);
          service = context.service;
          final vm = await service.getVM();
          isolateId = vm.isolates!.first.id!;
          final scriptList = await service.getScripts(isolateId);

          mainScript = scriptList.scripts!.firstWhere(
            (script) => script.uri!.contains('main.dart'),
          );
        });

        test('emits GET_SOURCE_REPORT events', () async {
          await expectEventDuring(
            matchesEvent(DwdsEventKind.getSourceReport, {
              'elapsedMilliseconds': isNotNull,
            }),
            () => service.getSourceReport(isolateId, [
              SourceReportKind.kPossibleBreakpoints,
            ], scriptId: mainScript.id),
          );
        });
      });

      group('getScripts', () {
        late VmServiceInterface service;
        late String isolateId;

        setUp(() async {
          setCurrentLogWriter(debug: provider.verbose);
          service = context.service;
          final vm = await service.getVM();
          isolateId = vm.isolates!.first.id!;
        });

        test('emits GET_SCRIPTS events', () async {
          await expectEventDuring(
            matchesEvent(DwdsEventKind.getScripts, {
              'elapsedMilliseconds': isNotNull,
            }),
            () => service.getScripts(isolateId),
          );
        });
      });

      group('getIsolate', () {
        late VmServiceInterface service;
        late String isolateId;

        setUp(() async {
          setCurrentLogWriter(debug: provider.verbose);
          service = context.service;
          final vm = await service.getVM();
          isolateId = vm.isolates!.first.id!;
        });

        test('emits GET_ISOLATE events', () async {
          await expectEventDuring(
            matchesEvent(DwdsEventKind.getIsolate, {
              'elapsedMilliseconds': isNotNull,
            }),
            () => service.getIsolate(isolateId),
          );
        });
      });

      group('getVM', () {
        setUp(() async {
          setCurrentLogWriter(debug: provider.verbose);
        });

        test('emits GET_VM events', () async {
          await expectEventDuring(
            matchesEvent(DwdsEventKind.getVM, {
              'elapsedMilliseconds': isNotNull,
            }),
            () => context.service.getVM(),
          );
        });
      });

      group('hotRestart', () {
        setUp(() async {
          setCurrentLogWriter(debug: provider.verbose);
        });

        test('emits HOT_RESTART event', () async {
          final hotRestart = context.getRegisteredServiceExtension(
            'hotRestart',
          );

          await expectEventDuring(
            matchesEvent(DwdsEventKind.hotRestart, {
              'elapsedMilliseconds': isNotNull,
            }),
            () => fakeClient.callServiceExtension(hotRestart!),
          );
        });
      });

      group('resume', () {
        late VmServiceInterface service;
        late String isolateId;

        setUp(() async {
          setCurrentLogWriter(debug: provider.verbose);
          service = context.service;
          final vm = await service.getVM();
          isolateId = vm.isolates!.first.id!;
          await service.streamListen('Debug');
          final stream = service.onEvent('Debug');
          final scriptList = await service.getScripts(isolateId);
          final mainScript = scriptList.scripts!.firstWhere(
            (script) => script.uri!.contains('main.dart'),
          );
          final line = await context.findBreakpointLine(
            'callPrintCount',
            isolateId,
            mainScript,
          );
          final bp = await service.addBreakpoint(
            isolateId,
            mainScript.id!,
            line,
          );
          // Wait for breakpoint to trigger.
          await stream.firstWhere(
            (event) => event.kind == EventKind.kPauseBreakpoint,
          );
          await service.removeBreakpoint(isolateId, bp.id!);
        });

        tearDown(() async {
          // We must resume execution in case a test left the isolate paused,
          // but error 106 is expected if the isolate is already running.
          try {
            await service.resume(isolateId);
          } on RPCError catch (e) {
            if (e.code != 106) rethrow;
          }
        });

        test('emits RESUME events', () async {
          await expectEventDuring(
            matchesEvent(DwdsEventKind.resume, {
              'step': 'Into',
              'elapsedMilliseconds': isNotNull,
            }),
            () => service.resume(isolateId, step: 'Into'),
          );
        });
      });

      group('fullReload', () {
        setUp(() async {
          setCurrentLogWriter(debug: provider.verbose);
        });

        test('emits FULL_RELOAD event', () async {
          final fullReload = context.getRegisteredServiceExtension(
            'fullReload',
          );

          await expectEventDuring(
            matchesEvent(DwdsEventKind.fullReload, {
              'elapsedMilliseconds': isNotNull,
            }),
            () => fakeClient.callServiceExtension(fullReload!),
          );
        });
      });
    },
    // TODO(elliette): Re-enable (https://github.com/dart-lang/webdev/issues/1852).
    skip: Platform.isWindows,
    timeout: const Timeout.factor(2),
  );
}

/// Matches event recursively.
Matcher matchesEvent(String type, Map<String, Object> payload) {
  return isA<DwdsEvent>()
      .having((e) => e.type, 'type', type)
      .having((e) => e.payload.keys, 'payload.keys', payload.keys)
      .having((e) => e.payload.values, 'payload.values', payload.values);
}

/// Pipes the [stream] into a newly created stream.
/// Returns the new stream which is closed on [timeout].
Stream<DwdsEvent> pipe(Stream<DwdsEvent> stream, {Timeout? timeout}) {
  final controller = StreamController<DwdsEvent>();
  final defaultTimeout = const Timeout(Duration(seconds: 20));
  timeout ??= defaultTimeout;
  unawaited(
    stream
        .forEach(controller.add)
        .timeout(defaultTimeout.merge(timeout).duration!)
        .catchError((_) {})
        .then((value) => controller.close()),
  );
  return controller.stream;
}
