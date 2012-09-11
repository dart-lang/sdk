// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const String _webSocketGUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

class _WebSocketMessageType {
  static const int NONE = 0;
  static const int BINARY = 1;
  static const int TEXT = 2;
}


class _WebSocketOpcode {
  static const int CONTINUATION = 0;
  static const int TEXT = 1;
  static const int BINARY = 2;
  static const int RESERVED_3 = 3;
  static const int RESERVED_4 = 4;
  static const int RESERVED_5 = 5;
  static const int RESERVED_6 = 6;
  static const int RESERVED_7 = 7;
  static const int CLOSE = 8;
  static const int PING = 9;
  static const int PONG = 10;
  static const int RESERVED_B = 11;
  static const int RESERVED_C = 12;
  static const int RESERVED_D = 13;
  static const int RESERVED_E = 14;
  static const int RESERVED_F = 15;
}

/**
 * The web socket protocol processor handles the protocol byte stream
 * which is supplied through the [:update:] and [:closed:]
 * methods. As the protocol is processed the following callbacks are
 * called:
 *
 *   [:onMessageStart:]
 *   [:onMessageData:]
 *   [:onMessageEnd:]
 *   [:onClosed:]
 *   [:onError:]
 *
 */
class _WebSocketProtocolProcessor {
  static const int START = 0;
  static const int LEN_FIRST = 1;
  static const int LEN_REST = 2;
  static const int MASK = 3;
  static const int PAYLOAD = 4;
  static const int CLOSED = 5;
  static const int FAILURE = 6;

  _WebSocketProtocolProcessor() {
    _prepareForNextFrame();
    _currentMessageType = _WebSocketMessageType.NONE;
  }

  /**
   * Process data received from the underlying communication channel.
   */
  void update(List<int> buffer, int offset, int count) {
    int index = offset;
    int lastIndex = offset + count;
    try {
      if (_state == CLOSED) {
        throw new WebSocketException("Data on closed connection");
      }
      if (_state == FAILURE) {
        throw new WebSocketException("Data on failed connection");
      }
      while ((index < lastIndex) && _state != CLOSED && _state != FAILURE) {
        int byte = buffer[index];
        switch (_state) {
          case START:
            _fin = (byte & 0x80) != 0;
            _opcode = (byte & 0xF);
            switch (_opcode) {
            case _WebSocketOpcode.CONTINUATION:
              if (_currentMessageType == _WebSocketMessageType.NONE) {
                throw new WebSocketException("Protocol error");
              }
              break;

            case _WebSocketOpcode.TEXT:
              if (_currentMessageType != _WebSocketMessageType.NONE) {
                throw new WebSocketException("Protocol error");
              }
              _currentMessageType = _WebSocketMessageType.TEXT;
              if (onMessageStart !== null) {
                onMessageStart(_WebSocketMessageType.TEXT);
              }
              break;

            case _WebSocketOpcode.BINARY:
              if (_currentMessageType != _WebSocketMessageType.NONE) {
                throw new WebSocketException("Protocol error");
              }
              _currentMessageType = _WebSocketMessageType.BINARY;
              if (onMessageStart !== null) {
                onMessageStart(_WebSocketMessageType.BINARY);
              }
              break;

            case _WebSocketOpcode.CLOSE:
            case _WebSocketOpcode.PING:
            case _WebSocketOpcode.PONG:
              // Control frames cannot be fragmented.
              if (!_fin) throw new WebSocketException("Protocol error");
              break;

            default:
              throw new WebSocketException("Protocol error");
            }
            _state = LEN_FIRST;
            break;

          case LEN_FIRST:
            _masked = (byte & 0x80) != 0;
            _len = byte & 0x7F;
            if (_isControlFrame() && _len > 126) {
              throw new WebSocketException("Protocol error");
            }
            if (_len < 126) {
              _lengthDone();
            } else if (_len == 126) {
              _len = 0;
              _remainingLenBytes = 2;
              _state = LEN_REST;
            } else if (_len == 127) {
              _len = 0;
              _remainingLenBytes = 8;
              _state = LEN_REST;
            }
            break;

          case LEN_REST:
            _len = _len << 8 | byte;
            _remainingLenBytes--;
            if (_remainingLenBytes == 0) {
              _lengthDone();
            }
            break;

          case MASK:
            _maskingKey = _maskingKey << 8 | byte;
            _remainingMaskingKeyBytes--;
            if (_remainingMaskingKeyBytes == 0) {
              _maskDone();
            }
            break;

          case PAYLOAD:
            // The payload is not handled one byte at a time but in blocks.
            int payload;
            if (lastIndex - index <= _remainingPayloadBytes) {
              payload = lastIndex - index;
            } else {
              payload = _remainingPayloadBytes;
            }
            _remainingPayloadBytes -= payload;

            // Unmask payload if masked.
            if (_masked) {
              for (int i = 0; i < payload; i++) {
                int maskingByte =
                    ((_maskingKey >> ((3 - _unmaskingIndex) * 8)) & 0xFF);
                buffer[index + i] = buffer[index + i] ^ maskingByte;
                _unmaskingIndex = (_unmaskingIndex + 1) % 4;
              }
            }

            if (_isControlFrame()) {
              if (payload > 0) {
                // Allocate a buffer for collecting the control frame
                // payload if any.
                if (_controlPayload == null) {
                  _controlPayload = new List<int>();
                }
                _controlPayload.addAll(buffer.getRange(index, payload));
                index += payload;
              }

              if (_remainingPayloadBytes == 0) {
                _controlFrameEnd();
              }
            } else {
              switch (_currentMessageType) {
                case _WebSocketMessageType.NONE:
                  throw new WebSocketException("Protocol error");

                case _WebSocketMessageType.TEXT:
                case _WebSocketMessageType.BINARY:
                  if (onMessageData !== null) {
                    onMessageData(buffer, index, payload);
                  }
                  index += payload;
                  if (_remainingPayloadBytes == 0) {
                    _messageFrameEnd();
                  }
                  break;

                default:
                  throw new WebSocketException("Protocol error");
              }
            }

            // Hack - as we always do index++ below.
            index--;
        }

        // Move to the next byte.
        index++;
      }
    } catch (e) {
      if (onClosed !== null) onClosed(1002, "Protocol error");
      _state = FAILURE;
    }
  }

