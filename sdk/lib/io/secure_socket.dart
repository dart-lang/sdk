// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * A high-level class for communicating securely over a TCP socket, using
 * TLS and SSL. The [SecureSocket] exposes both a [Stream] and an
 * [IOSink] interface, making it ideal for using together with
 * other [Stream]s.
 */
abstract class SecureSocket implements Socket {
  external factory SecureSocket._(RawSecureSocket rawSocket);

  /**
   * Constructs a new secure client socket and connect it to the given
   * [host] on port [port]. The returned Future will complete with a
   * [SecureSocket] that is connected and ready for subscription.
   *
   * If [sendClientCertificate] is set to true, the socket will send a client
   * certificate if one is requested by the server.
   *
   * If [certificateName] is the nickname of a certificate in the certificate
   * database, that certificate will be sent.
   *
   * If [certificateName] is null, which is the usual use case, an
   * appropriate certificate will be searched for in the database and
   * sent automatically, based on what the server says it will accept.
   *
   * [onBadCertificate] is an optional handler for unverifiable certificates.
   * The handler receives the [X509Certificate], and can inspect it and
   * decide (or let the user decide) whether to accept
   * the connection or not.  The handler should return true
   * to continue the [SecureSocket] connection.
   */
  static Future<SecureSocket> connect(
      host,
      int port,
      {bool sendClientCertificate: false,
       String certificateName,
       bool onBadCertificate(X509Certificate certificate)}) {
    return RawSecureSocket.connect(host,
                                   port,
                                   sendClientCertificate: sendClientCertificate,
                                   certificateName: certificateName,
                                   onBadCertificate: onBadCertificate)
        .then((rawSocket) => new SecureSocket._(rawSocket));
  }

  /**
   * Takes an already connected [socket] and starts client side TLS
   * handshake to make the communication secure. When the returned
   * future completes the [SecureSocket] has completed the TLS
   * handshake. Using this function requires that the other end of the
   * connection is prepared for TLS handshake.
   *
   * If the [socket] already has a subscription, this subscription
   * will no longer receive and events. In most cases calling
   * [:pause:] on this subscription before starting TLS handshake is
   * the right thing to do.
   *
   * If the [host] argument is passed it will be used as the host name
   * for the TLS handshake. If [host] is not passed the host name from
   * the [socket] will be used. The [host] can be either a [String] or
   * an [InternetAddress].
   *
   * See [connect] for more information on the arguments.
   *
   */
  static Future<SecureSocket> secure(
      Socket socket,
      {host,
       bool sendClientCertificate: false,
       String certificateName,
       bool onBadCertificate(X509Certificate certificate)}) {
    var completer = new Completer();
    (socket as dynamic)._detachRaw()
        .then((detachedRaw) {
          return RawSecureSocket.secure(
            detachedRaw[0],
            subscription: detachedRaw[1],
            host: host,
            sendClientCertificate: sendClientCertificate,
            onBadCertificate: onBadCertificate);
          })
        .then((raw) {
          completer.complete(new SecureSocket._(raw));
        });
    return completer.future;
  }

  /**
   * Takes an already connected [socket] and starts server side TLS
   * handshake to make the communication secure. When the returned
   * future completes the [SecureSocket] has completed the TLS
   * handshake. Using this function requires that the other end of the
   * connection is going to start the TLS handshake.
   *
   * If the [socket] already has a subscription, this subscription
   * will no longer receive and events. In most cases calling
   * [:pause:] on this subscription before starting TLS handshake is
   * the right thing to do.
   *
   * If some of the data of the TLS handshake has already been read
   * from the socket this data can be passed in the [carryOverData]
   * parameter. This data will be processed before any other data
   * available on the socket.
   *
   * See [SecureServerSocket.bind] for more information on the
   * arguments.
   *
   */
  static Future<SecureSocket> secureServer(
      Socket socket,
      String certificateName,
      {List<int> carryOverData,
       bool requestClientCertificate: false,
       bool requireClientCertificate: false}) {
    var completer = new Completer();
    (socket as dynamic)._detachRaw()
        .then((detachedRaw) {
          return RawSecureSocket.secureServer(
            detachedRaw[0],
            certificateName,
            subscription: detachedRaw[1],
            carryOverData: carryOverData,
            requestClientCertificate: requestClientCertificate,
            requireClientCertificate: requireClientCertificate);
          })
        .then((raw) {
          completer.complete(new SecureSocket._(raw));
        });
    return completer.future;
  }

