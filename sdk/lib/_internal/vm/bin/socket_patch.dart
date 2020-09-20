// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "common_patch.dart";

@patch
class RawServerSocket {
  @patch
  static Future<RawServerSocket> bind(address, int port,
      {int backlog: 0, bool v6Only: false, bool shared: false}) {
    return _RawServerSocket.bind(address, port, backlog, v6Only, shared);
  }
}

@patch
class RawSocket {
  @patch
  static Future<RawSocket> connect(dynamic host, int port,
      {dynamic sourceAddress, Duration? timeout}) {
    return _RawSocket.connect(host, port, sourceAddress, timeout);
  }

  @patch
  static Future<ConnectionTask<RawSocket>> startConnect(dynamic host, int port,
      {dynamic sourceAddress}) {
    return _RawSocket.startConnect(host, port, sourceAddress);
  }
}

@patch
class RawSocketOption {
  static final List<int?> _optionsCache =
      List<int?>.filled(_RawSocketOptions.values.length, null);

  @patch
  static int _getOptionValue(int key) {
    if (key > _RawSocketOptions.values.length) {
      throw ArgumentError.value(key, 'key');
    }
    return _optionsCache[key] ??= _getNativeOptionValue(key);
  }

  static int _getNativeOptionValue(int key)
      native "RawSocketOption_GetOptionValue";
}

@patch
class InternetAddress {
  @patch
  static InternetAddress get LOOPBACK_IP_V4 {
    return _InternetAddress.loopbackIPv4;
  }

  @patch
  static InternetAddress get LOOPBACK_IP_V6 {
    return _InternetAddress.loopbackIPv6;
  }

  @patch
  static InternetAddress get ANY_IP_V4 {
    return _InternetAddress.anyIPv4;
  }

  @patch
  static InternetAddress get ANY_IP_V6 {
    return _InternetAddress.anyIPv6;
  }

  @patch
  factory InternetAddress(String address, {InternetAddressType? type}) {
    return _InternetAddress.fromString(address, type: type);
  }

  @patch
  factory InternetAddress.fromRawAddress(Uint8List rawAddress,
      {InternetAddressType? type}) {
    return _InternetAddress.fromRawAddress(rawAddress, type: type);
  }

  @patch
  static Future<List<InternetAddress>> lookup(String host,
      {InternetAddressType type: InternetAddressType.any}) {
    return _NativeSocket.lookup(host, type: type);
  }

  @patch
  static InternetAddress _cloneWithNewHost(
      InternetAddress address, String host) {
    return (address as _InternetAddress)._cloneWithNewHost(host);
  }

  @patch
  static InternetAddress? tryParse(String address) {
    return _InternetAddress.tryParse(address);
  }
}

@patch
class NetworkInterface {
  @patch
  static bool get listSupported {
    return _listSupported();
  }

  @patch
  static Future<List<NetworkInterface>> list(
      {bool includeLoopback: false,
      bool includeLinkLocal: false,
      InternetAddressType type: InternetAddressType.any}) {
    return _NativeSocket.listInterfaces(
        includeLoopback: includeLoopback,
        includeLinkLocal: includeLinkLocal,
        type: type);
  }

  static bool _listSupported() native "NetworkInterface_ListSupported";
}

void _throwOnBadPort(int port) {
  // TODO(40614): Remove once non-nullability is sound.
  ArgumentError.checkNotNull(port, "port");
  if ((port < 0) || (port > 0xFFFF)) {
    throw new ArgumentError("Invalid port $port");
  }
}

void _throwOnBadTtl(int ttl) {
  // TODO(40614): Remove once non-nullability is sound.
  ArgumentError.checkNotNull(ttl, "ttl");
  if (ttl < 1 || ttl > 255) {
    throw new ArgumentError('Invalid ttl $ttl');
  }
}

class _InternetAddress implements InternetAddress {
  static const int _addressLoopbackIPv4 = 0;
  static const int _addressLoopbackIPv6 = 1;
  static const int _addressAnyIPv4 = 2;
  static const int _addressAnyIPv6 = 3;
  static const int _IPv4AddrLength = 4;
  static const int _IPv6AddrLength = 16;

  static _InternetAddress loopbackIPv4 =
      _InternetAddress.fixed(_addressLoopbackIPv4);
  static _InternetAddress loopbackIPv6 =
      _InternetAddress.fixed(_addressLoopbackIPv6);
  static _InternetAddress anyIPv4 = _InternetAddress.fixed(_addressAnyIPv4);
  static _InternetAddress anyIPv6 = _InternetAddress.fixed(_addressAnyIPv6);

  final String address;
  final String? _host;
  final Uint8List _in_addr;
  final int _scope_id;
  final InternetAddressType type;

  String get host => _host ?? address;

  Uint8List get rawAddress => new Uint8List.fromList(_in_addr);

  bool get isLoopback {
    switch (type) {
      case InternetAddressType.IPv4:
        return _in_addr[0] == 127;

      case InternetAddressType.IPv6:
        for (int i = 0; i < _IPv6AddrLength - 1; i++) {
          if (_in_addr[i] != 0) return false;
        }
        return _in_addr[_IPv6AddrLength - 1] == 1;

      case InternetAddressType.unix:
        return false;
    }
    throw new UnsupportedError("Unexpected address type $type");
  }

  bool get isLinkLocal {
    switch (type) {
      case InternetAddressType.IPv4:
        // Checking for 169.254.0.0/16.
        return _in_addr[0] == 169 && _in_addr[1] == 254;

      case InternetAddressType.IPv6:
        // Checking for fe80::/10.
        return _in_addr[0] == 0xFE && (_in_addr[1] & 0xB0) == 0x80;

      case InternetAddressType.unix:
        return false;
    }
    throw new UnsupportedError("Unexpected address type $type");
  }

  bool get isMulticast {
    switch (type) {
      case InternetAddressType.IPv4:
        // Checking for 224.0.0.0 through 239.255.255.255.
        return _in_addr[0] >= 224 && _in_addr[0] < 240;

      case InternetAddressType.IPv6:
        // Checking for ff00::/8.
        return _in_addr[0] == 0xFF;

      case InternetAddressType.unix:
        return false;
    }
    throw new UnsupportedError("Unexpected address type $type");
  }

  Future<InternetAddress> reverse() {
    if (type == InternetAddressType.unix) {
      return Future.value(this);
    }
    return _NativeSocket.reverseLookup(this);
  }

  _InternetAddress(this.type, this.address, this._host, this._in_addr,
      [this._scope_id = 0]);

