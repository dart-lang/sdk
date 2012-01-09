// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ListInputStream extends _BaseDataInputStream implements InputStream {
  ListInputStream(List<int> this._buffer) {
    _streamMarkedClosed = true;
  }

  int available() => _buffer.length - _offset;

  List<int> _read(int bytesToRead) {
    if (_offset == 0 && bytesToRead == _buffer.length) {
      _offset = _buffer.length;
      return _buffer;
    } else {
      List<int> result = _buffer.getRange(_offset, bytesToRead);
      _offset += bytesToRead;
      return result;
    }
  }

  int _readInto(List<int> buffer, int offset, int bytesToRead) {
    buffer.setRange(offset, bytesToRead, _buffer, _offset);
    _offset += bytesToRead;
    return bytesToRead;
  }

  void _close() {
    _offset = _buffer.length;
  }

  List<int> _buffer;
  int _offset = 0;
}


class DynamicListInputStream
    extends _BaseDataInputStream implements InputStream {
  DynamicListInputStream() : _bufferList = new _BufferList();

  int available() => _bufferList.length;

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

  List<int> _read(int bytesToRead) {
    return _bufferList.readBytes(bytesToRead);
  }

  int _readInto(List<int> buffer, int offset, int bytesToRead) {
    List<int> tmp = _bufferList.readBytes(byteToRead);
    buffer.setRange(offset, bytesToRead, tmp, _offset);
    return bytesToRead;
  }

  void _close() {
    _streamMarkedClosed = true;
    _bufferList.clear();
  }

  _BufferList _bufferList;
}


class ListOutputStream implements OutputStream {
  ListOutputStream() : _bufferList = new _BufferList();

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

  void set noPendingWriteHandler(void callback()) {
    _clientNoPendingWriteHandler = callback;
    _checkScheduleCallbacks();
  }

  void set closeHandler(void callback()) {
    _clientCloseHandler = callback;
  }

  void set errorHandler(void callback()) {
    // No errors emitted.
  }

  List<int> contents() => _bufferList.readBytes(_bufferList.length);

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
              new Timer(issueNoPendingWriteCallback, 0);
        }
      } else if (_clientCloseHandler != null &&
                 _streamMarkedClosed &&
                 !_closeCallbackCalled) {
        _scheduledCloseCallback = new Timer(issueCloseCallback, 0);
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
