// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class ServerSocket {
  /**
   * Constructs a new server socket, binds it to a given address and port,
   * and listens on it.
   */
  factory ServerSocket(String bindAddress, int port, int backlog) {
    return new _ServerSocket(bindAddress, port, backlog);
  }

  /**
   * The connection handler gets called when there is a new incoming
   * connection on the socket.
   */
  void set onConnection(void callback(Socket connection));

  /**
   * The error handler gets called when a socket error occurs.
   */
  void set onError(void callback(e));

  /**
   * Returns the port used by this socket.
   */
  int get port;

  /**
   * Closes the socket.
   */
  void close();
}


abstract class Socket implements Hashable {
  /**
   * Constructs a new socket and initiate connecting it to the given
   * host on the given port. The returned socket is not yet connected
   * but ready for registration of callbacks.
   */
  factory Socket(String host, int port) => new _Socket(host, port);

  /**
   * Returns the number of received and non-read bytes in the socket that
   * can be read.
   */
  int available();

  /**
   * Reads up to [count] bytes of data from the socket and stores them into
   * buffer after buffer offset [offset]. The number of successfully read
   * bytes is returned. This function is non-blocking and will only read data
   * if data is available.
   */
  int readList(List<int> buffer, int offset, int count);

  /**
   * Writes up to [count] bytes of the buffer from [offset] buffer offset to
   * the socket. The number of successfully written bytes is returned. This
   * function is non-blocking and will only write data if buffer space is
   * available in the socket.
   */
  int writeList(List<int> buffer, int offset, int count);

  /**
   * The connect handler gets called when connection to a given host
   * succeeded.
   */
  void set onConnect(void callback());

  /**
   * The data handler gets called when data becomes available at the socket.
   */
  void set onData(void callback());

  /**
   * The write handler gets called once when the socket becomes
   * available for writing. Then the handler is automatically reset to null.
   * This handler is mainly used when writeList has reported an incomplete
   * write, to schedule writing the remaining data to the socket.
   */
  void set onWrite(void callback());

  /**
   * The close handler gets called when a the last byte have been read
   * from a socket. At this point the socket might still be open for
   * writing for sending more data.
   */
  void set onClosed(void callback());

  /**
   * The error handler gets called when a socket error occurs.
   */
  void set onError(void callback(e));

  /**
   * Returns input stream to the socket.
   */
  InputStream get inputStream;

  /**
   * Returns output stream of the socket.
   */
  OutputStream get outputStream;

  /**
   * Returns the port used by this socket.
   */
  int get port;

  /**
   * Returns the remote port connected to by this socket.
   */
  int get remotePort;

  /**
   * Returns the remote host connected to by this socket.
   */
  String get remoteHost;

  /**
   * Closes the socket. Calling [close] will never throw an exception
   * and calling it several times is supported. If [halfClose] is true
   * the socket will only be closed for writing and it might still be
   * possible to read data. Calling [close] will not trigger a call to
   * [onClosed].
   */
  void close([bool halfClose = false]);

  /**
   * Socket is hashable.
   */
  int hashCode();
}


class SocketIOException implements Exception {
  const SocketIOException([String this.message = "",
                           OSError this.osError = null]);
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.add("SocketIOException");
    if (!message.isEmpty()) {
      sb.add(": $message");
      if (osError != null) {
        sb.add(" ($osError)");
      }
    } else if (osError != null) {
      sb.add(": $osError");
    }
    return sb.toString();
  }
  final String message;
  final OSError osError;
}
