// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

abstract class SecureServerSocket implements ServerSocket {
  /**
   * Constructs a new secure server socket, binds it to a given address
   * and port, and listens on it.  Incoming client connections are
   * promoted to secure connections, using the server certificate given by
   * certificate_name.  The bindAddress must be given as a numeric address,
   * not a host name.  The certificate name is the distinguished name (DN) of
   * the certificate, such as "CN=localhost" or "CN=myserver.mydomain.com".
   * The certificate is looked up in the NSS certificate database set by
   * SecureSocket.setCertificateDatabase.
   *
   * To request or require that clients authenticate by providing an SSL (TLS)
   * client certificate, set the optional parameters requestClientCertificate or
   * requireClientCertificate to true.  Require implies request, so one doesn't
   * need to specify both.  To check whether a client certificate was received,
   * check SecureSocket.peerCertificate after connecting.  If no certificate
   * was received, the result will be null.
   */
  factory SecureServerSocket(String bindAddress,
                             int port,
                             int backlog,
                             String certificate_name,
                             {bool requestClientCertificate: false,
                              bool requireClientCertificate: false}) {
    return new _SecureServerSocket(bindAddress,
                                   port,
                                   backlog,
                                   certificate_name,
                                   requestClientCertificate,
                                   requireClientCertificate);
  }
}


class _SecureServerSocket implements SecureServerSocket {

  _SecureServerSocket(String bindAddress,
                      int port,
                      int backlog,
                      String this.certificate_name,
                      bool this.requestClientCertificate,
                      bool this.requireClientCertificate) {
    socket = new ServerSocket(bindAddress, port, backlog);
    socket.onConnection = this._onConnectionHandler;
  }

  void set onConnection(void callback(Socket connection)) {
    _onConnectionCallback = callback;
  }

  void set onError(void callback(e)) {
    socket.onError = callback;
  }

  /**
   * Returns the port used by this socket.
   */
  int get port => socket.port;

  /**
   * Closes the socket.
   */
  void close() {
    socket.close();
  }

  void _onConnectionHandler(Socket connection) {
    if (_onConnectionCallback == null) {
      connection.close();
      throw new SocketIOException(
          "SecureServerSocket with no onConnection callback connected to");
    }
    if (certificate_name == null) {
      connection.close();
      throw new SocketIOException(
          "SecureServerSocket with server certificate not set connected to");
    }
    var secure_connection = new _SecureSocket(
        connection.remoteHost,
        connection.remotePort,
        certificate_name,
        is_server: true,
        socket: connection,
        requestClientCertificate: requestClientCertificate,
        requireClientCertificate: requireClientCertificate);
    _onConnectionCallback(secure_connection);
  }

  ServerSocket socket;
  var _onConnectionCallback;
  final String certificate_name;
  final bool requestClientCertificate;
  final bool requireClientCertificate;
}
