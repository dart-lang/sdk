// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "io.dart";

// Read the file in blocks of size 64k.
const int _BLOCK_SIZE = 64 * 1024;

class _FileStream extends Stream<List<int>> {
  // Stream controller.
  StreamController<List<int>> _controller;

  // Information about the underlying file.
  String _path;
  RandomAccessFile _openedFile;
  int _position;
  int _end;
  final Completer _closeCompleter = new Completer();

  // Has the stream been paused or unsubscribed?
  bool _unsubscribed = false;

  // Is there a read currently in progress?
  bool _readInProgress = true;
  bool _closed = false;

  bool _atEnd = false;

  _FileStream(this._path, this._position, this._end) {
    if (_position == null) _position = 0;
  }

  _FileStream.forStdin() : _position = 0;

  StreamSubscription<List<int>> listen(void onData(List<int> event),
      {Function onError, void onDone(), bool cancelOnError}) {
    _setupController();
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  void _setupController() {
    _controller = new StreamController<List<int>>(
        sync: true,
        onListen: _start,
        onResume: _readBlock,
        onCancel: () {
          _unsubscribed = true;
          return _closeFile();
        });
  }

  Future _closeFile() {
    if (_readInProgress || _closed) {
      return _closeCompleter.future;
    }
    _closed = true;

    void done() {
      _closeCompleter.complete();
      _controller.close();
    }

    _openedFile.close().catchError(_controller.addError).whenComplete(done);
    return _closeCompleter.future;
  }

  void _readBlock() {
    // Don't start a new read if one is already in progress.
    if (_readInProgress) return;
    if (_atEnd) {
      _closeFile();
      return;
    }
    _readInProgress = true;
    int readBytes = _BLOCK_SIZE;
    if (_end != null) {
      readBytes = min(readBytes, _end - _position);
      if (readBytes < 0) {
        _readInProgress = false;
        if (!_unsubscribed) {
          _controller.addError(new RangeError("Bad end position: $_end"));
          _closeFile();
          _unsubscribed = true;
        }
        return;
      }
    }
    _openedFile.read(readBytes).then((block) {
      _readInProgress = false;
      if (_unsubscribed) {
        _closeFile();
        return;
      }
      _position += block.length;
      if (block.length < readBytes || (_end != null && _position == _end)) {
        _atEnd = true;
      }
      if (!_atEnd && !_controller.isPaused) {
        _readBlock();
      }
      _controller.add(block);
      if (_atEnd) {
        _closeFile();
      }
    }).catchError((e, s) {
      if (!_unsubscribed) {
        _controller.addError(e, s);
        _closeFile();
        _unsubscribed = true;
      }
    });
  }

  void _start() {
    if (_position < 0) {
      _controller.addError(new RangeError("Bad start position: $_position"));
      _controller.close();
      _closeCompleter.complete();
      return;
    }

    void onReady(RandomAccessFile file) {
      _openedFile = file;
      _readInProgress = false;
      _readBlock();
    }

    void onOpenFile(RandomAccessFile file) {
      if (_position > 0) {
        file.setPosition(_position).then(onReady, onError: (e, s) {
          _controller.addError(e, s);
          _readInProgress = false;
          _closeFile();
        });
      } else {
        onReady(file);
      }
    }

    void openFailed(error, stackTrace) {
      _controller.addError(error, stackTrace);
      _controller.close();
      _closeCompleter.complete();
    }

    if (_path != null) {
      new File(_path)
          .open(mode: FileMode.READ)
          .then(onOpenFile, onError: openFailed);
    } else {
      try {
        onOpenFile(_File._openStdioSync(0));
      } catch (e, s) {
        openFailed(e, s);
      }
    }
  }
}

class _FileStreamConsumer extends StreamConsumer<List<int>> {
  File _file;
  Future<RandomAccessFile> _openFuture;

  _FileStreamConsumer(this._file, FileMode mode) {
    _openFuture = _file.open(mode: mode);
  }

  _FileStreamConsumer.fromStdio(int fd) {
    assert(1 <= fd && fd <= 2);
    _openFuture = new Future.value(_File._openStdioSync(fd));
  }

