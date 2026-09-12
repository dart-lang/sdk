// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "dart:io";

/// A TCP socket using TLS and SSL.
///
/// See [Socket] for more information.
abstract interface class SecureSocket implements Socket {
  external factory SecureSocket._(RawSecureSocket rawSocket);

  /// Constructs a new secure client socket and connects it to the given
  /// [host] on port [port].
  ///
  /// The returned Future will complete with a
  /// [SecureSocket] that is connected and ready for subscription.
  ///
  /// The certificate provided by the server is checked
  /// using the trusted certificates set in the SecurityContext object.
  /// The default SecurityContext object contains a built-in set of trusted
  /// root certificates for well-known certificate authorities.
  ///
  /// [onBadCertificate] is an optional handler for unverifiable certificates.
  /// The handler receives the [X509Certificate], and can inspect it and
  /// decide (or let the user decide) whether to accept
  /// the connection or not.  The handler should return true
  /// to continue the [SecureSocket] connection.
  ///
  /// [keyLog] is an optional callback that will be called when new TLS keys
  /// are exchanged with the server. [keyLog] will receive one line of text in
  /// [NSS Key Log Format](https://developer.mozilla.org/en-US/docs/Mozilla/Projects/NSS/Key_Log_Format)
  /// for each call. Writing these lines to a file will allow tools (such as
  /// [Wireshark](https://gitlab.com/wireshark/wireshark/-/wikis/TLS#tls-decryption))
  /// to decrypt content sent through this socket. This is meant to allow
  /// network-level debugging of secure sockets and should not be used in
  /// production code. For example:
  /// ```dart
  /// final log = File('keylog.txt');
  /// final socket = await SecureSocket.connect('www.example.com', 443,
  ///     keyLog: (line) => log.writeAsStringSync(line, mode: FileMode.append));
  /// ```
  ///
  /// [supportedProtocols] is an optional list of protocols (in decreasing
  /// order of preference) to use during the ALPN protocol negotiation with the
  /// server.  Example values are "http/1.1" or "h2".  The selected protocol
  /// can be obtained via [SecureSocket.selectedProtocol].
  ///
  /// The argument [timeout] is used to specify the maximum allowed time to wait
  /// for a connection to be established. If [timeout] is longer than the system
  /// level timeout duration, a timeout may occur sooner than specified in
  /// [timeout]. On timeout, a [SocketException] is thrown and all ongoing
  /// connection attempts to [host] are cancelled.
  static Future<SecureSocket> connect(
    host,
    int port, {
    SecurityContext? context,
    bool onBadCertificate(X509Certificate certificate)?,
    void keyLog(String line)?,
    List<String>? supportedProtocols,
    Duration? timeout,
  }) {
    return RawSecureSocket.connect(
      host,
      port,
      context: context,
      onBadCertificate: onBadCertificate,
      keyLog: keyLog,
      supportedProtocols: supportedProtocols,
      timeout: timeout,
    ).then((rawSocket) => SecureSocket._(rawSocket));
  }

  /// Like [connect], but returns a [Future] that completes with a
  /// [ConnectionTask] that can be cancelled if the [SecureSocket] is no
  /// longer needed.
  static Future<ConnectionTask<SecureSocket>> startConnect(
    host,
    int port, {
    SecurityContext? context,
    bool onBadCertificate(X509Certificate certificate)?,
    void keyLog(String line)?,
    List<String>? supportedProtocols,
  }) {
    return RawSecureSocket.startConnect(
      host,
      port,
      context: context,
      onBadCertificate: onBadCertificate,
      keyLog: keyLog,
      supportedProtocols: supportedProtocols,
    ).then((rawState) {
      Future<SecureSocket> socket = rawState.socket.then(
        (rawSocket) => SecureSocket._(rawSocket),
      );
      return ConnectionTask<SecureSocket>._(socket, rawState._onCancel);
    });
  }

  /// Initiates TLS on an existing connection.
  ///
  /// Takes an already connected [socket] and starts client side TLS
  /// handshake to make the communication secure. When the returned
  /// future completes the [SecureSocket] has completed the TLS
  /// handshake. Using this function requires that the other end of the
  /// connection is prepared for TLS handshake.
  ///
  /// If the [socket] already has a subscription, this subscription
  /// will no longer receive and events. In most cases calling
  /// [StreamSubscription.pause] on this subscription before
  /// starting TLS handshake is the right thing to do.
  ///
  /// The given [socket] is closed and may not be used anymore.
  ///
  /// If the [host] argument is passed it will be used as the host name
  /// for the TLS handshake. If [host] is not passed the host name from
  /// the [socket] will be used. The [host] can be either a [String] or
  /// an [InternetAddress].
  ///
  /// [onBadCertificate] is an optional handler for unverifiable certificates.
  /// The handler receives the [X509Certificate], and can inspect it and
  /// decide (or let the user decide) whether to accept
  /// the connection or not.  The handler should return true
  /// to continue the [SecureSocket] connection.
  ///
  /// [keyLog] is an optional callback that will be called when new TLS keys
  /// are exchanged with the server. [keyLog] will receive one line of text in
  /// [NSS Key Log Format](https://developer.mozilla.org/en-US/docs/Mozilla/Projects/NSS/Key_Log_Format)
  /// for each call. Writing these lines to a file will allow tools (such as
  /// [Wireshark](https://gitlab.com/wireshark/wireshark/-/wikis/TLS#tls-decryption))
  /// to decrypt content sent through this socket. This is meant to allow
  /// network-level debugging of secure sockets and should not be used in
  /// production code. For example:
  /// ```dart
  /// final log = File('keylog.txt');
  /// final socket = await SecureSocket.connect('www.example.com', 443,
  ///     keyLog: (line) => log.writeAsStringSync(line, mode: FileMode.append));
  /// ```
  ///
  /// [supportedProtocols] is an optional list of protocols (in decreasing
  /// order of preference) to use during the ALPN protocol negotiation with the
  /// server.  Example values are "http/1.1" or "h2".  The selected protocol
  /// can be obtained via [SecureSocket.selectedProtocol].
  ///
  /// Calling this function will _not_ cause a DNS host lookup. If the
  /// [host] passed is a [String], the [InternetAddress] for the
  /// resulting [SecureSocket] will have the passed in [host] as its
  /// host value and the internet address of the already connected
  /// socket as its address value.
  ///
  /// See [connect] for more information on the arguments.
  static Future<SecureSocket> secure(
    Socket socket, {
    host,
    SecurityContext? context,
    bool onBadCertificate(X509Certificate certificate)?,
    void keyLog(String line)?,
    List<String>? supportedProtocols,
  }) {
    return socket
        ._detachRaw()
        .then<RawSecureSocket>((detachedRaw) {
          return RawSecureSocket.secure(
            detachedRaw[0] as RawSocket,
            subscription: detachedRaw[1] as StreamSubscription<RawSocketEvent>?,
            host: host,
            context: context,
            onBadCertificate: onBadCertificate,
            keyLog: keyLog,
            supportedProtocols: supportedProtocols,
          );
        })
        .then<SecureSocket>((raw) => SecureSocket._(raw));
  }

