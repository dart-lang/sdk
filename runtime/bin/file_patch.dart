// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@patch
class _File {
  @patch
  static _exists(_Namespace namespace, String path) native "File_Exists";
  @patch
  static _create(_Namespace namespace, String path) native "File_Create";
  @patch
  static _createLink(_Namespace namespace, String path, String target)
      native "File_CreateLink";
  @patch
  static _linkTarget(_Namespace namespace, String path)
      native "File_LinkTarget";
  @patch
  static _deleteNative(_Namespace namespace, String path) native "File_Delete";
  @patch
  static _deleteLinkNative(_Namespace namespace, String path)
      native "File_DeleteLink";
  @patch
  static _rename(_Namespace namespace, String oldPath, String newPath)
      native "File_Rename";
  @patch
  static _renameLink(_Namespace namespace, String oldPath, String newPath)
      native "File_RenameLink";
  @patch
  static _copy(_Namespace namespace, String oldPath, String newPath)
      native "File_Copy";
  @patch
  static _lengthFromPath(_Namespace namespace, String path)
      native "File_LengthFromPath";
  @patch
  static _lastModified(_Namespace namespace, String path)
      native "File_LastModified";
  @patch
  static _setLastModified(_Namespace namespace, String path, int millis)
      native "File_SetLastModified";
  @patch
  static _lastAccessed(_Namespace namespace, String path)
      native "File_LastAccessed";
  @patch
  static _setLastAccessed(_Namespace namespace, String path, int millis)
      native "File_SetLastAccessed";
  @patch
  static _open(_Namespace namespace, String path, int mode) native "File_Open";
  @patch
  static int _openStdio(int fd) native "File_OpenStdio";
}

@patch
class _RandomAccessFileOps {
  @patch
  factory _RandomAccessFileOps(int pointer) =>
      new _RandomAccessFileOpsImpl(pointer);
}

class _RandomAccessFileOpsImpl extends NativeFieldWrapperClass1
    implements _RandomAccessFileOps {
  _RandomAccessFileOpsImpl._();

  factory _RandomAccessFileOpsImpl(int pointer) =>
      new _RandomAccessFileOpsImpl._().._setPointer(pointer);

  void _setPointer(int pointer) native "File_SetPointer";

  int getPointer() native "File_GetPointer";
  int close() native "File_Close";
  readByte() native "File_ReadByte";
  read(int bytes) native "File_Read";
  readInto(List<int> buffer, int start, int end) native "File_ReadInto";
  writeByte(int value) native "File_WriteByte";
  writeFrom(List<int> buffer, int start, int end) native "File_WriteFrom";
  position() native "File_Position";
  setPosition(int position) native "File_SetPosition";
  truncate(int length) native "File_Truncate";
  length() native "File_Length";
  flush() native "File_Flush";
  lock(int lock, int start, int end) native "File_Lock";
}

class _WatcherPath {
  final int pathId;
  final String path;
  final int events;
  int count = 0;
  _WatcherPath(this.pathId, this.path, this.events);
}

@patch
class _FileSystemWatcher {
  static int _id;
  static final Map<int, _WatcherPath> _idMap = {};

  final String _path;
  final int _events;
  final bool _recursive;

  _WatcherPath _watcherPath;

  StreamController _broadcastController;

  @patch
  static Stream<FileSystemEvent> _watch(
      String path, int events, bool recursive) {
    if (Platform.isLinux) {
      return new _InotifyFileSystemWatcher(path, events, recursive)._stream;
    }
    if (Platform.isWindows) {
      return new _Win32FileSystemWatcher(path, events, recursive)._stream;
    }
    if (Platform.isMacOS) {
      return new _FSEventStreamFileSystemWatcher(path, events, recursive)
          ._stream;
    }
    throw new FileSystemException(
        "File system watching is not supported on this platform");
  }

  _FileSystemWatcher._(this._path, this._events, this._recursive) {
    if (!isSupported) {
      throw new FileSystemException(
          "File system watching is not supported on this platform", _path);
    }
    _broadcastController =
        new StreamController.broadcast(onListen: _listen, onCancel: _cancel);
  }

  Stream get _stream => _broadcastController.stream;

