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
 * The web socket protocol transformer handles the protocol byte stream
 * which is supplied through the [:handleData:]. As the protocol is processed,
 * it'll output frame data as either a List<int> or String.
 *
 * Important infomation about usage: Be sure you use cancelOnError, so the
 * socket will be closed when the processer encounter an error. Not using it
 * will lead to undefined behaviour.
 */
class _WebSocketProtocolTransformer extends StreamEventTransformer {
  static const int START = 0;
  static const int LEN_FIRST = 1;
  static const int LEN_REST = 2;
  static const int MASK = 3;
  static const int PAYLOAD = 4;
  static const int CLOSED = 5;
  static const int FAILURE = 6;

  bool _serverSide;

  _WebSocketProtocolTransformer([bool this._serverSide = false]) {
    _prepareForNextFrame();
    _currentMessageType = _WebSocketMessageType.NONE;
  }

  /**
   * Process data received from the underlying communication channel.
   */
  void handleData(List<int> buffer, EventSink sink) {
    int count = buffer.length;
    int index = 0;
    int lastIndex = count;
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
              _buffer = new StringBuffer();
              break;

            case _WebSocketOpcode.BINARY:
              if (_currentMessageType != _WebSocketMessageType.NONE) {
                throw new WebSocketException("Protocol error");
              }
              _currentMessageType = _WebSocketMessageType.BINARY;
              _buffer = new _BufferList();
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
              _lengthDone(sink);
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
              _lengthDone(sink);
            }
            break;

          case MASK:
            _maskingKey = _maskingKey << 8 | byte;
            _remainingMaskingKeyBytes--;
            if (_remainingMaskingKeyBytes == 0) {
              _maskDone(sink);
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
                _controlPayload.addAll(buffer.sublist(index, index + payload));
                index += payload;
              }

