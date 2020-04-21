// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dds;

/// Representation of a single DDS client which manages the connection and
/// DDS request intercepting / forwarding.
class _DartDevelopmentServiceClient {
  _DartDevelopmentServiceClient(
    this.dds,
    this.ws,
    json_rpc.Peer vmServicePeer,
  ) : _vmServicePeer = vmServicePeer {
    _clientPeer = json_rpc.Peer(ws.cast<String>());
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
  void sendNotification(String method, [dynamic parameters]) async {
    if (_clientPeer.isClosed) {
      return;
    }
    _clientPeer.sendNotification(method, parameters);
  }

  /// Registers handlers for JSON RPC methods which need to be intercepted by
  /// DDS as well as fallback request forwarder.
  void _registerJsonRpcMethods() {
    _clientPeer.registerMethod('streamListen', (parameters) async {
      final streamId = parameters['streamId'].asString;
      await dds.streamManager.streamListen(this, streamId);
      return _success;
    });

    _clientPeer.registerMethod('streamCancel', (parameters) async {
      final streamId = parameters['streamId'].asString;
      await dds.streamManager.streamCancel(this, streamId);
      return _success;
    });

    // Unless otherwise specified, the request is forwarded to the VM service.
    _clientPeer.registerFallback((parameters) async =>
        await _vmServicePeer.sendRequest(parameters.method, parameters.asMap));
  }

  static const _success = <String, dynamic>{
    'type': 'Success',
  };

  final _DartDevelopmentService dds;
  final json_rpc.Peer _vmServicePeer;
  final WebSocketChannel ws;
  json_rpc.Peer _clientPeer;
}
