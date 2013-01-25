// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * SecureSocket provides a secure (SSL or TLS) client connection to a server.
 * The certificate provided by the server is checked
 * using the certificate database (optionally) provided in initialize().
 */
abstract class SecureSocket implements Socket {
  /**
   * Constructs a new secure client socket and connect it to the given
   * host on the given port. The returned socket is not yet connected
   * but ready for registration of callbacks.  If sendClientCertificate is
   * set to true, the socket will send a client certificate if one is
   * requested by the server.  If clientCertificate is the nickname of
   * a certificate in the certificate database, that certificate will be sent.
   * If clientCertificate is null, which is the usual use case, an
   * appropriate certificate will be searched for in the database and
   * sent automatically, based on what the server says it will accept.
   */
  factory SecureSocket(String host,
                       int port,
                       {bool sendClientCertificate: false,
                        String certificateName}) {
    return new _SecureSocket(host,
                             port,
                             certificateName,
                             is_server: false,
                             sendClientCertificate: sendClientCertificate);
  }

  /**
   * Install a handler for unverifiable certificates.  The handler can inspect
   * the certificate, and decide (or let the user decide) whether to accept
   * the connection or not.  The callback should return true
   * to continue the SecureSocket connection.
   */
  void set onBadCertificate(bool callback(X509Certificate certificate));

  /**
   * Get the peerCertificate for a connected secure socket.  For a server
   * socket, this will return the client certificate, or null, if no
   * client certificate was received.  For a client socket, this
   * will return the server's certificate.
   */
  X509Certificate get peerCertificate;

   /**
   * Initializes the NSS library.  If [initialize] is not called, the library
   * is automatically initialized as if [initialize] were called with no
   * arguments.
   *
   * The optional argument [database] is the path to a certificate database
   * containing root certificates for verifying certificate paths on
   * client connections, and server certificates to provide on server
   * connections.  The argument [password] should be used when creating
   * secure server sockets, to allow the private key of the server
   * certificate to be fetched.  If [useBuiltinRoots] is true (the default),
   * then a built-in set of root certificates for trusted certificate
   * authorities is merged with the certificates in the database.
   *
   * Examples:
   *   1) Use only the builtin root certificates:
   *     SecureSocket.initialize(); or
   *
   *   2) Use a specified database and the builtin roots:
   *     SecureSocket.initialize(database: 'path/to/my/database',
   *                             password: 'my_password');
   *
   *   3) Use a specified database, without builtin roots:
   *     SecureSocket.initialize(database: 'path/to/my/database',
   *                             password: 'my_password'.
   *                             useBuiltinRoots: false);
   *
   * The database should be an NSS certificate database directory
   * containing a cert9.db file, not a cert8.db file.  This version of
   * the database can be created using the NSS certutil tool with "sql:" in
   * front of the absolute path of the database directory, or setting the
   * environment variable [[NSS_DEFAULT_DB_TYPE]] to "sql".
   */
  external static void initialize({String database,
                                   String password,
                                   bool useBuiltinRoots: true});
}


/**
 * X509Certificate represents an SSL certificate, with accessors to
 * get the fields of the certificate.
 */
class X509Certificate {
  X509Certificate(this.subject,
                  this.issuer,
                  this.startValidity,
                  this.endValidity);
  final String subject;
  final String issuer;
  final DateTime startValidity;
  final DateTime endValidity;
}


class _SecureSocket implements SecureSocket {
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

  _SecureSocket(String this.host,
                int requestedPort,
                String this.certificateName,
                {bool this.is_server,
                 Socket this.socket,
                 bool this.requestClientCertificate: false,
                 bool this.requireClientCertificate: false,
                 bool this.sendClientCertificate: false})
      : secureFilter = new _SecureFilter() {
    // Throw an ArgumentError if any field is invalid.
    _verifyFields();
    if (socket == null) {
      socket = new Socket(host, requestedPort);
    }
    socket.onConnect = _secureConnectHandler;
    socket.onData = _secureDataHandler;
    socket.onClosed = _secureCloseHandler;
    socket.onError = _secureErrorHandler;
    secureFilter.init();
    secureFilter.registerHandshakeCompleteCallback(
        _secureHandshakeCompleteHandler);
  }