  factory _InternetAddress.fromString(String address,
      {InternetAddressType? type}) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(address, 'address');
    if (type == InternetAddressType.unix) {
      var rawAddress = FileSystemEntity._toUtf8Array(address);
      return _InternetAddress(
          InternetAddressType.unix, address, null, rawAddress);
    } else {
      int index = address.indexOf('%');
      String originalAddress = address;
      String? scopeID;
      if (index > 0) {
        scopeID = address.substring(index, address.length);
        address = address.substring(0, index);
      }
      var inAddr = _parse(address);
      if (inAddr == null) {
        throw ArgumentError('Invalid internet address $address');
      }
      InternetAddressType type = inAddr.length == _IPv4AddrLength
          ? InternetAddressType.IPv4
          : InternetAddressType.IPv6;
      if (scopeID != null && scopeID.length > 0) {
        if (type != InternetAddressType.IPv6) {
          throw ArgumentError.value(
              address, 'address', 'IPv4 addresses cannot have a scope ID');
        }

        final scopeID = _parseScopedLinkLocalAddress(originalAddress);

        if (scopeID is int) {
          return _InternetAddress(
              InternetAddressType.IPv6, originalAddress, null, inAddr, scopeID);
        } else {
          throw ArgumentError.value(
              address, 'address', 'Invalid IPv6 address with scope ID');
        }
      }
      return _InternetAddress(type, originalAddress, null, inAddr, 0);
    }
  }

  factory _InternetAddress.fromRawAddress(Uint8List rawAddress,
      {InternetAddressType? type}) {
    if (type == InternetAddressType.unix) {
      ArgumentError.checkNotNull(rawAddress, 'rawAddress');
      var rawPath = FileSystemEntity._toNullTerminatedUtf8Array(rawAddress);
      var address = FileSystemEntity._toStringFromUtf8Array(rawAddress);
      return _InternetAddress(InternetAddressType.unix, address, null, rawPath);
    } else {
      int type = -1;
      if (rawAddress.length == _IPv4AddrLength) {
        type = 0;
      } else {
        if (rawAddress.length != _IPv6AddrLength) {
          throw ArgumentError("Invalid internet address ${rawAddress}");
        }
        type = 1;
      }
      var address = _rawAddrToString(rawAddress);
      return _InternetAddress(
          InternetAddressType._from(type), address, null, rawAddress);
    }
  }

  static _InternetAddress? tryParse(String address) {
    checkNotNullable(address, "address");
    try {
      return _InternetAddress.fromString(address);
    } on ArgumentError catch (_) {
      return null;
    }
  }

  factory _InternetAddress.fixed(int id) {
    switch (id) {
      case _addressLoopbackIPv4:
        var in_addr = Uint8List(_IPv4AddrLength);
        in_addr[0] = 127;
        in_addr[_IPv4AddrLength - 1] = 1;
        return _InternetAddress(
            InternetAddressType.IPv4, "127.0.0.1", null, in_addr);
      case _addressLoopbackIPv6:
        var in_addr = Uint8List(_IPv6AddrLength);
        in_addr[_IPv6AddrLength - 1] = 1;
        return _InternetAddress(InternetAddressType.IPv6, "::1", null, in_addr);
      case _addressAnyIPv4:
        var in_addr = Uint8List(_IPv4AddrLength);
        return _InternetAddress(
            InternetAddressType.IPv4, "0.0.0.0", "0.0.0.0", in_addr);
      case _addressAnyIPv6:
        var in_addr = Uint8List(_IPv6AddrLength);
        return _InternetAddress(InternetAddressType.IPv6, "::", "::", in_addr);
      default:
        assert(false);
        throw ArgumentError();
    }
  }

  // Create a clone of this _InternetAddress replacing the host.
  _InternetAddress _cloneWithNewHost(String host) {
    return _InternetAddress(
        type, address, host, Uint8List.fromList(_in_addr), _scope_id);
  }

  bool operator ==(other) {
    if (!(other is _InternetAddress)) return false;
    if (other.type != type) return false;
    if (type == InternetAddressType.unix) {
      return address == other.address;
    }
    bool equals = true;
    for (int i = 0; i < _in_addr.length && equals; i++) {
      equals = other._in_addr[i] == _in_addr[i];
    }
    return equals;
  }

  int get hashCode {
    if (type == InternetAddressType.unix) {
      return address.hashCode;
    }
    int result = 1;
    for (int i = 0; i < _in_addr.length; i++) {
      result = (result * 31 + _in_addr[i]) & 0x3FFFFFFF;
    }
    return result;
  }

  String toString() {
    return "InternetAddress('$address', ${type.name})";
  }

  static String _rawAddrToString(Uint8List address)
      native "InternetAddress_RawAddrToString";
  static dynamic /* int | OSError */ _parseScopedLinkLocalAddress(
      String address) native "InternetAddress_ParseScopedLinkLocalAddress";
  static Uint8List? _parse(String address) native "InternetAddress_Parse";
}

class _NetworkInterface implements NetworkInterface {
  final String name;
  final int index;
  final List<InternetAddress> addresses = [];

  _NetworkInterface(this.name, this.index);

  String toString() {
    return "NetworkInterface('$name', $addresses)";
  }
}

// The NativeFieldWrapperClass1 cannot be used with a mixin, due to missing
// implicit constructor.
class _NativeSocketNativeWrapper extends NativeFieldWrapperClass1 {}

// The _NativeSocket class encapsulates an OS socket.
class _NativeSocket extends _NativeSocketNativeWrapper with _ServiceObject {
  // Bit flags used when communicating between the eventhandler and
  // dart code. The EVENT flags are used to indicate events of
  // interest when sending a message from dart code to the
  // eventhandler. When receiving a message from the eventhandler the
  // EVENT flags indicate the events that actually happened. The
  // COMMAND flags are used to send commands from dart to the
  // eventhandler. COMMAND flags are never received from the
  // eventhandler. Additional flags are used to communicate other
  // information.
  static const int readEvent = 0;
  static const int writeEvent = 1;
  static const int errorEvent = 2;
  static const int closedEvent = 3;
  static const int destroyedEvent = 4;
  static const int firstEvent = readEvent;
  static const int lastEvent = destroyedEvent;
  static const int eventCount = lastEvent - firstEvent + 1;

  static const int closeCommand = 8;
  static const int shutdownReadCommand = 9;
  static const int shutdownWriteCommand = 10;
  // The lower bits of returnTokenCommand messages contains the number
  // of tokens returned.
  static const int returnTokenCommand = 11;
  static const int setEventMaskCommand = 12;
  static const int firstCommand = closeCommand;
  static const int lastCommand = setEventMaskCommand;

  // Type flag send to the eventhandler providing additional
  // information on the type of the file descriptor.
  static const int listeningSocket = 16;
  static const int pipeSocket = 17;
  static const int typeNormalSocket = 0;
  static const int typeListeningSocket = 1 << listeningSocket;
  static const int typePipe = 1 << pipeSocket;
  static const int typeTypeMask = typeListeningSocket | pipeSocket;

  // Protocol flags.
  // Keep in sync with SocketType enum in socket.h.
  static const int tcpSocket = 18;
  static const int udpSocket = 19;
  static const int internalSocket = 20;
  static const int internalSignalSocket = 21;
  static const int typeTcpSocket = 1 << tcpSocket;
  static const int typeUdpSocket = 1 << udpSocket;
  static const int typeInternalSocket = 1 << internalSocket;
  static const int typeInternalSignalSocket = 1 << internalSignalSocket;
  static const int typeProtocolMask = typeTcpSocket |
      typeUdpSocket |
      typeInternalSocket |
      typeInternalSignalSocket;

  // Native port messages.
  static const hostNameLookupMessage = 0;
  static const listInterfacesMessage = 1;
  static const reverseLookupMessage = 2;

  // Protocol flags.
  static const int protocolIPv4 = 1 << 0;
  static const int protocolIPv6 = 1 << 1;

  static const int normalTokenBatchSize = 8;
  static const int listeningTokenBatchSize = 2;

  static const Duration _retryDuration = const Duration(milliseconds: 250);
  static const Duration _retryDurationLoopback =
      const Duration(milliseconds: 25);

  // Socket close state
  bool isClosed = false;
  bool isClosing = false;
  bool isClosedRead = false;
  bool closedReadEventSent = false;
  bool isClosedWrite = false;
  Completer closeCompleter = new Completer.sync();

  // Handlers and receive port for socket events from the event handler.
  final List eventHandlers = new List.filled(eventCount + 1, null);
  RawReceivePort? eventPort;
  bool flagsSent = false;

  // The type flags for this socket.
  final int typeFlags;

  // Holds the port of the socket, 0 if not known.
  int localPort = 0;

  // Holds the address used to connect or bind the socket.
  late InternetAddress localAddress;

  // The size of data that is ready to be read, for TCP sockets.
  // This might be out-of-date when Read is called.
  // The number of pending connections, for Listening sockets.
  int available = 0;

  // Only used for UDP sockets.
  bool _availableDatagram = false;

  // The number of incoming connnections for Listening socket.
  int connections = 0;

  // The count of received event from eventhandler.
  int tokens = 0;

  bool sendReadEvents = false;
  bool readEventIssued = false;

  bool sendWriteEvents = false;
  bool writeEventIssued = false;
  bool writeAvailable = false;

  // The owner object is the object that the Socket is being used by, e.g.
  // a HttpServer, a WebSocket connection, a process pipe, etc.
  Object? owner;

  static Future<List<InternetAddress>> lookup(String host,
      {InternetAddressType type: InternetAddressType.any}) {
    return _IOService._dispatch(_IOService.socketLookup, [host, type._value])
        .then((response) {
      if (isErrorResponse(response)) {
        throw createError(response, "Failed host lookup: '$host'");
      } else {
        return response.skip(1).map<InternetAddress>((result) {
          var type = InternetAddressType._from(result[0]);
          return _InternetAddress(type, result[1], host, result[2], result[3]);
        }).toList();
      }
    });
  }

  static Future<InternetAddress> reverseLookup(InternetAddress addr) {
    return _IOService._dispatch(_IOService.socketReverseLookup,
        [(addr as _InternetAddress)._in_addr]).then((response) {
      if (isErrorResponse(response)) {
        throw createError(response, "Failed reverse host lookup", addr);
      } else {
        return (addr as _InternetAddress)._cloneWithNewHost(response);
      }
    });
  }

