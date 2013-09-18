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
  int _end;

  // Has the stream been paused or unsubscribed?
  bool _paused = false;
  bool _unsubscribed = false;

  // Is there a read currently in progress?
  bool _readInProgress = false;

  // Block read but not yet send because stream is paused.
  List<int> _currentBlock;

  _FileStream(String this._path, this._position, this._end) {
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
    _controller = new StreamController<List<int>>(sync: true,
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
    int readBytes = _BLOCK_SIZE;
    if (_end != null) {
      readBytes = min(readBytes, _end - _position);
      if (readBytes < 0) {
        if (!_unsubscribed) {
          _controller.addError(new RangeError("Bad end position: $_end"));
          _closeFile().then((_) { _controller.close(); });
          _unsubscribed = true;
        }
        return;
      }
    }
    _openedFile.read(readBytes)
      .then((block) {
        _readInProgress = false;
        if (block.length == 0) {
          if (!_unsubscribed) {
            _closeFile().then((_) { _controller.close(); });
            _unsubscribed = true;
          }
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
    if (_position == null) {
      _position = 0;
    } else if (_position < 0) {
      _controller.addError(new RangeError("Bad start position: $_position"));
      _controller.close();
      return;
    }
    Future<RandomAccessFile> openFuture;
    if (_path != null) {
      openFuture = new File(_path).open(mode: FileMode.READ);
    } else {
      openFuture = new Future.value(_File._openStdioSync(0));
    }
    openFuture
      .then((RandomAccessFile opened) {
        _openedFile = opened;
        if (_position > 0) {
          return opened.setPosition(_position);
        }
      })
      .then((_) => _readBlock())
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
const int _RENAME_REQUEST = 3;
const int _OPEN_REQUEST = 4;
const int _RESOLVE_SYMBOLIC_LINKS_REQUEST = 5;
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
const int _RENAME_LINK_REQUEST = 21;
const int _LINK_TARGET_REQUEST = 22;
const int _TYPE_REQUEST = 23;
const int _IDENTICAL_REQUEST = 24;
const int _STAT_REQUEST = 25;

// TODO(ager): The only reason for this class is that the patching
// mechanism doesn't seem to like patching a private top level
// function.
class _FileUtils {
  external static SendPort _newServicePort();
}

// Class for encapsulating the native implementation of files.
class _File extends FileSystemEntity implements File {
  final String path;
  SendPort _fileService;

  // Constructor for file.
  _File(String this.path) {
    if (path is! String) {
      throw new ArgumentError('${Error.safeToString(path)} '
                              'is not a String');
    }
  }

  Future<bool> exists() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _EXISTS_REQUEST;
    request[1] = path;
    return _fileService.call(request).then((response) {
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

  Future<FileStat> stat() => FileStat.stat(path);

  FileStat statSync() => FileStat.statSync(path);

  Future<File> create() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _CREATE_REQUEST;
    request[1] = path;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "Cannot create file", path);
      }
      return this;
    });
  }

  external static _create(String path);

  external static _createLink(String path, String target);

  external static _linkTarget(String path);

  void createSync() {
    var result = _create(path);
    throwIfError(result, "Cannot create file", path);
  }

  Future<File> _delete({bool recursive: false}) {
    if (recursive) {
      return new Directory(path).delete(recursive: true).then((_) => this);
    }
    _ensureFileService();
    List request = new List(2);
    request[0] = _DELETE_REQUEST;
    request[1] = path;
    return _fileService.call(request).then((response) {
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
    _ensureFileService();
    List request = new List(3);
    request[0] = _RENAME_REQUEST;
    request[1] = path;
    request[2] = newPath;
    return _fileService.call(request).then((response) {
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

  Directory get directory {
    _Path path = new _Path(this.path).directoryPath;
    return new Directory(path.toNativePath());
  }

  Future<RandomAccessFile> open({FileMode mode: FileMode.READ}) {
    _ensureFileService();
    if (mode != FileMode.READ &&
        mode != FileMode.WRITE &&
        mode != FileMode.APPEND) {
      return new Future.error(new ArgumentError());
    }
    List request = new List(3);
    request[0] = _OPEN_REQUEST;
    request[1] = path;
    request[2] = mode._mode;  // Direct int value for serialization.
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "Cannot open file", path);
      }
      return new _RandomAccessFile(response, path);
    });
  }

  Future<int> length() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _LENGTH_FROM_PATH_REQUEST;
    request[1] = path;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "Cannot retrieve length of file",
                                     path);
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

  Future<DateTime> lastModified() {
    _ensureFileService();
    List request = new List(2);
    request[0] = _LAST_MODIFIED_REQUEST;
    request[1] = path;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "Cannot retrieve modification time",
                                     path);
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

  external static _open(String path, int mode);

  RandomAccessFile openSync({FileMode mode: FileMode.READ}) {
    if (mode != FileMode.READ &&
        mode != FileMode.WRITE &&
        mode != FileMode.APPEND) {
      throw new FileException("Unknown file mode. Use FileMode.READ, "
                              "FileMode.WRITE or FileMode.APPEND.",
                              path);
    }
    var id = _open(path, mode._mode);
    throwIfError(id, "Cannot open file", path);
    return new _RandomAccessFile(id, path);
  }

  external static int _openStdio(int fd);

  static RandomAccessFile _openStdioSync(int fd) {
    var id = _openStdio(fd);
    if (id == 0) {
      throw new FileException("Cannot open stdio file for: $fd");
    }
    return new _RandomAccessFile(id, "");
  }

  Future<String> fullPath() => resolveSymbolicLinks();

  String fullPathSync() => resolveSymbolicLinksSync();

  Stream<List<int>> openRead([int start, int end]) {
    return new _FileStream(path, start, end);
  }

  IOSink openWrite({FileMode mode: FileMode.WRITE,
                    Encoding encoding: UTF8}) {
    if (mode != FileMode.WRITE &&
        mode != FileMode.APPEND) {
      throw new ArgumentError(
          "Wrong FileMode. Use FileMode.WRITE or FileMode.APPEND");
    }
    var consumer = new _FileStreamConsumer(this, mode);
    return new IOSink(consumer, encoding: encoding);
  }

  Future<List<int>> readAsBytes() {
    _ensureFileService();
    Completer<List<int>> completer = new Completer<List<int>>();
    var builder = new BytesBuilder();
    openRead().listen(
      (d) => builder.add(d),
      onDone: () {
        completer.complete(builder.takeBytes());
      },
      onError: (e) {
        completer.completeError(e);
      },
      cancelOnError: true);
    return completer.future;
  }

  List<int> readAsBytesSync() {
    var opened = openSync();
    var builder = new BytesBuilder();
    var data;
    while ((data = opened.readSync(_BLOCK_SIZE)).length > 0) {
      builder.add(data);
    }
    opened.closeSync();
    return builder.takeBytes();
  }

  String _tryDecode(List<int> bytes, Encoding encoding) {
    try {
      return encoding.decode(bytes);
    } catch (_) {
      throw new FileException(
          "Failed to decode data using encoding '${encoding.name}'", path);
    }
  }

  Future<String> readAsString({Encoding encoding: UTF8}) {
    _ensureFileService();
    return readAsBytes().then((bytes) {
      return _tryDecode(bytes, encoding);
    });
  }

  String readAsStringSync({Encoding encoding: UTF8}) {
    List<int> bytes = readAsBytesSync();
    return _tryDecode(bytes, encoding);
  }

  List<String> _decodeLines(List<int> bytes, Encoding encoding) {
    if (bytes.length == 0) return [];
    var list = [];
    var controller = new StreamController(sync: true);
    var error = null;
    controller.stream
        .transform(encoding.decoder)
        .transform(new LineSplitter())
        .listen((line) => list.add(line), onError: (e) => error = e);
    controller.add(bytes);
    controller.close();
    if (error != null) {
      throw new FileException(
          "Failed to decode data using encoding '${encoding.name}'", path);
    }
    return list;
  }

  Future<List<String>> readAsLines({Encoding encoding: UTF8}) {
    _ensureFileService();
    return readAsBytes().then((bytes) {
      return _decodeLines(bytes, encoding);
    });
  }

  List<String> readAsLinesSync({Encoding encoding: UTF8}) {
    return _decodeLines(readAsBytesSync(), encoding);
  }

  Future<File> writeAsBytes(List<int> bytes,
                            {FileMode mode: FileMode.WRITE}) {
    try {
      IOSink sink = openWrite(mode: mode);
      sink.add(bytes);
      sink.close();
      return sink.done.then((_) => this);
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
                              Encoding encoding: UTF8}) {
    try {
      return writeAsBytes(encoding.encode(contents), mode: mode);
    } catch (e) {
      return new Future.error(e);
    }
  }

  void writeAsStringSync(String contents,
                         {FileMode mode: FileMode.WRITE,
                          Encoding encoding: UTF8}) {
    writeAsBytesSync(encoding.encode(contents), mode: mode);
  }

  String toString() => "File: '$path'";

  void _ensureFileService() {
    if (_fileService == null) {
      _fileService = _FileUtils._newServicePort();
    }
  }

  static throwIfError(Object result, String msg, String path) {
    if (result is OSError) {
      throw new FileException(msg, path, result);
    }
  }
}


class _RandomAccessFile implements RandomAccessFile {
  final String path;
  int _id;
  SendPort _fileService;

  _RandomAccessFile(int this._id, String this.path);

  Future<RandomAccessFile> close() {
    if (closed) return _closedException();
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
        throw new FileException("Cannot close file", path);
      }
    });
  }

  external static int _close(int id);

  void closeSync() {
    _checkNotClosed();
    var id = _close(_id);
    if (id == -1) {
      throw new FileException("Cannot close file", path);
    }
    _id = id;
  }

  Future<int> readByte() {
    _ensureFileService();
    if (closed) return _closedException();
    List request = new List(2);
    request[0] = _READ_BYTE_REQUEST;
    request[1] = _id;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "readByte failed", path);
      }
      return response;
    });
  }

  external static _readByte(int id);

  int readByteSync() {
    _checkNotClosed();
    var result = _readByte(_id);
    if (result is OSError) {
      throw new FileException("readByte failed", path, result);
    }
    return result;
  }

  Future<List<int>> read(int bytes) {
    _ensureFileService();
    if (bytes is !int) {
      throw new ArgumentError(bytes);
    }
    if (closed) return _closedException();
    List request = new List(3);
    request[0] = _READ_REQUEST;
    request[1] = _id;
    request[2] = bytes;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "read failed", path);
      }
      return response[1];
    });
  }

  external static _read(int id, int bytes);

  List<int> readSync(int bytes) {
    _checkNotClosed();
    if (bytes is !int) {
      throw new ArgumentError(bytes);
    }
    var result = _read(_id, bytes);
    if (result is OSError) {
      throw new FileException("readSync failed", path, result);
    }
    return result;
  }

  Future<int> readInto(List<int> buffer, [int start, int end]) {
    _ensureFileService();
    if (buffer is !List ||
        (start != null && start is !int) ||
        (end != null && end is !int)) {
      throw new ArgumentError();
    }
    if (closed) return _closedException();
    List request = new List(3);
    if (start == null) start = 0;
    if (end == null) end = buffer.length;
    request[0] = _READ_LIST_REQUEST;
    request[1] = _id;
    request[2] = end - start;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "readInto failed", path);
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
      throw new ArgumentError();
    }
    if (start == null) start = 0;
    if (end == null) end = buffer.length;
    if (end == start) return 0;
    _checkReadWriteListArguments(buffer.length, start, end);
    var result = _readInto(_id, buffer, start, end);
    if (result is OSError) {
      throw new FileException("readInto failed", path, result);
    }
    return result;
  }

  Future<RandomAccessFile> writeByte(int value) {
    _ensureFileService();
    if (value is !int) {
      throw new ArgumentError(value);
    }
    if (closed) return _closedException();
    List request = new List(3);
    request[0] = _WRITE_BYTE_REQUEST;
    request[1] = _id;
    request[2] = value;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "writeByte failed", path);
      }
      return this;
    });
  }

  external static _writeByte(int id, int value);

  int writeByteSync(int value) {
    _checkNotClosed();
    if (value is !int) {
      throw new ArgumentError(value);
    }
    var result = _writeByte(_id, value);
    if (result is OSError) {
      throw new FileException("writeByte failed", path, result);
    }
    return result;
  }

  Future<RandomAccessFile> writeFrom(List<int> buffer, [int start, int end]) {
    _ensureFileService();
    if ((buffer is !List && buffer is !ByteData) ||
        (start != null && start is !int) ||
        (end != null && end is !int)) {
      throw new ArgumentError("Invalid arguments to writeFrom");
    }

    if (closed) return _closedException();

    _BufferAndStart result;
    try {
      result = _ensureFastAndSerializableByteData(buffer, start, end);
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
        throw _exceptionFromResponse(response, "writeFrom failed", path);
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
      throw new ArgumentError("Invalid arguments to writeFromSync");
    }
    if (start == null) start = 0;
    if (end == null) end = buffer.length;
    if (end == start) return;
    _checkReadWriteListArguments(buffer.length, start, end);
    _BufferAndStart bufferAndStart =
        _ensureFastAndSerializableByteData(buffer, start, end);
    var result = _writeFrom(_id,
                            bufferAndStart.buffer,
                            bufferAndStart.start,
                            end - (start - bufferAndStart.start));
    if (result is OSError) {
      throw new FileException("writeFrom failed", path, result);
    }
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
    _ensureFileService();
    if (closed) return _closedException();
    List request = new List(2);
    request[0] = _POSITION_REQUEST;
    request[1] = _id;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "position failed", path);
      }
      return response;
    });
  }

  external static _position(int id);

  int positionSync() {
    _checkNotClosed();
    var result = _position(_id);
    if (result is OSError) {
      throw new FileException("position failed", path, result);
    }
    return result;
  }

  Future<RandomAccessFile> setPosition(int position) {
    _ensureFileService();
    if (closed) return _closedException();
    List request = new List(3);
    request[0] = _SET_POSITION_REQUEST;
    request[1] = _id;
    request[2] = position;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "setPosition failed", path);
      }
      return this;
    });
  }

  external static _setPosition(int id, int position);

  void setPositionSync(int position) {
    _checkNotClosed();
    var result = _setPosition(_id, position);
    if (result is OSError) {
      throw new FileException("setPosition failed", path, result);
    }
  }

  Future<RandomAccessFile> truncate(int length) {
    _ensureFileService();
    if (closed) return _closedException();
    List request = new List(3);
    request[0] = _TRUNCATE_REQUEST;
    request[1] = _id;
    request[2] = length;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "truncate failed", path);
      }
      return this;
    });
  }

  external static _truncate(int id, int length);

  void truncateSync(int length) {
    _checkNotClosed();
    var result = _truncate(_id, length);
    if (result is OSError) {
      throw new FileException("truncate failed", path, result);
    }
  }

  Future<int> length() {
    _ensureFileService();
    if (closed) return _closedException();
    List request = new List(2);
    request[0] = _LENGTH_REQUEST;
    request[1] = _id;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "length failed", path);
      }
      return response;
    });
  }

  external static _length(int id);

  int lengthSync() {
    _checkNotClosed();
    var result = _length(_id);
    if (result is OSError) {
      throw new FileException("length failed", path, result);
    }
    return result;
  }

  Future<RandomAccessFile> flush() {
    _ensureFileService();
    if (closed) return _closedException();
    List request = new List(2);
    request[0] = _FLUSH_REQUEST;
    request[1] = _id;
    return _fileService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "flush failed",
                                     path);
      }
      return this;
    });
  }

  external static _flush(int id);

  void flushSync() {
    _checkNotClosed();
    var result = _flush(_id);
    if (result is OSError) {
      throw new FileException("flush failed", path, result);
    }
  }

  void _ensureFileService() {
    if (_fileService == null) {
      _fileService = _FileUtils._newServicePort();
    }
  }

  bool get closed => _id == 0;

  void _checkNotClosed() {
    if (closed) {
      throw new FileException("File closed", path);
    }
  }

  Future _closedException() {
    return new Future.error(new FileException("File closed", path));
  }
}