  Future<File> addStream(Stream<List<int>> stream) {
    Completer<File> completer = new Completer<File>.sync();
    _openFuture.then((openedFile) {
      var _subscription;
      void error(e, [StackTrace stackTrace]) {
        _subscription.cancel();
        openedFile.close();
        completer.completeError(e, stackTrace);
      }

      _subscription = stream.listen((d) {
        _subscription.pause();
        try {
          openedFile
              .writeFrom(d, 0, d.length)
              .then((_) => _subscription.resume(), onError: error);
        } catch (e, stackTrace) {
          error(e, stackTrace);
        }
      }, onDone: () {
        completer.complete(_file);
      }, onError: error, cancelOnError: true);
    }).catchError(completer.completeError);
    return completer.future;
  }

  Future<File> close() =>
      _openFuture.then((openedFile) => openedFile.close()).then((_) => _file);
}

// Class for encapsulating the native implementation of files.
class _File extends FileSystemEntity implements File {
  final String path;

  // Constructor for file.
  _File(this.path) {
    if (path is! String) {
      throw new ArgumentError('${Error.safeToString(path)} '
          'is not a String');
    }
  }

  Future<bool> exists() {
    return _IOService._dispatch(_FILE_EXISTS, [path]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "Cannot check existence", path);
      }
      return response;
    });
  }

  external static _exists(String path);

  bool existsSync() {
    var result = _exists(path);
    throwIfError(result, "Cannot check existence of file", path);
    return result;
  }

  File get absolute => new File(_absolutePath);

  Future<File> create({bool recursive: false}) {
    var result =
        recursive ? parent.create(recursive: true) : new Future.value(null);
    return result
        .then((_) => _IOService._dispatch(_FILE_CREATE, [path]))
        .then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "Cannot create file", path);
      }
      return this;
    });
  }

  external static _create(String path);

  external static _createLink(String path, String target);

  external static _linkTarget(String path);

  void createSync({bool recursive: false}) {
    if (recursive) {
      parent.createSync(recursive: true);
    }
    var result = _create(path);
    throwIfError(result, "Cannot create file", path);
  }

  Future<File> _delete({bool recursive: false}) {
    if (recursive) {
      return new Directory(path).delete(recursive: true).then((_) => this);
    }
    return _IOService._dispatch(_FILE_DELETE, [path]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "Cannot delete file", path);
      }
      return this;
    });
  }

  external static _deleteNative(String path);

  external static _deleteLinkNative(String path);

  void _deleteSync({bool recursive: false}) {
    if (recursive) {
      return new Directory(path).deleteSync(recursive: true);
    }
    var result = _deleteNative(path);
    throwIfError(result, "Cannot delete file", path);
  }

  Future<File> rename(String newPath) {
    return _IOService._dispatch(_FILE_RENAME, [path, newPath]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(
            response, "Cannot rename file to '$newPath'", path);
      }
      return new File(newPath);
    });
  }

  external static _rename(String oldPath, String newPath);

  external static _renameLink(String oldPath, String newPath);

  File renameSync(String newPath) {
    var result = _rename(path, newPath);
    throwIfError(result, "Cannot rename file to '$newPath'", path);
    return new File(newPath);
  }

  Future<File> copy(String newPath) {
    return _IOService._dispatch(_FILE_COPY, [path, newPath]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(
            response, "Cannot copy file to '$newPath'", path);
      }
      return new File(newPath);
    });
  }

  external static _copy(String oldPath, String newPath);

  File copySync(String newPath) {
    var result = _copy(path, newPath);
    throwIfError(result, "Cannot copy file to '$newPath'", path);
    return new File(newPath);
  }

  Future<RandomAccessFile> open({FileMode mode: FileMode.READ}) {
    if (mode != FileMode.READ &&
        mode != FileMode.WRITE &&
        mode != FileMode.APPEND &&
        mode != FileMode.WRITE_ONLY &&
        mode != FileMode.WRITE_ONLY_APPEND) {
      return new Future.error(
          new ArgumentError('Invalid file mode for this operation'));
    }
    return _IOService
        ._dispatch(_FILE_OPEN, [path, mode._mode]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "Cannot open file", path);
      }
      return new _RandomAccessFile(response, path);
    });
  }

  Future<int> length() {
    return _IOService
        ._dispatch(_FILE_LENGTH_FROM_PATH, [path]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(
            response, "Cannot retrieve length of file", path);
      }
      return response;
    });
  }

  external static _lengthFromPath(String path);

  int lengthSync() {
    var result = _lengthFromPath(path);
    throwIfError(result, "Cannot retrieve length of file", path);
    return result;
  }

  Future<DateTime> lastAccessed() {
    return _IOService._dispatch(_FILE_LAST_ACCESSED, [path]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(
            response, "Cannot retrieve access time", path);
      }
      return new DateTime.fromMillisecondsSinceEpoch(response);
    });
  }

  external static _lastAccessed(String path);

  DateTime lastAccessedSync() {
    var ms = _lastAccessed(path);
    throwIfError(ms, "Cannot retrieve access time", path);
    return new DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future setLastAccessed(DateTime time) {
    int millis = time.millisecondsSinceEpoch;
    return _IOService
        ._dispatch(_FILE_SET_LAST_ACCESSED, [path, millis]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "Cannot set access time", path);
      }
      return null;
    });
  }

  external static _setLastAccessed(String path, int millis);

  void setLastAccessedSync(DateTime time) {
    int millis = time.millisecondsSinceEpoch;
    var result = _setLastAccessed(path, millis);
    if (result is OSError) {
      throw new FileSystemException(
          "Failed to set file access time", path, result);
    }
  }

  Future<DateTime> lastModified() {
    return _IOService._dispatch(_FILE_LAST_MODIFIED, [path]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(
            response, "Cannot retrieve modification time", path);
      }
      return new DateTime.fromMillisecondsSinceEpoch(response);
    });
  }

  external static _lastModified(String path);

  DateTime lastModifiedSync() {
    var ms = _lastModified(path);
    throwIfError(ms, "Cannot retrieve modification time", path);
    return new DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future setLastModified(DateTime time) {
    int millis = time.millisecondsSinceEpoch;
    return _IOService
        ._dispatch(_FILE_SET_LAST_MODIFIED, [path, millis]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(
            response, "Cannot set modification time", path);
      }
      return null;
    });
  }

  external static _setLastModified(String path, int millis);

  void setLastModifiedSync(DateTime time) {
    int millis = time.millisecondsSinceEpoch;
    var result = _setLastModified(path, millis);
    if (result is OSError) {
      throw new FileSystemException(
          "Failed to set file modification time", path, result);
    }
  }

  external static _open(String path, int mode);

  RandomAccessFile openSync({FileMode mode: FileMode.READ}) {
    if (mode != FileMode.READ &&
        mode != FileMode.WRITE &&
        mode != FileMode.APPEND &&
        mode != FileMode.WRITE_ONLY &&
        mode != FileMode.WRITE_ONLY_APPEND) {
      throw new ArgumentError('Invalid file mode for this operation');
    }
    var id = _open(path, mode._mode);
    throwIfError(id, "Cannot open file", path);
    return new _RandomAccessFile(id, path);
  }

  external static int _openStdio(int fd);

  static RandomAccessFile _openStdioSync(int fd) {
    var id = _openStdio(fd);
    if (id == 0) {
      throw new FileSystemException("Cannot open stdio file for: $fd");
    }
    return new _RandomAccessFile(id, "");
  }

  Stream<List<int>> openRead([int start, int end]) {
    return new _FileStream(path, start, end);
  }

  IOSink openWrite({FileMode mode: FileMode.WRITE, Encoding encoding: UTF8}) {
    if (mode != FileMode.WRITE &&
        mode != FileMode.APPEND &&
        mode != FileMode.WRITE_ONLY &&
        mode != FileMode.WRITE_ONLY_APPEND) {
      throw new ArgumentError('Invalid file mode for this operation');
    }
    var consumer = new _FileStreamConsumer(this, mode);
    return new IOSink(consumer, encoding: encoding);
  }

  Future<List<int>> readAsBytes() {
    Future<List<int>> readDataChunked(RandomAccessFile file) {
      var builder = new BytesBuilder(copy: false);
      var completer = new Completer<List<int>>();
      void read() {
        file.read(_BLOCK_SIZE).then((data) {
          if (data.length > 0) {
            builder.add(data);
            read();
          } else {
            completer.complete(builder.takeBytes());
          }
        }, onError: completer.completeError);
      }

      read();
      return completer.future;
    }

    return open().then((file) {
      return file.length().then((length) {
        if (length == 0) {
          // May be character device, try to read it in chunks.
          return readDataChunked(file);
        }
        return file.read(length);
      }).whenComplete(file.close);
    });
  }

  List<int> readAsBytesSync() {
    var opened = openSync();
    try {
      List<int> data;
      var length = opened.lengthSync();
      if (length == 0) {
        // May be character device, try to read it in chunks.
        var builder = new BytesBuilder(copy: false);
        do {
          data = opened.readSync(_BLOCK_SIZE);
          if (data.length > 0) builder.add(data);
        } while (data.length > 0);
        data = builder.takeBytes();
      } else {
        data = opened.readSync(length);
      }
      return data;
    } finally {
      opened.closeSync();
    }
  }

  String _tryDecode(List<int> bytes, Encoding encoding) {
    try {
      return encoding.decode(bytes);
    } catch (_) {
      throw new FileSystemException(
          "Failed to decode data using encoding '${encoding.name}'", path);
    }
  }

  Future<String> readAsString({Encoding encoding: UTF8}) =>
      readAsBytes().then((bytes) => _tryDecode(bytes, encoding));

  String readAsStringSync({Encoding encoding: UTF8}) =>
      _tryDecode(readAsBytesSync(), encoding);

  Future<List<String>> readAsLines({Encoding encoding: UTF8}) =>
      readAsString(encoding: encoding).then(const LineSplitter().convert);

  List<String> readAsLinesSync({Encoding encoding: UTF8}) =>
      const LineSplitter().convert(readAsStringSync(encoding: encoding));

  Future<File> writeAsBytes(List<int> bytes,
      {FileMode mode: FileMode.WRITE, bool flush: false}) {
    return open(mode: mode).then((file) {
      return file.writeFrom(bytes, 0, bytes.length).then<File>((_) {
        if (flush) return file.flush().then((_) => this);
        return this;
      }).whenComplete(file.close);
    });
  }

  void writeAsBytesSync(List<int> bytes,
      {FileMode mode: FileMode.WRITE, bool flush: false}) {
    RandomAccessFile opened = openSync(mode: mode);
    try {
      opened.writeFromSync(bytes, 0, bytes.length);
      if (flush) opened.flushSync();
    } finally {
      opened.closeSync();
    }
  }

  Future<File> writeAsString(String contents,
      {FileMode mode: FileMode.WRITE,
      Encoding encoding: UTF8,
      bool flush: false}) {
    try {
      return writeAsBytes(encoding.encode(contents), mode: mode, flush: flush);
    } catch (e) {
      return new Future.error(e);
    }
  }

  void writeAsStringSync(String contents,
      {FileMode mode: FileMode.WRITE,
      Encoding encoding: UTF8,
      bool flush: false}) {
    writeAsBytesSync(encoding.encode(contents), mode: mode, flush: flush);
  }

  String toString() => "File: '$path'";

  static throwIfError(Object result, String msg, String path) {
    if (result is OSError) {
      throw new FileSystemException(msg, path, result);
    }
  }
}

