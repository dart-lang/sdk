// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._http;

/**
 * WebSocket status codes used when closing a WebSocket connection.
 */
abstract class WebSocketStatus {
  static const int NORMAL_CLOSURE = 1000;
  static const int GOING_AWAY = 1001;
  static const int PROTOCOL_ERROR = 1002;
  static const int UNSUPPORTED_DATA = 1003;
  static const int RESERVED_1004 = 1004;
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
 * The [CompressionOptions] class allows you to control
 * the options of WebSocket compression.
 */
class CompressionOptions {
  /**
   * Default WebSocket Compression options.
   * Compression will be enabled with the following options:
   * clientNoContextTakeover: false
   * serverNoContextTakeover: false
   * clientMaxWindowBits: 15
   * serverMaxWindowBits: 15
   */
  static const CompressionOptions DEFAULT = const CompressionOptions();

  /**
   * Disables WebSocket Compression.
   */
  static const CompressionOptions OFF =
      const CompressionOptions(enabled: false);

  /**
   * Control whether the client will reuse it's compression instances.
   */
  final bool clientNoContextTakeover;

  /**
   * Control whether the server will reuse it's compression instances.
   */
  final bool serverNoContextTakeover;

  /**
   * Sets the Max Window Bits for the Client.
   */
  final int clientMaxWindowBits;

  /**
   * Sets the Max Window Bits for the Server.
   */
  final int serverMaxWindowBits;

  /**
   * Enables or disables WebSocket compression.
   */
  final bool enabled;

  const CompressionOptions(
      {this.clientNoContextTakeover: false,
      this.serverNoContextTakeover: false,
      this.clientMaxWindowBits,
      this.serverMaxWindowBits,
      this.enabled: true});

  /// Parses list of requested server headers to return server compression
  /// response headers. Uses [serverMaxWindowBits] value if set, otherwise will
  /// attempt to use value from headers. Defaults to
  /// [WebSocket.DEFAULT_WINDOW_BITS]. Returns a [_CompressionMaxWindowBits]
  /// object which contains the response headers and negotiated max window bits.
  _CompressionMaxWindowBits _createServerResponseHeader(HeaderValue requested) {
    var info = new _CompressionMaxWindowBits();

    int mwb;
    String part;
    if (requested?.parameters != null) {
      part = requested.parameters[_serverMaxWindowBits];
    }
    if (part != null) {
      if (part.length >= 2 && part.startsWith('0')) {
        throw new ArgumentError("Illegal 0 padding on value.");
      } else {
        mwb = serverMaxWindowBits == null
            ? int.parse(part,
                onError: (source) => _WebSocketImpl.DEFAULT_WINDOW_BITS)
            : serverMaxWindowBits;
        info.headerValue = "; server_max_window_bits=${mwb}";
        info.maxWindowBits = mwb;
      }
    } else {
      info.headerValue = "";
      info.maxWindowBits = _WebSocketImpl.DEFAULT_WINDOW_BITS;
    }
    return info;
  }

  /// Returns default values for client compression request headers.
  String _createClientRequestHeader(HeaderValue requested, int size) {
    var info = "";

    // If responding to a valid request, specify size
    if (requested != null) {
      info = "; client_max_window_bits=$size";
    } else {
      // Client request. Specify default
      if (clientMaxWindowBits == null) {
        info = "; client_max_window_bits";
      } else {
        info = "; client_max_window_bits=$clientMaxWindowBits";
      }
      if (serverMaxWindowBits != null) {
        info += "; server_max_window_bits=$serverMaxWindowBits";
      }
    }

    return info;
  }

  /// Create a Compression Header. If [requested] is null or contains
  /// client request headers, returns Client compression request headers with
  /// default settings for `client_max_window_bits` header value.
  /// If [requested] contains server response headers this method returns
  /// a Server compression response header negotiating the max window bits
  /// for both client and server as requested server_max_window_bits value.
  /// This method returns a [_CompressionMaxWindowBits] object with the
  /// response headers and negotiated maxWindowBits value.
  _CompressionMaxWindowBits _createHeader([HeaderValue requested]) {
    var info = new _CompressionMaxWindowBits("", 0);
    if (!enabled) {
      return info;
    }

    info.headerValue = _WebSocketImpl.PER_MESSAGE_DEFLATE;

    if (clientNoContextTakeover &&
        (requested == null ||
            (requested != null &&
                requested.parameters.containsKey(_clientNoContextTakeover)))) {
      info.headerValue += "; client_no_context_takeover";
    }

    if (serverNoContextTakeover &&
        (requested == null ||
            (requested != null &&
                requested.parameters.containsKey(_serverNoContextTakeover)))) {
      info.headerValue += "; server_no_context_takeover";
    }

    var headerList = _createServerResponseHeader(requested);
    info.headerValue += headerList.headerValue;
    info.maxWindowBits = headerList.maxWindowBits;

    info.headerValue +=
        _createClientRequestHeader(requested, info.maxWindowBits);

    return info;
  }
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
 * This transformer strives to implement WebSockets as specified by RFC6455.
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
   *
   * If [compression] is provided, the [WebSocket] created will be configured
   * to negotiate with the specified [CompressionOptions]. If none is specified
   * then the [WebSocket] will be created with the default [CompressionOptions].
   */
  factory WebSocketTransformer(
      {/*String|Future<String>*/ protocolSelector(List<String> protocols),
      CompressionOptions compression: CompressionOptions.DEFAULT}) {
    return new _WebSocketTransformerImpl(protocolSelector, compression);
  }

