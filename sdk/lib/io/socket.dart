// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/// The type, or address family, of an [InternetAddress].
///
/// Currently, IP version 4 (IPv4), IP version 6 (IPv6)
/// and Unix domain address are supported.
/// Unix domain sockets are available only on Linux, MacOS and Android.
class InternetAddressType {
  static const InternetAddressType IPv4 = const InternetAddressType._(0);
  static const InternetAddressType IPv6 = const InternetAddressType._(1);
  @Since("2.8")
  static const InternetAddressType unix = const InternetAddressType._(2);
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
    if (value == IPv4._value) return IPv4;
    if (value == IPv6._value) return IPv6;
    if (value == unix._value) return unix;
    throw new ArgumentError("Invalid type: $value");
  }

  /// Get the name of the type, e.g. "IPv4" or "IPv6".
  String get name => const ["ANY", "IPv4", "IPv6", "Unix"][_value + 1];

  String toString() => "InternetAddressType: $name";
}

/// An internet address or a Unix domain address.
///
/// This object holds an internet address. If this internet address
/// is the result of a DNS lookup, the address also holds the hostname
/// used to make the lookup.
/// An Internet address combined with a port number represents an
/// endpoint to which a socket can connect or a listening socket can
/// bind.
abstract class InternetAddress {
  /// IP version 4 loopback address.
  ///
  /// Use this address when listening on or connecting
  /// to the loopback adapter using IP version 4 (IPv4).
  static InternetAddress get loopbackIPv4 => LOOPBACK_IP_V4;
  @Deprecated("Use loopbackIPv4 instead")
  external static InternetAddress get LOOPBACK_IP_V4;

  /// IP version 6 loopback address.
  ///
  /// Use this address when listening on or connecting to
  /// the loopback adapter using IP version 6 (IPv6).
  static InternetAddress get loopbackIPv6 => LOOPBACK_IP_V6;
  @Deprecated("Use loopbackIPv6 instead")
  external static InternetAddress get LOOPBACK_IP_V6;

  /// IP version 4 any address.
  ///
  /// Use this address when listening on the addresses
  /// of all adapters using IP version 4 (IPv4).
  static InternetAddress get anyIPv4 => ANY_IP_V4;
  @Deprecated("Use anyIPv4 instead")
  external static InternetAddress get ANY_IP_V4;

  /// IP version 6 any address.
  ///
  /// Use this address when listening on the addresses
  /// of all adapters using IP version 6 (IPv6).
  static InternetAddress get anyIPv6 => ANY_IP_V6;
  @Deprecated("Use anyIPv6 instead")
  external static InternetAddress get ANY_IP_V6;

  /// The address family of the [InternetAddress].
  InternetAddressType get type;

  /// The numeric address of the host.
  ///
  /// For IPv4 addresses this is using the dotted-decimal notation.
  /// For IPv6 it is using the hexadecimal representation.
  /// For Unix domain addresses, this is a file path.
  String get address;

  /// The host used to lookup the address.
  ///
  /// If there is no host associated with the address this returns the [address].
  String get host;

  /// The raw address of this [InternetAddress].
  ///
  /// For an IP address, the result is either a 4 or 16 byte long list.
  /// For a Unix domain address, UTF-8 encoded byte sequences that represents
  /// [address] is returned.
  ///
  /// The returned list is a fresh copy, making it possible to change the list without
  /// modifying the [InternetAddress].
  Uint8List get rawAddress;

  /// Whether the [InternetAddress] is a loopback address.
  bool get isLoopback;

  /// Whether the scope of the [InternetAddress] is a link-local.
  bool get isLinkLocal;

  /// Whether the scope of the [InternetAddress] is multicast.
  bool get isMulticast;

  /// Creates a new [InternetAddress] from a numeric address or a file path.
  ///
  /// If [type] is [InternetAddressType.IPv4], [address] must be a numeric IPv4
  /// address (dotted-decimal notation).
  /// If [type] is [InternetAddressType.IPv6], [address] must be a numeric IPv6
  /// address (hexadecimal notation).
  /// If [type] is [InternetAddressType.unix], [address] must be a a valid file
  /// path.
  /// If [type] is omitted, [address] must be either a numeric IPv4 or IPv6
  /// address and the type is inferred from the format.
  external factory InternetAddress(String address,
      {@Since("2.8") InternetAddressType? type});

