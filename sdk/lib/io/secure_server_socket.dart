// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * The [SecureServerSocket] is a server socket, providing a stream of high-level
 * [Socket]s.
 *
 * See [SecureSocket] for more info.
 */
class SecureServerSocket extends Stream<SecureSocket> {
  final RawSecureServerSocket _socket;

  SecureServerSocket._(this._socket);

  /**
   * Returns a future for a [SecureServerSocket]. When the future
   * completes the server socket is bound to the given [address] and
   * [port] and has started listening on it.
   *
   * The [address] can either be a [String] or an
   * [InternetAddress]. If [address] is a [String], [bind] will
   * perform a [InternetAddress.lookup] and use the first value in the
   * list. To listen on the loopback adapter, which will allow only
   * incoming connections from the local host, use the value
   * [InternetAddress.LOOPBACK_IP_V4] or
   * [InternetAddress.LOOPBACK_IP_V6]. To allow for incoming
   * connection from the network use either one of the values
   * [InternetAddress.ANY_IP_V4] or [InternetAddress.ANY_IP_V6] to
   * bind to all interfaces or the IP address of a specific interface.
   *
   * If [port] has the value [:0:] an ephemeral port will be chosen by
   * the system. The actual port used can be retrieved using the
   * [port] getter.
   *
   * The optional argument [backlog] can be used to specify the listen
   * backlog for the underlying OS listen setup. If [backlog] has the
   * value of [:0:] (the default) a reasonable value will be chosen by
   * the system.
   *
   * Incoming client connections are promoted to secure connections, using
   * the server certificate given by [certificateName].
   *
   * [address] must be given as a numeric address, not a host name.
   *
   * [certificateName] is the nickname or the distinguished name (DN) of
   * the certificate in the certificate database. It is looked up in the
   * NSS certificate database set by SecureSocket.setCertificateDatabase.
   * If [certificateName] contains "CN=", it is assumed to be a distinguished
   * name.  Otherwise, it is looked up as a nickname.
   *
   * To request or require that clients authenticate by providing an SSL (TLS)
   * client certificate, set the optional parameter [requestClientCertificate]
   * or [requireClientCertificate] to true.  Requiring a certificate implies
   * requesting a certificate, so one doesn't need to set both to true.
   * To check whether a client certificate was received, check
   * SecureSocket.peerCertificate after connecting.  If no certificate
   * was received, the result will be null.
   */
  static Future<SecureServerSocket> bind(
      address,
      int port,
      String certificateName,
      {int backlog: 0,
       bool v6Only: false,
       bool requestClientCertificate: false,
       bool requireClientCertificate: false}) {
    return RawSecureServerSocket.bind(
        address,
        port,
        certificateName,
        backlog: backlog,
        v6Only: v6Only,
        requestClientCertificate: requestClientCertificate,
        requireClientCertificate: requireClientCertificate).then(
            (serverSocket) => new SecureServerSocket._(serverSocket));
  }

  StreamSubscription<SecureSocket> listen(void onData(SecureSocket socket),
                                          {Function onError,
                                           void onDone(),
                                           bool cancelOnError}) {
    return _socket.map((rawSocket) => new SecureSocket._(rawSocket))
                  .listen(onData,
                          onError: onError,
                          onDone: onDone,
                          cancelOnError: cancelOnError);
  }

  /**
   * Returns the port used by this socket.
   */
  int get port => _socket.port;

  /**
   * Returns the address used by this socket.
   */
  InternetAddress get address => _socket.address;

  /**
   * Closes the socket. The returned future completes when the socket
   * is fully closed and is no longer bound.
   */
  Future<SecureServerSocket> close() => _socket.close().then((_) => this);
}


/**
 * The RawSecureServerSocket is a server socket, providing a stream of low-level
 * [RawSecureSocket]s.
 *
 * See [RawSecureSocket] for more info.
 */
class RawSecureServerSocket extends Stream<RawSecureSocket> {
  RawServerSocket _socket;
  StreamController<RawSecureSocket> _controller;
  StreamSubscription<RawSocket> _subscription;
  final String certificateName;
  final bool requestClientCertificate;
  final bool requireClientCertificate;
  bool _closed = false;

  RawSecureServerSocket._(RawServerSocket serverSocket,
                          this.certificateName,
                          this.requestClientCertificate,
                          this.requireClientCertificate) {
    _socket = serverSocket;
    _controller = new StreamController<RawSecureSocket>(
        sync: true,
        onListen: _onSubscriptionStateChange,
        onPause: _onPauseStateChange,
        onResume: _onPauseStateChange,
        onCancel: _onSubscriptionStateChange);
  }

