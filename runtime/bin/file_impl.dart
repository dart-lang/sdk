// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _FileInputStream extends _BaseDataInputStream implements InputStream {
  _FileInputStream(String name) {
    _file = new File(name);
    _data = [];
    _position = 0;
    _file.onError = (String s) {
      if (_clientErrorHandler != null) {
        _clientErrorHandler();
      }
    };
    _file.open(FileMode.READ, (openedFile) {
      _readDataFromFile(openedFile);
    });
  }

  _FileInputStream.fromStdio(int fd) {
    assert(fd == 0);
    _file = _File._openStdioSync(fd);
    _data = [];
    _position = 0;
    _readDataFromFile(_file);
  }

  void _readDataFromFile(RandomAccessFile openedFile) {
    openedFile.onError = (String s) {
      if (_clientErrorHandler != null) {
        _clientErrorHandler();
      }
    };
    openedFile.length((length) {
      var contents = new ByteArray(length);
      if (length != 0) {
        openedFile.readList(contents, 0, length, (read) {
          if (read != length) {
            if (_clientErrorHandler != null) {
              _clientErrorHandler();
            }
          } else {
            _data = contents;
          }
          openedFile.close(() {
            _streamMarkedClosed = true;
            _checkScheduleCallbacks();
          });
        });
      } else {
        openedFile.close(() {
          _streamMarkedClosed = true;
          _checkScheduleCallbacks();
        });
      }
    });
  }

  int available() {
    return _closed ? 0 : _data.length - _position;
  }

  void pipe(OutputStream output, [bool close = true]) {
    _pipe(this, output, close: close);
  }

  List<int> _read(int bytesToRead) {
    ByteArray result = new ByteArray(bytesToRead);
    result.setRange(0, bytesToRead, _data, _position);
    _position += bytesToRead;
    _checkScheduleCallbacks();
    return result;
  }

  int _readInto(List<int> buffer, int offset, int len) {
    buffer.setRange(offset, len, _data, _position);
    _position += len;
    _checkScheduleCallbacks();
    return len;
  }

  void _close() {
    if (_closed) return;
    _closed = true;
  }

  File _file;
  List<int> _data;
  int _position;
  bool _closed = false;
}


class _FileOutputStream extends _BaseOutputStream implements OutputStream {
  _FileOutputStream(String name, FileMode mode) {
    _pendingOperations = new List<List<int>>();
    var f = new File(name);
    f.open(mode, (openedFile) {
      _file = openedFile;
      _setupFileHandlers();
      _processPendingOperations();
    });
    f.onError = (e) {
      if (_onError != null) _onError();
    };
  }

  _FileOutputStream.fromStdio(int fd) {
    assert(1 <= fd && fd <= 2);
    _file = _File._openStdioSync(fd);
    _setupFileHandlers();
  }


  void _setupFileHandlers() {
    _file.onError = (e) {
      if (_onError != null) _onError();
    };
    _file.onNoPendingWrites = () {
      if (!_streamMarkedClosed && _onNoPendingWrites != null) {
        _onNoPendingWrites();
      }
    };
  }

  bool write(List<int> buffer, [bool copyBuffer = false]) {
    var data = buffer;
    if (copyBuffer) {
      var length = buffer.length;
      data = new ByteArray(length);
      data.setRange(0, length, buffer, 0);
    }
    if (_file == null) {
      _pendingOperations.add(data);
    } else {
      _write(data, 0, data.length);
    }
    return false;
  }

  bool writeFrom(List<int> buffer, [int offset = 0, int len]) {
    // A copy is required by the interface.
    var length = buffer.length - offset;
    if (len != null) {
      if (len > length) throw new IndexOutOfRangeException(len);
      length = len;
    }
    var copy = new ByteArray(length);
    copy.setRange(0, length, buffer, offset);
    return write(copy);
  }

  void close() {
    if (_file == null) {
      _pendingOperations.add(null);
    } else if (!_streamMarkedClosed) {
      _file.close(() {
        if (_onClosed != null) _onClosed();
      });
      _streamMarkedClosed = true;
    }
  }

