// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _FileInputStream extends _BaseDataInputStream implements InputStream {
  _FileInputStream(File file) {
    _file = file.openSync();
    _length = _file.lengthSync();
    _streamMarkedClosed = true;
    _checkScheduleCallbacks();
  }

  int available() {
    return _closed ? 0 : _length - _file.positionSync();
  }

  void pipe(OutputStream output, [bool close = true]) {
    _pipe(this, output, close: close);
  }

  List<int> _read(int bytesToRead) {
    List<int> result = new List<int>(bytesToRead);
    int bytesRead = _file.readListSync(result, 0, bytesToRead);
    if (bytesRead < bytesToRead) {
      List<int> buffer = new List<int>(bytesRead);
      buffer.copyFrom(result, 0, 0, bytesRead);
      result = buffer;
    }
    _checkScheduleCallbacks();
    return result;
  }

  int _readInto(List<int> buffer, int offset, int len) {
    int result = _file.readListSync(buffer, offset, len);
    _checkScheduleCallbacks();
    return result;
  }

  void _close() {
    if (_closed) return;
    _file.closeSync();
    _closed = true;
  }

  RandomAccessFile _file;
  int _length;
  bool _closed = false;
}


class _FileOutputStream implements OutputStream {
  _FileOutputStream(File file) {
    _file = file.openSync(FileMode.WRITE);
  }

  bool write(List<int> buffer, [bool copyBuffer = false]) {
    return _write(buffer, 0, buffer.length);
  }

  bool writeFrom(List<int> buffer, [int offset = 0, int len]) {
    return _write(
        buffer, offset, (len == null) ? buffer.length - offset : len);
  }

  void close() {
    _file.closeSync();
  }

  void set noPendingWriteHandler(void callback()) {
    // TODO(sgjesse): How to handle this?
  }

  void set closeHandler(void callback()) {
    // TODO(sgjesse): How to handle this?
  }

  void set errorHandler(void callback()) {
    // TODO(sgjesse): How to handle this?
  }

  bool _write(List<int> buffer, int offset, int len) {
    int bytesWritten = _file.writeListSync(buffer, offset, len);
    if (bytesWritten == len) {
      return true;
    } else {
      throw "FileOutputStream: write error";
    }
  }

  RandomAccessFile _file;
}


class _FileOperation {
  abstract void execute(ReceivePort port);

  SendPort set replyPort(SendPort port) {
    _replyPort = port;
  }

  bool isWrite() => false;

  SendPort _replyPort;
}


class _ExistsOperation extends _FileOperation {
  _ExistsOperation(String this._name);

  void execute(ReceivePort port) {
    _replyPort.send(_FileUtils.exists(_name), port.toSendPort());
  }

  String _name;
}


class _OpenOperation extends _FileOperation {
  _OpenOperation(String this._name, int this._mode);

  void execute(ReceivePort port) {
    _replyPort.send(_FileUtils.checkedOpen(_name, _mode),
                    port.toSendPort());
  }

  String _name;
  int _mode;
}


class _CloseOperation extends _FileOperation {
  _CloseOperation(int this._id);

  void execute(ReceivePort port) {
    _replyPort.send(_FileUtils.close(_id), port.toSendPort());
  }

  int _id;
}


class _ReadByteOperation extends _FileOperation {
  _ReadByteOperation(int this._id);

  void execute(ReceivePort port) {
    _replyPort.send(_FileUtils.readByte(_id), port.toSendPort());
  }

  int _id;
}


class _ReadListResult {
  _ReadListResult(this.read, this.buffer);
  int read;
  List buffer;
}


class _ReadListOperation extends _FileOperation {
  _ReadListOperation(int this._id,
                     int this._length,
                     int this._offset,
                     int this._bytes);

  void execute(ReceivePort port) {
    if (_bytes == 0) {
      _replyPort.send(0, port.toSendPort());
      return;
    }
    int index =
        _FileUtils.checkReadWriteListArguments(_length, _offset, _bytes);
    if (index != 0) {
      _replyPort.send("index out of range in readList: $index",
                      port.toSendPort());
      return;
    }
    var buffer = new List(_bytes);
    var result =
        new _ReadListResult(_FileUtils.readList(_id, buffer, 0, _bytes),
                            buffer);
    _replyPort.send(result, port.toSendPort());
  }