abstract class _RandomAccessFileOps {
  external factory _RandomAccessFileOps(int pointer);

  int getPointer();
  int close();
  readByte();
  read(int bytes);
  readInto(List<int> buffer, int start, int end);
  writeByte(int value);
  writeFrom(List<int> buffer, int start, int end);
  position();
  setPosition(int position);
  truncate(int length);
  length();
  flush();
  lock(int lock, int start, int end);
}

class _RandomAccessFile implements RandomAccessFile {
  static bool _connectedResourceHandler = false;

  final String path;

  bool _asyncDispatched = false;
  SendPort _fileService;

  _FileResourceInfo _resourceInfo;
  _RandomAccessFileOps _ops;

  _RandomAccessFile(int pointer, this.path) {
    _ops = new _RandomAccessFileOps(pointer);
    _resourceInfo = new _FileResourceInfo(this);
    _maybeConnectHandler();
  }

  void _maybePerformCleanup() {
    if (closed) {
      _FileResourceInfo.FileClosed(_resourceInfo);
    }
  }

  _maybeConnectHandler() {
    if (!_connectedResourceHandler) {
      // TODO(ricow): We probably need to set these in some initialization code.
      // We need to make sure that these are always available from the
      // observatory even if no files (or sockets for the socket ones) are
      // open.
      registerExtension(
          'ext.dart.io.getOpenFiles', _FileResourceInfo.getOpenFiles);
      registerExtension(
          'ext.dart.io.getFileByID', _FileResourceInfo.getFileInfoMapByID);
      _connectedResourceHandler = true;
    }
  }

