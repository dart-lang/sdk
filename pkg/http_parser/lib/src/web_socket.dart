// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http_parser.web_socket;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'bytes_builder.dart';

/// An implementation of the WebSocket protocol that's not specific to "dart:io"
/// or to any particular HTTP API.
///
/// Because this is HTTP-API-agnostic, it doesn't handle the initial [WebSocket
/// handshake][]. This needs to be handled manually by the user of the code.
/// Once that's been done, [new CompatibleWebSocket] can be called with the
/// underlying socket and it will handle the remainder of the protocol.
///
/// [WebSocket handshake]: https://tools.ietf.org/html/rfc6455#section-4
abstract class CompatibleWebSocket implements Stream, StreamSink {
  /// The interval for sending ping signals.
  ///
  /// If a ping message is not answered by a pong message from the peer, the
  /// `WebSocket` is assumed disconnected and the connection is closed with a
  /// [WebSocketStatus.GOING_AWAY] close code. When a ping signal is sent, the
  /// pong message must be received within [pingInterval].
  ///
  /// There are never two outstanding pings at any given time, and the next ping
  /// timer starts when the pong is received.
  ///
  /// By default, the [pingInterval] is `null`, indicating that ping messages
  /// are disabled.
  Duration pingInterval;

  /// The [close code][] set when the WebSocket connection is closed.
  ///
  /// [close code]: https://tools.ietf.org/html/rfc6455#section-7.1.5
  ///
  /// Before the connection has been closed, this will be `null`.
  int get closeCode;

  /// The [close reason][] set when the WebSocket connection is closed.
  ///
  /// [close reason]: https://tools.ietf.org/html/rfc6455#section-7.1.6
  ///
  /// Before the connection has been closed, this will be `null`.
  String get closeReason;

  /// Signs a `Sec-WebSocket-Key` header sent by a WebSocket client as part of
  /// the [initial handshake].
  ///
  /// The return value should be sent back to the client in a
  /// `Sec-WebSocket-Accept` header.
  ///
  /// [initial handshake]: https://tools.ietf.org/html/rfc6455#section-4.2.2
  static String signKey(String key) {
    var hash = new SHA1();
    // We use [codeUnits] here rather than UTF-8-decoding the string because
    // [key] is expected to be base64 encoded, and so will be pure ASCII.
    hash.add((key + _webSocketGUID).codeUnits);
    return CryptoUtils.bytesToBase64(hash.close());
  }

  /// Creates a new WebSocket handling messaging across an existing socket.
  ///
  /// Because this is HTTP-API-agnostic, the initial [WebSocket handshake][]
  /// must have already been completed on the socket before this is called.
  ///
  /// If [stream] is also a [StreamSink] (for example, if it's a "dart:io"
  /// `Socket`), it will be used for both sending and receiving data. Otherwise,
  /// it will be used for receiving data and [sink] will be used for sending it.
  ///
  /// If this is a WebSocket server, [serverSide] should be `true` (the
  /// default); if it's a client, [serverSide] should be `false`.
  ///
  /// [WebSocket handshake]: https://tools.ietf.org/html/rfc6455#section-4
  factory CompatibleWebSocket(Stream<List<int>> stream,
        {StreamSink<List<int>> sink, bool serverSide: true}) {
    if (sink == null) {
      if (stream is! StreamSink) {
        throw new ArgumentError("If stream isn't also a StreamSink, sink must "
            "be passed explicitly.");
      }
      sink = stream as StreamSink;
    }

    return new _WebSocketImpl._fromSocket(stream, sink, serverSide);
  }

  /// Closes the web socket connection.
  ///
  /// [closeCode] and [closeReason] are the [close code][] and [reason][] sent
  /// to the remote peer, respectively. If they are omitted, the peer will see
  /// a "no status received" code with no reason.
  ///
  /// [close code]: https://tools.ietf.org/html/rfc6455#section-7.1.5
  /// [reason]: https://tools.ietf.org/html/rfc6455#section-7.1.6
  Future close([int closeCode, String closeReason]);
}

/// An exception thrown by [CompatibleWebSocket].
class CompatibleWebSocketException implements Exception {
  final String message;

  CompatibleWebSocketException([this.message]);

  String toString() => message == null
      ? "CompatibleWebSocketException" :
        "CompatibleWebSocketException: $message";
}

