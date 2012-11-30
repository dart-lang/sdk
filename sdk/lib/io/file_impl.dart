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
    // If there is currently a _fillBuffer call waiting on read,
    // let it fill the buffer instead of us.
    if (_activeFillBufferCall) return;
    _activeFillBufferCall = true;
    var future = _openedFile.read(size);
    future.then((data) {
      _data = data;
      _position = 0;
      _filePosition += _data.length;
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

  void pipe(OutputStream output, {bool close: true}) {
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
      if (len > length) throw new RangeError.value(len);
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
        if (identical(buffer, _PendingOperation.CLOSE)) {
          close();
        } else {
          assert(identical(buffer, _PendingOperation.FLUSH));
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

const int _EXISTS_REQUEST = 0;
const int _CREATE_REQUEST = 1;
const int _DELETE_REQUEST = 2;
const int _OPEN_REQUEST = 3;
const int _FULL_PATH_REQUEST = 4;
const int _DIRECTORY_REQUEST = 5;
const int _CLOSE_REQUEST = 6;
const int _POSITION_REQUEST = 7;
const int _SET_POSITION_REQUEST = 8;
const int _TRUNCATE_REQUEST = 9;
const int _LENGTH_REQUEST = 10;
const int _LENGTH_FROM_NAME_REQUEST = 11;
const int _LAST_MODIFIED_REQUEST = 12;
const int _FLUSH_REQUEST = 13;
const int _READ_BYTE_REQUEST = 14;
const int _WRITE_BYTE_REQUEST = 15;
const int _READ_REQUEST = 16;
const int _READ_LIST_REQUEST = 17;
const int _WRITE_LIST_REQUEST = 18;

// Base class for _File and _RandomAccessFile with shared functions.
class _FileBase {
  bool _isErrorResponse(response) {
    return response is List && response[0] != _SUCCESS_RESPONSE;
  }

  _exceptionFromResponse(response, String message) {
    assert(_isErrorResponse(response));
    switch (response[_ERROR_RESPONSE_ERROR_TYPE]) {
      case _ILLEGAL_ARGUMENT_RESPONSE:
        return new ArgumentError();
      case _OSERROR_RESPONSE:
        var err = new OSError(response[_OSERROR_RESPONSE_MESSAGE],
                              response[_OSERROR_RESPONSE_ERROR_CODE]);
        return new FileIOException(message, err);
      case _FILE_CLOSED_RESPONSE:
        return new FileIOException("File closed");
      default:
        return new Exception("Unknown error");
    }
  }
}

// TODO(ager): The only reason for this class is that the patching
// mechanism doesn't seem to like patching a private top level
// function.
class _FileUtils {
  external static SendPort _newServicePort();
}

// Class for encapsulating the native implementation of files.
class _File extends _FileBase implements File {
  // Constructor for file.
  _File(String this._name) {
    if (_name is! String) {
      throw new ArgumentError('${Error.safeToString(_name)} '
                              'is not a String');
    }
  }

  // Constructor from Path for file.
  _File.fromPath(Path path) : this(path.toNativePath());

  Future<bool> exists() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _EXISTS_REQUEST;
    request[1] = _name;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "Cannot open file '$_name'");
      }
      return response;
    });
  }

  external static _exists(String name);

  bool existsSync() {
    var result = _exists(_name);
    throwIfError(result, "Cannot check existence of file '$_name'");
    return result;
  }

  Future<File> create() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _CREATE_REQUEST;
    request[1] = _name;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "Cannot create file '$_name'");
      }
      return this;
    });
  }

  external static _create(String name);

  void createSync() {
    var result = _create(_name);
    throwIfError(result, "Cannot create file '$_name'");
  }

  Future<File> delete() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _DELETE_REQUEST;
    request[1] = _name;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "Cannot delete file '$_name'");
      }
      return this;
    });
  }

  external static _delete(String name);

  void deleteSync() {
    var result = _delete(_name);
    throwIfError(result, "Cannot delete file '$_name'");
  }

  Future<Directory> directory() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _DIRECTORY_REQUEST;
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

  external static _directory(String name);

  Directory directorySync() {
    var result = _directory(name);
    throwIfError(result, "Cannot retrieve directory for file '$_name'");
    return new Directory(result);
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
    request[0] = _OPEN_REQUEST;
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
    request[0] = _LENGTH_FROM_NAME_REQUEST;
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


  external static _lengthFromName(String name);

  int lengthSync() {
    var result = _lengthFromName(_name);
    throwIfError(result, "Cannot retrieve length of file '$_name'");
    return result;
  }

  Future<Date> lastModified() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _LAST_MODIFIED_REQUEST;
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

  external static _lastModified(String name);

  Date lastModifiedSync() {
    var ms = _lastModified(name);
    throwIfError(ms, "Cannot retrieve modification time for file '$_name'");
    return new Date.fromMillisecondsSinceEpoch(ms);
  }

  external static _open(String name, int mode);

  RandomAccessFile openSync([FileMode mode = FileMode.READ]) {
    if (mode != FileMode.READ &&
        mode != FileMode.WRITE &&
        mode != FileMode.APPEND) {
      throw new FileIOException("Unknown file mode. Use FileMode.READ, "
                                "FileMode.WRITE or FileMode.APPEND.");
    }
    var id = _open(_name, mode._mode);
    throwIfError(id, "Cannot open file '$_name'");
    return new _RandomAccessFile(id, _name);
  }

  external static int _openStdio(int fd);

  static RandomAccessFile _openStdioSync(int fd) {
    var id = _openStdio(fd);
    if (id == 0) {
      throw new FileIOException("Cannot open stdio file for: $fd");
    }
    return new _RandomAccessFile(id, "");
  }

  Future<String> fullPath() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _FULL_PATH_REQUEST;
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

  external static _fullPath(String name);

  String fullPathSync() {
    var result = _fullPath(_name);
    throwIfError(result, "Cannot retrieve full path for file '$_name'");
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

  Future<String> readAsString([Encoding encoding = Encoding.UTF_8]) {
    _ensureFileService();
    return readAsBytes().transform((bytes) {
      if (bytes.length == 0) return "";
      var decoder = _StringDecoders.decoder(encoding);
      decoder.write(bytes);
      return decoder.decoded();
    });
  }

  String readAsStringSync([Encoding encoding = Encoding.UTF_8]) {
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

  Future<File> writeAsBytes(List<int> bytes,
                            [FileMode mode = FileMode.WRITE]) {
    Completer<File> completer = new Completer<File>();
    try {
      var stream = openOutputStream(mode);
      stream.write(bytes);
      stream.close();
      stream.onClosed = () {
        completer.complete(this);
      };
      stream.onError = (e) {
        completer.completeException(e);
      };
    } catch (e) {
      new Timer(0, (t) => completer.completeException(e));
      return completer.future;
    }
    return completer.future;
  }

  void writeAsBytesSync(List<int> bytes, [FileMode mode = FileMode.WRITE]) {
    RandomAccessFile opened = openSync(mode);
    opened.writeListSync(bytes, 0, bytes.length);
    opened.closeSync();
  }

  Future<File> writeAsString(String contents,
                             [FileMode mode = FileMode.WRITE,
                              Encoding encoding = Encoding.UTF_8]) {
    try {
      var data = _StringEncoders.encoder(encoding).encodeString(contents);
      return writeAsBytes(data, mode);
    } catch (e) {
      var completer = new Completer();
      new Timer(0, (t) => completer.completeException(e));
      return completer.future;
    }
  }

  void writeAsStringSync(String contents,
                         [FileMode mode = FileMode.WRITE,
                          Encoding encoding = Encoding.UTF_8]) {
    var data = _StringEncoders.encoder(encoding).encodeString(contents);
    writeAsBytesSync(data, mode);
  }

  String get name => _name;

  void _ensureFileService() {
    if (_fileService == null) {
      _fileService = _FileUtils._newServicePort();
    }
  }

  static throwIfError(Object result, String msg) {
    if (result is OSError) {
      throw new FileIOException(msg, result);
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
    request[0] = _CLOSE_REQUEST;
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

  external static int _close(int id);

  void closeSync() {
    _checkNotClosed();
    var id = _close(_id);
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
    request[0] = _READ_BYTE_REQUEST;
    request[1] = _id;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "readByte failed for file '$_name'");
      }
      return response;
    });
  }

  external static _readByte(int id);

  int readByteSync() {
    _checkNotClosed();
    var result = _readByte(_id);
    if (result is OSError) {
      throw new FileIOException("readByte failed for file '$_name'", result);
    }
    return result;
  }

  Future<List<int>> read(int bytes) {
    _ensureFileService();
    Completer<List<int>> completer = new Completer<List<int>>();
    if (bytes is !int) {
      // Complete asynchronously so the user has a chance to setup
      // handlers without getting exceptions when registering the
      // then handler.
      new Timer(0, (t) {
        completer.completeException(new FileIOException(
            "Invalid arguments to read for file '$_name'"));
      });
      return completer.future;
    };
    if (closed) return _completeWithClosedException(completer);
    List request = new List(3);
    request[0] = _READ_REQUEST;
    request[1] = _id;
    request[2] = bytes;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "read failed for file '$_name'");
      }
      return response[1];
    });
  }

  external static _read(int id, int bytes);

  List<int> readSync(int bytes) {
    if (bytes is !int) {
      throw new FileIOException(
          "Invalid arguments to readSync for file '$_name'");
    }
    return _read(_id, bytes);
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
    request[0] = _READ_LIST_REQUEST;
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

  static void _checkReadWriteListArguments(int length, int offset, int bytes) {
    if (offset < 0) throw new RangeError.value(offset);
    if (bytes < 0) throw new RangeError.value(bytes);
    if ((offset + bytes) > length) {
      throw new RangeError.value(offset + bytes);
    }
  }

  external static _readList(int id, List<int> buffer, int offset, int bytes);

  int readListSync(List<int> buffer, int offset, int bytes) {
    _checkNotClosed();
    if (buffer is !List || offset is !int || bytes is !int) {
      throw new FileIOException(
          "Invalid arguments to readList for file '$_name'");
    }
    if (bytes == 0) return 0;
    _checkReadWriteListArguments(buffer.length, offset, bytes);
    var result = _readList(_id, buffer, offset, bytes);
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
    request[0] = _WRITE_BYTE_REQUEST;
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

  external static _writeByte(int id, int value);

  int writeByteSync(int value) {
    _checkNotClosed();
    if (value is !int) {
      throw new FileIOException(
          "Invalid argument to writeByte for file '$_name'");
    }
    var result = _writeByte(_id, value);
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

    _BufferAndOffset result;
    try {
      result = _ensureFastAndSerializableBuffer(buffer, offset, bytes);
    } catch (e) {
      // Complete asynchronously so the user has a chance to setup
      // handlers without getting exceptions when registering the
      // then handler.
      new Timer(0, (t) => completer.completeException(e));
      return completer.future;
    }

    List request = new List(5);
    request[0] = _WRITE_LIST_REQUEST;
    request[1] = _id;
    request[2] = result.buffer;
    request[3] = result.offset;
    request[4] = bytes;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "writeList failed for file '$_name'");
      }
      return this;
    });
  }

  external static _writeList(int id, List<int> buffer, int offset, int bytes);

  int writeListSync(List<int> buffer, int offset, int bytes) {
    _checkNotClosed();
    if (buffer is !List || offset is !int || bytes is !int) {
      throw new FileIOException(
          "Invalid arguments to writeList for file '$_name'");
    }
    if (bytes == 0) return 0;
    _checkReadWriteListArguments(buffer.length, offset, bytes);
    _BufferAndOffset bufferAndOffset =
        _ensureFastAndSerializableBuffer(buffer, offset, bytes);
    var result =
      _writeList(_id, bufferAndOffset.buffer, bufferAndOffset.offset, bytes);
    if (result is OSError) {
      throw new FileIOException("writeList failed for file '$_name'", result);
    }
    return result;
  }

  Future<RandomAccessFile> writeString(String string,
                                       [Encoding encoding = Encoding.UTF_8]) {
    if (encoding is! Encoding) {
      var completer = new Completer();
      new Timer(0, (t) {
        completer.completeException(new FileIOException(
            "Invalid encoding in writeString: $encoding"));
      });
      return completer.future;
    }
    var data = _StringEncoders.encoder(encoding).encodeString(string);
    return writeList(data, 0, data.length);
  }

  int writeStringSync(String string, [Encoding encoding = Encoding.UTF_8]) {
    if (encoding is! Encoding) {
      throw new FileIOException(
          "Invalid encoding in writeStringSync: $encoding");
    }
    var data = _StringEncoders.encoder(encoding).encodeString(string);
    return writeListSync(data, 0, data.length);
  }

  Future<int> position() {
    _ensureFileService();
    Completer<int> completer = new Completer<int>();
    if (closed) return _completeWithClosedException(completer);
    List request = new List(2);
    request[0] = _POSITION_REQUEST;
    request[1] = _id;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "position failed for file '$_name'");
      }
      return response;
    });
  }

  external static _position(int id);

  int positionSync() {
    _checkNotClosed();
    var result = _position(_id);
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
    request[0] = _SET_POSITION_REQUEST;
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

  external static _setPosition(int id, int position);

  void setPositionSync(int position) {
    _checkNotClosed();
    var result = _setPosition(_id, position);
    if (result is OSError) {
      throw new FileIOException("setPosition failed for file '$_name'", result);
    }
  }

  Future<RandomAccessFile> truncate(int length) {
    _ensureFileService();
    Completer<RandomAccessFile> completer = new Completer<RandomAccessFile>();
    if (closed) return _completeWithClosedException(completer);
    List request = new List(3);
    request[0] = _TRUNCATE_REQUEST;
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

  external static _truncate(int id, int length);

  void truncateSync(int length) {
    _checkNotClosed();
    var result = _truncate(_id, length);
    if (result is OSError) {
      throw new FileIOException("truncate failed for file '$_name'", result);
    }
  }

  Future<int> length() {
    _ensureFileService();
    Completer<int> completer = new Completer<int>();
    if (closed) return _completeWithClosedException(completer);
    List request = new List(2);
    request[0] = _LENGTH_REQUEST;
    request[1] = _id;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "length failed for file '$_name'");
      }
      return response;
    });
  }

  external static _length(int id);

  int lengthSync() {
    _checkNotClosed();
    var result = _length(_id);
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
    request[0] = _FLUSH_REQUEST;
    request[1] = _id;
    return _fileService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "flush failed for file '$_name'");
      }
      return this;
    });
  }

  external static _flush(int id);

  void flushSync() {
    _checkNotClosed();
    var result = _flush(_id);
    if (result is OSError) {
      throw new FileIOException("flush failed for file '$_name'", result);
    }
  }

  String get name => _name;

  void _ensureFileService() {
    if (_fileService == null) {
      _fileService = _FileUtils._newServicePort();
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
