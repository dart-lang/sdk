// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dart_service_protocol_shared/dart_service_protocol_shared.dart';
import 'package:sse/server/sse_handler.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:dtd/dtd.dart' show RpcErrorCodes;

import 'constants.dart';
import '../dart_tooling_daemon.dart';

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
  void streamNotify(String stream, Object data) {
    _clientPeer.sendNotification('streamNotify', data);
  }

  /// Start receiving JSON RPC requests from the client.
  ///
  /// Returned future completes when the peer is closed.
  Future<void> listen() => _clientPeer.listen().then(
        (_) => dtd.streamManager.onClientDisconnect(this),
      );

  /// Registers handlers for the Dart Tooling Daemon JSON RPC method endpoints.
  void _registerJsonRpcMethods() {
    _clientPeer.registerMethod('streamListen', _streamListen);
    _clientPeer.registerMethod('streamCancel', _streamCancel);
    _clientPeer.registerMethod('postEvent', _postEvent);
    _clientPeer.registerMethod('registerService', _registerService);

    // Handle service extension invocations.
    _clientPeer.registerFallback(_fallback);
  }

  /// jrpc endpoint for listening to a stream.
  ///
  /// Parameters:
  /// 'streamId': the stream to be cancelled.
  _streamListen(parameters) async {
    final streamId = parameters['streamId'].asString;
    try {
      await dtd.streamManager.streamListen(
        this,
        streamId,
      );
    } on StreamAlreadyListeningException catch (_) {
      throw RpcErrorCodes.buildRpcException(
        RpcErrorCodes.kStreamAlreadySubscribed,
        data: {
          'details': "The stream '$streamId' is already subscribed",
        },
      );
    }
    return RPCResponses.success;
  }

  /// jrpc endpoint for stopping listening to a stream.
  ///
  /// Parameters:
  /// 'streamId': the stream that the client would like to stop listening to.
  _streamCancel(parameters) async {
    final streamId = parameters['streamId'].asString;

    if (!dtd.streamManager.isSubscribed(this, streamId)) {
      throw RpcErrorCodes.buildRpcException(
        RpcErrorCodes.kStreamNotSubscribed,
        data: {
          'details': "Client is not listening to '$streamId'",
        },
      );
    }
    await dtd.streamManager.streamCancel(this, streamId);
    return RPCResponses.success;
  }

  /// jrpc endpoint for posting an event to a stream.
  ///
  /// Parameters:
  /// 'eventKind': the kind of event being sent.
  /// 'eventData': the data being sent over the stream.
  /// 'streamId: the stream that is being posted to.
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

    final existingServiceOwnerClient =
        dtd.clientManager.findClientThatOwnsService(serviceName);
    if (existingServiceOwnerClient != null &&
        existingServiceOwnerClient != this) {
      throw RpcErrorCodes.buildRpcException(
        RpcErrorCodes.kServiceAlreadyRegistered,
        data: {
          'details':
              "Service '$serviceName' is already registered by another client. "
                  "Only 1 client at a time may register methods to a service.",
        },
      );
    }

    if (services.containsKey(combinedName)) {
      throw RpcErrorCodes.buildRpcException(
        RpcErrorCodes.kServiceMethodAlreadyRegistered,
        data: {
          'details': "$combinedName has already been registered by the client.",
        },
      );
    }

    services[combinedName] = method;
    return RPCResponses.success;
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

  /// Registers a service method to the Dart Tooling Daemon using the name
  /// "[service].[method]".
  ///
  /// This method is a helper for registering service methods that are available
  /// when the Dart Tooling Daemon is initialized. To trigger a service method
  /// registered with this helper see the
  /// [dtd_protocol.md#servicemethod](https://github.com/dart-lang/sdk/blob/main/pkg/dtd_impl/dtd_protocol.md#servicemethod)
  /// documentation.
  ///
  /// When a client of the Dart Tooling Daemon calls [service].[method], then
  /// [callback] will be run with the parameters of that call.
  void registerServiceMethod(
    String service,
    String method,
    void Function(json_rpc.Parameters parameters) callback,
  ) {
    final combinedName = '$service.$method';
    _clientPeer.registerMethod(combinedName, callback);
  }
}