// The following code is copied from sdk/lib/io/websocket_impl.dart. The
// "dart:io" implementation isn't used directly both to support non-"dart:io"
// applications, and because it's incompatible with non-"dart:io" HTTP requests
// (issue 18172).
//
// Because it's copied directly, only modifications necessary to support the
// desired public API and to remove "dart:io" dependencies have been made.

/**
 * Web socket status codes used when closing a web socket connection.
 */
abstract class _WebSocketStatus {
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

abstract class _WebSocketState {
  static const int CONNECTING = 0;
  static const int OPEN = 1;
  static const int CLOSING = 2;
  static const int CLOSED = 3;
}

const String _webSocketGUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

final _random = new Random();

// Matches _WebSocketOpcode.
class _WebSocketMessageType {
  static const int NONE = 0;
  static const int TEXT = 1;
  static const int BINARY = 2;
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
// TODO(ajohnsen): make this transformer reusable?
class _WebSocketProtocolTransformer implements StreamTransformer, EventSink {
  static const int START = 0;
  static const int LEN_FIRST = 1;
  static const int LEN_REST = 2;
  static const int MASK = 3;
  static const int PAYLOAD = 4;
  static const int CLOSED = 5;
  static const int FAILURE = 6;

  int _state = START;
  bool _fin = false;
  int _opcode = -1;
  int _len = -1;
  bool _masked = false;
  int _remainingLenBytes = -1;
  int _remainingMaskingKeyBytes = 4;
  int _remainingPayloadBytes = -1;
  int _unmaskingIndex = 0;
  int _currentMessageType = _WebSocketMessageType.NONE;
  int closeCode = _WebSocketStatus.NO_STATUS_RECEIVED;
  String closeReason = "";

  EventSink _eventSink;

  final bool _serverSide;
  final List _maskingBytes = new List(4);
  final BytesBuilder _payload = new BytesBuilder(copy: false);

  _WebSocketProtocolTransformer([this._serverSide = false]);

  Stream bind(Stream stream) {
    return new Stream.eventTransformed(
        stream,
        (EventSink eventSink) {
          if (_eventSink != null) {
            throw new StateError("WebSocket transformer already used.");
          }
          _eventSink = eventSink;
          return this;
        });
  }

  void addError(Object error, [StackTrace stackTrace]) =>
      _eventSink.addError(error, stackTrace);

  void close() => _eventSink.close();

  /**
   * Process data received from the underlying communication channel.
   */
  void add(Uint8List buffer) {
    int count = buffer.length;
    int index = 0;
    int lastIndex = count;
    if (_state == CLOSED) {
      throw new CompatibleWebSocketException("Data on closed connection");
    }
    if (_state == FAILURE) {
      throw new CompatibleWebSocketException("Data on failed connection");
    }
    while ((index < lastIndex) && _state != CLOSED && _state != FAILURE) {
      int byte = buffer[index];
      if (_state <= LEN_REST) {
        if (_state == START) {
          _fin = (byte & 0x80) != 0;
          if ((byte & 0x70) != 0) {
            // The RSV1, RSV2 bits RSV3 must be all zero.
            throw new CompatibleWebSocketException("Protocol error");
          }
          _opcode = (byte & 0xF);
          if (_opcode <= _WebSocketOpcode.BINARY) {
            if (_opcode == _WebSocketOpcode.CONTINUATION) {
              if (_currentMessageType == _WebSocketMessageType.NONE) {
                throw new CompatibleWebSocketException("Protocol error");
              }
            } else {
              assert(_opcode == _WebSocketOpcode.TEXT ||
                     _opcode == _WebSocketOpcode.BINARY);
              if (_currentMessageType != _WebSocketMessageType.NONE) {
                throw new CompatibleWebSocketException("Protocol error");
              }
              _currentMessageType = _opcode;
            }
          } else if (_opcode >= _WebSocketOpcode.CLOSE &&
                     _opcode <= _WebSocketOpcode.PONG) {
            // Control frames cannot be fragmented.
            if (!_fin) throw new CompatibleWebSocketException("Protocol error");
          } else {
            throw new CompatibleWebSocketException("Protocol error");
          }
          _state = LEN_FIRST;
        } else if (_state == LEN_FIRST) {
          _masked = (byte & 0x80) != 0;
          _len = byte & 0x7F;
          if (_isControlFrame() && _len > 125) {
            throw new CompatibleWebSocketException("Protocol error");
          }
          if (_len == 126) {
            _len = 0;
            _remainingLenBytes = 2;
            _state = LEN_REST;
          } else if (_len == 127) {
            _len = 0;
            _remainingLenBytes = 8;
            _state = LEN_REST;
          } else {
            assert(_len < 126);
            _lengthDone();
          }
        } else {
          assert(_state == LEN_REST);
          _len = _len << 8 | byte;
          _remainingLenBytes--;
          if (_remainingLenBytes == 0) {
            _lengthDone();
          }
        }
      } else {
        if (_state == MASK) {
          _maskingBytes[4 - _remainingMaskingKeyBytes--] = byte;
          if (_remainingMaskingKeyBytes == 0) {
            _maskDone();
          }
        } else {
          assert(_state == PAYLOAD);
          // The payload is not handled one byte at a time but in blocks.
          int payloadLength = min(lastIndex - index, _remainingPayloadBytes);
          _remainingPayloadBytes -= payloadLength;
          // Unmask payload if masked.
          if (_masked) {
            _unmask(index, payloadLength, buffer);
          }
          // Control frame and data frame share _payloads.
          _payload.add(
              new Uint8List.view(buffer.buffer, index, payloadLength));
          index += payloadLength;
          if (_isControlFrame()) {
            if (_remainingPayloadBytes == 0) _controlFrameEnd();
          } else {
            if (_currentMessageType != _WebSocketMessageType.TEXT &&
                _currentMessageType != _WebSocketMessageType.BINARY) {
                throw new CompatibleWebSocketException("Protocol error");
            }
            if (_remainingPayloadBytes == 0) _messageFrameEnd();
          }

          // Hack - as we always do index++ below.
          index--;
        }
      }

      // Move to the next byte.
      index++;
    }
  }

