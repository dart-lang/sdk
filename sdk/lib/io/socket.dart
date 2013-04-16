// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * The RawServerSocket is a server socket, providing a stream of low-level
 * [RawSocket]s.
 *
 * See [RawSocket] for more info.
 */
abstract class RawServerSocket implements Stream<RawSocket> {
  /**
   * Returns a future for a [:RawServerSocket:]. When the future
   * completes the server socket is bound to the given [address] and
   * [port] and has started listening on it.
   *
   * The default value for [address] is 127.0.0.1, which will allow
   * only incoming connections from the local host. To allow for
   * incoming connection from the network use either the value 0.0.0.0
   * to bind to all interfaces or the IP address of a specific
   * interface.
   *
   * If [port] has the value [:0:] (the default) an ephemeral port will
   * be chosen by the system. The actual port used can be retrieved
   * using the [:port:] getter.
   *
   * The optional argument [backlog] can be used to specify the listen
   * backlog for the underlying OS listen setup. If [backlog] has the
   * value of [:0:] (the default) a reasonable value will be chosen by
   * the system.
   */
  external static Future<RawServerSocket> bind([String address = "127.0.0.1",
                                               int port = 0,
                                               int backlog = 0]);

  /**
   * Returns the port used by this socket.
   */
  int get port;

  /**
   * Closes the socket.
   */
  void close();
}


/**
 * The [ServerSocket] is server socket, providing a stream of high-level
 * [Socket]s.
 *
 * See [Socket] for more info.
 */
abstract class ServerSocket implements Stream<Socket> {
  /**
   * Returns a future for a [:ServerSocket:]. When the future
   * completes the server socket is bound to the given [address] and
   * [port] and has started listening on it.
   *
   * The default value for [address] is 127.0.0.1, which will allow
   * only incoming connections from the local host. To allow for
   * incoming connection from the network use either the value 0.0.0.0
   * to bind to all interfaces or the IP address of a specific
   * interface.
   *
   * If [port] has the value [:0:] (the default) an ephemeral port will
   * be chosen by the system. The actual port used can be retrieved
   * using the [port] getter.
   *
   * The optional argument [backlog] can be used to specify the listen
   * backlog for the underlying OS listen setup. If [backlog] has the
   * value of [:0:] (the default) a reasonable value will be chosen by
   * the system.
   */
  external static Future<ServerSocket> bind([String address = "127.0.0.1",
                                             int port = 0,
                                             int backlog = 0]);

  /**
   * Returns the port used by this socket.
   */
  int get port;

  /**
   * Closes the socket.
   */
  void close();
}

/**
 * The [SocketDirection] is used as a parameter to [Socket.close] and
 * [RawSocket.close] to close a socket in the specified direction(s).
 */
class SocketDirection {
  static const SocketDirection RECEIVE = const SocketDirection._(0);
  static const SocketDirection SEND = const SocketDirection._(1);
  static const SocketDirection BOTH = const SocketDirection._(2);
  const SocketDirection._(this._value);
  final _value;
}

/**
 * The [SocketOption] is used as a parameter to [Socket.setOption] and
 * [RawSocket.setOption] to set customize the behaviour of the underlying
 * socket.
 */
class SocketOption {
  /**
   * Enable or disable no-delay on the socket. If TCP_NODELAY is enabled, the
   * socket will not buffer data internally, but instead write each data chunk
   * as an invidual TCP packet.
   *
   * TCP_NODELAY is disabled by default.
   */
  static const SocketOption TCP_NODELAY = const SocketOption._(0);
  const SocketOption._(this._value);
  final _value;
}

/**
 * Events for the [RawSocket].
 */
class RawSocketEvent {
  static const RawSocketEvent READ = const RawSocketEvent._(0);
  static const RawSocketEvent WRITE = const RawSocketEvent._(1);
  static const RawSocketEvent READ_CLOSED = const RawSocketEvent._(2);
  const RawSocketEvent._(this._value);
  final int _value;
  String toString() {
    return ['RawSocketEvent:READ',
            'RawSocketEvent:WRITE',
            'RawSocketEvent:READ_CLOSED'][_value];
  }
}

/**
 * The [RawSocket] is a low-level interface to a socket, exposing the raw
 * events signaled by the system. It's a [Stream] of [RawSocketEvent]s.
 */
abstract class RawSocket implements Stream<RawSocketEvent> {
  /**
   * Creates a new socket connection to the host and port and returns a [Future]
   * that will complete with either a [RawSocket] once connected or an error
   * if the host-lookup or connection failed.
   */
  external static Future<RawSocket> connect(String host, int port);

  /**
   * Returns the number of received and non-read bytes in the socket that
   * can be read.
   */
  int available();

  /**
   * Read up to [len] bytes from the socket. This function is
   * non-blocking and will only return data if data is available. The
   * number of bytes read can be less then [len] if fewer bytes are
   * available for immediate reading. If no data is available [null]
   * is returned.
   */
  List<int> read([int len]);

  /**
   * Writes up to [count] bytes of the buffer from [offset] buffer offset to
   * the socket. The number of successfully written bytes is returned. This
   * function is non-blocking and will only write data if buffer space is
   * available in the socket.
   */
  int write(List<int> buffer, [int offset, int count]);

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
   * and calling it several times is supported. Calling [close] can result in
   * a [RawSocketEvent.READ_CLOSED] event.
   */
  void close();

  /**
   * Shutdown the socket in the [direction]. Calling [shutdown] will never
   * throw an exception and calling it several times is supported. Calling
   * shutdown with either [SocketDirection.BOTH] or [SocketDirection.RECEIVE]
   * can result in a [RawSocketEvent.READ_CLOSED] event.
   */
  void shutdown(SocketDirection direction);

  /**
   * Set or get, if the [RawSocket] should listen for [RawSocketEvent.READ]
   * events. Default is [true].
   */
  bool readEventsEnabled;

  /**
   * Set or get, if the [RawSocket] should listen for [RawSocketEvent.WRITE]
   * events. Default is [true].
   * This is a one-shot listener, and writeEventsEnabled must be set
   * to true again to receive another write event.
   */
  bool writeEventsEnabled;

  /**
   * Use [setOption] to customize the [RawSocket]. See [SocketOption] for
   * available options.
   *
   * Returns [true] if the option was set successfully, false otherwise.
   */
  bool setOption(SocketOption option, bool enabled);
}

/**
 * A high-level class for communicating over a TCP socket. The [Socket] exposes
 * both a [Stream] and a [IOSink] interface, making it ideal for
 * using together with other [Stream]s.
 */
abstract class Socket implements Stream<List<int>>, IOSink {
  /**
   * Creats a new socket connection to the host and port and returns a [Future]
   * that will complete with either a [Socket] once connected or an error
   * if the host-lookup or connection failed.
   */
  external static Future<Socket> connect(String host, int port);

  /**
   * Destroy the socket in both directions. Calling [destroy] will make the
   * send a close event on the stream and will no longer react on data being
   * piped to it.
   *
   * Call [close](inherited from [IOSink]) to only close the [Socket]
   * for sending data.
   */
  void destroy();

  /**
   * Use [setOption] to customize the [RawSocket]. See [SocketOption] for
   * available options.
   *
   * Returns [true] if the option was set successfully, false otherwise.
   */
  bool setOption(SocketOption option, bool enabled);

  int get port;
  String get remoteHost;
  int get remotePort;
}


class SocketIOException implements Exception {
  const SocketIOException([String this.message = "",
                           OSError this.osError = null]);
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("SocketIOException");
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
  final String message;
  final OSError osError;
}
