// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _TlsSocket implements TlsSocket {
  static final int _BUFFER_SIZE = 2048;

  // Status states
  static final int NOT_CONNECTED = 200;
  static final int HANDSHAKE = 201;
  static final int CONNECTED = 202;
  static final int CLOSED = 203;

  // Buffer identifiers.
  static final int kReadPlaintext = 0;
  static final int kWritePlaintext = 1;
  static final int kReadEncrypted = 2;
  static final int kWriteEncrypted = 3;
  static final int kNumBuffers = 4;

  // Constructs a new secure client socket.
  _TlsSocket(String host,
             int port)
      : _socket = new Socket(host, port),
        _tlsFilter = new _TlsFilter() {
    _socket.onConnect = _tlsConnectHandler;
    _socket.onWrite = _tlsWriteHandler;
    _socket.onData = _tlsDataHandler;
    _socket.onClosed = _tlsCloseHandler;
    _tlsFilter.init();
    _tlsFilter.registerHandshakeCallbacks(_tlsHandshakeStartHandler,
                                          _tlsHandshakeFinishHandler);
  }

  void set onConnect(void callback()) {
    _socketConnectHandler = callback;
  }

  void set onWrite(void callback()) {
    _socketWriteHandler = callback;
    // Reset the one-shot onWrite handler.
    _socket.onWrite = _tlsWriteHandler;
  }

  void set onData(void callback()) {
    _socketDataHandler = callback;
  }

  void set onClosed(void callback()) {
    _socketCloseHandler = callback;
  }

  void _tlsConnectHandler() {
    _tlsFilter.connect();
    _connectPending = true;
  }

  void _tlsWriteHandler() {
    if (_status == HANDSHAKE) {
      _writeEncryptedData();
      _readEncryptedData();
      _tlsFilter.connect();
      // Only do this if we have more data to write.
      if (_tlsFilter.buffers[kWriteEncrypted].length > 0) {
        _socket.onWrite = _tlsWriteHandler;
      }
    } else if (_status == CONNECTED) {
      if (_socketWriteHandler != null) {
        _socketWriteHandler();
      }
    }
  }

  void _tlsDataHandler() {
    if (_status == HANDSHAKE) {
      _readEncryptedData();
      _writeEncryptedData();
      _tlsFilter.connect();
      _socket.onWrite = _tlsWriteHandler;
    } else {
      if (scheduledDataEvent != null) {
        scheduledDataEvent.cancel();
        scheduledDataEvent = null;
      }
      if (_socketDataHandler != null) {
        _readEncryptedData();
        _socketDataHandler();
      }
    }
  }

  void _tlsCloseHandler() {
    _socketClosed = true;
    _status = CLOSED;
    _socket.close();
    if (_filterEmpty) {
      _fireCloseEvent();
    } else {
      _fireCloseEventPending = true;
    }
  }

  void _tlsHandshakeStartHandler() {
    _status = HANDSHAKE;
    _socket.onWrite = _tlsWriteHandler;
  }

  void _tlsHandshakeFinishHandler() {
    _status = CONNECTED;
    if (_connectPending && _socketConnectHandler != null) {
      _connectPending = false;
      _socketConnectHandler();
    }
  }

  void _fireCloseEvent() {
    _fireCloseEventPending = false;
    _tlsFilter.destroy();
    _tlsFilter = null;
    if (scheduledDataEvent != null) {
      scheduledDataEvent.cancel();
    }
    if (_socketCloseHandler != null) {
      _socketCloseHandler();
    }
  }

  void close([bool halfClose]) {
    _socket.close(halfClose);
  }

  int readList(List<int> data, int offset, int bytes) {
    _readEncryptedData();
    if (offset < 0 || bytes < 0 || offset + bytes > data.length) {
      throw new IllegalArgumentException(
          "Invalid offset or bytes in TlsSocket.readList");
    }
    int bytesRead = 0;
    var buffer = _tlsFilter.buffers[kReadPlaintext];
    if (buffer.length == 0 && buffer.start != 0) {
      throw "Unexpected buffer state in TlsSocket.readList";
    }
    if (buffer.length > 0) {
      int toRead = Math.min(bytes, buffer.length);
      data.setRange(offset, toRead, buffer.data, buffer.start);
      buffer.advanceStart(toRead);
      bytesRead += toRead;
    }
    int newBytes = _tlsFilter.processBuffer(kReadPlaintext);
    if (newBytes > 0) {
      buffer.length += newBytes;
    }
    if (bytes - bytesRead > 0 && buffer.length > 0) {
      int toRead = Math.min(bytes - bytesRead, buffer.length);
      data.setRange(offset + bytesRead, toRead, buffer.data, buffer.start);
      buffer.advanceStart(toRead);
      bytesRead += toRead;
    }

    // If bytesRead is 0, then something is blocked or empty, and
    // we are guaranteed an event when it becomes unblocked.
    // Otherwise, give an event if there is data available, and
    // there has been a read call since the last data event.
    // This gives the invariant that:
    // If there is data available, and there has been a read after the
    // last data event (or no previous one fired), then we are guaranteed
    // to get a data event.
    _filterEmpty = (bytesRead == 0);
    if (bytesRead > 0 && scheduledDataEvent == null) {
      scheduledDataEvent = new Timer(0, (_) => _tlsDataHandler());
    } else if (bytesRead == 0) {
      if (_fireCloseEventPending) {
        _fireCloseEvent();
      } else if (scheduledDataEvent != null) {
        scheduledDataEvent.cancel();
        scheduledDataEvent = null;
      }
    }
    return bytesRead;
  }


  // Write the data to the socket, and flush it as much as possible
  // without blocking.  If not all the data is written, enable the
  // onWrite event.  If data is not all flushed, add handlers to all
  // relevant events.
  int writeList(List<int> data, int offset, int bytes) {
    _writeEncryptedData();  // Tries to flush all post-filter stages.
    var buffer = _tlsFilter.buffers[kWritePlaintext];
    if (bytes > buffer.free) {
      bytes = buffer.free;
    }
    if (bytes > 0) {
      buffer.data.setRange(buffer.start + buffer.length, bytes, data, offset);
      buffer.length += bytes;
    }
    int bytesWritten = _tlsFilter.processBuffer(kWritePlaintext);
    buffer.advanceStart(bytesWritten);
    _readEncryptedData();
    _writeEncryptedData();
    return bytes;
  }

  void _readEncryptedData() {
    // Read from the socket and write to the filter.
    var buffer = _tlsFilter.buffers[kReadEncrypted];
    while (true) {
      if (buffer.length > 0) {
        int bytes = _tlsFilter.processBuffer(kReadEncrypted);
        if (bytes > 0) {
          buffer.advanceStart(bytes);
        } else {
          break;
        }
      } else if (!_socketClosed) {
        int bytes = _socket.readList(buffer.data,
                                     buffer.start + buffer.length,
                                     buffer.free);
        if (bytes <= 0) break;
        buffer.length += bytes;
      } else {
        break;  // Socket is closed and read buffer is empty.
      }
    }
  }

  void _writeEncryptedData() {
    // Write from the filter to the socket.
    var buffer = _tlsFilter.buffers[kWriteEncrypted];
    while (true) {
      if (buffer.length > 0) {
        int bytes = _socket.writeList(buffer.data, buffer.start, buffer.length);
        if (bytes <= 0) break;
        buffer.advanceStart(bytes);
      } else {
        if (buffer.start != 0 || buffer.length != 0) {
          throw "Unexpected state in _writeEncryptedData";
        }
        int bytes = _tlsFilter.processBuffer(kWriteEncrypted);
        if (bytes <= 0) break;
        buffer.length += bytes;
      }
    }
  }

  // _TlsSocket cannot extend _Socket and use _Socket's factory constructor.
  Socket _socket;

  var _status = NOT_CONNECTED;
  bool _socketClosed = false;
  bool _filterEmpty = false;
  bool _connectPending = false;
  bool _fireCloseEventPending = false;
  Function _socketConnectHandler;
  Function _socketWriteHandler;
  Function _socketDataHandler;
  Function _socketCloseHandler;
  Timer scheduledDataEvent;

  var _tlsFilter;
}