  void set onNoPendingWrites(void callback()) {
    _onNoPendingWrites = callback;
  }

  void set onClosed(void callback()) {
    _onClosed = callback;
  }

  void set onError(void callback()) {
    _onError = callback;
  }

  void _processPendingOperations() {
    _pendingOperations.forEach((buffer) {
      (buffer != null) ? write(buffer) : close();
    });
    _pendingOperations = null;
  }

  void _write(List<int> buffer, int offset, int len) {
    _file.writeList(buffer, offset, len);
  }

  RandomAccessFile _file;

  // When this is set to true the stream is marked closed. When a
  // stream is marked closed no more data can be written.
  bool _streamMarkedClosed = false;

  // When this is set to true the close callback has been called and
  // the stream is fully closed.
  bool _closeCallbackCalled = false;

  // List of pending writes that were issued before the underlying
  // file was successfully opened.
  List<List<int>> _pendingOperations;

  Function _onNoPendingWrites;
  Function _onClosed;
  Function _onError;
}


// Helper class containing static file helper methods.
class _FileUtils {
  static final kExistsRequest = 0;
  static final kCreateRequest = 1;
  static final kDeleteRequest = 2;
  static final kOpenRequest = 3;
  static final kFullPathRequest = 4;
  static final kDirectoryRequest = 5;
  static final kCloseRequest = 6;
  static final kPositionRequest = 7;
  static final kSetPositionRequest = 8;
  static final kTruncateRequest = 9;
  static final kLengthRequest = 10;
  static final kFlushRequest = 11;
  static final kReadByteRequest = 12;
  static final kWriteByteRequest = 13;
  static final kReadListRequest = 14;
  static final kWriteListRequest = 15;
  static final kWriteStringRequest = 16;

  static List ensureFastAndSerializableBuffer(
      List buffer, int offset, int bytes) {
    // When using the Dart C API to access raw data, using a ByteArray is
    // currently much faster. This function will make a copy of the
    // supplied List to a ByteArray if it isn't already.
    List outBuffer;
    int outOffset = offset;
    if (buffer is ByteArray || buffer is ObjectArray) {
      outBuffer = buffer;
    } else {
      outBuffer = new ByteArray(bytes);
      outOffset = 0;
      int j = offset;
      for (int i = 0; i < bytes; i++) {
        int value = buffer[j];
        if (value is! int) {
          throw new FileIOException(
              "List element is not an integer at index $j");
        }
        outBuffer[i] = value;
        j++;
      }
    }
    return [outBuffer, outOffset];
  }

  static bool exists(String name) native "File_Exists";
  static int open(String name, int mode) native "File_Open";
  static bool create(String name) native "File_Create";
  static bool delete(String name) native "File_Delete";
  static String fullPath(String name) native "File_FullPath";
  static String directory(String name) native "File_Directory";
  static int close(int id) native "File_Close";
  static int readByte(int id) native "File_ReadByte";
  static int readList(int id, List<int> buffer, int offset, int bytes)
      native "File_ReadList";
  static int writeByte(int id, int value) native "File_WriteByte";
  static int writeList(int id, List<int> buffer, int offset, int bytes) {
    List result =
        _FileUtils.ensureFastAndSerializableBuffer(buffer, offset, bytes);
    List outBuffer = result[0];
    int outOffset = result[1];
    return writeListNative(id, outBuffer, outOffset, bytes);
  }
  static int writeListNative(int id, List<int> buffer, int offset, int bytes)
      native "File_WriteList";
  static int writeString(int id, String string) native "File_WriteString";
  static int position(int id) native "File_Position";
  static bool setPosition(int id, int position) native "File_SetPosition";
  static bool truncate(int id, int length) native "File_Truncate";
  static int length(int id) native "File_Length";
  static int flush(int id) native "File_Flush";
  static int openStdio(int fd) native "File_OpenStdio";
  static SendPort newServicePort() native "File_NewServicePort";

  static int checkedOpen(String name, int mode) {
    if (name is !String || mode is !int) return 0;
    return open(name, mode);
  }