  void _listen() {
    if (_id == null) {
      try {
        _id = _initWatcher();
        _newWatcher();
      } catch (e) {
        _broadcastController.addError(new FileSystemException(
            "Failed to initialize file system entity watcher", null, e));
        _broadcastController.close();
        return;
      }
    }
    var pathId;
    try {
      pathId =
          _watchPath(_id, _Namespace._namespace, _path, _events, _recursive);
    } catch (e) {
      _broadcastController
          .addError(new FileSystemException("Failed to watch path", _path, e));
      _broadcastController.close();
      return;
    }
    if (!_idMap.containsKey(pathId)) {
      _idMap[pathId] = new _WatcherPath(pathId, _path, _events);
    }
    _watcherPath = _idMap[pathId];
    _watcherPath.count++;
    _pathWatched().pipe(_broadcastController);
  }

  void _cancel() {
    if (_watcherPath != null) {
      assert(_watcherPath.count > 0);
      _watcherPath.count--;
      if (_watcherPath.count == 0) {
        _unwatchPath(_id, _watcherPath.pathId);
        _pathWatchedEnd();
        _idMap.remove(_watcherPath.pathId);
      }
      _watcherPath = null;
    }
    if (_idMap.isEmpty && _id != null) {
      _closeWatcher(_id);
      _doneWatcher();
      _id = null;
    }
  }

  // Called when (and after) a new watcher instance is created and available.
  void _newWatcher() {}
  // Called when a watcher is no longer needed.
  void _doneWatcher() {}
  // Called when a new path is being watched.
  Stream _pathWatched() {}
  // Called when a path is no longer being watched.
  void _donePathWatched() {}

  static _WatcherPath _pathFromPathId(int pathId) {
    return _idMap[pathId];
  }

  static Stream _listenOnSocket(int socketId, int id, int pathId) {
    var native = new _NativeSocket.watch(socketId);
    var socket = new _RawSocket(native);
    return socket.expand((event) {
      var stops = [];
      var events = [];
      var pair = {};
      if (event == RawSocketEvent.READ) {
        String getPath(event) {
          var path = _pathFromPathId(event[4]).path;
          if (event[2] != null && event[2].isNotEmpty) {
            path += Platform.pathSeparator;
            path += event[2];
          }
          return path;
        }

        bool getIsDir(event) {
          if (Platform.isWindows) {
            // Windows does not get 'isDir' as part of the event.
            return FileSystemEntity.isDirectorySync(getPath(event));
          }
          return (event[0] & FileSystemEvent._IS_DIR) != 0;
        }

        void add(id, event) {
          if ((event.type & _pathFromPathId(id).events) == 0) return;
          events.add([id, event]);
        }

        void rewriteMove(event, isDir) {
          if (event[3]) {
            add(event[4], new FileSystemCreateEvent._(getPath(event), isDir));
          } else {
            add(event[4], new FileSystemDeleteEvent._(getPath(event), isDir));
          }
        }

        int eventCount;
        do {
          eventCount = 0;
          for (var event in _readEvents(id, pathId)) {
            if (event == null) continue;
            eventCount++;
            int pathId = event[4];
            if (!_idMap.containsKey(pathId)) {
              // Path is no longer being wathed.
              continue;
            }
            bool isDir = getIsDir(event);
            var path = getPath(event);
            if ((event[0] & FileSystemEvent.CREATE) != 0) {
              add(event[4], new FileSystemCreateEvent._(path, isDir));
            }
            if ((event[0] & FileSystemEvent.MODIFY) != 0) {
              add(event[4], new FileSystemModifyEvent._(path, isDir, true));
            }
            if ((event[0] & FileSystemEvent._MODIFY_ATTRIBUTES) != 0) {
              add(event[4], new FileSystemModifyEvent._(path, isDir, false));
            }
            if ((event[0] & FileSystemEvent.MOVE) != 0) {
              int link = event[1];
              if (link > 0) {
                pair.putIfAbsent(pathId, () => {});
                if (pair[pathId].containsKey(link)) {
                  add(
                      event[4],
                      new FileSystemMoveEvent._(
                          getPath(pair[pathId][link]), isDir, path));
                  pair[pathId].remove(link);
                } else {
                  pair[pathId][link] = event;
                }
              } else {
                rewriteMove(event, isDir);
              }
            }
            if ((event[0] & FileSystemEvent.DELETE) != 0) {
              add(event[4], new FileSystemDeleteEvent._(path, isDir));
            }
            if ((event[0] & FileSystemEvent._DELETE_SELF) != 0) {
              add(event[4], new FileSystemDeleteEvent._(path, isDir));
              // Signal done event.
              stops.add([event[4], null]);
            }
          }
        } while (eventCount > 0);
        // Be sure to clear this manually, as the sockets are not read through
        // the _NativeSocket interface.
        native.available = 0;
        for (var map in pair.values) {
          for (var event in map.values) {
            rewriteMove(event, getIsDir(event));
          }
        }
      } else if (event == RawSocketEvent.CLOSED) {} else if (event ==
          RawSocketEvent.READ_CLOSED) {} else {
        assert(false);
      }
      events.addAll(stops);
      return events;
    });
  }

