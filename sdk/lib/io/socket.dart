// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * [InternetAddressType] is the type an [InternetAddress]. Currently,
 * IP version 4 (IPv4) and IP version 6 (IPv6) are supported.
 */
class InternetAddressType {
  static const InternetAddressType IPv4 = const InternetAddressType._(0);
  static const InternetAddressType IPv6 = const InternetAddressType._(1);
  static const InternetAddressType any = const InternetAddressType._(-1);

  @Deprecated("Use IPv4 instead")
  static const InternetAddressType IP_V4 = IPv4;
  @Deprecated("Use IPv6 instead")
  static const InternetAddressType IP_V6 = IPv6;
  @Deprecated("Use any instead")
  static const InternetAddressType ANY = any;

  final int _value;

  const InternetAddressType._(this._value);

  factory InternetAddressType._from(int value) {
    if (value == 0) return IPv4;
    if (value == 1) return IPv6;
    throw new ArgumentError("Invalid type: $value");
  }

  /**
   * Get the name of the type, e.g. "IPv4" or "IPv6".
   */
  String get name {
    switch (_value) {
      case -1:
        return "ANY";
      case 0:
        return "IPv4";
      case 1:
        return "IPv6";
      default:
        throw new ArgumentError("Invalid InternetAddress");
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
  static InternetAddress get loopbackIPv4 => LOOPBACK_IP_V4;
  @Deprecated("Use loopbackIPv4 instead")
  external static InternetAddress get LOOPBACK_IP_V4;

  /**
   * IP version 6 loopback address. Use this address when listening on
   * or connecting to the loopback adapter using IP version 6 (IPv6).
   */
  static InternetAddress get loopbackIPv6 => LOOPBACK_IP_V6;
  @Deprecated("Use loopbackIPv6 instead")
  external static InternetAddress get LOOPBACK_IP_V6;

  /**
   * IP version 4 any address. Use this address when listening on
   * all adapters IP addresses using IP version 4 (IPv4).
   */
  static InternetAddress get anyIPv4 => ANY_IP_V4;
  @Deprecated("Use anyIPv4 instead")
  external static InternetAddress get ANY_IP_V4;

  /**
   * IP version 6 any address. Use this address when listening on
   * all adapters IP addresses using IP version 6 (IPv6).
   */
  static InternetAddress get anyIPv6 => ANY_IP_V6;
  @Deprecated("Use anyIPv6 instead")
  external static InternetAddress get ANY_IP_V6;

  /**
   * The [type] of the [InternetAddress] specified what IP protocol.
   */
  InternetAddressType get type;

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
   * addresses. If [type] is either [InternetAddressType.IPv4] or
   * [InternetAddressType.IPv6] it will only lookup addresses of the
   * specified type. The order of the list can, and most likely will,
   * change over time.
   */
  external static Future<List<InternetAddress>> lookup(String host,
      {InternetAddressType type: InternetAddressType.any});

  /**
   * Clones the given [address] with the new [host].
   *
   * The [address] must be an [InternetAddress] that was created with one
   * of the static methods of this class.
   */
  external static InternetAddress _cloneWithNewHost(
      InternetAddress address, String host);
}

/**
 * A [NetworkInterface] represents an active network interface on the current
 * system. It contains a list of [InternetAddress]es that are bound to the
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
  int get index;

  /**
   * Get a list of [InternetAddress]es currently bound to this
   * [NetworkInterface].
   */
  List<InternetAddress> get addresses;

  /**
   * Whether [list] is supported.
   *
   * [list] is currently unsupported on Android.
   */
  external static bool get listSupported;

  /**
   * Query the system for [NetworkInterface]s.
   *
   * If [includeLoopback] is `true`, the returned list will include the
   * loopback device. Default is `false`.
   *
   * If [includeLinkLocal] is `true`, the list of addresses of the returned
   * [NetworkInterface]s, may include link local addresses. Default is `false`.
   *
   * If [type] is either [InternetAddressType.IPv4] or
   * [InternetAddressType.IPv6] it will only lookup addresses of the
   * specified type. Default is [InternetAddressType.any].
   */
  external static Future<List<NetworkInterface>> list(
      {bool includeLoopback: false,
      bool includeLinkLocal: false,
      InternetAddressType type: InternetAddressType.any});
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
   * [InternetAddress.loopbackIPv4] or
   * [InternetAddress.loopbackIPv6]. To allow for incoming
   * connection from the network use either one of the values
   * [InternetAddress.anyIPv4] or [InternetAddress.anyIPv6] to
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
   *
   * The optional argument [shared] specifies whether additional RawServerSocket
   * objects can bind to the same combination of `address`, `port` and `v6Only`.
   * If `shared` is `true` and more `RawServerSocket`s from this isolate or
   * other isolates are bound to the port, then the incoming connections will be
   * distributed among all the bound `RawServerSocket`s. Connections can be
   * distributed over multiple isolates this way.
   */
  external static Future<RawServerSocket> bind(address, int port,
      {int backlog: 0, bool v6Only: false, bool shared: false});

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
   * [InternetAddress.loopbackIPv4] or
   * [InternetAddress.loopbackIPv6]. To allow for incoming
   * connection from the network use either one of the values
   * [InternetAddress.anyIPv4] or [InternetAddress.anyIPv6] to
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
   *
   * The optional argument [shared] specifies whether additional ServerSocket
   * objects can bind to the same combination of `address`, `port` and `v6Only`.
   * If `shared` is `true` and more `ServerSocket`s from this isolate or other
   * isolates are bound to the port, then the incoming connections will be
   * distributed among all the bound `ServerSocket`s. Connections can be
   * distributed over multiple isolates this way.
   */
  external static Future<ServerSocket> bind(address, int port,
      {int backlog: 0, bool v6Only: false, bool shared: false});

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
  static const SocketDirection receive = const SocketDirection._(0);
  static const SocketDirection send = const SocketDirection._(1);
  static const SocketDirection both = const SocketDirection._(2);

  @Deprecated("Use receive instead")
  static const SocketDirection RECEIVE = receive;
  @Deprecated("Use send instead")
  static const SocketDirection SEND = send;
  @Deprecated("Use both instead")
  static const SocketDirection BOTH = both;

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
   * Enable or disable no-delay on the socket. If tcpNoDelay is enabled, the
   * socket will not buffer data internally, but instead write each data chunk
   * as an individual TCP packet.
   *
   * tcpNoDelay is disabled by default.
   */
  static const SocketOption tcpNoDelay = const SocketOption._(0);
  @Deprecated("Use tcpNoDelay instead")
  static const SocketOption TCP_NODELAY = tcpNoDelay;

  static const SocketOption _ipMulticastLoop = const SocketOption._(1);
  static const SocketOption _ipMulticastHops = const SocketOption._(2);
  static const SocketOption _ipMulticastIf = const SocketOption._(3);
  static const SocketOption _ipBroadcast = const SocketOption._(4);

  final _value;

  const SocketOption._(this._value);
}

// Must be kept in sync with enum in socket.cc
enum _RawSocketOptions {
  SOL_SOCKET, // 0
  IPPROTO_IP, // 1
  IP_MULTICAST_IF, // 2
  IPPROTO_IPV6, // 3
  IPV6_MULTICAST_IF, // 4
  IPPROTO_TCP, // 5
  IPPROTO_UDP, // 6
}

/// The [RawSocketOption] is used as a parameter to [Socket.setRawOption] and
/// [RawSocket.setRawOption] to set customize the behaviour of the underlying
/// socket.
///
/// It allows for fine grained control of the socket options, and its values will
/// be passed to the underlying platform's implementation of setsockopt and
/// getsockopt.
class RawSocketOption {
  /// Creates a RawSocketOption for getRawOption andSetRawOption.
  ///
  /// All arguments are required and must not be null.
  ///
  /// The level and option arguments correspond to level and optname arguments
  /// on the get/setsockopt native calls.
  ///
  /// The value argument and its length correspond to the optval and length
  /// arguments on the native call.
  ///
  /// For a [getRawOption] call, the value parameter will be updated after a
  /// successful call (although its length will not be changed).
  ///
  /// For a [setRawOption] call, the value parameter will be used set the
  /// option.
  const RawSocketOption(this.level, this.option, this.value);

