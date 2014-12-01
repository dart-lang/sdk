// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library channel;

import 'dart:async';
import 'dart:convert';

import 'package:analysis_server/src/protocol.dart';
import 'package:analyzer/src/util/utilities_timing.dart';

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
   * Close the channel to the server. Once called, all future communication
   * with the server via [sendRequest] will silently be ignored.
   */
  Future close();

  /**
   * Send the given [request] to the server
   * and return a future with the associated [Response].
   */
  Future<Response> sendRequest(Request request);
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
 * The abstract class [ServerCommunicationChannel] defines the behavior of
 * objects that allow an [AnalysisServer] to receive [Request]s and to return
 * both [Response]s and [Notification]s.
 */
abstract class ServerCommunicationChannel {
  /**
   * A stopwatch used to accumulate the amount of time spent converting
   * incomming requests from Json to objects.
   */
  static final CountedStopwatch FromJson = new CountedStopwatch();

  /**
   * A stopwatch used to accumulate the amount of time spent converting outgoing
   * responses and notifications from objects to Json.
   */
  static final CountedStopwatch ToJson = new CountedStopwatch();

  /**
   * Close the communication channel.
   */
  void close();

  /**
   * Listen to the channel for requests. If a request is received, invoke the
   * [onRequest] function. If an error is encountered while trying to read from
   * the socket, invoke the [onError] function. If the socket is closed by the
   * client, invoke the [onDone] function.
   * Only one listener is allowed per channel.
   */
  void listen(void onRequest(Request request), {Function onError, void
      onDone()});

  /**
   * Send the given [notification] to the client.
   */
  void sendNotification(Notification notification);

  /**
   * Send the given [response] to the client.
   */
  void sendResponse(Response response);
}
