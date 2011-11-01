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


class _FileOperationIsolate extends Isolate {
  static int EXISTS = 0;
  static int OPEN = 1;
  static int CLOSE = 2;
  static int READ_BYTE = 3;
  static int READ_LIST = 4;
  static int WRITE_BYTE = 5;
  static int WRITE_LIST = 6;
  static int WRITE_STRING = 7;
  static int POSITION = 8;
  static int LENGTH = 9;
  static int FLUSH = 10;
  static int EXIT = 11;

  _FileOperationIsolate() : super.heavy();

  void handleOperation(Map message, SendPort ignored) {
    switch (message["type"]) {
      case EXISTS:
        message["reply"].send(_File._exists(message["name"]),
                              port.toSendPort());
        break;
      case OPEN:
        var name = message["name"];
        var writable = message["writable"];
        message["reply"].send(_File._open(name, writable),
                              port.toSendPort());
        break;
      case CLOSE:
        message["reply"].send(_File._close(message["id"]),
                              port.toSendPort());
        break;
      case READ_BYTE:
        message["reply"].send(_File._readByte(message["id"]),
                              port.toSendPort());
        break;
      case READ_LIST:
        var replyPort = message["reply"];
        var bytes = message["bytes"];
        var offset = message["offset"];
        var length = message["length"];
        var id = message["id"];
        if (bytes == 0) {
          replyPort.send(0, port.toSendPort());
          return;
        }
        int index = _File._checkReadWriteListArguments(length, offset, bytes);
        if (index != 0) {
          replyPort.send("index out of range in readList: $index",
                         port.toSendPort());
          return;
        }
        var buffer = new List(bytes);
        var result = { "read": _File._readList(id, buffer, 0, bytes),
                       "buffer": buffer };
        replyPort.send(result, port.toSendPort());
        break;
      case WRITE_BYTE:
        message["reply"].send(_File._writeByte(message["id"], message["value"]),
                              port.toSendPort());
        break;
      case WRITE_LIST:
        var replyPort = message["reply"];
        var buffer = message["buffer"];
        var bytes = message["bytes"];
        var offset = message["offset"];
        var id = message["id"];
        if (bytes == 0) {
          replyPort.send(0, port.toSendPort());
          return;
        }
        int index =
            _File._checkReadWriteListArguments(buffer.length, offset, bytes);
        if (index != 0) {
          replyPort.send("index out of range in writeList: $index",
                         port.toSendPort());
          return;
        }
        var result = _File._writeList(id, buffer, offset, bytes);
        replyPort.send(result, port.toSendPort());
        break;
      case WRITE_STRING:
        var id = message["id"];
        var string = message["string"];
        message["reply"].send(_File._writeString(id, string),
                              port.toSendPort());
        break;
      case POSITION:
        message["reply"].send(_File._position(message["id"]),
                              port.toSendPort());
        break;
      case LENGTH:
        message["reply"].send(_File._length(message["id"]),
                              port.toSendPort());
        break;
      case FLUSH:
        message["reply"].send(_File._flush(message["id"]),
                              port.toSendPort());
        break;
      case EXIT:
        port.close();
        return;
    }
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
      port.send({ "type": _FileOperationIsolate.EXIT });
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

  void enqueue(Map params, void callback(result, ignored)) {
    ReceivePort replyPort = new ReceivePort.singleShot();
    replyPort.receive(scheduleWrap(callback));
    params["reply"] = replyPort.toSendPort();
    _queue.addLast(params);
    if (_isolate == null) {
      _isolate = new _FileOperationIsolate();
      _isolate.spawn().then((port) {
        schedule(port);
      });
    }
  }

  bool noPendingWrite() {
    int queuedWrites = 0;
    _queue.forEach((map) {
      if (_isWriteOperation(map["type"])) {
        queuedWrites++;
      }
    });
    return queuedWrites == 0;
  }

  bool _isWriteOperation(int type) {
    return (type == _FileOperationIsolate.WRITE_BYTE) ||
        (type == _FileOperationIsolate.WRITE_LIST) ||
        (type == _FileOperationIsolate.WRITE_STRING);
  }

  Queue<Map> _queue;
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
    Map params = {
      "type": _FileOperationIsolate.EXISTS,
      "name": _name
    };
    _scheduler.enqueue(params, (result, ignored) { _existsHandler(result); });
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
    Map params = {
      "type": _FileOperationIsolate.OPEN,
      "name": _name,
      "writable": writable
    };
    _scheduler.enqueue(params, handleOpenResult);
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
    Map params = {
      "type": _FileOperationIsolate.CLOSE,
      "id": _id
    };
    _scheduler.enqueue(params, handleOpenResult);
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
    Map params = {
      "type": _FileOperationIsolate.READ_BYTE,
      "id": _id
    };
    _scheduler.enqueue(params, handleReadByteResult);
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
      if (result is Map && result["read"] != -1) {
        var read = result["read"];
        buffer.setRange(offset, read, result["buffer"]);
        handler(read);
        return;
      }
      if (_errorHandler != null) {
        _errorHandler(result is String ? result : "readList failed");
      }
    };
    Map params = {
      "type": _FileOperationIsolate.READ_LIST,
      "length": buffer.length,
      "offset": offset,
      "bytes": bytes,
      "id": _id
    };
    _scheduler.enqueue(params, handleReadListResult);
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
    Map params = {
      "type": _FileOperationIsolate.WRITE_BYTE,
      "value": value,
      "id": _id
    };
    _scheduler.enqueue(params, handleReadByteResult);
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
    Map params = {
      "type": _FileOperationIsolate.WRITE_LIST,
      "buffer": buffer,
      "offset": offset,
      "bytes": bytes,
      "id": _id
    };
    _scheduler.enqueue(params, handleWriteListResult);
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
    Map params = {
      "type": _FileOperationIsolate.WRITE_STRING,
      "string": string,
      "id": _id
    };
    _scheduler.enqueue(params, handleWriteStringResult);
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
    Map params = {
      "type": _FileOperationIsolate.POSITION,
      "id": _id
    };
    _scheduler.enqueue(params, handlePositionResult);
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
    Map params = {
      "type": _FileOperationIsolate.LENGTH,
      "id": _id
    };
    _scheduler.enqueue(params, handleLengthResult);
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
    Map params = {
      "type": _FileOperationIsolate.FLUSH,
      "id": _id
    };
    _scheduler.enqueue(params, handleFlushResult);
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