  /// Creates a new [InternetAddress] from the provided raw address bytes.
  ///
  /// If the [type] is [InternetAddressType.IPv4], the [rawAddress] must have
  /// length 4.
  /// If the [type] is [InternetAddressType.IPv6], the [rawAddress] must have
  /// length 16.
  /// If the [type] is [InternetAddressType.unix], the [rawAddress] must be a
  /// valid UTF-8 encoded file path.
  ///
  /// If [type] is omitted, the [rawAddress] must have a length of either 4 or
  /// 16, in which case the type defaults to [InternetAddressType.IPv4] or
  /// [InternetAddressType.IPv6] respectively.
  external factory InternetAddress.fromRawAddress(Uint8List rawAddress,
      {@Since("2.8") InternetAddressType? type});

  /// Performs a reverse DNS lookup on this [address]
  ///
  /// Returns a new [InternetAddress] with the same address, but where the [host]
  /// field set to the result of the lookup.
  ///
  /// If this address is Unix domain addresses, no lookup is performed and this
  /// address is returned directly.
  Future<InternetAddress> reverse();

  /// Looks up the addresses of a host.
  ///
  /// If [type] is [InternetAddressType.any], it will lookup both
  /// IP version 4 (IPv4) and IP version 6 (IPv6) addresses.
  /// If [type] is either [InternetAddressType.IPv4] or
  /// [InternetAddressType.IPv6] it will only lookup addresses of the
  /// specified type. The order of the list can, and most likely will,
  /// change over time.
  external static Future<List<InternetAddress>> lookup(String host,
      {InternetAddressType type = InternetAddressType.any});

  /// Clones the given [address] with the new [host].
  ///
  /// The [address] must be an [InternetAddress] that was created with one
  /// of the static methods of this class.
  external static InternetAddress _cloneWithNewHost(
      InternetAddress address, String host);

  /// Attempts to parse [address] as a numeric address.
  ///
  /// Returns `null` If [address] is not a numeric IPv4 (dotted-decimal
  /// notation) or IPv6 (hexadecimal representation) address.
  external static InternetAddress? tryParse(String address);
}

/// A [NetworkInterface] represents an active network interface on the current
/// system. It contains a list of [InternetAddress]es that are bound to the
/// interface.
abstract class NetworkInterface {
  /// The name of the [NetworkInterface].
  String get name;

  /// The index of the [NetworkInterface].
  int get index;

  /// The list of [InternetAddress]es currently bound to this
  /// [NetworkInterface].
  List<InternetAddress> get addresses;

  /// Whether the [list] method is supported.
  ///
  /// The [list] method is currently unsupported on Android.
  external static bool get listSupported;

  /// Query the system for [NetworkInterface]s.
  ///
  /// If [includeLoopback] is `true`, the returned list will include the
  /// loopback device. Default is `false`.
  ///
  /// If [includeLinkLocal] is `true`, the list of addresses of the returned
  /// [NetworkInterface]s, may include link local addresses. Default is `false`.
  ///
  /// If [type] is either [InternetAddressType.IPv4] or
  /// [InternetAddressType.IPv6] it will only lookup addresses of the
  /// specified type. Default is [InternetAddressType.any].
  external static Future<List<NetworkInterface>> list(
      {bool includeLoopback = false,
      bool includeLinkLocal = false,
      InternetAddressType type = InternetAddressType.any});
}

