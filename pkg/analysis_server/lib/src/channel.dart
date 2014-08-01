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
 * objects that allow a client to send [Request]s to an [AnalysisServer] and to
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
  void listen(void onRequest(Request request), {Function onError, void onDone()});

  /**
   * Send the given [notification] to the client.
   */
  void sendNotification(Notification notification);

  /**
   * Send the given [response] to the client.
   */
  void sendResponse(Response response);

  /**
   * Close the communication channel.
   */
  void close();
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
  final WebSocket socket;

  @override
  Stream<Response> responseStream;

  @override
  Stream<Notification> notificationStream;

  /**
   * Initialize a new [WebSocket] wrapper for the given [socket].
   */
  WebSocketClientChannel(this.socket) {
    Stream jsonStream = socket
        .where((data) => data is String)
        .transform(new JsonStreamDecoder())
        .where((json) => json is Map)
        .asBroadcastStream();
    responseStream = jsonStream
        .where((json) => json[Notification.EVENT] == null)
        .transform(new ResponseConverter())
        .asBroadcastStream();
    notificationStream = jsonStream
        .where((json) => json[Notification.EVENT] != null)
        .transform(new NotificationConverter())
        .asBroadcastStream();
  }

  @override
  Future<Response> sendRequest(Request request) {
    String id = request.id;
    socket.add(JSON.encode(request.toJson()));
    return responseStream.firstWhere((Response response) => response.id == id);
  }

  @override
  Future close() {
    return socket.close();
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
    socket.listen((data) => readRequest(data, onRequest), onError: onError,
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
  void readRequest(Object data, void onRequest(Request request)) {
    if (data is String) {
      // Parse the string as a JSON descriptor and process the resulting
      // structure as a request.
      Request request = new Request.fromString(data);
      if (request == null) {
        sendResponse(new Response.invalidRequestFormat());
        return;
      }
      onRequest(request);
    } else if (data is List<int>) {
      // TODO(brianwilkerson) Implement a more efficient protocol.
      sendResponse(new Response.invalidRequestFormat());
    } else {
      sendResponse(new Response.invalidRequestFormat());
    }
  }

  @override
  void close() {
    socket.close(WebSocketStatus.NORMAL_CLOSURE);
  }
}

/**
 * Instances of the class [ByteStreamClientChannel] implement a
 * [ClientCommunicationChannel] that uses a stream and a sink (typically,
 * standard input and standard output) to communicate with servers.
 */
class ByteStreamClientChannel implements ClientCommunicationChannel {
  final Stream input;
  final IOSink output;

  @override
  Stream<Response> responseStream;

  @override
  Stream<Notification> notificationStream;

  ByteStreamClientChannel(this.input, this.output) {
    Stream jsonStream = input.transform((new Utf8Codec()).decoder)
        .transform(new LineSplitter())
        .transform(new JsonStreamDecoder())
        .where((json) => json is Map)
        .asBroadcastStream();
    responseStream = jsonStream
        .where((json) => json[Notification.EVENT] == null)
        .transform(new ResponseConverter())
        .asBroadcastStream();
    notificationStream = jsonStream
        .where((json) => json[Notification.EVENT] != null)
        .transform(new NotificationConverter())
        .asBroadcastStream();
  }

  @override
  Future close() {
    return output.close();
  }

  @override
  Future<Response> sendRequest(Request request) {
    String id = request.id;
    output.writeln(JSON.encode(request.toJson()));
    return responseStream.firstWhere((Response response) => response.id == id);
  }
}

/**
 * Instances of the class [ByteStreamServerChannel] implement a
 * [ServerCommunicationChannel] that uses a stream and a sink (typically,
 * standard input and standard output) to communicate with clients.
 */
class ByteStreamServerChannel implements ServerCommunicationChannel {
  final Stream input;
  final IOSink output;

  /**
   * Completer that will be signalled when the input stream is closed.
   */
  final Completer _closed = new Completer();

  ByteStreamServerChannel(this.input, this.output);

  /**
   * Future that will be completed when the input stream is closed.
   */
  Future get closed {
    return _closed.future;
  }

  @override
  void listen(void onRequest(Request request), {Function onError, void
      onDone()}) {
    input.transform((new Utf8Codec()).decoder).transform(new LineSplitter()
        ).listen((String data) => _readRequest(data, onRequest), onError: onError,
        onDone: () {
      close();
      onDone();
    });
  }

  @override
  void sendNotification(Notification notification) {
    // Don't send any further notifications after the communication channel is
    // closed.
    if (_closed.isCompleted) {
      return;
    }
    output.writeln(JSON.encode(notification.toJson()));
  }

  @override
  void sendResponse(Response response) {
    // Don't send any further responses after the communication channel is
    // closed.
    if (_closed.isCompleted) {
      return;
    }
    output.writeln(JSON.encode(response.toJson()));
  }

  /**
   * Read a request from the given [data] and use the given function to handle
   * the request.
   */
  void _readRequest(Object data, void onRequest(Request request)) {
    // Ignore any further requests after the communication channel is closed.
    if (_closed.isCompleted) {
      return;
    }
    // Parse the string as a JSON descriptor and process the resulting
    // structure as a request.
    Request request = new Request.fromString(data);
    if (request == null) {
      sendResponse(new Response.invalidRequestFormat());
      return;
    }
    onRequest(request);
  }

  @override
  void close() {
    if (!_closed.isCompleted) {
      _closed.complete();
    }
  }
}

/**
 * Instances of the class [JsonStreamDecoder] convert JSON strings to JSON
 * maps.
 */
class JsonStreamDecoder extends Converter<String, Map> {
  @override
  Map convert(String text) => JSON.decode(text);

  @override
  ChunkedConversionSink startChunkedConversion(Sink sink) =>
      new ChannelChunkSink<String, Map>(this, sink);
}

/**
 * Instances of the class [ResponseConverter] convert JSON maps to [Response]s.
 */
class ResponseConverter extends Converter<Map, Response> {
  @override
  Response convert(Map json) => new Response.fromJson(json);

  @override
  ChunkedConversionSink startChunkedConversion(Sink sink) =>
      new ChannelChunkSink<Map, Response>(this, sink);
}

/**
 * Instances of the class [NotificationConverter] convert JSON maps to
 * [Notification]s.
 */
class NotificationConverter extends Converter<Map, Notification> {
  @override
  Notification convert(Map json) => new Notification.fromJson(json);

  @override
  ChunkedConversionSink startChunkedConversion(Sink sink) =>
      new ChannelChunkSink<Map, Notification>(this, sink);
}

/**
 * Instances of the class [ChannelChunkSink] uses a [Converter] to translate
 * chunks.
 */
class ChannelChunkSink<S, T> extends ChunkedConversionSink<S> {
  /**
   * The converter used to translate chunks.
   */
  final Converter<S, T> converter;

  /**
   * The sink to which the converted chunks are added.
   */
  final Sink sink;

  /**
   * A flag indicating whether the sink has been closed.
   */
  bool closed = false;

  /**
   * Initialize a newly create sink to use the given [converter] to convert
   * chunks before adding them to the given [sink].
   */
  ChannelChunkSink(this.converter, this.sink);

  @override
  void add(S chunk) {
    if (!closed) {
      T convertedChunk = converter.convert(chunk);
      if (convertedChunk != null) {
        sink.add(convertedChunk);
      }
    }
  }

  @override
  void close() {
    closed = true;
    sink.close();
  }
}
