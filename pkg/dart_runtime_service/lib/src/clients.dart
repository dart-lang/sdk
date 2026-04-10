// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

import 'dart_runtime_service.dart';
import 'dart_runtime_service_backend.dart';
import 'dart_runtime_service_rpcs.dart';
import 'event_streams.dart';
import 'rpc_exceptions.dart';
import 'utils.dart';

typedef ServiceName = String;
typedef ServiceAlias = String;
typedef ServiceNameAliasPair = ({ServiceName service, ServiceAlias alias});

/// Represents a client that is connected to a service.
base class Client {
  Client({
    required this.connection,
    required UnmodifiableClientNamedLookup clients,
    required EventStreamMethods eventStreamMethods,
    required this.backend,
    required this.artificial,
    String? name,
  }) {
    _name = name ?? defaultClientName;
    // Manually create a StreamChannel<String> instead of calling
    // .cast<String>() as cast() results in addStream() being called,
    // binding the underlying sink. This results in a StateError being thrown
    // if we try and add directly to the sink, which we do for binary events
    // in [EventStreamMethod]'s streamNotify().
    final manualConnectionSinkCast = StreamController<String>(sync: true)
      ..stream
          .cast<String>()
          .listen((event) => connection.sink.add(event))
          .onDone(() => connection.sink.close());
    final manualConnectionStreamCast = connection.stream.cast<String>();
    _clientPeer = json_rpc.Peer(
      StreamChannel<String>(
        manualConnectionStreamCast,
        manualConnectionSinkCast,
      ),
      strictProtocolChecks: false,
    );
    _internalRpcs = DartRuntimeServiceRpcs(
      clients: clients,
      eventStreamMethods: eventStreamMethods,
      client: this,
      expressionEvaluator: backend.expressionEvaluator,
    );
  }

  late final String namespace;

  final StreamChannel<Object?> connection;
  late json_rpc.Peer _clientPeer;
  late final DartRuntimeServiceRpcs _internalRpcs;
  final DartRuntimeServiceBackend backend;

  /// If `true`, this client was created via
  /// [DartRuntimeService.addArtificialClient].
  ///
  /// [DartRuntimeServiceBackend]s sometimes need to be able to create clients
  /// that aren't associated with an active connection to the service. For
  /// example, the Dart VM provides native APIs to invoke service RPCs. This
  /// can be implemented by manually creating a [StreamChannel] for native RPC
  /// invocations to be added to, which is then used to create an artificial
  /// client.
  final bool artificial;

  /// The logger to be used when handling requests from this client.
  Logger get logger => Logger(toString());

  /// A [Future] that completes when [close] is invoked.
  late final Future<void> done;

  Future<void> initialize({required String namespace}) {
    logger.info('Initializing...');
    this.namespace = namespace;
    registerRpcHandlers();
    done = _listen().then((_) {
      logger.info('Client connection closed.');
      // Cleanup stream subscription state when the client disconnects.
      _internalRpcs.eventStreamMethods.onClientDisconnect(this);
    });
    logger.info('Initialization complete.');
    return done;
  }

  /// Start receiving JSON RPC requests from the client.
  ///
  /// Returned future completes when the peer is closed.
  Future<void> _listen() => _clientPeer.listen();

  /// Called if the connection to the client should be closed.
  @mustCallSuper
  Future<void> close() async {
    logger.info('Cleaning up.');
    await _clientPeer.close();
  }

  @mustCallSuper
  void registerRpcHandlers() {
    _internalRpcs
      ..addBackendRpcs(backend: backend)
      ..registerRpcsWithPeer(_clientPeer)
      ..registerServiceExtensionForwarder(_clientPeer)
      ..registerBackendFallbacks(_clientPeer);
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
      "'$namespace.$service'.",
    );
    _services[service] = alias;
    _internalRpcs.eventStreamMethods.sendServiceRegisteredEvent(
      this,
      service,
      alias,
    );
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

  /// Invokes a JSON-RPC [method] provided by this client, ignoring the
  /// response.
  void sendNotification({
    required String method,
    Map<String, Object?>? parameters,
  }) {
    if (_clientPeer.isClosed) {
      RpcException.serviceDisappeared.throwException();
    }

    try {
      _clientPeer.sendNotification(method, parameters);
      // ignore: avoid_catching_errors
    } on StateError {
      RpcException.serviceDisappeared.throwException();
    }
  }

  /// Sends raw binary [data] to the client.
  ///
  /// This technically isn't compliant with the JSON-RPC specification and
  /// should only be used to send binary events to streams.
  void sendBinaryData({required Uint8List data}) {
    if (_clientPeer.isClosed) {
      RpcException.serviceDisappeared.throwException();
    }

    try {
      connection.sink.add(data);
      // ignore: avoid_catching_errors
    } on StateError {
      RpcException.serviceDisappeared.throwException();
    }
  }

  /// The set of services registered by this [Client].
  Iterable<ServiceNameAliasPair> get services =>
      _services.entries.map((e) => (service: e.key, alias: e.value));
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
  void setName(String? n) {
    final updated = n ?? defaultClientName;
    logger.info('Changing client name to $updated.');
    _name = updated;
  }

  late String _name;

  @override
  String toString() => 'Client ($name)';
}