  static Future<List<NetworkInterface>> listInterfaces(
      {bool includeLoopback: false,
      bool includeLinkLocal: false,
      InternetAddressType type: InternetAddressType.any}) {
    return _IOService._dispatch(_IOService.socketListInterfaces, [type._value])
        .then((response) {
      if (isErrorResponse(response)) {
        throw createError(response, "Failed listing interfaces");
      } else {
        var map = response.skip(1).fold(new Map<String, NetworkInterface>(),
            (map, result) {
          var type = InternetAddressType._from(result[0]);
          var name = result[3];
          var index = result[4];
          var address = _InternetAddress(type, result[1], "", result[2]);
          if (!includeLinkLocal && address.isLinkLocal) return map;
          if (!includeLoopback && address.isLoopback) return map;
          map.putIfAbsent(name, () => new _NetworkInterface(name, index));
          map[name].addresses.add(address);
          return map;
        });
        return map.values.toList();
      }
    });
  }

  static String escapeLinkLocalAddress(String host) {
    // if the host contains escape, host is an IPv6 address with scope ID.
    // Remove '25' before feeding into native calls.
    int index = host.indexOf('%');
    if (index >= 0) {
      if (!checkLinkLocalAddress(host)) {
        // The only well defined usage is link-local address. Checks Section 4 of https://tools.ietf.org/html/rfc6874.
        // If it is not a valid link-local address and contains escape character, throw an exception.
        throw new FormatException(
            '${host} is not a valid link-local address but contains %. Scope id should be used as part of link-local address.',
            host,
            index);
      }
      if (host.startsWith("25", index + 1)) {
        // Remove '25' after '%' if present
        host = host.replaceRange(index + 1, index + 3, '');
      }
    }
    return host;
  }

  static bool checkLinkLocalAddress(String host) {
    // The shortest possible link-local address is [fe80::1]
    if (host.length < 7) return false;
    var char = host[2];
    return host.startsWith('fe') &&
        (char == '8' || char == '9' || char == 'a' || char == 'b');
  }

  static Future<ConnectionTask<_NativeSocket>> startConnect(
      dynamic host, int port, dynamic sourceAddress) {
    if (host is String) {
      host = escapeLinkLocalAddress(host);
    }
    _throwOnBadPort(port);
    if (sourceAddress != null && sourceAddress is! _InternetAddress) {
      if (sourceAddress is String) {
        sourceAddress = new InternetAddress(sourceAddress);
      }
    }
    return new Future.value(host).then((host) {
      if (host is _InternetAddress) return [host];
      return lookup(host).then((addresses) {
        if (addresses.isEmpty) {
          throw createError(null, "Failed host lookup: '$host'");
        }
        return addresses;
      });
    }).then((addresses) {
      var completer = new Completer<_NativeSocket>();
      var it = (addresses as List<InternetAddress>).iterator;
      var error = null;
      var connecting = new HashMap();

      void connectNext() {
        if (!it.moveNext()) {
          if (connecting.isEmpty) {
            assert(error != null);
            completer.completeError(error);
          }
          return;
        }
        final _InternetAddress address = it.current as _InternetAddress;
        var socket = new _NativeSocket.normal(address);
        var result;
        if (sourceAddress == null) {
          if (address.type == InternetAddressType.unix) {
            result = socket.nativeCreateUnixDomainConnect(
                address.address, _Namespace._namespace);
          } else {
            result = socket.nativeCreateConnect(
                address._in_addr, port, address._scope_id);
          }
        } else {
          assert(sourceAddress is _InternetAddress);
          if (address.type == InternetAddressType.unix) {
            assert(sourceAddress.type == InternetAddressType.unix);
            result = socket.nativeCreateUnixDomainBindConnect(
                address.address, sourceAddress.address, _Namespace._namespace);
          } else {
            result = socket.nativeCreateBindConnect(address._in_addr, port,
                sourceAddress._in_addr, address._scope_id);
          }
        }
        if (result is OSError) {
          // Keep first error, if present.
          if (error == null) {
            int errorCode = result.errorCode;
            if (sourceAddress != null &&
                errorCode != null &&
                socket.isBindError(errorCode)) {
              error = createError(result, "Bind failed", sourceAddress);
            } else {
              error = createError(result, "Connection failed", address, port);
            }
          }
          connectNext();
        } else {
          // Query the local port for error messages.
          try {
            socket.port;
          } catch (e) {
            if (error == null) {
              error = createError(e, "Connection failed", address, port);
            }
            connectNext();
          }
          // Set up timer for when we should retry the next address
          // (if any).
          var duration =
              address.isLoopback ? _retryDurationLoopback : _retryDuration;
          var timer = new Timer(duration, connectNext);

          connecting[socket] = timer;
          // Setup handlers for receiving the first write event which
          // indicate that the socket is fully connected.
          socket.setHandlers(write: () {
            timer.cancel();
            connecting.remove(socket);
            // From 'man 2 connect':
            // After select(2) indicates writability, use getsockopt(2) to read
            // the SO_ERROR option at level SOL_SOCKET to determine whether
            // connect() completed successfully (SO_ERROR is zero) or
            // unsuccessfully.
            OSError osError = socket.nativeGetError();
            if (osError.errorCode != 0) {
              socket.close();
              if (error == null) error = osError;
              if (connecting.isEmpty) connectNext();
              return;
            }
            socket.setListening(read: false, write: false);
            completer.complete(socket);
            connecting.forEach((s, t) {
              t.cancel();
              s.close();
              s.setHandlers();
              s.setListening(read: false, write: false);
            });
            connecting.clear();
          }, error: (e, st) {
            timer.cancel();
            socket.close();
            // Keep first error, if present.
            if (error == null) error = e;
            connecting.remove(socket);
            if (connecting.isEmpty) connectNext();
          });
          socket.setListening(read: false, write: true);
        }
      }

      void onCancel() {
        connecting.forEach((s, t) {
          t.cancel();
          s.close();
          s.setHandlers();
          s.setListening(read: false, write: false);
          if (error == null) {
            error = createError(null,
                "Connection attempt cancelled, host: ${host}, port: ${port}");
          }
        });
        connecting.clear();
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      }

      connectNext();
      return new ConnectionTask<_NativeSocket>._(completer.future, onCancel);
    });
  }

  static Future<_NativeSocket> connect(
      dynamic host, int port, dynamic sourceAddress, Duration? timeout) {
    return startConnect(host, port, sourceAddress)
        .then((ConnectionTask<_NativeSocket> task) {
      Future<_NativeSocket> socketFuture = task.socket;
      if (timeout != null) {
        socketFuture = socketFuture.timeout(timeout, onTimeout: () {
          task.cancel();
          throw createError(
              null, "Connection timed out, host: ${host}, port: ${port}");
        });
      }
      return socketFuture;
    });
  }

  static Future<_InternetAddress> _resolveHost(dynamic host) async {
    if (host is _InternetAddress) {
      return host;
    } else {
      final list = await lookup(host);
      if (list.isEmpty) {
        throw createError(null, "Failed host lookup: '$host'");
      }
      return list.first as _InternetAddress;
    }
  }

  static Future<_NativeSocket> bind(
      host, int port, int backlog, bool v6Only, bool shared) async {
    _throwOnBadPort(port);
    if (host is String) {
      host = escapeLinkLocalAddress(host);
    }
    final address = await _resolveHost(host);

    var socket = new _NativeSocket.listen(address);
    var result;
    if (address.type == InternetAddressType.unix) {
      var path = address.address;
      if (FileSystemEntity.isLinkSync(path)) {
        path = Link(path).targetSync();
      }
      result = socket.nativeCreateUnixDomainBindListen(
          path, backlog, shared, _Namespace._namespace);
    } else {
      result = socket.nativeCreateBindListen(
          address._in_addr, port, backlog, v6Only, shared, address._scope_id);
    }
    if (result is OSError) {
      throw new SocketException("Failed to create server socket",
          osError: result, address: address, port: port);
    }
    if (port != 0) socket.localPort = port;
    socket.connectToEventHandler();
    return socket;
  }

  static Future<_NativeSocket> bindDatagram(
      host, int port, bool reuseAddress, bool reusePort, int ttl) async {
    _throwOnBadPort(port);
    _throwOnBadTtl(ttl);

    final address = await _resolveHost(host);

    var socket = new _NativeSocket.datagram(address);
    var result = socket.nativeCreateBindDatagram(
        address._in_addr, port, reuseAddress, reusePort, ttl);
    if (result is OSError) {
      throw new SocketException("Failed to create datagram socket",
          osError: result, address: address, port: port);
    }
    if (port != 0) socket.localPort = port;
    return socket;
  }

