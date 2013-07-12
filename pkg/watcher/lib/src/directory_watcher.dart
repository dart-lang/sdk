// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library watcher.directory_watcher;

import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'stat.dart';
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

  _WatchState _state = _WatchState.notWatching;

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

  /// The previous status of the files in the directory.
  ///
  /// Used to tell which files have been modified.
  final _statuses = new Map<String, _FileStatus>();

  /// Creates a new [DirectoryWatcher] monitoring [directory].
  DirectoryWatcher(this.directory) {
    _events = new StreamController<WatchEvent>.broadcast(onListen: () {
      _state = _state.listen(this);
    }, onCancel: () {
      _state = _state.cancel(this);
    });
  }

  /// Starts the asynchronous polling process.
  ///
  /// Scans the contents of the directory and compares the results to the
  /// previous scan. Loops to continue monitoring as long as there are
  /// subscribers to the [events] stream.
  Future _watch() {
    var files = new Set<String>();

    var stream = new Directory(directory).list(recursive: true);

    return stream.map((entity) {
      if (entity is! File) return new Future.value();
      files.add(entity.path);
      // TODO(rnystrom): These all run as fast as possible and read the
      // contents of the files. That means there's a pretty big IO hit all at
      // once. Maybe these should be queued up and rate limited?
      return _refreshFile(entity.path);
    }).toList().then((futures) {
      // Once the listing is done, make sure to wait until each file is also
      // done.
      return Future.wait(futures);
    }).then((_) {
      var removedFiles = _statuses.keys.toSet().difference(files);
      for (var removed in removedFiles) {
        if (_state.shouldNotify) {
          _events.add(new WatchEvent(ChangeType.REMOVE, removed));
        }
        _statuses.remove(removed);
      }

      var previousState = _state;
      _state = _state.finish(this);

      // If we were already sending notifications, add a bit of delay before
      // restarting just so that we don't whale on the file system.
      // TODO(rnystrom): Tune this and/or make it tunable?
      if (_state.shouldNotify) {
        return new Future.delayed(new Duration(seconds: 1));
      }
    }).then((_) {
      // Make sure we haven't transitioned to a non-watching state during the
      // delay.
      if (_state.shouldWatch) _watch();
    });
  }

  /// Compares the current state of the file at [path] to the state it was in
  /// the last time it was scanned.
  Future _refreshFile(String path) {
    return getModificationTime(path).then((modified) {
      var lastStatus = _statuses[path];

      // If it's modification time hasn't changed, assume the file is unchanged.
      if (lastStatus != null && lastStatus.modified == modified) return;

      return _hashFile(path).then((hash) {
        var status = new _FileStatus(modified, hash);
        _statuses[path] = status;

        // Only notify if the file contents changed.
        if (_state.shouldNotify &&
            (lastStatus == null || !_sameHash(lastStatus.hash, hash))) {
          var change = lastStatus == null ? ChangeType.ADD : ChangeType.MODIFY;
          _events.add(new WatchEvent(change, path));
        }
      });
    });
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

/// An "event" that is sent to the [_WatchState] FSM to trigger state
/// transitions.
typedef _WatchState _WatchStateEvent(DirectoryWatcher watcher);

/// The different states that the watcher can be in and the transitions between
/// them.
///
/// This class defines a finite state machine for keeping track of what the
/// asynchronous file polling is doing. Each instance of this is a state in the
/// machine and its [listen], [cancel], and [finish] fields define the state
/// transitions when those events occur.
class _WatchState {
  /// The watcher has no subscribers.
  static final notWatching = new _WatchState(
      listen: (watcher) {
    watcher._watch();
    return _WatchState.scanning;
  });

  /// The watcher has subscribers and is scanning for pre-existing files.
  static final scanning = new _WatchState(
      cancel: (watcher) {
    // No longer watching, so create a new incomplete ready future.
    watcher._ready = new Completer();
    return _WatchState.cancelling;
  }, finish: (watcher) {
    watcher._ready.complete();
    return _WatchState.watching;
  }, shouldWatch: true);

  /// The watcher was unsubscribed while polling and we're waiting for the poll
  /// to finish.
  static final cancelling = new _WatchState(
      listen: (_) => _WatchState.scanning,
      finish: (_) => _WatchState.notWatching);

  /// The watcher has subscribers, we have scanned for pre-existing files and
  /// now we're polling for changes.
  static final watching = new _WatchState(
      cancel: (watcher) {
    // No longer watching, so create a new incomplete ready future.
    watcher._ready = new Completer();
    return _WatchState.cancelling;
  }, finish: (_) => _WatchState.watching,
      shouldWatch: true, shouldNotify: true);

  /// Called when the first subscriber to the watcher has been added.
  final _WatchStateEvent listen;

  /// Called when all subscriptions on the watcher have been cancelled.
  final _WatchStateEvent cancel;

  /// Called when a poll loop has finished.
  final _WatchStateEvent finish;

  /// If the directory watcher should be watching the file system while in
  /// this state.
  final bool shouldWatch;

  /// If a change event should be sent for a file modification while in this
  /// state.
  final bool shouldNotify;

  _WatchState({this.listen, this.cancel, this.finish,
      this.shouldWatch: false, this.shouldNotify: false});
}

class _FileStatus {
  /// The last time the file was modified.
  DateTime modified;

  /// The SHA-1 hash of the contents of the file.
  List<int> hash;

  _FileStatus(this.modified, this.hash);
}