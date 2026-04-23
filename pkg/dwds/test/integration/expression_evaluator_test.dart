// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
@Timeout(Duration(minutes: 2))
library;

import 'dart:async';

import 'package:dwds/src/debugging/debugger.dart';
import 'package:dwds/src/debugging/location.dart';
import 'package:dwds/src/debugging/skip_list.dart';
import 'package:dwds/src/services/batched_expression_evaluator.dart';
import 'package:dwds/src/services/expression_evaluator.dart';
import 'package:dwds/src/utilities/shared.dart';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' hide LogRecord;
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'fixtures/context.dart';
import 'fixtures/fakes.dart';
import 'fixtures/utilities.dart';

late ExpressionEvaluator? _evaluator;
late ExpressionEvaluator? _batchedEvaluator;

void main() async {
  group('expression compiler service with fake asset server', () {
    Future<void> stop() async {
      _evaluator?.close();
      _evaluator = null;
      _batchedEvaluator?.close();
      _batchedEvaluator = null;
    }

    late StreamController<DebuggerPausedEvent> pausedController;
    late StreamController<Event> debugEventController;
    late FakeChromeAppInspector inspector;
    setUp(() async {
      final assetReader = FakeAssetReader(sourceMap: '');
      final toolConfiguration = TestToolConfiguration.withLoadStrategy(
        loadStrategy: FakeStrategy(assetReader),
      );
      setGlobalsForTesting(toolConfiguration: toolConfiguration);
      final modules = FakeModules();

      final webkitDebugger = FakeWebkitDebugger();
      pausedController = StreamController<DebuggerPausedEvent>();
      debugEventController = StreamController<Event>();
      webkitDebugger.onPaused = pausedController.stream;

      final root = 'fakeRoot';
      final entry = 'fake_entrypoint';
      final locations = Locations(assetReader, modules, root);
      await locations.initialize(entry);

      final skipLists = SkipLists(root);
      final debugger = await Debugger.create(
        webkitDebugger,
        (_, e) => debugEventController.sink.add(e),
        locations,
        skipLists,
        root,
      );
      inspector = FakeChromeAppInspector(
        webkitDebugger,
        fakeIsolate: simpleIsolate,
      );
      debugger.updateInspector(inspector);

      _evaluator = ExpressionEvaluator(
        entry,
        inspector,
        debugger,
        locations,
        modules,
        FakeExpressionCompiler(),
      );
      _batchedEvaluator = BatchedExpressionEvaluator(
        entry,
        inspector,
        debugger,
        locations,
        modules,
        FakeExpressionCompiler(),
      );
    });

    tearDown(() async {
      await stop();
    });

    group('evaluator', () {
      late ExpressionEvaluator evaluator;

      setUp(() async {
        evaluator = _evaluator!;
      });

      test('can evaluate expression', () async {
        final result = await evaluator.evaluateExpression(
          '1',
          'main.dart',
          'true',
          {},
        );
        expect(
          result,
          const TypeMatcher<RemoteObject>().having(
            (o) => o.value,
            'value',
            'true',
          ),
        );
      });

      test('can evaluate expression in frame with null scope', () async {
        // Verify that we don't get the internal error.
        // More extensive testing of 'evaluateExpressionInFrame' is done in
        // evaluation tests for frontend server and build daemon.
        await expectLater(
          evaluator.evaluateExpressionInFrame('1', 0, 'true', null),
          throwsRPCErrorWithMessage(
            'Cannot evaluate on a call frame when the program is not paused',
          ),
        );
      });

      test('cannot evaluate expression in async frame ', () async {
        // Add a DebuggerPausedEvent with no frames provoke an error.
        pausedController.sink.add(
          DebuggerPausedEvent({
            'method': '',
            'params': {
              'reason': 'other',
              'callFrames': <Map<String, dynamic>>[],
            },
          }),
        );

        await debugEventController.stream.firstWhere(
          (e) => e.kind == EventKind.kPauseInterrupted,
        );

        // Verify that we get the internal error.
        final result = await evaluator.evaluateExpressionInFrame(
          '20',
          0,
          'true',
          null,
        );
        expect(
          result,
          isA<RemoteObject>()
              .having((o) => o.json['type'], 'type', 'AsyncFrameError')
              .having(
                (o) => o.json['value'],
                'value',
                'Expression evaluation in async frames is not supported. '
                    'No frame with index 0.',
              ),
        );
      });

      test('can evaluate expression in frame with empty scope', () async {
        // Verify that we don't get the internal error.
        // More extensive testing of 'evaluateExpressionInFrame' is done in
        // evaluation tests for frontend server and build daemon.
        await expectLater(
          evaluator.evaluateExpressionInFrame('1', 0, 'true', {}),
          throwsRPCErrorWithMessage(
            'Cannot evaluate on a call frame when the program is not paused',
          ),
        );
      });

      test('returns error if closed', () async {
        evaluator.close();
        final result = await evaluator.evaluateExpression(
          '1',
          'main.dart',
          'true',
          {},
        );
        expect(
          result,
          const TypeMatcher<RemoteObject>()
              .having((o) => o.type, 'type', 'InternalError')
              .having((o) => o.value, 'value', contains('evaluator closed')),
        );
      });
    });

    group('batched evaluator', () {
      late ExpressionEvaluator evaluator;

      setUp(() async {
        evaluator = _batchedEvaluator!;
      });

      test('can evaluate expression', () async {
        final result = await evaluator.evaluateExpression(
          '1',
          'main.dart',
          'true',
          {},
        );
        expect(
          result,
          const TypeMatcher<RemoteObject>().having(
            (o) => o.value,
            'value',
            'true',
          ),
        );
      });

      test('retries failed batched expression', () async {
        safeUnawaited(
          evaluator.evaluateExpression('2', 'main.dart', 'true', {}),
        );

        await evaluator.evaluateExpression('2', 'main.dart', 'false', {});
        expect(inspector.functionsCalled.length, 3);
        expect(
          inspector.functionsCalled[0].contains('return [ true, false ];'),
          true,
        );
        expect(inspector.functionsCalled[1].contains('return true;'), true);
        expect(inspector.functionsCalled[2].contains('return false;'), true);
      });

      test('returns error if closed', () async {
        evaluator.close();
        final result = await evaluator.evaluateExpression(
          '1',
          'main.dart',
          'true',
          {},
        );
        expect(
          result,
          const TypeMatcher<RemoteObject>()
              .having((o) => o.type, 'type', 'InternalError')
              .having((o) => o.value, 'value', contains('evaluator closed')),
        );
      });
    });
  });
}
