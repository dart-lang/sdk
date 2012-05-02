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
 * Server web socket connection.
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


/**
 * Client web socket connection.
 */
interface WebSocketClientConnection default _WebSocketClientConnection {
  /**
   * Creates a new web socket client connection based on a HTTP client
   * connection. The HTTP client connection must be freshly opened.
   */
  WebSocketClientConnection(HttpClientConnection conn,
                            [List<String> protocols]);

  /**
   * Sets the callback to be called when the request object for the
   * opening handshake request is ready. This callback can be used if
   * one need to add additional headers to the opening handshake
   * request.
   */
  void set onRequest(void callback(HttpClientRequest request));

  /**
   * Sets the callback to be called when a web socket connection has
   * been established.
   */
  void set onOpen(void callback());

  /**
   * Sets the callback to be called when a message have been
   * received. The type of [message] is either [:String:] or
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
   * Sets the callback to be called when the response object for the
   * opening handshake did not cause a web socket connection
   * upgrade. This will be called in case the response status code is
   * not 101 (Switching Protocols). If this callback is not set the
   * [:onError:] callback will be called if the server did not upgrade
   * the connection.
   */
  void set onNoUpgrade(void callback(HttpClientResponse response));

  /**
   * Sets the callback to be called when the web socket connection
   * encountered an error.
   */
  void set onError(void callback(e));

  /**
   * Sends a message. The [message] must be a [:String:] or a
   * [:List<int>:]. To send an empty message use either an empty
   * [:String:] or an empty [:List<int>:]. [:null:] cannot be used.
   */
  send(message);

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
