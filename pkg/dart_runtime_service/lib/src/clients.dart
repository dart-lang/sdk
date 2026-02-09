// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

import 'dart_runtime_service_rpcs.dart';
import 'utils.dart';

/// Represents a client that is connected to a service.
base class Client {
  Client(this._connection) {
    _clientPeer = json_rpc.Peer(_connection, strictProtocolChecks: false);
    registerRpcHandlers();
    _done = _listen();
  }

  final StreamChannel<String> _connection;
  late json_rpc.Peer _clientPeer;
  late final _internalRpcs = DartRuntimeServiceRpcs(client: this);

  /// A [Future] that completes when [close] is invoked.
  Future<void> get done => _done;
  late final Future<void> _done;

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
    final client = Client(connection);
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
  final clients = NamedLookup<Client>(prologue: _kServicePrologue);
}
