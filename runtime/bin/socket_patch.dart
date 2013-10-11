// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class RawServerSocket {
  /* patch */ static Future<RawServerSocket> bind(address,
                                                  int port,
                                                  {int backlog: 0,
                                                   bool v6Only: false}) {
    return _RawServerSocket.bind(address, port, backlog, v6Only);
  }
}


patch class RawSocket {
  /* patch */ static Future<RawSocket> connect(host, int port) {
    return _RawSocket.connect(host, port);
  }
}


patch class InternetAddress {
  /* patch */ static InternetAddress get LOOPBACK_IP_V4 {
    return _InternetAddress.LOOPBACK_IP_V4;
  }

  /* patch */ static InternetAddress get LOOPBACK_IP_V6 {
    return _InternetAddress.LOOPBACK_IP_V6;
  }

  /* patch */ static InternetAddress get ANY_IP_V4 {
    return _InternetAddress.ANY_IP_V4;
  }

  /* patch */ static InternetAddress get ANY_IP_V6 {
    return _InternetAddress.ANY_IP_V6;
  }

  /* patch */ static Future<List<InternetAddress>> lookup(
      String host, {InternetAddressType type: InternetAddressType.ANY}) {
    return _NativeSocket.lookup(host, type: type);
  }
}

patch class NetworkInterface {
  /* patch */ static Future<List<NetworkInterface>> list({
      bool includeLoopback: false,
      bool includeLinkLocal: false,
      InternetAddressType type: InternetAddressType.ANY}) {
    return _NativeSocket.listInterfaces(includeLoopback: includeLoopback,
                                        includeLinkLocal: includeLinkLocal,
                                        type: type);
  }
}

class _InternetAddress implements InternetAddress {
  static const int _ADDRESS_LOOPBACK_IP_V4 = 0;
  static const int _ADDRESS_LOOPBACK_IP_V6 = 1;
  static const int _ADDRESS_ANY_IP_V4 = 2;
  static const int _ADDRESS_ANY_IP_V6 = 3;
  static const int _IPV4_ADDR_OFFSET = 4;
  static const int _IPV6_ADDR_OFFSET = 8;
  static const int _IPV6_ADDR_LENGTH = 16;

  static _InternetAddress LOOPBACK_IP_V4 =
      new _InternetAddress.fixed(_ADDRESS_LOOPBACK_IP_V4);
  static _InternetAddress LOOPBACK_IP_V6 =
      new _InternetAddress.fixed(_ADDRESS_LOOPBACK_IP_V6);
  static _InternetAddress ANY_IP_V4 =
      new _InternetAddress.fixed(_ADDRESS_ANY_IP_V4);
  static _InternetAddress ANY_IP_V6 =
      new _InternetAddress.fixed(_ADDRESS_ANY_IP_V6);

  final InternetAddressType type;
  final String address;
  final String host;
  final Uint8List _sockaddr_storage;

  bool get isLoopback {
    switch (type) {
      case InternetAddressType.IP_V4:
        return _sockaddr_storage[_IPV4_ADDR_OFFSET] == 127;

      case InternetAddressType.IP_V6:
        for (int i = 0; i < _IPV6_ADDR_LENGTH - 1; i++) {
          if (_sockaddr_storage[_IPV6_ADDR_OFFSET + i] != 0) return false;
        }
        int lastByteIndex = _IPV6_ADDR_OFFSET + _IPV6_ADDR_LENGTH - 1;
        return _sockaddr_storage[lastByteIndex] == 1;
    }
  }

  bool get isLinkLocal {
    switch (type) {
      case InternetAddressType.IP_V4:
        // Checking for 169.254.0.0/16.
        return _sockaddr_storage[_IPV4_ADDR_OFFSET] == 169 &&
            _sockaddr_storage[_IPV4_ADDR_OFFSET + 1] == 254;

      case InternetAddressType.IP_V6:
        // Checking for fe80::/10.
        return _sockaddr_storage[_IPV6_ADDR_OFFSET] == 0xFE &&
            (_sockaddr_storage[_IPV6_ADDR_OFFSET + 1] & 0xB0) == 0x80;
    }
  }