  void _unmask(int index, int length, Uint8List buffer) {
    const int BLOCK_SIZE = 16;
    // Skip Int32x4-version if message is small.
    if (length >= BLOCK_SIZE) {
      // Start by aligning to 16 bytes.
      final int startOffset = BLOCK_SIZE - (index & 15);
      final int end = index + startOffset;
      for (int i = index; i < end; i++) {
        buffer[i] ^= _maskingBytes[_unmaskingIndex++ & 3];
      }
      index += startOffset;
      length -= startOffset;
      final int blockCount = length ~/ BLOCK_SIZE;
      if (blockCount > 0) {
        // Create mask block.
        int mask = 0;
        for (int i = 3; i >= 0; i--) {
          mask = (mask << 8) | _maskingBytes[(_unmaskingIndex + i) & 3];
        }
        Int32x4 blockMask = new Int32x4(mask, mask, mask, mask);
        Int32x4List blockBuffer = new Int32x4List.view(
            buffer.buffer, index, blockCount);
        for (int i = 0; i < blockBuffer.length; i++) {
          blockBuffer[i] ^= blockMask;
        }
        final int bytes = blockCount * BLOCK_SIZE;
        index += bytes;
        length -= bytes;
      }
    }
    // Handle end.
    final int end = index + length;
    for (int i = index; i < end; i++) {
      buffer[i] ^= _maskingBytes[_unmaskingIndex++ & 3];
    }
  }

  void _lengthDone() {
    if (_masked) {
      if (!_serverSide) {
        throw new CompatibleWebSocketException(
            "Received masked frame from server");
      }
      _state = MASK;
    } else {
      if (_serverSide) {
        throw new CompatibleWebSocketException(
            "Received unmasked frame from client");
      }
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
            _state = CLOSED;
            _eventSink.close();
            break;
          case _WebSocketOpcode.PING:
            _eventSink.add(new _WebSocketPing());
            break;
          case _WebSocketOpcode.PONG:
            _eventSink.add(new _WebSocketPong());
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
      switch (_currentMessageType) {
        case _WebSocketMessageType.TEXT:
          _eventSink.add(UTF8.decode(_payload.takeBytes()));
          break;
        case _WebSocketMessageType.BINARY:
          _eventSink.add(_payload.takeBytes());
          break;
      }
      _currentMessageType = _WebSocketMessageType.NONE;
    }
    _prepareForNextFrame();
  }

