// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _FileInputStream extends _BaseDataInputStream implements InputStream {
  _FileInputStream(String name)
      : _data = const [],
        _position = 0,
        _filePosition = 0 {
    var file = new File(name);
    var future = file.open(FileMode.READ);
    future.handleException((e) {
      _reportError(e);
      return true;
    });
    future.then(_setupOpenedFile);
  }

  _FileInputStream.fromStdio(int fd)
      : _data = const [],
        _position = 0,
        _filePosition = 0 {
    assert(fd == 0);
    _setupOpenedFile(_File._openStdioSync(fd));
  }

  void _setupOpenedFile(RandomAccessFile openedFile) {
    _openedFile = openedFile;
    if (_streamMarkedClosed) {
      // This input stream has already been closed.
      _fileLength = 0;
      _closeFile();
      return;
    }
    var futureOpen = _openedFile.length();
    futureOpen.then((len) {
      _fileLength = len;
      _fillBuffer();
    });
    futureOpen.handleException((e) {
      _reportError(e);
      return true;
    });
  }

  void _closeFile() {
    if (_openedFile == null) {
      _streamMarkedClosed = true;
      return;
    }
    if (available() == 0) _cancelScheduledDataCallback();
    if (!_openedFile.closed) {
      _openedFile.close().then((ignore) {
        _streamMarkedClosed = true;
        _checkScheduleCallbacks();
      });
    }
  }

  void _fillBuffer() {
    Expect.equals(_position, _data.length);
    if (_openedFile == null) return;  // Called before the file is opened.
    int size = min(_bufferLength, _fileLength - _filePosition);
    if (size == 0) {
      _closeFile();
      return;
    }
    // If there is currently a _fillBuffer call waiting on readList,
    // let it fill the buffer instead of us.
    if (_activeFillBufferCall) return;
    _activeFillBufferCall = true;
    if (_data.length != size) {
      _data = new Uint8List(size);
      // Maintain the invariant signalling that the buffer is empty.
      _position = _data.length;
    }
    var future = _openedFile.readList(_data, 0, _data.length);
    future.then((read) {
      _filePosition += read;
      if (read != _data.length) {
        _data = _data.getRange(0, read);
      }
      _position = 0;
      _activeFillBufferCall = false;

      if (_fileLength == _filePosition) {
        _closeFile();
      }
      _checkScheduleCallbacks();
    });
    future.handleException((e) {
      _activeFillBufferCall = false;
      _reportError(e);
      return true;
    });
  }

  int available() {
    return closed ? 0 : _data.length - _position;
  }

  void pipe(OutputStream output, [bool close = true]) {
    _pipe(this, output, close: close);
  }

  void _finishRead() {
    if (_position == _data.length && !_streamMarkedClosed) {
      _fillBuffer();
    } else {
      _checkScheduleCallbacks();
    }
  }

  List<int> _read(int bytesToRead) {
    List<int> result;
    if (_position == 0 && bytesToRead == _data.length) {
      result = _data;
      _data = const [];
    } else {
      result = new Uint8List(bytesToRead);
      result.setRange(0, bytesToRead, _data, _position);
      _position += bytesToRead;
    }
    _finishRead();
    return result;
  }

  int _readInto(List<int> buffer, int offset, int len) {
    buffer.setRange(offset, len, _data, _position);
    _position += len;
    _finishRead();
    return len;
  }

  void _close() {
    _data = const [];
    _position = 0;
    _filePosition = 0;
    _fileLength = 0;
    _closeFile();
  }

  static const int _bufferLength = 64 * 1024;

  RandomAccessFile _openedFile;
  List<int> _data;
  int _position;
  int _filePosition;
  int _fileLength;
  bool _activeFillBufferCall = false;
}


class _PendingOperation {
  const _PendingOperation(this._id);
  static const _PendingOperation CLOSE = const _PendingOperation(0);
  static const _PendingOperation FLUSH = const _PendingOperation(1);
  final int _id;
}


class _FileOutputStream extends _BaseOutputStream implements OutputStream {
  _FileOutputStream(String name, FileMode mode) {
    _pendingOperations = new List();
    var f = new File(name);
    var openFuture = f.open(mode);
    openFuture.then((openedFile) {
      _file = openedFile;
      _processPendingOperations();
    });
    openFuture.handleException((e) {
      _reportError(e);
      return true;
    });
  }

