// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library channel;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/src/protocol.dart';

/**
 * The abstract class [ClientCommunicationChannel] defines the behavior of
 * objects that allows an object to send [Request]s to [AnalysisServer] and to
 * receive both [Response]s and [Notification]s.
 */
abstract class ClientCommunicationChannel {

  /**
   * The stream of notifications from the server.
   */
  Stream<Notification> notificationStream;

  /**
   * The stream of responses from the server.
   */
  Stream<Response> responseStream;

  /**
   * Send the given [request] to the server
   * and return a future with the associated [Response].
   */
  Future<Response> sendRequest(Request request);

  /**
   * Close the channel to the server. Once called, all future communication
   * with the server via [sendRequest] will silently be ignored.
   */
  Future close();
}

/**
 * The abstract class [ServerCommunicationChannel] defines the behavior of
 * objects that allow an [AnalysisServer] to receive [Request]s and to return
 * both [Response]s and [Notification]s.
 */
abstract class ServerCommunicationChannel {
  /**
   * Listen to the channel for requests. If a request is received, invoke the
   * [onRequest] function. If an error is encountered while trying to read from
   * the socket, invoke the [onError] function. If the socket is closed by the
   * client, invoke the [onDone] function.
   * Only one listener is allowed per channel.
   */
  void listen(void onRequest(Request request), {void onError(), void onDone()});

  /**
   * Send the given [notification] to the client.
   */
  void sendNotification(Notification notification);

  /**
   * Send the given [response] to the client.
   */
  void sendResponse(Response response);
}

/**
 * Instances of the class [WebSocketClientChannel] implement a
 * [ClientCommunicationChannel] that uses a [WebSocket] to communicate with
 * servers.
 */
class WebSocketClientChannel implements ClientCommunicationChannel {
  /**
   * The socket being wrapped.
   */
  final WebSocket _socket;

  @override
  Stream<Response> responseStream;

  @override
  Stream<Notification> notificationStream;

  /**
   * Initialize a new [WebSocket] wrapper for the given [_socket].
   */
  WebSocketClientChannel(this._socket) {
    Stream jsonStream = _socket
        .where((data) => data is String)
        .transform(new _JsonStreamDecoder())
        .where((json) => json is Map)
        .asBroadcastStream();
    responseStream = jsonStream
        .where((json) => json[Notification.EVENT] == null)
        .transform(new _ResponseConverter())
        .asBroadcastStream();
    notificationStream = jsonStream
        .where((json) => json[Notification.EVENT] != null)
        .transform(new _NotificationConverter())
        .asBroadcastStream();
  }

  @override
  Future<Response> sendRequest(Request request) {
    String id = request.id;
    _socket.add(JSON.encode(request.toJson()));
    return responseStream.firstWhere((Response response) => response.id == id);
  }

  @override
  Future close() {
    return _socket.close();
  }
}

/**
 * Instances of the class [WebSocketServerChannel] implement a
 * [ServerCommunicationChannel] that uses a [WebSocket] to communicate with
 * clients.
 */
class WebSocketServerChannel implements ServerCommunicationChannel {
  /**
   * The socket being wrapped.
   */
  final WebSocket socket;

  /**
   * Initialize a newly create [WebSocket] wrapper to wrap the given [socket].
   */
  WebSocketServerChannel(this.socket);

  @override
  void listen(void onRequest(Request request), {void onError(), void onDone()}) {
    socket.listen((data) => _readRequest(data, onRequest), onError: onError,
        onDone: onDone);
  }

  @override
  void sendNotification(Notification notification) {
    socket.add(JSON.encode(notification.toJson()));
  }

  @override
  void sendResponse(Response response) {
    socket.add(JSON.encode(response.toJson()));
  }

  /**
   * Read a request from the given [data] and use the given function to handle
   * the request.
   */
  void _readRequest(Object data, void onRequest(Request request)) {
    if (data is List<int>) {
      sendResponse(new Response.invalidRequestFormat());
      return;
    }
    if (data is String) {
      // Parse the string as a JSON descriptor and process the resulting
      // structure as a request.
      Request request = new Request.fromString(data);
      if (request == null) {
        sendResponse(new Response.invalidRequestFormat());
        return;
      }
      onRequest(request);
    }
  }
}

/**
 * Instances of [_JsonStreamDecoder] convert JSON strings to JSON maps
 */
class _JsonStreamDecoder extends Converter<String, Map> {

  @override
  Map convert(String text) => JSON.decode(text);

  @override
  ChunkedConversionSink startChunkedConversion(ChunkedConversionSink sink) =>
      new _ChannelChunkSink<String, Map>(this, sink);
}

/**
 * Instances of [_ResponseConverter] convert JSON maps to [Response]s.
 */
class _ResponseConverter extends Converter<Map, Response> {

  @override
  Response convert(Map json) => new Response.fromJson(json);

  @override
  ChunkedConversionSink startChunkedConversion(ChunkedConversionSink sink) =>
      new _ChannelChunkSink<Map, Response>(this, sink);
}

/**
 * Instances of [_NotificationConverter] convert JSON maps to [Notification]s.
 */
class _NotificationConverter extends Converter<Map, Notification> {

  @override
  Notification convert(Map json) => new Notification.fromJson(json);

  @override
  ChunkedConversionSink startChunkedConversion(ChunkedConversionSink sink) =>
      new _ChannelChunkSink<Map, Notification>(this, sink);
}

/**
 * A [_ChannelChunkSink] uses a [Convter] to translate chunks.
 */
class _ChannelChunkSink<S, T> extends ChunkedConversionSink<S> {
  final Converter<S, T> _converter;
  final ChunkedConversionSink _chunkedSink;

  _ChannelChunkSink(this._converter, this._chunkedSink);

  @override
  void add(S chunk) {
    var convertedChunk = _converter.convert(chunk);
    if (convertedChunk != null) {
      _chunkedSink.add(convertedChunk);
    }
  }

  @override
  void close() => _chunkedSink.close();
}
