// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_runtime_service_dds/dart_runtime_service_dds.dart';
import 'package:dart_runtime_service_dds/src/dds_cli_entrypoint.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:test/fake.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' as vm;
import 'package:web_socket_channel/io.dart';

const _acceptHeader = 'accept';
const _clientIdParam = 'sseClientId';
const _dataPrefix = 'data: ';
const _ddsUriKey = 'ddsUri';
const _eventStreamMimeType = 'text/event-stream';
const _firstClientId = 'client-1';
const _firstMessageId = '0';
const _getVmMethod = 'getVM';
const _idKey = 'id';
const _jsonRpcKey = 'jsonrpc';
const _jsonRpcVersion = '2.0';
const _messageIdParam = 'messageId';
const _methodKey = 'method';
const _mockVmName = 'mock-vm';
const _nameKey = 'name';
const _requestId = '1';
const _resultKey = 'result';
const _secondClientId = 'client-2';
const _startedState = 'started';
const _stateKey = 'state';
const _vmType = 'VM';

class _FakeStderr extends Fake implements Stdout {
  final buffer = StringBuffer();

  @override
  void writeln([Object? object = '']) {
    buffer.writeln(object);
  }

  @override
  Future<void> close() async {}
}

class _MockVmService {
  _MockVmService._(this.server);

  final HttpServer server;
  final clients = <json_rpc.Peer>[];

  Uri get uri => Uri.parse('http://localhost:${server.port}/');

  static Future<_MockVmService> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final mock = _MockVmService._(server);

    server.transform(WebSocketTransformer()).listen((webSocket) {
      final peer = json_rpc.Peer(IOWebSocketChannel(webSocket).cast<String>())
        ..registerMethod(
          _getVmMethod,
          (_) => <String, Object?>{
            'type': _vmType,
            _nameKey: _mockVmName,
            'isolates': <Map<String, Object?>>[],
          },
        )
        ..registerMethod('_yieldControlToDDS', (_) => vm.Success().toJson())
        ..registerMethod('streamListen', (_) => vm.Success().toJson())
        ..registerMethod(
          'getFlagList',
          (_) => vm.FlagList(flags: <vm.Flag>[]).toJson(),
        )
        ..listen();
      mock.clients.add(peer);
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

Future<Uri> _launchDdsFromCli(
  _MockVmService mockVmService, {
  required bool disableServiceAuthCodes,
}) async {
  final fakeStderr = _FakeStderr();
  await IOOverrides.runZoned(
    () => runDartDevelopmentServiceFromCLI(<String>[
      '--${DartDevelopmentServiceOptions.vmServiceUriOption}='
          '${mockVmService.uri}',
      if (disableServiceAuthCodes)
        '--${DartDevelopmentServiceOptions.disableServiceAuthCodesFlag}',
    ]),
    exit: (code) => fail(
      'runDartDevelopmentServiceFromCLI exited with $code: '
      '${fakeStderr.buffer}',
    ),
    stderr: () => fakeStderr,
  );

  final launchInfo =
      json.decode(fakeStderr.buffer.toString().trim()) as Map<String, Object?>;
  expect(launchInfo[_stateKey], _startedState);
  return Uri.parse(launchInfo[_ddsUriKey]! as String);
}

Future<void> _verifySseGetVm(Uri ddsHttpUri, {required String clientId}) async {
  final sseEndpoint = ddsHttpUri.resolve(
    DartRuntimeServiceDdsBackend.kSseHandlerPath,
  );
  final client = HttpClient();
  try {
    final connectUri = sseEndpoint.replace(
      queryParameters: <String, String>{_clientIdParam: clientId},
    );
    final getRequest = await client.getUrl(connectUri);
    getRequest.headers.set(_acceptHeader, _eventStreamMimeType);
    final getResponse = await getRequest.close();
    expect(getResponse.statusCode, HttpStatus.ok);

    final firstEvent = Completer<Map<String, Object?>>();
    final subscription = getResponse
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (!line.startsWith(_dataPrefix) || firstEvent.isCompleted) {
            return;
          }
          final encodedPayload = line.substring(_dataPrefix.length);
          final payload = json.decode(encodedPayload) as String;
          final message = json.decode(payload) as Map<String, Object?>;
          firstEvent.complete(message);
        });

    final postUri = sseEndpoint.replace(
      queryParameters: <String, String>{
        _clientIdParam: clientId,
        _messageIdParam: _firstMessageId,
      },
    );
    final postRequest = await client.postUrl(postUri);
    postRequest.write(
      json.encode(
        json.encode(<String, Object?>{
          _jsonRpcKey: _jsonRpcVersion,
          _idKey: _requestId,
          _methodKey: _getVmMethod,
        }),
      ),
    );
    final postResponse = await postRequest.close();
    await postResponse.drain<void>();
    expect(postResponse.statusCode, HttpStatus.ok);

    final responseMessage = await firstEvent.future;
    expect(responseMessage[_idKey], _requestId);
    final result = responseMessage[_resultKey] as Map<String, Object?>?;
    expect(result, isNotNull);
    expect(result![_nameKey], _mockVmName);

    await subscription.cancel();
  } finally {
    client.close(force: true);
  }
}

void main() {
  group('runDartDevelopmentServiceFromCLI SSE handler', () {
    late _MockVmService mockVmService;

    setUp(() async {
      mockVmService = await _MockVmService.start();
    });

    tearDown(() async {
      await mockVmService.shutdown();
    });

    test(
      'mounts \$debugHandler and serves multiple SSE clients with auth codes',
      () async {
        final ddsHttpUri = await _launchDdsFromCli(
          mockVmService,
          disableServiceAuthCodes: false,
        );
        expect(ddsHttpUri.pathSegments.where((s) => s.isNotEmpty), isNotEmpty);

        await _verifySseGetVm(ddsHttpUri, clientId: _firstClientId);
        await _verifySseGetVm(ddsHttpUri, clientId: _secondClientId);
      },
    );

    test('mounts \$debugHandler and serves multiple SSE clients without auth '
        'codes', () async {
      final ddsHttpUri = await _launchDdsFromCli(
        mockVmService,
        disableServiceAuthCodes: true,
      );
      expect(ddsHttpUri.pathSegments.where((s) => s.isNotEmpty), isEmpty);

      await _verifySseGetVm(ddsHttpUri, clientId: _firstClientId);
      await _verifySseGetVm(ddsHttpUri, clientId: _secondClientId);
    });
  });
}
