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

  const InternetAddressType._(this._value);

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
 * An internet address.
 *
 * This object holds an internet address. If this internet address
 * is the result of a DNS lookup, the address also holds the hostname
 * used to make the lookup.
 * An Internet address combined with a port number represents an
 * endpoint to which a socket can connect or a listening socket can
 * bind.
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
   * The numeric address of the host. For IPv4 addresses this is using
   * the dotted-decimal notation. For IPv6 it is using the
   * hexadecimal representation.
   */
  String get address;

  /**
   * The host used to lookup the address. If there is no host
   * associated with the address this returns the numeric address.
   */
  String get host;

  /**
   * Get the raw address of this [InternetAddress]. The result is either a
   * 4 or 16 byte long list. The returned list is a copy, making it possible
   * to change the list without modifying the [InternetAddress].
   */
  List<int> get rawAddress;

  /**
   * Returns true if the [InternetAddress] is a loopback address.
   */
  bool get isLoopback;

  /**
   * Returns true if the [InternetAddress]s scope is a link-local.
   */
  bool get isLinkLocal;

  /**
   * Returns true if the [InternetAddress]s scope is multicast.
   */
  bool get isMulticast;

  /**
   * Creates a new [InternetAddress] from a numeric address.
   *
   * If the address in [address] is not a numeric IPv4
   * (dotted-decimal notation) or IPv6 (hexadecimal representation).
   * address [ArgumentError] is thrown.
   */
  external factory InternetAddress(String address);

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
   * Get the index of the [NetworkInterface].
   */
  String get index;

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

  /**
   * Get the [RawServerSocketReference].
   *
   * WARNING: This feature is *highly experimental* and currently only works on
   * Linux. The API is most likely going to change in the near future.
   *
   * The returned [RawServerSocketReference] can be used to create other
   * [RawServerSocket]s listening on the same port,
   * using [RawServerSocketReference.create].
   * Incoming connections on the port will be distributed fairly between the
   * active server sockets.
   * The [RawServerSocketReference] can be distributed to other isolates through
   * a [RawSendPort].
   */
  RawServerSocketReference get reference;
}


/**
 * A [RawServerSocketReference].
 *
 * WARNING: This class is used with [RawServerSocket.reference] which is highly
 * experimental.
 */
abstract class RawServerSocketReference {
  /**
   * Create a new [RawServerSocket], from this reference.
   */
  Future<RawServerSocket> create();
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

  /**
   * Get the [ServerSocketReference].
   *
   * WARNING: This feature is *highly experimental* and currently only works on
   * Linux. The API is most likely going to change in the near future.
   *
   * The returned [ServerSocketReference] can be used to create other
   * [ServerSocket]s listening on the same port,
   * using [ServerSocketReference.create].
   * Incoming connections on the port will be distributed fairly between the
   * active server sockets.
   * The [ServerSocketReference] can be distributed to other isolates through a
   * [SendPort].
   */
  ServerSocketReference get reference;
}


/**
 * A [ServerSocketReference].
 *
 * WARNING: This class is used with [ServerSocket.reference] which is highly
 * experimental.
 */
abstract class ServerSocketReference {
  /**
   * Create a new [ServerSocket], from this reference.
   */
  Future<ServerSocket> create();
}


/**
 * The [SocketDirection] is used as a parameter to [Socket.close] and
 * [RawSocket.close] to close a socket in the specified direction(s).
 */
class SocketDirection {
  static const SocketDirection RECEIVE = const SocketDirection._(0);
  static const SocketDirection SEND = const SocketDirection._(1);
  static const SocketDirection BOTH = const SocketDirection._(2);
  final _value;

  const SocketDirection._(this._value);
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

  static const SocketOption _IP_MULTICAST_LOOP = const SocketOption._(1);
  static const SocketOption _IP_MULTICAST_HOPS = const SocketOption._(2);
  static const SocketOption _IP_MULTICAST_IF = const SocketOption._(3);
  static const SocketOption _IP_BROADCAST = const SocketOption._(4);
  final _value;

  const SocketOption._(this._value);
}

/**
 * Events for the [RawSocket].
 */
class RawSocketEvent {
  static const RawSocketEvent READ = const RawSocketEvent._(0);
  static const RawSocketEvent WRITE = const RawSocketEvent._(1);
  static const RawSocketEvent READ_CLOSED = const RawSocketEvent._(2);
  static const RawSocketEvent CLOSED = const RawSocketEvent._(3);
  final int _value;

  const RawSocketEvent._(this._value);
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
   * Set or get, if the [RawSocket] should listen for [RawSocketEvent.READ]
   * events. Default is [:true:].
   */
  bool readEventsEnabled;