  /// Convenience constructor for creating an int based RawSocketOption.
  factory RawSocketOption.fromInt(int level, int option, int value) {
    if (value == null) {
      value = 0;
    }
    final Uint8List list = Uint8List(4);
    final buffer = ByteData.view(list.buffer);
    buffer.setInt32(0, value);
    return RawSocketOption(level, option, list);
  }

  /// Convenience constructor for creating a bool based RawSocketOption.
  factory RawSocketOption.fromBool(int level, int option, bool value) =>
      RawSocketOption.fromInt(level, option, value == true ? 1 : 0);

  /// The level for the option to set or get.
  ///
  /// See also:
  ///   * [RawSocketOption.levelSocket]
  ///   * [RawSocketOption.levelIPv4]
  ///   * [RawSocketOption.levelIPv6]
  ///   * [RawSocketOption.levelTcp]
  ///   * [RawSocketOption.levelUdp]
  final int level;

  /// The option to set or get.
  final int option;

  /// The raw data to set, or the array to write the current option value into.
  ///
  /// This list must be the correct length for the expected option. For most
  /// options that take int or bool values, the length should be 4. For options
  /// that expect a struct (such as an in_addr_t), the length should be the
  /// correct length for that struct.
  final Uint8List value;

  /// Socket level option for SOL_SOCKET.
  static int get levelSocket =>
      _getOptionValue(_RawSocketOptions.SOL_SOCKET.index);