  void _verifyFields() {
    if (host is! String) throw new ArgumentError(
        "SecureSocket constructor: host is not a String");
    assert(is_server is bool);
    assert(socket == null || socket is Socket);
    if (certificateName != null && certificateName is! String) {
      throw new ArgumentError(
          "SecureSocket constructor: certificateName is not null or a String");
    }
    if (certificateName == null && is_server) {
      throw new ArgumentError(
          "SecureSocket constructor: certificateName is null on a server");
    }
    if (requestClientCertificate is! bool) {
      throw new ArgumentError(
          "SecureSocket constructor: requestClientCertificate is not a bool");
    }
    if (requireClientCertificate is! bool) {
      throw new ArgumentError(
          "SecureSocket constructor: requireClientCertificate is not a bool");
    }
    if (sendClientCertificate is! bool) {
      throw new ArgumentError(
          "SecureSocket constructor: sendClientCertificate is not a bool");
    }
  }

  int get port => socket.port;

  String get remoteHost => socket.remoteHost;

  int get remotePort => socket.remotePort;

  void set onClosed(void callback()) {
    if (_inputStream != null && callback != null) {
      throw new StreamException(
           "Cannot set close handler when input stream is used");
    }
    _onClosed = callback;
  }

  void set _onClosed(void callback()) {
    _socketCloseHandler = callback;
  }

  void set onConnect(void callback()) {
    if (_status == CONNECTED || _status == CLOSED) {
      throw new StreamException(
          "Cannot set connect handler when already connected");
    }
    _onConnect = callback;
  }

  void set _onConnect(void callback()) {
    _socketConnectHandler = callback;
  }

  void set onData(void callback()) {
    if (_inputStream != null && callback != null) {
      throw new StreamException(
          "Cannot set data handler when input stream is used");
    }
    _onData = callback;
  }

  void set _onData(void callback()) {
    _socketDataHandler = callback;
  }

  void set onError(void callback(e)) {
    _socketErrorHandler = callback;
  }

  void set onWrite(void callback()) {
    if (_outputStream != null && callback != null) {
      throw new StreamException(
          "Cannot set write handler when output stream is used");
    }
    _onWrite = callback;
  }

  void set _onWrite(void callback()) {
    _socketWriteHandler = callback;
    // Reset the one-shot onWrite handler.
    socket.onWrite = _secureWriteHandler;
  }

  void set onBadCertificate(bool callback(X509Certificate certificate)) {
    if (callback is! Function && callback != null) {
      throw new SocketIOException(
          "Callback provided to onBadCertificate is not a function or null");
    }
    secureFilter.registerBadCertificateCallback(callback);
  }

  InputStream get inputStream {
    if (_inputStream == null) {
      if (_socketDataHandler != null || _socketCloseHandler != null) {
        throw new StreamException(
            "Cannot get input stream when socket handlers are used");
      }
      _inputStream = new _SocketInputStream(this);
    }
    return _inputStream;
  }

  OutputStream get outputStream {
    if (_outputStream == null) {
      if (_socketWriteHandler != null) {
        throw new StreamException(
            "Cannot get output stream when socket write handler is used");
      }
      _outputStream = new _SocketOutputStream(this);
    }
    return _outputStream;
  }

  int available() {
    throw new UnimplementedError("SecureSocket.available not implemented yet");
  }

  void close([bool halfClose = false]) {
    if (_status == CLOSED) return;
    if (halfClose) {
      _closedWrite = true;
      _writeEncryptedData();
      if (_filterWriteEmpty) {
        socket.close(true);
        _socketClosedWrite = true;
        if (_closedRead) {
          close(false);
        }
      }
    } else {
      _closedWrite = true;
      _closedRead = true;
      socket.close(false);
      _socketClosedWrite = true;
      _socketClosedRead = true;
      secureFilter.destroy();
      secureFilter = null;
      if (scheduledDataEvent != null) {
        scheduledDataEvent.cancel();
      }
      _status = CLOSED;
    }
  }