  int _id;
  int _length;
  int _offset;
  int _bytes;
}


class _WriteByteOperation extends _FileOperation {
  _WriteByteOperation(int this._id, int this._value);

  void execute(ReceivePort port) {
    _replyPort.send(_FileUtils.writeByte(_id, _value), port.toSendPort());
  }

  bool isWrite() => true;

  int _id;
  int _value;
}


class _WriteListOperation extends _FileOperation {
  _WriteListOperation(int this._id,
                      List this._buffer,
                      int this._offset,
                      int this._bytes);

  void execute(ReceivePort port) {
    if (_bytes == 0) {
      _replyPort.send(0, port.toSendPort());
      return;
    }
    int index =
        _FileUtils.checkReadWriteListArguments(_buffer.length, _offset, _bytes);
    if (index != 0) {
      _replyPort.send("index out of range in writeList: $index",
                      port.toSendPort());
      return;
    }
    var result = _FileUtils.writeList(_id, _buffer, _offset, _bytes);
    _replyPort.send(result, port.toSendPort());
  }

  bool isWrite() => true;

  int _id;
  List _buffer;
  int _offset;
  int _bytes;
}


class _WriteStringOperation extends _FileOperation {
  _WriteStringOperation(int this._id, String this._string);

  void execute(ReceivePort port) {
    _replyPort.send(_FileUtils.checkedWriteString(_id, _string),
                    port.toSendPort());
  }

  bool isWrite() => true;

  int _id;
  String _string;
}


class _PositionOperation extends _FileOperation {
  _PositionOperation(int this._id);

  void execute(ReceivePort port) {
    _replyPort.send(_FileUtils.position(_id), port.toSendPort());
  }

  int _id;
}


class _SetPositionOperation extends _FileOperation {
  _SetPositionOperation(int this._id, int this._position);

  void execute(ReceivePort port) {
    _replyPort.send(_FileUtils.setPosition(_id, _position), port.toSendPort());
  }

  int _id;
  int _position;
}


class _TruncateOperation extends _FileOperation {
  _TruncateOperation(int this._id, int this._length);

  void execute(ReceivePort port) {
    _replyPort.send(_FileUtils.truncate(_id, _length), port.toSendPort());
  }

  int _id;
  int _length;
}


class _LengthOperation extends _FileOperation {
  _LengthOperation(int this._id);

  void execute(ReceivePort port) {
    _replyPort.send(_FileUtils.length(_id), port.toSendPort());
  }

  int _id;
}


class _FlushOperation extends _FileOperation {
  _FlushOperation(int this._id);

  void execute(ReceivePort port) {
    _replyPort.send(_FileUtils.flush(_id), port.toSendPort());
  }

  int _id;
}


class _FullPathOperation extends _FileOperation {
  _FullPathOperation(String this._name);

  void execute(ReceivePort port) {
    _replyPort.send(_FileUtils.checkedFullPath(_name), port.toSendPort());
  }

  String _name;
}


class _CreateOperation extends _FileOperation {
  _CreateOperation(String this._name);

  void execute(ReceivePort port) {
    _replyPort.send(_FileUtils.checkedCreate(_name), port.toSendPort());
  }

  String _name;
}


class _DeleteOperation extends _FileOperation {
  _DeleteOperation(String this._name);

  void execute(ReceivePort port) {
    _replyPort.send(_FileUtils.checkedDelete(_name), port.toSendPort());
  }

  String _name;
}


class _ExitOperation extends _FileOperation {
  void execute(ReceivePort port) {
    port.close();
  }
}


class _FileOperationIsolate extends Isolate {
  _FileOperationIsolate() : super.heavy();

  void handleOperation(_FileOperation message, SendPort ignored) {
    message.execute(port);
    port.receive(handleOperation);
  }

  void main() {
    port.receive(handleOperation);
  }
}


class _FileOperationScheduler {
  _FileOperationScheduler() : _queue = new Queue();

  void schedule(SendPort port) {
    assert(_isolate != null);
    if (_queue.isEmpty()) {
      port.send(new _ExitOperation());
      _isolate = null;
    } else {
      port.send(_queue.removeFirst());
    }
  }

  void scheduleWrap(void callback(result, ignored)) {
    return (result, replyTo) {
      callback(result, replyTo);
      schedule(replyTo);
    };
  }

