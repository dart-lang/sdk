// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Used for holding error code and error message for failed OS system calls.
class _OSStatus {
  int _errorCode;
  String _errorMessage;
}


class _DirectoryListingIsolate extends Isolate {

  _DirectoryListingIsolate() : super.heavy();

  void main() {
    port.receive((message, replyTo) {
      bool started = _list(message['dir'],
                           message['recursive'],
                           message['dirPort'],
                           message['filePort'],
                           message['donePort'],
                           message['errorPort']);
      replyTo.send(started);
      port.close();
    });
  }

  bool _list(String dir,
             bool recursive,
             SendPort dirPort,
             SendPort filePort,
             SendPort donePort,
             SendPort errorPort) native "Directory_List";
}


class _DirectoryOperation {
  abstract void execute(ReceivePort port);

  SendPort set replyPort(SendPort port) {
    _replyPort = port;
  }

  SendPort _replyPort;
}


class _DirExitOperation extends _DirectoryOperation {
  void execute(ReceivePort port) {
    port.close();
  }
}


class _DirExistsOperation extends _DirectoryOperation {
  _DirExistsOperation(String this._path);

  void execute(ReceivePort port) {
    _replyPort.send(_Directory._exists(_path), port.toSendPort());
  }

  String _path;
}


class _DirCreateOperation extends _DirectoryOperation {
  _DirCreateOperation(String this._path);

  void execute(ReceivePort port) {
    _replyPort.send(_Directory._create(_path), port.toSendPort());
  }

  String _path;
}


class _DirCreateTempOperation extends _DirectoryOperation {
  _DirCreateTempOperation(String this._path);

  void execute(ReceivePort port) {
    var status = new _OSStatus();
    var result = _Directory._createTemp(_path, status);
    if (result == null) {
      _replyPort.send(status, port.toSendPort());
    } else {
      _replyPort.send(result, port.toSendPort());
    }
  }

  String _path;
}


class _DirDeleteOperation extends _DirectoryOperation {
  _DirDeleteOperation(String this._path);

  void execute(ReceivePort port) {
    _replyPort.send(_Directory._delete(_path), port.toSendPort());
  }

  String _path;
}


class _DirectoryOperationIsolate extends Isolate {
  _DirectoryOperationIsolate() : super.heavy();

  void handleOperation(_DirectoryOperation message, SendPort ignored) {
    message.execute(port);
    port.receive(handleOperation);
  }

  void main() {
    port.receive(handleOperation);
  }
}


class _DirectoryOperationScheduler {
  _DirectoryOperationScheduler() : _queue = new Queue();