  void _closeWrite() => close(true);

  List<int> read([int len]) {
    if (_closedRead) {
      throw new SocketIOException("Reading from a closed socket");
    }
    if (_status != CONNECTED) {
      return new List<int>(0);
    }
    var buffer = secureFilter.buffers[READ_PLAINTEXT];
    _readEncryptedData();
    int toRead = buffer.length;
    if (len != null) {
      if (len is! int || len < 0) {
        throw new ArgumentError(
            "Invalid len parameter in SecureSocket.read (len: $len)");
      }
      if (len < toRead) {
        toRead = len;
      }
    }
    List<int> result = (toRead == 0) ? null :
        buffer.data.getRange(buffer.start, toRead);
    buffer.advanceStart(toRead);
    _setHandlersAfterRead();
    return result;
  }

  int readList(List<int> data, int offset, int bytes) {
    if (_closedRead) {
      throw new SocketIOException("Reading from a closed socket");
    }
    if (offset < 0 || bytes < 0 || offset + bytes > data.length) {
      throw new ArgumentError(
          "Invalid offset or bytes in SecureSocket.readList");
    }
    if (_status != CONNECTED && _status != CLOSED) {
      return 0;
    }

    int bytesRead = 0;
    var buffer = secureFilter.buffers[READ_PLAINTEXT];
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
    if (_closedWrite) {
      throw new SocketIOException("Writing to a closed socket");
    }
    if (_status != CONNECTED) return 0;
    var buffer = secureFilter.buffers[WRITE_PLAINTEXT];
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

  X509Certificate get peerCertificate => secureFilter.peerCertificate;

  void _secureConnectHandler() {
    _connectPending = true;
    secureFilter.connect(host,
                         port,
                         is_server,
                         certificateName,
                         requestClientCertificate || requireClientCertificate,
                         requireClientCertificate,
                         sendClientCertificate);
    _status = HANDSHAKE;
    _secureHandshake();
  }

  void _secureWriteHandler() {
    _writeEncryptedData();
    if (_filterWriteEmpty && _closedWrite && !_socketClosedWrite) {
      close(true);
    }
    if (_status == HANDSHAKE) {
      _secureHandshake();
    } else if (_status == CONNECTED &&
               _socketWriteHandler != null &&
               secureFilter.buffers[WRITE_PLAINTEXT].free > 0) {
      // We must be able to set onWrite from the onWrite callback.
      var handler = _socketWriteHandler;
      // Reset the one-shot handler.
      _socketWriteHandler = null;
      handler();
    }
  }

  void _secureDataHandler() {
    if (_status == HANDSHAKE) {
      try {
        _secureHandshake();
      } catch (e) { _reportError(e, "SecureSocket error"); }
    } else {
      try {
        _writeEncryptedData();  // TODO(whesse): Removing this causes a failure.
        _readEncryptedData();
      } catch (e) { _reportError(e, "SecureSocket error"); }
      if (!_filterReadEmpty) {
        // Call the onData event.
        if (scheduledDataEvent != null) {
          scheduledDataEvent.cancel();
          scheduledDataEvent = null;
        }
        if (_socketDataHandler != null) {
          _socketDataHandler();
        }
      } else if (_socketClosedRead) {
        _secureCloseHandler();
      }
    }
  }

  void _secureErrorHandler(e) {
    _reportError(e, 'Error on underlying Socket');
  }

  void _reportError(error, String message) {
    // TODO(whesse): Call _reportError from all internal functions that throw.
    var e;
    if (error is SocketIOException) {
      e = new SocketIOException('$message (${error.message})', error.osError);
    } else if (error is OSError) {
      e = new SocketIOException(message, error);
    } else {
      e = new SocketIOException('$message (${error.toString()})', null);
    }
    close(false);
    bool reported = false;
    if (_socketErrorHandler != null) {
      reported = true;
      _socketErrorHandler(e);
    }
    if (_inputStream != null) {
      reported = reported || _inputStream._onSocketError(e);
    }
    if (_outputStream != null) {
      reported = reported || _outputStream._onSocketError(e);
    }
    if (!reported) throw e;
  }

  void _secureCloseHandler() {
    if (_closedRead) return;
    _socketClosedRead = true;
    if (_filterReadEmpty) {
      _closedRead = true;
      if (scheduledDataEvent != null) {
        scheduledDataEvent.cancel();
      }
      if (_socketCloseHandler != null) {
        _socketCloseHandler();
      }
      if (_socketClosedWrite) {
        close(false);
      }
    }
  }

  void _secureHandshake() {
    _readEncryptedData();
    secureFilter.handshake();
    _writeEncryptedData();
    if (secureFilter.buffers[WRITE_ENCRYPTED].length > 0) {
      socket.onWrite = _secureWriteHandler;
    }
  }

  void _secureHandshakeCompleteHandler() {
    _status = CONNECTED;
    if (_connectPending && _socketConnectHandler != null) {
      _connectPending = false;
      _socketConnectHandler();
    }
    if (_socketWriteHandler != null) {
      socket.onWrite = _secureWriteHandler;
    }
  }

  // True if the underlying socket is closed, the filter has been emptied of
  // all data, and the close event has been fired.
  get _closed => _socketClosed;

  void _readEncryptedData() {
    // Read from the socket, and push it through the filter as far as
    // possible.
    var encrypted = secureFilter.buffers[READ_ENCRYPTED];
    var plaintext = secureFilter.buffers[READ_PLAINTEXT];
    bool progress = true;
    while (progress) {
      progress = false;
      // Do not try to read plaintext from the filter while handshaking.
      if ((_status == CONNECTED) && plaintext.free > 0) {
        int bytes = secureFilter.processBuffer(READ_PLAINTEXT);
        if (bytes > 0) {
          plaintext.length += bytes;
          progress = true;
        }
      }
      if (encrypted.length > 0) {
        int bytes = secureFilter.processBuffer(READ_ENCRYPTED);
        if (bytes > 0) {
          encrypted.advanceStart(bytes);
          progress = true;
        }
      }
      if (!_socketClosedRead) {
        int bytes = socket.readList(encrypted.data,
                                    encrypted.start + encrypted.length,
                                    encrypted.free);
        if (bytes > 0) {
          encrypted.length += bytes;
          progress = true;
        }
      }
    }
    // If there is any data in any stages of the filter, there should
    // be data in the plaintext buffer after this process.
    // TODO(whesse): Verify that this is true, and there can be no
    // partial encrypted block stuck in the secureFilter.
    _filterReadEmpty = (plaintext.length == 0);
  }

  void _writeEncryptedData() {
    if (_socketClosedWrite) return;
    var encrypted = secureFilter.buffers[WRITE_ENCRYPTED];
    var plaintext = secureFilter.buffers[WRITE_PLAINTEXT];
    while (true) {
      if (encrypted.length > 0) {
        // Write from the filter to the socket.
        int bytes = socket.writeList(encrypted.data,
                                     encrypted.start,
                                     encrypted.length);
        if (bytes == 0) {
          // The socket has blocked while we have data to write.
          // We must be notified when it becomes unblocked.
          socket.onWrite = _secureWriteHandler;
          _filterWriteEmpty = false;
          break;
        }
        encrypted.advanceStart(bytes);
      } else {
        var plaintext = secureFilter.buffers[WRITE_PLAINTEXT];
        if (plaintext.length > 0) {
           int plaintext_bytes = secureFilter.processBuffer(WRITE_PLAINTEXT);
           plaintext.advanceStart(plaintext_bytes);
        }
        int bytes = secureFilter.processBuffer(WRITE_ENCRYPTED);
        if (bytes <= 0) {
          // We know the WRITE_ENCRYPTED buffer is empty, and the
          // filter wrote zero bytes to it, so the filter must be empty.
          // Also, the WRITE_PLAINTEXT buffer must have been empty, or
          // it would have written to the filter.
          // TODO(whesse): Verify that the filter works this way.
          _filterWriteEmpty = true;
          break;
        }
        encrypted.length += bytes;
      }
    }
  }

  /* After a read, the onData handler is enabled to fire again.
   * We may also have a close event waiting for the SecureFilter to empty.
   */
  void _setHandlersAfterRead() {
    // If the filter is empty, then we are guaranteed an event when it
    // becomes unblocked.  Cancel any _secureDataHandler call.
    // Otherwise, schedule a _secureDataHandler call since there may data
    // available, and this read call enables the data event.
    if (_filterReadEmpty) {
      if (scheduledDataEvent != null) {
        scheduledDataEvent.cancel();
        scheduledDataEvent = null;
      }
    } else if (scheduledDataEvent == null) {
      scheduledDataEvent = new Timer(0, (_) => _secureDataHandler());
    }

    if (_socketClosedRead) {  // An onClose event is pending.
      // _closedRead is false, since we are in a read or readList call.
      if (!_filterReadEmpty) {
        // _filterReadEmpty may be out of date since read and readList empty
        // the plaintext buffer after calling _readEncryptedData.
        // TODO(whesse): Fix this as part of fixing read and readList.
        _readEncryptedData();
      }
      if (_filterReadEmpty) {
        // This can't be an else clause: the value of _filterReadEmpty changes.
        // This must be asynchronous, because we are in a read or readList call.
        new Timer(0, (_) => _secureCloseHandler());
      }
    }
  }

  bool get _socketClosed => _closedRead;

  // _SecureSocket cannot extend _Socket and use _Socket's factory constructor.
  Socket socket;
  final String host;
  final bool is_server;
  final String certificateName;
  final bool requestClientCertificate;
  final bool requireClientCertificate;
  final bool sendClientCertificate;

  var _status = NOT_CONNECTED;
  bool _socketClosedRead = false;  // The network socket is closed for reading.
  bool _socketClosedWrite = false;  // The network socket is closed for writing.
  bool _closedRead = false;  // The secure socket has fired an onClosed event.
  bool _closedWrite = false;  // The secure socket has been closed for writing.
  bool _filterReadEmpty = true;  // There is no buffered data to read.
  bool _filterWriteEmpty = true;  // There is no buffered data to be written.
  _SocketInputStream _inputStream;
  _SocketOutputStream _outputStream;
  bool _connectPending = false;
  Function _socketConnectHandler;
  Function _socketWriteHandler;
  Function _socketDataHandler;
  Function _socketErrorHandler;
  Function _socketCloseHandler;
  Timer scheduledDataEvent;

  _SecureFilter secureFilter;
}


class _ExternalBuffer {
  // Performance is improved if a full buffer of plaintext fits
  // in the encrypted buffer, when encrypted.
  static final int SIZE = 8 * 1024;
  static final int ENCRYPTED_SIZE = 10 * 1024;
  _ExternalBuffer() : start = 0, length = 0;

  // TODO(whesse): Consider making this a circular buffer.  Only if it helps.
  void advanceStart(int numBytes) {
    start += numBytes;
    length -= numBytes;
    if (length == 0) {
      start = 0;
    }
  }

  int get free => data.length - (start + length);

  List data;  // This will be a ExternalByteArray, backed by C allocated data.
  int start;
  int length;
}


abstract class _SecureFilter {
  external factory _SecureFilter();

  void connect(String hostName,
               int port,
               bool is_server,
               String certificateName,
               bool requestClientCertificate,
               bool requireClientCertificate,
               bool sendClientCertificate);
  void destroy();
  void handshake();
  void init();
  X509Certificate get peerCertificate;
  int processBuffer(int bufferIndex);
  void registerBadCertificateCallback(Function callback);
  void registerHandshakeCompleteCallback(Function handshakeCompleteHandler);

  List<_ExternalBuffer> get buffers;
}