/// A listening socket.
///
/// A `RawServerSocket` and provides a stream of low-level [RawSocket] objects,
/// one for each connection made to the listening socket.
///
/// See [RawSocket] for more info.
abstract class RawServerSocket implements Stream<RawSocket> {
  /// Listens on a given address and port.
  ///
  /// When the returned future completes the server socket is bound
  /// to the given [address] and [port] and has started listening on it.
  ///
  /// The [address] can either be a [String] or an
  /// [InternetAddress]. If [address] is a [String], [bind] will
  /// perform a [InternetAddress.lookup] and use the first value in the
  /// list. To listen on the loopback adapter, which will allow only
  /// incoming connections from the local host, use the value
  /// [InternetAddress.loopbackIPv4] or
  /// [InternetAddress.loopbackIPv6]. To allow for incoming
  /// connection from the network use either one of the values
  /// [InternetAddress.anyIPv4] or [InternetAddress.anyIPv6] to
  /// bind to all interfaces or the IP address of a specific interface.
  ///
  /// If an IP version 6 (IPv6) address is used, both IP version 6
  /// (IPv6) and version 4 (IPv4) connections will be accepted. To
  /// restrict this to version 6 (IPv6) only, use [v6Only] to set
  /// version 6 only.
  ///
  /// If [port] has the value `0` an ephemeral port will
  /// be chosen by the system. The actual port used can be retrieved
  /// using the `port` getter.
  ///
  /// The optional argument [backlog] can be used to specify the listen
  /// backlog for the underlying OS listen setup. If [backlog] has the
  /// value of `0` (the default) a reasonable value will be chosen by
  /// the system.
  ///
  /// The optional argument [shared] specifies whether additional RawServerSocket
  /// objects can bind to the same combination of [address], [port] and [v6Only].
  /// If [shared] is `true` and more [RawServerSocket]s from this isolate or
  /// other isolates are bound to the port, then the incoming connections will be
  /// distributed among all the bound [RawServerSocket]s. Connections can be
  /// distributed over multiple isolates this way.
  external static Future<RawServerSocket> bind(address, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false});

  /// The port used by this socket.
  int get port;

  /// The address used by this socket.
  InternetAddress get address;

  /// Closes the socket.
  ///
  /// The returned future completes when the socket
  /// is fully closed and is no longer bound.
  Future<RawServerSocket> close();
}

/// A listening socket.
///
/// A [ServerSocket] provides a stream of [Socket] objects,
/// one for each connection made to the listening socket.
///
/// See [Socket] for more info.
abstract class ServerSocket implements Stream<Socket> {
  /// Listens on a given address and port.
  ///
  /// When the returned future completes the server socket is bound
  /// to the given [address] and [port] and has started listening on it.
  ///
  /// The [address] can either be a [String] or an
  /// [InternetAddress]. If [address] is a [String], [bind] will
  /// perform a [InternetAddress.lookup] and use the first value in the
  /// list. To listen on the loopback adapter, which will allow only
  /// incoming connections from the local host, use the value
  /// [InternetAddress.loopbackIPv4] or
  /// [InternetAddress.loopbackIPv6]. To allow for incoming
  /// connection from the network use either one of the values
  /// [InternetAddress.anyIPv4] or [InternetAddress.anyIPv6] to
  /// bind to all interfaces or the IP address of a specific interface.
  ///
  /// If an IP version 6 (IPv6) address is used, both IP version 6
  /// (IPv6) and version 4 (IPv4) connections will be accepted. To
  /// restrict this to version 6 (IPv6) only, use [v6Only] to set
  /// version 6 only.
  ///
  /// If [port] has the value `0` an ephemeral port will be chosen by
  /// the system. The actual port used can be retrieved using the
  /// [port] getter.
  ///
  /// The optional argument [backlog] can be used to specify the listen
  /// backlog for the underlying OS listen setup. If [backlog] has the
  /// value of `0` (the default) a reasonable value will be chosen by
  /// the system.
  ///
  /// The optional argument [shared] specifies whether additional ServerSocket
  /// objects can bind to the same combination of [address], [port] and
  /// [v6Only]. If [shared] is `true` and more server sockets from this
  /// isolate or other isolates are bound to the port, then the incoming
  /// connections will be distributed among all the bound server sockets.
  /// Connections can be distributed over multiple isolates this way.
  static Future<ServerSocket> bind(address, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false}) {
    final IOOverrides? overrides = IOOverrides.current;
    if (overrides == null) {
      return ServerSocket._bind(address, port,
          backlog: backlog, v6Only: v6Only, shared: shared);
    }
    return overrides.serverSocketBind(address, port,
        backlog: backlog, v6Only: v6Only, shared: shared);
  }

  external static Future<ServerSocket> _bind(address, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false});

  /// The port used by this socket.
  int get port;

  /// The address used by this socket.
  InternetAddress get address;

  /// Closes the socket.
  ///
  /// The returned future completes when the socket
  /// is fully closed and is no longer bound.
  Future<ServerSocket> close();
}

