// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * Web socket status codes used when closing a web socket connection.
 */
abstract class WebSocketStatus {
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
 * The [WebSocketTransformer] provides the ability to upgrade a
 * [HttpRequest] to a [WebSocket] connection. It supports both
 * upgrading a single [HttpRequest] and upgrading a stream of
 * [HttpRequest]s.
 *
 * To upgrade a single [HttpRequest] use the static [upgrade] method.
 *
 *     HttpServer server;
 *     server.listen((request) {
 *       if (...) {
 *         WebSocketTransformer.upgrade(request).then((websocket) {
 *           ...
 *         });
 *       } else {
 *         // Do normal HTTP request processing.
 *       }
 *     });
 *
 * To transform a stream of [HttpRequest] events as it implements a
 * stream transformer that transforms a stream of HttpRequest into a
 * stream of WebSockets by upgrading each HttpRequest from the HTTP or
 * HTTPS server, to the WebSocket protocol.
 *
 *     server.transform(new WebSocketTransformer()).listen((webSocket) => ...);
 *
 * This transformer strives to implement web sockets as specified by RFC6455.
 */
abstract class WebSocketTransformer
    implements StreamTransformer<HttpRequest, WebSocket> {

  /**
   * Create a new [WebSocketTransformer].
   *
   * If [protocolSelector] is provided, [protocolSelector] will be called to
   * select what protocol to use, if any were provided by the client.
   * [protocolSelector] is should return either a [String] or a [Future]
   * completing with a [String]. The [String] must exist in the list of
   * protocols.
   */
  factory WebSocketTransformer({protocolSelector(List<String> protocols)})
      => new _WebSocketTransformerImpl(protocolSelector);

  /**
   * Upgrades a [HttpRequest] to a [WebSocket] connection. If the
   * request is not a valid web socket upgrade request a HTTP response
   * with status code 500 will be returned. Otherwise the returned
   * future will complete with the [WebSocket] when the upgrade pocess
   * is complete.
   *
   * If [protocolSelector] is provided, [protocolSelector] will be called to
   * select what protocol to use, if any were provided by the client.
   * [protocolSelector] is should return either a [String] or a [Future]
   * completing with a [String]. The [String] must exist in the list of
   * protocols.
   */
  static Future<WebSocket> upgrade(HttpRequest request,
                                   {protocolSelector(List<String> protocols)}) {
    return _WebSocketTransformerImpl._upgrade(request, protocolSelector);
  }

  /**
   * Checks whether the request is a valid WebSocket upgrade request.
   */
  static bool isUpgradeRequest(HttpRequest request) {
    return _WebSocketTransformerImpl._isUpgradeRequest(request);
  }
}


/**
 * A two-way HTTP communication object for client or server applications.
 *
 * The stream exposes the messages received. A text message will be of type
 * [:String:] and a binary message will be of type [:List<int>:].
 */
abstract class WebSocket implements Stream, StreamSink {
  /**
   * Possible states of the connection.
   */
  static const int CONNECTING = 0;
  static const int OPEN = 1;
  static const int CLOSING = 2;
  static const int CLOSED = 3;

  /**
   * Set and get the interval for sending ping signals. If a ping message is not
   * answered by a pong message from the peer, the `WebSocket` is assumed
   * disconnected and the connection is closed with a
   * [WebSocketStatus.GOING_AWAY] close code. When a ping signal is sent, the
   * pong message must be received within [pingInterval].
   *
   * There are never two outstanding pings at any given time, and the next ping
   * timer starts when the pong is received.
   *
   * Set the [pingInterval] to `null` to disable sending ping messages.
   *
   * The default value is `null`.
   */
  Duration pingInterval;

  /**
   * Create a new web socket connection. The URL supplied in [url]
   * must use the scheme [:ws:] or [:wss:]. The [protocols] argument is
   * specifying the subprotocols the client is willing to speak.
   */
  static Future<WebSocket> connect(String url,
                                   {List<String> protocols: const []}) =>
      _WebSocketImpl.connect(url, protocols);

  @Deprecated('This constructor will be removed in Dart 2.0. Use `implements`'
      ' instead of `extends` if implementing this abstract class.')
  WebSocket();

  /**
   * Creates a WebSocket from an already-upgraded socket.
   *
   * The initial WebSocket handshake must have occurred prior to this call. A
   * WebSocket client can automatically perform the handshake using
   * [WebSocket.connect], while a server can do so using
   * [WebSocketTransformer.upgrade]. To manually upgrade an [HttpRequest],
   * [HttpRequest.detachSocket] may be called.
   *
   * [protocol] should be the protocol negotiated by this handshake, if any.
   *
   * [serverSide] must be passed explicitly. If it's `false`, the WebSocket will
   * act as the client and mask the messages it sends. If it's `true`, it will
   * act as the server and will not mask its messages.
   */
  factory WebSocket.fromUpgradedSocket(Socket socket, {String protocol,
        bool serverSide}) {
    if (serverSide == null) {
      throw new ArgumentError("The serverSide argument must be passed "
          "explicitly to WebSocket.fromUpgradedSocket.");
    }
    return new _WebSocketImpl._fromSocket(socket, protocol, serverSide);
  }

  /**
   * Returns the current state of the connection.
   */
  int get readyState;

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
   * The close code set when the web socket connection is closed. If
   * there is no close code available this property will be [:null:]
   */
  int get closeCode;

  /**
   * The close reason set when the web socket connection is closed. If
   * there is no close reason available this property will be [:null:]
   */
  String get closeReason;

  /**
   * Closes the web socket connection. Set the optional [code] and [reason]
   * arguments to send close information to the remote peer. If they are
   * omitted, the peer will see [WebSocketStatus.NO_STATUS_RECEIVED] code
   * with no reason.
   */
  Future close([int code, String reason]);

  /**
   * Sends data on the web socket connection. The data in [data] must
   * be either a [:String:], or a [:List<int>:] holding bytes.
   */
  void add(data);

  /**
   * Sends data from a stream on web socket connection. Each data event from
   * [stream] will be send as a single WebSocket frame. The data from [stream]
   * must be either [:String:]s, or [:List<int>:]s holding bytes.
   */
  Future addStream(Stream stream);
}


class WebSocketException implements IOException {
  final String message;
  const WebSocketException([this.message = ""]);
  String toString() => "WebSocketException: $message";
}
