// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dap_adapters/dap_adapters.dart';
import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:dart_runtime_service_dds/dart_runtime_service_dds.dart';
import 'package:dds_service_extensions/dap.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' as vm;
import 'package:vm_service/vm_service_io.dart';
import 'package:web_socket_channel/io.dart';

const _kClassId = 'classes/1';
const _kClassName = 'MyClass';
const _kIsolateId = 'isolates/1';
const _kIsolateName = 'main';
const _kIsolateNumber = '1';
const _kMainFileName = 'main.dart';
const _kMainFilePath = '/file/to/main.dart';
const _kMockVmName = 'mock-vm';
const _kObjectId = 'objects/1';
const _kResponseType = 'response';
const _kSetBreakpointsCommand = 'setBreakpoints';
const _kStringObjectId = 'objects/2';
const _kThreadIdKey = 'id';
const _kThreadIsolateIdKey = 'isolateId';
const _kThreadNameKey = 'name';
const _kThreadsKey = 'threads';
const _kValueVariableName = 'value';
const _kVariablesCommand = 'variables';
const _kVmServiceMajorVersion = 4;
const _kVmServiceMinorVersion = 0;
const _kVmServiceProtocolName = 'VM Service';
const _kFirstBreakpointLine = 20;
const _kSecondBreakpointLine = 30;
const _kExpectedThreadId = 1;

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
        return vm
            .VM(
              name: _kMockVmName,
              operatingSystem: Platform.operatingSystem,
              isolates: <vm.IsolateRef>[
                vm.IsolateRef(
                  id: _kIsolateId,
                  name: _kIsolateName,
                  number: _kIsolateNumber,
                ),
              ],
            )
            .toJson();
      });

      peer.registerMethod('getIsolate', (json_rpc.Parameters params) {
        return vm.Isolate(
          id: _kIsolateId,
          name: _kIsolateName,
          number: _kIsolateNumber,
          runnable: true,
          pauseEvent: vm.Event(
            isolate: vm.IsolateRef(
              id: _kIsolateId,
              name: _kIsolateName,
              number: _kIsolateNumber,
            ),
            kind: vm.EventKind.kPauseBreakpoint,
            timestamp: 0,
          ),
          libraries: <vm.LibraryRef>[],
          breakpoints: <vm.Breakpoint>[],
        ).toJson();
      });

      peer.registerMethod('_yieldControlToDDS', (json_rpc.Parameters params) {
        return vm.Success().toJson();
      });

      peer.registerMethod('streamListen', (json_rpc.Parameters params) {
        return vm.Success().toJson();
      });

      peer.registerMethod('streamCancel', (json_rpc.Parameters params) {
        return vm.Success().toJson();
      });

      peer.registerMethod('getSupportedProtocols', (
        json_rpc.Parameters params,
      ) {
        return vm.ProtocolList(
          protocols: <vm.Protocol>[
            vm.Protocol(
              protocolName: _kVmServiceProtocolName,
              major: _kVmServiceMajorVersion,
              minor: _kVmServiceMinorVersion,
            ),
          ],
        ).toJson();
      });

      peer.registerMethod('getFlagList', (json_rpc.Parameters params) {
        return vm.FlagList(
          flags: <vm.Flag>[
            vm.Flag(name: 'pause_isolates_on_start', valueAsString: 'true'),
            vm.Flag(name: 'pause_isolates_on_exit', valueAsString: 'true'),
          ],
        ).toJson();
      });

      peer.registerMethod('setFlag', (json_rpc.Parameters params) {
        return vm.Success().toJson();
      });

      peer.registerMethod('setIsolatePauseMode', (json_rpc.Parameters params) {
        return vm.Success().toJson();
      });

      peer.registerMethod('setLibraryDebuggable', (json_rpc.Parameters params) {
        return vm.Success().toJson();
      });

      peer.registerMethod('getObject', (json_rpc.Parameters params) {
        return vm.Instance(
          id: _kObjectId,
          kind: vm.InstanceKind.kPlainInstance,
          classRef: vm.ClassRef(id: _kClassId, name: _kClassName),
          fields: <vm.BoundField>[],
        ).toJson();
      });

      peer.registerMethod('invoke', (json_rpc.Parameters params) {
        return vm.InstanceRef(
          id: _kStringObjectId,
          kind: vm.InstanceKind.kString,
          valueAsString: _kClassName,
        ).toJson();
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
  group('DapHandler', () {
    late MockVmService mockVmService;
    late DartRuntimeService ddsService;
    late vm.VmService ddsClient;
    var nextSeq = 1;

    setUp(() async {
      nextSeq = 1;
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

    Future<DapResponse> sendDapRequest(
      String command, [
      Object? arguments,
    ]) async {
      final result = await ddsClient.sendDapRequest(
        jsonEncode(
          Request(arguments: arguments, command: command, seq: nextSeq++),
        ),
      );

      expect(result.dapResponse, isNotNull);
      expect(result.dapResponse.type, _kResponseType);
      expect(result.dapResponse.message, isNull);
      expect(result.dapResponse.success, isTrue);
      expect(result.dapResponse.command, command);

      return result;
    }

    test('responds to DAP message and broadcasts DAP stream events', () async {
      final dapEvents = <vm.Event>[];
      final subscription = ddsClient.onDAPEvent.listen(dapEvents.add);
      await ddsClient.streamListen(DapEventStreams.kDAP);

      final breakpointArguments = SetBreakpointsArguments(
        breakpoints: <SourceBreakpoint>[
          SourceBreakpoint(line: _kFirstBreakpointLine),
          SourceBreakpoint(line: _kSecondBreakpointLine),
        ],
        source: Source(name: _kMainFileName, path: _kMainFilePath),
      );

      final result = await sendDapRequest(
        _kSetBreakpointsCommand,
        breakpointArguments,
      );
      final response = SetBreakpointsResponseBody.fromMap(
        result.dapResponse.body! as Map<String, Object?>,
      );
      expect(response.breakpoints, hasLength(2));
      expect(response.breakpoints[0].verified, isFalse);
      expect(response.breakpoints[1].verified, isFalse);

      expect(dapEvents, isNotEmpty);
      expect(
        dapEvents.map((e) => e.kind),
        everyElement(DapEventKind.kDAPEvent),
      );
      expect(dapEvents.map((e) => e.dapData.event), contains('initialized'));

      await subscription.cancel();
    });

    test('maps between variableReferences and InstanceRefs', () async {
      final createVariableResult = await sendDapRequest(
        Command.createVariableForInstance,
        <String, Object?>{
          Parameters.isolateId: _kIsolateId,
          Parameters.instanceId: _kObjectId,
        },
      );
      final createVariablesBody =
          createVariableResult.dapResponse.body! as Map<String, Object?>;
      final variablesReference =
          createVariablesBody[Parameters.variablesReference] as int;

      final getInstanceResult = await sendDapRequest(
        Command.getVariablesInstanceId,
        <String, Object?>{Parameters.variablesReference: variablesReference},
      );
      final getInstanceRefBody =
          getInstanceResult.dapResponse.body! as Map<String, Object?>;
      final mappedInstanceId =
          getInstanceRefBody[Parameters.instanceId] as String;
      expect(mappedInstanceId, _kObjectId);

      final variablesResult = await sendDapRequest(
        _kVariablesCommand,
        VariablesArguments(variablesReference: variablesReference),
      );
      final variablesBody = VariablesResponseBody.fromMap(
        variablesResult.dapResponse.body! as Map<String, Object?>,
      );
      expect(variablesBody.variables, hasLength(1));
      final variable = variablesBody.variables.single;
      expect(variable.name, _kValueVariableName);
      expect(variable.variablesReference, isPositive);
      expect(variable.value, _kClassName);
    });

    test('includes Isolate IDs in Threads', () async {
      final threadsResult = await sendDapRequest(Command.threads);
      final threadsBody =
          threadsResult.dapResponse.body! as Map<String, Object?>;

      final threads = threadsBody[_kThreadsKey] as List<Object?>;
      expect(threads, hasLength(1));
      final thread = threads.first as Map<String, Object?>;
      expect(thread, <String, Object?>{
        _kThreadIdKey: _kExpectedThreadId,
        _kThreadNameKey: _kIsolateName,
        _kThreadIsolateIdKey: _kIsolateId,
      });
    });

    test(
      'concurrent initial sendDapRequest calls initialize the adapter once',
      () async {
        final dapEvents = <vm.Event>[];
        final subscription = ddsClient.onDAPEvent.listen(dapEvents.add);
        addTearDown(subscription.cancel);
        await ddsClient.streamListen(DapEventStreams.kDAP);

        final results = await Future.wait(<Future<DapResponse>>[
          sendDapRequest(Command.threads),
          sendDapRequest(Command.threads),
        ]);

        for (final result in results) {
          final threadsBody = result.dapResponse.body! as Map<String, Object?>;
          final threads = threadsBody[_kThreadsKey] as List<Object?>;
          expect(threads, hasLength(1));
        }

        expect(
          dapEvents.where((e) => e.dapData.event == 'initialized'),
          hasLength(1),
        );
        // One client connection from ddsClient and one from the single
        // DdsHostedAdapter initialization.
        expect(ddsService.clients, hasLength(2));
      },
    );
  });
}