  void enqueue(_FileOperation operation, void callback(result, ignored)) {
    ReceivePort replyPort = new ReceivePort.singleShot();
    replyPort.receive(scheduleWrap(callback));
    operation.replyPort = replyPort.toSendPort();
    _queue.addLast(operation);
    if (_isolate == null) {
      _isolate = new _FileOperationIsolate();
      _isolate.spawn().then((port) {
        schedule(port);
      });
    }
  }

  bool noPendingWrite() {
    int queuedWrites = 0;
    _queue.forEach((operation) {
      if (operation.isWrite()) {
        queuedWrites++;
      }
    });
    return queuedWrites == 0;
  }

  Queue<_FileOperation> _queue;
  _FileOperationIsolate _isolate;
}


// Helper class containing static file helper methods.
class _FileUtils {
  static bool exists(String name) native "File_Exists";
  static int open(String name, int mode) native "File_Open";
  static bool create(String name) native "File_Create";
  static bool delete(String name) native "File_Delete";
  static String fullPath(String name) native "File_FullPath";
  static int close(int id) native "File_Close";
  static int readByte(int id) native "File_ReadByte";
  static int readList(int id, List<int> buffer, int offset, int bytes)
      native "File_ReadList";
  static int writeByte(int id, int value) native "File_WriteByte";
  static int writeList(int id, List<int> buffer, int offset, int bytes)
      native "File_WriteList";
  static int writeString(int id, String string) native "File_WriteString";
  static int position(int id) native "File_Position";
  static bool setPosition(int id, int position) native "File_SetPosition";
  static bool truncate(int id, int length) native "File_Truncate";
  static int length(int id) native "File_Length";
  static int flush(int id) native "File_Flush";

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
  _File(String this._name)
    : _scheduler = new _FileOperationScheduler(),
      _asyncUsed = false;