  Future<InternetAddress> reverse() => _NativeSocket.reverseLookup(this);

  _InternetAddress(InternetAddressType this.type,
                   String this.address,
                   String this.host,
                   List<int> this._sockaddr_storage);

  factory _InternetAddress.fixed(int id) {
    var sockaddr = _fixed(id);
    switch (id) {
      case _ADDRESS_LOOPBACK_IP_V4:
        return new _InternetAddress(
            InternetAddressType.IP_V4, "127.0.0.1", "localhost", sockaddr);
      case _ADDRESS_LOOPBACK_IP_V6:
        return new _InternetAddress(
            InternetAddressType.IP_V6, "::1", "ip6-localhost", sockaddr);
      case _ADDRESS_ANY_IP_V4:
        return new _InternetAddress(
            InternetAddressType.IP_V4, "0.0.0.0", "0.0.0.0", sockaddr);
      case _ADDRESS_ANY_IP_V6:
        return new _InternetAddress(
            InternetAddressType.IP_V6, "::", "::", sockaddr);
      default:
        assert(false);
        throw new ArgumentError();
    }
  }

  // Create a clone of this _InternetAddress replacing the host.
  _InternetAddress _cloneWithNewHost(String host) {
    return new _InternetAddress(
        type, address, host, new Uint8List.fromList(_sockaddr_storage));
  }

  String toString() {
    return "InternetAddress('$address', ${type.name})";
  }

  static Uint8List _fixed(int id) native "InternetAddress_Fixed";
}

class _NetworkInterface implements NetworkInterface {
  final String name;
  final List<InternetAddress> addresses;

  _NetworkInterface(String this.name, List<InternetAddress> this.addresses);

  String toString() {
    return "NetworkInterface('$name', $addresses)";
  }
}


// The _NativeSocket class encapsulates an OS socket.
class _NativeSocket extends NativeFieldWrapperClass1 {
  // Bit flags used when communicating between the eventhandler and
  // dart code. The EVENT flags are used to indicate events of
  // interest when sending a message from dart code to the
  // eventhandler. When receiving a message from the eventhandler the
  // EVENT flags indicate the events that actually happened. The
  // COMMAND flags are used to send commands from dart to the
  // eventhandler. COMMAND flags are never received from the
  // eventhandler. Additional flags are used to communicate other
  // information.
  static const int READ_EVENT = 0;
  static const int WRITE_EVENT = 1;
  static const int ERROR_EVENT = 2;
  static const int CLOSED_EVENT = 3;
  static const int DESTROYED_EVENT = 4;
  static const int FIRST_EVENT = READ_EVENT;
  static const int LAST_EVENT = DESTROYED_EVENT;
  static const int EVENT_COUNT = LAST_EVENT - FIRST_EVENT + 1;

  static const int CLOSE_COMMAND = 8;
  static const int SHUTDOWN_READ_COMMAND = 9;
  static const int SHUTDOWN_WRITE_COMMAND = 10;
  static const int FIRST_COMMAND = CLOSE_COMMAND;
  static const int LAST_COMMAND = SHUTDOWN_WRITE_COMMAND;

  // Type flag send to the eventhandler providing additional
  // information on the type of the file descriptor.
  static const int LISTENING_SOCKET = 16;
  static const int PIPE_SOCKET = 17;
  static const int TYPE_NORMAL_SOCKET = 0;
  static const int TYPE_LISTENING_SOCKET = 1 << LISTENING_SOCKET;
  static const int TYPE_PIPE = 1 << PIPE_SOCKET;

  // Native port messages.
  static const HOST_NAME_LOOKUP = 0;
  static const LIST_INTERFACES = 1;
  static const REVERSE_LOOKUP = 2;

  // Socket close state
  bool isClosed = false;
  bool isClosing = false;
  bool isClosedRead = false;
  bool isClosedWrite = false;
  Completer closeCompleter = new Completer();

  // Handlers and receive port for socket events from the event handler.
  int eventMask = 0;
  List eventHandlers;
  ReceivePort eventPort;

  // Indicates if native interrupts can be activated.
  bool canActivateEvents = true;