  static bool checkedCreate(String name) {
    if (name is !String) return false;
    return create(name);
  }

  static bool checkedDelete(String name) {
    if (name is !String) return false;
    return delete(name);
  }

  static String checkedFullPath(String name) {
    if (name is !String) return null;
    return fullPath(name);
  }

  static int checkReadWriteListArguments(int length, int offset, int bytes) {
    if (offset < 0) return offset;
    if (bytes < 0) return bytes;
    if ((offset + bytes) > length) return offset + bytes;
    return 0;
  }

  static int checkedWriteString(int id, String string) {
    if (string is !String) return -1;
    return writeString(id, string);
  }
}


// Class for encapsulating the native implementation of files.
class _File implements File {
  // Constructor for file.
  _File(String this._name) : _asyncUsed = false;

  void exists(void callback(bool exists)) {
    _ensureFileService();
    _asyncUsed = true;
    if (_name is !String) {
      if (_onError != null) {
        _onError('File name is not a string: $_name');
      }
      return;
    }
    List request = new List(2);
    request[0] = _FileUtils.kExistsRequest;
    request[1] = _name;
    _fileService.call(request).then((exists) {
      callback(exists);
    });
  }

  bool existsSync() {
    if (_asyncUsed) {
      throw new FileIOException(
          "Mixed use of synchronous and asynchronous API");
    }
    if (_name is !String) {
      throw new FileIOException('File name is not a string: $_name');
    }
    return _FileUtils.exists(_name);
  }

  void create(void callback()) {
    _ensureFileService();
    _asyncUsed = true;
    List request = new List(2);
    request[0] = _FileUtils.kCreateRequest;
    request[1] = _name;
    _fileService.call(request).then((created) {
      if (created) {
        callback();
      } else if (_onError != null) {
        _onError("Cannot create file: $_name");
      }
    });
  }

  void createSync() {
    if (_asyncUsed) {
      throw new FileIOException(
          "Mixed use of synchronous and asynchronous API");
    }
    bool created = _FileUtils.checkedCreate(_name);
    if (!created) {
      throw new FileIOException("Cannot create file: $_name");
    }
  }

  void delete(void callback()) {
    _ensureFileService();
    _asyncUsed = true;
    List request = new List(2);
    request[0] = _FileUtils.kDeleteRequest;
    request[1] = _name;
    _fileService.call(request).then((deleted) {
      if (deleted) {
        callback();
      } else if (_onError != null) {
        _onError("Cannot delete file: $_name");
      }
    });
  }

  void deleteSync() {
    if (_asyncUsed) {
      throw new FileIOException(
          "Mixed use of synchronous and asynchronous API");
    }
    bool deleted = _FileUtils.checkedDelete(_name);
    if (!deleted) {
      throw new FileIOException("Cannot delete file: $_name");
    }
  }

  void directory(void callback(Directory dir)) {
    _ensureFileService();
    _asyncUsed = true;
    List request = new List(2);
    request[0] = _FileUtils.kDirectoryRequest;
    request[1] = _name;
    _fileService.call(request).then((path) {
      if (path != null) {
        callback(new Directory(path));
      } else if (_onError != null) {
        _onError("Cannot get directory for: ${_name}");
      }
    });
  }

  Directory directorySync() {
    if (_asyncUsed) {
      throw new FileIOException(
          "Mixed use of synchronous and asynchronous API");
    }
    if (!existsSync()) {
      throw new FileIOException("Cannot get directory for: $_name");
    }
    return new Directory(_FileUtils.directory(_name));
  }

  void open(FileMode mode, void callback(RandomAccessFile file)) {
    _ensureFileService();
    _asyncUsed = true;
    if (mode != FileMode.READ &&
        mode != FileMode.WRITE &&
        mode != FileMode.APPEND) {
      if (_onError != null) {
        _onError("Unknown file mode. Use FileMode.READ, FileMode.WRITE " +
                 "or FileMode.APPEND.");
        return;
      }
    }
    List request = new List(3);
    request[0] = _FileUtils.kOpenRequest;
    request[1] = _name;
    request[2] = mode._mode;  // Direct int value for serialization.
    _fileService.call(request).then((id) {
      if (id != 0) {
        callback(new _RandomAccessFile(id, _name));
      } else if (_onError != null) {
        _onError("Cannot open file: $_name");
      }
    });
  }

