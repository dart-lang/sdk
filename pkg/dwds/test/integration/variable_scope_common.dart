// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dwds/src/debugging/dart_scope.dart';
import 'package:dwds/src/services/chrome/chrome_proxy_service.dart';
import 'package:dwds_test_common/logging.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'fixtures/context.dart';
import 'fixtures/project.dart';
import 'fixtures/utilities.dart';

void testAll({required TestSdkConfigurationProvider provider}) {
  final context = TestContext(TestProject.testScopes, provider);

  setUpAll(() async {
    setCurrentLogWriter(debug: provider.verbose);
    await context.setUp(
      testSettings: TestSettings(
        verboseCompiler: provider.verbose,
        moduleFormat: provider.ddcModuleFormat,
        canaryFeatures: provider.canaryFeatures,
      ),
    );
  });

  tearDownAll(() async {
    await context.tearDown();
  });

  group('temporary variable regular expression', () {
    setUpAll(() => setCurrentLogWriter(debug: provider.verbose));
    test('matches correctly for pre-patterns temporary variables', () {
      expect(previousDdcTemporaryVariableRegExp.hasMatch(r't4$'), isTrue);
      expect(previousDdcTemporaryVariableRegExp.hasMatch(r't4$0'), isTrue);
      expect(previousDdcTemporaryVariableRegExp.hasMatch(r't4$10'), isTrue);
      expect(previousDdcTemporaryVariableRegExp.hasMatch(r't4$0'), isTrue);
      expect(previousDdcTemporaryVariableRegExp.hasMatch(r't1'), isTrue);
      expect(previousDdcTemporaryVariableRegExp.hasMatch(r't10'), isTrue);
      expect(previousDdcTemporaryVariableRegExp.hasMatch(r'__t$TL'), isTrue);
      expect(
        previousDdcTemporaryVariableRegExp.hasMatch(r'__t$StringN'),
        isTrue,
      );
      expect(
        previousDdcTemporaryVariableRegExp.hasMatch(
          r'__t$IdentityMapOfString$T',
        ),
        isTrue,
      );

      expect(previousDdcTemporaryVariableRegExp.hasMatch(r't'), isFalse);
      expect(previousDdcTemporaryVariableRegExp.hasMatch(r't10foo'), isFalse);
      expect(previousDdcTemporaryVariableRegExp.hasMatch(r't$10foo'), isFalse);
    });

    test('matches correctly for post-patterns temporary variables', () {
      expect(ddcTemporaryVariableRegExp.hasMatch(r't$364$'), isTrue);
      expect(ddcTemporaryVariableRegExp.hasMatch(r't$364$0'), isTrue);
      expect(ddcTemporaryVariableRegExp.hasMatch(r't$364$10'), isTrue);
      expect(ddcTemporaryVariableRegExp.hasMatch(r't$364$0'), isTrue);
      expect(ddcTemporaryVariableRegExp.hasMatch(r't$361'), isTrue);
      expect(ddcTemporaryVariableRegExp.hasMatch(r't$36$350$350'), isTrue);
      expect(
        ddcTemporaryVariableRegExp.hasMatch(r't$36$350$354$35isSet'),
        isTrue,
      );
      expect(
        ddcTemporaryVariableRegExp.hasMatch(r't$36$35variable$35isSet'),
        isTrue,
      );
      expect(
        ddcTemporaryVariableRegExp.hasMatch(r'synthetic$35variable'),
        isTrue,
      );
      expect(ddcTemporaryTypeVariableRegExp.hasMatch(r'__t$TL'), isTrue);
      expect(ddcTemporaryTypeVariableRegExp.hasMatch(r'__t$StringN'), isTrue);
      expect(
        ddcTemporaryTypeVariableRegExp.hasMatch(r'__t$IdentityMapOfString$T'),
        isTrue,
      );

      expect(ddcTemporaryVariableRegExp.hasMatch(r't'), isFalse);
      expect(ddcTemporaryVariableRegExp.hasMatch(r'this'), isFalse);
      expect(ddcTemporaryVariableRegExp.hasMatch(r'\$this'), isFalse);
      expect(ddcTemporaryVariableRegExp.hasMatch(r't10'), isFalse);
      expect(ddcTemporaryVariableRegExp.hasMatch(r't10foo'), isFalse);
      expect(ddcTemporaryVariableRegExp.hasMatch(r'ten'), isFalse);
      expect(ddcTemporaryVariableRegExp.hasMatch(r'my$3635variable'), isFalse);
    });
  });

  group('variable scope', () {
    late ChromeProxyService service;
    VM vm;
    String? isolateId;
    late Stream<Event> stream;
    ScriptList scripts;
    late ScriptRef mainScript;
    Stack stack;

    // TODO: Be able to set breakpoints before start/reload so we can exercise
    // things that aren't in recurring loops.

    /// Support function for pausing and returning the stack at a line.
    Future<Stack> breakAt(String breakpointId, ScriptRef scriptRef) async {
      final lineNumber = await context.findBreakpointLine(
        breakpointId,
        isolateId!,
        scriptRef,
      );

      final bp = await service.addBreakpoint(
        isolateId!,
        scriptRef.id!,
        lineNumber,
      );
      // Wait for breakpoint to trigger.
      await stream.firstWhere(
        (event) => event.kind == EventKind.kPauseBreakpoint,
      );
      // Remove breakpoint so it doesn't impact other tests.
      await service.removeBreakpoint(isolateId!, bp.id!);
      final stack = await service.getStack(isolateId!);
      return stack;
    }

    Future<Instance> getInstance(InstanceRef ref) async {
      final result = await service.getObject(isolateId!, ref.id!);
      expect(result, isA<Instance>());
      return result as Instance;
    }

    void expectDartObject(String variableName, Instance instance) {
      expect(
        instance,
        isA<Instance>().having(
          (instance) => instance.classRef!.name,
          '$variableName: classRef.name',
          isNot(
            isIn(['NativeJavaScriptObject', 'JavaScriptObject', 'NativeError']),
          ),
        ),
      );
    }

    Future<void> expectDartVariables(
      Map<String?, InstanceRef?> variables,
    ) async {
      for (final name in variables.keys) {
        final instance = await getInstance(variables[name]!);
        expectDartObject(name!, instance);
      }
    }

    Map<String?, InstanceRef?> getFrameVariables(Frame frame) {
      return <String?, InstanceRef?>{
        for (final variable in frame.vars!)
          variable.name: variable.value as InstanceRef?,
      };
    }

    setUpAll(() => setCurrentLogWriter(debug: provider.verbose));

    setUp(() async {
      service = context.service;
      vm = await service.getVM();
      isolateId = vm.isolates!.first.id;
      scripts = await service.getScripts(isolateId!);
      await service.streamListen('Debug');
      stream = service.onEvent('Debug');
      mainScript = scripts.scripts!.firstWhere(
        (each) => each.uri!.contains('main.dart'),
      );
    });

    tearDown(() async {
      await service.resume(isolateId!);
    });

    test('variables in static function', () async {
      stack = await breakAt('staticFunction', mainScript);
      final variables = getFrameVariables(stack.frames!.first);
      await expectDartVariables(variables);

      final variableNames = variables.keys.toList()..sort();
      expect(variableNames, containsAll(['formal']));
    });

    test('variables in static async function', () async {
      stack = await breakAt('staticAsyncFunction', mainScript);
      final variables = getFrameVariables(stack.frames!.first);
      await expectDartVariables(variables);

      final variableNames = variables.keys.toList()..sort();
      final variableValues = variableNames
          .map((name) => variables[name]?.valueAsString)
          .toList();
      expect(variableNames, containsAll(['myLocal', 'value']));
      expect(variableValues, containsAll(['a local value', 'arg1']));
    });

    test('variables in static async loop function', () async {
      stack = await breakAt('staticAsyncLoopFunction', mainScript);
      final variables = getFrameVariables(stack.frames!.first);
      await expectDartVariables(variables);

      final variableNames = variables.keys.toList()..sort();
      final variableValues = variableNames
          .map((name) => variables[name]?.valueAsString)
          .toList();
      expect(variableNames, containsAll(['i', 'myLocal', 'value']));
      // Ensure the loop variable, i, is captued correctly. The value from the
      // first iteration should be captured by the saved closure.
      expect(variableValues, containsAll(['1', 'my local value', 'arg2']));
    });

    test('variables in function', () async {
      stack = await breakAt('nestedFunction', mainScript);
      final variables = getFrameVariables(stack.frames!.first);
      await expectDartVariables(variables);

      final variableNames = variables.keys.toList()..sort();
      expect(
        variableNames,
        containsAll([
          'aClass',
          'another',
          'intLocalInMain',
          'local',
          'localThatsNull',
          'nestedFunction',
          'parameter',
          'testClass',
        ]),
      );
    });

    test('variables in closure nested in method', () async {
      stack = await breakAt('nestedClosure', mainScript);
      final variables = getFrameVariables(stack.frames!.first);
      await expectDartVariables(variables);

      final variableNames = variables.keys.toList()..sort();
      expect(variableNames, [
        'closureLocalInsideMethod',
        'local',
        'parameter',
        'this',
      ]);
    });

    test('variables in method', () async {
      stack = await breakAt('printMethod', mainScript);
      final variables = getFrameVariables(stack.frames!.first);
      await expectDartVariables(variables);

      final variableNames = variables.keys.toList()..sort();
      expect(variableNames, ['this']);
    });

    test('variables in extension method', () async {
      stack = await breakAt('extension', mainScript);
      final variables = getFrameVariables(stack.frames!.first);
      await expectDartVariables(variables);

      final variableNames = variables.keys.toList()..sort();
      // Note: '$this' should change to 'this', and 'return' should
      // disappear after debug symbols are available.
      // https://github.com/dart-lang/webdev/issues/1371
      expect(variableNames, ['\$this', 'ret', 'return']);
    });

    test('evaluateJsOnCallFrame', () async {
      stack = await breakAt('nestedFunction', mainScript);
      final debugger = await service.debuggerFuture;
      final parameter = await debugger.evaluateJsOnCallFrameIndex(
        0,
        'parameter',
      );
      expect(parameter.value, matches(RegExp(r'\d+ world')));
      final ticks = await debugger.evaluateJsOnCallFrameIndex(1, 'ticks');
      // We don't know how many ticks there were before we stopped, but it
      // should be a positive number.
      expect(ticks.value, isPositive);
    });
  });
}
