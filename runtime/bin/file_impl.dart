// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _FileInputStream implements InputStream {
  _FileInputStream(File file) {
    _file = file;
  }

  List<int> read([int len]) {
    int bytesToRead = available();
    if (bytesToRead == 0) {
      return null;
    }
    if (len != null) {
      if (len <= 0) {
        throw new StreamException("Illegal length $len");
      } else if (bytesToRead > len) {
        bytesToRead = len;
      }
    }
    List<int> buffer = new List<int>(bytesToRead);
    int bytesRead = _file.readList(buffer, 0, bytesToRead);
    if (bytesRead < bytesToRead) {
      List<int> newBuffer = new List<int>(bytesRead);
      newBuffer.copyFrom(buffer, 0, 0, bytesRead);
      return newBuffer;
    } else {
      return buffer;
    }
  }

  int readInto(List<int> buffer, int offset, int len) {
    if (offset == null) offset = 0;
    if (len == null) len = buffer.length;
    if (offset < 0) throw new StreamException("Illegal offset $offset");
    if (len < 0) throw new StreamException("Illegal length $len");
    return _file.readList(buffer, offset, len);
  }

  int available() {
    return _file.length - _file.position;
  }

  bool closed() {
    _file.position == _file.length;
  }

  void set dataHandler(void callback()) {
    // TODO(sgjesse): How to handle this?
  }

  void set closeHandler(void callback()) {
    // TODO(sgjesse): How to handle this?
  }

  void set errorHandler(void callback()) {
    // TODO(sgjesse): How to handle this?
  }

  File _file;
}


class _FileOutputStream implements OutputStream {
  _FileOutputStream(File file) {
    _file = file;
  }

  bool write(List<int> buffer, int offset, int len, void callback()) {
    int bytesWritten = _file.writeList(buffer, offset, len);

    if (bytesWritten == len) {
      return true;
    } else {
      throw "FileOutputStream: write error";
    }
  }

  File _file;
}


// Class for encapsulating the native implementation of files.
class _File extends FileNativeWrapper implements File {
  // Constructor for file.
  factory _File(String name, bool writable) {
    _File file = new _File._internal();
    if (!file._openFile(name, writable)) {
      return null;
    }
    file._writeable = writable;
    return file;
  }
  _File._internal();

  bool _openFile(String name, bool writable) native "File_OpenFile";

  void close() {
     _close();
  }
  int _close() native "File_Close";

  int readByte() {
    int result = _readByte();
    if (result == -1) {
      throw new FileIOException("Error: readByte failed");
    }
    return result;
  }
  int _readByte() native "File_ReadByte";

  int writeByte(int value) {
    int result = _writeByte(value);
    if (result == -1) {
      throw new FileIOException("Error: writeByte failed");
    }
    return result;
  }
  int _writeByte(int value) native "File_WriteByte";

  int writeString(String string) {
    int result = _writeString(string);
    if (result == -1) {
      throw new FileIOException("Error: writeString failed");
    }
    return result;
  }
  int _writeString(String string) native "File_WriteString";

  int readList(List<int> buffer, int offset, int bytes) {
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
    int result = _readList(buffer, offset, bytes);
    if (result == -1) {
      throw new FileIOException("Error: readList failed");
    }
    return result;
  }
  int _readList(List<int> buffer, int offset, int bytes)
      native "File_ReadList";

  int writeList(List<int> buffer, int offset, int bytes) {
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
    int result = _writeList(buffer, offset, bytes);
    if (result == -1) {
      throw new FileIOException("Error: writeList failed");
    }
    return result;
  }
  int _writeList(List<int> buffer, int offset, int bytes)
      native "File_WriteList";

  int get position() {
    int result = _position;
    if (result == -1) {
      throw new FileIOException("Error: get position failed");
    }
    return result;
  }
  int get _position() native "File_Position";

  int get length() {
    int result = _length;
    if (result == -1) {
      throw new FileIOException("Error: get length failed");
    }
    return result;
  }
  int get _length() native "File_Length";

  void flush() {
    int result = _flush();
    if (result == -1) {
      throw new FileIOException("Error: flush failed");
    }
  }
  int _flush() native "File_Flush";

  // Each file has an unique InputStream.
  InputStream get inputStream() {
    if (_inputStream == null) {
      _inputStream = new _FileInputStream(this);
    }
    return _inputStream;
  }

  // Each file has an unique OutputStream.
  OutputStream get outputStream() {
    if (!_writeable) {
      throw "File is not writable";
    }
    if (_outputStream == null) {
      _outputStream = new _FileOutputStream(this);
    }
    return _outputStream;
  }

  // Set of native methods used to provide file functionality.
  static bool fileExists(String name) native "File_Exists";

  bool _writeable;
  InputStream _inputStream;
  OutputStream _outputStream;
}