  _NativeSocket.datagram(this.localAddress)
      : typeFlags = typeNormalSocket | typeUdpSocket;

  _NativeSocket.normal(this.localAddress)
      : typeFlags = typeNormalSocket | typeTcpSocket;

  _NativeSocket.listen(this.localAddress)
      : typeFlags = typeListeningSocket | typeTcpSocket {
    isClosedWrite = true;
  }

  _NativeSocket.pipe() : typeFlags = typePipe;

  _NativeSocket._watchCommon(int id, int type)
      : typeFlags = typeNormalSocket | type {
    isClosedWrite = true;
    nativeSetSocketId(id, typeFlags);
  }

  _NativeSocket.watchSignal(int id)
      : this._watchCommon(id, typeInternalSignalSocket);

  _NativeSocket.watch(int id) : this._watchCommon(id, typeInternalSocket);

  bool get isListening => (typeFlags & typeListeningSocket) != 0;
  bool get isPipe => (typeFlags & typePipe) != 0;
  bool get isInternal => (typeFlags & typeInternalSocket) != 0;
  bool get isInternalSignal => (typeFlags & typeInternalSignalSocket) != 0;
  bool get isTcp => (typeFlags & typeTcpSocket) != 0;
  bool get isUdp => (typeFlags & typeUdpSocket) != 0;

  Map _toJSON(bool ref) => throw new UnimplementedError();
  String get _serviceTypePath => throw new UnimplementedError();
  String get _serviceTypeName => throw new UnimplementedError();

  Uint8List? read(int? count) {
    if (count != null && count <= 0) {
      throw ArgumentError("Illegal length $count");
    }
    if (isClosing || isClosed) return null;
    try {
      Uint8List? list;
      if (count != null) {
        list = nativeRead(count);
        available = nativeAvailable();
      } else {
        // If count is null, read as many bytes as possible.
        // Loop here to ensure bytes that arrived while this read was
        // issued are also read.
        BytesBuilder builder = BytesBuilder();
        do {
          assert(available > 0);
          list = nativeRead(available);
          if (list == null) {
            break;
          }
          builder.add(list);
          available = nativeAvailable();
        } while (available > 0);
        if (builder.isEmpty) {
          list = null;
        } else {
          list = builder.toBytes();
        }
      }
      if (!const bool.fromEnvironment("dart.vm.product")) {
        _SocketProfile.collectStatistic(
            nativeGetSocketId(), _SocketProfileType.readBytes, list?.length);
      }
      return list;
    } catch (e) {
      reportError(e, StackTrace.current, "Read failed");
      return null;
    }
  }

  Datagram? receive() {
    if (isClosing || isClosed) return null;
    try {
      Datagram? result = nativeRecvFrom();
      if (!const bool.fromEnvironment("dart.vm.product")) {
        _SocketProfile.collectStatistic(nativeGetSocketId(),
            _SocketProfileType.readBytes, result?.data.length);
      }
      _availableDatagram = nativeAvailableDatagram();
      return result;
    } catch (e) {
      reportError(e, StackTrace.current, "Receive failed");
      return null;
    }
  }

  static int _fixOffset(int? offset) => offset ?? 0;

  int write(List<int> buffer, int offset, int? bytes) {
    // TODO(40614): Remove once non-nullability is sound.
    offset = _fixOffset(offset);
    if (bytes == null) {
      if (offset > buffer.length) {
        throw new RangeError.value(offset);
      }
      bytes = buffer.length - offset;
    }
    if (offset < 0) throw new RangeError.value(offset);
    if (bytes < 0) throw new RangeError.value(bytes);
    if ((offset + bytes) > buffer.length) {
      throw new RangeError.value(offset + bytes);
    }
    if (isClosing || isClosed) return 0;
    if (bytes == 0) return 0;
    try {
      _BufferAndStart bufferAndStart =
          _ensureFastAndSerializableByteData(buffer, offset, offset + bytes);
      if (!const bool.fromEnvironment("dart.vm.product")) {
        _SocketProfile.collectStatistic(
            nativeGetSocketId(),
            _SocketProfileType.writeBytes,
            bufferAndStart.buffer.length - bufferAndStart.start);
      }
      int result =
          nativeWrite(bufferAndStart.buffer, bufferAndStart.start, bytes);
      // The result may be negative, if we forced a short write for testing
      // purpose. In such case, don't mark writeAvailable as false, as we don't
      // know if we'll receive an event. It's better to just retry.
      if (result >= 0 && result < bytes) {
        writeAvailable = false;
      }
      // Negate the result, as stated above.
      if (result < 0) result = -result;
      return result;
    } catch (e) {
      StackTrace st = StackTrace.current;
      scheduleMicrotask(() => reportError(e, st, "Write failed"));
      return 0;
    }
  }

  int send(List<int> buffer, int offset, int bytes, InternetAddress address,
      int port) {
    _throwOnBadPort(port);
    if (isClosing || isClosed) return 0;
    try {
      _BufferAndStart bufferAndStart =
          _ensureFastAndSerializableByteData(buffer, offset, bytes);
      if (!const bool.fromEnvironment("dart.vm.product")) {
        _SocketProfile.collectStatistic(
            nativeGetSocketId(),
            _SocketProfileType.writeBytes,
            bufferAndStart.buffer.length - bufferAndStart.start);
      }
      int result = nativeSendTo(bufferAndStart.buffer, bufferAndStart.start,
          bytes, (address as _InternetAddress)._in_addr, port);
      return result;
    } catch (e) {
      StackTrace st = StackTrace.current;
      scheduleMicrotask(() => reportError(e, st, "Send failed"));
      return 0;
    }
  }

  _NativeSocket? accept() {
    // Don't issue accept if we're closing.
    if (isClosing || isClosed) return null;
    assert(connections > 0);
    connections--;
    tokens++;
    returnTokens(listeningTokenBatchSize);
    var socket = new _NativeSocket.normal(address);
    if (nativeAccept(socket) != true) return null;
    socket.localPort = localPort;
    return socket;
  }

  int get port {
    if (localAddress.type == InternetAddressType.unix) return 0;
    if (localPort != 0) return localPort;
    if (isClosing || isClosed) throw const SocketException.closed();
    return localPort = nativeGetPort();
  }

  int get remotePort {
    if (localAddress.type == InternetAddressType.unix) return 0;
    if (isClosing || isClosed) throw const SocketException.closed();
    return nativeGetRemotePeer()[1];
  }

  InternetAddress get address => localAddress;

  InternetAddress get remoteAddress {
    if (isClosing || isClosed) throw const SocketException.closed();
    var result = nativeGetRemotePeer();
    var addr = result[0];
    var type = new InternetAddressType._from(addr[0]);
    if (type == InternetAddressType.unix) {
      return _InternetAddress.fromString(addr[1],
          type: InternetAddressType.unix);
    }
    return _InternetAddress(type, addr[1], null, addr[2]);
  }

  void issueReadEvent() {
    if (closedReadEventSent) return;
    if (readEventIssued) return;
    readEventIssued = true;
    void issue() {
      readEventIssued = false;
      if (isClosing) return;
      if (!sendReadEvents) return;
      if (stopRead()) {
        if (isClosedRead && !closedReadEventSent) {
          if (isClosedWrite) close();
          var handler = eventHandlers[closedEvent];
          if (handler == null) return;
          closedReadEventSent = true;
          handler();
        }
        return;
      }
      var handler = eventHandlers[readEvent];
      if (handler == null) return;
      readEventIssued = true;
      handler();
      scheduleMicrotask(issue);
    }

    scheduleMicrotask(issue);
  }

  bool stopRead() {
    if (isUdp) {
      return !_availableDatagram;
    } else {
      return available == 0;
    }
  }

  void issueWriteEvent({bool delayed: true}) {
    if (writeEventIssued) return;
    if (!writeAvailable) return;
    void issue() {
      writeEventIssued = false;
      if (!writeAvailable) return;
      if (isClosing) return;
      if (!sendWriteEvents) return;
      sendWriteEvents = false;
      var handler = eventHandlers[writeEvent];
      if (handler == null) return;
      handler();
    }

    if (delayed) {
      writeEventIssued = true;
      scheduleMicrotask(issue);
    } else {
      issue();
    }
  }

