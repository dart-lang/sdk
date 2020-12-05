// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dds;

/// Representation of a single DDS client which manages the connection and
/// DDS request intercepting / forwarding.
class _DartDevelopmentServiceClient {
  factory _DartDevelopmentServiceClient.fromWebSocket(
    DartDevelopmentService dds,
    WebSocketChannel ws,
    json_rpc.Peer vmServicePeer,
  ) =>
      _DartDevelopmentServiceClient._(
        dds,
        ws,
        vmServicePeer,
      );

  factory _DartDevelopmentServiceClient.fromSSEConnection(
    DartDevelopmentService dds,
    SseConnection sse,
    json_rpc.Peer vmServicePeer,
  ) =>
      _DartDevelopmentServiceClient._(
        dds,
        sse,
        vmServicePeer,
      );

  _DartDevelopmentServiceClient._(
    this.dds,
    this.connection,
    json_rpc.Peer vmServicePeer,
  ) : _vmServicePeer = vmServicePeer {
    _clientPeer = json_rpc.Peer(
      // Manually create a StreamChannel<String> instead of calling
      // .cast<String>() as cast() results in addStream() being called,
      // binding the underlying sink. This results in a StateError being thrown
      // if we try and add directly to the sink, which we do for binary events
      // in _StreamManager's streamNotify().
      StreamChannel<String>(
        connection.stream.cast(),
        StreamController(sync: true)
          ..stream
              .cast()
              .listen((event) => connection.sink.add(event))
              .onDone(() => connection.sink.close()),
      ),
      strictProtocolChecks: false,
    );
    _registerJsonRpcMethods();
  }

  /// Start receiving JSON RPC requests from the client.
  ///
  /// Returned future completes when the peer is closed.
  Future<void> listen() => _clientPeer.listen().then(
        (_) => dds.streamManager.clientDisconnect(this),
      );

  /// Close the connection to the client.
  Future<void> close() async {
    // Cleanup the JSON RPC server for this connection if DDS has shutdown.
    await _clientPeer.close();
  }

  /// Send a JSON RPC notification to the client.
  void sendNotification(String method, [dynamic parameters]) {
    if (_clientPeer.isClosed) {
      return;
    }
    _clientPeer.sendNotification(method, parameters);
  }

  /// Send a JSON RPC request to the client.
  Future<dynamic> sendRequest(String method, [dynamic parameters]) async {
    if (_clientPeer.isClosed) {
      return null;
    }
    return await _clientPeer.sendRequest(method, parameters);
  }

