// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _BaseDataInputStream {
  abstract int available();

  List<int> read([int len]) {
    if (_closeCallbackCalled) return null;
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
    if (_closeCallbackCalled) return null;
    if (len === null) len = buffer.length;
    if (offset < 0) throw new StreamException("Illegal offset $offset");
    if (len < 0) throw new StreamException("Illegal length $len");
    int bytesToRead = Math.min(len, available());
    return _readInto(buffer, offset, bytesToRead);
  }

  void pipe(OutputStream output, [bool close = true]) {
    _pipe(this, output, close: close);
  }

  void close() {
    if (_scheduledDataCallback != null) _scheduledDataCallback.cancel();
    _close();
    _checkScheduleCallbacks();
  }

  bool get closed() => _closeCallbackCalled;

  void set dataHandler(void callback()) {
    _clientDataHandler = callback;
    _checkScheduleCallbacks();
  }

  void set closeHandler(void callback()) {
    _clientCloseHandler = callback;
    _checkScheduleCallbacks();
  }

  void set errorHandler(void callback()) {
    // No errors emitted by default.
  }

  abstract List<int> _read(int bytesToRead);

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
      if (_clientCloseHandler !== null) _clientCloseHandler();
    }

    // Schedule data callback if there is more data to read. Schedule
    // close callback once when all data has been read. Only schedule
    // a new callback if the previous one has actually been called.
    if (!_closeCallbackCalled) {
      if (available() > 0) {
        if (_scheduledDataCallback == null) {
          _scheduledDataCallback = new Timer(issueDataCallback, 0);
        }
      } else if (_streamMarkedClosed && !_closeCallbackCalled) {
        _close();
        _scheduledCloseCallback = new Timer(issueCloseCallback, 0);
        _closeCallbackCalled = true;
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
        input.dataHandler = null;
        output.noPendingWriteHandler = pipeNoPendingWriteHandler;
        break;
      }
    }
  };

  pipeCloseHandler = () {
    if (close) output.close();
    if (_inputCloseHandler !== null) _inputCloseHandler();
  };

  pipeNoPendingWriteHandler = () {
    input.dataHandler = pipeDataHandler;
    output.noPendingWriteHandler = null;
  };

  _inputCloseHandler = input._clientCloseHandler;
  input.dataHandler = pipeDataHandler;
  input.closeHandler = pipeCloseHandler;
  output.noPendingWriteHandler = null;
}

