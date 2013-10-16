// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.file_pool;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

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

  /// Opens [file] for reading.
  ///
  /// When the returned stream is listened to, if there are too many files
  /// open, this will wait for a previously opened file to be closed and then
  /// try again.
  Stream<List<int>> openRead(File file) => new _FileReader(this, file).stream;

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

  /// Tries to re-listen to the next pending file reader if there are any.
  void _retryPendingListen() {
    if (_pendingListens.isEmpty) return;

    var pending = _pendingListens.removeFirst();
    pending._listen();
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

  /// The underyling file stream.
  Stream<List<int>> _fileStream;

  /// The controller for the stream wrapper.
  StreamController<List<int>> _controller;

  /// The current subscription to the underlying file stream.
  ///
  /// This will only be non-null while the wrapped stream is being listened to.
  StreamSubscription _subscription;

  /// The timeout timer.
  ///
  /// If this timer fires before the listen is retried, it gives up and throws
  /// the original error.
  Timer _timer;

  /// When a [listen] call has thrown a "too many files" error, this will be
  /// the exception object.
  Object _exception;

  /// When a [listen] call has thrown a "too many files" error, this will be
  /// the captured stack trace.
  Object _stackTrace;

  /// The wrapped stream that the file can be read from.
  Stream<List<int>> get stream => _controller.stream;

  _FileReader(this._pool, this._file) {
    _controller = new StreamController<List<int>>(onListen: _listen,
        onPause: () {
      _subscription.pause();
    }, onResume: () {
      _subscription.resume();
    }, onCancel: () {
      if (_subscription != null) _subscription.cancel();
      _subscription = null;
    }, sync: true);
  }

  /// Starts listening to the underlying file stream.
  void _listen() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }

    _exception = null;
    _stackTrace = null;

    _fileStream = _file.openRead();
    _subscription = _fileStream.listen(_controller.add,
        onError: _onError, onDone: _onDone, cancelOnError: true);
  }

  /// Handles an error from the underlying file stream.
  ///
  /// "Too many file" errors are caught so that we can retry later. Other
  /// errors are passed to the wrapped stream and the underlying stream
  /// subscription is canceled.
  void _onError(Object exception, Object stackTrace) {
    assert(_subscription != null);
    assert(_exception == null);

    // The subscription is canceled after an error.
    _subscription = null;

    // We only handle "Too many open files errors".
    if (exception is! FileException || exception.osError.errorCode != 24) {
      _controller.addError(exception, stackTrace);
      return;
    }

    _exception = exception;
    _stackTrace = stackTrace;

    // We'll try to defer the listen in the hopes that another file will close
    // and we can try. If that doesn't happen after a while, give up and just
    // throw the original error.
    // TODO(rnystrom): The point of this timer is to not get stuck forever in
    // a deadlock scenario. But this can also erroneously fire if there is a
    // large number of slow reads that do incrementally finish. A file may not
    // move to the front of the queue in time even though it is making
    // progress. A better solution is to have a single deadlock timer on the
    // FilePool itself that starts when a pending listen is enqueued and checks
    // to see if progress has been made when it fires.
    _timer = new Timer(new Duration(seconds: 60), _onTimeout);

    // Tell the pool that this file is waiting.
    _pool._pendingListens.add(this);
  }

  /// Handles the underlying file stream finishing.
  void _onDone() {
    _subscription = null;

    _controller.close();
    _pool._retryPendingListen();
  }

  /// If this file failed to be read because there were too many open files and
  /// no file was closed in time to retry, this handles giving up.
  void _onTimeout() {
    assert(_subscription == null);
    assert(_exception != null);

    // We failed to open in time, so just fail with the original error.
    _pool._pendingListens.remove(this);
    _controller.addError(_exception, _stackTrace);
    _controller.close();

    _timer = null;
    _exception = null;
    _stackTrace = null;
  }
}
