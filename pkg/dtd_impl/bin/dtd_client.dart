// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dart_service_protocol_shared/dart_service_protocol_shared.dart';
import 'package:sse/server/sse_handler.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'constants.dart';
import 'dart_tooling_daemon.dart';
import 'rpc_error_codes.dart';

/// Represents a client that is connected to a DTD service.
class DTDClient extends Client {
  final StreamChannel connection;
  late json_rpc.Peer _clientPeer;
  final DartToolingDaemon dtd;
  late final Future _done;

  Future get done => _done;

  DTDClient.fromWebSocket(
    DartToolingDaemon dtd,
    WebSocketChannel ws,
  ) : this._(
          dtd,
          ws,
        );

  DTDClient.fromSSEConnection(
    DartToolingDaemon dtd,
    SseConnection sse,
  ) : this._(
          dtd,
          sse,
        );

  DTDClient._(
    this.dtd,
    this.connection,
  ) {
    _clientPeer = json_rpc.Peer(
      connection.cast<String>(),
      strictProtocolChecks: false,
    );
    _registerJsonRpcMethods();
    _done = listen();
  }

  @override
  Future<void> close() => _clientPeer.close();

  @override
  Future<dynamic> sendRequest({
    required String method,
    dynamic parameters,
  }) async {
    if (_clientPeer.isClosed) {
      return;
    }

    return await _clientPeer.sendRequest(method, parameters.asMap);
  }

  @override
  void streamNotify(String streamId, Object eventData) {
    _clientPeer.sendNotification('streamNotify', eventData);
  }

  /// Start receiving JSON RPC requests from the client.
  ///
  /// Returned future completes when the peer is closed.
  Future<void> listen() => _clientPeer.listen().then(
        (_) => dtd.streamManager.onClientDisconnect(this),
      );

  /// Registers handlers for the Dart Tooling Daemon JSON RPC method endpoints.
  void _registerJsonRpcMethods() {
    // TODO(danchevalier): do a once over of all methods and ensure that we have
    // all necessary validations.
    _clientPeer.registerMethod('streamListen', _streamListen);
    _clientPeer.registerMethod('streamCancel', _streamCancel);
    _clientPeer.registerMethod('postEvent', _postEvent);
    _clientPeer.registerMethod('registerService', _registerService);
    _clientPeer.registerMethod('getRegisteredStreams', _getRegisteredStreams);

    // Handle service extension invocations.
    _clientPeer.registerFallback(_fallback);
  }

  /// jrpc endpoint for cancelling a stream.
  ///
  /// Parameters:
  /// 'streamId': the stream to be cancelled.
  _streamListen(parameters) async {
    final streamId = parameters['streamId'].asString;
    await dtd.streamManager.streamListen(
      this,
      streamId,
    );
    return RPCResponses.success;
  }

  /// jrpc endpoint for stopping listening to a stream.
  ///
  /// Parameters:
  /// 'streamId': the stream that the client would like to stop listening to.
  _streamCancel(parameters) async {
    final streamId = parameters['streamId'].asString;
    await dtd.streamManager.streamCancel(this, streamId);
    return RPCResponses.success;
  }

  /// jrpc endpoint for posting an event to a stream.
  ///
  /// Parameters:
  /// 'eventKind': the kind of event being sent.
  /// 'data': the data being sent over the stream.
  /// 'stream: the stream that is being posted to.
  _postEvent(parameters) async {
    final eventKind = parameters['eventKind'].asString;
    final eventData = parameters['eventData'].asMap;
    final stream = parameters['streamId'].asString;
    dtd.streamManager.postEventHelper(stream, eventKind, eventData);
    return RPCResponses.success;
  }

  /// jrpc endpoint for registering a service to the tooling daemon.
  ///
  /// Parameters:
  /// 'service': the name of the service that is being registered to.
  /// 'method': the name of the method that is being registered on the service.
  _registerService(parameters) {
    final serviceName = parameters['service'].asString;
    final method = parameters['method'].asString;
    final combinedName = '$serviceName.$method';

    // TODO(danchevalier): enforce only one client can register methods to a
    // service.
    if (services.containsKey(combinedName)) {
      throw RpcErrorCodes.buildRpcException(
        RpcErrorCodes.kServiceAlreadyRegistered,
      );
    }
    services[combinedName] = method;
    return RPCResponses.success;
  }

  _getRegisteredStreams(parameters) {
    // TODO(danchevalier) implement this.
    return [];
  }

  /// jrpc fallback handler.
  ///
  /// Handles all service method calls that will be forwarded to the respective
  /// client which registered that service method.
  _fallback(parameters) async {
    // Lookup the client associated with the service extension's namespace.
    // If the client exists and that client has registered the specified
    // method, forward the request to that client.
    final serviceMethod = parameters.method;

    final client = dtd.clientManager.findFirstClientThatHandlesService(
      serviceMethod,
    );
    if (client == null) {
      throw json_rpc.RpcException(
        RpcErrorCodes.kMethodNotFound,
        'Unknown service method: $serviceMethod',
      );
    }

    return await client.sendRequest(
      method: serviceMethod,
      parameters: parameters,
    );
  }
}