  void _controlFrameEnd() {
    switch (_opcode) {
      case _WebSocketOpcode.CLOSE:
        closeCode = _WebSocketStatus.NO_STATUS_RECEIVED;
        var payload = _payload.takeBytes();
        if (payload.length > 0) {
          if (payload.length == 1) {
            throw new CompatibleWebSocketException("Protocol error");
          }
          closeCode = payload[0] << 8 | payload[1];
          if (closeCode == _WebSocketStatus.NO_STATUS_RECEIVED) {
            throw new CompatibleWebSocketException("Protocol error");
          }
          if (payload.length > 2) {
            closeReason = UTF8.decode(payload.sublist(2));
          }
        }
        _state = CLOSED;
        _eventSink.close();
        break;

      case _WebSocketOpcode.PING:
        _eventSink.add(new _WebSocketPing(_payload.takeBytes()));
        break;

      case _WebSocketOpcode.PONG:
        _eventSink.add(new _WebSocketPong(_payload.takeBytes()));
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
    _fin = false;
    _opcode = -1;
    _len = -1;
    _remainingLenBytes = -1;
    _remainingMaskingKeyBytes = 4;
    _remainingPayloadBytes = -1;
    _unmaskingIndex = 0;
  }
}


class _WebSocketPing {
  final List<int> payload;
  _WebSocketPing([this.payload = null]);
}


class _WebSocketPong {
  final List<int> payload;
  _WebSocketPong([this.payload = null]);
}

// TODO(ajohnsen): Make this transformer reusable.
class _WebSocketOutgoingTransformer implements StreamTransformer, EventSink {
  final _WebSocketImpl webSocket;
  EventSink _eventSink;

  _WebSocketOutgoingTransformer(this.webSocket);

  Stream bind(Stream stream) {
    return new Stream.eventTransformed(
        stream,
        (EventSink eventSink) {
          if (_eventSink != null) {
            throw new StateError("WebSocket transformer already used");
          }
          _eventSink = eventSink;
          return this;
        });
  }

  void add(message) {
    if (message is _WebSocketPong) {
      addFrame(_WebSocketOpcode.PONG, message.payload);
      return;
    }
    if (message is _WebSocketPing) {
      addFrame(_WebSocketOpcode.PING, message.payload);
      return;
    }
    List<int> data;
    int opcode;
    if (message != null) {
      if (message is String) {
        opcode = _WebSocketOpcode.TEXT;
        data = UTF8.encode(message);
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
    addFrame(opcode, data);
  }

  void addError(Object error, [StackTrace stackTrace]) =>
      _eventSink.addError(error, stackTrace);

  void close() {
    int code = webSocket._outCloseCode;
    String reason = webSocket._outCloseReason;
    List<int> data;
    if (code != null) {
      data = new List<int>();
      data.add((code >> 8) & 0xFF);
      data.add(code & 0xFF);
      if (reason != null) {
        data.addAll(UTF8.encode(reason));
      }
    }
    addFrame(_WebSocketOpcode.CLOSE, data);
    _eventSink.close();
  }

  void addFrame(int opcode, List<int> data) =>
      createFrame(opcode, data, webSocket._serverSide).forEach(_eventSink.add);

  static Iterable createFrame(int opcode, List<int> data, bool serverSide) {
    bool mask = !serverSide;  // Masking not implemented for server.
    int dataLength = data == null ? 0 : data.length;
    // Determine the header size.
    int headerSize = (mask) ? 6 : 2;
    if (dataLength > 65535) {
      headerSize += 8;
    } else if (dataLength > 125) {
      headerSize += 2;
    }
    Uint8List header = new Uint8List(headerSize);
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
      var maskBytes = [_random.nextInt(256), _random.nextInt(256),
          _random.nextInt(256), _random.nextInt(256)];
      header.setRange(index, index + 4, maskBytes);
      index += 4;
      if (data != null) {
        Uint8List list;
        // If this is a text message just do the masking inside the
        // encoded data.
        if (opcode == _WebSocketOpcode.TEXT && data is Uint8List) {
          list = data;
        } else {
          if (data is Uint8List) {
            list = new Uint8List.fromList(data);
          } else {
            list = new Uint8List(data.length);
            for (int i = 0; i < data.length; i++) {
              if (data[i] < 0 || 255 < data[i]) {
                throw new ArgumentError(
                    "List element is not a byte value "
                    "(value ${data[i]} at index $i)");
              }
              list[i] = data[i];
            }
          }
        }
        const int BLOCK_SIZE = 16;
        int blockCount = list.length ~/ BLOCK_SIZE;
        if (blockCount > 0) {
          // Create mask block.
          int mask = 0;
          for (int i = 3; i >= 0; i--) {
            mask = (mask << 8) | maskBytes[i];
          }
          Int32x4 blockMask = new Int32x4(mask, mask, mask, mask);
          Int32x4List blockBuffer = new Int32x4List.view(
              list.buffer, 0, blockCount);
          for (int i = 0; i < blockBuffer.length; i++) {
            blockBuffer[i] ^= blockMask;
          }
        }
        // Handle end.
        for (int i = blockCount * BLOCK_SIZE; i < list.length; i++) {
          list[i] ^= maskBytes[i & 3];
        }
        data = list;
      }
    }
    assert(index == headerSize);
    if (data == null) {
      return [header];
    } else {
      return [header, data];
    }
  }
}


class _WebSocketConsumer implements StreamConsumer {
  final _WebSocketImpl webSocket;
  final StreamSink<List<int>> sink;
  StreamController _controller;
  StreamSubscription _subscription;
  bool _issuedPause = false;
  bool _closed = false;
  Completer _closeCompleter = new Completer();
  Completer _completer;

