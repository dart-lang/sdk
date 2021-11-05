// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/protocol/protocol.dart';

/// Instances of the class [ChannelChunkSink] uses a [Converter] to translate
/// chunks.
class ChannelChunkSink<S, T> extends ChunkedConversionSink<S> {
  /// The converter used to translate chunks.
  final Converter<S, T> converter;

  /// The sink to which the converted chunks are added.
  final Sink sink;

  /// A flag indicating whether the sink has been closed.
  bool closed = false;

  /// Initialize a newly create sink to use the given [converter] to convert
  /// chunks before adding them to the given [sink].
  ChannelChunkSink(this.converter, this.sink);

  @override
  void add(S chunk) {
    if (!closed) {
      var convertedChunk = converter.convert(chunk);
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

/// The abstract class [ClientCommunicationChannel] defines the behavior of
/// objects that allow a client to send [Request]s to an [AnalysisServer] and to
/// receive both [Response]s and [Notification]s.
abstract class ClientCommunicationChannel {
  /// The stream of notifications from the server.
  Stream<Notification> get notificationStream;

  /// The stream of responses from the server.
  Stream<Response> get responseStream;

  /// Close the channel to the server. Once called, all future communication
  /// with the server via [sendRequest] will silently be ignored.
  Future close();

  /// Send the given [request] to the server
  /// and return a future with the associated [Response].
  Future<Response> sendRequest(Request request);
}

/// Instances of the class [JsonStreamDecoder] convert JSON strings to values.
class JsonStreamDecoder extends Converter<String, Object?> {
  @override
  Object? convert(String text) => json.decode(text);

  @override
  ChunkedConversionSink<String> startChunkedConversion(Sink<Object?> sink) =>
      ChannelChunkSink<String, Object?>(this, sink);
}

/// Instances of the class [NotificationConverter] convert JSON maps to
/// [Notification]s.
class NotificationConverter
    extends Converter<Map<String, Object?>, Notification> {
  @override
  Notification convert(Map json) => Notification.fromJson(json);

  @override
  ChunkedConversionSink<Map<String, Object?>> startChunkedConversion(
          Sink<Notification> sink) =>
      ChannelChunkSink<Map<String, Object?>, Notification>(this, sink);
}

/// Instances of the class [ResponseConverter] convert JSON maps to [Response]s.
class ResponseConverter extends Converter<Map<String, Object?>, Response?> {
  @override
  Response? convert(Map<String, Object?> json) => Response.fromJson(json);

  @override
  ChunkedConversionSink<Map<String, Object?>> startChunkedConversion(
    Sink<Response?> sink,
  ) {
    return ChannelChunkSink<Map<String, Object?>, Response?>(this, sink);
  }
}

/// The abstract class [ServerCommunicationChannel] defines the behavior of
/// objects that allow an [AnalysisServer] to receive [Request]s and to return
/// both [Response]s and [Notification]s.
abstract class ServerCommunicationChannel {
  /// The single-subscription stream of requests.
  Stream<Request> get requests;

  /// Close the communication channel.
  void close();

  /// Send the given [notification] to the client.
  void sendNotification(Notification notification);

  /// Send the given [response] to the client.
  void sendResponse(Response response);
}
