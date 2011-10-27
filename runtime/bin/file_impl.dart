// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _FileInputStream implements FileInputStream {
  _FileInputStream(File file) {
    _file = new File(file.name);
    _file.openSync();
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
    int bytesRead = _file.readListSync(buffer, 0, bytesToRead);
    if (bytesRead < bytesToRead) {
      List<int> newBuffer = new List<int>(bytesRead);
      newBuffer.copyFrom(buffer, 0, 0, bytesRead);
      return newBuffer;
    } else {
      return buffer;
    }
  }

  int readInto(List<int> buffer, int offset, int len) {
    if (offset === null) offset = 0;
    if (len === null) len = buffer.length;
    if (offset < 0) throw new StreamException("Illegal offset $offset");
    if (len < 0) throw new StreamException("Illegal length $len");
    return _file.readListSync(buffer, offset, len);
  }

  int available() {
    return _file.lengthSync() - _file.positionSync();
  }

  bool closed() {
    _file.positionSync() == _file.lengthSync();
  }

  void close() {
    _file.closeSync();
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


class _FileOutputStream implements FileOutputStream {
  _FileOutputStream(File file) {
    _file = new File(file.name);
    _file.openSync(true);
  }

  bool write(List<int> buffer, int offset, int len, void callback()) {
    int bytesWritten = _file.writeListSync(buffer, offset, len);

    if (bytesWritten == len) {
      return true;
    } else {
      throw "FileOutputStream: write error";
    }
  }

  void close() {
    _file.closeSync();
  }

  File _file;
}


// Class for encapsulating the native implementation of files.
class _File implements File {
  // Constructor for file.
  _File(String this._name);

  void exists() {
    throw "Unimplemented";
  }

  bool existsSync() {
    return _fileExists(_name);
  }

  bool _fileExists(String name) native "File_Exists";

  void create() {
    throw "Unimplemented";
  }

  void createSync() {
    throw "Unimplemented";
  }

  void open([bool writable = false]) {
    throw "Unimplemented";
  }

  void openSync([bool writable = false]) {
    if (!_openFile(_name, writable)) {
      throw new FileIOException("Cannot open file: $_name");
    }
  }

  bool _openFile(String name, bool writable) native "File_OpenFile";

  void close() {
    throw "Unimplemented";
  }

  void closeSync() {
    _close();
  }

  int _close() native "File_Close";

  void readByte() {
    throw "Unimplemented";
  }

  int readByteSync() {
    int result = _readByte();
    if (result == -1) {
      throw new FileIOException("Error: readByte failed");
    }
    return result;
  }

  int _readByte() native "File_ReadByte";

  void readList(List<int> buffer, int offset, int bytes) {
    throw "Unimplemented";
  }

  int readListSync(List<int> buffer, int offset, int bytes) {
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

  int _readList(List<int> buffer, int offset, int bytes) native "File_ReadList";

  void writeByte(int value) {
    throw "Unimplemented";
  }

  int writeByteSync(int value) {
    int result = _writeByte(value);
    if (result == -1) {
      throw new FileIOException("Error: writeByte failed");
    }
    return result;
  }

  int _writeByte(int value) native "File_WriteByte";

  int writeList(List<int> buffer, int offset, int bytes) {
    throw "Unimplemented";
  }

  int writeListSync(List<int> buffer, int offset, int bytes) {
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

  int writeString(String string) {
    throw "Unimplemented";
  }

  int writeStringSync(String string) {
    int result = _writeString(string);
    if (result == -1) {
      throw new FileIOException("Error: writeString failed");
    }
    return result;
  }

  int _writeString(String string) native "File_WriteString";

  int position() {
    throw "Unimplemented";
  }

  int positionSync() {
    int result = _position;
    if (result == -1) {
      throw new FileIOException("Error: get position failed");
    }
    return result;
  }

  int get _position() native "File_Position";

  int length() {
    throw "Unimplemented";
  }

  int lengthSync() {
    int result = _length;
    if (result == -1) {
      throw new FileIOException("Error: get length failed");
    }
    return result;
  }

  int get _length() native "File_Length";

  void flush() {
    throw "Unimplemented";
  }

  void flushSync() {
    int result = _flush();
    if (result == -1) {
      throw new FileIOException("Error: flush failed");
    }
  }

  int _flush() native "File_Flush";

  InputStream openInputStream() {
    return new _FileInputStream(this);
  }

  OutputStream openOutputStream() {
    return new _FileOutputStream(this);
  }

  String get name() {
    return _name;
  }

  void set existsHandler(void handler(bool exists)) {
    _existsHandler = handler;
  }

  void set createHandler(void handler()) {
    _createHandler = handler;
  }

  void set openHandler(void handler()) {
    _openHandler = handler;
  }

  void set closeHandler(void handler()) {
    _closeHandler = handler;
  }

  void set readByteHandler(void handler(int byte)) {
    _readByteHandler = handler;
  }

  void set readListHandler(void handler(int read)) {
    _readListHandler = handler;
  }

  void set noPendingWriteHandler(void handler()) {
    _noPendingWriteHandler = handler;
  }

  void set errorHandler(void handler(String error)) {
    _errorHandler = handler;
  }

  String _name;
  int _id;

  var _existsHandler;
  var _createHandler;
  var _openHandler;
  var _closeHandler;
  var _readByteHandler;
  var _readListHandler;
  var _noPendingWriteHandler;
  var _errorHandler;
}