  // Multiplexes socket events to the socket handlers.
  void multiplex(Object eventsObj) {
    // TODO(paulberry): when issue #31305 is fixed, we should be able to simply
    // declare `events` as a `covariant int` parameter.
    int events = eventsObj as int;
    for (int i = firstEvent; i <= lastEvent; i++) {
      if (((events & (1 << i)) != 0)) {
        if ((i == closedEvent || i == readEvent) && isClosedRead) continue;
        if (isClosing && i != destroyedEvent) continue;
        if (i == closedEvent && !isListening && !isClosing && !isClosed) {
          isClosedRead = true;
          issueReadEvent();
          continue;
        }

        if (i == writeEvent) {
          writeAvailable = true;
          issueWriteEvent(delayed: false);
          continue;
        }

        if (i == readEvent) {
          if (isListening) {
            connections++;
          } else {
            if (isUdp) {
              _availableDatagram = nativeAvailableDatagram();
            } else {
              available = nativeAvailable();
            }
            issueReadEvent();
            continue;
          }
        }

        var handler = eventHandlers[i];
        if (i == destroyedEvent) {
          assert(isClosing);
          assert(!isClosed);
          isClosed = true;
          closeCompleter.complete();
          disconnectFromEventHandler();
          if (handler != null) handler();
          continue;
        }

        if (i == errorEvent) {
          if (!isClosing) {
            reportError(nativeGetError(), null, "");
          }
        } else if (!isClosed) {
          // If the connection is closed right after it's accepted, there's a
          // chance the close-handler is not set.
          if (handler != null) handler();
        }
      }
    }
    if (!isListening) {
      tokens++;
      returnTokens(normalTokenBatchSize);
    }
  }

  void returnTokens(int tokenBatchSize) {
    if (!isClosing && !isClosed) {
      assert(eventPort != null);
      // Return in batches.
      if (tokens == tokenBatchSize) {
        assert(tokens < (1 << firstCommand));
        sendToEventHandler((1 << returnTokenCommand) | tokens);
        tokens = 0;
      }
    }
  }

  void setHandlers({read, write, error, closed, destroyed}) {
    eventHandlers[readEvent] = read;
    eventHandlers[writeEvent] = write;
    eventHandlers[errorEvent] = error;
    eventHandlers[closedEvent] = closed;
    eventHandlers[destroyedEvent] = destroyed;
  }

  void setListening({bool read: true, bool write: true}) {
    sendReadEvents = read;
    sendWriteEvents = write;
    if (read) issueReadEvent();
    if (write) issueWriteEvent();
    if (!flagsSent && !isClosing) {
      flagsSent = true;
      int flags = 1 << setEventMaskCommand;
      if (!isClosedRead) flags |= 1 << readEvent;
      if (!isClosedWrite) flags |= 1 << writeEvent;
      sendToEventHandler(flags);
    }
  }

  Future close() {
    if (!isClosing && !isClosed) {
      sendToEventHandler(1 << closeCommand);
      isClosing = true;
    }
    return closeCompleter.future;
  }

  void shutdown(SocketDirection direction) {
    if (!isClosing && !isClosed) {
      switch (direction) {
        case SocketDirection.receive:
          shutdownRead();
          break;
        case SocketDirection.send:
          shutdownWrite();
          break;
        case SocketDirection.both:
          close();
          break;
        default:
          throw new ArgumentError(direction);
      }
    }
  }

  void shutdownWrite() {
    if (!isClosing && !isClosed) {
      if (closedReadEventSent) {
        close();
      } else {
        sendToEventHandler(1 << shutdownWriteCommand);
      }
      isClosedWrite = true;
    }
  }

  void shutdownRead() {
    if (!isClosing && !isClosed) {
      if (isClosedWrite) {
        close();
      } else {
        sendToEventHandler(1 << shutdownReadCommand);
      }
      isClosedRead = true;
    }
  }

  void sendToEventHandler(int data) {
    int fullData = (typeFlags & typeTypeMask) | data;
    assert(!isClosing);
    connectToEventHandler();
    _EventHandler._sendData(this, eventPort!.sendPort, fullData);
  }

  void connectToEventHandler() {
    assert(!isClosed);
    if (eventPort == null) {
      eventPort = new RawReceivePort(multiplex);
    }
  }

  void disconnectFromEventHandler() {
    eventPort!.close();
    eventPort = null;
    // Now that we don't track this Socket anymore, we can clear the owner
    // field.
    owner = null;
  }

  // Check whether this is an error response from a native port call.
  static bool isErrorResponse(response) {
    return response is List && response[0] != _successResponse;
  }

  // Create the appropriate error/exception from different returned
  // error objects.
  static createError(error, String message,
      [InternetAddress? address, int? port]) {
    if (error is OSError) {
      return new SocketException(message,
          osError: error, address: address, port: port);
    } else if (error is List) {
      assert(isErrorResponse(error));
      switch (error[0]) {
        case _illegalArgumentResponse:
          return new ArgumentError();
        case _osErrorResponse:
          return new SocketException(message,
              osError: new OSError(error[2], error[1]),
              address: address,
              port: port);
        default:
          return new Exception("Unknown error");
      }
    } else {
      return new SocketException(message, address: address, port: port);
    }
  }

  void reportError(error, StackTrace? st, String message) {
    var e =
        createError(error, message, isUdp || isTcp ? address : null, localPort);
    // Invoke the error handler if any.
    if (eventHandlers[errorEvent] != null) {
      eventHandlers[errorEvent](e, st);
    }
    // For all errors we close the socket
    close();
  }

  dynamic getOption(SocketOption option) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(option, "option");
    var result = nativeGetOption(option._value, address.type._value);
    if (result is OSError) throw result;
    return result;
  }

  bool setOption(SocketOption option, value) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(option, "option");
    nativeSetOption(option._value, address.type._value, value);
    return true;
  }

  Uint8List getRawOption(RawSocketOption option) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(option, "option");
    ArgumentError.checkNotNull(option.value, "option.value");
    nativeGetRawOption(option.level, option.option, option.value);
    return option.value;
  }

  void setRawOption(RawSocketOption option) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(option, "option");
    ArgumentError.checkNotNull(option.value, "option.value");
    nativeSetRawOption(option.level, option.option, option.value);
  }

  InternetAddress? multicastAddress(
      InternetAddress addr, NetworkInterface? interface) {
    // On Mac OS using the interface index for joining IPv4 multicast groups
    // is not supported. Here the IP address of the interface is needed.
    if (Platform.isMacOS && addr.type == InternetAddressType.IPv4) {
      if (interface != null) {
        for (int i = 0; i < interface.addresses.length; i++) {
          if (interface.addresses[i].type == InternetAddressType.IPv4) {
            return interface.addresses[i];
          }
        }
        // No IPv4 address found on the interface.
        throw new SocketException(
            "The network interface does not have an address "
            "of the same family as the multicast address");
      } else {
        // Default to the ANY address if no interface is specified.
        return InternetAddress.anyIPv4;
      }
    } else {
      return null;
    }
  }

  void joinMulticast(InternetAddress addr, NetworkInterface? interface) {
    final interfaceAddr =
        multicastAddress(addr, interface) as _InternetAddress?;
    var interfaceIndex = interface == null ? 0 : interface.index;
    nativeJoinMulticast((addr as _InternetAddress)._in_addr,
        interfaceAddr?._in_addr, interfaceIndex);
  }

  void leaveMulticast(InternetAddress addr, NetworkInterface? interface) {
    final interfaceAddr =
        multicastAddress(addr, interface) as _InternetAddress?;
    var interfaceIndex = interface == null ? 0 : interface.index;
    nativeLeaveMulticast((addr as _InternetAddress)._in_addr,
        interfaceAddr?._in_addr, interfaceIndex);
  }

  void nativeSetSocketId(int id, int typeFlags) native "Socket_SetSocketId";
  int nativeAvailable() native "Socket_Available";
  bool nativeAvailableDatagram() native "Socket_AvailableDatagram";
  Uint8List? nativeRead(int len) native "Socket_Read";
  Datagram? nativeRecvFrom() native "Socket_RecvFrom";
  int nativeWrite(List<int> buffer, int offset, int bytes)
      native "Socket_WriteList";
  int nativeSendTo(List<int> buffer, int offset, int bytes, Uint8List address,
      int port) native "Socket_SendTo";
  nativeCreateConnect(Uint8List addr, int port, int scope_id)
      native "Socket_CreateConnect";
  nativeCreateUnixDomainConnect(String addr, _Namespace namespace)
      native "Socket_CreateUnixDomainConnect";
  nativeCreateBindConnect(Uint8List addr, int port, Uint8List sourceAddr,
      int scope_id) native "Socket_CreateBindConnect";
  nativeCreateUnixDomainBindConnect(String addr, String sourceAddr,
      _Namespace namespace) native "Socket_CreateUnixDomainBindConnect";
  bool isBindError(int errorNumber) native "SocketBase_IsBindError";
  nativeCreateBindListen(Uint8List addr, int port, int backlog, bool v6Only,
      bool shared, int scope_id) native "ServerSocket_CreateBindListen";
  nativeCreateUnixDomainBindListen(String addr, int backlog, bool shared,
      _Namespace namespace) native "ServerSocket_CreateUnixDomainBindListen";
  nativeCreateBindDatagram(Uint8List addr, int port, bool reuseAddress,
      bool reusePort, int ttl) native "Socket_CreateBindDatagram";
  bool nativeAccept(_NativeSocket socket) native "ServerSocket_Accept";
  int nativeGetPort() native "Socket_GetPort";
  List nativeGetRemotePeer() native "Socket_GetRemotePeer";
  int nativeGetSocketId() native "Socket_GetSocketId";
  OSError nativeGetError() native "Socket_GetError";
  nativeGetOption(int option, int protocol) native "Socket_GetOption";
  void nativeGetRawOption(int level, int option, Uint8List data)
      native "Socket_GetRawOption";
  void nativeSetOption(int option, int protocol, value)
      native "Socket_SetOption";
  void nativeSetRawOption(int level, int option, Uint8List data)
      native "Socket_SetRawOption";
  void nativeJoinMulticast(Uint8List addr, Uint8List? interfaceAddr,
      int interfaceIndex) native "Socket_JoinMulticast";
  void nativeLeaveMulticast(Uint8List addr, Uint8List? interfaceAddr,
      int interfaceIndex) native "Socket_LeaveMulticast";
}