  /**
   * Get the peer certificate for a connected SecureSocket.  If this
   * SecureSocket is the server end of a secure socket connection,
   * [peerCertificate] will return the client certificate, or null, if no
   * client certificate was received.  If it is the client end,
   * [peerCertificate] will return the server's certificate.
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
 * RawSecureSocket provides a secure (SSL or TLS) network connection.
 * Client connections to a server are provided by calling
 * RawSecureSocket.connect.  A secure server, created with
 * RawSecureServerSocket, also returns RawSecureSocket objects representing
 * the server end of a secure connection.
 * The certificate provided by the server is checked
 * using the certificate database provided in SecureSocket.initialize, and/or
 * the default built-in root certificates.
 */
abstract class RawSecureSocket implements RawSocket {
  /**
   * Constructs a new secure client socket and connect it to the given
   * host on the given port. The returned Future is completed with the
   * RawSecureSocket when it is connected and ready for subscription.
   *
   * The certificate provided by the server is checked using the certificate
   * database provided in [SecureSocket.initialize], and/or the default built-in
   * root certificates. If [sendClientCertificate] is
   * set to true, the socket will send a client certificate if one is
   * requested by the server. If [certificateName] is the nickname of
   * a certificate in the certificate database, that certificate will be sent.
   * If [certificateName] is null, which is the usual use case, an
   * appropriate certificate will be searched for in the database and
   * sent automatically, based on what the server says it will accept.
   *
   * [onBadCertificate] is an optional handler for unverifiable certificates.
   * The handler receives the [X509Certificate], and can inspect it and
   * decide (or let the user decide) whether to accept
   * the connection or not.  The handler should return true
   * to continue the [RawSecureSocket] connection.
   */
  static Future<RawSecureSocket> connect(
      host,
      int port,
      {bool sendClientCertificate: false,
       String certificateName,
       bool onBadCertificate(X509Certificate certificate)}) {
    return  _RawSecureSocket.connect(
        host,
        port,
        certificateName,
        is_server: false,
        sendClientCertificate: sendClientCertificate,
        onBadCertificate: onBadCertificate);
  }

  /**
   * Takes an already connected [socket] and starts client side TLS
   * handshake to make the communication secure. When the returned
   * future completes the [RawSecureSocket] has completed the TLS
   * handshake. Using this function requires that the other end of the
   * connection is prepared for TLS handshake.
   *
   * If the [socket] already has a subscription, pass the existing
   * subscription in the [subscription] parameter. The secure socket
   * will take over the subscription and process any subsequent
   * events.
   *
   * See [connect] for more information on the arguments.
   *
   */
  static Future<RawSecureSocket> secure(
      RawSocket socket,
      {StreamSubscription subscription,
       host,
       bool sendClientCertificate: false,
       String certificateName,
       bool onBadCertificate(X509Certificate certificate)}) {
    socket.readEventsEnabled = false;
    socket.writeEventsEnabled = false;
    return  _RawSecureSocket.connect(
        host != null ? host : socket.address,
        socket.port,
        certificateName,
        is_server: false,
        socket: socket,
        subscription: subscription,
        sendClientCertificate: sendClientCertificate,
        onBadCertificate: onBadCertificate);
  }

  /**
   * Takes an already connected [socket] and starts server side TLS
   * handshake to make the communication secure. When the returned
   * future completes the [RawSecureSocket] has completed the TLS
   * handshake. Using this function requires that the other end of the
   * connection is going to start the TLS handshake.
   *
   * If the [socket] already has a subscription, pass the existing
   * subscription in the [subscription] parameter. The secure socket
   * will take over the subscription and process any subsequent
   * events.
   *
   * If some of the data of the TLS handshake has already been read
   * from the socket this data can be passed in the [carryOverData]
   * parameter. This data will be processed before any other data
   * available on the socket.
   *
   * See [RawSecureServerSocket.bind] for more information on the
   * arguments.
   *
   */
  static Future<RawSecureSocket> secureServer(
      RawSocket socket,
      String certificateName,
      {StreamSubscription subscription,
       List<int> carryOverData,
       bool requestClientCertificate: false,
       bool requireClientCertificate: false}) {
    socket.readEventsEnabled = false;
    socket.writeEventsEnabled = false;
    return _RawSecureSocket.connect(
        socket.address,
        socket.remotePort,
        certificateName,
        is_server: true,
        socket: socket,
        subscription: subscription,
        carryOverData: carryOverData,
        requestClientCertificate: requestClientCertificate,
        requireClientCertificate: requireClientCertificate);
  }