  _FileOutputStream.fromStdio(int fd) {
    assert(1 <= fd && fd <= 2);
    _file = _File._openStdioSync(fd);
  }

  bool write(List<int> buffer, [bool copyBuffer = false]) {
    var data = buffer;
    if (copyBuffer) {
      var length = buffer.length;
      data = new Uint8List(length);
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
    var copy = new Uint8List(length);
    copy.setRange(0, length, buffer, offset);
    return write(copy);
  }


  void flush() {
    if (_file == null) {
      _pendingOperations.add(_PendingOperation.FLUSH);
    } else {
      _file.flush().then((ignored) => null);
    }
  }


  void close() {
    _streamMarkedClosed = true;
    if (_file == null) {
      _pendingOperations.add(_PendingOperation.CLOSE);
    } else if (!_closeCallbackScheduled) {
      _file.close().then((ignore) {
        if (_onClosed != null) _onClosed();
      });
      _closeCallbackScheduled = true;
    }
  }

  void set onNoPendingWrites(void callback()) {
    _onNoPendingWrites = callback;
    if ((_pendingOperations == null || _pendingOperations.length == 0) &&
        outstandingWrites == 0 &&
        !_streamMarkedClosed &&
        _onNoPendingWrites != null) {
      new Timer(0, (t) {
        if (_onNoPendingWrites != null) {
          _onNoPendingWrites();
        }
      });
    }
  }

  void set onClosed(void callback()) {
    _onClosed = callback;
  }

  void _processPendingOperations() {
    _pendingOperations.forEach((buffer) {
      if (buffer is _PendingOperation) {
        if (buffer === _PendingOperation.CLOSE) {
          close();
        } else {
          assert(buffer === _PendingOperation.FLUSH);
          flush();
        }
      } else {
        write(buffer);
      }
    });
    _pendingOperations = null;
  }

  void _write(List<int> buffer, int offset, int len) {
    outstandingWrites++;
    var writeListFuture = _file.writeList(buffer, offset, len);
    writeListFuture.then((ignore) {
        outstandingWrites--;
        if (outstandingWrites == 0 &&
            !_streamMarkedClosed &&
            _onNoPendingWrites != null) {
          _onNoPendingWrites();
        }
    });
    writeListFuture.handleException((e) {
      outstandingWrites--;
      _reportError(e);
      return true;
    });
  }

  bool get closed => _streamMarkedClosed;

  RandomAccessFile _file;

  // When this is set to true the stream is marked closed. When a
  // stream is marked closed no more data can be written.
  bool _streamMarkedClosed = false;

  // When this is set to true, the close callback has been scheduled and the
  // stream will be fully closed once it's called.
  bool _closeCallbackScheduled = false;

  // Number of writes that have not yet completed.
  int outstandingWrites = 0;

  // List of pending writes that were issued before the underlying
  // file was successfully opened.
  List _pendingOperations;

  Function _onNoPendingWrites;
  Function _onClosed;
}


// Helper class containing static file helper methods.
class _FileUtils {
  static const EXISTS_REQUEST = 0;
  static const CREATE_REQUEST = 1;
  static const DELETE_REQUEST = 2;
  static const OPEN_REQUEST = 3;
  static const FULL_PATH_REQUEST = 4;
  static const DIRECTORY_REQUEST = 5;
  static const CLOSE_REQUEST = 6;
  static const POSITION_REQUEST = 7;
  static const SET_POSITION_REQUEST = 8;
  static const TRUNCATE_REQUEST = 9;
  static const LENGTH_REQUEST = 10;
  static const LENGTH_FROM_NAME_REQUEST = 11;
  static const LAST_MODIFIED_REQUEST = 12;
  static const FLUSH_REQUEST = 13;
  static const READ_BYTE_REQUEST = 14;
  static const WRITE_BYTE_REQUEST = 15;
  static const READ_LIST_REQUEST = 16;
  static const WRITE_LIST_REQUEST = 17;
  static const WRITE_STRING_REQUEST = 18;

  static const SUCCESS_RESPONSE = 0;
  static const ILLEGAL_ARGUMENT_RESPONSE = 1;
  static const OSERROR_RESPONSE = 2;
  static const FILE_CLOSED_RESPONSE = 3;