  void exists() {
    _asyncUsed = true;
    if (_name is !String) {
      if (_errorHandler != null) {
        _errorHandler('File name is not a string: $_name');
      }
      return;
    }
    var handler =
        (_existsHandler != null) ? _existsHandler : (result) => null;
    var operation = new _ExistsOperation(_name);
    _scheduler.enqueue(operation, (result, ignored) { _existsHandler(result); });
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

  void create() {
    _asyncUsed = true;
    var handler = (_createHandler != null) ? _createHandler : () => null;
    var handleCreateResult = (created, ignored) {
      if (created) {
        handler();
      } else if (_errorHandler != null) {
        _errorHandler("Cannot create file: $_name");
      }
    };
    var operation = new _CreateOperation(_name);
    _scheduler.enqueue(operation, handleCreateResult);
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

  void delete() {
    _asyncUsed = true;
    var handler = (_deleteHandler != null) ? _deleteHandler : () => null;
    var handleDeleteResult = (created, ignored) {
      if (created) {
        handler();
      } else if (_errorHandler != null) {
        _errorHandler("Cannot delete file: $_name");
      }
    };
    var operation = new _DeleteOperation(_name);
    _scheduler.enqueue(operation, handleDeleteResult);
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

  void open([FileMode mode = FileMode.READ]) {
    _asyncUsed = true;
    if (mode != FileMode.READ &&
        mode != FileMode.WRITE &&
        mode != FileMode.APPEND) {
      if (_errorHandler != null) {
        _errorHandler("Unknown file mode. Use FileMode.READ, FileMode.WRITE " +
                      "or FileMode.APPEND.");
        return;
      }
    }
    // If no open handler is present, close the file immediately to
    // avoid leaking an open file descriptor.
    var handler = _openHandler;
    if (handler === null) {
      handler = (file) => file.close();
    }
    var handleOpenResult = (id, ignored) {
      if (id != 0) {
        var randomAccessFile = new _RandomAccessFile(id, _name);
        handler(randomAccessFile);
      } else if (_errorHandler != null) {
        _errorHandler("Cannot open file: $_name");
      }
    };
    var operation = new _OpenOperation(_name, mode.mode);
    _scheduler.enqueue(operation, handleOpenResult);
  }

  void openSync([FileMode mode = FileMode.READ]) {
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
    var id = _FileUtils.checkedOpen(_name, mode.mode);
    if (id == 0) {
      throw new FileIOException("Cannot open file: $_name");
    }
    return new _RandomAccessFile(id, _name);
  }

  void fullPath() {
    _asyncUsed = true;
    var handler = _fullPathHandler;
    if (handler == null) handler = (path) => null;
    var handleFullPathResult = (result, ignored) {
      if (result != null) {
        handler(result);
      } else if (_errorHandler != null) {
        _errorHandler("fullPath failed");
      }
    };
    var operation = new _FullPathOperation(_name);
    _scheduler.enqueue(operation, handleFullPathResult);
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

  InputStream openInputStream() => new _FileInputStream(this);

  OutputStream openOutputStream() => new _FileOutputStream(this);

  String get name() => _name;

  void set existsHandler(void handler(bool exists)) {
    _existsHandler = handler;
  }

  void set createHandler(void handler()) {
    _createHandler = handler;
  }

  void set deleteHandler(void handler()) {
    _deleteHandler = handler;
  }

  void set openHandler(void handler(RandomAccessFile file)) {
    _openHandler = handler;
  }

  void set fullPathHandler(void handler(String)) {
    _fullPathHandler = handler;
  }

  void set errorHandler(void handler(String error)) {
    _errorHandler = handler;
  }

  String _name;
  bool _asyncUsed;

  _FileOperationScheduler _scheduler;

  var _existsHandler;
  var _createHandler;
  var _deleteHandler;
  var _openHandler;
  var _fullPathHandler;
  var _errorHandler;
}


class _RandomAccessFile implements RandomAccessFile {
  _RandomAccessFile(int this._id, String this._name)
    : _scheduler = new _FileOperationScheduler(),
      _asyncUsed = false;

  void close() {
    _asyncUsed = true;
    var handler = (_closeHandler != null) ? _closeHandler : () => null;
    var handleOpenResult = (result, ignored) {
      if (result != -1) {
        _id = result;
        handler();
      } else if (_errorHandler != null) {
        _errorHandler("Cannot close file: $_name");
      }
    };
    var operation = new _CloseOperation(_id);
    _scheduler.enqueue(operation, handleOpenResult);
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

  void readByte() {
    _asyncUsed = true;
    var handler =
        (_readByteHandler != null) ? _readByteHandler : (byte) => null;
    var handleReadByteResult = (result, ignored) {
      if (result != -1) {
        handler(result);
      } else if (_errorHandler != null) {
        _errorHandler("readByte failed");
      }
    };
    var operation = new _ReadByteOperation(_id);
    _scheduler.enqueue(operation, handleReadByteResult);
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

  void readList(List<int> buffer, int offset, int bytes) {
    _asyncUsed = true;
    if (buffer is !List || offset is !int || bytes is !int) {
      if (_errorHandler != null) {
        _errorHandler("Invalid arguments to readList");
      }
      return;
    };
    var handler =
        (_readListHandler != null) ? _readListHandler : (result) => null;
    var handleReadListResult = (result, ignored) {
      if (result is _ReadListResult && result.read != -1) {
        var read = result.read;
        buffer.setRange(offset, read, result.buffer);
        handler(read);
        return;
      }
      if (_errorHandler != null) {
        _errorHandler(result is String ? result : "readList failed");
      }
    };
    var operation = new _ReadListOperation(_id, buffer.length, offset, bytes);
    _scheduler.enqueue(operation, handleReadListResult);
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

  void _checkPendingWrites() {
    if (_scheduler.noPendingWrite() && _noPendingWriteHandler != null) {
      _noPendingWriteHandler();
    }
  }

  void writeByte(int value) {
    _asyncUsed = true;
    if (value is !int) {
      if (_errorHandler != null) {
        _errorHandler("Invalid argument to writeByte");
      }
      return;
    }
    var handleReadByteResult = (result, ignored) {
      if (result == -1 &&_errorHandler != null) {
        _errorHandler("writeByte failed");
        return;
      }
      _checkPendingWrites();
    };
    var operation = new _WriteByteOperation(_id, value);
    _scheduler.enqueue(operation, handleReadByteResult);
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
    _asyncUsed = true;
    if (buffer is !List || offset is !int || bytes is !int) {
      if (_errorHandler != null) {
        _errorHandler("Invalid arguments to writeList");
      }
      return;
    }
    var handleWriteListResult = (result, ignored) {
      if (result is !String && result != -1) {
        if (result < bytes) {
          writeList(buffer, offset + result, bytes - result);
        } else {
          _checkPendingWrites();
        }
        return;
      }
      if (_errorHandler != null) {
        _errorHandler(result is String ? result : "writeList failed");
      }
    };
    var operation = new _WriteListOperation(_id, buffer, offset, bytes);
    _scheduler.enqueue(operation, handleWriteListResult);
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

  void writeString(String string) {
    _asyncUsed = true;
    var handleWriteStringResult = (result, ignored) {
      if (result == -1 &&_errorHandler != null) {
        _errorHandler("writeString failed");
        return;
      }
      if (result < string.length) {
        writeString(string.substring(result));
      } else {
        _checkPendingWrites();
      }
    };
    var operation = new _WriteStringOperation(_id, string);
    _scheduler.enqueue(operation, handleWriteStringResult);
  }

  int writeStringSync(String string) {
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

  void position() {
    _asyncUsed = true;
    var handler = (_positionHandler != null) ? _positionHandler : (pos) => null;
    var handlePositionResult = (result, ignored) {
      if (result == -1 && _errorHandler != null) {
        _errorHandler("position failed");
        return;
      }
      handler(result);
    };
    var operation = new _PositionOperation(_id);
    _scheduler.enqueue(operation, handlePositionResult);
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

  void setPosition(int position) {
    _asyncUsed = true;
    var handler =
        (_setPositionHandler != null) ? _setPositionHandler : () => null;
    var handleSetPositionResult = (result, ignored) {
      if (result == false && _errorHandler != null) {
        _errorHandler("setPosition failed");
        return;
      }
      handler();
    };
    var operation = new _SetPositionOperation(_id, position);
    _scheduler.enqueue(operation, handleSetPositionResult);
  }

  void setPositionSync(int position) {
    if (_asyncUsed) {
      throw new FileIOException(
          "Mixed use of synchronous and asynchronous API");
    }
    bool result = _FileUtils.setPosition(_id, position);
    if (result == false) {
      throw new FileIOException("setPosition failed");
    }
  }
  
  void truncate(int length) {
    _asyncUsed = true;
    var handler = (_truncateHandler != null) ? _truncateHandler : () => null;
    var handleTruncateResult = (result, ignored) {
      if (result == false && _errorHandler != null) {
        _errorHandler("truncate failed");
        return;
      }
      handler();
    };
    var operation = new _TruncateOperation(_id, length);
    _scheduler.enqueue(operation, handleTruncateResult);
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

  void length() {
    _asyncUsed = true;
    var handler = (_lengthHandler != null) ? _lengthHandler : (pos) => null;
    var handleLengthResult = (result, ignored) {
      if (result == -1 && _errorHandler != null) {
        _errorHandler("length failed");
        return;
      }
      handler(result);
    };
    var operation = new _LengthOperation(_id);
    _scheduler.enqueue(operation, handleLengthResult);
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

  void flush() {
    _asyncUsed = true;
    var handler = (_flushHandler != null) ? _flushHandler : (pos) => null;
    var handleFlushResult = (result, ignored) {
      if (result == -1 && _errorHandler != null) {
        _errorHandler("flush failed");
        return;
      }
      handler();
    };
    var operation = new _FlushOperation(_id);
    _scheduler.enqueue(operation, handleFlushResult);
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

  void set errorHandler(void handler(String error)) {
    _errorHandler = handler;
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

  void set positionHandler(void handler(int pos)) {
    _positionHandler = handler;
  }

  void set setPositionHandler(void handler()) {
    _setPositionHandler = handler;
  }

  void set truncateHandler(void handler()) {
    _truncateHandler = handler;
  }

  void set lengthHandler(void handler(int length)) {
    _lengthHandler = handler;
  }

  void set flushHandler(void handler()) {
    _flushHandler = handler;
  }

  String _name;
  int _id;
  bool _asyncUsed;

  _FileOperationScheduler _scheduler;

  var _closeHandler;
  var _readByteHandler;
  var _readListHandler;
  var _noPendingWriteHandler;
  var _positionHandler;
  var _setPositionHandler;
  var _truncateHandler;
  var _lengthHandler;
  var _flushHandler;
  var _errorHandler;
}