/// The [SocketDirection] is used as a parameter to [Socket.close] and
/// [RawSocket.close] to close a socket in the specified direction(s).
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

/// An option for a socket which is configured using [Socket.setOption].
///
/// The [SocketOption] is used as a parameter to [Socket.setOption] and
/// [RawSocket.setOption] to customize the behaviour of the underlying
/// socket.
class SocketOption {
  /// Enable or disable no-delay on the socket. If tcpNoDelay is enabled, the
  /// socket will not buffer data internally, but instead write each data chunk
  /// as an individual TCP packet.
  ///
  /// tcpNoDelay is disabled by default.
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
/// [RawSocket.setRawOption] to customize the behaviour of the underlying
/// socket.
///
/// It allows for fine grained control of the socket options, and its values
/// will be passed to the underlying platform's implementation of setsockopt and
/// getsockopt.
@Since("2.2")
class RawSocketOption {
  /// Creates a [RawSocketOption] for [RawSocket.getRawOption]
  /// and [RawSocket.setRawOption].
  ///
  /// The [level] and [option] arguments correspond to `level` and `optname` arguments
  /// on the `getsockopt()` and `setsockopt()` native calls.
  ///
  /// The value argument and its length correspond to the optval and length
  /// arguments on the native call.
  ///
  /// For a [RawSocket.getRawOption] call, the value parameter will be updated
  /// after a successful call (although its length will not be changed).
  ///
  /// For a [RawSocket.setRawOption] call, the value parameter will be used set
  /// the option.
  const RawSocketOption(this.level, this.option, this.value);

  /// Convenience constructor for creating an integer based [RawSocketOption].
  factory RawSocketOption.fromInt(int level, int option, int value) {
    final Uint8List list = Uint8List(4);
    final buffer = ByteData.view(list.buffer, list.offsetInBytes);
    buffer.setInt32(0, value, Endian.host);
    return RawSocketOption(level, option, list);
  }

  /// Convenience constructor for creating a boolean based [RawSocketOption].
  factory RawSocketOption.fromBool(int level, int option, bool value) =>
      RawSocketOption.fromInt(level, option, value ? 1 : 0);

  /// The level for the option to set or get.
  ///
  /// See also:
  ///   * [RawSocketOption.levelSocket]
  ///   * [RawSocketOption.levelIPv4]
  ///   * [RawSocketOption.levelIPv6]
  ///   * [RawSocketOption.levelTcp]
  ///   * [RawSocketOption.levelUdp]
  final int level;

  /// The numeric ID of the option to set or get.
  final int option;

  /// The raw data to set, or the array to write the current option value into.
  ///
  /// This list must be the correct length for the expected option. For most
  /// options that take [int] or [bool] values, the length should be 4. For options
  /// that expect a struct (such as an in_addr_t), the length should be the
  /// correct length for that struct.
  final Uint8List value;

  /// Socket level option for `SOL_SOCKET`.
  static int get levelSocket =>
      _getOptionValue(_RawSocketOptions.SOL_SOCKET.index);

  /// Socket level option for `IPPROTO_IP`.
  static int get levelIPv4 =>
      _getOptionValue(_RawSocketOptions.IPPROTO_IP.index);

  /// Socket option for `IP_MULTICAST_IF`.
  static int get IPv4MulticastInterface =>
      _getOptionValue(_RawSocketOptions.IP_MULTICAST_IF.index);

  /// Socket level option for `IPPROTO_IPV6`.
  static int get levelIPv6 =>
      _getOptionValue(_RawSocketOptions.IPPROTO_IPV6.index);

  /// Socket option for `IPV6_MULTICAST_IF`.
  static int get IPv6MulticastInterface =>
      _getOptionValue(_RawSocketOptions.IPV6_MULTICAST_IF.index);

  /// Socket level option for `IPPROTO_TCP`.
  static int get levelTcp =>
      _getOptionValue(_RawSocketOptions.IPPROTO_TCP.index);