  /// Initiates TLS on an existing server connection.
  ///
  /// Takes an already connected [socket] and starts server side TLS
  /// handshake to make the communication secure. When the returned
  /// future completes the [SecureSocket] has completed the TLS
  /// handshake. Using this function requires that the other end of the
  /// connection is going to start the TLS handshake.
  ///
  /// If the [socket] already has a subscription, this subscription
  /// will no longer receive and events. In most cases calling
  /// [StreamSubscription.pause] on this subscription
  /// before starting TLS handshake is the right thing to do.
  ///
  /// If some of the data of the TLS handshake has already been read
  /// from the socket this data can be passed in the [bufferedData]
  /// parameter. This data will be processed before any other data
  /// available on the socket.
  ///
  /// See [SecureServerSocket.bind] for more information on the
  /// arguments.
  static Future<SecureSocket> secureServer(
    Socket socket,
    SecurityContext? context, {
    List<int>? bufferedData,
    bool requestClientCertificate = false,
    bool requireClientCertificate = false,
    List<String>? supportedProtocols,
  }) {
    return socket
        ._detachRaw()
        .then<RawSecureSocket>((detachedRaw) {
          return RawSecureSocket.secureServer(
            detachedRaw[0] as RawSocket,
            context,
            subscription: detachedRaw[1] as StreamSubscription<RawSocketEvent>?,
            bufferedData: bufferedData,
            requestClientCertificate: requestClientCertificate,
            requireClientCertificate: requireClientCertificate,
            supportedProtocols: supportedProtocols,
          );
        })
        .then<SecureSocket>((raw) => SecureSocket._(raw));
  }

  /// The peer certificate for a connected SecureSocket.
  ///
  /// If this [SecureSocket] is the server end of a secure socket connection,
  /// [peerCertificate] will return the client certificate, or `null` if no
  /// client certificate was received.  If this socket is the client end,
  /// [peerCertificate] will return the server's certificate.
  X509Certificate? get peerCertificate;

  /// The protocol which was selected during ALPN protocol negotiation.
  ///
  /// Returns `null` if one of the peers does not have support for ALPN, did not
  /// specify a list of supported ALPN protocols or there was no common
  /// protocol between client and server.
  String? get selectedProtocol;

  /// Does nothing.
  ///
  /// The original intent was to allow TLS renegotiation of existing secure
  /// connections.
  @Deprecated("Not implemented")
  void renegotiate({
    bool useSessionCache = true,
    bool requestClientCertificate = false,
    bool requireClientCertificate = false,
  });
}

/// `RawSecureSocket` provides a secure (SSL or TLS) network connection.
///
/// Client connections to a server are provided by calling
/// RawSecureSocket.connect.  A secure server, created with
/// [RawSecureServerSocket], also returns `RawSecureSocket` objects representing
/// the server end of a secure connection.
/// The certificate provided by the server is checked
/// using the trusted certificates set in the [SecurityContext] object.
/// The default [SecurityContext] object contains a built-in set of trusted
/// root certificates for well-known certificate authorities.
///
/// See [RawSocket] for more information.
abstract interface class RawSecureSocket implements RawSocket {
  /// Constructs a new secure client socket and connect it to the given
  /// host on the given port.
  ///
  /// The returned [Future] is completed with the
  /// [RawSecureSocket] when it is connected and ready for subscription.
  ///
  /// The certificate provided by the server is checked using the trusted
  /// certificates set in the SecurityContext object If a certificate and key are
  /// set on the client, using [SecurityContext.useCertificateChain] and
  /// [SecurityContext.usePrivateKey], and the server asks for a client
  /// certificate, then that client certificate is sent to the server.
  ///
  /// [onBadCertificate] is an optional handler for unverifiable certificates.
  /// The handler receives the [X509Certificate], and can inspect it and
  /// decide (or let the user decide) whether to accept
  /// the connection or not.  The handler should return true
  /// to continue the [RawSecureSocket] connection.
  ///
  /// [onBadCertificate] is an optional handler for unverifiable certificates.
  /// The handler receives the [X509Certificate], and can inspect it and
  /// decide (or let the user decide) whether to accept
  /// the connection or not.  The handler should return true
  /// to continue the [SecureSocket] connection.
  ///
  /// [keyLog] is an optional callback that will be called when new TLS keys
  /// are exchanged with the server. [keyLog] will receive one line of text in
  /// [NSS Key Log Format](https://developer.mozilla.org/en-US/docs/Mozilla/Projects/NSS/Key_Log_Format)
  /// for each call. Writing these lines to a file will allow tools (such as
  /// [Wireshark](https://gitlab.com/wireshark/wireshark/-/wikis/TLS#tls-decryption))
  /// to decrypt content sent through this socket. This is meant to allow
  /// network-level debugging of secure sockets and should not be used in
  /// production code. For example:
  /// ```dart
  /// final log = File('keylog.txt');
  /// final socket = await SecureSocket.connect('www.example.com', 443,
  ///     keyLog: (line) => log.writeAsStringSync(line, mode: FileMode.append));
  /// ```
  ///
  /// [supportedProtocols] is an optional list of protocols (in decreasing
  /// order of preference) to use during the ALPN protocol negotiation with the
  /// server.  Example values are "http/1.1" or "h2".  The selected protocol
  /// can be obtained via [RawSecureSocket.selectedProtocol].
  static Future<RawSecureSocket> connect(
    host,
    int port, {
    SecurityContext? context,
    bool onBadCertificate(X509Certificate certificate)?,
    void keyLog(String line)?,
    List<String>? supportedProtocols,
    Duration? timeout,
  }) {
    _RawSecureSocket._verifyFields(host, port, false, false);
    return RawSocket.connect(host, port, timeout: timeout).then((socket) {
      return secure(
        socket,
        context: context,
        onBadCertificate: onBadCertificate,
        keyLog: keyLog,
        supportedProtocols: supportedProtocols,
      );
    });
  }

