// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library watcher.directory_watcher.linux;

import 'dart:async';
import 'dart:io';

import 'package:stack_trace/stack_trace.dart';

import '../utils.dart';
import '../watch_event.dart';
import 'resubscribable.dart';

/// Uses the inotify subsystem to watch for filesystem events.
///
/// Inotify doesn't suport recursively watching subdirectories, nor does
/// [Directory.watch] polyfill that functionality. This class polyfills it
/// instead.
///
/// This class also compensates for the non-inotify-specific issues of
/// [Directory.watch] producing multiple events for a single logical action
/// (issue 14372) and providing insufficient information about move events
/// (issue 14424).
class LinuxDirectoryWatcher extends ResubscribableDirectoryWatcher {
  LinuxDirectoryWatcher(String directory)
      : super(directory, () => new _LinuxDirectoryWatcher(directory));
}

class _LinuxDirectoryWatcher implements ManuallyClosedDirectoryWatcher {
  final String directory;

  Stream<WatchEvent> get events => _eventsController.stream;
  final _eventsController = new StreamController<WatchEvent>.broadcast();

  bool get isReady => _readyCompleter.isCompleted;

  Future get ready => _readyCompleter.future;
  final _readyCompleter = new Completer();

  /// The last known state for each entry in this directory.
  ///
  /// The keys in this map are the paths to the directory entries; the values
  /// are [_EntryState]s indicating whether the entries are files or
  /// directories.
  final _entries = new Map<String, _EntryState>();

  /// The watchers for subdirectories of [directory].
  final _subWatchers = new Map<String, _LinuxDirectoryWatcher>();

  /// A set of all subscriptions that this watcher subscribes to.
  ///
  /// These are gathered together so that they may all be canceled when the
  /// watcher is closed.
  final _subscriptions = new Set<StreamSubscription>();

  _LinuxDirectoryWatcher(String directory)
      : directory = directory {
    // Batch the inotify changes together so that we can dedup events.
    var innerStream = Chain.track(new Directory(directory).watch())
        .transform(new BatchedStreamTransformer<FileSystemEvent>());
    _listen(innerStream, _onBatch,
        onError: _eventsController.addError,
        onDone: _onDone);

    _listen(Chain.track(new Directory(directory).list()), (entity) {
      _entries[entity.path] = new _EntryState(entity is Directory);
      if (entity is! Directory) return;
      _watchSubdir(entity.path);
    }, onError: (error, stackTrace) {
      _eventsController.addError(error, stackTrace);
      close();
    }, onDone: () {
      _waitUntilReady().then((_) => _readyCompleter.complete());
    }, cancelOnError: true);
  }

  /// Returns a [Future] that completes once all the subdirectory watchers are
  /// fully initialized.
  Future _waitUntilReady() {
    return Future.wait(_subWatchers.values.map((watcher) => watcher.ready))
        .then((_) {
      if (_subWatchers.values.every((watcher) => watcher.isReady)) return null;
      return _waitUntilReady();
    });
  }

  void close() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    for (var watcher in _subWatchers.values) {
      watcher.close();
    }

