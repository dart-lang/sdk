// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_rpc_2.peer;

import 'dart:async';

import '../error_code.dart' as error_code;
import 'client.dart';
import 'exception.dart';
import 'parameters.dart';
import 'server.dart';
import 'two_way_stream.dart';

/// A JSON-RPC 2.0 client *and* server.
///
/// This supports bidirectional peer-to-peer communication with another JSON-RPC
/// 2.0 endpoint. It sends both requests and responses across the same
/// communication channel and expects to connect to a peer that does the same.
class Peer implements Client, Server {
  TwoWayStream _streams;

  /// The underlying client that handles request-sending and response-receiving
  /// logic.
  Client _client;

  /// The underlying server that handles request-receiving and response-sending
  /// logic.
  Server _server;

  /// A stream controller that forwards incoming messages to [_server] if
  /// they're requests.
  final _serverIncomingForwarder = new StreamController(sync: true);

  /// A stream controller that forwards incoming messages to [_client] if
  /// they're responses.
  final _clientIncomingForwarder = new StreamController(sync: true);

  /// A stream controller that forwards outgoing messages from both [_server]
  /// and [_client].
  final _outgoingForwarder = new StreamController(sync: true);

  /// Creates a [Peer] that reads incoming messages from [incoming] and writes
  /// outgoing messages to [outgoing].
  ///
  /// If [incoming] is a [StreamSink] as well as a [Stream] (for example, a
  /// `WebSocket`), [outgoing] may be omitted.
  ///
  /// Note that the peer won't begin listening to [incoming] until [Peer.listen]
  /// is called.
  Peer(Stream<String> incoming, [StreamSink<String> outgoing]) {
    _streams = new TwoWayStream("Peer", incoming, "incoming",
        outgoing, "outgoing", onInvalidInput: (message, error) {
      _streams.add(new RpcException(error_code.PARSE_ERROR,
          'Invalid JSON: ${error.message}').serialize(message));
    });

    _outgoingForwarder.stream.listen(_streams.add);
    _server = new Server.withoutJson(
        _serverIncomingForwarder.stream, _outgoingForwarder);
    _client = new Client.withoutJson(
        _clientIncomingForwarder.stream, _outgoingForwarder);
  }

  /// Creates a [Peer] that reads incoming decoded messages from [incoming] and
  /// writes outgoing decoded messages to [outgoing].
  ///
  /// Unlike [new Peer], this doesn't read or write JSON strings. Instead, it
  /// reads and writes decoded maps or lists.
  ///
  /// If [incoming] is a [StreamSink] as well as a [Stream], [outgoing] may be
  /// omitted.
  ///
  /// Note that the peer won't begin listening to [incoming] until
  /// [Peer.listen] is called.
  Peer.withoutJson(Stream incoming, [StreamSink outgoing]) {
    _streams = new TwoWayStream.withoutJson("Peer", incoming, "incoming",
        outgoing, "outgoing");

    _outgoingForwarder.stream.listen(_streams.add);
    _server = new Server.withoutJson(
        _serverIncomingForwarder.stream, _outgoingForwarder);
    _client = new Client.withoutJson(
        _clientIncomingForwarder.stream, _outgoingForwarder);
  }

  // Client methods.

  Future sendRequest(String method, [parameters]) =>
      _client.sendRequest(method, parameters);

  void sendNotification(String method, [parameters]) =>
      _client.sendNotification(method, parameters);

  withBatch(callback()) => _client.withBatch(callback);

  // Server methods.

  void registerMethod(String name, Function callback) =>
      _server.registerMethod(name, callback);

  void registerFallback(callback(Parameters parameters)) =>
      _server.registerFallback(callback);

  // Shared methods.

  Future listen() {
    _client.listen();
    _server.listen();
    return _streams.listen((message) {
      if (message is Map) {
        if (message.containsKey('result') || message.containsKey('error')) {
          _clientIncomingForwarder.add(message);
        } else {
          _serverIncomingForwarder.add(message);
        }
      } else if (message is List && message.isNotEmpty &&
                 message.first is Map) {
        if (message.first.containsKey('result') ||
            message.first.containsKey('error')) {
          _clientIncomingForwarder.add(message);
        } else {
          _serverIncomingForwarder.add(message);
        }
      } else {
        // Non-Map and -List messages are ill-formed, so we pass them to the
        // server since it knows how to send error responses.
        _serverIncomingForwarder.add(message);
      }
    });
  }

  Future close() =>
      Future.wait([_client.close(), _server.close(), _streams.close()]);
}
