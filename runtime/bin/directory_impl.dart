// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _Directory implements Directory {
  static const CREATE_REQUEST = 0;
  static const DELETE_REQUEST = 1;
  static const EXISTS_REQUEST = 2;
  static const CREATE_TEMP_REQUEST = 3;
  static const LIST_REQUEST = 4;
  static const RENAME_REQUEST = 5;

  static const SUCCESS_RESPONSE = 0;
  static const ILLEGAL_ARGUMENT_RESPONSE = 1;
  static const OSERROR_RESPONSE = 2;

  _Directory(String this._path);
  _Directory.fromPath(Path path) : this(path.toNativePath());
  _Directory.current() : this(_current());

  static String _current() native "Directory_Current";
  static _createTemp(String template) native "Directory_CreateTemp";
  static int _exists(String path) native "Directory_Exists";
  static _create(String path) native "Directory_Create";
  static _delete(String path, bool recursive) native "Directory_Delete";
  static _rename(String path, String newPath) native "Directory_Rename";
  static SendPort _newServicePort() native "Directory_NewServicePort";

  Future<bool> exists() {
    _ensureDirectoryService();
    List request = new List(2);
    request[0] = EXISTS_REQUEST;
    request[1] = _path;
    return _directoryService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "Exists failed");
      }
      return response == 1;
    });
  }

  bool existsSync() {
    if (_path is !String) {
      throw new ArgumentError();
    }
    var result = _exists(_path);
    if (result is OSError) {
      throw new DirectoryIOException("Exists failed", _path, result);
    }
    return (result == 1);
  }

  Future<Directory> create() {
    _ensureDirectoryService();
    List request = new List(2);
    request[0] = CREATE_REQUEST;
    request[1] = _path;
    return _directoryService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "Creation failed");
      }
      return this;
    });
  }

  void createSync() {
    if (_path is !String) {
      throw new ArgumentError();
    }
    var result = _create(_path);
    if (result is OSError) {
      throw new DirectoryIOException("Creation failed", _path, result);
    }
  }

  Future<Directory> createTemp() {
    _ensureDirectoryService();
    List request = new List(2);
    request[0] = CREATE_TEMP_REQUEST;
    request[1] = _path;
    return _directoryService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
                                     "Creation of temporary directory failed");
      }
      return new Directory(response);
    });
  }

  Directory createTempSync() {
    if (_path is !String) {
      throw new ArgumentError();
    }
    var result = _createTemp(path);
    if (result is OSError) {
      throw new DirectoryIOException("Creation of temporary directory failed",
                                     _path,
                                     result);
    }
    return new Directory(result);
  }

  Future<Directory> _deleteHelper(bool recursive, String errorMsg) {
    _ensureDirectoryService();
    List request = new List(3);
    request[0] = DELETE_REQUEST;
    request[1] = _path;
    request[2] = recursive;
    return _directoryService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, errorMsg);
      }
      return this;
    });
    return completer.future;
  }

  Future<Directory> delete() {
    return _deleteHelper(false, "Deletion failed");
  }

  void deleteSync() {
    if (_path is !String) {
      throw new ArgumentError();
    }
    var result = _delete(_path, false);
    if (result is OSError) {
      throw new DirectoryIOException("Deletion failed", _path, result);
    }
  }

  Future<Directory> deleteRecursively() {
    return _deleteHelper(true, "Deletion failed");
  }

  void deleteRecursivelySync() {
    if (_path is !String) {
      throw new ArgumentError();
    }
    var result = _delete(_path, true);
    if (result is OSError) {
      throw new DirectoryIOException("Deletion failed", _path, result);
    }
  }

  Future<Directory> rename(String newPath) {
    _ensureDirectoryService();
    List request = new List(3);
    request[0] = RENAME_REQUEST;
    request[1] = _path;
    request[2] = newPath;
    return _directoryService.call(request).transform((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "Rename failed");
      }
      return new Directory(newPath);
    });
  }

  Directory renameSync(String newPath) {
    if (_path is !String || newPath is !String) {
      throw new ArgumentError();
    }
    var result = _rename(_path, newPath);
    if (result is OSError) {
      throw new DirectoryIOException("Rename failed", _path, result);
    }
    return new Directory(newPath);
  }

  DirectoryLister list([bool recursive = false]) {
    return new _DirectoryLister(_path, recursive);
  }

  String get path { return _path; }

  bool _isErrorResponse(response) {
    return response is List && response[0] != _FileUtils.SUCCESS_RESPONSE;
  }

  Exception _exceptionFromResponse(response, String message) {
    assert(_isErrorResponse(response));
    switch (response[_FileUtils.ERROR_RESPONSE_ERROR_TYPE]) {
      case _FileUtils.ILLEGAL_ARGUMENT_RESPONSE:
        return new ArgumentError();
      case _FileUtils.OSERROR_RESPONSE:
        var err = new OSError(response[_FileUtils.OSERROR_RESPONSE_MESSAGE],
                              response[_FileUtils.OSERROR_RESPONSE_ERROR_CODE]);
        return new DirectoryIOException(message, _path, err);
      default:
        return new Exception("Unknown error");
    }
  }

  void _ensureDirectoryService() {
    if (_directoryService == null) {
      _directoryService = _newServicePort();
    }
  }

  final String _path;
  SendPort _directoryService;
}