  static const ERROR_RESPONSE_ERROR_TYPE = 0;
  static const OSERROR_RESPONSE_ERROR_CODE = 1;
  static const OSERROR_RESPONSE_MESSAGE = 2;

  static exists(String name) native "File_Exists";
  static open(String name, int mode) native "File_Open";
  static create(String name) native "File_Create";
  static delete(String name) native "File_Delete";
  static fullPath(String name) native "File_FullPath";
  static directory(String name) native "File_Directory";
  static lengthFromName(String name) native "File_LengthFromName";
  static lastModified(String name) native "File_LastModified";
  static int close(int id) native "File_Close";
  static readByte(int id) native "File_ReadByte";
  static readList(int id, List<int> buffer, int offset, int bytes)
      native "File_ReadList";
  static writeByte(int id, int value) native "File_WriteByte";
  static writeList(int id, List<int> buffer, int offset, int bytes) {
    List result = _ensureFastAndSerializableBuffer(buffer, offset, bytes);
    List outBuffer = result[0];
    int outOffset = result[1];
    return writeListNative(id, outBuffer, outOffset, bytes);
  }
  static writeListNative(int id, List<int> buffer, int offset, int bytes)
      native "File_WriteList";
  static writeString(int id, String string) native "File_WriteString";
  static position(int id) native "File_Position";
  static setPosition(int id, int position) native "File_SetPosition";
  static truncate(int id, int length) native "File_Truncate";
  static length(int id) native "File_Length";
  static flush(int id) native "File_Flush";
  static int openStdio(int fd) native "File_OpenStdio";
  static SendPort newServicePort() native "File_NewServicePort";

  static bool checkedExists(String name) {
    if (name is !String) throw new ArgumentError();
    var result = exists(name);
    throwIfError(result, "Cannot check existence of file '$name'");
    return result;
  }

  static int checkedOpen(String name, int mode) {
    if (name is !String || mode is !int) throw new ArgumentError();
    var result = open(name, mode);
    throwIfError(result, "Cannot open file '$name'");
    return result;
  }

  static bool checkedCreate(String name) {
    if (name is !String) throw new ArgumentError();
    var result = create(name);
    throwIfError(result, "Cannot create file '$name'");
    return true;
  }

  static bool checkedDelete(String name) {
    if (name is !String) throw new ArgumentError();
    var result = delete(name);
    throwIfError(result, "Cannot delete file '$name'");
    return true;
  }

  static String checkedFullPath(String name) {
    if (name is !String) throw new ArgumentError();
    var result = fullPath(name);
    throwIfError(result, "Cannot retrieve full path for file '$name'");
    return result;
  }

  static String checkedDirectory(String name) {
    if (name is !String) throw new ArgumentError();
    var result = directory(name);
    throwIfError(result, "Cannot retrieve directory for file '$name'");
    return result;
  }

  static int checkedLengthFromName(String name) {
    if (name is !String) throw new ArgumentError();
    var result = lengthFromName(name);
    throwIfError(result, "Cannot retrieve length of file '$name'");
    return result;
  }

  static int checkedLastModified(String name) {
    if (name is !String) throw new ArgumentError();
    var result = lastModified(name);
    throwIfError(result, "Cannot retrieve modification time for file '$name'");
    return result;
  }

  static int checkReadWriteListArguments(int length, int offset, int bytes) {
    if (offset < 0) return offset;
    if (bytes < 0) return bytes;
    if ((offset + bytes) > length) return offset + bytes;
    return 0;
  }

  static int checkedWriteString(int id, String string) {
    if (string is !String) throw new ArgumentError();
    return writeString(id, string);
  }

  static throwIfError(Object result, String msg) {
    if (result is OSError) {
      throw new FileIOException(msg, result);
    }
  }
}

// Base class for _File and _RandomAccessFile with shared functions.
class _FileBase {
  bool _isErrorResponse(response) {
    return response is List && response[0] != _FileUtils.SUCCESS_RESPONSE;
  }