  /// Socket level option for `IPPROTO_UDP`.
  static int get levelUdp =>
      _getOptionValue(_RawSocketOptions.IPPROTO_UDP.index);

  external static int _getOptionValue(int key);
}

/// Events for the [RawSocket].
///
/// These event objects are used by the [Stream] behavior of [RawSocket]
/// (for example [RawSocket.listen], [RawSocket.forEach])
/// when the socket's state change.
class RawSocketEvent {
  /// An event indicates the socket is ready to be read.
  static const RawSocketEvent read = const RawSocketEvent._(0);

  /// An event indicates the socket is ready to write.
  static const RawSocketEvent write = const RawSocketEvent._(1);

  /// An event indicates the reading from the socket is closed
  static const RawSocketEvent readClosed = const RawSocketEvent._(2);

  /// An event indicates the socket is closed.
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

/// A cancelable connection attempt.
///
/// Returned by the `startConnect` methods on client-side socket types `S`,
/// `ConnectionTask<S>` allows cancelling an attempt to connect to a host.
class ConnectionTask<S> {
  /// A `Future` that completes with value that `S.connect()` would return
  /// unless [cancel] is called on this [ConnectionTask].
  ///
  /// If [cancel] is called, the future completes with a [SocketException]
  /// error whose message indicates that the connection attempt was cancelled.
  final Future<S> socket;
  final void Function() _onCancel;

  ConnectionTask._(Future<S> this.socket, void Function() onCancel)
      : _onCancel = onCancel;

  /// Cancels the connection attempt.
  ///
  /// This also causes the [socket] `Future` to complete with a
  /// [SocketException] error.
  void cancel() {
    _onCancel();
  }
}

/// A TCP connection.
///
/// A *socket connection* connects a *local* socket to a *remote* socket.
/// Data, as [Uint8List]s, is received by the local socket and made
/// available by the [read] method, and can be sent to the remote socket
/// through the [write] method.
///
/// The [Stream] interface of this class provides event notification about when
/// a certain change has happened, for example when data has become available
/// ([RawSocketEvent.read]) or when the remote end has stopped listening
/// ([RawSocketEvent.closed]).
abstract class RawSocket implements Stream<RawSocketEvent> {
  /// Set or get, if the [RawSocket] should listen for [RawSocketEvent.read]
  /// events. Default is `true`.
  abstract bool readEventsEnabled;

  /// Set or get, if the [RawSocket] should listen for [RawSocketEvent.write]
  /// events. Default is `true`.
  /// This is a one-shot listener, and writeEventsEnabled must be set
  /// to true again to receive another write event.
  abstract bool writeEventsEnabled;

  /// Creates a new socket connection to the host and port.
  ///
  /// Returns a [Future] that will complete with either a [RawSocket]
  /// once connected, or an error if the host-lookup or connection failed.
  ///
  /// The [host] can either be a [String] or an [InternetAddress]. If [host] is a
  /// [String], [connect] will perform a [InternetAddress.lookup] and try
  /// all returned [InternetAddress]es, until connected. Unless a
  /// connection was established, the error from the first failing connection is
  /// returned.
  ///
  /// The argument [sourceAddress] can be used to specify the local
  /// address to bind when making the connection. The [sourceAddress] can either
  /// be a [String] or an [InternetAddress]. If a [String] is passed it must
  /// hold a numeric IP address.
  ///
  /// The argument [timeout] is used to specify the maximum allowed time to wait
  /// for a connection to be established. If [timeout] is longer than the system
  /// level timeout duration, a timeout may occur sooner than specified in
  /// [timeout]. On timeout, a [SocketException] is thrown and all ongoing
  /// connection attempts to [host] are cancelled.
  external static Future<RawSocket> connect(host, int port,
      {sourceAddress, Duration? timeout});

  /// Like [connect], but returns a [Future] that completes with a
  /// [ConnectionTask] that can be cancelled if the [RawSocket] is no
  /// longer needed.
  external static Future<ConnectionTask<RawSocket>> startConnect(host, int port,
      {sourceAddress});

  /// The number of received and non-read bytes in the socket that can be read.
  int available();

