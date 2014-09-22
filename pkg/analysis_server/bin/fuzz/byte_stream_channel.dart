// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library channel.byte_stream;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'channel.dart';
import 'protocol.dart';

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
  void close() {
    if (!_closed.isCompleted) {
      _closed.complete();
    }
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
}