  /**
   * Indicate that the underlying communication channel has been closed.
   */
  void closed() {
    if (_state == START || _state == CLOSED || _state == FAILURE) return;
    if (onClosed !== null) onClosed(1006, "Connection closed unexpectedly");
    _state = CLOSED;
  }

  void _lengthDone() {
    if (_masked) {
      _state = MASK;
      _remainingMaskingKeyBytes = 4;
    } else {
      _remainingPayloadBytes = _len;
      _startPayload();
    }
  }

  void _maskDone() {
    _remainingPayloadBytes = _len;
    _startPayload();
  }

  void _startPayload() {
    // If there is no actual payload perform perform callbacks without
    // going through the PAYLOAD state.
    if (_remainingPayloadBytes == 0) {
      if (_isControlFrame()) {
        switch (_opcode) {
          case _WebSocketOpcode.CLOSE:
            if (onClosed !== null) onClosed(1005, "");
            _state = CLOSED;
            break;
          case _WebSocketOpcode.PING:
            if (onPing !== null) onPing(null);
            break;
          case _WebSocketOpcode.PONG:
            if (onPong !== null) onPong(null);
            break;
        }
        _prepareForNextFrame();
      } else {
        _messageFrameEnd();
      }
    } else {
      _state = PAYLOAD;
    }
  }

  void _messageFrameEnd() {
    if (_fin) {
      if (onMessageEnd !== null) onMessageEnd();
      _currentMessageType = _WebSocketMessageType.NONE;
    }
    _prepareForNextFrame();
  }

  void _controlFrameEnd() {
    switch (_opcode) {
      case _WebSocketOpcode.CLOSE:
        int status = 1005;
        String reason = "";
        if (_controlPayload.length > 0) {
          if (_controlPayload.length == 1) {
            throw new WebSocketException("Protocol error");
          }
          status = _controlPayload[0] << 8 | _controlPayload[1];
          if (_controlPayload.length > 2) {
            var decoder = _StringDecoders.decoder(Encoding.UTF_8);
            decoder.write(
                _controlPayload.getRange(2, _controlPayload.length - 2));
            reason = decoder.decoded;
          }
        }
        if (onClosed !== null) onClosed(status, reason);
        _state = CLOSED;
        break;

      case _WebSocketOpcode.PING:
        if (onPing !== null) onPing(_controlPayload);
        break;

      case _WebSocketOpcode.PONG:
        if (onPong !== null) onPong(_controlPayload);
        break;
    }
    _prepareForNextFrame();
  }

