// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library channel;

import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/src/protocol.dart';

/**
 * The abstract class [CommunicationChannel] defines the behavior of objects
 * that allow an [AnalysisServer] to receive [Request]s and to return both
 * [Response]s and [Notification]s.
 */
abstract class CommunicationChannel {
  /**
   * Listen to the channel for requests. If a request is received, invoke the
   * [onRequest] function. If an error is encountered while trying to read from
   * the socket, invoke the [onError] function. If the socket is closed by the
   * client, invoke the [onDone] function.
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
 * Instances of the class [WebSocketChannel] implement a [CommunicationChannel]
 * that uses a [WebSocket] to communicate with clients.
 */
class WebSocketChannel implements CommunicationChannel {
  /**
   * The socket being wrapped.
   */
  final WebSocket socket;

  /**
   * Initialize a newly create [WebSocket] wrapper to wrap the given [socket].
   */
  WebSocketChannel(this.socket);

  @override
  void listen(void onRequest(Request request), {void onError(), void onDone()}) {
    socket.listen((data) => _readRequest(data, onRequest), onError: onError, onDone: onDone);
  }

  @override
  void sendNotification(Notification notification) {
    JsonEncoder encoder = const JsonEncoder(null);
    socket.add(encoder.convert(notification.toJson()));
  }

  @override
  void sendResponse(Response response) {
    JsonEncoder encoder = const JsonEncoder(null);
    socket.add(encoder.convert(response.toJson()));
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
