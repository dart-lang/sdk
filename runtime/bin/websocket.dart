// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Web socket status codes used when closing a web socket connection.
 */
interface WebSocketStatus {
  static const int NORMAL_CLOSURE = 1000;
  static const int GOING_AWAY = 1001;
  static const int PROTOCOL_ERROR = 1002;
  static const int UNSUPPORTED_DATA = 1003;
  static const int RESERVED_1004  = 1004;
  static const int NO_STATUS_RECEIVED = 1005;
  static const int ABNORMAL_CLOSURE = 1006;
  static const int INVALID_FRAME_PAYLOAD_DATA = 1007;
  static const int POLICY_VIOLATION = 1008;
  static const int MESSAGE_TOO_BIG = 1009;
  static const int MISSING_MANDATORY_EXTENSION = 1010;
  static const int INTERNAL_SERVER_ERROR = 1011;
  static const int RESERVED_1015 = 1015;
}

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
 *
 * This handler strives to implement web sockets as specified by RFC6455.
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
interface WebSocketConnection extends Hashable {
  /**
   * Sets the callback to be called when a message have been
   * received. The type on [message] is either [:String:] or
   * [:List<int>:] depending on whether it is a text or binary
   * message. If the message is empty [message] will be [:null:].
   */
  void set onMessage(void callback(message));

  /**
   * Sets the callback to be called when the web socket connection is
   * closed. [status] indicate the reason for closing. For network
   * errors the value of [status] will be
   * WebSocketStatus.ABNORMAL_CLOSURE].
   */
  void set onClosed(void callback(int status, String reason));

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

  /**
   * WebSocketConnection is hashable.
   */
  int hashCode();
}


/**
 * Client web socket connection.
 */
interface WebSocketClientConnection
    extends Hashable default _WebSocketClientConnection {
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
   * closed. [status] indicate the reason for closing. For network
   * errors the value of [status] will be
   * WebSocketStatus.ABNORMAL_CLOSURE].
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

  /**
   * WebSocketClientConnection is hashable.
   */
  int hashCode();
}


/**
 * Base interface for the events generated by the W3C complient
 * browser API for web sockets.
 */
interface Event { }

/**
 * Event delivered when there is data on a web socket connection.
 */
interface MessageEvent extends Event default _WebSocketMessageEvent {
  /**
   * The type of [message] is either [:String:] or [:List<int>:]
   * depending on whether it is a text or binary message. If the
   * message is empty [message] will be [:null:]
   */
  get data;
}


/**
 * Event delivered when a web socket connection is closed.
 */
interface CloseEvent extends Event default _WebSocketCloseEvent {
  /**
   * Returns whether the connection was closed cleanly or not.
   */
  bool get wasClean;

  /**
   * Returns the web socket connection close code provided by the
   * server.
   */
  int get code;

  /**
   * Returns the web socket connection close reason provided by the
   * server.
   */
  String get reason;
}


/**
 * Alternative web socket client interface. This interface is compliant
 * with the W3C browser API for web sockets specified in
 * http://dev.w3.org/html5/websockets/.
 */
interface WebSocket default _WebSocket {
  /**
   * Possible states of the connection.
   */
  static const int CONNECTING = 0;
  static const int OPEN = 1;
  static const int CLOSING = 2;
  static const int CLOSED = 3;

  /**
   * Create a new web socket connection. The URL supplied in [url]
   * must use the scheme [:ws:]. The [protocols] argument is either a
   * [:String:] or [:List<String>:] specifying the subprotocols the
   * client is willing to speak.
   */
  WebSocket(String url, [protocols]);

  /**
   * Returns the current state of the connection.
   */
  int get readyState;

  /**
   * Returns the number of bytes currently buffered for transmission.
   */
  int get bufferedAmount;

  /**
   * Sets the callback to be called when a web socket connection has
   * been established.
   */
  void set onopen(void callback());

  /**
   * Sets the callback to be called when the web socket connection
   * encountered an error.
   */
  void set onerror(void callback(e));

  /**
   * Sets the callback to be called when the web socket connection is
   * closed.
   */
  void set onclose(void callback(CloseEvent event));

  /**
   * The extensions property is initially the empty string. After the
   * web socket connection is established this string reflects the
   * extensions used by the server.
   */
  String get extensions;

  /**
   * The protocol property is initially the empty string. After the
   * web socket connection is established the value is the subprotocol
   * selected by the server. If no subprotocol is negotiated the
   * value will remain [:null:].
   */
  String get protocol;

  /**
   * Closes the web socket connection.
   */
  void close(int code, String reason);

  /**
   * Sets the callback to be called when a message have been
   * received.
   */
  void set onmessage(void callback(MessageEvent event));

  /**
   * Sends data on the web socket connection. The data in [data] must
   * be either a [:String:] or [:List<int>:] holding bytes.
   */
  void send(data);
}


class WebSocketException implements Exception {
  const WebSocketException([String this.message = ""]);
  String toString() => "WebSocketException: $message";
  final String message;
}
