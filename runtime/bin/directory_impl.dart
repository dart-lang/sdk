// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Used for holding error code and error message for failed OS system calls.
class _OSStatus {
  int _errorCode;
  String _errorMessage;
}


class _Directory implements Directory {
  static final kCreateRequest = 0;
  static final kDeleteRequest = 1;
  static final kExistsRequest = 2;
  static final kCreateTempRequest = 3;
  static final kListRequest = 4;

  _Directory(String this._path);

  static String _createTemp(String template,
                            _OSStatus status) native "Directory_CreateTemp";
  static int _exists(String path) native "Directory_Exists";
  static bool _create(String path) native "Directory_Create";
  static bool _delete(String path, bool recursive) native "Directory_Delete";
  static SendPort _newServicePort() native "Directory_NewServicePort";

  void exists() {
    if (_directoryService == null) {
      _directoryService = _newServicePort();
    }
    List request = new List(2);
    request[0] = kExistsRequest;
    request[1] = _path;
    _directoryService.call(request).receive((result, replyTo) {
      var handler =
          (_existsHandler != null) ? _existsHandler : (result) => null;
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
    if (_directoryService == null) {
      _directoryService = _newServicePort();
    }
    List request = new List(2);
    request[0] = kCreateRequest;
    request[1] = _path;
    _directoryService.call(request).receive((result, replyTo) {
      if (result) {
        if (_createHandler != null) _createHandler();
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
    if (_directoryService == null) {
      _directoryService = _newServicePort();
    }
    List request = new List(2);
    request[0] = kCreateTempRequest;
    request[1] = _path;
    _directoryService.call(request).receive((result, replyTo) {
      if (result is !List) {
        _path = result;
        if (_createTempHandler != null) _createTempHandler();
      } else if (_errorHandler != null) {
        _errorHandler("Could not create temporary directory [$_path]: " +
                      "${result[1]}");
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

  void delete([bool recursive = false]) {
    if (_directoryService == null) {
      _directoryService = _newServicePort();
    }
    List request = new List(3);
    request[0] = kDeleteRequest;
    request[1] = _path;
    request[2] = recursive;
    _directoryService.call(request).receive((result, replyTo) {
      if (result) {
        if (_deleteHandler != null) _deleteHandler();
      } else if (_errorHandler != null) {
        if (recursive) {
          _errorHandler("Recursive directory deletion failed: $_path");
        } else {
          _errorHandler("Non-recursive directory deletion failed: $_path");
        }
      }
    });
  }

  void deleteSync([bool recursive = false]) {
    if (!_delete(_path, recursive)) {
      throw new DirectoryException("Directory deletion failed: $_path");
    }
  }

  void list([bool recursive = false]) {
    final int kListDirectory = 0;
    final int kListFile = 1;
    final int kListError = 2;
    final int kListDone = 3;

    List request = new List(3);
    request[0] = kListRequest;
    request[1] = _path;
    request[2] = recursive;
    ReceivePort responsePort = new ReceivePort();
    // Use a separate directory service port for each listing as
    // listing operations on the same directory can run in parallel.
    _newServicePort().send(request, responsePort.toSendPort());
    responsePort.receive((message, replyTo) {
      if (message is !List || message[0] is !int) {
        responsePort.close();
        if (_errorHandler != null) _errorHandler("Internal error");
        return;
      }
      switch (message[0]) {
        case kListDirectory:
          if (_dirHandler != null) _dirHandler(message[1]);
          break;
        case kListFile:
          if (_fileHandler != null) _fileHandler(message[1]);
          break;
        case kListError:
          if (_errorHandler != null) _errorHandler(message[1]);
          break;
        case kListDone:
          responsePort.close();
          if (_doneHandler != null) _doneHandler(message[1]);
          break;
      }
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
  SendPort _directoryService;
}