  _WebSocketConsumer(this.webSocket, this.sink);

  void _onListen() {
    if (_subscription != null) {
      _subscription.cancel();
    }
  }

  void _onPause() {
    if (_subscription != null) {
      _subscription.pause();
    } else {
      _issuedPause = true;
    }
  }

  void _onResume() {
    if (_subscription != null) {
      _subscription.resume();
    } else {
      _issuedPause = false;
    }
  }

  void _cancel() {
    if (_subscription != null) {
      var subscription = _subscription;
      _subscription = null;
      subscription.cancel();
    }
  }

  _ensureController() {
    if (_controller != null) return;
    _controller = new StreamController(sync: true,
                                       onPause: _onPause,
                                       onResume: _onResume,
                                       onCancel: _onListen);
    var stream = _controller.stream.transform(
        new _WebSocketOutgoingTransformer(webSocket));
    sink.addStream(stream)
        .then((_) {
          _done();
          _closeCompleter.complete(webSocket);
        }, onError: (error, StackTrace stackTrace) {
          _closed = true;
          _cancel();
          if (error is ArgumentError) {
            if (!_done(error, stackTrace)) {
              _closeCompleter.completeError(error, stackTrace);
            }
          } else {
            _done();
            _closeCompleter.complete(webSocket);
          }
        });
  }

  bool _done([error, StackTrace stackTrace]) {
    if (_completer == null) return false;
    if (error != null) {
      _completer.completeError(error, stackTrace);
    } else {
      _completer.complete(webSocket);
    }
    _completer = null;
    return true;
  }

  Future addStream(var stream) {
    if (_closed) {
      stream.listen(null).cancel();
      return new Future.value(webSocket);
    }
    _ensureController();
    _completer = new Completer();
    _subscription = stream.listen(
        (data) {
          _controller.add(data);
        },
        onDone: _done,
        onError: _done,
        cancelOnError: true);
    if (_issuedPause) {
      _subscription.pause();
      _issuedPause = false;
    }
    return _completer.future;
  }

  Future close() {
    _ensureController();
    Future closeSocket() {
      return sink.close().catchError((_) {}).then((_) => webSocket);
    }
    _controller.close();
    return _closeCompleter.future.then((_) => closeSocket());
  }

  void add(data) {
    if (_closed) return;
    _ensureController();
    _controller.add(data);
  }

  void closeSocket() {
    _closed = true;
    _cancel();
    close();
  }
}


class _WebSocketImpl extends Stream implements CompatibleWebSocket {
  StreamController _controller;
  StreamSubscription _subscription;
  StreamController _sink;

  final bool _serverSide;
  int _readyState = _WebSocketState.CONNECTING;
  bool _writeClosed = false;
  int _closeCode;
  String _closeReason;
  Duration _pingInterval;
  Timer _pingTimer;
  _WebSocketConsumer _consumer;

  int _outCloseCode;
  String _outCloseReason;
  Timer _closeTimer;