  bool _isControlFrame() {
    return _opcode == _WebSocketOpcode.CLOSE ||
           _opcode == _WebSocketOpcode.PING ||
           _opcode == _WebSocketOpcode.PONG;
  }

  void _prepareForNextFrame() {
    if (_state != CLOSED && _state != FAILURE) _state = START;
    _fin = null;
    _opcode = null;
    _len = null;
    _masked = null;
    _maskingKey = 0;
    _remainingLenBytes = null;
    _remainingMaskingKeyBytes = null;
    _remainingPayloadBytes = null;
    _unmaskingIndex = 0;
    _controlPayload = null;
  }

  int _state;
  bool _fin;
  int _opcode;
  int _len;
  bool _masked;
  int _maskingKey;
  int _remainingLenBytes;
  int _remainingMaskingKeyBytes;
  int _remainingPayloadBytes;
  int _unmaskingIndex;

  int _currentMessageType;
  List<int> _controlPayload;

  Function onMessageStart;
  Function onMessageData;
  Function onMessageEnd;
  Function onPing;
  Function onPong;
  Function onClosed;
}


class _WebSocketConnectionBase  {
  void _socketConnected(Socket socket) {
    _socket = socket;
    _socket.onError = (e) => _socket.close();
  }

  void _startProcessing(List<int> unparsedData) {
    _WebSocketProtocolProcessor processor = new _WebSocketProtocolProcessor();
    processor.onMessageStart = _onWebSocketMessageStart;
    processor.onMessageData = _onWebSocketMessageData;
    processor.onMessageEnd = _onWebSocketMessageEnd;
    processor.onPing = _onWebSocketPing;
    processor.onPong = _onWebSocketPong;
    processor.onClosed = _onWebSocketClosed;
    if (unparsedData !== null) {
      processor.update(unparsedData, 0, unparsedData.length);
    }
    _socket.onData = () {
      int available = _socket.available();
      List<int> data = new List<int>(available);
      int read = _socket.readList(data, 0, available);
      processor.update(data, 0, read);
    };
    _socket.onClosed = () {
      processor.closed();
      if (_closeSent) {
        // Got socket close in response to close frame. Don't treat
        // that as an error.
        if (_closeTimer !== null) _closeTimer.cancel();
      } else {
        if (_onClosed !== null) _onClosed(1006, "Unexpected close");
      }
      _socket.close();
    };
  }

  void set onMessage(void callback(Object message)) {
    _onMessage = callback;
  }

  void set onClosed(void callback(int status, String reason)) {
    _onClosed = callback;
  }

  send(message) {
    if (_closeSent) {
      throw new WebSocketException("Connection closed");
    }
    List<int> data;
    int opcode;
    if (message !== null) {
      if (message is String) {
        opcode = _WebSocketOpcode.TEXT;
        data = _StringEncoders.encoder(Encoding.UTF_8).encodeString(message);
      } else {
        if (message is !List<int>) {
          throw new IllegalArgumentException(message);
        }
        opcode = _WebSocketOpcode.BINARY;
        data = message;
      }
    } else {
      opcode = _WebSocketOpcode.TEXT;
    }
    _sendFrame(opcode, data);
  }

  close([int status, String reason]) {
    if (_closeSent) return;
    List<int> data;
    if (status !== null) {
      data = new List<int>();
      data.add((status >> 8) & 0xFF);
      data.add(status & 0xFF);
      if (reason !== null) {
        data.addAll(
           _StringEncoders.encoder(Encoding.UTF_8).encodeString(reason));
      }
    }
    _sendFrame(_WebSocketOpcode.CLOSE, data);

    if (_closeReceived) {
      // Close the socket when the close frame has been sent - if it
      // does not take too long.
      _socket.outputStream.close();
      _socket.outputStream.onClosed = () {
        if (_closeTimer !== null) _closeTimer.cancel();
        _socket.close();
      };
      _closeTimer = new Timer(5000, (t) {
        _socket.close();
      });
    } else {
      // Half close the socket and expect a close frame in response
      // before closing the socket. If a close frame does not arrive
      // within a reasonable amount of time just close the socket.
      _socket.outputStream.close();
      _closeTimer = new Timer(5000, (t) {
        _socket.close();
      });
    }
    _closeSent = true;
  }

