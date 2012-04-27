// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The web socket protocol is implemented by a HTTP server handler
 * which can be instantiated like this:
 *
 *     WebSocketHandler wsHandler = new WebSocketHandler();
 *
 * and then its onRequest method can be assigned to the HTTP server, e.g.
 *
 *     server.defaultHandler = wsHandler.onRequest;
 *
 * or
 *
 *     server.addRequestHandler((req) => req.path == "/ws",
 *                              wsHandler.onRequest);
 */
interface WebSocketHandler default _WebSocketHandler {
  WebSocketHandler();

  /**
   * Request handler to be registered with the HTTP server.
   */
  void onRequest(HttpRequest request, HttpResponse response);

  /**
   * Sets the callback to be called when a new web socket connection
   * has been established.
   */
  void set onOpen(callback(WebSocketConnection connection));
}


/**
 * Web socket connection.
 */
interface WebSocketConnection {
  /**
   * Sets the callback to be called when a message have been
   * received. The type on [message] is either [:String:] or
   * [:List<int>:] depending on whether it is a text or binary
   * message. If the message is empty [message] will be [:null:].
   */
  void set onMessage(void callback(message));

  /**
   * Sets the callback to be called when the web socket connection is
   * closed.
   */
  void set onClosed(void callback(int status, String reason));

  /**
   * Sets the callback to be called when the web socket connection
   * encountered an error.
   */
  void set onError(void callback(e));

  /**
   * Sends a message. The [message] must be a [:String:] a
   * [:List<int>:] or [:null:].
   */
  send(Object message);

  /**
   * Close the web socket connection. The default value for [status]
   * and [reason] are [:null:].
   */
  close([int status, String reason]);
}


class WebSocketException implements Exception {
  const WebSocketException([String this.message = ""]);
  String toString() => "WebSocketException: $message";
  final String message;
}