  RandomAccessFile openSync([FileMode mode = FileMode.READ]) {
    if (_asyncUsed) {
      throw new FileIOException(
          "Mixed use of synchronous and asynchronous API");
    }
    if (mode != FileMode.READ &&
        mode != FileMode.WRITE &&
        mode != FileMode.APPEND) {
      throw new FileIOException("Unknown file mode. Use FileMode.READ, " +
                                "FileMode.WRITE or FileMode.APPEND.");
    }
    var id = _FileUtils.checkedOpen(_name, mode._mode);
    if (id == 0) {
      throw new FileIOException("Cannot open file: $_name");
    }
    return new _RandomAccessFile(id, _name);
  }

  static RandomAccessFile _openStdioSync(int fd) {
    var id = _FileUtils.openStdio(fd);
    if (id == 0) {
      throw new FileIOException("Cannot open stdio file for: $fd");
    }
    return new _RandomAccessFile(id, "");
  }

  void fullPath(void callback(String result)) {
    _ensureFileService();
    _asyncUsed = true;
    List request = new List(2);
    request[0] = _FileUtils.kFullPathRequest;
    request[1] = _name;
    _fileService.call(request).then((result) {
      if (result != null) {
        callback(result);
      } else if (_onError != null) {
        _onError("fullPath failed");
      }
    });
  }

  String fullPathSync() {
    if (_asyncUsed) {
      throw new FileIOException(
          "Mixed use of synchronous and asynchronous API");
    }
    String result = _FileUtils.checkedFullPath(_name);
    if (result == null) {
      throw new FileIOException("fullPath failed");
    }
    return result;
  }

  InputStream openInputStream() {
    return new _FileInputStream(_name);
  }

  OutputStream openOutputStream([FileMode mode = FileMode.WRITE]) {
    if (mode != FileMode.WRITE &&
        mode != FileMode.APPEND) {
      throw new FileIOException(
          "Wrong FileMode. Use FileMode.WRITE or FileMode.APPEND");
    }
    return new _FileOutputStream(_name, mode);
  }

  void readAsBytes(void callback(List<int> bytes)) {
    _asyncUsed = true;
    var chunks = new _BufferList();
    var stream = openInputStream();
    stream.onClosed = () {
      callback(chunks.readBytes(chunks.length));
    };
    stream.onData = () {
      var chunk = stream.read();
      chunks.add(chunk);
    };
    stream.onError = () {
      if (_onError != null) {
        _onError("Failed to read file as bytes: $_name");
      }
    };
  }

  List<int> readAsBytesSync() {
    if (_asyncUsed) {
      throw new FileIOException(
          "Mixed use of synchronous and asynchronous API");
    }
    var opened = openSync();
    var length = opened.lengthSync();
    var result = new ByteArray(length);
    var read = opened.readListSync(result, 0, length);
    if (read != length) {
      throw new FileIOException("Failed reading file as bytes: $_name");
    }
    opened.closeSync();
    return result;
  }

  void readAsText(Encoding encoding, void callback(String text)) {
    _asyncUsed = true;
    var decoder = _StringDecoders.decoder(encoding);
    readAsBytes((bytes) {
      try {
        decoder.write(bytes);
      } catch (var e) {
        if (_onError != null) {
          _onError(e.toString());
          return;
        }
      }
      callback(decoder.decoded);
    });
  }

  String readAsTextSync([Encoding encoding = Encoding.UTF_8]) {
    if (_asyncUsed) {
      throw new FileIOException(
          "Mixed use of synchronous and asynchronous API");
    }
    var decoder = _StringDecoders.decoder(encoding);
    List<int> bytes = readAsBytesSync();
    decoder.write(bytes);
    return decoder.decoded;
  }