  // The type flags for this socket.
  final int typeFlags;

  // Holds the port of the socket, null if not known.
  int localPort;

  // Holds the address used to connect or bind the socket.
  InternetAddress address;

  static Future<List<InternetAddress>> lookup(
      String host, {InternetAddressType type: InternetAddressType.ANY}) {
    return _IOService.dispatch(_SOCKET_LOOKUP, [host, type._value])
        .then((response) {
          if (isErrorResponse(response)) {
            throw createError(response, "Failed host lookup: '$host'");
          } else {
            return response.skip(1).map((result) {
              var type = new InternetAddressType._from(result[0]);
              return new _InternetAddress(type, result[1], host, result[2]);
            }).toList();
          }
        });
  }

  static Future<InternetAddress> reverseLookup(InternetAddress addr) {
    return _IOService.dispatch(_SOCKET_REVERSE_LOOKUP, [addr._sockaddr_storage])
        .then((response) {
          if (isErrorResponse(response)) {
            throw createError(response, "Failed reverse host lookup", addr);
          } else {
            return addr._cloneWithNewHost(response);
          }
        });
  }

  static Future<List<NetworkInterface>> listInterfaces({
      bool includeLoopback: false,
      bool includeLinkLocal: false,
      InternetAddressType type: InternetAddressType.ANY}) {
    return _IOService.dispatch(_SOCKET_LIST_INTERFACES, [type._value])
        .then((response) {
          if (isErrorResponse(response)) {
            throw createError(response, "Failed listing interfaces");
          } else {
            var list = new List<NetworkInterface>();
            var map = response.skip(1)
                .fold(new Map<String, List<InternetAddress>>(), (map, result) {
                  var type = new InternetAddressType._from(result[0]);
                  var name = result[3];
                  var address = new _InternetAddress(
                      type, result[1], "", result[2]);
                  if (!includeLinkLocal && address.isLinkLocal) return map;
                  if (!includeLoopback && address.isLoopback) return map;
                  map.putIfAbsent(name, () => new List<InternetAddress>());
                  map[name].add(address);
                  return map;
                })
                .forEach((name, addresses) {
                  list.add(new _NetworkInterface(name, addresses));
                });
            return list;
          }
        });
  }

  static Future<_NativeSocket> connect(host, int port) {
    return new Future.value(host)
        .then((host) {
          if (host is _InternetAddress) return host;
          return lookup(host)
              .then((list) {
                if (list.length == 0) {
                  throw createError(response, "Failed host lookup: '$host'");
                }
                return list[0];
              });
        })
        .then((address) {
          var socket = new _NativeSocket.normal();
          socket.address = address;
          var result = socket.nativeCreateConnect(
              address._sockaddr_storage, port);
          if (result is OSError) {
            throw createError(result, "Connection failed", address, port);
          } else {
            socket.port;  // Query the local port, for error messages.
            var completer = new Completer();
            // Setup handlers for receiving the first write event which
            // indicate that the socket is fully connected.
            socket.setHandlers(
                write: () {
                  socket.setListening(read: false, write: false);
                  completer.complete(socket);
                },
                error: (e) {
                  socket.close();
                  completer.completeError(e);
                }
            );
            socket.setListening(read: false, write: true);
            return completer.future;
          }
        });
  }

  static Future<_NativeSocket> bind(host,
                                    int port,
                                    int backlog,
                                    bool v6Only) {
    return new Future.value(host)
        .then((host) {
          if (host is _InternetAddress) return host;
          return lookup(host)
              .then((list) {
                if (list.length == 0) {
                  throw createError(response, "Failed host lookup: '$host'");
                }
                return list[0];
              });
        })
        .then((address) {
          var socket = new _NativeSocket.listen();
          socket.address = address;
          var result = socket.nativeCreateBindListen(address._sockaddr_storage,
                                                     port,
                                                     backlog,
                                                     v6Only);
          if (result is OSError) {
            throw new SocketException("Failed to create server socket",
                                      osError: result,
                                      address: address,
                                      port: port);
          }
          if (port != 0) socket.localPort = port;
          return socket;
        });
  }