    _subWatchers.clear();
    _subscriptions.clear();
    _eventsController.close();
  }

  /// Returns all files (not directories) that this watcher knows of are
  /// recursively in the watched directory.
  Set<String> get _allFiles {
    var files = new Set<String>();
    _getAllFiles(files);
    return files;
  }

  /// Helper function for [_allFiles].
  ///
  /// Adds all files that this watcher knows of to [files].
  void _getAllFiles(Set<String> files) {
    files.addAll(_entries.keys
        .where((path) => _entries[path] == _EntryState.FILE).toSet());
    for (var watcher in _subWatchers.values) {
      watcher._getAllFiles(files);
    }
  }

  /// Watch a subdirectory of [directory] for changes.
  ///
  /// If the subdirectory was added after [this] began emitting events, its
  /// contents will be emitted as ADD events.
  void _watchSubdir(String path) {
    if (_subWatchers.containsKey(path)) return;
    var watcher = new _LinuxDirectoryWatcher(path);
    _subWatchers[path] = watcher;

    // TODO(nweiz): Catch any errors here that indicate that the directory in
    // question doesn't exist and silently stop watching it instead of
    // propagating the errors.
    _listen(watcher.events, (event) {
      if (isReady) _eventsController.add(event);
    }, onError: (error, stackTrace) {
      _eventsController.addError(error, stackTrace);
      _eventsController.close();
    }, onDone: () {
      if (_subWatchers[path] == watcher) _subWatchers.remove(path);

      // It's possible that a directory was removed and recreated very quickly.
      // If so, make sure we're still watching it.
      if (new Directory(path).existsSync()) _watchSubdir(path);
    });

    // TODO(nweiz): Right now it's possible for the watcher to emit an event for
    // a file before the directory list is complete. This could lead to the user
    // seeing a MODIFY or REMOVE event for a file before they see an ADD event,
    // which is bad. We should handle that.
    //
    // One possibility is to provide a general means (e.g.
    // `DirectoryWatcher.eventsAndExistingFiles`) to tell a watcher to emit
    // events for all the files that already exist. This would be useful for
    // top-level clients such as barback as well, and could be implemented with
    // a wrapper similar to how listening/canceling works now.

    // If a directory is added after we're finished with the initial scan, emit
    // an event for each entry in it. This gives the user consistently gets an
    // event for every new file.
    watcher.ready.then((_) {
      if (!isReady || _eventsController.isClosed) return;
      _listen(Chain.track(new Directory(path).list(recursive: true)), (entry) {
        if (entry is Directory) return;
        _eventsController.add(new WatchEvent(ChangeType.ADD, entry.path));
      }, onError: (error, stackTrace) {
        // Ignore an exception caused by the dir not existing. It's fine if it
        // was added and then quickly removed.
        if (error is FileSystemException) return;

        _eventsController.addError(error, stackTrace);
        close();
      }, cancelOnError: true);
    });
  }

  /// The callback that's run when a batch of changes comes in.
  void _onBatch(List<FileSystemEvent> batch) {
    var changedEntries = new Set<String>();
    var oldEntries = new Map.from(_entries);

    // inotify event batches are ordered by occurrence, so we treat them as a
    // log of what happened to a file.
    for (var event in batch) {
      // If the watched directory is deleted or moved, we'll get a deletion
      // event for it. Ignore it; we handle closing [this] when the underlying
      // stream is closed.
      if (event.path == directory) continue;

      changedEntries.add(event.path);

      if (event is FileSystemMoveEvent) {
        changedEntries.add(event.destination);
        _changeEntryState(event.path, ChangeType.REMOVE, event.isDirectory);
        _changeEntryState(event.destination, ChangeType.ADD, event.isDirectory);
      } else {
        _changeEntryState(event.path, _changeTypeFor(event), event.isDirectory);
      }
    }

    for (var path in changedEntries) {
      emitEvent(ChangeType type) {
        if (isReady) _eventsController.add(new WatchEvent(type, path));
      }

      var oldState = oldEntries[path];
      var newState = _entries[path];

      if (oldState != _EntryState.FILE && newState == _EntryState.FILE) {
        emitEvent(ChangeType.ADD);
      } else if (oldState == _EntryState.FILE && newState == _EntryState.FILE) {
        emitEvent(ChangeType.MODIFY);
      } else if (oldState == _EntryState.FILE && newState != _EntryState.FILE) {
        emitEvent(ChangeType.REMOVE);
      }

      if (oldState == _EntryState.DIRECTORY) {
        var watcher = _subWatchers.remove(path);
        if (watcher == null) continue;
        for (var path in watcher._allFiles) {
          _eventsController.add(new WatchEvent(ChangeType.REMOVE, path));
        }
        watcher.close();
      }

      if (newState == _EntryState.DIRECTORY) _watchSubdir(path);
    }
  }

  /// Changes the known state of the entry at [path] based on [change] and
  /// [isDir].
  void _changeEntryState(String path, ChangeType change, bool isDir) {
    if (change == ChangeType.ADD || change == ChangeType.MODIFY) {
      _entries[path] = new _EntryState(isDir);
    } else {
      assert(change == ChangeType.REMOVE);
      _entries.remove(path);
    }
  }

  /// Determines the [ChangeType] associated with [event].
  ChangeType _changeTypeFor(FileSystemEvent event) {
    if (event is FileSystemDeleteEvent) return ChangeType.REMOVE;
    if (event is FileSystemCreateEvent) return ChangeType.ADD;

    assert(event is FileSystemModifyEvent);
    return ChangeType.MODIFY;
  }

  /// Handles the underlying event stream closing, indicating that the directory
  /// being watched was removed.
  void _onDone() {
    // Most of the time when a directory is removed, its contents will get
    // individual REMOVE events before the watch stream is closed -- in that
    // case, [_entries] will be empty here. However, if the directory's removal
    // is caused by a MOVE, we need to manually emit events.
    if (isReady) {
      _entries.forEach((path, state) {
        if (state == _EntryState.DIRECTORY) return;
        _eventsController.add(new WatchEvent(ChangeType.REMOVE, path));
      });
    }

    // The parent directory often gets a close event before the subdirectories
    // are done emitting events. We wait for them to finish before we close
    // [events] so that we can be sure to emit a remove event for every file
    // that used to exist.
    Future.wait(_subWatchers.values.map((watcher) {
      try {
        return watcher.events.toList();
      } on StateError catch (_) {
        // It's possible that [watcher.events] is closed but the onDone event
        // hasn't reached us yet. It's fine if so.
        return new Future.value();
      }
    })).then((_) => close());
  }

  /// Like [Stream.listen], but automatically adds the subscription to
  /// [_subscriptions] so that it can be canceled when [close] is called.
  void _listen(Stream stream, void onData(event), {Function onError,
      void onDone(), bool cancelOnError}) {
    var subscription;
    subscription = stream.listen(onData, onError: onError, onDone: () {
      _subscriptions.remove(subscription);
      if (onDone != null) onDone();
    }, cancelOnError: cancelOnError);
    _subscriptions.add(subscription);
  }
}

/// An enum for the possible states of entries in a watched directory.
class _EntryState {
  final String _name;

  /// The entry is a file.
  static const FILE = const _EntryState._("file");

  /// The entry is a directory.
  static const DIRECTORY = const _EntryState._("directory");

  const _EntryState._(this._name);

  /// Returns [DIRECTORY] if [isDir] is true, and [FILE] otherwise.
  factory _EntryState(bool isDir) =>
      isDir ? _EntryState.DIRECTORY : _EntryState.FILE;

  String toString() => _name;
}
