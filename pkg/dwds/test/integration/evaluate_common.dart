// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
@Timeout(Duration(minutes: 2))
library;

import 'dart:async';

import 'package:dwds/src/services/expression_evaluator.dart';
import 'package:dwds_test_common/logging.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:dwds_test_common/utilities.dart' show dartSdkIsAtLeast;
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

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

  final testProject = TestProject.test;
  final testPackageProject = TestProject.testPackage(baseMode: indexBaseMode);

  final context = TestContext(testPackageProject, provider);

  Future<void> onBp(
    Stream<Event> stream,
    String isolate,
    ScriptRef script,
    String breakPointId,
    Future<void> Function(Event event) body,
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
      final event = await stream.firstWhere(
        (Event event) => event.kind == EventKind.kPauseBreakpoint,
      );
      await body(event);
    } finally {
      // Remove breakpoint so it doesn't impact other tests or retries.
      if (bp != null) {
        await context.service.removeBreakpoint(isolate, bp.id!);
      }
    }
  }

  group('Shared context with evaluation |', () {
    setUpAll(() async {
      setCurrentLogWriter(debug: provider.verbose);
      await context.setUp(
        testSettings: TestSettings(
          compilationMode: compilationMode,
          moduleFormat: provider.ddcModuleFormat,
          enableExpressionEvaluation: true,
          useDebuggerModuleNames: useDebuggerModuleNames,
          verboseCompiler: provider.verbose,
          canaryFeatures: provider.canaryFeatures,
        ),
      );
    });

    tearDownAll(() async {
      await context.tearDown();
    });

    setUp(() => setCurrentLogWriter(debug: provider.verbose));

    group('evaluateInFrame |', () {
      VM vm;
      late Isolate isolate;
      late String isolateId;
      ScriptList scripts;
      late ScriptRef mainScript;
      late ScriptRef libraryScript;
      late ScriptRef testLibraryScript;
      late ScriptRef testLibraryPartScript;
      late Stream<Event> stream;
      late StreamController<String> output;

      setUp(() async {
        output = StreamController<String>.broadcast();
        output.stream.listen(provider.verbose ? print : printOnFailure);

        configureLogWriter(
          customLogWriter: (level, message, {error, loggerName, stackTrace}) {
            final e = error == null ? '' : ': $error';
            final s = stackTrace == null ? '' : ':\n$stackTrace';
            if (!output.isClosed) {
              output.add('[$level] $loggerName: $message$e$s');
            }
          },
        );

        vm = await context.service.getVM();
        isolate = await context.service.getIsolate(vm.isolates!.first.id!);
        isolateId = isolate.id!;
        scripts = await context.service.getScripts(isolateId);

        await context.service.streamListen('Debug');
        stream = context.service.onEvent('Debug');

        final testPackage = testPackageProject.packageName;
        final test = testProject.packageName;
        mainScript = scripts.scripts!.firstWhere(
          (each) => each.uri!.contains('main.dart'),
        );
        testLibraryScript = scripts.scripts!.firstWhere(
          (each) =>
              each.uri!.contains('package:$testPackage/test_library.dart'),
        );
        testLibraryPartScript = scripts.scripts!.firstWhere(
          (each) =>
              each.uri!.contains('package:$testPackage/src/test_part.dart'),
        );
        libraryScript = scripts.scripts!.firstWhere(
          (each) => each.uri!.contains('package:$test/library.dart'),
        );
      });

      tearDown(() async {
        await output.close();
        try {
          await context.service.resume(isolateId);
        } catch (_) {}
      });

      Future<void> onBreakPoint(
        ScriptRef script,
        String bpId,
        Future<void> Function(Event) body,
      ) => onBp(stream, isolateId, script, bpId, body);

      Future<Response> evaluateInFrame(
        int frame,
        String expr, {
        Map<String, String>? scope,
      }) async => await context.service.evaluateInFrame(
        isolateId,
        frame,
        expr,
        scope: scope,
      );

      Future<InstanceRef> getInstanceRef(
        int frame,
        String expr, {
        Map<String, String>? scope,
      }) async {
        final result = await evaluateInFrame(frame, expr, scope: scope);
        expect(result, isA<InstanceRef>());
        return result as InstanceRef;
      }

      Future<Instance> getInstance(InstanceRef ref) async =>
          await context.service.getObject(isolateId, ref.id!) as Instance;

      test('with scope', () async {
        await onBreakPoint(mainScript, 'printFrame1', (Event event) async {
          final frame = event.topFrame!.index!;

          final scope = {
            'x1': (await getInstanceRef(frame, '"cat"')).id!,
            'x2': (await getInstanceRef(frame, '2')).id!,
            'x3': (await getInstanceRef(frame, 'MainClass(1,0)')).id!,
          };

          final result = await getInstanceRef(
            frame,
            '"\$x1\$x2 (\$x3) \$testLibraryValue (\$local1)"',
            scope: scope,
          );

          expect(result, matchInstanceRef('cat2 (1, 0) 3 (1)'));
        });
      });

      test('with large scope', () async {
        await onBreakPoint(mainScript, 'printLocal', (Event event) async {
          const N = 20;
          final frame = event.topFrame!.index!;

          final scope = {
            for (var i = 0; i < N; i++)
              'x$i': (await getInstanceRef(frame, '$i')).id!,
          };
          final expression = [for (var i = 0; i < N; i++) '\$x$i'].join(' ');
          final expected = [for (var i = 0; i < N; i++) '$i'].join(' ');

          final result = await evaluateInFrame(
            frame,
            '"$expression"',
            scope: scope,
          );
          expect(result, matchInstanceRef(expected));
        });
      });

      test('with large code scope', () async {
        await onBreakPoint(mainScript, 'printLargeScope', (Event event) async {
          const xN = 2;
          const tN = 20;
          final frame = event.topFrame!.index!;

          final scope = {
            for (var i = 0; i < xN; i++)
              'x$i': (await getInstanceRef(frame, '$i')).id!,
          };
          final expression = [
            for (var i = 0; i < xN; i++) '\$x$i',
            for (var i = 0; i < tN; i++) '\$t$i',
          ].join(' ');
          final expected = [
            for (var i = 0; i < xN; i++) '$i',
            for (var i = 0; i < tN; i++) '$i',
          ].join(' ');

          final result = await evaluateInFrame(
            frame,
            '"$expression"',
            scope: scope,
          );
          expect(result, matchInstanceRef(expected));
        });
      });

      test('with scope in caller frame', () async {
        await onBreakPoint(mainScript, 'printFrame1', (Event event) async {
          final frame = event.topFrame!.index! + 1;

          final scope = {
            'x1': (await getInstanceRef(frame, '"cat"')).id!,
            'x2': (await getInstanceRef(frame, '2')).id!,
            'x3': (await getInstanceRef(frame, 'MainClass(1,0)')).id!,
          };

          final result = await getInstanceRef(
            frame,
            '"\$x1\$x2 (\$x3) \$testLibraryValue (\$local2)"',
            scope: scope,
          );

          expect(result, matchInstanceRef('cat2 (1, 0) 3 (2)'));
        });
      });

      test('with scope and this', () async {
        await onBreakPoint(mainScript, 'toStringMainClass', (
          Event event,
        ) async {
          final frame = event.topFrame!.index!;

          final scope = {'x1': (await getInstanceRef(frame, '"cat"')).id!};

          final result = await getInstanceRef(
            frame,
            '"\$x1 \${this._field} \${this.field}"',
            scope: scope,
          );

          expect(result, matchInstanceRef('cat 1 2'));
        });
      });

      test(
        'extension method scope variables can be evaluated',
        () async {
          await onBreakPoint(mainScript, 'extension', (Event event) async {
            final stack = await context.service.getStack(isolateId);
            final scope = _getFrameVariables(stack.frames!.first);
            for (final p in scope.entries) {
              final name = p.key;
              final value = p.value as InstanceRef;
              final result = await getInstanceRef(
                event.topFrame!.index!,
                name!,
              );

              expect(result, matchInstanceRef(value.valueAsString));
            }
          });
        },
        skip: 'https://github.com/dart-lang/webdev/issues/1371',
      );

      test('does not crash if class metadata cannot be found', () async {
        await onBreakPoint(mainScript, 'printStream', (Event event) async {
          final instanceRef = await getInstanceRef(
            event.topFrame!.index!,
            'stream',
          );
          final instance = await getInstance(instanceRef);

          expect(instance, matchInstanceClassName('_AsBroadcastStream<int>'));
        });
      });

      test('local', () async {
        await onBreakPoint(mainScript, 'printLocal', (Event event) async {
          final result = await getInstanceRef(event.topFrame!.index!, 'local');

          expect(result, matchInstanceRef('42'));
        });
      });

      test('Type does not show native JavaScript object fields', () async {
        await onBreakPoint(mainScript, 'printLocal', (Event event) async {
          final instanceRef = await getInstanceRef(
            event.topFrame!.index!,
            'Type',
          );

          // Type
          final instance = await getInstance(instanceRef);
          for (final field in instance.fields!) {
            final name = field.decl!.name;
            final fieldInstance = await getInstance(field.value as InstanceRef);

            expect(
              fieldInstance,
              isA<Instance>().having(
                (i) => i.classRef!.name,
                'Type.$name: classRef.name',
                isNot(isIn(['NativeJavaScriptObject', 'JavaScriptObject'])),
              ),
            );
          }
        });
      });

      test('field', () async {
        await onBreakPoint(mainScript, 'printFieldFromLibraryClass', (
          Event event,
        ) async {
          final result = await getInstanceRef(
            event.topFrame!.index!,
            'instance.field',
          );

          expect(result, matchInstanceRef('1'));
        });
      });

      test('private field from another library', () async {
        await onBreakPoint(mainScript, 'printFieldFromLibraryClass', (
          Event event,
        ) async {
          final result = await evaluateInFrame(
            event.topFrame!.index!,
            'instance._field',
          );

          if (dartSdkIsAtLeast('3.10.0-140.0.dev')) {
            expect(result, matchInstanceRefKind('String'));
            expect(
              result,
              matchInstanceRef(contains("NoSuchMethodError: '_field")),
            );
          } else {
            expect(
              result,
              matchErrorRef(contains("The getter '_field' isn't defined")),
            );
          }
        });
      });

      test('private field from current library', () async {
        await onBreakPoint(mainScript, 'printFieldMain', (Event event) async {
          final result = await getInstanceRef(
            event.topFrame!.index!,
            'instance._field',
          );

          expect(result, matchInstanceRef('1'));
        });
      });

      test('access instance fields after evaluation', () async {
        await onBreakPoint(mainScript, 'printFieldFromLibraryClass', (
          Event event,
        ) async {
          final instanceRef = await getInstanceRef(
            event.topFrame!.index!,
            'instance',
          );

          final instance = await getInstance(instanceRef);
          final field = instance.fields!.firstWhere(
            (BoundField element) => element.decl!.name == 'field',
          );

          expect(field.value, matchInstanceRef('1'));
        });
      });

      test('global', () async {
        await onBreakPoint(mainScript, 'printGlobal', (Event event) async {
          final result = await getInstanceRef(
            event.topFrame!.index!,
            'testLibraryValue',
          );

          expect(result, matchInstanceRef('3'));
        });
      });

      test('call core function', () async {
        await onBreakPoint(mainScript, 'printLocal', (Event event) async {
          final result = await getInstanceRef(
            event.topFrame!.index!,
            'print(local)',
          );

          expect(result, matchInstanceRef('null'));
        });
      });

      test('call library function with const param', () async {
        await onBreakPoint(mainScript, 'printLocal', (Event event) async {
          final result = await getInstanceRef(
            event.topFrame!.index!,
            'testLibraryFunction(42)',
          );

          expect(result, matchInstanceRef('42'));
        });
      });

      test('call library function with local param', () async {
        await onBreakPoint(mainScript, 'printLocal', (Event event) async {
          final result = await getInstanceRef(
            event.topFrame!.index!,
            'testLibraryFunction(local)',
          );

          expect(result, matchInstanceRef('42'));
        });
      });

      test('call library part function with const param', () async {
        await onBreakPoint(mainScript, 'printLocal', (Event event) async {
          final result = await getInstanceRef(
            event.topFrame!.index!,
            'testLibraryPartFunction(42)',
          );

          expect(result, matchInstanceRef('42'));
        });
      });

      test('call library part function with local param', () async {
        await onBreakPoint(mainScript, 'printLocal', (Event event) async {
          final result = await getInstanceRef(
            event.topFrame!.index!,
            'testLibraryPartFunction(local)',
          );

          expect(result, matchInstanceRef('42'));
        });
      });

      test('loop variable', () async {
        await onBreakPoint(mainScript, 'printLoopVariable', (
          Event event,
        ) async {
          final result = await getInstanceRef(event.topFrame!.index!, 'item');

          expect(result, matchInstanceRef('1'));
        });
      });

      test('evaluate expression in _test_package/test_library', () async {
        await onBreakPoint(testLibraryScript, 'testLibraryFunction', (
          Event event,
        ) async {
          final result = await getInstanceRef(event.topFrame!.index!, 'formal');

          expect(result, matchInstanceRef('23'));
        });
      });

      test('evaluate expression in a class constructor in a library', () async {
        await onBreakPoint(testLibraryScript, 'testLibraryClassConstructor', (
          Event event,
        ) async {
          final result = await getInstanceRef(
            event.topFrame!.index!,
            'this.field',
          );

          expect(result, matchInstanceRef('1'));
        });
      });

      test(
        'evaluate expression in a class constructor in a library part',
        () async {
          await onBreakPoint(
            testLibraryPartScript,
            'testLibraryPartClassConstructor',
            (Event event) async {
              final result = await getInstanceRef(
                event.topFrame!.index!,
                'this.field',
              );

              expect(result, matchInstanceRef('1'));
            },
          );
        },
      );

      test('evaluate expression in caller frame', () async {
        await onBreakPoint(testLibraryScript, 'testLibraryFunction', (
          Event event,
        ) async {
          final result = await getInstanceRef(
            event.topFrame!.index! + 1,
            'local',
          );

          expect(result, matchInstanceRef('23'));
        });
      });

      test('evaluate expression in a library', () async {
        await onBreakPoint(libraryScript, 'Concatenate', (Event event) async {
          final result = await getInstanceRef(event.topFrame!.index!, 'a');

          expect(result, matchInstanceRef('Hello'));
        });
      });

      test('compilation error', () async {
        await onBreakPoint(mainScript, 'printLocal', (Event event) async {
          final error = await evaluateInFrame(event.topFrame!.index!, 'typo');

          expect(
            error,
            matchErrorRef(contains(EvaluationErrorKind.compilation)),
          );
        });
      });

      test('async frame error', () async {
        final maxAttempts = 100;

        Response? error;
        String? breakpointId;
        try {
          // Pause in client.js directly to force pausing in async code.
          breakpointId = await _setBreakpointInInjectedClient(
            context.tabConnection.debugger,
          );

          var attempt = 0;
          do {
            try {
              await context.service.resume(isolateId);
            } catch (_) {}

            final event = stream.firstWhere(
              (Event event) => event.kind == EventKind.kPauseInterrupted,
            );
            final frame = (await event).topFrame;
            if (frame != null) {
              error = await context.service.evaluateInFrame(
                isolateId,
                frame.index!,
                'true',
              );
            }
            expect(
              attempt,
              lessThan(maxAttempts),
              reason:
                  'Failed to receive and async frame error in $attempt '
                  'attempts',
            );
            await Future<void>.delayed(const Duration(milliseconds: 10));
            attempt++;
          } while (error is! ErrorRef);
        } finally {
          if (breakpointId != null) {
            await context.tabConnection.debugger.removeBreakpoint(breakpointId);
          }
        }

        // Verify we receive an error when evaluating
        // on async frame.
        expect(error, matchErrorRef(contains(EvaluationErrorKind.asyncFrame)));

        // Verify we don't emit errors or warnings
        // on async frame evaluations.
        output.stream.listen((String event) {
          expect(event, isNot(contains('[WARNING]')));
          expect(event, isNot(contains('[SEVERE]')));
        });
      });

      test('module load error', () async {
        await onBreakPoint(mainScript, 'printLocal', (Event event) async {
          final error = await evaluateInFrame(
            event.topFrame!.index!,
            'd.deferredPrintLocal()',
          );

          expect(
            error,
            matchErrorRef(contains(EvaluationErrorKind.loadModule)),
          );
        });
      }, skip: 'https://github.com/dart-lang/sdk/issues/48587');

      test('cannot evaluate in unsupported isolate', () async {
        await onBreakPoint(mainScript, 'printLocal', (Event event) async {
          await expectLater(
            context.service.evaluateInFrame(
              'bad',
              event.topFrame!.index!,
              'local',
            ),
            throwsSentinelException,
          );
        });
      });
    });

    group('evaluate |', () {
      VM vm;
      late Isolate isolate;
      late String isolateId;

      setUp(() async {
        setCurrentLogWriter(debug: provider.verbose);
        final service = context.service;
        vm = await service.getVM();
        isolate = await service.getIsolate(vm.isolates!.first.id!);
        isolateId = isolate.id!;

        await service.streamListen('Debug');
      });

      tearDown(() async {});

      Future<Response> evaluate(
        String? targetId,
        String expr, {
        Map<String, String>? scope,
      }) async => await context.service.evaluate(
        isolateId,
        targetId!,
        expr,
        scope: scope,
      );

      Future<InstanceRef> getInstanceRef(
        String? targetId,
        String expr, {
        Map<String, String>? scope,
      }) async {
        final result = await evaluate(targetId, expr, scope: scope);
        expect(result, isA<InstanceRef>());
        return result as InstanceRef;
      }

      String getRootLibraryId() {
        expect(isolate.rootLib, isNotNull);
        expect(isolate.rootLib!.id, isNotNull);
        return isolate.rootLib!.id!;
      }

      test(
        'RecordType getters',
        () async {
          final libraryId = getRootLibraryId();

          final type = await getInstanceRef(libraryId, '(0,1).runtimeType');
          final result = await getInstanceRef(type.id, 'hashCode');

          expect(result, matchInstanceRefKind('Double'));
        },
        skip: 'https://github.com/dart-lang/sdk/issues/54609',
      );

      test('Object getters', () async {
        final libraryId = getRootLibraryId();

        final type = await getInstanceRef(libraryId, 'Object()');
        final result = await getInstanceRef(type.id, 'hashCode');

        expect(result, matchInstanceRefKind('Double'));
      });

      test('with scope', () async {
        final libraryId = getRootLibraryId();

        final scope = {
          'x1': (await getInstanceRef(libraryId, '"cat"')).id!,
          'x2': (await getInstanceRef(libraryId, '2')).id!,
          'x3': (await getInstanceRef(libraryId, 'MainClass(1,0)')).id!,
        };

        final result = await getInstanceRef(
          libraryId,
          '"\$x1\$x2 (\$x3) \$testLibraryValue"',
          scope: scope,
        );

        expect(result, matchInstanceRef('cat2 (1, 0) 3'));
      });

      test('with large scope', () async {
        final libraryId = getRootLibraryId();
        const N = 2;

        final scope = {
          for (var i = 0; i < N; i++)
            'x$i': (await getInstanceRef(libraryId, '$i')).id!,
        };
        final expression = [for (var i = 0; i < N; i++) '\$x$i'].join(' ');
        final expected = [for (var i = 0; i < N; i++) '$i'].join(' ');

        final result = await getInstanceRef(
          libraryId,
          '"$expression"',
          scope: scope,
        );
        expect(result, matchInstanceRef(expected));
      });

      test('in parallel (in a batch)', () async {
        final libraryId = getRootLibraryId();

        final evaluation1 = getInstanceRef(
          libraryId,
          'MainClass(1,0).toString()',
        );
        final evaluation2 = getInstanceRef(
          libraryId,
          'MainClass(1,1).toString()',
        );

        final results = await Future.wait([evaluation1, evaluation2]);
        expect(results[0], matchInstanceRef('1, 0'));
        expect(results[1], matchInstanceRef('1, 1'));
      });

      test('in parallel (in a batch) handles errors', () async {
        final libraryId = getRootLibraryId();
        final missingLibId = '';

        final evaluation1 = evaluate(missingLibId, 'MainClass(1,0).toString()');
        final evaluation2 = evaluate(libraryId, 'MainClass(1,1).toString()');

        final results = await Future.wait([evaluation1, evaluation2]);
        expect(
          results[0],
          matchErrorRef(
            contains('Evaluate is called on an unsupported target'),
          ),
        );
        expect(results[1], matchInstanceRef('1, 1'));
      });

      test('with scope override', () async {
        final libraryId = getRootLibraryId();

        final param = await getInstanceRef(libraryId, 'MainClass(1,0)');
        final result = await getInstanceRef(
          libraryId,
          't.toString()',
          scope: {'t': param.id!},
        );

        expect(result, matchInstanceRef('1, 0'));
      });

      test('uses symbol from the same library', () async {
        final libraryId = getRootLibraryId();

        final result = await getInstanceRef(
          libraryId,
          'MainClass(1,0).toString()',
        );

        expect(result, matchInstanceRef('1, 0'));
      });

      test('uses symbol from another library', () async {
        final libraryId = getRootLibraryId();
        final result = await getInstanceRef(
          libraryId,
          'TestLibraryClass(0,1).toString()',
        );

        expect(result, matchInstanceRef('field: 0, _field: 1'));
      });

      test('closure call', () async {
        final libraryId = getRootLibraryId();
        final result = await getInstanceRef(libraryId, '(() => 42)()');

        expect(result, matchInstanceRef('42'));
      });
    });
  }, timeout: const Timeout.factor(2));

  group('shared context with no evaluation |', () {
    setUpAll(() async {
      setCurrentLogWriter(debug: provider.verbose);
      await context.setUp(
        testSettings: TestSettings(
          compilationMode: compilationMode,
          moduleFormat: provider.ddcModuleFormat,
          enableExpressionEvaluation: false,
          verboseCompiler: provider.verbose,
          canaryFeatures: provider.canaryFeatures,
        ),
      );
    });

    tearDownAll(() async {
      await context.tearDown();
    });

    setUp(() => setCurrentLogWriter(debug: provider.verbose));

    group('evaluateInFrame |', () {
      VM vm;
      late Isolate isolate;
      late String isolateId;
      ScriptList scripts;
      late ScriptRef mainScript;
      late Stream<Event> stream;

      setUp(() async {
        final service = context.service;
        vm = await service.getVM();
        isolate = await service.getIsolate(vm.isolates!.first.id!);
        isolateId = isolate.id!;
        scripts = await service.getScripts(isolateId);

        await service.streamListen('Debug');
        stream = service.onEvent('Debug');

        mainScript = scripts.scripts!.firstWhere(
          (each) => each.uri!.contains('main.dart'),
        );
      });

      tearDown(() async {
        await context.service.resume(isolateId);
      });

      test('cannot evaluate expression', () async {
        await onBp(stream, isolateId, mainScript, 'printLocal', (
          Event event,
        ) async {
          await expectLater(
            context.service.evaluateInFrame(
              isolateId,
              event.topFrame!.index!,
              'local',
            ),
            throwsRPCError,
          );
        });
      });
    });
  });
}

