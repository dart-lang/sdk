// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:dart_runtime_service_dds/dart_runtime_service_dds.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' as vm;
import 'package:vm_service/vm_service_io.dart';
import 'package:web_socket_channel/io.dart';

/// Kernel bytes which cause the mock VM's `_evaluateCompiledExpression` to
/// return a `null` instance.
const nullResultKernelBytes = 'null_result_kernel_bytes';

/// Kernel bytes which cause the mock VM's `_evaluateCompiledExpression` to
/// return an expired [vm.Sentinel].
const sentinelResultKernelBytes = 'sentinel_result_kernel_bytes';

/// An expression which the test `compileExpression` service compiles to
/// [sentinelResultKernelBytes].
const sentinelResultExpression = 'expiredObject';

class MockVmService {
  MockVmService._(this.server, this.port);

  final HttpServer server;
  final int port;
  final clients = <json_rpc.Peer>[];

  Uri get uri => Uri.parse('http://localhost:$port/');

  static Future<MockVmService> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final mock = MockVmService._(server, server.port);

    server.transform(WebSocketTransformer()).listen((webSocket) {
      final channel = IOWebSocketChannel(webSocket);
      final peer = json_rpc.Peer(channel.cast<String>());
      mock.clients.add(peer);

      peer.registerMethod('getVM', (json_rpc.Parameters params) {
        return <String, Object?>{
          'type': 'VM',
          'name': 'mock-vm',
          'isolates': <Map<String, Object?>>[],
        };
      });

      peer.registerMethod('_yieldControlToDDS', (json_rpc.Parameters params) {
        return vm.Success().toJson();
      });

      peer.registerMethod('streamListen', (json_rpc.Parameters params) {
        return vm.Success().toJson();
      });

      peer.registerMethod('evaluate', (json_rpc.Parameters params) {
        return vm.InstanceRef(
          id: 'objects/1',
          kind: vm.InstanceKind.kString,
          valueAsString: 'evaluated:${params['expression'].asString}',
        ).toJson();
      });

      peer.registerMethod('evaluateInFrame', (json_rpc.Parameters params) {
        final frameIndex = params['frameIndex'].asInt;
        final expr = params['expression'].asString;
        return vm.InstanceRef(
          id: 'objects/2',
          kind: vm.InstanceKind.kString,
          valueAsString: 'evaluatedInFrame:$frameIndex:$expr',
        ).toJson();
      });

      peer.registerMethod('_buildExpressionEvaluationScope', (
        json_rpc.Parameters params,
      ) {
        final isolateId = params['isolateId'].asString;
        if (isolateId == 'isolates/exited') {
          return vm.Sentinel(
            kind: vm.SentinelKind.kCollected,
            valueAsString: '<collected>',
          ).toJson();
        }
        final targetId = params['targetId'].asStringOr('');
        if (targetId == 'targets/invalid') {
          RpcException.invalidParams.throwExceptionWithDetails(
            details: 'Invalid targetId',
          );
        }
        return <String, Object?>{
          'isolateId': isolateId,
          'klass': 'MyClass',
          'libraryUri': 'file:///test.dart',
          'param_names': <String>['x'],
          'param_types': <String>['int'],
          'tokenPos': 123,
        };
      });

      peer.registerMethod('_evaluateCompiledExpression', (
        json_rpc.Parameters params,
      ) {
        final kernelBytes = params['kernelBytes'].asString;
        return switch (kernelBytes) {
          nullResultKernelBytes => vm.InstanceRef(
            id: 'objects/null',
            kind: vm.InstanceKind.kNull,
            valueAsString: 'null',
          ).toJson(),
          sentinelResultKernelBytes => vm.Sentinel(
            kind: vm.SentinelKind.kExpired,
            valueAsString: '<expired>',
          ).toJson(),
          _ => vm.InstanceRef(
            id: 'objects/3',
            kind: vm.InstanceKind.kString,
            valueAsString: 'compiled:$kernelBytes',
          ).toJson(),
        };
      });

      peer.listen();
    });

    return mock;
  }

  Future<void> shutdown() async {
    for (final client in clients) {
      await client.close();
    }
    await server.close(force: true);
  }
}