  @patch
  static bool get isSupported native "FileSystemWatcher_IsSupported";

  static int _initWatcher() native "FileSystemWatcher_InitWatcher";
  static void _closeWatcher(int id) native "FileSystemWatcher_CloseWatcher";

  static int _watchPath(int id, _Namespace namespace, String path, int events,
      bool recursive) native "FileSystemWatcher_WatchPath";
  static void _unwatchPath(int id, int path_id)
      native "FileSystemWatcher_UnwatchPath";
  static List _readEvents(int id, int path_id)
      native "FileSystemWatcher_ReadEvents";
  static int _getSocketId(int id, int path_id)
      native "FileSystemWatcher_GetSocketId";
}

class _InotifyFileSystemWatcher extends _FileSystemWatcher {
  static final Map<int, StreamController> _idMap = {};
  static StreamSubscription _subscription;

  _InotifyFileSystemWatcher(path, events, recursive)
      : super._(path, events, recursive);

  void _newWatcher() {
    int id = _FileSystemWatcher._id;
    _subscription =
        _FileSystemWatcher._listenOnSocket(id, id, 0).listen((event) {
      if (_idMap.containsKey(event[0])) {
        if (event[1] != null) {
          _idMap[event[0]].add(event[1]);
        } else {
          _idMap[event[0]].close();
        }
      }
    });
  }

  void _doneWatcher() {
    _subscription.cancel();
  }

  Stream _pathWatched() {
    var pathId = _watcherPath.pathId;
    if (!_idMap.containsKey(pathId)) {
      _idMap[pathId] = new StreamController.broadcast();
    }
    return _idMap[pathId].stream;
  }

  void _pathWatchedEnd() {
    var pathId = _watcherPath.pathId;
    if (!_idMap.containsKey(pathId)) return;
    _idMap[pathId].close();
    _idMap.remove(pathId);
  }
}

class _Win32FileSystemWatcher extends _FileSystemWatcher {
  StreamSubscription _subscription;
  StreamController _controller;

  _Win32FileSystemWatcher(path, events, recursive)
      : super._(path, events, recursive);

  Stream _pathWatched() {
    var pathId = _watcherPath.pathId;
    _controller = new StreamController();
    _subscription =
        _FileSystemWatcher._listenOnSocket(pathId, 0, pathId).listen((event) {
      assert(event[0] == pathId);
      if (event[1] != null) {
        _controller.add(event[1]);
      } else {
        _controller.close();
      }
    });
    return _controller.stream;
  }

  void _pathWatchedEnd() {
    _subscription.cancel();
    _controller.close();
  }
}

class _FSEventStreamFileSystemWatcher extends _FileSystemWatcher {
  StreamSubscription _subscription;
  StreamController _controller;

  _FSEventStreamFileSystemWatcher(path, events, recursive)
      : super._(path, events, recursive);

  Stream _pathWatched() {
    var pathId = _watcherPath.pathId;
    var socketId = _FileSystemWatcher._getSocketId(0, pathId);
    _controller = new StreamController();
    _subscription =
        _FileSystemWatcher._listenOnSocket(socketId, 0, pathId).listen((event) {
      if (event[1] != null) {
        _controller.add(event[1]);
      } else {
        _controller.close();
      }
    });
    return _controller.stream;
  }

  void _pathWatchedEnd() {
    _subscription.cancel();
    _controller.close();
  }
}

Uint8List _makeUint8ListView(Uint8List source, int offsetInBytes, int length) {
  return new Uint8List.view(source.buffer, offsetInBytes, length);
}
