// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

class _Directory extends FileSystemEntity implements Directory {
  final String path;

  _Directory(this.path) {
    if (path is! String) {
      throw new ArgumentError('${Error.safeToString(path)} '
                              'is not a String');
    }
  }

  external static _current();
  external static _setCurrent(path);
  external static _createTemp(String path);
  external static String _systemTemp();
  external static _exists(String path);
  external static _create(String path);
  external static _deleteNative(String path, bool recursive);
  external static _rename(String path, String newPath);
  external static List _list(String path, bool recursive, bool followLinks);

  static Directory get current {
    var result = _current();
    if (result is OSError) {
      throw new FileSystemException(
          "Getting current working directory failed", "", result);
    }
    return new _Directory(result);
  }

  static void set current(path) {
    if (path is Directory) path = path.path;
    var result = _setCurrent(path);
    if (result is ArgumentError) throw result;
    if (result is OSError) {
      throw new FileSystemException(
          "Setting current working directory failed", path, result);
    }
  }

  Future<bool> exists() {
    return _IOService.dispatch(_DIRECTORY_EXISTS, [path]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionOrErrorFromResponse(response, "Exists failed");
      }
      return response == 1;
    });
  }

  bool existsSync() {
    var result = _exists(path);
    if (result is OSError) {
      throw new FileSystemException("Exists failed", path, result);
    }
    return (result == 1);
  }

  Directory get absolute => new Directory(_absolutePath);

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

  Future<Directory> create({bool recursive: false}) {
    if (recursive) {
      return exists().then((exists) {
        if (exists) return this;
        if (path != parent.path) {
          return parent.create(recursive: true).then((_) {
            return create();
          });
        } else {
          return create();
        }
      });
    } else {
      return _IOService.dispatch(_DIRECTORY_CREATE, [path]).then((response) {
        if (_isErrorResponse(response)) {
          throw _exceptionOrErrorFromResponse(response, "Creation failed");
        }
        return this;
      });
    }
  }

  void createSync({bool recursive: false}) {
    if (recursive) {
      if (existsSync()) return;
      if (path != parent.path) {
        parent.createSync(recursive: true);
      }
    }
    var result = _create(path);
    if (result is OSError) {
      throw new FileSystemException("Creation failed", path, result);
    }
  }

  static Directory get systemTemp => new Directory(_systemTemp());

  Future<Directory> createTemp([String prefix]) {
    if (prefix == null) prefix = '';
    if (path == '') {
      throw new ArgumentError(
          "Directory.createTemp called with an empty path. "
          "To use the system temp directory, use Directory.systemTemp");
    }
    String fullPrefix;
    if (path.endsWith('/') || (Platform.isWindows && path.endsWith('\\'))) {
      fullPrefix = "$path$prefix";
    } else {
      fullPrefix = "$path${Platform.pathSeparator}$prefix";
    }
    return _IOService.dispatch(_DIRECTORY_CREATE_TEMP, [fullPrefix])
        .then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionOrErrorFromResponse(
            response, "Creation of temporary directory failed");
      }
      return new Directory(response);
    });
  }

  Directory createTempSync([String prefix]) {
    if (prefix == null) prefix = '';
    if (path == '') {
      throw new ArgumentError(
          "Directory.createTemp called with an empty path. "
          "To use the system temp directory, use Directory.systemTemp");
    }
    String fullPrefix;
    if (path.endsWith('/') || (Platform.isWindows && path.endsWith('\\'))) {
      fullPrefix = "$path$prefix";
    } else {
      fullPrefix = "$path${Platform.pathSeparator}$prefix";
    }
    var result = _createTemp(fullPrefix);
    if (result is OSError) {
      throw new FileSystemException("Creation of temporary directory failed",
                                   fullPrefix,
                                   result);
    }
    return new Directory(result);
  }

  Future<Directory> _delete({bool recursive: false}) {
    return _IOService.dispatch(_DIRECTORY_DELETE, [path, recursive])
        .then((response) {
          if (_isErrorResponse(response)) {
            throw _exceptionOrErrorFromResponse(response, "Deletion failed");
          }
          return this;
        });
  }

  void _deleteSync({bool recursive: false}) {
    var result = _deleteNative(path, recursive);
    if (result is OSError) {
      throw new FileSystemException("Deletion failed", path, result);
    }
  }

  Future<Directory> rename(String newPath) {
    return _IOService.dispatch(_DIRECTORY_RENAME, [path, newPath])
        .then((response) {
          if (_isErrorResponse(response)) {
            throw _exceptionOrErrorFromResponse(response, "Rename failed");
          }
          return new Directory(newPath);
        });
  }

  Directory renameSync(String newPath) {
    if (newPath is !String) {
      throw new ArgumentError();
    }
    var result = _rename(path, newPath);
    if (result is OSError) {
      throw new FileSystemException("Rename failed", path, result);
    }
    return new Directory(newPath);
  }

  Stream<FileSystemEntity> list({bool recursive: false,
                                 bool followLinks: true}) {
    return new _AsyncDirectoryLister(
        FileSystemEntity._ensureTrailingPathSeparators(path),
        recursive,
        followLinks).stream;
  }

  List listSync({bool recursive: false, bool followLinks: true}) {
    if (recursive is! bool || followLinks is! bool) {
      throw new ArgumentError();
    }
    return _list(
        FileSystemEntity._ensureTrailingPathSeparators(path),
        recursive,
        followLinks);
  }

  String toString() => "Directory: '$path'";

  bool _isErrorResponse(response) =>
      response is List && response[0] != _SUCCESS_RESPONSE;

  _exceptionOrErrorFromResponse(response, String message) {
    assert(_isErrorResponse(response));
    switch (response[_ERROR_RESPONSE_ERROR_TYPE]) {
      case _ILLEGAL_ARGUMENT_RESPONSE:
        return new ArgumentError();
      case _OSERROR_RESPONSE:
        var err = new OSError(response[_OSERROR_RESPONSE_MESSAGE],
                              response[_OSERROR_RESPONSE_ERROR_CODE]);
        return new FileSystemException(message, path, err);
      default:
        return new Exception("Unknown error");
    }
  }
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
  Completer closeCompleter = new Completer();

  _AsyncDirectoryLister(this.path, this.recursive, this.followLinks) {
    controller = new StreamController(onListen: onListen,
                                      onResume: onResume,
                                      onCancel: onCancel,
                                      sync: true);
  }

  Stream get stream => controller.stream;

  void onListen() {
    _IOService.dispatch(_DIRECTORY_LIST_START, [path, recursive, followLinks])
        .then((response) {
          if (response is int) {
            id = response;
            next();
          } else {
            error(response);
            close();
          }
        });
  }

  void onResume() {
    if (!nextRunning) next();
  }

  Future onCancel() {
    canceled = true;
    // If we are active, but not requesting, close.
    if (!nextRunning) {
      close();
    }

    return closeCompleter.future;
  }

  void next() {
    if (canceled) {
      close();
      return;
    }
    if (id == null) return;
    if (controller.isPaused) return;
    if (nextRunning) return;
    nextRunning = true;
    _IOService.dispatch(_DIRECTORY_LIST_NEXT, [id]).then((result) {
      nextRunning = false;
      if (result is List) {
        next();
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
              canceled = true;
              return;
          }
        }
      } else {
        controller.addError(new FileSystemException("Internal error"));
      }
    });
  }

  void close() {
    if (closed) return;
    if (nextRunning) return;
    void cleanup() {
      controller.close();
      closeCompleter.complete();
    }
    closed = true;
    if (id != null) {
      _IOService.dispatch(_DIRECTORY_LIST_STOP, [id]).whenComplete(cleanup);
    } else {
      cleanup();
    }
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
          new FileSystemException("Directory listing failed",
                                 errorPath,
                                 err));
    } else {
      controller.addError(
          new FileSystemException("Internal error"));
    }
  }
}
