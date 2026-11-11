// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:dart_runtime_service/dart_runtime_service_io.dart';
import 'package:dart_runtime_service/src/dart_runtime_service_rpcs.dart';
import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import 'utils/mocks.dart';
import 'utils/utilities.dart';

const kDetailsKey = 'details';

final class _TestRpcBackend extends FakeDartRuntimeServiceBackend {
  _TestRpcBackend({
    required super.frontend,
    List<RpcHandlerWithParameters> fallbacks =
        const <RpcHandlerWithParameters>[],
    List<ServiceRpcHandler> rpcs = const <ServiceRpcHandler>[],
  }) : fallbacks = UnmodifiableListView(fallbacks),
       rpcs = UnmodifiableListView(rpcs);

  @override
  final UnmodifiableListView<RpcHandlerWithParameters> fallbacks;

  @override
  final UnmodifiableListView<ServiceRpcHandler> rpcs;
}

final class _ThrowingDevFSCollection extends DevelopmentFileSystemCollection {
  @override
  List<String> get fsNames => const <String>[];

  @override
  Future<void> cleanup() async {}

  @override
  Future<DevelopmentFileSystem> createFileSystem({required String name}) {
    throw const PathAccessException(
      '/data/user/0/com.example/code_cache',
      OSError('Permission denied', 13),
      'Creation of temporary directory failed',
    );
  }

  @override
  Future<void> deleteFileSystem({required String name}) async {}

  @override
  DevelopmentFileSystem getFileSystem({required String name}) {
    RpcException.fileSystemDoesNotExist.throwException();
  }
}