  /**
   * Upgrades a [HttpRequest] to a [WebSocket] connection. If the
   * request is not a valid WebSocket upgrade request an HTTP response
   * with status code 500 will be returned. Otherwise the returned
   * future will complete with the [WebSocket] when the upgrade process
   * is complete.
   *
   * If [protocolSelector] is provided, [protocolSelector] will be called to
   * select what protocol to use, if any were provided by the client.
   * [protocolSelector] is should return either a [String] or a [Future]
   * completing with a [String]. The [String] must exist in the list of
   * protocols.
   *
   * If [compression] is provided, the [WebSocket] created will be configured
   * to negotiate with the specified [CompressionOptions]. If none is specified
   * then the [WebSocket] will be created with the default [CompressionOptions].
   */
  static Future<WebSocket> upgrade(HttpRequest request,
      {protocolSelector(List<String> protocols),
      CompressionOptions compression: CompressionOptions.DEFAULT}) {
    return _WebSocketTransformerImpl._upgrade(
        request, protocolSelector, compression);
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
 * `String` and a binary message will be of type `List<int>`.
 */
abstract class WebSocket
    implements
        Stream<dynamic /*String|List<int>*/ >,
        StreamSink<dynamic /*String|List<int>*/ > {
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
   * Create a new WebSocket connection. The URL supplied in [url]
   * must use the scheme `ws` or `wss`.
   *
   * The [protocols] argument is specifying the subprotocols the
   * client is willing to speak.
   *
   * The [headers] argument is specifying additional HTTP headers for
   * setting up the connection. This would typically be the `Origin`
   * header and potentially cookies. The keys of the map are the header
   * fields and the values are either String or List<String>.
   *
   * If [headers] is provided, there are a number of headers
   * which are controlled by the WebSocket connection process. These
   * headers are:
   *
   *   - `connection`
   *   - `sec-websocket-key`
   *   - `sec-websocket-protocol`
   *   - `sec-websocket-version`
   *   - `upgrade`
   *
   * If any of these are passed in the `headers` map they will be ignored.
   *
   * If the `url` contains user information this will be passed as basic
   * authentication when setting up the connection.
   */
  static Future<WebSocket> connect(String url,
          {Iterable<String> protocols,
          Map<String, dynamic> headers,
          CompressionOptions compression: CompressionOptions.DEFAULT}) =>
      _WebSocketImpl.connect(url, protocols, headers, compression: compression);

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
   * [HttpResponse.detachSocket] may be called.
   *
   * [protocol] should be the protocol negotiated by this handshake, if any.
   *
   * [serverSide] must be passed explicitly. If it's `false`, the WebSocket will
   * act as the client and mask the messages it sends. If it's `true`, it will
   * act as the server and will not mask its messages.
   *
   * If [compression] is provided, the [WebSocket] created will be configured
   * to negotiate with the specified [CompressionOptions]. If none is specified
   * then the [WebSocket] will be created with the default [CompressionOptions].
   */
  factory WebSocket.fromUpgradedSocket(Socket socket,
      {String protocol,
      bool serverSide,
      CompressionOptions compression: CompressionOptions.DEFAULT}) {
    if (serverSide == null) {
      throw new ArgumentError("The serverSide argument must be passed "
          "explicitly to WebSocket.fromUpgradedSocket.");
    }
    return new _WebSocketImpl._fromSocket(
        socket, protocol, compression, serverSide);
  }

  /**
   * Returns the current state of the connection.
   */
  int get readyState;

  /**
   * The extensions property is initially the empty string. After the
   * WebSocket connection is established this string reflects the
   * extensions used by the server.
   */
  String get extensions;

  /**
   * The protocol property is initially the empty string. After the
   * WebSocket connection is established the value is the subprotocol
   * selected by the server. If no subprotocol is negotiated the
   * value will remain [:null:].
   */
  String get protocol;

  /**
   * The close code set when the WebSocket connection is closed. If
   * there is no close code available this property will be [:null:]
   */
  int get closeCode;

  /**
   * The close reason set when the WebSocket connection is closed. If
   * there is no close reason available this property will be [:null:]
   */
  String get closeReason;

  /**
   * Closes the WebSocket connection. Set the optional [code] and [reason]
   * arguments to send close information to the remote peer. If they are
   * omitted, the peer will see [WebSocketStatus.NO_STATUS_RECEIVED] code
   * with no reason.
   */
  Future close([int code, String reason]);

  /**
   * Sends data on the WebSocket connection. The data in [data] must
   * be either a `String`, or a `List<int>` holding bytes.
   */
  void add(/*String|List<int>*/ data);

  /**
   * Sends data from a stream on WebSocket connection. Each data event from
   * [stream] will be send as a single WebSocket frame. The data from [stream]
   * must be either `String`s, or `List<int>`s holding bytes.
   */
  Future addStream(Stream stream);

  /**
   * Sends a text message with the text represented by [bytes].
   *
   * The [bytes] should be valid UTF-8 encoded Unicode characters. If they are
   * not, the receiving end will close the connection.
   */
  void addUtf8Text(List<int> bytes);

  /**
   * Gets the user agent used for WebSocket connections.
   */
  static String get userAgent => _WebSocketImpl.userAgent;

  /**
   * Sets the user agent to use for WebSocket connections.
   */
  static set userAgent(String userAgent) {
    _WebSocketImpl.userAgent = userAgent;
  }
}

class WebSocketException implements IOException {
  final String message;

  const WebSocketException([this.message = ""]);

  String toString() => "WebSocketException: $message";
}
