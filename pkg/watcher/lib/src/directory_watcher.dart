// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library watcher.directory_watcher;

import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'async_queue.dart';
import 'stat.dart';
import 'utils.dart';
import 'watch_event.dart';

/// Watches the contents of a directory and emits [WatchEvent]s when something
/// in the directory has changed.
class DirectoryWatcher {
  /// The directory whose contents are being monitored.
  final String directory;

  /// The broadcast [Stream] of events that have occurred to files in
  /// [directory].
  ///
  /// Changes will only be monitored while this stream has subscribers. Any
  /// file changes that occur during periods when there are no subscribers
  /// will not be reported the next time a subscriber is added.
  Stream<WatchEvent> get events => _events.stream;
  StreamController<WatchEvent> _events;

  _WatchState _state = _WatchState.UNSUBSCRIBED;

  /// A [Future] that completes when the watcher is initialized and watching
  /// for file changes.
  ///
  /// If the watcher is not currently monitoring the directory (because there
  /// are no subscribers to [events]), this returns a future that isn't
  /// complete yet. It will complete when a subscriber starts listening and
  /// the watcher finishes any initialization work it needs to do.
  ///
  /// If the watcher is already monitoring, this returns an already complete
  /// future.
  Future get ready => _ready.future;
  Completer _ready = new Completer();

  /// The amount of time the watcher pauses between successive polls of the
  /// directory contents.
  final Duration pollingDelay;

  /// The previous status of the files in the directory.
  ///
  /// Used to tell which files have been modified.
  final _statuses = new Map<String, _FileStatus>();

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

  /// Creates a new [DirectoryWatcher] monitoring [directory].
  ///
  /// If [pollingDelay] is passed, it specifies the amount of time the watcher
  /// will pause between successive polls of the directory contents. Making
  /// this shorter will give more immediate feedback at the expense of doing
  /// more IO and higher CPU usage. Defaults to one second.
  DirectoryWatcher(this.directory, {Duration pollingDelay})
      : pollingDelay = pollingDelay != null ? pollingDelay :
                                              new Duration(seconds: 1) {
    _events = new StreamController<WatchEvent>.broadcast(
        onListen: _watch, onCancel: _cancel);

    _filesToProcess = new AsyncQueue<String>(_processFile,
        onError: _events.addError);
  }

  /// Scans to see which files were already present before the watcher was
  /// subscribed to, and then starts watching the directory for changes.
  void _watch() {
    assert(_state == _WatchState.UNSUBSCRIBED);
    _state = _WatchState.SCANNING;
    _poll();
  }

  /// Stops watching the directory when there are no more subscribers.
  void _cancel() {
    assert(_state != _WatchState.UNSUBSCRIBED);
    _state = _WatchState.UNSUBSCRIBED;

    // If we're in the middle of listing the directory, stop.
    if (_listSubscription != null) _listSubscription.cancel();

    // Don't process any remaining files.
    _filesToProcess.clear();
    _polledFiles.clear();
    _statuses.clear();

    _ready = new Completer();
  }

  /// Scans the contents of the directory once to see which files have been
  /// added, removed, and modified.
  void _poll() {
    _filesToProcess.clear();
    _polledFiles.clear();

    endListing() {
      assert(_state != _WatchState.UNSUBSCRIBED);
      _listSubscription = null;

      // Null tells the queue consumer that we're done listing.
      _filesToProcess.add(null);
    }

    var stream = new Directory(directory).list(recursive: true);
    _listSubscription = stream.listen((entity) {
      assert(_state != _WatchState.UNSUBSCRIBED);

      if (entity is! File) return;
      _filesToProcess.add(entity.path);
    }, onError: (error) {
      if (isDirectoryNotFoundException(error)) {
        // If the directory doesn't exist, we end the listing normally, which
        // has the desired effect of marking all files that were in the
        // directory as being removed.
        endListing();
        return;
      }

      // It's some unknown error. Pipe it over to the event stream so we don't
      // take down the whole isolate.
      _events.addError(error);
    }, onDone: endListing);
  }

