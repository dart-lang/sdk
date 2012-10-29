// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _SocketBase extends NativeFieldWrapperClass1 {
  // Bit flags used when communicating between the eventhandler and
  // dart code. The EVENT flags are used to indicate events of
  // interest when sending a message from dart code to the
  // eventhandler. When receiving a message from the eventhandler the
  // EVENT flags indicate the events that actually happened. The
  // COMMAND flags are used to send commands from dart to the
  // eventhandler. COMMAND flags are never received from the
  // eventhandler. Additional flags are used to communicate other
  // information.
  static const int _IN_EVENT = 0;
  static const int _OUT_EVENT = 1;
  static const int _ERROR_EVENT = 2;
  static const int _CLOSE_EVENT = 3;

  static const int _CLOSE_COMMAND = 8;
  static const int _SHUTDOWN_READ_COMMAND = 9;
  static const int _SHUTDOWN_WRITE_COMMAND = 10;

  // Flag send to the eventhandler providing additional information on
  // the type of the file descriptor.
  static const int _LISTENING_SOCKET = 16;
  static const int _PIPE = 17;

  static const int _FIRST_EVENT = _IN_EVENT;
  static const int _LAST_EVENT = _CLOSE_EVENT;

  static const int _FIRST_COMMAND = _CLOSE_COMMAND;
  static const int _LAST_COMMAND = _SHUTDOWN_WRITE_COMMAND;

  _SocketBase () {
    _handlerMap = new List(_LAST_EVENT + 1);
    _handlerMask = 0;
    _canActivateHandlers = true;
    _closed = true;
    _EventHandler._start();
    _hashCode = _nextHashCode;
    _nextHashCode = (_nextHashCode + 1) & 0xFFFFFFF;
  }

  // Multiplexes socket events to the socket handlers.
  void _multiplex(int event_mask) {
    _canActivateHandlers = false;
    for (int i = _FIRST_EVENT; i <= _LAST_EVENT; i++) {
      if (((event_mask & (1 << i)) != 0)) {
        if ((i == _CLOSE_EVENT) && this is _Socket && !_closed) {
          _closedRead = true;
          if (_closedWrite) _close();
        }

        var eventHandler = _handlerMap[i];
        if (eventHandler != null || i == _ERROR_EVENT) {
          // Unregister the out handler before executing it.
          if (i == _OUT_EVENT) _setHandler(i, null);

          // Don't call the in handler if there is no data available
          // after all.
          if ((i == _IN_EVENT) && (this is _Socket) && (available() == 0)) {
            continue;
          }
          if (i == _ERROR_EVENT) {
            _reportError(_getError(), "");
            close();
          } else {
            eventHandler();
          }
        }
      }
    }
    _canActivateHandlers = true;
    _activateHandlers();
  }

  void _setHandler(int event, Function callback) {
    if (callback == null) {
      _handlerMask &= ~(1 << event);
    } else {
      _handlerMask |= (1 << event);
    }
    _handlerMap[event] = callback;
    // If the socket is only for writing then close the receive port
    // when not waiting for any events.
    if (this is _Socket &&
        _closedRead &&
        _handlerMask == 0 &&
        _handler != null) {
      _handler.close();
      _handler = null;
    } else {
      _activateHandlers();
    }
  }

  OSError _getError() native "Socket_GetError";
  int _getPort() native "Socket_GetPort";

  void set onError(void callback(e)) {
    _setHandler(_ERROR_EVENT, callback);
  }

  void _activateHandlers() {
    if (_canActivateHandlers && !_closed) {
      if (_handlerMask == 0) {
        if (_handler != null) {
          _handler.close();
          _handler = null;
        }
        return;
      }
      int data = _handlerMask;
      if (_isListenSocket()) {
        data |= (1 << _LISTENING_SOCKET);
      } else {
        if (_closedRead) { data &= ~(1 << _IN_EVENT); }
        if (_closedWrite) { data &= ~(1 << _OUT_EVENT); }
        if (_isPipe()) data |= (1 << _PIPE);
      }
      _sendToEventHandler(data);
    }
  }

  int get port {
    if (_port === null) {
      _port = _getPort();
    }
    return _port;
  }

  void close([bool halfClose = false]) {
    if (!_closed) {
      if (halfClose) {
        _closeWrite();
      } else {
        _close();
      }
    } else if (_handler != null) {
      // This is to support closing sockets created but never assigned
      // any actual socket.
      _handler.close();
      _handler = null;
    }
  }

  void _closeWrite() {
    if (!_closed) {
      if (_closedRead) {
        _close();
      } else {
        _sendToEventHandler(1 << _SHUTDOWN_WRITE_COMMAND);
      }
      _closedWrite = true;
    }
  }

  void _closeRead() {
    if (!_closed) {
      if (_closedWrite) {
        _close();
      } else {
        _sendToEventHandler(1 << _SHUTDOWN_READ_COMMAND);
      }
      _closedRead = true;
    }
  }

  void _close() {
    if (!_closed) {
      _sendToEventHandler(1 << _CLOSE_COMMAND);
      _handler.close();
      _handler = null;
      _closed = true;
    }
  }

  void _sendToEventHandler(int data) {
    if (_handler === null) {
      _handler = new ReceivePort();
      _handler.receive((var message, ignored) { _multiplex(message); });
    }
    assert(!_closed);
    _EventHandler._sendData(this, _handler, data);
  }

  bool _reportError(error, String message) {
    void doReportError(Exception e) {
      // Invoke the socket error callback if any.
      bool reported = false;
      if (_handlerMap[_ERROR_EVENT] != null) {
        _handlerMap[_ERROR_EVENT](e);
        reported = true;
      }
      // Propagate the error to any additional listeners.
      reported = reported || _propagateError(e);
      if (!reported) throw e;
    }

    // For all errors we close the socket, call the error handler and
    // disable further calls of the error handler.
    close();
    if (error is OSError) {
      doReportError(new SocketIOException(message, error));
    } else if (error is List) {
      assert(_isErrorResponse(error));
      switch (error[0]) {
        case _ILLEGAL_ARGUMENT_RESPONSE:
          doReportError(new ArgumentError());
          break;
        case _OSERROR_RESPONSE:
          doReportError(new SocketIOException(
              message, new OSError(error[2], error[1])));
          break;
        default:
          doReportError(new Exception("Unknown error"));
          break;
      }
    } else {
      doReportError(new SocketIOException(message));
    }
  }

  int get hashCode => _hashCode;

  bool _propagateError(Exception e) => false;

  abstract bool _isListenSocket();
  abstract bool _isPipe();

  // Is this socket closed.
  bool _closed;

  // Dedicated ReceivePort for socket events.
  ReceivePort _handler;

  // Poll event to handler map.
  List _handlerMap;

  // Indicates for which poll events the socket registered handlers.
  int _handlerMask;

  // Indicates if native interrupts can be activated.
  bool _canActivateHandlers;

  // Holds the port of the socket, null if not known.
  int _port;

  // Hash code for the socket. Currently this is just a counter.
  int _hashCode;
  static int _nextHashCode = 0;
  bool _closedRead = false;
  bool _closedWrite = false;
}


