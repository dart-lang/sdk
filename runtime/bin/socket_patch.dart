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
  static Future<RawSocket> connect(host, int port,
      {sourceAddress, Duration timeout}) {
    return _RawSocket.connect(host, port, sourceAddress, timeout);
  }
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
  factory InternetAddress(String address) {
    return new _InternetAddress.parse(address);
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
  if ((port == null) || (port < 0) || (port > 0xFFFF)) {
    throw new ArgumentError("Invalid port $port");
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
      new _InternetAddress.fixed(_addressLoopbackIPv4);
  static _InternetAddress loopbackIPv6 =
      new _InternetAddress.fixed(_addressLoopbackIPv6);
  static _InternetAddress anyIPv4 = new _InternetAddress.fixed(_addressAnyIPv4);
  static _InternetAddress anyIPv6 = new _InternetAddress.fixed(_addressAnyIPv6);

  final String address;
  final String _host;
  final Uint8List _in_addr;

  InternetAddressType get type => _in_addr.length == _IPv4AddrLength
      ? InternetAddressType.IPv4
      : InternetAddressType.IPv6;

  String get host => _host != null ? _host : address;

  List<int> get rawAddress => new Uint8List.fromList(_in_addr);

  bool get isLoopback {
    switch (type) {
      case InternetAddressType.IPv4:
        return _in_addr[0] == 127;

      case InternetAddressType.IPv6:
        for (int i = 0; i < _IPv6AddrLength - 1; i++) {
          if (_in_addr[i] != 0) return false;
        }
        return _in_addr[_IPv6AddrLength - 1] == 1;
    }
  }

  bool get isLinkLocal {
    switch (type) {
      case InternetAddressType.IPv4:
        // Checking for 169.254.0.0/16.
        return _in_addr[0] == 169 && _in_addr[1] == 254;

      case InternetAddressType.IPv6:
        // Checking for fe80::/10.
        return _in_addr[0] == 0xFE && (_in_addr[1] & 0xB0) == 0x80;
    }
  }

  bool get isMulticast {
    switch (type) {
      case InternetAddressType.IPv4:
        // Checking for 224.0.0.0 through 239.255.255.255.
        return _in_addr[0] >= 224 && _in_addr[0] < 240;

      case InternetAddressType.IPv6:
        // Checking for ff00::/8.
        return _in_addr[0] == 0xFF;
    }
  }

  Future<InternetAddress> reverse() => _NativeSocket.reverseLookup(this);

  _InternetAddress(this.address, this._host, this._in_addr);

  factory _InternetAddress.parse(String address) {
    if (address is! String) {
      throw new ArgumentError("Invalid internet address $address");
    }
    var in_addr = _parse(address);
    if (in_addr == null) {
      throw new ArgumentError("Invalid internet address $address");
    }
    return new _InternetAddress(address, null, in_addr);
  }

  factory _InternetAddress.fixed(int id) {
    switch (id) {
      case _addressLoopbackIPv4:
        var in_addr = new Uint8List(_IPv4AddrLength);
        in_addr[0] = 127;
        in_addr[_IPv4AddrLength - 1] = 1;
        return new _InternetAddress("127.0.0.1", null, in_addr);
      case _addressLoopbackIPv6:
        var in_addr = new Uint8List(_IPv6AddrLength);
        in_addr[_IPv6AddrLength - 1] = 1;
        return new _InternetAddress("::1", null, in_addr);
      case _addressAnyIPv4:
        var in_addr = new Uint8List(_IPv4AddrLength);
        return new _InternetAddress("0.0.0.0", "0.0.0.0", in_addr);
      case _addressAnyIPv6:
        var in_addr = new Uint8List(_IPv6AddrLength);
        return new _InternetAddress("::", "::", in_addr);
      default:
        assert(false);
        throw new ArgumentError();
    }
  }

  // Create a clone of this _InternetAddress replacing the host.
  _InternetAddress _cloneWithNewHost(String host) {
    return new _InternetAddress(
        address, host, new Uint8List.fromList(_in_addr));
  }

  bool operator ==(other) {
    if (!(other is _InternetAddress)) return false;
    if (other.type != type) return false;
    bool equals = true;
    for (int i = 0; i < _in_addr.length && equals; i++) {
      equals = other._in_addr[i] == _in_addr[i];
    }
    return equals;
  }

  int get hashCode {
    int result = 1;
    for (int i = 0; i < _in_addr.length; i++) {
      result = (result * 31 + _in_addr[i]) & 0x3FFFFFFF;
    }
    return result;
  }

  String toString() {
    return "InternetAddress('$address', ${type.name})";
  }

  static Uint8List _parse(String address) native "InternetAddress_Parse";
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
  final List eventHandlers = new List(eventCount + 1);
  RawReceivePort eventPort;
  bool flagsSent = false;

  // The type flags for this socket.
  final int typeFlags;

  // Holds the port of the socket, 0 if not known.
  int localPort = 0;

  // Holds the address used to connect or bind the socket.
  InternetAddress localAddress;

  int available = 0;

  int tokens = 0;

  bool sendReadEvents = false;
  bool readEventIssued = false;

  bool sendWriteEvents = false;
  bool writeEventIssued = false;
  bool writeAvailable = false;

  static bool connectedResourceHandler = false;
  _ReadWriteResourceInfo resourceInfo;

  // The owner object is the object that the Socket is being used by, e.g.
  // a HttpServer, a WebSocket connection, a process pipe, etc.
  Object owner;

  static Future<List<InternetAddress>> lookup(String host,
      {InternetAddressType type: InternetAddressType.any}) {
    return _IOService._dispatch(
        _IOService.socketLookup, [host, type._value]).then((response) {
      if (isErrorResponse(response)) {
        throw createError(response, "Failed host lookup: '$host'");
      } else {
        return response.skip(1).map<InternetAddress>((result) {
          var type = new InternetAddressType._from(result[0]);
          return new _InternetAddress(result[1], host, result[2]);
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
    return _IOService._dispatch(
        _IOService.socketListInterfaces, [type._value]).then((response) {
      if (isErrorResponse(response)) {
        throw createError(response, "Failed listing interfaces");
      } else {
        var map = response.skip(1).fold(new Map<String, NetworkInterface>(),
            (map, result) {
          var type = new InternetAddressType._from(result[0]);
          var name = result[3];
          var index = result[4];
          var address = new _InternetAddress(result[1], "", result[2]);
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

  static Future<_NativeSocket> connect(
      host, int port, sourceAddress, Duration timeout) {
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
      Timer timeoutTimer = null;
      void timeoutHandler() {
        connecting.forEach((s, t) {
          t.cancel();
          s.close();
          s.setHandlers();
          s.setListening(read: false, write: false);
          error = createError(
              null, "Connection timed out, host: ${host}, port: ${port}");
          completer.completeError(error);
        });
      }

      void connectNext() {
        if ((timeout != null) && (timeoutTimer == null)) {
          timeoutTimer = new Timer(timeout, timeoutHandler);
        }
        if (!it.moveNext()) {
          if (connecting.isEmpty) {
            assert(error != null);
            if (timeoutTimer != null) {
              timeoutTimer.cancel();
            }
            completer.completeError(error);
          }
          return;
        }
        final _InternetAddress address = it.current;
        var socket = new _NativeSocket.normal();
        socket.localAddress = address;
        var result;
        if (sourceAddress == null) {
          result = socket.nativeCreateConnect(address._in_addr, port);
        } else {
          assert(sourceAddress is _InternetAddress);
          result = socket.nativeCreateBindConnect(
              address._in_addr, port, sourceAddress._in_addr);
        }
        if (result is OSError) {
          // Keep first error, if present.
          if (error == null) {
            int errorCode = result.errorCode;
            if (errorCode != null && socket.isBindError(errorCode)) {
              error = createError(result, "Bind failed", sourceAddress);
            } else {
              error = createError(result, "Connection failed", address, port);
            }
          }
          connectNext();
        } else {
          // Query the local port, for error messages.
          try {
            socket.port;
          } catch (e) {
            error = createError(e, "Connection failed", address, port);
            connectNext();
          }
          // Set up timer for when we should retry the next address
          // (if any).
          var duration =
              address.isLoopback ? _retryDurationLoopback : _retryDuration;
          var timer = new Timer(duration, connectNext);
          setupResourceInfo(socket);

          connecting[socket] = timer;
          // Setup handlers for receiving the first write event which
          // indicate that the socket is fully connected.
          socket.setHandlers(write: () {
            timer.cancel();
            if (timeoutTimer != null) {
              timeoutTimer.cancel();
            }
            socket.setListening(read: false, write: false);
            completer.complete(socket);
            connecting.remove(socket);
            connecting.forEach((s, t) {
              t.cancel();
              s.close();
              s.setHandlers();
              s.setListening(read: false, write: false);
            });
          }, error: (e) {
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

      connectNext();
      return completer.future;
    });
  }

  static Future<_InternetAddress> _resolveHost(host) async {
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

    final address = await _resolveHost(host);

    var socket = new _NativeSocket.listen();
    socket.localAddress = address;
    var result = socket.nativeCreateBindListen(
        address._in_addr, port, backlog, v6Only, shared);
    if (result is OSError) {
      throw new SocketException("Failed to create server socket",
          osError: result, address: address, port: port);
    }
    if (port != 0) socket.localPort = port;
    setupResourceInfo(socket);
    socket.connectToEventHandler();
    return socket;
  }

  static void setupResourceInfo(_NativeSocket socket) {
    socket.resourceInfo = new _SocketResourceInfo(socket);
  }

  static Future<_NativeSocket> bindDatagram(
      host, int port, bool reuseAddress) async {
    _throwOnBadPort(port);

    final address = await _resolveHost(host);

    var socket = new _NativeSocket.datagram(address);
    var result =
        socket.nativeCreateBindDatagram(address._in_addr, port, reuseAddress);
    if (result is OSError) {
      throw new SocketException("Failed to create datagram socket",
          osError: result, address: address, port: port);
    }
    if (port != 0) socket.localPort = port;
    setupResourceInfo(socket);
    return socket;
  }

  _NativeSocket.datagram(this.localAddress)
      : typeFlags = typeNormalSocket | typeUdpSocket;

  _NativeSocket.normal() : typeFlags = typeNormalSocket | typeTcpSocket;

  _NativeSocket.listen() : typeFlags = typeListeningSocket | typeTcpSocket {
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

  List<int> read(int len) {
    if (len != null && len <= 0) {
      throw new ArgumentError("Illegal length $len");
    }
    if (isClosing || isClosed) return null;
    len = min(available, len == null ? available : len);
    if (len == 0) return null;
    var result = nativeRead(len);
    if (result is OSError) {
      reportError(result, "Read failed");
      return null;
    }
    if (result != null) {
      available -= result.length;
      // TODO(ricow): Remove when we track internal and pipe uses.
      assert(resourceInfo != null || isPipe || isInternal || isInternalSignal);
      if (resourceInfo != null) {
        resourceInfo.totalRead += result.length;
      }
    }
    // TODO(ricow): Remove when we track internal and pipe uses.
    assert(resourceInfo != null || isPipe || isInternal || isInternalSignal);
    if (resourceInfo != null) {
      resourceInfo.didRead();
    }
    return result;
  }

  Datagram receive() {
    if (isClosing || isClosed) return null;
    var result = nativeRecvFrom();
    if (result is OSError) {
      reportError(result, "Receive failed");
      return null;
    }
    if (result != null) {
      // Read the next available. Available is only for the next datagram, not
      // the sum of all datagrams pending, so we need to call after each
      // receive. If available becomes > 0, the _NativeSocket will continue to
      // emit read events.
      available = nativeAvailable();
      // TODO(ricow): Remove when we track internal and pipe uses.
      assert(resourceInfo != null || isPipe || isInternal || isInternalSignal);
      if (resourceInfo != null) {
        resourceInfo.totalRead += result.data.length;
      }
    }
    // TODO(ricow): Remove when we track internal and pipe uses.
    assert(resourceInfo != null || isPipe || isInternal || isInternalSignal);
    if (resourceInfo != null) {
      resourceInfo.didRead();
    }
    return result;
  }

  int write(List<int> buffer, int offset, int bytes) {
    if (buffer is! List) throw new ArgumentError();
    if (offset == null) offset = 0;
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
    if (offset is! int || bytes is! int) {
      throw new ArgumentError("Invalid arguments to write on Socket");
    }
    if (isClosing || isClosed) return 0;
    if (bytes == 0) return 0;
    _BufferAndStart bufferAndStart =
        _ensureFastAndSerializableByteData(buffer, offset, offset + bytes);
    var result =
        nativeWrite(bufferAndStart.buffer, bufferAndStart.start, bytes);
    if (result is OSError) {
      OSError osError = result;
      scheduleMicrotask(() => reportError(osError, "Write failed"));
      result = 0;
    }
    // The result may be negative, if we forced a short write for testing
    // purpose. In such case, don't mark writeAvailable as false, as we don't
    // know if we'll receive an event. It's better to just retry.
    if (result >= 0 && result < bytes) {
      writeAvailable = false;
    }
    // Negate the result, as stated above.
    if (result < 0) result = -result;
    // TODO(ricow): Remove when we track internal and pipe uses.
    assert(resourceInfo != null || isPipe || isInternal || isInternalSignal);
    if (resourceInfo != null) {
      resourceInfo.addWrite(result);
    }
    return result;
  }

  int send(List<int> buffer, int offset, int bytes, InternetAddress address,
      int port) {
    _throwOnBadPort(port);
    if (isClosing || isClosed) return 0;
    _BufferAndStart bufferAndStart =
        _ensureFastAndSerializableByteData(buffer, offset, bytes);
    var result = nativeSendTo(bufferAndStart.buffer, bufferAndStart.start,
        bytes, (address as _InternetAddress)._in_addr, port);
    if (result is OSError) {
      OSError osError = result;
      scheduleMicrotask(() => reportError(osError, "Send failed"));
      result = 0;
    }
    // TODO(ricow): Remove when we track internal and pipe uses.
    assert(resourceInfo != null || isPipe || isInternal || isInternalSignal);
    if (resourceInfo != null) {
      resourceInfo.addWrite(result);
    }
    return result;
  }

  _NativeSocket accept() {
    // Don't issue accept if we're closing.
    if (isClosing || isClosed) return null;
    assert(available > 0);
    available--;
    tokens++;
    returnTokens(listeningTokenBatchSize);
    var socket = new _NativeSocket.normal();
    if (nativeAccept(socket) != true) return null;
    socket.localPort = localPort;
    socket.localAddress = address;
    setupResourceInfo(socket);
    // TODO(ricow): Remove when we track internal and pipe uses.
    assert(resourceInfo != null || isPipe || isInternal || isInternalSignal);
    if (resourceInfo != null) {
      // We track this as read one byte.
      resourceInfo.addRead(1);
    }
    return socket;
  }

  int get port {
    if (localPort != 0) return localPort;
    if (isClosing || isClosed) throw const SocketException.closed();
    var result = nativeGetPort();
    if (result is OSError) throw result;
    return localPort = result;
  }

  int get remotePort {
    if (isClosing || isClosed) throw const SocketException.closed();
    var result = nativeGetRemotePeer();
    if (result is OSError) throw result;
    return result[1];
  }

  InternetAddress get address => localAddress;

  InternetAddress get remoteAddress {
    if (isClosing || isClosed) throw const SocketException.closed();
    var result = nativeGetRemotePeer();
    if (result is OSError) throw result;
    var addr = result[0];
    var type = new InternetAddressType._from(addr[0]);
    return new _InternetAddress(addr[1], null, addr[2]);
  }

  void issueReadEvent() {
    if (closedReadEventSent) return;
    if (readEventIssued) return;
    readEventIssued = true;
    void issue() {
      readEventIssued = false;
      if (isClosing) return;
      if (!sendReadEvents) return;
      if (available == 0) {
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
    int events = eventsObj;
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
            available++;
          } else {
            available = nativeAvailable();
            issueReadEvent();
            continue;
          }
        }

        var handler = eventHandlers[i];
        if (i == destroyedEvent) {
          assert(isClosing);
          assert(!isClosed);
          // TODO(ricow): Remove/update when we track internal and pipe uses.
          assert(
              resourceInfo != null || isPipe || isInternal || isInternalSignal);
          if (resourceInfo != null) {
            _SocketResourceInfo.SocketClosed(resourceInfo);
          }
          isClosed = true;
          closeCompleter.complete();
          disconnectFromEventHandler();
          if (handler != null) handler();
          continue;
        }

        if (i == errorEvent) {
          if (!isClosing) {
            reportError(nativeGetError(), "");
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

  void setListening({read: true, write: true}) {
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
    _EventHandler._sendData(this, eventPort.sendPort, fullData);
  }

  void connectToEventHandler() {
    assert(!isClosed);
    if (eventPort == null) {
      eventPort = new RawReceivePort(multiplex);
    }
    if (!connectedResourceHandler) {
      registerExtension(
          'ext.dart.io.getOpenSockets', _SocketResourceInfo.getOpenSockets);
      registerExtension('ext.dart.io.getSocketByID',
          _SocketResourceInfo.getSocketInfoMapByID);

      connectedResourceHandler = true;
    }
  }

  void disconnectFromEventHandler() {
    assert(eventPort != null);
    eventPort.close();
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
      [InternetAddress address, int port]) {
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

  void reportError(error, String message) {
    var e = createError(error, message, address, localPort);
    // Invoke the error handler if any.
    if (eventHandlers[errorEvent] != null) {
      eventHandlers[errorEvent](e);
    }
    // For all errors we close the socket
    close();
  }

  getOption(SocketOption option) {
    if (option is! SocketOption) throw new ArgumentError(option);
    var result = nativeGetOption(option._value, address.type._value);
    if (result is OSError) throw result;
    return result;
  }

  bool setOption(SocketOption option, value) {
    if (option is! SocketOption) throw new ArgumentError(option);
    var result = nativeSetOption(option._value, address.type._value, value);
    if (result is OSError) throw result;
  }

  InternetAddress multicastAddress(
      InternetAddress addr, NetworkInterface interface) {
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

  void joinMulticast(InternetAddress addr, NetworkInterface interface) {
    _InternetAddress interfaceAddr = multicastAddress(addr, interface);
    var interfaceIndex = interface == null ? 0 : interface.index;
    var result = nativeJoinMulticast((addr as _InternetAddress)._in_addr,
        interfaceAddr?._in_addr, interfaceIndex);
    if (result is OSError) throw result;
  }

  void leaveMulticast(InternetAddress addr, NetworkInterface interface) {
    _InternetAddress interfaceAddr = multicastAddress(addr, interface);
    var interfaceIndex = interface == null ? 0 : interface.index;
    var result = nativeLeaveMulticast((addr as _InternetAddress)._in_addr,
        interfaceAddr?._in_addr, interfaceIndex);
    if (result is OSError) throw result;
  }

  void nativeSetSocketId(int id, int typeFlags) native "Socket_SetSocketId";
  nativeAvailable() native "Socket_Available";
  nativeRead(int len) native "Socket_Read";
  nativeRecvFrom() native "Socket_RecvFrom";
  nativeWrite(List<int> buffer, int offset, int bytes)
      native "Socket_WriteList";
  nativeSendTo(List<int> buffer, int offset, int bytes, List<int> address,
      int port) native "Socket_SendTo";
  nativeCreateConnect(List<int> addr, int port) native "Socket_CreateConnect";
  nativeCreateBindConnect(List<int> addr, int port, List<int> sourceAddr)
      native "Socket_CreateBindConnect";
  bool isBindError(int errorNumber) native "SocketBase_IsBindError";
  nativeCreateBindListen(List<int> addr, int port, int backlog, bool v6Only,
      bool shared) native "ServerSocket_CreateBindListen";
  nativeCreateBindDatagram(List<int> addr, int port, bool reuseAddress)
      native "Socket_CreateBindDatagram";
  nativeAccept(_NativeSocket socket) native "ServerSocket_Accept";
  int nativeGetPort() native "Socket_GetPort";
  List nativeGetRemotePeer() native "Socket_GetRemotePeer";
  int nativeGetSocketId() native "Socket_GetSocketId";
  OSError nativeGetError() native "Socket_GetError";
  nativeGetOption(int option, int protocol) native "Socket_GetOption";
  bool nativeSetOption(int option, int protocol, value)
      native "Socket_SetOption";
  OSError nativeJoinMulticast(List<int> addr, List<int> interfaceAddr,
      int interfaceIndex) native "Socket_JoinMulticast";
  bool nativeLeaveMulticast(List<int> addr, List<int> interfaceAddr,
      int interfaceIndex) native "Socket_LeaveMulticast";
}

class _RawServerSocket extends Stream<RawSocket> implements RawServerSocket {
  final _NativeSocket _socket;
  StreamController<RawSocket> _controller;
  ReceivePort _referencePort;
  bool _v6Only;

  static Future<_RawServerSocket> bind(
      address, int port, int backlog, bool v6Only, bool shared) {
    _throwOnBadPort(port);
    if (backlog < 0) throw new ArgumentError("Invalid backlog $backlog");
    return _NativeSocket
        .bind(address, port, backlog, v6Only, shared)
        .then((socket) => new _RawServerSocket(socket, v6Only));
  }

  _RawServerSocket(this._socket, this._v6Only);

  StreamSubscription<RawSocket> listen(void onData(RawSocket event),
      {Function onError, void onDone(), bool cancelOnError}) {
    if (_controller != null) {
      throw new StateError("Stream was already listened to");
    }
    var zone = Zone.current;
    _controller = new StreamController(
        sync: true,
        onListen: _onSubscriptionStateChange,
        onCancel: _onSubscriptionStateChange,
        onPause: _onPauseStateChange,
        onResume: _onPauseStateChange);
    _socket.setHandlers(read: zone.bindCallbackGuarded(() {
      while (_socket.available > 0) {
        var socket = _socket.accept();
        if (socket == null) return;
        _controller.add(new _RawSocket(socket));
        if (_controller.isPaused) return;
      }
    }), error: zone.bindUnaryCallbackGuarded((e) {
      _controller.addError(e);
      _controller.close();
    }), destroyed: () {
      _controller.close();
      if (_referencePort != null) {
        _referencePort.close();
        _referencePort = null;
      }
    });
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  int get port => _socket.port;

  InternetAddress get address => _socket.address;

  Future<RawServerSocket> close() {
    return _socket.close().then<RawServerSocket>((_) {
      if (_referencePort != null) {
        _referencePort.close();
        _referencePort = null;
      }
      return this;
    });
  }

  void _pause() {
    _socket.setListening(read: false, write: false);
  }

  void _resume() {
    _socket.setListening(read: true, write: false);
  }

  void _onSubscriptionStateChange() {
    if (_controller.hasListener) {
      _resume();
    } else {
      _socket.close();
    }
  }

  void _onPauseStateChange() {
    if (_controller.isPaused) {
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
  StreamController<RawSocketEvent> _controller;
  bool _readEventsEnabled = true;
  bool _writeEventsEnabled = true;

  // Flag to handle Ctrl-D closing of stdio on Mac OS.
  bool _isMacOSTerminalInput = false;

  static Future<RawSocket> connect(
      host, int port, sourceAddress, Duration timeout) {
    return _NativeSocket
        .connect(host, port, sourceAddress, timeout)
        .then((socket) => new _RawSocket(socket));
  }

  _RawSocket(this._socket) {
    var zone = Zone.current;
    _controller = new StreamController(
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
        error: zone.bindUnaryCallbackGuarded((e) {
          _controller.addError(e);
          _socket.close();
        }));
  }

  factory _RawSocket._writePipe() {
    var native = new _NativeSocket.pipe();
    native.isClosedRead = true;
    native.closedReadEventSent = true;
    return new _RawSocket(native);
  }

  factory _RawSocket._readPipe(int fd) {
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

  StreamSubscription<RawSocketEvent> listen(void onData(RawSocketEvent event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  int available() => _socket.available;

  List<int> read([int len]) {
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

  int write(List<int> buffer, [int offset, int count]) =>
      _socket.write(buffer, offset, count);

  Future<RawSocket> close() => _socket.close().then<RawSocket>((_) => this);

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
  static Future<ServerSocket> bind(address, int port,
      {int backlog: 0, bool v6Only: false, bool shared: false}) {
    return _ServerSocket.bind(address, port, backlog, v6Only, shared);
  }
}

class _ServerSocket extends Stream<Socket> implements ServerSocket {
  final _socket;

  static Future<_ServerSocket> bind(
      address, int port, int backlog, bool v6Only, bool shared) {
    return _RawServerSocket
        .bind(address, port, backlog, v6Only, shared)
        .then((socket) => new _ServerSocket(socket));
  }

  _ServerSocket(this._socket);

  StreamSubscription<Socket> listen(void onData(Socket event),
      {Function onError, void onDone(), bool cancelOnError}) {
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
  static Future<Socket> _connect(host, int port,
      {sourceAddress, Duration timeout}) {
    return RawSocket
        .connect(host, port, sourceAddress: sourceAddress, timeout: timeout)
        .then((socket) => new _Socket(socket));
  }
}

class _SocketStreamConsumer extends StreamConsumer<List<int>> {
  StreamSubscription subscription;
  final _Socket socket;
  int offset;
  List<int> buffer;
  bool paused = false;
  Completer streamCompleter;

  _SocketStreamConsumer(this.socket);

  Future<Socket> addStream(Stream<List<int>> stream) {
    socket._ensureRawSocketSubscription();
    streamCompleter = new Completer<Socket>();
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
    return streamCompleter.future;
  }

  Future<Socket> close() {
    socket._consumerDone();
    return new Future.value(socket);
  }

  void write() {
    if (subscription == null) return;
    assert(buffer != null);
    // Write as much as possible.
    offset += socket._write(buffer, offset, buffer.length - offset);
    if (offset < buffer.length) {
      if (!paused) {
        paused = true;
        subscription.pause();
      }
      socket._enableWriteEvent();
    } else {
      buffer = null;
      if (paused) {
        paused = false;
        subscription.resume();
      }
    }
  }

  void done([error, stackTrace]) {
    if (streamCompleter != null) {
      if (error != null) {
        streamCompleter.completeError(error, stackTrace);
      } else {
        streamCompleter.complete(socket);
      }
      streamCompleter = null;
    }
  }

  void stop() {
    if (subscription == null) return;
    subscription.cancel();
    subscription = null;
    paused = false;
    socket._disableWriteEvent();
  }
}

class _Socket extends Stream<List<int>> implements Socket {
  RawSocket _raw; // Set to null when the raw socket is closed.
  bool _closed = false; // Set to true when the raw socket is closed.
  StreamController<List<int>> _controller;
  bool _controllerClosed = false;
  _SocketStreamConsumer _consumer;
  IOSink _sink;
  var _subscription;
  var _detachReady;

  _Socket(this._raw) {
    _controller = new StreamController<List<int>>(
        sync: true,
        onListen: _onSubscriptionStateChange,
        onCancel: _onSubscriptionStateChange,
        onPause: _onPauseStateChange,
        onResume: _onPauseStateChange);
    _consumer = new _SocketStreamConsumer(this);
    _sink = new IOSink(_consumer);

    // Disable read events until there is a subscription.
    _raw.readEventsEnabled = false;

    // Disable write events until the consumer needs it for pending writes.
    _raw.writeEventsEnabled = false;
  }

  factory _Socket._writePipe() {
    return new _Socket(new _RawSocket._writePipe());
  }

  factory _Socket._readPipe([int fd]) {
    return new _Socket(new _RawSocket._readPipe(fd));
  }

  // Note: this code seems a bit suspicious because _raw can be _RawSocket and
  // it can be _RawSecureSocket because _SecureSocket extends _Socket
  // and these two types are incompatible because _RawSecureSocket._socket
  // is Socket and not _NativeSocket.
  _NativeSocket get _nativeSocket => (_raw as _RawSocket)._socket;

  StreamSubscription<List<int>> listen(void onData(List<int> event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  Encoding get encoding => _sink.encoding;

  void set encoding(Encoding value) {
    _sink.encoding = value;
  }

  void write(Object obj) => _sink.write(obj);

  void writeln([Object obj = ""]) => _sink.writeln(obj);

  void writeCharCode(int charCode) => _sink.writeCharCode(charCode);

  void writeAll(Iterable objects, [sep = ""]) => _sink.writeAll(objects, sep);

  void add(List<int> bytes) => _sink.add(bytes);

  void addError(Object error, [StackTrace stackTrace]) {
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
    if (_raw == null) return false;
    return _raw.setOption(option, enabled);
  }

  int get port {
    if (_raw == null) throw const SocketException.closed();
    ;
    return _raw.port;
  }

  InternetAddress get address {
    if (_raw == null) throw const SocketException.closed();
    ;
    return _raw.address;
  }

  int get remotePort {
    if (_raw == null) throw const SocketException.closed();
    ;
    return _raw.remotePort;
  }

  InternetAddress get remoteAddress {
    if (_raw == null) throw const SocketException.closed();
    ;
    return _raw.remoteAddress;
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
    if (_subscription == null && _raw != null) {
      _subscription = _raw.listen(_onData,
          onError: _onError, onDone: _onDone, cancelOnError: true);
    }
  }

  _closeRawSocket() {
    var tmp = _raw;
    _raw = null;
    _closed = true;
    tmp.close();
  }

  void _onSubscriptionStateChange() {
    if (_controller.hasListener) {
      _ensureRawSocketSubscription();
      // Enable read events for providing data to subscription.
      if (_raw != null) {
        _raw.readEventsEnabled = true;
      }
    } else {
      _controllerClosed = true;
      if (_raw != null) {
        _raw.shutdown(SocketDirection.receive);
      }
    }
  }

  void _onPauseStateChange() {
    if (_raw != null) {
      _raw.readEventsEnabled = !_controller.isPaused;
    }
  }

  void _onData(event) {
    switch (event) {
      case RawSocketEvent.read:
        var buffer = _raw.read();
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

  int _write(List<int> data, int offset, int length) =>
      _raw.write(data, offset, length);

  void _enableWriteEvent() {
    _raw.writeEventsEnabled = true;
  }

  void _disableWriteEvent() {
    if (_raw != null) {
      _raw.writeEventsEnabled = false;
    }
  }

  void _consumerDone() {
    if (_detachReady != null) {
      _detachReady.complete(null);
    } else {
      if (_raw != null) {
        _raw.shutdown(SocketDirection.send);
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
      {bool reuseAddress: true}) {
    return _RawDatagramSocket.bind(host, port, reuseAddress);
  }
}

class _RawDatagramSocket extends Stream<RawSocketEvent>
    implements RawDatagramSocket {
  _NativeSocket _socket;
  StreamController<RawSocketEvent> _controller;
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
        error: zone.bindUnaryCallbackGuarded((e) {
          _controller.addError(e);
          _socket.close();
        }));
  }

  static Future<RawDatagramSocket> bind(host, int port, bool reuseAddress) {
    _throwOnBadPort(port);
    return _NativeSocket
        .bindDatagram(host, port, reuseAddress)
        .then((socket) => new _RawDatagramSocket(socket));
  }

  StreamSubscription<RawSocketEvent> listen(void onData(RawSocketEvent event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  Future close() => _socket.close().then<RawDatagramSocket>((_) => this);

  int send(List<int> buffer, InternetAddress address, int port) =>
      _socket.send(buffer, 0, buffer.length, address, port);

  Datagram receive() {
    return _socket.receive();
  }

  void joinMulticast(InternetAddress group, [NetworkInterface interface]) {
    _socket.joinMulticast(group, interface);
  }

  void leaveMulticast(InternetAddress group, [NetworkInterface interface]) {
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

  NetworkInterface get multicastInterface => throw "Not implemented";
  void set multicastInterface(NetworkInterface value) =>
      throw "Not implemented";

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
}

Datagram _makeDatagram(
    List<int> data, String address, List<int> in_addr, int port) {
  return new Datagram(data, new _InternetAddress(address, null, in_addr), port);
}
