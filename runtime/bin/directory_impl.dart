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
  _Directory.current() : _path = _current();

  static String _current() native "Directory_Current";
  static String _createTemp(String template,
                            _OSStatus status) native "Directory_CreateTemp";
  static int _exists(String path) native "Directory_Exists";
  static bool _create(String path) native "Directory_Create";
  static bool _delete(String path, bool recursive) native "Directory_Delete";
  static SendPort _newServicePort() native "Directory_NewServicePort";

  void exists(void callback(bool exists)) {
    _ensureDirectoryService();
    List request = new List(2);
    request[0] = kExistsRequest;
    request[1] = _path;
    _directoryService.call(request).receive((result, replyTo) {
      if (result < 0) {
        if (_onError != null) {
          _onError("Diretory exists test failed: $_path");
        }
      } else {
        callback(result == 1);
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

  void create(void callback()) {
    _ensureDirectoryService();
    List request = new List(2);
    request[0] = kCreateRequest;
    request[1] = _path;
    _directoryService.call(request).receive((result, replyTo) {
      if (result) {
        callback();
      } else if (_onError != null) {
        _onError("Directory creation failed: $_path");
      }
    });
  }

  void createSync() {
    if (!_create(_path)) {
      throw new DirectoryException("Directory creation failed: $_path");
    }
  }

  void createTemp(void callback()) {
    _ensureDirectoryService();
    List request = new List(2);
    request[0] = kCreateTempRequest;
    request[1] = _path;
    _directoryService.call(request).receive((result, replyTo) {
      if (result is !List) {
        _path = result;
        callback();
      } else if (_onError != null) {
        _onError("Could not create temporary directory [$_path]: " +
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

  void _deleteHelper(bool recursive, String errorMsg, void callback()) {
    _ensureDirectoryService();
    List request = new List(3);
    request[0] = kDeleteRequest;
    request[1] = _path;
    request[2] = recursive;
    _directoryService.call(request).receive((result, replyTo) {
      if (result) {
        callback();
      } else if (_onError != null) {
        _onError("${errorMsg}: $_path");
      }
    });
  }

  void delete(void callback()) {
    _deleteHelper(false, "Directory deletion failed", callback);
  }

  void deleteRecursively(void callback()) {
    _deleteHelper(true, "Recursive directory deletion failed", callback);
  }

  void deleteSync() {
    bool recursive = false;
    if (!_delete(_path, recursive)) {
      throw new DirectoryException("Directory deletion failed: $_path");
    }
  }

  void deleteRecursivelySync() {
    bool recursive = true;
    if (!_delete(_path, recursive)) {
      throw new DirectoryException(
          "Recursive directory deletion failed: $_path");
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
        if (_onError != null) _onError("Internal error");
        return;
      }
      switch (message[0]) {
        case kListDirectory:
          if (_onDir != null) _onDir(message[1]);
          break;
        case kListFile:
          if (_onFile != null) _onFile(message[1]);
          break;
        case kListError:
          if (_onError != null) _onError(message[1]);
          break;
        case kListDone:
          responsePort.close();
          if (_onDone != null) _onDone(message[1]);
          break;
      }
    });
  }

  void set onDir(void onDir(String dir)) {
    _onDir = onDir;
  }

  void set onFile(void onFile(String file)) {
    _onFile = onFile;
  }

  void set onDone(void onDone(bool completed)) {
    _onDone = onDone;
  }

  void set onError(void onError(String error)) {
    _onError = onError;
  }

  String get path() { return _path; }

  void _ensureDirectoryService() {
    if (_directoryService == null) {
      _directoryService = _newServicePort();
    }
  }

  var _onDir;
  var _onFile;
  var _onDone;
  var _onError;

  String _path;
  SendPort _directoryService;
}
