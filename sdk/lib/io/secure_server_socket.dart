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
class SecureServerSocket extends Stream<SecureSocket> implements ServerSocket {
  final RawSecureServerSocket _socket;

  SecureServerSocket._(RawSecureServerSocket this._socket);

  /**
   * Returns a future for a [SecureServerSocket]. When the future
   * completes the server socket is bound to the given [address] and
   * [port] and has started listening on it.
   *
   * If [port] has the value [:0:] (the default) an ephemeral port will
   * be chosen by the system. The actual port used can be retrieved
   * using the [port] getter.
   *
   * If [backlog] has the value of [:0:] a reasonable value will be
   * chosen by the system.
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
      String address,
      int port,
      int backlog,
      String certificateName,
      {bool requestClientCertificate: false,
       bool requireClientCertificate: false}) {
    return RawSecureServerSocket.bind(
        address,
        port,
        backlog,
        certificateName,
        requestClientCertificate: requestClientCertificate,
        requireClientCertificate: requireClientCertificate).then(
            (serverSocket) => new SecureServerSocket._(serverSocket));
  }

  StreamSubscription<SecureSocket> listen(void onData(SecureSocket socket),
                                          {void onError(error),
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
   * Closes the socket.
   */
  void close() => _socket.close();
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
                          String this.certificateName,
                          bool this.requestClientCertificate,
                          bool this.requireClientCertificate) {
    _socket = serverSocket;
    _controller = new StreamController<RawSecureSocket>(
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
   * If [port] has the value [:0:] (the default) an ephemeral port will
   * be chosen by the system. The actual port used can be retrieved
   * using the [port] getter.
   *
   * If [backlog] has the value of [:0:] a reasonable value will be
   * chosen by the system.
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
      String address,
      int port,
      int backlog,
      String certificateName,
      {bool requestClientCertificate: false,
       bool requireClientCertificate: false}) {
    return RawServerSocket.bind(address, port, backlog)
        .then((serverSocket) => new RawSecureServerSocket._(
            serverSocket,
            certificateName,
            requestClientCertificate,
            requireClientCertificate));
  }

  StreamSubscription<RawSecureSocket> listen(void onData(RawSecureSocket s),
                                             {void onError(error),
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
   * Closes the socket.
   */
  void close() {
    _closed = true;
    _socket.close();
  }

  void _onData(RawSocket connection) {
    _RawSecureSocket.connect(
        connection.remoteHost,
        connection.remotePort,
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
      if (_closed) {
        throw e;
      } else {
        _controller.addError(e);
        close();
      }
    });
  }

  void _onError(e) {
    _controller.addError(e);
    close();
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