class _RawServerSocket extends Stream<RawSocket> implements RawServerSocket {
  final _NativeSocket _socket;
  StreamController<RawSocket>? _controller;
  bool _v6Only;

  static Future<_RawServerSocket> bind(
      address, int port, int backlog, bool v6Only, bool shared) {
    _throwOnBadPort(port);
    if (backlog < 0) throw new ArgumentError("Invalid backlog $backlog");
    return _NativeSocket.bind(address, port, backlog, v6Only, shared)
        .then((socket) => new _RawServerSocket(socket, v6Only));
  }

  _RawServerSocket(this._socket, this._v6Only);

  StreamSubscription<RawSocket> listen(void onData(RawSocket event)?,
      {Function? onError, void onDone()?, bool? cancelOnError}) {
    if (_controller != null) {
      throw new StateError("Stream was already listened to");
    }
    var zone = Zone.current;
    final controller = _controller = new StreamController(
        sync: true,
        onListen: _onSubscriptionStateChange,
        onCancel: _onSubscriptionStateChange,
        onPause: _onPauseStateChange,
        onResume: _onPauseStateChange);
    _socket.setHandlers(
        read: zone.bindCallbackGuarded(() {
          while (_socket.connections > 0) {
            var socket = _socket.accept();
            if (socket == null) return;
            if (!const bool.fromEnvironment("dart.vm.product")) {
              _SocketProfile.collectNewSocket(socket.nativeGetSocketId(),
                  _tcpSocket, socket.address, socket.port);
            }
            controller.add(_RawSocket(socket));
            if (controller.isPaused) return;
          }
        }),
        error: zone.bindBinaryCallbackGuarded((Object e, StackTrace? st) {
          controller.addError(e, st);
          controller.close();
        }),
        destroyed: () => controller.close());
    return controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  int get port => _socket.port;

  InternetAddress get address => _socket.address;

  Future<RawServerSocket> close() {
    return _socket.close().then<RawServerSocket>((_) => this);
  }

  void _pause() {
    _socket.setListening(read: false, write: false);
  }

  void _resume() {
    _socket.setListening(read: true, write: false);
  }

  void _onSubscriptionStateChange() {
    if (_controller!.hasListener) {
      _resume();
    } else {
      _socket.close();
    }
  }

  void _onPauseStateChange() {
    if (_controller!.isPaused) {
      _pause();
    } else {
      _resume();
    }
  }

  void set _owner(owner) {
    _socket.owner = owner;
  }
}

class _RawSocket extends Stream<RawSocketEvent> implements RawSocket {
  final _NativeSocket _socket;
  final _controller = new StreamController<RawSocketEvent>(sync: true);
  bool _readEventsEnabled = true;
  bool _writeEventsEnabled = true;

  // Flag to handle Ctrl-D closing of stdio on Mac OS.
  bool _isMacOSTerminalInput = false;

  static Future<RawSocket> connect(
      dynamic host, int port, dynamic sourceAddress, Duration? timeout) {
    return _NativeSocket.connect(host, port, sourceAddress, timeout)
        .then((socket) {
      if (!const bool.fromEnvironment("dart.vm.product")) {
        _SocketProfile.collectNewSocket(
            socket.nativeGetSocketId(), _tcpSocket, socket.address, port);
      }
      return _RawSocket(socket);
    });
  }

  static Future<ConnectionTask<_RawSocket>> startConnect(
      dynamic host, int port, dynamic sourceAddress) {
    return _NativeSocket.startConnect(host, port, sourceAddress)
        .then((ConnectionTask<_NativeSocket> nativeTask) {
      final Future<_RawSocket> raw =
          nativeTask.socket.then((_NativeSocket nativeSocket) {
        if (!const bool.fromEnvironment("dart.vm.product")) {
          _SocketProfile.collectNewSocket(nativeSocket.nativeGetSocketId(),
              _tcpSocket, nativeSocket.address, port);
        }
        return _RawSocket(nativeSocket);
      });
      return ConnectionTask<_RawSocket>._(raw, nativeTask._onCancel);
    });
  }

  _RawSocket(this._socket) {
    var zone = Zone.current;
    _controller
      ..onListen = _onSubscriptionStateChange
      ..onCancel = _onSubscriptionStateChange
      ..onPause = _onPauseStateChange
      ..onResume = _onPauseStateChange;
    _socket.setHandlers(
        read: () => _controller.add(RawSocketEvent.read),
        write: () {
          // The write event handler is automatically disabled by the
          // event handler when it fires.
          writeEventsEnabled = false;
          _controller.add(RawSocketEvent.write);
        },
        closed: () => _controller.add(RawSocketEvent.readClosed),
        destroyed: () {
          _controller.add(RawSocketEvent.closed);
          _controller.close();
        },
        error: zone.bindBinaryCallbackGuarded((Object e, StackTrace? st) {
          _controller.addError(e, st);
          _socket.close();
        }));
  }

  factory _RawSocket._writePipe() {
    var native = new _NativeSocket.pipe();
    native.isClosedRead = true;
    native.closedReadEventSent = true;
    return new _RawSocket(native);
  }

  factory _RawSocket._readPipe(int? fd) {
    var native = new _NativeSocket.pipe();
    native.isClosedWrite = true;
    if (fd != null) _getStdioHandle(native, fd);
    var result = new _RawSocket(native);
    if (fd != null) {
      var socketType = _StdIOUtils._nativeSocketType(result._socket);
      result._isMacOSTerminalInput =
          Platform.isMacOS && socketType == _stdioHandleTypeTerminal;
    }
    return result;
  }