  /// Socket level option for IPPROTO_IP.
  static int get levelIPv4 =>
      _getOptionValue(_RawSocketOptions.IPPROTO_IP.index);

  /// Socket option for IP_MULTICAST_IF.
  static int get IPv4MulticastInterface =>
      _getOptionValue(_RawSocketOptions.IP_MULTICAST_IF.index);

  /// Socket level option for IPPROTO_IPV6.
  static int get levelIPv6 =>
      _getOptionValue(_RawSocketOptions.IPPROTO_IPV6.index);

  /// Socket option for IPV6_MULTICAST_IF.
  static int get IPv6MulticastInterface =>
      _getOptionValue(_RawSocketOptions.IPV6_MULTICAST_IF.index);

  /// Socket level option for IPPROTO_TCP.
  static int get levelTcp =>
      _getOptionValue(_RawSocketOptions.IPPROTO_TCP.index);

  /// Socket level option for IPPROTO_UDP.
  static int get levelUdp =>
      _getOptionValue(_RawSocketOptions.IPPROTO_UDP.index);

  external static int _getOptionValue(int key);
}

/**
 * Events for the [RawSocket].
 */
class RawSocketEvent {
  static const RawSocketEvent read = const RawSocketEvent._(0);
  static const RawSocketEvent write = const RawSocketEvent._(1);
  static const RawSocketEvent readClosed = const RawSocketEvent._(2);
  static const RawSocketEvent closed = const RawSocketEvent._(3);

  @Deprecated("Use read instead")
  static const RawSocketEvent READ = read;
  @Deprecated("Use write instead")
  static const RawSocketEvent WRITE = write;
  @Deprecated("Use readClosed instead")
  static const RawSocketEvent READ_CLOSED = readClosed;
  @Deprecated("Use closed instead")
  static const RawSocketEvent CLOSED = closed;

  final int _value;

  const RawSocketEvent._(this._value);
  String toString() {
    return const [
      'RawSocketEvent.read',
      'RawSocketEvent.write',
      'RawSocketEvent.readClosed',
      'RawSocketEvent.closed'
    ][_value];
  }
}

/// Returned by the `startConnect` methods on client-side socket types `S`,
/// `ConnectionTask<S>` allows cancelling an attempt to connect to a host.
class ConnectionTask<S> {
  /// A `Future` that completes with value that `S.connect()` would return
  /// unless [cancel] is called on this [ConnectionTask].
  ///
  /// If [cancel] is called, the `Future` completes with a [SocketException]
  /// error whose message indicates that the connection attempt was cancelled.
  final Future<S> socket;
  final void Function() _onCancel;

