// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library channel.web_socket;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';

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
  Future close() {
    return socket.close();
  }

  @override
  Future<Response> sendRequest(Request request) async {
    String id = request.id;
    socket.add(JSON.encode(request.toJson()));
    return await responseStream
        .firstWhere((Response response) => response.id == id);
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
   * The instrumentation service that is to be used by this analysis server.
   */
  final InstrumentationService instrumentationService;

  /**
   * Initialize a newly create [WebSocket] wrapper to wrap the given [socket].
   */
  WebSocketServerChannel(this.socket, this.instrumentationService);

  @override
  void close() {
    socket.close(WebSocketStatus.NORMAL_CLOSURE);
  }

  @override
  void listen(void onRequest(Request request),
      {Function onError, void onDone()}) {
    socket.listen((data) => readRequest(data, onRequest),
        onError: onError, onDone: onDone);
  }

  /**
   * Read a request from the given [data] and use the given function to handle
   * the request.
   */
  void readRequest(Object data, void onRequest(Request request)) {
    if (data is String) {
      instrumentationService.logRequest(data);
      // Parse the string as a JSON descriptor and process the resulting
      // structure as a request.
      ServerPerformanceStatistics.serverChannel.makeCurrentWhile(() {
        Request request = new Request.fromString(data);
        if (request == null) {
          sendResponse(new Response.invalidRequestFormat());
          return;
        }
        onRequest(request);
      });
    } else if (data is List<int>) {
      // TODO(brianwilkerson) Implement a more efficient protocol.
      sendResponse(new Response.invalidRequestFormat());
    } else {
      sendResponse(new Response.invalidRequestFormat());
    }
  }

  @override
  void sendNotification(Notification notification) {
    ServerPerformanceStatistics.serverChannel.makeCurrentWhile(() {
      String jsonEncoding = JSON.encode(notification.toJson());
      socket.add(jsonEncoding);
      instrumentationService.logNotification(jsonEncoding);
    });
  }

  @override
  void sendResponse(Response response) {
    ServerPerformanceStatistics.serverChannel.makeCurrentWhile(() {
      String jsonEncoding = JSON.encode(response.toJson());
      socket.add(jsonEncoding);
      instrumentationService.logResponse(jsonEncoding);
    });
  }
}
