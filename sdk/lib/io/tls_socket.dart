// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * TlsSocket provides a secure (SSL or TLS) client connection to a server.
 * The certificate provided by the server is checked
 * using the certificate database provided in setCertificateDatabase.
 */
abstract class TlsSocket implements Socket {
  /**
   * Constructs a new secure client socket and connect it to the given
   * host on the given port. The returned socket is not yet connected
   * but ready for registration of callbacks.
   */
  factory TlsSocket(String host, int port) => new _TlsSocket(host, port);

   /**
   * Initializes the TLS library with the path to a certificate database
   * containing root certificates for verifying certificate paths on
   * client connections, and server certificates to provide on server
   * connections.  The password argument should be used when creating
   * secure server sockets, to allow the private key of the server
   * certificate to be fetched.
   *
   * The database should be an NSS certificate database directory
   * containing a cert9.db file, not a cert8.db file.  This version of
   * the database can be created using the NSS certutil tool with "sql:" in
   * front of the absolute path of the database directory, or setting the
   * environment variable NSS_DEFAULT_DB_TYPE to "sql".
   */
  external static void setCertificateDatabase(String certificateDatabase,
                                              [String password]);
}


class _TlsSocket implements TlsSocket {
  // Status states
  static final int NOT_CONNECTED = 200;
  static final int HANDSHAKE = 201;
  static final int CONNECTED = 202;
  static final int CLOSED = 203;

  // Buffer identifiers.
  // These must agree with those in the native C++ implementation.
  static final int READ_PLAINTEXT = 0;
  static final int WRITE_PLAINTEXT = 1;
  static final int READ_ENCRYPTED = 2;
  static final int WRITE_ENCRYPTED = 3;
  static final int NUM_BUFFERS = 4;

  int _count = 0;
  // Constructs a new secure client socket.
  factory _TlsSocket(String host, int port) =>
      new _TlsSocket.internal(host, port, false);

  // Constructs a new secure server socket, with the named server certificate.
  factory _TlsSocket.server(String host,
                            int port,
                            Socket socket,
                            String certificateName) =>
      new _TlsSocket.internal(host, port, true, socket, certificateName);

  _TlsSocket.internal(String host,
                      int port,
                      bool is_server,
                      [Socket socket,
                       String certificateName])
      : _host = host,
        _port = port,
        _socket = socket,
        _certificateName = certificateName,
        _is_server = is_server,
        _tlsFilter = new _TlsFilter() {
    if (_socket == null) {
      _socket = new Socket(host, port);
    }
    _socket.onConnect = _tlsConnectHandler;
    _socket.onData = _tlsDataHandler;
    _socket.onClosed = _tlsCloseHandler;
    _tlsFilter.init();
    _tlsFilter.registerHandshakeCompleteCallback(_tlsHandshakeCompleteHandler);
  }

  InputStream get inputStream {
    // TODO(6701): Implement stream interfaces on TlsSocket.
    throw new UnimplementedError("TlsSocket.inputStream not implemented yet");
  }

  int get port => _socket.port;

  String get remoteHost => _socket.remoteHost;

  int get remotePort => _socket.remotePort;

  void set onClosed(void callback()) {
    _socketCloseHandler = callback;
  }

  void set onConnect(void callback()) {
    _socketConnectHandler = callback;
  }

  void set onData(void callback()) {
    _socketDataHandler = callback;
  }

  void set onWrite(void callback()) {
    _socketWriteHandler = callback;
    // Reset the one-shot onWrite handler.
    _socket.onWrite = _tlsWriteHandler;
  }

  OutputStream get outputStream {
    // TODO(6701): Implement stream interfaces on TlsSocket.
    throw new UnimplementedError("TlsSocket.inputStream not implemented yet");
  }

  int available() {
    throw new UnimplementedError("TlsSocket.available not implemented yet");
  }

  void close([bool halfClose]) {
    _socket.close(halfClose);
  }

