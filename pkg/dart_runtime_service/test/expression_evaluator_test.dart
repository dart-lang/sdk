// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:test/test.dart';

base class TestExpressionEvaluator extends ExpressionEvaluator {
  TestExpressionEvaluator({UnmodifiableClientNamedLookup? clients})
    : super(
        clients: clients ?? UnmodifiableClientNamedLookup(ClientNamedLookup()),
      );

  Map<String, Object?> testBuildCompileParams({
    required String expression,
    required String isolateId,
    required Map<String, Object?> scope,
  }) => buildCompileParams(
    expression: expression,
    isolateId: isolateId,
    scope: scope,
  );

  @override
  Future<Map<String, Object?>> buildScope({
    required String isolateId,
    int? frameIndex,
    Map<String, String>? scope,
    String? targetId,
  }) async {
    return <String, Object?>{
      'isolateId': isolateId,
      'klass': 'MyClass',
      'libraryUri': 'file:///test.dart',
      'param_names': <String>['x'],
      'param_types': <String>['int'],
      'tokenPos': 123,
    };
  }

  @override
  Future<RpcResponse> evaluateCompiledExpression({
    required String expression,
    required String isolateId,
    required String kernelBase64,
    bool? disableBreakpoints,
    int? frameIndex,
    String? idZoneId,
    Map<String, String>? scope,
    String? targetId,
  }) async {
    return <String, Object?>{
      'type': 'InstanceRef',
      'valueAsString': 'evaluated:$expression:$kernelBase64',
    };
  }

  @override
  Future<RpcResponse> fallbackCompileAndEvaluate({
    required String expression,
    required String isolateId,
    required String method,
    bool? disableBreakpoints,
    int? frameIndex,
    String? idZoneId,
    Map<String, String>? scope,
    String? targetId,
  }) async {
    return <String, Object?>{
      'type': 'InstanceRef',
      'valueAsString': 'fallback:$method:$expression',
    };
  }
}

void main() {
  group('ExpressionEvaluator:', () {
    test('buildCompileParams formats scope parameters correctly', () {
      final evaluator = TestExpressionEvaluator();
      final scope = <String, Object?>{
        'param_names': ['x'],
        'param_types': ['int'],
        'type_params_names': ['T'],
        'type_params_bounds': ['Object'],
        'type_params_defaults': ['dynamic'],
        'libraryUri': 'file:///test.dart',
        'method': 'foo',
        'tokenPos': 123,
        'isStatic': true,
        'klass': 'MyClass',
        'scriptUri': 'file:///test.dart',
      };

      final result = evaluator.testBuildCompileParams(
        expression: 'x + 1',
        isolateId: 'isolates/1',
        scope: scope,
      );

      expect(result['isolateId'], equals('isolates/1'));
      expect(result['expression'], equals('x + 1'));
      expect(result['definitions'], equals(['x']));
      expect(result['definitionTypes'], equals(['int']));
      expect(result['klass'], equals('MyClass'));
      expect(result['scriptUri'], equals('file:///test.dart'));
    });

    test('evaluate falls back when no external compiler is present', () async {
      final evaluator = TestExpressionEvaluator();
      final response = await evaluator.evaluate(
        json_rpc.Parameters('evaluate', {
          'isolateId': 'isolates/1',
          'targetId': 'targets/1',
          'expression': '1 + 2',
        }),
      );

      expect(response, {
        'type': 'InstanceRef',
        'valueAsString': 'fallback:evaluate:1 + 2',
      });
    });

    test(
      'evaluateInFrame falls back when no external compiler is present',
      () async {
        final evaluator = TestExpressionEvaluator();
        final response = await evaluator.evaluateInFrame(
          json_rpc.Parameters('evaluateInFrame', {
            'isolateId': 'isolates/1',
            'frameIndex': 0,
            'expression': 'myVar',
          }),
        );

        expect(response, {
          'type': 'InstanceRef',
          'valueAsString': 'fallback:evaluateInFrame:myVar',
        });
      },
    );
  });
}
