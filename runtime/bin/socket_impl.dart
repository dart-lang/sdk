// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SocketIOException {
  const SocketIOException([String message = ""]) : message_ = message;
  String getMessage() { return message_; }
  final String message_;
}

/*
 * SocketNativeWrapper is defined in native and holds a field to store the
 * native socket object.
 */
class SocketBase {

  /*
   * Keep these constants in sync with the native poll event identifiers.
   */
  static final int _IN_EVENT = 0;
  static final int _OUT_EVENT = 1;
  static final int _ERROR_EVENT = 2;
  static final int _CLOSE_EVENT = 3;
  static final int _CLOSE_COMMAND = 4;

  SocketBase () {
    _handler = new ReceivePort();
    _handlerMap = new List(_CLOSE_EVENT + 1);
    _handlerMask = 0;
    _canActivateHandlers = true;
    _id = 0;
    _handler.receive((var message, ignored) {
      _multiplex(message);
    });
    EventHandler._start();
  }

  /*
   * Multiplexes socket events to the right socket handler.
   */
  void _multiplex(List<int> message) {
    assert(message.length == 1);
    _canActivateHandlers = false;
    int event_mask = message[0];
      for (int i = _IN_EVENT; i <= _CLOSE_EVENT; i++) {
        if (((event_mask & (1 << i)) != 0) && _handlerMap[i] !== null) {
          var handleEvent = _handlerMap[i];
          /*
           * Unregister the out handler before executing it.
           */
          if (i == _OUT_EVENT) {
            _setHandler(i, null);
          }
          handleEvent();
        }
      }
    _canActivateHandlers = true;
    _doActivateHandlers();
  }

  void _setHandler(int event, void callback()) {
    if (callback === null) {
      _handlerMask &= ~(1 << event);
    } else {
      _handlerMask |= (1 << event);
    }
    _handlerMap[event] = callback;
    _doActivateHandlers();
  }

  void _getPort() native "Socket_GetPort";

  void setErrorHandler(void callback()) {
    _setHandler(_ERROR_EVENT, callback);
  }

  void _doActivateHandlers() {
    if (_canActivateHandlers && (_id >= 0)) {
      EventHandler._sendData(_id, _handler, _handlerMask);
    }
  }

  int get port() {
    if (_port == null) {
      _port = _getPort();
    }
    return _port;
  }

  void close() {
    if (_id >= 0) {
      EventHandler._sendData(_id, _handler, 1 << _CLOSE_COMMAND);
      _handler.close();
      _id = -1;
    } else {
      throw new
          SocketIOException("Error: close failed - invalid socket handle");
    }
  }


  /*
   * Socket id is set from native. -1 indicates that the socket was closed.
   */
  int _id;

  /*
   * Dedicated ReceivePort for socket events.
   */
  ReceivePort _handler;

  /*
   * Poll event to handler map.
   */
  List _handlerMap;

  /*
   * Indicates for which poll events the socket registered handlers.
   */
  int _handlerMask;

  /*
   * Indicates if native interrupts can be activated.
   */
  bool _canActivateHandlers;

  /*
   * Holds the port of the socket, null if not known.
   */
  int _port;
}


class _ServerSocket extends SocketBase implements ServerSocket {
  /*
   * Constructor for server socket. First a socket object is allocated
   * in which the native socket is stored. After that _createBind
   * is called which creates a file descriptor and binds the given address
   * and port to the socket. Null is returned if file descriptor creation or
   * bind failed.
   */
  factory _ServerSocket(String bindAddress, int port, int backlog) {
    ServerSocket socket = new _ServerSocket._internal();
    if (!socket._createBindListen(bindAddress, port, backlog)) {
      return null;
    }
    if (port != 0) {
      socket._port = port;
    }
    return socket;
  }

  _ServerSocket._internal() : super() {}

  Socket accept() {
    if (_id >= 0) {
      _Socket socket = new _Socket._internal();
      if (_accept(socket)) {
        return socket;
      }
      return null;
    }
    throw new
        SocketIOException("Error: accept failed - invalid socket handle");
  }

  bool _accept(Socket socket) native "ServerSocket_Accept";

  bool _createBindListen(String bindAddress, int port, int backlog)
      native "ServerSocket_CreateBindListen";

  void setConnectionHandler(void callback()) {
    _setHandler(_IN_EVENT, callback);
  }
}


class _Socket extends SocketBase implements Socket {
  /*
   * Constructor for socket. First a socket object is allocated
   * in which the native socket is stored. After that _createConnect is
   * called which creates a file discriptor and connects to the given
   * host on the given port. Null is returned if file descriptor creation
   * or connect failsed
   */
  factory _Socket(String host, int port) {
    Socket socket = new _Socket._internal();
    if (!socket._createConnect(host, port)) {
      return null;
    }
    return socket;
  }

  _Socket._internal() : super() {}

  int available() {
    if (_id >= 0) {
      return _available();
    }
    throw new
        SocketIOException("Error: available failed - invalid socket handle");
  }

  int _available() native "Socket_Available";

  int readList(List<int> buffer, int offset, int bytes) {
    if (_id >= 0) {
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
      return _readList(buffer, offset, bytes);
    }
    throw new
        SocketIOException("Error: readList failed - invalid socket handle");
  }

  int _readList(List<int> buffer, int offset, int bytes)
      native "Socket_ReadList";

  int writeList(List<int> buffer, int offset, int bytes) {
    if (_id >= 0) {
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
      return _writeList(buffer, offset, bytes);
    }
    throw new
        SocketIOException("Error: writeList failed - invalid socket handle");
  }

  int _writeList(List<int> buffer, int offset, int bytes)
      native "Socket_WriteList";

  bool _createConnect(String host, int port) native "Socket_CreateConnect";

  void setWriteHandler(void callback()) {
    _setHandler(_OUT_EVENT, callback);
  }

  void setConnectHandler(void callback()) {
    _setHandler(_OUT_EVENT, callback);
  }

  void setDataHandler(void callback()) {
    _setHandler(_IN_EVENT, callback);
  }

  void setCloseHandler(void callback()) {
    _setHandler(_CLOSE_EVENT, callback);
  }

  InputStream get inputStream() {
    if (_inputStream === null) {
      _inputStream = new SocketInputStream(this);
    }
    return _inputStream;
  }

  OutputStream get outputStream() {
    if (_outputStream === null) {
      _outputStream = new SocketOutputStream(this);
    }
    return _outputStream;
  }

  SocketInputStream _inputStream;
  SocketOutputStream _outputStream;
}

