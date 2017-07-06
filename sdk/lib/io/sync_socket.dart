// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "io.dart";

/**
 * A low-level class for communicating synchronously over a TCP socket.
 *
 * Warning: [RawSynchronousSocket] should probably only be used to connect to
 * 'localhost'. The operations below will block the calling thread to wait for
 * a response from the network. The thread can process no other events while
 * waiting for these operations to complete. [RawSynchronousSocket] is not
 * suitable for applications that require high performance or asynchronous I/O
 * such as a server. Instead such applications should use the non-blocking
 * sockets and asynchronous operations in the Socket or RawSocket classes.
 */
abstract class RawSynchronousSocket {
  /**
   * Creates a new socket connection and returns a [RawSynchronousSocket].
   *
   * [host] can either be a [String] or an [InternetAddress]. If [host] is a
   * [String], [connectSync] will perform a [InternetAddress.lookup] and try
   * all returned [InternetAddress]es, until connected. Unless a
   * connection was established, the error from the first failing connection is
   * returned.
   */
  external static RawSynchronousSocket connectSync(host, int port);

  /**
   * Returns the number of received and unread bytes in the socket that can be
   * read.
   */
  int available();

  /**
   * Closes the [RawSynchronousSocket].
   *
   * Once [closeSync] has been called, attempting to call [readSync],
   * [readIntoSync], [writeFromSync], [remoteAddress], and [remotePort] will
   * cause a [SocketException] to be thrown.
   */
  void closeSync();

  /**
   * Reads into an existing [List<int>] from the socket into the range:
   * [[start],[end]).
   *
   * Reads into an existing [List<int>] from the socket. If [start] is present,
   * the bytes will be filled into [buffer] from index [start], otherwise index
   * 0. If [end] is present, [end] - [start] bytes will be read into [buffer],
   * otherwise up to [buffer.length]. If [end] == [start], no bytes are read.
   * Returns the number of bytes read.
   */
  int readIntoSync(List<int> buffer, [int start = 0, int end]);

  /**
   * Reads up to [bytes] bytes from the socket.
   *
   * Blocks and waits for a response of up to a specified number of bytes
   * sent by the socket. [bytes] specifies the maximum number of bytes to
   * be read. Returns the list of bytes read, which could be less than the
   * value specified by [bytes].
   */
  List<int> readSync(int bytes);

  /**
   * Shutdown a socket in the provided direction.
   *
   * Calling shutdown will never throw an exception and calling it several times
   * is supported. If both [SocketDirection.RECEIVE] and [SocketDirection.SEND]
   * directions are closed, the socket is closed completely, the same as if
   * [closeSync] has been called.
   */
  void shutdown(SocketDirection direction);

  /**
   * Writes data from a specified range in a [List<int>] to the socket.
   *
   * Writes into the socket from a [List<int>]. If [start] is present, the bytes
   * will be written to the socket starting from index [start]. If [start] is
   * not present, the bytes will be written starting from index 0. If [end] is
   * present, the [end] - [start] bytes will be written into the socket starting
   * at index [start]. If [end] is not provided, [buffer.length] elements will
   * be written to the socket starting from index [start]. If [end] == [start],
   * nothing happens.
   */
  void writeFromSync(List<int> buffer, [int start = 0, int end]);

  /**
   * The port used by this socket.
   */
  int get port;

  /**
   * The remote port connected to by this socket.
   */
  int get remotePort;

  /**
   * The [InternetAddress] used to connect this socket.
   */
  InternetAddress get address;

  /**
   * The remote [InternetAddress] connected to by this socket.
   */
  InternetAddress get remoteAddress;
}
