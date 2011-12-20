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

  List<int> _buffer;
  int _offset = 0;
}


class DynamicListInputStream
    extends _BaseDataInputStream implements InputStream {
  DynamicListInputStream() : _bufferList = new _BufferList();

  int available() => _bufferList.length;

  void write(List<int> data) {
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

  _BufferList _bufferList;
}