  /// Processes [file] to determine if it has been modified since the last
  /// time it was scanned.
  Future _processFile(String file) {
    assert(_state != _WatchState.UNSUBSCRIBED);

    // `null` is the sentinel which means the directory listing is complete.
    if (file == null) return _completePoll();

    return getModificationTime(file).then((modified) {
      if (_checkForCancel()) return;

      var lastStatus = _statuses[file];

      // If its modification time hasn't changed, assume the file is unchanged.
      if (lastStatus != null && lastStatus.modified == modified) {
        // The file is still here.
        _polledFiles.add(file);
        return;
      }

      return _hashFile(file).then((hash) {
        if (_checkForCancel()) return;

        var status = new _FileStatus(modified, hash);
        _statuses[file] = status;
        _polledFiles.add(file);

        // Only notify while in the watching state.
        if (_state != _WatchState.WATCHING) return;

        // And the file is different.
        var changed = lastStatus == null || !_sameHash(lastStatus.hash, hash);
        if (!changed) return;

        var type = lastStatus == null ? ChangeType.ADD : ChangeType.MODIFY;
        _events.add(new WatchEvent(type, file));
      });
    });
  }

  /// After the directory listing is complete, this determines which files were
  /// removed and then restarts the next poll.
  Future _completePoll() {
    // Any files that were not seen in the last poll but that we have a
    // status for must have been removed.
    var removedFiles = _statuses.keys.toSet().difference(_polledFiles);
    for (var removed in removedFiles) {
      if (_state == _WatchState.WATCHING) {
        _events.add(new WatchEvent(ChangeType.REMOVE, removed));
      }
      _statuses.remove(removed);
    }

    if (_state == _WatchState.SCANNING) {
      _state = _WatchState.WATCHING;
      _ready.complete();
    }

    // Wait and then poll again.
    return new Future.delayed(pollingDelay).then((_) {
      if (_checkForCancel()) return;
      _poll();
    });
  }

  /// Returns `true` and clears the processing queue if the watcher has been
  /// unsubscribed.
  bool _checkForCancel() {
    if (_state != _WatchState.UNSUBSCRIBED) return false;

    // Don't process any more files.
    _filesToProcess.clear();
    return true;
  }

  /// Calculates the SHA-1 hash of the file at [path].
  Future<List<int>> _hashFile(String path) {
    return new File(path).readAsBytes().then((bytes) {
      var sha1 = new SHA1();
      sha1.add(bytes);
      return sha1.close();
    });
  }

  /// Returns `true` if [a] and [b] are the same hash value, i.e. the same
  /// series of byte values.
  bool _sameHash(List<int> a, List<int> b) {
    // Hashes should always be the same size.
    assert(a.length == b.length);

    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }
}

/// Enum class for the states that the [DirectoryWatcher] can be in.
class _WatchState {
  /// There are no subscribers to the watcher's event stream and no watching
  /// is going on.
  static const UNSUBSCRIBED = const _WatchState("unsubscribed");

  /// There are subscribers and the watcher is doing an initial scan of the
  /// directory to see which files were already present before watching started.
  ///
  /// The watcher does not send notifications for changes that occurred while
  /// there were no subscribers, or for files already present before watching.
  /// The initial scan is used to determine what "before watching" state of
  /// the file system was.
  static const SCANNING = const _WatchState("scanning");

  /// There are subscribers and the watcher is polling the directory to look
  /// for changes.
  static const WATCHING = const _WatchState("watching");

  /// The name of the state.
  final String name;

  const _WatchState(this.name);
}

class _FileStatus {
  /// The last time the file was modified.
  DateTime modified;

  /// The SHA-1 hash of the contents of the file.
  List<int> hash;

  _FileStatus(this.modified, this.hash);
}