class _ServerSocket extends _SocketBase implements ServerSocket {
  // Constructor for server socket. First a socket object is allocated
  // in which the native socket is stored. After that _createBind
  // is called which creates a file descriptor and binds the given address
  // and port to the socket. Null is returned if file descriptor creation or
  // bind failed.
  factory _ServerSocket(String bindAddress, int port, int backlog) {
    _ServerSocket socket = new _ServerSocket._internal();
    var result = socket._createBindListen(bindAddress, port, backlog);
    if (result is OSError) {
      socket.close();
      throw new SocketIOException("Failed to create server socket", result);
    }
    socket._closed = false;
    assert(result);
    if (port != 0) {
      socket._port = port;
    }
    return socket;
  }

  _ServerSocket._internal();

  _accept(Socket socket) native "ServerSocket_Accept";

  _createBindListen(String bindAddress, int port, int backlog)
      native "ServerSocket_CreateBindListen";

  void set onConnection(void callback(Socket connection)) {
    _clientConnectionHandler = callback;
    _setHandler(_SocketBase._IN_EVENT,
                _clientConnectionHandler != null ? _connectionHandler : null);
  }

  void _connectionHandler() {
    if (!_closed) {
      _Socket socket = new _Socket._internal();
      var result = _accept(socket);
      if (result is OSError) {
        _reportError(result, "Accept failed");
      } else if (result) {
        socket._closed = false;
        _clientConnectionHandler(socket);
      } else {
        // Temporary failure accepting the connection. Ignoring
        // temporary failures lets us retry when we wake up with data
        // on the listening socket again.
      }
    }
  }

