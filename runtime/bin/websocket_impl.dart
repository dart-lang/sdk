// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _WebSocketMessageType {
  static final int NONE = 0;
  static final int BINARY = 1;
  static final int TEXT = 2;
  static final int CLOSE = 3;
}


class _WebSocketOpcode {
  static final int CONTINUATION = 0;
  static final int TEXT = 1;
  static final int BINARY = 2;
  static final int RESERVED_3 = 3;
  static final int RESERVED_4 = 4;
  static final int RESERVED_5 = 5;
  static final int RESERVED_6 = 6;
  static final int RESERVED_7 = 7;
  static final int CLOSE = 8;
  static final int PING = 9;
  static final int PONG = 10;
  static final int RESERVED_B = 11;
  static final int RESERVED_C = 12;
  static final int RESERVED_D = 13;
  static final int RESERVED_E = 14;
  static final int RESERVED_F = 15;
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
  static final int START = 0;
  static final int LEN_FIRST = 1;
  static final int LEN_REST = 2;
  static final int MASK = 3;
  static final int PAYLOAD = 4;
  static final int CLOSED = 5;
  static final int FAILURE = 6;

  _WebSocketProtocolProcessor() {
    _reset();
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
              if (_currentMessageType != _WebSocketMessageType.NONE) {
                throw new WebSocketException("Protocol error");
              }
              _currentMessageType = _WebSocketMessageType.CLOSE;
              break;

            case _WebSocketOpcode.PING:
              // TODO(sgjesse): Handle ping.
              throw new UnsupportedOperationException("Web socket PING");
              break;

            case _WebSocketOpcode.PONG:
              // TODO(sgjesse): Handle pong.
              throw new UnsupportedOperationException("Web socket PONG");
              break;

            default:
              throw new WebSocketException("Protocol error");
              break;
            }
            _state = LEN_FIRST;
            break;

          case LEN_FIRST:
            _masked = (byte & 0x80) != 0;
            _len = byte & 0x7F;
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
            // Unmask payload if masked.
            if (_masked) {
              for (int i = 0; i < payload; i++) {
                int maskingByte =
                    ((_maskingKey >> ((3 - _unmaskingIndex) * 8)) & 0xFF);
                buffer[index + i] = buffer[index + i] ^ maskingByte;
                _unmaskingIndex = (_unmaskingIndex + 1) % 4;
              }
            }

            switch (_currentMessageType) {
              case _WebSocketMessageType.NONE:
                throw new WebSocketException("Protocol error");
                break;

              case _WebSocketMessageType.TEXT:
              case _WebSocketMessageType.BINARY:
                if (onMessageData != null) {
                  onMessageData(buffer, index, payload);
                }
                _remainingPayloadBytes -= payload;
                index += payload;
                if (_remainingPayloadBytes == 0) {
                  _frameEnd();
                }
                break;

              case _WebSocketMessageType.CLOSE:
                // Allocate a buffer for holding the close payload if any.
                if (_closePayload == null) {
                  _closePayload = new List<int>();
                }
                _closePayload.addAll(buffer.getRange(index, payload));
                _remainingPayloadBytes -= payload;
                index += payload;
                if (_fin) {
                  if (_remainingPayloadBytes != 0) {
                    throw new WebSocketException("Protocol error");
                  }
                  int status;
                  String reason;
                  if (_closePayload.length > 0) {
                    if (_closePayload.length == 1) {
                      throw new WebSocketException("Protocol error");
                    }
                    status = _closePayload[0] << 8 | _closePayload[1];
                    if (_closePayload.length > 2) {
                      var decoder = _StringDecoders.decoder(Encoding.UTF_8);
                      decoder.write(_closePayload.getRange(
                          2, _closePayload.length - 2));
                      reason = decoder.decoded;
                    }
                  }
                  if (onClosed != null) onClosed(status, reason);
                  _currentMessageType = _WebSocketMessageType.NONE;
                  _state = CLOSED;
                }
                break;

              default:
                throw new WebSocketException("Protocol error");
                break;
            }

            // Hack - as we always do index++ below.
            index--;
            break;

          default:
            throw new WebSocketException("Protocol error");
            break;
        }

        // Move to the next byte.
        index++;
      }
    } catch (var e) {
      _reportError(e);
    }
  }

  /**
   * Indicate that the underlying communication channel has been closed.
   */
  void closed() {
    if (_state == START || _state == CLOSED || _state == FAILURE) return;
    _reportError(new WebSocketException("Protocol error"));
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
    // Check whether there is any payload. If not indicate empty
    // message or close without state and reason.
    if (_remainingPayloadBytes == 0) {
      if (_currentMessageType ==_WebSocketMessageType.CLOSE) {
        if (onClosed != null) onClosed(null, null);
      } else {
        _frameEnd();
      }
    } else {
      _state = PAYLOAD;
    }
  }

  void _frameEnd() {
    if (_remainingPayloadBytes != 0) {
      throw new WebSocketException("Protocol error");
    }
    if (_fin) {
      if (onMessageEnd != null) onMessageEnd();
      _currentMessageType = _WebSocketMessageType.NONE;
    }
    _reset();
  }

  void _reset() {
    _state = START;
    _fin = null;
    _opcode = null;
    _len = null;
    _masked = null;
    _maskingKey = 0;
    _remainingLenBytes = null;
    _remainingMaskingKeyBytes = null;
    _remainingPayloadBytes = null;
    _unmaskingIndex = 0;
  }

  void _reportError(e) {
    // Report the error through the error callback if any. Otherwise
    // throw the error.
    if (onError != null) {
      onError(e);
      _state = FAILURE;
    } else {
      throw e;
    }
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
  List<int> _closePayload;

  Function onMessageStart;
  Function onMessageData;
  Function onMessageEnd;
  Function onClosed;
  Function onError;
}