  List<String> _getDecodedLines(_StringDecoder decoder) {
    List<String> result = [];
    var line = decoder.decodedLine;
    while (line != null) {
      result.add(line);
      line = decoder.decodedLine;
    }
    // If there is more data with no terminating line break we treat
    // it as the last line.
    var data = decoder.decoded;
    if (data != null) {
      result.add(data);
    }
    return result;
  }

  void readAsLines(Encoding encoding, void callback(List<String> lines)) {
    _asyncUsed = true;
    var decoder = _StringDecoders.decoder(encoding);
    readAsBytes((bytes) {
      try {
        decoder.write(bytes);
      } catch (var e) {
        if (_onError != null) {
          _onError(e.toString());
          return;
        }
      }
      callback(_getDecodedLines(decoder));
    });
  }

  List<String> readAsLinesSync([Encoding encoding = Encoding.UTF_8]) {
    if (_asyncUsed) {
      throw new FileIOException(
          "Mixed use of synchronous and asynchronous API");
    }
    var decoder = _StringDecoders.decoder(encoding);
    List<int> bytes = readAsBytesSync();
    decoder.write(bytes);
    return _getDecodedLines(decoder);
  }

  String get name() => _name;

  void set onError(void handler(String error)) {
    _onError = handler;
  }

  void _ensureFileService() {
    if (_fileService == null) {
      _fileService = _FileUtils.newServicePort();
    }
  }

  String _name;
  bool _asyncUsed;

  SendPort _fileService;

  Function _onError;
}


class _RandomAccessFile implements RandomAccessFile {
  _RandomAccessFile(int this._id, String this._name) : _asyncUsed = false;

  void close(void callback()) {
    if (_id == 0) return;
    _ensureFileService();
    _asyncUsed = true;
    List request = new List(2);
    request[0] = _FileUtils.kCloseRequest;
    request[1] = _id;
    // Set the id_ to 0 (NULL) to ensure the no more async requests
    // can be issues for this file.
    _id = 0;
    _fileService.call(request).then((result) {
      if (result != -1) {
        _id = result;
        callback();
      } else if (_onError != null) {
        _onError("Cannot close file: $_name");
      }
    });
  }

  void closeSync() {
    if (_asyncUsed) {
      throw new FileIOException(
          "Mixed use of synchronous and asynchronous API");
    }
    var id = _FileUtils.close(_id);
    if (id == -1) {
      throw new FileIOException("Cannot close file: $_name");
    }
    _id = id;
  }

  void readByte(void callback(int byte)) {
    _ensureFileService();
    _asyncUsed = true;
    List request = new List(2);
    request[0] = _FileUtils.kReadByteRequest;
    request[1] = _id;
    _fileService.call(request).then((result) {
      if (result != -1) {
        callback(result);
      } else if (_onError != null) {
        _onError("readByte failed");
      }
    });
  }

  int readByteSync() {
    if (_asyncUsed) {
      throw new FileIOException(
          "Mixed use of synchronous and asynchronous API");
    }
    int result = _FileUtils.readByte(_id);
    if (result == -1) {
      throw new FileIOException("readByte failed");
    }
    return result;
  }

  void readList(List<int> buffer, int offset, int bytes,
                void callback(int read)) {
    _ensureFileService();
    _asyncUsed = true;
    if (buffer is !List || offset is !int || bytes is !int) {
      if (_onError != null) {
        _onError("Invalid arguments to readList");
      }
      return;
    };
    List request = new List(3);
    request[0] = _FileUtils.kReadListRequest;
    request[1] = _id;
    request[2] = bytes;
    _fileService.call(request).then((result) {
      if (result is List && result.length == 2 && result[0] != -1) {
        var read = result[0];
        var data = result[1];
        buffer.setRange(offset, read, data);
        callback(read);
        return;
      } else if (_onError != null) {
        _onError(result is String ? result : "readList failed");
      }
    });
  }

