// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _BaseDataInputStream {
  abstract int available();

  List<int> read([int len]) {
    if (_closeCallbackCalled || _scheduledCloseCallback != null) return null;
    int bytesToRead = available();
    if (bytesToRead == 0) {
      _checkScheduleCallbacks();
      return null;
    }
    if (len !== null) {
      if (len <= 0) {
        throw new StreamException("Illegal length $len");
      } else if (bytesToRead > len) {
        bytesToRead = len;
      }
    }
    return _read(bytesToRead);
  }

  int readInto(List<int> buffer, [int offset = 0, int len]) {
    if (_closeCallbackCalled || _scheduledCloseCallback != null) return 0;
    if (len === null) len = buffer.length;
    if (offset < 0) throw new StreamException("Illegal offset $offset");
    if (len < 0) throw new StreamException("Illegal length $len");
    int bytesToRead = min(len, available());
    return _readInto(buffer, offset, bytesToRead);
  }

  void pipe(OutputStream output, [bool close = true]) {
    _pipe(this, output, close: close);
  }

  void close() {
    _cancelScheduledDataCallback();
    _close();
    _checkScheduleCallbacks();
  }

  bool get closed => _closeCallbackCalled;

  void set onData(void callback()) {
    _clientDataHandler = callback;
    _checkScheduleCallbacks();
  }

  void set onClosed(void callback()) {
    _clientCloseHandler = callback;
    _checkScheduleCallbacks();
  }

  void set onError(void callback(e)) {
    _clientErrorHandler = callback;
  }

  void _reportError(e) {
    if (_clientErrorHandler != null) {
      _clientErrorHandler(e);
    } else {
      throw e;
    }
  }

  abstract List<int> _read(int bytesToRead);

  void _dataReceived() {
    // More data has been received asynchronously. Perform the data
    // handler callback now.
    _cancelScheduledDataCallback();
    if (_clientDataHandler !== null) {
      _clientDataHandler();
    }
    _checkScheduleCallbacks();
  }

  void _closeReceived() {
    // Close indication has been received asynchronously. Perform the
    // close callback now if all data has been delivered.
    _streamMarkedClosed = true;
    if (available() == 0) {
      _closeCallbackCalled = true;
      if (_clientCloseHandler !== null) _clientCloseHandler();
    } else {
      _checkScheduleCallbacks();
    }
  }

  void _cancelScheduledDataCallback() {
    if (_scheduledDataCallback != null) {
      _scheduledDataCallback.cancel();
      _scheduledDataCallback = null;
    }
  }

  void _checkScheduleCallbacks() {
    void issueDataCallback(Timer timer) {
      _scheduledDataCallback = null;
      if (_clientDataHandler !== null) {
        _clientDataHandler();
        _checkScheduleCallbacks();
      }
    }

    void issueCloseCallback(Timer timer) {
      _scheduledCloseCallback = null;
      _closeCallbackCalled = true;
      if (_clientCloseHandler !== null) _clientCloseHandler();
    }

    // Schedule data callback if there is more data to read. Schedule
    // close callback once when all data has been read. Only schedule
    // a new callback if the previous one has actually been called.
    if (!_closeCallbackCalled) {
      if (available() > 0) {
        if (_scheduledDataCallback == null) {
          _scheduledDataCallback = new Timer(0, issueDataCallback);
        }
      } else if (_streamMarkedClosed && _scheduledCloseCallback == null) {
        _cancelScheduledDataCallback();
        _close();
        _scheduledCloseCallback = new Timer(0, issueCloseCallback);
      }
    }
  }

  // When this is set to true the stream is marked closed. When a
  // stream is marked closed no more data can arrive and the value
  // from available is now all remaining data. If this is true and the
  // value of available is zero the close handler is called.
  bool _streamMarkedClosed = false;

  // When this is set to true the close callback has been called and
  // the stream is fully closed.
  bool _closeCallbackCalled = false;

  Timer _scheduledDataCallback;
  Timer _scheduledCloseCallback;
  Function _clientDataHandler;
  Function _clientCloseHandler;
  Function _clientErrorHandler;
}


void _pipe(InputStream input, OutputStream output, [bool close]) {
  Function pipeDataHandler;
  Function pipeCloseHandler;
  Function pipeNoPendingWriteHandler;

  Function _inputCloseHandler;

  pipeDataHandler = () {
    List<int> data;
    while ((data = input.read()) !== null) {
      if (!output.write(data)) {
        input.onData = null;
        output.onNoPendingWrites = pipeNoPendingWriteHandler;
        break;
      }
    }
  };

  pipeCloseHandler = () {
    if (close) output.close();
    if (_inputCloseHandler !== null) {
      _inputCloseHandler();
    }
  };

  pipeNoPendingWriteHandler = () {
    input.onData = pipeDataHandler;
    output.onNoPendingWrites = null;
  };

  _inputCloseHandler = input._clientCloseHandler;
  input.onData = pipeDataHandler;
  input.onClosed = pipeCloseHandler;
  output.onNoPendingWrites = null;
}


class _BaseOutputStream {
  bool writeString(String string, [Encoding encoding = Encoding.UTF_8]) {
    if (string.length > 0) {
      // Encode and write data.
      _StringEncoder encoder = _StringEncoders.encoder(encoding);
      List<int> data = encoder.encodeString(string);
      return write(data, copyBuffer: false);
    }
    return true;
  }

  void set onError(void callback(e)) {
    _onError = callback;
  }

  void _reportError(e) {
    if (_onError != null) {
      _onError(e);
    } else {
      throw e;
    }
  }

  Function _onError;
}
