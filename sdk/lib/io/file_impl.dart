// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

// Read the file in blocks of size 64k.
const int _BLOCK_SIZE = 64 * 1024;


class _FileStream extends Stream<List<int>> {
  // Stream controller.
  StreamController<List<int>> _controller;

  // Information about the underlying file.
  String _path;
  RandomAccessFile _openedFile;
  int _position;

  // Has the stream been paused or unsubscribed?
  bool _paused = false;
  bool _unsubscribed = false;

  // Is there a read currently in progress?
  bool _readInProgress = false;

  // Block read but not yet send because stream is paused.
  List<int> _currentBlock;

  _FileStream(String this._path) : _position = 0 {
    _setupController();
  }

  _FileStream.forStdin() : _position = 0 {
    _setupController();
  }

  StreamSubscription<List<int>> listen(void onData(List<int> event),
                                       {void onError(error),
                                        void onDone(),
                                        bool cancelOnError}) {
    return _controller.stream.listen(onData,
                                     onError: onError,
                                     onDone: onDone,
                                     cancelOnError: cancelOnError);
  }

  void _setupController() {
    _controller = new StreamController<List<int>>(
        onListen: _start,
        onPause: () => _paused = true,
        onResume: _resume,
        onCancel: () {
          _unsubscribed = true;
          _closeFile();
        });
  }

  Future _closeFile() {
    Future closeFuture;
    if (_openedFile != null) {
      Future closeFuture = _openedFile.close();
      _openedFile = null;
      return closeFuture;
    } else {
      return new Future.value();
    }
  }

  void _readBlock() {
    // Don't start a new read if one is already in progress.
    if (_readInProgress) return;
    _readInProgress = true;
    _openedFile.length()
      .then((length) {
        if (_position >= length) {
          _readInProgress = false;
          if (!_unsubscribed) {
            _closeFile().then((_) { _controller.close(); });
            _unsubscribed = true;
          }
          return null;
        } else {
          return _openedFile.read(_BLOCK_SIZE);
        }
      })
      .then((block) {
        _readInProgress = false;
        if (block == null || _unsubscribed) {
          return;
        }
        _position += block.length;
        if (_paused) {
          _currentBlock = block;
        } else {
          _controller.add(block);
          _readBlock();
        }
      })
      .catchError((e) {
        if (!_unsubscribed) {
          _controller.addError(e);
          _closeFile().then((_) { _controller.close(); });
          _unsubscribed = true;
        }
      });
  }

  void _start() {
    Future<RandomAccessFile> openFuture;
    if (_path != null) {
      openFuture = new File(_path).open(mode: FileMode.READ);
    } else {
      openFuture = new Future.value(_File._openStdioSync(0));
    }
    openFuture
      .then((RandomAccessFile opened) {
        _openedFile = opened;
        _readBlock();
      })
      .catchError((e) {
        _controller.addError(e);
        _controller.close();
      });
  }

  void _resume() {
    _paused = false;
    if (_currentBlock != null) {
      _controller.add(_currentBlock);
      _currentBlock = null;
    }
    // Resume reading unless we are already done.
    if (_openedFile != null) _readBlock();
  }
}

class _FileStreamConsumer extends StreamConsumer<List<int>> {
  File _file;
  Future<RandomAccessFile> _openFuture;
  StreamSubscription _subscription;

  _FileStreamConsumer(File this._file, FileMode mode) {
    _openFuture = _file.open(mode: mode);
  }

  _FileStreamConsumer.fromStdio(int fd) {
    assert(1 <= fd && fd <= 2);
    _openFuture = new Future.value(_File._openStdioSync(fd));
  }

  Future<File> addStream(Stream<List<int>> stream) {
    Completer<File> completer = new Completer<File>();
    _openFuture
      .then((openedFile) {
        _subscription = stream.listen(
          (d) {
            _subscription.pause();
            openedFile.writeFrom(d, 0, d.length)
              .then((_) => _subscription.resume())
              .catchError((e) {
                openedFile.close();
                completer.completeError(e);
              });
          },
          onDone: () {
            completer.complete(_file);
          },
          onError: (e) {
            openedFile.close();
            completer.completeError(e);
          },
          cancelOnError: true);
      })
      .catchError((e) {
        completer.completeError(e);
      });
    return completer.future;
  }

