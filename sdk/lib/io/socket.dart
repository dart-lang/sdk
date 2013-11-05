// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;


/**
 * [InternetAddressType] is the type an [InternetAddress]. Currently,
 * IP version 4 (IPv4) and IP version 6 (IPv6) are supported.
 */
class InternetAddressType {
  static const InternetAddressType IP_V4 = const InternetAddressType._(0);
  static const InternetAddressType IP_V6 = const InternetAddressType._(1);
  static const InternetAddressType ANY = const InternetAddressType._(-1);

  final int _value;

  const InternetAddressType._(int this._value);

  factory InternetAddressType._from(int value) {
    if (value == 0) return IP_V4;
    if (value == 1) return IP_V6;
    throw new ArgumentError("Invalid type: $value");
  }

  /**
   * Get the name of the type, e.g. "IP_V4" or "IP_V6".
   */
  String get name {
    switch (_value) {
      case -1: return "ANY";
      case 0: return "IP_V4";
      case 1: return "IP_V6";
      default: throw new ArgumentError("Invalid InternetAddress");
    }
  }

  String toString() => "InternetAddressType: $name";
}


/**
 * The [InternetAddress] is an object reflecting either a remote or a
 * local address. When combined with a port number, this represents a
 * endpoint that a socket can connect to or a listening socket can
 * bind to.
 */
abstract class InternetAddress {
  /**
   * IP version 4 loopback address. Use this address when listening on
   * or connecting to the loopback adapter using IP version 4 (IPv4).
   */
  external static InternetAddress get LOOPBACK_IP_V4;

  /**
   * IP version 6 loopback address. Use this address when listening on
   * or connecting to the loopback adapter using IP version 6 (IPv6).
   */
  external static InternetAddress get LOOPBACK_IP_V6;

  /**
   * IP version 4 any address. Use this address when listening on
   * all adapters IP addresses using IP version 4 (IPv4).
   */
  external static InternetAddress get ANY_IP_V4;

  /**
   * IP version 6 any address. Use this address when listening on
   * all adapters IP addresses using IP version 6 (IPv6).
   */
  external static InternetAddress get ANY_IP_V6;

  /**
   * The [type] of the [InternetAddress] specified what IP protocol.
   */
  InternetAddressType type;

  /**
   * The resolved address of the host.
   */
  String get address;

  /**
   * The host used to lookup the address.
   */
  String get host;

  /**
   * Returns true if the [InternetAddress] is a loopback address.
   */
  bool get isLoopback;

  /**
   * Returns true if the [InternetAddress]s scope is a link-local.
   */
  bool get isLinkLocal;

  /**
   * Perform a reverse dns lookup on the [address], creating a new
   * [InternetAddress] where the host field set to the result.
   */
  Future<InternetAddress> reverse();

  /**
   * Lookup a host, returning a Future of a list of
   * [InternetAddress]s. If [type] is [InternetAddressType.ANY], it
   * will lookup both IP version 4 (IPv4) and IP version 6 (IPv6)
   * addresses. If [type] is either [InternetAddressType.IP_V4] or
   * [InternetAddressType.IP_V6] it will only lookup addresses of the
   * specified type. The order of the list can, and most likely will,
   * change over time.
   */
  external static Future<List<InternetAddress>> lookup(
      String host, {InternetAddressType type: InternetAddressType.ANY});
}


/**
 * A [NetworkInterface] represent an active network interface on the current
 * system. It contains a list of [InternetAddress]s, that's bound to the
 * interface.
 */
abstract class NetworkInterface {
  /**
   * Get the name of the [NetworkInterface].
   */
  String get name;

  /**
   * Get a list of [InternetAddress]s currently bound to this
   * [NetworkInterface].
   */
  List<InternetAddress> get addresses;

  /**
   * Query the system for [NetworkInterface]s.
   *
   * If [includeLoopback] is `true`, the returned list will include the
   * loopback device. Default is `false`.
   *
   * If [includeLinkLocal] is `true`, the list of addresses of the returned
   * [NetworkInterface]s, may include link local addresses. Default is `false`.
   *
   * If [type] is either [InternetAddressType.IP_V4] or
   * [InternetAddressType.IP_V6] it will only lookup addresses of the
   * specified type. Default is [InternetAddressType.ANY].
   */
  external static Future<List<NetworkInterface>> list({
      bool includeLoopback: false,
      bool includeLinkLocal: false,
      InternetAddressType type: InternetAddressType.ANY});
}


/**
 * A [RawServerSocket] represents a listening socket, and provides a
 * stream of low-level [RawSocket] objects, one for each connection
 * made to the listening socket.
 *
 * See [RawSocket] for more info.
 */
