// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

import 'dds_backend.dart';

/// Represents a client connected to DDS.
base class DdsClient extends Client<DartRuntimeServiceDdsBackend> {
  DdsClient({
    required super.artificial,
    required super.backend,
    required super.clientManager,
    required super.clients,
    required super.connection,
    required super.eventStreamMethods,
    super.name,
  });

  /// Pairs of 1) the ID of a Service ID zone created by this client and 2) the
  /// ID of the isolate in which that zone was created.
  final _createdServiceIdZones =
      <({String isolateId, String serviceIdZoneId})>[];

  /// Tracks a Service ID zone created by this client.
  void addServiceIdZone({
    required String isolateId,
    required String serviceIdZoneId,
  }) => _createdServiceIdZones.add((
    isolateId: isolateId,
    serviceIdZoneId: serviceIdZoneId,
  ));

  @override
  @protected
  @mustCallSuper
  Future<void> cleanup() async {
    await super.cleanup();
    for (final (:isolateId, :serviceIdZoneId) in _createdServiceIdZones) {
      try {
        await backend.callVmService(
          'deleteIdZone',
          args: <String, Object?>{
            'idZoneId': serviceIdZoneId,
            'isolateId': isolateId,
          },
        );
      } on Object {
        // The isolate may have already exited or the VM service connection may
        // be closed, so ignore failure to delete the zone during cleanup.
      }
    }
  }
}

/// ClientManager for DDS clients.
final class DdsClientManager
    extends ClientManager<DartRuntimeServiceDdsBackend> {
  DdsClientManager({required super.backend, required super.eventStreamMethods});

  @override
  DdsClient clientBuilder({
    required bool artificial,
    required DartRuntimeServiceDdsBackend backend,
    required UnmodifiableClientNamedLookup clients,
    required StreamChannel<Object?> connection,
    required EventStreamMethods eventStreamMethods,
    String? name,
  }) {
    return DdsClient(
      artificial: artificial,
      backend: backend,
      clientManager: this,
      clients: clients,
      connection: connection,
      eventStreamMethods: eventStreamMethods,
      name: name,
    );
  }

  @override
  void removeClient(Client client) {
    super.removeClient(client);
    backend.isolateManager.handleClientDisconnected(client);
  }
}