  _NativeSocket.normal() : typeFlags = TYPE_NORMAL_SOCKET {
    eventHandlers = new List(EVENT_COUNT + 1);
  }

  _NativeSocket.listen() : typeFlags = TYPE_LISTENING_SOCKET {
    eventHandlers = new List(EVENT_COUNT + 1);
  }

  _NativeSocket.pipe() : typeFlags = TYPE_PIPE {
    eventHandlers = new List(EVENT_COUNT + 1);
  }

  _NativeSocket.watch(int id) : typeFlags = TYPE_NORMAL_SOCKET {
    eventHandlers = new List(EVENT_COUNT + 1);
    isClosedWrite = true;
    nativeSetSocketId(id);
  }

  int available() {
    if (isClosing || isClosed) return 0;
    var result = nativeAvailable();
    if (result is OSError) {
      reportError(result, "Available failed");
      return 0;
    } else {
      return result;
    }
  }

  List<int> read(int len) {
    if (len != null && len <= 0) {
      throw new ArgumentError("Illegal length $len");
    }
    if (isClosing || isClosed) return null;
    var result = nativeRead(len == null ? -1 : len);
    if (result is OSError) {
      reportError(result, "Read failed");
      return null;
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
      reportError(result, "Write failed");
      result = 0;
    }
    return result;
  }

  _NativeSocket accept() {
    // Don't issue accept if we're closing.
    if (isClosing || isClosed) return null;
    var socket = new _NativeSocket.normal();
    if (nativeAccept(socket) != true) return null;
    socket.localPort = localPort;
    socket.address = address;
    return socket;
  }

  int get port {
    if (localPort != null) return localPort;
    return localPort = nativeGetPort();
  }

  int get remotePort {
    return nativeGetRemotePeer()[1];
  }

  String get remoteHost {
    return nativeGetRemotePeer()[0];
  }