  Future<RandomAccessFile> close() {
    return _dispatch(_FILE_CLOSE, [null], markClosed: true).then((result) {
      if (result != -1) {
        closed = closed || (result == 0);
        _maybePerformCleanup();
        return this;
      } else {
        throw new FileSystemException("Cannot close file", path);
      }
    });
  }

  void closeSync() {
    _checkAvailable();
    var id = _ops.close();
    if (id == -1) {
      throw new FileSystemException("Cannot close file", path);
    }
    closed = closed || (id == 0);
    _maybePerformCleanup();
  }

  Future<int> readByte() {
    return _dispatch(_FILE_READ_BYTE, [null]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "readByte failed", path);
      }
      _resourceInfo.addRead(1);
      return response;
    });
  }

  int readByteSync() {
    _checkAvailable();
    var result = _ops.readByte();
    if (result is OSError) {
      throw new FileSystemException("readByte failed", path, result);
    }
    _resourceInfo.addRead(1);
    return result;
  }

  Future<List<int>> read(int bytes) {
    if (bytes is! int) {
      throw new ArgumentError(bytes);
    }
    return _dispatch(_FILE_READ, [null, bytes]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "read failed", path);
      }
      _resourceInfo.addRead(response[1].length);
      return response[1] as Object/*=List<int>*/;
    });
  }

  List<int> readSync(int bytes) {
    _checkAvailable();
    if (bytes is! int) {
      throw new ArgumentError(bytes);
    }
    var result = _ops.read(bytes);
    if (result is OSError) {
      throw new FileSystemException("readSync failed", path, result);
    }
    _resourceInfo.addRead(result.length);
    return result as Object/*=List<int>*/;
  }

  Future<int> readInto(List<int> buffer, [int start = 0, int end]) {
    if ((buffer is! List) ||
        ((start != null) && (start is! int)) ||
        ((end != null) && (end is! int))) {
      throw new ArgumentError();
    }
    end = RangeError.checkValidRange(start, end, buffer.length);
    if (end == start) {
      return new Future.value(0);
    }
    int length = end - start;
    return _dispatch(_FILE_READ_INTO, [null, length]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "readInto failed", path);
      }
      var read = response[1];
      var data = response[2] as Object/*=List<int>*/;
      buffer.setRange(start, start + read, data);
      _resourceInfo.addRead(read);
      return read;
    });
  }

  int readIntoSync(List<int> buffer, [int start = 0, int end]) {
    _checkAvailable();
    if ((buffer is! List) ||
        ((start != null) && (start is! int)) ||
        ((end != null) && (end is! int))) {
      throw new ArgumentError();
    }
    end = RangeError.checkValidRange(start, end, buffer.length);
    if (end == start) {
      return 0;
    }
    var result = _ops.readInto(buffer, start, end);
    if (result is OSError) {
      throw new FileSystemException("readInto failed", path, result);
    }
    _resourceInfo.addRead(result);
    return result;
  }

  Future<RandomAccessFile> writeByte(int value) {
    if (value is! int) {
      throw new ArgumentError(value);
    }
    return _dispatch(_FILE_WRITE_BYTE, [null, value]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "writeByte failed", path);
      }
      _resourceInfo.addWrite(1);
      return this;
    });
  }

  int writeByteSync(int value) {
    _checkAvailable();
    if (value is! int) {
      throw new ArgumentError(value);
    }
    var result = _ops.writeByte(value);
    if (result is OSError) {
      throw new FileSystemException("writeByte failed", path, result);
    }
    _resourceInfo.addWrite(1);
    return result;
  }

  Future<RandomAccessFile> writeFrom(List<int> buffer,
      [int start = 0, int end]) {
    if ((buffer is! List) ||
        ((start != null) && (start is! int)) ||
        ((end != null) && (end is! int))) {
      throw new ArgumentError("Invalid arguments to writeFrom");
    }
    end = RangeError.checkValidRange(start, end, buffer.length);
    if (end == start) {
      return new Future.value(this);
    }
    _BufferAndStart result;
    try {
      result = _ensureFastAndSerializableByteData(buffer, start, end);
    } catch (e) {
      return new Future.error(e);
    }

    List request = new List(4);
    request[0] = null;
    request[1] = result.buffer;
    request[2] = result.start;
    request[3] = end - (start - result.start);
    return _dispatch(_FILE_WRITE_FROM, request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "writeFrom failed", path);
      }
      _resourceInfo.addWrite(end - (start - result.start));
      return this;
    });
  }

  void writeFromSync(List<int> buffer, [int start = 0, int end]) {
    _checkAvailable();
    if ((buffer is! List) ||
        ((start != null) && (start is! int)) ||
        ((end != null) && (end is! int))) {
      throw new ArgumentError("Invalid arguments to writeFromSync");
    }
    end = RangeError.checkValidRange(start, end, buffer.length);
    if (end == start) {
      return;
    }
    _BufferAndStart bufferAndStart =
        _ensureFastAndSerializableByteData(buffer, start, end);
    var result = _ops.writeFrom(bufferAndStart.buffer, bufferAndStart.start,
        end - (start - bufferAndStart.start));
    if (result is OSError) {
      throw new FileSystemException("writeFrom failed", path, result);
    }
    _resourceInfo.addWrite(end - (start - bufferAndStart.start));
  }

  Future<RandomAccessFile> writeString(String string,
      {Encoding encoding: UTF8}) {
    if (encoding is! Encoding) {
      throw new ArgumentError(encoding);
    }
    var data = encoding.encode(string);
    return writeFrom(data, 0, data.length);
  }

  void writeStringSync(String string, {Encoding encoding: UTF8}) {
    if (encoding is! Encoding) {
      throw new ArgumentError(encoding);
    }
    var data = encoding.encode(string);
    writeFromSync(data, 0, data.length);
  }

  Future<int> position() {
    return _dispatch(_FILE_POSITION, [null]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "position failed", path);
      }
      return response;
    });
  }

  int positionSync() {
    _checkAvailable();
    var result = _ops.position();
    if (result is OSError) {
      throw new FileSystemException("position failed", path, result);
    }
    return result;
  }

  Future<RandomAccessFile> setPosition(int position) {
    return _dispatch(_FILE_SET_POSITION, [null, position]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "setPosition failed", path);
      }
      return this;
    });
  }

  void setPositionSync(int position) {
    _checkAvailable();
    var result = _ops.setPosition(position);
    if (result is OSError) {
      throw new FileSystemException("setPosition failed", path, result);
    }
  }

  Future<RandomAccessFile> truncate(int length) {
    return _dispatch(_FILE_TRUNCATE, [null, length]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "truncate failed", path);
      }
      return this;
    });
  }

  void truncateSync(int length) {
    _checkAvailable();
    var result = _ops.truncate(length);
    if (result is OSError) {
      throw new FileSystemException("truncate failed", path, result);
    }
  }

  Future<int> length() {
    return _dispatch(_FILE_LENGTH, [null]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "length failed", path);
      }
      return response;
    });
  }

  int lengthSync() {
    _checkAvailable();
    var result = _ops.length();
    if (result is OSError) {
      throw new FileSystemException("length failed", path, result);
    }
    return result;
  }

  Future<RandomAccessFile> flush() {
    return _dispatch(_FILE_FLUSH, [null]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "flush failed", path);
      }
      return this;
    });
  }

  void flushSync() {
    _checkAvailable();
    var result = _ops.flush();
    if (result is OSError) {
      throw new FileSystemException("flush failed", path, result);
    }
  }

  static final int LOCK_UNLOCK = 0;
  static final int LOCK_SHARED = 1;
  static final int LOCK_EXCLUSIVE = 2;
  static final int LOCK_BLOCKING_SHARED = 3;
  static final int LOCK_BLOCKING_EXCLUSIVE = 4;

  int _fileLockValue(FileLock fl) {
    switch (fl) {
      case FileLock.SHARED:
        return LOCK_SHARED;
      case FileLock.EXCLUSIVE:
        return LOCK_EXCLUSIVE;
      case FileLock.BLOCKING_SHARED:
        return LOCK_BLOCKING_SHARED;
      case FileLock.BLOCKING_EXCLUSIVE:
        return LOCK_BLOCKING_EXCLUSIVE;
      default:
        return -1;
    }
  }

  Future<RandomAccessFile> lock(
      [FileLock mode = FileLock.EXCLUSIVE, int start = 0, int end = -1]) {
    if ((mode is! FileLock) || (start is! int) || (end is! int)) {
      throw new ArgumentError();
    }
    if ((start < 0) || (end < -1) || ((end != -1) && (start >= end))) {
      throw new ArgumentError();
    }
    int lock = _fileLockValue(mode);
    return _dispatch(_FILE_LOCK, [null, lock, start, end]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, 'lock failed', path);
      }
      return this;
    });
  }

  Future<RandomAccessFile> unlock([int start = 0, int end = -1]) {
    if ((start is! int) || (end is! int)) {
      throw new ArgumentError();
    }
    if (start == end) {
      throw new ArgumentError();
    }
    return _dispatch(_FILE_LOCK, [null, LOCK_UNLOCK, start, end])
        .then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, 'unlock failed', path);
      }
      return this;
    });
  }

  void lockSync(
      [FileLock mode = FileLock.EXCLUSIVE, int start = 0, int end = -1]) {
    _checkAvailable();
    if ((mode is! FileLock) || (start is! int) || (end is! int)) {
      throw new ArgumentError();
    }
    if ((start < 0) || (end < -1) || ((end != -1) && (start >= end))) {
      throw new ArgumentError();
    }
    int lock = _fileLockValue(mode);
    var result = _ops.lock(lock, start, end);
    if (result is OSError) {
      throw new FileSystemException('lock failed', path, result);
    }
  }

  void unlockSync([int start = 0, int end = -1]) {
    _checkAvailable();
    if ((start is! int) || (end is! int)) {
      throw new ArgumentError();
    }
    if (start == end) {
      throw new ArgumentError();
    }
    var result = _ops.lock(LOCK_UNLOCK, start, end);
    if (result is OSError) {
      throw new FileSystemException('unlock failed', path, result);
    }
  }

  bool closed = false;

  // Calling this function will increase the reference count on the native
  // object that implements the file operations. It should only be called to
  // pass the pointer to the IO Service, which will decrement the reference
  // count when it is finished with it.
  int _pointer() => _ops.getPointer();

  Future _dispatch(int request, List data, {bool markClosed: false}) {
    if (closed) {
      return new Future.error(new FileSystemException("File closed", path));
    }
    if (_asyncDispatched) {
      var msg = "An async operation is currently pending";
      return new Future.error(new FileSystemException(msg, path));
    }
    if (markClosed) {
      // Set closed to true to ensure that no more async requests can be issued
      // for this file.
      closed = true;
    }
    _asyncDispatched = true;
    data[0] = _pointer();
    return _IOService._dispatch(request, data).whenComplete(() {
      _asyncDispatched = false;
    });
  }

  void _checkAvailable() {
    if (_asyncDispatched) {
      throw new FileSystemException(
          "An async operation is currently pending", path);
    }
    if (closed) {
      throw new FileSystemException("File closed", path);
    }
  }
}
