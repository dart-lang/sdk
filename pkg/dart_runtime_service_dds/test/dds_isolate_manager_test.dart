// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:dart_runtime_service_dds/src/dds_isolate_manager.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/stream_channel.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' as vm;

final class FakeVmService extends Fake implements vm.VmService {
  final isolates = <String, vm.Isolate>{};
  final resumedIsolates = <String>[];

  @override
  Future<vm.VM> getVM() async => vm.VM(
    isolates: [
      for (final iso in isolates.values)
        vm.IsolateRef(id: iso.id, name: iso.name, number: iso.number),
    ],
  );

  @override
  Future<vm.Isolate> getIsolate(String isolateId) async =>
      isolates[isolateId] ??
      (throw vm.SentinelException.parse('Sentinel', const <String, Object?>{}));

  @override
  Future<vm.Response> callMethod(
    String method, {
    Map<String, dynamic>? args,
    String? isolateId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<vm.Success> resume(
    String isolateId, {
    int? frameIndex,
    String? step,
  }) async {
    resumedIsolates.add(isolateId);
    if (isolates[isolateId] case final isolate?) {
      isolate.pauseEvent = vm.Event(
        kind: vm.EventKind.kResume,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }
    return vm.Success();
  }
}

final class FakeBackend extends Fake
    implements DartRuntimeServiceBackend<IsolateManager> {
  @override
  ExpressionEvaluator? get expressionEvaluator => null;

  @override
  UnmodifiableListView<ServiceRpcHandler> get rpcs =>
      UnmodifiableListView(const <ServiceRpcHandler>[]);

  @override
  UnmodifiableListView<RpcHandlerWithParameters> get fallbacks =>
      UnmodifiableListView(const <RpcHandlerWithParameters>[]);
}

Client createTestClient({required String name}) {
  final controller = StreamChannelController<String>();
  late final ClientManager clientManager;
  final backend = FakeBackend();
  final eventStreamMethods = EventStreamManager(
    backend: backend,
    clientsGetter: () => clientManager.clients,
  );
  clientManager = ClientManager(
    backend: backend,
    eventStreamMethods: eventStreamMethods,
  );
  return clientManager.addClient(connection: controller.foreign, name: name);
}

void main() {
  group('DdsIsolateManager', () {
    late FakeVmService fakeVmService;
    late DdsIsolateManager manager;

    setUp(() {
      fakeVmService = FakeVmService();
      manager = DdsIsolateManager(vmServiceClient: fakeVmService);
    });

    test(
      'requireUserPermissionToResume and getRequireUserPermissionToResume',
      () async {
        final client = createTestClient(name: 'testClient');

        // Initial state
        var result = manager.getRequireUserPermissionToResume(
          json_rpc.Parameters(
            'getRequireUserPermissionToResume',
            const <String, Object?>{},
          ),
          client,
        );
        expect(
          result,
          equals(const <String, Object?>{
            'type': 'ResumePermissionsRequired',
            'onPauseStart': false,
            'onPauseExit': false,
          }),
        );

        // Require onPauseStart
        await manager.requireUserPermissionToResume(
          json_rpc.Parameters(
            'requireUserPermissionToResume',
            const <String, Object?>{'onPauseStart': true},
          ),
          client,
        );
        result = manager.getRequireUserPermissionToResume(
          json_rpc.Parameters(
            'getRequireUserPermissionToResume',
            const <String, Object?>{},
          ),
          client,
        );
        expect(
          result,
          equals(const <String, Object?>{
            'type': 'ResumePermissionsRequired',
            'onPauseStart': true,
            'onPauseExit': false,
          }),
        );

        // Require onPauseExit as well
        await manager.requireUserPermissionToResume(
          json_rpc.Parameters(
            'requireUserPermissionToResume',
            const <String, Object?>{'onPauseExit': true, 'onPauseStart': true},
          ),
          client,
        );
        result = manager.getRequireUserPermissionToResume(
          json_rpc.Parameters(
            'getRequireUserPermissionToResume',
            const <String, Object?>{},
          ),
          client,
        );
        expect(
          result,
          equals(const <String, Object?>{
            'type': 'ResumePermissionsRequired',
            'onPauseStart': true,
            'onPauseExit': true,
          }),
        );
      },
    );

    test(
      'requirePermissionToResume enforces approvals before resuming',
      () async {
        final client1 = createTestClient(name: 'client1');
        final client2 = createTestClient(name: 'client2');

        final isolate = vm.Isolate(
          id: 'isolates/1',
          name: 'main',
          number: '1',
          pauseEvent: vm.Event(
            kind: vm.EventKind.kPauseStart,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        fakeVmService.isolates['isolates/1'] = isolate;
        await manager.initializeIsolates();

        // Client1 requires permission on start
        await manager.requirePermissionToResume(
          json_rpc.Parameters(
            'requirePermissionToResume',
            const <String, Object?>{'onPauseStart': true},
          ),
          client1,
        );

        // Client2 tries to resume; should succeed RPC-wise but not forward
        // to VM.
        final response = await manager.resume(
          json_rpc.Parameters('resume', const <String, Object?>{
            'isolateId': 'isolates/1',
          }),
          client2,
        );
        expect(response['type'], equals('Success'));
        expect(fakeVmService.resumedIsolates, isEmpty);

        // Client1 sends readyToResume
        await manager.readyToResume(
          json_rpc.Parameters('readyToResume', const <String, Object?>{
            'isolateId': 'isolates/1',
          }),
          client1,
        );

        // Now VM should have received the resume request
        expect(fakeVmService.resumedIsolates, contains('isolates/1'));
      },
    );

    test(
      'handleClientDisconnected clears approvals and unblocks resume',
      () async {
        final client1 = createTestClient(name: 'client1');
        final client2 = createTestClient(name: 'client2');

        final isolate = vm.Isolate(
          id: 'isolates/2',
          name: 'main',
          number: '2',
          pauseEvent: vm.Event(
            kind: vm.EventKind.kPauseStart,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        fakeVmService.isolates['isolates/2'] = isolate;
        await manager.initializeIsolates();

        // Client1 requires permission on start
        await manager.requirePermissionToResume(
          json_rpc.Parameters(
            'requirePermissionToResume',
            const <String, Object?>{'onPauseStart': true},
          ),
          client1,
        );

        // Client2 calls resume; pending client1 approval
        await manager.resume(
          json_rpc.Parameters('resume', const <String, Object?>{
            'isolateId': 'isolates/2',
          }),
          client2,
        );
        expect(fakeVmService.resumedIsolates, isEmpty);

        // Client1 disconnects
        manager.handleClientDisconnected(client1);

        // Now isolate should resume automatically since blocking client is gone
        expect(fakeVmService.resumedIsolates, contains('isolates/2'));
      },
    );
  });
}