  int hashCode() => _hash;

  _onWebSocketMessageStart(int type) {
    _currentMessageType = type;
    if (_currentMessageType == _WebSocketMessageType.TEXT) {
      _decoder = _StringDecoders.decoder(Encoding.UTF_8);
    } else {
      _outputStream = new ListOutputStream();
    }
  }

  _onWebSocketMessageData(List<int> buffer, int offset, int count) {
    if (_currentMessageType == _WebSocketMessageType.TEXT) {
      _decoder.write(buffer.getRange(offset, count));
    } else {
      _outputStream.write(buffer.getRange(offset, count));
    }
  }

  _onWebSocketMessageEnd() {
    if (_onMessage !== null) {
      if (_currentMessageType == _WebSocketMessageType.TEXT) {
        _onMessage(_decoder.decoded);
      } else {
        _onMessage(_outputStream.read());
      }
    }
    _decoder = null;
    _outputStream = null;
  }

  _onWebSocketPing(List<int> payload) {
    _sendFrame(_WebSocketOpcode.PONG, payload);
  }

  _onWebSocketPong(List<int> payload) {
    // Currently pong messages are ignored.
  }

  _onWebSocketClosed(int status, String reason) {
    _closeReceived = true;
    if (_onClosed !== null) _onClosed(status, reason);
    if (_closeSent) {
      // Got close frame in response to close frame. Now close the socket.
      if (_closeTimer !== null) _closeTimer.cancel();
      _socket.close();
    } else {
      close(status);
    }
  }

  _sendFrame(int opcode, [List<int> data]) {
    bool mask = false;  // Masking not implemented for server.
    int dataLength = data == null ? 0 : data.length;
    // Determine the header size.
    int headerSize = (mask) ? 6 : 2;
    if (dataLength > 65535) {
      headerSize += 8;
    } else if (dataLength > 125) {
      headerSize += 2;
    }
    List<int> header = new List<int>(headerSize);
    int index = 0;
    // Set FIN and opcode.
    header[index++] = 0x80 | opcode;
    // Determine size and position of length field.
    int lengthBytes = 1;
    int firstLengthByte = 1;
    if (dataLength > 65535) {
      header[index++] = 127;
      lengthBytes = 8;
    } else if (dataLength > 125) {
      header[index++] = 126;
      lengthBytes = 2;
    }
    // Write the length in network byte order into the header.
    for (int i = 0; i < lengthBytes; i++) {
      header[index++] = dataLength >> (((lengthBytes - 1) - i) * 8) & 0xFF;
    }
    assert(index == headerSize);
    _socket.outputStream.write(header);
    if (data !== null) {
      _socket.outputStream.write(data);
    }
  }

  Socket _socket;
  Timer _closeTimer;
  int _hash;

  Function _onMessage;
  Function _onClosed;

  int _currentMessageType = _WebSocketMessageType.NONE;
  _StringDecoder _decoder;
  ListOutputStream _outputStream;
  bool _closeReceived = false;
  bool _closeSent = false;
}


class _WebSocketConnection
    extends _WebSocketConnectionBase implements WebSocketConnection {
  _WebSocketConnection(DetachedSocket detached) {
    _hash = detached.socket.hashCode();
    _socketConnected(detached.socket);
    _startProcessing(detached.unparsedData);
  }
}


class _WebSocketHandler implements WebSocketHandler {
  void onRequest(HttpRequest request, HttpResponse response) {
    // Check that this is a web socket upgrade.
    if (!_isWebSocketUpgrade(request)) {
      response.statusCode = HttpStatus.BAD_REQUEST;
      response.outputStream.close();
      return;
    }

    // Send the upgrade response.
    response.statusCode = HttpStatus.SWITCHING_PROTOCOLS;
    response.headers.add(HttpHeaders.CONNECTION, "Upgrade");
    response.headers.add(HttpHeaders.UPGRADE, "websocket");
    String key = request.headers.value("Sec-WebSocket-Key");
    SHA1 sha1 = new SHA1();
    sha1.update("$key$_webSocketGUID".charCodes());
    String accept = _Base64._encode(sha1.digest());
    response.headers.add("Sec-WebSocket-Accept", accept);
    response.contentLength = 0;

    // Upgrade the connection and get the underlying socket.
    WebSocketConnection conn =
        new _WebSocketConnection(response.detachSocket());
    if (_onOpen !== null) _onOpen(conn);
  }