  StreamSubscription<RawSocketEvent> listen(void onData(RawSocketEvent event)?,
      {Function? onError, void onDone()?, bool? cancelOnError}) {
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  int available() => _socket.available;

  Uint8List? read([int? len]) {
    if (_isMacOSTerminalInput) {
      var available = this.available();
      if (available == 0) return null;
      var data = _socket.read(len);
      if (data == null || data.length < available) {
        // Reading less than available from a Mac OS terminal indicate Ctrl-D.
        // This is interpreted as read closed.
        scheduleMicrotask(() => _controller.add(RawSocketEvent.readClosed));
      }
      return data;
    } else {
      return _socket.read(len);
    }
  }

  int write(List<int> buffer, [int offset = 0, int? count]) =>
      _socket.write(buffer, offset, count);

  Future<RawSocket> close() => _socket.close().then<RawSocket>((_) {
        if (!const bool.fromEnvironment("dart.vm.product")) {
          _SocketProfile.collectStatistic(
              _socket.nativeGetSocketId(), _SocketProfileType.endTime);
        }
        return this;
      });

  void shutdown(SocketDirection direction) => _socket.shutdown(direction);

  int get port => _socket.port;

  int get remotePort => _socket.remotePort;

  InternetAddress get address => _socket.address;

  InternetAddress get remoteAddress => _socket.remoteAddress;

  bool get readEventsEnabled => _readEventsEnabled;
  void set readEventsEnabled(bool value) {
    if (value != _readEventsEnabled) {
      _readEventsEnabled = value;
      if (!_controller.isPaused) _resume();
    }
  }

  bool get writeEventsEnabled => _writeEventsEnabled;
  void set writeEventsEnabled(bool value) {
    if (value != _writeEventsEnabled) {
      _writeEventsEnabled = value;
      if (!_controller.isPaused) _resume();
    }
  }

  bool setOption(SocketOption option, bool enabled) =>
      _socket.setOption(option, enabled);

  Uint8List getRawOption(RawSocketOption option) =>
      _socket.getRawOption(option);
  void setRawOption(RawSocketOption option) => _socket.setRawOption(option);

  _pause() {
    _socket.setListening(read: false, write: false);
  }

  void _resume() {
    _socket.setListening(read: _readEventsEnabled, write: _writeEventsEnabled);
  }

  void _onPauseStateChange() {
    if (_controller.isPaused) {
      _pause();
    } else {
      _resume();
    }
  }

  void _onSubscriptionStateChange() {
    if (_controller.hasListener) {
      _resume();
    } else {
      _socket.close();
    }
  }

  void set _owner(owner) {
    _socket.owner = owner;
  }
}

@patch
class ServerSocket {
  @patch
  static Future<ServerSocket> _bind(address, int port,
      {int backlog: 0, bool v6Only: false, bool shared: false}) {
    return _ServerSocket.bind(address, port, backlog, v6Only, shared);
  }
}

class _ServerSocket extends Stream<Socket> implements ServerSocket {
  final _socket;

  static Future<_ServerSocket> bind(
      address, int port, int backlog, bool v6Only, bool shared) {
    return _RawServerSocket.bind(address, port, backlog, v6Only, shared)
        .then((socket) => new _ServerSocket(socket));
  }

  _ServerSocket(this._socket);

  StreamSubscription<Socket> listen(void onData(Socket event)?,
      {Function? onError, void onDone()?, bool? cancelOnError}) {
    return _socket.map<Socket>((rawSocket) => new _Socket(rawSocket)).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError);
  }

  int get port => _socket.port;

  InternetAddress get address => _socket.address;

  Future<ServerSocket> close() =>
      _socket.close().then<ServerSocket>((_) => this);

  void set _owner(owner) {
    _socket._owner = owner;
  }
}

@patch
class Socket {
  @patch
  static Future<Socket> _connect(dynamic host, int port,
      {dynamic sourceAddress, Duration? timeout}) {
    return RawSocket.connect(host, port,
            sourceAddress: sourceAddress, timeout: timeout)
        .then((socket) => new _Socket(socket));
  }

  @patch
  static Future<ConnectionTask<Socket>> _startConnect(dynamic host, int port,
      {dynamic sourceAddress}) {
    return RawSocket.startConnect(host, port, sourceAddress: sourceAddress)
        .then((rawTask) {
      Future<Socket> socket =
          rawTask.socket.then((rawSocket) => new _Socket(rawSocket));
      return new ConnectionTask<Socket>._(socket, rawTask._onCancel);
    });
  }
}

class _SocketStreamConsumer extends StreamConsumer<List<int>> {
  StreamSubscription? subscription;
  final _Socket socket;
  int? offset;
  List<int>? buffer;
  bool paused = false;
  Completer<Socket>? streamCompleter;

  _SocketStreamConsumer(this.socket);

  Future<Socket> addStream(Stream<List<int>> stream) {
    socket._ensureRawSocketSubscription();
    final completer = streamCompleter = new Completer<Socket>();
    if (socket._raw != null) {
      subscription = stream.listen((data) {
        assert(!paused);
        assert(buffer == null);
        buffer = data;
        offset = 0;
        try {
          write();
        } catch (e) {
          socket.destroy();
          stop();
          done(e);
        }
      }, onError: (error, [stackTrace]) {
        socket.destroy();
        done(error, stackTrace);
      }, onDone: () {
        done();
      }, cancelOnError: true);
    }
    return completer.future;
  }

  Future<Socket> close() {
    socket._consumerDone();
    return new Future.value(socket);
  }

  void write() {
    final sub = subscription;
    if (sub == null) return;
    // Write as much as possible.
    offset =
        offset! + socket._write(buffer!, offset!, buffer!.length - offset!);
    if (offset! < buffer!.length) {
      if (!paused) {
        paused = true;
        sub.pause();
      }
      socket._enableWriteEvent();
    } else {
      buffer = null;
      if (paused) {
        paused = false;
        sub.resume();
      }
    }
  }

  void done([error, stackTrace]) {
    final completer = streamCompleter;
    if (completer != null) {
      if (error != null) {
        completer.completeError(error, stackTrace);
      } else {
        completer.complete(socket);
      }
      streamCompleter = null;
    }
  }

  void stop() {
    final sub = subscription;
    if (sub == null) return;
    sub.cancel();
    subscription = null;
    paused = false;
    socket._disableWriteEvent();
  }
}

class _Socket extends Stream<Uint8List> implements Socket {
  RawSocket? _raw; // Set to null when the raw socket is closed.
  bool _closed = false; // Set to true when the raw socket is closed.
  final _controller = new StreamController<Uint8List>(sync: true);
  bool _controllerClosed = false;
  late _SocketStreamConsumer _consumer;
  late IOSink _sink;
  StreamSubscription? _subscription;
  var _detachReady;

  _Socket(RawSocket raw) : _raw = raw {
    _controller
      ..onListen = _onSubscriptionStateChange
      ..onCancel = _onSubscriptionStateChange
      ..onPause = _onPauseStateChange
      ..onResume = _onPauseStateChange;
    _consumer = new _SocketStreamConsumer(this);
    _sink = new IOSink(_consumer);

    // Disable read events until there is a subscription.
    raw.readEventsEnabled = false;

    // Disable write events until the consumer needs it for pending writes.
    raw.writeEventsEnabled = false;
  }

  factory _Socket._writePipe() {
    return new _Socket(new _RawSocket._writePipe());
  }

  factory _Socket._readPipe([int? fd]) {
    return new _Socket(new _RawSocket._readPipe(fd));
  }

  // Note: this code seems a bit suspicious because _raw can be _RawSocket and
  // it can be _RawSecureSocket because _SecureSocket extends _Socket
  // and these two types are incompatible because _RawSecureSocket._socket
  // is Socket and not _NativeSocket.
  _NativeSocket get _nativeSocket => (_raw as _RawSocket)._socket;

