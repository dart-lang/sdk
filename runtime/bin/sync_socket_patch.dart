// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "common_patch.dart";

@patch
class RawSynchronousSocket {
  @patch
  static RawSynchronousSocket connectSync(host, int port) {
    return _RawSynchronousSocket.connectSync(host, port);
  }
}

class _RawSynchronousSocket implements RawSynchronousSocket {
  final _NativeSynchronousSocket _socket;

  _RawSynchronousSocket(this._socket);

  static RawSynchronousSocket connectSync(host, int port) {
    _throwOnBadPort(port);
    return new _RawSynchronousSocket(
        _NativeSynchronousSocket.connectSync(host, port));
  }

  InternetAddress get address => _socket.address;
  int get port => _socket.port;
  InternetAddress get remoteAddress => _socket.remoteAddress;
  int get remotePort => _socket.remotePort;

  int available() => _socket.available;

  void closeSync() => _socket.closeSync();

  int readIntoSync(List<int> buffer, [int start = 0, int end]) =>
      _socket.readIntoSync(buffer, start, end);

  List<int> readSync(int bytes) => _socket.readSync(bytes);

  void shutdown(SocketDirection direction) => _socket.shutdown(direction);

  void writeFromSync(List<int> buffer, [int start = 0, int end]) =>
      _socket.writeFromSync(buffer, start, end);
}

// The NativeFieldWrapperClass1 can not be used with a mixin, due to missing
// implicit constructor.
class _NativeSynchronousSocketNativeWrapper extends NativeFieldWrapperClass1 {}

// The _NativeSynchronousSocket class encapsulates a synchronous OS socket.
class _NativeSynchronousSocket extends _NativeSynchronousSocketNativeWrapper {
  // Socket close state.
  bool isClosed = false;
  bool isClosedRead = false;
  bool isClosedWrite = false;

  // Holds the address used to connect the socket.
  InternetAddress localAddress;

  // Holds the port of the socket, 0 if not known.
  int localPort = 0;

  _ReadWriteResourceInfo resourceInfo;

  static _NativeSynchronousSocket connectSync(host, int port) {
    if (host == null) {
      throw new ArgumentError("Parameter host cannot be null");
    }
    List<_InternetAddress> addresses = null;
    var error = null;
    if (host is _InternetAddress) {
      addresses = [host];
    } else {
      try {
        addresses = lookup(host);
      } catch (e) {
        error = e;
      }
      if (error != null || addresses == null || addresses.isEmpty) {
        throw createError(error, "Failed host lookup: '$host'");
      }
    }
    assert(addresses is List);
    var it = addresses.iterator;
    _NativeSynchronousSocket connectNext() {
      if (!it.moveNext()) {
        // Could not connect. Throw the first connection error we encountered.
        assert(error != null);
        throw error;
      }
      var address = it.current;
      var socket = new _NativeSynchronousSocket();
      socket.localAddress = address;
      var result = socket.nativeCreateConnectSync(address._in_addr, port);
      if (result is OSError) {
        // Keep first error, if present.
        if (error == null) {
          error = createError(result, "Connection failed", address, port);
        }
        return connectNext();
      } else {
        // Query the local port, for error messages.
        try {
          socket.port;
        } catch (e) {
          if (error == null) {
            error = createError(e, "Connection failed", address, port);
          }
          return connectNext();
        }
        setupResourceInfo(socket);
      }
      return socket;
    }

    return connectNext();
  }

  InternetAddress get address => localAddress;
  int get available => nativeAvailable();

  int get port {
    if (localPort != 0) {
      return localPort;
    }
    if (isClosed) {
      throw const SocketException.closed();
    }
    var result = nativeGetPort();
    if (result is OSError) {
      throw result;
    }
    return localPort = result;
  }

  InternetAddress get remoteAddress {
    if (isClosed) {
      throw const SocketException.closed();
    }
    var result = nativeGetRemotePeer();
    if (result is OSError) {
      throw result;
    }
    var addr = result[0];
    return new _InternetAddress(addr[1], null, addr[2]);
  }

  int get remotePort {
    if (isClosed) {
      throw const SocketException.closed();
    }
    var result = nativeGetRemotePeer();
    if (result is OSError) {
      throw result;
    }
    return result[1];
  }

  void closeSync() {
    if (!isClosed) {
      nativeCloseSync();
      _SocketResourceInfo.SocketClosed(resourceInfo);
      isClosed = true;
    }
  }

  // Create the appropriate error/exception from different returned
  // error objects.
  static createError(error, String message,
      [InternetAddress address, int port]) {
    if (error is OSError) {
      return new SocketException(message,
          osError: error, address: address, port: port);
    } else {
      return new SocketException(message, address: address, port: port);
    }
  }

