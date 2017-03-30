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
   * Constructs a new secure client socket and connects it to the given
   * [host] on port [port]. The returned Future will complete with a
   * [SecureSocket] that is connected and ready for subscription.
   *
   * The certificate provided by the server is checked
   * using the trusted certificates set in the SecurityContext object.
   * The default SecurityContext object contains a built-in set of trusted
   * root certificates for well-known certificate authorities.
   *
   * [onBadCertificate] is an optional handler for unverifiable certificates.
   * The handler receives the [X509Certificate], and can inspect it and
   * decide (or let the user decide) whether to accept
   * the connection or not.  The handler should return true
   * to continue the [SecureSocket] connection.
   *
   * [supportedProtocols] is an optional list of protocols (in decreasing
   * order of preference) to use during the ALPN protocol negogiation with the
   * server.  Example values are "http/1.1" or "h2".  The selected protocol
   * can be obtained via [SecureSocket.selectedProtocol].
   */
  static Future<SecureSocket> connect(host, int port,
      {SecurityContext context,
      bool onBadCertificate(X509Certificate certificate),
      List<String> supportedProtocols}) {
    return RawSecureSocket
        .connect(host, port,
            context: context,
            onBadCertificate: onBadCertificate,
            supportedProtocols: supportedProtocols)
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
   * `pause` on this subscription before starting TLS handshake is
   * the right thing to do.
   *
   * If the [host] argument is passed it will be used as the host name
   * for the TLS handshake. If [host] is not passed the host name from
   * the [socket] will be used. The [host] can be either a [String] or
   * an [InternetAddress].
   *
   * Calling this function will _not_ cause a DNS host lookup. If the
   * [host] passed is a [String] the [InternetAddress] for the
   * resulting [SecureSocket] will have the passed in [host] as its
   * host value and the internet address of the already connected
   * socket as its address value.
   *
   * See [connect] for more information on the arguments.
   *
   */
  static Future<SecureSocket> secure(Socket socket,
      {host,
      SecurityContext context,
      bool onBadCertificate(X509Certificate certificate)}) {
    return ((socket as dynamic /*_Socket*/)._detachRaw() as Future)
        .then<RawSecureSocket>((detachedRaw) {
      return RawSecureSocket.secure(detachedRaw[0] as RawSocket,
          subscription: detachedRaw[1] as StreamSubscription<RawSocketEvent>,
          host: host,
          context: context,
          onBadCertificate: onBadCertificate);
    }).then<SecureSocket>((raw) => new SecureSocket._(raw));
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
   * from the socket this data can be passed in the [bufferedData]
   * parameter. This data will be processed before any other data
   * available on the socket.
   *
   * See [SecureServerSocket.bind] for more information on the
   * arguments.
   *
   */
  static Future<SecureSocket> secureServer(
      Socket socket, SecurityContext context,
      {List<int> bufferedData,
      bool requestClientCertificate: false,
      bool requireClientCertificate: false,
      List<String> supportedProtocols}) {
    return ((socket as dynamic /*_Socket*/)._detachRaw() as Future)
        .then<RawSecureSocket>((detachedRaw) {
      return RawSecureSocket.secureServer(detachedRaw[0] as RawSocket, context,
          subscription: detachedRaw[1] as StreamSubscription<RawSocketEvent>,
          bufferedData: bufferedData,
          requestClientCertificate: requestClientCertificate,
          requireClientCertificate: requireClientCertificate,
          supportedProtocols: supportedProtocols);
    }).then<SecureSocket>((raw) => new SecureSocket._(raw));
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
   * The protocol which was selected during ALPN protocol negotiation.
   *
   * Returns null if one of the peers does not have support for ALPN, did not
   * specify a list of supported ALPN protocols or there was no common
   * protocol between client and server.
   */
  String get selectedProtocol;

  /**
   * Renegotiate an existing secure connection, renewing the session keys
   * and possibly changing the connection properties.
   *
   * This repeats the SSL or TLS handshake, with options that allow clearing
   * the session cache and requesting a client certificate.
   */
  void renegotiate(
      {bool useSessionCache: true,
      bool requestClientCertificate: false,
      bool requireClientCertificate: false});
}

/**
 * RawSecureSocket provides a secure (SSL or TLS) network connection.
 * Client connections to a server are provided by calling
 * RawSecureSocket.connect.  A secure server, created with
 * [RawSecureServerSocket], also returns RawSecureSocket objects representing
 * the server end of a secure connection.
 * The certificate provided by the server is checked
 * using the trusted certificates set in the SecurityContext object.
 * The default [SecurityContext] object contains a built-in set of trusted
 * root certificates for well-known certificate authorities.
 */
abstract class RawSecureSocket implements RawSocket {
  /**
   * Constructs a new secure client socket and connect it to the given
   * host on the given port. The returned [Future] is completed with the
   * RawSecureSocket when it is connected and ready for subscription.
   *
   * The certificate provided by the server is checked using the trusted
   * certificates set in the SecurityContext object If a certificate and key are
   * set on the client, using [SecurityContext.useCertificateChain] and
   * [SecurityContext.usePrivateKey], and the server asks for a client
   * certificate, then that client certificate is sent to the server.
   *
   * [onBadCertificate] is an optional handler for unverifiable certificates.
   * The handler receives the [X509Certificate], and can inspect it and
   * decide (or let the user decide) whether to accept
   * the connection or not.  The handler should return true
   * to continue the [RawSecureSocket] connection.
   *
   * [supportedProtocols] is an optional list of protocols (in decreasing
   * order of preference) to use during the ALPN protocol negogiation with the
   * server.  Example values are "http/1.1" or "h2".  The selected protocol
   * can be obtained via [RawSecureSocket.selectedProtocol].
   */
  static Future<RawSecureSocket> connect(host, int port,
      {SecurityContext context,
      bool onBadCertificate(X509Certificate certificate),
      List<String> supportedProtocols}) {
    _RawSecureSocket._verifyFields(
        host, port, false, false, false, onBadCertificate);
    return RawSocket.connect(host, port).then((socket) {
      return secure(socket,
          context: context,
          onBadCertificate: onBadCertificate,
          supportedProtocols: supportedProtocols);
    });
  }

  /**
   * Takes an already connected [socket] and starts client side TLS
   * handshake to make the communication secure. When the returned
   * future completes the [RawSecureSocket] has completed the TLS
   * handshake. Using this function requires that the other end of the
   * connection is prepared for TLS handshake.
   *
   * If the [socket] already has a subscription, pass the existing
   * subscription in the [subscription] parameter. The [secure]
   * operation will take over the subscription by replacing the
   * handlers with it own secure processing. The caller must not touch
   * this subscription anymore. Passing a paused subscription is an
   * error.
   *
   * If the [host] argument is passed it will be used as the host name
   * for the TLS handshake. If [host] is not passed the host name from
   * the [socket] will be used. The [host] can be either a [String] or
   * an [InternetAddress].
   *
   * Calling this function will _not_ cause a DNS host lookup. If the
   * [host] passed is a [String] the [InternetAddress] for the
   * resulting [SecureSocket] will have this passed in [host] as its
   * host value and the internet address of the already connected
   * socket as its address value.
   *
   * See [connect] for more information on the arguments.
   *
   */
  static Future<RawSecureSocket> secure(RawSocket socket,
      {StreamSubscription<RawSocketEvent> subscription,
      host,
      SecurityContext context,
      bool onBadCertificate(X509Certificate certificate),
      List<String> supportedProtocols}) {
    socket.readEventsEnabled = false;
    socket.writeEventsEnabled = false;
    return _RawSecureSocket.connect(
        host != null ? host : socket.address.host, socket.port,
        is_server: false,
        socket: socket,
        subscription: subscription,
        context: context,
        onBadCertificate: onBadCertificate,
        supportedProtocols: supportedProtocols);
  }

  /**
   * Takes an already connected [socket] and starts server side TLS
   * handshake to make the communication secure. When the returned
   * future completes the [RawSecureSocket] has completed the TLS
   * handshake. Using this function requires that the other end of the
   * connection is going to start the TLS handshake.
   *
   * If the [socket] already has a subscription, pass the existing
   * subscription in the [subscription] parameter. The [secureServer]
   * operation will take over the subscription by replacing the
   * handlers with it own secure processing. The caller must not touch
   * this subscription anymore. Passing a paused subscription is an
   * error.
   *
   * If some of the data of the TLS handshake has already been read
   * from the socket this data can be passed in the [bufferedData]
   * parameter. This data will be processed before any other data
   * available on the socket.
   *
   * See [RawSecureServerSocket.bind] for more information on the
   * arguments.
   *
   */
  static Future<RawSecureSocket> secureServer(
      RawSocket socket, SecurityContext context,
      {StreamSubscription<RawSocketEvent> subscription,
      List<int> bufferedData,
      bool requestClientCertificate: false,
      bool requireClientCertificate: false,
      List<String> supportedProtocols}) {
    socket.readEventsEnabled = false;
    socket.writeEventsEnabled = false;
    return _RawSecureSocket.connect(socket.address, socket.remotePort,
        context: context,
        is_server: true,
        socket: socket,
        subscription: subscription,
        bufferedData: bufferedData,
        requestClientCertificate: requestClientCertificate,
        requireClientCertificate: requireClientCertificate,
        supportedProtocols: supportedProtocols);
  }

  /**
   * Renegotiate an existing secure connection, renewing the session keys
   * and possibly changing the connection properties.
   *
   * This repeats the SSL or TLS handshake, with options that allow clearing
   * the session cache and requesting a client certificate.
   */
  void renegotiate(
      {bool useSessionCache: true,
      bool requestClientCertificate: false,
      bool requireClientCertificate: false});

  /**
   * Get the peer certificate for a connected RawSecureSocket.  If this
   * RawSecureSocket is the server end of a secure socket connection,
   * [peerCertificate] will return the client certificate, or null, if no
   * client certificate was received.  If it is the client end,
   * [peerCertificate] will return the server's certificate.
   */
  X509Certificate get peerCertificate;

  /**
   * The protocol which was selected during protocol negotiation.
   *
   * Returns null if one of the peers does not have support for ALPN, did not
   * specify a list of supported ALPN protocols or there was no common
   * protocol between client and server.
   */
  String get selectedProtocol;
}

/**
 * X509Certificate represents an SSL certificate, with accessors to
 * get the fields of the certificate.
 */
abstract class X509Certificate {
  external factory X509Certificate._();

  String get subject;
  String get issuer;
  DateTime get startValidity;
  DateTime get endValidity;
}

class _FilterStatus {
  bool progress = false; // The filter read or wrote data to the buffers.
  bool readEmpty = true; // The read buffers and decryption filter are empty.
  bool writeEmpty = true; // The write buffers and encryption filter are empty.
  // These are set if a buffer changes state from empty or full.
  bool readPlaintextNoLongerEmpty = false;
  bool writePlaintextNoLongerFull = false;
  bool readEncryptedNoLongerFull = false;
  bool writeEncryptedNoLongerEmpty = false;

  _FilterStatus();
}

class _RawSecureSocket extends Stream<RawSocketEvent>
    implements RawSecureSocket {
  // Status states
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

  // Is a buffer identifier for an encrypted buffer?
  static bool _isBufferEncrypted(int identifier) =>
      identifier >= READ_ENCRYPTED;

  RawSocket _socket;
  final Completer<_RawSecureSocket> _handshakeComplete =
      new Completer<_RawSecureSocket>();
  StreamController<RawSocketEvent> _controller;
  Stream<RawSocketEvent> _stream;
  StreamSubscription<RawSocketEvent> _socketSubscription;
  List<int> _bufferedData;
  int _bufferedDataIndex = 0;
  final InternetAddress address;
  final bool is_server;
  SecurityContext context;
  final bool requestClientCertificate;
  final bool requireClientCertificate;
  final Function onBadCertificate;

  var _status = HANDSHAKE;
  bool _writeEventsEnabled = true;
  bool _readEventsEnabled = true;
  int _pauseCount = 0;
  bool _pendingReadEvent = false;
  bool _socketClosedRead = false; // The network socket is closed for reading.
  bool _socketClosedWrite = false; // The network socket is closed for writing.
  bool _closedRead = false; // The secure socket has fired an onClosed event.
  bool _closedWrite = false; // The secure socket has been closed for writing.
  // The network socket is gone.
  Completer<RawSecureSocket> _closeCompleter = new Completer<RawSecureSocket>();
  _FilterStatus _filterStatus = new _FilterStatus();
  bool _connectPending = true;
  bool _filterPending = false;
  bool _filterActive = false;

  _SecureFilter _secureFilter = new _SecureFilter();
  String _selectedProtocol;

  static Future<_RawSecureSocket> connect(
      dynamic /*String|InternetAddress*/ host, int requestedPort,
      {bool is_server,
      SecurityContext context,
      RawSocket socket,
      StreamSubscription<RawSocketEvent> subscription,
      List<int> bufferedData,
      bool requestClientCertificate: false,
      bool requireClientCertificate: false,
      bool onBadCertificate(X509Certificate certificate),
      List<String> supportedProtocols}) {
    _verifyFields(host, requestedPort, is_server, requestClientCertificate,
        requireClientCertificate, onBadCertificate);
    if (host is InternetAddress) host = host.host;
    InternetAddress address = socket.address;
    if (host != null) {
      address = InternetAddress._cloneWithNewHost(address, host);
    }
    return new _RawSecureSocket(
            address,
            requestedPort,
            is_server,
            context,
            socket,
            subscription,
            bufferedData,
            requestClientCertificate,
            requireClientCertificate,
            onBadCertificate,
            supportedProtocols)
        ._handshakeComplete
        .future;
  }

  _RawSecureSocket(
      this.address,
      int requestedPort,
      this.is_server,
      this.context,
      this._socket,
      this._socketSubscription,
      this._bufferedData,
      this.requestClientCertificate,
      this.requireClientCertificate,
      this.onBadCertificate,
      List<String> supportedProtocols) {
    if (context == null) {
      context = SecurityContext.defaultContext;
    }
    _controller = new StreamController<RawSocketEvent>(
        sync: true,
        onListen: _onSubscriptionStateChange,
        onPause: _onPauseStateChange,
        onResume: _onPauseStateChange,
        onCancel: _onSubscriptionStateChange);
    _stream = _controller.stream;
    // Throw an ArgumentError if any field is invalid.  After this, all
    // errors will be reported through the future or the stream.
    _secureFilter.init();
    _secureFilter
        .registerHandshakeCompleteCallback(_secureHandshakeCompleteHandler);
    if (onBadCertificate != null) {
      _secureFilter.registerBadCertificateCallback(_onBadCertificateWrapper);
    }
    _socket.readEventsEnabled = true;
    _socket.writeEventsEnabled = false;
    if (_socketSubscription == null) {
      // If a current subscription is provided use this otherwise
      // create a new one.
      _socketSubscription = _socket.listen(_eventDispatcher,
          onError: _reportError, onDone: _doneHandler);
    } else {
      if (_socketSubscription.isPaused) {
        _socket.close();
        throw new ArgumentError("Subscription passed to TLS upgrade is paused");
      }
      // If we are upgrading a socket that is already closed for read,
      // report an error as if we received READ_CLOSED during the handshake.
      dynamic s = _socket; // Cast to dynamic to avoid warning.
      if (s._socket.closedReadEventSent) {
        _eventDispatcher(RawSocketEvent.READ_CLOSED);
      }
      _socketSubscription
        ..onData(_eventDispatcher)
        ..onError(_reportError)
        ..onDone(_doneHandler);
    }
    try {
      var encodedProtocols =
          SecurityContext._protocolsToLengthEncoding(supportedProtocols);
      _secureFilter.connect(
          address.host,
          context,
          is_server,
          requestClientCertificate || requireClientCertificate,
          requireClientCertificate,
          encodedProtocols);
      _secureHandshake();
    } catch (e, s) {
      _reportError(e, s);
    }
  }

  StreamSubscription<RawSocketEvent> listen(void onData(RawSocketEvent data),
      {Function onError, void onDone(), bool cancelOnError}) {
    _sendWriteEvent();
    return _stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  static void _verifyFields(
      host,
      int requestedPort,
      bool is_server,
      bool requestClientCertificate,
      bool requireClientCertificate,
      Function onBadCertificate) {
    if (host is! String && host is! InternetAddress) {
      throw new ArgumentError("host is not a String or an InternetAddress");
    }
    if (requestedPort is! int) {
      throw new ArgumentError("requestedPort is not an int");
    }
    if (requestedPort < 0 || requestedPort > 65535) {
      throw new ArgumentError("requestedPort is not in the range 0..65535");
    }
    if (requestClientCertificate is! bool) {
      throw new ArgumentError("requestClientCertificate is not a bool");
    }
    if (requireClientCertificate is! bool) {
      throw new ArgumentError("requireClientCertificate is not a bool");
    }
    if (onBadCertificate != null && onBadCertificate is! Function) {
      throw new ArgumentError("onBadCertificate is not null or a Function");
    }
  }

  int get port => _socket.port;

  InternetAddress get remoteAddress => _socket.remoteAddress;

  int get remotePort => _socket.remotePort;

  void set _owner(owner) {
    (_socket as dynamic)._owner = owner;
  }

  int available() {
    return _status != CONNECTED
        ? 0
        : _secureFilter.buffers[READ_PLAINTEXT].length;
  }

  Future<RawSecureSocket> close() {
    shutdown(SocketDirection.BOTH);
    return _closeCompleter.future;
  }

  void _completeCloseCompleter([RawSocket dummy]) {
    if (!_closeCompleter.isCompleted) _closeCompleter.complete(this);
  }

  void _close() {
    _closedWrite = true;
    _closedRead = true;
    if (_socket != null) {
      _socket.close().then(_completeCloseCompleter);
    } else {
      _completeCloseCompleter();
    }
    _socketClosedWrite = true;
    _socketClosedRead = true;
    if (!_filterActive && _secureFilter != null) {
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
      if (_filterStatus.writeEmpty) {
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
    _writeEventsEnabled = value;
    if (value) {
      Timer.run(() => _sendWriteEvent());
    }
  }

  bool get readEventsEnabled => _readEventsEnabled;

  void set readEventsEnabled(bool value) {
    _readEventsEnabled = value;
    _scheduleReadEvent();
  }

  List<int> read([int length]) {
    if (length != null && (length is! int || length < 0)) {
      throw new ArgumentError(
          "Invalid length parameter in SecureSocket.read (length: $length)");
    }
    if (_closedRead) {
      throw new SocketException("Reading from a closed socket");
    }
    if (_status != CONNECTED) {
      return null;
    }
    var result = _secureFilter.buffers[READ_PLAINTEXT].read(length);
    _scheduleFilter();
    return result;
  }

  // Write the data to the socket, and schedule the filter to encrypt it.
  int write(List<int> data, [int offset, int bytes]) {
    if (bytes != null && (bytes is! int || bytes < 0)) {
      throw new ArgumentError(
          "Invalid bytes parameter in SecureSocket.read (bytes: $bytes)");
    }
    if (offset != null && (offset is! int || offset < 0)) {
      throw new ArgumentError(
          "Invalid offset parameter in SecureSocket.read (offset: $offset)");
    }
    if (_closedWrite) {
      _controller.addError(new SocketException("Writing to a closed socket"));
      return 0;
    }
    if (_status != CONNECTED) return 0;
    if (offset == null) offset = 0;
    if (bytes == null) bytes = data.length - offset;

    int written =
        _secureFilter.buffers[WRITE_PLAINTEXT].write(data, offset, bytes);
    if (written > 0) {
      _filterStatus.writeEmpty = false;
    }
    _scheduleFilter();
    return written;
  }

  X509Certificate get peerCertificate => _secureFilter.peerCertificate;

  String get selectedProtocol => _selectedProtocol;

  bool _onBadCertificateWrapper(X509Certificate certificate) {
    if (onBadCertificate == null) return false;
    var result = onBadCertificate(certificate);
    if (result is bool) return result;
    throw new HandshakeException(
        "onBadCertificate callback returned non-boolean $result");
  }

  bool setOption(SocketOption option, bool enabled) {
    if (_socket == null) return false;
    return _socket.setOption(option, enabled);
  }

  void _eventDispatcher(RawSocketEvent event) {
    try {
      if (event == RawSocketEvent.READ) {
        _readHandler();
      } else if (event == RawSocketEvent.WRITE) {
        _writeHandler();
      } else if (event == RawSocketEvent.READ_CLOSED) {
        _closeHandler();
      }
    } catch (e, stackTrace) {
      _reportError(e, stackTrace);
    }
  }

  void _readHandler() {
    _readSocket();
    _scheduleFilter();
  }

  void _writeHandler() {
    _writeSocket();
    _scheduleFilter();
  }

  void _doneHandler() {
    if (_filterStatus.readEmpty) {
      _close();
    }
  }

  void _reportError(e, [StackTrace stackTrace]) {
    if (_status == CLOSED) {
      return;
    } else if (_connectPending) {
      // _connectPending is true until the handshake has completed, and the
      // _handshakeComplete future returned from SecureSocket.connect has
      // completed.  Before this point, we must complete it with an error.
      _handshakeComplete.completeError(e, stackTrace);
    } else {
      _controller.addError(e, stackTrace);
    }
    _close();
  }

  void _closeHandler() {
    if (_status == CONNECTED) {
      if (_closedRead) return;
      _socketClosedRead = true;
      if (_filterStatus.readEmpty) {
        _closedRead = true;
        _controller.add(RawSocketEvent.READ_CLOSED);
        if (_socketClosedWrite) {
          _close();
        }
      } else {
        _scheduleFilter();
      }
    } else if (_status == HANDSHAKE) {
      _socketClosedRead = true;
      if (_filterStatus.readEmpty) {
        _reportError(
            new HandshakeException('Connection terminated during handshake'),
            null);
      } else {
        _secureHandshake();
      }
    }
  }

  void _secureHandshake() {
    try {
      _secureFilter.handshake();
      _filterStatus.writeEmpty = false;
      _readSocket();
      _writeSocket();
      _scheduleFilter();
    } catch (e, stackTrace) {
      _reportError(e, stackTrace);
    }
  }

  void renegotiate(
      {bool useSessionCache: true,
      bool requestClientCertificate: false,
      bool requireClientCertificate: false}) {
    if (_status != CONNECTED) {
      throw new HandshakeException(
          "Called renegotiate on a non-connected socket");
    }
    _secureFilter.renegotiate(
        useSessionCache, requestClientCertificate, requireClientCertificate);
    _status = HANDSHAKE;
    _filterStatus.writeEmpty = false;
    _scheduleFilter();
  }

  void _secureHandshakeCompleteHandler() {
    _status = CONNECTED;
    if (_connectPending) {
      _connectPending = false;
      try {
        _selectedProtocol = _secureFilter.selectedProtocol();
        // We don't want user code to run synchronously in this callback.
        Timer.run(() => _handshakeComplete.complete(this));
      } catch (error, stack) {
        _handshakeComplete.completeError(error, stack);
      }
    }
  }

  void _onPauseStateChange() {
    if (_controller.isPaused) {
      _pauseCount++;
    } else {
      _pauseCount--;
      if (_pauseCount == 0) {
        _scheduleReadEvent();
        _sendWriteEvent(); // Can send event synchronously.
      }
    }

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

  void _scheduleFilter() {
    _filterPending = true;
    _tryFilter();
  }

  void _tryFilter() {
    if (_status == CLOSED) {
      return;
    }
    if (_filterPending && !_filterActive) {
      _filterActive = true;
      _filterPending = false;
      _pushAllFilterStages().then((status) {
        _filterStatus = status;
        _filterActive = false;
        if (_status == CLOSED) {
          _secureFilter.destroy();
          _secureFilter = null;
          return;
        }
        _socket.readEventsEnabled = true;
        if (_filterStatus.writeEmpty && _closedWrite && !_socketClosedWrite) {
          // Checks for and handles all cases of partially closed sockets.
          shutdown(SocketDirection.SEND);
          if (_status == CLOSED) {
            return;
          }
        }
        if (_filterStatus.readEmpty && _socketClosedRead && !_closedRead) {
          if (_status == HANDSHAKE) {
            _secureFilter.handshake();
            if (_status == HANDSHAKE) {
              throw new HandshakeException(
                  'Connection terminated during handshake');
            }
          }
          _closeHandler();
        }
        if (_status == CLOSED) {
          return;
        }
        if (_filterStatus.progress) {
          _filterPending = true;
          if (_filterStatus.writeEncryptedNoLongerEmpty) {
            _writeSocket();
          }
          if (_filterStatus.writePlaintextNoLongerFull) {
            _sendWriteEvent();
          }
          if (_filterStatus.readEncryptedNoLongerFull) {
            _readSocket();
          }
          if (_filterStatus.readPlaintextNoLongerEmpty) {
            _scheduleReadEvent();
          }
          if (_status == HANDSHAKE) {
            _secureHandshake();
          }
        }
        _tryFilter();
      }).catchError(_reportError);
    }
  }

  List<int> _readSocketOrBufferedData(int bytes) {
    if (_bufferedData != null) {
      if (bytes > _bufferedData.length - _bufferedDataIndex) {
        bytes = _bufferedData.length - _bufferedDataIndex;
      }
      var result =
          _bufferedData.sublist(_bufferedDataIndex, _bufferedDataIndex + bytes);
      _bufferedDataIndex += bytes;
      if (_bufferedData.length == _bufferedDataIndex) {
        _bufferedData = null;
      }
      return result;
    } else if (!_socketClosedRead) {
      return _socket.read(bytes);
    } else {
      return null;
    }
  }

  void _readSocket() {
    if (_status == CLOSED) return;
    var buffer = _secureFilter.buffers[READ_ENCRYPTED];
    if (buffer.writeFromSource(_readSocketOrBufferedData) > 0) {
      _filterStatus.readEmpty = false;
    } else {
      _socket.readEventsEnabled = false;
    }
  }

  void _writeSocket() {
    if (_socketClosedWrite) return;
    var buffer = _secureFilter.buffers[WRITE_ENCRYPTED];
    if (buffer.readToSocket(_socket)) {
      // Returns true if blocked
      _socket.writeEventsEnabled = true;
    }
  }

  // If a read event should be sent, add it to the controller.
  _scheduleReadEvent() {
    if (!_pendingReadEvent &&
        _readEventsEnabled &&
        _pauseCount == 0 &&
        _secureFilter != null &&
        !_secureFilter.buffers[READ_PLAINTEXT].isEmpty) {
      _pendingReadEvent = true;
      Timer.run(_sendReadEvent);
    }
  }

  _sendReadEvent() {
    _pendingReadEvent = false;
    if (_status != CLOSED &&
        _readEventsEnabled &&
        _pauseCount == 0 &&
        _secureFilter != null &&
        !_secureFilter.buffers[READ_PLAINTEXT].isEmpty) {
      _controller.add(RawSocketEvent.READ);
      _scheduleReadEvent();
    }
  }

  // If a write event should be sent, add it to the controller.
  _sendWriteEvent() {
    if (!_closedWrite &&
        _writeEventsEnabled &&
        _pauseCount == 0 &&
        _secureFilter != null &&
        _secureFilter.buffers[WRITE_PLAINTEXT].free > 0) {
      _writeEventsEnabled = false;
      _controller.add(RawSocketEvent.WRITE);
    }
  }

  Future<_FilterStatus> _pushAllFilterStages() {
    bool wasInHandshake = _status != CONNECTED;
    List args = new List(2 + NUM_BUFFERS * 2);
    args[0] = _secureFilter._pointer();
    args[1] = wasInHandshake;
    var bufs = _secureFilter.buffers;
    for (var i = 0; i < NUM_BUFFERS; ++i) {
      args[2 * i + 2] = bufs[i].start;
      args[2 * i + 3] = bufs[i].end;
    }

    return _IOService._dispatch(_SSL_PROCESS_FILTER, args).then((response) {
      if (response.length == 2) {
        if (wasInHandshake) {
          // If we're in handshake, throw a handshake error.
          _reportError(
              new HandshakeException('${response[1]} error ${response[0]}'),
              null);
        } else {
          // If we're connected, throw a TLS error.
          _reportError(
              new TlsException('${response[1]} error ${response[0]}'), null);
        }
      }
      int start(int index) => response[2 * index];
      int end(int index) => response[2 * index + 1];

      _FilterStatus status = new _FilterStatus();
      // Compute writeEmpty as "write plaintext buffer and write encrypted
      // buffer were empty when we started and are empty now".
      status.writeEmpty = bufs[WRITE_PLAINTEXT].isEmpty &&
          start(WRITE_ENCRYPTED) == end(WRITE_ENCRYPTED);
      // If we were in handshake when this started, _writeEmpty may be false
      // because the handshake wrote data after we checked.
      if (wasInHandshake) status.writeEmpty = false;

      // Compute readEmpty as "both read buffers were empty when we started
      // and are empty now".
      status.readEmpty = bufs[READ_ENCRYPTED].isEmpty &&
          start(READ_PLAINTEXT) == end(READ_PLAINTEXT);

      _ExternalBuffer buffer = bufs[WRITE_PLAINTEXT];
      int new_start = start(WRITE_PLAINTEXT);
      if (new_start != buffer.start) {
        status.progress = true;
        if (buffer.free == 0) {
          status.writePlaintextNoLongerFull = true;
        }
        buffer.start = new_start;
      }
      buffer = bufs[READ_ENCRYPTED];
      new_start = start(READ_ENCRYPTED);
      if (new_start != buffer.start) {
        status.progress = true;
        if (buffer.free == 0) {
          status.readEncryptedNoLongerFull = true;
        }
        buffer.start = new_start;
      }
      buffer = bufs[WRITE_ENCRYPTED];
      int new_end = end(WRITE_ENCRYPTED);
      if (new_end != buffer.end) {
        status.progress = true;
        if (buffer.length == 0) {
          status.writeEncryptedNoLongerEmpty = true;
        }
        buffer.end = new_end;
      }
      buffer = bufs[READ_PLAINTEXT];
      new_end = end(READ_PLAINTEXT);
      if (new_end != buffer.end) {
        status.progress = true;
        if (buffer.length == 0) {
          status.readPlaintextNoLongerEmpty = true;
        }
        buffer.end = new_end;
      }
      return status;
    });
  }
}

/**
 * A circular buffer backed by an external byte array.  Accessed from
 * both C++ and Dart code in an unsynchronized way, with one reading
 * and one writing.  All updates to start and end are done by Dart code.
 */
class _ExternalBuffer {
  // This will be an ExternalByteArray, backed by C allocated data.
  List<int> data;
  int start;
  int end;
  final size;

  _ExternalBuffer(this.size) {
    start = end = size ~/ 2;
  }

  void advanceStart(int bytes) {
    assert(start > end || start + bytes <= end);
    start += bytes;
    if (start >= size) {
      start -= size;
      assert(start <= end);
      assert(start < size);
    }
  }

  void advanceEnd(int bytes) {
    assert(start <= end || start > end + bytes);
    end += bytes;
    if (end >= size) {
      end -= size;
      assert(end < start);
      assert(end < size);
    }
  }

  bool get isEmpty => end == start;

  int get length => start > end ? size + end - start : end - start;

  int get linearLength => start > end ? size - start : end - start;

  int get free => start > end ? start - end - 1 : size + start - end - 1;

  int get linearFree {
    if (start > end) return start - end - 1;
    if (start == 0) return size - end - 1;
    return size - end;
  }

  List<int> read(int bytes) {
    if (bytes == null) {
      bytes = length;
    } else {
      bytes = min(bytes, length);
    }
    if (bytes == 0) return null;
    List<int> result = new Uint8List(bytes);
    int bytesRead = 0;
    // Loop over zero, one, or two linear data ranges.
    while (bytesRead < bytes) {
      int toRead = min(bytes - bytesRead, linearLength);
      result.setRange(bytesRead, bytesRead + toRead, data, start);
      advanceStart(toRead);
      bytesRead += toRead;
    }
    return result;
  }

  int write(List<int> inputData, int offset, int bytes) {
    if (bytes > free) {
      bytes = free;
    }
    int written = 0;
    int toWrite = min(bytes, linearFree);
    // Loop over zero, one, or two linear data ranges.
    while (toWrite > 0) {
      data.setRange(end, end + toWrite, inputData, offset);
      advanceEnd(toWrite);
      offset += toWrite;
      written += toWrite;
      toWrite = min(bytes - written, linearFree);
    }
    return written;
  }

  int writeFromSource(List<int> getData(int requested)) {
    int written = 0;
    int toWrite = linearFree;
    // Loop over zero, one, or two linear data ranges.
    while (toWrite > 0) {
      // Source returns at most toWrite bytes, and it returns null when empty.
      var inputData = getData(toWrite);
      if (inputData == null || inputData.length == 0) break;
      var len = inputData.length;
      data.setRange(end, end + len, inputData);
      advanceEnd(len);
      written += len;
      toWrite = linearFree;
    }
    return written;
  }

  bool readToSocket(RawSocket socket) {
    // Loop over zero, one, or two linear data ranges.
    while (true) {
      var toWrite = linearLength;
      if (toWrite == 0) return false;
      int bytes = socket.write(data, start, toWrite);
      advanceStart(bytes);
      if (bytes < toWrite) {
        // The socket has blocked while we have data to write.
        return true;
      }
    }
  }
}

abstract class _SecureFilter {
  external factory _SecureFilter();

  void connect(
      String hostName,
      SecurityContext context,
      bool is_server,
      bool requestClientCertificate,
      bool requireClientCertificate,
      Uint8List protocols);
  void destroy();
  void handshake();
  String selectedProtocol();
  void rehandshake();
  void renegotiate(bool useSessionCache, bool requestClientCertificate,
      bool requireClientCertificate);
  void init();
  X509Certificate get peerCertificate;
  int processBuffer(int bufferIndex);
  void registerBadCertificateCallback(Function callback);
  void registerHandshakeCompleteCallback(Function handshakeCompleteHandler);

  // This call may cause a reference counted pointer in the native
  // implementation to be retained. It should only be called when the resulting
  // value is passed to the IO service through a call to dispatch().
  int _pointer();

  List<_ExternalBuffer> get buffers;
}

/** A secure networking exception caused by a failure in the
 *  TLS/SSL protocol.
 */
class TlsException implements IOException {
  final String type;
  final String message;
  final OSError osError;

  const TlsException([String message = "", OSError osError = null])
      : this._("TlsException", message, osError);

  const TlsException._(this.type, this.message, this.osError);

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(type);
    if (!message.isEmpty) {
      sb.write(": $message");
      if (osError != null) {
        sb.write(" ($osError)");
      }
    } else if (osError != null) {
      sb.write(": $osError");
    }
    return sb.toString();
  }
}

/**
 * An exception that happens in the handshake phase of establishing
 * a secure network connection.
 */
class HandshakeException extends TlsException {
  const HandshakeException([String message = "", OSError osError = null])
      : super._("HandshakeException", message, osError);
}

/**
 * An exception that happens in the handshake phase of establishing
 * a secure network connection, when looking up or verifying a
 * certificate.
 */
class CertificateException extends TlsException {
  const CertificateException([String message = "", OSError osError = null])
      : super._("CertificateException", message, osError);
}