/// An interface that allows for controlling whether or not new [Client]
/// connections should be accepted or rejected.
abstract interface class ClientConnectionController {
  /// Accept connection requests from new [Client]s.
  void acceptConnections();

  /// Reject connection requests from new [Client]s, redirecting them to
  /// connect to [redirectUri] instead.
  void rejectConnections({required Uri redirectUri});
}

/// Used for keeping track and managing clients that are connected to a given
/// service.
///
/// Call [addClient] when a client connects to your service.
base class ClientManager implements ClientConnectionController {
  ClientManager({required this.backend, required this.eventStreamMethods});

  static const _kServicePrologue = 's';
  final DartRuntimeServiceBackend backend;
  final EventStreamMethods eventStreamMethods;

  final _logger = Logger('$ClientManager');

  /// Returns `true` if new [Client] connections should be accepted.
  ///
  /// If `false`, [redirectUri] will be non-null and should be included in a
  /// redirect response.
  bool get acceptNewConnections => redirectUri == null;

  /// The [Uri] pointing to the service that [Client]s should attempt to connect
  /// to.
  ///
  /// Returns `null` if [acceptNewConnections] is `true`.
  Uri? get redirectUri => _redirectUri;
  Uri? _redirectUri;

  /// The set of [Client]s currently connected to the service.
  ///
  /// Each client is assigned a unique identifier, prefixed with
  /// [_kServicePrologue] (e.g., 's1'). This identifier is used when invoking
  /// service extensions registered by the client to indicate which client
  /// is responsible for handling the service extension invocation.
  UnmodifiableClientNamedLookup get clients =>
      UnmodifiableClientNamedLookup(_clients);
  final _clients = ClientNamedLookup(prefix: _kServicePrologue);

  @override
  void acceptConnections() {
    _redirectUri = null;
    _logger.info('Accepting new connections.');
  }

  @override
  void rejectConnections({required Uri redirectUri}) {
    _redirectUri = redirectUri;
    _logger.info(
      'No longer accepting new connections. Redirecting connections to '
      '$redirectUri.',
    );
  }

  /// Creates a [Client] from [connection] and adds it to the list of connected
  /// clients.
  ///
  /// This should be called when a client connects to the service.
  @mustCallSuper
  Client addClient({
    required StreamChannel<Object?> connection,
    String? name,
    bool artificial = false,
  }) {
    final client = Client(
      connection: connection,
      clients: clients,
      eventStreamMethods: eventStreamMethods,
      backend: backend,
      name: name,
      artificial: artificial,
    );
    final namespace = _clients.add(client);
    client.initialize(namespace: namespace).then((_) {
      // Remove the client from the clients list when it disconnects.
      removeClient(client);
    });
    return client;
  }

  /// Removes [client] from the list of connected clients.
  ///
  /// This is called when the client disconnects from the service and should
  /// not be invoked manually.
  @mustCallSuper
  @visibleForOverriding
  void removeClient(Client client) {
    if (_clients.contains(client)) {
      _clients.remove(client);
    }
  }

  /// Cleans up clients that are still connected by calling [Client.close] on
  /// all of them.
  Future<void> shutdown() async {
    // Close all incoming websocket connections.
    final futures = <Future<void>>[];
    // Copy `clients` to guard against modification while iterating.
    for (final client in _clients.toList()) {
      futures.add(
        Future.sync(() => removeClient(client)).whenComplete(client.close),
      );
    }
    await Future.wait(futures);
    // Reset the ID counter so logs in tests are consistent.
    Client._idCounter = 0;
  }
}