  /// Read up to [len] bytes from the socket.
  ///
  /// This function is non-blocking and will only return data
  /// if data is available.
  /// The number of bytes read can be less then [len] if fewer bytes are
  /// available for immediate reading. If no data is available `null`
  /// is returned.
  Uint8List? read([int? len]);

  /// Writes up to [count] bytes of the buffer from [offset] buffer offset to
  /// the socket.
  ///
  /// The number of successfully written bytes is returned.
  /// This function is non-blocking and will only write data
  /// if buffer space is available in the socket.
  ///
  /// The default value for [offset] is 0, and the default value for [count] is
  /// `buffer.length - offset`.
  int write(List<int> buffer, [int offset = 0, int? count]);

  /// The port used by this socket.
  ///
  /// Throws a [SocketException] if the socket is closed.
  int get port;

  /// The remote port connected to by this socket.
  ///
  /// Throws a [SocketException] if the socket is closed.
  int get remotePort;

  /// The [InternetAddress] used to connect this socket.
  ///
  /// Throws a [SocketException] if the socket is closed.
  InternetAddress get address;

  /// The remote [InternetAddress] connected to by this socket.
  ///
  /// Throws a [SocketException] if the socket is closed.
  InternetAddress get remoteAddress;

  /// Closes the socket.
  ///
  /// Returns a future that completes with this socket when the
  /// underlying connection is completely destroyed.
  ///
  /// Calling [close] will never throw an exception
  /// and calling it several times is supported. Calling [close] can result in
  /// a [RawSocketEvent.readClosed] event.
  Future<RawSocket> close();

  /// Shuts down the socket in the [direction].
  ///
  /// Calling [shutdown] will never throw an exception
  /// and calling it several times is supported. Calling
  /// shutdown with either [SocketDirection.both] or [SocketDirection.receive]
  /// can result in a [RawSocketEvent.readClosed] event.
  void shutdown(SocketDirection direction);

  /// Customize the [RawSocket].
  ///
  /// See [SocketOption] for available options.
  ///
  /// Returns `true` if the option was set successfully, `false` otherwise.
  bool setOption(SocketOption option, bool enabled);

  /// Reads low level information about the [RawSocket].
  ///
  /// See [RawSocketOption] for available options.
  ///
  /// Returns the [RawSocketOption.value] on success.
  ///
  /// Throws an [OSError] on failure.
  @Since("2.2")
  Uint8List getRawOption(RawSocketOption option);

  /// Customizes the [RawSocket].
  ///
  /// See [RawSocketOption] for available options.
  ///
  /// Throws an [OSError] on failure.
  @Since("2.2")
  void setRawOption(RawSocketOption option);
}

/// A TCP connection between two sockets.
///
/// A *socket connection* connects a *local* socket to a *remote* socket.
/// Data, as [Uint8List]s, is received by the local socket, made available
/// by the [Stream] interface of this class, and can be sent to the remote
/// socket through the [IOSink] interface of this class.
abstract class Socket implements Stream<Uint8List>, IOSink {
  /// Creates a new socket connection to the host and port and returns a [Future]
  /// that will complete with either a [Socket] once connected or an error
  /// if the host-lookup or connection failed.
  ///
  /// [host] can either be a [String] or an [InternetAddress]. If [host] is a
  /// [String], [connect] will perform a [InternetAddress.lookup] and try
  /// all returned [InternetAddress]es, until connected. Unless a
  /// connection was established, the error from the first failing connection is
  /// returned.
  ///
  /// The argument [sourceAddress] can be used to specify the local
  /// address to bind when making the connection. The [sourceAddress] can either
  /// be a [String] or an [InternetAddress]. If a [String] is passed it must
  /// hold a numeric IP address.
  ///
  /// The argument [timeout] is used to specify the maximum allowed time to wait
  /// for a connection to be established. If [timeout] is longer than the system
  /// level timeout duration, a timeout may occur sooner than specified in
  /// [timeout]. On timeout, a [SocketException] is thrown and all ongoing
  /// connection attempts to [host] are cancelled.
  static Future<Socket> connect(host, int port,
      {sourceAddress, Duration? timeout}) {
    final IOOverrides? overrides = IOOverrides.current;
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
    final IOOverrides? overrides = IOOverrides.current;
    if (overrides == null) {
      return Socket._startConnect(host, port, sourceAddress: sourceAddress);
    }
    return overrides.socketStartConnect(host, port,
        sourceAddress: sourceAddress);
  }