  /// Like [connect], but returns a [Future] that completes with a
  /// [ConnectionTask] that can be cancelled if the [RawSecureSocket] is no
  /// longer needed.
  static Future<ConnectionTask<RawSecureSocket>> startConnect(
    host,
    int port, {
    SecurityContext? context,
    bool onBadCertificate(X509Certificate certificate)?,
    void keyLog(String line)?,
    List<String>? supportedProtocols,
  }) {
    return RawSocket.startConnect(host, port).then((
      ConnectionTask<RawSocket> rawState,
    ) {
      Future<RawSecureSocket> socket = rawState.socket.then((rawSocket) {
        return secure(
          rawSocket,
          context: context,
          onBadCertificate: onBadCertificate,
          keyLog: keyLog,
          supportedProtocols: supportedProtocols,
        );
      });
      return ConnectionTask<RawSecureSocket>._(socket, rawState._onCancel);
    });
  }

  /// Initiates TLS on an existing connection.
  ///
  /// Takes an already connected [socket] and starts client side TLS
  /// handshake to make the communication secure. When the returned
  /// future completes the [RawSecureSocket] has completed the TLS
  /// handshake. Using this function requires that the other end of the
  /// connection is prepared for TLS handshake.
  ///
  /// If the [socket] already has a subscription, pass the existing
  /// subscription in the [subscription] parameter. The [secure]
  /// operation will take over the subscription by replacing the
  /// handlers with it own secure processing. The caller must not touch
  /// this subscription anymore. Passing a paused subscription is an
  /// error.
  ///
  /// If the [host] argument is passed it will be used as the host name
  /// for the TLS handshake. If [host] is not passed the host name from
  /// the [socket] will be used. The [host] can be either a [String] or
  /// an [InternetAddress].
  ///
  /// [onBadCertificate] is an optional handler for unverifiable certificates.
  /// The handler receives the [X509Certificate], and can inspect it and
  /// decide (or let the user decide) whether to accept
  /// the connection or not.  The handler should return true
  /// to continue the [SecureSocket] connection.
  ///
  /// [keyLog] is an optional callback that will be called when new TLS keys
  /// are exchanged with the server. [keyLog] will receive one line of text in
  /// [NSS Key Log Format](https://developer.mozilla.org/en-US/docs/Mozilla/Projects/NSS/Key_Log_Format)
  /// for each call. Writing these lines to a file will allow tools (such as
  /// [Wireshark](https://gitlab.com/wireshark/wireshark/-/wikis/TLS#tls-decryption))
  /// to decrypt content sent through this socket. This is meant to allow
  /// network-level debugging of secure sockets and should not be used in
  /// production code. For example:
  /// ```dart
  /// final log = File('keylog.txt');
  /// final socket = await SecureSocket.connect('www.example.com', 443,
  ///     keyLog: (line) => log.writeAsStringSync(line, mode: FileMode.append));
  /// ```
  ///
  /// [supportedProtocols] is an optional list of protocols (in decreasing
  /// order of preference) to use during the ALPN protocol negotiation with the
  /// server.  Example values are "http/1.1" or "h2".  The selected protocol
  /// can be obtained via [SecureSocket.selectedProtocol].
  ///
  /// Calling this function will _not_ cause a DNS host lookup. If the
  /// [host] passed is a [String] the [InternetAddress] for the
  /// resulting [SecureSocket] will have this passed in [host] as its
  /// host value and the internet address of the already connected
  /// socket as its address value.
  ///
  /// See [connect] for more information on the arguments.
  static Future<RawSecureSocket> secure(
    RawSocket socket, {
    StreamSubscription<RawSocketEvent>? subscription,
    host,
    SecurityContext? context,
    bool onBadCertificate(X509Certificate certificate)?,
    void keyLog(String line)?,
    List<String>? supportedProtocols,
  }) {
    socket.readEventsEnabled = false;
    socket.writeEventsEnabled = false;
    return _RawSecureSocket.connect(
      host != null ? host : socket.address.host,
      socket.port,
      false,
      socket,
      subscription: subscription,
      context: context,
      onBadCertificate: onBadCertificate,
      keyLog: keyLog,
      supportedProtocols: supportedProtocols,
    );
  }

  /// Initiates TLS on an existing server connection.
  ///
  /// Takes an already connected [socket] and starts server side TLS
  /// handshake to make the communication secure. When the returned
  /// future completes the [RawSecureSocket] has completed the TLS
  /// handshake. Using this function requires that the other end of the
  /// connection is going to start the TLS handshake.
  ///
  /// If the [socket] already has a subscription, pass the existing
  /// subscription in the [subscription] parameter. The [secureServer]
  /// operation will take over the subscription by replacing the
  /// handlers with it own secure processing. The caller must not touch
  /// this subscription anymore. Passing a paused subscription is an
  /// error.
  ///
  /// If some of the data of the TLS handshake has already been read
  /// from the socket this data can be passed in the [bufferedData]
  /// parameter. This data will be processed before any other data
  /// available on the socket.
  ///
  /// See [RawSecureServerSocket.bind] for more information on the
  /// arguments.
  static Future<RawSecureSocket> secureServer(
    RawSocket socket,
    SecurityContext? context, {
    StreamSubscription<RawSocketEvent>? subscription,
    List<int>? bufferedData,
    bool requestClientCertificate = false,
    bool requireClientCertificate = false,
    List<String>? supportedProtocols,
  }) {
    socket.readEventsEnabled = false;
    socket.writeEventsEnabled = false;
    return _RawSecureSocket.connect(
      socket.address,
      socket.remotePort,
      true,
      socket,
      context: context,
      subscription: subscription,
      bufferedData: bufferedData,
      requestClientCertificate: requestClientCertificate,
      requireClientCertificate: requireClientCertificate,
      supportedProtocols: supportedProtocols,
    );
  }

  /// Does nothing.
  ///
  /// The original intent was to allow TLS renegotiation of existing secure
  /// connections.
  @Deprecated("Not implemented")
  void renegotiate({
    bool useSessionCache = true,
    bool requestClientCertificate = false,
    bool requireClientCertificate = false,
  });

  /// Get the peer certificate for a connected RawSecureSocket.  If this
  /// RawSecureSocket is the server end of a secure socket connection,
  /// [peerCertificate] will return the client certificate, or null, if no
  /// client certificate was received.  If it is the client end,
  /// [peerCertificate] will return the server's certificate.
  X509Certificate? get peerCertificate;

  /// The protocol which was selected during protocol negotiation.
  ///
  /// Returns null if one of the peers does not have support for ALPN, did not
  /// specify a list of supported ALPN protocols or there was no common
  /// protocol between client and server.
  String? get selectedProtocol;
}

/// X509Certificate represents an SSL certificate, with accessors to
/// get the fields of the certificate.
@pragma("vm:entry-point")
abstract interface class X509Certificate {
  @pragma("vm:entry-point")
  external factory X509Certificate._();

  /// The DER encoded bytes of the certificate.
  Uint8List get der;

  /// The PEM encoded String of the certificate.
  String get pem;