class _WebSocketConnection implements WebSocketConnection {
  _WebSocketConnection(Socket this._socket) {
    _WebSocketProtocolProcessor processor = new _WebSocketProtocolProcessor();
    processor.onMessageStart = _onWebSocketMessageStart;
    processor.onMessageData = _onWebSocketMessageData;
    processor.onMessageEnd = _onWebSocketMessageEnd;
    processor.onClosed = _onWebSocketClosed;
    processor.onError = _onWebSocketError;

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
        if (_closeTimer != null) _closeTimer.cancel();
      } else {
        if (_onError != null) {
          _onError(new WebSocketException("Unexpected close"));
        }
      }
      _socket.close();
    };
    _socket.onError = (e) {
      if (_onError != null) _onError(e);
      _socket.close();
    };
  }

  void set onMessage(void callback(Object message)) {
    _onMessage = callback;
  }

  void set onClosed(void callback(int status, String reason)) {
    _onClosed = callback;
  }

  void set onError(void callback(e)) {
    _onError = callback;
  }

  send(Object message) {
    if (_closeSent) {
      throw new WebSocketException("Connection closed");
    }
    List<int> data;
    int opcode;
    if (message != null) {
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
    if (status != null) {
      data = new List<int>();
      data.add((status >> 8) & 0xFF);
      data.add(status & 0xFF);
      if (reason != null) {
        data.addAll(
           _StringEncoders.encoder(Encoding.UTF_8).encodeString(reason));
      }
    }
    _sendFrame(_WebSocketOpcode.CLOSE, data);

    if (_closeReceived) {
      // Close the socket when the close frame has been sent - if it
      // does not take too long.
      _socket.outputStream.onNoPendingWrites = () {
        if (_closeTimer != null) _closeTimer.cancel();
        _socket.close();
      };
      _closeTimer = new Timer(5000, (t) {
        _socket.close();
      });
    } else {
      // Half close the socket and expect a close frame in response
      // before closing the socket. If a close frame does not arrive
      // within a reasonable amount of time just close the socket.
      _socket.close(true);
      _closeTimer = new Timer(5000, (t) {
        _socket.close();
      });
    }
    _closeSent = true;
  }

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
    if (_onMessage != null) {
      if (_currentMessageType == _WebSocketMessageType.TEXT) {
        _onMessage(_decoder.decoded);
      } else {
        _onMessage(_outputStream.contents());
      }
    }
    _decoder = null;
    _outputStream = null;
  }

  _onWebSocketClosed(int status, String reason) {
    _closeReceived = true;
    if (_onClosed != null) _onClosed(status, reason);
    if (_closeSent) {
      // Got close frame in response to close frame. Now close the socket.
      if (_closeTimer != null) _closeTimer.cancel();
      _socket.close();
    } else {
      close(status);
    }
  }

  _onWebSocketError(e) {
    if (_onError != null) _onError(e);
    _socket.close();
  }

  _sendFrame(int opcode, List<int> data) {
    bool mask = false;  // Masking not implemented for server.
    int dataLength = data == null ? 0 : data.length;
    // Determine the header size.
    int headerSize = (mask) ? 6 : 2;
    if (dataLength > 65535) {
      headerSize += 8;
    } else if (dataLength > 126) {
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
    } else if (dataLength > 126) {
      header[index++] = 126;
      lengthBytes = 2;
    }
    // Write the length in network byte order into the header.
    for (int i = 0; i < lengthBytes; i++) {
      header[index++] = dataLength >> (((lengthBytes - 1) - i) * 8) & 0xFF;
    }
    assert(index == headerSize);
    _socket.outputStream.write(header);
    if (data != null) {
      _socket.outputStream.write(data);
    }
  }

  Socket _socket;
  Timer _closeTimer;

  Function _onMessage;
  Function _onClosed;
  Function _onError;

  int _currentMessageType = _WebSocketMessageType.NONE;
  _StringDecoder _decoder;
  ListOutputStream _outputStream;
  bool _closeReceived = false;
  bool _closeSent = false;
}


class _WebSocketHandler implements WebSocketHandler {
  void onRequest(HttpRequest request, HttpResponse response) {
    // Check that this is a web socket upgrade.
    if (!_isWebSocketUpgrade(request)) {
      response.statusCode = HttpStatus.BAD_REQUEST;
      return;
    }

    // Send the upgrade response.
    response.statusCode = HttpStatus.SWITCHING_PROTOCOLS;
    response.headers.add(HttpHeaders.CONNECTION, "Upgrade");
    response.headers.add(HttpHeaders.UPGRADE, "websocket");
    String x = request.headers.value("Sec-WebSocket-Key");
    String y = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
    String z = _Base64._encode(_Sha1._hash("$x$y".charCodes()));
    response.headers.add("Sec-WebSocket-Accept", z);
    response.contentLength = 0;

    // Upgrade the connection and get the underlying socket.
    Socket socket = response.detachSocket();
    WebSocketConnection conn = new _WebSocketConnection(socket);
    if (_onOpen != null) _onOpen(conn);
  }

  void set onOpen(callback(WebSocketConnection connection)) {
    _onOpen = callback;
  }

  bool _isWebSocketUpgrade(HttpRequest request) {
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
