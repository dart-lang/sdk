// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_service_protocol_shared/src/named_lookup.dart';
import 'package:meta/meta.dart';

/// Represents a client that is connected to a service.
abstract class Client {
  /// Sends [data] to the client on the provided [stream].
  ///
  /// This method should do any formatting needed on [data], then send it to
  /// the [Client].
  void streamNotify(String stream, Object data);

  /// Called if the connection to the client should be closed.
  Future<void> close();

  /// Sends a request to the client.
  ///
  /// This method should forward [method] with [parameters] to the client.
  Future<dynamic> sendRequest({required String method, dynamic parameters});

  /// A list of services that are handled by this client.
  ///
  /// The key is intended to be a service and the value is intended to be an
  /// alias.
  final Map<String, String> services = {};

  static int _idCounter = 0;
  final int _id = ++_idCounter;

  /// The name given to the client upon its creation.
  String get defaultClientName => 'client$_id';

  /// The current name associated with this client.
  String? get name => _name;

  // NOTE: this should not be called directly except from:
  //   - `ClientManager._clearClientName`
  //   - `ClientManager._setClientNameHelper`
  void _setName(String? n) => _name = n ?? defaultClientName;
  String? _name;
}

/// Used for keeping track and managing clients that are connected to a given
/// service.
///
/// Call [addClient] when a client connects to your service, then call
/// [removeClient] when it stops listening.
abstract class ClientManager {
  /// Adds [client] to the list of connected clients.
  ///
  /// This should be called when a client connects to the service.
  @mustCallSuper
  void addClient(Client client) {
    setClientName(
      client,
      client.defaultClientName,
    );
    clients.add(client);
  }

  /// Removes [client] from the list of connected clients.
  ///
  /// This should be called when the client disconnects from the service.
  @mustCallSuper
  void removeClient(Client client) {
    clients.remove(client);
  }

  /// Returns true if the client manager has and clients still connected.
  bool hasClients() => clients.isNotEmpty;

  /// Cleans up clients that are still connected by calling [Client.close] on
  /// all of them.
  Future<void> shutdown() async {
    // Close all incoming websocket connections.
    final futures = <Future>[];
    // Copy `clients` to guard against modification while iterating.
    for (final client in clients.toList()) {
      futures.add(
        Future.sync(() => removeClient(client))
            .whenComplete(() => client.close()),
      );
    }
    await Future.wait(futures);
  }

  /// Returns the first client that contains a service, from the list of
  /// connected clients.
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
  @mustCallSuper
  void setClientName(
    Client client,
    String name,
  ) {
    _setClientNameHelper(client, name);
  }

  /// Changes [client]'s name to [name]
  void _setClientNameHelper(
    Client client,
    String name,
  ) {
    clearClientName(client);
    client._setName(name.isEmpty ? client.defaultClientName : name);
  }

  static const _kServicePrologue = 's';
  final NamedLookup<Client> clients = NamedLookup(
    prologue: _kServicePrologue,
  );

  /// Unsets a client's name by setting it to null.
  @mustCallSuper
  String? clearClientName(Client client) {
    String? name = client.name;
    client._setName(null);
    return name;
  }
}