  /// The SHA1 hash of the certificate.
  Uint8List get sha1;

  String get subject;
  String get issuer;
  DateTime get startValidity;
  DateTime get endValidity;
}

class _FilterStatus {
  bool progress = false; // The filter made buffer or transport progress.
  bool readEmpty = true; // The plaintext and prefetched input are empty.
  bool writeEmpty = true; // The plaintext and TLS transport are empty.
  // These are set if a buffer changes state from empty or full.
  bool readPlaintextNoLongerEmpty = false;
  bool writePlaintextNoLongerFull = false;
  bool wantsWrite = false;
  bool hasPendingSocketWrite = false;
  bool hasPendingPlaintext = false;

  _FilterStatus();
}

class _DartRawSocketTransport {
  final RawSocket socket;
  bool _readClosed = false;
  bool writePending = false;

  _DartRawSocketTransport(this.socket);

  Uint8List? read(int length) => _readClosed ? null : socket.read(length);

  void closeRead() => _readClosed = true;

  int write(Uint8List data) {
    final written = socket.write(data);
    if (Platform.isWindows && written > 0) writePending = true;
    return written;
  }
}

// Interface used by [RawSecureServerSocket] and [_RawSecureSocket] that exposes
// members of [_NativeSocket].
abstract interface class _RawSocketBase {
  bool get _closedReadEventSent;
  Object? get _nativeSocket;
  void _syncNativeSocketState(bool wantsWrite, bool hasPendingWrite);
  void _recordNativeSocketIO(int readBytes, int writeBytes);
  void set _owner(owner);
}

