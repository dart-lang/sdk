// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:json_rpc_2/json_rpc_2.dart' hide Client;
import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:vm_service/vm_service.dart';

import '../dart_runtime_service_vm.dart';

typedef ServiceIDZone = ({IdZone idZone, String isolateId});

/// A [Client] of the VM service.
final class VmClient extends Client<DartRuntimeServiceVMBackend> {
  VmClient({
    required super.connection,
    required super.clients,
    required super.eventStreamMethods,
    required super.backend,
    required super.artificial,
    super.name,
  });

  final _idZones = <ServiceIDZone>{};

  @override
  @protected
  Future<void> cleanup() async {
    await _cleanupIdZones();
    await super.cleanup();
  }

  /// Track a newly created [IdZone].
  void registerIdZone({required String isolateId, required IdZone idZone}) {
    _idZones.add((idZone: idZone, isolateId: isolateId));
  }

  /// Stop tracking a recently destroyed [IdZone].
  void unregisterIdZone({required String isolateId, required String idZoneId}) {
    _idZones.removeWhere(
      (e) => e.isolateId == isolateId && e.idZone.id == idZoneId,
    );
  }

  Future<void> _cleanupIdZones() async {
    await Future.wait([
      for (final (:idZone, :isolateId) in _idZones)
        backend.sendToRuntime(
          Parameters('deleteIdZone', {
            'isolateId': isolateId,
            'idZoneId': idZone.id!,
          }),
        ),
    ]);
  }
}

/// Manages and tracks clients of the VM service.
final class VmClientManager extends ClientManager<DartRuntimeServiceVMBackend> {
  VmClientManager({required super.backend, required super.eventStreamMethods});

  @override
  VmClient clientBuilder({
    required StreamChannel<Object?> connection,
    required UnmodifiableClientNamedLookup clients,
    required EventStreamMethods eventStreamMethods,
    required DartRuntimeServiceVMBackend backend,
    required bool artificial,
    String? name,
  }) {
    return VmClient(
      connection: connection,
      clients: clients,
      eventStreamMethods: eventStreamMethods,
      backend: backend,
      name: name,
      artificial: artificial,
    );
  }
}