Map<String?, InstanceRef?> _getFrameVariables(Frame frame) {
  return <String?, InstanceRef?>{
    for (final variable in frame.vars!)
      variable.name: variable.value as InstanceRef?,
  };
}

Future<String> _setBreakpointInInjectedClient(WipDebugger debugger) async {
  final client = 'dwds/src/injected/client.js';
  final clientScript = debugger.scripts.values.firstWhere(
    (e) => e.url.contains(client),
  );
  final clientSource = await debugger.getScriptSource(clientScript.scriptId);

  final line = clientSource
      .split('\n')
      .indexWhere((element) => element.contains('convertDartClosureToJS'));

  final result = await debugger.sendCommand(
    'Debugger.setBreakpointByUrl',
    params: {
      'urlRegex': '.*$client',
      'lineNumber': line + 4,
      'columnNumber': 0,
    },
  );
  final responseMap = result.json['result'] as Map<String, dynamic>;
  return responseMap['breakpointId'] as String;
}

Matcher matchInstanceRefKind(String kind) =>
    isA<InstanceRef>().having((instance) => instance.kind, 'kind', kind);

Matcher matchInstanceRef(dynamic value) => isA<InstanceRef>().having(
  (instance) => instance.valueAsString,
  'valueAsString',
  value,
);

Matcher matchInstanceClassName(dynamic className) => isA<Instance>().having(
  (instance) => instance.classRef!.name,
  'class name',
  className,
);

Matcher matchInstanceRefClassName(dynamic className) => isA<InstanceRef>()
    .having((instance) => instance.classRef!.name, 'class name', className);

Matcher matchErrorRef(dynamic message) =>
    isA<ErrorRef>().having((instance) => instance.message, 'message', message);