  Exception _exceptionFromResponse(response, String message) {
    assert(_isErrorResponse(response));
    switch (response[_FileUtils.ERROR_RESPONSE_ERROR_TYPE]) {
      case _FileUtils.ILLEGAL_ARGUMENT_RESPONSE:
        return new ArgumentError();
      case _FileUtils.OSERROR_RESPONSE:
        var err = new OSError(response[_FileUtils.OSERROR_RESPONSE_MESSAGE],
                              response[_FileUtils.OSERROR_RESPONSE_ERROR_CODE]);
        return new FileIOException(message, err);
      case _FileUtils.FILE_CLOSED_RESPONSE:
        return new FileIOException("File closed");
      default:
        return new Exception("Unknown error");
    }
  }
}

// Class for encapsulating the native implementation of files.
class _File extends _FileBase implements File {
  // Constructor for file.
  _File(String this._name);

  // Constructor from Path for file.
  _File.fromPath(Path path) : this(path.toNativePath());

  Future<bool> exists() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _FileUtils.EXISTS_REQUEST;
    request[1] = _name;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "Cannot open file '$_name'");
      }
      return response;
    });
  }

  bool existsSync() {
    return _FileUtils.checkedExists(_name);
  }

  Future<File> create() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _FileUtils.CREATE_REQUEST;
    request[1] = _name;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "Cannot create file '$_name'");
      }
      return this;
    });
  }

  void createSync() {
    bool created = _FileUtils.checkedCreate(_name);
    if (!created) {
      throw new FileIOException("Cannot create file '$_name'");
    }
  }

  Future<File> delete() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _FileUtils.DELETE_REQUEST;
    request[1] = _name;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "Cannot delete file '$_name'");
      }
      return this;
    });
  }

  void deleteSync() {
    _FileUtils.checkedDelete(_name);
  }

  Future<Directory> directory() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _FileUtils.DIRECTORY_REQUEST;
    request[1] = _name;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "Cannot retrieve directory for "
                                     "file '$_name'");
      }
      return new Directory(response);
    });
  }

  Directory directorySync() {
    _FileUtils.checkedDirectory(_name);
    return new Directory(_FileUtils.directory(_name));
  }

  Future<RandomAccessFile> open([FileMode mode = FileMode.READ]) {
    _ensureFileService();
    Completer<RandomAccessFile> completer = new Completer<RandomAccessFile>();
    if (mode != FileMode.READ &&
        mode != FileMode.WRITE &&
        mode != FileMode.APPEND) {
      new Timer(0, (t) {
        completer.completeException(new ArgumentError());
      });
      return completer.future;
    }
    List request = new List(3);
    request[0] = _FileUtils.OPEN_REQUEST;
    request[1] = _name;
    request[2] = mode._mode;  // Direct int value for serialization.
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "Cannot open file '$_name'");
      }
      return new _RandomAccessFile(response, _name);
    });
  }

  Future<int> length() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _FileUtils.LENGTH_FROM_NAME_REQUEST;
    request[1] = _name;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "Cannot retrieve length of "
                                     "file '$_name'");
      }
      return response;
    });
  }

  int lengthSync() {
    return _FileUtils.checkedLengthFromName(_name);
  }

  Future<Date> lastModified() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _FileUtils.LAST_MODIFIED_REQUEST;
    request[1] = _name;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "Cannot retrieve modification time "
                                     "for file '$_name'");
      }
      return new Date.fromMillisecondsSinceEpoch(response);
    });
  }

  Date lastModifiedSync() {
    int ms = _FileUtils.checkedLastModified(_name);
    return new Date.fromMillisecondsSinceEpoch(ms);
  }

  RandomAccessFile openSync([FileMode mode = FileMode.READ]) {
    if (mode != FileMode.READ &&
        mode != FileMode.WRITE &&
        mode != FileMode.APPEND) {
      throw new FileIOException("Unknown file mode. Use FileMode.READ, "
                                "FileMode.WRITE or FileMode.APPEND.");
    }
    var id = _FileUtils.checkedOpen(_name, mode._mode);
    assert(id != 0);
    return new _RandomAccessFile(id, _name);
  }

  static RandomAccessFile _openStdioSync(int fd) {
    var id = _FileUtils.openStdio(fd);
    if (id == 0) {
      throw new FileIOException("Cannot open stdio file for: $fd");
    }
    return new _RandomAccessFile(id, "");
  }

  Future<String> fullPath() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _FileUtils.FULL_PATH_REQUEST;
    request[1] = _name;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "Cannot retrieve full path"
                                     " for '$_name'");
      }
      return response;
    });
  }

  String fullPathSync() {
    return _FileUtils.checkedFullPath(_name);
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

  Future<List<int>> readAsBytes() {
    _ensureFileService();
    Completer<List<int>> completer = new Completer<List<int>>();
    var chunks = new _BufferList();
    var stream = openInputStream();
    stream.onClosed = () {
      var result = chunks.readBytes(chunks.length);
      if (result == null) result = <int>[];
      completer.complete(result);
    };
    stream.onData = () {
      var chunk = stream.read();
      chunks.add(chunk);
    };
    stream.onError = completer.completeException;
    return completer.future;
  }

  List<int> readAsBytesSync() {
    var opened = openSync();
    var length = opened.lengthSync();
    var result = new Uint8List(length);
    var read = opened.readListSync(result, 0, length);
    if (read != length) {
      throw new FileIOException("Failed to read file");
    }
    opened.closeSync();
    return result;
  }

  Future<String> readAsText([Encoding encoding = Encoding.UTF_8]) {
    _ensureFileService();
    return readAsBytes().transform((bytes) {
      if (bytes.length == 0) return "";
      var decoder = _StringDecoders.decoder(encoding);
      decoder.write(bytes);
      return decoder.decoded();
    });
  }

  String readAsTextSync([Encoding encoding = Encoding.UTF_8]) {
    var decoder = _StringDecoders.decoder(encoding);
    List<int> bytes = readAsBytesSync();
    if (bytes.length == 0) return "";
    decoder.write(bytes);
    return decoder.decoded();
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
    var data = decoder.decoded();
    if (data != null) {
      result.add(data);
    }
    return result;
  }

  Future<List<String>> readAsLines([Encoding encoding = Encoding.UTF_8]) {
    _ensureFileService();
    Completer<List<String>> completer = new Completer<List<String>>();
    return readAsBytes().transform((bytes) {
      var decoder = _StringDecoders.decoder(encoding);
      decoder.write(bytes);
      return _getDecodedLines(decoder);
    });
  }

  List<String> readAsLinesSync([Encoding encoding = Encoding.UTF_8]) {
    var decoder = _StringDecoders.decoder(encoding);
    List<int> bytes = readAsBytesSync();
    decoder.write(bytes);
    return _getDecodedLines(decoder);
  }

  String get name => _name;

  void _ensureFileService() {
    if (_fileService == null) {
      _fileService = _FileUtils.newServicePort();
    }
  }

  final String _name;

  SendPort _fileService;
}