  // Multiplexes socket events to the socket handlers.
  void multiplex(int events) {
    canActivateEvents = false;
    for (int i = FIRST_EVENT; i <= LAST_EVENT; i++) {
      if (((events & (1 << i)) != 0)) {
        if (i == CLOSED_EVENT &&
            typeFlags != TYPE_LISTENING_SOCKET &&
            !isClosing &&
            !isClosed) {
          isClosedRead = true;
        }

        var handler = eventHandlers[i];
        if (i == DESTROYED_EVENT) {
          assert(!isClosed);
          isClosed = true;
          closeCompleter.complete(this);
          disconnectFromEventHandler();
          if (handler != null) handler();
          continue;
        }
        assert(handler != null);
        if (i == WRITE_EVENT) {
          // If the event was disabled before we had a chance to fire the event,
          // discard it. If we register again, we'll get a new one.
          if ((eventMask & (1 << i)) == 0) continue;
          // Unregister the out handler before executing it. There is
          // no need to notify the eventhandler as handlers are
          // disabled while the event is handled.
          eventMask &= ~(1 << i);
        }

        // Don't call the in handler if there is no data available
        // after all.
        if (i == READ_EVENT &&
            typeFlags != TYPE_LISTENING_SOCKET &&
            available() == 0) {
          continue;
        }
        if (i == ERROR_EVENT) {
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
    if (isClosedRead && isClosedWrite) close();
    canActivateEvents = true;
    activateHandlers();
  }

  void setHandlers({read, write, error, closed, destroyed}) {
    eventHandlers[READ_EVENT] = read;
    eventHandlers[WRITE_EVENT] = write;
    eventHandlers[ERROR_EVENT] = error;
    eventHandlers[CLOSED_EVENT] = closed;
    eventHandlers[DESTROYED_EVENT] = destroyed;
  }

  void setListening({read: true, write: true}) {
    eventMask = (1 << CLOSED_EVENT) | (1 << ERROR_EVENT);
    if (read) eventMask |= (1 << READ_EVENT);
    if (write) eventMask |= (1 << WRITE_EVENT);
    activateHandlers();
  }

  Future<_NativeSocket> get closeFuture => closeCompleter.future;

  void activateHandlers() {
    if (canActivateEvents && !isClosing && !isClosed) {
      if ((eventMask & ((1 << READ_EVENT) | (1 << WRITE_EVENT))) == 0) {
        // If we don't listen for either read or write, disconnect as we won't
        // get close and error events anyway.
        if (eventPort != null) disconnectFromEventHandler();
      } else {
        int data = eventMask;
        if (isClosedRead) data &= ~(1 << READ_EVENT);
        if (isClosedWrite) data &= ~(1 << WRITE_EVENT);
        data |= typeFlags;
        sendToEventHandler(data);
      }
    }
  }

  Future<_NativeSocket> close() {
    if (!isClosing && !isClosed) {
      sendToEventHandler(1 << CLOSE_COMMAND);
      isClosing = true;
    }
    return closeFuture;
  }

  void shutdown(SocketDirection direction) {
    if (!isClosing && !isClosed) {
      switch (direction) {
        case SocketDirection.RECEIVE:
          shutdownRead();
          break;
        case SocketDirection.SEND:
          shutdownWrite();
          break;
        case SocketDirection.BOTH:
          close();
          break;
        default:
          throw new ArgumentError(direction);
      }
    }
  }

  void shutdownWrite() {
    if (!isClosing && !isClosed) {
      if (isClosedRead) {
        close();
      } else {
        sendToEventHandler(1 << SHUTDOWN_WRITE_COMMAND);
      }
      isClosedWrite = true;
    }
  }

  void shutdownRead() {
    if (!isClosing && !isClosed) {
      if (isClosedWrite) {
        close();
      } else {
        sendToEventHandler(1 << SHUTDOWN_READ_COMMAND);
      }
      isClosedRead = true;
    }
  }

  void sendToEventHandler(int data) {
    connectToEventHandler();
    assert(!isClosed);
    _EventHandler._sendData(this, eventPort, data);
  }

  void connectToEventHandler() {
    if (eventPort == null) {
      eventPort = new ReceivePort();
      eventPort.receive ((var message, _) => multiplex(message));
    }
  }

  void disconnectFromEventHandler() {
    if (eventPort != null) {
      eventPort.close();
      eventPort = null;
    }
  }

  // Check whether this is an error response from a native port call.
  static bool isErrorResponse(response) {
    return response is List && response[0] != _SUCCESS_RESPONSE;
  }

  // Create the appropriate error/exception from different returned
  // error objects.
  static createError(error,
                     String message,
                     [InternetAddress address,
                      int port]) {
    if (error is OSError) {
      return new SocketException(
          message, osError: error, address: address, port: port);
    } else if (error is List) {
      assert(isErrorResponse(error));
      switch (error[0]) {
        case _ILLEGAL_ARGUMENT_RESPONSE:
          return new ArgumentError();
        case _OSERROR_RESPONSE:
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
    if (eventHandlers[ERROR_EVENT] != null) {
      eventHandlers[ERROR_EVENT](e);
    }
    // For all errors we close the socket
    close();
  }

  bool setOption(SocketOption option, bool enabled) {
    if (option is! SocketOption) throw new ArgumentError(options);
    if (enabled is! bool) throw new ArgumentError(enabled);
    return nativeSetOption(option._value, enabled);
  }

  void nativeSetSocketId(int id) native "Socket_SetSocketId";
  nativeAvailable() native "Socket_Available";
  nativeRead(int len) native "Socket_Read";
  nativeWrite(List<int> buffer, int offset, int bytes)
      native "Socket_WriteList";
  nativeCreateConnect(List<int> addr,
                      int port) native "Socket_CreateConnect";
  nativeCreateBindListen(List<int> addr, int port, int backlog, bool v6Only)
      native "ServerSocket_CreateBindListen";
  nativeAccept(_NativeSocket socket) native "ServerSocket_Accept";
  int nativeGetPort() native "Socket_GetPort";
  List nativeGetRemotePeer() native "Socket_GetRemotePeer";
  OSError nativeGetError() native "Socket_GetError";
  bool nativeSetOption(int option, bool enabled) native "Socket_SetOption";
}


class _RawServerSocket extends Stream<RawSocket>
                       implements RawServerSocket {
  final _NativeSocket _socket;
  StreamController<RawSocket> _controller;

  static Future<_RawServerSocket> bind(address,
                                       int port,
                                       int backlog,
                                       bool v6Only) {
    if (port < 0 || port > 0xFFFF)
      throw new ArgumentError("Invalid port $port");
    if (backlog < 0) throw new ArgumentError("Invalid backlog $backlog");
    return _NativeSocket.bind(address, port, backlog, v6Only)
        .then((socket) => new _RawServerSocket(socket));
  }

  _RawServerSocket(this._socket) {
    _controller = new StreamController(sync: true,
        onListen: _onSubscriptionStateChange,
        onCancel: _onSubscriptionStateChange,
        onPause: _onPauseStateChange,
        onResume: _onPauseStateChange);
    _socket.closeFuture.then((_) => _controller.close());
    _socket.setHandlers(
      read: () {
        var socket = _socket.accept();
        if (socket != null) _controller.add(new _RawSocket(socket));
      },
      error: (e) {
        _controller.addError(e);
        _controller.close();
      }
    );
  }

  StreamSubscription<RawSocket> listen(void onData(RawSocket event),
                                       {Function onError,
                                        void onDone(),
                                        bool cancelOnError}) {
    return _controller.stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError);
  }

  int get port => _socket.port;

  InternetAddress get address => _socket.address;

  Future close() => _socket.close().then((_) => this);

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
      close();
    }
  }

  void _onPauseStateChange() {
    if (_controller.isPaused) {
      _pause();
    } else {
      _resume();
    }
  }
}


class _RawSocket extends Stream<RawSocketEvent>
                 implements RawSocket {
  final _NativeSocket _socket;
  StreamController<RawSocketEvent> _controller;
  bool _readEventsEnabled = true;
  bool _writeEventsEnabled = true;

  // Flag to handle Ctrl-D closing of stdio on Mac OS.
  bool _isMacOSTerminalInput = false;

  static Future<RawSocket> connect(host, int port) {
    return _NativeSocket.connect(host, port)
        .then((socket) => new _RawSocket(socket));
  }

  _RawSocket(this._socket) {
    _controller = new StreamController(sync: true,
        onListen: _onSubscriptionStateChange,
        onCancel: _onSubscriptionStateChange,
        onPause: _onPauseStateChange,
        onResume: _onPauseStateChange);
    _socket.closeFuture.then((_) => _controller.close());
    _socket.setHandlers(
      read: () => _controller.add(RawSocketEvent.READ),
      write: () {
        // The write event handler is automatically disabled by the
        // event handler when it fires.
        _writeEventsEnabled = false;
        _controller.add(RawSocketEvent.WRITE);
      },
      closed: () => _controller.add(RawSocketEvent.READ_CLOSED),
      destroyed: () => _controller.add(RawSocketEvent.CLOSED),
      error: (e) {
        _controller.addError(e);
        close();
      }
    );
  }

  factory _RawSocket._writePipe(int fd) {
    var native = new _NativeSocket.pipe();
    native.isClosedRead = true;
    if (fd != null) _getStdioHandle(native, fd);
    return new _RawSocket(native);
  }

  factory _RawSocket._readPipe(int fd) {
    var native = new _NativeSocket.pipe();
    native.isClosedWrite = true;
    if (fd != null) _getStdioHandle(native, fd);
    var result = new _RawSocket(native);
    result._isMacOSTerminalInput =
        Platform.isMacOS &&
        _StdIOUtils._socketType(result._socket) == _STDIO_HANDLE_TYPE_TERMINAL;
    return result;
  }

  StreamSubscription<RawSocketEvent> listen(void onData(RawSocketEvent event),
                                            {Function onError,
                                             void onDone(),
                                             bool cancelOnError}) {
    return _controller.stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError);
  }

  int available() => _socket.available();

  List<int> read([int len]) {
    if (_isMacOSTerminalInput) {
      var available = available();
      if (available == 0) return null;
      var data = _socket.read(len);
      if (data == null || data.length < available) {
        // Reading less than available from a Mac OS terminal indicate Ctrl-D.
        // This is interpreted as read closed.
        runAsync(() => _controller.add(RawSocketEvent.READ_CLOSED));
      }
      return data;
    } else {
      return _socket.read(len);
    }
  }

  int write(List<int> buffer, [int offset, int count]) =>
      _socket.write(buffer, offset, count);

  Future close() => _socket.close().then((_) => this);

  void shutdown(SocketDirection direction) => _socket.shutdown(direction);

  int get port => _socket.port;

  int get remotePort => _socket.remotePort;

  InternetAddress get address => _socket.address;

  String get remoteHost => _socket.remoteHost;

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
      close();
    }
  }
}


