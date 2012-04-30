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

  List<int> contents() => _bufferList.readBytes(_bufferList.length);

  bool write(List<int> buffer, [bool copyBuffer = false]) {
    if (_streamMarkedClosed) throw new StreamException.streamClosed();
    if (copyBuffer) {
      _bufferList.add(buffer.getRange(0, buffer.length));
    } else {
      _bufferList.add(buffer);
    }
    return true;
  }

  bool writeFrom(List<int> buffer, [int offset = 0, int len]) {
    if (_streamMarkedClosed) throw new StreamException.streamClosed();
    _bufferList.add(
        buffer.getRange(offset, (len == null) ? buffer.length - offset : len));
    return true;
  }

  void close() {
    if (_streamMarkedClosed) throw new StreamException.streamClosed();
    _streamMarkedClosed = true;
  }

  void destroy() {
    close();
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
    void issueNoPendingWriteCallback(Timer timer) {
      _scheduledNoPendingWriteCallback = null;
      if (_clientNoPendingWriteHandler !== null) {
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
    if (!_closeCallbackCalled) {
      if (!_streamMarkedClosed) {
        if (_clientNoPendingWriteHandler != null &&
            _scheduledNoPendingWriteCallback == null) {
          _scheduledNoPendingWriteCallback =
              new Timer(0, issueNoPendingWriteCallback);
        }
      } else if (_clientCloseHandler != null &&
                 _streamMarkedClosed &&
                 !_closeCallbackCalled) {
        _scheduledCloseCallback = new Timer(0, issueCloseCallback);
        _closeCallbackCalled = true;
      }
    }
  }

  _BufferList _bufferList;
  bool _streamMarkedClosed = false;
  bool _closeCallbackCalled = false;
  Timer _scheduledNoPendingWriteCallback;
  Timer _scheduledCloseCallback;
  Function _clientNoPendingWriteHandler;
  Function _clientCloseHandler;
}