void main() {
  group('$DartRuntimeServiceRpcs:', () {
    test('getClientName + setClientName', () async {
      final service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(enableLogging: true),
      );

      final client = await vmServiceConnectUri(service.uri.toString());
      addTearDown(client.dispose);
      var response = await client.getClientName();
      final defaultName = response.name;

      await client.setClientName('foobar');
      response = await client.getClientName();
      expect(response.name, 'foobar');

      await client.setClientName();
      response = await client.getClientName();
      expect(response.name, defaultName);
    });

    test('uncaught non-RPC exception in registered RPC returns kInternalError '
        'with details', () async {
      const kThrowingRpc = 'throwingRpc';
      const kErrorMessage = 'unexpected failure in RPC';

      final service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(),
        backendBuilder: (frontend) => _TestRpcBackend(
          frontend: frontend,
          rpcs: <ServiceRpcHandler>[
            (
              kThrowingRpc,
              (json_rpc.Parameters _) {
                throw StateError(kErrorMessage);
              },
            ),
          ],
        ),
      );

      final client = await vmServiceConnectUri(service.uri.toString());
      addTearDown(client.dispose);

      await expectLater(
        client.callMethod(kThrowingRpc),
        throwsA(
          isA<RPCError>()
              .having((e) => e.callingMethod, 'callingMethod', kThrowingRpc)
              .having((e) => e.code, 'code', RPCErrorKind.kInternalError.code)
              .having(
                (e) => e.message,
                'message',
                RpcException.internalError.message,
              )
              .having(
                (e) => e.details,
                'details',
                allOf(
                  startsWith(
                    '$kThrowingRpc: Unexpected exception: '
                    'Bad state: $kErrorMessage\n',
                  ),
                  contains('dart_runtime_service_rpcs_test.dart'),
                ),
              ),
        ),
      );
    });

    test(
      'uncaught non-RPC exception in backend fallback returns kInternalError '
      'with details while methodNotFound chains fallbacks',
      () async {
        const kHandledMethod = 'handledByFirstFallback';
        const kThrowingFallback = 'throwingFallback';
        const kUnknownMethod = 'unknownMethod';
        const kErrorMessage = 'bad fallback format';

        final service = await createDartRuntimeServiceForTest(
          config: const DartRuntimeServiceOptions(),
          backendBuilder: (frontend) => _TestRpcBackend(
            frontend: frontend,
            fallbacks: <RpcHandlerWithParameters>[
              (json_rpc.Parameters parameters) {
                if (parameters.method == kHandledMethod) {
                  return Success().toJson();
                }
                RpcException.methodNotFound.throwException();
              },
              (json_rpc.Parameters parameters) {
                if (parameters.method == kThrowingFallback) {
                  throw const FormatException(kErrorMessage);
                }
                RpcException.methodNotFound.throwException();
              },
            ],
          ),
        );

        final client = await vmServiceConnectUri(service.uri.toString());
        addTearDown(client.dispose);

        final response = await client.callMethod(kHandledMethod);
        expect(response, isA<Success>());

        await expectLater(
          client.callMethod(kThrowingFallback),
          throwsA(
            isA<RPCError>()
                .having(
                  (e) => e.callingMethod,
                  'callingMethod',
                  kThrowingFallback,
                )
                .having((e) => e.code, 'code', RPCErrorKind.kInternalError.code)
                .having(
                  (e) => e.message,
                  'message',
                  RpcException.internalError.message,
                )
                .having(
                  (e) => e.details,
                  'details',
                  allOf(
                    startsWith(
                      '$kThrowingFallback: Unexpected exception: '
                      'FormatException: $kErrorMessage\n',
                    ),
                    contains('dart_runtime_service_rpcs_test.dart'),
                  ),
                ),
          ),
        );

        await expectLater(
          client.callMethod(kUnknownMethod),
          throwsA(
            isA<RPCError>().having(
              (e) => e.code,
              'code',
              RPCErrorKind.kMethodNotFound.code,
            ),
          ),
        );
      },
    );

    test('uncaught non-RPC exception in service extension forwarder returns '
        'kInternalError with details', () async {
      const kRegisterServiceRpc = 'registerService';
      const kServiceKey = 'service';
      const kAliasKey = 'alias';
      const kServiceName = 'badReturn';
      const kInvalidResponse = 'invalid';

      final service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(),
      );

      final controller = StreamChannelController<String>();
      final providerPeer = json_rpc.Peer(controller.local)
        ..registerMethod(
          kServiceName,
          (json_rpc.Parameters _) => kInvalidResponse,
        );
      unawaited(providerPeer.listen());
      addTearDown(providerPeer.close);

      final providerClient = service.addArtificialClient(
        connection: controller.foreign,
        name: 'badServiceProvider',
      );
      await providerPeer.sendRequest(kRegisterServiceRpc, <String, Object?>{
        kServiceKey: kServiceName,
        kAliasKey: kServiceName,
      });

      final forwardedMethod = '${providerClient.namespace}.$kServiceName';
      final client = await vmServiceConnectUri(service.uri.toString());
      addTearDown(client.dispose);

      await expectLater(
        client.callMethod(forwardedMethod),
        throwsA(
          isA<RPCError>()
              .having((e) => e.callingMethod, 'callingMethod', forwardedMethod)
              .having((e) => e.code, 'code', RPCErrorKind.kInternalError.code)
              .having(
                (e) => e.message,
                'message',
                RpcException.internalError.message,
              )
              .having(
                (e) => e.data?[kDetailsKey],
                kDetailsKey,
                allOf(
                  startsWith('$forwardedMethod: Unexpected exception: '),
                  contains("type 'String' is not a subtype of type"),
                  contains('Map<String, Object?>'),
                ),
              ),
        ),
      );
    });

    test(
      'intentional RpcException and RPCError preserve code, message, and data',
      () async {
        const kRpcExceptionMethod = 'rpcExceptionMethod';
        const kRpcErrorMethod = 'rpcErrorMethod';
        const kFallbackRpcErrorMethod = 'fallbackRpcErrorMethod';
        const kRequiredParam = 'requiredParam';
        const kCustomDetails = 'custom error details';

        final service = await createDartRuntimeServiceForTest(
          config: const DartRuntimeServiceOptions(),
          backendBuilder: (frontend) => _TestRpcBackend(
            frontend: frontend,
            fallbacks: <RpcHandlerWithParameters>[
              (json_rpc.Parameters parameters) {
                if (parameters.method == kFallbackRpcErrorMethod) {
                  throw RPCError(
                    kFallbackRpcErrorMethod,
                    RPCErrorKind.kFeatureDisabled.code,
                    RpcException.featureDisabled.message,
                    <String, Object?>{kDetailsKey: kCustomDetails},
                  );
                }
                RpcException.methodNotFound.throwException();
              },
            ],
            rpcs: <ServiceRpcHandler>[
              (
                kRpcExceptionMethod,
                (json_rpc.Parameters parameters) {
                  parameters[kRequiredParam].asString;
                  RpcException.fileSystemAlreadyExists
                      .throwExceptionWithDetails(details: kCustomDetails);
                },
              ),
              (
                kRpcErrorMethod,
                () {
                  throw RPCError(
                    kRpcErrorMethod,
                    RPCErrorKind.kCustomStreamDoesNotExist.code,
                    'Custom stream does not exist',
                    <String, Object?>{kDetailsKey: kCustomDetails},
                  );
                },
              ),
            ],
          ),
        );

        final client = await vmServiceConnectUri(service.uri.toString());
        addTearDown(client.dispose);

        await expectLater(
          client.callMethod(kRpcExceptionMethod),
          throwsA(
            isA<RPCError>().having(
              (e) => e.code,
              'code',
              RPCErrorKind.kInvalidParams.code,
            ),
          ),
        );

        await expectLater(
          client.callMethod(
            kRpcExceptionMethod,
            args: <String, Object?>{kRequiredParam: 'value'},
          ),
          throwsA(
            isA<RPCError>()
                .having(
                  (e) => e.code,
                  'code',
                  RpcException.fileSystemAlreadyExists.code,
                )
                .having(
                  (e) => e.message,
                  'message',
                  RpcException.fileSystemAlreadyExists.message,
                )
                .having((e) => e.details, 'details', kCustomDetails),
          ),
        );

        await expectLater(
          client.callMethod(kRpcErrorMethod),
          throwsA(
            isA<RPCError>()
                .having(
                  (e) => e.code,
                  'code',
                  RPCErrorKind.kCustomStreamDoesNotExist.code,
                )
                .having(
                  (e) => e.message,
                  'message',
                  'Custom stream does not exist',
                )
                .having((e) => e.details, 'details', kCustomDetails),
          ),
        );

        await expectLater(
          client.callMethod(kFallbackRpcErrorMethod),
          throwsA(
            isA<RPCError>()
                .having(
                  (e) => e.code,
                  'code',
                  RPCErrorKind.kFeatureDisabled.code,
                )
                .having(
                  (e) => e.message,
                  'message',
                  RpcException.featureDisabled.message,
                )
                .having((e) => e.details, 'details', kCustomDetails),
          ),
        );
      },
    );

    test(
      'DevFS _createDevFS surfaces FileSystemException as kInternalError with '
      'details',
      () async {
        const kCreateDevFS = '_createDevFS';
        const kFsNameKey = 'fsName';
        const kFsName = 'my_dev_fs';

        final devFs = DevFS(fileSystems: _ThrowingDevFSCollection());
        final service = await createDartRuntimeServiceForTest(
          config: const DartRuntimeServiceOptions(),
          backendBuilder: (frontend) =>
              _TestRpcBackend(frontend: frontend, rpcs: devFs.rpcs),
        );

        final client = await vmServiceConnectUri(service.uri.toString());
        addTearDown(client.dispose);

        await expectLater(
          client.callMethod(
            kCreateDevFS,
            args: <String, Object?>{kFsNameKey: kFsName},
          ),
          throwsA(
            isA<RPCError>()
                .having((e) => e.callingMethod, 'callingMethod', kCreateDevFS)
                .having((e) => e.code, 'code', RPCErrorKind.kInternalError.code)
                .having(
                  (e) => e.message,
                  'message',
                  RpcException.internalError.message,
                )
                .having(
                  (e) => e.details,
                  'details',
                  allOf(
                    startsWith(
                      '$kCreateDevFS: Unexpected exception: '
                      'PathAccessException: '
                      'Creation of temporary directory failed',
                    ),
                    contains("path = '/data/user/0/com.example/code_cache'"),
                    contains('Permission denied'),
                  ),
                ),
          ),
        );
      },
    );
  });
}
