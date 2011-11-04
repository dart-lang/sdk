// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface ServerSocket factory _ServerSocket {
  /*
   * Constructs a new server socket, binds it to a given address and port,
   * and listens on it.
   */
  ServerSocket(String bindAddress, int port, int backlog);

  /*
   * Accepts a connection to this socket.
   */
  Socket accept();

  /*
   * The connection handler gets executed when there are incoming connections
   * on the socket.
   */
  void set connectionHandler(void callback());

  /*
   * The error handler gets executed when a socket error occurs.
   */
  void set errorHandler(void callback());

  /*
   * Returns the port used by this socket.
   */
  int get port();

  /*
   * Closes the socket.
   */
  void close();
}


interface Socket factory _Socket {
  /*
   * Constructs a new socket and connects it to the given host on the given
   * port.
   */
  Socket(String host, int port);

  /*
   * Returns the number of received and non-read bytes in the socket that
   * can be read.
   */
  int available();

  /*
   * Reads up to [count] bytes of data from the socket and stores them into
   * buffer after buffer offset [offset]. The number of successfully read
   * bytes is returned. This function is non-blocking and will only read data
   * if data is available.
   */
  int readList(List<int> buffer, int offset, int count);

  /*
   * Writes up to [count] bytes of the buffer from [offset] buffer offset to
   * the socket. The number of successfully written bytes is returned. This
   * function is non-blocking and will only write data if buffer space is
   * available in the socket. It will return 0 if an error occurs, e.g., no
   * buffer space available.
   */
  int writeList(List<int> buffer, int offset, int count);

  /*
   * The connect handler gets called when connection to a given host
   * succeeded.
   */
  void set connectHandler(void callback());

  /*
   * The data handler gets called when data becomes available at the socket.
   */
  void set dataHandler(void callback());

  /*
   * The write handler gets called when the socket becomes available for
   * writing.
   */
  void set writeHandler(void callback());

  /*
   * The close handler gets called when a the last byte have been read
   * from a socket. At this point the socket might still be open for
   * writing for sending more data.
   */
  void set closeHandler(void callback());

  /*
   * The error handler gets called when a socket error occurs.
   */
  void set errorHandler(void callback());

  /*
   * Returns input stream to the socket.
   */
  InputStream get inputStream();

  /*
   * Returns output stream of the socket.
   */
  OutputStream get outputStream();

  /*
   * Returns the port used by this socket.
   */
  int get port();

  /*
   * Closes the socket. Calling [close] will never throw an exception
   * and calling it several times is supported. If [halfClose] is true
   * the socket will only be closed for writing and it might still be
   * possible to read data. Calling [close] will not trigger a call to
   * the [closeHandler].
   */
  void close([bool halfClose]);
}


class SocketIOException implements Exception {
  const SocketIOException([String this.message = ""]);
  String toString() => "SocketIOException: $message";

  /*
   * Contains the exception message.
   */
  final String message;
}