  int readListSync(List<int> buffer, int offset, int bytes) {
    if (_asyncUsed) {
      throw new FileIOException(
          "Mixed use of synchronous and asynchronous API");
    }
    if (buffer is !List || offset is !int || bytes is !int) {
      throw new FileIOException("Invalid arguments to readList");
    }
    if (bytes == 0) return 0;
    int index =
        _FileUtils.checkReadWriteListArguments(buffer.length, offset, bytes);
    if (index != 0) {
      throw new IndexOutOfRangeException(index);
    }
    int result = _FileUtils.readList(_id, buffer, offset, bytes);
    if (result == -1) {
      throw new FileIOException("readList failed");
    }
    return result;
  }

  void writeByte(int value) {
    _ensureFileService();
    _asyncUsed = true;
    if (value is !int) {
      if (_onError != null) {
        _onError("Invalid argument to writeByte");
      }
      return;
    }
    List request = new List(3);
    request[0] = _FileUtils.kWriteByteRequest;
    request[1] = _id;
    request[2] = value;
    _writeEnqueued();
    _fileService.call(request).then((result) {
      _writeCompleted();
      if (result == -1 && _onError !== null) {
        _onError("writeByte failed");
      }
    });
  }

  int writeByteSync(int value) {
    if (_asyncUsed) {
      throw new FileIOException(
          "Mixed use of synchronous and asynchronous API");
    }
    if (value is !int) {
      throw new FileIOException("Invalid argument to writeByte");
    }
    int result = _FileUtils.writeByte(_id, value);
    if (result == -1) {
      throw new FileIOException("writeByte failed");
    }
    return result;
  }

  void writeList(List<int> buffer, int offset, int bytes) {
    _ensureFileService();
    _asyncUsed = true;
    if (buffer is !List || offset is !int || bytes is !int) {
      if (_onError != null) {
        _onError("Invalid arguments to writeList");
      }
      return;
    }

    List result =
        _FileUtils.ensureFastAndSerializableBuffer(buffer, offset, bytes);
    List outBuffer = result[0];
    int outOffset = result[1];

    List request = new List(5);
    request[0] = _FileUtils.kWriteListRequest;
    request[1] = _id;
    request[2] = outBuffer;
    request[3] = outOffset;
    request[4] = bytes;
    _writeEnqueued();
    _fileService.call(request).then((result) {
      _writeCompleted();
      if (result == -1 && _onError !== null) {
        _onError("writeList failed");
      }
    });
  }

  int writeListSync(List<int> buffer, int offset, int bytes) {
    if (_asyncUsed) {
      throw new FileIOException(
          "Mixed use of synchronous and asynchronous API");
    }
    if (buffer is !List || offset is !int || bytes is !int) {
      throw new FileIOException("Invalid arguments to writeList");
    }
    if (bytes == 0) return 0;
    int index =
        _FileUtils.checkReadWriteListArguments(buffer.length, offset, bytes);
    if (index != 0) {
      throw new IndexOutOfRangeException(index);
    }
    int result = _FileUtils.writeList(_id, buffer, offset, bytes);
    if (result == -1) {
      throw new FileIOException("writeList failed");
    }
    return result;
  }

  void writeString(String string, [Encoding encoding = Encoding.UTF_8]) {
    _ensureFileService();
    _asyncUsed = true;
    List request = new List(3);
    request[0] = _FileUtils.kWriteStringRequest;
    request[1] = _id;
    request[2] = string;
    _writeEnqueued();
    _fileService.call(request).then((result) {
      _writeCompleted();
      if (result == -1 && _onError !== null) {
        _onError("writeString failed");
      }
    });
  }

  int writeStringSync(String string, [Encoding encoding = Encoding.UTF_8]) {
    if (_asyncUsed) {
      throw new FileIOException(
          "Mixed use of synchronous and asynchronous API");
    }
    int result = _FileUtils.checkedWriteString(_id, string);
    if (result == -1) {
      throw new FileIOException("writeString failed");
    }
    return result;
  }

  void position(void callback(int position)) {
    _ensureFileService();
    _asyncUsed = true;
    List request = new List(2);
    request[0] = _FileUtils.kPositionRequest;
    request[1] = _id;
    _fileService.call(request).then((result) {
      if (result != -1) {
        callback(result);
      } else if (_onError != null) {
        _onError("position failed");
      }
    });
  }

