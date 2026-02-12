// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

import 'dart_runtime_service_rpcs.dart';
import 'rpc_exceptions.dart';
import 'utils.dart';

typedef ServiceName = String;
typedef ServiceAlias = String;

/// Represents a client that is connected to a service.
base class Client {
  Client({
    required this.clientManager,
    required StreamChannel<String> connection,
  }) {
    _clientPeer = json_rpc.Peer(connection, strictProtocolChecks: false);
    registerRpcHandlers();
    done = _listen();
  }

  final ClientManager clientManager;
  late json_rpc.Peer _clientPeer;
  late final _internalRpcs = DartRuntimeServiceRpcs(
    clientManager: clientManager,
    client: this,
  );

  /// The logger to be used when handling requests from this client.
  Logger get logger => Logger('Client ($name)');

  /// A [Future] that completes when [close] is invoked.
  late final Future<void> done;

  /// Start receiving JSON RPC requests from the client.
  ///
  /// Returned future completes when the peer is closed.
  Future<void> _listen() => _clientPeer.listen();

  /// Called if the connection to the client should be closed.
  @mustCallSuper
  Future<void> close() async {
    await _clientPeer.close();
  }

  @mustCallSuper
  void registerRpcHandlers() {
    _internalRpcs.registerRpcsWithPeer(_clientPeer);
  }

  /// Attempts to register a [service] to be provided by this client.
  ///
  /// [alias] is a human-readable description of the provided service.
  ///
  /// If [service] is already registered with this client, an error is
  /// returned.
  bool registerService({
    required ServiceName service,
    required ServiceAlias alias,
  }) {
    if (hasService(service)) {
      logger.info("Service '$service' is already registered by this client.");
      return false;
    }
    logger.info(
      "Successfully registered service '$service' as "
      "'${clientManager.clients.keyOf(this)}.$service'.",
    );
    _services[service] = alias;
    // TODO(bkonyi): send notification of newly registered service.
    return true;
  }

  /// Returns true if [service] has already been registered by this client.
  bool hasService(String service) => _services.containsKey(service);

  /// Invokes a JSON-RPC [method] provided by this client.
  Future<RpcResponse> sendRequest({
    required String method,
    Map<String, Object?>? parameters,
  }) async {
    if (_clientPeer.isClosed) {
      RpcException.serviceDisappeared.throwException();
    }

    try {
      return await _clientPeer.sendRequest(method, parameters) as RpcResponse;
      // ignore: avoid_catching_errors
    } on StateError {
      RpcException.serviceDisappeared.throwException();
    }
  }

  final _services = <ServiceName, ServiceAlias>{};

  static int _idCounter = 0;
  final int _id = ++_idCounter;

  /// The name given to the client upon its creation.
  String get defaultClientName => 'client$_id';

  /// The current name associated with this client.
  String get name => _name;

  /// Sets the name associated with this client.
  ///
  /// If [n] is null, the client name is reset to [defaultClientName].
  void setName(String? n) => _name = n ?? defaultClientName;
  late String _name = defaultClientName;
}

/// Used for keeping track and managing clients that are connected to a given
/// service.
///
/// Call [addClient] when a client connects to your service, then call
/// [removeClient] when it stops listening.
base class ClientManager {
  /// Creates a [Client] from [connection] and adds it to the list of connected
  /// clients.
  ///
  /// This should be called when a client connects to the service.
  @mustCallSuper
  Client addClient(StreamChannel<String> connection) {
    final client = Client(clientManager: this, connection: connection);
    clients.add(client);
    return client;
  }

  /// Removes [client] from the list of connected clients.
  ///
  /// This should be called when the client disconnects from the service.
  @mustCallSuper
  void removeClient(Client client) {
    clients.remove(client);
  }

  /// Cleans up clients that are still connected by calling [Client.close] on
  /// all of them.
  Future<void> shutdown() async {
    // Close all incoming websocket connections.
    final futures = <Future<void>>[];
    // Copy `clients` to guard against modification while iterating.
    for (final client in clients.toList()) {
      futures.add(
        Future.sync(() => removeClient(client)).whenComplete(client.close),
      );
    }
    await Future.wait(futures);
  }

  static const _kServicePrologue = 's';

  /// The set of [Client]s currently connected to the service.
  ///
  /// Each client is assigned a unique identifier, prefixed with
  /// [_kServicePrologue] (e.g., 's1'). This identifier is used when invoking
  /// service extensions registered by the client to indicate which client
  /// is responsible for handling the service extension invocation.
  final clients = NamedLookup<Client>(prefix: _kServicePrologue);
}
