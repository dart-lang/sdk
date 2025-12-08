// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/stream_channel.dart';

typedef JsonRpcPeer = json_rpc.Peer;

typedef JsonRpcException = json_rpc.RpcException;

typedef JsonRpcMethod =
    FutureOr<Object?> Function(
      JsonRpcPeer requestor,
      Map<String, Object?>? params,
    );

JsonRpcPeer jsonRpcPeerFromSocket(
  io.Socket socket, [
  Map<String, JsonRpcMethod>? methods,
]) {
  final lineChannel = StreamChannel<String>(
    const LineSplitter().bind(utf8.decoder.bind(socket)),
    StreamController<String>(sync: true, onCancel: socket.close)
      ..stream.listen((line) {
        socket.write(line);
        socket.write('\n');
      }),
  );
  final peer = json_rpc.Peer(lineChannel);
  if (methods != null) {
    for (final MapEntry(:key, :value) in methods.entries) {
      peer.registerMethod(key, (json_rpc.Parameters params) {
        return value(
          peer,
          params.value == null ? null : params.asMap.cast<String, Object?>(),
        );
      });
    }
  }

  peer.listen().ignore();
  return peer;
}

class JsonRpcServer {
  final io.ServerSocket _serverSocket;
  final _endpoints = <JsonRpcPeer>{};

  JsonRpcServer(this._serverSocket, [Map<String, JsonRpcMethod>? methods]) {
    _serverSocket.listen((client) {
      final endpoint = jsonRpcPeerFromSocket(client, methods);
      _endpoints.add(endpoint);
      endpoint.done.whenComplete(() {
        _endpoints.remove(endpoint);
      });
    });
  }

  /// Returns a list of currently connected endpoints.
  List<JsonRpcPeer> get endpoints => _endpoints.toList();

  Future<void> close() async {
    await Future.wait(_endpoints.toList().map((e) => e.close()));
    await _serverSocket.close();
  }
}
