// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.file_pool;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:stack_trace/stack_trace.dart';

import 'utils.dart';

/// Manages a pool of files that are opened for reading to cope with maximum
/// file descriptor limits.
///
/// If a file cannot be opened because too many files are already open, this
/// will defer the open until a previously opened file is closed and then try
/// again. If this doesn't succeed after a certain amount of time, the open
/// will fail and the original "too many files" exception will be thrown.
class FilePool {
  /// [_FileReader]s whose last [listen] call failed and that are waiting for
  /// another file to close so they can be retried.
  final _pendingListens = new Queue<_FileReader>();

  /// The timeout timer.
  ///
  /// This timer is set as soon as the file limit is reached and is reset every
  /// time a file finishes being read or a new file is opened. If it fires, that
  /// indicates that the caller became deadlocked, likely due to files waiting
  /// for additional files to be read before they could be closed.
  Timer _timer;

  /// The number of files currently open in the pool.
  int _openFiles = 0;

  /// The maximum number of file descriptors that the pool will allocate.
  ///
  /// Barback may only use half the available file descriptors.
  int get _maxOpenFiles => (maxFileDescriptors / 2).floor();

  /// Opens [file] for reading.
  ///
  /// When the returned stream is listened to, if there are too many files
  /// open, this will wait for a previously opened file to be closed and then
  /// try again.
  Stream<List<int>> openRead(File file) {
    var reader = new _FileReader(this, file);
    if (_openFiles < _maxOpenFiles) {
      _openFiles++;
      reader.start();
    } else {
      _pendingListens.add(reader);
      _heartbeat();
    }
    return reader.stream;
  }

  /// Reads [file] as a string using [encoding].
  ///
  /// If there are too many files open and the read fails, this will wait for
  /// a previously opened file to be closed and then try again.
  Future<String> readAsString(File file, Encoding encoding) {
    return _readAsBytes(file).then(encoding.decode);
  }

  /// Reads [file] as a list of bytes, using [openRead] to retry if there are
  /// failures.
  Future<List<int>> _readAsBytes(File file) {
    var completer = new Completer<List<int>>();
    var builder = new BytesBuilder();

    openRead(file).listen(builder.add, onDone: () {
      completer.complete(builder.takeBytes());
    }, onError: completer.completeError, cancelOnError: true);

    return completer.future;
  }

  /// If there are any file reads that are waiting for available descriptors,
  /// this will allow the oldest one to start reading.
  void _startPendingListen() {
    if (_pendingListens.isEmpty) {
      _openFiles--;
      if (_timer != null) {
        _timer.cancel();
        _timer = null;
      }
      return;
    }

    _heartbeat();
    var pending = _pendingListens.removeFirst();
    pending.start();
  }

  /// Indicates that some external action has occurred and the timer should be
  /// restarted.
  void _heartbeat() {
    if (_timer != null) _timer.cancel();
    _timer = new Timer(new Duration(seconds: 60), _onTimeout);
  }

  /// Handles [_timer] timing out by causing all pending file readers to emit
  /// exceptions.
  void _onTimeout() {
    for (var reader in _pendingListens) {
      reader.timeout();
    }
    _pendingListens.clear();
    _timer = null;
  }
}

/// Wraps a raw file reading stream in a stream that handles "too many files"
/// errors.
///
/// This also notifies the pool when the underlying file stream is closed so
/// that it can try to open a waiting file.
class _FileReader {
  final FilePool _pool;
  final File _file;

  /// Whether the caller has paused this reader's stream.
  bool _isPaused = false;

  /// The underyling file stream.
  Stream<List<int>> _fileStream;

  /// The controller for the stream wrapper.
  StreamController<List<int>> _controller;

  /// The current subscription to the underlying file stream.
  ///
  /// This will only be non-null while the wrapped stream is being listened to.
  StreamSubscription _subscription;

  /// The wrapped stream that the file can be read from.
  Stream<List<int>> get stream => _controller.stream;

  _FileReader(this._pool, this._file) {
    _controller = new StreamController<List<int>>(onPause: () {
      _isPaused = true;
      if (_subscription != null) _subscription.pause();
    }, onResume: () {
      _isPaused = false;
      if (_subscription != null) _subscription.resume();
    }, onCancel: () {
      if (_subscription != null) _subscription.cancel();
      _subscription = null;
    }, sync: true);
  }

  /// Starts listening to the underlying file stream.
  void start() {
    _fileStream = _file.openRead();
    _subscription = _fileStream.listen(_controller.add,
        onError: _onError, onDone: _onDone, cancelOnError: true);
    if (_isPaused) _subscription.pause();
  }

  /// Emits a timeout exception.
  void timeout() {
    assert(_subscription == null);
    _controller.addError("FilePool deadlock: all file descriptors have been in "
        "use for too long.", new Trace.current().vmTrace);
    _controller.close();
  }

  /// Forwards an error from the underlying file stream.
  void _onError(Object exception, StackTrace stackTrace) {
    _controller.addError(exception, stackTrace);
    _onDone();
  }

  /// Handles the underlying file stream finishing.
  void _onDone() {
    _subscription = null;
    _controller.close();
    _pool._startPendingListen();
  }
}