  bool _isListenSocket() => true;
  bool _isPipe() => false;

  var _clientConnectionHandler;
}


class _Socket extends _SocketBase implements Socket {
  static const HOST_NAME_LOOKUP = 0;

  // Constructs a new socket. During the construction an asynchronous
  // host name lookup is initiated. The returned socket is not yet
  // connected but ready for registration of callbacks.
  factory _Socket(String host, int port) {
    Socket socket = new _Socket._internal();
    _ensureSocketService();
    List request = new List(2);
    request[0] = HOST_NAME_LOOKUP;
    request[1] = host;
    _socketService.call(request).then((response) {
      if (socket._isErrorResponse(response)) {
        socket._reportError(response, "Failed host name lookup");
      } else{
        var result = socket._createConnect(response, port);
        if (result is OSError) {
          socket.close();
          socket._reportError(result, "Connection failed");
        } else {
          socket._closed = false;
          socket._activateHandlers();
        }
      }
    });
    return socket;
  }

  _Socket._internal();
  _Socket._internalReadOnly() : _pipe = true { super._closedWrite = true; }
  _Socket._internalWriteOnly() : _pipe = true { super._closedRead = true; }

  int available() {
    if (!_closed) {
      var result = _available();
      if (result is OSError) {
        _reportError(result, "Available failed");
        return 0;
      } else {
        return result;
      }
    }
    throw new
        SocketIOException("Error: available failed - invalid socket handle");
  }

  _available() native "Socket_Available";

  int readList(List<int> buffer, int offset, int bytes) {
    if (!_closed) {
      if (bytes == 0) {
        return 0;
      }
      if (offset < 0) {
        throw new IndexOutOfRangeException(offset);
      }
      if (bytes < 0) {
        throw new IndexOutOfRangeException(bytes);
      }
      if ((offset + bytes) > buffer.length) {
        throw new IndexOutOfRangeException(offset + bytes);
      }
      var result = _readList(buffer, offset, bytes);
      if (result is OSError) {
        _reportError(result, "Read failed");
        return -1;
      }
      return result;
    }
    throw new
        SocketIOException("Error: readList failed - invalid socket handle");
  }

  _readList(List<int> buffer, int offset, int bytes) native "Socket_ReadList";

  int writeList(List<int> buffer, int offset, int bytes) {
    if (buffer is! List || offset is! int || bytes is! int) {
      throw new ArgumentError(
          "Invalid arguments to writeList on Socket");
    }
    if (!_closed) {
      if (bytes == 0) {
        return 0;
      }
      if (offset < 0) {
        throw new IndexOutOfRangeException(offset);
      }
      if (bytes < 0) {
        throw new IndexOutOfRangeException(bytes);
      }
      if ((offset + bytes) > buffer.length) {
        throw new IndexOutOfRangeException(offset + bytes);
      }
      _BufferAndOffset bufferAndOffset =
          _ensureFastAndSerializableBuffer(buffer, offset, bytes);
      var result =
          _writeList(bufferAndOffset.buffer, bufferAndOffset.offset, bytes);
      if (result is OSError) {
        _reportError(result, "Write failed");
        // If writing fails we return 0 as the number of bytes and
        // report the error on the error handler.
        result = 0;
      }
      return result;
    }
    throw new SocketIOException("writeList failed - invalid socket handle");
  }

  _writeList(List<int> buffer, int offset, int bytes)
      native "Socket_WriteList";

  bool _isErrorResponse(response) {
    return response is List && response[0] != _SUCCESS_RESPONSE;
  }

  bool _createConnect(String host, int port) native "Socket_CreateConnect";

