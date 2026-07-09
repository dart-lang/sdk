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
  Future<Object?> sendRequest({required String method, Object? parameters});

  /// A map of services that are handled by this client.
  ///
  /// The key is the service name and the value is a class containing
  /// information about each service method.
  final Map<String, ClientServiceInfo> services = {};

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

/// Information about a service provided by a client.
class ClientServiceInfo {
  ClientServiceInfo(this.name, [Map<String, ClientServiceMethodInfo>? methods])
      : methods = methods ?? {};

  /// Deserializes a [json] object to create a [ClientServiceInfo] object.
  static ClientServiceInfo fromJson(Map<String, Object?> json) {
    if (json case {_kName: final String name, _kMethods: final List methods}) {
      return ClientServiceInfo(
        name,
        <String, ClientServiceMethodInfo>{
          for (final method in methods
              .cast<Map<String, Object?>>()
              .map(ClientServiceMethodInfo.fromJson))
            method.name: method
        },
      );
    }
    throw ArgumentError('Unexpected JSON format: $json');
  }

  static const _kName = 'name';

  static const _kMethods = 'methods';

  /// The name of the service.
  ///
  /// A client can register multiple services each with multiple methods.
  ///
  /// Only one client can register services for a given name (this is enforced
  /// by the implementation of `registerService`).
  final String name;

  /// The service methods registered for this service.
  final Map<String, ClientServiceMethodInfo> methods;

  /// Serializes this [ClientServiceInfo] object to JSON.
  Map<String, Object?> toJson() => {
        _kName: name,
        _kMethods: methods.values.map((m) => m.toJson()).toList(),
      };
}

/// Information about an individual method of a service provided by a
/// client.
class ClientServiceMethodInfo {
  ClientServiceMethodInfo(this.name, [this.capabilities]);

  /// Deserializes a [json] object to create a [ClientServiceMethodInfo] object.
  static ClientServiceMethodInfo fromJson(Map<String, Object?> json) {
    try {
      return ClientServiceMethodInfo(
        json[_kName] as String,
        json[_kCapabilities] as Map<String, Object?>?,
      );
    } catch (e) {
      throw ArgumentError('Unexpected JSON format: $json');
    }
  }

  static const _kName = 'name';

  static const _kCapabilities = 'capabilities';

  /// The name of the method.
  ///
  /// A client can register multiple methods for each service but can only use
  /// each name once (this is enforced by the implementation of
  /// `registerService`).
  final String name;

  /// Optional capabilities of this service method provided by the client.
  final Map<String, Object?>? capabilities;

  /// Serializes this [ClientServiceMethodInfo] object to JSON.
  Map<String, Object?> toJson() => {
        _kName: name,
        if (capabilities != null) _kCapabilities: capabilities,
      };
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

  /// Returns the first client that contains a service+method from the list of
  /// connected clients.
  ///
  /// There should only ever be one client that owns a service+method but this
  /// method only assumes and does not verify that.
  @mustCallSuper
  Client? findClientThatHandlesServiceMethod(
    String serviceName,
    String methodName,
  ) {
    // TODO(dantup): Should we maintain a complete map of services to avoid
    //  looping over clients?
    for (final client in clients) {
      final service = client.services[serviceName];
      if (service?.methods.containsKey(methodName) ?? false) {
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