  ConnectionTask._({Future<S> socket, void Function() onCancel})
      : assert(socket != null),
        assert(onCancel != null),
        this.socket = socket,
        this._onCancel = onCancel;

  /// Cancels the connection attempt.
  ///
  /// This also causes the [socket] `Future` to complete with a
  /// [SocketException] error.
  void cancel() {
    _onCancel();
  }
}

/**
 * The [RawSocket] is a low-level interface to a socket, exposing the raw
 * events signaled by the system. It's a [Stream] of [RawSocketEvent]s.
 */
abstract class RawSocket implements Stream<RawSocketEvent> {
  /**
   * Set or get, if the [RawSocket] should listen for [RawSocketEvent.read]
   * events. Default is [:true:].
   */
  bool readEventsEnabled;

  /**
   * Set or get, if the [RawSocket] should listen for [RawSocketEvent.write]
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
   * all returned [InternetAddress]es, until connected. Unless a
   * connection was established, the error from the first failing connection is
   * returned.
   *
   * The argument [sourceAddress] can be used to specify the local
   * address to bind when making the connection. `sourceAddress` can either
   * be a `String` or an `InternetAddress`. If a `String` is passed it must
   * hold a numeric IP address.
   *
   * The argument [timeout] is used to specify the maximum allowed time to wait
   * for a connection to be established. If [timeout] is longer than the system
   * level timeout duration, a timeout may occur sooner than specified in
   * [timeout]. On timeout, a [SocketException] is thrown and all ongoing
   * connection attempts to [host] are cancelled.
   */
  external static Future<RawSocket> connect(host, int port,
      {sourceAddress, Duration timeout});

  /// Like [connect], but returns a [Future] that completes with a
  /// [ConnectionTask] that can be cancelled if the [RawSocket] is no
  /// longer needed.
  external static Future<ConnectionTask<RawSocket>> startConnect(host, int port,
      {sourceAddress});

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
   * a [RawSocketEvent.readClosed] event.
   */
  Future<RawSocket> close();

  /**
   * Shutdown the socket in the [direction]. Calling [shutdown] will never
   * throw an exception and calling it several times is supported. Calling
   * shutdown with either [SocketDirection.both] or [SocketDirection.receive]
   * can result in a [RawSocketEvent.readClosed] event.
   */
  void shutdown(SocketDirection direction);

  /**
   * Use [setOption] to customize the [RawSocket]. See [SocketOption] for
   * available options.
   *
   * Returns [:true:] if the option was set successfully, false otherwise.
   */
  bool setOption(SocketOption option, bool enabled);

  /**
   * Use [getRawOption] to get low level information about the [RawSocket]. See
   * [RawSocketOption] for available options.
   *
   * Returns the [RawSocketOption.value] on success.
   *
   * Throws an [OSError] on failure.
   */
  Uint8List getRawOption(RawSocketOption option);

  /**
   * Use [setRawOption] to customize the [RawSocket]. See [RawSocketOption] for
   * available options.
   *
   * Throws an [OSError] on failure.
   */
  void setRawOption(RawSocketOption option);
}

/**
 * A high-level class for communicating over a TCP socket.
 *
 * The [Socket] exposes both a [Stream] and a [IOSink] interface, making it
 * ideal for using together with other [Stream]s.
 */
abstract class Socket implements Stream<List<int>>, IOSink {
  /**
   * Creates a new socket connection to the host and port and returns a [Future]
   * that will complete with either a [Socket] once connected or an error
   * if the host-lookup or connection failed.
   *
   * [host] can either be a [String] or an [InternetAddress]. If [host] is a
   * [String], [connect] will perform a [InternetAddress.lookup] and try
   * all returned [InternetAddress]es, until connected. Unless a
   * connection was established, the error from the first failing connection is
   * returned.
   *
   * The argument [sourceAddress] can be used to specify the local
   * address to bind when making the connection. `sourceAddress` can either
   * be a `String` or an `InternetAddress`. If a `String` is passed it must
   * hold a numeric IP address.
   *
   * The argument [timeout] is used to specify the maximum allowed time to wait
   * for a connection to be established. If [timeout] is longer than the system
   * level timeout duration, a timeout may occur sooner than specified in
   * [timeout]. On timeout, a [SocketException] is thrown and all ongoing
   * connection attempts to [host] are cancelled.
   */
  static Future<Socket> connect(host, int port,
      {sourceAddress, Duration timeout}) {
    final IOOverrides overrides = IOOverrides.current;
    if (overrides == null) {
      return Socket._connect(host, port,
          sourceAddress: sourceAddress, timeout: timeout);
    }
    return overrides.socketConnect(host, port,
        sourceAddress: sourceAddress, timeout: timeout);
  }