  void set onWrite(void callback()) {
    if (_outputStream != null) throw new StreamException(
            "Cannot set write handler when output stream is used");
    _clientWriteHandler = callback;
    _updateOutHandler();
  }

  void set onConnect(void callback()) {
    if (_seenFirstOutEvent || _outputStream != null) {
      throw new StreamException(
          "Cannot set connect handler when already connected");
    }
    if (_outputStream != null) {
      throw new StreamException(
          "Cannot set connect handler when output stream is used");
    }
    _clientConnectHandler = callback;
    _updateOutHandler();
  }

  void set onData(void callback()) {
    if (_inputStream != null) throw new StreamException(
            "Cannot set data handler when input stream is used");
    _onData = callback;
  }

  void set onClosed(void callback()) {
    if (_inputStream != null) throw new StreamException(
           "Cannot set close handler when input stream is used");
    _onClosed = callback;
  }

  bool _isListenSocket() => false;

  bool _isPipe() => _pipe;

  InputStream get inputStream {
    if (_inputStream == null) {
      if (_handlerMap[_SocketBase._IN_EVENT] !== null ||
          _handlerMap[_SocketBase._CLOSE_EVENT] !== null) {
        throw new StreamException(
            "Cannot get input stream when socket handlers are used");
      }
      _inputStream = new _SocketInputStream(this);
    }
    return _inputStream;
  }

  OutputStream get outputStream {
    if (_outputStream == null) {
      if (_handlerMap[_SocketBase._OUT_EVENT] !== null) {
        throw new StreamException(
            "Cannot get input stream when socket handlers are used");
      }
      _outputStream = new _SocketOutputStream(this);
    }
    return _outputStream;
  }

  void set _onWrite(void callback()) {
    _setHandler(_SocketBase._OUT_EVENT, callback);
  }

  void set _onData(void callback()) {
    _setHandler(_SocketBase._IN_EVENT, callback);
  }

  void set _onClosed(void callback()) {
    _setHandler(_SocketBase._CLOSE_EVENT, callback);
  }

  bool _propagateError(Exception e) {
    bool reported = false;
    if (_inputStream != null) {
      reported = reported || _inputStream._onSocketError(e);
    }
    if (_outputStream != null) {
      reported = reported || _outputStream._onSocketError(e);
    }
    return reported;
  }

  void _updateOutHandler() {
    void firstWriteHandler() {
      assert(!_seenFirstOutEvent);
      _seenFirstOutEvent = true;

      // From now on the write handler is only the client write
      // handler (connect handler cannot be called again). Change this
      // before calling any handlers as handlers can change the
      // handlers.
      if (_clientWriteHandler === null) _onWrite = _clientWriteHandler;

      // First out event is socket connected event.
      if (_clientConnectHandler !== null) _clientConnectHandler();
      _clientConnectHandler = null;

      // Always (even for the first out event) call the write handler.
      if (_clientWriteHandler !== null) _clientWriteHandler();
    }

    if (_clientConnectHandler === null && _clientWriteHandler === null) {
      _onWrite = null;
    } else {
      if (_seenFirstOutEvent) {
        _onWrite = _clientWriteHandler;
      } else {
        _onWrite = firstWriteHandler;
      }
    }
  }

  int get remotePort {
    if (_remotePort === null) {
      remoteHost;
    }
    return _remotePort;
  }

  String get remoteHost {
    if (_remoteHost === null) {
      List peer = _getRemotePeer();
      _remoteHost = peer[0];
      _remotePort = peer[1];
    }
    return _remoteHost;
  }

  List _getRemotePeer() native "Socket_GetRemotePeer";

  static SendPort _newServicePort() native "Socket_NewServicePort";

  static void _ensureSocketService() {
    if (_socketService == null) {
      _socketService = _Socket._newServicePort();
    }
  }

  bool _seenFirstOutEvent = false;
  bool _pipe = false;
  Function _clientConnectHandler;
  Function _clientWriteHandler;
  _SocketInputStream _inputStream;
  _SocketOutputStream _outputStream;
  String _remoteHost;
  int _remotePort;
  static SendPort _socketService;
}