  /**
   * Set or get, if the [RawSocket] should listen for [RawSocketEvent.WRITE]
   * events. Default is [:true:].
   * This is a one-shot listener, and writeEventsEnabled must be set
   * to true again to receive another write event.
   */
  bool writeEventsEnabled;

  /**
   * Creates a new socket connection to the host and port and returns a [Future]
   * that will complete with either a [RawSocket] once connected or an error
   * if the host-lookup or connection failed.
   *
   * [host] can either be a [String] or an [InternetAddress]. If [host] is a
   * [String], [connect] will perform a [InternetAddress.lookup] and try
   * all returned [InternetAddress]es, in turn, until connected. Unless a
   * connection was established, the error from the first attempt is
   * returned.
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
   * available for immediate reading. If no data is available [:null:]
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
   * Use [setOption] to customize the [RawSocket]. See [SocketOption] for
   * available options.
   *
   * Returns [:true:] if the option was set successfully, false otherwise.
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
   * [String], [connect] will perform a [InternetAddress.lookup] and try
   * all returned [InternetAddress]es, in turn, until connected. Unless a
   * connection was established, the error from the first attempt is
   * returned.
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
   * Returns [:true:] if the option was set successfully, false otherwise.
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


/**
 * Datagram package. Data send to and received from datagram sockets
 * contains the internet address and port of the destination or source
 * togeter with the data.
 */
class Datagram {
  List<int> data;
  InternetAddress address;
  int port;

  Datagram(this.data, this.address, this.port);
}


/**
 * The [RawDatagramSocket] is a low-level interface to an UDP socket,
 * exposing the raw events signaled by the system. It's a [Stream] of
 * [RawSocketEvent]s.
 *
 * Note that the event [RawSocketEvent.READ_CLOSED] will never be
 * received as an UDP socket cannot be closed by a remote peer.
 */
abstract class RawDatagramSocket extends Stream<RawSocketEvent> {
  /**
   * Set or get, if the [RawDatagramSocket] should listen for
   * [RawSocketEvent.READ] events. Default is [:true:].
   */
  bool readEventsEnabled;

  /**
   * Set or get, if the [RawDatagramSocket] should listen for
   * [RawSocketEvent.WRITE] events. Default is [:true:].  This is a
   * one-shot listener, and writeEventsEnabled must be set to true
   * again to receive another write event.
   */
  bool writeEventsEnabled;

  /**
   * Set or get, whether multicast traffic is looped back to the host.
   *
   * By default multicast loopback is enabled.
   */
  bool multicastLoopback;

  /**
   * Set or get, the maximum network hops for multicast packages
   * originating from this socket.
   *
   * For IPv4 this is referred to as TTL (time to live).
   *
   * By default this value is 1 causing multicast traffic to stay on
   * the local network.
   */
  int multicastHops;

  /**
   * Set or get, the network interface used for outgoing multicast packages.
   *
   * A value of `null`indicate that the system chooses the network
   * interface to use.
   *
   * By default this value is `null`
   */
  NetworkInterface multicastInterface;

  /**
   * Set or get, whether IPv4 broadcast is enabled.
   *
   * IPv4 broadcast needs to be enabled by the sender for sending IPv4
   * broadcast packages. By default IPv4 broadcast is disabled.
   *
   * For IPv6 there is no general broadcast mechanism. Use multicast
   * instead.
   */
  bool broadcastEnabled;

  /**
   * Creates a new raw datagram socket binding it to an address and
   * port.
   */
  external static Future<RawDatagramSocket> bind(
      host, int port, {bool reuseAddress: true});

  /**
   * Returns the port used by this socket.
   */
  int get port;

  /**
   * Returns the address used by this socket.
   */
  InternetAddress get address;

  /**
   * Close the datagram socket.
   */
  void close();

  /**
   * Send a datagram.
   *
   * Returns the number of bytes written. This will always be either
   * the size of [buffer] or `0`.
   */
  int send(List<int> buffer, InternetAddress address, int port);

  /**
   * Receive a datagram. If there are no datagrams available `null` is
   * returned.
   */
  Datagram receive();

  /**
   * Join a multicast group.
   *
   * If an error occur when trying to join the multicast group an
   * exception is thrown.
   */
  void joinMulticast(InternetAddress group, {NetworkInterface interface});

  /**
   * Leave a multicast group.
   *
   * If an error occur when trying to join the multicase group an
   * exception is thrown.
   */
  void leaveMulticast(InternetAddress group, {NetworkInterface interface});
}


class SocketException implements IOException {
  final String message;
  final OSError osError;
  final InternetAddress address;
  final int port;

  const SocketException(this.message, {this.osError, this.address, this.port});

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
      sb.write(", address = ${address.host}");
    }
    if (port != null) {
      sb.write(", port = $port");
    }
    return sb.toString();
  }
}