  void set onOpen(callback(WebSocketConnection connection)) {
    _onOpen = callback;
  }

  bool _isWebSocketUpgrade(HttpRequest request) {
    if (request.method != "GET") {
      return false;
    }
    if (request.headers[HttpHeaders.CONNECTION] == null) {
      return false;
    }
    bool isUpgrade = false;
    request.headers[HttpHeaders.CONNECTION].forEach((String value) {
      if (value.toLowerCase() == "upgrade") isUpgrade = true;
    });
    if (!isUpgrade) return false;
    String upgrade = request.headers.value(HttpHeaders.UPGRADE);
    if (upgrade == null || upgrade.toLowerCase() != "websocket") {
      return false;
    }
    String version = request.headers.value("Sec-WebSocket-Version");
    if (version == null || version != "13") {
      return false;
    }
    String key = request.headers.value("Sec-WebSocket-Key");
    if (key == null) {
      return false;
    }
    return true;
  }

  Function _onOpen;
}


class _WebSocketClientConnection
    extends _WebSocketConnectionBase implements WebSocketClientConnection {
  _WebSocketClientConnection(HttpClientConnection this._conn,
                             [List<String> protocols]) {
    _conn.onRequest = _onHttpClientRequest;
    _conn.onResponse = _onHttpClientResponse;
    _conn.onError = (e) {
      if (_onClosed !== null) {
        _onClosed(1006, "$e");
      }
    };

    // Generate the nonce now as it is also used to set the hash code.
    _generateNonceAndHash();
  }

  void set onRequest(void callback(HttpClientRequest request)) {
    _onRequest = callback;
  }

  void set onOpen(void callback()) {
    _onOpen = callback;
  }

  void set onNoUpgrade(void callback(HttpClientResponse request)) {
    _onNoUpgrade = callback;
  }

  void _onHttpClientRequest(HttpClientRequest request) {
    if (_onRequest !== null) {
      _onRequest(request);
    }
    // Setup the initial handshake.
    request.headers.add(HttpHeaders.CONNECTION, "upgrade");
    request.headers.set(HttpHeaders.UPGRADE, "websocket");
    request.headers.set("Sec-WebSocket-Key", _nonce);
    request.headers.set("Sec-WebSocket-Version", "13");
    request.contentLength = 0;
    request.outputStream.close();
  }

  void _onHttpClientResponse(HttpClientResponse response) {
    if (response.statusCode != HttpStatus.SWITCHING_PROTOCOLS) {
      if (_onNoUpgrade !== null) {
        _onNoUpgrade(response);
      } else {
        _conn.detachSocket().socket.close();
        throw new WebSocketException("Protocol upgrade refused");
      }
      return;
    }

    if (!_isWebSocketUpgrade(response)) {
      _conn.detachSocket().socket.close();
      throw new WebSocketException("Protocol upgrade failed");
      return;
    }

    // Connection upgrade successful.
    DetachedSocket detached = _conn.detachSocket();
    _socketConnected(detached.socket);
    if (_onOpen !== null) _onOpen();
    _startProcessing(detached.unparsedData);
  }

  void _generateNonceAndHash() {
    Random random = new Random();
    assert(_nonce == null);
    void intToBigEndianBytes(int value, List<int> bytes, int offset) {
      bytes[offset] = (value >> 24) & 0xFF;
      bytes[offset + 1] = (value >> 16) & 0xFF;
      bytes[offset + 2] = (value >> 8) & 0xFF;
      bytes[offset + 3] = value & 0xFF;
    }

    // Generate 16 random bytes. Use the last four bytes for the hash code.
    List<int> nonce = new List<int>(16);
    for (int i = 0; i < 4; i++) {
      int r = random.nextInt(0x100000000);
      intToBigEndianBytes(r, nonce, i * 4);
    }
    _nonce = _Base64._encode(nonce);
    _hash = random.nextInt(0x100000000);
  }

  bool _isWebSocketUpgrade(HttpClientResponse response) {
    if (response.headers[HttpHeaders.CONNECTION] == null) {
      return false;
    }
    bool isUpgrade = false;
    response.headers[HttpHeaders.CONNECTION].forEach((String value) {
      if (value.toLowerCase() == "upgrade") isUpgrade = true;
    });
    if (!isUpgrade) return false;
    String upgrade = response.headers.value(HttpHeaders.UPGRADE);
    if (upgrade == null || upgrade.toLowerCase() != "websocket") {
      return false;
    }
    String accept = response.headers.value("Sec-WebSocket-Accept");
    if (accept == null) {
      return false;
    }
    SHA1 sha1 = new SHA1();
    sha1.update("$_nonce$_webSocketGUID".charCodes());
    List<int> expectedAccept = sha1.digest();
    List<int> receivedAccept = _Base64._decode(accept);
    if (expectedAccept.length != receivedAccept.length) return false;
    for (int i = 0; i < expectedAccept.length; i++) {
      if (expectedAccept[i] != receivedAccept[i]) return false;
    }
    return true;
  }

  Function _onRequest;
  Function _onOpen;
  Function _onNoUpgrade;
  HttpClientConnection _conn;
  String _nonce;
}