  Future<File> close() {
    return _openFuture.then((openedFile) => openedFile.close());
  }
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
const int _LENGTH_FROM_PATH_REQUEST = 11;
const int _LAST_MODIFIED_REQUEST = 12;
const int _FLUSH_REQUEST = 13;
const int _READ_BYTE_REQUEST = 14;
const int _WRITE_BYTE_REQUEST = 15;
const int _READ_REQUEST = 16;
const int _READ_LIST_REQUEST = 17;
const int _WRITE_LIST_REQUEST = 18;
const int _CREATE_LINK_REQUEST = 19;
const int _DELETE_LINK_REQUEST = 20;

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
  _File(String this._path) {
    if (_path is! String) {
      throw new ArgumentError('${Error.safeToString(_path)} '
                              'is not a String');
    }
  }

  // Constructor from Path for file.
  _File.fromPath(Path path) : this(path.toNativePath());

  Future<bool> exists() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _EXISTS_REQUEST;
    request[1] = _path;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "Cannot open file '$_path'");
      }
      return response;
    });
  }

  external static _exists(String path);

  bool existsSync() {
    var result = _exists(_path);
    throwIfError(result, "Cannot check existence of file '$_path'");
    return result;
  }

  Future<File> create() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _CREATE_REQUEST;
    request[1] = _path;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "Cannot create file '$_path'");
      }
      return this;
    });
  }

  external static _create(String path);

  external static _createLink(String path, String target);

  external static _linkTarget(String path);

  void createSync() {
    var result = _create(_path);
    throwIfError(result, "Cannot create file '$_path'");
  }

  Future<File> delete() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _DELETE_REQUEST;
    request[1] = _path;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "Cannot delete file '$_path'");
      }
      return this;
    });
  }

  external static _delete(String path);

  external static _deleteLink(String path);

  void deleteSync() {
    var result = _delete(_path);
    throwIfError(result, "Cannot delete file '$_path'");
  }

  Future<Directory> directory() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _DIRECTORY_REQUEST;
    request[1] = _path;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "Cannot retrieve directory for "
                                     "file '$_path'");
      }
      return new Directory(response);
    });
  }

  external static _directory(String path);

  Directory directorySync() {
    var result = _directory(path);
    throwIfError(result, "Cannot retrieve directory for file '$_path'");
    return new Directory(result);
  }

  Future<RandomAccessFile> open({FileMode mode: FileMode.READ}) {
    _ensureFileService();
    Completer<RandomAccessFile> completer = new Completer<RandomAccessFile>();
    if (mode != FileMode.READ &&
        mode != FileMode.WRITE &&
        mode != FileMode.APPEND) {
      Timer.run(() {
        completer.completeError(new ArgumentError());
      });
      return completer.future;
    }
    List request = new List(3);
    request[0] = _OPEN_REQUEST;
    request[1] = _path;
    request[2] = mode._mode;  // Direct int value for serialization.
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "Cannot open file '$_path'");
      }
      return new _RandomAccessFile(response, _path);
    });
  }

  Future<int> length() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _LENGTH_FROM_PATH_REQUEST;
    request[1] = _path;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "Cannot retrieve length of "
                                     "file '$_path'");
      }
      return response;
    });
  }


  external static _lengthFromPath(String path);

  int lengthSync() {
    var result = _lengthFromPath(_path);
    throwIfError(result, "Cannot retrieve length of file '$_path'");
    return result;
  }

  Future<DateTime> lastModified() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _LAST_MODIFIED_REQUEST;
    request[1] = _path;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "Cannot retrieve modification time "
                                     "for file '$_path'");
      }
      return new DateTime.fromMillisecondsSinceEpoch(response);
    });
  }

  external static _lastModified(String path);

  DateTime lastModifiedSync() {
    var ms = _lastModified(path);
    throwIfError(ms, "Cannot retrieve modification time for file '$_path'");
    return new DateTime.fromMillisecondsSinceEpoch(ms);
  }

  external static _open(String path, int mode);

  RandomAccessFile openSync({FileMode mode: FileMode.READ}) {
    if (mode != FileMode.READ &&
        mode != FileMode.WRITE &&
        mode != FileMode.APPEND) {
      throw new FileIOException("Unknown file mode. Use FileMode.READ, "
                                "FileMode.WRITE or FileMode.APPEND.");
    }
    var id = _open(_path, mode._mode);
    throwIfError(id, "Cannot open file '$_path'");
    return new _RandomAccessFile(id, _path);
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
    request[1] = _path;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "Cannot retrieve full path"
                                     " for '$_path'");
      }
      return response;
    });
  }

  external static _fullPath(String path);

  String fullPathSync() {
    var result = _fullPath(_path);
    throwIfError(result, "Cannot retrieve full path for file '$_path'");
    return result;
  }

  Stream<List<int>> openRead() {
    return new _FileStream(_path);
  }

  IOSink openWrite({FileMode mode: FileMode.WRITE,
                    Encoding encoding: Encoding.UTF_8}) {
    if (mode != FileMode.WRITE &&
        mode != FileMode.APPEND) {
      throw new FileIOException(
          "Wrong FileMode. Use FileMode.WRITE or FileMode.APPEND");
    }
    var consumer = new _FileStreamConsumer(this, mode);
    return new IOSink(consumer, encoding: encoding);
  }

  Future<List<int>> readAsBytes() {
    _ensureFileService();
    Completer<List<int>> completer = new Completer<List<int>>();
    var chunks = new _BufferList();
    openRead().listen(
      (d) => chunks.add(d),
      onDone: () {
        var result = chunks.readBytes(chunks.length);
        if (result == null) result = <int>[];
        completer.complete(result);
      },
      onError: (e) {
        completer.completeError(e);
      },
      cancelOnError: true);
    return completer.future;
  }

  List<int> readAsBytesSync() {
    var opened = openSync();
    var chunks = new _BufferList();
    var data;
    while ((data = opened.readSync(_BLOCK_SIZE)).length > 0) {
      chunks.add(data);
    }
    opened.closeSync();
    return chunks.readBytes();
  }

  Future<String> readAsString({Encoding encoding: Encoding.UTF_8}) {
    _ensureFileService();
    return readAsBytes().then((bytes) {
      return _decodeString(bytes, encoding);
    });
  }

  String readAsStringSync({Encoding encoding: Encoding.UTF_8}) {
    List<int> bytes = readAsBytesSync();
    return _decodeString(bytes, encoding);
  }

  static List<String> _decodeLines(List<int> bytes, Encoding encoding) {
    if (bytes.length == 0) return [];
    var list = [];
    var controller = new StreamController();
    controller.stream
        .transform(new StringDecoder(encoding))
        .transform(new LineTransformer())
        .listen((line) => list.add(line));
    controller.add(bytes);
    controller.close();
    return list;
  }

  Future<List<String>> readAsLines({Encoding encoding: Encoding.UTF_8}) {
    _ensureFileService();
    Completer<List<String>> completer = new Completer<List<String>>();
    return readAsBytes().then((bytes) {
      return _decodeLines(bytes, encoding);
    });
  }

  List<String> readAsLinesSync({Encoding encoding: Encoding.UTF_8}) {
    return _decodeLines(readAsBytesSync(), encoding);
  }

  Future<File> writeAsBytes(List<int> bytes,
                            {FileMode mode: FileMode.WRITE}) {
    try {
      IOSink sink = openWrite(mode: mode);
      sink.add(bytes);
      sink.close();
      return sink.done.then((_) => this);;
    } catch (e) {
      return new Future.error(e);
    }
  }

  void writeAsBytesSync(List<int> bytes, {FileMode mode: FileMode.WRITE}) {
    RandomAccessFile opened = openSync(mode: mode);
    opened.writeFromSync(bytes, 0, bytes.length);
    opened.closeSync();
  }

  Future<File> writeAsString(String contents,
                             {FileMode mode: FileMode.WRITE,
                              Encoding encoding: Encoding.UTF_8}) {
    try {
      return writeAsBytes(_encodeString(contents, encoding), mode: mode);
    } catch (e) {
      var completer = new Completer();
      Timer.run(() => completer.completeError(e));
      return completer.future;
    }
  }

  void writeAsStringSync(String contents,
                         {FileMode mode: FileMode.WRITE,
                          Encoding encoding: Encoding.UTF_8}) {
    writeAsBytesSync(_encodeString(contents, encoding), mode: mode);
  }

  String get path => _path;

  String toString() => "File: '$path'";

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

  final String _path;

  SendPort _fileService;
}


