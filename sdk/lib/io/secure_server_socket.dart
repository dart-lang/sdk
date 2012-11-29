// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart_io;

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
   */
  factory SecureServerSocket(String bindAddress,
                          int port,
                          int backlog,
                          String certificate_name) =>
      new _SecureServerSocket(bindAddress, port, backlog, certificate_name);
}


class _SecureServerSocket implements SecureServerSocket {

  _SecureServerSocket(String bindAddress,
                   int port,
                   int backlog,
                   String certificate_name) {
    _socket = new ServerSocket(bindAddress, port, backlog);
    _socket.onConnection = this._onConnectionHandler;
    _certificate_name = certificate_name;
  }

  void set onConnection(void callback(Socket connection)) {
    _onConnectionCallback = callback;
  }

  void set onError(void callback(e)) {
    _socket.onError = callback;
  }

  /**
   * Returns the port used by this socket.
   */
  int get port => _socket.port;

  /**
   * Closes the socket.
   */
  void close() {
    _socket.close();
  }

  void _onConnectionHandler(Socket connection) {
    if (_onConnectionCallback == null) {
      connection.close();
      throw new SocketIOException(
          "SecureServerSocket with no onConnection callback connected to");
    }
    if (_certificate_name == null) {
      connection.close();
      throw new SocketIOException(
          "SecureServerSocket with server certificate not set connected to");
    }
    var secure_connection = new _SecureSocket.server(connection.remoteHost,
                                                  connection.remotePort,
                                                  connection,
                                                  _certificate_name);
    _onConnectionCallback(secure_connection);
  }

  ServerSocket _socket;
  var _onConnectionCallback;
  String _certificate_name;
}
