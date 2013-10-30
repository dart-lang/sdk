// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class _File {
  /* patch */ static _exists(String path) native "File_Exists";
  /* patch */ static _create(String path) native "File_Create";
  /* patch */ static _createLink(String path, String target)
      native "File_CreateLink";
  /* patch */ static _linkTarget(String path) native "File_LinkTarget";
  /* patch */ static _deleteNative(String path) native "File_Delete";
  /* patch */ static _deleteLinkNative(String path) native "File_DeleteLink";
  /* patch */ static _rename(String oldPath, String newPath)
      native "File_Rename";
  /* patch */ static _renameLink(String oldPath, String newPath)
      native "File_RenameLink";
  /* patch */ static _lengthFromPath(String path) native "File_LengthFromPath";
  /* patch */ static _lastModified(String path) native "File_LastModified";
  /* patch */ static _open(String path, int mode) native "File_Open";
  /* patch */ static int _openStdio(int fd) native "File_OpenStdio";
}

patch class _RandomAccessFile {
  /* patch */ static int _close(int id) native "File_Close";
  /* patch */ static _readByte(int id) native "File_ReadByte";
  /* patch */ static _read(int id, int bytes) native "File_Read";
  /* patch */ static _readInto(int id, List<int> buffer, int start, int end)
      native "File_ReadInto";
  /* patch */ static _writeByte(int id, int value) native "File_WriteByte";
  /* patch */ static _writeFrom(int id, List<int> buffer, int start, int end)
      native "File_WriteFrom";
  /* patch */ static _position(int id) native "File_Position";
  /* patch */ static _setPosition(int id, int position)
      native "File_SetPosition";
  /* patch */ static _truncate(int id, int length) native "File_Truncate";
  /* patch */ static _length(int id) native "File_Length";
  /* patch */ static _flush(int id) native "File_Flush";
}

patch class _FileSystemWatcher {
  /* patch */ factory _FileSystemWatcher(
      String path, int events, bool recursive)
    => new _FileSystemWatcherImpl(path, events, recursive);

  /* patch */ static bool get isSupported => _FileSystemWatcherImpl.isSupported;
}

class _FileSystemWatcherImpl
    extends NativeFieldWrapperClass1
    implements _FileSystemWatcher {
  final String _path;
  final int _events;
  final bool _recursive;

  StreamController _controller;
  StreamSubscription _subscription;

  _FileSystemWatcherImpl(this._path, this._events, this._recursive) {
    if (!isSupported) {
      throw new FileSystemException(
          "File system watching is not supported on this system",
          _path);
    }
    _controller = new StreamController.broadcast(onListen: _listen,
                                                 onCancel: _cancel);
  }

  void _listen() {
    int socketId;
    try {
      socketId = _watchPath(_path, _events, identical(true, _recursive));
    } catch (e) {
      _controller.addError(new FileSystemException(
          "Failed to watch path", _path, e));
      _controller.close();
      return;
    }
    var socket = new _RawSocket(new _NativeSocket.watch(socketId));
    _subscription = socket.expand((event) {
      bool stop = false;
      var events = [];
      var pair = {};
      if (event == RawSocketEvent.READ) {
        String getPath(event) {
          var path = _path;
          if (event[2] != null) {
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
        void add(event) {
          if ((event.type & _events) == 0) return;
          events.add(event);
        }
        void rewriteMove(event, isDir) {
          if (event[3]) {
            add(new FileSystemCreateEvent._(getPath(event), isDir));
          } else {
            add(new FileSystemDeleteEvent._(getPath(event), isDir));
          }
        }
        while (socket.available() > 0) {
          for (var event in _readEvents()) {
            if (event == null) continue;
            bool isDir = getIsDir(event);
            var path = getPath(event);
            if ((event[0] & FileSystemEvent.CREATE) != 0) {
              add(new FileSystemCreateEvent._(path, isDir));
            }
            if ((event[0] & FileSystemEvent.MODIFY) != 0) {
              add(new FileSystemModifyEvent._(path, isDir, true));
            }
            if ((event[0] & FileSystemEvent._MODIFY_ATTRIBUTES) != 0) {
              add(new FileSystemModifyEvent._(path, isDir, false));
            }
            if ((event[0] & FileSystemEvent.MOVE) != 0) {
              int link = event[1];
              if (link > 0) {
                if (pair.containsKey(link)) {
                  events.add(new FileSystemMoveEvent._(
                      getPath(pair[link]), isDir, path));
                  pair.remove(link);
                } else {
                  pair[link] = event;
                }
              } else {
                rewriteMove(event, isDir);
              }
            }
            if ((event[0] & FileSystemEvent.DELETE) != 0) {
              add(new FileSystemDeleteEvent._(path, isDir));
            }
            if ((event[0] & FileSystemEvent._DELETE_SELF) != 0) {
              add(new FileSystemDeleteEvent._(path, isDir));
              stop = true;
            }
          }
        }
        for (var event in pair.values) {
          rewriteMove(event, getIsDir(event));
        }
      } else if (event == RawSocketEvent.CLOSED) {
      } else if (event == RawSocketEvent.READ_CLOSED) {
      } else {
        assert(false);
      }
      if (stop) socket.close();
      return events;
    })
    .listen(_controller.add, onDone: _cancel);
  }

  void _cancel() {
    if (_subscription != null) {
      _unwatchPath();
      _subscription.cancel();
      _subscription = null;
    }
    _controller.close();
  }

  Stream<FileSystemEvent> get stream => _controller.stream;

  static bool get isSupported native "FileSystemWatcher_IsSupported";

  int _watchPath(String path, int events, bool recursive)
      native "FileSystemWatcher_WatchPath";
  void _unwatchPath() native "FileSystemWatcher_UnwatchPath";
  List _readEvents() native "FileSystemWatcher_ReadEvents";
}

Uint8List _makeUint8ListView(Uint8List source, int offsetInBytes, int length) {
  return new Uint8List.view(source.buffer, offsetInBytes, length);
}