  _WebSocketImpl._fromSocket(Stream<List<int>> stream,
      StreamSink<List<int>> sink, [this._serverSide = false]) {
    _consumer = new _WebSocketConsumer(this, sink);
    _sink = new StreamController();
    _sink.stream.pipe(_consumer);
    _readyState = _WebSocketState.OPEN;

    var transformer = new _WebSocketProtocolTransformer(_serverSide);
    _subscription = stream.transform(transformer).listen(
        (data) {
          if (data is _WebSocketPing) {
            if (!_writeClosed) _consumer.add(new _WebSocketPong(data.payload));
          } else if (data is _WebSocketPong) {
            // Simply set pingInterval, as it'll cancel any timers.
            pingInterval = _pingInterval;
          } else {
            _controller.add(data);
          }
        },
        onError: (error) {
          if (_closeTimer != null) _closeTimer.cancel();
          if (error is FormatException) {
            _close(_WebSocketStatus.INVALID_FRAME_PAYLOAD_DATA);
          } else {
            _close(_WebSocketStatus.PROTOCOL_ERROR);
          }
          _controller.close();
        },
        onDone: () {
          if (_closeTimer != null) _closeTimer.cancel();
          if (_readyState == _WebSocketState.OPEN) {
            _readyState = _WebSocketState.CLOSING;
            if (!_isReservedStatusCode(transformer.closeCode)) {
              _close(transformer.closeCode);
            } else {
              _close();
            }
            _readyState = _WebSocketState.CLOSED;
          }
          _closeCode = transformer.closeCode;
          _closeReason = transformer.closeReason;
          _controller.close();
        },
        cancelOnError: true);
    _subscription.pause();
    _controller = new StreamController(sync: true,
                                       onListen: _subscription.resume,
                                       onPause: _subscription.pause,
                                       onResume: _subscription.resume);
  }

  StreamSubscription listen(void onData(message),
                            {Function onError,
                             void onDone(),
                             bool cancelOnError}) {
    return _controller.stream.listen(onData,
                                     onError: onError,
                                     onDone: onDone,
                                     cancelOnError: cancelOnError);
  }

  Duration get pingInterval => _pingInterval;

  void set pingInterval(Duration interval) {
    if (_writeClosed) return;
    if (_pingTimer != null) _pingTimer.cancel();
    _pingInterval = interval;

    if (_pingInterval == null) return;

    _pingTimer = new Timer(_pingInterval, () {
      if (_writeClosed) return;
      _consumer.add(new _WebSocketPing());
      _pingTimer = new Timer(_pingInterval, () {
        // No pong received.
        _close(_WebSocketStatus.GOING_AWAY);
      });
    });
  }

  int get closeCode => _closeCode;
  String get closeReason => _closeReason;

  void add(data) => _sink.add(data);
  void addError(error, [StackTrace stackTrace]) =>
      _sink.addError(error, stackTrace);
  Future addStream(Stream stream) => _sink.addStream(stream);
  Future get done => _sink.done;

  Future close([int code, String reason]) {
    if (_isReservedStatusCode(code)) {
      throw new CompatibleWebSocketException("Reserved status code $code");
    }
    if (_outCloseCode == null) {
      _outCloseCode = code;
      _outCloseReason = reason;
    }
    if (_closeTimer == null && !_controller.isClosed) {
      // When closing the web-socket, we no longer accept data.
      _closeTimer = new Timer(const Duration(seconds: 5), () {
        _subscription.cancel();
        _controller.close();
      });
    }
    return _sink.close();
  }

  void _close([int code, String reason]) {
    if (_writeClosed) return;
    if (_outCloseCode == null) {
      _outCloseCode = code;
      _outCloseReason = reason;
    }
    _writeClosed = true;
    _consumer.closeSocket();
  }

  static bool _isReservedStatusCode(int code) {
    return code != null &&
           (code < _WebSocketStatus.NORMAL_CLOSURE ||
            code == _WebSocketStatus.RESERVED_1004 ||
            code == _WebSocketStatus.NO_STATUS_RECEIVED ||
            code == _WebSocketStatus.ABNORMAL_CLOSURE ||
            (code > _WebSocketStatus.INTERNAL_SERVER_ERROR &&
             code < _WebSocketStatus.RESERVED_1015) ||
            (code >= _WebSocketStatus.RESERVED_1015 &&
             code < 3000));
  }
}