  List<int> read([int len]) {
    var buffer = _tlsFilter.buffers[READ_PLAINTEXT];
    _readEncryptedData();
    int toRead = buffer.length;
    if (len != null) {
      if (len is! int || len < 0) {
        throw new ArgumentError(
            "Invalid len parameter in TlsSocket.read (len: $len)");
      }
      if (len < toRead) {
        toRead = len;
      }
    }
    List<int> result = buffer.data.getRange(buffer.start, toRead);
    buffer.advanceStart(toRead);
    _setHandlersAfterRead();
    return result;
  }

  int readList(List<int> data, int offset, int bytes) {
    if (offset < 0 || bytes < 0 || offset + bytes > data.length) {
      throw new ArgumentError(
          "Invalid offset or bytes in TlsSocket.readList");
    }

    int bytesRead = 0;
    var buffer = _tlsFilter.buffers[READ_PLAINTEXT];
    // TODO(whesse): Currently this fails if the if is turned into a while loop.
    // Fix it so that it can loop and read more than one buffer's worth of data.
    if (bytes > bytesRead) {
      _readEncryptedData();
      if (buffer.length > 0) {
        int toRead = min(bytes - bytesRead, buffer.length);
        data.setRange(offset, toRead, buffer.data, buffer.start);
        buffer.advanceStart(toRead);
        bytesRead += toRead;
        offset += toRead;
      }
    }

    _setHandlersAfterRead();
    return bytesRead;
  }

  // Write the data to the socket, and flush it as much as possible
  // until it would block.  If the write would block, _writeEncryptedData sets
  // up handlers to flush the pipeline when possible.
  int writeList(List<int> data, int offset, int bytes) {
    var buffer = _tlsFilter.buffers[WRITE_PLAINTEXT];
    if (bytes > buffer.free) {
      bytes = buffer.free;
    }
    if (bytes > 0) {
      buffer.data.setRange(buffer.start + buffer.length, bytes, data, offset);
      buffer.length += bytes;
    }
    _writeEncryptedData();  // Tries to flush all pipeline stages.
    return bytes;
  }

  void _tlsConnectHandler() {
    _connectPending = true;
    _tlsFilter.connect(_host, _port, _is_server, _certificateName);
    _status = HANDSHAKE;
    _tlsHandshake();
  }

  void _tlsWriteHandler() {
    if (_status == HANDSHAKE) {
      _tlsHandshake();
    } else if (_status == CONNECTED) {
      if (_socketWriteHandler != null) {
        _socketWriteHandler();
      }
    }
  }