  /// Like [connect], but returns a [Future] that completes with a
  /// [ConnectionTask] that can be cancelled if the [Socket] is no
  /// longer needed.
  static Future<ConnectionTask<Socket>> startConnect(host, int port,
      {sourceAddress}) {
    final IOOverrides overrides = IOOverrides.current;
    if (overrides == null) {
      return Socket._startConnect(host, port, sourceAddress: sourceAddress);
    }
    return overrides.socketStartConnect(host, port,
        sourceAddress: sourceAddress);
  }

  external static Future<Socket> _connect(host, int port,
      {sourceAddress, Duration timeout});

  external static Future<ConnectionTask<Socket>> _startConnect(host, int port,
      {sourceAddress});

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
   * Use [getRawOption] to get low level information about the [RawSocket]. See
   * [RawSocketOption] for available options.
   *
   * Returns the [RawSocketOption.value] on success.
   *
   * Throws an [OSError] on failure.
   */
  Uint8List getRawOption(RawSocketOption option);

  /**
   * Use [setRawOption] to customize the [RawSocket]. See [RawSocketOption] for
   * available options.
   *
   * Throws an [OSError] on failure.
   */
  void setRawOption(RawSocketOption option);

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

  Future close();

  Future get done;
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
 * Note that the event [RawSocketEvent.readClosed] will never be
 * received as an UDP socket cannot be closed by a remote peer.
 */
abstract class RawDatagramSocket extends Stream<RawSocketEvent> {
  /**
   * Set or get, if the [RawDatagramSocket] should listen for
   * [RawSocketEvent.read] events. Default is [:true:].
   */
  bool readEventsEnabled;

  /**
   * Set or get, if the [RawDatagramSocket] should listen for
   * [RawSocketEvent.write] events. Default is [:true:].  This is a
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
  @Deprecated("This property is not implemented. Use getRawOption and "
      "setRawOption instead.")
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
  external static Future<RawDatagramSocket> bind(host, int port,
      {bool reuseAddress: true, bool reusePort: false, int ttl: 1});

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
   *
   * The maximum length of the datagram that can be received is 65503 bytes.
   */
  Datagram receive();

  /**
   * Join a multicast group.
   *
   * If an error occur when trying to join the multicast group an
   * exception is thrown.
   */
  void joinMulticast(InternetAddress group, [NetworkInterface interface]);

  /**
   * Leave a multicast group.
   *
   * If an error occur when trying to join the multicase group an
   * exception is thrown.
   */
  void leaveMulticast(InternetAddress group, [NetworkInterface interface]);

  /**
   * Use [getRawOption] to get low level information about the [RawSocket]. See
   * [RawSocketOption] for available options.
   *
   * Returns [RawSocketOption.value] on success.
   *
   * Throws an [OSError] on failure.
   */
  Uint8List getRawOption(RawSocketOption option);

  /**
   * Use [setRawOption] to customize the [RawSocket]. See [RawSocketOption] for
   * available options.
   *
   * Throws an [OSError] on failure.
   */
  void setRawOption(RawSocketOption option);
}

class SocketException implements IOException {
  final String message;
  final OSError osError;
  final InternetAddress address;
  final int port;

  const SocketException(this.message, {this.osError, this.address, this.port});
  const SocketException.closed()
      : message = 'Socket has been closed',
        osError = null,
        address = null,
        port = null;

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("SocketException");
    if (message.isNotEmpty) {
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