  external static Future<Socket> _connect(host, int port,
      {sourceAddress, Duration? timeout});

  external static Future<ConnectionTask<Socket>> _startConnect(host, int port,
      {sourceAddress});

  /// Destroys the socket in both directions.
  ///
  /// Calling [destroy] will make the send a close event on the stream
  /// and will no longer react on data being piped to it.
  ///
  /// Call [close] (inherited from [IOSink]) to only close the [Socket]
  /// for sending data.
  void destroy();

  /// Customizes the [RawSocket].
  ///
  /// See [SocketOption] for available options.
  ///
  /// Returns `true` if the option was set successfully, false otherwise.
  ///
  /// Throws a [SocketException] if the socket has been destroyed or upgraded to
  /// a secure socket.
  bool setOption(SocketOption option, bool enabled);

  /// Reads low level information about the [RawSocket].
  ///
  /// See [RawSocketOption] for available options.
  ///
  /// Returns the [RawSocketOption.value] on success.
  ///
  /// Throws an [OSError] on failure and a [SocketException] if the socket has
  /// been destroyed or upgraded to a secure socket.
  Uint8List getRawOption(RawSocketOption option);

  /// Customizes the [RawSocket].
  ///
  /// See [RawSocketOption] for available options.
  ///
  /// Throws an [OSError] on failure and a [SocketException] if the socket has
  /// been destroyed or upgraded to a secure socket.
  void setRawOption(RawSocketOption option);

  /// The port used by this socket.
  ///
  /// Throws a [SocketException] if the socket is closed.
  /// The port is 0 if the socket is a Unix domain socket.
  int get port;

  /// The remote port connected to by this socket.
  ///
  /// Throws a [SocketException] if the socket is closed.
  /// The port is 0 if the socket is a Unix domain socket.
  int get remotePort;

  /// The [InternetAddress] used to connect this socket.
  ///
  /// Throws a [SocketException] if the socket is closed.
  InternetAddress get address;

  /// The remote [InternetAddress] connected to by this socket.
  ///
  /// Throws a [SocketException] if the socket is closed.
  InternetAddress get remoteAddress;

  Future close();

  Future get done;
}

/// A data packet received by a [RawDatagramSocket].
class Datagram {
  /// The actual bytes of the message.
  Uint8List data;

  /// The address of the socket which sends the data.
  InternetAddress address;

  /// The port of the socket which sends the data.
  int port;

  Datagram(this.data, this.address, this.port);
}

/// An unbuffered interface to a UDP socket.
///
/// The raw datagram socket delivers the datagrams in the same chunks as the
/// underlying operating system. It's a [Stream] of [RawSocketEvent]s.
///
/// Note that the event [RawSocketEvent.readClosed] will never be
/// received as an UDP socket cannot be closed by a remote peer.
///
/// It is not the same as a
/// [POSIX raw socket](http://man7.org/linux/man-pages/man7/raw.7.html).
abstract class RawDatagramSocket extends Stream<RawSocketEvent> {
  /// Whether the [RawDatagramSocket] should listen for
  /// [RawSocketEvent.read] events.
  ///
  /// Default is `true`.
  abstract bool readEventsEnabled;

  /// Whether the [RawDatagramSocket] should listen for
  /// [RawSocketEvent.write] events.
  ///
  /// Default is `true`.
  /// This is a one-shot listener, and [writeEventsEnabled] must be set to true
  /// again to receive another write event.
  abstract bool writeEventsEnabled;

  /// Whether multicast traffic is looped back to the host.
  ///
  /// By default multicast loopback is enabled.
  abstract bool multicastLoopback;

  /// The maximum network hops for multicast packages
  /// originating from this socket.
  ///
  /// For IPv4 this is referred to as TTL (time to live).
  ///
  /// By default this value is 1 causing multicast traffic to stay on
  /// the local network.
  abstract int multicastHops;