  /**
   * Get the peer certificate for a connected RawSecureSocket.  If this
   * RawSecureSocket is the server end of a secure socket connection,
   * [peerCertificate] will return the client certificate, or null, if no
   * client certificate was received.  If it is the client end,
   * [peerCertificate] will return the server's certificate.
   */
  X509Certificate get peerCertificate;
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


class _RawSecureSocket extends Stream<RawSocketEvent>
                       implements RawSecureSocket {
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

  RawSocket _socket;
  final Completer<_RawSecureSocket> _handshakeComplete =
      new Completer<_RawSecureSocket>();
  StreamController<RawSocketEvent> _controller;
  Stream<RawSocketEvent> _stream;
  StreamSubscription<RawSocketEvent> _socketSubscription;
  List<int> _carryOverData;
  int _carryOverDataIndex = 0;
  final InternetAddress address;
  final bool is_server;
  final String certificateName;
  final bool requestClientCertificate;
  final bool requireClientCertificate;
  final bool sendClientCertificate;
  final Function onBadCertificate;

  var _status = NOT_CONNECTED;
  bool _writeEventsEnabled = true;
  bool _readEventsEnabled = true;
  bool _socketClosedRead = false;  // The network socket is closed for reading.
  bool _socketClosedWrite = false;  // The network socket is closed for writing.
  bool _closedRead = false;  // The secure socket has fired an onClosed event.
  bool _closedWrite = false;  // The secure socket has been closed for writing.
  bool _filterReadEmpty = true;  // There is no buffered data to read.
  bool _filterWriteEmpty = true;  // There is no buffered data to be written.
  bool _connectPending = false;
  _SecureFilter _secureFilter = new _SecureFilter();

  static Future<_RawSecureSocket> connect(
      host,
      int requestedPort,
      String certificateName,
      {bool is_server,
       RawSocket socket,
       StreamSubscription subscription,
       List<int> carryOverData,
       bool requestClientCertificate: false,
       bool requireClientCertificate: false,
       bool sendClientCertificate: false,
       bool onBadCertificate(X509Certificate certificate)}) {
    var future;
    if (host is String) {
      future = InternetAddress.lookup(host).then((addrs) => addrs.first);
    } else {
      future = new Future.value(host);
    }
    return future.then((addr) {
     return new _RawSecureSocket(addr,
                                 requestedPort,
                                 certificateName,
                                 is_server,
                                 socket,
                                 subscription,
                                 carryOverData,
                                 requestClientCertificate,
                                 requireClientCertificate,
                                 sendClientCertificate,
                                 onBadCertificate)
         ._handshakeComplete.future;
    });
  }

  _RawSecureSocket(
      InternetAddress this.address,
      int requestedPort,
      String this.certificateName,
      bool this.is_server,
      RawSocket socket,
      StreamSubscription this._socketSubscription,
      List<int> this._carryOverData,
      bool this.requestClientCertificate,
      bool this.requireClientCertificate,
      bool this.sendClientCertificate,
      bool this.onBadCertificate(X509Certificate certificate)) {
    _controller = new StreamController<RawSocketEvent>(
        sync: true,
        onListen: _onSubscriptionStateChange,
        onPause: _onPauseStateChange,
        onResume: _onPauseStateChange,
        onCancel: _onSubscriptionStateChange);
    _stream = _controller.stream;
    // Throw an ArgumentError if any field is invalid.  After this, all
    // errors will be reported through the future or the stream.
    _verifyFields();
    _secureFilter.init();
    if (_carryOverData != null) _readFromCarryOver();
    _secureFilter.registerHandshakeCompleteCallback(
        _secureHandshakeCompleteHandler);
    if (onBadCertificate != null) {
      _secureFilter.registerBadCertificateCallback(onBadCertificate);
    }
    var futureSocket;
    if (socket == null) {
      futureSocket = RawSocket.connect(address, requestedPort);
    } else {
      futureSocket = new Future.value(socket);
    }
    futureSocket.then((rawSocket) {
      _socket = rawSocket;
      _socket.readEventsEnabled = true;
      _socket.writeEventsEnabled = false;
      if (_socketSubscription == null) {
        // If a current subscription is provided use this otherwise
        // create a new one.
        _socketSubscription = _socket.listen(_eventDispatcher,
                                             onError: _errorHandler,
                                             onDone: _doneHandler);
      } else {
        _socketSubscription.onData(_eventDispatcher);
        _socketSubscription.onError(_errorHandler);
        _socketSubscription.onDone(_doneHandler);
      }
      _connectPending = true;
      _secureFilter.connect(address.host,
                            port,
                            is_server,
                            certificateName,
                            requestClientCertificate ||
                                requireClientCertificate,
                            requireClientCertificate,
                            sendClientCertificate);
      _status = HANDSHAKE;
      _secureHandshake();
    })
    .catchError((error) {
      _handshakeComplete.completeError(error);
      _close();
    });
  }

  StreamSubscription listen(void onData(RawSocketEvent data),
                            {void onError(error),
                             void onDone(),
                             bool cancelOnError}) {
    if (_writeEventsEnabled) {
      _writeEventsEnabled = false;
      _controller.add(RawSocketEvent.WRITE);
    }
    return _stream.listen(onData,
                          onError: onError,
                          onDone: onDone,
                          cancelOnError: cancelOnError);
  }

  void _verifyFields() {
    assert(is_server is bool);
    assert(_socket == null || _socket is RawSocket);
    if (address is! InternetAddress) {
      throw new ArgumentError(
          "RawSecureSocket constructor: host is not an InternetAddress");
    }
    if (certificateName != null && certificateName is! String) {
      throw new ArgumentError("certificateName is not null or a String");
    }
    if (certificateName == null && is_server) {
      throw new ArgumentError("certificateName is null on a server");
    }
    if (requestClientCertificate is! bool) {
      throw new ArgumentError("requestClientCertificate is not a bool");
    }
    if (requireClientCertificate is! bool) {
      throw new ArgumentError("requireClientCertificate is not a bool");
    }
    if (sendClientCertificate is! bool) {
      throw new ArgumentError("sendClientCertificate is not a bool");
    }
    if (onBadCertificate != null && onBadCertificate is! Function) {
      throw new ArgumentError("onBadCertificate is not null or a Function");
    }
   }

  int get port => _socket.port;

  String get remoteHost => _socket.remoteHost;

  int get remotePort => _socket.remotePort;

  int available() {
    if (_status != CONNECTED) return 0;
    _readEncryptedData();
    return _secureFilter.buffers[READ_PLAINTEXT].length;
  }

  void close() {
    shutdown(SocketDirection.BOTH);
  }

  void _close() {
    _closedWrite = true;
    _closedRead = true;
    if (_socket != null) {
      _socket.close();
    }
    _socketClosedWrite = true;
    _socketClosedRead = true;
    if (_secureFilter != null) {
      _secureFilter.destroy();
      _secureFilter = null;
    }
    if (_socketSubscription != null) {
      _socketSubscription.cancel();
    }
    _controller.close();
    _status = CLOSED;
  }

  void shutdown(SocketDirection direction) {
    if (direction == SocketDirection.SEND ||
        direction == SocketDirection.BOTH) {
      _closedWrite = true;
      _writeEncryptedData();
      if (_filterWriteEmpty) {
        _socket.shutdown(SocketDirection.SEND);
        _socketClosedWrite = true;
        if (_closedRead) {
          _close();
        }
      }
    }
    if (direction == SocketDirection.RECEIVE ||
        direction == SocketDirection.BOTH) {
      _closedRead = true;
      _socketClosedRead = true;
      _socket.shutdown(SocketDirection.RECEIVE);
      if (_socketClosedWrite) {
        _close();
      }
    }
  }

  bool get writeEventsEnabled => _writeEventsEnabled;

  void set writeEventsEnabled(bool value) {
    if (value &&
        _controller.hasListener &&
        _secureFilter != null &&
        _secureFilter.buffers[WRITE_PLAINTEXT].free > 0) {
      Timer.run(() => _controller.add(RawSocketEvent.WRITE));
    } else {
      _writeEventsEnabled = value;
    }
  }

  bool get readEventsEnabled => _readEventsEnabled;

  void set readEventsEnabled(bool value) {
    _readEventsEnabled = value;
    if (value &&
        ((_secureFilter != null &&
          _secureFilter.buffers[READ_PLAINTEXT].length > 0) ||
         _socketClosedRead)) {
      // We might not have no underlying socket to set off read events.
      Timer.run(_readHandler);
    }
  }

  List<int> read([int len]) {
    if (_closedRead) {
      throw new SocketIOException("Reading from a closed socket");
    }
    if (_status != CONNECTED) {
      return null;
    }
    var buffer = _secureFilter.buffers[READ_PLAINTEXT];
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
        buffer.data.sublist(buffer.start, buffer.start + toRead);
    buffer.advanceStart(toRead);

    // Set up a read event if the filter still has data.
    if (!_filterReadEmpty) {
      Timer.run(_readHandler);
    }

    if (_socketClosedRead) {  // An onClose event is pending.
      // _closedRead is false, since we are in a read  call.
      if (!_filterReadEmpty) {
        // _filterReadEmpty may be out of date since read empties
        // the plaintext buffer after calling _readEncryptedData.
        // TODO(whesse): Fix this as part of fixing read.
        _readEncryptedData();
      }
      if (_filterReadEmpty) {
        // This can't be an else clause: the value of _filterReadEmpty changes.
        // This must be asynchronous, because we are in a read call.
        Timer.run(_closeHandler);
      }
    }

    return result;
  }

  // Write the data to the socket, and flush it as much as possible
  // until it would block.  If the write would block, _writeEncryptedData sets
  // up handlers to flush the pipeline when possible.
  int write(List<int> data, [int offset, int bytes]) {
    if (_closedWrite) {
      _controller.addError(new SocketIOException("Writing to a closed socket"));
      return 0;
    }
    if (_status != CONNECTED) return 0;

    if (offset == null) offset = 0;
    if (bytes == null) bytes = data.length - offset;

    var buffer = _secureFilter.buffers[WRITE_PLAINTEXT];
    if (bytes > buffer.free) {
      bytes = buffer.free;
    }
    if (bytes > 0) {
      int startIndex = buffer.start + buffer.length;
      buffer.data.setRange(startIndex, startIndex + bytes, data, offset);
      buffer.length += bytes;
    }
    _writeEncryptedData();  // Tries to flush all pipeline stages.
    return bytes;
  }

  X509Certificate get peerCertificate => _secureFilter.peerCertificate;

  bool setOption(SocketOption option, bool enabled) {
    if (_socket == null) return false;
    return _socket.setOption(option, enabled);
  }

  void _writeHandler() {
    if (_status == CLOSED) return;
    _writeEncryptedData();
    if (_filterWriteEmpty && _closedWrite && !_socketClosedWrite) {
      // Close _socket for write, by calling shutdown(), to avoid cloning the
      // socket closing code in shutdown().
      shutdown(SocketDirection.SEND);
    }
    if (_status == HANDSHAKE) {
      try {
        _secureHandshake();
      } catch (e) { _reportError(e, "RawSecureSocket error"); }
    } else if (_status == CONNECTED &&
               _controller.hasListener &&
               _writeEventsEnabled &&
               _secureFilter.buffers[WRITE_PLAINTEXT].free > 0) {
      // Reset the one-shot handler.
      _writeEventsEnabled = false;
      _controller.add(RawSocketEvent.WRITE);
    }
  }

  void _eventDispatcher(RawSocketEvent event) {
    if (event == RawSocketEvent.READ) {
      _readHandler();
    } else if (event == RawSocketEvent.WRITE) {
      _writeHandler();
    } else if (event == RawSocketEvent.READ_CLOSED) {
      _closeHandler();
    }
  }

  void _readFromCarryOver() {
    assert(_carryOverData != null);
    var encrypted = _secureFilter.buffers[READ_ENCRYPTED];
    var bytes = _carryOverData.length - _carryOverDataIndex;
    int startIndex = encrypted.start + encrypted.length;
    encrypted.data.setRange(startIndex,
                            startIndex + bytes,
                            _carryOverData,
                            _carryOverDataIndex);
    encrypted.length += bytes;
    _carryOverDataIndex += bytes;
    if (_carryOverData.length == _carryOverDataIndex) {
      _carryOverData = null;
    }
  }

  void _readHandler() {
    if (_status == CLOSED) {
      return;
    } else if (_status == HANDSHAKE) {
      try {
        _secureHandshake();
        if (_status != HANDSHAKE) _readHandler();
      } catch (e) { _reportError(e, "RawSecureSocket error"); }
    } else {
      if (_status != CONNECTED) {
        // Cannot happen.
        throw new SocketIOException("Internal SocketIO Error");
      }
      try {
        _readEncryptedData();
      } catch (e) { _reportError(e, "RawSecureSocket error"); }
      if (!_filterReadEmpty) {
        if (_readEventsEnabled) {
          if (_secureFilter.buffers[READ_PLAINTEXT].length > 0) {
            _controller.add(RawSocketEvent.READ);
          }
          if (_socketClosedRead) {
            // Keep firing read events until we are paused or buffer is empty.
            Timer.run(_readHandler);
          }
        }
      } else if (_socketClosedRead) {
        _closeHandler();
      }
    }
  }

  void _doneHandler() {
    if (_filterReadEmpty) {
      _close();
    }
  }

  void _errorHandler(e) {
    _reportError(e, 'Error on underlying RawSocket');
  }

  void _reportError(e, String message) {
    // TODO(whesse): Call _reportError from all internal functions that throw.
    if (e is SocketIOException) {
      e = new SocketIOException('$message (${e.message})', e.osError);
    } else if (e is OSError) {
      e = new SocketIOException(message, e);
    } else {
      e = new SocketIOException('$message (${e.toString()})', null);
    }
    if (_connectPending) {
      _handshakeComplete.completeError(e);
    } else {
      _controller.addError(e);
    }
    _close();
  }

  void _closeHandler() {
    if  (_status == CONNECTED) {
      if (_closedRead) return;
      _socketClosedRead = true;
      if (_filterReadEmpty) {
        _closedRead = true;
        _controller.add(RawSocketEvent.READ_CLOSED);
        if (_socketClosedWrite) {
          _close();
        }
      }
    } else if (_status == HANDSHAKE) {
      _reportError(
          new SocketIOException('Connection terminated during handshake'),
          'handshake error');
    }
  }

  void _secureHandshake() {
    _readEncryptedData();
    _secureFilter.handshake();
    _writeEncryptedData();
  }

  void _secureHandshakeCompleteHandler() {
    _status = CONNECTED;
    if (_connectPending) {
      _connectPending = false;
      // If we complete the future synchronously, user code will run here,
      // and modify the state of the RawSecureSocket.  For example, it
      // could close the socket, and set _filter to null.
      Timer.run(() => _handshakeComplete.complete(this));
    }
  }

  void _onPauseStateChange() {
    if (!_socketClosedRead || !_socketClosedWrite) {
      if (_controller.isPaused) {
        _socketSubscription.pause();
      } else {
        _socketSubscription.resume();
      }
    }
  }

  void _onSubscriptionStateChange() {
    if (_controller.hasListener) {
      // TODO(ajohnsen): Do something here?
    }
  }

  void _readEncryptedData() {
    // Read from the socket, and push it through the filter as far as
    // possible.
    var encrypted = _secureFilter.buffers[READ_ENCRYPTED];
    var plaintext = _secureFilter.buffers[READ_PLAINTEXT];
    bool progress = true;
    while (progress) {
      progress = false;
      // Do not try to read plaintext from the filter while handshaking.
      if ((_status == CONNECTED) && plaintext.free > 0) {
        int bytes = _secureFilter.processBuffer(READ_PLAINTEXT);
        if (bytes > 0) {
          plaintext.length += bytes;
          progress = true;
        }
      }
      if (encrypted.length > 0) {
        int bytes = _secureFilter.processBuffer(READ_ENCRYPTED);
        if (bytes > 0) {
          encrypted.advanceStart(bytes);
          progress = true;
        }
      }
      if (!_socketClosedRead && encrypted.free > 0) {
        if (_carryOverData != null) {
          _readFromCarryOver();
          progress = true;
        } else {
          List<int> data = _socket.read(encrypted.free);
          if (data != null) {
            int bytes = data.length;
            int startIndex = encrypted.start + encrypted.length;
            encrypted.data.setRange(startIndex, startIndex + bytes, data);
            encrypted.length += bytes;
            progress = true;
          }
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
    var encrypted = _secureFilter.buffers[WRITE_ENCRYPTED];
    var plaintext = _secureFilter.buffers[WRITE_PLAINTEXT];
    while (true) {
      if (encrypted.length > 0) {
        // Write from the filter to the socket.
        int bytes = _socket.write(encrypted.data,
                                  encrypted.start,
                                  encrypted.length);
        encrypted.advanceStart(bytes);
        if (encrypted.length > 0) {
          // The socket has blocked while we have data to write.
          // We must be notified when it becomes unblocked.
          _socket.writeEventsEnabled = true;
          _filterWriteEmpty = false;
          break;
        }
      } else {
        var plaintext = _secureFilter.buffers[WRITE_PLAINTEXT];
        if (plaintext.length > 0) {
           int plaintext_bytes = _secureFilter.processBuffer(WRITE_PLAINTEXT);
           plaintext.advanceStart(plaintext_bytes);
        }
        int bytes = _secureFilter.processBuffer(WRITE_ENCRYPTED);
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