class _DirectoryLister implements DirectoryLister {
  _DirectoryLister(String path, bool recursive) {
    const int LIST_DIRECTORY = 0;
    const int LIST_FILE = 1;
    const int LIST_ERROR = 2;
    const int LIST_DONE = 3;

    final int RESPONSE_TYPE = 0;
    final int RESPONSE_PATH = 1;
    final int RESPONSE_COMPLETE = 1;
    final int RESPONSE_ERROR = 2;

    List request = new List(3);
    request[0] = _Directory.LIST_REQUEST;
    request[1] = path;
    request[2] = recursive;
    ReceivePort responsePort = new ReceivePort();
    // Use a separate directory service port for each listing as
    // listing operations on the same directory can run in parallel.
    _Directory._newServicePort().send(request, responsePort.toSendPort());
    responsePort.receive((message, replyTo) {
      if (message is !List || message[RESPONSE_TYPE] is !int) {
        responsePort.close();
        _reportError(new DirectoryIOException("Internal error"));
        return;
      }
      switch (message[RESPONSE_TYPE]) {
        case LIST_DIRECTORY:
          if (_onDir != null) _onDir(message[RESPONSE_PATH]);
          break;
        case LIST_FILE:
          if (_onFile != null) _onFile(message[RESPONSE_PATH]);
          break;
        case LIST_ERROR:
          var errorType =
              message[RESPONSE_ERROR][_FileUtils.ERROR_RESPONSE_ERROR_TYPE];
          if (errorType == _FileUtils.ILLEGAL_ARGUMENT_RESPONSE) {
            _reportError(new ArgumentError());
          } else if (errorType == _FileUtils.OSERROR_RESPONSE) {
            var responseError = message[RESPONSE_ERROR];
            var err = new OSError(
                responseError[_FileUtils.OSERROR_RESPONSE_MESSAGE],
                responseError[_FileUtils.OSERROR_RESPONSE_ERROR_CODE]);
            var errorPath = message[RESPONSE_PATH];
            if (errorPath == null) errorPath = path;
            _reportError(new DirectoryIOException("Directory listing failed",
                                                  errorPath,
                                                  err));
          } else {
            _reportError(new DirectoryIOException("Internal error"));
          }
          break;
        case LIST_DONE:
          responsePort.close();
          if (_onDone != null) _onDone(message[RESPONSE_COMPLETE]);
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

  void set onError(void onError(e)) {
    _onError = onError;
  }

  void _reportError(e) {
    if (_onError != null) {
      _onError(e);
    } else {
      throw e;
    }
  }

  Function _onDir;
  Function _onFile;
  Function _onDone;
  Function _onError;
}