patch class ServerSocket {
  /* patch */ static Future<ServerSocket> bind(address,
                                               int port,
                                               {int backlog: 0,
                                                bool v6Only: false}) {
    return _ServerSocket.bind(address, port, backlog, v6Only);
  }
}

class _ServerSocket extends Stream<Socket>
                    implements ServerSocket {
  final _socket;

  static Future<_ServerSocket> bind(address,
                                    int port,
                                    int backlog,
                                    bool v6Only) {
    return _RawServerSocket.bind(address, port, backlog, v6Only)
        .then((socket) => new _ServerSocket(socket));
  }

  _ServerSocket(this._socket);

  StreamSubscription<Socket> listen(void onData(Socket event),
                                    {Function onError,
                                     void onDone(),
                                     bool cancelOnError}) {
    return _socket.map((rawSocket) => new _Socket(rawSocket)).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError);
  }

  int get port => _socket.port;

  InternetAddress get address => _socket.address;

  Future close() => _socket.close().then((_) => this);
}


patch class Socket {
  /* patch */ static Future<Socket> connect(host, int port) {
    return RawSocket.connect(host, port).then(
        (socket) => new _Socket(socket));
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
      subscription = stream.listen(
          (data) {
            assert(!paused);
            assert(buffer == null);
            buffer = data;
            offset = 0;
            write();
          },
          onError: (error, [stackTrace]) {
            socket._consumerDone();
            done(error, stackTrace);
          },
          onDone: () {
            done();
          },
          cancelOnError: true);
    }
    return streamCompleter.future;
  }

  Future<Socket> close() {
    socket._consumerDone();
    return new Future.value(socket);
  }

  void write() {
    try {
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
    } catch (e) {
      stop();
      socket._consumerDone();
      done(e);
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
  RawSocket _raw;  // Set to null when the raw socket is closed.
  bool _closed = false;  // Set to true when the raw socket is closed.
  StreamController _controller;
  bool _controllerClosed = false;
  _SocketStreamConsumer _consumer;
  IOSink _sink;
  var _subscription;
  var _detachReady;

  _Socket(RawSocket this._raw) {
    _controller = new StreamController<List<int>>(sync: true,
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

  factory _Socket._writePipe([int fd]) {
    return new _Socket(new _RawSocket._writePipe(fd));
  }

  factory _Socket._readPipe([int fd]) {
    return new _Socket(new _RawSocket._readPipe(fd));
  }

  _NativeSocket get _nativeSocket => _raw._socket;

  StreamSubscription<List<int>> listen(void onData(List<int> event),
                                       {Function onError,
                                        void onDone(),
                                        bool cancelOnError}) {
    return _controller.stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError);
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

  Future<Socket> addStream(Stream<List<int>> stream) {
    return _sink.addStream(stream);
  }

  Future<Socket> close() => _sink.close();

  Future<Socket> get done => _sink.done;

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

  int get port => _raw.port;
  String get remoteHost => _raw.remoteHost;
  int get remotePort => _raw.remotePort;

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
                                  onError: _onError,
                                  onDone: _onDone,
                                  cancelOnError: true);
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
        _raw.shutdown(SocketDirection.RECEIVE);
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
      case RawSocketEvent.READ:
        var buffer = _raw.read();
        if (buffer != null) _controller.add(buffer);
        break;
      case RawSocketEvent.WRITE:
        _consumer.write();
        break;
      case RawSocketEvent.READ_CLOSED:
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
        _raw.shutdown(SocketDirection.SEND);
        _disableWriteEvent();
      }
    }
  }
}
