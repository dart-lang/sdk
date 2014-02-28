// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library channel;

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
   * Listen to the channel for responses and notifications.
   * If a response is received, invoke the [onResponse] function.
   * If a notification is received, invoke the [onNotification] function.
   * If an error is encountered while trying to read from
   * the socket, invoke the [onError] function. If the socket is closed by the
   * client, invoke the [onDone] function.
   */
  void listen(void onResponse(Response response),
              void onNotification(Notification notification),
              {void onError(), void onDone()});

  /**
   * Send the given [request] to the server.
   */
  void sendRequest(Request request);
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
  final WebSocket socket;

  final JsonEncoder jsonEncoder = const JsonEncoder(null);

  final JsonDecoder jsonDecoder = const JsonDecoder(null);

  /**
   * Initialize a newly create [WebSocket] wrapper to wrap the given [socket].
   */
  WebSocketClientChannel(this.socket);

  @override
  void listen(void onResponse(Response response),
              void onNotification(Notification notification),
              {void onError(), void onDone()}) {
    socket.listen((data) => _read(data, onResponse, onNotification),
        onError: onError, onDone: onDone);
  }

  @override
  void sendRequest(Request request) {
    socket.add(jsonEncoder.convert(request.toJson()));
  }

  /**
   * Read a request from the given [data] and use the given function to handle
   * the request.
   */
  void _read(Object data,
             void onResponse(Response response),
             void onNotification(Notification notification)) {
    if (data is String) {
      // Parse the string as a JSON descriptor
      var json;
      try {
        json = jsonDecoder.convert(data);
        if (json is! Map) {
          return;
        }
      } catch (error) {
        return;
      }
      // Process the resulting structure as a response or notification.
      if (json[Notification.EVENT] != null) {
        Notification notification = new Notification.fromJson(json);
        if (notification != null) {
          onNotification(notification);
        }
      } else {
        Response response = new Response.fromJson(json);
        if (response != null) {
          onResponse(response);
        }
      }
    }
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

  final JsonEncoder jsonEncoder = const JsonEncoder(null);

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
    socket.add(jsonEncoder.convert(notification.toJson()));
  }

  @override
  void sendResponse(Response response) {
    socket.add(jsonEncoder.convert(response.toJson()));
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
