// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library watcher.directory_watcher.polling;

import 'dart:async';
import 'dart:io';

import 'package:stack_trace/stack_trace.dart';

import '../async_queue.dart';
import '../stat.dart';
import '../utils.dart';
import '../watch_event.dart';
import 'resubscribable.dart';

/// Periodically polls a directory for changes.
class PollingDirectoryWatcher extends ResubscribableDirectoryWatcher {
  /// Creates a new polling watcher monitoring [directory].
  ///
  /// If [_pollingDelay] is passed, it specifies the amount of time the watcher
  /// will pause between successive polls of the directory contents. Making this
  /// shorter will give more immediate feedback at the expense of doing more IO
  /// and higher CPU usage. Defaults to one second.
  PollingDirectoryWatcher(String directory, {Duration pollingDelay})
      : super(directory, () {
        return new _PollingDirectoryWatcher(directory,
            pollingDelay != null ? pollingDelay : new Duration(seconds: 1));
      });
}

class _PollingDirectoryWatcher implements ManuallyClosedDirectoryWatcher {
  final String directory;

  Stream<WatchEvent> get events => _events.stream;
  final _events = new StreamController<WatchEvent>.broadcast();

  bool get isReady => _ready.isCompleted;

  Future get ready => _ready.future;
  final _ready = new Completer();

  /// The amount of time the watcher pauses between successive polls of the
  /// directory contents.
  final Duration _pollingDelay;

  /// The previous modification times of the files in the directory.
  ///
  /// Used to tell which files have been modified.
  final _lastModifieds = new Map<String, DateTime>();

  /// The subscription used while [directory] is being listed.
  ///
  /// Will be `null` if a list is not currently happening.
  StreamSubscription<FileSystemEntity> _listSubscription;

  /// The queue of files waiting to be processed to see if they have been
  /// modified.
  ///
  /// Processing a file is asynchronous, as is listing the directory, so the
  /// queue exists to let each of those proceed at their own rate. The lister
  /// will enqueue files as quickly as it can. Meanwhile, files are dequeued
  /// and processed sequentially.
  AsyncQueue<String> _filesToProcess;

  /// The set of files that have been seen in the current directory listing.
  ///
  /// Used to tell which files have been removed: files that are in [_statuses]
  /// but not in here when a poll completes have been removed.
  final _polledFiles = new Set<String>();

  _PollingDirectoryWatcher(this.directory, this._pollingDelay) {
    _filesToProcess = new AsyncQueue<String>(_processFile,
        onError: (e, stackTrace) {
      if (!_events.isClosed) _events.addError(e, stackTrace);
    });

    _poll();
  }

  void close() {
    _events.close();

    // If we're in the middle of listing the directory, stop.
    if (_listSubscription != null) _listSubscription.cancel();

    // Don't process any remaining files.
    _filesToProcess.clear();
    _polledFiles.clear();
    _lastModifieds.clear();
  }

  /// Scans the contents of the directory once to see which files have been
  /// added, removed, and modified.
  void _poll() {
    _filesToProcess.clear();
    _polledFiles.clear();

    endListing() {
      assert(!_events.isClosed);
      _listSubscription = null;

      // Null tells the queue consumer that we're done listing.
      _filesToProcess.add(null);
    }

    var stream = Chain.track(new Directory(directory).list(recursive: true));
    _listSubscription = stream.listen((entity) {
      assert(!_events.isClosed);

      if (entity is! File) return;
      _filesToProcess.add(entity.path);
    }, onError: (error, stackTrace) {
      if (!isDirectoryNotFoundException(error)) {
        // It's some unknown error. Pipe it over to the event stream so the
        // user can see it.
        _events.addError(error, stackTrace);
      }

      // When an error occurs, we end the listing normally, which has the
      // desired effect of marking all files that were in the directory as
      // being removed.
      endListing();
    }, onDone: endListing, cancelOnError: true);
  }

  /// Processes [file] to determine if it has been modified since the last
  /// time it was scanned.
  Future _processFile(String file) {
    // `null` is the sentinel which means the directory listing is complete.
    if (file == null) return _completePoll();

    return getModificationTime(file).then((modified) {
      if (_events.isClosed) return null;

      var lastModified = _lastModifieds[file];

      // If its modification time hasn't changed, assume the file is unchanged.
      if (lastModified != null && lastModified == modified) {
        // The file is still here.
        _polledFiles.add(file);
        return null;
      }

      if (_events.isClosed) return null;

      _lastModifieds[file] = modified;
      _polledFiles.add(file);

      // Only notify if we're ready to emit events.
      if (!isReady) return null;

      var type = lastModified == null ? ChangeType.ADD : ChangeType.MODIFY;
      _events.add(new WatchEvent(type, file));
    });
  }

  /// After the directory listing is complete, this determines which files were
  /// removed and then restarts the next poll.
  Future _completePoll() {
    // Any files that were not seen in the last poll but that we have a
    // status for must have been removed.
    var removedFiles = _lastModifieds.keys.toSet().difference(_polledFiles);
    for (var removed in removedFiles) {
      if (isReady) _events.add(new WatchEvent(ChangeType.REMOVE, removed));
      _lastModifieds.remove(removed);
    }

    if (!isReady) _ready.complete();

    // Wait and then poll again.
    return new Future.delayed(_pollingDelay).then((_) {
      if (_events.isClosed) return;
      _poll();
    });
  }
}