class _RawSecureSocket extends Stream<RawSocketEvent>
    implements RawSecureSocket, _RawSocketBase {
  // Status states
  static const int handshakeStatus = 201;
  static const int connectedStatus = 202;
  static const int closedStatus = 203;

  // BoringSSL SSL_ERROR_* values returned by _SecureFilter.handshake.
  static const int sslErrorWantWrite = 3;
  static const int sslErrorWantCertificateVerify = 16;

  // Buffer identifiers.
  // These must agree with those in the native C++ implementation.
  static const int readPlaintextId = 0;
  static const int writePlaintextId = 1;
  static const int bufferCount = 2;

  final RawSocket _socket;
  late final _RawSocketBase? _rawSocketBase;
  late final Object? _nativeTransport;
  late final _DartRawSocketTransport? _dartTransport;
  final Completer<_RawSecureSocket> _handshakeComplete =
      Completer<_RawSecureSocket>();
  final _controller = StreamController<RawSocketEvent>(sync: true);
  late final StreamSubscription<RawSocketEvent> _socketSubscription;
  List<int>? _bufferedData;
  int _bufferedDataIndex = 0;
  final InternetAddress address;
  final bool isServer;
  final SecurityContext context;
  final bool requestClientCertificate;
  final bool requireClientCertificate;
  final bool Function(X509Certificate certificate)? onBadCertificate;
  final void Function(String line)? keyLog;
  ReceivePort? keyLogPort;

  var _status = handshakeStatus;
  bool _writeEventsEnabled = true;
  bool _readEventsEnabled = true;
  int _pauseCount = 0;
  bool _pendingReadEvent = false;
  bool _pendingWriteEvent = false;
  bool _socketClosedRead = false; // The network socket is closed for reading.
  bool _socketClosedWrite = false; // The network socket is closed for writing.
  bool _closedRead = false; // The secure socket has fired an onClosed event.
  bool _closedWrite = false; // The secure socket has been closed for writing.
  // The network socket is gone.
  Completer<RawSecureSocket> _closeCompleter = Completer<RawSecureSocket>();
  _FilterStatus _filterStatus = _FilterStatus();
  bool _connectPending = true;
  bool _filterPending = false;
  bool _filterActive = false;
  bool _handshakePending = false;
  bool _handshakeActive = false;
  Completer<void>? _handshakeRun;
  bool _hasNativePrefetchedData = false;
  bool _secureFilterConnected = false;

  _SecureFilter? _secureFilter = _SecureFilter._();
  String? _selectedProtocol;

  static Future<_RawSecureSocket> connect(
    dynamic /*String|InternetAddress*/ host,
    int requestedPort,
    bool isServer,
    RawSocket socket, {
    SecurityContext? context,
    StreamSubscription<RawSocketEvent>? subscription,
    List<int>? bufferedData,
    bool requestClientCertificate = false,
    bool requireClientCertificate = false,
    bool onBadCertificate(X509Certificate certificate)?,
    void keyLog(String line)?,
    List<String>? supportedProtocols,
  }) {
    _verifyFields(
      host,
      requestedPort,
      requestClientCertificate,
      requireClientCertificate,
    );
    if (host is InternetAddress) host = host.host;
    InternetAddress address = socket.address;
    if (host != null) {
      address = InternetAddress._cloneWithNewHost(address, host);
    }
    return _RawSecureSocket(
      address,
      requestedPort,
      isServer,
      context ?? SecurityContext.defaultContext,
      socket,
      subscription,
      bufferedData,
      requestClientCertificate,
      requireClientCertificate,
      onBadCertificate,
      keyLog,
      supportedProtocols,
    )._handshakeComplete.future;
  }

  _RawSecureSocket(
    this.address,
    int requestedPort,
    this.isServer,
    this.context,
    this._socket,
    StreamSubscription<RawSocketEvent>? subscription,
    this._bufferedData,
    this.requestClientCertificate,
    this.requireClientCertificate,
    this.onBadCertificate,
    this.keyLog,
    List<String>? supportedProtocols,
  ) {
    _rawSocketBase = _socket is _RawSocketBase
        ? _socket as _RawSocketBase
        : null;
    _nativeTransport = _rawSocketBase?._nativeSocket;
    _dartTransport = _nativeTransport == null
        ? _DartRawSocketTransport(_socket)
        : null;
    _controller
      ..onListen = _onSubscriptionStateChange
      ..onPause = _onPauseStateChange
      ..onResume = _onPauseStateChange
      ..onCancel = _onSubscriptionStateChange;
    // Throw an ArgumentError if any field is invalid.  After this, all
    // errors will be reported through the future or the stream.
    final secureFilter = _secureFilter!;
    secureFilter.init();
    secureFilter.registerHandshakeCompleteCallback(
      _secureHandshakeCompleteHandler,
    );

    if (keyLog != null) {
      final port = ReceivePort();
      port.listen((line) {
        try {
          keyLog!((line as String) + '\n');
        } catch (e, s) {
          // There is no obvious place to surface exceptions from the keyLog
          // callback so write the details to stderr.
          stderr.writeln("Failure in keyLog callback:");
          stderr.writeln(s);
        }
      });
      secureFilter.registerKeyLogPort(port.sendPort);
      keyLogPort = port;
    }

    if (onBadCertificate != null) {
      secureFilter.registerBadCertificateCallback(_onBadCertificateWrapper);
    }
    _socket.readEventsEnabled = true;
    _socket.writeEventsEnabled = false;
    var closedReadEventSent = false;
    if (subscription == null) {
      // If a current subscription is provided use this otherwise
      // create a new one.
      _socketSubscription = _socket.listen(
        _eventDispatcher,
        onError: _reportError,
        onDone: _doneHandler,
      );
    } else {
      _socketSubscription = subscription;
      if (_socketSubscription.isPaused) {
        _socket.close();
        throw ArgumentError("Subscription passed to TLS upgrade is paused");
      }
      closedReadEventSent = _closedReadEventSent;
      _socketSubscription
        ..onData(_eventDispatcher)
        ..onError(_reportError)
        ..onDone(_doneHandler);
    }
    try {
      var encodedProtocols = SecurityContext._protocolsToLengthEncoding(
        supportedProtocols,
      );
      secureFilter.connect(
        address.host,
        context,
        isServer,
        requestClientCertificate || requireClientCertificate,
        requireClientCertificate,
        encodedProtocols,
        _nativeTransport,
        _dartTransport?.read,
        _dartTransport?.write,
      );
      _secureFilterConnected = true;
      if (closedReadEventSent) {
        _markSocketClosedRead();
      }
      if (_socketClosedRead) {
        if (_bufferedData == null || _bufferedData!.isEmpty) {
          _reportError(
            HandshakeException('Connection terminated during handshake'),
            null,
          );
        } else {
          _closeHandler();
        }
      } else {
        _secureHandshake();
      }
    } catch (e, s) {
      _reportError(e, s);
    }
  }

  StreamSubscription<RawSocketEvent> listen(
    void onData(RawSocketEvent data)?, {
    Function? onError,
    void onDone()?,
    bool? cancelOnError,
  }) {
    _sendWriteEvent();
    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  static void _verifyFields(
    host,
    int requestedPort,
    bool requestClientCertificate,
    bool requireClientCertificate,
  ) {
    if (host is! String && host is! InternetAddress) {
      throw ArgumentError("host is not a String or an InternetAddress");
    }
    if (requestedPort < 0 || requestedPort > 65535) {
      throw ArgumentError("requestedPort is not in the range 0..65535");
    }
  }

  int get port => _socket.port;

  InternetAddress get remoteAddress => _socket.remoteAddress;

  int get remotePort => _socket.remotePort;

  static _RawSocketBase? _extractRawSocketBase(RawSocket socket) {
    if (socket is _RawSocketBase) return socket as _RawSocketBase;
    try {
      final dynamic dynamicSocket = socket;
      final dynamic target = dynamicSocket.socket;
      if (target is RawSocket) {
        return _extractRawSocketBase(target as RawSocket);
      }
    } catch (_) {}
    return null;
  }

  bool get _closedReadEventSent {
    if (_closedRead || _socketClosedRead) return true;
    final base = _rawSocketBase ?? _extractRawSocketBase(_socket);
    if (base != null) return base._closedReadEventSent;
    try {
      final dynamic dynamicSocket = _socket;
      final dynamic closed = dynamicSocket._closedReadEventSent;
      if (closed is bool) return closed;
    } catch (_) {}
    return false;
  }

  // A RawSecureSocket is itself a public RawSocket transport. Returning null
  // keeps a second TLS layer on top of this one instead of bypassing it and
  // attaching the inner BIO to the original native socket.
  Object? get _nativeSocket => null;

  void _syncNativeSocketState(bool wantsWrite, bool hasPendingWrite) {
    // This implementation is exposed as a non-native transport to another
    // SecureSocket. Its own native transport is synchronized below.
  }

  void _recordNativeSocketIO(int readBytes, int writeBytes) {
    // A TLS layer using this object as a transport calls its public read/write
    // methods, so the innermost native transport records the bytes once.
  }

  void _syncNativeTransportState(bool wantsWrite, bool hasPendingWrite) {
    if (_nativeTransport == null) return;
    _rawSocketBase!._syncNativeSocketState(wantsWrite, hasPendingWrite);
  }

  void _recordNativeTransportIO(int readBytes, int writeBytes) {
    if (_nativeTransport == null) return;
    _rawSocketBase!._recordNativeSocketIO(readBytes, writeBytes);
  }

  void _markSocketClosedRead() {
    _socketClosedRead = true;
    _dartTransport?.closeRead();
  }

  void set _owner(owner) {
    _rawSocketBase?._owner = owner;
  }

  int available() {
    return _status != connectedStatus
        ? 0
        : _secureFilter!.buffers![readPlaintextId].length;
  }

  Future<RawSecureSocket> close() {
    shutdown(SocketDirection.both);
    return _closeCompleter.future;
  }

  void _completeCloseCompleter([RawSocket? dummy]) {
    if (!_closeCompleter.isCompleted) _closeCompleter.complete(this);
  }

  void _destroyFilterIfInactive() {
    if (_status != closedStatus ||
        _filterActive ||
        _handshakeActive ||
        _secureFilter == null) {
      return;
    }
    _secureFilter!.destroy();
    _secureFilter = null;
  }

  void _close() {
    if (_status == closedStatus) {
      _destroyFilterIfInactive();
      return;
    }
    _status = closedStatus;
    _closedWrite = true;
    _closedRead = true;
    _socket.close().then(_completeCloseCompleter);
    _socketClosedWrite = true;
    _markSocketClosedRead();
    _destroyFilterIfInactive();
    keyLogPort?.close();
    if (_socketSubscription != null) {
      _socketSubscription.cancel();
    }
    _controller.close();
  }

  void shutdown(SocketDirection direction) {
    if (direction == SocketDirection.send ||
        direction == SocketDirection.both) {
      _closedWrite = true;
      if (_filterStatus.writeEmpty) {
        _socket.shutdown(SocketDirection.send);
        _socketClosedWrite = true;
        if (_closedRead) {
          _close();
        }
      }
    }
    if (direction == SocketDirection.receive ||
        direction == SocketDirection.both) {
      _closedRead = true;
      _markSocketClosedRead();
      _socket.shutdown(SocketDirection.receive);
      if (_socketClosedWrite) {
        _close();
      }
    }
  }

  bool get writeEventsEnabled => _writeEventsEnabled;

  void set writeEventsEnabled(bool value) {
    _writeEventsEnabled = value;
    if (value) {
      _scheduleWriteEvent();
    }
  }

  bool get readEventsEnabled => _readEventsEnabled;

  void set readEventsEnabled(bool value) {
    _readEventsEnabled = value;
    _socket.readEventsEnabled =
        value &&
        _secureFilter != null &&
        _secureFilter!.buffers![readPlaintextId].free > 0;
    _scheduleReadEvent();
  }

  Uint8List? read([int? length]) {
    if (length != null && length < 0) {
      throw ArgumentError(
        "Invalid length parameter in SecureSocket.read (length: $length)",
      );
    }
    if (_closedRead) {
      throw SocketException("Reading from a closed socket");
    }
    if (_status != connectedStatus) {
      return null;
    }
    // A public RawSocket implementation is invoked synchronously by the
    // custom BIO. It may reenter this socket before the native filter call has
    // returned. Keep the positions and backing allocation passed to native
    // code immutable for the duration of that call.
    if (_filterActive) return null;
    final buffer = _secureFilter!.buffers![readPlaintextId];
    var result = buffer.read(length);
    if (_socketClosedRead && buffer.isEmpty) {
      scheduleMicrotask(_scheduleFilter);
    } else {
      _scheduleFilter();
    }
    return result;
  }

  SocketMessage? readMessage([int? count]) {
    throw UnsupportedError("Message-passing not supported by secure sockets");
  }

  // Write the data to the socket, and schedule the filter to encrypt it.
  int write(List<int> data, [int offset = 0, int? bytes]) {
    if (bytes != null && bytes < 0) {
      throw ArgumentError(
        "Invalid bytes parameter in SecureSocket.read (bytes: $bytes)",
      );
    }
    if (offset < 0) {
      throw ArgumentError(
        "Invalid offset parameter in SecureSocket.read (offset: $offset)",
      );
    }
    if (_closedWrite) {
      // A filter error closes the controller before an already scheduled
      // write event can be delivered. Do not replace the original TLS error
      // with StateError from adding to that closed controller.
      if (!_controller.isClosed) {
        _controller.addError(SocketException("Writing to a closed socket"));
      }
      return 0;
    }
    if (_status != connectedStatus) return 0;
    // Treat a write reentered from a custom BIO transport callback as
    // backpressure. Growing or otherwise mutating this ring while SSL_write is
    // using its current generation would invalidate native pointers and ring
    // positions.
    if (_filterActive) return 0;
    bytes ??= data.length - offset;

    int written = _secureFilter!.buffers![writePlaintextId].write(
      data,
      offset,
      bytes,
    );
    if (written > 0) {
      _filterStatus.writeEmpty = false;
    }
    _scheduleFilter();
    return written;
  }

  int sendMessage(
    List<SocketControlMessage> controlMessages,
    List<int> data, [
    int offset = 0,
    int? count,
  ]) {
    throw UnsupportedError("Message-passing not supported by secure sockets");
  }

  X509Certificate? get peerCertificate => _secureFilter!.peerCertificate;

  String? get selectedProtocol => _selectedProtocol;

  bool _onBadCertificateWrapper(X509Certificate certificate) {
    if (onBadCertificate == null) return false;
    return onBadCertificate!(certificate);
  }

  bool setOption(SocketOption option, bool enabled) {
    return _socket.setOption(option, enabled);
  }

  Uint8List getRawOption(RawSocketOption option) {
    return _socket.getRawOption(option);
  }

  void setRawOption(RawSocketOption option) {
    _socket.setRawOption(option);
  }

  void _eventDispatcher(RawSocketEvent event) {
    try {
      if (event == RawSocketEvent.read) {
        _readHandler();
      } else if (event == RawSocketEvent.write) {
        _writeHandler();
      } else if (event == RawSocketEvent.readClosed) {
        _closeHandler();
      }
    } catch (e, stackTrace) {
      _reportError(e, stackTrace);
    }
  }

  void _readHandler() {
    if (_status == handshakeStatus) {
      _secureHandshake();
    } else {
      _scheduleFilter();
    }
  }

  void _writeHandler() {
    final dartTransport = _dartTransport;
    if (dartTransport != null) dartTransport.writePending = false;
    if (_status == handshakeStatus) {
      _secureHandshake();
    } else {
      _scheduleFilter();
    }
  }

  void _doneHandler() {
    if (_filterStatus.readEmpty) {
      _close();
    }
  }

  void _reportError(e, [StackTrace? stackTrace]) {
    if (_status == closedStatus) {
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

  void _closeHandler() async {
    if (_status == connectedStatus) {
      if (_closedRead) return;
      _markSocketClosedRead();
      _socket.readEventsEnabled = false;
      await _scheduleFilter();
      _scheduleReadEvent();
    } else if (_status == handshakeStatus) {
      _markSocketClosedRead();
      if (!_secureFilterConnected) return;
      // Drain bytes delivered with the close event before declaring the
      // handshake truncated.
      await _secureHandshake();
      if (_status == handshakeStatus &&
          _bufferedData == null &&
          !_hasNativePrefetchedData) {
        _reportError(
          HandshakeException('Connection terminated during handshake'),
          null,
        );
      }
    }
  }

  void _finishClosedRead() {
    if (_status != connectedStatus || _closedRead || !_socketClosedRead) return;
    _closedRead = true;
    _filterStatus.readEmpty = true;
    _controller.add(RawSocketEvent.readClosed);
    if (_socketClosedWrite) {
      _close();
    }
  }

  Future<void> _secureHandshake() async {
    _handshakePending = true;
    if (_handshakeActive) {
      await _handshakeRun!.future;
      return;
    }
    _handshakeActive = true;
    final run = Completer<void>();
    _handshakeRun = run;
    try {
      while (_status == handshakeStatus &&
          _secureFilter != null &&
          _handshakePending) {
        _handshakePending = false;
        _queuePrefetchedData();
        final result = await _secureFilter!.handshake();
        final error = result[0] as int;
        final hasPrefetchedData = result[1] as bool;
        final hasPendingWrite =
            result[2] as bool || (_dartTransport?.writePending ?? false);
        final readBytes = result[3] as int;
        final writeBytes = result[4] as int;
        _recordNativeTransportIO(readBytes, writeBytes);
        _hasNativePrefetchedData = hasPrefetchedData;
        _syncNativeTransportState(error == sslErrorWantWrite, hasPendingWrite);
        if (!hasPendingWrite && (readBytes > 0 || writeBytes > 0)) {
          // A positive partial socket operation is progress, but it is not
          // guaranteed to produce another transport event. Retry until the
          // BIO actually blocks.
          _handshakePending = true;
        }
        if (error == sslErrorWantCertificateVerify) {
          // Certificate evaluation completed while awaiting handshake().
          _handshakePending = true;
          continue;
        }
        if (!hasPrefetchedData && _bufferedData != null) {
          // A bounded prefetched chunk was consumed. Queue the next one before
          // waiting for another socket event.
          _handshakePending = true;
          continue;
        }
        if (_status == connectedStatus) {
          _socket.writeEventsEnabled = false;
          await _scheduleFilter();
        } else {
          _socket.readEventsEnabled = true;
          _socket.writeEventsEnabled =
              error == sslErrorWantWrite || hasPendingWrite;
        }
        if (_handshakePending) continue;
        break;
      }
    } catch (e, stackTrace) {
      _reportError(e, stackTrace);
    } finally {
      _handshakeActive = false;
      _handshakeRun = null;
      try {
        _destroyFilterIfInactive();
      } finally {
        run.complete();
      }
    }
  }

  @Deprecated("Not implemented")
  void renegotiate({
    bool useSessionCache = true,
    bool requestClientCertificate = false,
    bool requireClientCertificate = false,
  }) {
    if (_status != connectedStatus) {
      throw HandshakeException("Called renegotiate on a non-connected socket");
    }
    _status = handshakeStatus;
    _filterStatus.writeEmpty = false;
    _scheduleFilter();
  }

  void _secureHandshakeCompleteHandler() {
    _status = connectedStatus;
    if (_connectPending) {
      _connectPending = false;
      try {
        _selectedProtocol = _secureFilter!.selectedProtocol();
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

  Future<void> _scheduleFilter() {
    _filterPending = true;
    return _tryFilter();
  }

  Future<void> _tryFilter() async {
    try {
      while (true) {
        if (_status == closedStatus) {
          return;
        }
        if (!_filterPending || _filterActive) {
          return;
        }
        _filterActive = true;
        _filterPending = false;

        try {
          _filterStatus = _pushAllFilterStages();
        } finally {
          _filterActive = false;
        }
        if (_status == closedStatus) {
          _destroyFilterIfInactive();
          return;
        }
        _socket.readEventsEnabled =
            _readEventsEnabled &&
            _secureFilter!.buffers![readPlaintextId].free > 0;
        _socket.writeEventsEnabled =
            _filterStatus.hasPendingSocketWrite ||
            (_filterStatus.wantsWrite &&
                (_secureFilter!.buffers![readPlaintextId].free > 0 ||
                    !_secureFilter!.buffers![writePlaintextId].isEmpty));
        if (_filterStatus.writeEmpty && _closedWrite && !_socketClosedWrite) {
          // Checks for and handles all cases of partially closed sockets.
          shutdown(SocketDirection.send);
          if (_status == closedStatus) {
            return;
          }
        }
        if (_socketClosedRead && !_closedRead && _filterStatus.readEmpty) {
          _finishClosedRead();
        }
        if (_status == closedStatus) {
          return;
        }
        if (_filterStatus.progress) {
          _filterPending = true;
          if (_filterStatus.writePlaintextNoLongerFull) {
            // Do not invoke user code before the current filter turn returns.
            // _filterActive is cleared after the native call, so a synchronous
            // write event here could start a nested filter turn.
            _scheduleWriteEvent();
          }
          if (_filterStatus.readPlaintextNoLongerEmpty) {
            _scheduleReadEvent();
          }
        }
      }
    } catch (e, st) {
      // Preserve RawSecureSocket's asynchronous error delivery and avoid
      // closing the stream reentrantly from write().
      scheduleMicrotask(() => _reportError(e, st));
    } finally {
      // If _close() was invoked while _filterActive was true, the filter
      // destruction was deferred. Ensure the native filter and its socket fd
      // are cleaned up immediately when the filter turn completes.
      _destroyFilterIfInactive();
    }
  }

  bool _queuePrefetchedData() {
    final bufferedData = _bufferedData;
    if (bufferedData == null) return false;
    if (_bufferedDataIndex >= bufferedData.length) {
      _bufferedData = null;
      return false;
    }
    final queued = _secureFilter!.queuePrefetchedData(
      bufferedData,
      _bufferedDataIndex,
    );
    if (queued > 0) {
      _bufferedDataIndex += queued;
      if (bufferedData.length == _bufferedDataIndex) {
        _bufferedData = null;
      }
      return true;
    }
    return false;
  }

  // If a read event should be sent, add it to the controller.
  _scheduleReadEvent() {
    if (!_pendingReadEvent &&
        !_closedRead &&
        _readEventsEnabled &&
        _pauseCount == 0 &&
        _secureFilter != null &&
        !_secureFilter!.buffers![readPlaintextId].isEmpty) {
      _pendingReadEvent = true;
      Timer.run(_sendReadEvent);
    }
  }

  _sendReadEvent() {
    _pendingReadEvent = false;
    if (_status != closedStatus &&
        !_closedRead &&
        _readEventsEnabled &&
        _pauseCount == 0 &&
        _secureFilter != null &&
        !_secureFilter!.buffers![readPlaintextId].isEmpty) {
      _controller.add(RawSocketEvent.read);
      _scheduleReadEvent();
    }
  }

  // If a write event should be sent, add it to the controller.
  void _scheduleWriteEvent() {
    if (_pendingWriteEvent) return;
    _pendingWriteEvent = true;
    Timer.run(() {
      _pendingWriteEvent = false;
      _sendWriteEvent();
    });
  }

  _sendWriteEvent() {
    if (!_closedWrite &&
        _writeEventsEnabled &&
        _pauseCount == 0 &&
        _secureFilter != null &&
        _secureFilter!.buffers![writePlaintextId].free > 0) {
      _writeEventsEnabled = false;
      _controller.add(RawSocketEvent.write);
    }
  }

  _FilterStatus _pushAllFilterStages() {
    final queuedPrefetchedData = _queuePrefetchedData();
    var bufs = _secureFilter!.buffers!;
    final positions = List<int>.filled(bufferCount * 3, 0);
    for (var i = 0; i < bufferCount; ++i) {
      positions[3 * i] = bufs[i].start;
      positions[3 * i + 1] = bufs[i].end;
      positions[3 * i + 2] = bufs[i].size;
    }

    final response = _secureFilter!.process(positions);
    int start(int index) => response[2 * index] as int;
    int end(int index) => response[2 * index + 1] as int;
    final wantsWrite = response[bufferCount * 2] as bool;
    final hasPrefetchedData = response[bufferCount * 2 + 1] as bool;
    final hasPendingWrite =
        response[bufferCount * 2 + 2] as bool ||
        (_dartTransport?.writePending ?? false);
    final readBytes = response[bufferCount * 2 + 3] as int;
    final writeBytes = response[bufferCount * 2 + 4] as int;
    final hasPendingPlaintext = response[bufferCount * 2 + 5] as bool;
    _recordNativeTransportIO(readBytes, writeBytes);
    _hasNativePrefetchedData = hasPrefetchedData;
    _syncNativeTransportState(wantsWrite, hasPendingWrite);

    _FilterStatus status = _FilterStatus();
    status.wantsWrite = wantsWrite;
    status.hasPendingSocketWrite = hasPendingWrite;
    status.hasPendingPlaintext = hasPendingPlaintext;
    status.writeEmpty =
        bufs[writePlaintextId].isEmpty && !wantsWrite && !hasPendingWrite;
    status.readEmpty =
        start(readPlaintextId) == end(readPlaintextId) &&
        _bufferedData == null &&
        !hasPrefetchedData &&
        !hasPendingPlaintext;
    status.progress =
        queuedPrefetchedData ||
        (!hasPrefetchedData && _bufferedData != null) ||
        readBytes > 0 ||
        writeBytes > 0;

    _ExternalBuffer buffer = bufs[writePlaintextId];
    int new_start = start(writePlaintextId);
    if (new_start != buffer.start) {
      status.progress = true;
      if (buffer.free == 0) {
        status.writePlaintextNoLongerFull = true;
      }
      buffer.setStart(new_start);
    }
    buffer = bufs[readPlaintextId];
    int new_end = end(readPlaintextId);
    if (new_end != buffer.end) {
      status.progress = true;
      if (buffer.length == 0) {
        status.readPlaintextNoLongerEmpty = true;
      }
      buffer.setEnd(new_end);
      if (buffer.free == 0 && buffer.grow()) {
        status.progress = true;
      }
    }
    return status;
  }
}

/// A plaintext circular buffer backed by an external byte array. Native TLS
/// processing is serialized on the isolate, and Dart applies the returned
/// start/end positions after each native call.
class _ExternalBuffer {
  // This will be an ExternalByteArray, backed by C allocated data.
  @pragma("vm:entry-point")
  Uint8List? data;

  @pragma("vm:entry-point")
  int start;

  @pragma("vm:entry-point")
  int end;

  final int maxSize;

  @pragma("vm:entry-point")
  int size;

  final Uint8List Function(int start, int end, int oldSize, int newSize)
  _growBacking;

  _ExternalBuffer(
    this.maxSize, {
    required int initialSize,
    required Uint8List Function(int start, int end, int oldSize, int newSize)
    growBacking,
  }) : assert(initialSize >= 2),
       assert(initialSize <= maxSize),
       size = initialSize,
       _growBacking = growBacking,
       start = 0,
       end = 0;

  void _resetIfEmpty() {
    if (start == end) {
      start = 0;
      end = 0;
    }
  }

  void setStart(int value) {
    assert(value >= 0 && value < size);
    start = value;
    _resetIfEmpty();
  }

  void setEnd(int value) {
    assert(value >= 0 && value < size);
    end = value;
  }

  void advanceStart(int bytes) {
    assert(start > end || start + bytes <= end);
    start += bytes;
    if (start >= size) {
      start -= size;
      assert(start <= end);
      assert(start < size);
    }
    _resetIfEmpty();
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

  bool grow([int requiredFree = 1]) {
    if (requiredFree <= free) return false;
    final requiredSize = min(maxSize, length + requiredFree + 1);
    if (requiredSize <= size) return false;

    // Start small for low-traffic connections, then move through a 4 KiB
    // working ring before allocating one maximum-size TLS plaintext record.
    final fourKiB = 4 * 1024 + 1;
    final newSize = size < fourKiB ? fourKiB : maxSize;
    final used = length;
    final newData = _growBacking(start, end, size, newSize);
    if (newData.length != newSize) {
      throw StateError('Invalid SecureSocket backing buffer size');
    }
    data = newData;
    size = newSize;
    start = 0;
    end = used;
    return true;
  }

  Uint8List? read(int? bytes) {
    if (bytes == null) {
      bytes = length;
    } else {
      bytes = min(bytes, length);
    }
    if (bytes == 0) return null;
    Uint8List result = Uint8List(bytes);
    int bytesRead = 0;
    // Loop over zero, one, or two linear data ranges.
    while (bytesRead < bytes) {
      int toRead = min(bytes - bytesRead, linearLength);
      result.setRange(bytesRead, bytesRead + toRead, data!, start);
      advanceStart(toRead);
      bytesRead += toRead;
    }
    return result;
  }

  int write(List<int> inputData, int offset, int bytes) {
    grow(bytes);
    if (bytes > free) {
      bytes = free;
    }
    int written = 0;
    int toWrite = min(bytes, linearFree);
    // Loop over zero, one, or two linear data ranges.
    while (toWrite > 0) {
      data!.setRange(end, end + toWrite, inputData, offset);
      advanceEnd(toWrite);
      offset += toWrite;
      written += toWrite;
      toWrite = min(bytes - written, linearFree);
    }
    return written;
  }
}

abstract class _SecureFilter {
  external factory _SecureFilter._();

  void connect(
    String hostName,
    SecurityContext context,
    bool isServer,
    bool requestClientCertificate,
    bool requireClientCertificate,
    Uint8List protocols,
    Object? nativeSocket,
    Uint8List? Function(int)? transportRead,
    int Function(Uint8List)? transportWrite,
  );
  void destroy();
  Future<List<Object?>> handshake();
  String? selectedProtocol();
  void rehandshake();
  void init();
  X509Certificate? get peerCertificate;
  int processBuffer(int bufferIndex);
  List<Object?> process(List<int> positions);
  int queuePrefetchedData(List<int> data, int offset);
  void registerBadCertificateCallback(bool Function(X509Certificate) callback);
  void registerHandshakeCompleteCallback(Function handshakeCompleteHandler);
  void registerKeyLogPort(SendPort port);

  List<_ExternalBuffer>? get buffers;
}

/// A secure networking exception caused by a failure in the
/// TLS/SSL protocol.
@pragma("vm:entry-point")
class TlsException implements IOException {
  final String type;
  final String message;
  final OSError? osError;

  @pragma("vm:entry-point")
  const TlsException([String message = "", OSError? osError])
    : this._("TlsException", message, osError);

  const TlsException._(this.type, this.message, this.osError);

  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write(type);
    if (message.isNotEmpty) {
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

/// An exception that happens in the handshake phase of establishing
/// a secure network connection.
@pragma("vm:entry-point")
class HandshakeException extends TlsException {
  @pragma("vm:entry-point")
  const HandshakeException([String message = "", OSError? osError])
    : super._("HandshakeException", message, osError);
}

/// An exception that happens in the handshake phase of establishing
/// a secure network connection, when looking up or verifying a
/// certificate.
class CertificateException extends TlsException {
  @pragma("vm:entry-point")
  const CertificateException([String message = "", OSError? osError])
    : super._("CertificateException", message, osError);
}