  /// Registers handlers for JSON RPC methods which need to be intercepted by
  /// DDS as well as fallback request forwarder.
  void _registerJsonRpcMethods() {
    _clientPeer.registerMethod('streamListen', (parameters) async {
      final streamId = parameters['streamId'].asString;
      await dds.streamManager.streamListen(this, streamId);
      return _RPCResponses.success;
    });

    _clientPeer.registerMethod('streamCancel', (parameters) async {
      final streamId = parameters['streamId'].asString;
      await dds.streamManager.streamCancel(this, streamId);
      return _RPCResponses.success;
    });

    _clientPeer.registerMethod('registerService', (parameters) async {
      final serviceId = parameters['service'].asString;
      final alias = parameters['alias'].asString;
      if (services.containsKey(serviceId)) {
        throw _RpcErrorCodes.buildRpcException(
          _RpcErrorCodes.kServiceAlreadyRegistered,
        );
      }
      services[serviceId] = alias;
      // Notify other clients that a new service extension is available.
      dds.streamManager.sendServiceRegisteredEvent(
        this,
        serviceId,
        alias,
      );
      return _RPCResponses.success;
    });

    _clientPeer.registerMethod(
      'getClientName',
      (parameters) => {'type': 'ClientName', 'name': name},
    );

    _clientPeer.registerMethod(
      'setClientName',
      (parameters) => dds.clientManager.setClientName(this, parameters),
    );

    _clientPeer.registerMethod(
      'requirePermissionToResume',
      (parameters) =>
          dds.clientManager.requirePermissionToResume(this, parameters),
    );

    _clientPeer.registerMethod(
      'resume',
      (parameters) => dds.isolateManager.resumeIsolate(this, parameters),
    );

    _clientPeer.registerMethod(
        'getLogHistorySize',
        (parameters) => {
              'type': 'Size',
              'size': _StreamManager
                  .loggingRepositories[_StreamManager.kLoggingStream]
                  .bufferSize,
            });

    _clientPeer.registerMethod('setLogHistorySize', (parameters) {
      final size = parameters['size'].asInt;
      if (size < 0) {
        throw json_rpc.RpcException.invalidParams(
          "'size' must be greater or equal to zero",
        );
      }
      _StreamManager.loggingRepositories[_StreamManager.kLoggingStream]
          .resize(size);
      return _RPCResponses.success;
    });

    _clientPeer.registerMethod('getDartDevelopmentServiceVersion',
        (parameters) async {
      final ddsVersion = DartDevelopmentService.protocolVersion.split('.');
      return <String, dynamic>{
        'type': 'Version',
        'major': int.parse(ddsVersion[0]),
        'minor': int.parse(ddsVersion[1]),
      };
    });

    _clientPeer.registerMethod('getSupportedProtocols', (parameters) async {
      final Map<String, dynamic> supportedProtocols =
          await _vmServicePeer.sendRequest('getSupportedProtocols');
      final ddsVersion = DartDevelopmentService.protocolVersion.split('.');
      final ddsProtocol = {
        'protocolName': 'DDS',
        'major': int.parse(ddsVersion[0]),
        'minor': int.parse(ddsVersion[1]),
      };
      supportedProtocols['protocols']
          .cast<Map<String, dynamic>>()
          .add(ddsProtocol);
      return supportedProtocols;
    });

    // `evaluate` and `evaluateInFrame` actually consist of multiple RPC
    // invocations, including a call to `compileExpression` which can be
    // overridden by clients which provide their own implementation (e.g.,
    // Flutter Tools). We handle all of this in [_ExpressionEvaluator].
    _clientPeer.registerMethod(
      'evaluate',
      dds.expressionEvaluator.execute,
    );
    _clientPeer.registerMethod(
      'evaluateInFrame',
      dds.expressionEvaluator.execute,
    );

    // When invoked within a fallback, the next fallback will start executing.
    // The final fallback forwards the request to the VM service directly.
    @alwaysThrows
    nextFallback() => throw json_rpc.RpcException.methodNotFound('');

    // Handle service extension invocations.
    _clientPeer.registerFallback((parameters) async {
      hasNamespace(String method) => method.contains('.');
      getMethod(String method) => method.split('.').last;
      getNamespace(String method) => method.split('.').first;
      if (!hasNamespace(parameters.method)) {
        nextFallback();
      }
      // Lookup the client associated with the service extension's namespace.
      // If the client exists and that client has registered the specified
      // method, forward the request to that client.
      final method = getMethod(parameters.method);
      final namespace = getNamespace(parameters.method);
      final serviceClient = dds.clientManager.clients[namespace];
      if (serviceClient != null && serviceClient.services.containsKey(method)) {
        return await Future.any(
          [
            // Forward the request to the service client or...
            serviceClient.sendRequest(method, parameters.asMap).catchError((_) {
              throw _RpcErrorCodes.buildRpcException(
                _RpcErrorCodes.kServiceDisappeared,
              );
            }, test: (error) => error is StateError),
            // if the service client closes, return an error response.
            serviceClient._clientPeer.done.then(
              (_) => throw _RpcErrorCodes.buildRpcException(
                _RpcErrorCodes.kServiceDisappeared,
              ),
            ),
          ],
        );
      }
      throw json_rpc.RpcException(
        _RpcErrorCodes.kMethodNotFound,
        'Unknown service: ${parameters.method}',
      );
    });

    // Unless otherwise specified, the request is forwarded to the VM service.
    // NOTE: This must be the last fallback registered.
    _clientPeer.registerFallback((parameters) async {
      try {
        return await _vmServicePeer.sendRequest(
            parameters.method, parameters.value);
      } on StateError {
        await dds.shutdown();
      }
    });
  }

  static int _idCounter = 0;
  final int _id = ++_idCounter;

  /// The name given to the client upon its creation.
  String get defaultClientName => 'client$_id';

  /// The current name associated with this client.
  String get name => _name;

  // NOTE: this should not be called directly except from:
  //   - `_ClientManager._clearClientName`
  //   - `_ClientManager._setClientNameHelper`
  set name(String n) => _name = n ?? defaultClientName;
  String _name;

  final _DartDevelopmentService dds;
  final StreamChannel connection;
  final Map<String, String> services = {};
  final json_rpc.Peer _vmServicePeer;
  json_rpc.Peer _clientPeer;
}
