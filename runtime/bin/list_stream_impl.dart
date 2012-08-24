// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Default implementation of [ListInputStream].
 */
class _ListInputStream extends _BaseDataInputStream implements ListInputStream {
  _ListInputStream() : _bufferList = new _BufferList();

  void write(List<int> data) {
    if (_streamMarkedClosed) {
      throw new StreamException.streamClosed();
    }
    _bufferList.add(data);
    _checkScheduleCallbacks();
  }

  void markEndOfStream() {
    _streamMarkedClosed = true;
    _checkScheduleCallbacks();
  }

  int available() => _bufferList.length;

  List<int> _read(int bytesToRead) {
    return _bufferList.readBytes(bytesToRead);
  }

  int _readInto(List<int> buffer, int offset, int bytesToRead) {
    List<int> tmp = _bufferList.readBytes(bytesToRead);
    buffer.setRange(offset, bytesToRead, tmp, 0);
    return bytesToRead;
  }

  void _close() {
    _streamMarkedClosed = true;
    _bufferList.clear();
  }

  _BufferList _bufferList;
}


class _ListOutputStream extends _BaseOutputStream implements ListOutputStream {
  _ListOutputStream() : _bufferList = new _BufferList();

  List<int> read() => _bufferList.readBytes(_bufferList.length);

  bool write(List<int> buffer, [bool copyBuffer = true]) {
    if (_streamMarkedClosed) throw new StreamException.streamClosed();
    if (copyBuffer) {
      _bufferList.add(buffer.getRange(0, buffer.length));
    } else {
      _bufferList.add(buffer);
    }
    _checkScheduleCallbacks();
    return true;
  }

  bool writeFrom(List<int> buffer, [int offset = 0, int len]) {
    return write(
        buffer.getRange(offset, (len == null) ? buffer.length - offset : len),
        copyBuffer: false);
  }

  void flush() {
    // Nothing to do on a list output stream.
  }

  void close() {
    if (_streamMarkedClosed) throw new StreamException.streamClosed();
    _streamMarkedClosed = true;
    _checkScheduleCallbacks();
  }

  void destroy() {
    close();
  }

  void set onData(void callback()) {
    _clientDataHandler = callback;
    _checkScheduleCallbacks();
  }

  void set onNoPendingWrites(void callback()) {
    _clientNoPendingWriteHandler = callback;
    _checkScheduleCallbacks();
  }

  void set onClosed(void callback()) {
    _clientCloseHandler = callback;
  }

  void set onError(void callback(e)) {
    // No errors emitted.
  }

  void _checkScheduleCallbacks() {
    void issueDataCallback(Timer timer) {
      _scheduledDataCallback = null;
      if (_clientDataHandler != null) {
        _clientDataHandler();
        _checkScheduleCallbacks();
      }
    }

    void issueNoPendingWriteCallback(Timer timer) {
      _scheduledNoPendingWriteCallback = null;
      if (_clientNoPendingWriteHandler != null &&
          !_streamMarkedClosed) {
        _clientNoPendingWriteHandler();
        _checkScheduleCallbacks();
      }
    }

    void issueCloseCallback(Timer timer) {
      _scheduledCloseCallback = null;
      if (_clientCloseHandler !== null) _clientCloseHandler();
    }

    // Schedule no pending callback if there is a callback set as this
    // output stream does not wait for any transmission. Schedule
    // close callback once when the stream is closed. Only schedule a
    // new callback if the previous one has actually been called.
    if (_closeCallbackCalled) return;

    if (!_streamMarkedClosed) {
      if (!_bufferList.isEmpty() &&
          _clientDataHandler != null &&
          _scheduledDataCallback == null) {
        _scheduledDataCallback = new Timer(0, issueDataCallback);
      }

      if (_clientNoPendingWriteHandler != null &&
          _scheduledNoPendingWriteCallback == null &&
          _scheduledDataCallback == null) {
        _scheduledNoPendingWriteCallback =
          new Timer(0, issueNoPendingWriteCallback);
      }

    } else if (_clientCloseHandler != null) {
      _scheduledCloseCallback = new Timer(0, issueCloseCallback);
      _closeCallbackCalled = true;
    }
  }

  bool get closed => _streamMarkedClosed;

  _BufferList _bufferList;
  bool _streamMarkedClosed = false;
  bool _closeCallbackCalled = false;
  Timer _scheduledDataCallback;
  Timer _scheduledNoPendingWriteCallback;
  Timer _scheduledCloseCallback;
  Function _clientDataHandler;
  Function _clientNoPendingWriteHandler;
  Function _clientCloseHandler;
}
