// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

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
              if (onMessageStart != null) {
                onMessageStart(_WebSocketMessageType.TEXT);
              }
              break;

            case _WebSocketOpcode.BINARY:
              if (_currentMessageType != _WebSocketMessageType.NONE) {
                throw new WebSocketException("Protocol error");
              }
              _currentMessageType = _WebSocketMessageType.BINARY;
              if (onMessageStart != null) {
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
                  if (onMessageData != null) {
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
            break;
        }

        // Move to the next byte.
        index++;
      }
    } catch (e) {
      if (onClosed != null) onClosed(WebSocketStatus.PROTOCOL_ERROR,
                                      "Protocol error");
      _state = FAILURE;
    }
  }

  /**
   * Indicate that the underlying communication channel has been closed.
   */
  void closed() {
    if (_state == START || _state == CLOSED || _state == FAILURE) return;
    if (onClosed != null) onClosed(WebSocketStatus.ABNORMAL_CLOSURE,
                                    "Connection closed unexpectedly");
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
            if (onClosed != null) onClosed(1005, "");
            _state = CLOSED;
            break;
          case _WebSocketOpcode.PING:
            if (onPing != null) onPing(null);
            break;
          case _WebSocketOpcode.PONG:
            if (onPong != null) onPong(null);
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
      if (onMessageEnd != null) onMessageEnd();
      _currentMessageType = _WebSocketMessageType.NONE;
    }
    _prepareForNextFrame();
  }

  void _controlFrameEnd() {
    switch (_opcode) {
      case _WebSocketOpcode.CLOSE:
        int status = WebSocketStatus.NO_STATUS_RECEIVED;
        String reason = "";
        if (_controlPayload.length > 0) {
          if (_controlPayload.length == 1) {
            throw new WebSocketException("Protocol error");
          }
          status = _controlPayload[0] << 8 | _controlPayload[1];
          if (status == WebSocketStatus.NO_STATUS_RECEIVED) {
            throw new WebSocketException("Protocol error");
          }
          if (_controlPayload.length > 2) {
            reason = _decodeString(
                _controlPayload.getRange(2, _controlPayload.length - 2));
          }
        }
        if (onClosed != null) onClosed(status, reason);
        _state = CLOSED;
        break;

      case _WebSocketOpcode.PING:
        if (onPing != null) onPing(_controlPayload);
        break;

      case _WebSocketOpcode.PONG:
        if (onPong != null) onPong(_controlPayload);
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


class _WebSocketTransformerImpl implements WebSocketTransformer {
  final StreamController<WebSocket> _controller =
      new StreamController<WebSocket>();

  Stream<WebSocket> bind(Stream<HttpRequest> stream) {
    stream.listen((request) {
      var response = request.response;
      if (!_isWebSocketUpgrade(request)) {
        _controller.signalError(
            new AsyncError(
                new WebSocketException("Invalid WebSocket upgrade request")));
        request.listen((_) {}, onDone: () {
          response.statusCode = HttpStatus.BAD_REQUEST;
          response.contentLength = 0;
          response.close();
        });
        return;
      }
      // Send the upgrade response.
      response.statusCode = HttpStatus.SWITCHING_PROTOCOLS;
      response.headers.add(HttpHeaders.CONNECTION, "Upgrade");
      response.headers.add(HttpHeaders.UPGRADE, "websocket");
      String key = request.headers.value("Sec-WebSocket-Key");
      SHA1 sha1 = new SHA1();
      sha1.add("$key$_webSocketGUID".codeUnits);
      String accept = _Base64._encode(sha1.close());
      response.headers.add("Sec-WebSocket-Accept", accept);
      response.headers.contentLength = 0;
      response.detachSocket()
        .then((socket) {
          _controller.add(new _WebSocketImpl._fromSocket(socket));
        }, onError: (error) {
          _controller.signalError(error);
        });
    });

    return _controller.stream;
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
}


class _WebSocketImpl extends Stream implements WebSocket {
  final StreamController _controller = new StreamController();

  final _WebSocketProtocolProcessor _processor =
      new _WebSocketProtocolProcessor();

  final Socket _socket;
  int _readyState = WebSocket.CONNECTING;
  bool _writeClosed = false;
  int _closeCode;
  String _closeReason;

  static final HttpClient _httpClient = new HttpClient();

  static Future<WebSocket> connect(String url, [protocols]) {
    Uri uri = Uri.parse(url);
    if (uri.scheme != "ws" && uri.scheme != "wss") {
      throw new WebSocketException("Unsupported URL scheme '${uri.scheme}'");
    }
    if (uri.userInfo != "") {
      throw new WebSocketException("Unsupported user info '${uri.userInfo}'");
    }

    Random random = new Random();
    // Generate 16 random bytes.
    List<int> nonceData = new List<int>(16);
    for (int i = 0; i < 16; i++) {
      nonceData[i] = random.nextInt(256);
    }
    String nonce = _Base64._encode(nonceData);

    uri = new Uri.fromComponents(scheme: uri.scheme == "wss" ? "https" : "http",
                                 userInfo: uri.userInfo,
                                 domain: uri.domain,
                                 port: uri.port,
                                 path: uri.path,
                                 query: uri.query,
                                 fragment: uri.fragment);
    return _httpClient.openUrl("GET", uri)
      .then((request) {
        // Setup the initial handshake.
        request.headers.add(HttpHeaders.CONNECTION, "upgrade");
        request.headers.set(HttpHeaders.UPGRADE, "websocket");
        request.headers.set("Sec-WebSocket-Key", nonce);
        request.headers.set("Sec-WebSocket-Version", "13");
        return request.close();
      })
      .then((response) {
        void error(String message) {
          // Flush data.
          response.detachSocket().then((socket) {
            socket.destroy();
          });
          throw new WebSocketException(message);
        }
        if (response.statusCode != HttpStatus.SWITCHING_PROTOCOLS ||
            response.headers[HttpHeaders.CONNECTION] == null ||
            !response.headers[HttpHeaders.CONNECTION].any(
                (value) => value.toLowerCase() == "upgrade") ||
            response.headers.value(HttpHeaders.UPGRADE).toLowerCase() !=
                "websocket") {
          error("Connection to '$uri' was not upgraded to websocket");
        }
        String accept = response.headers.value("Sec-WebSocket-Accept");
        if (accept == null) {
          error("Response did not contain a 'Sec-WebSocket-Accept' header");
        }
        SHA1 sha1 = new SHA1();
        sha1.add("$nonce$_webSocketGUID".codeUnits);
        List<int> expectedAccept = sha1.close();
        List<int> receivedAccept = _Base64._decode(accept);
        if (expectedAccept.length != receivedAccept.length) {
          error("Reasponse header 'Sec-WebSocket-Accept' is the wrong length");
        }
        for (int i = 0; i < expectedAccept.length; i++) {
          if (expectedAccept[i] != receivedAccept[i]) {
            error("Bad response 'Sec-WebSocket-Accept' header");
          }
        }
        return response.detachSocket()
            .then((socket) => new _WebSocketImpl._fromSocket(socket));
      });
  }

  _WebSocketImpl._fromSocket(Socket this._socket) {
    _readyState = WebSocket.OPEN;

    int type;
    var data;
    _processor.onMessageStart = (int t) {
      type = t;
      if (type == _WebSocketMessageType.TEXT) {
        data = new StringBuffer();
      } else {
        data = [];
      }
    };
    _processor.onMessageData = (buffer, offset, count) {
      if (type == _WebSocketMessageType.TEXT) {
        data.add(_decodeString(buffer.getRange(offset, count)));
      } else {
        data.addAll(buffer.getRange(offset, count));
      }
    };
    _processor.onMessageEnd = () {
      if (type == _WebSocketMessageType.TEXT) {
        _controller.add(data.toString());
      } else {
        _controller.add(data);
      }
    };
    _processor.onClosed = (code, reason) {
      bool clean = true;
      if (_readyState == WebSocket.OPEN) {
        _readyState = WebSocket.CLOSING;
        if (code != WebSocketStatus.NO_STATUS_RECEIVED) {
          _close(code);
        } else {
          _close();
          clean = false;
        }
        _readyState = WebSocket.CLOSED;
      }
      if (_readyState == WebSocket.CLOSED) return;
      _closeCode = code;
      _closeReason = reason;
      _controller.close();
    };

    _socket.listen(
        (data) => _processor.update(data, 0, data.length),
        onDone: () => _processor.closed(),
        onError: (error) => _controller.signalError(error));

    _socket.done
        .catchError((error) {
          if (_readyState == WebSocket.CLOSED) return;
          _readyState = WebSocket.CLOSED;
          _closeCode = ABNORMAL_CLOSURE;
          _controller.signalError(error);
          _controller.close();
          _socket.destroy();
        })
        .whenComplete(() {
          _writeClosed = true;
        });
  }

  StreamSubscription listen(void onData(message),
                            {void onError(AsyncError error),
                             void onDone(),
                             bool unsubscribeOnError}) {
    return _controller.stream.listen(onData,
                                     onError: onError,
                                     onDone: onDone,
                                     unsubscribeOnError: unsubscribeOnError);
  }

  int get readyState => _readyState;

  String get extensions => null;
  String get protocol => null;
  int get closeCode => _closeCode;
  String get closeReason => _closeReason;

  void close([int code, String reason]) {
    if (_readyState < WebSocket.CLOSING) _readyState = WebSocket.CLOSING;
    if (code == WebSocketStatus.RESERVED_1004 ||
        code == WebSocketStatus.NO_STATUS_RECEIVED ||
        code == WebSocketStatus.RESERVED_1015) {
      throw new WebSocketException("Reserved status code $code");
    }
    _close(code, reason);
  }

  void _close([int code, String reason]) {
    List<int> data;
    if (code != null) {
      data = new List<int>();
      data.add((code >> 8) & 0xFF);
      data.add(code & 0xFF);
      if (reason != null) {
        data.addAll(_encodeString(reason));
      }
    }
    _sendFrame(_WebSocketOpcode.CLOSE, data);

    if (_readyState == WebSocket.CLOSED) {
      // Close the socket when the close frame has been sent - if it
      // does not take too long.
      // TODO(ajohnsen): Honor comment.
      _socket.destroy();
    } else {
      // Half close the socket and expect a close frame in response
      // before closing the socket. If a close frame does not arrive
      // within a reasonable amount of time just close the socket.
      // TODO(ajohnsen): Honor comment.
      _socket.close();
    }
  }

  void send(message) {
    if (readyState != WebSocket.OPEN) {
      throw new StateError("Connection not open");
    }
    List<int> data;
    int opcode;
    if (message != null) {
      if (message is String) {
        opcode = _WebSocketOpcode.TEXT;
        data = _encodeString(message);
      } else {
        if (message is !List<int>) {
          throw new ArgumentError(message);
        }
        opcode = _WebSocketOpcode.BINARY;
        data = message;
      }
    } else {
      opcode = _WebSocketOpcode.TEXT;
    }
    try {
      _sendFrame(opcode, data);
    } catch (_) {
      // The socket can be closed before _socket.done have a chance
      // to complete.
    }
  }

  void _sendFrame(int opcode, [List<int> data]) {
    if (_writeClosed) return;
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
    _socket.add(header);
    if (data != null) {
      _socket.add(data);
    }
  }
}
