// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:service_extension_router/src/client.dart';
import 'package:service_extension_router/src/named_lookup.dart';
import 'package:meta/meta.dart';

class ClientManager {
  @mustCallSuper
  void addClient(Client client) {
    setClientName(
      client,
      client.defaultClientName,
    );
    clients.add(client);
  }

  @mustCallSuper
  void removeClient(Client client) {
    clients.remove(client);
  }

  bool hasClients() => clients.isNotEmpty;

  /// Cleanup clients on DDS shutdown.
  Future<void> shutdown() async {
    // Close all incoming websocket connections.
    final futures = <Future>[];
    // Copy `clients` to guard against modification while iterating.
    for (final client in clients.toList()) {
      futures.add(client.close());
    }
    await Future.wait(futures);
  }

  @mustCallSuper
  Client? findFirstClientThatHandlesService(String service) {
    for (final client in clients) {
      if (client.services.containsKey(service)) {
        return client;
      }
    }
    return null;
  }

  /// Associates a name with a given client.
  ///
  /// The provided client name is used to track isolate resume approvals.
  @mustCallSuper
  void setClientName(
    Client client,
    String name,
  ) {
    _setClientNameHelper(client, name);
  }

  /// Changes `client`'s name to `name`
  void _setClientNameHelper(
    Client client,
    String name,
  ) {
    clearClientName(client);
    client.name = name.isEmpty ? client.defaultClientName : name;
  }

  static const _kServicePrologue = 's';
  final NamedLookup<Client> clients = NamedLookup(
    prologue: _kServicePrologue,
  );

  @mustCallSuper
  String? clearClientName(Client client) {
    String? name = client.name;
    client.name = null;
    return name;
  }
}