  int positionSync() {
    if (_asyncUsed) {
      throw new FileIOException(
          "Mixed use of synchronous and asynchronous API");
    }
    int result = _FileUtils.position(_id);
    if (result == -1) {
      throw new FileIOException("position failed");
    }
    return result;
  }

  void setPosition(int position, void callback()) {
    _ensureFileService();
    _asyncUsed = true;
    List request = new List(3);
    request[0] = _FileUtils.kSetPositionRequest;
    request[1] = _id;
    request[2] = position;
    _fileService.call(request).then((result) {
      if (result) {
        callback();
      } else if (_onError != null) {
        _onError("setPosition failed");
      }
    });
  }

  void setPositionSync(int position) {
    _ensureFileService();
    if (_asyncUsed) {
      throw new FileIOException(
          "Mixed use of synchronous and asynchronous API");
    }
    bool result = _FileUtils.setPosition(_id, position);
    if (result == false) {
      throw new FileIOException("setPosition failed");
    }
  }

  void truncate(int length, void callback()) {
    _ensureFileService();
    _asyncUsed = true;
    List request = new List(3);
    request[0] = _FileUtils.kTruncateRequest;
    request[1] = _id;
    request[2] = length;
    _fileService.call(request).then((result) {
      if (result) {
        callback();
      } else if (_onError != null) {
        _onError("truncate failed");
      }
    });
  }

  void truncateSync(int length) {
    if (_asyncUsed) {
      throw new FileIOException(
          "Mixed use of synchronous and asynchronous API");
    }
    bool result = _FileUtils.truncate(_id, length);
    if (result == false) {
      throw new FileIOException("truncate failed");
    }
  }

  void length(void callback(int length)) {
    _ensureFileService();
    _asyncUsed = true;
    List request = new List(2);
    request[0] = _FileUtils.kLengthRequest;
    request[1] = _id;
    _fileService.call(request).then((result) {
      if (result != -1) {
        callback(result);
      } else if (_onError != null) {
        _onError("length failed");
      }
    });
  }

  int lengthSync() {
    if (_asyncUsed) {
      throw new FileIOException(
          "Mixed use of synchronous and asynchronous API");
    }
    int result = _FileUtils.length(_id);
    if (result == -1) {
      throw new FileIOException("length failed");
    }
    return result;
  }

  void flush(void callback()) {
    _ensureFileService();
    _asyncUsed = true;
    List request = new List(2);
    request[0] = _FileUtils.kFlushRequest;
    request[1] = _id;
    _fileService.call(request).then((result) {
      if (result != -1) {
        callback();
      } else if (_onError != null) {
        _onError("flush failed");
      }
    });
  }

  void flushSync() {
    if (_asyncUsed) {
      throw new FileIOException(
          "Mixed use of synchronous and asynchronous API");
    }
    int result = _FileUtils.flush(_id);
    if (result == -1) {
      throw new FileIOException("flush failed");
    }
  }

  String get name() => _name;

  void set onError(void handler(String error)) {
    _onError = handler;
  }

  void set onNoPendingWrites(void handler()) {
    _onNoPendingWrites = handler;
    if (_pendingWrites == 0) {
      _noPendingWriteTimer = new Timer(0, (t) {
        if (_onNoPendingWrites != null) _onNoPendingWrites();
      });
    }
  }

  void _ensureFileService() {
    if (_fileService == null) {
      _fileService = _FileUtils.newServicePort();
    }
  }

  void _writeEnqueued() {
    _pendingWrites++;
    if (_noPendingWriteTimer != null) {
      _noPendingWriteTimer.cancel();
      _noPendingWriteTimer = null;
    }
  }

  void  _writeCompleted() {
    _pendingWrites--;
    if (_pendingWrites == 0 && _onNoPendingWrites != null) {
      _onNoPendingWrites();
    }
  }


  String _name;
  int _id;
  bool _asyncUsed;
  int _pendingWrites = 0;

  SendPort _fileService;

  Timer _noPendingWriteTimer;

  Function _onNoPendingWrites;
  Function _onError;
}