              if (_remainingPayloadBytes == 0) {
                _controlFrameEnd(sink);
              }
            } else {
              switch (_currentMessageType) {
                case _WebSocketMessageType.NONE:
                  throw new WebSocketException("Protocol error");

                case _WebSocketMessageType.TEXT:
                  _buffer.write(_decodeString(
                      buffer.sublist(index, index + payload)));
                  index += payload;
                  if (_remainingPayloadBytes == 0) {
                    _messageFrameEnd(sink);
                  }
                  break;

                case _WebSocketMessageType.BINARY:
                  _buffer.write(buffer.sublist(index, index + payload));
                  index += payload;
                  if (_remainingPayloadBytes == 0) {
                    _messageFrameEnd(sink);
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
      _state = FAILURE;
      sink.addError(e);
    }
  }

  void _lengthDone(EventSink sink) {
    if (_masked) {
      if (!_serverSide) {
        throw new WebSocketException("Received masked frame from server");
      }
      _state = MASK;
      _remainingMaskingKeyBytes = 4;
    } else {
      if (_serverSide) {
        throw new WebSocketException("Received unmasked frame from client");
      }
      _remainingPayloadBytes = _len;
      _startPayload(sink);
    }
  }

  void _maskDone(EventSink sink) {
    _remainingPayloadBytes = _len;
    _startPayload(sink);
  }

  void _startPayload(EventSink sink) {
    // If there is no actual payload perform perform callbacks without
    // going through the PAYLOAD state.
    if (_remainingPayloadBytes == 0) {
      if (_isControlFrame()) {
        switch (_opcode) {
          case _WebSocketOpcode.CLOSE:
            _state = CLOSED;
            sink.close();
            break;
          case _WebSocketOpcode.PING:
            // TODO(ajohnsen): Handle ping.
            break;
          case _WebSocketOpcode.PONG:
            // TODO(ajohnsen): Handle pong.
            break;
        }
        _prepareForNextFrame();
      } else {
        _messageFrameEnd(sink);
      }
    } else {
      _state = PAYLOAD;
    }
  }

  void _messageFrameEnd(EventSink sink) {
    if (_fin) {
      switch (_currentMessageType) {
        case _WebSocketMessageType.TEXT:
          sink.add(_buffer.toString());
          break;
        case _WebSocketMessageType.BINARY:
          if (_buffer.length == 0) {
            sink.add(const []);
          } else {
            sink.add(_buffer.readBytes(_buffer.length));
          }
          break;
      }
      _buffer = null;
      _currentMessageType = _WebSocketMessageType.NONE;
    }
    _prepareForNextFrame();
  }

  void _controlFrameEnd(EventSink sink) {
    switch (_opcode) {
      case _WebSocketOpcode.CLOSE:
        closeCode = WebSocketStatus.NO_STATUS_RECEIVED;
        if (_controlPayload.length > 0) {
          if (_controlPayload.length == 1) {
            throw new WebSocketException("Protocol error");
          }
          closeCode = _controlPayload[0] << 8 | _controlPayload[1];
          if (closeCode == WebSocketStatus.NO_STATUS_RECEIVED) {
            throw new WebSocketException("Protocol error");
          }
          if (_controlPayload.length > 2) {
            closeReason = _decodeString(
                _controlPayload.sublist(2));
          }
        }
        _state = CLOSED;
        sink.close();
        break;

      case _WebSocketOpcode.PING:
        // TODO(ajohnsen): Handle ping.
        break;

      case _WebSocketOpcode.PONG:
        // TODO(ajohnsen): Handle pong.
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
  var _buffer;  // Either StringBuffer or _BufferList.

  int closeCode = WebSocketStatus.NO_STATUS_RECEIVED;
  String closeReason = "";
}


class _WebSocketTransformerImpl implements WebSocketTransformer {
  final StreamController<WebSocket> _controller =
      new StreamController<WebSocket>();

  Stream<WebSocket> bind(Stream<HttpRequest> stream) {
    stream.listen((request) {
        _upgrade(request)
            .then((WebSocket webSocket) => _controller.add(webSocket))
            .catchError((error) => _controller.addError(error));
    });

    return _controller.stream;
  }

  static Future<WebSocket> _upgrade(HttpRequest request) {
    var response = request.response;
    if (!_isUpgradeRequest(request)) {
      // Send error response and drain the request.
      request.listen((_) {}, onDone: () {
        response.statusCode = HttpStatus.BAD_REQUEST;
        response.contentLength = 0;
        response.close();
      });
      return new Future.error(
          new WebSocketException("Invalid WebSocket upgrade request"));
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
    return response.detachSocket()
        .then((socket) => new _WebSocketImpl._fromSocket(socket, true));
  }

  static bool _isUpgradeRequest(HttpRequest request) {
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


class _WebSocketOutgoingTransformer extends StreamEventTransformer {
  final _WebSocketImpl webSocket;

  _WebSocketOutgoingTransformer(_WebSocketImpl this.webSocket);

  void handleData(message, EventSink<List<int>> sink) {
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
    addFrame(opcode, data, sink);
  }

  void handleDone(EventSink<List<int>> sink) {
    int code = webSocket._outCloseCode;
    String reason = webSocket._outCloseReason;
    List<int> data;
    if (code != null) {
      data = new List<int>();
      data.add((code >> 8) & 0xFF);
      data.add(code & 0xFF);
      if (reason != null) {
        data.addAll(_encodeString(reason));
      }
    }
    addFrame(_WebSocketOpcode.CLOSE, data, sink);
    sink.close();
  }

  void addFrame(int opcode, List<int> data, EventSink<List<int>> sink) {
    bool mask = !webSocket._serverSide;  // Masking not implemented for server.
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
    if (mask) {
      header[1] |= 1 << 7;
      var maskBytes = _IOCrypto.getRandomBytes(4);
      header.setRange(index, index + 4, maskBytes);
      index += 4;
      if (data != null) {
        var list = new Uint8List(data.length);
        for (int i = 0; i < data.length; i++) {
          list[i] = data[i] ^ maskBytes[i % 4];
        }
        data = list;
      }
    }
    assert(index == headerSize);
    sink.add(header);
    if (data != null) {
      sink.add(data);
    }
  }
}


class _WebSocketConsumer implements StreamConsumer {
  final _WebSocketImpl webSocket;
  final Socket socket;
  StreamController _controller;
  StreamSubscription _subscription;
  Completer _closeCompleter = new Completer();
  Completer _completer;

  _WebSocketConsumer(_WebSocketImpl this.webSocket, Socket this.socket);

  void _onListen() {
    if (_subscription != null) {
      _subscription.cancel();
    }
  }

  _ensureController() {
    if (_controller != null) return;
    _controller = new StreamController(onPause: () => _subscription.pause(),
                                       onResume: () => _subscription.resume(),
                                       onCancel: _onListen);
    var stream = _controller.stream.transform(
        new _WebSocketOutgoingTransformer(webSocket));
    socket.addStream(stream)
        .then((_) {
                _done();
                _closeCompleter.complete(webSocket);
              },
              onError: (error) {
                if (!_done(error)) {
                  _closeCompleter.completeError(error);
                }
              });
  }

  bool _done([error]) {
    if (_completer == null) return false;
    var tmp = _completer;
    _completer = null;
    if (error != null) {
      tmp.completeError(error);
    } else {
      tmp.complete(webSocket);
    }
    return true;
  }

  Future addStream(var stream) {
    _ensureController();
    _completer = new Completer();
    _subscription = stream.listen(
        (data) {
          _controller.add(data);
        },
        onDone: () {
          _done();
        },
        onError: (error) {
          _done(error);
        },
        cancelOnError: true);
    return _completer.future;
  }

  Future close() {
    Future closeSocket() {
      return socket.close().then((_) => webSocket);
    }
    if (_controller == null) return closeSocket();
    _controller.close();
    return _closeCompleter.future.then((_) => closeSocket());
  }
}


class _WebSocketImpl extends Stream implements WebSocket {
  final StreamController _controller = new StreamController();
  StreamSink _sink;

  final Socket _socket;
  final bool _serverSide;
  int _readyState = WebSocket.CONNECTING;
  bool _writeClosed = false;
  int _closeCode;
  String _closeReason;

  int _outCloseCode;
  String _outCloseReason;

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

  _WebSocketImpl._fromSocket(Socket this._socket,
                             [bool this._serverSide = false]) {
    _sink = new _StreamSinkImpl(new _WebSocketConsumer(this, _socket));
    _readyState = WebSocket.OPEN;

    var transformer = new _WebSocketProtocolTransformer(_serverSide);
    _socket.transform(transformer).listen(
        (data) {
          _controller.add(data);
        },
        onError: (error) {
          _controller.addError(error);
          _controller.close();
        },
        onDone: () {
          if (_readyState == WebSocket.OPEN) {
            _readyState = WebSocket.CLOSING;
            if (transformer.closeCode != WebSocketStatus.NO_STATUS_RECEIVED) {
              close(transformer.closeCode);
            } else {
              close();
            }
            _readyState = WebSocket.CLOSED;
          }
          _closeCode = transformer.closeCode;
          _closeReason = transformer.closeReason;
          _controller.close();
        },
        cancelOnError: true);
  }

  StreamSubscription listen(void onData(message),
                            {void onError(error),
                             void onDone(),
                             bool cancelOnError}) {
    return _controller.stream.listen(onData,
                                     onError: onError,
                                     onDone: onDone,
                                     cancelOnError: cancelOnError);
  }

  int get readyState => _readyState;

  String get extensions => null;
  String get protocol => null;
  int get closeCode => _closeCode;
  String get closeReason => _closeReason;

  void add(data) => _sink.add(data);
  void addError(error) => _sink.addError(error);
  Future addStream(Stream stream) => _sink.addStream(stream);
  Future get done => _sink.done;

  Future close([int code, String reason]) {
    if (!_writeClosed) {
      if (code == WebSocketStatus.RESERVED_1004 ||
          code == WebSocketStatus.NO_STATUS_RECEIVED ||
          code == WebSocketStatus.RESERVED_1015) {
        throw new WebSocketException("Reserved status code $code");
      }
      _outCloseCode = code;
      _outCloseReason = reason;
      _writeClosed = true;
    }
    return _sink.close();
  }
}