  static List<_InternetAddress> lookup(String host,
      {InternetAddressType type: InternetAddressType.ANY}) {
    var response = _nativeLookupRequest(host, type._value);
    if (response is OSError) {
      throw response;
    }
    List<_InternetAddress> addresses =
        new List<_InternetAddress>(response.length);
    for (int i = 0; i < response.length; ++i) {
      var result = response[i];
      addresses[i] = new _InternetAddress(result[1], host, result[2]);
    }
    return addresses;
  }

  int readIntoSync(List<int> buffer, int start, int end) {
    _checkAvailable();
    if (isClosedRead) {
      throw new SocketException("Socket is closed for reading");
    }

    if ((buffer is! List) ||
        ((start != null) && (start is! int)) ||
        ((end != null) && (end is! int))) {
      throw new ArgumentError("Invalid arguments to readIntoSync");
    }
    if (start == null) {
      throw new ArgumentError("start cannot be null");
    }
    end = RangeError.checkValidRange(start, end, buffer.length);
    if (end == start) {
      return 0;
    }
    var result = nativeReadInto(buffer, start, (end - start));
    if (result is OSError) {
      throw new SocketException("readIntoSync failed", osError: result);
    }
    resourceInfo.addRead(result);
    return result;
  }

  List<int> readSync(int len) {
    _checkAvailable();
    if (isClosedRead) {
      throw new SocketException("Socket is closed for reading");
    }

    if ((len != null) && (len < 0)) {
      throw new ArgumentError("Illegal length $len");
    }
    if (len == 0) {
      return null;
    }
    var result = nativeRead(len);
    if (result is OSError) {
      throw result;
    }
    assert(resourceInfo != null);
    if (result != null) {
      if (resourceInfo != null) {
        resourceInfo.totalRead += result.length;
      }
    }
    if (resourceInfo != null) {
      resourceInfo.didRead();
    }
    return result;
  }

  static void setupResourceInfo(_NativeSynchronousSocket socket) {
    socket.resourceInfo = new _SocketResourceInfo(socket);
  }

  void shutdown(SocketDirection direction) {
    if (isClosed) {
      return;
    }
    switch (direction) {
      case SocketDirection.RECEIVE:
        shutdownRead();
        break;
      case SocketDirection.SEND:
        shutdownWrite();
        break;
      case SocketDirection.BOTH:
        closeSync();
        break;
      default:
        throw new ArgumentError(direction);
    }
  }

  void shutdownRead() {
    if (isClosed || isClosedRead) {
      return;
    }
    if (isClosedWrite) {
      closeSync();
    } else {
      nativeShutdownRead();
    }
    isClosedRead = true;
  }

  void shutdownWrite() {
    if (isClosed || isClosedWrite) {
      return;
    }
    if (isClosedRead) {
      closeSync();
    } else {
      nativeShutdownWrite();
    }
    isClosedWrite = true;
  }

  void writeFromSync(List<int> buffer, int start, int end) {
    _checkAvailable();
    if (isClosedWrite) {
      throw new SocketException("Socket is closed for writing");
    }
    if ((buffer is! List) ||
        ((start != null) && (start is! int)) ||
        ((end != null) && (end is! int))) {
      throw new ArgumentError("Invalid arguments to writeFromSync");
    }
    if (start == null) {
      throw new ArgumentError("start cannot be equal to null");
    }

    end = RangeError.checkValidRange(start, end, buffer.length);
    if (end == start) {
      return;
    }

    _BufferAndStart bufferAndStart =
        _ensureFastAndSerializableByteData(buffer, start, end);
    var result = nativeWrite(bufferAndStart.buffer, bufferAndStart.start,
        end - (start - bufferAndStart.start));
    if (result is OSError) {
      throw new SocketException("writeFromSync failed", osError: result);
    }
    assert(resourceInfo != null);
    if (resourceInfo != null) {
      resourceInfo.addWrite(result);
    }
  }

  void _checkAvailable() {
    if (isClosed) {
      throw const SocketException.closed();
    }
  }

  // Native method declarations.
  static _nativeLookupRequest(host, int type)
      native "SynchronousSocket_LookupRequest";
  nativeCreateConnectSync(host, int port)
      native "SynchronousSocket_CreateConnectSync";
  nativeAvailable() native "SynchronousSocket_Available";
  nativeCloseSync() native "SynchronousSocket_CloseSync";
  int nativeGetPort() native "SynchronousSocket_GetPort";
  List nativeGetRemotePeer() native "SynchronousSocket_GetRemotePeer";
  nativeRead(int len) native "SynchronousSocket_Read";
  nativeReadInto(List<int> buffer, int offset, int bytes)
      native "SynchronousSocket_ReadList";
  nativeShutdownRead() native "SynchronousSocket_ShutdownRead";
  nativeShutdownWrite() native "SynchronousSocket_ShutdownWrite";
  nativeWrite(List<int> buffer, int offset, int bytes)
      native "SynchronousSocket_WriteList";
}