  StreamSubscription<Uint8List> listen(void onData(Uint8List event)?,
      {Function? onError, void onDone()?, bool? cancelOnError}) {
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  Encoding get encoding => _sink.encoding;

  void set encoding(Encoding value) {
    _sink.encoding = value;
  }

  void write(Object? obj) => _sink.write(obj);

  void writeln([Object? obj = ""]) => _sink.writeln(obj);

  void writeCharCode(int charCode) => _sink.writeCharCode(charCode);

  void writeAll(Iterable objects, [String sep = ""]) =>
      _sink.writeAll(objects, sep);

  void add(List<int> bytes) => _sink.add(bytes);

  void addError(Object error, [StackTrace? stackTrace]) {
    throw new UnsupportedError("Cannot send errors on sockets");
  }

  Future addStream(Stream<List<int>> stream) {
    return _sink.addStream(stream);
  }

  Future flush() => _sink.flush();

  Future close() => _sink.close();

  Future get done => _sink.done;

  void destroy() {
    // Destroy can always be called to get rid of a socket.
    if (_raw == null) return;
    _consumer.stop();
    _closeRawSocket();
    _controllerClosed = true;
    _controller.close();
  }

  bool setOption(SocketOption option, bool enabled) {
    final raw = _raw;
    if (raw == null) throw const SocketException.closed();
    return raw.setOption(option, enabled);
  }

  Uint8List getRawOption(RawSocketOption option) {
    final raw = _raw;
    if (raw == null) throw const SocketException.closed();
    return raw.getRawOption(option);
  }

  void setRawOption(RawSocketOption option) {
    final raw = _raw;
    if (raw == null) throw const SocketException.closed();
    raw.setRawOption(option);
  }

  int get port {
    final raw = _raw;
    if (raw == null) throw const SocketException.closed();
    return raw.port;
  }

  InternetAddress get address {
    final raw = _raw;
    if (raw == null) throw const SocketException.closed();
    return raw.address;
  }

  int get remotePort {
    final raw = _raw;
    if (raw == null) throw const SocketException.closed();
    return raw.remotePort;
  }

  InternetAddress get remoteAddress {
    final raw = _raw;
    if (raw == null) throw const SocketException.closed();
    return raw.remoteAddress;
  }

  Future _detachRaw() {
    _detachReady = new Completer();
    _sink.close();
    return _detachReady.future.then((_) {
      assert(_consumer.buffer == null);
      var raw = _raw;
      _raw = null;
      return [raw, _subscription];
    });
  }

  // Ensure a subscription on the raw socket. Both the stream and the
  // consumer needs a subscription as they share the error and done
  // events from the raw socket.
  void _ensureRawSocketSubscription() {
    final raw = _raw;
    if (_subscription == null && raw != null) {
      _subscription = raw.listen(_onData,
          onError: _onError, onDone: _onDone, cancelOnError: true);
    }
  }

  _closeRawSocket() {
    var raw = _raw!;
    _raw = null;
    _closed = true;
    raw.close();
  }

  void _onSubscriptionStateChange() {
    final raw = _raw;
    if (_controller.hasListener) {
      _ensureRawSocketSubscription();
      // Enable read events for providing data to subscription.
      if (raw != null) {
        raw.readEventsEnabled = true;
      }
    } else {
      _controllerClosed = true;
      if (raw != null) {
        raw.shutdown(SocketDirection.receive);
      }
    }
  }

  void _onPauseStateChange() {
    _raw?.readEventsEnabled = !_controller.isPaused;
  }

  void _onData(event) {
    switch (event) {
      case RawSocketEvent.read:
        if (_raw == null) break;
        var buffer = _raw!.read();
        if (buffer != null) _controller.add(buffer);
        break;
      case RawSocketEvent.write:
        _consumer.write();
        break;
      case RawSocketEvent.readClosed:
        _controllerClosed = true;
        _controller.close();
        break;
    }
  }

  void _onDone() {
    if (!_controllerClosed) {
      _controllerClosed = true;
      _controller.close();
    }
    _consumer.done();
  }

  void _onError(error, stackTrace) {
    if (!_controllerClosed) {
      _controllerClosed = true;
      _controller.addError(error, stackTrace);
      _controller.close();
    }
    _consumer.done(error, stackTrace);
  }

  int _write(List<int> data, int offset, int length) {
    final raw = _raw;
    if (raw != null) {
      return raw.write(data, offset, length);
    }
    return 0;
  }

  void _enableWriteEvent() {
    _raw?.writeEventsEnabled = true;
  }

  void _disableWriteEvent() {
    _raw?.writeEventsEnabled = false;
  }

  void _consumerDone() {
    if (_detachReady != null) {
      _detachReady.complete(null);
    } else {
      final raw = _raw;
      if (raw != null) {
        raw.shutdown(SocketDirection.send);
        _disableWriteEvent();
      }
    }
  }

  void set _owner(owner) {
    // Note: _raw can be _RawSocket and _RawSecureSocket which are two
    // incompatible types.
    (_raw as dynamic)._owner = owner;
  }
}

@patch
class RawDatagramSocket {
  @patch
  static Future<RawDatagramSocket> bind(host, int port,
      {bool reuseAddress: true, bool reusePort: false, int ttl: 1}) {
    return _RawDatagramSocket.bind(host, port, reuseAddress, reusePort, ttl);
  }
}

class _RawDatagramSocket extends Stream<RawSocketEvent>
    implements RawDatagramSocket {
  _NativeSocket _socket;
  late StreamController<RawSocketEvent> _controller;
  bool _readEventsEnabled = true;
  bool _writeEventsEnabled = true;

  _RawDatagramSocket(this._socket) {
    var zone = Zone.current;
    _controller = new StreamController<RawSocketEvent>(
        sync: true,
        onListen: _onSubscriptionStateChange,
        onCancel: _onSubscriptionStateChange,
        onPause: _onPauseStateChange,
        onResume: _onPauseStateChange);
    _socket.setHandlers(
        read: () => _controller.add(RawSocketEvent.read),
        write: () {
          // The write event handler is automatically disabled by the
          // event handler when it fires.
          writeEventsEnabled = false;
          _controller.add(RawSocketEvent.write);
        },
        closed: () => _controller.add(RawSocketEvent.readClosed),
        destroyed: () {
          _controller.add(RawSocketEvent.closed);
          _controller.close();
        },
        error: zone.bindBinaryCallbackGuarded((Object e, StackTrace? st) {
          _controller.addError(e, st);
          _socket.close();
        }));
  }

  static Future<RawDatagramSocket> bind(
      host, int port, bool reuseAddress, bool reusePort, int ttl) {
    _throwOnBadPort(port);
    _throwOnBadTtl(ttl);
    return _NativeSocket.bindDatagram(host, port, reuseAddress, reusePort, ttl)
        .then((socket) {
      if (!const bool.fromEnvironment("dart.vm.product")) {
        _SocketProfile.collectNewSocket(
            socket.nativeGetSocketId(), _udpSocket, socket.address, port);
      }
      return _RawDatagramSocket(socket);
    });
  }

  StreamSubscription<RawSocketEvent> listen(void onData(RawSocketEvent event)?,
      {Function? onError, void onDone()?, bool? cancelOnError}) {
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  Future close() => _socket.close().then<RawDatagramSocket>((_) {
        if (!const bool.fromEnvironment("dart.vm.product")) {
          _SocketProfile.collectStatistic(
              _socket.nativeGetSocketId(), _SocketProfileType.endTime);
        }
        return this;
      });

  int send(List<int> buffer, InternetAddress address, int port) =>
      _socket.send(buffer, 0, buffer.length, address, port);

  Datagram? receive() {
    return _socket.receive();
  }

  void joinMulticast(InternetAddress group, [NetworkInterface? interface]) {
    _socket.joinMulticast(group, interface);
  }

  void leaveMulticast(InternetAddress group, [NetworkInterface? interface]) {
    _socket.leaveMulticast(group, interface);
  }

  bool get readEventsEnabled => _readEventsEnabled;
  void set readEventsEnabled(bool value) {
    if (value != _readEventsEnabled) {
      _readEventsEnabled = value;
      if (!_controller.isPaused) _resume();
    }
  }

  bool get writeEventsEnabled => _writeEventsEnabled;
  void set writeEventsEnabled(bool value) {
    if (value != _writeEventsEnabled) {
      _writeEventsEnabled = value;
      if (!_controller.isPaused) _resume();
    }
  }

  bool get multicastLoopback =>
      _socket.getOption(SocketOption._ipMulticastLoop);
  void set multicastLoopback(bool value) =>
      _socket.setOption(SocketOption._ipMulticastLoop, value);

  int get multicastHops => _socket.getOption(SocketOption._ipMulticastHops);
  void set multicastHops(int value) =>
      _socket.setOption(SocketOption._ipMulticastHops, value);

  NetworkInterface get multicastInterface => throw UnimplementedError();
  void set multicastInterface(NetworkInterface? value) =>
      throw UnimplementedError();

  bool get broadcastEnabled => _socket.getOption(SocketOption._ipBroadcast);
  void set broadcastEnabled(bool value) =>
      _socket.setOption(SocketOption._ipBroadcast, value);

  int get port => _socket.port;

  InternetAddress get address => _socket.address;

  _pause() {
    _socket.setListening(read: false, write: false);
  }

  void _resume() {
    _socket.setListening(read: _readEventsEnabled, write: _writeEventsEnabled);
  }

  void _onPauseStateChange() {
    if (_controller.isPaused) {
      _pause();
    } else {
      _resume();
    }
  }

  void _onSubscriptionStateChange() {
    if (_controller.hasListener) {
      _resume();
    } else {
      _socket.close();
    }
  }

  Uint8List getRawOption(RawSocketOption option) =>
      _socket.getRawOption(option);
  void setRawOption(RawSocketOption option) => _socket.setRawOption(option);
}

@pragma("vm:entry-point", "call")
Datagram _makeDatagram(
    Uint8List data, String address, Uint8List in_addr, int port, int type) {
  return new Datagram(
      data,
      _InternetAddress(InternetAddressType._from(type), address, null, in_addr),
      port);
}