void main() {
  group('DdsExpressionEvaluator:', () {
    late MockVmService mockVmService;
    late DartRuntimeService ddsService;
    late vm.VmService ddsClient;

    setUp(() async {
      mockVmService = await MockVmService.start();

      ddsService = await DartRuntimeService.initialize(
        config: const DartRuntimeServiceOptions(),
        backendBuilder: (frontend) =>
            DartRuntimeServiceDdsBackend(mockVmService.uri, frontend: frontend),
      );

      ddsClient = await vmServiceConnectUri(ddsService.uri.toString());
    });

    tearDown(() async {
      await ddsClient.dispose();
      await ddsService.shutdown();
      await mockVmService.shutdown();
    });

    test(
      'evaluate forwards to VM service when no compiler registered',
      () async {
        final result = await ddsClient.evaluate(
          'isolates/1',
          'targets/1',
          '1 + 2',
        );
        expect(result, isA<vm.InstanceRef>());
        expect((result as vm.InstanceRef).valueAsString, 'evaluated:1 + 2');
      },
    );

    test(
      'evaluateInFrame forwards to VM service when no compiler registered',
      () async {
        final result = await ddsClient.evaluateInFrame(
          'isolates/1',
          0,
          'myVar',
        );
        expect(result, isA<vm.InstanceRef>());
        expect(
          (result as vm.InstanceRef).valueAsString,
          'evaluatedInFrame:0:myVar',
        );
      },
    );

    test(
      'evaluate routes through registered compileExpression service',
      () async {
        await ddsClient.registerService(
          'compileExpression',
          'ExternalCompiler',
        );
        ddsClient.registerServiceCallback('compileExpression', (params) async {
          return <String, Object?>{
            'result': <String, Object?>{'kernelBytes': 'base64_encoded_bytes'},
          };
        });

        final result = await ddsClient.evaluate(
          'isolates/1',
          'targets/1',
          '1 + 2',
        );
        expect(result, isA<vm.InstanceRef>());
        expect(
          (result as vm.InstanceRef).valueAsString,
          'compiled:base64_encoded_bytes',
        );
      },
    );

    group('with a registered compileExpression service', () {
      setUp(() async {
        await ddsClient.registerService(
          'compileExpression',
          'ExternalCompiler',
        );
        ddsClient.registerServiceCallback('compileExpression', (params) async {
          return <String, Object?>{
            'result': <String, Object?>{
              'kernelBytes': params['expression'] == sentinelResultExpression
                  ? sentinelResultKernelBytes
                  : nullResultKernelBytes,
            },
          };
        });
      });

      final isNullInstanceRef = isA<vm.InstanceRef>().having(
        (r) => r.kind,
        'kind',
        vm.InstanceKind.kNull,
      );

      test('evaluate completes when the result is null', () async {
        expect(
          await ddsClient.evaluate('isolates/1', 'targets/1', 'voidMethod()'),
          isNullInstanceRef,
        );
      });

      test('evaluateInFrame completes when the result is null', () async {
        expect(
          await ddsClient.evaluateInFrame('isolates/1', 0, 'voidMethod()'),
          isNullInstanceRef,
        );
      });

      test('evaluate returns Sentinel results', () async {
        await expectLater(
          ddsClient.evaluate(
            'isolates/1',
            'targets/1',
            sentinelResultExpression,
          ),
          throwsA(
            isA<vm.SentinelException>().having(
              (e) => e.sentinel.kind,
              'sentinel.kind',
              vm.SentinelKind.kExpired,
            ),
          ),
        );
      });

      test(
        'evaluate wraps buildScope RPCError in kExpressionCompilationError',
        () async {
          await expectLater(
            ddsClient.evaluate('isolates/1', 'targets/invalid', '1 + 1'),
            throwsA(
              isA<vm.RPCError>()
                  .having(
                    (e) => e.code,
                    'code',
                    vm.RPCErrorKind.kExpressionCompilationError.code,
                  )
                  .having((e) => e.details, 'details', 'Invalid targetId'),
            ),
          );
        },
      );

      test('evaluate returns Sentinel when buildScope throws '
          'SentinelException for exited isolate', () async {
        await expectLater(
          ddsClient.evaluate('isolates/exited', 'targets/1', '1 + 1'),
          throwsA(
            isA<vm.SentinelException>().having(
              (e) => e.sentinel.kind,
              'sentinel.kind',
              vm.SentinelKind.kCollected,
            ),
          ),
        );
      });
    });
  });
}