class _TlsExternalBuffer {
  static final int kSize = 8 * 1024;
  _TlsExternalBuffer() : start = 0, length = 0;

  void advanceStart(int numBytes) {
    start += numBytes;
    length -= numBytes;
    if (length == 0) {
      start = 0;
    }
  }

  int get free() => kSize - start - length;

  List data;  // This will be a ExternalByteArray, backed by C allocated data.
  int start;
  int length;
}

/**
 * _TlsFilter wraps a filter that encrypts and decrypts data travelling
 * over a TLS encrypted socket.  The filter also handles the handshaking
 * and certificate verification.
 *
 * The filter exposes its input and output buffers as Dart objects that
 * are backed by an external C array of bytes, so that both Dart code and
 * native code can access the same data.
 */
class _TlsFilter extends NativeFieldWrapperClass1 {
  _TlsFilter() {
    buffers = new List<_TlsExternalBuffer>(_TlsSocket.kNumBuffers);
    for (int i = 0; i < _TlsSocket.kNumBuffers; ++i) {
      buffers[i] = new _TlsExternalBuffer();
    }
  }

  void init() native "TlsSocket_Init";

  void connect() native "TlsSocket_Connect";

  void registerHandshakeCallbacks(Function startHandshakeHandler,
                                  Function finishHandshakeHandler)
      native "TlsSocket_RegisterHandshakeCallbacks";
  int processBuffer(int bufferIndex) native "TlsSocket_ProcessBuffer";
  void destroy() native "TlsSocket_Destroy";

  List<_TlsExternalBuffer> buffers;
}
