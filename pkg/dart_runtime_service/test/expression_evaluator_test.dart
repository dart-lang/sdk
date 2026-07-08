// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:test/test.dart';

base class TestExpressionEvaluator extends ExpressionEvaluator {
  TestExpressionEvaluator()
    : super(clients: UnmodifiableClientNamedLookup(ClientNamedLookup()));

  Map<String, Object?> testBuildCompileParams({
    required String isolateId,
    required String expression,
    required Map<String, Object?> scope,
  }) => buildCompileParams(
    isolateId: isolateId,
    expression: expression,
    scope: scope,
  );

  @override
  Future<RpcResponse> evaluate(json_rpc.Parameters parameters) =>
      throw UnimplementedError();

  @override
  Future<RpcResponse> evaluateInFrame(json_rpc.Parameters parameters) =>
      throw UnimplementedError();
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
        isolateId: 'isolates/1',
        expression: 'x + 1',
        scope: scope,
      );

      expect(result['isolateId'], equals('isolates/1'));
      expect(result['expression'], equals('x + 1'));
      expect(result['definitions'], equals(['x']));
      expect(result['definitionTypes'], equals(['int']));
      expect(result['klass'], equals('MyClass'));
      expect(result['scriptUri'], equals('file:///test.dart'));
    });
  });
}
