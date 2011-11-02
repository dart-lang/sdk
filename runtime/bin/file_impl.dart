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
    if (len !== null) {
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

  bool write(List<int> buffer) {
    return _write(buffer, 0, buffer.length);
  }

  bool writeFrom(List<int> buffer, [int offset, int len]) {
    return _write(buffer, offset, (len == null) ? buffer.length : len);
  }

  void end() {
    _file.closeSync();
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

  File _file;
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
    _replyPort.send(_File._exists(_name), port.toSendPort());
  }

  String _name;
}


class _OpenOperation extends _FileOperation {
  _OpenOperation(String this._name, bool this._writable);

  void execute(ReceivePort port) {
    _replyPort.send(_File._open(_name, _writable), port.toSendPort());
  }

  String _name;
  bool _writable;
}


class _CloseOperation extends _FileOperation {
  _CloseOperation(int this._id);

  void execute(ReceivePort port) {
    _replyPort.send(_File._close(_id), port.toSendPort());
  }

  int _id;
}


class _ReadByteOperation extends _FileOperation {
  _ReadByteOperation(int this._id);

  void execute(ReceivePort port) {
    _replyPort.send(_File._readByte(_id), port.toSendPort());
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
    int index = _File._checkReadWriteListArguments(_length, _offset, _bytes);
    if (index != 0) {
      _replyPort.send("index out of range in readList: $index",
                      port.toSendPort());
      return;
    }
    var buffer = new List(_bytes);
    var result =
        new _ReadListResult(_File._readList(_id, buffer, 0, _bytes), buffer);
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
    _replyPort.send(_File._writeByte(_id, _value), port.toSendPort());
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
        _File._checkReadWriteListArguments(_buffer.length, _offset, _bytes);
    if (index != 0) {
      _replyPort.send("index out of range in writeList: $index",
                      port.toSendPort());
      return;
    }
    var result = _File._writeList(_id, _buffer, _offset, _bytes);
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
    _replyPort.send(_File._writeString(_id, _string), port.toSendPort());
  }

  bool isWrite() => true;

  int _id;
  String _string;
}


class _PositionOperation extends _FileOperation {
  _PositionOperation(int this._id);

  void execute(ReceivePort port) {
    _replyPort.send(_File._position(_id), port.toSendPort());
  }

  int _id;
}


class _LengthOperation extends _FileOperation {
  _LengthOperation(int this._id);

  void execute(ReceivePort port) {
    _replyPort.send(_File._length(_id), port.toSendPort());
  }

  int _id;
}


class _FlushOperation extends _FileOperation {
  _FlushOperation(int this._id);

  void execute(ReceivePort port) {
    _replyPort.send(_File._flush(_id), port.toSendPort());
  }

  int _id;
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


// Class for encapsulating the native implementation of files.
class _File implements File {
  // Constructor for file.
  _File(String this._name)
    : _scheduler = new _FileOperationScheduler(),
      _asyncUsed = false;

  static bool _exists(String name) native "File_Exists";
  static int _open(String name, bool writable) native "File_Open";
  static int _close(int id) native "File_Close";
  static int _readByte(int id) native "File_ReadByte";
  static int _readList(int id, List<int> buffer, int offset, int bytes)
      native "File_ReadList";
  static int _writeByte(int id, int value) native "File_WriteByte";
  static int _writeList(int id, List<int> buffer, int offset, int bytes)
      native "File_WriteList";
  static int _writeString(int id, String string) native "File_WriteString";
  static int _position(int id) native "File_Position";
  static int _length(int id) native "File_Length";
  static int _flush(int id) native "File_Flush";

  static int _checkReadWriteListArguments(int length, int offset, int bytes) {
    if (offset < 0) return offset;
    if (bytes < 0) return bytes;
    if ((offset + bytes) > length) return offset + bytes;
    return 0;
  }

  void exists() {
    _asyncUsed = true;
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
    return _exists(_name);
  }

  void create() {
    _asyncUsed = true;
    throw "Unimplemented";
  }

  void createSync() {
    if (_asyncUsed) {
      throw new FileIOException(
          "Mixed use of synchronous and asynchronous API");
    }
    throw "Unimplemented";
  }

  void open([bool writable = false]) {
    _asyncUsed = true;
    var handler = (_openHandler != null) ? _openHandler : () => null;
    var handleOpenResult = (result, ignored) {
      if (result != 0) {
        _id = result;
        handler();
      } else if (_errorHandler != null) {
        _errorHandler("Cannot open file: $_name");
      }
    };
    var operation = new _OpenOperation(_name, writable);
    _scheduler.enqueue(operation, handleOpenResult);
  }

  void openSync([bool writable = false]) {
    if (_asyncUsed) {
      throw new FileIOException(
          "Mixed use of synchronous and asynchronous API");
    }
    _id = _open(_name, writable);
    if (_id == 0) {
      throw new FileIOException("Cannot open file: $_name");
    }
  }

  void close() {
    _asyncUsed = true;
    var handler = (_closeHandler != null) ? _closeHandler : () => null;
    var handleOpenResult = (result, ignored) {
      if (result != -1) {
        _id = result;
        handler();
      } else if (_errorHandler != null) {
        _errorHandler("Cannot open file: $_name");
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
    _id = _close(_id);
    if (_id == -1) {
      throw new FileIOException("Cannot close file: $_name");
    }
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
    int result = _readByte(_id);
    if (result == -1) {
      throw new FileIOException("readByte failed");
    }
    return result;
  }

  void readList(List<int> buffer, int offset, int bytes) {
    _asyncUsed = true;
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
    if (bytes == 0) return 0;
    int index = _checkReadWriteListArguments(buffer.length, offset, bytes);
    if (index != 0) {
      throw new IndexOutOfRangeException(index);
    }
    int result = _readList(_id, buffer, offset, bytes);
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
    int result = _writeByte(_id, value);
    if (result == -1) {
      throw new FileIOException("writeByte failed");
    }
    return result;
  }

  void writeList(List<int> buffer, int offset, int bytes) {
    _asyncUsed = true;
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
    if (bytes == 0) return 0;
    int index = _checkReadWriteListArguments(buffer.length, offset, bytes);
    if (index != 0) {
      throw new IndexOutOfRangeException(index);
    }
    int result = _writeList(_id, buffer, offset, bytes);
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
    int result = _writeString(_id, string);
    if (result == -1) {
      throw new FileIOException("Error: writeString failed");
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
    int result = _position(_id);
    if (result == -1) {
      throw new FileIOException("position failed");
    }
    return result;
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
    int result = _length(_id);
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
    int result = _flush(_id);
    if (result == -1) {
      throw new FileIOException("flush failed");
    }
  }

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

  void set positionHandler(void handler(int pos)) {
    _positionHandler = handler;
  }

  void set lengthHandler(void handler(int length)) {
    _lengthHandler = handler;
  }

  void set flushHandler(void handler()) {
    _flushHandler = handler;
  }

  void set errorHandler(void handler(String error)) {
    _errorHandler = handler;
  }

  String _name;
  int _id;
  bool _asyncUsed;

  _FileOperationScheduler _scheduler;

  var _existsHandler;
  var _createHandler;
  var _openHandler;
  var _closeHandler;
  var _readByteHandler;
  var _readListHandler;
  var _noPendingWriteHandler;
  var _positionHandler;
  var _lengthHandler;
  var _flushHandler;
  var _errorHandler;
}
