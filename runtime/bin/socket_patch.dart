// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class RawServerSocket  {
  /* patch */ static Future<RawServerSocket> bind([String address = "127.0.0.1",
                                                   int port = 0,
                                                   int backlog = 0]) {
    return _RawServerSocket.bind(address, port, backlog);
  }
}


patch class RawSocket {
  /* patch */ static Future<RawSocket> connect(String host, int port) {
    return _RawSocket.connect(host, port);
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
  static const int FIRST_EVENT = READ_EVENT;
  static const int LAST_EVENT = CLOSED_EVENT;
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

  // Socket close state
  bool isClosed = false;
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

  // Native port for socket services.
  static SendPort socketService;

  static Future<_NativeSocket> connect(String host, int port) {
    var completer = new Completer();
    ensureSocketService();
    socketService.call([HOST_NAME_LOOKUP, host]).then((response) {
      if (isErrorResponse(response)) {
        completer.completeError(
            createError(response, "Failed host name lookup"));
      } else {
        var socket = new _NativeSocket.normal();
        var result = socket.nativeCreateConnect(response, port);
        if (result is OSError) {
          completer.completeError(createError(result, "Connection failed"));
        } else {
          // Setup handlers for receiving the first write event which
          // indicate that the socket is fully connected.
          socket.setHandlers(
              write: () {
                socket.setListening(read: false, write: false);
                completer.complete(socket);
              },
              error: (e) {
                socket.close();
                completer.completeError(createError(e, "Connection failed"));
              }
          );
          socket.setListening(read: false, write: true);
        }
      }
    });
    return completer.future;
  }

  static Future<_NativeSocket> bind(String address,
                                    int port,
                                    int backlog) {
    var socket = new _NativeSocket.listen();
    var result = socket.nativeCreateBindListen(address, port, backlog);
    if (result is OSError) {
      return new Future.error(
          new SocketIOException("Failed to create server socket", result));
    }
    if (port != 0) socket.localPort = port;
    return new Future.value(socket);
  }

  _NativeSocket.normal() : typeFlags = TYPE_NORMAL_SOCKET {
    eventHandlers = new List(EVENT_COUNT + 1);
    _EventHandler._start();
  }

  _NativeSocket.listen() : typeFlags = TYPE_LISTENING_SOCKET {
    eventHandlers = new List(EVENT_COUNT + 1);
    _EventHandler._start();
  }

  _NativeSocket.pipe() : typeFlags = TYPE_PIPE {
    eventHandlers = new List(EVENT_COUNT + 1);
    _EventHandler._start();
  }

  int available() {
    if (isClosed) return 0;
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
    if (isClosed) return null;
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
    if (bytes == null) bytes = buffer.length;
    if (offset < 0) throw new RangeError.value(offset);
    if (bytes < 0) throw new RangeError.value(bytes);
    if ((offset + bytes) > buffer.length) {
      throw new RangeError.value(offset + bytes);
    }
    if (offset is! int || bytes is! int) {
      throw new ArgumentError("Invalid arguments to write on Socket");
    }
    if (isClosed) return 0;
    if (bytes == 0) return 0;
    _BufferAndStart bufferAndStart =
        _ensureFastAndSerializableBuffer(buffer, offset, offset + bytes);
    var result =
        nativeWrite(bufferAndStart.buffer, bufferAndStart.start, bytes);
    if (result is OSError) {
      reportError(result, "Write failed");
      result = 0;
    }
    return result;
  }

  _NativeSocket accept() {
    var socket = new _NativeSocket.normal();
    if (nativeAccept(socket) != true) return null;
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
            !isClosed) {
          isClosedRead = true;
        }

        var handler = eventHandlers[i];
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
          reportError(nativeGetError(), "");
        } else if (!isClosed) {
          handler();
        }
      }
    }
    if (isClosedRead && isClosedWrite) close();
    canActivateEvents = true;
    activateHandlers();
  }

  void setHandlers({read: null, write: null, error: null, closed: null}) {
    eventHandlers[READ_EVENT] = read;
    eventHandlers[WRITE_EVENT] = write;
    eventHandlers[ERROR_EVENT] = error;
    eventHandlers[CLOSED_EVENT] = closed;
  }

  void setListening({read: true, write: true}) {
    eventMask = (1 << CLOSED_EVENT) | (1 << ERROR_EVENT);
    if (read) eventMask |= (1 << READ_EVENT);
    if (write) eventMask |= (1 << WRITE_EVENT);
    activateHandlers();
  }

  Future get closeFuture => closeCompleter.future;

  void activateHandlers() {
    if (canActivateEvents && !isClosed) {
      // If we don't listen for either read or write, disconnect as we won't
      // get close and error events anyway.
      if ((eventMask & ((1 << READ_EVENT) | (1 << WRITE_EVENT))) == 0) {
        if (eventPort != null) disconnectFromEventHandler();
      } else {
        int data = eventMask;
        data |= typeFlags;
        if (isClosedRead) data &= ~(1 << READ_EVENT);
        if (isClosedWrite) data &= ~(1 << WRITE_EVENT);
        sendToEventHandler(data);
      }
    }
  }

  void close() {
    if (!isClosed) {
      sendToEventHandler(1 << CLOSE_COMMAND);
      isClosed = true;
      closeCompleter.complete(this);
    }
    // Outside the if support closing sockets created but never
    // assigned any actual socket.
    disconnectFromEventHandler();
  }

  void shutdown(SocketDirection direction) {
    if (!isClosed) {
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
    if (!isClosed) {
      if (isClosedRead) {
        close();
      } else {
        sendToEventHandler(1 << SHUTDOWN_WRITE_COMMAND);
      }
      isClosedWrite = true;
    }
  }

  void shutdownRead() {
    if (!isClosed) {
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

  static void ensureSocketService() {
    if (socketService == null) {
      socketService = _NativeSocket.newServicePort();
    }
  }

  // Check whether this is an error response from a native port call.
  static bool isErrorResponse(response) {
    return response is List && response[0] != _SUCCESS_RESPONSE;
  }

  // Create the appropriate error/exception from different returned
  // error objects.
  static createError(error, String message) {
    if (error is OSError) {
      return new SocketIOException(message, error);
    } else if (error is List) {
      assert(isErrorResponse(error));
      switch (error[0]) {
        case _ILLEGAL_ARGUMENT_RESPONSE:
          return new ArgumentError();
        case _OSERROR_RESPONSE:
          return new SocketIOException(
              message, new OSError(error[2], error[1]));
        default:
          return new Exception("Unknown error");
      }
    } else {
      return new SocketIOException(message);
    }
  }

  void reportError(error, String message) {
    var e = createError(error, message);
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

  nativeAvailable() native "Socket_Available";
  nativeRead(int len) native "Socket_Read";
  nativeWrite(List<int> buffer, int offset, int bytes)
      native "Socket_WriteList";
  nativeCreateConnect(String host, int port) native "Socket_CreateConnect";
  nativeCreateBindListen(String address, int port, int backlog)
      native "ServerSocket_CreateBindListen";
  nativeAccept(_NativeSocket socket) native "ServerSocket_Accept";
  int nativeGetPort() native "Socket_GetPort";
  List nativeGetRemotePeer() native "Socket_GetRemotePeer";
  OSError nativeGetError() native "Socket_GetError";
  bool nativeSetOption(int option, bool enabled) native "Socket_SetOption";

  static SendPort newServicePort() native "Socket_NewServicePort";
}


class _RawServerSocket extends Stream<RawSocket>
                       implements RawServerSocket {
  final _NativeSocket _socket;
  StreamController<RawSocket> _controller;

  static Future<_RawServerSocket> bind(String address,
                                       int port,
                                       int backlog) {
    if (port < 0 || port > 0xFFFF)
      throw new ArgumentError("Invalid port $port");
    if (backlog < 0) throw new ArgumentError("Invalid backlog $backlog");
    return _NativeSocket.bind(address, port, backlog)
        .then((socket) => new _RawServerSocket(socket));
  }

  _RawServerSocket(this._socket) {
    _controller = new StreamController(
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
                                       {void onError(Object error),
                                        void onDone(),
                                        bool cancelOnError}) {
    return _controller.stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError);
  }

  int get port => _socket.port;

  void close() => _socket.close();

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

  static Future<RawSocket> connect(String host, int port) {
    return _NativeSocket.connect(host, port)
        .then((socket) => new _RawSocket(socket));
  }

  _RawSocket(this._socket) {
    _controller = new StreamController(
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
    return new _RawSocket(native);
  }

  StreamSubscription<RawSocketEvent> listen(void onData(RawSocketEvent event),
                                            {void onError(Object error),
                                             void onDone(),
                                             bool cancelOnError}) {
    return _controller.stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError);
  }

  int available() => _socket.available();

  List<int> read([int len]) => _socket.read(len);

  int write(List<int> buffer, [int offset, int count]) =>
      _socket.write(buffer, offset, count);

  void close() => _socket.close();

  void shutdown(SocketDirection direction) => _socket.shutdown(direction);

  int get port => _socket.port;

  int get remotePort => _socket.remotePort;

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
  /* patch */ static Future<ServerSocket> bind([String address = "127.0.0.1",
                                                int port = 0,
                                                int backlog = 0]) {
    return _ServerSocket.bind(address, port, backlog);
  }
}

class _ServerSocket extends Stream<Socket>
                    implements ServerSocket {
  final _socket;

  static Future<_ServerSocket> bind(String address,
                                    int port,
                                    int backlog) {
    return _RawServerSocket.bind(address, port, backlog)
        .then((socket) => new _ServerSocket(socket));
  }

  _ServerSocket(this._socket);

  StreamSubscription<Socket> listen(void onData(Socket event),
                                    {void onError(error),
                                     void onDone(),
                                     bool cancelOnError}) {
    return _socket.map((rawSocket) => new _Socket(rawSocket)).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError);
  }

  int get port => _socket.port;

  void close() => _socket.close();
}


patch class Socket {
  /* patch */ static Future<Socket> connect(String host, int port) {
    return RawSocket.connect(host, port).then(
        (socket) => new _Socket(socket));
  }
}


patch class SecureSocket {
  /* patch */ factory SecureSocket._(RawSecureSocket rawSocket) =>
      new _SecureSocket(rawSocket);
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
          onError: (error) {
            socket._consumerDone();
            done(error);
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
          // TODO(ajohnsen): It would be nice to avoid this check.
          // Some info: socket._write can emit an event, if it fails to write.
          // If the user closes the socket in that event, stop() will be called
          // before we get a change to pause.
          if (subscription == null) return;
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

  void done([error]) {
    if (streamCompleter != null) {
      var tmp = streamCompleter;
      streamCompleter = null;
      if (error != null) {
        tmp.completeError(error);
      } else {
        tmp.complete(socket);
      }
    }
  }

  void stop() {
    if (subscription == null) return;
    subscription.cancel();
    subscription = null;
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

  _Socket(RawSocket this._raw) {
    _controller = new StreamController<List<int>>(
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
                                       {void onError(error),
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

  void _onError(error) {
    if (!_controllerClosed) {
      _controllerClosed = true;
      _controller.addError(error);
      _controller.close();
    }
    _consumer.done(error);
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
    if (_raw != null) {
      _raw.shutdown(SocketDirection.SEND);
      _disableWriteEvent();
    }
  }
}


class _SecureSocket extends _Socket implements SecureSocket {
  _SecureSocket(RawSecureSocket raw) : super(raw);

  void set onBadCertificate(bool callback(X509Certificate certificate)) {
    if (_raw == null) {
      throw new StateError("onBadCertificate called on destroyed SecureSocket");
    }
    _raw.onBadCertificate = callback;
  }

  X509Certificate get peerCertificate {
    if (_raw == null) {
     throw new StateError("peerCertificate called on destroyed SecureSocket");
    }
    return _raw.peerCertificate;
  }
}
