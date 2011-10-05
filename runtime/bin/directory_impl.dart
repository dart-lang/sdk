// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DirectoryException {
  const DirectoryException(String this.message);
  final String message;
}


class DirectoryImpl implements Directory {

  DirectoryImpl.open(String dir) {
    _id = 0;
    _closed = false;
    _listing = false;
    if (!_open(dir)) {
      _closed = true;
      throw new DirectoryException("Error: could not open directory");
    }
  }

  bool close() {
    if (_closed) {
      throw new DirectoryException("Error: directory closed");
    }
    if (_close(_id)) {
      _closePort(_dirHandler);
      _closePort(_fileHandler);
      _closePort(_doneHandler);
      _closePort(_dirErrorHandler);
      _closed = true;
      bool was_listing = _listing;
      _listing = false;
      if (was_listing && _doneHandler !== null) {
        _doneHandler(false);
      }
      return true;
    }
    return false;
  }

  void list([bool recursive = false]) {
    if (_closed) {
      throw new DirectoryException("Error: directory closed");
    }
    if (_listing) {
      throw new DirectoryException("Error: listing already in progress");
    }
    _listing = true;
    _list(_id,
          recursive,
          _dirHandler,
          _fileHandler,
          _doneHandler,
          _dirErrorHandler);
  }

  // TODO(ager): Implement setting of the handlers as in the process library.
  void setDirHandler(void dirHandler(String dir)) {
    if (_closed) {
      throw new DirectoryException("Error: directory closed");
    }
    if (_dirHandler === null) {
      _dirHandler = new ReceivePort();
    }
    _dirHandler.receive((String dir, ignored) => dirHandler(dir));
  }

  void setFileHandler(void fileHandler(String file)) {
    if (_closed) {
      throw new DirectoryException("Error: directory closed");
    }
    if (_fileHandler === null) {
      _fileHandler = new ReceivePort();
    }
    _fileHandler.receive((String file, ignored) => fileHandler(file));
  }

  void setDoneHandler(void doneHandler(bool completed)) {
    if (_closed) {
      throw new DirectoryException("Error: directory closed");
    }
    if (_doneHandler === null) {
      _doneHandler = new ReceivePort();
    }
    _doneHandler.receive((bool completed, ignored) {
      _listing = false;
      doneHandler(completed);
    });
  }

  void setDirErrorHandler(void errorHandler(String dir)) {
    if (_closed) {
      throw new DirectoryException("Error: directory closed");
    }
    if (_dirErrorHandler === null) {
      _dirErrorHandler = new ReceivePort();
    }
    _dirErrorHandler.receive((String dir, ignored) {
      errorHandler(dir, completed);
    });
  }

  // Utility methods.
  void _closePort(ReceivePort port) {
    if (port !== null) {
      port.close();
    }
  }

  // Native code binding.
  bool _open(String dir) native "Directory_Open";
  bool _close(int id) native "Directory_Close";
  void _list(int id,
             bool recursive,
             ReceivePort dirHandler,
             ReceivePort fileHandler,
             ReceivePort doneHandler,
             ReceivePort dirErrorHandler) native "Directory_List";

  ReceivePort _dirHandler;
  ReceivePort _fileHandler;
  ReceivePort _doneHandler;
  ReceivePort _dirErrorHandler;

  int _id;
  bool _closed;
  bool _listing;
}