  /**
   * Returns a future for a [RawSecureServerSocket]. When the future
   * completes the server socket is bound to the given [address] and
   * [port] and has started listening on it.
   *
   * The [address] can either be a [String] or an
   * [InternetAddress]. If [address] is a [String], [bind] will
   * perform a [InternetAddress.lookup] and use the first value in the
   * list. To listen on the loopback adapter, which will allow only
   * incoming connections from the local host, use the value
   * [InternetAddress.LOOPBACK_IP_V4] or
   * [InternetAddress.LOOPBACK_IP_V6]. To allow for incoming
   * connection from the network use either one of the values
   * [InternetAddress.ANY_IP_V4] or [InternetAddress.ANY_IP_V6] to
   * bind to all interfaces or the IP address of a specific interface.
   *
   * If [port] has the value [:0:] an ephemeral port will be chosen by
   * the system. The actual port used can be retrieved using the
   * [port] getter.
   *
   * The optional argument [backlog] can be used to specify the listen
   * backlog for the underlying OS listen setup. If [backlog] has the
   * value of [:0:] (the default) a reasonable value will be chosen by
   * the system.
   *
   * Incoming client connections are promoted to secure connections,
   * using the server certificate given by [certificateName].
   *
   * [address] must be given as a numeric address, not a host name.
   *
   * [certificateName] is the nickname or the distinguished name (DN) of
   * the certificate in the certificate database. It is looked up in the
   * NSS certificate database set by SecureSocket.setCertificateDatabase.
   * If [certificateName] contains "CN=", it is assumed to be a distinguished
   * name.  Otherwise, it is looked up as a nickname.
   *
   * To request or require that clients authenticate by providing an SSL (TLS)
   * client certificate, set the optional parameters requestClientCertificate or
   * requireClientCertificate to true.  Require implies request, so one doesn't
   * need to specify both.  To check whether a client certificate was received,
   * check SecureSocket.peerCertificate after connecting.  If no certificate
   * was received, the result will be null.
   */
  static Future<RawSecureServerSocket> bind(
      address,
      int port,
      String certificateName,
      {int backlog: 0,
       bool v6Only: false,
       bool requestClientCertificate: false,
       bool requireClientCertificate: false}) {
    return RawServerSocket.bind(address, port, backlog: backlog, v6Only: v6Only)
        .then((serverSocket) => new RawSecureServerSocket._(
            serverSocket,
            certificateName,
            requestClientCertificate,
            requireClientCertificate));
  }

  StreamSubscription<RawSecureSocket> listen(void onData(RawSecureSocket s),
                                             {Function onError,
                                              void onDone(),
                                              bool cancelOnError}) {
    return _controller.stream.listen(onData,
                                     onError: onError,
                                     onDone: onDone,
                                     cancelOnError: cancelOnError);
  }

  /**
   * Returns the port used by this socket.
   */
  int get port => _socket.port;

  /**
   * Returns the address used by this socket.
   */
  InternetAddress get address => _socket.address;

  /**
   * Closes the socket. The returned future completes when the socket
   * is fully closed and is no longer bound.
   */
  Future<RawSecureServerSocket> close() {
    _closed = true;
    return _socket.close().then((_) => this);
  }

  void _onData(RawSocket connection) {
    var remotePort;
    try {
      remotePort = connection.remotePort;
    } catch (e) {
      // If connection is already closed, remotePort throws an exception.
      // Do nothing - connection is closed.
      return;
    }
    _RawSecureSocket.connect(
        connection.address,
        remotePort,
        certificateName,
        is_server: true,
        socket: connection,
        requestClientCertificate: requestClientCertificate,
        requireClientCertificate: requireClientCertificate)
    .then((RawSecureSocket secureConnection) {
      if (_closed) {
        secureConnection.close();
      } else {
        _controller.add(secureConnection);
      }
    }).catchError((e) {
      if (!_closed) {
        _controller.addError(e);
      }
    });
  }

  void _onError(e, [StackTrace stackTrace]) {
    _controller.addError(e, stackTrace);
  }

  void _onDone() {
    _controller.close();
  }

  void _onPauseStateChange() {
    if (_controller.isPaused) {
      _subscription.pause();
    } else {
      _subscription.resume();
    }
  }

  void _onSubscriptionStateChange() {
    if (_controller.hasListener) {
      _subscription = _socket.listen(_onData,
                                     onDone: _onDone,
                                     onError: _onError);
    } else {
      close();
    }
  }
}