  void schedule(SendPort port) {
    assert(_isolate != null);
    if (_queue.isEmpty()) {
      port.send(new _DirExitOperation());
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

  void enqueue(_DirectoryOperation operation, void callback(result, ignored)) {
    ReceivePort replyPort = new ReceivePort.singleShot();
    replyPort.receive(scheduleWrap(callback));
    operation.replyPort = replyPort.toSendPort();
    _queue.addLast(operation);
    if (_isolate == null) {
      _isolate = new _DirectoryOperationIsolate();
      _isolate.spawn().then((port) {
        schedule(port);
      });
    }
  }

  Queue<_DirectoryOperation> _queue;
  _DirectoryOperationIsolate _isolate;
}


class _Directory implements Directory {

  _Directory(String this._path)
      : _scheduler = new _DirectoryOperationScheduler();

  static String _createTemp(String template,
                            _OSStatus status) native "Directory_CreateTemp";
  static int _exists(String path) native "Directory_Exists";
  static bool _create(String path) native "Directory_Create";
  static bool _delete(String path) native "Directory_Delete";

  void exists() {
    var handler = (_existsHandler != null) ? _existsHandler : (result) => null;
    var operation = new _DirExistsOperation(_path);
    _scheduler.enqueue(operation, (result, ignored) {
      if (result < 0) {
        if (_errorHandler != null) {
          _errorHandler("Diretory exists test failed: $_path");
        }
      } else {
        handler(result == 1);
      }
    });
  }

  bool existsSync() {
    int exists = _exists(_path);
    if (exists < 0) {
      throw new DirectoryException("Diretory exists test failed: $_path");
    }
    return (exists == 1);
  }

  void create() {
    var handler = (_createHandler != null) ? _createHandler : () => null;
    var operation = new _DirCreateOperation(_path);
    _scheduler.enqueue(operation, (result, ignored) {
      if (result) {
        handler();
      } else if (_errorHandler != null) {
        _errorHandler("Directory creation failed: $_path");
      }
    });
  }

  void createSync() {
    if (!_create(_path)) {
      throw new DirectoryException("Directory creation failed: $_path");
    }
  }

  void createTemp() {
    var handler =
        (_createTempHandler != null) ? _createTempHandler : () => null;
    var operation = new _DirCreateTempOperation(_path);
    _scheduler.enqueue(operation, (result, ignored) {
      if (result is !_OSStatus) {
        _path = result;
        handler();
      } else if (_errorHandler !== null) {
        _errorHandler("Could not create temporary directory [$_path]: " +
                      "${result._errorMessage}");
      }
    });
  }

  void createTempSync() {
    var status = new _OSStatus();
    var result = _createTemp(path, status);
    if (result != null) {
      _path = result;
    } else {
      throw new DirectoryException(
          "Could not create temporary directory [$_path]: " +
          "${status._errorMessage}",
          status._errorCode);
    }
  }

  void delete() {
    var handler = (_deleteHandler != null) ? _deleteHandler : () => null;
    var operation = new _DirDeleteOperation(_path);
    _scheduler.enqueue(operation, (result, ignored) {
      if (result) {
        handler();
      } else if (_errorHandler != null) {
        _errorHandler("Directory deletion failed: $_path");
      }
    });
  }

  void deleteSync() {
    if (!_delete(_path)) {
      throw new DirectoryException("Directory deletion failed: $_path");
    }
  }

  void list([bool recursive = false]) {
    new _DirectoryListingIsolate().spawn().then((port) {
      // Build a map of parameters to the directory listing isolate.
      Map listingParameters = new Map();
      listingParameters['dir'] = _path;
      listingParameters['recursive'] = recursive;

      // Setup ports to receive messages from listing.
      // TODO(ager): Do not explicitly transform to send ports when
      // implicit conversions are implemented.
      ReceivePort dirPort;
      ReceivePort filePort;
      ReceivePort donePort;
      ReceivePort errorPort;
      if (_dirHandler !== null) {
        dirPort = new ReceivePort();
        dirPort.receive((String dir, ignored) {
          _dirHandler(dir);
        });
        listingParameters['dirPort'] = dirPort.toSendPort();
      }
      if (_fileHandler !== null) {
        filePort = new ReceivePort();
        filePort.receive((String file, ignored) {
          _fileHandler(file);
        });
        listingParameters['filePort'] = filePort.toSendPort();
      }
      if (_doneHandler !== null) {
        donePort = new ReceivePort.singleShot();
        donePort.receive((bool completed, ignored) {
          _doneHandler(completed);
        });
        listingParameters['donePort'] = donePort.toSendPort();
      }
      if (_errorHandler !== null) {
        errorPort = new ReceivePort.singleShot();
        errorPort.receive((String error, ignored) {
          _errorHandler(error);
        });
        listingParameters['errorPort'] = errorPort.toSendPort();
      }

      // Close ports when listing is done.
      ReceivePort closePortsPort = new ReceivePort();
      closePortsPort.receive((message, replyTo) {
        if (!message) {
          errorPort.toSendPort().send(
              "Failed to list directory: $_path recursive: $recursive");
          donePort.toSendPort().send(false);
        } else {
          _closePort(errorPort);
          _closePort(donePort);
        }
        _closePort(dirPort);
        _closePort(filePort);
        _closePort(closePortsPort);
      });

      // Send the listing parameters to the isolate.
      port.send(listingParameters, closePortsPort.toSendPort());
    });
  }

  void set dirHandler(void dirHandler(String dir)) {
    _dirHandler = dirHandler;
  }

  void set fileHandler(void fileHandler(String file)) {
    _fileHandler = fileHandler;
  }

  void set doneHandler(void doneHandler(bool completed)) {
    _doneHandler = doneHandler;
  }

  void set existsHandler(void existsHandler(bool exists)) {
    _existsHandler = existsHandler;
  }

  void set createHandler(void createHandler()) {
    _createHandler = createHandler;
  }

  void set createTempHandler(void createTempHandler()) {
    _createTempHandler = createTempHandler;
  }

  void set deleteHandler(void deleteHandler()) {
    _deleteHandler = deleteHandler;
  }

  void set errorHandler(void errorHandler(String error)) {
    _errorHandler = errorHandler;
  }

  void _closePort(ReceivePort port) {
    if (port !== null) {
      port.close();
    }
  }

  String get path() { return _path; }

  var _dirHandler;
  var _fileHandler;
  var _doneHandler;
  var _existsHandler;
  var _createHandler;
  var _createTempHandler;
  var _deleteHandler;
  var _errorHandler;

  String _path;
  _DirectoryOperationScheduler _scheduler;
}