class _RandomAccessFile extends _FileBase implements RandomAccessFile {
  _RandomAccessFile(int this._id, String this._name);

  Future<RandomAccessFile> close() {
    Completer<RandomAccessFile> completer = new Completer<RandomAccessFile>();
    if (closed) return _completeWithClosedException(completer);
    _ensureFileService();
    List request = new List(2);
    request[0] = _FileUtils.CLOSE_REQUEST;
    request[1] = _id;
    // Set the id_ to 0 (NULL) to ensure the no more async requests
    // can be issued for this file.
    _id = 0;
    return _fileService.call(request).transform((result) {
      if (result != -1) {
        _id = result;
        return this;
      } else {
        throw new FileIOException("Cannot close file '$_name'");
      }
    });
  }

  void closeSync() {
    _checkNotClosed();
    var id = _FileUtils.close(_id);
    if (id == -1) {
      throw new FileIOException("Cannot close file '$_name'");
    }
    _id = id;
  }

  Future<int> readByte() {
    _ensureFileService();
    Completer<int> completer = new Completer<int>();
    if (closed) return _completeWithClosedException(completer);
    List request = new List(2);
    request[0] = _FileUtils.READ_BYTE_REQUEST;
    request[1] = _id;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "readByte failed for file '$_name'");
      }
      return response;
    });
  }

  int readByteSync() {
    _checkNotClosed();
    var result = _FileUtils.readByte(_id);
    if (result is OSError) {
      throw new FileIOException("readByte failed for file '$_name'", result);
    }
    return result;
  }

  Future<int> readList(List<int> buffer, int offset, int bytes) {
    _ensureFileService();
    Completer<int> completer = new Completer<int>();
    if (buffer is !List || offset is !int || bytes is !int) {
      // Complete asynchronously so the user has a chance to setup
      // handlers without getting exceptions when registering the
      // then handler.
      new Timer(0, (t) {
        completer.completeException(new FileIOException(
            "Invalid arguments to readList for file '$_name'"));
      });
      return completer.future;
    };
    if (closed) return _completeWithClosedException(completer);
    List request = new List(3);
    request[0] = _FileUtils.READ_LIST_REQUEST;
    request[1] = _id;
    request[2] = bytes;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "readList failed for file '$_name'");
      }
      var read = response[1];
      var data = response[2];
      buffer.setRange(offset, read, data);
      return read;
    });
  }

  int readListSync(List<int> buffer, int offset, int bytes) {
    _checkNotClosed();
    if (buffer is !List || offset is !int || bytes is !int) {
      throw new FileIOException(
          "Invalid arguments to readList for file '$_name'");
    }
    if (bytes == 0) return 0;
    int index =
        _FileUtils.checkReadWriteListArguments(buffer.length, offset, bytes);
    if (index != 0) {
      throw new IndexOutOfRangeException(index);
    }
    var result = _FileUtils.readList(_id, buffer, offset, bytes);
    if (result is OSError) {
      throw new FileIOException("readList failed for file '$_name'",
                                result);
    }
    return result;
  }

  Future<RandomAccessFile> writeByte(int value) {
    _ensureFileService();
    Completer<RandomAccessFile> completer = new Completer<RandomAccessFile>();
    if (value is !int) {
      // Complete asynchronously so the user has a chance to setup
      // handlers without getting exceptions when registering the
      // then handler.
      new Timer(0, (t) {
          completer.completeException(new FileIOException(
              "Invalid argument to writeByte for file '$_name'"));
      });
      return completer.future;
    }
    if (closed) return _completeWithClosedException(completer);
    List request = new List(3);
    request[0] = _FileUtils.WRITE_BYTE_REQUEST;
    request[1] = _id;
    request[2] = value;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "writeByte failed for file '$_name'");
      }
      return this;
    });
  }

  int writeByteSync(int value) {
    _checkNotClosed();
    if (value is !int) {
      throw new FileIOException(
          "Invalid argument to writeByte for file '$_name'");
    }
    var result = _FileUtils.writeByte(_id, value);
    if (result is OSError) {
      throw new FileIOException("writeByte failed for file '$_name'",
                                result);
    }
    return result;
  }

  Future<RandomAccessFile> writeList(List<int> buffer, int offset, int bytes) {
    _ensureFileService();
    Completer<RandomAccessFile> completer = new Completer<RandomAccessFile>();
    if (buffer is !List || offset is !int || bytes is !int) {
      // Complete asynchronously so the user has a chance to setup
      // handlers without getting exceptions when registering the
      // then handler.
      new Timer(0, (t) {
          completer.completeException(new FileIOException(
          "Invalid arguments to writeList for file '$_name'"));
      });
      return completer.future;
    }
    if (closed) return _completeWithClosedException(completer);

    List result;
    try {
      result = _ensureFastAndSerializableBuffer(buffer, offset, bytes);
    } catch (e) {
      // Complete asynchronously so the user has a chance to setup
      // handlers without getting exceptions when registering the
      // then handler.
      new Timer(0, (t) => completer.completeException(e));
      return completer.future;
    }
    List outBuffer = result[0];
    int outOffset = result[1];

    List request = new List(5);
    request[0] = _FileUtils.WRITE_LIST_REQUEST;
    request[1] = _id;
    request[2] = outBuffer;
    request[3] = outOffset;
    request[4] = bytes;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "writeList failed for file '$_name'");
      }
      return this;
    });
  }

  int writeListSync(List<int> buffer, int offset, int bytes) {
    _checkNotClosed();
    if (buffer is !List || offset is !int || bytes is !int) {
      throw new FileIOException(
          "Invalid arguments to writeList for file '$_name'");
    }
    if (bytes == 0) return 0;
    int index =
        _FileUtils.checkReadWriteListArguments(buffer.length, offset, bytes);
    if (index != 0) {
      throw new IndexOutOfRangeException(index);
    }
    var result = _FileUtils.writeList(_id, buffer, offset, bytes);
    if (result is OSError) {
      throw new FileIOException("writeList failed for file '$_name'", result);
    }
    return result;
  }

  Future<RandomAccessFile> writeString(String string,
                                       [Encoding encoding = Encoding.UTF_8]) {
    _ensureFileService();
    Completer<RandomAccessFile> completer = new Completer<RandomAccessFile>();
    if (closed) return _completeWithClosedException(completer);
    List request = new List(3);
    request[0] = _FileUtils.WRITE_STRING_REQUEST;
    request[1] = _id;
    request[2] = string;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "writeString failed for file '$_name'");
      }
      return this;
    });
  }

  int writeStringSync(String string, [Encoding encoding = Encoding.UTF_8]) {
    _checkNotClosed();
    var result = _FileUtils.checkedWriteString(_id, string);
    if (result is OSError) {
      throw new FileIOException("writeString failed for file '$_name'");
    }
    return result;
  }

  Future<int> position() {
    _ensureFileService();
    Completer<int> completer = new Completer<int>();
    if (closed) return _completeWithClosedException(completer);
    List request = new List(2);
    request[0] = _FileUtils.POSITION_REQUEST;
    request[1] = _id;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "position failed for file '$_name'");
      }
      return response;
    });
  }

  int positionSync() {
    _checkNotClosed();
    var result = _FileUtils.position(_id);
    if (result is OSError) {
      throw new FileIOException("position failed for file '$_name'", result);
    }
    return result;
  }

  Future<RandomAccessFile> setPosition(int position) {
    _ensureFileService();
    Completer<RandomAccessFile> completer = new Completer<RandomAccessFile>();
    if (closed) return _completeWithClosedException(completer);
    List request = new List(3);
    request[0] = _FileUtils.SET_POSITION_REQUEST;
    request[1] = _id;
    request[2] = position;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "setPosition failed for file '$_name'");
      }
      return this;
    });
  }

  void setPositionSync(int position) {
    _checkNotClosed();
    var result = _FileUtils.setPosition(_id, position);
    if (result is OSError) {
      throw new FileIOException("setPosition failed for file '$_name'", result);
    }
  }

  Future<RandomAccessFile> truncate(int length) {
    _ensureFileService();
    Completer<RandomAccessFile> completer = new Completer<RandomAccessFile>();
    if (closed) return _completeWithClosedException(completer);
    List request = new List(3);
    request[0] = _FileUtils.TRUNCATE_REQUEST;
    request[1] = _id;
    request[2] = length;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "truncate failed for file '$_name'");
      }
      return this;
    });
  }

  void truncateSync(int length) {
    _checkNotClosed();
    var result = _FileUtils.truncate(_id, length);
    if (result is OSError) {
      throw new FileIOException("truncate failed for file '$_name'", result);
    }
  }

  Future<int> length() {
    _ensureFileService();
    Completer<int> completer = new Completer<int>();
    if (closed) return _completeWithClosedException(completer);
    List request = new List(2);
    request[0] = _FileUtils.LENGTH_REQUEST;
    request[1] = _id;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "length failed for file '$_name'");
      }
      return response;
    });
  }

  int lengthSync() {
    _checkNotClosed();
    var result = _FileUtils.length(_id);
    if (result is OSError) {
      throw new FileIOException("length failed for file '$_name'", result);
    }
    return result;
  }

  Future<RandomAccessFile> flush() {
    _ensureFileService();
    Completer<RandomAccessFile> completer = new Completer<RandomAccessFile>();
    if (closed) return _completeWithClosedException(completer);
    List request = new List(2);
    request[0] = _FileUtils.FLUSH_REQUEST;
    request[1] = _id;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "flush failed for file '$_name'");
      }
      return this;
    });
  }

  void flushSync() {
    _checkNotClosed();
    var result = _FileUtils.flush(_id);
    if (result is OSError) {
      throw new FileIOException("flush failed for file '$_name'", result);
    }
  }

  String get name => _name;

  void _ensureFileService() {
    if (_fileService == null) {
      _fileService = _FileUtils.newServicePort();
    }
  }

  bool get closed => _id == 0;

  void _checkNotClosed() {
    if (closed) {
      throw new FileIOException("File closed '$_name'");
    }
  }

  Future _completeWithClosedException(Completer completer) {
    new Timer(0, (t) {
      completer.completeException(
          new FileIOException("File closed '$_name'"));
    });
    return completer.future;
  }

  final String _name;
  int _id;

  SendPort _fileService;
}