abstract class RawServerSocket implements Stream<RawSocket> {
  /**
   * Returns a future for a [:RawServerSocket:]. When the future
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
   * If an IP version 6 (IPv6) address is used, both IP version 6
   * (IPv6) and version 4 (IPv4) connections will be accepted. To
   * restrict this to version 6 (IPv6) only, use [v6Only] to set
   * version 6 only.
   *
   * If [port] has the value [:0:] an ephemeral port will
   * be chosen by the system. The actual port used can be retrieved
   * using the [:port:] getter.
   *
   * The optional argument [backlog] can be used to specify the listen
   * backlog for the underlying OS listen setup. If [backlog] has the
   * value of [:0:] (the default) a reasonable value will be chosen by
   * the system.
   */
  external static Future<RawServerSocket> bind(address,
                                               int port,
                                               {int backlog: 0,
                                                bool v6Only: false});

  /**
   * Returns the port used by this socket.
   */
  int get port;

  /**
   * Returns the address used by this socket.
   */
  InternetAddress get address;

  /**
   * Closes the socket. The returned future completes when the socket
   * is fully closed and is no longer bound.
   */
  Future<RawServerSocket> close();
}


/**
 * A [ServerSocket] represents a listening socket, and provides a
 * stream of [Socket] objects, one for each connection made to the
 * listening socket.
 *
 * See [Socket] for more info.
 */
abstract class ServerSocket implements Stream<Socket> {
  /**
   * Returns a future for a [:ServerSocket:]. When the future
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
   * If an IP version 6 (IPv6) address is used, both IP version 6
   * (IPv6) and version 4 (IPv4) connections will be accepted. To
   * restrict this to version 6 (IPv6) only, use [v6Only] to set
   * version 6 only.
   *
   * If [port] has the value [:0:] an ephemeral port will be chosen by
   * the system. The actual port used can be retrieved using the
   * [port] getter.
   *
   * The optional argument [backlog] can be used to specify the listen
   * backlog for the underlying OS listen setup. If [backlog] has the
   * value of [:0:] (the default) a reasonable value will be chosen by
   * the system.
   */
  external static Future<ServerSocket> bind(address,
                                            int port,
                                            {int backlog: 0,
                                             bool v6Only: false});

  /**
   * Returns the port used by this socket.
   */
  int get port;

  /**
   * Returns the address used by this socket.
   */
  InternetAddress get address;

  /**
   * Closes the socket. The returned future completes when the socket
   * is fully closed and is no longer bound.
   */
  Future<ServerSocket> close();
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
  static const RawSocketEvent CLOSED = const RawSocketEvent._(3);
  const RawSocketEvent._(this._value);
  final int _value;
  String toString() {
    return ['RawSocketEvent:READ',
            'RawSocketEvent:WRITE',
            'RawSocketEvent:READ_CLOSED',
            'RawSocketEvent:CLOSED'][_value];
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
   *
   * [host] can either be a [String] or an [InternetAddress]. If [host] is a
   * [String], [connect] will perform a [InternetAddress.lookup] and use
   * the first value in the list.
   */
  external static Future<RawSocket> connect(host, int port);

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
   *
   * The default value for [offset] is 0, and the default value for [count] is
   * [:buffer.length - offset:].
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
   * Returns the [InternetAddress] used to connect this socket.
   */
  InternetAddress get address;

  /**
   * Returns the remote [InternetAddress] connected to by this socket.
   */
  InternetAddress get remoteAddress;

  /**
   * Closes the socket. Returns a Future that completes with [this] when the
   * underlying connection is completely destroyed.
   *
   * Calling [close] will never throw an exception
   * and calling it several times is supported. Calling [close] can result in
   * a [RawSocketEvent.READ_CLOSED] event.
   */
  Future<RawSocket> close();

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
 * A high-level class for communicating over a TCP socket.
 *
 * The [Socket] exposes both a [Stream] and a [IOSink] interface, making it
 * ideal for using together with other [Stream]s.
 */
abstract class Socket implements Stream<List<int>>, IOSink {
  /**
   * Creats a new socket connection to the host and port and returns a [Future]
   * that will complete with either a [Socket] once connected or an error
   * if the host-lookup or connection failed.
   *
   * [host] can either be a [String] or an [InternetAddress]. If [host] is a
   * [String], [connect] will perform a [InternetAddress.lookup] and use
   * the first value in the list.
   */
  external static Future<Socket> connect(host, int port);

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

  /**
   * Returns the port used by this socket.
   */
  int get port;

  /**
   * Returns the remote port connected to by this socket.
   */
  int get remotePort;

  /**
   * Returns the [InternetAddress] used to connect this socket.
   */
  InternetAddress get address;

  /**
   * Returns the remote [InternetAddress] connected to by this socket.
   */
  InternetAddress get remoteAddress;
}


class SocketException implements IOException {
  final String message;
  final OSError osError;
  final InternetAddress address;
  final int port;

  const SocketException(String this.message,
                        {OSError this.osError,
                         InternetAddress this.address,
                         int this.port});

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("SocketException");
    if (!message.isEmpty) {
      sb.write(": $message");
      if (osError != null) {
        sb.write(" ($osError)");
      }
    } else if (osError != null) {
      sb.write(": $osError");
    }
    if (address != null) {
      if (address.host.isNotEmpty) {
        sb.write(", address = ${address.host}");
      } else {
        sb.write(", address = ${address.address}");
      }
    }
    if (port != null) {
      sb.write(", port = $port");
    }
    return sb.toString();
  }
}
