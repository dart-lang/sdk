// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

class _Directory implements Directory {
  static const CREATE_REQUEST = 0;
  static const DELETE_REQUEST = 1;
  static const EXISTS_REQUEST = 2;
  static const CREATE_TEMP_REQUEST = 3;
  static const LIST_START_REQUEST = 4;
  static const LIST_NEXT_REQUEST = 5;
  static const LIST_STOP_REQUEST = 6;
  static const RENAME_REQUEST = 7;

  _Directory(String this._path);
  _Directory.fromPath(Path path) : this(path.toNativePath());

  external static String _current();
  external static _setCurrent(path);
  external static _createTemp(String template);
  external static int _exists(String path);
  external static _create(String path);
  external static _delete(String path, bool recursive);
  external static _rename(String path, String newPath);
  external static List _list(String path, bool recursive, bool followLinks);
  external static SendPort _newServicePort();

  static Directory get current => new _Directory(_current());

  static void set current(path) {
    if (path is Directory) path = path.path;
    var result = _setCurrent(path);
    if (result is ArgumentError) throw result;
    if (result is OSError) {
      throw new DirectoryException(
          "Setting current working directory failed", path, result);
    }
  }

  Future<bool> exists() {
    _ensureDirectoryService();
    List request = new List(2);
    request[0] = EXISTS_REQUEST;
    request[1] = _path;
    return _directoryService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionOrErrorFromResponse(response, "Exists failed");
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
      throw new DirectoryException("Exists failed", _path, result);
    }
    return (result == 1);
  }

  Future<FileStat> stat() => FileStat.stat(path);

  FileStat statSync() => FileStat.statSync(path);

  // Compute the index of the first directory in the list that exists. If
  // none of the directories exist dirsToCreate.length is returned.
  Future<int> _computeExistingIndex(List dirsToCreate) {
    var future;
    var notFound = dirsToCreate.length;
    for (var i = 0; i < dirsToCreate.length; i++) {
      if (future == null) {
        future = dirsToCreate[i].exists().then((e) => e ? i : notFound);
      } else {
        future = future.then((index) {
          if (index != notFound) {
            return new Future.value(index);
          }
          return dirsToCreate[i].exists().then((e) => e ? i : notFound);
        });
      }
    }
    if (future == null) {
      return new Future.value(notFound);
    } else {
      return future;
    }
  }

  Future<Directory> createRecursively() {
    if (_path is !String) {
      throw new ArgumentError();
    }
    var path = new Path(_path);
    var dirsToCreate = [];
    var terminator = path.isAbsolute ? '/' : '';
    while (path.toString() != terminator) {
      dirsToCreate.add(new Directory.fromPath(path));
      path = path.directoryPath;
    }
    return _computeExistingIndex(dirsToCreate).then((index) {
      var future;
      for (var i = index - 1; i >= 0 ; i--) {
        if (future == null) {
          future = dirsToCreate[i].create();
        } else {
          future = future.then((_) {
            return dirsToCreate[i].create();
          });
        }
      }
      if (future == null) {
        return new Future.value(this);
      } else {
        return future.then((_) => this);
      }
    });
  }

  Future<Directory> create({recursive: false}) {
    if (recursive) return createRecursively();
    _ensureDirectoryService();
    List request = new List(2);
    request[0] = CREATE_REQUEST;
    request[1] = _path;
    return _directoryService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionOrErrorFromResponse(response, "Creation failed");
      }
      return this;
    });
  }

  void createRecursivelySync() {
    var path = new Path(_path);
    var dirsToCreate = [];
    var terminator = path.isAbsolute ? '/' : '';
    while (path.toString() != terminator) {
      var dir = new Directory.fromPath(path);
      if (dir.existsSync()) break;
      dirsToCreate.add(dir);
      path = path.directoryPath;
    }
    for (var i = dirsToCreate.length - 1; i >= 0; i--) {
      dirsToCreate[i].createSync();
    }
  }

  void createSync({recursive: false}) {
    if (_path is !String) {
      throw new ArgumentError();
    }
    if (recursive) return createRecursivelySync();
    var result = _create(_path);
    if (result is OSError) {
      throw new DirectoryException("Creation failed", _path, result);
    }
  }

  Future<Directory> createTemp() {
    _ensureDirectoryService();
    List request = new List(2);
    request[0] = CREATE_TEMP_REQUEST;
    request[1] = _path;
    return _directoryService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionOrErrorFromResponse(
            response, "Creation of temporary directory failed");
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
      throw new DirectoryException("Creation of temporary directory failed",
                                   _path,
                                   result);
    }
    return new Directory(result);
  }

  Future<Directory> delete({recursive: false}) {
    _ensureDirectoryService();
    List request = new List(3);
    request[0] = DELETE_REQUEST;
    request[1] = _path;
    request[2] = recursive;
    return _directoryService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionOrErrorFromResponse(response, "Deletion failed");
      }
      return this;
    });
  }

  void deleteSync({recursive: false}) {
    if (_path is !String) {
      throw new ArgumentError();
    }
    var result = _delete(_path, recursive);
    if (result is OSError) {
      throw new DirectoryException("Deletion failed", _path, result);
    }
  }

  Future<Directory> rename(String newPath) {
    _ensureDirectoryService();
    List request = new List(3);
    request[0] = RENAME_REQUEST;
    request[1] = _path;
    request[2] = newPath;
    return _directoryService.call(request).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionOrErrorFromResponse(response, "Rename failed");
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
      throw new DirectoryException("Rename failed", _path, result);
    }
    return new Directory(newPath);
  }

  static String _trimTrailingPathSeparators(String path) {
    // Don't handle argument errors here.
    if (path is! String) return path;
    if (Platform.operatingSystem == 'windows') {
      while (path.length > 1 &&
             (path.endsWith(Platform.pathSeparator) ||
              path.endsWith('/'))) {
        path = path.substring(0, path.length - 1);
      }
    } else {
      while (path.length > 1 && path.endsWith(Platform.pathSeparator)) {
        path = path.substring(0, path.length - 1);
      }
    }
    return path;
  }

  Stream<FileSystemEntity> list({bool recursive: false,
                                 bool followLinks: true}) {
    return new _AsyncDirectoryLister(_trimTrailingPathSeparators(path),
                                     recursive,
                                     followLinks).stream;
  }

  List listSync({bool recursive: false, bool followLinks: true}) {
    if (_path is! String || recursive is! bool || followLinks is! bool) {
      throw new ArgumentError();
    }
    return _list(_trimTrailingPathSeparators(path), recursive, followLinks);
  }

  String get path => _path;

  String toString() => "Directory: '$path'";

  bool _isErrorResponse(response) {
    return response is List && response[0] != _SUCCESS_RESPONSE;
  }

  _exceptionOrErrorFromResponse(response, String message) {
    assert(_isErrorResponse(response));
    switch (response[_ERROR_RESPONSE_ERROR_TYPE]) {
      case _ILLEGAL_ARGUMENT_RESPONSE:
        return new ArgumentError();
      case _OSERROR_RESPONSE:
        var err = new OSError(response[_OSERROR_RESPONSE_MESSAGE],
                              response[_OSERROR_RESPONSE_ERROR_CODE]);
        return new DirectoryException(message, _path, err);
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

class _AsyncDirectoryLister {
  static const int LIST_FILE = 0;
  static const int LIST_DIRECTORY = 1;
  static const int LIST_LINK = 2;
  static const int LIST_ERROR = 3;
  static const int LIST_DONE = 4;

  static const int RESPONSE_TYPE = 0;
  static const int RESPONSE_PATH = 1;
  static const int RESPONSE_COMPLETE = 1;
  static const int RESPONSE_ERROR = 2;

  final String path;
  final bool recursive;
  final bool followLinks;

  StreamController controller;
  int id;
  bool canceled = false;
  bool nextRunning = false;
  bool closed = false;

  _AsyncDirectoryLister(String this.path,
                        bool this.recursive,
                        bool this.followLinks) {
    controller = new StreamController(onListen: onListen,
                                      onResume: onResume,
                                      onCancel: onCancel,
                                      sync: true);
  }

  Stream get stream => controller.stream;

  void onListen() {
    var request = [_Directory.LIST_START_REQUEST, path, recursive, followLinks];
    _Directory._newServicePort().call(request)
        .then((response) {
          if (response is int) {
            id = response;
            next();
          } else {
            error(response);
            controller.close();
          }
        });
  }

  void onResume() {
    if (!nextRunning) next();
  }

  void onCancel() {
    canceled = true;
    // If we are active, but not requesting, close.
    if (!nextRunning) {
      close();
    }
  }

  void next() {
    if (canceled) {
      close();
      return;
    }
    if (id == null) return;
    if (controller.isPaused) return;
    assert(!nextRunning);
    nextRunning = true;
    _Directory._newServicePort().call([_Directory.LIST_NEXT_REQUEST, id])
        .then((result) {
          if (result is List) {
            assert(result.length % 2 == 0);
            for (int i = 0; i < result.length; i++) {
              assert(i % 2 == 0);
              switch (result[i++]) {
                case LIST_FILE:
                  controller.add(new File(result[i]));
                  break;
                case LIST_DIRECTORY:
                  controller.add(new Directory(result[i]));
                  break;
                case LIST_LINK:
                  controller.add(new Link(result[i]));
                  break;
                case LIST_ERROR:
                  error(result[i]);
                  break;
                case LIST_DONE:
                  close();
                  return;
              }
            }
          } else {
            controller.addError(new DirectoryException("Internal error"));
          }
          nextRunning = false;
          next();
        });
  }

  void close() {
    if (closed) return;
    if (id == null) return;
    closed = true;
    _Directory._newServicePort().call([_Directory.LIST_STOP_REQUEST, id])
        .then((_) {
          controller.close();
        });
  }

  void error(message) {
    var errorType =
        message[RESPONSE_ERROR][_ERROR_RESPONSE_ERROR_TYPE];
    if (errorType == _ILLEGAL_ARGUMENT_RESPONSE) {
      controller.addError(new ArgumentError());
    } else if (errorType == _OSERROR_RESPONSE) {
      var responseError = message[RESPONSE_ERROR];
      var err = new OSError(
          responseError[_OSERROR_RESPONSE_MESSAGE],
          responseError[_OSERROR_RESPONSE_ERROR_CODE]);
      var errorPath = message[RESPONSE_PATH];
      if (errorPath == null) errorPath = path;
      controller.addError(
          new DirectoryException("Directory listing failed",
                                 errorPath,
                                 err));
    } else {
      controller.addError(
          new DirectoryException("Internal error"));
    }
  }
}
