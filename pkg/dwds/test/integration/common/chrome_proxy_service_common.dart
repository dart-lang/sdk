// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
@Tags(['daily'])
@Timeout(Duration(minutes: 2))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dwds/expression_compiler.dart';
import 'package:dwds/src/services/chrome/chrome_proxy_service.dart';
import 'package:dwds/src/utilities/dart_uri.dart';
import 'package:dwds/src/utilities/shared.dart';
import 'package:dwds_test_common/logging.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service_interface/vm_service_interface.dart';

import '../fixtures/context.dart';
import '../fixtures/project.dart';
import '../fixtures/utilities.dart';

void runTests({
  required TestSdkConfigurationProvider provider,
  required ModuleFormat moduleFormat,
  required CompilationMode compilationMode,
  required bool canaryFeatures,
}) {
  final project = TestProject.test;
  final context = TestContext(project, provider);

  group('shared context', () {
    setUpAll(() async {
      setCurrentLogWriter(debug: provider.verbose);
      await context.setUp(
        testSettings: TestSettings(
          enableExpressionEvaluation: true,
          verboseCompiler: false,
          moduleFormat: provider.ddcModuleFormat,
          canaryFeatures: canaryFeatures,
          compilationMode: compilationMode,
        ),
      );
    });

    tearDownAll(() async {
      await context.tearDown();
    });

    group('breakpoints', () {
      late VmServiceInterface service;
      VM vm;
      late Isolate isolate;

      late ScriptList scripts;
      late ScriptRef mainScript;

      setUp(() async {
        setCurrentLogWriter(debug: provider.verbose);
        service = context.service;
        vm = await service.getVM();
        isolate = await service.getIsolate(vm.isolates!.first.id!);
        scripts = await service.getScripts(isolate.id!);
        mainScript = scripts.scripts!.firstWhere(
          (ScriptRef each) => each.uri!.contains('main.dart'),
        );
      });

      test('addBreakpoint', () async {
        final line = await context.findBreakpointLine(
          'printHelloWorld',
          isolate.id!,
          mainScript,
        );
        final firstBp = await service.addBreakpoint(
          isolate.id!,
          mainScript.id!,
          line,
        );
        expect(firstBp, isNotNull);
        expect(firstBp.id, isNotNull);

        final secondBp = await service.addBreakpoint(
          isolate.id!,
          mainScript.id!,
          line,
        );
        expect(secondBp, isNotNull);
        expect(secondBp.id, isNotNull);

        expect(firstBp.id, equals(secondBp.id));

        // Remove breakpoint so it doesn't impact other tests.
        await service.removeBreakpoint(isolate.id!, firstBp.id!);
      });

      test(
        'addBreakpoint succeeds when sending the same breakpoint twice',
        () async {
          final line = await context.findBreakpointLine(
            'printHelloWorld',
            isolate.id!,
            mainScript,
          );
          final firstBp = service.addBreakpoint(
            isolate.id!,
            mainScript.id!,
            line,
          );
          final secondBp = service.addBreakpoint(
            isolate.id!,
            mainScript.id!,
            line,
          );

          // Remove breakpoint so it doesn't impact other tests.
          await service.removeBreakpoint(isolate.id!, (await firstBp).id!);
          expect((await firstBp).id, equals((await secondBp).id));
        },
      );

      test('addBreakpoint in nonsense location throws', () async {
        expect(
          service.addBreakpoint(isolate.id!, mainScript.id!, 200000),
          throwsA(predicate((dynamic e) => e is RPCError && e.code == 102)),
        );
      });

      test('addBreakpoint on a part file', () async {
        final partScript = scripts.scripts!.firstWhere(
          (script) => script.uri!.contains('part.dart'),
        );
        final bp = await service.addBreakpoint(isolate.id!, partScript.id!, 10);
        // Remove breakpoint so it doesn't impact other tests.
        await service.removeBreakpoint(isolate.id!, bp.id!);
        expect(bp.id, isNotNull);
      });

      test('addBreakpointAtEntry', () async {
        await expectLater(service.addBreakpointAtEntry('', ''), throwsRPCError);
      });

      test('addBreakpointWithScriptUri', () async {
        final line = await context.findBreakpointLine(
          'printHelloWorld',
          isolate.id!,
          mainScript,
        );
        final bp = await service.addBreakpointWithScriptUri(
          isolate.id!,
          mainScript.uri!,
          line,
        );
        // Remove breakpoint so it doesn't impact other tests.
        await service.removeBreakpoint(isolate.id!, bp.id!);
        expect(bp.id, isNotNull);
      });

      test('addBreakpointWithScriptUri absolute file URI', () async {
        final test = context.project.absolutePackageDirectory;
        final scriptPath = Uri.parse(mainScript.uri!).path.substring(1);
        final fullPath = path.join(test, scriptPath);
        final fileUri = Uri.file(fullPath);
        final line = await context.findBreakpointLine(
          'printHelloWorld',
          isolate.id!,
          mainScript,
        );
        final bp = await service.addBreakpointWithScriptUri(
          isolate.id!,
          '$fileUri',
          line,
        );
        // Remove breakpoint so it doesn't impact other tests.
        await service.removeBreakpoint(isolate.id!, bp.id!);
        expect(bp.id, isNotNull);
      });

      test('removeBreakpoint null arguments', () async {
        await expectLater(
          service.removeBreakpoint('', ''),
          throwsSentinelException,
        );
        await expectLater(
          service.removeBreakpoint(isolate.id!, ''),
          throwsRPCError,
        );
      });

      test("removeBreakpoint that doesn't exist fails", () async {
        await expectLater(
          service.removeBreakpoint(isolate.id!, '1234'),
          throwsRPCError,
        );
      });

      test('add and remove breakpoint', () async {
        final line = await context.findBreakpointLine(
          'printHelloWorld',
          isolate.id!,
          mainScript,
        );
        final bp = await service.addBreakpoint(
          isolate.id!,
          mainScript.id!,
          line,
        );
        expect(isolate.breakpoints, [bp]);
        await service.removeBreakpoint(isolate.id!, bp.id!);
        expect(isolate.breakpoints, isEmpty);
      });
    });

    group('callServiceExtension', () {
      late ChromeProxyService service;

      setUp(() {
        setCurrentLogWriter(debug: provider.verbose);
        service = context.service;
      });

      test(
        'success',
        () async {
          final serviceMethod = 'ext.test.callServiceExtension';
          await context.tabConnection.runtime.evaluate(
            'registerExtension("$serviceMethod");',
          );

          // The non-string keys/values get auto json-encoded to match the vm
          // behavior.
          final args = {
            'bool': true,
            'list': [1, '2', 3],
            'map': {'foo': 'bar'},
            'num': 1.0,
            'string': 'hello',
            1: 2,
            false: true,
          };

          final result = await service.callServiceExtension(
            serviceMethod,
            args: args,
          );
          expect(
            result.json,
            args.map(
              (k, v) => MapEntry(
                k is String ? k : jsonEncode(k),
                v is String ? v : jsonEncode(v),
              ),
            ),
          );
        },
        onPlatform: {
          'windows': const Skip(
            'https://github.com/dart-lang/webdev/issues/711',
          ),
        },
      );

      test(
        'failure',
        () async {
          final serviceMethod = 'ext.test.callServiceExtensionWithError';
          await context.tabConnection.runtime.evaluate(
            'registerExtensionWithError("$serviceMethod");',
          );

          final errorDetails = {'intentional': 'error'};
          expect(
            service.callServiceExtension(
              serviceMethod,
              args: {'code': '-32001', 'details': jsonEncode(errorDetails)},
            ),
            throwsA(
              predicate(
                (dynamic error) =>
                    error is RPCError &&
                    error.code == -32001 &&
                    error.details == jsonEncode(errorDetails),
              ),
            ),
          );
        },
        onPlatform: {
          'windows': const Skip(
            'https://github.com/dart-lang/webdev/issues/711',
          ),
        },
      );

      test('not found', () async {
        final serviceMethod = 'ext.test.missingServiceExtension';
        expect(
          service.callServiceExtension(serviceMethod),
          throwsA(
            predicate(
              (dynamic error) =>
                  error is RPCError &&
                  error.code == RPCErrorKind.kMethodNotFound.code,
            ),
          ),
        );
      });
    });

    group('VMTimeline', () {
      late VmServiceInterface service;

      setUp(() {
        setCurrentLogWriter(debug: provider.verbose);
        service = context.service;
      });

      test('clearVMTimeline', () async {
        await expectLater(service.clearVMTimeline(), throwsRPCError);
      });

      test('getVMTimelineMicros', () async {
        await expectLater(service.getVMTimelineMicros(), throwsRPCError);
      });

      test('getVMTimeline', () async {
        await expectLater(service.getVMTimeline(), throwsRPCError);
      });

      test('getVMTimelineFlags', () async {
        await expectLater(service.getVMTimelineFlags(), throwsRPCError);
      });

      test('setVMTimelineFlags', () async {
        await expectLater(
          service.setVMTimelineFlags(<String>[]),
          throwsRPCError,
        );
      });
    });

    test('getMemoryUsage', () async {
      final service = context.service;
      final vm = await service.getVM();
      final isolate = await service.getIsolate(vm.isolates!.first.id!);

      final memoryUsage = await service.getMemoryUsage(isolate.id!);

      expect(memoryUsage.heapUsage, isNotNull);
      expect(memoryUsage.heapUsage, greaterThan(0));
      expect(memoryUsage.heapCapacity, greaterThan(0));
      expect(memoryUsage.externalUsage, equals(0));
    });

    group('evaluate', () {
      late VmServiceInterface service;
      late Isolate isolate;
      LibraryRef? bootstrap;

      setUpAll(() async {
        setCurrentLogWriter(debug: provider.verbose);
        service = context.service;
        final vm = await service.getVM();
        isolate = await service.getIsolate(vm.isolates!.first.id!);
        bootstrap = isolate.rootLib;
      });

      group('top level methods', () {
        setUp(() {
          setCurrentLogWriter(debug: provider.verbose);
        });

        test('can return strings', () async {
          expect(
            await service.evaluate(
              isolate.id!,
              bootstrap!.id!,
              "helloString('world')",
            ),
            const TypeMatcher<InstanceRef>().having(
              (instance) => instance.valueAsString,
              'value',
              'world',
            ),
          );
        });

        test('can return bools', () async {
          expect(
            await service.evaluate(
              isolate.id!,
              bootstrap!.id!,
              'helloBool(true)',
            ),
            const TypeMatcher<InstanceRef>().having(
              (instance) => instance.valueAsString,
              'valueAsString',
              'true',
            ),
          );
          expect(
            await service.evaluate(
              isolate.id!,
              bootstrap!.id!,
              'helloBool(false)',
            ),
            const TypeMatcher<InstanceRef>().having(
              (instance) => instance.valueAsString,
              'valueAsString',
              'false',
            ),
          );
        });

        test('can return nums', () async {
          expect(
            await service.evaluate(
              isolate.id!,
              bootstrap!.id!,
              'helloNum(42.0)',
            ),
            const TypeMatcher<InstanceRef>().having(
              (instance) => instance.valueAsString,
              'valueAsString',
              '42',
            ),
          );
          expect(
            await service.evaluate(
              isolate.id!,
              bootstrap!.id!,
              'helloNum(42.2)',
            ),
            const TypeMatcher<InstanceRef>().having(
              (instance) => instance.valueAsString,
              'valueAsString',
              '42.2',
            ),
          );
        });

        test('can return objects with ids', () async {
          final object = await service.evaluate(
            isolate.id!,
            bootstrap!.id!,
            'createObject("cool")',
          );
          expect(
            object,
            const TypeMatcher<InstanceRef>().having(
              (instance) => instance.id,
              'id',
              isNotNull,
            ),
          );
          // TODO(jakemac): Add tests for the ClassRef once we create one,
          // https://github.com/dart-lang/sdk/issues/36771.
        });

        group('with provided scope', () {
          setUp(() {
            setCurrentLogWriter(debug: provider.verbose);
          });

          Future<InstanceRef> createRemoteObject(String message) async {
            return await service.evaluate(
                  isolate.id!,
                  bootstrap!.id!,
                  'createObject("$message")',
                )
                as InstanceRef;
          }

          test('single scope object', () async {
            final instance = await createRemoteObject('A');
            final result = await service.evaluate(
              isolate.id!,
              bootstrap!.id!,
              'messageFor(arg1)',
              scope: {'arg1': instance.id!},
            );
            expect(
              result,
              const TypeMatcher<InstanceRef>().having(
                (instance) => instance.valueAsString,
                'valueAsString',
                'A',
              ),
            );
          });

          test('multiple scope objects', () async {
            final instance1 = await createRemoteObject('A');
            final instance2 = await createRemoteObject('B');
            final result = await service.evaluate(
              isolate.id!,
              bootstrap!.id!,
              'messagesCombined(arg1, arg2)',
              scope: {'arg1': instance1.id!, 'arg2': instance2.id!},
            );
            expect(
              result,
              const TypeMatcher<InstanceRef>().having(
                (instance) => instance.valueAsString,
                'valueAsString',
                'AB',
              ),
            );
          });
        });
      });
    });

    test('evaluateInFrame', () async {
      final service = context.service;
      await expectLater(
        service.evaluateInFrame('', 0, ''),
        throwsSentinelException,
      );
    });

    test('getAllocationProfile', () async {
      final service = context.service;
      await expectLater(service.getAllocationProfile(''), throwsRPCError);
    });

    test('getClassList', () async {
      final service = context.service;
      await expectLater(service.getClassList(''), throwsRPCError);
    });

    test('getFlagList', () async {
      final service = context.service;
      expect(await service.getFlagList(), isA<FlagList>());
    });

    test('getInstances', () async {
      final service = context.service;
      await expectLater(service.getInstances('', '', 0), throwsRPCError);
    });

    group('getIsolate', () {
      late VmServiceInterface service;
      setUp(() {
        setCurrentLogWriter(debug: provider.verbose);
        service = context.service;
      });

      test('works for existing isolates', () async {
        final vm = await service.getVM();
        final result = await service.getIsolate(vm.isolates!.first.id!);
        expect(result, const TypeMatcher<Isolate>());
        final isolate = result;
        expect(isolate.name, contains('main'));
        // TODO: library names change with kernel dart-lang/sdk#36736
        expect(isolate.rootLib!.uri, endsWith('.dart'));

        expect(
          isolate.libraries,
          containsAll([
            _libRef('package:path/path.dart'),
            // TODO: library names change with kernel dart-lang/sdk#36736
            _libRef(endsWith('main.dart')),
          ]),
        );
        expect(isolate.extensionRPCs, contains('ext.hello_world.existing'));
      });

      test('throws for invalid ids', () async {
        expect(service.getIsolate('bad'), throwsSentinelException);
      });
    });

    group('getObject', () {
      late ChromeProxyService service;
      late Isolate isolate;
      LibraryRef? bootstrap;

      Library? rootLibrary;

      setUpAll(() async {
        setCurrentLogWriter(debug: provider.verbose);
        service = context.service;
        final vm = await service.getVM();
        isolate = await service.getIsolate(vm.isolates!.first.id!);
        bootstrap = isolate.rootLib;
        rootLibrary =
            await service.getObject(isolate.id!, bootstrap!.id!) as Library;
      });

      setUp(() {
        setCurrentLogWriter(debug: provider.verbose);
      });

      test('root Library', () async {
        expect(rootLibrary, isNotNull);
        // TODO: library names change with kernel dart-lang/sdk#36736
        expect(rootLibrary!.uri, endsWith('main.dart'));
        expect(rootLibrary!.classes, hasLength(1));
        final testClass = rootLibrary!.classes!.first;
        expect(testClass.name, 'MyTestClass');
      });

      test('Library only contains included scripts', () async {
        final library =
            await service.getObject(isolate.id!, rootLibrary!.id!) as Library;
        expect(library.scripts, hasLength(2));
        expect(
          library.scripts,
          unorderedEquals([
            predicate(
              (ScriptRef s) =>
                  s.uri == 'org-dartlang-app:///example/hello_world/main.dart',
            ),
            predicate(
              (ScriptRef s) =>
                  s.uri == 'org-dartlang-app:///example/hello_world/part.dart',
            ),
          ]),
        );
      });

      test('Can get the same library in parallel', () async {
        final futures = [
          service.getObject(isolate.id!, rootLibrary!.id!),
          service.getObject(isolate.id!, rootLibrary!.id!),
        ];
        final results = await Future.wait(futures);
        final library1 = results[0] as Library;
        final library2 = results[1] as Library;
        expect(library1, equals(library2));
      });

      test('Classes', () async {
        final testClass =
            await service.getObject(
                  isolate.id!,
                  rootLibrary!.classes!.first.id!,
                )
                as Class;
        expect(
          testClass.functions,
          unorderedEquals([
            predicate((FuncRef f) => f.name == 'staticHello' && f.isStatic!),
            predicate((FuncRef f) => f.name == 'hello' && !f.isStatic!),
            predicate((FuncRef f) => f.name == 'hashCode' && !f.isStatic!),
            predicate((FuncRef f) => f.name == 'runtimeType' && !f.isStatic!),
          ]),
        );
        expect(
          testClass.fields,
          unorderedEquals([
            predicate(
              (FieldRef f) =>
                  f.name == 'message' &&
                  f.declaredType != null &&
                  !f.isStatic! &&
                  !f.isConst! &&
                  f.isFinal!,
            ),
            predicate(
              (FieldRef f) =>
                  f.name == 'notFinal' &&
                  f.declaredType != null &&
                  !f.isStatic! &&
                  !f.isConst! &&
                  !f.isFinal!,
            ),
            predicate(
              (FieldRef f) =>
                  f.name == 'staticMessage' &&
                  f.declaredType != null &&
                  f.isStatic! &&
                  !f.isConst! &&
                  !f.isFinal!,
            ),
          ]),
        );
      });

      test('Runtime classes', () async {
        final testClass =
            await service.getObject(isolate.id!, 'classes|dart:_runtime|_Type')
                as Class;
        expect(testClass.name, '_Type');
      });

      test('String', () async {
        final worldRef =
            await service.evaluate(
                  isolate.id!,
                  bootstrap!.id!,
                  "helloString('world')",
                )
                as InstanceRef;
        final world =
            await service.getObject(isolate.id!, worldRef.id!) as Instance;
        expect(world.valueAsString, 'world');
      });

      test('Large strings not truncated', () async {
        final largeString =
            await service.evaluate(
                  isolate.id!,
                  bootstrap!.id!,
                  "helloString('${'abcde' * 250}')",
                )
                as InstanceRef;
        expect(largeString.valueAsStringIsTruncated, isNot(isTrue));
        expect(largeString.valueAsString!.length, largeString.length);
        expect(largeString.length, 5 * 250);
      });

      test('Lists', () async {
        final list =
            await service.evaluate(isolate.id!, bootstrap!.id!, 'topLevelList')
                as InstanceRef;
        final inst = await service.getObject(isolate.id!, list.id!) as Instance;
        expect(inst.length, 1001);
        expect(inst.offset, null);
        expect(inst.count, null);
        expect(inst.elements!.length, 1001);
        final fifth = inst.elements![4] as InstanceRef;
        expect(fifth.valueAsString, '100');
        final sixth = inst.elements![5] as InstanceRef;
        expect(sixth.valueAsString, '5');
      });

      test('Maps', () async {
        final map =
            await service.evaluate(isolate.id!, bootstrap!.id!, 'topLevelMap')
                as InstanceRef;
        final inst = await service.getObject(isolate.id!, map.id!) as Instance;
        expect(inst.length, 1001);
        expect(inst.offset, null);
        expect(inst.count, null);
        expect(inst.associations!.length, 1001);
        final fifth = inst.associations![4];
        expect((fifth.key as InstanceRef).valueAsString, '4');
        expect((fifth.value as InstanceRef).valueAsString, '996');
        final sixth = inst.associations![5];
        expect((sixth.key as InstanceRef).valueAsString, '5');
        expect((sixth.value as InstanceRef).valueAsString, '995');
      });

      test('bool', () async {
        final ref =
            await service.evaluate(
                  isolate.id!,
                  bootstrap!.id!,
                  'helloBool(true)',
                )
                as InstanceRef;
        final obj = await service.getObject(isolate.id!, ref.id!) as Instance;
        expect(obj.kind, InstanceKind.kBool);
        expect(obj.classRef!.name, 'Bool');
        expect(obj.valueAsString, 'true');
      });

      test('num', () async {
        final ref =
            await service.evaluate(isolate.id!, bootstrap!.id!, 'helloNum(42)')
                as InstanceRef;
        final obj = await service.getObject(isolate.id!, ref.id!) as Instance;
        expect(obj.kind, InstanceKind.kDouble);
        expect(obj.classRef!.name, 'Double');
        expect(obj.valueAsString, '42');
      });

      test('Scripts', () async {
        final scripts = await service.getScripts(isolate.id!);
        assert(scripts.scripts!.isNotEmpty);
        for (final scriptRef in scripts.scripts!) {
          final script =
              await service.getObject(isolate.id!, scriptRef.id!) as Script;
          final serverPath = DartUri(script.uri!, '').serverPath;
          final result = await http.get(
            Uri.parse('http://localhost:${context.port}/$serverPath'),
          );
          expect(script.source, utf8.decode(result.bodyBytes));
          expect(scriptRef.uri, endsWith('.dart'));
          expect(script.tokenPosTable, isNotEmpty);
        }
      });

      group('getObject called with offset/count parameters', () {
        test('Lists with null offset and count are not truncated', () async {
          final list =
              await service.evaluate(
                    isolate.id!,
                    bootstrap!.id!,
                    'topLevelList',
                  )
                  as InstanceRef;
          final inst =
              await service.getObject(
                    isolate.id!,
                    list.id!,
                    count: null,
                    offset: null,
                  )
                  as Instance;
          expect(inst.length, 1001);
          expect(inst.offset, null);
          expect(inst.count, null);
          expect(inst.elements!.length, 1001);
          final fifth = inst.elements![4] as InstanceRef;
          expect(fifth.valueAsString, '100');
          final sixth = inst.elements![5] as InstanceRef;
          expect(sixth.valueAsString, '5');
        });

        test('Lists with null count are not truncated', () async {
          final list =
              await service.evaluate(
                    isolate.id!,
                    bootstrap!.id!,
                    'topLevelList',
                  )
                  as InstanceRef;
          final inst =
              await service.getObject(
                    isolate.id!,
                    list.id!,
                    count: null,
                    offset: 0,
                  )
                  as Instance;
          expect(inst.length, 1001);
          expect(inst.offset, 0);
          expect(inst.count, null);
          expect(inst.elements!.length, 1001);
          final fifth = inst.elements![4] as InstanceRef;
          expect(fifth.valueAsString, '100');
          final sixth = inst.elements![5] as InstanceRef;
          expect(sixth.valueAsString, '5');
        });

        test('Lists with null count and offset greater than 0 are '
            'truncated from offset to end of list', () async {
          final list =
              await service.evaluate(
                    isolate.id!,
                    bootstrap!.id!,
                    'topLevelList',
                  )
                  as InstanceRef;
          final inst =
              await service.getObject(
                    isolate.id!,
                    list.id!,
                    count: null,
                    offset: 1000,
                  )
                  as Instance;
          expect(inst.length, 1001);
          expect(inst.offset, 1000);
          expect(inst.count, null);
          expect(inst.elements!.length, 1);
          final only = inst.elements![0] as InstanceRef;
          expect(only.valueAsString, '5');
        });

        test('Lists with offset/count are truncated', () async {
          final list =
              await service.evaluate(
                    isolate.id!,
                    bootstrap!.id!,
                    'topLevelList',
                  )
                  as InstanceRef;
          final inst =
              await service.getObject(
                    isolate.id!,
                    list.id!,
                    count: 7,
                    offset: 4,
                  )
                  as Instance;
          expect(inst.length, 1001);
          expect(inst.offset, 4);
          expect(inst.count, 7);
          expect(inst.elements!.length, 7);
          final fifth = inst.elements![0] as InstanceRef;
          expect(fifth.valueAsString, '100');
          final sixth = inst.elements![1] as InstanceRef;
          expect(sixth.valueAsString, '5');
        });

        test(
          'Lists are truncated to the end if offset/count runs off the end',
          () async {
            final list =
                await service.evaluate(
                      isolate.id!,
                      bootstrap!.id!,
                      'topLevelList',
                    )
                    as InstanceRef;
            final inst =
                await service.getObject(
                      isolate.id!,
                      list.id!,
                      count: 5,
                      offset: 1000,
                    )
                    as Instance;
            expect(inst.length, 1001);
            expect(inst.offset, 1000);
            expect(inst.count, 1);
            expect(inst.elements!.length, 1);
            final only = inst.elements![0] as InstanceRef;
            expect(only.valueAsString, '5');
          },
        );

        test(
          'Lists are truncated to empty if offset runs off the end',
          () async {
            final list =
                await service.evaluate(
                      isolate.id!,
                      bootstrap!.id!,
                      'topLevelList',
                    )
                    as InstanceRef;
            final inst =
                await service.getObject(
                      isolate.id!,
                      list.id!,
                      count: 5,
                      offset: 1002,
                    )
                    as Instance;
            expect(inst.elements!.length, 0);
            expect(inst.length, 1001);
            expect(inst.offset, 1002);
            expect(inst.count, 0);
            expect(inst.elements!.length, 0);
          },
        );

        test(
          'Lists are truncated to empty with 0 count and null offset',
          () async {
            final list =
                await service.evaluate(
                      isolate.id!,
                      bootstrap!.id!,
                      'topLevelList',
                    )
                    as InstanceRef;
            final inst =
                await service.getObject(
                      isolate.id!,
                      list.id!,
                      count: 0,
                      offset: null,
                    )
                    as Instance;
            expect(inst.elements!.length, 0);
            expect(inst.length, 1001);
            expect(inst.offset, null);
            expect(inst.count, 0);
            expect(inst.elements!.length, 0);
          },
        );

        test('Maps with null offset/count are not truncated', () async {
          final map =
              await service.evaluate(isolate.id!, bootstrap!.id!, 'topLevelMap')
                  as InstanceRef;
          final inst =
              await service.getObject(
                    isolate.id!,
                    map.id!,
                    count: null,
                    offset: null,
                  )
                  as Instance;
          expect(inst.length, 1001);
          expect(inst.offset, null);
          expect(inst.count, null);
          expect(inst.associations!.length, 1001);
          final fifth = inst.associations![4];
          expect((fifth.key as InstanceRef).valueAsString, '4');
          expect((fifth.value as InstanceRef).valueAsString, '996');
          final sixth = inst.associations![5];
          expect((sixth.key as InstanceRef).valueAsString, '5');
          expect((sixth.value as InstanceRef).valueAsString, '995');
        });

        test('Maps with null count and offset greater than 0 are '
            'truncated from offset to end of map', () async {
          final map =
              await service.evaluate(isolate.id!, bootstrap!.id!, 'topLevelMap')
                  as InstanceRef;
          final inst =
              await service.getObject(
                    isolate.id!,
                    map.id!,
                    count: null,
                    offset: 1000,
                  )
                  as Instance;
          expect(inst.length, 1001);
          expect(inst.offset, 1000);
          expect(inst.count, null);
          expect(inst.associations!.length, 1);
          final only = inst.associations![0];
          expect((only.key as InstanceRef).valueAsString, '1000');
          expect((only.value as InstanceRef).valueAsString, '0');
        });

        test('Maps with null count are not truncated', () async {
          final map =
              await service.evaluate(isolate.id!, bootstrap!.id!, 'topLevelMap')
                  as InstanceRef;
          final inst =
              await service.getObject(
                    isolate.id!,
                    map.id!,
                    count: null,
                    offset: 0,
                  )
                  as Instance;
          expect(inst.length, 1001);
          expect(inst.offset, 0);
          expect(inst.count, null);
          expect(inst.associations!.length, 1001);
          final fifth = inst.associations![4];
          expect((fifth.key as InstanceRef).valueAsString, '4');
          expect((fifth.value as InstanceRef).valueAsString, '996');
          final sixth = inst.associations![5];
          expect((sixth.key as InstanceRef).valueAsString, '5');
          expect((sixth.value as InstanceRef).valueAsString, '995');
        });

        test('Maps with offset/count are truncated', () async {
          final map =
              await service.evaluate(isolate.id!, bootstrap!.id!, 'topLevelMap')
                  as InstanceRef;
          final inst =
              await service.getObject(isolate.id!, map.id!, count: 7, offset: 4)
                  as Instance;
          expect(inst.length, 1001);
          expect(inst.offset, 4);
          expect(inst.count, 7);
          expect(inst.associations!.length, 7);
          final fifth = inst.associations![0];
          expect((fifth.key as InstanceRef).valueAsString, '4');
          expect((fifth.value as InstanceRef).valueAsString, '996');
          final sixth = inst.associations![1];
          expect((sixth.key as InstanceRef).valueAsString, '5');
          expect((sixth.value as InstanceRef).valueAsString, '995');
        });

        test(
          'Maps are truncated to the end if offset/count runs off the end',
          () async {
            final map =
                await service.evaluate(
                      isolate.id!,
                      bootstrap!.id!,
                      'topLevelMap',
                    )
                    as InstanceRef;
            final inst =
                await service.getObject(
                      isolate.id!,
                      map.id!,
                      count: 5,
                      offset: 1000,
                    )
                    as Instance;
            expect(inst.length, 1001);
            expect(inst.offset, 1000);
            expect(inst.count, 1);
            expect(inst.associations!.length, 1);
            final only = inst.associations![0];
            expect((only.key as InstanceRef).valueAsString, '1000');
            expect((only.value as InstanceRef).valueAsString, '0');
          },
        );

        test(
          'Maps are truncated to empty if offset runs off the end',
          () async {
            final map =
                await service.evaluate(
                      isolate.id!,
                      bootstrap!.id!,
                      'topLevelMap',
                    )
                    as InstanceRef;
            final inst =
                await service.getObject(
                      isolate.id!,
                      map.id!,
                      count: 5,
                      offset: 1002,
                    )
                    as Instance;
            expect(inst.associations!.length, 0);
            expect(inst.length, 1001);
            expect(inst.offset, 1002);
            expect(inst.count, 0);
            expect(inst.associations!.length, 0);
          },
        );

        test('Strings with offset/count are truncated', () async {
          final worldRef =
              await service.evaluate(
                    isolate.id!,
                    bootstrap!.id!,
                    "helloString('world')",
                  )
                  as InstanceRef;
          final world =
              await service.getObject(
                    isolate.id!,
                    worldRef.id!,
                    count: 2,
                    offset: 1,
                  )
                  as Instance;
          expect(world.valueAsString, 'or');
          expect(world.count, 2);
          expect(world.length, 5);
          expect(world.offset, 1);
        });

        test(
          'Maps are truncated to empty if offset runs off the end',
          () async {
            final map =
                await service.evaluate(
                      isolate.id!,
                      bootstrap!.id!,
                      'topLevelMap',
                    )
                    as InstanceRef;
            final inst =
                await service.getObject(
                      isolate.id!,
                      map.id!,
                      count: 5,
                      offset: 1002,
                    )
                    as Instance;
            expect(inst.associations!.length, 0);
            expect(inst.length, 1001);
            expect(inst.offset, 1002);
            expect(inst.count, 0);
            expect(inst.associations!.length, 0);
          },
        );

        test(
          'Maps are truncated to empty with 0 count and null offset',
          () async {
            final map =
                await service.evaluate(
                      isolate.id!,
                      bootstrap!.id!,
                      'topLevelMap',
                    )
                    as InstanceRef;
            final inst =
                await service.getObject(
                      isolate.id!,
                      map.id!,
                      count: 0,
                      offset: null,
                    )
                    as Instance;
            expect(inst.associations!.length, 0);
            expect(inst.length, 1001);
            expect(inst.offset, null);
            expect(inst.count, 0);
            expect(inst.associations!.length, 0);
          },
        );

        test(
          'Strings are truncated to the end if offset/count runs off the end',
          () async {
            final worldRef =
                await service.evaluate(
                      isolate.id!,
                      bootstrap!.id!,
                      "helloString('world')",
                    )
                    as InstanceRef;
            final world =
                await service.getObject(
                      isolate.id!,
                      worldRef.id!,
                      count: 5,
                      offset: 3,
                    )
                    as Instance;
            expect(world.valueAsString, 'ld');
            expect(world.count, 2);
            expect(world.length, 5);
            expect(world.offset, 3);
          },
        );

        test(
          'offset/count parameters greater than zero are ignored for Classes',
          () async {
            final testClass =
                await service.getObject(
                      isolate.id!,
                      rootLibrary!.classes!.first.id!,
                      offset: 100,
                      count: 100,
                    )
                    as Class;
            expect(
              testClass.functions,
              unorderedEquals([
                predicate(
                  (FuncRef f) => f.name == 'staticHello' && f.isStatic!,
                ),
                predicate((FuncRef f) => f.name == 'hello' && !f.isStatic!),
                predicate((FuncRef f) => f.name == 'hashCode' && !f.isStatic!),
                predicate(
                  (FuncRef f) => f.name == 'runtimeType' && !f.isStatic!,
                ),
              ]),
            );
            expect(
              testClass.fields,
              unorderedEquals([
                predicate(
                  (FieldRef f) =>
                      f.name == 'message' &&
                      f.declaredType != null &&
                      !f.isStatic! &&
                      !f.isConst! &&
                      f.isFinal!,
                ),
                predicate(
                  (FieldRef f) =>
                      f.name == 'notFinal' &&
                      f.declaredType != null &&
                      !f.isStatic! &&
                      !f.isConst! &&
                      !f.isFinal!,
                ),
                predicate(
                  (FieldRef f) =>
                      f.name == 'staticMessage' &&
                      f.declaredType != null &&
                      f.isStatic! &&
                      !f.isConst! &&
                      !f.isFinal!,
                ),
              ]),
            );
          },
        );

        test(
          'offset/count parameters equal to zero are ignored for Classes',
          () async {
            final testClass =
                await service.getObject(
                      isolate.id!,
                      rootLibrary!.classes!.first.id!,
                      offset: 0,
                      count: 0,
                    )
                    as Class;
            expect(
              testClass.functions,
              unorderedEquals([
                predicate(
                  (FuncRef f) => f.name == 'staticHello' && f.isStatic!,
                ),
                predicate((FuncRef f) => f.name == 'hello' && !f.isStatic!),
                predicate((FuncRef f) => f.name == 'hashCode' && !f.isStatic!),
                predicate(
                  (FuncRef f) => f.name == 'runtimeType' && !f.isStatic!,
                ),
              ]),
            );
            expect(
              testClass.fields,
              unorderedEquals([
                predicate(
                  (FieldRef f) =>
                      f.name == 'message' &&
                      f.declaredType != null &&
                      !f.isStatic! &&
                      !f.isConst! &&
                      f.isFinal!,
                ),
                predicate(
                  (FieldRef f) =>
                      f.name == 'notFinal' &&
                      f.declaredType != null &&
                      !f.isStatic! &&
                      !f.isConst! &&
                      !f.isFinal!,
                ),
                predicate(
                  (FieldRef f) =>
                      f.name == 'staticMessage' &&
                      f.declaredType != null &&
                      f.isStatic! &&
                      !f.isConst! &&
                      !f.isFinal!,
                ),
              ]),
            );
          },
        );

        test('offset/count parameters are ignored for bools', () async {
          final ref =
              await service.evaluate(
                    isolate.id!,
                    bootstrap!.id!,
                    'helloBool(true)',
                  )
                  as InstanceRef;
          final obj =
              await service.getObject(
                    isolate.id!,
                    ref.id!,
                    offset: 100,
                    count: 100,
                  )
                  as Instance;
          expect(obj.kind, InstanceKind.kBool);
          expect(obj.classRef!.name, 'Bool');
          expect(obj.valueAsString, 'true');
        });

        test('offset/count parameters are ignored for nums', () async {
          final ref =
              await service.evaluate(
                    isolate.id!,
                    bootstrap!.id!,
                    'helloNum(42)',
                  )
                  as InstanceRef;
          final obj =
              await service.getObject(
                    isolate.id!,
                    ref.id!,
                    offset: 100,
                    count: 100,
                  )
                  as Instance;
          expect(obj.kind, InstanceKind.kDouble);
          expect(obj.classRef!.name, 'Double');
          expect(obj.valueAsString, '42');
        });

        test('offset/count parameters are ignored for null', () async {
          final ref =
              await service.evaluate(
                    isolate.id!,
                    bootstrap!.id!,
                    'helloNum(null)',
                  )
                  as InstanceRef;
          final obj =
              await service.getObject(
                    isolate.id!,
                    ref.id!,
                    offset: 100,
                    count: 100,
                  )
                  as Instance;
          expect(obj.kind, InstanceKind.kNull);
          expect(obj.classRef!.name, 'Null');
          expect(obj.valueAsString, 'null');
        });
      });
    });

    test('getScripts', () async {
      final service = context.service;
      final vm = await service.getVM();
      final isolateId = vm.isolates!.first.id!;
      final scripts = await service.getScripts(isolateId);
      expect(scripts, isNotNull);
      expect(scripts.scripts, isNotEmpty);

      final scriptUris = scripts.scripts!.map((s) => s.uri);

      // Contains main script only once.
      expect(
        scriptUris.where((uri) => uri!.contains('hello_world/main.dart')),
        hasLength(1),
      );

      // Contains a known script.
      expect(scriptUris, contains('package:path/path.dart'));

      // Contains part files as well.
      expect(scriptUris, contains(endsWith('part.dart')));
      expect(
        scriptUris,
        contains('package:intl/src/date_format_internal.dart'),
      );
    });

    group('getSourceReport', () {
      late VmServiceInterface service;

      setUp(() {
        setCurrentLogWriter(debug: provider.verbose);
        service = context.service;
      });

      test('Coverage report', () async {
        final vm = await service.getVM();
        final isolateId = vm.isolates!.first.id!;

        await expectLater(
          service.getSourceReport(isolateId, ['Coverage']),
          throwsRPCError,
        );
      });

      test('Coverage report', () async {
        final vm = await service.getVM();
        final isolateId = vm.isolates!.first.id!;

        await expectLater(
          service.getSourceReport(
            isolateId,
            ['Coverage'],
            libraryFilters: ['foo'],
          ),
          throwsRPCError,
        );
      });

      test('report type not understood', () async {
        final vm = await service.getVM();
        final isolateId = vm.isolates!.first.id!;

        await expectLater(
          service.getSourceReport(isolateId, ['FooBar']),
          throwsRPCError,
        );
      });

      test('PossibleBreakpoints report', () async {
        final vm = await service.getVM();
        final isolateId = vm.isolates!.first.id!;
        final scripts = await service.getScripts(isolateId);
        final mainScript = scripts.scripts!.firstWhere(
          (script) => script.uri!.contains('main.dart'),
        );

        final sourceReport = await service.getSourceReport(isolateId, [
          'PossibleBreakpoints',
        ], scriptId: mainScript.id);

        expect(sourceReport.scripts, isNotEmpty);
        expect(sourceReport.ranges, isNotEmpty);

        final sourceReportRange = sourceReport.ranges!.first;
        expect(sourceReportRange.possibleBreakpoints, isNotEmpty);
      });
    });

    group('Pausing', () {
      late VmServiceInterface service;
      String? isolateId;
      late Stream<Event> stream;
      ScriptList scripts;
      late ScriptRef mainScript;

      setUp(() async {
        setCurrentLogWriter(debug: provider.verbose);
        service = context.service;
        final vm = await service.getVM();
        isolateId = vm.isolates!.first.id;
        scripts = await service.getScripts(isolateId!);
        await service.streamListen('Debug');
        stream = service.onEvent('Debug');
        mainScript = scripts.scripts!.firstWhere(
          (script) => script.uri!.contains('main.dart'),
        );
      });

      test('at breakpoints sets pauseBreakPoints', () async {
        final line = await context.findBreakpointLine(
          'callPrintCount',
          isolateId!,
          mainScript,
        );
        final bp = await service.addBreakpoint(
          isolateId!,
          mainScript.id!,
          line,
        );
        final event = await stream.firstWhere(
          (event) => event.kind == EventKind.kPauseBreakpoint,
        );
        final pauseBreakpoints = event.pauseBreakpoints!;
        expect(pauseBreakpoints, hasLength(1));
        expect(pauseBreakpoints.first.id, bp.id);
        await service.removeBreakpoint(isolateId!, bp.id!);
        // Resume execution to not impact other tests.
        await service.resume(isolateId!);
      });

      test(
        'resuming throws kIsolateMustBePaused error if not paused',
        () async {
          await expectLater(
            service.resume(isolateId!),
            throwsRPCErrorWithCode(RPCErrorKind.kIsolateMustBePaused.code),
          );
        },
      );
    });

    group('Step', () {
      late VmServiceInterface service;
      String? isolateId;
      late Stream<Event> stream;
      ScriptList scripts;
      ScriptRef mainScript;

      setUp(() async {
        setCurrentLogWriter(debug: provider.verbose);
        service = context.service;
        final vm = await service.getVM();
        isolateId = vm.isolates!.first.id;
        scripts = await service.getScripts(isolateId!);
        await service.streamListen('Debug');
        stream = service.onEvent('Debug');
        mainScript = scripts.scripts!.firstWhere(
          (script) => script.uri!.contains('main.dart'),
        );
        final line = await context.findBreakpointLine(
          'callPrintCount',
          isolateId!,
          mainScript,
        );
        final bp = await service.addBreakpoint(
          isolateId!,
          mainScript.id!,
          line,
        );
        // Wait for breakpoint to trigger.
        await stream.firstWhere(
          (event) => event.kind == EventKind.kPauseBreakpoint,
        );
        await service.removeBreakpoint(isolateId!, bp.id!);
      });

      tearDown(() async {
        // Resume execution to not impact other tests.
        await service.resume(isolateId!);
      });

      test('Into goes to the next Dart location', () async {
        await service.resume(isolateId!, step: 'Into');
        // Wait for the step to actually occur.
        await stream.firstWhere(
          (event) => event.kind == EventKind.kPauseInterrupted,
        );
        final stack = await service.getStack(isolateId!);
        expect(stack, isNotNull);
        final first = stack.frames!.first;
        expect(first.kind, 'Regular');
        expect(first.code!.kind, 'Dart');
        expect(first.code!.name, 'printCount');
      });

      test('Over goes to the next Dart location', () async {
        await service.resume(isolateId!, step: 'Over');
        // Wait for the step to actually occur.
        await stream.firstWhere(
          (event) => event.kind == EventKind.kPauseInterrupted,
        );
        final stack = await service.getStack(isolateId!);
        expect(stack, isNotNull);
        final first = stack.frames!.first;
        expect(first.kind, 'Regular');
        expect(first.code!.kind, 'Dart');
        expect(first.code!.name, '<closure>');
      });

      test('Out goes to the next Dart location', () async {
        await service.resume(isolateId!, step: 'Out');
        // Wait for the step to actually occur.
        await stream.firstWhere(
          (event) => event.kind == EventKind.kPauseInterrupted,
        );
        final stack = await service.getStack(isolateId!);
        expect(stack, isNotNull);
        final first = stack.frames!.first;
        expect(first.kind, 'Regular');
        expect(first.code!.kind, 'Dart');
        expect(first.code!.name, '<closure>');
      });
    });

    group('getStack', () {
      late VmServiceInterface service;
      String? isolateId;
      late Stream<Event> stream;
      ScriptList scripts;
      late ScriptRef mainScript;

      setUp(() async {
        setCurrentLogWriter(debug: provider.verbose);
        service = context.service;
        final vm = await service.getVM();
        isolateId = vm.isolates!.first.id;
        scripts = await service.getScripts(isolateId!);
        await service.streamListen('Debug');
        stream = service.onEvent('Debug');
        mainScript = scripts.scripts!.firstWhere(
          (ScriptRef each) => each.uri!.contains('main.dart'),
        );
      });

      test(
        'throws if not paused',
        () async {
          await expectLater(service.getStack(isolateId!), throwsRPCError);
        },
        skip: Platform.isWindows ? true : null,
      ); // Issue: https://github.com/dart-lang/webdev/issues/1749

      /// Support function for pausing and returning the stack at a line.
      Future<Stack> breakAt(String breakpointId, {int? limit}) async {
        final line = await context.findBreakpointLine(
          breakpointId,
          isolateId!,
          mainScript,
        );
        Breakpoint? bp;
        try {
          bp = await service.addBreakpoint(isolateId!, mainScript.id!, line);
          // Wait for breakpoint to trigger.
          await stream.firstWhere(
            (event) => event.kind == EventKind.kPauseBreakpoint,
          );
          return await service.getStack(isolateId!, limit: limit);
        } finally {
          // Remove breakpoint and resume so it doesn't impact other tests.
          if (bp != null) {
            await service.removeBreakpoint(isolateId!, bp.id!);
          }
          await service.resume(isolateId!);
        }
      }

      test('returns stack when broken', () async {
        final stack = await breakAt('inPrintCount');
        expect(stack, isNotNull);
        expect(stack.frames, hasLength(2));
        final first = stack.frames!.first;
        expect(first.kind, 'Regular');
        expect(first.code!.kind, 'Dart');
        expect(first.code!.name, 'printCount');
      });

      test('stack has a variable', () async {
        final stack = await breakAt('callPrintCount');
        expect(stack, isNotNull);
        expect(stack.frames, hasLength(1));
        final first = stack.frames!.first;
        expect(first.kind, 'Regular');
        expect(first.code!.kind, 'Dart');
        expect(first.code!.name, '<closure>');
        // TODO: Make this more precise once this case doesn't
        // also include all the libraries.
        expect(first.vars, hasLength(greaterThanOrEqualTo(1)));
        final underscore = first.vars!.firstWhere((v) => v.name == 'timer');
        expect(underscore, isNotNull);
      });

      test('collects async frames', () async {
        final stack = await breakAt('asyncCall');
        expect(stack, isNotNull);
        expect(stack.frames, hasLength(greaterThan(1)));

        final first = stack.frames!.first;
        expect(first.kind, 'Regular');
        expect(first.code!.kind, 'Dart');

        // We should have an async marker.
        final suspensionFrames = stack.frames!.where(
          (frame) => frame.kind == FrameKind.kAsyncSuspensionMarker,
        );
        expect(suspensionFrames, isNotEmpty);

        // We should have async frames.
        final asyncFrames = stack.frames!.where(
          (frame) => frame.kind == FrameKind.kAsyncCausal,
        );
        expect(asyncFrames, isNotEmpty);
      });

      test(
        'returns the correct number of frames when a limit is provided',
        () async {
          var stack = await breakAt('asyncCall', limit: 4);
          expect(stack, isNotNull);
          expect(stack.frames, hasLength(equals(4)));
          stack = await breakAt('asyncCall', limit: 2);
          expect(stack, isNotNull);
          expect(stack.frames, hasLength(equals(2)));
          stack = await breakAt('asyncCall');
          expect(stack, isNotNull);
          expect(stack.frames, hasLength(equals(5)));
        },
      );

      test('truncated stacks are properly indicated', () async {
        var stack = await breakAt('asyncCall', limit: 3);
        expect(stack, isNotNull);
        expect(stack.truncated, isTrue);
        stack = await breakAt('asyncCall');
        expect(stack, isNotNull);
        expect(stack.truncated, isFalse);
        stack = await breakAt('asyncCall', limit: 20000);
        expect(stack, isNotNull);
        expect(stack.truncated, isFalse);
      });

      test('break on exceptions with setIsolatePauseMode', () async {
        final oldPauseMode = (await service.getIsolate(
          isolateId!,
        )).exceptionPauseMode;
        await service.setIsolatePauseMode(
          isolateId!,
          exceptionPauseMode: ExceptionPauseMode.kAll,
        );
        // Wait for pausing to actually propagate.
        final event = await stream.firstWhere(
          (event) => event.kind == EventKind.kPauseException,
        );
        expect(event.exception, isNotNull);
        // Check that the exception stack trace has been mapped to Dart source
        // files.
        expect(event.exception!.valueAsString, contains('main.dart'));

        final stack = await service.getStack(isolateId!);
        expect(stack, isNotNull);

        await service.setIsolatePauseMode(
          isolateId!,
          exceptionPauseMode: oldPauseMode,
        );
        await service.resume(isolateId!);
      });

      test('returns non-null stack when paused', () async {
        await service.pause(isolateId!);
        // Wait for pausing to actually propagate.
        await stream.firstWhere(
          (event) => event.kind == EventKind.kPauseInterrupted,
        );
        expect(await service.getStack(isolateId!), isNotNull);
        // Resume the isolate to not impact other tests.
        await service.resume(isolateId!);
      });
    });

    test('getVM', () async {
      final service = context.service;
      final vm = await service.getVM();
      expect(vm.name, isNotNull);
      expect(vm.version, Platform.version);
      expect(vm.isolates, hasLength(1));
      final isolate = vm.isolates!.first;
      expect(isolate.id, isNotNull);
      expect(isolate.name, isNotNull);
      expect(isolate.number, isNotNull);
    });

    test('getVersion', () async {
      final service = context.service;
      final version = await service.getVersion();
      expect(version, isNotNull);
      expect(version.major, greaterThan(0));
    });

    group('invoke', () {
      late ChromeProxyService service;
      VM vm;
      late Isolate isolate;
      LibraryRef? bootstrap;
      late InstanceRef testInstance;

      setUp(() async {
        setCurrentLogWriter(debug: provider.verbose);
        service = context.service;
        vm = await service.getVM();
        isolate = await service.getIsolate(vm.isolates!.first.id!);
        bootstrap = isolate.rootLib;
        testInstance =
            await service.evaluate(isolate.id!, bootstrap!.id!, 'myInstance')
                as InstanceRef;
      });

      test('rootLib', () async {
        expect(
          bootstrap,
          const TypeMatcher<LibraryRef>().having(
            (library) => library.name,
            'name',
            'org-dartlang-app:///example/hello_world/main.dart',
          ),
        );
      });

      test('toString()', () async {
        final remote = await service.invoke(
          isolate.id!,
          testInstance.id!,
          'toString',
          [],
        );
        expect(
          remote,
          const TypeMatcher<InstanceRef>().having(
            (instance) => instance.valueAsString,
            'toString()',
            "Instance of 'MyTestClass'",
          ),
        );
      });

      test('hello()', () async {
        final remote = await service.invoke(
          isolate.id!,
          testInstance.id!,
          'hello',
          [],
        );
        expect(
          remote,
          const TypeMatcher<InstanceRef>().having(
            (instance) => instance.valueAsString,
            'hello()',
            'world',
          ),
        );
      });

      test('helloString', () async {
        final remote = await service.invoke(
          isolate.id!,
          bootstrap!.id!,
          'helloString',
          ['#StringInstanceRef#abc'],
        );
        expect(
          remote,
          const TypeMatcher<InstanceRef>().having(
            (instance) => instance.valueAsString,
            'helloString',
            'abc',
          ),
        );
        expect(
          remote,
          const TypeMatcher<InstanceRef>().having(
            (instance) => instance.kind,
            'kind',
            'String',
          ),
        );
      });

      test('null argument', () async {
        final remote = await service.invoke(
          isolate.id!,
          bootstrap!.id!,
          'helloString',
          ['objects/null'],
        );
        expect(
          remote,
          const TypeMatcher<InstanceRef>().having(
            (instance) => instance.valueAsString,
            'helloString',
            'null',
          ),
        );
        expect(
          remote,
          const TypeMatcher<InstanceRef>().having(
            (instance) => instance.kind,
            'kind',
            'Null',
          ),
        );
      });

      test('helloBool', () async {
        final remote = await service.invoke(
          isolate.id!,
          bootstrap!.id!,
          'helloBool',
          ['objects/bool-true'],
        );
        expect(
          remote,
          const TypeMatcher<InstanceRef>().having(
            (instance) => instance.valueAsString,
            'helloBool',
            'true',
          ),
        );
        expect(
          remote,
          const TypeMatcher<InstanceRef>().having(
            (instance) => instance.kind,
            'kind',
            'Bool',
          ),
        );
      });

      test('helloNum', () async {
        final remote = await service.invoke(
          isolate.id!,
          bootstrap!.id!,
          'helloNum',
          ['objects/int-123'],
        );
        expect(
          remote,
          const TypeMatcher<InstanceRef>().having(
            (instance) => instance.valueAsString,
            'helloNum',
            '123',
          ),
        );
        expect(
          remote,
          const TypeMatcher<InstanceRef>().having(
            (instance) => instance.kind,
            'kind',
            'Double',
          ),
        );
      });

      test('two object arguments', () async {
        final remote = await service.invoke(
          isolate.id!,
          bootstrap!.id!,
          'messagesCombined',
          [testInstance.id, testInstance.id],
        );
        expect(
          remote,
          const TypeMatcher<InstanceRef>().having(
            (instance) => instance.valueAsString,
            'messagesCombined',
            'worldworld',
          ),
        );
        expect(
          remote,
          const TypeMatcher<InstanceRef>().having(
            (instance) => instance.kind,
            'kind',
            'String',
          ),
        );
      });
    });

    test('kill', () async {
      final service = context.service;
      await expectLater(service.kill(''), throwsRPCError);
    });

    test('onEvent', () async {
      final service = context.service;
      expect(() => service.onEvent(''), throwsRPCError);
    });

    test('pause / resume', () async {
      final service = context.service;
      await service.streamListen('Debug');
      final stream = service.onEvent('Debug');
      final vm = await service.getVM();
      final isolateId = vm.isolates!.first.id!;
      final pauseCompleter = Completer<void>();
      final pauseSub = context.tabConnection.debugger.onPaused.listen((_) {
        pauseCompleter.complete();
      });
      final resumeCompleter = Completer<void>();
      final resumeSub = context.tabConnection.debugger.onResumed.listen((_) {
        resumeCompleter.complete();
      });
      expect(await service.pause(isolateId), const TypeMatcher<Success>());
      await stream.firstWhere(
        (event) => event.kind == EventKind.kPauseInterrupted,
      );
      expect(
        (await service.getIsolate(isolateId)).pauseEvent!.kind,
        EventKind.kPauseInterrupted,
      );
      await pauseCompleter.future;
      expect(await service.resume(isolateId), const TypeMatcher<Success>());
      await stream.firstWhere((event) => event.kind == EventKind.kResume);
      expect(
        (await service.getIsolate(isolateId)).pauseEvent!.kind,
        EventKind.kResume,
      );
      await resumeCompleter.future;
      await pauseSub.cancel();
      await resumeSub.cancel();
    });

    test('getInboundReferences', () async {
      final service = context.service;
      await expectLater(
        service.getInboundReferences('', '', 0),
        throwsRPCError,
      );
    });

    test('getRetainingPath', () async {
      final service = context.service;
      await expectLater(service.getRetainingPath('', '', 0), throwsRPCError);
    });

    test(
      'lookupResolvedPackageUris converts package and org-dartlang-app uris',
      () async {
        final service = context.service;
        final vm = await service.getVM();
        final isolateId = vm.isolates!.first.id!;
        final scriptList = await service.getScripts(isolateId);

        final uris = scriptList.scripts!.map((e) => e.uri!).toList();
        final resolvedUris = await service.lookupResolvedPackageUris(
          isolateId,
          uris,
        );

        expect(
          resolvedUris.uris,
          containsAll([
            contains('/_test/example/hello_world/main.dart'),
            contains('/lib/path.dart'),
            contains('/lib/src/path_set.dart'),
          ]),
        );
      },
    );

    test(
      'lookupResolvedPackageUris does not translate non-existent paths',
      () async {
        final service = context.service;
        final vm = await service.getVM();
        final isolateId = vm.isolates!.first.id!;

        final resolvedUris = await service
            .lookupResolvedPackageUris(isolateId, [
              'package:does/not/exist.dart',
              'dart:does_not_exist',
              'file:///does_not_exist.dart',
            ]);
        expect(resolvedUris.uris, [null, null, null]);
      },
    );

    test(
      'lookupResolvedPackageUris translates dart uris',
      () async {
        final service = context.service;
        final vm = await service.getVM();
        final isolateId = vm.isolates!.first.id!;

        final resolvedUris = await service.lookupResolvedPackageUris(
          isolateId,
          ['dart:html', 'dart:async'],
        );

        expect(resolvedUris.uris, [
          'org-dartlang-sdk:///sdk/lib/html/dart2js/html_dart2js.dart',
          'org-dartlang-sdk:///sdk/lib/async/async.dart',
        ]);
      },
      skip: 'https://github.com/dart-lang/webdev/issues/1584',
    );

    test(
      'lookupPackageUris finds package and org-dartlang-app paths',
      () async {
        final service = context.service;
        final vm = await service.getVM();
        final isolateId = vm.isolates!.first.id!;
        final scriptList = await service.getScripts(isolateId);

        final uris = scriptList.scripts!.map((e) => e.uri!).toList();
        final resolvedUris = await service.lookupResolvedPackageUris(
          isolateId,
          uris,
        );

        final packageUris = await service.lookupPackageUris(
          isolateId,
          List<String>.from(resolvedUris.uris!),
        );
        expect(
          packageUris.uris,
          containsAll([
            'org-dartlang-app:///example/hello_world/main.dart',
            'package:path/path.dart',
            'package:path/src/path_set.dart',
          ]),
        );
      },
    );

    test('lookupPackageUris ignores local parameter', () async {
      final service = context.service;
      final vm = await service.getVM();
      final isolateId = vm.isolates!.first.id!;
      final scriptList = await service.getScripts(isolateId);

      final uris = scriptList.scripts!.map((e) => e.uri!).toList();
      final resolvedUrisWithLocal = await service.lookupResolvedPackageUris(
        isolateId,
        uris,
        local: true,
      );

      final packageUrisWithLocal = await service.lookupPackageUris(
        isolateId,
        List<String>.from(resolvedUrisWithLocal.uris!),
      );
      expect(
        packageUrisWithLocal.uris,
        containsAll([
          'org-dartlang-app:///example/hello_world/main.dart',
          'package:path/path.dart',
          'package:path/src/path_set.dart',
        ]),
      );

      final resolvedUrisWithoutLocal = await service.lookupResolvedPackageUris(
        isolateId,
        uris,
        local: true,
      );

      final packageUrisWithoutLocal = await service.lookupPackageUris(
        isolateId,
        List<String>.from(resolvedUrisWithoutLocal.uris!),
      );
      expect(
        packageUrisWithoutLocal.uris,
        containsAll([
          'org-dartlang-app:///example/hello_world/main.dart',
          'package:path/path.dart',
          'package:path/src/path_set.dart',
        ]),
      );
    });

    test('lookupPackageUris does not translate non-existent paths', () async {
      final service = context.service;
      final vm = await service.getVM();
      final isolateId = vm.isolates!.first.id!;

      final resolvedUris = await service.lookupPackageUris(isolateId, [
        'org-dartlang-sdk:///sdk/does/not/exist.dart',
        'does_not_exist.dart',
        'file:///does_not_exist.dart',
      ]);
      expect(resolvedUris.uris, [null, null, null]);
    });

    test(
      'lookupPackageUris translates dart uris',
      () async {
        final service = context.service;
        final vm = await service.getVM();
        final isolateId = vm.isolates!.first.id!;

        final resolvedUris = await service.lookupPackageUris(isolateId, [
          'org-dartlang-sdk:///sdk/lib/html/dart2js/html_dart2js.dart',
          'org-dartlang-sdk:///sdk/lib/async/async.dart',
        ]);

        expect(resolvedUris.uris, ['dart:html', 'dart:async']);
      },
      skip: 'https://github.com/dart-lang/webdev/issues/1584',
    );

    test('registerService', () async {
      final service = context.service;
      await expectLater(
        service.registerService('ext.foo.bar', ''),
        throwsRPCError,
      );
    });

    test('setIsolatePauseMode', () async {
      final service = context.service;
      final vm = await service.getVM();
      final isolateId = vm.isolates!.first.id!;
      expect(await service.setIsolatePauseMode(isolateId), _isSuccess);
      expect(
        await service.setIsolatePauseMode(
          isolateId,
          exceptionPauseMode: ExceptionPauseMode.kAll,
        ),
        _isSuccess,
      );
      expect(
        await service.setIsolatePauseMode(
          isolateId,
          exceptionPauseMode: ExceptionPauseMode.kUnhandled,
        ),
        _isSuccess,
      );
      // Make sure this is the last one - or future tests might hang.
      expect(
        await service.setIsolatePauseMode(
          isolateId,
          exceptionPauseMode: ExceptionPauseMode.kNone,
        ),
        _isSuccess,
      );
      await expectLater(
        service.setIsolatePauseMode(isolateId, exceptionPauseMode: 'invalid'),
        throwsRPCError,
      );
    });

    test('setFlag', () async {
      final service = context.service;
      await expectLater(service.setFlag('', ''), throwsRPCError);
    });

    test('setLibraryDebuggable', () async {
      final service = context.service;
      await expectLater(
        service.setLibraryDebuggable('', '', false),
        throwsRPCError,
      );
    });

    test('setName', () async {
      final service = context.service;
      final vm = await service.getVM();
      final isolateId = vm.isolates!.first.id!;
      expect(service.setName(isolateId, 'test'), completion(_isSuccess));
      final isolate = await service.getIsolate(isolateId);
      expect(isolate.name, 'test');
    });

    test('setVMName', () async {
      final service = context.service;
      expect(service.setVMName('foo'), completion(_isSuccess));
      final vm = await service.getVM();
      expect(vm.name, 'foo');
    });

    test('streamCancel', () async {
      final service = context.service;
      await expectLater(service.streamCancel(''), throwsRPCError);
    });

    group('setFlag', () {
      test('pause_isolates_on_start set to true', () {
        final service = context.service;
        expect(
          service.setFlag('pause_isolates_on_start', 'true'),
          completion(_isSuccess),
        );
        expect(context.service.pauseIsolatesOnStart, equals(true));
      });

      test('pause_isolates_on_start set to false', () {
        final service = context.service;
        expect(
          service.setFlag('pause_isolates_on_start', 'false'),
          completion(_isSuccess),
        );
        expect(context.service.pauseIsolatesOnStart, equals(false));
      });

      test('pause_isolates_on_start set to invalid value', () {
        final service = context.service;
        expect(
          service.setFlag('pause_isolates_on_start', 'pizza'),
          throwsRPCError,
        );
      });
    });

    group('getFlagList', () {
      List<String> stringifyFlags(FlagList flagList) {
        return flagList.flags
                ?.map((flag) => '${flag.name} -> ${flag.valueAsString}')
                .toList() ??
            [];
      }

      test('returns expected default values', () async {
        final service = context.service;
        final flagList = await service.getFlagList();
        expect(
          stringifyFlags(flagList),
          containsAll(['pause_isolates_on_start -> false']),
        );
      });

      test('returns any modified flag values', () async {
        final service = context.service;
        await service.setFlag('pause_isolates_on_start', 'true');
        final flagList = await service.getFlagList();
        expect(
          stringifyFlags(flagList),
          containsAll(['pause_isolates_on_start -> true']),
        );
      });
    });

    group('streamListen/onEvent', () {
      late ChromeProxyService service;

      group('Debug', () {
        late Stream<Event> eventStream;

        setUp(() async {
          setCurrentLogWriter(debug: provider.verbose);
          service = context.service;
          expect(
            await service.streamListen('Debug'),
            const TypeMatcher<Success>(),
          );
          eventStream = service.onEvent('Debug');
        });

        test('basic Pause/Resume', () async {
          expect(service.streamListen('Debug'), completion(_isSuccess));
          final stream = service.onEvent('Debug');
          safeUnawaited(context.tabConnection.debugger.pause());
          await expectLater(
            stream,
            emitsThrough(
              const TypeMatcher<Event>().having(
                (e) => e.kind,
                'kind',
                EventKind.kPauseInterrupted,
              ),
            ),
          );
          safeUnawaited(context.tabConnection.debugger.resume());
          expect(
            eventStream,
            emitsThrough(
              const TypeMatcher<Event>().having(
                (e) => e.kind,
                'kind',
                EventKind.kResume,
              ),
            ),
          );
        });

        test('Inspect', () async {
          expect(
            eventStream,
            emitsThrough(
              const TypeMatcher<Event>()
                  .having((e) => e.kind, 'kind', EventKind.kInspect)
                  .having(
                    (e) => e.inspectee,
                    'inspectee',
                    const TypeMatcher<InstanceRef>()
                        .having((instance) => instance.id, 'id', isNotNull)
                        .having(
                          (instance) => instance.kind,
                          'inspectee.kind',
                          InstanceKind.kPlainInstance,
                        ),
                  ),
            ),
          );
          await context.tabConnection.runtime.evaluate('inspectInstance()');
        });
      });

      group('Extension', () {
        late VmServiceInterface service;
        late Stream<Event> eventStream;

        setUp(() async {
          setCurrentLogWriter(debug: provider.verbose);
          service = context.service;
          expect(
            await service.streamListen('Extension'),
            const TypeMatcher<Success>(),
          );
          eventStream = service.onEvent('Extension');
        });

        test('Custom debug event', () async {
          final eventKind = 'my.custom.event';
          expect(
            eventStream,
            emitsThrough(
              predicate(
                (Event event) =>
                    event.kind == EventKind.kExtension &&
                    event.extensionKind == eventKind &&
                    event.extensionData!.data['example'] == 'data',
              ),
            ),
          );
          await context.tabConnection.runtime.evaluate(
            "postEvent('$eventKind');",
          );
        });

        test('Batched debug events from injected client', () async {
          final eventKind = EventKind.kExtension;
          final extensionKind = 'MyEvent';
          final eventData = 'eventData';
          final delay = const Duration(milliseconds: 2000);

          TypeMatcher<Event> eventMatcher(String data) =>
              const TypeMatcher<Event>()
                  .having((event) => event.kind, 'kind', eventKind)
                  .having(
                    (event) => event.extensionKind,
                    'extensionKind',
                    extensionKind,
                  )
                  .having(
                    (event) => event.extensionData!.data['eventData'],
                    'eventData',
                    data,
                  );

          String emitDebugEvent(String data) =>
              '\$emitDebugEvent("$extensionKind", '
              '\'{"$eventData": "$data"}\');';

          final size = 2;
          final batch1 = List.generate(size, (int i) => 'data$i');
          final batch2 = List.generate(size, (int i) => 'data${size + i}');

          expect(
            eventStream,
            emitsInOrder([
              ...batch1.map(eventMatcher),
              ...batch2.map(eventMatcher),
            ]),
          );

          for (final data in batch1) {
            await context.tabConnection.runtime.evaluate(emitDebugEvent(data));
          }
          await Future<void>.delayed(delay);
          for (final data in batch2) {
            await context.tabConnection.runtime.evaluate(emitDebugEvent(data));
          }
        });
      });

      test('GC', () async {
        expect(service.streamListen('GC'), completion(_isSuccess));
      });

      group('Isolate', () {
        late Stream<Event> isolateEventStream;

        setUp(() async {
          expect(await service.streamListen(EventStreams.kIsolate), _isSuccess);
          isolateEventStream = service.onEvent(EventStreams.kIsolate);
        });

        test('serviceExtensionAdded', () async {
          final extensionMethod = 'ext.foo.bar';
          expect(
            isolateEventStream,
            emitsThrough(
              predicate(
                (Event event) =>
                    event.kind == EventKind.kServiceExtensionAdded &&
                    event.extensionRPC == extensionMethod,
              ),
            ),
          );
          await context.tabConnection.runtime.evaluate(
            "registerExtension('$extensionMethod');",
          );
        });

        test('lifecycle events', () async {
          final vm = await service.getVM();
          final initialIsolateId = vm.isolates!.first.id;
          final eventsDone = expectLater(
            isolateEventStream,
            emitsThrough(
              emitsInOrder([
                predicate(
                  (Event event) =>
                      event.kind == EventKind.kIsolateExit &&
                      event.isolate!.id == initialIsolateId,
                ),
                predicate(
                  (Event event) =>
                      event.kind == EventKind.kIsolateStart &&
                      event.isolate!.id != initialIsolateId,
                ),
                predicate(
                  (Event event) =>
                      event.kind == EventKind.kIsolateRunnable &&
                      event.isolate!.id != initialIsolateId,
                ),
              ]),
            ),
          );
          service.destroyIsolate();
          await service.createIsolate(context.appConnection);
          await eventsDone;
          expect(
            (await service.getVM()).isolates!.first.id,
            isNot(initialIsolateId),
          );
        });

        test('RegisterExtension events from injected client', () async {
          final eventKind = EventKind.kServiceExtensionAdded;
          final extensions = List.generate(10, (index) => 'extension$index');

          TypeMatcher<Event> eventMatcher(String extension) =>
              const TypeMatcher<Event>()
                  .having((event) => event.kind, 'kind', eventKind)
                  .having((event) => event.extensionRPC, 'RPC', extension);

          String emitRegisterEvent(String extension) =>
              "\$emitRegisterEvent('$extension')";

          expect(
            isolateEventStream,
            emitsInOrder(extensions.map(eventMatcher)),
          );
          for (final extension in extensions) {
            await context.tabConnection.runtime.evaluate(
              emitRegisterEvent(extension),
            );
          }
        });
      });

      test('Timeline', () async {
        expect(service.streamListen('Timeline'), completion(_isSuccess));
      });

      test('Stdout', () async {
        expect(service.streamListen('Stdout'), completion(_isSuccess));
        expect(
          service.onEvent('Stdout'),
          emitsThrough(
            predicate(
              (Event event) =>
                  event.kind == EventKind.kWriteEvent &&
                  String.fromCharCodes(
                    base64.decode(event.bytes!),
                  ).contains('hello'),
            ),
          ),
        );
        await context.tabConnection.runtime.evaluate('console.log("hello");');
      });

      test('Stderr', () async {
        expect(service.streamListen('Stderr'), completion(_isSuccess));
        final stderrStream = service.onEvent('Stderr');
        expect(
          stderrStream,
          emitsThrough(
            predicate(
              (Event event) =>
                  event.kind == EventKind.kWriteEvent &&
                  String.fromCharCodes(
                    base64.decode(event.bytes!),
                  ).contains('Error'),
            ),
          ),
        );
        await context.tabConnection.runtime.evaluate('console.error("Error");');
      });

      test('exception stack trace mapper', () async {
        expect(service.streamListen('Stderr'), completion(_isSuccess));
        final stderrStream = service.onEvent('Stderr');
        expect(
          stderrStream,
          emitsThrough(
            predicate(
              (Event event) =>
                  event.kind == EventKind.kWriteEvent &&
                  String.fromCharCodes(
                    base64.decode(event.bytes!),
                  ).contains('main.dart'),
            ),
          ),
        );
        await context.tabConnection.runtime.evaluate(
          'throwUncaughtException();',
        );
      });

      test('VM', () async {
        final status = await service.streamListen('VM');
        expect(status, _isSuccess);
        final stream = service.onEvent('VM');
        expect(
          stream,
          emitsThrough(
            predicate(
              (Event e) =>
                  e.kind == EventKind.kVMUpdate && e.vm!.name == 'test',
            ),
          ),
        );
        await service.setVMName('test');
      });

      test('custom stream', () {
        expect(
          () => service.streamListen('aCustomStreamId'),
          throwsA(
            predicate(
              (e) =>
                  (e is RPCError) && e.code == RPCErrorKind.kInvalidParams.code,
            ),
          ),
        );
      });
    });

    group('Logging |', () {
      test('logging stream is registered', () {
        final service = context.service;
        expect(
          service.streamListen(EventStreams.kLogging),
          completion(_isSuccess),
        );
      });

      test(
        'dart:developer logs are correctly converted to log records',
        () async {
          final logStream = context.service.onEvent(EventStreams.kLogging);
          final message = 'myMessage';

          safeUnawaited(
            context.tabConnection.runtime.evaluate("sendLog('$message');"),
          );

          final event = await logStream.first;
          expect(event.kind, EventKind.kLogging);

          final logRecord = event.logRecord!;
          expect(logRecord.message!.valueAsString, message);
          expect(logRecord.loggerName!.valueAsString, 'testLogCategory');
        },
      );

      test('long dart:developer log messages are not truncated', () async {
        final logStream = context.service.onEvent(EventStreams.kLogging);
        final longMessage =
            'A very long log message that Chrome truncates by default and '
            'requires users to expand in order to see the entire message.';
        safeUnawaited(
          context.tabConnection.runtime.evaluate("sendLog('$longMessage');"),
        );

        final event = await logStream.first;
        expect(event.logRecord!.message!.valueAsString, longMessage);
      });
    });
  });
}

final _isSuccess = isA<Success>();

TypeMatcher<LibraryRef> _libRef(Object? uriMatcher) =>
    isA<LibraryRef>().having((LibraryRef l) => l.uri, 'uri', uriMatcher);

void expectEventually(Matcher expectation) {}