  void _tlsDataHandler() {
    if (_status == HANDSHAKE) {
      _tlsHandshake();
    } else {
      _writeEncryptedData();  // TODO(whesse): Removing this causes a failure.
      _readEncryptedData();
      var buffer = _tlsFilter.buffers[READ_PLAINTEXT];
      if (_filterEmpty) {
        if (_fireCloseEventPending) {
          _fireCloseEvent();
        }
      } else {  // Filter is not empty.
        if (scheduledDataEvent != null) {
          scheduledDataEvent.cancel();
          scheduledDataEvent = null;
        }
        if (_socketDataHandler != null) {
          _socketDataHandler();
        }
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

  void _tlsHandshake() {
      _readEncryptedData();
      _tlsFilter.handshake();
      _writeEncryptedData();
      if (_tlsFilter.buffers[WRITE_ENCRYPTED].length > 0) {
        _socket.onWrite = _tlsWriteHandler;
      }
  }

  void _tlsHandshakeCompleteHandler() {
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

  void _readEncryptedData() {
    // Read from the socket, and push it through the filter as far as
    // possible.
    var encrypted = _tlsFilter.buffers[READ_ENCRYPTED];
    var plaintext = _tlsFilter.buffers[READ_PLAINTEXT];
    bool progress = true;
    while (progress) {
      progress = false;
      // Do not try to read plaintext from the filter while handshaking.
      if ((_status == CONNECTED || _status == CLOSED) && plaintext.free > 0) {
        int bytes = _tlsFilter.processBuffer(READ_PLAINTEXT);
        if (bytes > 0) {
          plaintext.length += bytes;
          progress = true;
        }
      }
      if (encrypted.length > 0) {
        int bytes = _tlsFilter.processBuffer(READ_ENCRYPTED);
        if (bytes > 0) {
          encrypted.advanceStart(bytes);
          progress = true;
        }
      }
      if (!_socketClosed) {
        int bytes = _socket.readList(encrypted.data,
                                     encrypted.start + encrypted.length,
                                     encrypted.free);
        if (bytes > 0) {
          encrypted.length += bytes;
          progress = true;
        }
      }
    }
    // TODO(whesse): This can be incorrect if there is a partial
    // encrypted block stuck in the tlsFilter, and no other data.
    // Fix this - we do need to know when the filter is empty.
    _filterEmpty = (plaintext.length == 0);
  }

  void _writeEncryptedData() {
    // Write from the filter to the socket.
    var buffer = _tlsFilter.buffers[WRITE_ENCRYPTED];
    while (true) {
      if (buffer.length > 0) {
        int bytes = _socket.writeList(buffer.data, buffer.start, buffer.length);
        if (bytes == 0) {
          // The socket has blocked while we have data to write.
          // We must be notified when it becomes unblocked.
          _socket.onWrite = _tlsWriteHandler;
          break;
        }
        buffer.advanceStart(bytes);
      } else {
        var plaintext = _tlsFilter.buffers[WRITE_PLAINTEXT];
        if (plaintext.length > 0) {
           int plaintext_bytes = _tlsFilter.processBuffer(WRITE_PLAINTEXT);
           plaintext.advanceStart(plaintext_bytes);
        }
        int bytes = _tlsFilter.processBuffer(WRITE_ENCRYPTED);
        if (bytes <= 0) break;
        buffer.length += bytes;
      }
    }
  }

  /* After a read, the onData handler is enabled to fire again.
   * We may also have a close event waiting for the TlsFilter to empty.
   */
  void _setHandlersAfterRead() {
    // If the filter is empty, then we are guaranteed an event when it
    // becomes unblocked.
    // Otherwise, schedule a _tlsDataHandler call since there may data
    // available, and this read call enables the data event.
    if (!_filterEmpty && scheduledDataEvent == null) {
      scheduledDataEvent = new Timer(0, (_) => _tlsDataHandler());
    } else if (_filterEmpty && scheduledDataEvent != null) {
        scheduledDataEvent.cancel();
        scheduledDataEvent = null;
    }
    if (_filterEmpty && _fireCloseEventPending) {
        _fireCloseEvent();
    }
  }

  // _TlsSocket cannot extend _Socket and use _Socket's factory constructor.
  Socket _socket;
  String _host;
  int _port;
  bool _is_server;
  String _certificateName;

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

  _TlsFilter _tlsFilter;
}


class _TlsExternalBuffer {
  static final int SIZE = 8 * 1024;
  _TlsExternalBuffer() : start = 0, length = 0;

  // TODO(whesse): Consider making this a circular buffer.  Only if it helps.
  void advanceStart(int numBytes) {
    start += numBytes;
    length -= numBytes;
    if (length == 0) {
      start = 0;
    }
  }

  int get free => SIZE - (start + length);

  List data;  // This will be a ExternalByteArray, backed by C allocated data.
  int start;
  int length;
}


abstract class _TlsFilter {
  external factory _TlsFilter();

  void connect(String hostName,
               int port,
               bool is_server,
               String certificateName);
  void destroy();
  void handshake();
  void init();
  int processBuffer(int bufferIndex);
  void registerHandshakeCompleteCallback(Function handshakeCompleteHandler);

  List<_TlsExternalBuffer> get buffers;
}