  /// The network interface used for outgoing multicast packages.
  ///
  /// A value of `null` indicate that the system chooses the network
  /// interface to use.
  ///
  /// By default this value is `null`
  @Deprecated("This property is not implemented. Use getRawOption and "
      "setRawOption instead.")
  NetworkInterface? multicastInterface;

  /// Whether IPv4 broadcast is enabled.
  ///
  /// IPv4 broadcast needs to be enabled by the sender for sending IPv4
  /// broadcast packages. By default IPv4 broadcast is disabled.
  ///
  /// For IPv6 there is no general broadcast mechanism. Use multicast
  /// instead.
  abstract bool broadcastEnabled;

  /// Binds a socket to the given [host] and [port].
  ///
  /// When the socket is bound and has started listening on [port], the returned
  /// future completes with the [RawDatagramSocket] of the bound socket.
  ///
  /// The [host] can either be a [String] or an [InternetAddress]. If [host] is a
  /// [String], [bind] will perform a [InternetAddress.lookup] and use the first
  /// value in the list. To listen on the loopback interface, which will allow
  /// only incoming connections from the local host, use the value
  /// [InternetAddress.loopbackIPv4] or [InternetAddress.loopbackIPv6].
  /// To allow for incoming connection from any network use either one of
  /// the values [InternetAddress.anyIPv4] or [InternetAddress.anyIPv6] to
  /// bind to all interfaces, or use the IP address of a specific interface.
  ///
  /// The [reuseAddress] should be set for all listeners that bind to the same
  /// address. Otherwise, it will fail with a [SocketException].
  ///
  /// The [reusePort] specifies whether the port can be reused.
  ///
  /// The [ttl] sets `time to live` of a datagram sent on the socket.
  external static Future<RawDatagramSocket> bind(host, int port,
      {bool reuseAddress = true, bool reusePort = false, int ttl = 1});

  /// The port used by this socket.
  int get port;

  /// The address used by this socket.
  InternetAddress get address;

  /// Closes the datagram socket.
  void close();

  /// Sends a datagram.
  ///
  /// Returns the number of bytes written. This will always be either
  /// the size of [buffer] or `0`.
  int send(List<int> buffer, InternetAddress address, int port);

  /// Receives a datagram.
  ///
  /// Returns `null` if there are no datagrams available.
  ///
  /// The maximum length of the datagram that can be received is 65503 bytes.
  Datagram? receive();

  /// Joins a multicast group.
  ///
  /// If an error occur when trying to join the multicast group, an
  /// exception is thrown.
  void joinMulticast(InternetAddress group, [NetworkInterface? interface]);

  /// Leaves a multicast group.
  ///
  /// If an error occur when trying to join the multicast group, an
  /// exception is thrown.
  void leaveMulticast(InternetAddress group, [NetworkInterface? interface]);

  /// Reads low level information about the [RawSocket].
  ///
  /// See [RawSocketOption] for available options.
  ///
  /// Returns [RawSocketOption.value] on success.
  ///
  /// Throws an [OSError] on failure.
  Uint8List getRawOption(RawSocketOption option);

  /// Customizes the [RawSocket].
  ///
  /// See [RawSocketOption] for available options.
  ///
  /// Throws an [OSError] on failure.
  void setRawOption(RawSocketOption option);
}

/// Exception thrown when a socket operation fails.
class SocketException implements IOException {
  /// Description of the error.
  final String message;

  /// The underlying OS error.
  ///
  /// If this exception is not thrown due to an OS error, the value is `null`.
  final OSError? osError;

  /// The address of the socket giving rise to the exception.
  ///
  /// This is either the source or destination address of a socket,
  /// or it can be `null` if no socket end-point was involved in the cause of
  /// the exception.
  final InternetAddress? address;

  /// The port of the socket giving rise to the exception.
  ///
  /// This is either the source or destination address of a socket,
  /// or it can be `null` if no socket end-point was involved in the cause of
  /// the exception.
  final int? port;

  /// Creates a [SocketException] with the provided values.
  const SocketException(this.message, {this.osError, this.address, this.port});

  /// Creates an exception reporting that a socket was used after it was closed.
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
      sb.write(", address = ${address!.host}");
    }
    if (port != null) {
      sb.write(", port = $port");
    }
    return sb.toString();
  }
}