class _WebSocket implements WebSocket {
  _WebSocket(String url, [protocols]) {
    Uri uri = new Uri.fromString(url);
    if (uri.scheme != "ws") {
      throw new WebSocketException("Unsupported URL scheme ${uri.scheme}");
    }
    if (uri.userInfo != "") {
      throw new WebSocketException("Unsupported user info ${uri.userInfo}");
    }
    int port = uri.port == 0 ? HttpClient.DEFAULT_HTTP_PORT : uri.port;
    String path;
    if (uri.query != "") {
      if (uri.fragment != "") {
        path = "${uri.path}?${uri.query}#${uri.fragment}";
      } else {
        path = "${uri.path}?${uri.query}";
      }
    } else {
      path = uri.path;
    }

    HttpClient client = new HttpClient();
    HttpClientConnection conn = client.open("GET", uri.domain, port, path);
    if (protocols is String) protocols = [protocols];
    _wsconn = new WebSocketClientConnection(conn, protocols);
    _wsconn.onOpen = () {
      // HTTP client not needed after socket have been detached.
      client.shutdown();
      client = null;
      _readyState = WebSocket.OPEN;
      if (_onopen !== null) _onopen();
    };
    _wsconn.onMessage = (message) {
      if (_onmessage !== null) {
        _onmessage(new _WebSocketMessageEvent(message));
      }
    };
    _wsconn.onClosed = (status, reason) {
      _readyState = WebSocket.CLOSED;
      if (_onclose !== null) {
        _onclose(new _WebSocketCloseEvent(true, status, reason));
      }
    };
    _wsconn.onNoUpgrade = (response) {
      if (_onclose !== null) {
        _onclose(
            new _WebSocketCloseEvent(true, 1006, "Connection not upgraded"));
      }
    };
  }

  int get readyState => _readyState;
  int get bufferedAmount => 0;

  void set onopen(Function callback) {
    _onopen = callback;
  }

  void set onerror(Function callback) {}

  void set onclose(Function callback) {
    _onclose = callback;
  }

  String get extensions => null;
  String get protocol => null;

  void close(int code, String reason) {
    if (_readyState < WebSocket.CLOSING) _readyState = WebSocket.CLOSING;
    _wsconn.close(code, reason);
  }

  void set onmessage(Function callback) {
    _onmessage = callback;
  }

  void send(data) {
    _wsconn.send(data);
  }

  WebSocketClientConnection _wsconn;
  int _readyState = WebSocket.CONNECTING;
  Function _onopen;
  Function _onclose;
  Function _onmessage;
}


class _WebSocketMessageEvent implements MessageEvent {
  _WebSocketMessageEvent(this._data);
  get data => _data;
  var _data;
}


class _WebSocketCloseEvent implements CloseEvent {
  _WebSocketCloseEvent(this._wasClean, this._code, this._reason);
  bool get wasClean => _wasClean;
  int get code => _code;
  String get reason => _reason;
  bool _wasClean;
  int _code;
  String _reason;
}