class _RandomAccessFile extends _FileBase implements RandomAccessFile {
  _RandomAccessFile(int this._id, String this._path);

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
    return _fileService.call(request).then((result) {
      if (result != -1) {
        _id = result;
        return this;
      } else {
        throw new FileIOException("Cannot close file '$_path'");
      }
    });
  }

  external static int _close(int id);

  void closeSync() {
    _checkNotClosed();
    var id = _close(_id);
    if (id == -1) {
      throw new FileIOException("Cannot close file '$_path'");
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
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "readByte failed for file '$_path'");
      }
      return response;
    });
  }

  external static _readByte(int id);

  int readByteSync() {
    _checkNotClosed();
    var result = _readByte(_id);
    if (result is OSError) {
      throw new FileIOException("readByte failed for file '$_path'", result);
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
      Timer.run(() {
        completer.completeError(new FileIOException(
            "Invalid arguments to read for file '$_path'"));
      });
      return completer.future;
    };
    if (closed) return _completeWithClosedException(completer);
    List request = new List(3);
    request[0] = _READ_REQUEST;
    request[1] = _id;
    request[2] = bytes;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "read failed for file '$_path'");
      }
      return response[1];
    });
  }

  external static _read(int id, int bytes);

  List<int> readSync(int bytes) {
    _checkNotClosed();
    if (bytes is !int) {
      throw new FileIOException(
          "Invalid arguments to readSync for file '$_path'");
    }
    var result = _read(_id, bytes);
    if (result is OSError) {
      throw new FileIOException("readSync failed for file '$_path'",
                                result);
    }
    return result;
  }

  Future<int> readInto(List<int> buffer, [int start, int end]) {
    _ensureFileService();
    if (buffer is !List ||
        (start != null && start is !int) ||
        (end != null && end is !int)) {
      return new Future.error(new FileIOException(
          "Invalid arguments to readInto for file '$_path'"));
    };
    Completer<int> completer = new Completer<int>();
    if (closed) return _completeWithClosedException(completer);
    List request = new List(3);
    if (start == null) start = 0;
    if (end == null) end = buffer.length;
    request[0] = _READ_LIST_REQUEST;
    request[1] = _id;
    request[2] = end - start;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "readInto failed for file '$_path'");
      }
      var read = response[1];
      var data = response[2];
      buffer.setRange(start, start + read, data);
      return read;
    });
  }

  static void _checkReadWriteListArguments(int length, int start, int end) {
    if (start < 0) throw new RangeError.value(start);
    if (end < start) throw new RangeError.value(end);
    if (end > length) {
      throw new RangeError.value(end);
    }
  }

  external static _readInto(int id, List<int> buffer, int start, int end);

  int readIntoSync(List<int> buffer, [int start, int end]) {
    _checkNotClosed();
    if (buffer is !List ||
        (start != null && start is !int) ||
        (end != null && end is !int)) {
      throw new FileIOException(
          "Invalid arguments to readInto for file '$_path'");
    }
    if (start == null) start = 0;
    if (end == null) end = buffer.length;
    if (end == start) return 0;
    _checkReadWriteListArguments(buffer.length, start, end);
    var result = _readInto(_id, buffer, start, end);
    if (result is OSError) {
      throw new FileIOException("readInto failed for file '$_path'",
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
      Timer.run(() {
          completer.completeError(new FileIOException(
              "Invalid argument to writeByte for file '$_path'"));
      });
      return completer.future;
    }
    if (closed) return _completeWithClosedException(completer);
    List request = new List(3);
    request[0] = _WRITE_BYTE_REQUEST;
    request[1] = _id;
    request[2] = value;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "writeByte failed for file '$_path'");
      }
      return this;
    });
  }

  external static _writeByte(int id, int value);

  int writeByteSync(int value) {
    _checkNotClosed();
    if (value is !int) {
      throw new FileIOException(
          "Invalid argument to writeByte for file '$_path'");
    }
    var result = _writeByte(_id, value);
    if (result is OSError) {
      throw new FileIOException("writeByte failed for file '$_path'",
                                result);
    }
    return result;
  }

  Future<RandomAccessFile> writeFrom(List<int> buffer, [int start, int end]) {
    _ensureFileService();
    if ((buffer is !List && buffer is !ByteData) ||
        (start != null && start is !int) ||
        (end != null && end is !int)) {
      return new Future.error(new FileIOException(
          "Invalid arguments to writeFrom for file '$_path'"));
    }
    Completer<RandomAccessFile> completer = new Completer<RandomAccessFile>();

    if (closed) return _completeWithClosedException(completer);

    _BufferAndStart result;
    try {
      result = _ensureFastAndSerializableBuffer(buffer, start, end);
    } catch (e) {
      return new Future.error(e);
    }

    List request = new List(5);
    request[0] = _WRITE_LIST_REQUEST;
    request[1] = _id;
    request[2] = result.buffer;
    request[3] = result.start;
    request[4] = end - (start - result.start);
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "writeFrom failed for file '$_path'");
      }
      return this;
    });
  }

  external static _writeFrom(int id, List<int> buffer, int start, int end);

  void writeFromSync(List<int> buffer, [int start, int end]) {
    _checkNotClosed();
    if (buffer is !List ||
        (start != null && start is !int) ||
        (end != null && end is !int)) {
      throw new FileIOException(
          "Invalid arguments to writeFrom for file '$_path'");
    }
    if (start == null) start = 0;
    if (end == null) end = buffer.length;
    if (end == start) return;
    _checkReadWriteListArguments(buffer.length, start, end);
    _BufferAndStart bufferAndStart =
        _ensureFastAndSerializableBuffer(buffer, start, end);
    var result = _writeFrom(_id,
                            bufferAndStart.buffer,
                            bufferAndStart.start,
                            end - (start - bufferAndStart.start));
    if (result is OSError) {
      throw new FileIOException("writeFrom failed for file '$_path'", result);
    }
  }

  Future<RandomAccessFile> writeString(String string,
                                       {Encoding encoding: Encoding.UTF_8}) {
    if (encoding is! Encoding) {
      var completer = new Completer();
      Timer.run(() {
        completer.completeError(new FileIOException(
            "Invalid encoding in writeString: $encoding"));
      });
      return completer.future;
    }
    var data = _encodeString(string, encoding);
    return writeFrom(data, 0, data.length);
  }

  void writeStringSync(String string, {Encoding encoding: Encoding.UTF_8}) {
    if (encoding is! Encoding) {
      throw new FileIOException(
          "Invalid encoding in writeStringSync: $encoding");
    }
    var data = _encodeString(string, encoding);
    writeFromSync(data, 0, data.length);
  }

  Future<int> position() {
    _ensureFileService();
    Completer<int> completer = new Completer<int>();
    if (closed) return _completeWithClosedException(completer);
    List request = new List(2);
    request[0] = _POSITION_REQUEST;
    request[1] = _id;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "position failed for file '$_path'");
      }
      return response;
    });
  }

  external static _position(int id);

  int positionSync() {
    _checkNotClosed();
    var result = _position(_id);
    if (result is OSError) {
      throw new FileIOException("position failed for file '$_path'", result);
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
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "setPosition failed for file '$_path'");
      }
      return this;
    });
  }

  external static _setPosition(int id, int position);

  void setPositionSync(int position) {
    _checkNotClosed();
    var result = _setPosition(_id, position);
    if (result is OSError) {
      throw new FileIOException("setPosition failed for file '$_path'", result);
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
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "truncate failed for file '$_path'");
      }
      return this;
    });
  }

  external static _truncate(int id, int length);

  void truncateSync(int length) {
    _checkNotClosed();
    var result = _truncate(_id, length);
    if (result is OSError) {
      throw new FileIOException("truncate failed for file '$_path'", result);
    }
  }

  Future<int> length() {
    _ensureFileService();
    Completer<int> completer = new Completer<int>();
    if (closed) return _completeWithClosedException(completer);
    List request = new List(2);
    request[0] = _LENGTH_REQUEST;
    request[1] = _id;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "length failed for file '$_path'");
      }
      return response;
    });
  }

  external static _length(int id);

  int lengthSync() {
    _checkNotClosed();
    var result = _length(_id);
    if (result is OSError) {
      throw new FileIOException("length failed for file '$_path'", result);
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
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "flush failed for file '$_path'");
      }
      return this;
    });
  }

  external static _flush(int id);

  void flushSync() {
    _checkNotClosed();
    var result = _flush(_id);
    if (result is OSError) {
      throw new FileIOException("flush failed for file '$_path'", result);
    }
  }

  String get path => _path;

  void _ensureFileService() {
    if (_fileService == null) {
      _fileService = _FileUtils._newServicePort();
    }
  }

  bool get closed => _id == 0;

  void _checkNotClosed() {
    if (closed) {
      throw new FileIOException("File closed '$_path'");
    }
  }

  Future _completeWithClosedException(Completer completer) {
    Timer.run(() {
      completer.completeError(
          new FileIOException("File closed '$_path'"));
    });
    return completer.future;
  }

  final String _path;
  int _id;

  SendPort _fileService;
}
